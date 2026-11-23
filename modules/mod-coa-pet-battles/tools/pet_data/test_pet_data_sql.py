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

    TEMPLATE_COLUMNS = ['entry', 'name', 'minlevel', 'maxlevel', 'faction', 'npcflag', 'type', 'AIName',
                        'ScriptName', 'VerifiedBuild']

    def write(self, export):
        return sql_writer.write(export, self.path, '20261123', 81, self.TEMPLATE_COLUMNS)

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

    def test_every_insert_directly_follows_its_delete_or_upserts(self):
        for path in self.write(load_fixture()):
            statements = [statement.strip() for statement in
                          re.split(r";\n", re.sub(r"'(?:\\.|[^'\\])*'", "''", path.read_text(encoding='utf-8')))]
            for previous, statement in zip([''] + statements, statements):
                insert = re.match(r'INSERT INTO `(\w+)`', statement)
                if insert and 'ON DUPLICATE KEY UPDATE' not in statement:
                    self.assertTrue(previous.startswith(f'DELETE FROM `{insert.group(1)}`'), path.name)

    def test_each_table_is_one_delete_then_one_insert(self):
        export = load_fixture()
        export['tables']['coa_pet_display_size'] = [[display, 1.5] for display in range(2500)]
        paths = self.write(export)
        text = next(path for path in paths if path.name.endswith('_display_size.sql')).read_text(encoding='utf-8')
        self.assertEqual(text.count('INSERT INTO `coa_pet_display_size`'), 1)
        self.assertTrue(text.startswith('DELETE FROM `coa_pet_display_size`;\nINSERT INTO `coa_pet_display_size`'))
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

    def test_standins_never_delete_creature_templates(self):
        text = self.write(load_fixture())[-1].read_text(encoding='utf-8')
        self.assertNotIn('DELETE FROM `creature_template`', text)
        self.assertIn('ON DUPLICATE KEY UPDATE', text)

    def test_standin_models_and_equipment_clear_their_range_right_before_insert(self):
        lines = self.write(load_fixture())[-1].read_text(encoding='utf-8').splitlines()
        for table in ('creature_template_model', 'creature_equip_template'):
            insert = next(index for index, line in enumerate(lines) if line.startswith(f'INSERT INTO `{table}`'))
            self.assertEqual(lines[insert - 1],
                             f'DELETE FROM `{table}` WHERE `CreatureID` BETWEEN 9800000 AND 9849999;')

    def test_standins_use_offset_and_level_60(self):
        text = self.write(load_fixture())[-1].read_text(encoding='utf-8')
        for expected in ('`src`.`entry` + 9800000 AS `entry`', '60 AS `minlevel`', '60 AS `maxlevel`',
                         '35 AS `faction`', 'IF(`src`.`type` = 12, 1, `src`.`type`) AS `type`', '0 AS `npcflag`',
                         "'' AS `AIName`", "'' AS `ScriptName`", '`src`.`name` AS `name`',
                         'WHERE `src`.`entry` IN (10)) AS `coa_new`',
                         'UPDATE `creature_template_model` SET `DisplayScale` = 0.49202 '
                         'WHERE `CreatureID` = 9800010 AND `Idx` = 0;'):
            self.assertIn(expected, text)
        update = next(line for line in text.splitlines() if line.startswith('ON DUPLICATE KEY UPDATE'))
        self.assertNotIn('`entry` =', update)
        self.assertIn('`faction` = `coa_new`.`faction`', update)

    def test_template_columns_come_from_the_base_schema(self):
        columns = sql_writer.creature_template_columns(ROOT / 'data/sql/base/db_world/creature_template.sql')
        self.assertEqual(columns[0], 'entry')
        self.assertIn('CreatureImmunitiesId', columns)
        self.assertNotIn('scale', columns)
        self.assertEqual(len(columns), len(set(columns)))

if __name__ == '__main__':
    unittest.main()
