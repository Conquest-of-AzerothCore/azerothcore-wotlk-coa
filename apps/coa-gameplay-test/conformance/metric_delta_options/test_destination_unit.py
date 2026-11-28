from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from behaviours import behaviour_scenario
from metric_delta_options.destination_unit import NAME, parse
from profile import load_class_file

DBC_DIR = Path('/srv/coa/server-data/dbc')
WITCH_HUNTER_CLASS_ID = 15
CALTROPS = 503679


class DestinationUnitOptionTests(unittest.TestCase):
    def test_parse_accepts_caster_and_dummy_and_rejects_others(self):
        self.assertEqual(parse('caster'), 'caster')
        self.assertEqual(parse('dummy'), 'dummy')
        for bad in ('ally', '', 1, None, True):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse(bad)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_destination_unit_attaches_to_trigger_cast_step(self):
        class_file = load_class_file(WITCH_HUNTER_CLASS_ID)
        entry = {
            'spell': CALTROPS,
            'name': 'Caltrops',
            'kind': 'metric_delta',
            'quote': 'Throw caltrops over a $a1 yd area, lasting for $d.',
            'trigger_spell': CALTROPS,
            'target': 'dummy',
            'measure_actor': 'caster',
            'metric': 'owned_creature_count',
            'fields': {'entry': 506010},
            'before_expected': 0,
            'expected': 12,
            'cast_in_before': False,
            'wait_ms': 500,
            'expire_ms': 500,
            NAME: 'dummy',
        }
        scenario, _ = behaviour_scenario(class_file, entry)
        casts = [step for step in scenario['steps'] if step.get('action') == 'cast' and step.get('spell') == CALTROPS]
        self.assertEqual(len(casts), 1)
        self.assertEqual(casts[0]['destination_unit'], 'dummy')
        self.assertIn("targets the dummy's ground position", scenario['contract'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_destination_unit_dummy_without_dummy_in_scenario_is_refused(self):
        class_file = load_class_file(WITCH_HUNTER_CLASS_ID)
        entry = {
            'spell': CALTROPS,
            'name': 'Caltrops',
            'kind': 'metric_delta',
            'quote': 'Throw caltrops over a $a1 yd area, lasting for $d.',
            'trigger_spell': CALTROPS,
            'target': 'caster',
            'measure_actor': 'caster',
            'metric': 'owned_creature_count',
            'fields': {'entry': 506010},
            'before_expected': 0,
            'expected': 12,
            'cast_in_before': False,
            'wait_ms': 500,
            'expire_ms': 500,
            NAME: 'dummy',
        }
        with self.assertRaises(ValueError):
            behaviour_scenario(class_file, entry)


if __name__ == '__main__':
    unittest.main()
