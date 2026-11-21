import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def skill_entry(**changes) -> dict:
    return {'spell': 536213, 'name': 'Natural Alchemist (Alchemy skill)', 'kind': 'metric_delta',
            'label_suffix': 'alchemy_bonus', 'quote': 'Alchemy skill increased by $s1.', 'expected': 15,
            'before_expected': 0, 'trigger_spell': 801663, 'target': 'caster', 'metric': 'skill_bonus',
            'fields': {'skill': 171}, 'skill_line': {'skill': 171, 'value': 1, 'maximum': 300}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SkillLineTests(unittest.TestCase):
    def test_the_line_is_given_once_before_the_before_reading(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), skill_entry())
        run.validate(scenario)
        steps = scenario['steps']
        given = [index for index, step in enumerate(steps) if step['action'] == 'set_skill' and step['skill'] == 171]
        self.assertEqual(len(given), 1)
        self.assertEqual((steps[given[0]]['skill'], steps[given[0]]['value'], steps[given[0]]['maximum']),
                         (171, 1, 300))
        labels = [step.get('label') for step in steps]
        self.assertLess(given[0], labels.index(expectation.model['before_label']))

    def test_without_the_option_no_line_is_given(self):
        entry = {key: value for key, value in skill_entry().items() if key != 'skill_line'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'set_skill' and step['skill'] == 171 for step in scenario['steps']))

    def test_refused_inputs(self):
        for raw in ({}, {'skill': 171, 'value': 1}, {'skill': 171, 'value': 0, 'maximum': 300},
                    {'skill': 171, 'value': 301, 'maximum': 300}, {'skill': 0, 'value': 1, 'maximum': 300},
                    {'skill': 171, 'value': 1, 'maximum': 451}, {'skill': '171', 'value': 1, 'maximum': 300}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), skill_entry(skill_line=raw))


if __name__ == '__main__':
    unittest.main()
