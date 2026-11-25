import hashlib
import os
import unittest
from pathlib import Path

CLIENT = Path(__file__).resolve().parents[2] / 'client'
ADDONS = CLIENT / 'AddOns'
MANIFEST = CLIENT / 'MANIFEST.sha256'


def manifest():
    rows = {}
    for line in MANIFEST.read_text(encoding='utf-8').splitlines():
        digest, path = line.split(None, 1)
        rows[path.strip()] = digest
    return rows


class ClientAddonsTest(unittest.TestCase):
    def test_manifest_matches_files(self):
        rows = manifest()
        files = {p.relative_to(CLIENT).as_posix() for p in ADDONS.rglob('*') if p.is_file()}
        self.assertEqual(set(rows), files)
        for path, digest in rows.items():
            self.assertEqual(hashlib.sha256((CLIENT / path).read_bytes()).hexdigest(), digest, path)

    def test_tocs_load_their_files(self):
        tocs = list(ADDONS.glob('*/*.toc'))
        self.assertEqual(sorted(t.parent.name for t in tocs), ['AcoreLib', 'wotlk_petbattle', 'wotlk_pets'])
        for toc in tocs:
            lines = toc.read_text(encoding='utf-8').splitlines()
            self.assertIn('## Interface: 30300', lines, toc.name)
            for name in (line.strip() for line in lines if line.strip() and not line.startswith('#')):
                self.assertTrue((toc.parent / name).is_file(), f'{toc.name}: {name}')

    def test_matches_upstream_when_available(self):
        upstream = os.environ.get('PET_BATTLES_UPSTREAM')
        if not upstream:
            self.skipTest('PET_BATTLES_UPSTREAM is not set')
        for path in manifest():
            source = Path(upstream) / 'addons' / Path(path).relative_to('AddOns')
            self.assertEqual(source.read_bytes(), (CLIENT / path).read_bytes(), path)


if __name__ == '__main__':
    unittest.main()
