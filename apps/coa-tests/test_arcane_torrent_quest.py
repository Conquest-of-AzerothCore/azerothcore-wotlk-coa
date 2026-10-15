CLI_DESCRIPTION = """Exercise the Thirst Unending migration against existing SmartAI data in memory."""

import argparse
from pathlib import Path
import re
import sqlite3
import struct


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "data/sql/updates/pending_db_world/rev_1789353356981639400.sql"
ENTRIES = (15273, 15274, 15294, 15298)
SPELLS = tuple(range(814286, 814293))


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--before", action="store_true", help="Reproduce missing credit without the migration.")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    source = (ROOT / "data/sql/base/db_world/smart_scripts.sql").read_text(encoding="utf-8")
    columns = re.findall(r'^  `(\w+)`', source[:source.index("PRIMARY KEY")], re.M)
    rows = re.findall(r"\((?:15273|15274|15294|15298),0,[^']*'(?:\\.|[^'\\])*'\)", source)
    assert len(rows) == 12
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE smart_scripts (" + ",".join('`' + c + '`' for c in columns)
               + ",PRIMARY KEY(entryorguid,source_type,id,link))")
    db.executescript("INSERT INTO smart_scripts VALUES " + ",".join(rows).replace("\\'", "''") + ";")
    original = db.execute("SELECT * FROM smart_scripts ORDER BY entryorguid,id").fetchall()
    for entry, source_type in ((99999, 0), (15274, 9)):
        row = list(original[0])
        row[0], row[1] = entry, source_type
        db.execute("INSERT INTO smart_scripts VALUES (" + ",".join("?" for _ in columns) + ")", row)
    unrelated = db.execute("SELECT * FROM smart_scripts WHERE entryorguid=99999 OR source_type=9").fetchall()
    if not args.before:
        sql = MIGRATION.read_text(encoding="utf-8").replace("\\'", "''")
        db.executescript(sql)
        once = list(db.iterdump())
        db.executescript(sql)
        assert list(db.iterdump()) == once
    for row in original:
        assert db.execute("SELECT * FROM smart_scripts WHERE entryorguid=? AND source_type=0 AND id=?",
                          (row[0], row[2])).fetchone() == row
    assert db.execute("SELECT * FROM smart_scripts WHERE entryorguid=99999 OR source_type=9").fetchall() == unrelated
    for entry in ENTRIES:
        for spell in SPELLS:
            rows = db.execute("SELECT action_type,action_param1,target_type,event_flags FROM smart_scripts "
                              "WHERE entryorguid=? AND source_type=0 AND event_type=8 AND event_param1=?",
                              (entry, spell)).fetchall()
            assert rows == [(11, 61314, 7, 1)], (entry, spell, rows)
    assert db.execute("SELECT COUNT(*) FROM smart_scripts WHERE event_param1=12345").fetchone()[0] == 0
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        magic, count, fields, size, _ = struct.unpack_from("<4s4I", raw)
        assert magic == b"WDBC" and fields == 234 and size == 936
        spells = {row[0]: row for row in struct.iter_unpack("<234I", raw[20:20 + count * size])}
        for spell in SPELLS:
            assert spells[spell][71] == 6 and spells[spell][95] == 27
            assert spells[spell][86] == 22 and spells[spell][89] == 15
        assert spells[61314][71] == 134 and spells[61314][110] == 15468
    print("PASS: 28 CoA quest-credit matches, preserved stock/combat rows, scoped replacement and idempotence")


if __name__ == "__main__":
    main()
