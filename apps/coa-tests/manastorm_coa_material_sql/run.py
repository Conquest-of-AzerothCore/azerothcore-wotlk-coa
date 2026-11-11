import json
from fractions import Fraction
from pathlib import Path
import re
import sqlite3
import unittest


ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / 'modules/mod-manastorm-endless/data/sql/db-world/base/42_manastorm_material_cache.sql'
MIGRATION = ROOT / 'data/sql/updates/pending_db_world/rev_20261103_02_manastorm_coa_material_cache_chance.sql'
SOURCE = ROOT / 'modules/mod-manastorm-endless/src/ManastormCacheLoot.cpp'


def sqlite_schema(sql):
    return re.sub(r'\) ENGINE=InnoDB[^;]*;', ');', sql)


def loader_queries():
    queries = []
    for match in re.finditer(r'WorldDatabase.Query\(\s*((?:"[^"\n]*"\s*)+)\);',
                             SOURCE.read_text(encoding='utf-8')):
        sql = ''.join(json.loads(part) for part in re.findall(r'"[^"\n]*"', match[1]))
        if 'manastorm_material_cache_pool' in sql:
            queries.append(sql)
    if len(queries) != 2:
        raise ValueError('Expected CoA and legacy material pool loader queries')
    return queries


class MaterialChanceTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        base = BASE.read_text(encoding='utf-8')
        schema = re.search(r'CREATE TABLE IF NOT EXISTS.*?;', base, re.S)[0]
        seed = re.search(r'INSERT IGNORE INTO.*?;', base, re.S)[0]
        self.db.executescript(sqlite_schema(schema) + seed.replace('INSERT IGNORE', 'INSERT OR IGNORE'))
        self.migration = sqlite_schema(MIGRATION.read_text(encoding='utf-8'))
        self.db.executescript(self.migration)
        self.coa, self.legacy = loader_queries()

    def tearDown(self):
        self.db.close()

    def rows(self, query):
        return {row[1]: row for row in self.db.execute(query)}

    def probability(self, query, entry):
        rows = list(self.db.execute(query))
        selected = next(row for row in rows if row[1] == entry)
        categories = len({row[0] for row in rows})
        total_weight = sum(row[2] for row in rows if row[0] == selected[0])
        return Fraction(3, categories) * Fraction(selected[2], total_weight) * Fraction(selected[5], 100)

    def test_rare_category_is_four_times_less_frequent(self):
        for entry in (11382, 17010, 17011):
            self.assertEqual(self.probability(self.legacy, entry), Fraction(1, 12))
            self.assertEqual(self.probability(self.coa, entry), Fraction(1, 48))

    def test_targeted_odds_and_ordinary_material_controls(self):
        old = self.rows(self.legacy)
        new = self.rows(self.coa)
        self.assertEqual(set(old), set(new))
        self.assertEqual(sum(row[5] == 25 for row in new.values()), 7)
        self.assertEqual(sum(row[5] == 50 for row in new.values()), 32)
        for entry, row in old.items():
            self.assertEqual(row[:5], new[entry][:5])
            self.assertEqual(self.probability(self.coa, entry),
                             self.probability(self.legacy, entry) * Fraction(new[entry][5], 100))
        for entry in (2447, 2840, 2589, 2318, 10940, 7067, 3371):
            self.assertEqual(new[entry][5], 100)

    def test_override_boundaries_and_missing_row_default(self):
        self.db.execute('UPDATE manastorm_coa_material_cache_chance SET chance_pct=0 WHERE item_entry=17010')
        self.assertEqual(self.probability(self.coa, 17010), 0)
        self.db.execute('UPDATE manastorm_coa_material_cache_chance SET chance_pct=100 WHERE item_entry=17010')
        self.assertEqual(self.probability(self.coa, 17010), self.probability(self.legacy, 17010))
        self.db.execute('DELETE FROM manastorm_coa_material_cache_chance WHERE item_entry=17010')
        self.assertEqual(self.probability(self.coa, 17010), self.probability(self.legacy, 17010))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE manastorm_coa_material_cache_chance SET chance_pct=101')

    def test_migration_rerun_is_idempotent_and_keeps_unrelated_overrides(self):
        self.db.execute('INSERT INTO manastorm_coa_material_cache_chance VALUES(2447, 80)')
        self.db.executescript(self.migration)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM manastorm_coa_material_cache_chance')
                         .fetchone()[0], 40)
        self.assertEqual(self.rows(self.coa)[2447][5], 80)

    def test_legacy_loader_does_not_require_coa_migration(self):
        self.db.execute('DROP TABLE manastorm_coa_material_cache_chance')
        self.assertTrue(all(row[5] == 100 for row in self.db.execute(self.legacy)))
        with self.assertRaises(sqlite3.OperationalError):
            self.db.execute(self.coa)

    def test_native_selector_keeps_realm_gate_and_rejects_without_reroll(self):
        source = SOURCE.read_text(encoding='utf-8')
        self.assertIn('if (ManastormModuleConfig::CoALootModeEnabled())', source)
        self.assertIn('ManastormRewards::Instance().IsCoALootMode(player->GetGUID().GetCounter())', source)
        self.assertRegex(source, r'if \(coaLoot && !roll_chance_i\(candidate.CoAChancePct\)\)\s+break;')
        self.assertIn('coaChance > 100', source)


if __name__ == '__main__':
    unittest.main()
