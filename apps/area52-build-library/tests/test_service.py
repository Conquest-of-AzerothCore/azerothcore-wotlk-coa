import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock,patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import worker_service as service


class ServiceTests(unittest.TestCase):
    def test_cycle_respects_publication_switch_and_catalog(self):
        config={'installation':'test','publication_enabled':False,'state_directory':'unused'}
        catalog=Mock();catalog.data={'catalog':'v1','spell_ids':[116],'enchant_ids':[]}
        with patch.object(service,'ingest') as ingest,patch.object(service,'process') as publish,patch.object(service,'reconcile'),patch.object(service,'refresh') as refresh:
            service.cycle(config,Mock(),Mock(),Mock(),catalog)
            publish.assert_not_called();catalog.check.assert_called_once()
            self.assertIs(ingest.call_args.args[-1],catalog.validate)
            self.assertIs(refresh.call_args.kwargs['validate'],catalog.validate)
            config['publication_enabled']=True
            service.cycle(config,Mock(),Mock(),Mock(),catalog)
            publish.assert_called_once()
    def test_catalog_drift_stops_all_mutations(self):
        catalog=Mock();catalog.check.side_effect=ValueError('drift')
        with patch.object(service,'ingest') as ingest:
            with self.assertRaises(ValueError):service.cycle({},None,None,None,catalog)
            ingest.assert_not_called()
    @unittest.skipIf(os.name=='nt','POSIX credential and flock checks run through the WSL offline runner')
    def test_lock_and_private_token(self):
        with tempfile.TemporaryDirectory() as root:
            with service.lock(root):
                with self.assertRaises(BlockingIOError):
                    with service.lock(root):pass
            path=Path(root)/'token';path.write_text('x'*30);path.chmod(0o600)
            self.assertEqual(service.token_file(path),'x'*30)
            path.chmod(0o644)
            with self.assertRaises(ValueError):service.token_file(path)
            path.chmod(0o600);alias=Path(root)/'alias';alias.symlink_to(path)
            with self.assertRaises(ValueError):service.token_file(alias)
    def test_no_authentication_redirects(self):
        with self.assertRaises(RuntimeError):service.NoRedirect().redirect_request(None,None,None,None,None,None)


if __name__=='__main__':unittest.main()
