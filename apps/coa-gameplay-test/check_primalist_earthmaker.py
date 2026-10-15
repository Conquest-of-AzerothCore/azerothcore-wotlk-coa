#!/usr/bin/env python3
CLI_DESCRIPTION = """Compare Earthmaker CDR with native damage counts, subtracting an unrelated cooldown's elapsed time."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for mode in ('baseline', 'talented', 'removed'):
        for spell in (503264, 505157, 582532, 803138):
            prefix = f'{mode}_{spell}'
            hits = values[prefix + '_trials']
            actual = values[prefix + '_avatar_delta'] - values[prefix + '_control_delta']
            expected = -1000 * hits if mode == 'talented' and spell != 803138 else 0
            if hits < 1 or abs(actual - expected) > 200:
                raise ValueError(f'{prefix}: {hits} hits, adjusted CDR {actual}, expected {expected} ms')
            print(f'{prefix}: {hits:g} hits, CDR {actual:g} ms, expected {expected:g} ms')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
