#!/usr/bin/env python3
CLI_DESCRIPTION = """Check four-percent Stoneshard Mana returns at the first and highest ranks."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: int(float(step['actual'])) for step in result['steps'] if 'actual' in step}
    for actor, stone in (('first', 680448), ('highest', 681536)):
        mana = values[actor + '_max_mana'] * 4 // 100
        for phase in ('baseline', 'talented', 'removed'):
            for spell in (stone, 803138):
                expected = mana if phase == 'talented' and spell == stone else 0
                key = f'{actor}_{phase}_{spell}_gain'
                if values[key] != expected:
                    raise ValueError(f'{key}: {values[key]}, expected {expected}')
        print(f'{actor}: {mana} Mana per Stoneshard; unrelated spell and removal controls passed')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
