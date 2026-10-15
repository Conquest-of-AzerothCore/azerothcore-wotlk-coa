import argparse
import os
from pathlib import Path
import re
import runpy
import sqlite3
import struct
import subprocess
import tempfile
import zipfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SQL = ROOT / 'data/sql/updates/pending_db_world/rev_1789370063248101100.sql'


def check_summons(rows):
    sql = SQL.read_text()
    db = sqlite3.connect(':memory:')
    schemas = {}
    for table, columns in re.findall(r'INSERT INTO `(\w+)`\s*\((.*?)\)', sql, re.S):
        schemas.setdefault(table, set()).update(re.findall(r'`(\w+)`', columns))
    for table, columns in schemas.items():
        db.execute(f'CREATE TABLE `{table}` (' + ','.join(f'`{c}`' for c in sorted(columns)) + ')')
    db.execute("INSERT INTO spell_script_names VALUES ('other_script',801294)")
    db.executescript(sql)
    once = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == once
    assert db.execute("SELECT COUNT(*) FROM spell_script_names WHERE ScriptName='other_script'").fetchone() == (1,)
    clone_display = db.execute('SELECT CreatureDisplayID FROM creature_template_model WHERE CreatureID=50071').fetchone()
    assert clone_display == (11686,)
    spells = rows('Spell')
    displays = rows('CreatureDisplayInfo')
    assert displays[11686][1] in rows('CreatureModelData')
    assert spells[801299][71] == 28 and spells[801299][110:114:3] == (50071, 61)
    assert rows('SummonProperties')[61][1:4] == (1, 0, 2)
    for spell, entry, duration in ((1200006, 194109, 120000), (1200007, 194112, 300000)):
        assert spells[spell][71] == 50 and spells[spell][110] == entry
        assert rows('SpellDuration')[spells[spell][40]][1] == duration
        display, = db.execute('SELECT displayId FROM gameobject_template WHERE entry=?', (entry,)).fetchone()
        assert display in rows('GameObjectDisplayInfo')
    assert db.execute('SELECT type,data0,data1,data6,data7 FROM gameobject_template WHERE entry=194109').fetchone() == (
        18, 2, 1200007, 1, 1)
    assert db.execute('SELECT type,data0 FROM gameobject_template WHERE entry=194112').fetchone() == (23, 1)
    assert 23598 in spells
    assert db.execute('SELECT ProcFlags,SpellTypeMask,SpellPhaseMask,Chance,Cooldown FROM spell_proc').fetchone() == (
        262144, 3, 2, 100, 0)
    bonuses = db.execute('SELECT direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus FROM spell_bonus_data')
    assert set(bonuses) == {(0, 0, 0, 0)}
    db.execute("UPDATE creature_template SET name='existing clone' WHERE entry=50071")
    db.execute('UPDATE creature_template_model SET CreatureDisplayID=123 WHERE CreatureID=50071')
    db.execute("UPDATE gameobject_template SET name='existing object'")
    db.executescript(sql)
    assert db.execute('SELECT name FROM creature_template').fetchone() == ('existing clone',)
    assert db.execute('SELECT CreatureDisplayID FROM creature_template_model').fetchone() == (123,)
    assert set(db.execute('SELECT name FROM gameobject_template')) == {('existing object',)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dbc-dir', type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    def rows(name):
        blob = (args.dbc_dir / (name + '.dbc')).read_bytes()
        count, fields, size = struct.unpack_from('<3I', blob, 4)
        return {r[0]: r for r in struct.iter_unpack('<' + str(fields) + 'I', blob[20:20 + count * size])}

    def signed(value):
        return struct.unpack('<i', struct.pack('<I', value))[0]

    source = (ROOT / 'src/server/coa/AscensionChronomancerTime.cpp').read_text()
    spells, durations, radii = rows('Spell'), rows('SpellDuration'), rows('SpellRadius')
    check_summons(rows)
    ids = set(map(int, re.findall(r'^    \w+ = (\d+)', source, re.M))) | {574310, 574362}
    archive = zipfile.ZipFile(ROOT / 'data/coa-world/coa-world-20260912.zip')
    rank_sql = archive.read(next(p for p in archive.namelist() if p.rsplit('/', 1)[-1] == 'spell_ranks.sql')).decode()
    ranks = [tuple(map(int, row)) for row in re.findall(r'\((\d+),(\d+),(\d+)\)', rank_sql)]
    ranks = [row for row in ranks if row[0] in (801270, 800857, 804491, 572633, 572352)]
    ids.update(row[1] for row in ranks)
    init = ['void InitData(){']
    for sid in sorted(ids):
        r = spells[sid]
        duration = signed(durations[r[40]][1]) if r[40] else 0
        init.append(f'{{auto& s=manager.infos[{sid}];s.Id={sid};s.duration={duration};s.SpellFamilyName={r[208]};'
                    f's.StackAmount={r[49]};s.MaxAffectedTargets={r[212]};s.AttributesEx4={r[8]};'
                    f's.flags={{{r[209]},{r[210]},{r[211]}}};')
        for i in range(3):
            scaling = struct.unpack('<f', struct.pack('<I', r[77+i]))[0]
            bonus = struct.unpack('<f', struct.pack('<I', r[229+i]))[0]
            radius = struct.unpack('<f', struct.pack('<I', radii[r[92+i]][1]))[0] if r[92+i] else 0
            init.append(f'{{auto& e=s.Effects[{i}];e.Effect={r[71+i]};e.ApplyAuraName={r[95+i]};'
                        f'e.BasePoints={signed(r[80+i])};e.DieSides={signed(r[74+i])};'
                        f'e.RealPointsPerLevel={scaling}f;e.BonusMultiplier={bonus}f;'
                        f'e.Amplitude={r[98+i]};e.MiscValue={signed(r[110+i])};e.radius={float(radius)}f;'
                        f'e.mask={{{r[122+i*3]},{r[123+i*3]},{r[124+i*3]}}};}}')
        init.append('}')
    init.extend(f'manager.roots[{sid}]={root};manager.infos[{sid}].rank={rank};' for root, sid, rank in ranks)
    init.append('}')
    code = (HERE / 'harness.cpp').read_text() + re.sub(r'^#include.*\n', '', source, flags=re.M)
    extract = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
    native = extract((ROOT / 'src/server/game/Spells/Auras/SpellAuraEffects.cpp').read_text(),
                     'void AuraEffect::HandleObsModPowerAuraTick(')
    calculation = re.search(r'uint32 amount = .*?;', native).group()
    code += '\nuint32 NativeManaTick(int32 m_amount,uint32 maximum){'
    code += 'struct Target{uint32 maximum;uint32 GetMaxPower(int)const{return maximum;}} unit{maximum};'
    code += 'auto target=&unit;int PowerType=0;' + calculation + 'return amount;}\n'
    code += '\n'.join(init) + (HERE / 'cases.cpp').read_text()
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-chrono-time-') as directory:
        out = Path(directory)
        cpp, exe = out / 'time.cpp', out / 'time.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: Epoch/Aeons, copied amounts, stacks, rank-aware Recovery extensions, echoes and periodic cooldowns')


if __name__ == '__main__':
    main()
