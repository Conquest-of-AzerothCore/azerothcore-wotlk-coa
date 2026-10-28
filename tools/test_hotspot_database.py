import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.environ.get('XPHOT_DISPOSABLE_MYSQL') == '1', 'Disposable MySQL fixture not selected')
class HotspotDatabaseTests(unittest.TestCase):
    def sql(self, statement):
        result = subprocess.run(['mysql', '--host=127.0.0.1', '--user=root', '--batch', '--skip-column-names',
                               'hotspot_test'], input=statement, text=True, capture_output=True,
                              check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def test_migration_preserves_edits_and_runtime_state_on_reapply(self):
        self.assertEqual(self.sql('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE();'), '0')
        migration = (ROOT / 'data/sql/updates/pending_db_world/rev_20261011_00_hotspots.sql').read_text()
        self.sql(migration)
        self.assertEqual(self.sql('SELECT COUNT(*), SUM(JSON_VALID(payload)) FROM xp_hotspot_location;'), '3129\t3129')
        self.assertEqual(self.sql("SELECT COUNT(*) FROM xp_hotspot_location WHERE "
                                  "JSON_UNQUOTE(JSON_EXTRACT(payload,'$.kind'))='circle';"), '2715')
        self.sql("UPDATE xp_hotspot_location SET payload=JSON_SET(payload,'$.name','GM edited',"
                 "'$.ends',2000000000) WHERE id=1;")
        self.sql('UPDATE xp_hotspot_setting SET value=0 WHERE id=1;')
        self.sql(migration)
        self.assertEqual(self.sql("SELECT JSON_UNQUOTE(JSON_EXTRACT(payload,'$.name')),"
                                  "JSON_EXTRACT(payload,'$.ends') FROM xp_hotspot_location WHERE id=1;"),
                         'GM edited\t2000000000')
        self.assertEqual(self.sql('SELECT value FROM xp_hotspot_setting WHERE id=1;'), '0')
        self.assertEqual(self.sql('SELECT COUNT(*) FROM xp_hotspot_location;'), '3129')


if __name__ == '__main__':
    unittest.main()
