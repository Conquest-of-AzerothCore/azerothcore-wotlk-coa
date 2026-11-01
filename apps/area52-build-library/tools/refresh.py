"""Process a server-wide Update Library request; keep player-owned builds untouched."""
import json
import re
import subprocess
import time
from pathlib import Path

from cache import snapshot, install_snapshot
import portable_dependency
from library import require
from projection import prepare, apply


class RealmDatabase:
    def __init__(self, container):
        require(re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9_.-]{0,99}',container) is not None,'Invalid database container')
        self.container=container

    def __call__(self, statement):
        result=subprocess.run(['docker','exec','-i',self.container,'mysql',
            '--defaults-extra-file=/run/secrets/mysql-root.cnf','-BNr','acore_characters'],
            input=statement,text=True,capture_output=True,timeout=120)
        if result.returncode:
            codes=re.findall(r'ERROR \d+ \([^)]*\)',result.stderr)
            raise RuntimeError('Library database operation failed: '+(', '.join(codes) or 'details withheld'))
        return result.stdout.strip()


def run(query, remote, catalog, spell_ids, enchant_ids, cache_directory, now=None, validate=None):
    row=query("SELECT JSON_OBJECT('generation',generation,'state',state) FROM area52_library_refresh WHERE id=1;")
    require(bool(row),'Library refresh schema is not initialized')
    job=json.loads(row)
    if job['state'] not in ('queued','running'):
        return {'state':job['state'],'processed':False}
    generation=job['generation']
    require(type(generation) is int and generation>0,'Invalid refresh generation')
    changed=query(f"UPDATE area52_library_refresh SET state='running' WHERE id=1 AND generation={generation} AND state IN ('queued','running'); SELECT COUNT(*) FROM area52_library_refresh WHERE id=1 AND generation={generation} AND state='running';")
    require(changed=='1','Refresh request changed')
    try:
        value=snapshot(remote,catalog,Path(cache_directory)/'blobs')
        records=[entry['record'] for entry in value['entries']]
        planned=prepare(records,query,catalog,spell_ids,enchant_ids,int(time.time()) if now is None else now,validate)
        install_snapshot(cache_directory,value)
        apply(planned,query)
        added=sum(row['before'] is None for row in planned['changes'])
        updated=len(planned['changes'])-added
        skipped=len(planned['skipped'])
        changed=query(f"UPDATE area52_library_refresh SET state='complete',finished_at=UNIX_TIMESTAMP(),added={added},updated={updated},skipped={skipped} WHERE id=1 AND generation={generation} AND state='running'; SELECT ROW_COUNT();")
        require(changed=='1','Refresh result could not be confirmed')
        return {'state':'complete','processed':True,'added':added,'updated':updated,'skipped':skipped}
    except Exception:
        query(f"UPDATE area52_library_refresh SET state='failed',finished_at=UNIX_TIMESTAMP() WHERE id=1 AND generation={generation} AND state='running';")
        raise
