"""Single-instance server worker; installation and service start are separate deployment actions."""
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import stat
import time
import urllib.error
import urllib.request
import uuid

import portable_dependency
from library import require
from publication import GitHub,Queue
from ingestion import ingest,reconcile
from native_catalog import NativeCatalog,CatalogDrift
from notifications import notify
from refresh import RealmDatabase,run as refresh
from worker import process,REPOSITORY


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):
        raise RuntimeError('GitHub redirect refused')


class Remote(GitHub):
    def __init__(self,token):
        super().__init__(REPOSITORY)
        self.token=token
        self.opener=urllib.request.build_opener(NoRedirect)

    def api(self,endpoint,payload=None,method=None):
        request=urllib.request.Request('https://api.github.com/repos/'+self.repository+'/'+endpoint,
            data=json.dumps(payload).encode() if payload is not None else None,
            headers={'Authorization':'Bearer '+self.token,'Accept':'application/vnd.github+json',
                     'User-Agent':'Area52-Build-Library','X-GitHub-Api-Version':'2022-11-28'},
            method=method or ('POST' if payload is not None else 'GET'))
        try:
            with self.opener.open(request,timeout=60) as response:
                data=response.read(16*1024*1024+1)
                require(len(data)<=16*1024*1024,'GitHub response exceeds limits')
                return json.loads(data)
        except urllib.error.HTTPError as error:
            raise RuntimeError('GitHub operation failed (HTTP '+str(error.code)+'); details withheld') from None
        except (urllib.error.URLError,TimeoutError):
            raise RuntimeError('GitHub transport unavailable; details withheld') from None


def token_file(path):
    path=Path(path)
    require(path.is_file() and not path.is_symlink(),'Worker token is not configured')
    require(stat.S_IMODE(path.stat().st_mode)&0o077==0,'Worker token permissions must be private')
    value=path.read_text().strip()
    require(20<=len(value)<=4096 and not any(c.isspace() for c in value),'Invalid worker token')
    return value


@contextmanager
def lock(directory):
    import fcntl
    directory=Path(directory);directory.mkdir(mode=0o700,parents=True,exist_ok=True)
    with (directory/'worker.lock').open('a') as stream:
        fcntl.flock(stream,fcntl.LOCK_EX|fcntl.LOCK_NB)
        yield


def cycle(config,queue,remote,database,catalog):
    catalog.check()
    data=catalog.data
    ingest(database,queue,config['installation'],data['catalog'],catalog.validate)
    if config['publication_enabled']:
        process(queue,remote,catalog.validate)
    reconcile(database,queue)
    return refresh(database,remote,data['catalog'],set(data['spell_ids']),set(data['enchant_ids']),
                   Path(config['state_directory'])/'cache',validate=catalog.validate)


def load(path):
    config=json.loads(Path(path).read_text())
    require(config['schema']==1 and type(config['publication_enabled']) is bool,'Unsupported worker config')
    require(5<=config['poll_seconds']<=300,'Invalid worker interval')
    config['installation']=str(uuid.UUID(config['installation']))
    return config


def cycle_and_report(config,queue,database,catalog=None):
    blocked=None
    try:
        if catalog is None:catalog=NativeCatalog(config['catalog_manifest'],config['validator'],config['catalog_directory'])
        remote=Remote(token_file(config['token_file']))
        cycle(config,queue,remote,database,catalog)
    except Exception as error:
        blocked='catalog' if isinstance(error,CatalogDrift) else 'unavailable'
        print('Library cycle paused: '+blocked+'; request retained.',flush=True)
    try:notify(config,queue,database,blocked)
    except Exception:print('Private status notification unavailable; no send retried.',flush=True)
    return catalog


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config',type=Path,required=True)
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--offline',action='store_true')
    args=parser.parse_args()
    require(not args.offline or args.check,'Offline mode is only for read-only checks')
    config=load(args.config)
    if args.check:
        catalog=NativeCatalog(config['catalog_manifest'],config['validator'],config['catalog_directory'])
        if not args.offline:
            remote=Remote(token_file(config['token_file']))
            require(len(remote.head())==40,'Remote repository readback failed')
        print('Worker configuration and catalog checks passed; no service, SQL or publication changes.')
        return
    os.umask(0o077)
    with lock(config['state_directory']):
        queue=Queue(Path(config['state_directory'])/'queue.sqlite')
        database=RealmDatabase(config['realm_container'])
        catalog=None
        try:
            while True:
                catalog=cycle_and_report(config,queue,database,catalog)
                time.sleep(config['poll_seconds'])
        finally:
            queue.connection.close()


if __name__=='__main__':main()
