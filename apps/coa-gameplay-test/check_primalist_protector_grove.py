#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Protector's three cooldown reductions against an unrelated elapsed-time control."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for phase in ('baseline', 'talented', 'periodic', 'removed'):
        hits = values[phase + '_hits']
        if hits < 1:
            raise ValueError(f'{phase}: no damage events')
        expected = -1000 * hits if phase == 'talented' else 0
        for spell in (500692, 800181, 800094):
            actual = values[f'{phase}_{spell}_delta'] - values[f'{phase}_680421_delta']
            if abs(actual - expected) > 200:
                raise ValueError(f'{phase}/{spell}: {actual} ms, expected {expected} ms')
            print(f'{phase}/{spell}: {actual:g} ms, expected {expected:g} ms')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
