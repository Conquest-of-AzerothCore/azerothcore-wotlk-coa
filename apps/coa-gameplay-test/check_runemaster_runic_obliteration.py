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
    transforms = [values[f'natural_transform_{trial}'] for trial in range(1, 81)]
    if any(value not in (0, 1) for value in transforms) or not any(transforms):
        raise ValueError('No completed Elemental Burst observed a naturally applied transform aura')
    print(f'{sum(transforms):g}/80 native hit checkpoints observed the natural transform aura; no aura injection')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
