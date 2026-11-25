import argparse
import hashlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import sql_reader
import sql_writer

ROOT = HERE.parents[3]


def generate(export_path, directory, date, first_number, template_schema):
    export = json.loads(Path(export_path).read_text(encoding='utf-8'))
    columns = sql_writer.creature_template_columns(template_schema)
    paths = sql_writer.write(export, directory, date, first_number, columns)
    tables = sql_reader.read([path for path in paths if not path.name.endswith('_standins.sql')])
    if tables != export['tables']:
        different = sorted(name for name in export['tables'] if tables.get(name) != export['tables'][name])
        raise ValueError(f'SQL does not read back as the export: {different}')
    counts = {name: len(rows) for name, rows in tables.items()}
    if counts != export['manifest']:
        raise ValueError(f'row counts {counts} differ from the manifest {export["manifest"]}')
    return paths


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--export', required=True)
    parser.add_argument('--sql-dir', default=str(ROOT / 'data/sql/updates/pending_db_world'))
    parser.add_argument('--date', required=True)
    parser.add_argument('--first-number', type=int, required=True)
    parser.add_argument('--template-schema', default=str(ROOT / 'data/sql/base/db_world/creature_template.sql'))
    args = parser.parse_args()
    paths = generate(args.export, Path(args.sql_dir), args.date, args.first_number, args.template_schema)
    print(json.dumps({'export_sha256': hashlib.sha256(Path(args.export).read_bytes()).hexdigest(),
                      'files': [path.name for path in paths]}, indent=1))


if __name__ == '__main__':
    main()
