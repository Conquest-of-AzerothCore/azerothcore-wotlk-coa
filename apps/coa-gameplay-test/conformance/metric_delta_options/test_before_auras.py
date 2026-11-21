import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run

FIXTURE = [92123, 1, 'caster', 'caster']


def control_entry(**changes) -> dict:
    armor = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['spell'] == 301207 and entry.get('label_suffix') == 'armor')
    entry = {**armor, 'variant': 'before_fixture', 'label_suffix': 'before_fixture', 'expected': 3,
             'before_expected': 3, 'trigger_spell': 500981, 'metric': 'aura_stacks', 'fields': {'spell': 805011},
             'cast_in_before': False, 'before_auras': [FIXTURE]}
    for key in ('expected_ratio', 'tolerance', 'phase_auras', 'after_auras'):
        entry.pop(key, None)
    return {**entry, **changes}


def fixture_steps(scenario: dict) -> list[int]:
    return [index for index, step in enumerate(scenario['steps'])
            if step['action'] == 'set_aura' and step['spell'] == FIXTURE[0]]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BeforeAurasTests(unittest.TestCase):
    def test_the_aura_is_set_once_before_the_gate_learn(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), control_entry())
        run.validate(scenario)
        steps = scenario['steps']
        before = next(index for index, step in enumerate(steps)
                      if step.get('label') == expectation.model['before_label'])
        gate = next(index for index, step in enumerate(steps)
                    if index > before and step['action'] == 'learn' and step['spell'] == 301207)
        [index] = fixture_steps(scenario)
        self.assertLess(index, before)
        self.assertLess(before, gate)

    def test_without_the_option_no_aura_is_set(self):
        entry = {key: value for key, value in control_entry().items() if key != 'before_auras'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(fixture_steps(scenario), [])

    def test_an_aura_set_again_after_the_learn_is_refused(self):
        for changes in ({'phase_auras': [FIXTURE]}, {'after_auras': [FIXTURE]}, {'gate_timing': 'start'},
                        {'before_auras': []}, {'before_auras': [[92123, 1, 'moon', 'caster']]}):
            with self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), control_entry(**changes))


if __name__ == '__main__':
    unittest.main()
