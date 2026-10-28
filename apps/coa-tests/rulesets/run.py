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
    shared = (ROOT / 'src/server/shared/SharedDefines.h').read_text()
    info = (ROOT / 'src/server/game/Spells/SpellInfo.h').read_text()
    enums = ''.join(method(shared, 'enum ' + name) + ';\n'
                    for name in ('SpellAttr0', 'SpellAttr3', 'SpellAttr7', 'SpellCastResult'))
    enums += method(info, 'enum SpellCustomAttributes') + ';\n'
    enums += method((ROOT / 'src/server/game/Entities/Player/Player.h').read_text(), 'enum PlayerFlags') + ';\n'
    header = (ROOT / 'src/server/coa/AscensionRulesets.h').read_text().replace('class Player;', 'struct Player;')
    source = header + (ROOT / 'src/server/coa/AscensionRulesets.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = source.replace(': public SpellScript\n{', ': public SpellScript\n{\npublic:')
    code = (HERE / 'harness.cpp').read_text().replace('// ENUMS', enums).replace('// SOURCE', source)
    native = method((ROOT / 'src/server/game/Spells/Auras/SpellAuras.cpp').read_text(), 'bool Aura::CanBeSaved()')
    native += method((ROOT / 'src/server/game/Spells/SpellInfo.cpp').read_text(), 'bool SpellInfo::IsDeathPersistent()')
    native += method((ROOT / 'src/server/game/Entities/Unit/Unit.cpp').read_text(),
                     'void Unit::RemoveAllAurasOnDeath()')
    code = code.replace('// NATIVE', native)
    saving = method((ROOT / 'src/server/game/Entities/Player/PlayerStorage.cpp').read_text(),
                    'void Player::_SaveAuras(')
    assert '!aura->IsPermanent()' in saving
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {84420, 84421, 84422, 1004019, 1004119, 9931032}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936]) if r[0] in ids}
    assert set(rows) == ids
    for sid in (84420, 84421, 84422):
        assert rows[sid][71:74] == (3, 0, 0) and rows[sid][86] == 1
        assert rows[sid][29:31] == (1500, 1500)
    for sid in (1004019, 1004119, 9931032):
        row = rows[sid]
        assert row[40] == 21 and not (row[4] & 0x40) and not (row[5] & (4 | 64))
    assert rows[1004019][95] == 200 and rows[1004119][96] == 200
    code = code.replace('// DBC_CASES', '\n'.join(
        f'{{ SpellInfo auraInfo; auraInfo.Id={sid}; auraInfo.Attributes={rows[sid][4]}u; '
        f'auraInfo.AttributesEx3={rows[sid][7]}u; CheckAura(auraInfo); }}'
        for sid in (1004019, 1004119, 9931032)))
    with tempfile.TemporaryDirectory(prefix='coa-rulesets-') as directory:
        out = Path(directory)
        cpp, exe = out / 'rulesets.cpp', out / 'rulesets.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], check=True, timeout=15)
    db = sqlite3.connect(':memory:')
    db.execute('CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT)')
    db.execute("INSERT INTO spell_script_names VALUES (84420, 'unrelated')")
    sql = (ROOT / 'data/sql/updates/pending_db_world/rev_1789377682080669300.sql').read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == before
    assert db.execute("SELECT spell_id FROM spell_script_names "
                      "WHERE ScriptName='spell_ascension_ruleset_select' ORDER BY 1").fetchall() == [
                          (84420,), (84421,), (84422,)]
    assert db.execute("SELECT COUNT(*) FROM spell_script_names WHERE ScriptName='unrelated'").fetchone() == (1,)
    print('PASS: all mode transitions, rested-area check, native death removal/save eligibility and SQL replay')


if __name__ == '__main__':
    main()
