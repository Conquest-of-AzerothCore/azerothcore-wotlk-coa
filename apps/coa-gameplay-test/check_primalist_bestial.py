#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Bestial Wrath's exact native energize amounts, independently of regeneration."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: int(float(step['actual'])) for step in result['steps']
              if 'actual' in step}
    for phase in ('baseline', 'removed'):
        for resource in ('focus', 'mana'):
            for metric in ('count', 'total'):
                if values[f'{phase}_{resource}_{metric}'] != 0:
                    raise ValueError(f'{resource} proc without the talent in {phase}')
    expected = {'focus': 10, 'mana': values['max_mana'] * 2 // 100}
    for resource, amount in expected.items():
        count = values[f'talented_{resource}_count']
        total = values[f'talented_{resource}_total']
        if count < 1 or total != count * amount:
            raise ValueError(f'{resource}: {count} events gave {total}, expected {count * amount}')
        print(f'{resource}: {count} native events, {amount} each, {total} total')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    args = parser.parse_args()
    check(args.result_directory)
