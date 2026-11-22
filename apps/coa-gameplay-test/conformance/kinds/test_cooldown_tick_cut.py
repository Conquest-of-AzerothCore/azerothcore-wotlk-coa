import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from coverage import metric_evidence
from kinds.cooldown_tick_cut import TICK_CUT_METRIC, interval_bracket
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 300361, 'name': 'Day Cycles (Horusath Blast cut in Sunrise)', 'kind': 'cooldown_tick_cut',
         'label_suffix': 'tick_cut_sunrise',
         'quote': 'While in Sunrise, the remaining cooldown of Horusath Blast is reduced by $301176s2% every $t1 sec.',
         'cooled_spell': 500154, 'phase_aura': 500477, 'expected_pct': 10}


def remaining_after(first: float, cut_pct: float, offset_ms: float, elapsed_ms: float = 1000.0) -> float:
    return (1.0 - cut_pct / 100.0) * (first - offset_ms) - (elapsed_ms - offset_ms)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownTickCutTests(unittest.TestCase):
    def judged(self, cut_pct: float, offset_ms: float = 400.0, elapsed_ms: float = 1000.0,
               entry: dict = ENTRY) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        model = expectation.model
        values, remaining, now = {}, 24800.0, 5000.0
        for time_label, cooldown_label in model['reads']:
            values[time_label], values[cooldown_label] = now, remaining
            remaining, now = remaining_after(remaining, cut_pct, offset_ms, elapsed_ms), now + elapsed_ms
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_cooled_spell_is_cast_in_the_phase_and_read_one_amplitude_apart(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        steps = scenario['steps']
        phase = next(index for index, step in enumerate(steps) if step['action'] == 'set_aura'
                     and step['spell'] == 500477)
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 500154)
        self.assertLess(phase, cast)
        self.assertEqual(steps[cast]['target'], 'dummy')
        reads = [step for step in steps if step['action'] == 'assert' and step['metric'] == 'cooldown_ms']
        self.assertEqual(len(reads), 4)
        self.assertEqual([step['ms'] for step in steps if str(step.get('label', '')).startswith('tick interval')],
                         [1000, 1000, 1000])
        self.assertEqual(expectation.model['amplitude_ms'], 1000)
        self.assertEqual(expectation.label, '300361 behaviour_metric_delta tick_cut_sunrise')

    def test_a_ten_percent_cut_is_ok_wherever_the_tick_falls(self):
        for offset in (0.0, 1.0, 400.0, 999.0, 1000.0):
            with self.subTest(offset=offset):
                self.assertEqual(self.judged(10.0, offset).status, 'ok')

    def test_a_server_that_cuts_nothing_alerts(self):
        verdict = self.judged(0.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('against 10', verdict.explanation)

    def test_a_cut_twice_as_large_alerts(self):
        self.assertEqual(self.judged(20.0).status, 'alert')

    def test_the_control_phase_expects_no_cut(self):
        control = {**ENTRY, 'label_suffix': 'tick_cut_sunrise_control', 'phase_aura': 500511, 'expected_pct': 0}
        self.assertEqual(self.judged(0.0, entry=control).status, 'ok')
        self.assertEqual(self.judged(10.0, entry=control).status, 'alert')

    def test_an_interval_of_another_length_is_unmeasured(self):
        self.assertEqual(self.judged(10.0, elapsed_ms=1025.0).status, 'unmeasured')

    def test_the_bracket_holds_the_true_cut(self):
        for offset in (0.0, 250.0, 1000.0):
            low, high = interval_bracket(24800.0, remaining_after(24800.0, 10.0, offset), 1000.0)
            self.assertLessEqual(low, 10.0 + 1e-9)
            self.assertGreaterEqual(high, 10.0 - 1e-9)

    def test_the_derived_metric_is_an_event(self):
        self.assertEqual(metric_evidence()[TICK_CUT_METRIC], 'event')

    def test_reads_and_cut_are_bounded(self):
        for changes in ({'reads': 2}, {'reads': 21}, {'expected_pct': 100}, {'amplitude_effect': 1}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})


if __name__ == '__main__':
    unittest.main()
