import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CLIENT_LUA = ROOT / 'src/server/coa/AscensionClientLua.cpp'
CLIENT_LUA_HEADER = ROOT / 'src/server/coa/AscensionClientLua.h'


def client_lua_source():
    source = CLIENT_LUA_HEADER.read_text(encoding='utf-8') + CLIENT_LUA.read_text(encoding='utf-8')
    return re.sub(r'^#include "[^"]+"\n', '', source, flags=re.M)


def main():
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8').replace('// ACTUAL_CLIENT_LUA', client_lua_source())
    with tempfile.TemporaryDirectory(prefix='coa-client-hot-patch-') as directory:
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
