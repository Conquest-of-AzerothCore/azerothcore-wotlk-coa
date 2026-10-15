#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Replenishment's five-percent Mana ticks and the Resources of the Earth proc."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: int(float(step['actual'])) for step in result['steps'] if 'actual' in step}
    if values['primalist_max_mana'] == values['ally_max_mana']:
        raise ValueError('Recipients must have different maximum Mana')
    for actor in ('primalist', 'ally'):
        tick = values[actor + '_max_mana'] * 5 // 100
        expected = {'first': tick, 'total': tick * 3} if result['scenario'] == 'ascension-replenishment' else {
            'baseline_gain': 0, 'talented_gain': tick * 3, 'removed_gain': 0}
        for suffix, amount in expected.items():
            key = actor + '_' + suffix
            if values[key] != amount:
                raise ValueError(f'{key}: {values[key]}, expected {amount}')
        print(f'{actor}: {tick} Mana per tick; three ticks and expiration verified')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
