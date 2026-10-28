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
    source = (ROOT / 'src/server/game/Loot/LootMgr.cpp').read_text(encoding='utf-8')
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    code = code.replace('// ACTUAL_ADD_ITEM', method(source, 'void Loot::AddItem('))
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler (VS Developer PowerShell on Windows).'
    with tempfile.TemporaryDirectory(prefix='coa-dungeon-loot-') as directory:
        out = Path(directory)
        cpp = out / 'dungeon_loot.cpp'
        exe = out / ('dungeon_loot.exe' if os.name == 'nt' else 'dungeon_loot')
        cpp.write_text(code, encoding='utf-8')
        include = ROOT / 'src/server/game/Loot'
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', '/I' + str(include),
                     str(cpp), '/Fe' + str(exe)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-I' + str(include), str(cpp), '-o', str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print('PASS: actual Loot::AddItem maps both tiers before item construction, preserves source rows, conditions '
          'and quest loot; target stack sizes, counts, unknown variants and map/store exclusions checked')


if __name__ == '__main__':
    main()
