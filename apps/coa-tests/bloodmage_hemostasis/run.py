import os
from pathlib import Path
import re
import runpy
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def main():
    method = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    source = (ROOT / 'src/server/coa/AscensionBloodmageHemostasis.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = re.sub(r'(: public (?:AuraScript|SpellScript)\n\{)', r'\1\npublic:', source)
    player = (ROOT / 'src/server/game/Entities/Player/Player.cpp').read_text()
    native = method(player, 'void Player::SetTemporarySpellReplacement(') + '\n' + method(
        player, 'uint32 Player::GetTemporarySpellReplacement(')
    code = Path(__file__).with_name('harness.cpp').read_text().replace('// SOURCE', source)
    code = code.replace('// NATIVE', native)
    enums = (ROOT / 'src/server/game/Spells/SpellInfo.h').read_text()
    code = code.replace('// ENUMS', method(enums, 'enum SpellCustomAttributes') + ';')
    with tempfile.TemporaryDirectory(prefix='coa-hemostasis-') as directory:
        out = Path(directory)
        cpp, exe = out / 'hemostasis.cpp', out / 'hemostasis.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936])
            if r[0] in {681304, 302895, 803326}}
    assert rows[681304][29] == 120000 and rows[803326][29:31] == (0, 0)
    assert rows[681304][95] == 12 and rows[681304][40] == rows[302895][40] == 35
    assert rows[803326][71:74] == (2, 64, 164) and rows[803326][118] == 681304
    spell = (ROOT / 'src/server/game/Spells/Spell.cpp').read_text()
    prepare = method(spell, 'SpellCastResult Spell::prepare(')
    assert prepare.index('InitExplicitTargets(*targets)') < prepare.index('CanPrepare')
    print('PASS: native replacement packets, original target, expiry/races, caster ownership and cooldown data')


if __name__ == '__main__':
    main()
