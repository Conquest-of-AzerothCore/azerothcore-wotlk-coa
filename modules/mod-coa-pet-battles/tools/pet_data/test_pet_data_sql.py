import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))

from tables import TABLES

SCHEMA = ROOT / 'data/sql/updates/pending_db_world/rev_20261123_80_coa_pet_battles_schema.sql'


def schema_columns(text):
    tables = {}
    for name, body in re.findall(r'CREATE TABLE `(\w+)` \((.*?)\) ENGINE=InnoDB', text, re.S):
        tables[name] = re.findall(r'^\s*`(\w+)`\s', body, re.M)
    return tables


class SchemaTest(unittest.TestCase):
    def test_schema_matches_tables(self):
        tables = schema_columns(SCHEMA.read_text(encoding='utf-8'))
        self.assertEqual(list(tables), list(TABLES))
        for name, columns in TABLES.items():
            self.assertEqual(tables[name], columns, name)


if __name__ == '__main__':
    unittest.main()
