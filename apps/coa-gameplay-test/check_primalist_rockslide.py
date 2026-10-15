#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Rockslide's 15% recursive repeats at the first and highest Stoneshard ranks."""

import argparse
import json
import math
from pathlib import Path


def check(directories):
    recursive_windows = 0
    for directory in directories:
        summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
        result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
        if summary['status'] != 'passed' or result['status'] != 'passed':
            raise ValueError('Completed native scenario passes are required')
        values = {step['label']: int(float(step['actual'])) for step in result['steps'] if 'actual' in step}
        originals = 200
        repeats = values['talented_total'] - originals
        if repeats < 0:
            raise ValueError('Missing original casts')
        recursive_windows += sum(values[f'talented_{i}_hits'] >= 3 for i in range(originals))

        def probability(k):
            return math.exp(math.lgamma(originals + k) - math.lgamma(originals) - math.lgamma(k + 1)
                            + originals * math.log(.85) + k * math.log(.15))

        observed = probability(repeats)
        p_value = min(1.0, sum(p for k in range(max(1000, repeats + 1))
                               if (p := probability(k)) <= observed * (1 + 1e-12)))
        print(f'{directory.name}: {repeats} repeats from {originals} originals; exact p={p_value:.6f}')
        if p_value < .001:
            raise ValueError('Sample is inconsistent with 15% recursive repeats')
    if not recursive_windows:
        raise ValueError('No cast window demonstrated a second repeat across 400 original casts')
    print(f'{recursive_windows} cast windows contained at least three hits, demonstrating recursion')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directories', type=Path, nargs=2)
    check(parser.parse_args().result_directories)
