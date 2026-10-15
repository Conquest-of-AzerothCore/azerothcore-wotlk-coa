#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Heavy Earth's percentage of completed native Barrage damage."""

import argparse
import json
from pathlib import Path


def check(directory, prefix=''):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    scenario = json.loads((directory / 'scenario.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {scenario['steps'][int(step['index'])].get('save_as'): int(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    for stacks in (3, 10):
        source, echo = values[f'{prefix}source_{stacks}'], values[f'{prefix}echo_{stacks}']
        expected = source * stacks * 5 // 100
        if source <= 0 or expected <= 0 or echo != expected:
            raise ValueError(f'{stacks} stacks: source {source}, echo {echo}, expected {expected}')
        print(f'{stacks} stacks: {source} physical damage, {echo} additional Nature damage')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    parser.add_argument('--prefix', default='')
    args = parser.parse_args()
    check(args.result_directory, args.prefix)
