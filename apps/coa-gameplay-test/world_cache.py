import hashlib
import json
import os
import re
import secrets

IDENTIFIER = re.compile(r'[A-Za-z_][A-Za-z0-9_]*\Z')
OWNER_TABLE = 'coa_gameplay_cache_owner'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def read_identity(database, statement):
    for _ in range(3):
        value = database.sql('world', statement)
        if value:
            return value
    raise ValueError('World cache identity query returned no data after three reads')


def write_json(path, value):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')
    temporary.replace(path)


def input_fingerprint(root, source_config, module_source, environment=None):
    paths = {source_config}
    paths.update(module_source.glob('*.conf'))
    for directory in (root / 'data/sql/updates', root / 'data/sql/custom', root / 'modules'):
        if directory.exists():
            paths.update(directory.rglob('*.sql'))
    result = hashlib.sha256()
    source = os.environ if environment is None else environment
    result.update(json.dumps({key: value for key, value in source.items() if key.startswith('AC_')},
                             sort_keys=True).encode())
    for path in sorted(paths):
        result.update(str(path.resolve()).encode())
        with path.open('rb') as stream:
            result.update(hashlib.file_digest(stream, 'sha256').digest())
    return result.hexdigest()


def world_fingerprint(database, name):
    require(IDENTIFIER.fullmatch(name), 'Invalid world schema name')
    rows = database.sql('world', f'SHOW FULL TABLES FROM `{name}`;').splitlines()
    tables = []
    for row in rows:
        table, kind = row.split('\t')
        require(IDENTIFIER.fullmatch(table), 'Unsupported world table name; use --fresh-databases')
        require(kind == 'BASE TABLE', 'World cache requires base tables; use --fresh-databases')
        if table != OWNER_TABLE:
            tables.append(table)
    require(tables, 'World database is empty')
    tables.sort()
    names = ', '.join(f'`{name}`.`{table}`' for table in tables)
    checksums = database.sql('world', f'CHECKSUM TABLE {names} EXTENDED;', timeout=300).splitlines()
    expected = {f'{name}.{table}' for table in tables}
    values = {}
    for row in checksums:
        table, checksum = row.split('\t')
        require(table in expected and checksum.isdecimal(), 'World checksum unavailable; use --fresh-databases')
        values[table.split('.', 1)[1]] = checksum
    require(len(values) == len(tables), 'Incomplete world checksums')
    for _ in range(3):
        definitions = database.sql('world', '\n'.join(f'SHOW CREATE TABLE `{name}`.`{table}`;' for table in tables))
        if len(definitions.splitlines()) == len(tables):
            break
    require(len(definitions.splitlines()) == len(tables), 'Incomplete world table definitions')
    programs = database.sql('world',
                            f"SELECT (SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='{name}')"
                            f" + (SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='{name}')"
                            f" + (SELECT COUNT(*) FROM information_schema.EVENTS WHERE EVENT_SCHEMA='{name}');")
    require(programs == '0', 'World cache excludes triggers/routines/events; use --fresh-databases')
    return digest({'data': values, 'definitions': definitions})


class WorldCache:
    def __init__(self, database, root, inputs, result_directory=None):
        self.database = database
        self.result_directory = result_directory if result_directory is not None else database.directory
        source = database.connections['world']
        self.source = source.database
        server = read_identity(database, 'SELECT @@server_uuid;')
        require(re.fullmatch(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', server),
                'World cache server identity is not a complete MySQL UUID')
        self.identity = digest([source.host, source.port, source.database, server])
        self.directory = root / self.identity[:24]
        self.path = self.directory / 'world.json'
        self.lock = self.directory / 'lease.json'
        self.inputs = inputs
        self.metadata = None
        self.locked = False
        self.owned = False
        self.created_here = False
        self.baseline = None
        self.info = {'mode': 'pending', 'retained': False, 'directory': str(self.directory)}

    @property
    def name(self):
        return f"coa_test_{self.metadata['world_id']}_world"

    def acquire(self):
        self.directory.mkdir(parents=True, exist_ok=True)
        try:
            stream = self.lock.open('x', encoding='utf-8')
        except FileExistsError:
            raise ValueError(f'World cache is leased: {self.lock}. Another run or an interrupted server may '
                             'still own it. Use --fresh-databases for an independent run.') from None
        self.locked = True
        with stream:
            json.dump({'runner_pid': os.getpid(), 'results': str(self.result_directory)}, stream)

    def verify_owner(self):
        require(self.name != self.source, 'Source and cached world must differ')
        token = read_identity(self.database, f'SELECT token FROM `{self.name}`.`{OWNER_TABLE}`;')
        require(token == self.metadata['token'], 'World cache ownership mismatch; refusing to reuse or drop it')

    def save(self):
        write_json(self.path, self.metadata)

    def drop(self):
        if not self.created_here:
            self.verify_owner()
        self.database.sql('world', f'DROP DATABASE `{self.name}`;')
        self.owned = False
        self.created_here = False
        self.path.unlink(missing_ok=True)

    def prepare(self, refresh=False):
        self.acquire()
        if self.path.exists():
            self.metadata = json.loads(self.path.read_text(encoding='utf-8'))
            require(self.metadata.get('schema') == 1 and self.metadata.get('identity') == self.identity,
                    'World cache metadata is incompatible')
            require(re.fullmatch(r'[0-9a-f]{12}', self.metadata.get('world_id', '')), 'Invalid cached world ID')
            require(re.fullmatch(r'[0-9a-f]{64}', self.metadata.get('token', '')), 'Invalid cache ownership token')
            require(self.metadata.get('state') in {'ready', 'invalid'},
                    'World cache was not released cleanly; inspect its lease/results or use --fresh-databases')
            self.verify_owner()
            self.owned = True
        print('Checking source world data for changes...', flush=True)
        source_fingerprint = world_fingerprint(self.database, self.source)
        if self.owned:
            unchanged = self.metadata['state'] == 'ready'
            unchanged = unchanged and self.metadata['source_fingerprint'] == source_fingerprint
            unchanged = unchanged and self.metadata['inputs'] == self.inputs
            unchanged = unchanged and world_fingerprint(self.database, self.name) == self.metadata['fingerprint']
            if refresh or not unchanged:
                self.drop()
                self.info['mode'] = 'refreshed'
        if not self.owned:
            self.metadata = {'schema': 1, 'identity': self.identity, 'world_id': secrets.token_hex(6),
                             'token': secrets.token_hex(32), 'state': 'building', 'inputs': self.inputs,
                             'source_fingerprint': source_fingerprint}
            require(self.name != self.source, 'Source and cached world must differ')
            self.database.sql('world', f'CREATE DATABASE `{self.name}` '
                              'CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;')
            self.owned = self.created_here = True
            self.save()
            self.database.names['world'] = self.name
            print('Preparing reusable world database...', flush=True)
            self.database.copy('world')
            self.database.sql('world', f'CREATE TABLE `{self.name}`.`{OWNER_TABLE}` '
                              '(token CHAR(64) NOT NULL PRIMARY KEY) ENGINE=InnoDB; '
                              f"INSERT INTO `{self.name}`.`{OWNER_TABLE}` VALUES ('{self.metadata['token']}');")
            require(world_fingerprint(self.database, self.source) == source_fingerprint,
                    'Source world changed while copying; retry after the data update completes')
            if self.info['mode'] != 'refreshed':
                self.info['mode'] = 'created'
        else:
            self.info['mode'] = 'reused'
            print('Reusing isolated world database; full copy skipped.', flush=True)
        self.database.names['world'] = self.name
        self.info['database'] = self.name
        self.metadata['state'] = 'in_use'
        self.save()

    def ready(self, record, start_file, run_id):
        require(record.get('waiting_for_start') in (True, 'true'),
                'This worldserver lacks the database-cache startup barrier; rebuild or use --fresh-databases')
        self.verify_owner()
        self.baseline = world_fingerprint(self.database, self.name)
        write_json(start_file, {'run_id': run_id})

    def finish(self, server_still_running=False):
        if not self.locked:
            return
        if server_still_running:
            self.info['blocked'] = 'Test server could not be stopped; lease and database retained'
            return
        try:
            if self.owned:
                if self.baseline:
                    self.verify_owner()
                if self.baseline and world_fingerprint(self.database, self.name) == self.baseline:
                    self.metadata.update(state='ready', fingerprint=self.baseline)
                    self.save()
                    self.info['retained'] = True
                else:
                    self.drop()
                    self.info['invalidated'] = 'World data changed during the scenario or startup did not complete'
        except Exception:
            if self.owned:
                self.metadata['state'] = 'invalid'
                self.save()
            raise
        finally:
            self.lock.unlink()
            self.locked = False
