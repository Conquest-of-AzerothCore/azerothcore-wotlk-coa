#!/usr/bin/env python3
CLI_DESCRIPTION = """Check that Primal Shred's bleed amount follows owner-AP base and the native pet modifier."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    scenario = json.loads((directory / 'scenario.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {scenario['steps'][int(step['index'])].get('save_as'): float(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    base = values['cast_base']
    multiplier = values['cast_multiplier'] / 1000
    amount = values['cast_amount']
    if base - values['base_504684'] != 5:
        raise ValueError('100 owner AP must contribute 5 before percentage modifiers')
    if abs(amount - int(base * multiplier)) > 2:
        raise ValueError(f'base {base}, multiplier {multiplier}, actual {amount}')
    print(f'rank 9: base {base:.0f}, pet modifier {multiplier:.3f}, bleed {amount:.0f}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
