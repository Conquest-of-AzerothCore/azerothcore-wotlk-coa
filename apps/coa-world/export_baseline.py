"""Publish world content from a clean repack snapshot into the repository baseline.

The supplied MySQL world schema must be an isolated import of that snapshot.
Its row fingerprints are checked again after importing the generated baseline.
Only world tables enter the package; account/character sections are discarded.
"""

import argparse
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile

from world_data import METADATA, MySQL, ROOT, identifier


# Historical before-images are rollback material, not installable world content.
EXCLUDED = {
    "item_template_ascension_heirloom_backup",
    "item_template_ascension_heirloom_pre_exact",
    "item_template_displayid_before_ascension",
}


def manifest_json(manifest):
    # Put migration hashes on their own lines so long repository paths stay within 120 columns.
    rendered = json.dumps(manifest, indent=2)
    return re.sub(r'^(    "[^"]+\.sql":) ("[0-9a-f]{40}",?)$', r'\1\n      \2',
                  rendered, flags=re.MULTILINE) + "\n"


def extract_tables(snapshot, directory):
    active = False
    table = None
    target = None
    definition = False
    try:
        with gzip.open(snapshot, "rt", encoding="utf-8") as stream:
            for line in stream:
                if line.startswith("USE "):
                    active = line.strip() == "USE `acore_world`;"
                    continue
                if not active:
                    continue
                match = re.match(r"CREATE TABLE `([^`]+)` \(", line)
                if match:
                    if target:
                        target.close()
                    table = match[1]
                    identifier(table)
                    target = None if table in EXCLUDED else (directory / (table + ".sql")).open(
                        "w", encoding="utf-8", newline="\n")
                    definition = True
                if target and (definition or line.startswith("INSERT INTO `" + table + "` ")):
                    target.write(line)
                if definition and line.startswith(") ENGINE="):
                    definition = False
    finally:
        if target:
            target.close()
    if not (directory / "item_template.sql").is_file() or not (directory / "updates.sql").is_file():
        raise ValueError("Snapshot does not contain a complete acore_world section")
    # Installed absolute/custom paths must not become part of a portable source installation.
    include = directory / "updates_include.sql"
    sql = include.read_text(encoding="utf-8").split("INSERT INTO", 1)[0]
    sql += "INSERT INTO `updates_include` VALUES\n"
    sql += "('$/data/sql/archive/db_world','ARCHIVED'),\n"
    sql += "('$/data/sql/custom/db_world','CUSTOM'),\n"
    sql += "('$/data/sql/updates/db_world','RELEASED'),\n"
    sql += "('$/data/sql/updates/pending_db_world','PENDING');\n"
    include.write_text(sql, encoding="utf-8", newline="\n")


def export(snapshot, mysql, output, baseline_id, release):
    if output.exists():
        raise ValueError("Output already exists; publish a new baseline directory")
    recorded = {row[0]: row[1].lower() for row in mysql.query("SELECT `name`,`hash` FROM `updates`;")}
    covered = {}
    migrations = [*sorted((ROOT / "data/sql/updates/pending_db_world").glob("*.sql")),
                  *sorted((ROOT / "modules/mod-ascension/data/sql/db-world").glob("*.sql"))]
    for migration in migrations:
        checksum = hashlib.sha1(migration.read_bytes().replace(b"\r\n", b"\n")).hexdigest()
        if recorded.get(migration.name) != checksum:
            raise ValueError("Snapshot does not incorporate the current migration: " + migration.name)
        covered[str(migration.relative_to(ROOT)).replace("\\", "/")] = checksum
    output.mkdir(parents=True)
    archive_path = output / (baseline_id + ".zip")
    manifest = {
        "format": 1,
        "id": baseline_id,
        "archive": archive_path.name,
        "sourceRevision": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "repackRelease": release,
        "sourceSnapshotSha256": "",
        "excludedTables": sorted(EXCLUDED),
        "metadataTables": sorted(METADATA),
        "coveredMigrations": covered,
        "tables": {},
    }
    with snapshot.open("rb") as stream:
        manifest["sourceSnapshotSha256"] = hashlib.file_digest(stream, "sha256").hexdigest()
    with tempfile.TemporaryDirectory(prefix="coa-world-export-") as temporary:
        directory = Path(temporary)
        extract_tables(snapshot, directory)
        with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for index, path in enumerate(sorted(directory.glob("*.sql")), 1):
                table = path.stem
                schema = mysql.query("SHOW COLUMNS FROM " + identifier(table) + ";")
                columns = [row[0] for row in schema]
                keys = [row[0] for row in schema if row[3] == "PRI"]
                with path.open("rb") as stream:
                    sql_hash = hashlib.file_digest(stream, "sha256").hexdigest()
                # Fixed ZIP metadata makes the same reviewed inputs reproduce the same package bytes.
                info = zipfile.ZipInfo(path.name, date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                with path.open("rb") as source, archive.open(info, "w", force_zip64=True) as target:
                    while block := source.read(1024 * 1024):
                        target.write(block)
                manifest["tables"][table] = {
                    "columns": columns, "primaryKey": keys, "schema": schema, "sqlSha256": sql_hash,
                    "content": mysql.fingerprint(table, columns, keys),
                }
                if index % 25 == 0:
                    print("Exported world tables:", index, flush=True)
    with archive_path.open("rb") as stream:
        manifest["sha256"] = hashlib.file_digest(stream, "sha256").hexdigest()
    (output / "baseline.json").write_text(manifest_json(manifest), encoding="utf-8", newline="\n")
    print(json.dumps({"archive": str(archive_path), "bytes": archive_path.stat().st_size,
                      "tables": len(manifest["tables"]), "sha256": manifest["sha256"]}), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot", type=Path, required=True)
    parser.add_argument("--mysql", type=Path, default=Path("mysql"))
    parser.add_argument("--defaults-file", type=Path, required=True)
    parser.add_argument("--database", required=True, help="Isolated world import of the clean snapshot")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--id", required=True)
    parser.add_argument("--repack-release", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]+", args.id):
        parser.error("--id must use lowercase letters, digits, and hyphens")
    mysql = MySQL(args.mysql, args.database, args.defaults_file)
    try:
        export(args.snapshot, mysql, args.output, args.id, args.repack_release)
    finally:
        mysql.close()


if __name__ == "__main__":
    main()
