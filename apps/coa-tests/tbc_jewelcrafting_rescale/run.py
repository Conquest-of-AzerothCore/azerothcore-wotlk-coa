import argparse
import json
import importlib.util
import math
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
spec = importlib.util.spec_from_file_location('profession_build', ROOT / 'apps/coa-world-content/professions/build.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
plan = generator.build(baseline)
fixture = {'schemas': baseline['schemas'], 'rows': {
    'item_template': list({int(row['entry']): row for row in baseline['items'] + baseline['recipe_books'] + baseline['outside_controls']}.values()),
    'item_enchantment_template': baseline['property_pools']}}


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

        pending = ROOT / 'data/sql/updates/pending_db_world'
        combat = pending / 'rev_20261121_20_coa_hellfire_dungeons_combat.sql'
        execute(combat.read_text())
        execute('CREATE TABLE npc_vendor (entry INT UNSIGNED, slot INT, item INT UNSIGNED, maxcount INT, '
                'incrtime INT, ExtendedCost INT, VerifiedBuild INT, PRIMARY KEY(entry,item,ExtendedCost))')
        execute("INSERT INTO item_template (entry,name,ItemSet) VALUES (999100,'Faith fixture',525),"
                "(999101,'Other fixture',9999)")
        wrong_vendors = list(range(91000005, 91000009)) + list(range(91000109, 91000117))
        for vendor in wrong_vendors + list(range(91000009, 91000013)) + [42]:
            execute(f'INSERT INTO npc_vendor VALUES ({vendor},1,999100,0,0,123,0),'
                    f'({vendor},2,999101,1,60,456,12340)')
        original_vendors = execute('SELECT * FROM npc_vendor ORDER BY entry,item,ExtendedCost')
        original_budgets = execute('SELECT * FROM coa_dungeon_rescale_budget ORDER BY map_id,difficulty,entry')
        damage = pending / 'rev_20261122_00_coa_hellfire_boss_damage.sql'
        faith = pending / 'rev_20261122_02_coa_faith_tier3_vendor_exclusivity.sql'
        execute(damage.read_text())
        execute(faith.read_text())
        boss_entries = {540: {16807, 16808, 16809, 20923}, 542: {17377, 17380, 17381},
                        543: {17306, 17307, 17308, 17536, 17537}}
        before = {tuple(map(int, row.split('\t')[:3])): row.split('\t') for row in original_budgets.splitlines()}
        after = execute('SELECT * FROM coa_dungeon_rescale_budget ORDER BY map_id,difficulty,entry')
        changes = 0
        for line in after.splitlines():
            row = line.split('\t')
            key = tuple(map(int, row[:3]))
            old = before[key]
            if key[2] in boss_entries.get(key[0], set()):
                factor = 3 if key[1] == 2 else 2
                assert all(math.isclose(float(row[n]), float(old[n]) * factor, rel_tol=2e-5) for n in (5, 6)), key
                assert row[:5] + row[7:] == old[:5] + old[7:], key
                changes += 1
            else:
                assert row == old, key
        assert changes == 36
        wrong = ','.join(map(str, wrong_vendors))
        assert execute('SELECT COUNT(*) FROM npc_vendor v JOIN item_template i ON i.entry=v.item '
                       'WHERE i.ItemSet=525 AND v.entry IN (' + wrong + ')') == '0'
        expected_vendors = '\n'.join(line for line in original_vendors.splitlines()
                                     if not (int(line.split('\t')[0]) in wrong_vendors and
                                             int(line.split('\t')[2]) == 999100))
        assert execute('SELECT * FROM npc_vendor ORDER BY entry,item,ExtendedCost') == expected_vendors
        path = generator.MIGRATION
        assert path.read_text() == generator.migration(plan)
        assert (ROOT / 'src/server/coa/CoAProfessionRescaleData.h').read_text() == generator.header(plan)
        original_pools = execute('SELECT * FROM item_enchantment_template ORDER BY entry,ench')
        before_items = {int(row['entry']): row for row in fixture['rows']['item_template']}
        execute(path.read_text())
        assert execute('SELECT COUNT(*) FROM coa_profession_item_budget') == '49'
        assert execute('SELECT COUNT(*) FROM coa_profession_item_budget b JOIN item_template i ON i.entry=b.entry WHERE i.ItemLevel<>b.item_level OR i.RequiredLevel>60') == '0'
        assert execute('SELECT * FROM item_enchantment_template WHERE entry<6100000 ORDER BY entry,ench') == original_pools
        for entry, item in before_items.items():
            expected = dict(item, **plan['changes'].get(entry, {}))
            fields = list(item)
            actual = execute('SELECT ' + ','.join('`' + field + '`' for field in fields) +
                             ' FROM item_template WHERE entry=' + str(entry))
            values = actual.split('\t')
            assert len(values) == len(fields), entry
            for field, value in zip(fields, values):
                wanted = expected[field]
                if field in ('dmg_min1', 'dmg_max1', 'dmg_min2', 'dmg_max2', 'RangedModRange', 'ArmorDamageModifier', 'DamageModifier'):
                    assert abs(float(value) - float(wanted)) < 0.0001, (entry, field)
                else:
                    assert value == ('NULL' if wanted is None else str(wanted)), (entry, field, value, wanted)
        assert plan['anchors'] == [83, 159] and plan['band'] == [60, 77]
        assert {row['original']: row['target'] for row in plan['details']} == {
            83: 60, 88: 61, 93: 62, 97: 63, 99: 64, 100: 64, 102: 64, 109: 66,
            114: 67, 115: 67, 125: 69, 159: 77}
        for row in plan['details']:
            item = row['before']
            after = row['after']
            assert int(item['Quality']) == int(after['Quality'])
            for n in range(1, 6):
                sid = int(item[f'spellid_{n}'])
                if sid and not 101600 < sid < 101800 and sid != 33488:
                    assert after[f'spellid_{n}'] == item[f'spellid_{n}']
                for prefix in ('spelltrigger_', 'spellcharges_', 'spellcooldown_', 'spellcategory_', 'spellcategorycooldown_'):
                    assert after[prefix + str(n)] == item[prefix + str(n)]
            original = int(item['RandomProperty'])
            expected_weight = sum(float(r['chance']) for r in baseline['property_pools'] if int(r['entry']) == original)
            actual_weight = float(execute('SELECT SUM(chance) FROM item_enchantment_template WHERE entry=' + str(6100000 + row['entry'])))
            assert abs(expected_weight - actual_weight) < 0.0001
            mapping = row['property_mapping']
            assert all(mapping.get(value, value) == value for value in mapping.values())
        assert generator.mapped(83, 83, 159, 60, 77) == 60
        assert generator.mapped(159, 83, 159, 60, 77) == 77
        assert generator.mapped(125, 83, 159, 60, 77) == 69
        assert generator.mapped(125, 125, 125, 69, 69) == 69
        try:
            generator.mapped(125, 125, 125, 60, 77)
        except ValueError:
            pass
        else:
            raise AssertionError('Ambiguous single-level band accepted')
        dump_command = [str(args.mysql_bin / 'mysqldump'), '--no-defaults', '--protocol=SOCKET',
                        '--socket=' + str(socket), '--user=root', '--skip-comments', '--compact',
                        '--skip-add-locks', '--no-tablespaces', '--set-gtid-purged=OFF',
                        '--column-statistics=0', '--order-by-primary', 'coa_test_hellfire_sql']
        before = subprocess.check_output(dump_command)
        execute(damage.read_text())
        execute(faith.read_text())
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

print('PASS: 49 equipment budgets, level-60 item/recipe gates, original proc/on-use preservation, '
      'unchanged outside items and original affix pools; 36 scoped boss damage rows, Faith-only vendor cleanup, '
      'valid mappings, chance totals and identical combined rollout replay')
