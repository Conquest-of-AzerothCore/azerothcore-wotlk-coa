import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from library import encode
from publication import Queue, publish
from worker import process
from test_library import sample


class Remote:
    repository = 'CWO4PapaBear/Area-52-Build-Architect-Library'

    def __init__(self):
        self.current = 'initial'
        self.commits = {'initial': {'LICENSE': b'preserve', 'README.md': b'preserve'}}
        self.parents = {}
        self.writes = 0
        self.fail_before = self.fail_after = self.read_failure = False

    def head(self):
        if self.read_failure:
            raise RuntimeError('secret error body must not escape')
        return self.current

    def read(self, commit, path):
        return self.commits[commit].get(path)

    def create_commit(self, head, files):
        new = str(uuid.uuid4())
        self.commits[new] = dict(self.commits[head], **files)
        self.parents[new] = head
        return new

    def advance(self, before, new):
        self.writes += 1
        if self.fail_before:
            raise RuntimeError('not written')
        assert self.current == before
        self.current = new
        if self.fail_after:
            raise RuntimeError('response lost')

    def descendant(self, ancestor, head):
        while head in self.parents:
            head = self.parents[head]
            if head == ancestor:
                return True
        return False


class PublicationTests(unittest.TestCase):
    def test_progression_rechecked_before_remote_mutation(self):
        request=self.queue.enqueue(str(uuid.uuid4()),7,'123',1,encode(sample()),'Alias','v1','CC0-1.0')
        remote=Remote()
        results=process(self.queue,remote,lambda build:'prerequisite missing at level 20')
        self.assertEqual(results[0]['state'],'conflict')
        self.assertEqual(remote.writes,0)
        self.assertEqual(self.queue.get(request)['state'],'conflict')
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / 'private.sqlite'
        self.queue = Queue(self.path)
        self.installation = str(uuid.uuid4())
        self.remote = Remote()

    def tearDown(self):
        self.queue.connection.close()
        self.temp.cleanup()

    def enqueue(self, owner=7, revision=1, author='Public alias'):
        return self.queue.enqueue(self.installation, owner, '456', revision, encode(sample()), author, 'test-v1', 'CC0-1.0')

    def test_idempotent_queue_and_owner_isolation(self):
        first = self.enqueue()
        self.assertEqual(first, self.enqueue())
        with self.assertRaises(ValueError):
            self.enqueue(author='Changed')
        other = self.enqueue(owner=8)
        get_id = lambda request: json.loads(self.queue.get(request)['record'])['id']
        self.assertNotEqual(get_id(first), get_id(other))
        self.assertEqual(get_id(first), get_id(self.enqueue(revision=2)))

    def test_lost_successful_response_and_no_resend(self):
        request = self.enqueue()
        self.remote.fail_after = True
        self.assertEqual(publish(self.queue, request, self.remote), 'published')
        self.queue.connection.close()
        self.queue = Queue(self.path)
        self.assertEqual(publish(self.queue, request, self.remote), 'published')
        self.assertEqual(self.remote.writes, 1)
        self.assertEqual(self.remote.commits[self.remote.current]['LICENSE'], b'preserve')
        public = json.loads(self.queue.get(request)['record'])
        self.assertNotIn('owner', public)
        self.assertNotIn('source', public)

    def test_failed_write_never_blindly_retried(self):
        request = self.enqueue()
        self.remote.fail_before = True
        self.assertEqual(publish(self.queue, request, self.remote), 'uncertain')
        self.remote.fail_before = False
        self.assertEqual(publish(self.queue, request, self.remote), 'uncertain')
        self.assertEqual(self.remote.writes, 1)

    def test_readback_loss_and_descendant_recovery(self):
        request = self.enqueue()
        advance = self.remote.advance
        def lose(before, new):
            advance(before, new)
            self.remote.read_failure = True
        self.remote.advance = lose
        self.assertEqual(publish(self.queue, request, self.remote), 'uncertain')
        self.assertNotIn('secret', self.queue.get(request)['error'])
        self.remote.read_failure = False
        new = self.remote.create_commit(self.remote.current, {'README.md': b'unrelated edit'})
        self.remote.current = new
        self.assertEqual(publish(self.queue, request, self.remote), 'published')
        self.assertEqual(self.remote.writes, 1)

    def test_conflicting_descendant_rejected(self):
        request = self.enqueue()
        self.remote.fail_before = True
        publish(self.queue, request, self.remote)
        intent = json.loads(self.queue.get(request)['intent'])
        new = self.remote.create_commit(intent['commit'], {'index.json': b'wrong'})
        self.remote.current = new
        self.assertEqual(publish(self.queue, request, self.remote), 'conflict')
        self.assertEqual(self.remote.writes, 1)


if __name__ == '__main__':
    unittest.main()
