import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from cache import install_snapshot, snapshot
from library import canonical, make_record
from test_library import sample


class SnapshotRemote:
    def __init__(self):
        self.record = make_record(sample(), 'Alias', 'v1')
        path = 'builds/' + self.record['id'] + '/1.json'
        body = canonical(self.record)
        self.item = dict(id=self.record['id'], revision=1, name=self.record['build']['Name'], author='Alias',
                         compatibility=self.record['compatibility'], path=path, sha256=hashlib.sha256(body).hexdigest())
        self.files = {path: body}

    def head(self):
        return 'a' * 40

    def read(self, head, path):
        assert head == self.head()
        return canonical({'schema': 1, 'builds': [self.item]}) if path == 'index.json' else self.files.get(path)


class CacheTests(unittest.TestCase):
    def test_cached_immutable_records_avoid_duplicate_downloads(self):
        remote=SnapshotRemote()
        with tempfile.TemporaryDirectory() as tmp:
            first=snapshot(remote,'v1',tmp)
            original=remote.read
            def index_only(head,path):
                if path!='index.json':raise AssertionError('Unchanged record downloaded again')
                return original(head,path)
            remote.read=index_only
            self.assertEqual(snapshot(remote,'v1',tmp),first)
            path=next(Path(tmp).glob('*.json'));path.write_bytes(b'corrupted')
            with self.assertRaises(ValueError):snapshot(remote,'v1',tmp)
    def test_atomic_snapshot_and_incompatible_visibility(self):
        remote = SnapshotRemote()
        value = snapshot(remote, 'v2')
        self.assertFalse(value['entries'][0]['compatible'])
        with tempfile.TemporaryDirectory() as tmp:
            path = install_snapshot(tmp, value)
            pointer = json.loads((Path(tmp) / 'current.json').read_text())
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), pointer['sha256'])
            self.assertEqual(path, install_snapshot(tmp, value))

    def test_tampered_record_and_traversal_rejected(self):
        remote = SnapshotRemote()
        remote.files[remote.item['path']] += b' '
        with self.assertRaises(ValueError):
            snapshot(remote, 'v1')
        remote = SnapshotRemote()
        remote.item['path'] = '../../secret'
        with self.assertRaises(ValueError):
            snapshot(remote, 'v1')

    def test_metadata_spoof_rejected(self):
        remote = SnapshotRemote()
        remote.item['name'] = 'Misleading title'
        with self.assertRaises(ValueError):
            snapshot(remote, 'v1')


if __name__ == '__main__':
    unittest.main()
