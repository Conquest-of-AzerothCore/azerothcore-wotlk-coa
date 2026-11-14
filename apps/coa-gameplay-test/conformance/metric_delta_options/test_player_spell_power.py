import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class PlayerSpellPowerTests(unittest.TestCase):
    def test_the_option_sets_the_caster_spell_power_and_its_absence_leaves_it_unset(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'tick_sp')
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(scenario['players'][0]['spell_power'], entry['player_spell_power'])
        plain = {key: value for key, value in entry.items() if key != 'player_spell_power'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), plain)
        self.assertNotIn('spell_power', scenario['players'][0])
