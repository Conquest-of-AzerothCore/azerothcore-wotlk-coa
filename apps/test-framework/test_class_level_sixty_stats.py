"""Exercise the level-60 Ascension class stat migration on a disposable MySQL instance.

Usage: python apps/test-framework/test_class_level_sixty_stats.py --mysql-bin /path/to/mysql/bin
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
PROGRESSION = PENDING / "rev_20260912_00_custom_class_stat_progression.sql"
MIGRATION = PENDING / "rev_20261105_95_coa_class_level_sixty_stats.sql"
TABLES = ("player_class_stats", "player_race_stats", "ascension_custom_class")
RACES = (1, 2, 3, 4, 5, 6, 7, 8, 10, 11)
ZERO_MANA_CLASSES = (12, 14, 17, 18, 19, 20, 21, 30)
BISBEARD_HUMAN_LEVEL_SIXTY = {
    12: (3752, 0, 99, 98, 90, 51, 67),
    13: (3128, 1538, 54, 82, 86, 79, 106),
    14: (3440, 0, 68, 93, 93, 75, 78),
    15: (3440, 2064, 75, 94, 91, 71, 75),
    16: (2925, 1456, 55, 57, 73, 119, 103),
    17: (4220, 0, 117, 69, 99, 66, 55),
    18: (3752, 0, 99, 76, 112, 59, 62),
    19: (4220, 0, 83, 92, 96, 63, 72),
    20: (3385, 0, 71, 75, 102, 73, 87),
    21: (2972, 0, 80, 110, 91, 65, 60),
    22: (3307, 1651, 54, 61, 74, 105, 115),
    23: (3463, 1648, 69, 50, 91, 109, 91),
    24: (2956, 1456, 51, 63, 78, 109, 108),
    25: (3502, 1814, 92, 66, 99, 78, 72),
    26: (3151, 1824, 82, 71, 92, 104, 57),
    27: (3463, 1814, 94, 55, 97, 80, 84),
    28: (3229, 1824, 74, 94, 87, 91, 59),
    29: (2995, 1824, 63, 78, 86, 91, 90),
    30: (4196, 0, 95, 70, 100, 67, 76),
    31: (3697, 1824, 89, 73, 90, 86, 67),
    32: (2917, 1361, 60, 88, 87, 96, 75),
}
BISBEARD_RACE_CLASS_LEVEL_SIXTY = {
    (2, 12): (106, 101, 98, 47, 60),
    (6, 17): (127, 66, 110, 61, 52),
    (7, 16): (52, 60, 70, 127, 100),
    (11, 32): (62, 86, 92, 96, 71),
    (10, 32): (58, 92, 90, 102, 68),
}


class ClassLevelSixtyStatsTests(unittest.TestCase):
    mysql_bin = None

    @classmethod
    def setUpClass(cls):
        cls.database = isolated_mysql.EnchantmentMigrations
        cls.database.mysql_bin = cls.mysql_bin
        cls.addClassCleanup(cls.database.doClassCleanups)
        cls.database.setUpClass()
        cls.database.query("CREATE DATABASE level_sixty_seed; CREATE DATABASE level_sixty_test;", database=None)
        directory = ROOT / "data/coa-world"
        manifest = json.loads((directory / "baseline.json").read_text(encoding="utf-8"))
        with zipfile.ZipFile(directory / manifest["archive"]) as archive:
            for table in TABLES:
                cls.database.query(archive.read(table + ".sql").decode("utf-8"), database="level_sixty_seed")
        cls.database.query(PROGRESSION.read_text(encoding="utf-8"), database="level_sixty_seed")
        cls.donors = {int(c): int(d) for c, d in cls.database.query(
            "SELECT class, fallback_class FROM ascension_custom_class;", database="level_sixty_seed")}

    def query(self, sql):
        return self.database.query(sql, database="level_sixty_test")

    def setUp(self):
        self.query("DROP TABLE IF EXISTS `ascension_race_class_stats`; DROP TABLE IF EXISTS `ascension_class_stats`;")
        for table in TABLES:
            self.query(f"DROP TABLE IF EXISTS `{table}`; "
                       f"CREATE TABLE `{table}` LIKE `level_sixty_seed`.`{table}`; "
                       f"INSERT INTO `{table}` SELECT * FROM `level_sixty_seed`.`{table}`;")

    def apply(self):
        self.query(MIGRATION.read_text(encoding="utf-8"))

    def rows_by_class_level(self, sql):
        return {(int(row[0]), int(row[1])): tuple(map(int, row[2:])) for row in self.query(sql)}

    def stock_rows(self):
        return self.rows_by_class_level(
            "SELECT Class, Level, BaseHP, BaseMana, Strength, Agility, Stamina, Intellect, Spirit "
            "FROM player_class_stats;")

    def class_rows(self):
        return self.rows_by_class_level(
            "SELECT s.Class, s.Level, COALESCE(a.BaseHP, s.BaseHP), COALESCE(a.BaseMana, s.BaseMana), "
            "COALESCE(a.Strength, s.Strength), COALESCE(a.Agility, s.Agility), COALESCE(a.Stamina, s.Stamina), "
            "COALESCE(a.Intellect, s.Intellect), COALESCE(a.Spirit, s.Spirit) FROM player_class_stats s "
            "LEFT JOIN ascension_class_stats a ON a.Class = s.Class AND a.Level = s.Level;")

    def race_rows(self):
        return {int(row[0]): tuple(map(int, row[1:])) for row in self.query(
            "SELECT Race, Strength, Agility, Stamina, Intellect, Spirit FROM player_race_stats;")}

    def adjustment_rows(self):
        return {tuple(map(int, row[:3])): tuple(map(int, row[3:])) for row in self.query(
            "SELECT Race, Class, Level, Strength, Agility, Stamina, Intellect, Spirit "
            "FROM ascension_race_class_stats;")}

    def effective_stats(self, classes, races, adjustments, race, custom, level):
        adjustment = adjustments.get((race, custom, level), (0,) * 5)
        return tuple(classes[custom, level][2 + i] + races[race][i] + adjustment[i] for i in range(5))

    def test_human_level_sixty_matches_bisbeard(self):
        self.apply()
        rows = self.class_rows()
        for custom, expected in BISBEARD_HUMAN_LEVEL_SIXTY.items():
            self.assertEqual(rows[custom, 60], expected, custom)
        self.assertFalse([key for key in self.adjustment_rows() if key[0] == 1])

    def test_race_totals_at_level_sixty_match_bisbeard(self):
        self.apply()
        classes, races, adjustments = self.class_rows(), self.race_rows(), self.adjustment_rows()
        for (race, custom), expected in BISBEARD_RACE_CLASS_LEVEL_SIXTY.items():
            actual = self.effective_stats(classes, races, adjustments, race, custom, 60)
            self.assertEqual(actual, expected, (race, custom))

    def test_level_one_and_stock_classes_are_unchanged(self):
        before = self.stock_rows()
        self.apply()
        self.assertEqual(before, self.stock_rows())
        after = self.class_rows()
        self.assertEqual(before.keys(), after.keys())
        self.assertNotEqual(before[12, 60], after[12, 60])
        for key in before:
            if key[0] < 12 or key[1] == 1:
                self.assertEqual(before[key], after[key], key)
        self.assertEqual(after[12, 1], (74, 0, 27, 26, 24, 14, 18))
        self.assertFalse([key for key in self.adjustment_rows() if key[2] == 1])

    def test_levels_above_sixty_keep_fallback_gains_and_constant_race_adjustments(self):
        self.apply()
        rows, adjustments = self.class_rows(), self.adjustment_rows()
        for custom in range(12, 33):
            donor = self.donors[custom]
            for level in range(61, 81):
                for index in range(7):
                    if index == 1 and custom in ZERO_MANA_CLASSES:
                        continue
                    with self.subTest(custom=custom, level=level, index=index):
                        self.assertEqual(rows[custom, level][index] - rows[custom, level - 1][index],
                                         rows[donor, level][index] - rows[donor, level - 1][index])
                for race in RACES:
                    self.assertEqual(adjustments.get((race, custom, level), (0,) * 5),
                                     adjustments.get((race, custom, 60), (0,) * 5), (race, custom, level))

    def test_effective_stats_and_base_health_never_drop(self):
        self.apply()
        classes, races, adjustments = self.class_rows(), self.race_rows(), self.adjustment_rows()
        for custom in range(12, 33):
            for level in range(2, 81):
                self.assertGreaterEqual(classes[custom, level][0], classes[custom, level - 1][0], (custom, level))
                for race in RACES:
                    previous = self.effective_stats(classes, races, adjustments, race, custom, level - 1)
                    current = self.effective_stats(classes, races, adjustments, race, custom, level)
                    with self.subTest(race=race, custom=custom, level=level):
                        self.assertTrue(all(a <= b for a, b in zip(previous, current)))
                        self.assertGreaterEqual(min(current), 0)

    def test_zero_mana_classes_keep_no_base_mana(self):
        self.apply()
        rows = self.class_rows()
        for custom in ZERO_MANA_CLASSES:
            for level in range(1, 81):
                self.assertEqual(rows[custom, level][1], 0, (custom, level))

    def test_replay_is_stable_and_out_of_scope_rows_are_kept(self):
        self.query("INSERT INTO player_class_stats VALUES (12,81,9999,0,500,500,500,500,500), "
                   "(33,2,123,456,20,21,22,23,24);")
        self.apply()
        self.assertEqual(self.class_rows()[12, 81], (9999, 0, 500, 500, 500, 500, 500))
        self.query("INSERT INTO ascension_class_stats VALUES (12,81,8888,0,400,400,400,400,400);")
        self.query("INSERT INTO ascension_race_class_stats VALUES (2,1,60,1,2,3,4,5), (2,12,81,1,1,1,1,1), "
                   "(9,12,60,2,2,2,2,2);")
        classes, adjustments = self.class_rows(), self.adjustment_rows()
        self.assertEqual(classes[12, 81], (8888, 0, 400, 400, 400, 400, 400))
        self.assertEqual(classes[33, 2], (123, 456, 20, 21, 22, 23, 24))
        self.apply()
        self.assertEqual(classes, self.class_rows())
        self.assertEqual(adjustments, self.adjustment_rows())
        self.assertEqual(adjustments[2, 12, 81], (1, 1, 1, 1, 1))
        self.assertEqual(adjustments[9, 12, 60], (2, 2, 2, 2, 2))
        self.assertGreater(MIGRATION.name, PROGRESSION.name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mysql-bin", required=True, type=Path)
    args, remaining = parser.parse_known_args()
    ClassLevelSixtyStatsTests.mysql_bin = args.mysql_bin.resolve()
    unittest.main(argv=[__file__, *remaining], verbosity=2)
