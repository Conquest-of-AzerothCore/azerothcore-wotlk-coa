#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Geode procs against positive offhand hits or direct spell hits."""

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
    offhand = result['scenario'] == 'primalist-terrasmash'
    trials = values['talented_offhand' if offhand else 'talented_hits']
    procs = values['talented_geodes']
    chance = .3 if offhand else .1
    if trials < 180 or not 0 < procs <= trials:
        raise ValueError(f'Invalid or inadequate sample: {procs}/{trials}')

    def probability(k):
        return math.exp(math.lgamma(trials + 1) - math.lgamma(k + 1) - math.lgamma(trials - k + 1)
                        + k * math.log(chance) + (trials - k) * math.log1p(-chance))

    observed = probability(procs)
    p_value = min(1.0, sum(p for k in range(trials + 1)
                           if (p := probability(k)) <= observed * (1 + 1e-12)))
    if p_value < .001:
        raise ValueError(f'{procs}/{trials} inconsistent with {chance:.0%}: exact p={p_value:.6f}')
    print(f'{procs}/{trials} Geodes, expected {chance:.0%}; exact p={p_value:.6f}; negative controls passed')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
