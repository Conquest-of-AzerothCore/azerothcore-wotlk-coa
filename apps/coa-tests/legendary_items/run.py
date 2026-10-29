import importlib.util
import os
import struct
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'modules/mod-coa-legendary-items'
SPEC = importlib.util.spec_from_file_location('legendary_catalog', MODULE / 'tools/generate_catalog.py')
CATALOG = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CATALOG)


class LegendaryCatalogTest(unittest.TestCase):
    def test_generated_artifacts_match_the_catalog(self):
        for path, content in CATALOG.outputs().items():
            with self.subTest(path=path):
                self.assertEqual(path.read_text(), content)

    def test_stats_and_descriptions_match_a_level_29_drop(self):
        catalog = CATALOG.load_catalog()
        self.assertEqual(CATALOG.item_stats(catalog[0], 35), [4, 4, 7, 5, 38, 10, 0, 0])
        self.assertEqual(CATALOG.item_stats(catalog[3], 35), [5, 4, 7, 5, 45, 6, 0, 0])
        self.assertEqual(CATALOG.item_stats(catalog[6], 35), [3, 4, 7, 5, 38, 5, 45, 2])
        self.assertEqual(CATALOG.power_text(catalog[0], 29),
            'Gain 35 melee and ranged attack power for 8 sec after killing a non-gray creature.')
        self.assertEqual(CATALOG.power_text(catalog[63], 29), 'Gain 20% armor while at or below 35% health.')

    def test_stat_budget_sits_between_worldforged_and_epic_items(self):
        weights = {38: 0.5, 45: 0.86}
        for item in CATALOG.load_catalog():
            for level in (20, 40, 60):
                ilvl = level + CATALOG.ITEM_LEVEL_BONUS
                stats = CATALOG.item_stats(item, ilvl)
                points = sum(value * weights.get(stat, 1) for stat, value in zip(stats[::2], stats[1::2]))
                with self.subTest(item=item['name'], level=level):
                    self.assertGreaterEqual(points / ilvl, 0.35)
                    self.assertLessEqual(points / ilvl, 0.5)

    def test_items_are_rare_realm_bound_with_the_fabled_tag(self):
        sql = CATALOG.render_sql(CATALOG.load_catalog())
        item_rows = sql.split('INSERT INTO `item_dbc`', 1)[0]
        quality_and_flags = re.findall(r"^\(970\d{4}, 4, \d+, -1, '(?:[^'\\]|\\.)*', \d+, (\d+), (\d+),",
            item_rows, re.MULTILINE)
        self.assertEqual(len(quality_and_flags), 3840)
        self.assertEqual(set(quality_and_flags), {('3', str(0x08000000))})
        self.assertEqual(item_rows.count("'@Fabled@'"), 3840)
        self.assertNotIn("''", item_rows)

    def test_movement_is_exclusive_to_boots(self):
        catalog = CATALOG.load_catalog()
        movements = [item for item in catalog if item['power'] == 'Movement']
        self.assertEqual(len(movements), 21)
        self.assertTrue(all(item['inventory_type'] == 8 for item in movements))
        self.assertEqual(catalog[63]['power'], 'Armor')

    def test_emitted_item_rows_end_at_level_60(self):
        sql = CATALOG.render_sql(CATALOG.load_catalog())
        item_rows = sql.split('INSERT INTO `item_dbc`', 1)[1].split('INSERT INTO `spell_dbc`', 1)[0]
        entries = [int(entry) for entry in re.findall(r'^\((\d+),', item_rows, re.MULTILINE)]
        self.assertEqual(len(entries), 3840)
        self.assertEqual(len(set(entries)), 3840)
        self.assertTrue(all(1 <= (entry - 9700000) % 100 <= 60 for entry in entries))
        self.assertIn(9700060, entries)
        self.assertIn(9706360, entries)

    def test_native_stat_auras_cover_the_advertised_bonuses(self):
        catalog = CATALOG.load_catalog()
        self.assertEqual(CATALOG.aura_effects(catalog[0]), [(99, 0), (124, 0)])
        self.assertEqual(CATALOG.aura_effects(catalog[3]), [(13, 126), (135, 0)])
        self.assertEqual(CATALOG.aura_effects(catalog[6]), [(99, 0), (13, 126), (135, 0)])
        self.assertEqual(CATALOG.aura_effects(catalog[1]), [(31, 0)])
        self.assertEqual(CATALOG.aura_effects(catalog[63]), [(101, 1)])
        self.assertEqual(CATALOG.aura_effects(catalog[2]), [(108, 0)])

    def test_client_signature_selectors_preserve_existing_modifier_matches(self):
        path = Path(os.environ.get('COA_DBC_DIR', ROOT / 'env/dist/data/dbc')) / 'Spell.dbc'
        blob = path.read_bytes()
        magic, count, width, size, _ = struct.unpack_from('<4s4I', blob)
        self.assertEqual((magic, width, size), (b'WDBC', 234, 936))
        rows = list(struct.iter_unpack('<234I', blob[20:20 + count * size]))
        by_id = {row[0]: row for row in rows}
        families = {}
        for row in rows:
            families.setdefault(row[208], []).append(row)
        for item in CATALOG.load_catalog():
            if item['power'] != 'Signature':
                continue
            signature = by_id[item['signature_spell']]
            original = signature[209:212]
            bit = item['signature_mask_bit']
            extended = [value | ((1 << (bit % 32)) if bit // 32 == word else 0)
                for word, value in enumerate(original)]
            for row in families[signature[208]]:
                for effect in range(3):
                    if not row[71 + effect]:
                        continue
                    mask = row[122 + effect * 3:125 + effect * 3]
                    before = any(a & b for a, b in zip(original, mask))
                    after = any(a & b for a, b in zip(extended, mask))
                    with self.subTest(item=item['name'], modifier=row[0], effect=effect):
                        self.assertEqual(after, before)


if __name__ == '__main__':
    unittest.main()
