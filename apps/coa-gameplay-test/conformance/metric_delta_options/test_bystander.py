from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from behaviours import behaviour_scenario
from metric_delta_options.bystander import BYSTANDER_ID, NAME, BystanderSpec, parse
from profile import load_class_file

DBC_DIR = Path('/srv/coa/server-data/dbc')
WITCH_HUNTER_CLASS_ID = 15
INFILTRATE = 802281


class BystanderOptionTests(unittest.TestCase):
    def test_parse_validates_fields(self):
        parsed = parse({'entry': 68, 'faction': 12, 'distance': 5})
        self.assertEqual(parsed, BystanderSpec(68, 12, 5.0, 0, True, 100000))
        for bad in (
            {},
            {'entry': 0, 'faction': 12, 'distance': 5},
            {'entry': 68, 'faction': 0, 'distance': 5},
            {'entry': 68, 'faction': 12, 'distance': 0},
            {'entry': 68, 'faction': 12, 'distance': 150},
            {'entry': 68, 'faction': 12, 'distance': 5, 'reaction': 3},
            {'entry': 68, 'faction': 12, 'distance': 5, 'stationary': 1},
            {'entry': 68, 'faction': 12, 'distance': 5, 'health': 0},
        ):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse(bad)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_bystander_spawns_alongside_dummy_for_reaction_probe(self):
        class_file = load_class_file(WITCH_HUNTER_CLASS_ID)
        entry = {
            'spell': INFILTRATE,
            'name': 'Infiltrate (reaction)',
            'kind': 'metric_delta',
            'quote': 'While active you will appear as neutral to all aggressive creatures.',
            'trigger_spell': INFILTRATE,
            'target': 'dummy',
            'target_entry': 36,
            'dummy_distance': 15,
            'measure_actor': 'caster',
            'metric': 'reaction_to',
            'fields': {'target': 'dummy'},
            'before_expected': 1,
            'expected': 3,
            'cast_in_before': False,
            'wait_ms': 2500,
            'expire_ms': 500,
            NAME: {'entry': 68, 'faction': 12, 'distance': 5},
            'ally_arm': {
                'allies': 0,
                'arms': [
                    {
                        'actors': ['caster'],
                        'metric': 'reaction_to',
                        'fields': {'target': BYSTANDER_ID},
                        'before_expected': 4,
                        'expected': 4,
                        'tolerance': 0,
                        'source': 'Friendly faction 12 NPC remains REP_FRIENDLY (4) under Infiltrate 802281',
                    }
                ],
            },
        }
        scenario, _ = behaviour_scenario(class_file, entry)
        ids = [creature['id'] for creature in scenario['creatures']]
        self.assertEqual(ids, ['dummy', BYSTANDER_ID])
        bystander = scenario['creatures'][1]
        self.assertEqual(bystander['faction'], 12)
        self.assertEqual(bystander['entry'], 68)
        self.assertIn('faction 12', scenario['contract'])


if __name__ == '__main__':
    unittest.main()
