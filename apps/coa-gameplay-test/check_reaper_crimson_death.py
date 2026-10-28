import json
import math
from pathlib import Path
import sys


def check(folder):
    result = json.loads((folder / 'result.json').read_text())
    summary = json.loads((folder / 'summary.json').read_text())
    scenario = json.loads((folder / 'scenario.json').read_text())
    if result['status'] != 'passed' or summary['status'] != 'passed':
        raise ValueError('A completed native scenario is required')
    values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    cost = values['slaughter_cost']
    successes = 0
    for i in range(200):
        casts = values['after_' + str(i)] - values['before_' + str(i)]
        if casts not in (1, 2):
            raise ValueError(f'Trial {i}: expected one normal cast and at most one extra, observed {casts:g}')
        if values['power_' + str(i)] != 1000 - cost:
            raise ValueError(f'Trial {i}: Slaughter did not pay exactly one native cast cost')
        successes += casts == 2
    probabilities = [math.comb(200, k) * 0.2**k * 0.8**(200-k) for k in range(201)]
    observed = probabilities[successes]
    probability = sum(p for p in probabilities if p <= observed * (1 + 1e-12))
    if probability < 1e-6:
        raise ValueError(f'{successes}/200 extra casts contradict the authored 20 percent chance: p={probability:g}')
    print(f'{successes}/200 free extra Slaughters; exact binomial p={probability:g}; one normal cost per trial')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
