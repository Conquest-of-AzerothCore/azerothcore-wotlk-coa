#!/usr/bin/env python3
CLI_DESCRIPTION = """Check the advertised 15% proc rate separately for Geodes and Geode Barrage stones."""

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
    for spell in (804002, 803138):
        trials = successes = 0
        for sample in range(10):
            prefix = f'fury_{spell}_{sample}'
            count = values[prefix + '_trials']
            added = values[prefix + '_charges'] - 10
            if count != 25 or not 0 <= added <= count:
                raise ValueError(f'{prefix}: invalid trial/charge count {count}/{added}')
            trials += count
            successes += added

        def probability(k):
            return math.exp(math.lgamma(trials + 1) - math.lgamma(k + 1) - math.lgamma(trials - k + 1)
                            + k * math.log(.15) + (trials - k) * math.log(.85))

        observed = probability(successes)
        p_value = min(1.0, sum(p for k in range(trials + 1)
                               if (p := probability(k)) <= observed * (1 + 1e-12)))
        print(f'{spell}: {successes}/{trials}; expected 15%; exact binomial p={p_value:.6f}')
        if p_value < .001:
            raise ValueError(f'{spell}: sample is inconsistent with the advertised proc rate')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
