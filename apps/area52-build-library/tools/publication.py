"""Server-only durable publication queue. Never import this module into a game client."""
from contextlib import contextmanager
import hashlib
import json
import sqlite3
import subprocess
import uuid

import portable_dependency
from library import canonical, decode, make_record, require, validate_record
from native_wire import portable, decode_wire
from catalog import page, overview


class Queue:
    def __init__(self, path):
        self.connection = sqlite3.connect(path)
        self.connection.row_factory = sqlite3.Row
        self.connection.executescript('''
            PRAGMA journal_mode=WAL;
            PRAGMA foreign_keys=ON;
            CREATE TABLE IF NOT EXISTS bindings (
                source TEXT PRIMARY KEY, public_id TEXT UNIQUE NOT NULL);
            CREATE TABLE IF NOT EXISTS requests (
                id TEXT PRIMARY KEY, source TEXT NOT NULL REFERENCES bindings(source),
                source_revision INTEGER NOT NULL, fingerprint TEXT NOT NULL,
                record TEXT NOT NULL, state TEXT NOT NULL DEFAULT 'queued',
                intent TEXT, error TEXT, UNIQUE(source,source_revision));
        ''')

    @contextmanager
    def transaction(self):
        self.connection.execute('BEGIN IMMEDIATE')
        try:
            yield
            self.connection.commit()
        except Exception:
            self.connection.rollback()
            raise

    def enqueue(self, installation, owner, local_build, local_revision, code, author, catalog, consent):
        require(consent == 'CC0-1.0', 'Explicit CC0 consent is required')
        require(type(owner) is int and owner > 0, 'Authenticated owner required')
        require(type(local_build) is str and local_build.isdecimal() and 0 < int(local_build) < 2**64, 'Invalid local build')
        require(type(local_revision) is int and 0 < local_revision < 2**32, 'Invalid source revision')
        installation = str(uuid.UUID(installation))
        source = hashlib.sha256(canonical([installation, owner, local_build])).hexdigest()
        build = decode(code)
        fingerprint = hashlib.sha256(canonical([build, author, catalog, consent])).hexdigest()
        with self.transaction():
            prior = self.connection.execute('SELECT * FROM requests WHERE source=? AND source_revision=?', (source, local_revision)).fetchone()
            if prior:
                require(prior['fingerprint'] == fingerprint, 'Source revision was already queued with different content')
                return prior['id']
            row = self.connection.execute('SELECT public_id FROM bindings WHERE source=?', (source,)).fetchone()
            public_id = row[0] if row else str(uuid.uuid4())
            if not row:
                self.connection.execute('INSERT INTO bindings VALUES (?,?)', (source, public_id))
            revision = self.connection.execute('SELECT COUNT(*)+1 FROM requests WHERE source=?', (source,)).fetchone()[0]
            record = make_record(build, author, catalog, public_id, revision)
            request = str(uuid.uuid4())
            self.connection.execute('INSERT INTO requests(id,source,source_revision,fingerprint,record) VALUES (?,?,?,?,?)',
                                    (request, source, local_revision, fingerprint, canonical(record).decode()))
            return request

    def get(self, request):
        row = self.connection.execute('SELECT * FROM requests WHERE id=?', (request,)).fetchone()
        require(row is not None, 'Unknown publication request')
        return dict(row)

    def enqueue_saved(self, installation, session_account, build_id, expected_updated,
                      confirmed_code, alias, catalog, consent, read_saved):
        saved = read_saved(build_id)
        require(saved is not None and saved['owner_account'] == session_account, 'Build is not owned by this session')
        raw = bytes.fromhex(saved['wire'])
        require(decode_wire(raw)['Updated'] == expected_updated, 'Saved build changed after confirmation')
        require(canonical(portable(raw)) == canonical(decode(confirmed_code)), 'Confirmed build differs from saved revision')
        return self.enqueue(installation, session_account, build_id, saved['revision'],
                            confirmed_code, alias, catalog, consent)

    def intent(self, request, value):
        with self.transaction():
            row = self.get(request)
            require(row['state'] == 'queued' and row['intent'] is None, 'Publication already started')
            self.connection.execute("UPDATE requests SET state='uncertain',intent=? WHERE id=?", (canonical(value).decode(), request))

    def finish(self, request, state, error=None):
        require(state in ('published', 'uncertain', 'conflict'), 'Invalid publication state')
        with self.transaction():
            self.connection.execute('UPDATE requests SET state=?,error=? WHERE id=?', (state, error, request))


def publish(queue, request, remote):
    row = queue.get(request)
    if row['state'] == 'published':
        return 'published'
    if row['intent']:
        intent = json.loads(row['intent'])
        require(intent['repository'] == remote.repository, 'Recovery repository mismatch')
        return reconcile(queue, request, remote, intent)
    require(row['state'] == 'queued', 'Request requires operator review')
    record = validate_record(json.loads(row['record']))
    head = remote.head()
    path = 'builds/' + record['id'] + '/' + str(record['revision']) + '.json'
    body = canonical(record)
    old = remote.read(head, path)
    require(old is None or old == body, 'Conflicting public revision')
    previous_index = remote.read(head, 'index.json')
    index = json.loads(previous_index) if previous_index else {'schema': 1, 'builds': []}
    require(set(index) == {'schema', 'builds'} and index['schema'] == 1 and isinstance(index['builds'], list), 'Unsupported remote index')
    item = {'id': record['id'], 'revision': record['revision'], 'name': record['build']['Name'],
            'author': record['author'], 'compatibility': record['compatibility'], 'path': path,
            'sha256': hashlib.sha256(body).hexdigest()}
    existing = [r for r in index['builds'] if r.get('path') == path]
    require(not existing or existing == [item], 'Conflicting remote index revision')
    if not existing:
        index['builds'].append(item)
    index['builds'].sort(key=lambda r: (r['id'], r['revision']))
    catalog_path = 'catalog/' + record['id'] + '/' + str(record['revision']) + '.md'
    rendered = page(record).encode('utf-8')
    prior_page = remote.read(head, catalog_path)
    require(prior_page is None or prior_page == rendered, 'Conflicting public catalog revision')
    files = {path: body, 'index.json': canonical(index), catalog_path: rendered,
             'CATALOG.md': overview(index['builds']).encode('utf-8')}
    commit = remote.create_commit(head, files)
    intent = {'repository': remote.repository, 'previous': head, 'commit': commit,
              'files': {key: hashlib.sha256(value).hexdigest() for key, value in files.items()}}
    queue.intent(request, intent)
    try:
        remote.advance(head, commit)
    except Exception:
        pass
    return reconcile(queue, request, remote, intent)


def reconcile(queue, request, remote, intent):
    try:
        head = remote.head()
        if head != intent['commit'] and not remote.descendant(intent['commit'], head):
            queue.finish(request, 'uncertain', 'Remote update unconfirmed; no write retried')
            return 'uncertain'
        for commit in set((head, intent['commit'])):
            for path, digest in intent['files'].items():
                value = remote.read(commit, path)
                if value is None or hashlib.sha256(value).hexdigest() != digest:
                    queue.finish(request, 'conflict', 'Published files differ; operator review required')
                    return 'conflict'
        queue.finish(request, 'published')
        return 'published'
    except Exception:
        queue.finish(request, 'uncertain', 'Remote readback unavailable; no write retried')
        return 'uncertain'


class GitHub:
    def __init__(self, repository, executable='gh'):
        require(repository == 'CWO4PapaBear/Area-52-Build-Architect-Library', 'Unapproved repository')
        self.repository, self.executable = repository, executable
        self.trees = {}

    def api(self, endpoint, payload=None, method=None):
        args = [self.executable, 'api', 'repos/' + self.repository + '/' + endpoint]
        if method:
            args += ['--method', method]
        if payload is not None:
            args += ['--input', '-']
        result = subprocess.run(args, input=json.dumps(payload).encode() if payload is not None else None,
                                capture_output=True, timeout=60)
        if result.returncode:
            raise RuntimeError('GitHub request failed; response and credentials withheld')
        return json.loads(result.stdout)

    def head(self):
        return self.api('git/ref/heads/main')['object']['sha']

    def read(self, commit, path):
        import base64
        require(len(commit) == 40 and all(c in '0123456789abcdef' for c in commit), 'Invalid commit')
        if commit not in self.trees:
            self.trees[commit] = self.api('git/trees/' + commit + '?recursive=1')
        tree = self.trees[commit]
        require(not tree.get('truncated'), 'Remote tree truncated')
        nodes = [r for r in tree['tree'] if r['path'] == path]
        if not nodes:
            return None
        require(len(nodes) == 1 and nodes[0]['type'] == 'blob' and nodes[0]['mode'] == '100644', 'Unexpected remote file type')
        value = self.api('git/blobs/' + nodes[0]['sha'])
        require(value['encoding'] == 'base64' and value['size'] <= 8 * 1024 * 1024, 'Unsupported remote blob')
        data = base64.b64decode(value['content'])
        require(len(data) == value['size'], 'Remote blob length mismatch')
        require(hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest() == nodes[0]['sha'], 'Remote blob hash mismatch')
        return data

    def create_commit(self, head, files):
        import base64
        tree = []
        for path, body in files.items():
            blob = self.api('git/blobs', {'content': base64.b64encode(body).decode(), 'encoding': 'base64'})
            tree.append({'path': path, 'mode': '100644', 'type': 'blob', 'sha': blob['sha']})
        parent = self.api('git/commits/' + head)
        created = self.api('git/trees', {'base_tree': parent['tree']['sha'], 'tree': tree})
        return self.api('git/commits', {'message': 'Publish an explicitly shared Area 52 build', 'tree': created['sha'], 'parents': [head]})['sha']

    def advance(self, previous, commit):
        require(self.head() == previous, 'Concurrent repository change; no update attempted')
        self.api('git/refs/heads/main', {'sha': commit, 'force': False}, 'PATCH')

    def descendant(self, ancestor, head):
        return self.api('compare/' + ancestor + '...' + head)['status'] in ('ahead', 'identical')
