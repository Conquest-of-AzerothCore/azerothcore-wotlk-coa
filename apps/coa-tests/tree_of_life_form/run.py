CLI_DESCRIPTION = """Check that Tree of Life stays up, and that casting outside its tooltip's list leaves the form, without a server.

Tree of Life 33891's third effect procs Remove Tree of Life 44975 whenever the druid takes any spell, including the
form's own application, so the form never stayed up. This checks that shape in Spell.dbc (--dbc-dir), that the
tooltip still names the allowed spells, and that the script turns the proc off, takes the druid out of the form for any
other cast, and is registered and bound.
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

SOURCE = ROOT / "src/server/coa/AscensionTreeOfLife.cpp"
LOADER = ROOT / "src/server/coa/CoAScriptLoader.cpp"
SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261010_10_coa_tree_of_life_form.sql"

TAKEN_SPELL_FLAGS = 0x20 | 0x200 | 0x800 | 0x2000 | 0x8000 | 0x20000
PROC_FLAGS, PROC_CHANCE, EFFECT, AURA, TRIGGER, CLASS_MASK, DESCRIPTION = 34, 35, 71, 95, 116, 122, 170
FAMILY, FAMILY_FLAGS = 208, 209
APPLY_AURA, PROC_TRIGGER_SPELL, REMOVE_AURA = 6, 42, 164
TREE_OF_LIFE, REMOVE_TREE_OF_LIFE, TREE_OF_LIFE_ENTRY_SPELL = 33891, 44975, 65139
DRUID = 7
NAMED = {"Thorns": (467, 0, 0x100), "Nature's Grasp": (16689, 0, 0x100000), "Innervate": (29166, 1, 0x1000),
         "Barkskin": (22812, 1, 0x40000)}

failures = 0


def check(value, name):
    global failures
    failures += not value
    print(("PASS" if value else "FAIL") + ": " + name)


def load_spells(directory):
    raw = (directory / "Spell.dbc").read_bytes()
    count, fields, size, _ = struct.unpack_from("<IIII", raw, 4)
    strings = raw[20 + count * size:]
    rows = {row[0]: row for row in struct.iter_unpack(f"<{fields}i", raw[20:20 + count * size])}
    return rows, lambda offset: strings[offset:strings.index(b"\0", offset)].decode("utf-8", "replace")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    spells, text = load_spells(args.dbc_dir or dbc_dir())

    tree = spells[TREE_OF_LIFE]
    check(tree[EFFECT + 2] == APPLY_AURA and tree[AURA + 2] == PROC_TRIGGER_SPELL and
          tree[TRIGGER + 2] == REMOVE_TREE_OF_LIFE and tree[PROC_CHANCE] == 100,
          "Tree of Life procs Remove Tree of Life at 100%")
    check(tree[PROC_FLAGS] == TAKEN_SPELL_FLAGS, "the proc fires on every spell the druid takes, not on casts")
    check(not any(tree[CLASS_MASK + 2 + 3 * index] for index in range(3)),
          "the proc's class mask is empty, so nothing in the data limits which spells remove the form")
    remove = spells[REMOVE_TREE_OF_LIFE]
    check(remove[EFFECT] == REMOVE_AURA and remove[TRIGGER] == TREE_OF_LIFE, "Remove Tree of Life removes the form")
    tooltip = text(spells[TREE_OF_LIFE_ENTRY_SPELL][DESCRIPTION])
    check(all(name in tooltip for name in NAMED) and "healing spells" in tooltip and
          "spells usable while shapeshifted" in tooltip, "the tooltip names the spells the form allows")
    check(all(spells[spell][FAMILY] == DRUID and spells[spell][FAMILY_FLAGS + word] & flag
              for spell, word, flag in NAMED.values()), "the named spells carry the druid family flags the script reads")

    source = SOURCE.read_text(encoding="utf-8") if SOURCE.exists() else ""
    proc = source.split("bool CheckProc(ProcEventInfo&)", 1)[-1].split("}", 1)[0]
    check("DoCheckProc += AuraCheckProcFn(aura_ascension_tree_of_life::CheckProc)" in source and
          proc.strip().startswith("{") and "return false;" in proc, "the script turns the removal proc off")
    check("ALLSPELLHOOK_ON_SPELL_CHECK_CAST" in source and "GetShapeshiftForm() != FORM_TREE" in source and
          "RemoveAurasByType(SPELL_AURA_MOD_SHAPESHIFT)" in source and "spell->IsTriggered()" in source and
          "!strict" in source and
          "CheckShapeshift(FORM_TREE)" in source and "IsPositive()" in source and
          all(f"DRUID_{name.upper().replace(' ', '_').replace('NATURE' + chr(39) + 'S', 'NATURES')}" in source
              for name in NAMED), "a cast outside the tooltip's list takes the druid out of the form")
    check("AddSC_AscensionTreeOfLife();" in LOADER.read_text(encoding="utf-8"), "the loader registers the script")
    sql = SQL.read_text(encoding="utf-8") if SQL.exists() else ""
    check(re.search(r"\(33891,\s*'aura_ascension_tree_of_life'\)", sql) is not None, "the SQL binds the script to 33891")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
