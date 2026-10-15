CLI_DESCRIPTION = """Capture selected spell/quest metadata using SELECTs against a local world database."""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
TABLE_KEYS = {'spell_bonus_data': 'entry', 'spell_proc': 'SpellId', 'spell_ranks': 'spell_id',
              'spell_script_names': 'spell_id', 'spell_dbc': 'ID', 'spell_learn_spell': 'entry'}
QUEST_KEYS = {'quest_template': 'ID', 'quest_template_addon': 'ID', 'quest_offer_reward': 'ID',
              'quest_request_items': 'ID', 'creature_queststarter': 'quest', 'creature_questender': 'quest',
              'gameobject_queststarter': 'quest', 'gameobject_questender': 'quest'}


def capture(config, mysql, spells, quests=()):
    sys.path.insert(0, str(ROOT / 'apps/coa-gameplay-test'))
    import run

    if not (spells or quests) or any(type(value) is not int or not 0 < value <= 0xFFFFFFFF
                                    for value in [*spells, *quests]):
        raise ValueError('Provide positive spell or quest IDs')
    settings = run.read_config(config)
    connection = run.Connection.parse(run.source_setting(settings, 'WorldDatabaseInfo'))
    with tempfile.TemporaryDirectory(prefix='coa-dbc-sql-') as temporary:
        defaults = Path(temporary) / 'client.cnf'
        with defaults.open('x', encoding='utf-8') as stream:
            defaults.chmod(0o600)
            stream.write('[client]\n' + '\n'.join(f'{key}={run.cnf_quote(str(value))}' for key, value in
                [('host', connection.host), ('port', connection.port), ('user', connection.user),
                 ('password', connection.password)]))
        command = [str(mysql), '--defaults-extra-file=' + str(defaults), '--no-login-paths',
                   '--batch', '--raw', '--skip-column-names', '--default-character-set=utf8mb4',
                   '--connect-timeout=10', '--database=' + connection.database]

        def query(sql):
            result = subprocess.run(command, input=sql, text=True, capture_output=True, timeout=30)
            if result.returncode:
                raise ValueError('Local world database query failed; verify the selected config and MySQL client')
            return [json.loads(line) for line in result.stdout.splitlines() if line.strip()]

        columns = {}
        selected_tables = {**(TABLE_KEYS if spells else {}), **(QUEST_KEYS if quests else {})}
        for table in selected_tables:
            columns[table] = query("SELECT JSON_QUOTE(COLUMN_NAME) FROM information_schema.COLUMNS "
                                   f"WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='{table}' ORDER BY ORDINAL_POSITION;")
            if any(not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', name) for name in columns[table]):
                raise ValueError('Unsupported column identifier')

        def rows(table, condition):
            pairs = ','.join(f"'{name}',`{name}`" for name in columns[table])
            return query(f'SELECT JSON_OBJECT({pairs}) FROM `{table}` WHERE {condition};')

        ids = set(spells)
        roots = set()
        if columns.get('spell_ranks'):
            selected = ','.join(map(str, sorted(ids)))
            ranks = rows('spell_ranks', f'`spell_id` IN ({selected}) OR `first_spell_id` IN ({selected})')
            roots = {row['first_spell_id'] for row in ranks}
            if roots:
                ranks = rows('spell_ranks', '`first_spell_id` IN (' + ','.join(map(str, sorted(roots))) + ')')
                ids.update(row['spell_id'] for row in ranks)
                ids.update(roots)
        tables = {}
        for table, key in selected_tables.items():
            if not columns[table]:
                tables[table] = {'status': 'table absent', 'rows': []}
                continue
            if key.casefold() not in {name.casefold() for name in columns[table]}:
                raise ValueError(f'Unexpected key column in {table}')
            selector = f'ABS(`{key}`)' if table in ('spell_proc', 'spell_script_names') else f'`{key}`'
            selected_ids = quests if table in QUEST_KEYS else ids
            tables[table] = {'status': 'observed', 'rows': rows(
                table, selector + ' IN (' + ','.join(map(str, sorted(set(selected_ids)))) + ')')}
        return {'schema': 1, 'captured_at': datetime.now(timezone.utc).isoformat(),
                'source': {'host': connection.host, 'port': connection.port, 'database': connection.database},
                'requested_spells': sorted(set(spells)), 'resolved_spells': sorted(ids), 'rank_roots': sorted(roots),
                'requested_quests': sorted(set(quests)),
                'scope': 'sequential SELECTs, not an atomic snapshot; C++ corrections/runtime values are not inferred',
                'tables': tables}


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--mysql', type=Path, required=True)
    parser.add_argument('--spell', type=int, action='append', default=[])
    parser.add_argument('--quest', type=int, action='append', default=[])
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.output.exists():
            raise ValueError('Output already exists; select a new capture path')
        data = capture(args.config, args.mysql, args.spell, args.quest)
        with args.output.open('x', encoding='utf-8') as stream:
            stream.write(json.dumps(data, indent=2) + '\n')
        print(f'World metadata captured: {args.output}')
        return 0
    except (OSError, ValueError, KeyError, subprocess.TimeoutExpired) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
