import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def focus_entry(**changes) -> dict:
    return {'spell': 500960, 'name': 'Serpent Ward (focus on the selected enemy)', 'kind': 'metric_delta',
            'label_suffix': 'focus_primary', 'quote': 'attempting to focus on your primary target', 'expected': 3,
            'before_expected': 0, 'after_at_least': 2, 'after_at_most': 4, 'trigger_spell': 500960,
            'target': 'caster', 'measure_actor': 'caster', 'metric': 'spell_damage_count',
            'fields': {'spell': 573055, 'target': 'dummy'}, 'cast_power': 1400, 'wait_ms': 4300, 'expire_ms': 500,
            'area_dummies': [6],
            'engage_and_select': {'spell': 504608, 'gap_ms': 1600, 'select_before': 'area1',
                                  'select_after': 'dummy'}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class EngageAndSelectTests(unittest.TestCase):
    def test_each_phase_selects_its_unit_and_engages_every_dummy(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), focus_entry())
        run.validate(scenario)
        steps = scenario['steps']
        selects = [step['target'] for step in steps if step['action'] == 'select']
        self.assertEqual(selects, ['area1', 'dummy'])
        engaged = [step['target'] for step in steps if step['action'] == 'cast' and step['spell'] == 504608]
        self.assertEqual(engaged, ['area1', 'dummy', 'area1', 'dummy'])
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['dummy', 'area1'])

    def test_without_the_option_nothing_is_engaged(self):
        entry = {key: value for key, value in focus_entry().items() if key != 'engage_and_select'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'select' for step in scenario['steps']))

    def test_refused_inputs(self):
        for changes in ({'engage_and_select': {'spell': 504608, 'gap_ms': 1600, 'select_before': 'dummy',
                                               'select_after': 'dummy'}},
                        {'engage_and_select': {'spell': 504608, 'gap_ms': 1600, 'select_before': 'area2',
                                               'select_after': 'dummy'}},
                        {'area_dummies': None}, {'cast_in_before': False}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), focus_entry(**changes))


if __name__ == '__main__':
    unittest.main()
