CLI_DESCRIPTION = """Check the talents that run on Ascension's Spell.dbc shape instead of their stock scripts, without a server.

Every stock binding rev_20261003_30 drops is safe only while the data still carries the behaviour, and every
replacement script reads a trigger the data names. This checks those Spell.dbc shapes (--dbc-dir) and that the SQL
binds exactly the scripts AscensionTalentDataProcs.cpp registers.
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

SOURCE = ROOT / "src/server/coa/AscensionTalentDataProcs.cpp"
SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261003_30_ascension_talent_data_procs.sql"

PROC_FLAGS, PROC_CHANCE = 34, 35
EFFECT, BASE, TARGET_A, AURA, MISC, TRIGGER = 71, 80, 86, 95, 110, 116
FAMILY, FAMILY_FLAGS = 208, 209

APPLY_AURA, ENERGIZE, DUMMY, TRIGGER_SPELL, AREA_AURA_RAID = 6, 30, 3, 64, 65
ASCENSION_RESTORE_BASE_MANA_PCT = 166
PROC_TRIGGER_SPELL, ADD_PCT_MODIFIER, LINKED, MOD_MELEE_HASTE = 42, 108, 284, 138
SPELL_COST_REFUND_ON_FAIL = 30

failures = 0


def check(value, name):
    global failures
    failures += not value
    print(("PASS" if value else "FAIL") + ": " + name)


def load_spells(directory):
    raw = (directory / "Spell.dbc").read_bytes()
    count, fields, size = struct.unpack_from("<III", raw, 4)
    return {row[0]: row for row in struct.iter_unpack(f"<{fields}i", raw[20:20 + count * size])}


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    spells = load_spells(args.dbc_dir or dbc_dir())

    def slot(spell, index):
        row = spells[spell]
        return row[EFFECT + index], row[AURA + index], row[TRIGGER + index]

    def triggers(spell, index, target):
        return spell in spells and slot(spell, index)[:3:2] == (APPLY_AURA, target) and \
            slot(spell, index)[1] == PROC_TRIGGER_SPELL

    check(all(slot(spell, 1)[0] == ENERGIZE and slot(spell, 2)[::2] == (TRIGGER_SPELL, 7922)
              for spell in (100, 6178, 11578)), "Charge ranks energize and trigger Charge Root in data")
    check(spells[64976][PROC_FLAGS] and slot(64976, 0)[2] == 65156, "Juggernaut procs from its own data")
    check(triggers(12328, 0, 997604) and spells[12328][PROC_FLAGS] == 0,
          "Sweeping Strikes triggers Sweeping Strike but has no DBC proc flags")
    check(all(triggers(spell, 0, 17941) and spells[spell][PROC_FLAGS] & 0x40000 for spell in (18094, 18095)),
          "Nightfall ranks proc Shadow Trance on periodic damage")
    check(all(triggers(spell, 1, 67545) for spell in (31656, 31657, 31658)) and
          slot(67545, 0)[0] == ASCENSION_RESTORE_BASE_MANA_PCT, "Empowered Fire restores base mana through 67545")
    check(all(slot(spell, 0)[0] == AREA_AURA_RAID for spell in (53379, 53484, 53648)),
          "Swift Retribution ranks are raid-area auras")
    check(slot(53563, 0)[1:] == (LINKED, 53651), "Beacon of Light links Light's Beacon")
    check(all(slot(spell, 0)[1] == ADD_PCT_MODIFIER and spells[spell][MISC] == SPELL_COST_REFUND_ON_FAIL and
              spells[spell][BASE] < 0 for spell in (31244, 31245)),
          "Quick Recovery refunds cost on a failed hit through a spell modifier")

    check(triggers(29441, 0, 29442) and triggers(29444, 0, 29446) and
          all(slot(spell, 0)[0] == ENERGIZE for spell in (29442, 29446)),
          "Magic Absorption ranks trigger the mana energize whose value is the percent")
    check(all(triggers(spell, 0, 48517) and triggers(spell, 1, 48519) for spell in (48516, 48521, 48525)) and
          spells[48517][AURA] == ADD_PCT_MODIFIER and 48518 in spells,
          "Eclipse ranks carry both proc triggers; Solar and Lunar exist")
    check(all(triggers(spell, 0, 48542) and spells[spell][PROC_FLAGS] == 0 for spell in (48539, 48544, 48545)) and
          [spells[spell][PROC_CHANCE] for spell in (48539, 48544, 48545)] == [5, 10, 15] and
          [spells[48542][MISC + index] for index in range(3)] == [0, 3, 1],
          "Revitalize ranks trigger the mana/energy/rage energize at 5/10/15% with no DBC proc flags")
    check(all(triggers(spell, 0, 9931095) and spells[spell][PROC_FLAGS] == 0 for spell in (51664, 51665, 51667)) and
          spells[9931095][EFFECT] == DUMMY and spells[9931095][TARGET_A] == 1,
          "Cut to the Chase ranks trigger the self-dummy refresh with no DBC proc flags")
    check(all(spells[spell][FAMILY] == 8 and spells[spell][FAMILY_FLAGS] & 0x40000 and
              spells[spell][AURA + 1] == MOD_MELEE_HASTE for spell in (5171, 6774)),
          "Slice and Dice is the rogue melee-haste aura the refresh looks up")

    source = SOURCE.read_text(encoding="utf-8")
    registered = set(re.findall(r"RegisterSpellScript\((\w+)\)", source))
    sql = SQL.read_text(encoding="utf-8")
    insert = sql.split("INSERT INTO `spell_script_names`", 1)[1].split(";", 1)[0]
    bound = set(re.findall(r"'(\w+)'", insert))
    check(registered and registered == bound, "the SQL binds exactly the scripts the source registers")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
