from pathlib import Path
import sqlite3
import unittest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "data/sql/updates/pending_db_world/rev_20261114_03_coa_reaper_spectral_scythe_weapon.sql"


class SpectralScytheEquipment(unittest.TestCase):
    def test_replaces_only_set_one_and_is_idempotent(self):
        sql = MIGRATION.read_text(encoding="utf-8")
        for existing in (False, True):
            with self.subTest(existing=existing), sqlite3.connect(":memory:") as db:
                db.execute("CREATE TABLE creature_equip_template (CreatureID INTEGER, ID INTEGER, ItemID1 INTEGER, "
                           "ItemID2 INTEGER, ItemID3 INTEGER, VerifiedBuild INTEGER, PRIMARY KEY (CreatureID, ID))")
                preserved = [(250305, 2, 123, 456, 789, 10), (250306, 1, 321, 654, 987, 11)]
                rows = preserved + ([(250305, 1, 111, 222, 333, 12)] if existing else [])
                db.executemany("INSERT INTO creature_equip_template VALUES (?, ?, ?, ?, ?, ?)", rows)
                expected = sorted(preserved + [(250305, 1, 574486, 0, 0, 0)])
                for _ in range(2):
                    db.executescript(sql)
                    actual = db.execute("SELECT * FROM creature_equip_template ORDER BY CreatureID, ID").fetchall()
                    self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
