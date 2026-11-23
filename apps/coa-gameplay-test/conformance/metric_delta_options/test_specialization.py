import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_class_file
import run


def fish_entry(**changes) -> dict:
    return {'spell': 561069, 'name': 'Mixologist (teaches Ingredient: Fish Oil)', 'kind': 'metric_delta',
            'label_suffix': 'fish_taught', 'quote': 'Teaches you', 'trigger_spell': 801663, 'target': 'caster',
            'cast_in_before': False, 'metric': 'knows_spell', 'fields': {'spell': 801662}, 'before_expected': 0,
            'expected': 1, 'wait_ms': 500, 'expire_ms': 500, 'specialization': 6, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SpecializationTests(unittest.TestCase):
    def test_the_switch_comes_before_the_before_reading(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(13), fish_entry())
        run.validate(scenario)
        steps = scenario['steps']
        switched = [index for index, step in enumerate(steps) if step['action'] == 'specialization']
        self.assertEqual(len(switched), 1)
        self.assertEqual(steps[switched[0]]['id'], 6)
        self.assertEqual(steps[switched[0] - 1], {'action': 'money', 'actor': 'caster', 'copper': 1000000})
        labels = [step.get('label') for step in steps]
        self.assertLess(switched[0], labels.index(expectation.model['before_label']))

    def test_refused_inputs(self):
        for raw in (0, '6', 6.0, True, 0x10000):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(13), fish_entry(specialization=raw))


if __name__ == '__main__':
    unittest.main()
