import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def jinx_entry(**changes) -> dict:
    return {'spell': 803325, 'name': "Hir'eek's Jinx (8 sec on an enemy player in Cat Form)", 'kind': 'metric_delta',
            'label_suffix': 'jinx_player_lasts', 'quote': '(8 sec vs players)', 'trigger_spell': 803325,
            'target': 'enemy', 'measure_actor': 'enemy', 'enemy_player_race': 6, 'enemy_player_class': 11,
            'enemy_casts_before': [768], 'metric': 'aura', 'fields': {'spell': 803325, 'caster': 'caster'},
            'gate_timing': 'start', 'trigger_only_after': True, 'cast_power': 1400, 'before_expected': 0,
            'expected': 1, 'wait_ms': 7800, 'expire_ms': 500, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class EnemyCastsBeforeTests(unittest.TestCase):
    def test_the_enemy_casts_once_before_the_trigger(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), jinx_entry())
        run.validate(scenario)
        steps = scenario['steps']
        forms = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 768]
        self.assertEqual(len(forms), 1)
        self.assertEqual(steps[forms[0]]['actor'], 'enemy')
        self.assertIn({'action': 'learn', 'actor': 'enemy', 'spell': 768}, steps[:forms[0]])
        trigger = next(index for index, step in enumerate(steps) if step['action'] == 'cast'
                       and step['spell'] == 803325)
        self.assertLess(forms[0], trigger)

    def test_without_an_enemy_player_the_option_is_refused(self):
        entry = jinx_entry(target='dummy', measure_actor='dummy')
        del entry['enemy_player_race']
        del entry['enemy_player_class']
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), entry)

    def test_refused_inputs(self):
        for raw in ([], [768, 768], [0], 768):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), jinx_entry(enemy_casts_before=raw))


if __name__ == '__main__':
    unittest.main()
