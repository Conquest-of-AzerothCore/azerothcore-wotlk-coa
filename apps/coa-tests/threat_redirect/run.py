import os
from pathlib import Path
import re
import runpy
import sqlite3
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main():
    method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
    code = (HERE / 'harness.cpp').read_text()
    aura = (ROOT / 'src/server/game/Spells/Auras/SpellAuraDefines.h').read_text()
    info = (ROOT / 'src/server/game/Spells/SpellInfo.h').read_text()
    enums = method(aura, 'enum AuraRemoveMode') + ';\n' + method(info, 'enum SpellCustomAttributes') + ';\n'
    code = code.replace('// ENUMS', enums)
    source = (ROOT / 'src/server/coa/AscensionThreatRedirect.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = source.replace(': public AuraScript\n{', ': public AuraScript\n{\npublic:')
    code = code.replace('// SOURCE', source)
    native = (ROOT / 'src/server/game/Combat/ThreatManager.cpp').read_text()
    code = code.replace('// NATIVE', method(native, 'void ThreatManager::RegisterRedirectThreat(') +
                        method(native, 'void ThreatManager::UnregisterRedirectThreat(uint32 spellId)'))
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    parents = (574356, 534605, 534480)
    children = (574357, 535214, 535097)
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936])
            if r[0] in (*parents, *children)}
    for sid in parents:
        row = rows[sid]
        assert row[71:74] == (130, 6, 0) and row[96] == 4 and row[34] == 2167124
        assert row[80] + row[74] == 100 and row[86:88] == (57, 1) and row[40] == 9
    for sid in children:
        assert rows[sid][71:74] == (6, 0, 0) and rows[sid][95] == 4 and rows[sid][40] == 35
    raw = (dbc_dir() / 'SpellDuration.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    durations = {r[0]: r[1] for r in struct.iter_unpack('<4i', raw[20:20 + count * 16])}
    assert durations[9] == 30000 and durations[35] == 4000
    with tempfile.TemporaryDirectory(prefix='coa-threat-redirect-') as directory:
        out = Path(directory)
        cpp, exe = out / 'redirect.cpp', out / 'redirect.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], check=True, timeout=15)
    db = sqlite3.connect(':memory:')
    db.execute('CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT)')
    db.execute('CREATE TABLE spell_linked_spell (spell_trigger INT, spell_effect INT, type INT, comment TEXT)')
    db.execute('CREATE TABLE spell_bonus_data (entry INT, direct_bonus FLOAT, dot_bonus FLOAT, ap_bonus FLOAT, '
               'ap_dot_bonus FLOAT, comments TEXT)')
    db.execute('CREATE TABLE spell_proc (SpellId INT, SchoolMask INT, SpellFamilyName INT, SpellFamilyMask0 INT, '
               'SpellFamilyMask1 INT, SpellFamilyMask2 INT, ProcFlags INT, SpellTypeMask INT, SpellPhaseMask INT, '
               'HitMask INT, AttributesMask INT, DisableEffectsMask INT, ProcsPerMinute FLOAT, Chance FLOAT, '
               'Cooldown INT, Charges INT)')
    db.execute('CREATE TABLE creature_template (entry INT, name TEXT, minlevel INT, maxlevel INT, faction INT, '
               'unit_class INT, type INT, ScriptName TEXT)')
    db.execute('CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT, '
               'DisplayScale FLOAT, Probability FLOAT)')
    db.execute("INSERT INTO spell_script_names VALUES (574356, 'unrelated')")
    sql = (ROOT / 'data/sql/updates/pending_db_world/rev_1789379311228000700.sql').read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == before
    assert db.execute("SELECT COUNT(*) FROM spell_script_names WHERE ScriptName='unrelated'").fetchone() == (1,)
    assert db.execute('SELECT CreatureDisplayID FROM creature_template_model WHERE CreatureID=503201').fetchone() == (29352,)
    assert db.execute('SELECT ScriptName FROM creature_template WHERE entry=503201').fetchone() == ('npc_ascension_power_sphere',)
    assert db.execute('SELECT spell_trigger, spell_effect, type FROM spell_linked_spell ORDER BY spell_trigger').fetchall() == [
        (804591, 800046, 2), (804833, 805161, 2), (807555, 807464, 2)]
    for sid, name in [(s, 'aura_ascension_threat_redirect') for s in parents] + [
            (s, 'aura_ascension_threat_redirect_active') for s in children]:
        assert db.execute('SELECT COUNT(*) FROM spell_script_names WHERE spell_id=? AND ScriptName=?',
                          (sid, name)).fetchone() == (1,)
    print('PASS: redirect activation, expiry/cancel/dispel/death, unrelated registrations and SQL replay')


if __name__ == '__main__':
    main()
