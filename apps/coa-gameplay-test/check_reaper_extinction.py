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
    trials = values['physical_hits']
    successes = values['stack_adders_after'] - values['stack_adders_before']
    if trials < 40 or trials != int(trials) or not 1 <= successes <= trials or successes != int(successes):
        raise ValueError('At least 40 actual Physical hits and an integral nonzero native proc count are required')
    trials, successes = int(trials), int(successes)
    probabilities = [math.comb(trials, k) * 0.35**k * 0.65**(trials-k) for k in range(trials+1)]
    observed = probabilities[successes]
    probability = sum(p for p in probabilities if p <= observed * (1 + 1e-12))
    if probability < 1e-6:
        raise ValueError(f'{successes}/{trials} procs contradict the original 35 percent chance: p={probability:g}')
    print(f'{successes}/{trials} native Extinction procs with three active souls; exact binomial p={probability:g}')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
