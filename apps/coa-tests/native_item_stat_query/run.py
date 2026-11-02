import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def pending_queries(source):
    start = source.index('PendingStatQueries pendingStatQueries;')
    discard = 'void DiscardPendingStatQueries('
    return source[start:source.index(discard) + len(method(source, discard))]


def check_wiring(source):
    handler = method(source, 'bool HandleItemStatQuery(')
    assert 'GetPlayer' not in handler and 'OwnsStoredKey' not in handler, \
        'HandleItemStatQuery runs on the network thread and must not read the player'
    acquisition = method(source, 'class Acquisition : public PlayerScript')
    assert 'PLAYERHOOK_ON_UPDATE' in acquisition and 'PLAYERHOOK_ON_LOGOUT' in acquisition, \
        'the acquisition script must subscribe to player updates and logouts'
    assert 'AnswerPendingStatQueries(player)' in method(acquisition, 'void OnPlayerUpdate('), \
        'player updates must answer deferred stat queries'
    assert 'DiscardPendingStatQueries(player)' in method(acquisition, 'void OnPlayerLogout('), \
        'logout must discard deferred stat queries'


def main():
    source = (ROOT / 'src/server/coa/AscensionNativeItemScaling.cpp').read_text(encoding='utf-8')
    check_wiring(source)
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    harness = harness.replace('// ACTUAL_PENDING_QUERIES', pending_queries(source))
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    include = ROOT / 'src/server/coa'
    with tempfile.TemporaryDirectory(prefix='coa-native-item-stat-query-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        cpp.write_text(harness, encoding='utf-8')
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/I' + str(include), str(cpp),
                     '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-pthread', '-I' + str(include), str(cpp),
                     '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=60)


if __name__ == '__main__':
    main()
