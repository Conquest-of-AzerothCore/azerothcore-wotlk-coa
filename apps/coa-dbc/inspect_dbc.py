CLI_DESCRIPTION = """Read-only DBC inspection shared by the CLI and local viewer. No inferred runtime values."""

import argparse
import ast
from dataclasses import asdict
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import itertools
import json
import math
from pathlib import Path
import re
import struct
import subprocess
import sys
import threading
from urllib.parse import parse_qs, urlsplit

import client_dbc
import schemas


ROOT = schemas.ROOT
HERE = Path(__file__).resolve().parent


def load_catalog():
    path = ROOT / 'apps/coa-gameplay-test/catalog.py'
    spec = importlib.util.spec_from_file_location('coa_catalog', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.catalog()


def enums(root=ROOT):
    result, constants = {}, {}

    def integer(node):
        if isinstance(node, ast.Constant) and type(node.value) is int:
            return node.value
        if isinstance(node, ast.Name):
            return constants[node.id]
        if isinstance(node, ast.BinOp) and isinstance(node.op, (ast.LShift, ast.BitOr)):
            left, right = integer(node.left), integer(node.right)
            return left << right if isinstance(node.op, ast.LShift) else left | right
        raise ValueError('Not a literal enum expression')

    for relative in ['src/server/shared/SharedDefines.h', 'src/server/game/Spells/Auras/SpellAuraDefines.h']:
        text = (root / relative).read_text(encoding='utf-8')
        text = re.sub(r'/\*.*?\*/|//[^\n]*', '', text, flags=re.S)
        for name, body in re.findall(r'enum\s+(\w+)(?:\s*:\s*\w+)?\s*\{(.*?)\};', text, re.S):
            values = {}
            previous = -1
            for part in body.split(','):
                match = re.fullmatch(r'\s*(\w+)\s*(?:=\s*(.*?))?\s*', part, re.S)
                if not match:
                    continue
                label, expression = match.groups()
                try:
                    value = integer(ast.parse(expression.strip(), mode='eval').body) if expression else previous + 1
                except (ValueError, SyntaxError, KeyError):
                    continue
                constants[label] = value
                previous = value
                values[value] = label
            result[name] = values
    return result


class DataSet:
    def __init__(self, directory, root=ROOT, sql=None, observations=()):
        self.directory = Path(directory).resolve(strict=True)
        self.schemas = schemas.registry(root)
        self.root = root
        self.enums = enums(root)
        self.files = {}
        for path in sorted(self.directory.glob('*.dbc')):
            key = path.stem.casefold()
            if key in self.files:
                raise ValueError(f'Ambiguous table name: {path.name}')
            if not path.resolve().is_relative_to(self.directory):
                raise ValueError('DBC symlinks outside the selected data directory are not supported')
            self.files[key] = path
        if not self.files:
            raise ValueError('No DBC files in the selected directory')
        self.loaded = {}
        self.label_fields = {}
        self.file_stats = {}
        self.reverse = None
        self.catalog = None
        manifest = self.directory / client_dbc.MANIFEST
        self.manifest = json.loads(manifest.read_text(encoding='utf-8')) if manifest.exists() else {}
        if not isinstance(self.manifest, dict) or not isinstance(self.manifest.get('files', {}), dict):
            raise ValueError('Unsupported extraction manifest')
        self.sql = json.loads(Path(sql).read_text(encoding='utf-8')) if sql else None
        if self.sql is not None and (not isinstance(self.sql, dict) or self.sql.get('schema') != 1
                                     or not isinstance(self.sql.get('tables'), dict)
                                     or not isinstance(self.sql.get('resolved_spells'), list)):
            raise ValueError('Unsupported SQL capture')
        self.observations = []
        for folder in map(Path, observations):
            scenario_path = folder / 'scenario.json'
            scenario = json.loads(scenario_path.read_text(encoding='utf-8'))
            summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
            report = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
            if summary.get('scenario_sha256') != hashlib.sha256(scenario_path.read_bytes()).hexdigest():
                raise ValueError('Observation scenario hash mismatch')
            if report.get('run_id') != summary.get('run_id') or report.get('scenario') != scenario.get('name'):
                raise ValueError('Observation run/scenario mismatch')
            if summary.get('scenario') != scenario.get('name') or not report.get('run_id'):
                raise ValueError('Observation summary/scenario mismatch')
            samples, seen = [], set()
            for step in report.get('steps', []):
                index = int(step['index'])
                if not 0 <= index < len(scenario['steps']) or index in seen:
                    raise ValueError('Observation step is outside the scenario or duplicated')
                seen.add(index)
                definition = scenario['steps'][index]
                if step.get('action') != definition['action']:
                    raise ValueError('Observation action does not match the scenario')
                if 'actual' in step and 'spell' in definition:
                    samples.append({'definition': definition, 'actual': step['actual'], 'status': step.get('status')})
            self.observations.append({'directory': str(folder.resolve()), 'scenario': scenario['name'],
                'run_id': report['run_id'], 'binary_sha256': summary.get('binary_sha256'),
                'native_status': summary.get('status'), 'samples': samples,
                'scope': 'recorded observations; not a current runtime snapshot or proof of deployment'})

    def load(self, name):
        key = name.removesuffix('.dbc').casefold()
        if key not in self.files:
            raise ValueError(f'Table not found: {name}')
        stat = self.files[key].stat()
        identity = (stat.st_mtime_ns, stat.st_size, stat.st_ino)
        if key in self.loaded and self.file_stats[key] != identity:
            raise ValueError('DBC changed while the inspector was open; restart it to inspect a consistent data set')
        if key not in self.loaded:
            path = self.files[key]
            data = path.read_bytes()
            after = path.stat()
            if identity != (after.st_mtime_ns, after.st_size, after.st_ino):
                raise ValueError('DBC changed while being read; retry with a stable data set')
            table = client_dbc.Table(path.name, data)
            schema = self.schemas.get(path.stem)
            if schema and (table.fields, table.record_size) != (schema.fields, schema.size):
                raise ValueError(f'{path.name}: unsupported layout {table.fields}/{table.record_size}; '
                                 f'reviewed schema requires {schema.fields}/{schema.size}')
            if table.record_size == 0 and table.rows:
                raise ValueError('Nonempty table with zero-sized records')
            index = {}
            if schema:
                field = next(field for field in schema.columns if field.name == schema.key)
                for row in range(table.rows):
                    value = struct.unpack_from('<I', data, 20 + row * table.record_size + field.offset)[0]
                    if value in index:
                        raise ValueError(f'{path.name}: duplicate ID {value}; cannot select a unique record')
                    index[value] = row
            origin = self.manifest.get('files', {}).get(path.name, {})
            digest = hashlib.sha256(data).hexdigest()
            self.loaded[key] = (table, schema, index, {
                'directory': str(self.directory), 'file': path.name, 'sha256': digest,
                'archive': origin.get('archive'), 'overridden': origin.get('overridden', []),
                'manifest_match': digest == origin['sha256'] if origin.get('sha256') else None,
                'archive_source': next((a.get('source') for a in self.manifest.get('archives', [])
                                        if a.get('name') == origin.get('archive')), None),
                'schema': schema.version if schema else 'unknown; raw bytes only',
                'schema_definition_sha256': hashlib.sha256(Path(schemas.__file__).read_bytes()).hexdigest(),
                'schema_source': schema.source if schema else None,
                'schema_source_sha256': hashlib.sha256((self.root / schema.source).read_bytes()).hexdigest()
                if schema else None,
                'runtime': 'not observed', 'sql': 'not observed',
            })
            self.file_stats[key] = identity
        return self.loaded[key]

    def table_list(self):
        return [{'table': path.stem, 'schema': path.stem in self.schemas,
                 'bytes': path.stat().st_size} for path in self.files.values()]

    def schema(self, name):
        table, schema, _, origin = self.load(name)
        return {'table': table.name, 'records': table.rows, 'field_count': table.fields,
                'record_bytes': table.record_size, 'reviewed_schema': asdict(schema) if schema else None,
                'origin': origin}

    def value(self, table, row, field):
        value = struct.unpack_from('<I' if field.kind == 's' else '<' + field.kind,
                                   table.data, 20 + row * table.record_size + field.offset)[0]
        if field.kind == 's':
            if value == 0 and table.string_size == 0:
                return '', None
            if value >= table.string_size:
                return None, f'String offset {value} is outside the string block'
            start = table.string_start + value
            end = table.data.find(b'\0', start)
            if end < 0:
                return None, 'Unterminated string'
            try:
                return table.data[start:end].decode('utf-8'), None
            except UnicodeDecodeError:
                return None, 'Invalid UTF-8 string'
        if field.kind == 'f' and not math.isfinite(value):
            return None, 'Non-finite floating point value'
        return value, None

    def label(self, table, schema, row, locale='enUS'):
        if not schema:
            return f'Row {row}'
        key = (table.name, locale)
        if key not in self.label_fields:
            names = {field.name: field for field in schema.columns}
            self.label_fields[key] = next((names[name] for name in [f'SpellName[{locale}]', f'Name[{locale}]',
                f'DisplayName[{locale}]', 'Token'] if name in names), None)
        field = self.label_fields[key]
        return self.value(table, row, field)[0] if field else ''

    def search(self, name, query='', locale='enUS', offset=0, limit=50):
        if offset < 0 or not 1 <= limit <= 200:
            raise ValueError('Search needs offset >= 0 and limit 1..200')
        table, schema, index, origin = self.load(name)
        query = query.casefold()
        rows, total = [], 0
        entries = index.items() if schema else ((None, row) for row in range(table.rows))
        if not query:
            entries = itertools.islice(entries, offset, offset + limit)
            rows = [{'id': identity, 'row': row, 'name': self.label(table, schema, row, locale)}
                    for identity, row in entries]
            return {'table': table.name, 'total': table.rows, 'offset': offset, 'records': rows, 'origin': origin}
        for identity, row in entries:
            label = self.label(table, schema, row, locale)
            if query and query not in str(identity if schema else row) and query not in (label or '').casefold():
                continue
            if offset <= total < offset + limit:
                rows.append({'id': identity, 'row': row, 'name': label})
            total += 1
        return {'table': table.name, 'total': total, 'offset': offset, 'records': rows, 'origin': origin}

    def record(self, name, identity=None, row=None):
        table, schema, index, origin = self.load(name)
        if identity is not None:
            if not schema:
                raise ValueError('Unknown schema: use --row; no ID column is assumed')
            if identity not in index:
                raise ValueError(f'{table.name}: ID {identity} not found')
            row = index[identity]
        if row is None or not 0 <= row < table.rows:
            raise ValueError('Record row is out of range')
        if identity is None and schema:
            key = next(field for field in schema.columns if field.name == schema.key)
            identity = self.value(table, row, key)[0]
        fields, notes, covered = [], [], set()
        for field in schema.columns if schema else []:
            value, error = self.value(table, row, field)
            raw = table.record(row)[field.offset:field.offset+4]
            result = {'name': field.name, 'offset': field.offset, 'type': field.kind, 'value': value,
                      'raw_hex': raw.hex(), 'unit': field.unit}
            covered.update(range(field.offset, field.offset + 4))
            if error:
                result['error'] = error
                notes.append(f'{field.name}: {error}')
            if field.target and value:
                result['reference'] = {'table': field.target, 'id': value}
            enum_name = field.enum
            if enum_name and enum_name.startswith('Attributes'):
                suffix = enum_name.removeprefix('Attributes').removeprefix('Ex')
                enum_name = 'SpellAttr' + (suffix or ('1' if 'Ex' in field.enum else '0'))
            values = self.enums.get(enum_name, {})
            if values and value is not None:
                if enum_name.startswith('SpellAttr') or enum_name == 'SpellSchoolMask':
                    bits = {k: v for k, v in values.items() if k > 0 and k & (k-1) == 0}
                    result['labels'] = [v for k, v in bits.items() if value & k]
                    result['unknown_bits'] = hex(value & ~sum(bits))
                else:
                    result['labels'] = [values.get(value, 'Unknown enum value')]
            fields.append(result)
        raw = table.record(row)
        start = None
        for offset in range(len(raw) + 1):
            if offset < len(raw) and offset not in covered:
                if start is None:
                    start = offset
            elif start is not None:
                fields.append({'name': 'Unknown bytes', 'offset': start, 'type': 'bytes',
                               'value': None, 'raw_hex': raw[start:offset].hex()})
                start = None
        if origin['manifest_match'] is False:
            notes.append('File differs from its extraction manifest; archive provenance is stale')
        if table.name == 'Spell.dbc':
            notes.append('Raw DBC values precede SQL and C++ corrections. '
                         'BonusMultiplier is not an effective CoA coefficient.')
        result = {'table': table.name.removesuffix('.dbc'), 'id': identity, 'row': row,
                'name': self.label(table, schema, row), 'origin': origin,
                'fields': sorted(fields, key=lambda field: field['offset']), 'notes': notes}
        if table.name == 'Spell.dbc':
            result['sql_layer'] = self.sql if self.sql and identity in self.sql['resolved_spells'] else {
                'status': 'not observed for this spell'}
            result['observations'] = [{**observation, 'samples': samples} for observation in self.observations
                if (samples := [s for s in observation['samples'] if s['definition']['spell'] == identity])]
        return result

    def relationships(self, name, identity):
        selected = self.record(name, identity)
        canonical = selected['table']
        outgoing = [{'field': f['name'], **f['reference']} for f in selected['fields'] if 'reference' in f]
        if self.reverse is None:
            reverse = {}
            for table_name, schema in self.schemas.items():
                references = [f for f in schema.columns if f.target]
                if table_name.casefold() not in self.files or not references:
                    continue
                table, _, index, _ = self.load(table_name)
                for source_id, row in index.items():
                    for field in references:
                        value = struct.unpack_from('<I', table.data, 20 + row * table.record_size + field.offset)[0]
                        if value:
                            reverse.setdefault((field.target, value), []).append(
                                {'table': table_name, 'id': source_id, 'field': field.name})
            self.reverse = reverse
        else:
            for loaded_name in list(self.loaded):
                self.load(loaded_name)
        return {'outgoing': outgoing, 'incoming': self.reverse.get((canonical, identity), []),
                'scope': 'reviewed DBC references; an edge alone does not establish runtime execution or acquisition'}

    def mechanics(self, identity):
        if self.catalog is None:
            self.catalog = load_catalog()
        return [row for row in self.catalog if identity in row['spells']]

    def mechanic_map(self, identity, details=False):
        sys.path.insert(0, str(ROOT / 'apps/coa-mechanics'))
        from mechanic_map import MechanicMap
        return MechanicMap(self, root=self.root).show(f'ability:{identity}', details)

    def compare(self, other, name, identity):
        left, right = self.record(name, identity), other.record(name, identity)
        before = {field['offset']: field for field in left['fields']}
        after = {field['offset']: field for field in right['fields']}
        differences = []
        for offset in sorted(before.keys() | after.keys()):
            a, b = before.get(offset), after.get(offset)
            def semantic(field):
                if field is None:
                    return None
                if field.get('error') or field['type'] == 'bytes':
                    return field.get('error'), field['raw_hex']
                return field['type'], field['value']
            if semantic(a) != semantic(b):
                differences.append({'offset': offset, 'before': a, 'after': b})
        return {'table': name, 'id': identity, 'before': left['origin'], 'after': right['origin'],
                'differences': differences}


def source_matches(identity):
    result = subprocess.run(['rg', '-n', '--max-count', '5', '--glob', '*.{cpp,h,sql}',
                             rf'\b{int(identity)}\b', 'src/server/coa',
                             'src/server/game', 'src/server/scripts', 'data/sql/updates/pending_db_world'],
                            cwd=ROOT, capture_output=True, text=True, timeout=30)
    if result.returncode not in (0, 1):
        raise ValueError('Source lookup failed: ' + result.stderr.strip())
    matches = result.stdout.splitlines()
    return {'scope': 'source text references; not proof of missing or implemented behavior',
            'matches': matches[:100], 'truncated': len(matches) > 100}


def serve(dataset, compare, port):
    lock = threading.Lock()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            parsed = urlsplit(self.path)
            if self.headers.get('Host') not in (f'127.0.0.1:{self.server.server_port}',
                                                f'localhost:{self.server.server_port}'):
                self.send_error(403)
                return
            try:
                args = {k: v[0] for k, v in parse_qs(parsed.query).items()}
                with lock:
                    if parsed.path == '/':
                        return self.send((HERE / 'viewer.html').read_bytes(), 'text/html; charset=utf-8')
                    if parsed.path == '/api/tables':
                        result = {'tables': dataset.table_list(),
                                  'compare': str(compare.directory) if compare else None}
                    elif parsed.path == '/api/search':
                        result = dataset.search(args['table'], args.get('q', ''), args.get('locale', 'enUS'),
                                                int(args.get('offset', 0)))
                    elif parsed.path == '/api/map':
                        result = dataset.mechanic_map(int(args['id']))
                    elif parsed.path == '/api/record':
                        identity = int(args['id']) if 'id' in args else None
                        result = dataset.record(args['table'], identity,
                                                int(args['row']) if 'row' in args else None)
                        if identity is not None:
                            result['relationships'] = dataset.relationships(args['table'], identity)
                            if result['table'] == 'Spell':
                                result['mechanics'] = dataset.mechanics(identity)
                            if compare:
                                try:
                                    result['comparison'] = dataset.compare(compare, args['table'], identity)
                                except ValueError as error:
                                    result['comparison'] = {'error': str(error)}
                    elif parsed.path == '/api/source':
                        result = source_matches(int(args['id']))
                    else:
                        self.send_error(404)
                        return
                self.send(json.dumps(result, allow_nan=False).encode(), 'application/json; charset=utf-8')
            except (ValueError, KeyError, OSError, subprocess.TimeoutExpired) as error:
                self.send(json.dumps({'error': str(error)}).encode(), 'application/json', 400)

        def send(self, payload, content_type, status=200):
            self.send_response(status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(payload)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Content-Security-Policy', "default-src 'self'; script-src 'unsafe-inline'; "
                             "style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'")
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, *_):
            pass

    server = ThreadingHTTPServer(('127.0.0.1', port), Handler)
    print(f'DBC viewer: http://127.0.0.1:{server.server_port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


def project_fields(record, patterns):
    if not patterns:
        return record
    chosen = []
    for pattern in patterns:
        matches = [field for field in record['fields'] if field['name'] == pattern
                   or (pattern.endswith('*') and field['name'].startswith(pattern[:-1]))]
        if not matches:
            raise ValueError(f'No field matches {pattern!r}; use schema to discover reviewed field names')
        chosen.extend(matches)
    offsets = {field['offset'] for field in chosen}
    return {**record, 'fields': [field for field in record['fields'] if field['offset'] in offsets]}


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('command', choices=[
        'tables', 'schema', 'search', 'record', 'map', 'links', 'source', 'compare', 'serve'])
    parser.add_argument('--data', type=Path, required=True)
    parser.add_argument('--other', type=Path)
    parser.add_argument('--sql', type=Path, help='Read-only SQL capture produced by capture_sql.py')
    parser.add_argument('--observations', type=Path, action='append', default=[],
                        help='Existing gameplay result directory')
    parser.add_argument('--table', default='Spell')
    selector = parser.add_mutually_exclusive_group()
    selector.add_argument('--id', type=int)
    selector.add_argument('--row', type=int)
    parser.add_argument('--query', default='')
    parser.add_argument('--field', action='append', default=[], help='Record field name or prefix*; repeatable')
    parser.add_argument('--with-links', action='store_true', help='Include incoming/outgoing links with record')
    parser.add_argument('--with-map', action='store_true', help='Include the compact mechanic map with a Spell record')
    parser.add_argument('--details', action='store_true', help='Include complete mechanic-map contracts')
    parser.add_argument('--locale', default='enUS', choices=schemas.LOCALES)
    parser.add_argument('--offset', type=int, default=0)
    parser.add_argument('--limit', type=int, default=50)
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args(argv)
    try:
        dataset = DataSet(args.data, sql=args.sql, observations=args.observations)
        other = DataSet(args.other) if args.other else None
        if args.command == 'serve':
            serve(dataset, other, args.port)
            return 0
        if args.command == 'tables':
            result = dataset.table_list()
        elif args.command == 'schema':
            result = dataset.schema(args.table)
        elif args.command == 'source':
            if args.id is None:
                raise ValueError('--id is required for source')
            result = source_matches(args.id)
        elif args.command == 'search':
            result = dataset.search(args.table, args.query, args.locale, args.offset, args.limit)
        elif args.command == 'map':
            if args.table != 'Spell' or args.id is None:
                raise ValueError('map requires --table Spell and --id; quest maps use coa-mechanics/mechanic_map.py')
            result = dataset.mechanic_map(args.id, args.details)
        elif args.command == 'record':
            result = project_fields(dataset.record(args.table, args.id, args.row), args.field)
            if result['table'] == 'Spell' and result['id'] is not None:
                result['mechanics'] = dataset.mechanics(result['id'])
            if args.with_links and result['id'] is not None:
                result['relationships'] = dataset.relationships(args.table, result['id'])
            if args.with_map:
                if result['table'] != 'Spell':
                    raise ValueError('--with-map requires a Spell record')
                result['mechanic_map'] = dataset.mechanic_map(result['id'], args.details)
        elif args.command == 'links':
            if args.id is None:
                raise ValueError('--id is required for links')
            result = dataset.relationships(args.table, args.id)
        else:
            if other is None or args.id is None:
                raise ValueError('compare requires --other and --id')
            result = dataset.compare(other, args.table, args.id)
        print(json.dumps(result, indent=2, allow_nan=False))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({'error': str(error)}), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
