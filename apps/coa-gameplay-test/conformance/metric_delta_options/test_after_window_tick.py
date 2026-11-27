import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.after_window_tick import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def templar():
    return load_fixture_class_file(19)


def base_entry(**changes) -> dict:
    entry = next(entry for entry in templar()['behaviours']
                 if entry.get('spell') == 527023 and entry.get('variant') == 'steed_speed')
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterWindowTickTests(unittest.TestCase):
    OPTION = {'wait_ms': 3000, 'count_metric': 'spell_heal_count', 'expected': 400, 'tolerance': 5,
              'min_ticks': 2, 'hold_aura': {'actor': 'ally', 'spell': 807239, 'stacks': 5},
              'source': '5 stacks heal 400 HP per 1s tick'}

    def entry(self, **overrides) -> dict:
        return base_entry(
            metric='spell_heal_total', fields={'spell': 807239, 'target': 'ally'},
            before_expected=0, expected=1760,
            ally_arm={'allies': 1, 'arms': []},
            after_window_tick={**self.OPTION, **overrides})

    def test_window_steps_and_verdict_distinguish_five_stacks_from_three_percent_cap(self):
        scenario, [expectation] = behaviour_scenario(templar(), self.entry())
        run.validate(scenario)
        model = expectation.model
        window = model['after_window_tick']
        ok_values = {model['before_label']: 0.0, model['after_label']: 1760.0,
                     window['start_total']: 1760.0, window['start_count']: 9.0,
                     window['end_total']: 2960.0, window['end_count']: 12.0,
                     window['hold_aura']['label']: 5.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(ok_values), expectation).status, 'ok')
        two_ticks = {**ok_values, window['end_total']: 2560.0, window['end_count']: 11.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(two_ticks), expectation).status, 'ok')
        capped_three_pct = {**ok_values, window['end_total']: 2480.0, window['end_count']: 12.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(capped_three_pct), expectation).status,
                         'alert')
        dropped_stacks = {**ok_values, window['hold_aura']['label']: 4.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(dropped_stacks), expectation).status,
                         'alert')
        zero_ticks = {**ok_values, window['end_total']: 1760.0, window['end_count']: 9.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(zero_ticks), expectation).status, 'alert')
        one_tick = {**ok_values, window['end_total']: 2160.0, window['end_count']: 10.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(one_tick), expectation).status,
                         'unmeasured')

    def test_malformed_options_are_refused(self):
        for bad in ({}, {**self.OPTION, 'wait_ms': 0}, {**self.OPTION, 'min_ticks': 0},
                    {**self.OPTION, 'expected': 0}, {**self.OPTION, 'tolerance': -1},
                    {**self.OPTION, 'source': ' '},
                    {**self.OPTION, 'hold_aura': {'actor': 'ally', 'spell': 0, 'stacks': 5}}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse(bad)


if __name__ == '__main__':
    unittest.main()
