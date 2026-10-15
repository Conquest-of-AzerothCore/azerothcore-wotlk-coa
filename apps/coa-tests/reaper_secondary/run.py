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
    code = (HERE / 'harness.cpp').read_text()
    code = code.replace('// ENUMS', method((ROOT / 'src/server/game/Spells/SpellInfo.h').read_text(),
                                         'enum SpellCustomAttributes') + ';')
    source = (ROOT / 'src/server/coa/AscensionReaperSecondary.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M).replace(
        ': public AuraScript\n{', ': public AuraScript\n{\npublic:')
    code = code.replace('// SOURCE', source)
    with tempfile.TemporaryDirectory(prefix='coa-reaper-secondary-') as directory:
        out = Path(directory)
        cpp, exe = out / 'reaper.cpp', out / 'reaper.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {561093, 801341, 520419, 803742, 803942, 807415, 807416, 807417, 807545}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in ids}
    assert rows[801341][80] + rows[801341][74] == 75
    assert rows[807417][80] + rows[807417][74] == 50
    assert rows[803742][71:73] == (5, 2) and rows[803942][95] == 26
    assert rows[807415][116] == 807416 and rows[807416][49] == 5
    assert rows[520419][71] == rows[807545][71] == 10
    assert rows[520419][213] == 1 and rows[807545][213] == 0
    assert rows[561093][95:97] == (31, 58)
    print('PASS: ghost lifetime, Endbringer healing/resource cap, Spectre root, physical-only Crimson stacks and Murder ranks')


if __name__ == '__main__':
    main()
