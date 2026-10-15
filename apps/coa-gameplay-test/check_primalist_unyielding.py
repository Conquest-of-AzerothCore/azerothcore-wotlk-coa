#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Unyielding Form against the ordinary, non-scaling armor items in its fixture."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for armor, item_armor in (('cloth', 103), ('leather', 150), ('mail', 178), ('plate', 359)):
        contribution = values[f'{armor}_armor'] - values[f'{armor}_bare']
        if contribution <= 0:
            raise ValueError(f'{armor}: equipment must contribute armor')
        for rank in (1, 2):
            expected = item_armor * rank / 4 if armor in ('mail', 'plate') else 0
            actual = values[f'{armor}_rank{rank}']
            if abs(actual - expected) > 1:
                raise ValueError(f'{armor} rank {rank}: added {actual}, expected {expected} (rounding <= 1)')
            print(f'{armor} rank {rank}: item armor {item_armor}, talent bonus {actual}, expected {expected}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
