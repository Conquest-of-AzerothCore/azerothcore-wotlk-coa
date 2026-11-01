"""Validate a public library snapshot before making it available to the game server."""
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile

import portable_dependency
from library import canonical, encode, require, validate_record


def safe_preview(value):
    return ''.join(c for c in value if c >= ' ' and c not in '|\x7f')


def snapshot(remote, catalog, blob_directory=None):
    head = remote.head()
    raw = remote.read(head, 'index.json')
    index = json.loads(raw) if raw else {'schema': 1, 'builds': []}
    require(isinstance(index, dict) and set(index) == {'schema', 'builds'} and index['schema'] == 1, 'Unsupported index')
    require(isinstance(index['builds'], list) and len(index['builds']) <= 10000, 'Library index exceeds limits')
    result, seen = [], set()
    for item in index['builds']:
        require(isinstance(item, dict) and isinstance(item.get('path'), str), 'Invalid index entry')
        path = item['path']
        require(re.fullmatch(r'builds/[0-9a-f-]{36}/[1-9][0-9]{0,9}\.json', path) is not None, 'Invalid library path')
        require(path not in seen, 'Duplicate library revision')
        seen.add(path)
        digest=item.get('sha256')
        require(isinstance(digest,str) and re.fullmatch('[0-9a-f]{64}',digest),'Invalid record digest')
        cached=Path(blob_directory)/(digest+'.json') if blob_directory else None
        body = cached.read_bytes() if cached and cached.is_file() else remote.read(head, path)
        require(body is not None and len(body) <= 200000, 'Missing or oversized library record')
        require(hashlib.sha256(body).hexdigest() == item.get('sha256'), 'Library record hash mismatch')
        record = validate_record(json.loads(body))
        require(path == 'builds/' + record['id'] + '/' + str(record['revision']) + '.json', 'Library identity mismatch')
        require(item.get('id') == record['id'] and item.get('revision') == record['revision'], 'Index identity mismatch')
        require(item.get('name') == record['build']['Name'] and item.get('author') == record['author'] and
                item.get('compatibility') == record['compatibility'], 'Index metadata mismatch')
        if cached and not cached.exists():
            cached.parent.mkdir(parents=True,exist_ok=True)
            with tempfile.NamedTemporaryFile(dir=cached.parent,delete=False) as output:
                temporary=Path(output.name);output.write(body);output.flush();os.fsync(output.fileno())
            os.replace(temporary,cached)
        result.append({'id': record['id'], 'revision': record['revision'],
                       'name': safe_preview(record['build']['Name']), 'author': safe_preview(record['author']),
                       'compatible': record['compatibility']['catalog'] == catalog,
                       'catalog': record['compatibility']['catalog'], 'code': encode(record['build']),
                       'record_sha256': hashlib.sha256(body).hexdigest(), 'record': record})
    return {'schema': 1, 'commit': head, 'entries': result}


def install_snapshot(root, value):
    root = Path(root)
    root.mkdir(parents=True, exist_ok=True)
    require(re.fullmatch('[0-9a-f]{40}', value['commit']) is not None, 'Invalid immutable commit')
    data = canonical(value)
    digest = hashlib.sha256(data).hexdigest()
    target = root / (digest + '.json')
    if target.exists():
        require(target.read_bytes() == data, 'Conflicting cache snapshot')
    else:
        with target.open('xb') as output:
            output.write(data)
            output.flush()
            os.fsync(output.fileno())
    with tempfile.NamedTemporaryFile(dir=root, delete=False) as output:
        temporary = Path(output.name)
        output.write(canonical({'file': target.name, 'sha256': digest}))
        output.flush()
        os.fsync(output.fileno())
    os.replace(temporary, root / 'current.json')
    return target
