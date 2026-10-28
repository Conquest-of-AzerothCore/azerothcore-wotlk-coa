import os
from pathlib import Path
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='coa-rotation-assist-') as directory:
        output = Path(directory)
        executable = output / ('rotation.exe' if os.name == 'nt' else 'rotation')
        include = ROOT / 'src/server/coa'
        source = HERE / 'harness.cpp'
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/I' + str(include),
                     str(source), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-I' + str(include),
                     str(source), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=output, check=True, timeout=120)
        subprocess.run([str(executable)], cwd=output, check=True, timeout=30)
    print('PASS: specialization priorities, missing spells, unavailable attacks, aura thresholds and one selection')


if __name__ == '__main__':
    main()
