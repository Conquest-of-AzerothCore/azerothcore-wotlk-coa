#!/usr/bin/env python3
CLI_DESCRIPTION = """Check independent Bash proc samples from scenarios/primalist-bash.json.

Usage: python apps/coa-gameplay-test/check_primalist_bash.py <run-directory>
The native run must pass first. Each sample needs at least 250 auto-attacks;
a two-sided exact binomial test rejects an advertised rate at p < 0.001.
"""

import json
import math
import sys
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('The native scenario must pass before checking proc rates')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for name, chance in [('base', .30), ('rank1', .33), ('rank2', .36)]:
        trials = int(values[name + '_trials'])
        successes = int(values[name + '_successes'])
        if trials < 250 or not 0 <= successes <= trials:
            raise ValueError(f'{name}: invalid or insufficient sample ({successes}/{trials})')

        def probability(k):
            return math.exp(math.lgamma(trials + 1) - math.lgamma(k + 1) - math.lgamma(trials - k + 1)
                            + k * math.log(chance) + (trials - k) * math.log1p(-chance))

        observed = probability(successes)
        p_value = min(1.0, sum(p for k in range(trials + 1)
                               if (p := probability(k)) <= observed * (1 + 1e-12)))
        print(f'{name}: {successes}/{trials} = {successes / trials:.3%}; '
              f'expected {chance:.0%}; exact binomial p={p_value:.6f}')
        if p_value < .001:
            raise ValueError(f'{name}: sample is inconsistent with the advertised proc rate')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(CLI_DESCRIPTION)
    check(Path(sys.argv[1]))
