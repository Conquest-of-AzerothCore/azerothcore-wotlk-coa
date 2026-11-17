import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def tick_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'tick_sp')
    plain = {key: value for key, value in entry.items() if key != 'player_spell_power'}
    return {**plain, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class PlayerAttackPowerTests(unittest.TestCase):
    def test_the_option_sets_the_caster_attack_power_and_its_absence_leaves_it_unset(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), tick_entry(player_attack_power=20000))
        run.validate(scenario)
        self.assertEqual(scenario['players'][0]['attack_power'], 20000)
        self.assertNotIn('spell_power', scenario['players'][0])
        self.assertIn('20000 more attack power', scenario['contract'])
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), tick_entry())
        self.assertNotIn('attack_power', scenario['players'][0])

    def test_an_attack_power_is_a_positive_integer(self):
        for raw in (0, -5, 2.5, True, '100'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), tick_entry(player_attack_power=raw))


if __name__ == '__main__':
    unittest.main()
