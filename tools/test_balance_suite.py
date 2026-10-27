import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
BALANCE_DIR = ROOT / 'apps/coa-gameplay-test/balance'

KNOWN_GROUPS = {'tank', 'healer', 'dps', 'dps-support'}
KNOWN_ARMORS = {'cloth', 'leather', 'mail', 'plate'}
KNOWN_STATS = {'strength', 'agility', 'intellect'}

OWNER_ROLE_DECISIONS = {
    25: 'healer',
    6: 'healer',
    31: 'healer',
    35: 'dps',
    57: 'tank',
}

DPS_SUPPORT_IDS = {3, 13, 20, 29, 58}


def load_catalog():
    return json.loads((BALANCE_DIR / 'catalog.json').read_text())


def load_dungeons():
    return json.loads((BALANCE_DIR / 'dungeons.json').read_text())


def load_gear():
    return json.loads((BALANCE_DIR / 'gear.json').read_text())


class CatalogTests(unittest.TestCase):
    def test_catalog_has_70_specs(self):
        catalog = load_catalog()
        self.assertEqual(len(catalog['specs']), 70)
        ids = [spec['spec_id'] for spec in catalog['specs']]
        self.assertEqual(len(ids), len(set(ids)))

    def test_groups_are_known(self):
        catalog = load_catalog()
        for spec in catalog['specs']:
            self.assertIn(spec['group'], KNOWN_GROUPS)
            self.assertIn(spec['armor'], KNOWN_ARMORS)
            self.assertIn(spec['primary_stat'], KNOWN_STATS)

    def test_owner_role_decisions_hold(self):
        catalog = load_catalog()
        by_id = {spec['spec_id']: spec for spec in catalog['specs']}
        for spec_id, group in OWNER_ROLE_DECISIONS.items():
            self.assertEqual(by_id[spec_id]['group'], group, spec_id)
        for spec_id in DPS_SUPPORT_IDS:
            self.assertEqual(by_id[spec_id]['group'], 'dps-support', spec_id)

    def test_every_level_has_talents(self):
        catalog = load_catalog()
        for spec in catalog['specs']:
            for level in ('20', '40', '60'):
                entries = spec['talents'][level]
                self.assertTrue(entries, (spec['spec_id'], level))
                for entry in entries:
                    self.assertEqual(len(entry), 2)
                    self.assertIsInstance(entry[0], int)
                    self.assertIsInstance(entry[1], int)
                    self.assertGreater(entry[1], 0)


class GearTests(unittest.TestCase):
    def test_every_armor_stat_pair_has_gear_at_each_level(self):
        catalog = load_catalog()
        gear = load_gear()
        pairs = {(spec['armor'], spec['primary_stat']) for spec in catalog['specs']}
        for level in ('20', '40', '60'):
            level_gear = gear['gear'][level]
            for armor, stat in pairs:
                key = f'{armor}/{stat}'
                self.assertIn(key, level_gear, (level, key))
                items = level_gear[key]
                self.assertTrue(items)
                for row in items:
                    self.assertIn('item', row)
                    self.assertIn('slot', row)
                    self.assertIsInstance(row['item'], int)
                    self.assertIsInstance(row['slot'], int)


class DungeonTests(unittest.TestCase):
    def test_dungeons_cover_20_40_60_with_3_elites_and_a_boss(self):
        dungeons = load_dungeons()
        for level in ('20', '40', '60'):
            row = dungeons['levels'][level]
            self.assertEqual(row['player_level'], int(level))
            self.assertIsInstance(row['map'], int)
            location = row['location']
            for axis in ('x', 'y', 'z', 'o'):
                self.assertIn(axis, location)
            self.assertEqual(len(row['elites']), 3)
            for elite in row['elites']:
                self.assertIsInstance(elite['entry'], int)
                self.assertIsInstance(elite['level'], int)
            self.assertIsInstance(row['boss']['entry'], int)
            self.assertIsInstance(row['boss']['level'], int)


if __name__ == '__main__':
    unittest.main()
