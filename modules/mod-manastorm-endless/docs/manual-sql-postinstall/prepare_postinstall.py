#!/usr/bin/env python3
"""Prepare SQL for review; never connects to a database or changes source exports."""

import argparse
import hashlib
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
REPAIR = HERE.parents[1] / "data/sql/db-world/updates/zz_manastorm_link_affix_eligibility.sql"


def world_sql(source):
    schemas = {}
    for match in re.finditer(r"CREATE TABLE `([^`]+)`\s*\((.*?)\n\)", source, re.S):
        table, body = match.groups()
        if not table.startswith("manastorm_"):
            raise ValueError(f"Unexpected table: {table}")
        columns = re.findall(r"^\s*`([^`]+)`\s", body, re.M)
        primary = re.search(r"PRIMARY KEY\s*\(([^)]+)\)", body)
        if not primary:
            raise ValueError(f"Missing primary key: {table}")
        keys = set(re.findall(r"`([^`]+)`", primary[1]))
        schemas[table] = (columns, keys, body)
    if len(schemas) != 25:
        raise ValueError(f"Expected 25 world tables, found {len(schemas)}")
    result = ["-- REVIEW ONLY: configured snapshot upserts; existing non-snapshot rows remain.",
              "-- Run in the intended world database AFTER upstream and module SQL.",
              "SET NAMES utf8mb4;"]
    body = schemas["manastorm_unlock_message"][2]
    for column in ("source_field_1", "source_field_2", "source_field_3"):
        definition = re.search(r"^\s*(`" + column + r"`[^\n]+)", body, re.M)
        if not definition:
            raise ValueError(f"Missing source metadata: {column}")
        declaration = definition[1].rstrip().removesuffix(",")
        declaration = declaration.replace("\\", "\\\\").replace("'", "''")
        result.extend([
            "SET @ms_column_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'manastorm_unlock_message' "
            f"AND COLUMN_NAME = '{column}');",
            "SET @ms_sql = IF(@ms_column_exists = 0, "
            f"'ALTER TABLE `manastorm_unlock_message` ADD COLUMN {declaration}', 'DO 0');",
            "PREPARE ms_statement FROM @ms_sql;",
            "EXECUTE ms_statement;",
            "DEALLOCATE PREPARE ms_statement;",
        ])
    count = 0
    for match in re.finditer(r"^INSERT INTO `([^`]+)` VALUES (.*);$", source, re.M):
        table, values = match.groups()
        columns, keys, _ = schemas[table]
        names = ", ".join(f"`{name}`" for name in columns)
        updates = ", ".join(f"`{name}` = VALUES(`{name}`)" for name in columns if name not in keys)
        result.append(f"INSERT INTO `{table}` ({names}) VALUES {values} ON DUPLICATE KEY UPDATE {updates};")
        count += 1
    if count != len(re.findall(r"^INSERT INTO ", source, re.M)):
        raise ValueError("Not every export INSERT was recognized")
    result.append(REPAIR.read_text(encoding="utf-8"))
    return "\n".join(result) + "\n", count


def teleport_sql(source):
    result = ["-- REVIEW ONLY: overwrites overlapping teleport values with the authored snapshot.",
              "-- Run in the intended world database AFTER upstream and module SQL.",
              "SET NAMES utf8mb4;"]
    count = 0
    pattern = r"^INSERT INTO `acore_world`\.`game_tele` (\([^\n]+?\)) VALUES (.*);$"
    for match in re.finditer(pattern, source, re.M):
        columns, values = match.groups()
        names = re.findall(r"`([^`]+)`", columns)
        updates = ", ".join(f"`{name}` = VALUES(`{name}`)" for name in names if name != "id")
        result.append(f"INSERT INTO `game_tele` {columns} VALUES {values} ON DUPLICATE KEY UPDATE {updates};")
        count += 1
    if count != 163 or count != len(re.findall(r"^INSERT INTO ", source, re.M)):
        raise ValueError("Expected all 163 authored teleports")
    return "\n".join(result) + "\n", count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    sources = [HERE / "Gametele.sql", HERE / "ManastormWorldDBExport-RUNTHIS.sql"]
    hashes = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in sources}
    teleports, tele_count = teleport_sql(sources[0].read_text(encoding="utf-8-sig"))
    world, world_count = world_sql(sources[1].read_text(encoding="utf-8-sig"))
    output = args.output_dir.resolve()
    if output == HERE.resolve() or HERE.resolve() in output.parents:
        raise ValueError("Choose an output directory outside the source exports")
    files = {"01_game_tele_REVIEW.sql": teleports,
             "02_manastorm_world_REVIEW.sql": world}
    if any((output / name).exists() for name in files):
        raise FileExistsError("Review output already exists; choose another output directory")
    output.mkdir(parents=True, exist_ok=True)
    for name, text in files.items():
        (output / name).write_text(text, encoding="utf-8", newline="\n")
    if any(hashlib.sha256(path.read_bytes()).hexdigest() != digest for path, digest in hashes.items()):
        raise RuntimeError("Source export changed during preparation")
    print(f"Prepared {tele_count} teleport and {world_count} world row upserts in {output}")
    print("No character history generated; no database connection or import performed.")


if __name__ == "__main__":
    main()
