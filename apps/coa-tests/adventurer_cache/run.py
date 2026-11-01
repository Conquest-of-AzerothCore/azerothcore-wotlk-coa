import csv
from pathlib import Path
import re
import sqlite3
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PENDING = ROOT / 'data/sql/updates/pending_db_world'
SATCHEL, CACHE, RARE_CACHE = 1397884, 1397885, 1397886


def main():
    archive = zipfile.ZipFile(ROOT / 'data/coa-world/coa-world-20260912.zip')

    def table(name):
        return archive.read(next(p for p in archive.namelist() if p.rsplit('/', 1)[-1] == name + '.sql')).decode()

    sql = (PENDING / 'rev_1789371937554667200.sql').read_text()
    variants_sql = (PENDING / 'rev_1789486726522615900.sql').read_text()
    satchel_sql = (PENDING / 'rev_20260930_00_coa_adventurer_satchel_loot.sql').read_text()
    gear_sql = (PENDING / 'rev_20261028_70_adventurer_cache_gear.sql').read_text()
    supplies, gear = (set(map(int, re.findall(r'\d+', group)))
                      for group in re.findall(r'IN \(\n([\d,\s]+)\)', gear_sql))
    candidates = set(map(int, re.findall(r'\b\d+\b', sql + variants_sql + satchel_sql + gear_sql)))
    references = []
    for match in re.finditer(r'\((\d+),(\d+),(\d+),', table('reference_loot_template')):
        entry, item, reference = map(int, match.groups())
        if 1010000 <= entry <= 1039999 and reference == 0:
            references.append((entry, item, reference))
            candidates.add(item)
    data = table('item_template')
    columns = re.findall(r'^  `([^`]+)`', data, re.M)
    fields = ['entry', 'class', 'subclass', 'Quality', 'bonding', 'RequiredLevel', 'ItemLevel', 'maxcount', 'Flags']
    rows = []
    for match in re.finditer(r'\((\d+),', data):
        if int(match[1]) not in candidates:
            continue
        end = min(p for p in (data.find('),(', match.start()), data.find(');', match.start())) if p >= 0)
        values = next(csv.reader([data[match.start() + 1:end]], quotechar="'", escapechar='\\'))
        row = dict(zip(columns, values))
        rows.append(tuple(int(row[f]) for f in fields) + (row['ScriptName'],))
    db = sqlite3.connect(':memory:')
    db.execute('CREATE TABLE item_template (' + ','.join('`' + f + '`' for f in fields) + ',ScriptName)')
    db.executemany('INSERT INTO item_template VALUES (' + ','.join('?' for _ in range(10)) + ')', rows)
    db.execute('CREATE TABLE reference_loot_template (Entry,Item,Reference)')
    db.executemany('INSERT INTO reference_loot_template VALUES (?,?,?)', references)
    db.executescript('''
        CREATE TABLE item_loot_template (Entry,Item,Reference,Chance,QuestRequired,LootMode,GroupId,
            MinCount,MaxCount,Comment);
        INSERT INTO item_loot_template VALUES (123,117,0,100,0,1,0,1,1,'unrelated');
    ''')
    assert db.execute('SELECT Flags & 4,ScriptName FROM item_template WHERE entry=1397885').fetchone() == (0, '')
    assert not db.execute('SELECT Item FROM item_loot_template WHERE Entry=1397885').fetchall()
    before = list(db.execute('SELECT * FROM item_template WHERE entry!=1397885'))
    db.executescript(sql)
    once = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == once
    assert list(db.execute('SELECT * FROM item_template WHERE entry!=1397885')) == before
    assert db.execute('SELECT Comment FROM item_loot_template WHERE Entry=123').fetchone() == ('unrelated',)
    assert db.execute('SELECT Flags & 4,ScriptName FROM item_template WHERE entry=1397885').fetchone() == (
        4, 'item_ascension_adventurer_cache')
    before_variants = list(db.execute('SELECT * FROM item_template WHERE entry NOT IN (1397884,1397886)'))
    db.executescript(variants_sql)
    once = list(db.iterdump())
    db.executescript(variants_sql)
    assert list(db.iterdump()) == once
    assert list(db.execute('SELECT * FROM item_template WHERE entry NOT IN (1397884,1397886)')) == before_variants

    db.executescript(satchel_sql)
    satchel_pool = list(db.execute('SELECT * FROM item_loot_template WHERE Entry=? ORDER BY Item', (SATCHEL,)))
    assert satchel_pool
    db.executescript(gear_sql)
    once = list(db.iterdump())
    db.executescript(gear_sql)
    assert list(db.iterdump()) == once
    assert list(db.execute('SELECT * FROM item_loot_template WHERE Entry=? ORDER BY Item', (SATCHEL,))) == satchel_pool
    assert db.execute('SELECT Comment FROM item_loot_template WHERE Entry=123').fetchone() == ('unrelated',)

    known = {row[0] for row in rows}
    assert gear <= known and supplies <= known, sorted((gear | supplies) - known)[:10]
    quality = dict(db.execute('SELECT entry,Quality FROM item_template'))
    for cache, highest in ((CACHE, 2), (RARE_CACHE, 3)):
        loot = list(db.execute('''SELECT l.Item,l.Reference,l.Chance,l.GroupId,l.MaxCount,t.class,t.Quality,t.bonding
            FROM item_loot_template l JOIN item_template t ON t.entry=l.Item WHERE l.Entry=?''', (cache,)))
        assert {row[0] for row in loot} == supplies | {item for item in gear if quality[item] <= highest}
        assert all(row[1:4] == (0, 0, 1) for row in loot)
        for item, _, _, _, max_count, item_class, item_quality, bonding in loot:
            if item in supplies:
                assert max_count == 3 and item_quality == 1 and item_class not in (2, 4)
            else:
                assert max_count == 1 and item_class in (2, 4) and item_quality in (2, 3)
                assert bonding == 2 if item_quality == 2 else bonding in (1, 2)
    print(f'PASS: satchel pool kept ({len(satchel_pool)} rows); caches hold {len(supplies)} supplies and '
          f'{len(gear)} gear items; SQL replay/preservation')


if __name__ == '__main__':
    main()
