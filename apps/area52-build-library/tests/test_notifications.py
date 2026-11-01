import json,sqlite3,tempfile,unittest
from pathlib import Path
from unittest.mock import Mock,patch
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import notifications as n
import worker_service as service
from native_catalog import CatalogDrift
class NotificationTests(unittest.TestCase):
 def setUp(self):
  self.q=Mock();self.q.connection=sqlite3.connect(':memory:');self.config={'notification_since':'2026-11-01 16:31:34'}
  self.row={'owner':1,'token':'abc','queue':None,'state':'queued','name':'Example'}
  self.db=Mock(side_effect=lambda sql:json.dumps(self.row));self.send=Mock()
 def tearDown(self):self.q.connection.close()
 def test_pause_once_and_completion(self):
  for _ in range(3):n.notify(self.config,self.q,self.db,'catalog',self.send)
  self.send.assert_called_once();self.assertIn('catalog rules changed',self.send.call_args.args[1])
  self.row['state']='published';n.notify(self.config,self.q,self.db,None,self.send);self.assertEqual(self.send.call_count,2)
  n.notify(self.config,self.q,self.db,None,self.send);self.assertEqual(self.send.call_count,2)
  self.assertTrue(all(c.args[0].startswith('SELECT ') for c in self.db.call_args_list))
 def test_uncertain_send_never_repeated(self):
  self.send.side_effect=RuntimeError('response lost')
  n.notify(self.config,self.q,self.db,'unavailable',self.send);n.notify(self.config,self.q,self.db,'unavailable',self.send)
  self.send.assert_called_once();self.assertEqual(self.q.connection.execute('SELECT state FROM notification_receipts').fetchone()[0],'uncertain')
 def test_offline_no_receipt_and_known_failure(self):
  self.db.side_effect=None;self.db.return_value='';n.notify(self.config,self.q,self.db,'catalog',self.send);self.send.assert_not_called()
  self.db.return_value=json.dumps(dict(self.row,state='failed'));n.notify(self.config,self.q,self.db,None,self.send);self.assertIn('catalog/format',self.send.call_args.args[1])
 def test_uncertain_queue_message(self):
  self.row.update(queue='q',state='accepted');self.q.get.return_value={'state':'uncertain','error':'private'}
  n.notify(self.config,self.q,self.db,None,self.send);self.assertIn('will not repeat the write',self.send.call_args.args[1]);self.assertNotIn('private',self.send.call_args.args[1])
 def test_cold_start_drift_and_recovery(self):
  config=dict(self.config,catalog_manifest='m',validator='v',catalog_directory='d',token_file='t')
  with patch.object(service,'NativeCatalog',side_effect=CatalogDrift('private path')),patch.object(service,'notify') as notify,patch.object(service,'cycle') as cycle:
   self.assertIsNone(service.cycle_and_report(config,self.q,self.db));cycle.assert_not_called();self.assertEqual(notify.call_args.args[-1],'catalog')
  with patch.object(service,'NativeCatalog') as cat,patch.object(service,'token_file',return_value='secret'),patch.object(service,'Remote'),patch.object(service,'notify') as notify,patch.object(service,'cycle') as cycle:
   result=service.cycle_and_report(config,self.q,self.db);self.assertIs(result,cat.return_value);cycle.assert_called_once();self.assertIsNone(notify.call_args.args[-1])
class IngestDriftTests(unittest.TestCase):
 def test_drift_during_validation_retains_realm_request(self):
  import ingestion
  query=Mock(return_value=json.dumps({'owner':1,'token':'abc','build':'1','revision':2,'wire':'00','alias':'Test','consent':'CC0-1.0'}))
  queue=Mock()
  with patch.object(ingestion,'portable',return_value={}):
   with self.assertRaises(CatalogDrift):
    ingestion.ingest(query,queue,'unused','v1',Mock(side_effect=CatalogDrift('changed')))
  query.assert_called_once();queue.enqueue.assert_not_called()
if __name__=='__main__':unittest.main()
