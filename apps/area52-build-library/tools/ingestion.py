"""Move authenticated, immutable realm outbox rows into the private publication queue."""
import json
import re
import portable_dependency
from library import encode, require
from native_wire import portable
from native_catalog import CatalogDrift
from projection import sql_text


def ingest(query, queue, installation, catalog, validate=None):
    rows=query("SELECT JSON_OBJECT('owner',owner_account,'token',request_token,'build',CAST(build_id AS CHAR),"
        "'revision',revision,'wire',wire,'alias',public_alias,'consent',consent) "
        "FROM area52_library_publication WHERE state='queued' ORDER BY created_at,owner_account,request_token LIMIT 10;")
    results=[]
    for line in rows.splitlines():
        row=json.loads(line)
        require(type(row['owner']) is int and row['owner']>0,'Invalid authenticated owner')
        require(re.fullmatch('[0-9a-f]{1,24}',row['token']) is not None,'Invalid request token')
        where=f"owner_account={row['owner']} AND request_token={sql_text(row['token'])}"
        try:
            build=portable(bytes.fromhex(row['wire']))
            require(not validate or validate(build) is None,'Build is incompatible with the native catalog')
            request=queue.enqueue(installation,row['owner'],row['build'],row['revision'],
                encode(build),row['alias'],catalog,row['consent'])
        except CatalogDrift:
            raise
        except ValueError:
            query("UPDATE area52_library_publication SET state='failed' WHERE "+where+" AND state='queued';")
            results.append({'state':'failed'})
            continue
        query("UPDATE area52_library_publication SET state='accepted',queue_id="+sql_text(request)+
            " WHERE "+where+" AND state='queued' AND HEX(wire)="+sql_text(row['wire'].encode().hex().upper())+";")
        confirmed=query("SELECT queue_id FROM area52_library_publication WHERE "+where+" AND state='accepted';")
        require(confirmed==request,'Outbox acceptance is unconfirmed; reconcile before publishing')
        results.append({'state':'accepted','request':request})
    return results


def reconcile(query,queue):
    rows=query("SELECT JSON_OBJECT('owner',owner_account,'token',request_token,'queue',queue_id) "
        "FROM area52_library_publication WHERE state='accepted' ORDER BY created_at LIMIT 100;")
    for line in rows.splitlines():
        row=json.loads(line)
        require(type(row['owner']) is int and row['owner']>0,'Invalid authenticated owner')
        state=queue.get(row['queue'])['state']
        if state in ('published','conflict'):
            query("UPDATE area52_library_publication SET state="+sql_text(state)+
                f" WHERE owner_account={row['owner']} AND request_token="+sql_text(row['token'])+
                " AND state='accepted' AND queue_id="+sql_text(row['queue'])+";")
