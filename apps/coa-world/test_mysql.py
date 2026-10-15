"""Compare a fresh repository database and the CoA baseline on disposable MySQL.

This reuses the repository's existing isolated MySQL fixture. It opens no TCP
listeners, reads no live connection settings, and never starts worldserver.
"""

import argparse
import importlib.util
import json
from pathlib import Path

from world_data import METADATA, MySQL, ROOT, audit, bootstrap, identifier, load_baseline, native_sql_hash

PROVENANCE_TABLES = {"item_template_coa", "item_template_ascension_compat"}


def migrate_source(mysql):
    for index, path in enumerate(sorted((ROOT / "data/sql/base/db_world").glob("*.sql")), 1):
        mysql.query(path.read_text(encoding="utf-8"))
        if index % 50 == 0:
            print("Imported source base tables:", index, flush=True)
    return apply_updates(mysql)


def apply_updates(mysql):
    recorded = {row[0]: (row[1], row[2]) for row in mysql.query("SELECT name,hash,state FROM updates;")}
    released = [(p, "RELEASED") for p in sorted((ROOT / "data/sql/updates/db_world").glob("*.sql"))]
    pending = [(p, "PENDING") for p in (ROOT / "data/sql/updates/pending_db_world").glob("*.sql")]
    modules = [(p, "MODULE") for p in (ROOT / "modules/mod-ascension/data/sql/db-world").glob("*.sql")]
    applied = []
    for path, state in released + sorted(pending + modules, key=lambda entry: entry[0].name):
        checksum = native_sql_hash(path.read_bytes()).upper()
        previous = recorded.get(path.name)
        # These are active directories: an ARCHIVED ledger state alone does not skip their hash check.
        if previous and previous[0] == checksum:
            continue
        mysql.query(path.read_text(encoding="utf-8"))
        mysql.query("REPLACE INTO `updates` (`name`,`hash`,`state`,`speed`) VALUES ('" + path.name + "','"
                    + checksum + "','" + state + "',0);")
        applied.append(str(path.relative_to(ROOT)).replace("\\", "/"))
        if len(applied) % 40 == 0:
            print("Applied source migrations:", len(applied), flush=True)
    return applied


def compare_source(source, manifest):
    installed = {row[0] for row in source.query("SHOW TABLES;")}
    differences = {}
    for table, contract in manifest["tables"].items():
        if table in METADATA:
            continue
        if table not in installed:
            differences[table] = {"missingTable": True, "baselineRows": contract["content"]["rows"]}
            continue
        columns = [row[0] for row in source.query("SHOW COLUMNS FROM " + identifier(table) + ";")]
        if columns != contract["columns"]:
            differences[table] = {"columnsDiffer": True}
            continue
        actual = source.fingerprint(table, columns, contract["primaryKey"])
        if actual == contract["content"]:
            continue
        entry = {"sourceRows": actual["rows"], "baselineRows": contract["content"]["rows"]}
        keys = contract["primaryKey"]
        if keys:
            # Generation timestamps in this provenance table are expected to differ on a fresh install.
            compared = [c for c in columns
                        if not (table in PROVENANCE_TABLES and c == "created_at")]
            join = " AND ".join("s." + identifier(k) + "=r." + identifier(k) for k in keys)
            changed = " OR ".join("NOT (BINARY s." + identifier(c) + " <=> BINARY r."
                                  + identifier(c) + ")" for c in compared)
            table_name = identifier(table)
            rows = source.query(
                "SELECT COUNT(*) FROM baseline_world." + table_name + " r LEFT JOIN source_world." + table_name
                + " s ON " + join + " WHERE s." + identifier(keys[0]) + " IS NULL;"
                + " SELECT COUNT(*) FROM source_world." + table_name + " s LEFT JOIN baseline_world." + table_name
                + " r ON " + join + " WHERE r." + identifier(keys[0]) + " IS NULL;"
                + " SELECT COUNT(*) FROM source_world." + table_name + " s JOIN baseline_world." + table_name
                + " r ON " + join + " WHERE " + changed + ";")
            if len(rows) != 3:
                raise AssertionError("Incomplete table comparison: " + table)
            entry.update(zip(("missingRows", "extraRows", "changedRows"), (int(row[0]) for row in rows)))
            if not any(entry[key] for key in ("missingRows", "extraRows", "changedRows")):
                continue
        else:
            entry["contentDiffers"] = True
        differences[table] = entry
        print("Source difference:", table, entry, flush=True)
    return differences


def run(mysql_bin):
    spec = importlib.util.spec_from_file_location(
        "isolated_mysql", ROOT / "apps/test-framework/test_enchantment_migrations.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    database = fixture.EnchantmentMigrations
    database.mysql_bin = mysql_bin
    clients = []
    try:
        database.setUpClass()
        extra = [arg for arg in database.client if arg.startswith(
            ("--user=", "--socket=", "--protocol=", "--host="))]

        def connect(name):
            client = MySQL(database.mysql, name, extra_args=extra)
            clients.append(client)
            return client

        admin = connect("mysql")
        # These settings affect only the disposable named-pipe/socket instance.
        admin.query("SET GLOBAL innodb_flush_log_at_trx_commit=2; SET GLOBAL sync_binlog=0;"
                    " SET GLOBAL time_zone='+00:00'; CREATE DATABASE source_world; CREATE DATABASE baseline_world;")
        source = connect("source_world")
        applied = migrate_source(source)
        manifest, archive = load_baseline()
        target = connect("baseline_world")
        bootstrap(target, manifest, archive)
        baseline_result = audit(target, manifest)
        if not baseline_result["contentMatches"]:
            raise AssertionError("Baseline round-trip differs: " + json.dumps(baseline_result))
        print("Baseline content matches after import.", flush=True)
        try:
            bootstrap(target, manifest, archive)
        except ValueError as error:
            if "not empty" not in str(error):
                raise
        else:
            raise AssertionError("An installed database was overwritten")
        replayed = apply_updates(target)
        if replayed:
            raise AssertionError("Covered migrations replayed unexpectedly: " + json.dumps(replayed))
        if not audit(target, manifest)["contentMatches"]:
            raise AssertionError("Updater check or rejected repeat changed the baseline")
        print("Repeat refused, no migrations replayed, content unchanged. Comparing source SQL...", flush=True)
        starters = target.query("SELECT entry,name,Quality,dmg_min1,dmg_max1,armor,MaxDurability FROM item_template "
                                "WHERE entry IN (484319,967757) ORDER BY entry;")
        if starters != [["484319", "Decayed Dagger", "1", "0.9375", "3.75", "0", "18"],
                        ["967757", "Noxious Kilt", "0", "0", "0", "6", "35"]]:
            raise AssertionError("The known repack starter definitions changed: " + json.dumps(starters))
        return {"baseline": manifest["id"], "roundTripMatches": True, "repeatRefusedWithoutChanges": True,
                "unexpectedMigrationReplays": replayed, "sourceMigrationsApplied": len(applied),
                "starterDefinitionsMatchRepack": True, "sourceDifferences": compare_source(source, manifest)}
    finally:
        try:
            for client in clients:
                client.close()
        finally:
            database.doClassCleanups()
            if database.tearDown_exceptions:
                raise database.tearDown_exceptions[0][1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mysql-bin", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    result = run(args.mysql_bin)
    if args.report:
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
