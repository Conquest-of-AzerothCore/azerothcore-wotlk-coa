import json
import sys
from pathlib import Path


def main():
    folder = Path(sys.argv[1])
    result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
    summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
    scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
    assert result['status'] == summary['status'] == 'passed'
    values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    for phase in ['first', 'highest', 'ap_sp']:
        expected = int(values[phase + '_hit']) * 20 // 100
        assert values[phase + '_heals'] == values[phase + '_damage'] == expected * 3
        print(f'{phase}: {values[phase + "_hit"]:g} melee damage, {expected} per recipient, three of each')
    for phase in ['baseline', 'removed']:
        assert values[phase + '_heals'] == values[phase + '_damage'] == 0


if __name__ == '__main__':
    main()
