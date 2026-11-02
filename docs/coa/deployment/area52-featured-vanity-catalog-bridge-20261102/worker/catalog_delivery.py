from pathlib import Path
import copy
import json
import os
import subprocess
from catalog_publication import verify,sha


def save(path,state):
    temporary=path.with_suffix('.tmp')
    with temporary.open('w',encoding='utf-8') as stream:
        json.dump(state,stream,sort_keys=True)
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def effective(config,state):
    result=copy.deepcopy(config)
    if state.get('completed'):
        root=Path(config['outbox'])/state['completed']
        verify(root)
        for name,file in (('manifest','manifest.json'),('pointer','area52.json')):
            path=root/'release'/file
            entry={'path':str(path),'sha256':sha(path.read_bytes())}
            result['release'][name]=entry
            result['publication'][name]=entry
        result['release']['archive_sha256']=sha((root/'patch-E.MPQ').read_bytes())
    return result


def invoke(config,root,transaction):
    def windows(path):
        return subprocess.check_output(['wslpath','-w',str(path)],text=True).strip()
    command=[config['delivery']['powershell'],'-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass',
        '-File',windows(Path(__file__).with_name('Publish-Catalog.ps1')),
        '-Root',windows(root),'-Transaction',windows(transaction),'-Python',config['delivery']['python'],'-Phase','publish']
    result=subprocess.run(command,capture_output=True,timeout=1800)
    if result.returncode:
        raise RuntimeError('Catalog publication incomplete; retained immutable job and receipts')


def tick(config,query,decode,cycle,publish=invoke):
    outbox=Path(config['outbox']);outbox.mkdir(parents=True,exist_ok=True)
    path=outbox/'delivery-state.json'
    state=json.loads(path.read_text()) if path.exists() else {'schema':1}
    if state['schema']!=1:
        raise ValueError('Catalog delivery state invalid')
    if not state.get('pending'):
        identity=cycle(effective(config,state),query,decode)
        root=outbox/identity
        request=json.loads((root/'release-request.json').read_text())
        content=sha(json.dumps(request['files'],sort_keys=True).encode())
        if state.get('content')==content:
            return 'unchanged'
        state.update(pending=identity,pending_content=content)
        save(path,state)
    identity=state['pending']
    if len(identity)!=64 or any(c not in '0123456789abcdef' for c in identity):
        raise ValueError('Catalog job identity invalid')
    root=outbox/identity
    verify(root)
    transaction=outbox/'transactions'/identity
    transaction.mkdir(parents=True,exist_ok=True)
    receipt=transaction/'publication/client-release.json'
    expected=json.loads((root/'release-config.json').read_text())['id']
    def complete():
        record=json.loads(receipt.read_text()) if receipt.exists() else {}
        if record and record.get('package')!=expected:
            raise ValueError('Catalog receipt package mismatch')
        return record.get('status')=='complete' and record.get('assets_verified') is True and bool(record.get('feed_commit'))
    if not complete():
        publish(config,root,transaction)
    if not complete():
        raise RuntimeError('Catalog publication has no verified completion receipt')
    state.update(completed=identity,content=state.pop('pending_content'))
    del state['pending']
    save(path,state)
    return 'published'
