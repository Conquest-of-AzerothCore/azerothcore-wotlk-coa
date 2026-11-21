import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def kill_entry(**changes) -> dict:
    return {'spell': 501146, 'name': 'Shadowflare (a kill grants a Spirit)', 'kind': 'metric_delta',
            'label_suffix': 'kill_spirit', 'quote': 'Killing an enemy with this spell grants you a', 'expected': 1,
            'before_expected': 0, 'trigger_spell': 501146, 'target': 'dummy', 'measure_actor': 'caster',
            'metric': 'aura_stacks', 'fields': {'spell': 561136}, 'cast_power': 1400, 'wait_ms': 3500,
            'expire_ms': 500, 'after_target_health': 1, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterTargetHealthTests(unittest.TestCase):
    def test_the_treatment_dummy_alone_is_set_to_the_health(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), kill_entry())
        run.validate(scenario)
        steps = scenario['steps']
        health = [index for index, step in enumerate(steps) if step['action'] == 'set_health']
        self.assertEqual(len(health), 1)
        self.assertEqual((steps[health[0]]['actor'], steps[health[0]]['value']), ('dummy', 1))
        labels = [step.get('label') for step in steps]
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 501146]
        self.assertLess(labels.index(expectation.model['before_label']), health[0])
        self.assertLess(health[0], casts[-1])

    def test_without_the_option_the_dummy_keeps_its_health(self):
        entry = {key: value for key, value in kill_entry().items() if key != 'after_target_health'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'set_health' for step in scenario['steps']))

    def test_refused_inputs(self):
        for changes in ({'after_target_health': 0}, {'after_target_health': True},
                        {'after_target_health': 50000000}, {'trigger_only_after': True, 'gate_timing': 'start'},
                        {'target_health_pct': 50}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), kill_entry(**changes))


if __name__ == '__main__':
    unittest.main()
