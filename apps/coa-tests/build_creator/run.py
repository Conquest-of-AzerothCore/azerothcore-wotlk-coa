import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent


def command(source, exe):
    if os.environ.get('VCToolsInstallDir'):
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        return [str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', str(source), '/Fe' + str(exe)]
    compiler = shutil.which(os.environ.get('CXX', 'g++'))
    assert compiler, 'Set CXX to a C++17 compiler or run from an MSVC developer environment.'
    return [compiler, '-std=c++17', '-Wall', '-Wextra', '-Werror', str(source), '-o', str(exe)]


def main():
    with tempfile.TemporaryDirectory(prefix='coa-build-creator-') as directory:
        exe = Path(directory) / 'rules.exe'
        subprocess.run(command(HERE / 'test_rules.cpp', exe), cwd=directory, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=directory, check=True, timeout=15)
    print('PASS: Hero Architect wire form, publish validation, ownership, ratings, categories, paging, build ids and activation')


if __name__ == '__main__':
    main()
