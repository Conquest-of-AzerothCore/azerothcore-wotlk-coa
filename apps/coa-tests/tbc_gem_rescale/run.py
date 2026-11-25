import argparse
import json
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import time


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--mysql-bin', type=Path, required=True)
args = parser.parse_args()
baseline = json.loads((HERE / 'baseline.json').read_text())
spec = importlib.util.spec_from_file_location('gem_build', ROOT / 'apps/coa-world-content/tbc_gems/build.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
meta = json.loads((HERE / 'meta-baseline.json').read_text())
fixture = {'schemas': dict(baseline['schemas'], **meta['schemas']), 'rows': {
    'item_template': baseline['gem_items'] + baseline['outside_controls'],
    'gemproperties_dbc': baseline['gem_properties'],
    'spellitemenchantment_dbc': [row for row in baseline['enchantments']
        if all(len(value) <= 100 for key, value in row.items()
               if key.startswith('Name_Lang_') and isinstance(value, str))] + baseline['original_sql_enchantments'],
    'spell_dbc': baseline['effect_spells'] + meta['spells'], 'spell_proc': meta['procs']}}


def sql_value(value):
    if value is None or value == 'NULL':
        return 'NULL'
    return "'" + str(value).replace('\\', '\\\\').replace("'", "''") + "'"


with tempfile.TemporaryDirectory(prefix='coa-hf-mysql-') as directory:
    scratch = Path(directory)
    data = scratch / 'data'
    socket = scratch / 'mysql.sock'
    log = (scratch / 'mysql.log').open('w')
    initialize = [str(args.mysql_bin / 'mysqld'), '--no-defaults', '--initialize-insecure',
                  '--datadir=' + str(data), '--innodb-buffer-pool-size=32M']
    subprocess.run(initialize, stdout=log, stderr=log, check=True, timeout=60)
    command = [str(args.mysql_bin / 'mysqld'), '--no-defaults', '--datadir=' + str(data),
               '--socket=' + str(socket), '--pid-file=' + str(scratch / 'mysql.pid'),
               '--skip-networking', '--mysqlx=OFF', '--skip-log-bin', '--innodb-buffer-pool-size=32M']
    server = subprocess.Popen(command, stdout=log, stderr=log)
    client = [str(args.mysql_bin / 'mysql'), '--no-defaults', '--protocol=SOCKET',
              '--socket=' + str(socket), '--user=root', '--batch', '--skip-column-names']

    def execute(sql, database=True):
        result = subprocess.run(client + (['coa_test_hellfire_sql'] if database else []), input=sql,
                                text=True, capture_output=True, timeout=30)
        if result.returncode:
            raise RuntimeError(result.stderr.strip())
        return result.stdout.strip()

    try:
        deadline = time.monotonic() + 30
        while True:
            try:
                execute('SELECT 1;', database=False)
                break
            except (subprocess.CalledProcessError, RuntimeError):
                if server.poll() is not None or time.monotonic() >= deadline:
                    log.flush()
                    raise RuntimeError((scratch / 'mysql.log').read_text()[-6000:])
                time.sleep(0.2)
        execute('CREATE DATABASE coa_test_hellfire_sql;', database=False)
        for table, schema in fixture['schemas'].items():
            execute(schema + ';')
            rows = fixture['rows'][table]
            for offset in range(0, len(rows), 100):
                statements = []
                for row in rows[offset:offset + 100]:
                    columns = ','.join('`' + key + '`' for key in row)
                    values = ','.join(sql_value(value) for value in row.values())
                    statements.append('INSERT INTO `' + table + '` (' + columns + ') VALUES (' + values + ');')
                execute('\n'.join(statements))

        path = ROOT / 'data/sql/updates/pending_db_world/rev_20261122_01_coa_tbc_gems_level60.sql'
        if not path.exists():
            path = Path(str(path) + '.draft')
        assert path.read_text() == generator.migration(baseline)
        assert (ROOT / 'src/server/coa/CoATbcGemRequirementsData.h').read_text() == generator.header(baseline)
        tables = ('gemproperties_dbc', 'spellitemenchantment_dbc', 'spell_dbc', 'spell_proc')
        before_tables = {table: execute('SELECT * FROM `' + table + '` ORDER BY 1') for table in tables}
        outside_ids = ','.join(str(row['entry']) for row in baseline['outside_controls'])
        outside = execute('SELECT * FROM item_template WHERE entry IN (' + outside_ids + ') ORDER BY entry')
        execute(path.read_text())
        for table in tables:
            assert execute('SELECT * FROM `' + table + '` ORDER BY 1') == before_tables[table], table
        assert execute('SELECT * FROM item_template WHERE entry IN (' + outside_ids + ') ORDER BY entry') == outside
        for old in baseline['gem_items']:
            item = int(old['entry'])
            assert execute('SELECT RequiredLevel FROM item_template WHERE entry=' + str(item)) == str(int(old['RequiredLevel']) if item == 33060 else min(60, int(old['RequiredLevel'])))
            fields = [field for field in old if field != 'RequiredLevel']
            actual = execute('SELECT ' + ','.join('`' + field + '`' for field in fields) + ' FROM item_template WHERE entry=' + str(item))
            expected = '\t'.join('NULL' if old[field] is None else str(old[field]) for field in fields)
            assert actual == expected, item
        dump_command = [str(args.mysql_bin / 'mysqldump'), '--no-defaults', '--protocol=SOCKET',
                        '--socket=' + str(socket), '--user=root', '--skip-comments', '--compact',
                        '--skip-add-locks', '--no-tablespaces', '--set-gtid-purged=OFF',
                        '--column-statistics=0', '--order-by-primary', 'coa_test_hellfire_sql']
        before = subprocess.check_output(dump_command)
        execute(path.read_text())
        assert subprocess.check_output(dump_command) == before
    finally:
        server.terminate()
        try:
            server.wait(timeout=15)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait(timeout=5)
        log.close()

print('PASS: 231 scoped TBC gems capped at level 60; all other item fields, gem properties, enchantments, '
      'spells, procs and outside items unchanged; identical SQL replay')
