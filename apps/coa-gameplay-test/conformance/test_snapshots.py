import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import snapshots
from profile import DBC_DIR
from snapshots import (FINISHED_CLASSES, GENERATIONS, check, differences, directory_digests,
                       snapshot_path, write)

TEMPLAR = 19
NECROMANCER = 23


def fake_generator(files):
    return lambda class_id, arguments: dict(files[' '.join(arguments)])


class DigestTest(unittest.TestCase):
    def test_directory_digests_are_relative_sha256_per_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'scenarios').mkdir()
            (root / 'manifest.json').write_bytes(b'{}')
            (root / 'scenarios' / 'a.json').write_bytes(b'a')
            digests = directory_digests(root)
            self.assertEqual(sorted(digests), ['manifest.json', 'scenarios/a.json'])
            self.assertEqual(digests['scenarios/a.json'],
                             'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb')
            (root / 'scenarios' / 'a.json').write_bytes(b'b')
            self.assertNotEqual(directory_digests(root)['scenarios/a.json'], digests['scenarios/a.json'])

    def test_differences_name_changed_added_and_removed_files(self):
        found = differences({'a': '1', 'b': '2', 'c': '3'}, {'a': '1', 'b': '9', 'd': '4'})
        self.assertEqual(found, {'changed': ['b'], 'added': ['d'], 'removed': ['c']})

    def test_finished_classes_have_generations_and_committed_digest_files(self):
        self.assertEqual(sorted(FINISHED_CLASSES), sorted(GENERATIONS))
        for class_id in FINISHED_CLASSES:
            with self.subTest(class_id=class_id):
                committed = json.loads(snapshot_path(class_id).read_text(encoding='utf-8'))
                self.assertEqual(committed['class_id'], class_id)
                self.assertEqual(set(committed['generations']), set(GENERATIONS[class_id]))
                for generation in committed['generations'].values():
                    self.assertIn('manifest.json', generation['files'])
                    self.assertTrue(all(len(digest) == 64 for digest in generation['files'].values()))


class CheckTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.files = {'': {'manifest.json': 'm', 'scenarios/x.json': 'x'}, '--stack': {'manifest.json': 's'}}
        write(TEMPLAR, self.root, fake_generator(self.files))

    def tearDown(self):
        self.directory.cleanup()

    def test_an_unchanged_generation_passes(self):
        self.assertEqual(check(TEMPLAR, self.root, fake_generator(self.files)), [])

    def test_a_changed_scenario_is_named_with_the_regenerate_and_diff_instructions(self):
        self.files['']['scenarios/x.json'] = 'y'
        self.files['']['scenarios/new.json'] = 'n'
        problems = check(TEMPLAR, self.root, fake_generator(self.files))
        self.assertEqual(len(problems), 1)
        self.assertIn('changed (1): scenarios/x.json', problems[0])
        self.assertIn('added (1): scenarios/new.json', problems[0])
        self.assertIn('generate --class 19 --out <A>', problems[0])
        self.assertIn('diff -r <A> <B>', problems[0])
        self.assertIn('snapshots.py write --class 19', problems[0])

    def test_a_stack_change_names_the_stack_generation(self):
        self.files['--stack']['manifest.json'] = 't'
        problems = check(TEMPLAR, self.root, fake_generator(self.files))
        self.assertEqual(len(problems), 1)
        self.assertIn('generation "stack"', problems[0])
        self.assertIn('generate --class 19 --stack --out <A>', problems[0])

    def test_long_lists_are_shortened(self):
        self.files[''].update({f'scenarios/{index:03}.json': 'n' for index in range(30)})
        problems = check(TEMPLAR, self.root, fake_generator(self.files))
        self.assertIn('added (30)', problems[0])
        self.assertIn('... 10 more', problems[0])

    def test_a_missing_digest_file_fails(self):
        problems = check(NECROMANCER, self.root, fake_generator(self.files))
        self.assertEqual(len(problems), 1)
        self.assertIn('snapshots.py write --class 23', problems[0])

    def test_without_a_dbc_set_the_check_skips(self):
        with mock.patch.object(snapshots, 'DBC_DIR', self.root / 'absent'), mock.patch('builtins.print') as shown:
            self.assertEqual(snapshots.main(['check', '--class', str(TEMPLAR)]), 0)
        self.assertIn('skipped', shown.call_args.args[0])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MutantTest(unittest.TestCase):
    def test_one_changed_byte_in_a_committed_digest_fails_the_real_generation(self):
        committed = json.loads(snapshot_path(TEMPLAR).read_text(encoding='utf-8'))
        committed['generations'] = {'stack': committed['generations']['stack']}
        with tempfile.TemporaryDirectory() as directory, \
                mock.patch.dict(snapshots.GENERATIONS, {TEMPLAR: {'stack': ['--stack']}}):
            path = snapshot_path(TEMPLAR, Path(directory))
            path.write_text(json.dumps(committed), encoding='utf-8')
            self.assertEqual(check(TEMPLAR, Path(directory)), [])
            files = committed['generations']['stack']['files']
            name = sorted(files)[-1]
            files[name] = ('0' if files[name][0] != '0' else '1') + files[name][1:]
            path.write_text(json.dumps(committed), encoding='utf-8')
            problems = check(TEMPLAR, Path(directory))
        self.assertEqual(len(problems), 1)
        self.assertIn(f'changed (1): {name}', problems[0])


if __name__ == '__main__':
    unittest.main()
