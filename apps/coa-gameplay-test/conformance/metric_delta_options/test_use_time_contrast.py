import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def cast_time_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(19)['behaviours']
                 if entry.get('spell') == 712678 and entry.get('variant') == 'cooldown')
    return {**entry, 'metric': 'spell_cast_time_ms', 'before_expected': 2500, 'expected': 2125, 'tolerance': 1,
            'use_time_contrast': ['cooldown'], **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class UseTimeContrastTests(unittest.TestCase):
    def test_the_model_names_the_arm_labels_and_the_declared_gain(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), cast_time_entry())
        run.validate(scenario)
        self.assertEqual(expectation.model['use_time_contrast'],
                         {'arms': ['712678 behaviour_metric_delta cooldown'], 'gain': -375.0})
        self.assertIn('learned contrast with the arms cooldown', scenario['contract'])

    def test_an_expected_gain_is_the_declared_gain(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(19), cast_time_entry(expected_gain=0))
        self.assertEqual(expectation.model['use_time_contrast']['gain'], 0.0)

    def test_without_the_option_the_scenario_is_unchanged(self):
        plain = {key: value for key, value in cast_time_entry().items() if key != 'use_time_contrast'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), plain)
        opted, _ = behaviour_scenario(load_fixture_class_file(19), cast_time_entry())
        self.assertNotIn('use_time_contrast', expectation.model)
        self.assertEqual(scenario['steps'], opted['steps'])
        self.assertNotIn('learned contrast with the arms', scenario['contract'])

    def test_the_option_is_a_list_of_distinct_suffixes(self):
        for raw in (True, [], 'cooldown', ['cooldown', 'cooldown'], [''], [1]):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), cast_time_entry(use_time_contrast=raw))

    def test_the_option_judges_the_use_time_metrics_with_its_own_arm(self):
        for changes in ({'metric': 'cooldown_ms'}, {'use_time_contrast': ['other']}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), cast_time_entry(**changes))

    def test_the_verdict_detail_carries_the_contrast(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(19), cast_time_entry())
        values = {expectation.model['before_label']: 2500, expectation.model['after_label']: 2125}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['use_time_contrast'], expectation.model['use_time_contrast'])
        self.assertEqual(verdict.detail['metric'], 'spell_cast_time_ms')
        self.assertEqual(verdict.detail['contrast'], 'learned')


if __name__ == '__main__':
    unittest.main()
