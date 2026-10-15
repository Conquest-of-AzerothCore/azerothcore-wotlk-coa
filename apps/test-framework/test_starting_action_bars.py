"""Exercise custom-class starting action bars on disposable MySQL.

Usage: python apps/test-framework/test_starting_action_bars.py --mysql-bin /path/to/mysql/bin
Reuses the isolated named-pipe/socket fixture; no live database or worldserver is accessed.
"""

import argparse
import json
from pathlib import Path
import unittest
import zipfile

import test_enchantment_migrations as isolated_mysql


ROOT = Path(__file__).resolve().parents[2]
PENDING = ROOT / "data/sql/updates/pending_db_world"
ORIGINAL = PENDING / "rev_20260917_30_custom_class_starting_action_bars.sql"
MIGRATION = PENDING / "rev_20260920_00_custom_class_starting_action_bars.sql"
TABLES = ("playercreateinfo", "playercreateinfo_action", "ascension_custom_class_race")


class StartingActionBarTests(unittest.TestCase):
    mysql_bin = None

    @classmethod
    def setUpClass(cls):
        cls.database = isolated_mysql.EnchantmentMigrations
        cls.database.mysql_bin = cls.mysql_bin
        cls.addClassCleanup(cls.database.doClassCleanups)
        cls.database.setUpClass()
        cls.database.query("CREATE DATABASE action_bar_seed; CREATE DATABASE action_bar_test;", database=None)
        directory = ROOT / "data/coa-world"
        manifest = json.loads((directory / "baseline.json").read_text(encoding="utf-8"))
        with zipfile.ZipFile(directory / manifest["archive"]) as archive:
            for table in TABLES:
                cls.database.query(archive.read(table + ".sql").decode("utf-8"), database="action_bar_seed")
        cls.database.query(ORIGINAL.read_text(encoding="utf-8"), database="action_bar_seed")
        # The original fix defines the accepted spell layout, but only for its old whitelist.
        cls.layouts = {}
        for class_id, button, action, kind in cls.database.query(
                "SELECT DISTINCT class,button,action,type FROM playercreateinfo_action "
                "WHERE class BETWEEN 12 AND 32 AND button BETWEEN 0 AND 4 ORDER BY class,button;",
                database="action_bar_seed"):
            cls.layouts.setdefault(int(class_id), []).append(tuple(map(int, (button, action, kind))))

    def query(self, sql):
        return self.database.query(sql, database="action_bar_test")

    def setUp(self):
        for table in TABLES:
            self.query(f"DROP TABLE IF EXISTS `{table}`; "
                       f"CREATE TABLE `{table}` LIKE `action_bar_seed`.`{table}`; "
                       f"INSERT INTO `{table}` SELECT * FROM `action_bar_seed`.`{table}`;")

    def rows(self):
        return [tuple(map(int, row)) for row in self.query(
            "SELECT race,class,button,action,type FROM playercreateinfo_action ORDER BY race,class,button;")]

    def apply(self):
        self.query(MIGRATION.read_text(encoding="utf-8"))

    def test_all_supported_pairs_receive_the_original_layout(self):
        pairs = [tuple(map(int, row)) for row in self.query(
            "SELECT race,class FROM playercreateinfo WHERE class BETWEEN 12 AND 32 ORDER BY race,class;")]
        self.assertEqual(len(pairs), 210)
        self.assertEqual(sum(len(layout) for layout in self.layouts.values()), 71)
        before = self.rows()
        covered = {(race, class_id) for race, class_id, button, _, _ in before if 1 <= button <= 4}
        missing = set(pairs) - covered
        self.assertEqual(len(missing), 86)
        # Templar is class 19: Orc, Night Elf, Tauren, Gnome and Troll were omitted.
        self.assertEqual({race for race, class_id in missing if class_id == 19}, {2, 4, 6, 7, 8})
        self.assertEqual(self.layouts[19], [(0, 6603, 0), (1, 801443, 0), (2, 803157, 0)])
        self.apply()
        expected = [(race, class_id, *entry) for race, class_id in pairs for entry in self.layouts[class_id]]
        actual = [row for row in self.rows() if 12 <= row[1] <= 32 and 0 <= row[2] <= 4]
        self.assertEqual(actual, expected)
        self.assertEqual(len(actual), 710)

    def test_replay_preserves_legacy_classes_and_other_buttons(self):
        self.query("INSERT INTO playercreateinfo_action (race,class,button,action,type) VALUES "
                   "(6,19,60,6948,128), (1,33,1,6603,0);")
        before = self.rows()
        unaffected = [row for row in before if not (12 <= row[1] <= 32 and 0 <= row[2] <= 4)]
        creation = self.query("SELECT * FROM playercreateinfo ORDER BY race,class;")
        self.apply()
        after = self.rows()
        self.assertEqual(unaffected, [row for row in after if not (12 <= row[1] <= 32 and 0 <= row[2] <= 4)])
        self.assertEqual(creation, self.query("SELECT * FROM playercreateinfo ORDER BY race,class;"))
        self.apply()
        self.assertEqual(after, self.rows())
        # Updates run in filename order, including fresh installs where #3977 still has to run.
        self.assertGreater(MIGRATION.name, ORIGINAL.name)

    def test_actual_availability_does_not_depend_on_the_old_whitelist(self):
        self.query("DELETE FROM playercreateinfo WHERE race=1 AND class=19; "
                   "DROP TABLE ascension_custom_class_race;")
        self.apply()
        self.assertEqual([], self.query("SELECT * FROM playercreateinfo_action WHERE race=1 AND class=19;"))
        self.assertEqual([("0", "6603"), ("1", "801443"), ("2", "803157")], self.query(
            "SELECT button,action FROM playercreateinfo_action WHERE race=6 AND class=19 ORDER BY button;"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mysql-bin", required=True, type=Path)
    args, remaining = parser.parse_known_args()
    StartingActionBarTests.mysql_bin = args.mysql_bin.resolve()
    unittest.main(argv=[__file__, *remaining], verbosity=2)
