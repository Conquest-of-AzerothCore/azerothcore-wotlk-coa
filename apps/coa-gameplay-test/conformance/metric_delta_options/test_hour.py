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
class HourTests(unittest.TestCase):
    def test_the_hour_is_set_on_the_scenario_and_named_in_the_contract(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), haste_entry(hour=0))
        run.validate(scenario)
        self.assertEqual(scenario['hour'], 0)
        self.assertIn('realm-local hour 0', scenario['contract'])
        self.assertEqual(expectation.model['hour'], 0)

    def test_without_the_option_the_scenario_has_no_hour(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), haste_entry())
        self.assertNotIn('hour', scenario)
        self.assertNotIn('hour', expectation.model)

    def test_an_hour_outside_the_day_is_refused(self):
        for raw in (24, -1, True, '12'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), haste_entry(hour=raw))
