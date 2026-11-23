import unittest

from behaviours import ENEMY_PLAYER, behaviour_scenario
from profile import DBC_DIR, load_class_file
import run


def jinx_entry(**changes) -> dict:
    return {'spell': 807833, 'name': 'Shrinking Jinx (spell power -85)', 'kind': 'metric_delta',
            'label_suffix': 'jinx_sp', 'quote': 'and spell power by ${-($m3+0)}.', 'trigger_spell': 807833,
            'target': ENEMY_PLAYER, 'measure_actor': ENEMY_PLAYER, 'enemy_player_race': 2, 'enemy_spell_power': 100,
            'metric': 'spell_power', 'fields': {'school': 3}, 'gate_timing': 'start', 'trigger_only_after': True,
            'cast_power': 2000, 'before_expected': 100, 'expected': 15, 'expected_gain': -85, 'wait_ms': 1500,
            'expire_ms': 500, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class EnemySpellPowerTests(unittest.TestCase):
    def test_the_enemy_player_carries_the_spell_power(self):
        scenario, _ = behaviour_scenario(load_class_file(13), jinx_entry())
        run.validate(scenario)
        enemy = next(player for player in scenario['players'] if player['id'] == ENEMY_PLAYER)
        self.assertEqual(enemy['spell_power'], 100)
        self.assertNotIn('spell_power', scenario['players'][0])

    def test_refused_inputs(self):
        for raw in (0, -5, '100', True):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(13), jinx_entry(enemy_spell_power=raw))


if __name__ == '__main__':
    unittest.main()
