import os
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    if not compiler:
        raise RuntimeError('A C++20 compiler is required for native token policy checks')
    with TemporaryDirectory(prefix='manastorm-coa-loot-') as temporary:
        output = Path(temporary)
        binary = output / ('policy.exe' if os.name == 'nt' else 'policy')
        include = ROOT / 'modules/mod-manastorm-endless/src'
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', '/I' + str(include),
                     str(HERE / 'harness.cpp'), '/Fo' + str(output / 'policy.obj'), '/Fe' + str(binary)]
        else:
            flags = ['-std=c++20', '-I' + str(include), str(HERE / 'harness.cpp'), '-o', str(binary)]
        subprocess.run([compiler, *flags], cwd=output, check=True, timeout=60)
        subprocess.run([str(binary)], cwd=output, check=True, timeout=10)
    print('PASS: actual policy expiry, clock rollback, allowance, partial awards and overflow controls')


if __name__ == '__main__':
    main()
