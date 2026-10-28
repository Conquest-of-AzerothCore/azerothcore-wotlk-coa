CLI_DESCRIPTION = """Searchable mechanic map derived from scenarios; explicit bindings for additional checks."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


DIRECTORY = Path(__file__).resolve().parent
ROOT = DIRECTORY.parents[1]


def read_json(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f'Duplicate key in {path}: {key}')
            result[key] = value
        return result
    return json.loads(Path(path).read_text(encoding='utf-8'), object_pairs_hook=unique)


def bindings(directory=DIRECTORY):
    data = read_json(directory / 'checks.json')
    if not isinstance(data, dict) or data.get('schema') != 1 or set(data) != {'schema', 'checks'}:
        raise ValueError('Unsupported check registry')
    if not isinstance(data['checks'], list):
        raise ValueError('Registry checks must be a list')
    seen = set()
    for check in data['checks']:
        if not isinstance(check, dict) or set(check) != {'script', 'scenarios', 'args'}:
            raise ValueError('Check requires script, scenarios and args')
        script = check['script']
        if not isinstance(script, str) or not re.fullmatch(r'check_[a-z0-9_]+\.py', script):
            raise ValueError('Invalid checker name')
        if not (directory / script).is_file():
            raise ValueError(f'Missing checker: {script}')
        cases = check['scenarios']
        if not isinstance(cases, list) or not cases or len(cases) != len(set(cases)):
            raise ValueError(f'Invalid scenarios for {script}')
        for case in cases:
            if not isinstance(case, str) or not re.fullmatch(r'[a-z0-9-]+', case):
                raise ValueError('Invalid scenario key')
            if not (directory / 'scenarios' / (case + '.json')).is_file():
                raise ValueError(f'Missing scenario: {case}')
        if not isinstance(check['args'], list) or not all(isinstance(arg, str) for arg in check['args']):
            raise ValueError('Checker args must be strings')
        identity = (script, tuple(cases), tuple(check['args']))
        if identity in seen:
            raise ValueError('Duplicate checker binding')
        seen.add(identity)
    registered = {check['script'] for check in data['checks']}
    unregistered = {path.name for path in directory.glob('check_*.py')} - registered
    if unregistered:
        raise ValueError(f'Unregistered result checkers: {sorted(unregistered)}')
    return data['checks']


def catalog(directory=DIRECTORY):
    checks = bindings(directory)
    rows = []
    inactive = {}
    paths = list((directory / 'scenarios').glob('*.json'))
    if directory.resolve() == DIRECTORY.resolve():
        paths += list((ROOT / 'modules').glob('*/tests/gameplay/*.json'))
        for manifest in (ROOT / 'modules').glob('*/tests/gameplay.json'):
            for case in read_json(manifest).get('disabled_scenarios', []):
                if case in inactive:
                    raise ValueError(f'Duplicate disabled scenario: {case}')
                inactive[case] = manifest.parents[1]
    for path in sorted(paths):
        data = read_json(path)
        contract = data.get('contract', '')
        if isinstance(contract, list) and all(isinstance(item, str) for item in contract):
            contract = '\n'.join(contract)
        if not isinstance(contract, str):
            raise ValueError(f'Unsupported contract in {path}')
        spells = sorted({step['spell'] for step in data['steps'] if type(step.get('spell')) is int})
        talents = sorted({step['talent'] for step in data['steps'] if type(step.get('talent')) is int})
        entities = {kind: sorted({step[key] for step in data['steps'] if type(step.get(key)) is int})
                    for kind, key in [('spell', 'spell'), ('talent', 'talent'), ('quest', 'quest'), ('item', 'item')]}
        rows.append({'id': path.stem, 'name': data['name'], 'path': str(path.relative_to(ROOT))
                     if path.is_relative_to(ROOT) else str(path), 'contract': contract,
                     'spells': spells, 'talents': talents,
                     'entities': entities,
                     'classes': sorted({player['class'] for player in data['players']}),
                     'metrics': sorted({step['metric'] for step in data['steps'] if 'metric' in step}),
                     'assertions': sum(step['action'] == 'assert' for step in data['steps']),
                     'checks': [c for c in checks if path.stem in c['scenarios']],
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                     'evidence': 'scenario definition; execution not established'})
        module = path.parents[2] if path.parent != directory / 'scenarios' else inactive.get(path.stem)
        if module:
            requirements = read_json(module / 'tests/gameplay.json')
            rows[-1].update(module=module.name, configuration=requirements['configuration'],
                            module_active=path.stem not in inactive)
    ids = [row['id'] for row in rows]
    if len(ids) != len(set(ids)):
        raise ValueError('Duplicate scenario ids across core and modules')
    if set(inactive) - set(ids):
        raise ValueError(f'Unknown disabled scenarios: {sorted(set(inactive) - set(ids))}')
    return rows


def select(rows, query='', spell=None, quest=None):
    words = query.casefold().split()
    return [row for row in rows if (spell is None or spell in row['spells'])
            and (quest is None or quest in row['entities']['quest'])
            and all(word in (row['id'] + ' ' + row['name'] + ' ' + row['contract']).casefold() for word in words)]


def companion_cases(cases, checks):
    selected = set(cases)
    while True:
        expanded = selected | {case for check in checks if selected.intersection(check['scenarios'])
                               for case in check['scenarios']}
        if selected == expanded:
            return sorted(selected)
        selected = expanded


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--query', default='')
    parser.add_argument('--spell', type=int)
    parser.add_argument('--quest', type=int)
    parser.add_argument('--check', action='store_true', help='Validate scenarios and all checker bindings')
    args = parser.parse_args(argv)
    try:
        rows = catalog()
        if args.check:
            import run
            for row in rows:
                run.validate(read_json(ROOT / row['path']))
            registered = {check['script'] for check in bindings()}
            print(f'{len(rows)} scenarios validated; {len(registered)} result checkers registered')
        else:
            print(json.dumps(select(rows, args.query, args.spell, args.quest), indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
