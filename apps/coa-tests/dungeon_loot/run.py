import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler (VS Developer PowerShell on Windows).'
    with tempfile.TemporaryDirectory(prefix='coa-dungeon-loot-') as directory:
        out = Path(directory)
        cpp = out / 'dungeon_loot.cpp'
        exe = out / ('dungeon_loot.exe' if os.name == 'nt' else 'dungeon_loot')
        cpp.write_text(code, encoding='utf-8')
        include = ROOT / 'src/server/coa'
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', '/I' + str(include),
                     str(cpp), '/Fe' + str(exe)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-I' + str(include), str(cpp), '-o', str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print('PASS: both tiers resolve, quest rows, empty tiers and unknown items keep the rolled item; '
          'Heroic/Mythic maps and store exclusions checked')


if __name__ == '__main__':
    main()
