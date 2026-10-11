CLI_DESCRIPTION = """Check the Hero talents whose trigger auras have no ProcFlags in Ascension's Spell.dbc, without a server.

Omen of Clarity 16864, Double Down 275235 and Hydromancer 272057 are PROC_TRIGGER_SPELL auras with ProcFlags 0 in
Spell.dbc and no spell_proc row giving any, so they never proc. This checks that shape (--dbc-dir), that the spells
the tooltips name carry the family flags the rows match, and that the SQL gives each row its flags.
No database, server build or game client is needed.
"""

import argparse
from pathlib import Path
import re
import struct
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261010_21_coa_hero_talent_proc_flags.sql"
PROC_FLAGS, PROC_CHANCE, EFFECT, AURA, TRIGGER, DESCRIPTION, FAMILY, FAMILY_FLAGS = 34, 35, 71, 95, 116, 170, 208, 209
APPLY_AURA, PROC_TRIGGER_SPELL = 6, 42
OMEN_OF_CLARITY, OMEN_OF_CLARITY_REBORN, DOUBLE_DOWN, HYDROMANCER = 16864, 1116864, 275235, 272057
SINISTER_STRIKE, THRUST, ECLIPSE_STRIKE, BACKSTAB = 1752, 274269, 274510, 53
FROSTBOLT, FROST_NOVA, FROSTFIRE_BOLT = 116, 122, 44614

failures = 0


def check(value, name):
    global failures
    failures += not value
    print(("PASS" if value else "FAIL") + ": " + name)


def load(directory):
    raw = (directory / "Spell.dbc").read_bytes()
    count, fields, size, _ = struct.unpack_from("<IIII", raw, 4)
    strings = raw[20 + count * size:]
    rows = {row[0]: row for row in struct.iter_unpack(f"<{fields}i", raw[20:20 + count * size])}
    return rows, lambda offset: strings[offset:strings.index(b"\0", offset)].decode("utf-8", "replace")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    spells, text = load(args.dbc_dir or dbc_dir())
    flags = lambda spell, word: spells[spell][FAMILY_FLAGS + word] & 0xffffffff

    for spell in (OMEN_OF_CLARITY, DOUBLE_DOWN, HYDROMANCER):
        row = spells[spell]
        check(row[EFFECT] == APPLY_AURA and row[AURA] == PROC_TRIGGER_SPELL and row[TRIGGER] and row[PROC_FLAGS] == 0,
              f"{spell} is a trigger aura with no ProcFlags in Spell.dbc")
    check(spells[OMEN_OF_CLARITY_REBORN][PROC_FLAGS] & 0xffffffff == 0x14004 and spells[OMEN_OF_CLARITY][PROC_CHANCE] == 6,
          "Omen of Clarity's Reborn copy procs on auto attacks, damage and healing; the stock row keeps 6%")
    check("2 second cooldown" in text(spells[OMEN_OF_CLARITY][DESCRIPTION]), "Omen of Clarity's tooltip names a 2 second cooldown")
    check(all(flags(s, 0) & 0x2 for s in (SINISTER_STRIKE, THRUST, ECLIPSE_STRIKE)) and not flags(BACKSTAB, 0) & 0x2,
          "Sinister Strike and its transforms share family flag 0x2; Backstab does not")
    check(flags(FROSTBOLT, 0) & 0x20 and flags(FROST_NOVA, 0) & 0x40 and flags(FROSTFIRE_BOLT, 1) & 0x1000,
          "Frostbolt, Frost Nova and Frostfire Bolt carry the flags Hydromancer's row matches")

    sql = SQL.read_text(encoding="utf-8") if SQL.exists() else ""
    check(re.search(r"SET `ProcFlags` = 0x14004, `SpellTypeMask` = 0x3, `SpellPhaseMask` = 0x2, `ProcsPerMinute` = 0,"
                    r"\s+`Chance` = 0, `Cooldown` = 2000\s+WHERE `SpellId` = 16864;", sql) is not None,
          "Omen of Clarity's row procs from auto attacks, damage and healing with a 2 second cooldown")
    check("(275235, 0, 8, 0x2, 0, 0, 0x10, 0x1, 0x2," in sql, "Double Down procs on melee hits of family flag 0x2")
    check("(272057, 0, 3, 0x60, 0x1000, 0, 0x10000, 0x1, 0x2," in sql,
          "Hydromancer procs on harmful spell hits of Frostbolt, Frost Nova and Frostfire Bolt")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
