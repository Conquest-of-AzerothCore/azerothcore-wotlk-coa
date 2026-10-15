#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Mountain Giant's twenty-percent Aftershock chance per autoattack."""

import argparse
import json
import math
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: int(float(step['actual'])) for step in result['steps'] if 'actual' in step}
    trials = 180
    outcomes = [values[f'talented_{n}_proc'] for n in range(trials)]
    if any(value not in (0, 1) for value in outcomes):
        raise ValueError('Each single-attack sample must observe zero or one Aftershock')
    successes = sum(outcomes)

    def probability(k):
        return math.exp(math.lgamma(trials + 1) - math.lgamma(k + 1) - math.lgamma(trials - k + 1)
                        + k * math.log(.2) + (trials - k) * math.log(.8))

    observed = probability(successes)
    p_value = min(1.0, sum(p for k in range(trials + 1)
                           if (p := probability(k)) <= observed * (1 + 1e-12)))
    if p_value < .001:
        raise ValueError(f'{successes}/{trials} inconsistent with 20%: exact p={p_value:.6f}')
    print(f'{successes}/{trials} Aftershock procs, expected 20%; exact p={p_value:.6f}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
