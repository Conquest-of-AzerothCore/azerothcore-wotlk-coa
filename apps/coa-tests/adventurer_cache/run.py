import csv
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    archive = zipfile.ZipFile(ROOT / 'data/coa-world/coa-world-20260912.zip')

    def table(name):
        return archive.read(next(p for p in archive.namelist() if p.rsplit('/', 1)[-1] == name + '.sql')).decode()

    sql = (ROOT / 'data/sql/updates/pending_db_world/rev_1789371937554667200.sql').read_text()
    variants_sql = (ROOT / 'data/sql/updates/pending_db_world/rev_1789486726522615900.sql').read_text()
    candidates = set(map(int, re.findall(r'\b\d+\b', sql + variants_sql)))
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
    reference = db.execute('''SELECT Item,Reference,Chance,QuestRequired,LootMode,GroupId,MinCount,MaxCount
        FROM item_loot_template WHERE Entry=1397885 ORDER BY Item''').fetchall()
    for entry in (1397884, 1397886):
        assert db.execute('SELECT Flags & 4,ScriptName FROM item_template WHERE entry=?', (entry,)).fetchone() == (
            4, 'item_ascension_adventurer_cache')
        assert db.execute('''SELECT Item,Reference,Chance,QuestRequired,LootMode,GroupId,MinCount,MaxCount
            FROM item_loot_template WHERE Entry=? ORDER BY Item''', (entry,)).fetchall() == reference
    pool = list(db.execute('''SELECT t.entry,t.class,t.subclass,t.Quality,t.RequiredLevel,t.ItemLevel,l.MaxCount
        FROM item_template t JOIN item_loot_template l ON t.entry=l.Item WHERE l.Entry=1397885'''))
    assert len(pool) > 100
    assert {r[3] for r in pool if r[1] == 4} == {1, 2, 3}
    assert all(r[6] == (1 if r[1] == 4 else 3) for r in pool)
    source = (ROOT / 'src/server/coa/AscensionAdventurerCache.cpp').read_text()
    code = (HERE / 'harness.cpp').read_text() + re.sub(r'^#include.*\n', '', source, flags=re.M)
    code += '\nvoid InitPool(){\n'
    for entry, cls, subclass, quality, required, level, _ in pool:
        code += f'manager.items[{entry}]={{{entry},{cls},{subclass},{quality},{required},{level}}};\n'
    code += '}\n' + (HERE / 'cases.cpp').read_text()
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-adventurer-cache-') as directory:
        out = Path(directory)
        cpp, exe = out / 'cache.cpp', out / 'cache.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print(f'PASS: three containers, {len(pool)} existing rewards; selection; use guards; SQL replay/preservation')


if __name__ == '__main__':
    main()
