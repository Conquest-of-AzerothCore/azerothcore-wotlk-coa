"""Test complete new-creature cohorts using the repository's disposable MySQL lifecycle.

Usage: python apps/test-framework/test_coa_creature_migrations.py --mysql-bin /path/to/mysql/bin
Add --before-ref <commit> to prove the named new-creature assertions fail before the migration exists.
"""
import argparse
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
PENDING = ROOT / 'data/sql/updates/pending_db_world'
MIGRATION = PENDING / 'rev_1789088238898143200.sql'
from coa_mysql_fixture import CreatureMySQLFixture, PROCESS_OPTIONS

TABLES = [
    'creature_template', 'creature_template_model', 'creature_template_spell',
    'creature_template_addon', 'creature_template_resistance', 'creature_template_movement',
    'creature_equip_template', 'creature_text', 'creature_text_locale', 'smart_scripts',
    'conditions', 'creature_loot_template', 'quest_template', 'creature_template_locale',
    'creature_onkill_reputation', 'creature_questitem', 'creature_summon_groups',
    'creature_queststarter', 'creature_questender', 'game_event_creature_quest',
    'npc_vendor', 'npc_spellclick_spells', 'creature_default_trainer',
    'vehicle_template_accessory', 'creature', 'creature_multispawn', 'script_waypoint',
]

class CreatureMigrations(CreatureMySQLFixture, unittest.TestCase):
    mysql_bin = None
    before_ref = None

    @classmethod
    def setUpClass(cls):
        cls.start_mysql()
        cls.query("CREATE DATABASE `creature_test`;", database=None)
        item_sql = (ROOT/'data/sql/base/db_world/item_template.sql').read_text(encoding='utf8')
        cls.query(re.search(r'CREATE TABLE `item_template` \(.*?\) ENGINE=.*?;', item_sql, re.S).group(0))
        # Use schema from the repository; source data stays outside the test artifact.
        for table in TABLES:
            if table == 'creature_multispawn':
                continue
            text = (ROOT/'data/sql/base/db_world'/(table+'.sql')).read_text(encoding='utf8')
            ddl = re.search(r'CREATE TABLE `'+table+r'` \(.*?\) ENGINE=.*?;',text,re.S).group(0)
            cls.query(ddl)
        # The base dump predates the current multispawn schema. Apply its checked-in update so
        # the fixture exercises the same creature.id namespace as current source.
        update = (ROOT/'data/sql/updates/db_world/2026_06_16_00.sql').read_text(encoding='utf8')
        cls.query(update)

        # Supply synthetic, non-quest item fixtures for every staged reference. The migration itself
        # still executes unmodified in each test; no archived item content is embedded in the test.
        migration = MIGRATION.read_text(encoding='utf8')
        prefix = migration[:migration.index('CREATE TEMPORARY TABLE `_coa_tw_new`')]
        stage = re.search(r'CREATE TEMPORARY TABLE `([^`]+)` LIKE `creature_loot_template`;', prefix).group(1)
        cls.query(prefix + f'INSERT INTO `item_template` (`entry`) SELECT DISTINCT `Item` FROM `{stage}`; COMMIT;')
        cls.cabal_item = int(cls.query(prefix + f'SELECT `Item` FROM `{stage}` WHERE `Entry`=15 LIMIT 1;')[0][0])
        ai_stage = re.search(r'CREATE TEMPORARY TABLE `([^`]+)` LIKE `smart_scripts`;', prefix).group(1)
        tal = cls.query(prefix + f'SELECT `_owner`,`entryorguid` FROM `{ai_stage}` WHERE `source_type`=9 LIMIT 1;')
        cls.tal_owner, cls.tal_id = map(int, tal[0])

    def setUp(self):
        for table in TABLES:
            self.query(f'TRUNCATE TABLE `{table}`;')
        self.query("INSERT INTO `creature_template` (`entry`,`name`,`faction`,`unit_class`,`lootid`) "
                   "VALUES (42,'Unrelated creature',35,1,42);")
        self.query("INSERT INTO `creature_loot_template` (`Entry`,`Item`,`Chance`,`MinCount`,`MaxCount`,`Comment`) "
                   "VALUES (42,118,37,2,4,'Operator loot');")

    def apply(self):
        sql = MIGRATION.read_text(encoding='utf8')
        if self.before_ref:
            r = subprocess.run(['git','show',self.before_ref+':'+MIGRATION.relative_to(ROOT).as_posix()],
                               cwd=ROOT,text=True,encoding='utf8',capture_output=True,**PROCESS_OPTIONS)
            sql = r.stdout if r.returncode == 0 else '-- Migration absent at requested baseline.'
        self.query(sql)

    def snapshot(self):
        return {t:sorted(self.query(f'SELECT * FROM `{t}`;')) for t in TABLES}

    def test_full_migration_and_repeat_preserve_existing_rows(self):
        existing = self.snapshot()
        self.apply()
        self.assertEqual([('15','Cabal Cultist','70','70','16','1','15','-12341')], self.query(
            'SELECT `entry`,`name`,`minlevel`,`maxlevel`,`faction`,`unit_class`,`lootid`,`VerifiedBuild` '
            'FROM `creature_template` WHERE `entry`=15;'))
        self.assertTrue(self.query('SELECT `CreatureID` FROM `creature_template_model` WHERE `CreatureID`=15;'))
        for table, rows in existing.items():
            self.assertTrue(set(rows).issubset(set(self.query(f'SELECT * FROM `{table}`;'))), table)
        after = self.snapshot()
        self.apply()
        self.assertEqual(after,self.snapshot())
        self.query("UPDATE `creature_template` SET `name`='Operator correction' WHERE `entry`=15;")
        edited = self.snapshot()
        self.apply()
        self.assertEqual(edited,self.snapshot())

    def test_existing_creature_blocks_every_child(self):
        self.query("INSERT INTO `creature_template` (`entry`,`name`,`faction`,`unit_class`) "
                   "VALUES (15,'Existing distinct creature',35,1);")
        self.apply()
        self.assertEqual([('Existing distinct creature',)], self.query(
            'SELECT `name` FROM `creature_template` WHERE `entry`=15;'))
        self.assertEqual([],self.query('SELECT * FROM `creature_template_model` WHERE `CreatureID`=15;'))
        self.assertEqual([],self.query('SELECT * FROM `creature_loot_template` WHERE `Entry`=15;'))
        self.assertEqual([],self.query('SELECT * FROM `smart_scripts` WHERE `entryorguid`=15 AND `source_type`=0;'))

    def test_orphan_child_blocks_entire_cohort(self):
        self.query('INSERT INTO `creature_template_spell` (`CreatureID`,`Index`,`Spell`) VALUES (15,0,744);')
        self.apply()
        self.assertEqual([],self.query('SELECT * FROM `creature_template` WHERE `entry`=15;'))
        self.assertEqual([('744',)],self.query('SELECT `Spell` FROM `creature_template_spell` WHERE `CreatureID`=15;'))
        self.assertEqual([],self.query('SELECT * FROM `creature_template_model` WHERE `CreatureID`=15;'))

    def test_unstaged_template_owned_rows_block_each_complete_cohort(self):
        cases = [
            (15, "INSERT INTO `creature_template_locale` (`entry`,`locale`) VALUES (15,'frFR');",
             'SELECT `entry` FROM `creature_template_locale` WHERE `entry`=15;'),
            (16, 'INSERT INTO `creature_onkill_reputation` (`creature_id`) VALUES (16);',
             'SELECT `creature_id` FROM `creature_onkill_reputation` WHERE `creature_id`=16;'),
            (17, 'INSERT INTO `creature_questitem` (`CreatureEntry`,`Idx`,`ItemId`) VALUES (17,0,118);',
             'SELECT `CreatureEntry` FROM `creature_questitem` WHERE `CreatureEntry`=17;'),
            (18, 'INSERT INTO `creature_summon_groups` (`summonerId`,`summonerType`,`entry`) '
                 'VALUES (18,0,42);',
             'SELECT `summonerId` FROM `creature_summon_groups` WHERE `summonerId`=18;'),
            (20, 'INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (20,123);',
             'SELECT `id` FROM `creature_queststarter` WHERE `id`=20;'),
            (21, 'INSERT INTO `creature_questender` (`id`,`quest`) VALUES (21,123);',
             'SELECT `id` FROM `creature_questender` WHERE `id`=21;'),
            (22, 'INSERT INTO `game_event_creature_quest` (`eventEntry`,`id`,`quest`) VALUES (1,22,123);',
             'SELECT `id` FROM `game_event_creature_quest` WHERE `id`=22;'),
            (23, 'INSERT INTO `npc_vendor` (`entry`,`item`) VALUES (23,118);',
             'SELECT `entry` FROM `npc_vendor` WHERE `entry`=23;'),
            (24, 'INSERT INTO `npc_spellclick_spells` (`npc_entry`,`spell_id`,`cast_flags`) '
                 'VALUES (24,744,0);',
             'SELECT `npc_entry` FROM `npc_spellclick_spells` WHERE `npc_entry`=24;'),
            (27, 'INSERT INTO `creature_default_trainer` (`CreatureId`,`TrainerId`) VALUES (27,0);',
             'SELECT `CreatureId` FROM `creature_default_trainer` WHERE `CreatureId`=27;'),
            (10511, 'INSERT INTO `vehicle_template_accessory` '
                    '(`entry`,`accessory_entry`,`seat_id`,`description`) '
                    "VALUES (10511,42,0,'Synthetic orphan');",
             'SELECT `entry` FROM `vehicle_template_accessory` WHERE `entry`=10511;'),
            (10512, 'INSERT INTO `creature` (`guid`,`id`) VALUES (900001,10512);',
             'SELECT `id` FROM `creature` WHERE `guid`=900001;'),
            (40553, 'INSERT INTO `creature_multispawn` (`spawnId`,`entry`) VALUES (900002,40553);',
             'SELECT `entry` FROM `creature_multispawn` WHERE `spawnId`=900002;'),
            (40554, 'INSERT INTO `script_waypoint` (`entry`,`pointid`) VALUES (40554,0);',
             'SELECT `entry` FROM `script_waypoint` WHERE `entry`=40554;'),
        ]
        self.query('INSERT INTO `creature` (`guid`,`id`) VALUES (900002,42);')
        for _, insert, _ in cases:
            self.query(insert)

        self.apply()

        for entry, _, preserved in cases:
            with self.subTest(entry=entry):
                self.assertEqual([], self.query(
                    f'SELECT `entry` FROM `creature_template` WHERE `entry`={entry};'))
                self.assertTrue(self.query(preserved))

    def test_gameobject_summon_group_id_does_not_block_creature_entry(self):
        self.query('INSERT INTO `creature_summon_groups` (`summonerId`,`summonerType`,`entry`) '
                   'VALUES (15,1,42);')

        self.apply()

        self.assertTrue(self.query('SELECT `entry` FROM `creature_template` WHERE `entry`=15;'))
        self.assertTrue(self.query(
            'SELECT `summonerId` FROM `creature_summon_groups` '
            'WHERE `summonerId`=15 AND `summonerType`=1;'))

    def test_shared_loot_owner_blocks_new_creature(self):
        self.query('UPDATE `creature_template` SET `lootid`=15 WHERE `entry`=42;')
        self.apply()
        self.assertEqual([],self.query('SELECT * FROM `creature_template` WHERE `entry`=15;'))
        self.assertEqual([],self.query('SELECT * FROM `creature_loot_template` WHERE `Entry`=15;'))

    def test_missing_or_newly_quest_sensitive_item_blocks_complete_cohort(self):
        for mode in ('missing', 'bonding', 'quest', 'late_quest_field', 'duplicate_quest_fields'):
            with self.subTest(mode=mode):
                self.setUp()
                try:
                    if mode == 'missing':
                        self.query(f'DELETE FROM `item_template` WHERE `entry`={self.cabal_item};')
                    elif mode == 'bonding':
                        self.query(f'UPDATE `item_template` SET `Bonding`=4 WHERE `entry`={self.cabal_item};')
                    elif mode == 'quest':
                        self.query('INSERT INTO `quest_template` (`ID`,`RequiredItemId1`) '
                                   f'VALUES (123,{self.cabal_item});')
                    elif mode == 'late_quest_field':
                        self.query('INSERT INTO `quest_template` (`ID`,`ItemDrop4`) '
                                   f'VALUES (123,{self.cabal_item});')
                    else:
                        self.query('INSERT INTO `quest_template` (`ID`,`RequiredItemId6`,`ItemDrop4`) '
                                   f'VALUES (123,{self.cabal_item},{self.cabal_item});')
                    self.apply()
                    self.assertEqual([], self.query('SELECT `entry` FROM `creature_template` WHERE `entry`=15;'))
                    self.assertEqual([], self.query('SELECT `Item` FROM `creature_loot_template` WHERE `Entry`=15;'))
                finally:
                    self.query(f'INSERT IGNORE INTO `item_template` (`entry`) VALUES ({self.cabal_item});')
                    self.query(f'UPDATE `item_template` SET `Bonding`=0 WHERE `entry`={self.cabal_item};')

    def test_existing_timed_action_condition_blocks_whole_owner(self):
        self.query('INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`, '
                   '`ConditionTypeOrReference`,`ConditionValue1`) '
                   f'VALUES (22,1,{self.tal_id},9,1,744);')
        self.apply()
        self.assertEqual([], self.query(f'SELECT `entry` FROM `creature_template` WHERE `entry`={self.tal_owner};'))
        self.assertEqual([], self.query(f'SELECT `entryorguid` FROM `smart_scripts` '
                                        f'WHERE `entryorguid`={self.tal_id} AND `source_type`=9;'))
        self.assertEqual([('744',)], self.query('SELECT `ConditionValue1` FROM `conditions` '
                                               f'WHERE `SourceEntry`={self.tal_id} AND `SourceId`=9;'))

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mysql-bin',type=Path,required=True)
    parser.add_argument('--before-ref')
    args,remaining=parser.parse_known_args()
    CreatureMigrations.mysql_bin=args.mysql_bin.resolve()
    CreatureMigrations.before_ref=args.before_ref
    unittest.main(argv=[__file__]+remaining)