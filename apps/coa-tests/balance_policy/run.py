import os
from pathlib import Path
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
INCLUDES = [
    ROOT / 'src/server/coa',
    ROOT / 'src/server/game/Entities/Object',
    ROOT / 'src/server/shared/Packets',
    ROOT / 'src/common',
    ROOT / 'src/common/Utilities',
    ROOT / 'src/common/Debugging',
    ROOT / 'src/common/Logging',
    ROOT / 'src/common/Platform',
    ROOT / 'src/common/Threading',
    ROOT / 'src/common/Encoding',
    ROOT / 'src/common/Metric',
    ROOT / 'src/common/Configuration',
]


def main():
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='coa-balance-policy-') as directory:
        output = Path(directory)
        executable = output / ('balance.exe' if os.name == 'nt' else 'balance')
        source = HERE / 'harness.cpp'
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', *['/I' + str(p) for p in INCLUDES],
                     str(source), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', *['-I' + str(p) for p in INCLUDES],
                     str(source), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=output, check=True, timeout=120)
        subprocess.run([str(executable)], cwd=output, check=True, timeout=30)
    print('PASS: stage outcomes, solo target selection, kit rule picking and white-hit swing tallies')


if __name__ == '__main__':
    main()
