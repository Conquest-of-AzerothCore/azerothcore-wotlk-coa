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
HERE = Path(__file__).resolve().parent


def main():
    method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
    source = (ROOT / 'src/server/coa/AscensionChronomancerSecondary.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = re.sub(r'(: public (?:AuraScript|SpellScript)\n\{)', r'\1\npublic:', source)
    code = (HERE / 'harness.cpp').read_text().replace('// SOURCE', source)
    info = (ROOT / 'src/server/game/Spells/SpellInfo.h').read_text()
    code = code.replace('// NATIVE_ENUMS', method(info, 'enum SpellCustomAttributes') + ';')
    player = (ROOT / 'src/server/game/Entities/Player/Player.cpp').read_text()
    creature = (ROOT / 'src/server/game/Entities/Creature/Creature.cpp').read_text()
    regen = method(player, 'void Player::RegenerateHealth()') + '\n'
    regen += '#pragma warning(push)\n#pragma warning(disable: 4244)\n'
    regen += method(creature, 'void Creature::RegenerateHealth()') + '\n#pragma warning(pop)\n'
    code = code.replace('// NATIVE_REGEN', regen)
    with tempfile.TemporaryDirectory(prefix='coa-chrono-secondary-') as directory:
        out = Path(directory)
        cpp, exe = out / 'chrono.cpp', out / 'chrono.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {806335,503895,503896,503897,503898,503899,572835,504727,807570,561310,561388,
           560948,592009,592010,806296,806297,806298,804455,524853,807711}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in ids}
    assert rows[504727][80] + rows[504727][74] == 20 and rows[504727][116] == 807570
    assert rows[807570][86] == 53 and rows[807570][89] == 16 and rows[807570][92] == 8
    for sid in (806335,503895,503896,503897,503898,503899,572835):
        assert rows[sid][95] == 3 and rows[sid][208] == 28 and rows[sid][210] == 512
    assert rows[561310][95] == 67 and rows[561388][95] == 294 and rows[561388][110] == 0xfffffffe
    assert rows[561388][96] == 118 and rows[561388][81] == 0xffffff9b
    assert rows[592009][49] == 10 and rows[592009][40] == 8 and rows[592010][40] == 1
    assert rows[592010][95] == 345 and rows[592010][80] + rows[592010][74] == 10
    assert rows[806296][99] == 250 and rows[806296][117] == 806297
    assert rows[806297][80] + rows[806297][74] == 8
    assert rows[806297][123] & rows[806298][210] and rows[806297][110] == 0
    assert rows[524853][47] == 0 and rows[524853][40] == 35
    assert rows[807711][80] + rows[807711][74] == 2000 and rows[807711][110] == 1
    assert rows[807711][124] & rows[524853][211] and rows[804455][49] == rows[807711][49] == 5
    print('PASS: owned periodic copies, tenth-event power, channel release, Echo duration and native health locks')


if __name__ == '__main__':
    main()
