from pathlib import Path
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parents[3]


class CriteriaRepairTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.execute('CREATE TABLE achievement_criteria_data '
                        '(criteria_id, type, value1, value2, ScriptName, PRIMARY KEY(criteria_id, type))')
        self.sql = (ROOT / 'data/sql/updates/pending_db_world/rev_20261029_03_culling_achievement_criteria.sql') \
            .read_text(encoding='utf-8').replace('INSERT IGNORE', 'INSERT OR IGNORE')

    def tearDown(self):
        self.db.close()

    def test_missing_filters_copy_only_matching_siblings_and_replay_safely(self):
        self.db.executemany('INSERT INTO achievement_criteria_data VALUES (?, ?, ?, ?, ?)',
                            [(211, 12, 0, 0, ''), (6805, 12, 1, 0, '')])
        self.db.executescript(self.sql)
        self.db.executescript(self.sql)
        actual = self.db.execute('SELECT * FROM achievement_criteria_data WHERE criteria_id IN (202, 6801) '
                                 'ORDER BY criteria_id').fetchall()
        self.assertEqual(actual, [(202, 12, 0, 0, ''), (6801, 12, 1, 0, '')])

    def test_existing_criterion_rows_are_preserved_without_adding_filters(self):
        existing = [(202, 0, 3, 4, 'custom'), (6801, 1, 5, 6, 'other')]
        self.db.executemany('INSERT INTO achievement_criteria_data VALUES (?, ?, ?, ?, ?)',
                            existing + [(211, 12, 0, 0, ''), (6805, 12, 1, 0, '')])
        self.db.executescript(self.sql)
        actual = self.db.execute('SELECT * FROM achievement_criteria_data WHERE criteria_id IN (202, 6801) '
                                 'ORDER BY criteria_id').fetchall()
        self.assertEqual(actual, existing)

    def test_missing_or_wrong_difficulty_siblings_do_not_invent_filters(self):
        self.db.execute("INSERT INTO achievement_criteria_data VALUES (211, 12, 1, 0, '')")
        self.db.executescript(self.sql)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM achievement_criteria_data '
                                         'WHERE criteria_id IN (202, 6801)').fetchone(), (0,))


if __name__ == '__main__':
    unittest.main()
