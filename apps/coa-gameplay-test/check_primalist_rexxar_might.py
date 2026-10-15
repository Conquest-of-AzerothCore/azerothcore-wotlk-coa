#!/usr/bin/env python3
CLI_DESCRIPTION = """Separate Rexxar's owner-AP coefficient from native pet damage modifiers."""

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
    if values['owner_ap_base'] - values['talented_base'] != 15:
        raise ValueError('100 owner AP must contribute 15 before percentage modifiers')
    for phase in ('talented', 'owner_ap', 'pet_ap'):
        base = values[phase + '_base']
        multiplier = values[phase + '_multiplier'] / 1000
        amount = values[phase + '_amount']
        if abs(amount - int(base * multiplier)) > 2:
            raise ValueError(f'{phase}: base {base}, multiplier {multiplier}, actual {amount}')
        print(f'{phase}: base {base:.0f}, pet modifier {multiplier:.3f}, bleed {amount:.0f}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
