#!/usr/bin/env python3
CLI_DESCRIPTION = """Verify Mineralization's healing multiplier below and above its proc threshold."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    baseline = values['baseline_heal']
    if baseline <= 0:
        raise ValueError('Missing positive baseline heal')
    if abs(values['own_heal'] - baseline) > 2:
        raise ValueError('The initial self-heal must retain its pre-proc calculation')
    for key in ('low_heal', 'above_heal', 'own_followup'):
        actual = values[key]
        if abs(actual - baseline * 1.1) > 2:
            raise ValueError(f'{key}: {actual}, expected 110% of {baseline}')
        print(f'{key}: {actual:.0f}, baseline {baseline:.0f}, multiplier {actual / baseline:.3f}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
