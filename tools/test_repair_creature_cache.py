from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

import repair_creature_cache as repair


def record(entry, flags=0, kind=8):
    body = b'Example\0\0\0\0\0\0' + struct.pack('<4I', flags, kind, 0, 0) + bytes(60)
    return struct.pack('<II', entry, len(body)) + body


def cache(*rows):
    return b'BOMW' + struct.pack('<5I', 12340, 0, 108, 1, 17) + b''.join(rows) + bytes(8)


class RepairTests(unittest.TestCase):
    def setUp(self):
        self.before = cache(record(22313), record(17157, 512, 4))
        self.after, self.count = repair.invalidate(self.before, 22313, 0, 8)

    def test_selective_preservation_and_retry(self):
        self.assertEqual(self.after, cache(record(17157, 512, 4)))
        self.assertEqual(self.count, 1)
        self.assertEqual(repair.invalidate(self.after, 22313, 0, 8), (self.after, 1))
        self.assertEqual(repair.metadata(record(22313)), (0, 8))

    def test_invalid_and_changed_records(self):
        for data in (self.before[:-8], cache(record(22313), record(22313)),
                     cache(record(22313, 512, 4)), b'NOPE' + self.before[4:]):
            with self.subTest(data=data[:24]), self.assertRaises(ValueError):
                repair.invalidate(data, 22313, 0, 8)

    def test_apply_backup_readback_and_retry(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'creaturecache.wdb'
            path.write_bytes(self.before)
            backup = repair.apply(path, self.before, self.after, lambda: None)
            self.assertEqual(backup.read_bytes(), self.before)
            self.assertEqual(path.read_bytes(), self.after)
            self.assertIsNone(repair.apply(path, self.after, self.after, lambda: None))
            self.assertEqual(len(list(Path(directory).iterdir())), 2)

    def test_open_client_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'creaturecache.wdb'
            path.write_bytes(self.before)
            def open_client():
                raise RuntimeError('Client open')
            with self.assertRaises(RuntimeError):
                repair.apply(path, self.before, self.after, open_client)
            self.assertEqual(path.read_bytes(), self.before)
            self.assertEqual(len(list(Path(directory).iterdir())), 1)

    def test_concurrent_change_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'creaturecache.wdb'
            path.write_bytes(self.before)
            calls = 0
            changed = cache(record(999))
            def check():
                nonlocal calls
                calls += 1
                if calls == 2:
                    path.write_bytes(changed)
            with self.assertRaises(RuntimeError):
                repair.apply(path, self.before, self.after, check)
            self.assertEqual(path.read_bytes(), changed)
            backups = list(Path(directory).glob('*.backup-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_bytes(), self.before)
            self.assertFalse(list(Path(directory).glob('*.repair-*')))

    def test_replace_failure_retains_backup(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'creaturecache.wdb'
            path.write_bytes(self.before)
            with patch.object(repair.os, 'replace', side_effect=OSError('locked')):
                with self.assertRaises(OSError):
                    repair.apply(path, self.before, self.after, lambda: None)
            self.assertEqual(path.read_bytes(), self.before)
            self.assertEqual(len(list(Path(directory).glob('*.backup-*'))), 1)
            self.assertFalse(list(Path(directory).glob('*.repair-*')))


if __name__ == '__main__':
    unittest.main()
