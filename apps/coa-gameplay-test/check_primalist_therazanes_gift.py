#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Therazane's Gift mana percentages separately from natural regeneration."""

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
    maximum = values['max_mana']
    for key, fraction in [('baseline_mana', .10), ('talented_mana', .15), ('removed_mana', .10)]:
        expected = int(maximum * fraction)
        if values[key] != expected:
            raise ValueError(f'{key}: {values[key]}, expected {expected}')
        print(f'{key}: {expected}, {fraction:.0%} of {maximum:.0f} maximum mana')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
