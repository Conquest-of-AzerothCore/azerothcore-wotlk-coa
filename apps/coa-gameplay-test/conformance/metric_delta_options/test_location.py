from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from behaviours import behaviour_scenario
from metric_delta_options.location import NAME, parse
from profile import load_class_file

DBC_DIR = Path('/srv/coa/server-data/dbc')
WITCH_HUNTER_CLASS_ID = 15
INFILTRATE = 802281


class LocationOptionTests(unittest.TestCase):
    def test_parse_validates_coordinates_and_optional_ignore_access(self):
        parsed = parse({'map': 36, 'x': -16.4, 'y': -383.07, 'z': 61.78, 'o': 0, 'ignore_access': True})
        self.assertEqual(parsed, {'map': 36, 'x': -16.4, 'y': -383.07, 'z': 61.78, 'o': 0.0, 'ignore_access': True})
        for bad in (
            {},
            {'map': -1, 'x': 0, 'y': 0, 'z': 0, 'o': 0},
            {'map': True, 'x': 0, 'y': 0, 'z': 0, 'o': 0},
            {'map': 0, 'x': float('nan'), 'y': 0, 'z': 0, 'o': 0},
            {'map': 0, 'x': 0, 'y': 0, 'z': 0, 'o': 0, 'ignore_access': 1},
            {'map': 0, 'x': 0, 'y': 0, 'z': 0, 'o': 0, 'extra': 1},
        ):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse(bad)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_location_sets_top_level_scenario_location(self):
        class_file = load_class_file(WITCH_HUNTER_CLASS_ID)
        spot = {'map': 36, 'x': -16.4, 'y': -383.07, 'z': 61.78, 'o': 0.0, 'ignore_access': True}
        entry = {
            'spell': INFILTRATE,
            'name': 'Infiltrate',
            'kind': 'metric_delta',
            'quote': 'Can only be used in the open world.',
            'trigger_spell': INFILTRATE,
            'target': 'dummy',
            'target_entry': 36,
            'dummy_distance': 15,
            'measure_actor': 'caster',
            'metric': 'cast_failure',
            'fields': {'spell': INFILTRATE},
            'before_expected': 0,
            'expected': 9,
            'cast_in_before': False,
            'wait_ms': 500,
            'expire_ms': 500,
            NAME: spot,
        }
        scenario, _ = behaviour_scenario(class_file, entry)
        self.assertEqual(scenario['location'], spot)
        self.assertIn('starts on map 36', scenario['contract'])


if __name__ == '__main__':
    unittest.main()
