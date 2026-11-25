import json
from pathlib import Path
import sqlite3
import sys


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'apps/coa-world-content/professions'))
import build_remaining


data = json.loads(build_remaining.BASELINE.read_text())
build_remaining.validate(data)
sql = build_remaining.migration(data)
migration = ROOT/'data/sql/updates/pending_db_world/rev_20261124_00_coa_tbc_remaining_professions.sql'
assert sql == migration.read_text()
assert build_remaining.header(data) == (ROOT/'src/server/coa/CoAProfessionRescaleRemainingData.h').read_text()

db = sqlite3.connect(':memory:')
columns = sorted({'RequiredLevel'} | {key for row in data['equipment'] for key in row['changes']})
db.execute('CREATE TABLE item_template (entry INTEGER PRIMARY KEY, ' + ', '.join(columns) + ')')
db.executescript('''
CREATE TABLE coa_profession_item_budget (
    entry INTEGER PRIMARY KEY, profession_id, expansion, original_item_level, item_level, pve_power, pvp_power);
CREATE TABLE item_enchantment_template (entry, ench, chance, PRIMARY KEY (entry, ench));
CREATE TABLE npc_trainer (ID, SpellID, ReqLevel, PRIMARY KEY (ID, SpellID));
CREATE TABLE trainer_spell (TrainerId, SpellId, ReqLevel, PRIMARY KEY (TrainerId, SpellId));
CREATE TABLE quest_template (ID INTEGER PRIMARY KEY, MinLevel);
''')
expected = {}
for row in data['equipment']:
    values = {key: float(value) for key, value in row['before'].items()}
    placeholders = ', '.join(['?'] * (len(values) + 1))
    db.execute(f'INSERT INTO item_template (entry, {", ".join(values)}) VALUES ({placeholders})',
               (row['entry'], *values.values()))
    expected[row['entry']] = row['changes']
for row in data['item_gates']:
    db.execute('INSERT INTO item_template (entry, RequiredLevel) VALUES (?, ?)', (row['entry'], row['required']))
    expected[row['entry']] = {'RequiredLevel': 60}
for table, rows in data['trainer_gates'].items():
    keys = ('ID','SpellID','ReqLevel') if table == 'npc_trainer' else ('TrainerId','SpellId','ReqLevel')
    db.executemany(f'INSERT INTO {table} VALUES (?, ?, ?)', ([int(row[key]) for key in keys] for row in rows))
db.executemany('INSERT INTO quest_template VALUES (?, ?)',
               [(int(row['ID']), int(row['MinLevel'])) for row in data['quest_gates']])
db.executemany('INSERT INTO item_template (entry, RequiredLevel) VALUES (?, ?)',
               [(24122,60), (40111,80), (33447,70)])
db.commit()

replayable = sql.replace('START TRANSACTION;', 'BEGIN;')
db.executescript(replayable)
first = list(db.iterdump())
db.executescript(replayable)
assert first == list(db.iterdump())
for entry, fields in expected.items():
    current = db.execute(f'SELECT {", ".join(fields)} FROM item_template WHERE entry=?', (entry,)).fetchone()
    assert current == tuple(fields.values())
controls = db.execute('SELECT RequiredLevel FROM item_template WHERE entry IN (24122,33447,40111) ORDER BY entry')
assert controls.fetchall() == [(60,), (70,), (80,)]
budgets = db.execute('SELECT COUNT(*), MIN(item_level), MAX(item_level) FROM coa_profession_item_budget').fetchone()
assert budgets == (len(data['equipment']), 60, 77)
assert db.execute('SELECT MAX(ReqLevel) FROM npc_trainer').fetchone() == (60,)
assert db.execute('SELECT MAX(ReqLevel) FROM trainer_spell').fetchone() == (60,)
assert db.execute('SELECT MAX(MinLevel) FROM quest_template').fetchone() == (60,)
print(f'PASS: {len(expected)} item updates, trainer and quest caps, generated artifacts, and SQL replay')
