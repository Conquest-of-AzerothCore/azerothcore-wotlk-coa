CLI_DESCRIPTION = """Plan an investigation and execute the registered native and numerical verification together."""

import argparse
import copy
import json
import subprocess
import sys

import catalog
import verification


def plan(query='', spell=None, quest=None):
    rows = catalog.select(catalog.catalog(), query, spell, quest)
    inspector = ['python', 'apps/coa-dbc/coa-dbc-viewer', 'map', '--data', '<DBC-directory>',
                 '--table', 'Spell', '--id', str(spell)] if spell is not None else None
    if quest is not None:
        inspector = ['python', 'apps/coa-mechanics/mechanic_map.py', 'show', f'quest:{quest}',
                     '--sql', '<world-metadata-capture.json>']
    return {'schema': 1, 'query': query, 'spell': spell, 'quest': quest, 'candidates': rows,
            'classification': 'untriaged',
            'sequence': ['Inspect effective client/server records and acquisition',
                         'Establish the expected result independently of the implementation',
                         'Select a relevant scenario and verify its metric observes the behavior',
                         'Classify: confirmed defect, already working, incorrect test, or unresolved expectation',
                         'Apply a scoped fix for a confirmed defect',
                         'Run the registered scenario and result checks; review the diff before a PR'],
            'inspector': inspector}


def run_registered(args, scenario, native_execute, directory=catalog.DIRECTORY):
    if getattr(args, 'native_only', False):
        print('NATIVE ONLY: registered numerical checks are disabled; this is not combined verification.')
        return native_execute(args, scenario)
    rows = catalog.catalog(directory)
    exact = [row for row in rows if catalog.read_json(catalog.ROOT / row['path']) == scenario]
    if not exact:
        raise ValueError('Scenario does not match the catalog. Register its current definition, or use '
                         '--native-only for exploratory execution without combined verification.')
    cases = catalog.companion_cases([exact[0]['id']], catalog.bindings(directory))
    from run import validate
    paths = {row['id']: catalog.ROOT / row['path'] for row in rows}
    definitions = {case: validate(catalog.read_json(paths[case])) for case in cases}
    outputs, execution_failures = [], []
    for case in cases:
        parameters = copy.copy(args)
        parameters.result_directory = None
        if len(cases) > 1 and args.output:
            parameters.output = args.output / case
        try:
            status = native_execute(parameters, definitions[case])
        except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
            status = 1
            execution_failures.append({'scenario': case, 'message': str(error)})
        if parameters.result_directory is not None:
            outputs.append(parameters.result_directory)
        if status:
            execution_failures.append({'scenario': case, 'message': f'Native stage exited with status {status}'})
            break
    result = verification.verify(outputs, directory, expected_scenarios=cases)
    result['failures'].extend(execution_failures)
    if result['failures']:
        result['status'] = 'failed'
    encoded = json.dumps(result, indent=2) + '\n'
    destination = None
    if outputs:
        destination = outputs[0] / 'verification.json'
        destination.write_text(encoded, encoding='utf-8')
    print(f"VERIFICATION {result['status'].upper()}: {len(cases)} required scenario(s), "
          f"{len(result['checks'])} required numerical check(s)")
    if destination:
        print(f'Combined result: {destination}')
    else:
        print(encoded, end='')
    for failure in result['failures']:
        print(failure['message'], file=sys.stderr)
    return 0 if result['status'] == 'passed' else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--query', default='')
    selector = parser.add_mutually_exclusive_group()
    selector.add_argument('--spell', type=int)
    selector.add_argument('--quest', type=int)
    args = parser.parse_args(argv)
    try:
        print(json.dumps(plan(args.query, args.spell, args.quest), indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
