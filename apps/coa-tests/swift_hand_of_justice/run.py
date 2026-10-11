CLI_DESCRIPTION = """Check that Swift Hand of Justice procs on a kill, without a server.

Its trigger aura 59906 has no ProcFlags in Ascension's Spell.dbc, and the stock spell_proc row leaves ProcFlags at 0,
which means "use the DBC". This checks that shape (--dbc-dir) and that the SQL gives the row PROC_FLAG_KILL while
keeping its experience-or-honor requirement.
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

SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261010_20_swift_hand_of_justice_proc.sql"
BASE = ROOT / "data/sql/base/db_world/spell_proc.sql"
PROC_FLAGS, EFFECT, AURA, TRIGGER_HEAL_ITEM = 34, 71, 95, 59906
APPLY_AURA, DUMMY, PROC_FLAG_KILL, REQ_EXP_OR_HONOR = 6, 4, 0x2, 0x1

failures = 0


def check(value, name):
    global failures
    failures += not value
    print(("PASS" if value else "FAIL") + ": " + name)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    raw = ((args.dbc_dir or dbc_dir()) / "Spell.dbc").read_bytes()
    count, fields, size, _ = struct.unpack_from("<IIII", raw, 4)
    rows = {row[0]: row for row in struct.iter_unpack(f"<{fields}i", raw[20:20 + count * size])}
    aura = rows[TRIGGER_HEAL_ITEM]
    check(aura[EFFECT] == APPLY_AURA and aura[AURA] == DUMMY and aura[PROC_FLAGS] == 0,
          "59906 is a dummy aura with no ProcFlags in Spell.dbc")

    base = BASE.read_text(encoding="utf-8")
    stock = re.search(r"\(59906,([^)]*)\)", base)
    values = [int(v.strip(), 0) for v in stock.group(1).split(",")] if stock else []
    check(len(values) == 15 and values[5] == 0 and values[9] & REQ_EXP_OR_HONOR,
          "the stock spell_proc row has ProcFlags 0 and requires experience or honor")
    sql = SQL.read_text(encoding="utf-8") if SQL.exists() else ""
    check(re.search(r"UPDATE `spell_proc` SET `ProcFlags` = 0x2 WHERE `SpellId` = 59906;", sql) is not None,
          "the SQL makes the row proc on a kill")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
