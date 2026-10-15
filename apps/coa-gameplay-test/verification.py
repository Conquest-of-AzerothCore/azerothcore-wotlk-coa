CLI_DESCRIPTION = """Combine native completion, exact scenario identity and registered numerical checks."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

import catalog


def environment_with_checker_assertions_enabled():
    environment = dict(os.environ)
    environment.pop('PYTHONOPTIMIZE', None)
    return environment


def verify(directories, directory=catalog.DIRECTORY, expected_scenarios=()):
    import run

    checks = catalog.bindings(directory)
    cases = {row['id']: row for row in catalog.catalog(directory)}
    selected = set(expected_scenarios)
    if selected - cases.keys():
        raise ValueError(f'Unknown required scenarios: {sorted(selected - cases.keys())}')
    fingerprints = {}
    for key, case in cases.items():
        definition = catalog.read_json(catalog.ROOT / case['path'])
        fingerprints[json.dumps(definition, sort_keys=True)] = key
    results, evidence, failures, check_results = {}, {}, [], []
    observed = set()
    started = time.monotonic()
    for folder in map(Path, directories):
        try:
            scenario_path = folder / 'scenario.json'
            scenario = run.validate(catalog.read_json(scenario_path))
            case = fingerprints.get(json.dumps(scenario, sort_keys=True))
            if case is None:
                raise ValueError('Scenario does not match a current catalog entry; stale or exploratory results')
            selected.add(case)
            if case in observed:
                raise ValueError(f'Duplicate result for {case}; select one run explicitly')
            observed.add(case)
            summary = catalog.read_json(folder / 'summary.json')
            if summary.get('status') != 'passed' or summary.get('cleanup_failed'):
                raise ValueError(f"Native run or cleanup failed: {summary.get('message', case)}")
            report = catalog.read_json(folder / 'result.json')
            digest = hashlib.sha256(scenario_path.read_bytes()).hexdigest()
            if digest != summary.get('scenario_sha256'):
                raise ValueError('Recorded scenario hash does not match the result bundle')
            if summary.get('scenario') != scenario['name']:
                raise ValueError('Summary names a different scenario')
            if not re.fullmatch('[0-9a-f]{64}', summary.get('binary_sha256', '')):
                raise ValueError('Missing executable identity')
            run.check_report(report, summary['run_id'], scenario, 0)
            results[case] = folder.resolve()
            evidence[case] = {'directory': str(folder.resolve()), 'run_id': summary['run_id'],
                              'binary_sha256': summary['binary_sha256'], 'scenario_sha256': digest}
        except (OSError, ValueError, KeyError, TypeError) as error:
            failures.append({'result': str(folder), 'message': str(error)})
    required = catalog.companion_cases(selected, checks)
    missing_scenarios = set(required) - observed
    if missing_scenarios:
        failures.append({'message': f'Missing required scenario results: {sorted(missing_scenarios)}'})
    for check in checks:
        needed = set(check['scenarios'])
        if not needed.intersection(required):
            continue
        record = {**check, 'status': 'blocked'}
        check_results.append(record)
        missing = needed - results.keys()
        if missing:
            record['message'] = f'Missing passing native results: {sorted(missing)}'
            failures.append({'check': check['script'], 'message': record['message']})
            continue
        if len({evidence[case]['binary_sha256'] for case in needed}) != 1:
            record['message'] = 'Companion results used different executables'
            failures.append({'check': check['script'], 'message': record['message']})
            continue
        command = [sys.executable, '-B', str(directory / check['script']),
                   *(str(results[case]) for case in check['scenarios']), *check['args']]
        try:
            record['script_sha256'] = hashlib.sha256((directory / check['script']).read_bytes()).hexdigest()
            outcome = subprocess.run(command, capture_output=True, text=True, timeout=60,
                                     env=environment_with_checker_assertions_enabled())
            record.update(status='passed' if outcome.returncode == 0 else 'failed', returncode=outcome.returncode,
                          output=(outcome.stdout + outcome.stderr)[-12000:])
            if outcome.returncode:
                failures.append({'check': check['script'],
                                 'message': record['output'] or f'Checker exited with status {outcome.returncode}'})
        except (OSError, subprocess.TimeoutExpired) as error:
            record.update(status='failed', message=str(error))
            failures.append({'check': check['script'], 'message': str(error)})
    if not directories:
        failures.append({'message': 'No results supplied'})
    return {'schema': 1, 'status': 'failed' if failures else 'passed',
            'scope': 'recorded native execution plus registered checks; not client rendering or current deployment',
            'required_scenarios': required, 'scenarios': list(results), 'evidence': evidence,
            'checks': check_results, 'failures': failures,
            'seconds': round(time.monotonic() - started, 4)}


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('results', type=Path, nargs='+')
    parser.add_argument('--output', type=Path, help='Write the combined result to a new JSON file')
    args = parser.parse_args(argv)
    try:
        result = verify(args.results)
        encoded = json.dumps(result, indent=2) + '\n'
        if args.output:
            with args.output.open('x', encoding='utf-8') as stream:
                stream.write(encoded)
        print(encoded, end='')
        return 0 if result['status'] == 'passed' else 1
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
