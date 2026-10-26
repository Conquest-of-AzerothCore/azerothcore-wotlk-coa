from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[3]


def main():
    db = sqlite3.connect(':memory:')
    db.execute('CREATE TABLE battleground_template (ID INTEGER PRIMARY KEY, MinPlayersPerTeam INTEGER, '
               'MaxPlayersPerTeam INTEGER, MinLvl INTEGER, MaxLvl INTEGER)')
    base = (ROOT / 'data/sql/base/db_world/battleground_template.sql').read_text()
    rows = [tuple(map(int, match)) for match in re.findall(r'^\((\d+),(\d+),(\d+),(\d+),(\d+),', base, re.M)]
    assert rows
    db.executemany('INSERT INTO battleground_template VALUES (?,?,?,?,?)', rows)
    before = {row[0]: row for row in rows}
    sql = (ROOT / 'data/sql/updates/pending_db_world/rev_20261026_01_small_battleground_starts.sql').read_text()
    db.executescript(sql)
    after = list(db.execute('SELECT * FROM battleground_template ORDER BY ID'))
    selected = {1, 2, 3, 7, 9, 30, 32}
    assert selected <= before.keys()
    for row in after:
        assert row == ((row[0], 1, *before[row[0]][2:]) if row[0] in selected else before[row[0]])
    db.executescript(sql)
    assert after == list(db.execute('SELECT * FROM battleground_template ORDER BY ID'))
    print('PASS: seven battleground minima, unchanged team caps and level gates, arenas preserved, idempotent replay')


if __name__ == '__main__':
    main()
