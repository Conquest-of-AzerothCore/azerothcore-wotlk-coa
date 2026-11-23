import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def gated_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (health-gated setup and trigger)', 'kind': 'metric_delta',
            'label_suffix': 'gated', 'quote': "to increase your and your Undead minion's haste", 'expected': 1,
            'before_expected': 0, 'trigger_spell': 500237, 'target': 'dummy', 'setup_casts': [500237],
            'setup_only_after': True, 'setup_wait_ms': 1100, 'metric': 'aura', 'fields': {'spell': 500237},
            'phase_target_health_pct': [30, 29], **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PhaseTargetHealthPctTests(unittest.TestCase):
    def test_the_health_is_set_once_per_phase_before_its_setup_casts(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), gated_entry())
        run.validate(scenario)
        steps = scenario['steps']
        health = [index for index, step in enumerate(steps) if step['action'] == 'set_health_pct']
        self.assertEqual([steps[index]['pct'] for index in health], [30, 29])
        self.assertTrue(all(steps[index]['target'] == 'dummy' for index in health))
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 3)
        self.assertLess(health[0], casts[0])
        self.assertLess(casts[0], health[1])
        self.assertLess(health[1], casts[1])
        self.assertEqual(expectation.model['phase_target_health_pct'], [30, 29])

    def test_without_the_option_no_health_is_set(self):
        entry = {key: value for key, value in gated_entry().items() if key != 'phase_target_health_pct'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'set_health_pct' for step in scenario['steps']))

    def test_the_after_phase_is_lower_and_the_option_replaces_the_trigger_health(self):
        for changes in ({'phase_target_health_pct': [30, 30]}, {'phase_target_health_pct': [30]},
                        {'phase_target_health_pct': [0, -1]}, {'target_health_pct': 30},
                        {'target': 'caster'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), gated_entry(**changes))


if __name__ == '__main__':
    unittest.main()
