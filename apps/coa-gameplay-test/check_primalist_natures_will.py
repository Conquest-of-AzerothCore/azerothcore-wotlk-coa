#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Earthshaping duration changes against an independent elapsed-time aura."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for phase, spells in [('baseline', [582532]),
                          ('talented', [582532, 681114, 503264, 572878, 300693, 807432, 803138]),
                          ('removed', [582532])]:
        for spell in spells:
            key = f'{phase}_{spell}'
            extension = values[key + '_d680441'] - values[key + '_d5697']
            expected = 4000 if phase == 'talented' and spell != 803138 else 0
            if abs(extension - expected) > 250:
                raise ValueError(f'{key}: extension {extension:.0f} ms, expected {expected}')
            print(f'{key}: Earthshaping extension {extension:.0f} ms')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
