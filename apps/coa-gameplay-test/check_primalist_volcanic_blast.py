#!/usr/bin/env python3
CLI_DESCRIPTION = """Verify both Volcanic Blast ranks copy resolved damage onto nearby targets."""

import argparse
import json
import math
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    scenario = json.loads((directory / 'scenario.json').read_text(encoding='utf-8'))
    values = {scenario['steps'][int(step['index'])]['save_as']: int(float(step['actual']))
              for step in result['steps'] if step['action'] == 'snapshot'}
    for phase, percent in [('rank1', 20)]:
        expected = values[phase + '_source'] * percent // 100
        for target in ('target', 'near'):
            actual = values[phase + '_' + target]
            if actual != expected:
                raise ValueError(f'{phase}, {target}: {actual}, expected {expected}')
        print(f'{phase}: {expected} on each nearby target, {percent}% of resolved critical damage')
    successes = 0
    for i in range(160):
        phase = 'rank2_' + str(i)
        if values[phase + '_source_n'] != 1 or values[phase + '_source'] <= 0:
            raise ValueError(f'{phase}: one actual critical source hit is required')
        count = values[phase + '_target_n']
        if count not in (0, 1) or values[phase + '_near_n'] != count or values[phase + '_far_n'] != 0:
            raise ValueError(f'{phase}: the proc must hit both nearby targets once and exclude the distant target')
        expected = values[phase + '_source'] * 40 // 100 if count else 0
        for target in ('target', 'near'):
            if values[phase + '_' + target] != expected:
                raise ValueError(f'{phase}, {target}: expected {expected} copied damage')
        successes += count
    probabilities = [math.comb(160, k) * 0.9**k * 0.1**(160-k) for k in range(161)]
    observed = probabilities[successes]
    probability = sum(p for p in probabilities if p <= observed * (1 + 1e-12))
    if probability < 1e-6:
        raise ValueError(f'{successes}/160 procs contradict the authored 90 percent chance: p={probability:g}')
    print(f'rank2: {successes}/160 procs; exact binomial p={probability:g}; 40% copied to each nearby target')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
