import copy
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))

from tables import TABLES
import sql_reader
import sql_writer

SCHEMA = ROOT / 'data/sql/updates/pending_db_world/rev_20261123_80_coa_pet_battles_schema.sql'
FIXTURE = HERE / 'fixtures' / 'mini_export.json'


def load_fixture():
    return json.loads(FIXTURE.read_text(encoding='utf-8'))


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


class WriterTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.path = Path(self.directory.name)

    def tearDown(self):
        self.directory.cleanup()

    def write(self, export):
        return sql_writer.write(export, self.path, '20261123', 81)

    def data_files(self, paths):
        return [path for path in paths if not path.name.endswith('_standins.sql')]

    def test_files_are_named_in_table_order(self):
        paths = self.write(load_fixture())
        self.assertEqual(len(paths), len(TABLES) + 1)
        self.assertEqual(paths[0].name, 'rev_20261123_81_coa_pet_battles_species.sql')
        self.assertEqual(paths[-1].name, f'rev_20261123_{81 + len(TABLES)}_coa_pet_battles_standins.sql')

    def test_round_trip_equals_export(self):
        export = load_fixture()
        tables = sql_reader.read(self.data_files(self.write(export)))
        self.assertEqual(tables, export['tables'])

    def test_strings_round_trip_exactly(self):
        export = load_fixture()
        names = ["Lil' K.T.", 'a\\b', 'line1\nline2', '|cffffffffHit Chance|r', "Zul'Drak", 'Café', 'quote "x"',
                 'tab\there', 'cr\rhere', 'nul\0here', 'ctrl\x1az']
        export['tables']['coa_pet_state'] = [[index, name] for index, name in enumerate(names)]
        tables = sql_reader.read(self.data_files(self.write(export)))
        self.assertEqual([row[1] for row in tables['coa_pet_state']], names)

    def test_every_insert_is_preceded_by_delete(self):
        for path in self.write(load_fixture()):
            text = path.read_text(encoding='utf-8')
            for match in re.finditer(r'INSERT INTO `(\w+)`', text):
                self.assertIn(f'DELETE FROM `{match.group(1)}`', text[:match.start()], path.name)

    def test_inserts_are_chunked_by_1000(self):
        export = load_fixture()
        export['tables']['coa_pet_display_size'] = [[display, 1.5] for display in range(2500)]
        paths = self.write(export)
        text = next(path for path in paths if path.name.endswith('_display_size.sql')).read_text(encoding='utf-8')
        self.assertEqual(text.count('INSERT INTO `coa_pet_display_size`'), 3)
        self.assertEqual(sql_reader.read(self.data_files(paths))['coa_pet_display_size'],
                         export['tables']['coa_pet_display_size'])

    def test_species_outside_range_is_rejected(self):
        export = load_fixture()
        export['standins']['species'] = [50000]
        with self.assertRaises(ValueError):
            self.write(export)

    def test_row_with_wrong_column_count_is_rejected(self):
        export = load_fixture()
        export['tables']['coa_pet_xp'].append([2, 3])
        with self.assertRaises(ValueError):
            self.write(export)

    def test_unknown_or_missing_table_is_rejected(self):
        export = load_fixture()
        export['tables']['coa_pet_unknown'] = []
        with self.assertRaises(ValueError):
            self.write(export)
        export = load_fixture()
        del export['tables']['coa_pet_xp']
        with self.assertRaises(ValueError):
            self.write(copy.deepcopy(export))

    def test_value_of_another_type_is_rejected(self):
        export = load_fixture()
        export['tables']['coa_pet_xp'][0][1] = True
        with self.assertRaises(ValueError):
            self.write(export)
        export = load_fixture()
        export['tables']['coa_pet_xp'][0][1] = None
        with self.assertRaises(ValueError):
            self.write(export)

    def test_standins_clear_their_whole_range_first(self):
        text = self.write(load_fixture())[-1].read_text(encoding='utf-8')
        statements = [line for line in text.splitlines() if line.strip()]
        self.assertEqual(statements[:3], [
            'DELETE FROM `creature_equip_template` WHERE `CreatureID` BETWEEN 9800000 AND 9849999;',
            'DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 9800000 AND 9849999;',
            'DELETE FROM `creature_template` WHERE `entry` BETWEEN 9800000 AND 9849999;',
        ])

    def test_standins_use_offset_and_level_60(self):
        text = self.write(load_fixture())[-1].read_text(encoding='utf-8')
        self.assertIn('+ 9800000', text)
        self.assertIn("WHEN COLUMN_NAME IN ('minlevel', 'maxlevel') THEN '60'", text)
        self.assertIn("WHEN '9800010-0' THEN 0.49202", text)
        self.assertIn("SET @coa_pet_ids = '10';", text)


if __name__ == '__main__':
    unittest.main()
