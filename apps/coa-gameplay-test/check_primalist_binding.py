#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Earthmother's Binding redirects 30% of the actual incoming hit, rounded down."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: int(float(step['actual'])) for step in result['steps'] if 'actual' in step}
    redirected = values['redirect_damage']
    total = values['remaining_damage'] + redirected
    if total <= 0 or redirected != total * 30 // 100:
        raise ValueError(f'Redirected {redirected} of {total}, expected floor(30%)')
    print(f'Redirected {redirected} of {total} incoming damage (30%, rounded down)')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
