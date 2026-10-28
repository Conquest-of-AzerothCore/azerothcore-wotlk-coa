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
    baseline = values['cast_speed_base']
    if baseline <= 0:
        raise ValueError('The native baseline casting speed must be positive')
    amounts = {key.removeprefix('haste_'): value for key, value in values.items()
               if key.startswith('haste_') and key.removeprefix('haste_').isdigit()}
    observed_amounts = [value for key, value in values.items()
                       if key.startswith('haste_') and key != 'haste_procs']
    if len(amounts) != 280 or any(value not in (0, 20) for value in observed_amounts):
        raise ValueError('Each native checkpoint must observe absent haste or its original 20 percent amount')
    max_step = float(result['max_step_ms'])
    if max_step <= 0:
        raise ValueError('The native maximum step must be positive')
    active = [values[f'speed_{index}'] / baseline for index, amount in amounts.items()
              if amount == values[f'haste_after_{index}'] == 20
              and values[f'duration_{index}'] > 2 * max_step]
    if not active:
        raise ValueError('No checkpoint observed a real Runeslinger haste proc')
    if any(abs(value - 1 / 1.2) > 0.0001 for value in active):
        raise ValueError('The native haste proc does not supply the authored casting-speed benefit')
    inactive = [values[f'speed_{index}'] / baseline for index, amount in amounts.items()
                if amount == values[f'haste_after_{index}'] == 0]
    if any(abs(value - 1) > 0.0001 for value in inactive):
        raise ValueError('Casting speed changed without the native haste aura')
    trials = values['blast_hits'] + values['burst_hits']
    successes = values['haste_procs']
    if trials < 281 or trials != int(trials) or not 1 <= successes <= trials or successes != int(successes):
        raise ValueError('At least 281 real direct-damage hits and an integral nonzero native proc count are required')
    trials, successes = int(trials), int(successes)
    probabilities = [math.comb(trials, k) * 0.05**k * 0.95**(trials-k) for k in range(trials+1)]
    observed = probabilities[successes]
    probability = sum(p for p in probabilities if p <= observed * (1 + 1e-12))
    if probability < 1e-6:
        raise ValueError(f'{successes}/{trials} procs contradict the authored 5 percent chance: p={probability:g}')
    print(f'{successes}/{trials} native procs; exact binomial p={probability:g}; '
          f'{len(active)} stable checkpoints verified 20 percent haste and its 1/1.2 casting-speed multiplier')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
