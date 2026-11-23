from pathlib import Path
import sqlite3
import unittest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "data/sql/updates/pending_db_world/rev_20261123_05_coa_dunshire_crow_on_scarecrow_hat.sql"


class DunshireCrowHatMigration(unittest.TestCase):
    def test_replaces_only_its_handlers_and_is_idempotent(self):
        sql = MIGRATION.read_text(encoding="utf-8")
        with sqlite3.connect(":memory:") as db:
            db.executescript("""
                CREATE TABLE creature (guid INTEGER, id INTEGER, position_x REAL, position_y REAL, position_z REAL);
                CREATE TABLE creature_movement_override (SpawnId INTEGER PRIMARY KEY, Flight INTEGER);
                CREATE TABLE smart_scripts (
                    entryorguid INTEGER, source_type INTEGER, id INTEGER, link INTEGER, event_type INTEGER,
                    event_phase_mask INTEGER, event_chance INTEGER, event_flags INTEGER, event_param1 INTEGER,
                    event_param2 INTEGER, action_type INTEGER, action_param1 INTEGER, action_param2 INTEGER,
                    target_type INTEGER, target_x REAL, target_y REAL, target_z REAL, comment TEXT,
                    PRIMARY KEY (entryorguid, source_type, id, link)
                );
            """)
            db.execute("INSERT INTO creature VALUES (9920417, 164944, 0, 0, 0)")
            rows = [(-9920417, 0, n, 0, 'old') for n in range(3)]
            preserved = [(-9920417, 0, 3, 0, 'other handler'),
                         (-9920417, 1, 0, 0, 'other source'), (-9920418, 0, 0, 0, 'other spawn')]
            db.executemany("INSERT INTO smart_scripts (entryorguid, source_type, id, link, comment) "
                           "VALUES (?, ?, ?, ?, ?)", rows + preserved)
            for _ in range(2):
                db.executescript(sql)
                actual = db.execute("SELECT entryorguid, source_type, id, link, comment FROM smart_scripts "
                                    "WHERE id = 3 OR source_type = 1 OR entryorguid = -9920418").fetchall()
                self.assertCountEqual(actual, preserved)
                handlers = db.execute("SELECT id, event_type, action_type FROM smart_scripts "
                                      "WHERE entryorguid = -9920417 AND source_type = 0 AND id IN (0, 1, 2) "
                                      "ORDER BY id").fetchall()
                self.assertEqual(handlers, [(0, 7, 91), (1, 21, 97), (2, 34, 66)])
                self.assertEqual(db.execute("SELECT position_x, position_y, position_z FROM creature").fetchone(),
                                 (-7786.923, 568.814, 140.37))
                self.assertEqual(db.execute("SELECT SpawnId, Flight FROM creature_movement_override").fetchall(),
                                 [(9920417, 1)])


if __name__ == "__main__":
    unittest.main()
