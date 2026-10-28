CLI_DESCRIPTION = """Check that Wildcard skill card items carry the name of the card SkillCard.dbc makes them, without a server.

The world package names many Wildcard card items after another Ascension mode's card with the same item ID, so
"Golden Skill Card - Demon Skin" (2222442) grants Ancient of War (#6300). Every card the Season 10 Wildcard item
cache captured is named "<type prefix> - <Spell.dbc name of its spell>". This checks every Wildcard Hero card row
of a captured type whose item is a skill card against the package names with the pending SQL applied (--dbc-dir).
No database, server build or game client is needed.
"""

import argparse
import csv
from pathlib import Path
import re
import struct
import sys
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261010_22_wildcard_skill_card_names.sql"
ARCHIVE = ROOT / "data/coa-world/coa-world-20260912.zip"
SPELL_NAME = 136
CARD_ITEM, CARD_SPELL, CARD_TYPE, CARD_CLASS, CARD_WILDCARD = 3, 4, 5, 7, 9
PREFIX = {"SKILL_CARD_DEFAULT_NORMAL": "Skill Card", "SKILL_CARD_DEFAULT_GOLDEN": "Golden Skill Card",
          "SKILL_CARD_TALENT_NORMAL": "Skill Card"}
CAPTURED = {2222442: "Skill Card - Ancient of War", 2205168: "Skill Card - Breath of Neltharion",
            2222001: "Golden Skill Card - Runic Hurricane"}

failures = 0


def check(value, name):
    global failures
    failures += not value
    print(("PASS" if value else "FAIL") + ": " + name)


def load(path):
    raw = path.read_bytes()
    count, fields, size, _ = struct.unpack_from("<IIII", raw, 4)
    strings = raw[20 + count * size:]
    rows = [row for row in struct.iter_unpack(f"<{fields}i", raw[20:20 + count * size])]
    return rows, lambda offset: strings[offset:strings.index(b"\0", offset)].decode("utf-8")


def package_names(entries):
    archive = zipfile.ZipFile(ARCHIVE)
    data = archive.read(next(p for p in archive.namelist() if p.rsplit("/", 1)[-1] == "item_template.sql")).decode()
    name = re.findall(r"^  `([^`]+)`", data, re.M).index("name")
    names = {}
    for match in re.finditer(r"\((\d+),", data):
        if int(match[1]) not in entries:
            continue
        end = min(p for p in (data.find("),(", match.start()), data.find(");", match.start())) if p >= 0)
        names[int(match[1])] = next(csv.reader([data[match.start() + 1:end]], quotechar="'", escapechar="\\"))[name]
    return names


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    directory = args.dbc_dir or dbc_dir()
    spells, spell_text = load(directory / "Spell.dbc")
    spell = {row[0]: spell_text(row[SPELL_NAME]) for row in spells}
    cards, card_text = load(directory / "SkillCard.dbc")
    wildcard = [row for row in cards if row[CARD_WILDCARD] and card_text(row[CARD_CLASS]) == "CLASS_HERO"]

    names = package_names({row[CARD_ITEM] for row in wildcard})
    sql = SQL.read_text(encoding="utf-8") if SQL.exists() else ""
    for value, entry in re.findall(r"UPDATE `item_template` SET `name` = '((?:[^'\\]|\\.)*)' WHERE `entry` = (\d+);", sql):
        names[int(entry)] = re.sub(r"\\(.)", r"\1", value)

    by_item = {row[CARD_ITEM]: row for row in wildcard}
    check(spell.get(by_item[2222442][CARD_SPELL]) == "Ancient of War", "SkillCard.dbc makes 2222442 grant Ancient of War")
    for entry, live in CAPTURED.items():
        check(names.get(entry) == live, f"{entry} is named {live!r}, as the Season 10 Wildcard item cache captured it")

    checked = wrong = 0
    for row in wildcard:
        prefix = PREFIX.get(card_text(row[CARD_TYPE]))
        if not prefix or "Skill Card" not in names.get(row[CARD_ITEM], "") or row[CARD_SPELL] not in spell:
            continue
        checked += 1
        if names[row[CARD_ITEM]] != f"{prefix} - {spell[row[CARD_SPELL]]}":
            wrong += 1
            if wrong <= 5:
                print(f"  {row[CARD_ITEM]}: {names[row[CARD_ITEM]]!r} grants {spell[row[CARD_SPELL]]!r}")
    check(checked > 4000 and not wrong, f"all {checked} Wildcard cards are named after the spell they grant ({wrong} are not)")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
