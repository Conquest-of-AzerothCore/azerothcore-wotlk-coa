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
    observed = 0
    for window in range(20):
        before = values[f'before_{window}']
        for sample in range(8):
            count = values[f'proc_{window}_{sample}']
            if count < before or count != int(count):
                raise ValueError('Native proc counts must be monotonic integers')
            if count > before:
                if values[f'cooldown_{window}_{sample}'] != 0:
                    raise ValueError('A native Crusher proc failed to reset the still-active Crush cooldown')
                observed += 1
            before = count
    if not observed:
        raise ValueError('No native proc reset Crush before ordinary cooldown expiry')
    print(f'{observed} native proc observations reset Crush inside sixteen-second windows')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
