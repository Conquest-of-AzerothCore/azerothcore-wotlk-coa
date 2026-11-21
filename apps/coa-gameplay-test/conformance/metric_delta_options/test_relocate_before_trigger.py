import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def haste_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (caster haste after a landed proc)', 'kind': 'metric_delta',
            'label_suffix': 'caster_proc_haste',
            'quote': "to increase your and your Undead minion's haste by $301334s1% for $301334d.",
            'expected': 0.83333, 'before_expected': 1, 'tolerance': 0.0001, 'trigger_spell': 500237,
            'target': 'dummy', 'setup_casts': [500971], 'setup_target': 'caster', 'setup_wait_ms': 3000,
            'wait_ms': 1000, 'expire_ms': 500, 'metric': 'cast_speed_multiplier', 'fields': {}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RelocateBeforeTriggerTests(unittest.TestCase):
    def test_the_caster_moves_right_before_each_trigger_cast(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     haste_entry(relocate_before_trigger={'dx': -12}))
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 500237]
        self.assertEqual(len(casts), 2)
        for index in casts:
            self.assertEqual(steps[index - 1], {'action': 'relocate', 'actor': 'caster', 'dx': -12.0})
        self.assertEqual(sum(step['action'] == 'relocate' for step in steps), 2)
        self.assertEqual(expectation.model['relocate_before_trigger'], -12.0)
        self.assertIn('moved -12 yd', scenario['contract'])

    def test_without_the_option_the_caster_stays(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), haste_entry())
        self.assertFalse(any(step['action'] == 'relocate' for step in scenario['steps']))
        self.assertNotIn('relocate_before_trigger', expectation.model)

    def test_a_shift_is_nonzero_and_bounded(self):
        for raw in ({'dx': 0}, {'dx': 41}, {'dx': True}, {'dy': 3}, -12):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), haste_entry(relocate_before_trigger=raw))


if __name__ == '__main__':
    unittest.main()
