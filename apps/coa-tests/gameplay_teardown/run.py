CLI_DESCRIPTION = """Exercise native gameplay teardown when an asynchronous account deletion commits between queries.

Extracts DeleteAccounts and TeardownComplete from the gameplay runner. Account and character storage are
bounded dependencies; the native deletion and completion guards are compiled without rewriting them.
"""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--source-ref', help='Read native teardown from a local Git ref.')
    args = parser.parse_args()
    path = 'src/server/coa/CoAGameplayTest.cpp'
    source = (git_source(['git', 'show', f'{args.source_ref}:{path}'], cwd=ROOT).decode()
              if args.source_ref else (ROOT / path).read_text(encoding='utf-8'))
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, anchor in [('// NATIVE_DELETE', 'static void DeleteAccounts(Lane& lane)'),
                           ('// NATIVE_COMPLETE', 'static bool TeardownComplete(Lane const& lane)')]:
        assert harness.count(marker) == 1
        harness = harness.replace(marker, method(source, anchor))
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='coa-gameplay-teardown-') as directory:
        folder = Path(directory)
        cpp = folder / 'harness.cpp'
        cpp.write_text(harness, encoding='utf-8')
        executable = folder / ('harness.exe' if os.name == 'nt' else 'harness')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', str(cpp),
                     '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=folder, check=True, timeout=120)
        return subprocess.run([str(executable)], cwd=folder, timeout=30).returncode


if __name__ == '__main__':
    raise SystemExit(main())
