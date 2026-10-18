"""Exercise the pending CoA loot migration on a disposable MySQL 8 database.

Usage: python apps/test-framework/test_coa_loot_migrations.py --mysql-bin /path/to/mysql/bin
Add --before-ref <commit> to show the required data assertions fail before this migration exists.
The server uses a unique local socket/named pipe, no TCP listeners, and a temporary data directory.
"""

import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import unittest
import uuid


ROOT = Path(__file__).resolve().parents[2]
PENDING = ROOT / "data/sql/updates/pending_db_world"
MIGRATION = PENDING / "rev_1789072184949916200.sql"
TABLES = ("creature_template", "creature_loot_template", "item_template", "quest_template", "conditions")
PROCESS_OPTIONS = {"creationflags": subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {}


class CoaLootMigrations(unittest.TestCase):
    mysql_bin = None
    before_ref = None

    @classmethod
    def setUpClass(cls):
        suffix = ".exe" if os.name == "nt" else ""
        cls.mysql = cls.mysql_bin / ("mysql" + suffix)
        cls.mysqld = cls.mysql_bin / ("mysqld" + suffix)
        if not cls.mysql.is_file() or not cls.mysqld.is_file():
            raise RuntimeError("--mysql-bin must contain both mysql and mysqld")

        cls.temporary = tempfile.TemporaryDirectory(prefix="coa-enchant-")
        cls.directory = Path(cls.temporary.name).resolve()
        cls.process = None
        cls.addClassCleanup(cls.stop_mysql)
        cls.log = cls.directory / "mysql.log"
        server = [str(cls.mysqld), "--no-defaults", f"--basedir={cls.mysql_bin.parent}",
                  f"--datadir={cls.directory / 'data'}", f"--log-error={cls.log}"]
        print("Initializing isolated MySQL data directory...", flush=True)
        subprocess.run(server + ["--initialize-insecure"], check=True, capture_output=True,
                       timeout=90, **PROCESS_OPTIONS)

        endpoint = ("coa_enchant_" + uuid.uuid4().hex if os.name == "nt"
                    else str(cls.directory / "mysql.sock"))
        cls.client = [str(cls.mysql), "--no-defaults", "--no-login-paths", "--user=root", "--batch",
                      "--skip-column-names", "--default-character-set=utf8mb4", "--connect-timeout=1",
                      "--max-allowed-packet=1GB", f"--socket={endpoint}"]
        server += ["--skip-networking", "--mysqlx=OFF", "--max-allowed-packet=1GB", f"--socket={endpoint}"]
        if os.name == "nt":
            server.append("--enable-named-pipe")
            cls.client += ["--protocol=PIPE", "--host=."]
        else:
            cls.client.append("--protocol=SOCKET")
        cls.process = subprocess.Popen(server, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                       **PROCESS_OPTIONS)
        deadline = time.monotonic() + 40
        while time.monotonic() < deadline:
            if cls.process.poll() is not None:
                raise RuntimeError(cls.log.read_text(encoding="utf-8"))
            result = subprocess.run(cls.client, input="SELECT 1;\n", text=True, capture_output=True,
                                    timeout=5, **PROCESS_OPTIONS)
            if result.returncode == 0 and result.stdout.strip() == "1":
                break
            time.sleep(0.2)
        else:
            raise RuntimeError("Isolated MySQL startup timed out: " + cls.log.read_text(encoding="utf-8"))

        cls.query("CREATE DATABASE `enchantment_test`;", database=None)
        tables = ("creature_template", "creature_loot_template", "item_template", "quest_template", "conditions")
        for table in tables:
            source = (ROOT / "data/sql/base/db_world" / (table + ".sql")).read_text(encoding="utf8")
            schema = re.search(r"CREATE TABLE.*?;", source, re.DOTALL).group(0)
            cls.query(schema)

    @classmethod
    def stop_mysql(cls):
        if cls.process is not None and cls.process.poll() is None:
            try:
                subprocess.run(cls.client, input="SHUTDOWN;\n", text=True, capture_output=True,
                               timeout=10, **PROCESS_OPTIONS)
                cls.process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                cls.process.kill()
                cls.process.wait(timeout=10)
        # Only clean the exact temporary directory created by this test, after its server exits.
        if cls.directory.parent != Path(tempfile.gettempdir()).resolve() or not cls.directory.name.startswith(
                "coa-enchant-"):
            raise RuntimeError("Unexpected test data directory; refusing cleanup")
        cls.temporary.cleanup()

    @classmethod
    def query(cls, sql, database="enchantment_test", expected_error=None):
        marker = "enchant_test_" + uuid.uuid4().hex
        command = cls.client + ([database] if database else [])
        result = subprocess.run(command, input=f"SELECT '{marker}_begin';\n{sql}\nSELECT '{marker}_end';\n",
                                text=True, encoding="utf-8", capture_output=True, timeout=60, **PROCESS_OPTIONS)
        lines = result.stdout.splitlines()
        if not lines or lines[0] != marker + "_begin":
            raise AssertionError("Missing MySQL result frame: " + result.stderr)
        if expected_error:
            if result.returncode == 0 or expected_error not in result.stderr:
                raise AssertionError("Expected SQL failure was not reproduced: " + result.stderr)
            if marker + "_end" in lines:
                raise AssertionError("MySQL continued after a failed migration")
            return result.stderr
        if result.returncode or lines[-1] != marker + "_end":
            raise AssertionError("Migration/query failed: " + result.stderr)
        return [tuple(line.split("\t")) for line in lines[1:-1]]

    def setUp(self):
        for table in TABLES:
            self.query(f"TRUNCATE TABLE `{table}`;")
        self.query("INSERT INTO creature_template (entry,name,lootid) VALUES (10161,'Rookery Whelp',0);")
        self.query("INSERT INTO item_template (entry,name) VALUES (1180298,'Draconic Warhorn: Rookery Whelp');")

    def apply(self):
        if self.before_ref:
            old = subprocess.run(["git", "show", f"{self.before_ref}:{MIGRATION.relative_to(ROOT).as_posix()}"],
                                 cwd=ROOT, text=True, encoding="utf8", capture_output=True, **PROCESS_OPTIONS)
            migration = old.stdout if old.returncode == 0 else "SELECT 1;"
        else:
            migration = MIGRATION.read_text(encoding="utf8")
        self.query(migration)

    def test_named_drop_and_repeat_preserve_unrelated_rows(self):
        self.query("INSERT INTO creature_loot_template (Entry,Item,Chance,Comment) "
                   "VALUES (777,888,37.125,'Unrelated exact value');")
        before = self.query("SELECT * FROM creature_loot_template WHERE Entry=777;")
        self.apply()
        self.assertEqual([("10161",)], self.query("SELECT lootid FROM creature_template WHERE entry=10161;"))
        self.assertEqual([("Rookery Whelp", "Draconic Warhorn: Rookery Whelp", "1", "1", "1")], self.query(
            "SELECT c.name,i.name,l.Chance,l.MinCount,l.MaxCount FROM creature_loot_template l "
            "JOIN creature_template c ON c.entry=l.Entry JOIN item_template i ON i.entry=l.Item "
            "WHERE l.Entry=10161;"))
        self.assertEqual(before, self.query("SELECT * FROM creature_loot_template WHERE Entry=777;"))
        snapshot = self.query("SELECT * FROM creature_loot_template ORDER BY Entry,Item;")
        self.apply()
        self.assertEqual(snapshot, self.query("SELECT * FROM creature_loot_template ORDER BY Entry,Item;"))

    def test_shared_or_renamed_creature_is_untouched(self):
        for setup in (
            "INSERT INTO creature_template (entry,name,lootid) VALUES (999,'Other owner',10161);",
            "UPDATE creature_template SET name='Different NPC' WHERE entry=10161;",
            "UPDATE creature_template SET name='ROOKERY WHELP' WHERE entry=10161;",
            "INSERT INTO creature_loot_template (Entry,Item) VALUES (10161,999);",
            "INSERT INTO conditions (SourceTypeOrReferenceId,SourceGroup,SourceEntry) VALUES (1,10161,1180298);",
        ):
            with self.subTest(setup=setup):
                self.setUp()
                self.query(setup)
                before = self.query("SELECT * FROM creature_loot_template ORDER BY Entry,Item;")
                self.apply()
                self.assertEqual(before, self.query("SELECT * FROM creature_loot_template ORDER BY Entry,Item;"))
                self.assertEqual([("0",)], self.query("SELECT lootid FROM creature_template WHERE entry=10161;"))

    def test_quest_bound_missing_and_quest_required_items_do_not_enable_loot(self):
        for setup in (
            "UPDATE item_template SET Bonding=4 WHERE entry=1180298;",
            "UPDATE item_template SET class=12 WHERE entry=1180298;",
            "UPDATE item_template SET startquest=123 WHERE entry=1180298;",
            "INSERT INTO quest_template (ID,RequiredItemId6) VALUES (123,1180298);",
            "INSERT INTO quest_template (ID,ItemDrop4) VALUES (123,1180298);",
            "DELETE FROM item_template WHERE entry=1180298;",
        ):
            with self.subTest(setup=setup):
                self.setUp()
                self.query(setup)
                self.apply()
                self.assertEqual([("0",)], self.query("SELECT COUNT(*) FROM creature_loot_template;"))
                self.assertEqual([("0",)], self.query("SELECT lootid FROM creature_template WHERE entry=10161;"))

    def test_reference_existing_probability_and_custom_stack_are_preserved(self):
        self.query("UPDATE creature_template SET lootid=10161;")
        for row in (
            "(10161,1,999,100,0,1,0,1,1,'Reference')",
            "(10161,1180298,0,8.12345,0,1,0,2,7,'Custom direct')",
        ):
            with self.subTest(row=row):
                self.query("TRUNCATE TABLE creature_loot_template;")
                self.query("INSERT INTO creature_loot_template VALUES " + row + ";")
                before = self.query("SELECT * FROM creature_loot_template;")
                self.apply()
                self.assertEqual(before, self.query("SELECT * FROM creature_loot_template;"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mysql-bin", type=Path, required=True)
    parser.add_argument("--before-ref", help="Use a previous migration revision; missing SQL is a no-op")
    options, remaining = parser.parse_known_args()
    CoaLootMigrations.mysql_bin = options.mysql_bin.resolve()
    CoaLootMigrations.before_ref = options.before_ref
    unittest.main(argv=[__file__, *remaining], verbosity=2)
