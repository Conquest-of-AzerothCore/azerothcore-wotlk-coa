import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from cycle import DEFAULT_GATE_PATHS
from profile import DBC_DIR

CONFORMANCE = Path(__file__).resolve().parent
REPOSITORY = CONFORMANCE.parents[2]
FORMER_GATE_PATHS = ('apps', 'src', 'data/sql/updates')
AUDITED_GENERATION =('generate', '--class', '19', '--spell', '570233')
RECORDER = '''
import json, os, runpy, sys
root, record, script = map(os.path.realpath, sys.argv[1:4])
reads = set()
def hook(event, arguments):
    if event not in ('open', 'os.listdir', 'os.scandir') or not arguments or arguments[0] is None:
        return
    target = arguments[0]
    if isinstance(target, int):
        return
    full = os.path.realpath(os.fsdecode(target))
    if full.startswith(root + os.sep):
        reads.add(os.path.relpath(full, root).replace(os.sep, '/'))
sys.addaudithook(hook)
sys.argv = [script, *sys.argv[4:]]
sys.path.insert(0, os.path.dirname(script))
code = 0
try:
    runpy.run_path(script, run_name='__main__')
except SystemExit as exit:
    code = exit.code or 0
with open(record, 'w') as handle:
    json.dump({'exit': code, 'reads': sorted(reads)}, handle)
'''


def uncovered(reads, paths) -> list[str]:
    return sorted(read for read in reads if not any(read == path or read.startswith(path + '/') for path in paths))


def tracked(reads, files) -> set[str]:
    directories = {'/'.join(parts[:index]) for parts in (file.split('/') for file in files)
                   for index in range(1, len(parts))}
    return {read for read in reads if read in files or read in directories}


def tracked_files() -> set[str]:
    output = subprocess.run(['git', '-C', str(REPOSITORY), 'ls-files', '-z'], capture_output=True, check=True)
    return set(output.stdout.decode('utf-8').split('\0')) - {''}


def generator_reads() -> set[str]:
    with tempfile.TemporaryDirectory() as directory:
        record = Path(directory) / 'reads.json'
        out = Path(directory) / 'out'
        subprocess.run([sys.executable, '-B', '-c', RECORDER, str(REPOSITORY), str(record),
                        str(CONFORMANCE / 'conformance.py'), *AUDITED_GENERATION, '--out', str(out)],
                       cwd=CONFORMANCE, capture_output=True, check=True)
        result = json.loads(record.read_text(encoding='utf-8'))
    if result['exit'] != 0:
        raise AssertionError(f'the audited generation exited with {result["exit"]}')
    return tracked(result['reads'], tracked_files())


class Uncovered(unittest.TestCase):
    def test_a_read_outside_every_gate_path_is_uncovered(self):
        reads = {'apps/a.py', 'data/coa-world/baseline.json', 'data/sql/updates/db_world/x.sql', 'apps2/b.py'}
        self.assertEqual(uncovered(reads, ('apps', 'data/sql/updates')), ['apps2/b.py', 'data/coa-world/baseline.json'])

    def test_a_gate_path_covers_itself_and_what_is_under_it(self):
        self.assertEqual(uncovered({'modules', 'modules/m/data/sql/a.sql'}, ('modules',)), [])

    def test_untracked_reads_are_left_out(self):
        files = {'data/sql/custom/db_world/.dummy', 'apps/a.py'}
        reads = {'data/sql/custom/db_world', 'data/sql/custom/db_world/local.sql', 'apps/__pycache__/a.pyc',
                 'apps/a.py'}
        self.assertEqual(tracked(reads, files), {'data/sql/custom/db_world', 'apps/a.py'})


class DefaultGatePaths(unittest.TestCase):
    def test_every_default_gate_path_is_in_the_repository(self):
        listed = subprocess.run(['git', '-C', str(REPOSITORY), 'ls-tree', '--name-only', 'HEAD', '--',
                                 *DEFAULT_GATE_PATHS], capture_output=True, text=True, check=True).stdout.split()
        self.assertEqual(sorted(listed), sorted(DEFAULT_GATE_PATHS))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GeneratorReads(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reads = generator_reads()

    def test_the_gate_archive_covers_every_path_the_generator_reads(self):
        self.assertTrue(any(read.startswith('data/') for read in self.reads))
        self.assertEqual(uncovered(self.reads, DEFAULT_GATE_PATHS), [])

    def test_the_former_gate_paths_leave_the_world_baseline_out(self):
        self.assertIn('data/coa-world/baseline.json', uncovered(self.reads, FORMER_GATE_PATHS))


if __name__ == '__main__':
    unittest.main()
