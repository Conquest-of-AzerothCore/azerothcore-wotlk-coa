import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    compat = (ROOT / 'src/server/coa/AscensionCompat.cpp').read_text(encoding='utf-8')
    send = method(compat, 'void SendSecureAddonList(WorldSession* session)')

    session = (ROOT / 'src/server/game/Server/WorldSession.cpp').read_text(encoding='utf-8')
    read = method(session, 'void WorldSession::ReadAddonsInfo(')
    assert 'm_clientAddonNames.push_back(' in read, 'ReadAddonsInfo keeps the addon names'
    assert 'm_clientAddonNames' not in method(session, 'void WorldSession::SendAddonsInfo('), \
        'SendAddonsInfo leaves the addon names for SMSG 0x94E'

    code = (HERE / 'harness.cpp').read_text(encoding='utf-8').replace('// ACTUAL_SEND', send)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler
    with tempfile.TemporaryDirectory(prefix='coa-known-addon-list-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        exe = out / ('harness.exe' if os.name == 'nt' else 'harness')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)


if __name__ == '__main__':
    main()
