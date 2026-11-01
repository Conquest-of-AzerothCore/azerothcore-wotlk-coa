"""Run explicitly authorized publication or read-only cache refresh from a server account."""
import argparse
import json
from pathlib import Path

from cache import install_snapshot, snapshot
from publication import GitHub, Queue, publish

REPOSITORY = 'CWO4PapaBear/Area-52-Build-Architect-Library'


def process(queue, remote, validate=None):
    rows = queue.connection.execute("SELECT id FROM requests WHERE state IN ('queued','uncertain') ORDER BY rowid LIMIT 10").fetchall()
    results = []
    for row in rows:
        try:
            request=queue.get(row['id'])
            if validate and not request['intent']:
                reason=validate(json.loads(request['record'])['build'])
                if reason:
                    queue.finish(row['id'],'conflict','Native progression validation rejected the queued build')
                    results.append({'request':row['id'],'state':'conflict'})
                    continue
            state = publish(queue, row['id'], remote)
        except Exception:
            queue.connection.execute('UPDATE requests SET error=? WHERE id=?',('Publication checks or transport unavailable; retained for reconciliation',row['id']))
            queue.connection.commit()
            state = 'error'
        results.append({'request': row['id'], 'state': state})
        if state != 'published':
            break
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--queue', type=Path, required=True)
    parser.add_argument('--gh', default='gh')
    parser.add_argument('--publish', action='store_true', help='Explicitly permit queued GitHub writes')
    parser.add_argument('--refresh-cache', type=Path)
    parser.add_argument('--catalog')
    parser.add_argument('--process-refresh',action='store_true',help='Process an authenticated in-game refresh request and import shared records')
    parser.add_argument('--realm-container')
    parser.add_argument('--catalog-data',type=Path)
    parser.add_argument('--native-validator',type=Path)
    parser.add_argument('--catalog-directory',type=Path)
    parser.add_argument('--ingest',action='store_true',help='Accept authenticated realm publication requests into the private queue')
    parser.add_argument('--installation',help='Stable private UUID for this server installation')
    args = parser.parse_args()
    if not args.queue.is_file():
        parser.error('Expected an existing private queue database')
    if args.refresh_cache and not args.catalog:
        parser.error('--catalog is required for cache refresh')
    if args.process_refresh and not (args.realm_container and args.catalog_data and args.refresh_cache and args.catalog):
        parser.error('--process-refresh requires --realm-container, --catalog-data, --catalog and --refresh-cache')
    if args.ingest and not (args.realm_container and args.installation and args.catalog):
        parser.error('--ingest requires --realm-container, --installation and --catalog')
    if (args.publish or args.ingest or args.process_refresh) and not (args.catalog_data and args.native_validator and args.catalog_directory and args.catalog):
        parser.error('Native catalog manifest, validator and directory are required for realm operations')
    queue = Queue(args.queue)
    remote = GitHub(REPOSITORY, args.gh)
    try:
        if args.publish or args.ingest or args.process_refresh:
            from native_catalog import NativeCatalog
            native=NativeCatalog(args.catalog_data,args.native_validator,args.catalog_directory)
            if native.data['catalog']!=args.catalog:raise ValueError('Native catalog selection mismatch')
        if args.ingest:
            from refresh import RealmDatabase
            from ingestion import ingest,reconcile
            database=RealmDatabase(args.realm_container)
            print(json.dumps(ingest(database,queue,args.installation,args.catalog,native.validate)))
        if args.publish:
            print(json.dumps(process(queue, remote,native.validate)))
        else:
            counts = dict(queue.connection.execute('SELECT state,COUNT(*) FROM requests GROUP BY state'))
            print(json.dumps({'publication_enabled': False, 'counts': counts}))
        if args.ingest:
            reconcile(database,queue)
        if args.process_refresh:
            from refresh import RealmDatabase,run
            data=json.loads(args.catalog_data.read_text(encoding='utf-8'))
            if data['catalog']!=args.catalog:
                raise ValueError('Native catalog selection mismatch')
            print(json.dumps(run(RealmDatabase(args.realm_container),remote,args.catalog,
                set(data['spell_ids']),set(data['enchant_ids']),args.refresh_cache,validate=native.validate)))
        elif args.refresh_cache:
            target = install_snapshot(args.refresh_cache, snapshot(remote, args.catalog))
            print(json.dumps({'cache_snapshot': target.name}))
    finally:
        queue.connection.close()


if __name__ == '__main__':
    main()
