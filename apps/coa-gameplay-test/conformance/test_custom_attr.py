from pathlib import Path
import tempfile
import unittest

from bonus_data import BASE_DIRECTORY
from custom_attr import custom_attributes
from mitigation import SPELL_ATTR0_CU_IGNORE_ARMOR
from test_bonus_data import INCLUDES

STAKE_RANKS = (680537, 681347, 681348, 681349, 681350, 681351, 681352)
BASE_ROWS = ("DROP TABLE IF EXISTS `spell_custom_attr`;\nCREATE TABLE `spell_custom_attr` (`spell_id` int);\n"
             "INSERT INTO `spell_custom_attr` VALUES (100,64),(200,32768);\n")
PENDING = 'data/sql/updates/pending_db_world'


class World:
    def __init__(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        base = self.root / BASE_DIRECTORY
        base.mkdir(parents=True)
        (base / 'spell_custom_attr.sql').write_text(BASE_ROWS, encoding='utf-8')
        (base / 'updates_include.sql').write_text(INCLUDES, encoding='utf-8')
        (base / 'updates.sql').write_text('', encoding='utf-8')

    def update(self, name: str, text: str):
        path = self.root / PENDING / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')

    def close(self):
        self.directory.cleanup()


class CustomAttributesTest(unittest.TestCase):
    def world(self) -> World:
        world = World()
        self.addCleanup(world.close)
        return world

    def test_the_base_dump_and_a_pending_delete_insert_are_replayed(self):
        world = self.world()
        world.update('rev_1.sql', "DELETE FROM `spell_custom_attr` WHERE (`spell_id` IN (100));\n"
                                  "INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES (100, 32768);\n")
        table = custom_attributes(world.root)
        self.assertEqual(table.unreadable, '')
        self.assertEqual(table.rows, {100: 32768, 200: 32768})
        self.assertEqual(table.sources[100], f'{PENDING}/rev_1.sql')
        self.assertEqual(table.of(300), 0)

    def test_a_bit_update_is_replayed_as_the_engine_reads_the_row(self):
        world = self.world()
        world.update('rev_2.sql', "UPDATE `spell_custom_attr` SET `attributes` = `attributes` | 0x8000 "
                                  "WHERE `spell_id` = 100;\nUPDATE `spell_custom_attr` SET `attributes` = "
                                  "`attributes` & ~(32768) WHERE `spell_id` = 200;\n")
        self.assertEqual(custom_attributes(world.root).rows, {100: 32832, 200: 0})

    def test_an_unmodelled_statement_makes_the_table_unreadable(self):
        world = self.world()
        world.update('rev_3.sql', "REPLACE INTO `spell_custom_attr` VALUES (100, 0);\n")
        table = custom_attributes(world.root)
        self.assertIn('rev_3.sql', table.unreadable)
        self.assertEqual(table.rows, {})

    def test_the_repository_world_gives_every_stake_rank_the_ignore_armor_bit(self):
        table = custom_attributes()
        self.assertEqual(table.unreadable, '')
        for rank in STAKE_RANKS:
            self.assertTrue(table.of(rank) & SPELL_ATTR0_CU_IGNORE_ARMOR, rank)


if __name__ == '__main__':
    unittest.main()
