"""Verify, audit, and bootstrap the versioned CoA world-content baseline.

Bootstrap accepts an existing, empty world schema only. It never connects to the
character or authentication databases and never replaces an installed database.
"""

import argparse
import functools
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import uuid
import zipfile


ROOT = Path(__file__).resolve().parents[2]
BASELINE = ROOT / "data/coa-world/baseline.json"
IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z_0-9]*\Z")
PROCESS_OPTIONS = {"creationflags": subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {}
METADATA = {"updates", "updates_include", "version"}


def identifier(value):
    if not IDENTIFIER.fullmatch(value):
        raise ValueError("Invalid database/table/column identifier")
    return "`" + value + "`"


@functools.lru_cache(maxsize=None)
def login_path_options(executable):
    try:
        result = subprocess.run([executable, "--help"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                text=True, errors="replace", timeout=30, **PROCESS_OPTIONS)
    except (OSError, subprocess.TimeoutExpired):
        return ("--no-login-paths",)
    return ("--no-login-paths",) if "--no-login-paths" in result.stdout else ()


def digest(stream):
    return hashlib.file_digest(stream, "sha256").hexdigest()


def native_sql_hash(data, windows=None):
    # UpdateFetcher reads through a text-mode ifstream: Windows translates CRLF, Unix does not.
    if windows is None:
        windows = os.name == "nt"
    if windows:
        data = data.replace(b"\r\n", b"\n")
    return hashlib.sha1(data).hexdigest()


def covered_hashes(manifest, root=ROOT):
    result = []
    for relative, expected in manifest.get("coveredMigrations", {}).items():
        path = (root / relative).resolve()
        if not path.is_relative_to(root.resolve()) or not re.fullmatch(r"[A-Za-z0-9_.-]+\.sql", path.name):
            raise ValueError("Invalid covered migration path")
        data = path.read_bytes()
        if hashlib.sha1(data.replace(b"\r\n", b"\n")).hexdigest() != expected:
            raise ValueError("Covered migration changed; refresh the baseline: " + relative)
        result.append((path.name, expected, native_sql_hash(data)))
    return result


def load_baseline(path=BASELINE):
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("format") != 1 or not manifest.get("tables"):
        raise ValueError("Unsupported or empty world baseline")
    archive_name = manifest["archive"]
    if Path(archive_name).name != archive_name:
        raise ValueError("Baseline archive must be beside its manifest")
    archive_path = path.parent / archive_name
    with archive_path.open("rb") as stream:
        if digest(stream) != manifest["sha256"]:
            raise ValueError("World baseline archive checksum mismatch")
    with zipfile.ZipFile(archive_path) as archive:
        expected = {table + ".sql" for table in manifest["tables"]}
        if set(archive.namelist()) != expected or len(archive.namelist()) != len(expected):
            raise ValueError("Unexpected or duplicate members in world baseline")
        for table, contract in manifest["tables"].items():
            identifier(table)
            for column in contract["columns"]:
                identifier(column)
            with archive.open(table + ".sql") as stream:
                if digest(stream) != contract["sqlSha256"]:
                    raise ValueError("World baseline table checksum mismatch: " + table)
    covered_hashes(manifest)
    return manifest, archive_path


class MySQL:
    def __init__(self, executable, database, defaults_file=None, extra_args=()):
        identifier(database)
        if database.lower().endswith(("_auth", "_characters")):
            raise ValueError("Select a world database, not an account or character database")
        options = ["--defaults-extra-file=" + str(defaults_file.resolve())] if defaults_file else ["--no-defaults"]
        self.command = [str(executable), *options, *login_path_options(str(executable)), *extra_args,
                        "--batch", "--raw", "--skip-column-names", "--default-character-set=utf8mb4", "--max-allowed-packet=1GB",
                        "--connect-timeout=10", "--init-command=SET time_zone='+00:00', max_execution_time=300000",
                        "--database=" + database]
        self.process = None
        self.errors = None

    def close(self):
        if self.process is not None:
            try:
                self.process.stdin.close()
                self.process.wait(timeout=10)
            except (BrokenPipeError, subprocess.TimeoutExpired):
                self.process.kill()
                self.process.wait()
            finally:
                self.process.stdout.close()
                self.errors.close()
                self.process = None

    def lines(self, sql):
        if self.process is None:
            self.errors = tempfile.TemporaryFile()
            self.process = subprocess.Popen(self.command + ["--unbuffered"], stdin=subprocess.PIPE,
                                            stdout=subprocess.PIPE, stderr=self.errors, **PROCESS_OPTIONS)
        marker = "coa_query_" + uuid.uuid4().hex
        try:
            self.process.stdin.write((sql.rstrip().rstrip(";") + ";\nSELECT '" + marker + "';\n").encode("utf-8"))
            self.process.stdin.flush()
            while True:
                line = self.process.stdout.readline()
                if not line:
                    self.process.wait(timeout=10)
                    self.errors.seek(0)
                    raise RuntimeError(self.errors.read().decode("utf-8", errors="replace") or "MySQL closed early")
                line = line.rstrip(b"\r\n")
                if line == marker.encode():
                    break
                yield line
        except BaseException:
            self.close()
            raise

    def query(self, sql):
        return [line.decode("utf-8").split("\t") for line in self.lines(sql)]

    def execute_stream(self, stream):
        # mysql must finish successfully before the next table is started. Never use --force.
        with tempfile.TemporaryFile() as errors:
            process = subprocess.Popen(self.command, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                                       stderr=errors, **PROCESS_OPTIONS)
            try:
                process.stdin.write(b"SET NAMES utf8mb4; SET FOREIGN_KEY_CHECKS=0;\n")
                while block := stream.read(1024 * 1024):
                    process.stdin.write(block)
                process.stdin.close()
                status = process.wait(timeout=300)
            except BrokenPipeError:
                process.wait(timeout=10)
                errors.seek(0)
                raise RuntimeError(errors.read().decode("utf-8", errors="replace")) from None
            except BaseException:
                process.kill()
                process.wait()
                raise
            if status:
                errors.seek(0)
                raise RuntimeError(errors.read().decode("utf-8", errors="replace"))

    def fingerprint(self, table, columns, keys):
        # Hex encoding distinguishes NULL, empty text, embedded newlines, and binary values.
        fields = ["IFNULL(HEX(CAST(" + identifier(column) + " AS BINARY)), '~')" for column in columns]
        order = ",".join(identifier(column) for column in keys) if keys else ",".join(fields)
        sql = "SELECT " + ",".join(fields) + " FROM " + identifier(table) + " ORDER BY " + order + ";"
        checksum = hashlib.sha256()
        count = 0
        for line in self.lines(sql):
            checksum.update(line + b"\n")
            count += 1
        return {"rows": count, "sha256": checksum.hexdigest()}


def compare_content(mysql, manifest):
    installed = {row[0] for row in mysql.query("SHOW TABLES;")}
    differences = {}
    for table, contract in manifest["tables"].items():
        if table in METADATA:
            continue
        if table not in installed:
            differences[table] = {"missingTable": True}
            continue
        actual_schema = mysql.query("SHOW COLUMNS FROM " + identifier(table) + ";")
        if actual_schema != contract["schema"]:
            differences[table] = {"schemaDiffers": True}
            continue
        actual = mysql.fingerprint(table, contract["columns"], contract["primaryKey"])
        if actual != contract["content"]:
            differences[table] = {"expected": contract["content"], "actual": actual}
    additional = installed - set(manifest["tables"])
    unexpected = additional - set(manifest.get("excludedTables", ()))
    return {"baseline": manifest["id"], "contentMatches": not differences and not unexpected,
            "differences": differences, "additionalTables": sorted(additional),
            "unexpectedAdditionalTables": sorted(unexpected)}


def audit(mysql, manifest):
    mysql.query("SET TRANSACTION READ ONLY; START TRANSACTION WITH CONSISTENT SNAPSHOT;")
    try:
        return compare_content(mysql, manifest)
    finally:
        mysql.query("ROLLBACK;")


def bootstrap(mysql, manifest, archive_path):
    if mysql.query("SHOW TABLES;"):
        raise ValueError("World database is not empty; use audit. Bootstrap never replaces installed data.")
    covered = covered_hashes(manifest)
    with zipfile.ZipFile(archive_path) as archive:
        # The migration ledger is installed last, after all of the covered content succeeds.
        tables = sorted(manifest["tables"], key=lambda table: (table in METADATA, table))
        for index, table in enumerate(tables, 1):
            with archive.open(table + ".sql") as stream:
                mysql.execute_stream(stream)
            if index % 25 == 0 or index == len(tables):
                print(f"Imported {index}/{len(tables)} world tables", file=sys.stderr, flush=True)
    reconcile_ledger(mysql, covered)


def reconcile_ledger(mysql, covered):
    changed = [(name, expected, native) for name, expected, native in covered if expected != native]
    if not changed:
        return
    mysql.query("START TRANSACTION;")
    try:
        for name, expected, native in changed:
            # UpdateFetcher compares hexadecimal hashes case-sensitively and writes uppercase.
            rows = mysql.query("UPDATE `updates` SET `hash`='" + native.upper() + "' WHERE `name`='" + name
                               + "' AND LOWER(`hash`)='" + expected + "'; SELECT ROW_COUNT();")
            if rows != [["1"]]:
                raise ValueError("Unexpected covered migration identity: " + name)
        mysql.query("COMMIT;")
    except BaseException:
        mysql.query("ROLLBACK;")
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("verify", "audit", "bootstrap"))
    parser.add_argument("--manifest", type=Path, default=BASELINE)
    parser.add_argument("--mysql", type=Path, default=Path("mysql"))
    parser.add_argument("--defaults-file", type=Path, help="MySQL client option file; credentials are never printed")
    parser.add_argument("--database", help="Existing world schema; bootstrap requires it to be empty")
    args = parser.parse_args()
    manifest, archive = load_baseline(args.manifest)
    if args.command == "verify":
        print(json.dumps({"baseline": manifest["id"], "tables": len(manifest["tables"]), "verified": True}))
        return
    if not args.database:
        parser.error("--database is required for audit/bootstrap")
    mysql = MySQL(args.mysql, args.database, args.defaults_file)
    try:
        if args.command == "bootstrap":
            bootstrap(mysql, manifest, archive)
        result = audit(mysql, manifest)
    finally:
        mysql.close()
    print(json.dumps(result, indent=2))
    if not result["contentMatches"]:
        raise SystemExit(1)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, OSError, subprocess.SubprocessError, zipfile.BadZipFile) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
