import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def alchemy_entry(**changes) -> dict:
    return {'spell': 536213, 'name': 'Natural Alchemist (Alchemy skill)', 'kind': 'metric_delta',
            'label_suffix': 'alchemy_bonus', 'quote': 'Alchemy skill increased by $s1.', 'expected': 15,
            'before_expected': 0, 'trigger_spell': 801663, 'target': 'caster', 'metric': 'skill_bonus',
            'fields': {'skill': 171}, 'skill_line': {'skill': 171, 'value': 1, 'maximum': 300},
            'unlearn_before': [536213], **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class UnlearnBeforeTests(unittest.TestCase):
    def test_the_starting_spell_is_unlearned_before_the_before_reading(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), alchemy_entry())
        run.validate(scenario)
        steps = scenario['steps']
        removed = [index for index, step in enumerate(steps) if step['action'] == 'unlearn'
                   and step['spell'] == 536213]
        self.assertEqual(len(removed), 1)
        labels = [step.get('label') for step in steps]
        self.assertLess(removed[0], labels.index(expectation.model['before_label']))

    def test_without_the_option_nothing_is_unlearned(self):
        entry = {key: value for key, value in alchemy_entry().items() if key != 'unlearn_before'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'unlearn' for step in scenario['steps']))

    def test_refused_inputs(self):
        for raw in ([], [0], ['536213'], [536213, 536213], 536213):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), alchemy_entry(unlearn_before=raw))


if __name__ == '__main__':
    unittest.main()
