#!/usr/bin/env python3
CLI_DESCRIPTION = """Verify Totem Warrior repeats forty percent of each completed weapon hit."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: int(float(step['actual'])) for step in result['steps'] if 'actual' in step}
    for phase in ('baseline', 'first_rank', 'highest_rank', 'critical', 'no_boon', 'removed'):
        main = 800140 if phase in ('baseline', 'first_rank') else 520566
        expected = 0
        if phase in ('first_rank', 'highest_rank', 'critical'):
            expected = sum(values[f'{phase}_{spell}_damage'] * 40 // 100 for spell in (main, 504240))
        actual = values[f'{phase}_555732_damage']
        if actual != expected:
            raise ValueError(f'{phase}: extra damage {actual}, expected {expected}')
        print(f'{phase}: {actual} extra damage; each weapon contributes forty percent once')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
