import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

from bonus_data import (BASE_DIRECTORY, BASELINE_MANIFEST, BonusRow, BonusTable, BonusTerms, NotModelled,
                        bonus_row, bonus_table, bonus_terms, client_first_ranks, coefficient_modifiers,
                        engine_ap_term, engine_sp_term, level_penalty)
from tooltip import CasterStats

INCLUDES = ("INSERT INTO `updates_include` VALUES ('$/data/sql/archive/db_world','ARCHIVED'),"
            "('$/data/sql/custom/db_world','CUSTOM'),('$/data/sql/updates/db_world','RELEASED'),"
            "('$/data/sql/updates/pending_db_world','PENDING');\n")
BASE_ROWS = ("DROP TABLE IF EXISTS `spell_bonus_data`;\nCREATE TABLE `spell_bonus_data` (`entry` int);\n"
             "LOCK TABLES `spell_bonus_data` WRITE;\n/*!40000 ALTER TABLE `spell_bonus_data` DISABLE KEYS */;\n"
             "INSERT INTO `spell_bonus_data` VALUES (100,0.5,0,0.2,0,'base'),(200,0,0,0,0,'zero');\n"
             "/*!40000 ALTER TABLE `spell_bonus_data` ENABLE KEYS */;\nUNLOCK TABLES;\n")
CASTER = CasterStats(level=60, ap=1000.0, rap=400.0, sp_by_school={5: 300.0}, stats={})


def sha1(text: str) -> str:
    return hashlib.sha1(text.encode('utf-8')).hexdigest().upper()


class World:
    def __init__(self, applied=None):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        base = self.root / BASE_DIRECTORY
        base.mkdir(parents=True)
        (base / 'spell_bonus_data.sql').write_text(BASE_ROWS, encoding='utf-8')
        (base / 'updates_include.sql').write_text(INCLUDES, encoding='utf-8')
        rows = ','.join(f"('{name}','{digest}','RELEASED','2026-01-01 00:00:00',0)"
                        for name, digest in (applied or {}).items())
        (base / 'updates.sql').write_text(f'INSERT INTO `updates` VALUES {rows};\n' if rows else '', encoding='utf-8')

    def update(self, directory: str, name: str, text: str) -> Path:
        path = self.root / directory / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')
        return path

    def table(self) -> BonusTable:
        return bonus_table(self.root)

    def close(self):
        self.directory.cleanup()


class ParserTest(unittest.TestCase):
    def world(self, applied=None) -> World:
        world = World(applied)
        self.addCleanup(world.close)
        return world

    def test_the_base_dump_is_read_with_its_column_order(self):
        table = self.world().table()
        self.assertEqual(table.unreadable, '')
        self.assertEqual(table.rows[100], BonusRow(100, 0.5, 0.0, 0.2, 0.0, str(BASE_DIRECTORY / 'spell_bonus_data.sql')))
        self.assertFalse(table.rows[200].terms)

    def test_delete_then_insert_replays_and_the_last_write_wins(self):
        world = self.world()
        world.update('data/sql/updates/db_world', '2026_01_01_00.sql',
                     'DELETE FROM `spell_bonus_data` WHERE `entry` IN (100, 200);\n'
                     'INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `ap_bonus`) VALUES (100, 0.7, 0.1);\n')
        world.update('data/sql/updates/pending_db_world', 'rev_1.sql',
                     'DELETE FROM `spell_bonus_data` WHERE `entry` = 100;\n'
                     'INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `ap_bonus`) VALUES (100, 1, 0.55);\n')
        table = world.table()
        self.assertEqual((table.rows[100].direct, table.rows[100].ap), (1.0, 0.55))
        self.assertEqual(table.rows[100].source, 'data/sql/updates/pending_db_world/rev_1.sql')
        self.assertNotIn(200, table.rows)

    def test_released_updates_run_before_pending_ones_whatever_their_names(self):
        world = self.world()
        world.update('data/sql/updates/pending_db_world', 'a_pending.sql',
                     "DELETE FROM `spell_bonus_data` WHERE `entry` = 100;\n"
                     "INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`) VALUES (100, 0.9);\n")
        world.update('data/sql/updates/db_world', 'z_released.sql',
                     "DELETE FROM `spell_bonus_data` WHERE `entry` = 100;\n"
                     "INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`) VALUES (100, 0.3);\n")
        self.assertEqual(world.table().rows[100].direct, 0.9)

    def test_an_applied_update_with_its_recorded_hash_is_not_replayed(self):
        text = "DELETE FROM `spell_bonus_data` WHERE `entry` = 100;\n"
        world = self.world({'old.sql': sha1(text)})
        world.update('data/sql/archive/db_world', 'old.sql', text)
        self.assertIn(100, world.table().rows)

    def test_a_changed_applied_update_is_replayed(self):
        text = "DELETE FROM `spell_bonus_data` WHERE `entry` = 100;\n"
        world = self.world({'old.sql': sha1('-- before\n')})
        world.update('data/sql/archive/db_world', 'old.sql', text)
        self.assertNotIn(100, world.table().rows)

    def test_a_replace_statement_makes_the_table_unreadable(self):
        world = self.world()
        world.update('data/sql/updates/pending_db_world', 'rev_2.sql',
                     "REPLACE INTO `spell_bonus_data` VALUES (100, 1, 0, 0, 0, 'x');\n")
        table = world.table()
        self.assertIn('rev_2.sql', table.unreadable)
        self.assertEqual(table.rows, {})

    def test_an_update_statement_or_an_unkeyed_delete_makes_the_table_unreadable(self):
        world = self.world()
        world.update('data/sql/updates/pending_db_world', 'rev_3.sql',
                     'UPDATE `spell_bonus_data` SET `ap_bonus` = 0 WHERE `entry` = 100;\n')
        self.assertIn('outside DELETE and INSERT', world.table().unreadable)
        world = self.world()
        world.update('data/sql/updates/pending_db_world', 'rev_4.sql',
                     'DELETE FROM `spell_bonus_data` WHERE `comments` LIKE "x%";\n')
        self.assertIn('not keyed by entry', world.table().unreadable)

    def test_a_module_world_update_naming_the_table_makes_it_unreadable(self):
        world = self.world()
        world.update('modules/mod-example/data/sql/db-world/nested', 'mod_1.sql',
                     'DELETE FROM `spell_bonus_data` WHERE `entry` = 100;\n')
        world.update('modules/mod-example/data/sql/db-characters', 'mod_2.sql',
                     'DELETE FROM `spell_bonus_data` WHERE `entry` = 200;\n')
        table = world.table()
        self.assertIn('modules/mod-example/data/sql/db-world/nested/mod_1.sql', table.unreadable)

    def test_module_world_directories_are_listed_and_other_databases_are_not(self):
        world = self.world()
        world.update('modules/mod-example/data/sql/db-world', 'mod_1.sql', 'SELECT 1;\n')
        world.update('modules/mod-example/data/sql/db-characters', 'mod_2.sql',
                     'DELETE FROM `spell_bonus_data` WHERE `entry` = 100;\n')
        table = world.table()
        self.assertEqual(table.unreadable, '')
        self.assertIn('modules/mod-example/data/sql/db-world', table.directories)
        self.assertIn(100, table.rows)

    def test_a_duplicate_update_name_makes_the_table_unreadable(self):
        world = self.world()
        world.update('data/sql/updates/db_world', 'same.sql', 'SELECT 1;\n')
        world.update('data/sql/updates/pending_db_world', 'same.sql', 'SELECT 1;\n')
        self.assertIn('duplicate update file name same.sql', world.table().unreadable)

    def test_the_world_baseline_replaces_the_base_dump(self):
        world = self.world()
        archive = world.root / BASELINE_MANIFEST.parent / 'world.zip'
        archive.parent.mkdir(parents=True)
        text = "INSERT INTO `spell_bonus_data` VALUES (300,0,0,0.4,0,'pack');\n"
        with zipfile.ZipFile(archive, 'w') as package:
            package.writestr('spell_bonus_data.sql', text)
            package.writestr('updates.sql', '')
            package.writestr('updates_include.sql', INCLUDES)
        columns = ['entry', 'direct_bonus', 'dot_bonus', 'ap_bonus', 'ap_dot_bonus', 'comments']
        (world.root / BASELINE_MANIFEST).write_text(json.dumps(
            {'archive': 'world.zip', 'tables': {'spell_bonus_data': {'columns': columns}}}), encoding='utf-8')
        table = world.table()
        self.assertEqual(sorted(table.rows), [300])
        self.assertEqual(table.rows[300].source, 'world.zip:spell_bonus_data.sql')


def fields(effect=2, school=32, spell_level=0, max_level=0, **others):
    values = {'Effect[0]': effect, 'SchoolMask': school, 'SpellLevel': spell_level, 'MaxLevel': max_level,
              'SpellFamilyName': 21, 'SpellFamilyFlags[1]': 0, 'EquippedItemSubClassMask': 0, 'Attributes': 0,
              'DmgClass': 1, **others}
    return values.get


ROW = BonusRow(100, 1.0, 0.0, 0.55, 0.0, 'rev.sql')
TABLE = BonusTable({100: ROW})


class TermsTest(unittest.TestCase):
    def terms(self, token='${$m1+0+$AP*0.55+$sps*1}', table=TABLE, field=None, modifiers=()):
        return bonus_terms(table, 100, 0, token, CASTER, field or fields(), list(modifiers))

    def test_a_direct_damage_row_adds_both_terms(self):
        terms = self.terms()
        self.assertIsInstance(terms, BonusTerms)
        self.assertAlmostEqual(terms.ap_term, 550.0, places=3)
        self.assertEqual(terms.sp_term, 300.0)
        self.assertIn('spell_bonus_data 100 (rev.sql)', terms.text())

    def test_each_term_is_truncated_to_int32_as_the_engine_does(self):
        caster = CasterStats(level=60, ap=313.0, rap=0.0, sp_by_school={5: 7.0}, stats={})
        table = BonusTable({100: BonusRow(100, 0.45, 0.0, 0.55, 0.0, 'rev.sql')})
        terms = bonus_terms(table, 100, 0, '${$m1+$AP*0.55+$sps*0.45}', caster, fields(), [])
        self.assertEqual((terms.ap_term, terms.sp_term, terms.total), (172.0, 3.0, 175.0))
        self.assertAlmostEqual(terms.ap_formula, 172.15)
        self.assertAlmostEqual(terms.sp_formula, 3.15)
        self.assertEqual(terms.truncated, 2)
        self.assertIn('terms modelled from spell_bonus_data, not observed', terms.text())
        self.assertIn('= 172.150, int32 172 (Unit.cpp:9885)', terms.text())
        self.assertIn('= 3.150, int32 3 (Unit.cpp:9914)', terms.text())

    def test_an_integral_term_is_not_counted_as_truncated(self):
        terms = self.terms()
        self.assertEqual((terms.ap_term, terms.sp_term, terms.truncated), (550.0, 300.0, 0))
        self.assertEqual(engine_ap_term(0.55, 1000.0), 550)
        self.assertEqual(engine_sp_term(0.45, 20000.0), 9000)
        self.assertEqual(engine_ap_term(0.3, -282.0), -84)

    def test_a_token_without_a_power_term_is_left_alone(self):
        self.assertIsNone(self.terms('$s1'))

    def test_a_zero_row_or_no_row_is_left_alone(self):
        self.assertIsNone(self.terms(table=BonusTable({100: BonusRow(100, 0, 0, 0, 0, 'zero')})))
        self.assertIsNone(self.terms(table=BonusTable({})))

    def test_an_unreadable_table_is_not_modelled(self):
        self.assertIsInstance(self.terms(table=BonusTable({}, 'x.sql: REPLACE')), NotModelled)

    def test_a_periodic_row_or_a_non_damage_effect_is_not_modelled(self):
        periodic = BonusTable({100: BonusRow(100, 0.0, 0.2, 0.0, 0.0, 'dot.sql')})
        self.assertIn('periodic terms', self.terms(table=periodic).reason)
        self.assertIn('not a direct damage effect', self.terms(field=fields(effect=6)).reason)

    def test_a_level_penalty_is_not_modelled(self):
        self.assertLess(level_penalty(10, 30, 60), 1.0)
        self.assertIn('level penalty', self.terms(field=fields(spell_level=10, max_level=30)).reason)
        zero = CasterStats(level=60, ap=1000.0, rap=400.0, sp_by_school={5: 0.0}, stats={})
        terms = bonus_terms(TABLE, 100, 0, '${$m1+$AP*0.55}', zero, fields(spell_level=10, max_level=30), [])
        self.assertEqual(terms.sp_term, 0.0)

    def test_a_coefficient_modifier_of_the_family_is_not_modelled(self):
        self.assertIn('700001', self.terms(modifiers=[(700001, 'sp')]).reason)
        self.assertIn('700002', self.terms(modifiers=[(700002, 'ap')]).reason)

    def test_a_spell_power_modifier_with_no_spell_power_leaves_the_terms(self):
        caster = CasterStats(level=60, ap=1000.0, rap=400.0, sp_by_school={5: 0.0}, stats={})
        terms = bonus_terms(TABLE, 100, 0, '${$m1+$AP*0.55+$sps*1}', caster, fields(), [(700001, 'sp')])
        self.assertAlmostEqual(terms.ap_term, 550.0)
        self.assertEqual(terms.sp_term, 0.0)
        self.assertIsInstance(bonus_terms(TABLE, 100, 0, '${$m1+$AP*0.55}', caster, fields(), [(700002, 'ap')]),
                              NotModelled)

    def test_a_ranged_weapon_spell_outside_melee_reads_ranged_attack_power(self):
        terms = self.terms(field=fields(EquippedItemSubClassMask=1 << 18))
        self.assertEqual((terms.power, terms.attack_power), ('RAP', 400.0))
        self.assertEqual(self.terms(field=fields(EquippedItemSubClassMask=1 << 18, DmgClass=2)).power, 'AP')


def spell_rank_dbc(records, fields=4, size=16) -> bytes:
    body = b''.join(struct.pack('<4I', *record) for record in records)
    return struct.pack('<4s4I', b'WDBC', len(records), fields, size, 1) + body + b'\0'


class FirstRankTest(unittest.TestCase):
    KNOWN = frozenset({100, 101, 102, 200, 201, 300, 301, 400, 500, 501})

    def test_each_rank_of_a_client_chain_maps_to_the_chains_rank_one_spell(self):
        data = spell_rank_dbc([(1, 100, 100, 1), (2, 100, 102, 3), (3, 100, 101, 2)])
        self.assertEqual(client_first_ranks(data, self.KNOWN), {100: 100, 101: 100, 102: 100})

    def test_an_out_of_order_chain_a_missing_spell_or_a_single_rank_is_skipped(self):
        data = spell_rank_dbc([(1, 200, 200, 1), (2, 200, 201, 3), (3, 300, 300, 1), (4, 300, 302, 2),
                               (5, 400, 400, 1), (6, 500, 500, 1), (7, 500, 501, 2)])
        self.assertEqual(client_first_ranks(data, self.KNOWN), {500: 500, 501: 500})

    def test_a_table_of_another_layout_is_refused(self):
        with self.assertRaises(ValueError):
            client_first_ranks(spell_rank_dbc([(1, 100, 100, 1)], fields=3, size=12), self.KNOWN)

    def test_a_rank_without_its_own_row_resolves_to_its_first_ranks_row(self):
        table = BonusTable({100: ROW})
        self.assertIs(bonus_row(table, 101, 100), ROW)
        self.assertIsNone(bonus_row(table, 101))
        own = BonusRow(101, 0.0, 0.0, 0.3, 0.0, 'own.sql')
        self.assertIs(bonus_row(BonusTable({100: ROW, 101: own}), 101, 100), own)

    def test_the_inherited_terms_name_the_rank_and_the_engine_lookup(self):
        terms = bonus_terms(TABLE, 101, 0, '${$m1+0+$AP*0.55}', CASTER, fields(), [], 100)
        self.assertAlmostEqual(terms.ap_term, 550.0, places=3)
        self.assertIn('spell_bonus_data 100 (rev.sql), the first rank of 101', terms.text())
        self.assertIn('SpellMgr.cpp:1010-1016', terms.text())
        self.assertEqual(terms.detail()['first_rank_of'], 101)
        self.assertNotIn('first_rank_of', bonus_terms(TABLE, 100, 0, '${$m1+0+$AP*0.55}', CASTER, fields(),
                                                     []).detail())


class FakeRecords:
    def __init__(self, values):
        self.values = values

    def field(self, table, spell, name):
        return self.values.get((spell, name), 0)


class ModifiersTest(unittest.TestCase):
    def test_masked_coefficient_spellmods_and_scripts_are_found(self):
        family = {100: ('Target', (0, 0, 4)), 1: ('Mod', (0, 0, 0)), 2: ('Script', (0, 0, 0)),
                  3: ('Other mask', (0, 0, 0)), 4: ('Damage mod', (0, 0, 0))}
        records = FakeRecords({(1, 'EffectApplyAuraName[0]'): 108, (1, 'EffectMiscValue[0]'): 24,
                               (1, 'EffectSpellClassMask[2]'): 4,
                               (2, 'EffectApplyAuraName[1]'): 112, (2, 'EffectMiscValue[1]'): 20041,
                               (2, 'EffectSpellClassMask[5]'): 4,
                               (3, 'EffectApplyAuraName[0]'): 107, (3, 'EffectMiscValue[0]'): 41,
                               (3, 'EffectSpellClassMask[2]'): 8,
                               (4, 'EffectApplyAuraName[0]'): 108, (4, 'EffectMiscValue[0]'): 0})
        self.assertEqual(coefficient_modifiers(records, family, 100), [(1, 'sp'), (2, 'sp')])


if __name__ == '__main__':
    unittest.main()
