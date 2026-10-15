#!/usr/bin/env python3

import json
import math
import sys
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    scenario = json.loads((directory / 'scenario.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {scenario['steps'][int(step['index'])].get('save_as'): int(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    trials, successes = values['swings'], values['procs']
    if trials < 200 or not 0 < successes < trials or values['proc_damage'] <= 0:
        raise ValueError('Insufficient native attacks or positive proc damage')
    masses = [math.comb(trials, k) * 0.2 ** k * 0.8 ** (trials - k) for k in range(trials + 1)]
    probability = sum(mass for mass in masses if mass <= masses[successes] * (1 + 1e-12))
    if probability < 0.001:
        raise ValueError(f'{successes}/{trials} procs reject the 20% contract: p={probability:.6g}')
    mana_per_proc = values['maximum_mana'] * 5 // 100
    if values['mana_events'] != successes or values['mana_total'] != successes * mana_per_proc:
        raise ValueError('Every damaging proc must restore exactly 5% maximum mana')
    print(f'{successes}/{trials} procs; binomial p={probability:.4f}; {mana_per_proc} mana per proc')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
