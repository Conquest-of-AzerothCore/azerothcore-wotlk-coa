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
            rows = fixture['rows'][table]
            for offset in range(0, len(rows), 100):
                statements = []
                for row in rows[offset:offset + 100]:
                    columns = ','.join('`' + key + '`' for key in row)
                    values = ','.join(sql_value(value) for value in row.values())
                    statements.append('INSERT INTO `' + table + '` (' + columns + ') VALUES (' + values + ');')
                execute('\n'.join(statements))

        paths = sorted((ROOT / 'data/sql/updates/pending_db_world').glob('rev_20261121_2[0-7]_coa_hellfire_dungeons_*.sql*'))
        assert len(paths) == 8

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

        access_columns = ','.join(key for key in fixture['rows']['dungeon_access_template'][0] if key != 'min_level')
        access_before = execute('SELECT ' + access_columns + ' FROM dungeon_access_template ORDER BY id')
        lfg_before = {int(row['ID']): row for row in fixture['rows']['lfgdungeons_dbc']}
        keys_before = execute('SELECT * FROM dungeon_access_requirements ORDER BY dungeon_access_id,requirement_id,faction')
        unique = set(fixture['expected']['unique_items'])
        shared = [int(row['entry']) for row in fixture['rows']['item_template'] if int(row['entry']) not in unique]
        unchanged_ids = ','.join(map(str, shared))
        shared_before = execute('SELECT * FROM item_template WHERE entry IN (' + unchanged_ids + ') ORDER BY entry')
        apply()
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_budget') == '198'
        assert execute('SELECT level,health,attack_time FROM coa_dungeon_rescale_budget WHERE map_id=543 AND difficulty=0 AND entry=17306') == '63\t584760\t1200'
        assert execute('SELECT health FROM coa_dungeon_rescale_budget WHERE map_id=543 AND difficulty=1 AND entry=17306') == '842054'
        assert execute('SELECT health FROM coa_dungeon_rescale_budget WHERE map_id=543 AND difficulty=2 AND entry=17306') == '1099349'
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_item') == str(fixture['expected']['owned_items'])
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_item b JOIN item_template i ON i.entry=b.entry LEFT JOIN item_enchantment_template e ON e.entry=i.RandomProperty WHERE i.RandomProperty<>0 AND e.entry IS NULL') == '0'
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_item b JOIN item_template i ON i.entry=b.entry WHERE i.ItemLevel NOT IN (65,68,71) OR i.RequiredLevel>60') == '0'
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_loot') == str(fixture['expected']['routing'])
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_loot r LEFT JOIN item_template i ON i.entry=r.target_item WHERE i.entry IS NULL OR i.ItemLevel<>65+3*r.difficulty') == '0'
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_property a LEFT JOIN coa_dungeon_rescale_property b ON b.entry=a.entry AND b.zone_id=a.zone_id AND b.original_property=a.scaled_property WHERE b.scaled_property IS NULL OR b.scaled_property<>a.scaled_property') == '0'
        assert execute('SELECT COUNT(*) FROM creature WHERE map IN (540,542,543) AND (spawnMask&2)<>0 AND (spawnMask&4)=0') == '0'
        assert execute('SELECT COUNT(*) FROM gameobject WHERE map IN (540,542,543) AND (spawnMask&2)<>0 AND (spawnMask&4)=0') == '0'
        assert execute('SELECT QuestLevel,MinLevel FROM quest_template WHERE ID=9572') == '60\t59'
        assert execute('SELECT MinLevel FROM quest_template WHERE ID=10665') == '60'
        assert execute('SELECT QuestLevel,MinLevel FROM quest_template WHERE ID=10884') == '70\t70'
        assert execute('SELECT ' + access_columns + ' FROM dungeon_access_template ORDER BY id') == access_before
        for row in fixture['rows']['dungeon_access_template']:
            expected_min = min(int(row['min_level']), 60)
            assert execute('SELECT min_level FROM dungeon_access_template WHERE id=' + str(row['id'])) == str(expected_min)
        assert execute('SELECT COUNT(*) FROM lfgdungeons_dbc WHERE MapID IN (540,542,543) AND Difficulty IN (0,1,2) AND MinLevel<=60 AND MaxLevel>=60 AND Target_Level=60 AND Target_Level_Min=60 AND Target_Level_Max=60') == '9'
        level_fields = {'MinLevel', 'MaxLevel', 'Target_Level', 'Target_Level_Min', 'Target_Level_Max'}
        for identifier, row in lfg_before.items():
            selected = int(row['MapID']) in (540, 542, 543)
            for key, value in row.items():
                if selected and key in level_fields:
                    continue
                actual = execute('SELECT ' + '`' + key + '` FROM lfgdungeons_dbc WHERE ID=' + str(identifier))
                assert actual == str(value), (identifier, key, actual, value)
        assert execute('SELECT * FROM dungeon_access_requirements ORDER BY dungeon_access_id,requirement_id,faction') == keys_before
        assert execute('SELECT * FROM item_template WHERE entry IN (' + unchanged_ids + ') ORDER BY entry') == shared_before
        assert execute('SELECT COUNT(*) FROM spell_dbc WHERE ID BETWEEN 8740000 AND 8740999') == str(fixture['expected']['effect_rows'])
        assert execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=8740010') == '268'
        assert execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=8740041') == '280'
        assert execute('SELECT EffectBasePoints_1 FROM spell_dbc WHERE ID=8740066') == '293'
        assert execute('SELECT DurationIndex FROM spell_dbc WHERE ID=8740009') == '18'
        assert execute('SELECT COUNT(*) FROM coa_dungeon_rescale_loot r JOIN item_template i ON i.entry=r.target_item WHERE r.source_item<>r.target_item AND i.description NOT LIKE "@%"') == '0'
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

print('PASS: eight dungeon migrations, health ratios, loot bands, scoped/shared items, quests, level-60 access and unchanged keys, and identical replay')
