from pathlib import Path
import sqlite3

root = Path(__file__).resolve().parents[3]
migration = root / 'data/sql/updates/pending_db_world/rev_20261021_130_fel_enchanted_warchest.sql'
db = sqlite3.connect(':memory:')
db.executescript('''
CREATE TABLE item_template (entry INTEGER PRIMARY KEY, Flags INTEGER, spellid_1 INTEGER);
CREATE TABLE item_loot_template (Entry INTEGER, Item INTEGER, Reference INTEGER, Chance REAL,
QuestRequired INTEGER, LootMode INTEGER, GroupId INTEGER, MinCount INTEGER, MaxCount INTEGER, Comment TEXT,
PRIMARY KEY (Entry, Item));
INSERT INTO item_template VALUES (657112, 128, 60034), (999, 16, 42);
INSERT INTO item_loot_template VALUES (657112,1414012,0,100,0,1,0,1,1,'obsolete reward'),
(999,1414012,0,100,0,1,0,1,1,'other container'),(657112,123,0,100,0,1,0,1,1,'unrelated');
''')
expected = {99489: 1, 1903515: 1, 99492: 1, 597602: 1, 348450: 4}
for _ in range(2):
    db.executescript(migration.read_text())
    assert db.execute('SELECT Flags,spellid_1 FROM item_template WHERE entry=657112').fetchone() == (132, 0)
    assert db.execute('SELECT Flags,spellid_1 FROM item_template WHERE entry=999').fetchone() == (16, 42)
    rows = db.execute('SELECT Item,Reference,Chance,QuestRequired,LootMode,GroupId,MinCount,MaxCount '
                      'FROM item_loot_template WHERE Entry=657112 AND Item!=123').fetchall()
    assert {r[0] for r in rows} == set(expected)
    for item, reference, chance, quest, mode, group, low, high in rows:
        assert (reference, chance, quest, mode, group, low, high) == (0, 100, 0, 1, 0, expected[item], expected[item])
    assert db.execute('SELECT COUNT(*) FROM item_loot_template WHERE Entry=999 OR Item=123').fetchone()[0] == 2
print('PASS: five guaranteed reward types, four non-Unique satchels selected, obsolete reward removed, '
      'repeat apply, existing flag bits and unrelated records preserved. SQLite SQL-shape fixture; no gameplay.')
