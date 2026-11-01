import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from native_catalog import NativeCatalog


class NativeCatalogTests(unittest.TestCase):
    def test_new_effective_override_and_changed_data_stop_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);data=root/'data';data.mkdir()
            executable=root/'validator';executable.write_bytes(b'fixture executable')
            dbc=data/'Example.dbc';dbc.write_bytes(b'fixture data')
            name='src/server/coa/Rules.cpp';fallback=root/'fallback'/name;fallback.parent.mkdir(parents=True);fallback.write_bytes(b'rules')
            effective=root/'effective'
            sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
            manifest=root/'manifest.json'
            manifest.write_text(json.dumps({'schema':1,'files':{'Example.dbc':sha(dbc)},'validator_sha256':sha(executable),
                'source':{name:sha(fallback)},'effective_source_root':str(effective),'fallback_source_root':str(root/'fallback')}))
            catalog=NativeCatalog(manifest,executable,data);catalog.check()
            override=effective/name;override.parent.mkdir(parents=True);override.write_bytes(b'changed rules')
            with self.assertRaises(ValueError):catalog.check()
            override.write_bytes(b'rules');catalog.check()
            dbc.write_bytes(b'changed data')
            with self.assertRaises(ValueError):catalog.check()


if __name__=='__main__':unittest.main()
