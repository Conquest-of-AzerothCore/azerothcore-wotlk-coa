import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict


def rage_entry(**changes) -> dict:
    entry = next(entry for entry in load_class_file(15)['behaviours']
                 if entry.get('spell') == 807284 and entry.get('label_suffix') == 'rage')
    return {**entry, **changes}


def without_option(**changes) -> dict:
    return {key: value for key, value in rage_entry(**changes).items() if key != 'phase_power_in_uncast_before'}


def rage_powers(scenario: dict) -> list[tuple[int, int]]:
    return [(index, step['value']) for index, step in enumerate(scenario['steps'])
            if step['action'] == 'set_power' and step.get('power') == 1]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PhasePowerInUncastBeforeTests(unittest.TestCase):
    def scenario(self, entry: dict):
        return behaviour_scenario(load_class_file(15), entry)

    def test_the_uncast_before_phase_sets_the_before_power_ahead_of_its_read(self):
        scenario, [expectation] = self.scenario(rage_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        before, after = labels.index(expectation.model['before_label']), labels.index(expectation.model['after_label'])
        cast = next(index for index, step in enumerate(steps)
                    if step['action'] == 'cast' and step['spell'] == 807284)
        powers = rage_powers(scenario)
        self.assertEqual([value for _, value in powers], [0, 0])
        self.assertLess(powers[0][0], before)
        self.assertLess(before, powers[1][0])
        self.assertLess(powers[1][0], cast)
        self.assertLess(cast, after)
        self.assertTrue(expectation.model['phase_power_in_uncast_before'])

    def test_without_the_option_the_uncast_before_phase_sets_no_power(self):
        scenario, [expectation] = self.scenario(without_option())
        before = [step.get('label') for step in scenario['steps']].index(expectation.model['before_label'])
        self.assertEqual([index < before for index, _ in rage_powers(scenario)], [False])
        self.assertNotIn('phase_power_in_uncast_before', expectation.model)

    def test_the_option_is_true_with_phase_power_and_an_uncast_before_phase(self):
        for changes in ({'phase_power_in_uncast_before': 1}, {'phase_power_in_uncast_before': False},
                        {'cast_in_before': True}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.scenario(rage_entry(**changes))
        with self.assertRaises(ValueError):
            self.scenario({key: value for key, value in rage_entry().items() if key != 'phase_power'})

    def test_a_before_read_left_at_the_fixture_rage_alerts(self):
        _, [expectation] = self.scenario(rage_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(before_value: float, after_value: float) -> str:
            run_values = {before: before_value, after: after_value}
            return judge_behaviour(base_verdict(expectation), FakeRun(run_values), expectation).status

        self.assertEqual(judged(0, 179), 'ok')
        self.assertEqual(judged(1000, 1000), 'alert')
        self.assertEqual(judged(0, 0), 'alert')


if __name__ == '__main__':
    unittest.main()
