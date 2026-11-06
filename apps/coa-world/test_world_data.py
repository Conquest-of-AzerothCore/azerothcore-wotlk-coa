"""Checks for world-only exports, package integrity, and non-destructive bootstrap."""

import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock
import zipfile

from export_baseline import extract_tables
from world_data import MySQL, bootstrap, covered_hashes, load_baseline, native_sql_hash, reconcile_ledger


class WorldDataTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="coa-world-unit-")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)

    def package(self):
        sql = b"CREATE TABLE `item_template` (`entry` INT PRIMARY KEY);\n"
        archive = self.directory / "test.zip"
        with zipfile.ZipFile(archive, "w") as output:
            output.writestr("item_template.sql", sql)
        manifest = {"format": 1, "id": "test", "archive": archive.name,
                    "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
                    "tables": {"item_template": {"columns": ["entry"],
                                                  "sqlSha256": hashlib.sha256(sql).hexdigest()}}}
        path = self.directory / "baseline.json"
        path.write_text(json.dumps(manifest), encoding="utf-8")
        return path, archive

    def test_snapshot_export_excludes_accounts_characters_and_before_images(self):
        snapshot = self.directory / "clean.sql.gz"
        with gzip.open(snapshot, "wt", encoding="utf-8") as output:
            output.write("USE `acore_auth`;\nCREATE TABLE `account` (\n  `secret` TEXT\n) ENGINE=InnoDB;\n")
            output.write("INSERT INTO `account` VALUES ('private account material');\nUSE `acore_world`;\n")
            for table in ("item_template", "updates", "updates_include", "item_template_ascension_heirloom_backup"):
                output.write(f"CREATE TABLE `{table}` (\n  `entry` INT\n) ENGINE=InnoDB;\n")
                output.write(f"INSERT INTO `{table}` VALUES (42);\n")
            output.write("USE `acore_characters`;\nCREATE TABLE `characters` (\n  `guid` INT\n) ENGINE=InnoDB;\n")
            output.write("INSERT INTO `characters` VALUES (123);\n")
            output.write("/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;\n")
        destination = self.directory / "world"
        destination.mkdir()
        extract_tables(snapshot, destination)
        self.assertEqual({p.name for p in destination.iterdir()},
                         {"item_template.sql", "updates.sql", "updates_include.sql"})
        contents = "".join(p.read_text(encoding="utf-8") for p in destination.iterdir())
        self.assertNotIn("private account", contents)
        self.assertNotIn("`characters`", contents)
        self.assertNotIn("USE ", contents)
        self.assertNotIn("DROP TABLE", contents)
        self.assertIn("$/data/sql/updates/pending_db_world", contents)

    def test_corrupted_archive_is_rejected_before_database_access(self):
        path, archive = self.package()
        load_baseline(path)
        with archive.open("ab") as output:
            output.write(b"unexpected change")
        with self.assertRaisesRegex(ValueError, "archive checksum"):
            load_baseline(path)

    def test_wrong_table_content_hash_is_rejected(self):
        path, _ = self.package()
        manifest = json.loads(path.read_text())
        manifest["tables"]["item_template"]["sqlSha256"] = "0" * 64
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "table checksum"):
            load_baseline(path)

    def test_unknown_or_duplicate_archive_member_is_rejected(self):
        path, archive = self.package()
        with zipfile.ZipFile(archive, "a") as output:
            output.writestr("account.sql", "CREATE TABLE account (secret TEXT);")
        manifest = json.loads(path.read_text())
        manifest["sha256"] = hashlib.sha256(archive.read_bytes()).hexdigest()
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "Unexpected or duplicate"):
            load_baseline(path)

    def test_installed_database_is_refused_before_opening_archive(self):
        class InstalledDatabase:
            def query(self, sql):
                self.last_query = sql
                return [["item_template"]]

            def execute_stream(self, stream):
                raise AssertionError("Installed data must never be written")

        database = InstalledDatabase()
        with self.assertRaisesRegex(ValueError, "not empty"):
            bootstrap(database, {}, self.directory / "does-not-exist.zip")
        self.assertEqual(database.last_query, "SHOW TABLES;")

    def test_account_character_and_invalid_database_names_are_rejected(self):
        for name in ("acore_auth", "coa_characters", "world; DROP DATABASE x", "world`"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                MySQL("mysql", name)

    def test_login_paths_are_disabled_only_when_the_client_supports_it(self):
        for executable, help_text, expected in (
                ("mysql-8.4", "  --no-login-paths    Don't read login paths from the login path file.\n", True),
                ("mysql-8.0.46", "  --login-path=name   Read this path from the login file.\n", False)):
            with self.subTest(executable=executable), mock.patch(
                    "world_data.subprocess.run",
                    return_value=subprocess.CompletedProcess([executable, "--help"], 0, stdout=help_text)):
                self.assertEqual("--no-login-paths" in MySQL(executable, "coa_world").command, expected)

    def test_unreadable_client_help_keeps_login_paths_disabled(self):
        with mock.patch("world_data.subprocess.run", side_effect=FileNotFoundError):
            self.assertIn("--no-login-paths", MySQL("missing-mysql", "coa_world").command)

    def test_native_hash_matches_platform_text_mode(self):
        crlf = b"UPDATE `example` SET `value`=1;\r\n"
        lf = crlf.replace(b"\r\n", b"\n")
        self.assertEqual(native_sql_hash(crlf, windows=True), hashlib.sha1(lf).hexdigest())
        self.assertEqual(native_sql_hash(crlf, windows=False), hashlib.sha1(crlf).hexdigest())

    def test_changed_migration_cannot_be_relabelled_as_covered(self):
        path = self.directory / "rev_test.sql"
        original = b"UPDATE `example` SET `value`=1;\n"
        manifest = {"coveredMigrations": {path.name: hashlib.sha1(original).hexdigest()}}
        path.write_bytes(original.replace(b"\n", b"\r\n"))
        self.assertEqual(len(covered_hashes(manifest, self.directory)), 1)
        path.write_bytes(b"UPDATE `example` SET `value`=2;\n")
        with self.assertRaisesRegex(ValueError, "Covered migration changed"):
            covered_hashes(manifest, self.directory)

    def test_ledger_rebinding_rejects_unexpected_recorded_hash(self):
        class WrongLedger:
            def __init__(self):
                self.statements = []

            def query(self, sql):
                self.statements.append(sql)
                return [["0"]] if sql.startswith("UPDATE") else []

        database = WrongLedger()
        with self.assertRaisesRegex(ValueError, "Unexpected covered migration identity"):
            reconcile_ledger(database, [("rev_test.sql", "a" * 40, "b" * 40)])
        self.assertEqual(database.statements[-1], "ROLLBACK;")
        self.assertNotIn("COMMIT;", database.statements)

    def test_rebound_hash_uses_native_updater_casing(self):
        class Ledger:
            def __init__(self):
                self.statements = []

            def query(self, sql):
                self.statements.append(sql)
                return [["1"]] if sql.startswith("UPDATE") else []

        database = Ledger()
        reconcile_ledger(database, [("rev_test.sql", "a" * 40, "b" * 40)])
        self.assertIn("SET `hash`='" + "B" * 40 + "'", database.statements[1])
        self.assertIn("LOWER(`hash`)='" + "a" * 40 + "'", database.statements[1])
        self.assertEqual(database.statements[-1], "COMMIT;")


if __name__ == "__main__":
    unittest.main()
