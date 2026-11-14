import unittest

from behaviours import STRIKER, behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def snare_entry(variant: str, **changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 503740 and entry.get('variant') == variant)
    return {**entry, 'strike_landed': True, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class StrikeLandedTests(unittest.TestCase):
    def test_the_strike_logs_are_read_right_after_the_after_reading(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry('snare_control'))
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        logs = expectation.model['strike_landed']['log_label']
        read = scenario['steps'][labels.index(logs)]
        self.assertEqual(labels.index(logs), labels.index(expectation.model['after_label']) + 1)
        self.assertEqual((read['metric'], read['spell'], read['caster']), ('spell_log_count', 1715, STRIKER))

    def test_without_the_option_nothing_is_read(self):
        entry = {key: value for key, value in snare_entry('snare_control').items() if key != 'strike_landed'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('strike_landed', expectation.model)
        self.assertFalse(any(step.get('metric') == 'spell_log_count' for step in scenario['steps']))

    def test_the_option_needs_a_strike_at_an_owned_creature(self):
        for raw in ({'entry': 50073}, 1):
            with self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), snare_entry('snare_control', strike_landed=raw))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23),
                               snare_entry('snare_control', strike={'spell': 1715, 'health': 100000,
                                                                    'max_health': 100000}))

    def test_a_landed_strike_is_judged_and_a_missed_one_is_unmeasured(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry('snare_control'))
        before, after = expectation.model['before_label'], expectation.model['after_label']
        logs = expectation.model['strike_landed']['log_label']

        def judged(after_value: float, landed: float | None) -> str:
            values = {before: 1.14286, after: after_value}
            if landed is not None:
                values[logs] = landed
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(0.57143, 4), 'ok')
        self.assertEqual(judged(1.14286, 4), 'alert')
        self.assertEqual(judged(1.14286, 0), 'unmeasured')
        self.assertEqual(judged(1.14286, None), 'unmeasured')

    def test_an_immunity_read_without_a_landed_strike_is_not_ok(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry('frenzied_snare_immune'))
        model = expectation.model
        forced = model['forced_chance']
        values = {model['before_label']: 1.14286, model['after_label']: 1.14286, forced['absent_label']: 0,
                  forced['present_label']: 1, forced['count_label']: 1, forced['released_label']: 0}

        def judged(landed: float) -> str:
            run_values = {**values, model['strike_landed']['log_label']: landed}
            return judge_behaviour(base_verdict(expectation), FakeRun(run_values), expectation).status

        self.assertEqual(judged(2), 'ok')
        self.assertEqual(judged(0), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
