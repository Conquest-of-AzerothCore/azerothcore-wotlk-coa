#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Pulverize repeats the rank's area amount after native mitigation."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for phase in ('first', 'highest', 'spellpower', 'attackpower'):
        normal, repeat = values[phase + '_normal'], values[phase + '_repeat']
        if normal <= 0 or abs(normal - repeat) > 3:
            raise ValueError(f'{phase}: area damage {normal}, repeated damage {repeat}')
    if abs(values['spellpower_repeat'] - values['highest_repeat']) > 3:
        raise ValueError('Nature spell power must not increase the attack-power area damage')
    if values['attackpower_repeat'] <= values['highest_repeat'] + 30:
        raise ValueError('The 100 AP fixture must increase the mitigated critical repeat')
    print('Pulverize repeats the first/highest rank area damage with AP scaling and no extra SP term')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
