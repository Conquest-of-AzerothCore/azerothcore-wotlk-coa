#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Ring of Life's native healing, non-stacking and owner-only magic defense."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for phase in ('ring', 'stacked', 'removed'):
        for actor in ('primalist', 'ally', 'outsider'):
            multiplier = 1.06 if phase != 'removed' and actor != 'outsider' else 1
            expected = values[f'baseline_{actor}_heal'] * multiplier
            actual = values[f'{phase}_{actor}_heal']
            if expected <= 0 or abs(actual - expected) > 2:
                raise ValueError(f'{phase}/{actor}: healing {actual}, expected {expected}')
        for actor in ('primalist', 'ally'):
            for spell in (803138, 803140):
                multiplier = .9 if phase != 'removed' and actor == 'primalist' and spell == 803140 else 1
                expected = values[f'baseline_{actor}_{spell}'] * multiplier
                actual = values[f'{phase}_{actor}_{spell}']
                if expected <= 0 or abs(actual - expected) > (15 if spell == 803140 else 2):
                    raise ValueError(f'{phase}/{actor}/{spell}: damage {actual}, expected {expected}')
    print('6% party healing, equal-aura non-stacking, owner-only 10% magic defense and removal passed')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
