CLI_DESCRIPTION = """Check the quest content the core does not: spawn reachability, obtainability and duplicates."""

import argparse
from datetime import datetime, timezone
import json
import math
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
SAMPLE_LIMIT = 8
CROWD_LIMIT = 500
SAME_SPOT_YARDS = 1.0
SAME_HEIGHT_YARDS = 2.0
LOOT_TABLES = ('creature_loot_template', 'disenchant_loot_template', 'fishing_loot_template',
               'gameobject_loot_template', 'item_loot_template', 'mail_loot_template',
               'milling_loot_template', 'pickpocketing_loot_template', 'player_loot_template',
               'prospecting_loot_template', 'reference_loot_template', 'skinning_loot_template',
               'spell_loot_template')
REQUIRED_ITEM_COLUMNS = ('RequiredItemId1', 'RequiredItemId2', 'RequiredItemId3',
                         'RequiredItemId4', 'RequiredItemId5', 'RequiredItemId6')
SELF_SUPPLIED_COLUMNS = ('StartItem', 'ItemDrop1', 'ItemDrop2', 'ItemDrop3', 'ItemDrop4')
TARGET_COLUMNS = ('RequiredNpcOrGo1', 'RequiredNpcOrGo2', 'RequiredNpcOrGo3', 'RequiredNpcOrGo4')


def union_columns(columns, table):
    return ' UNION ALL '.join(f'SELECT `ID` AS `quest`, `{column}` AS `value` '
                              f'FROM `{table}` WHERE `{column}` <> 0' for column in columns)


def sql_checks():
    checks = {}
    for entity in ('creature', 'gameobject'):
        for role in ('starter', 'ender'):
            relation = f'{entity}_quest{role}'
            checks[f'{entity}-{role}-unspawned'] = (
                f'SELECT `r`.`quest`, `r`.`id` FROM `{relation}` AS `r` '
                f'WHERE EXISTS (SELECT 1 FROM `{entity}_template` AS `t` WHERE `t`.`entry` = `r`.`id`) '
                f'AND NOT EXISTS (SELECT 1 FROM `{entity}` AS `s` WHERE `s`.`id` = `r`.`id`)', 0)
    targets = union_columns(TARGET_COLUMNS, 'quest_template')
    checks['quest-target-creature-unspawned'] = (
        f'SELECT `u`.`quest`, `u`.`value` FROM ({targets}) AS `u` WHERE `u`.`value` > 0 '
        f'AND EXISTS (SELECT 1 FROM `creature_template` AS `t` WHERE `t`.`entry` = `u`.`value`) '
        f'AND NOT EXISTS (SELECT 1 FROM `creature` AS `s` WHERE `s`.`id` = `u`.`value`)', 0)
    checks['quest-target-gameobject-unspawned'] = (
        f'SELECT `u`.`quest`, -`u`.`value` FROM ({targets}) AS `u` WHERE `u`.`value` < 0 '
        f'AND EXISTS (SELECT 1 FROM `gameobject_template` AS `t` WHERE `t`.`entry` = -`u`.`value`) '
        f'AND NOT EXISTS (SELECT 1 FROM `gameobject` AS `s` WHERE `s`.`id` = -`u`.`value`)', 0)
    checks['quest-unreachable'] = (
        'SELECT `q`.`ID` FROM `quest_template` AS `q` WHERE NOT EXISTS '
        '(SELECT 1 FROM `creature_queststarter` AS `a` WHERE `a`.`quest` = `q`.`ID`) AND NOT EXISTS '
        '(SELECT 1 FROM `gameobject_queststarter` AS `b` WHERE `b`.`quest` = `q`.`ID`) AND NOT EXISTS '
        '(SELECT 1 FROM `item_template` AS `c` WHERE `c`.`startquest` = `q`.`ID`)', 0)
    return checks


def dataset_queries():
    loot = ' UNION ALL '.join(f'SELECT `Item` AS `item` FROM `{table}`' for table in LOOT_TABLES)
    required = union_columns(REQUIRED_ITEM_COLUMNS, 'quest_template')
    self_supplied = union_columns(SELF_SUPPLIED_COLUMNS, 'quest_template')
    return {
        'obtainable_items': f'SELECT DISTINCT `l`.`item` FROM ({loot}) AS `l` '
                            f'UNION SELECT DISTINCT `v`.`item` FROM `npc_vendor` AS `v`',
        'required_items': f'SELECT `u`.`quest`, `u`.`value` FROM ({required}) AS `u`',
        'self_supplied_items': f'SELECT `u`.`quest`, `u`.`value` FROM ({self_supplied}) AS `u`',
        'creature_spawns': 'SELECT `id`, `map`, `guid`, `position_x`, `position_y`, `position_z` '
                           'FROM `creature` ORDER BY `id`, `map`, `guid`',
        'gameobject_spawns': 'SELECT `id`, `map`, `guid`, `position_x`, `position_y`, `position_z` '
                             'FROM `gameobject` ORDER BY `id`, `map`, `guid`',
        'pooled_creatures': 'SELECT `guid` FROM `pool_creature`',
        'pooled_gameobjects': 'SELECT `guid` FROM `pool_gameobject`',
    }


def unobtainable_items(datasets):
    obtainable = {row[0] for row in datasets['obtainable_items']}
    own = {(row[0], row[1]) for row in datasets['self_supplied_items']}
    findings = []
    for quest, item in ((row[0], row[1]) for row in datasets['required_items']):
        if item not in obtainable and (quest, item) not in own:
            findings.append([quest, item])
    return findings


def duplicate_spawns(rows, pooled):
    groups = {}
    for entry, map_id, guid, x, y, z in rows:
        if guid in pooled:
            continue
        groups.setdefault((entry, map_id), []).append((guid, float(x), float(y), float(z)))
    findings = []
    crowded = 0
    for (entry, map_id), spawns in groups.items():
        if len(spawns) > CROWD_LIMIT:
            crowded += 1
            continue
        for index, (guid, x, y, z) in enumerate(spawns):
            for other_guid, other_x, other_y, other_z in spawns[index + 1:]:
                if (math.isclose(x, other_x, abs_tol=SAME_SPOT_YARDS)
                        and math.isclose(y, other_y, abs_tol=SAME_SPOT_YARDS)
                        and math.isclose(z, other_z, abs_tol=SAME_HEIGHT_YARDS)):
                    findings.append([entry, guid, other_guid])
    return findings, crowded


def run_queries(config, mysql, queries):
    sys.path.insert(0, str(ROOT / 'apps/coa-gameplay-test'))
    import run

    settings = run.read_config(config)
    connection = run.Connection.parse(run.source_setting(settings, 'WorldDatabaseInfo'))
    with tempfile.TemporaryDirectory(prefix='coa-world-content-') as temporary:
        defaults = Path(temporary) / 'client.cnf'
        with defaults.open('x', encoding='utf-8') as stream:
            defaults.chmod(0o600)
            stream.write('[client]\n' + '\n'.join(f'{key}={run.cnf_quote(str(value))}' for key, value in
                [('host', connection.host), ('port', connection.port), ('user', connection.user),
                 ('password', connection.password)]))
        command = [str(mysql), '--defaults-extra-file=' + str(defaults), '--no-login-paths',
                   '--batch', '--raw', '--skip-column-names', '--default-character-set=utf8mb4',
                   '--connect-timeout=10', '--database=' + connection.database]
        results = {}
        for name, sql in queries.items():
            outcome = subprocess.run(command, input=sql + ';\n', text=True, capture_output=True, timeout=600)
            if outcome.returncode:
                raise ValueError(f'Query {name} failed against the world database')
            results[name] = [line.split('\t') for line in outcome.stdout.splitlines() if line.strip()]
        return connection, results


def identity(name, row):
    return name + ':' + '|'.join(str(value) for value in row)


def collect(quest_columns, results, quests):
    report = {}
    findings = set()
    for name, rows in results.items():
        column = quest_columns.get(name)
        if quests is not None and column is not None:
            rows = [row for row in rows if len(row) > column and str(row[column]).isdecimal()
                    and int(row[column]) in quests]
        findings.update(identity(name, row) for row in rows)
        report[name] = {'findings': len(rows), 'samples': [[str(value) for value in row]
                                                           for row in rows[:SAMPLE_LIMIT]]}
    return report, findings


def load_baseline(path):
    if path is None or not path.exists():
        return set()
    data = json.loads(path.read_text(encoding='utf-8'))
    if data.get('schema') != 1:
        raise ValueError('Unsupported baseline schema')
    return set(data['accepted'])


def evaluate(config, mysql, quests):
    checks = sql_checks()
    queries = {name: sql for name, (sql, _) in checks.items()}
    queries.update(dataset_queries())
    connection, raw = run_queries(config, mysql, queries)
    outcomes = {name: raw[name] for name in checks}
    quest_columns = {name: column for name, (_, column) in checks.items()}
    datasets = {'obtainable_items': raw['obtainable_items'],
                'required_items': [[int(row[0]), int(row[1])] for row in raw['required_items']],
                'self_supplied_items': [[int(row[0]), int(row[1])] for row in raw['self_supplied_items']]}
    datasets['obtainable_items'] = [[int(row[0])] for row in raw['obtainable_items']]
    outcomes['quest-required-item-unobtainable'] = unobtainable_items(datasets)
    quest_columns['quest-required-item-unobtainable'] = 0
    notes = {}
    for entity, key, pool in (('creature', 'creature_spawns', 'pooled_creatures'),
                              ('gameobject', 'gameobject_spawns', 'pooled_gameobjects')):
        pooled = {row[0] for row in raw[pool]}
        findings, crowded = duplicate_spawns(raw[key], pooled)
        outcomes[f'duplicate-{entity}-spawn'] = findings
        quest_columns[f'duplicate-{entity}-spawn'] = None
        notes[f'duplicate-{entity}-spawn'] = (f'{len(pooled)} pooled spawns excluded; '
                                              f'{crowded} entries above {CROWD_LIMIT} spawns not compared')
    report, findings = collect(quest_columns, outcomes, quests)
    for name, note in notes.items():
        report[name]['note'] = note
    return connection, report, findings


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--mysql', type=Path, required=True)
    parser.add_argument('--quest', type=int, action='append', default=[])
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--write-baseline', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args(argv)
    try:
        if args.write_baseline and args.baseline is None:
            raise ValueError('--write-baseline needs --baseline')
        quests = set(args.quest) or None
        connection, report, findings = evaluate(args.config, args.mysql, quests)
        accepted = set() if args.write_baseline else load_baseline(args.baseline)
        introduced = sorted(findings - accepted)
        resolved = sorted(accepted - findings)
        summary = {'schema': 1, 'checked_at': datetime.now(timezone.utc).isoformat(),
                   'source': {'host': connection.host, 'port': connection.port,
                              'database': connection.database},
                   'scope': 'reachability, obtainability and duplicate spawns only; '
                            'ObjectMgr::LoadQuests already reports every existence failure to sql.sql',
                   'requested_quests': sorted(quests) if quests else [],
                   'checks': report, 'total_findings': len(findings),
                   'accepted_findings': len(accepted), 'introduced': introduced[:SAMPLE_LIMIT * 4],
                   'introduced_count': len(introduced), 'resolved_count': len(resolved)}
        if args.write_baseline:
            with args.baseline.open('w', encoding='utf-8') as stream:
                stream.write(json.dumps({'schema': 1, 'recorded_at': summary['checked_at'],
                                         'accepted': sorted(findings)}, indent=2) + '\n')
            print(f'Baseline recorded: {args.baseline} ({len(findings)} findings)')
        text = json.dumps(summary, indent=2) + '\n'
        if args.output:
            with args.output.open('w', encoding='utf-8') as stream:
                stream.write(text)
        else:
            print(text, end='')
        return 1 if introduced and not args.write_baseline else 0
    except (OSError, ValueError, KeyError, subprocess.TimeoutExpired) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
