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
    if values['normal_casts'] != 61:
        raise ValueError('One untalented control and sixty funded normal area casts are required')
    successes = 0
    for cohort in range(10):
        previous = 0
        for trial in range(6):
            current = values[f'scarabs_{cohort}_{trial}']
            if current != int(current) or current - previous not in (0, 1):
                raise ValueError('Within a live cohort each cast must summon zero or one real Scarab')
            previous = current
        successes += previous
    if successes == 0:
        raise ValueError('No native Scarab summon was observed across the counted casts')
    trials = 60
    successes = int(successes)
    probabilities = [math.comb(trials, k) * 0.4**k * 0.6**(trials-k) for k in range(trials+1)]
    observed = probabilities[successes]
    probability = sum(p for p in probabilities if p <= observed * (1 + 1e-12))
    if probability < 1e-6:
        raise ValueError(f'{successes}/{trials} Scarabs contradict the original 40 percent chance: p={probability:g}')
    print(f'{successes}/{trials} real Scarab summons across ten lifetime-bounded cohorts; '
          f'exact binomial p={probability:g}; untalented and original expiry controls passed')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
