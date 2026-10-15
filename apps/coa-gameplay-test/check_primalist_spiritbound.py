#!/usr/bin/env python3
CLI_DESCRIPTION = """Verify removed Spiritbound no longer reduces Seismic cooldowns when another attack is avoided."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for mode in ('dodge', 'parry'):
        difference = values[mode + '_removed_cd_delta'] - values[mode + '_removed_control_delta']
        if abs(difference) > 200:
            raise ValueError(f'{mode}: Seismic CDR after removal differs from elapsed time by {difference} ms')
        print(f'{mode}: CDR after removal minus control timer = {difference:g} ms')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
