from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[3]
def migration(filename):
    path = ROOT / 'data/sql/updates/pending_db_world' / filename
    return path if path.exists() else Path(str(path) + '.draft')


COMBAT = migration('rev_20261121_10_coa_hellfire_outdoor_combat.sql')
QUESTS = migration('rev_20261121_11_coa_hellfire_outdoor_quests.sql')
db = sqlite3.connect(':memory:')
db.executescript('''
CREATE TABLE creature_template (entry INTEGER PRIMARY KEY, level INTEGER, health INTEGER);
INSERT INTO creature_template VALUES (18728,73,1000);
CREATE TABLE quest_template (ID INTEGER PRIMARY KEY, QuestLevel INTEGER, MinLevel INTEGER,
SuggestedGroupNum INTEGER, RewardMoney INTEGER, RewardXPDifficulty INTEGER);
INSERT INTO quest_template VALUES (10136,63,58,3,87000,7);
INSERT INTO quest_template VALUES (10400,63,58,3,87000,7);
INSERT INTO quest_template VALUES (9342,61,255,0,1000,6);
INSERT INTO quest_template VALUES (9572,62,59,0,54000,6);
INSERT INTO quest_template VALUES (9734,63,60,0,10000,6);
INSERT INTO quest_template VALUES (11002,70,70,0,10000,6);
CREATE TABLE quest_template_addon (ID INTEGER PRIMARY KEY, MaxLevel INTEGER);
INSERT INTO quest_template_addon VALUES (10136,0);
INSERT INTO quest_template_addon VALUES (9342,0);
''')

columns = ['entry INTEGER PRIMARY KEY', 'ItemLevel INTEGER', 'RequiredLevel INTEGER',
           'armor INTEGER', 'block INTEGER', 'description TEXT', 'socketBonus INTEGER DEFAULT 0', 'RandomProperty INTEGER DEFAULT 0', 'RandomSuffix INTEGER DEFAULT 0']
columns += [f'{name}{i} INTEGER DEFAULT 0' for name in ['stat_type', 'stat_value'] for i in range(1, 11)]
columns += [f'{name}_{i} INTEGER DEFAULT 0' for name in ['spellid', 'spelltrigger'] for i in range(1, 6)]
columns += [f'{name}_res INTEGER DEFAULT 0' for name in ['holy', 'fire', 'nature', 'frost', 'shadow', 'arcane']]
columns += [f'dmg_{side}{i} REAL DEFAULT 0' for side in ['min', 'max'] for i in [1, 2]]
db.execute('CREATE TABLE item_template (' + ','.join(columns) + ')')
db.executemany('INSERT INTO item_template (entry,ItemLevel,RequiredLevel,armor,block,spellid_1) VALUES (?,?,?,?,?,?)',
               [(25478,93,60,120,0,101625), (28064,93,60,0,0,37736),
                (25787,93,60,0,0,32600), (24575,81,60,0,0,0), (24589,84,60,0,0,0), (999,200,80,500,0,0)])
db.executescript('CREATE TABLE item_enchantment_template (entry INTEGER, ench INTEGER, chance REAL, PRIMARY KEY(entry,ench)); INSERT INTO item_enchantment_template VALUES (8600,8600,1.02041);')
spell_columns = re.findall(r'^\s*`([^`]+)` ',
                          (ROOT / 'data/sql/base/db_world/spell_dbc.sql').read_text(), re.M)
db.execute('CREATE TABLE spell_dbc (' + ','.join('`' + name + '` NUMERIC' for name in spell_columns) + ')')
db.execute('INSERT INTO spell_dbc (ID,EffectBasePoints_1) VALUES (32600,191)')
db.execute('CREATE TABLE spell_script_names (spell_id INTEGER, ScriptName TEXT, UNIQUE(spell_id,ScriptName))')

def apply():
    db.executescript(re.sub(r'\) ENGINE=InnoDB;', ');', COMBAT.read_text()))
    db.executescript(QUESTS.read_text())
    for filename in ['rev_20261121_12_coa_hellfire_outdoor_equipment.sql',
                     'rev_20261121_13_coa_hellfire_item_effects.sql',
                     'rev_20261121_14_coa_hellfire_random_properties.sql',
                     'rev_20261121_15_coa_hellfire_original_health_budgets.sql',
                     'rev_20261121_16_coa_hellfire_ilvl63_equipment.sql',
                     'rev_20261121_17_coa_hellfire_ilvl63_affixes.sql',
                     'rev_20261121_18_coa_hellfire_ilvl63_effects.sql']:
        db.executescript(re.sub(r'\) ENGINE=InnoDB;', ');', migration(filename).read_text()))

apply()
assert db.execute('SELECT level,health FROM coa_zone_creature_budget WHERE zone_id=3483 AND entry=16972').fetchone() == (60,106410)
for entry, expected in [(19701,85150), (16863,134000), (16867,97090)]:
    assert db.execute('SELECT health FROM coa_zone_creature_budget WHERE zone_id=3483 AND entry=?', (entry,)).fetchone() == (expected,)
assert db.execute('SELECT health FROM coa_zone_creature_budget WHERE zone_id=3483 AND entry=16903').fetchone() == (10000,)
assert db.execute('SELECT level,health FROM coa_zone_creature_budget WHERE zone_id=3483 AND entry=18728').fetchone() == (63,3600000)
assert db.execute('SELECT level,health FROM creature_template WHERE entry=18728').fetchone() == (73,1000)
assert db.execute('SELECT zone_order,reward_level,reward_min,reward_max FROM coa_zone_scaling').fetchone() == (0,63,59,66)
assert db.execute('SELECT QuestLevel,MinLevel,SuggestedGroupNum,RewardMoney,RewardXPDifficulty FROM quest_template WHERE ID=10136').fetchone() == (60,60,5,87000,7)
for entry, expected in [(9342,(61,255)), (9572,(62,59)), (9734,(63,60)), (11002,(70,70))]:
    assert db.execute('SELECT QuestLevel,MinLevel FROM quest_template WHERE ID=?', (entry,)).fetchone() == expected
assert db.execute('SELECT MaxLevel FROM quest_template_addon WHERE ID=10136').fetchone() == (60,)
assert db.execute('SELECT ItemLevel,RequiredLevel FROM item_template WHERE entry=25478').fetchone() == (65,60)
assert db.execute('SELECT spellid_1,stat_type1,stat_value1 FROM item_template WHERE entry=28064').fetchone() == (0,38,18)
assert db.execute('SELECT ItemLevel,RequiredLevel,armor FROM item_template WHERE entry=999').fetchone() == (200,80,500)
assert db.execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=32600').fetchone() == (191,)
assert db.execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=8700000').fetchone() == (119,)
assert db.execute('SELECT spellid_1 FROM item_template WHERE entry=25787').fetchone() == (8710001,)
assert db.execute('SELECT COUNT(*) FROM coa_zone_item_budget WHERE item_level NOT BETWEEN 59 AND 66').fetchone() == (0,)

assert db.execute('SELECT ItemLevel,RandomProperty FROM item_template WHERE entry=24575').fetchone() == (81,8600)
assert db.execute('SELECT ItemLevel,RandomProperty FROM item_template WHERE entry=24589').fetchone() == (84,8600)
assert db.execute('SELECT chance FROM item_enchantment_template WHERE entry=8600 AND ench=8600').fetchone() == (1.02041,)
assert db.execute('SELECT COUNT(*) FROM coa_zone_property_mapping a LEFT JOIN coa_zone_property_mapping b ON b.entry=a.entry AND b.zone_id=a.zone_id AND b.original_property=a.scaled_property WHERE b.scaled_property IS NULL OR b.scaled_property<>a.scaled_property').fetchone() == (0,)

assert db.execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=8710001').fetchone() == (123,)
assert db.execute('SELECT EffectBasePoints_1,EffectBasePoints_2 FROM spell_dbc WHERE ID=8710003').fetchone() == (147,147)
assert db.execute('SELECT original_property,scaled_property FROM coa_zone_property_mapping WHERE entry=24575 AND original_property=400').fetchone() == (400,8600)
assert db.execute('SELECT COUNT(*) FROM coa_zone_item_budget').fetchone() == (196,)
assert db.execute('SELECT COUNT(*) FROM coa_zone_item_budget WHERE entry IN (24575,24589,7734)').fetchone() == (0,)
assert db.execute('SELECT COUNT(*) FROM item_enchantment_template WHERE entry=6024575').fetchone() == (0,)
before = '\n'.join(db.iterdump())
apply()
assert '\n'.join(db.iterdump()) == before
print('PASS: zone budgets, quest gates, unchanged gold fields, disabled quests and instance exclusion; '
      'equipment, role-neutral relics and separate item effects; identical data on reapplication')
