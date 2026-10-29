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
        offhand_expected = int(values[phase + '_offhand']) * 20 // 100
        total_expected = (expected + offhand_expected) * 3
        assert values[phase + '_heals'] == total_expected
        assert 0 < values[phase + '_damage'] <= total_expected
        print(f'{phase}: {values[phase + "_hit"]:g} main-hand + {values[phase + "_offhand"]:g} offhand melee '
              f'damage, {expected + offhand_expected} per recipient, three of each (damage copy can be '
              f'partially resisted, the heal copy cannot)')
    for phase in ['baseline', 'removed']:
        assert values[phase + '_heals'] == values[phase + '_damage'] == 0


if __name__ == '__main__':
    main()
