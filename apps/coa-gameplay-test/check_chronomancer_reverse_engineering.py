import json
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
    baseline = values['baseline_cast_speed']
    active = [values[f'speed_{i}'] / baseline for i in range(120) if values[f'haste_{i}'] == 15]
    if not active:
        raise ValueError('No checkpoint observed the original 15 percent haste aura')
    expected = 1 / 1.15
    if any(abs(value - expected) > 0.0001 for value in active):
        raise ValueError('The observed native haste aura does not supply its authored cast-speed benefit')
    print(f'{len(active)} checkpoints observed the 15 percent haste aura; cast-speed multiplier {active[0]:g}')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
