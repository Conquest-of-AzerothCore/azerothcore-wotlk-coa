import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import time


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--mysql-bin', type=Path, required=True)
args = parser.parse_args()
fixture = json.loads((HERE / 'fixture.json').read_text())


def sql_value(value):
    if value is None:
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
        return subprocess.run(client + (['coa_test_hellfire_sql'] if database else []), input=sql,
                              text=True, capture_output=True, check=True, timeout=30).stdout.strip()

    try:
        deadline = time.monotonic() + 30
        while True:
            try:
                execute('SELECT 1;', database=False)
                break
            except subprocess.CalledProcessError:
                if server.poll() is not None or time.monotonic() >= deadline:
                    log.flush()
                    raise RuntimeError((scratch / 'mysql.log').read_text()[-6000:])
                time.sleep(0.2)
        execute('CREATE DATABASE coa_test_hellfire_sql;', database=False)
        for table, schema in fixture['schemas'].items():
            execute(schema + ';')
            for row in fixture['rows'][table]:
                columns = ','.join('`' + key + '`' for key in row)
                values = ','.join(sql_value(value) for value in row.values())
                execute('INSERT INTO `' + table + '` (' + columns + ') VALUES (' + values + ');')

        paths = sorted((ROOT / 'data/sql/updates/pending_db_world').glob('rev_20261121_1[0-8]_coa_hellfire_*.sql*'))
        assert len(paths) == 9

        def apply():
            for path in paths:
                execute(path.read_text())

        def dump():
            return subprocess.check_output([str(args.mysql_bin / 'mysqldump'), '--no-defaults',
                                            '--protocol=SOCKET', '--socket=' + str(socket), '--user=root',
                                            '--skip-comments', '--compact', '--skip-add-locks',
                                            '--no-tablespaces', '--set-gtid-purged=OFF',
                                            '--column-statistics=0', '--order-by-primary',
                                            'coa_test_hellfire_sql'])

        apply()
        assert execute('SELECT level,health FROM coa_zone_creature_budget WHERE zone_id=3483 AND entry=16972') == '60\t106410'
        assert execute('SELECT QuestLevel,MinLevel,SuggestedGroupNum,RewardMoney FROM quest_template WHERE ID=10136') == '60\t60\t5\t87000'
        assert execute('SELECT MinLevel FROM quest_template WHERE ID=9342') == '255'
        assert execute('SELECT QuestLevel FROM quest_template WHERE ID=9572') == '62'
        assert execute('SELECT ItemLevel,RequiredLevel FROM item_template WHERE entry=30732') == '66\t60'
        assert execute('SELECT ItemLevel,RequiredLevel FROM item_template WHERE entry=999') == '200\t80'
        assert execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=32600') == '191'
        assert execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=8700000') == '119'
        assert execute('SELECT COUNT(*) FROM coa_zone_item_budget WHERE item_level NOT BETWEEN 59 AND 66') == '0'
        assert execute('SELECT ItemLevel,RandomProperty FROM item_template WHERE entry=24575') == '81\t8600'
        assert execute('SELECT COUNT(*) FROM coa_zone_property_mapping a LEFT JOIN coa_zone_property_mapping b ON b.zone_id=a.zone_id AND b.entry=a.entry AND b.original_property=a.scaled_property WHERE b.scaled_property IS NULL OR b.scaled_property<>a.scaled_property') == '0'
        assert execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=8710001') == '123'
        assert execute('SELECT scaled_property FROM coa_zone_property_mapping WHERE entry=24575 AND original_property=400') == '8600'
        assert execute('SELECT COUNT(*) FROM coa_zone_item_budget') == '196'
        assert execute('SELECT ItemLevel,spellid_1 FROM item_template WHERE entry=7734') == '51\t14537'
        assert execute('SELECT COUNT(*) FROM coa_zone_item_budget WHERE entry=7734') == '0'
        before = dump()
        apply()
        assert dump() == before
    finally:
        server.terminate()
        try:
            server.wait(timeout=15)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait(timeout=5)
        log.close()

print('PASS: nine pending migrations applied to private MySQL, scoped data and original shared effects preserved, '
      'identical schema and rows on reapplication')
