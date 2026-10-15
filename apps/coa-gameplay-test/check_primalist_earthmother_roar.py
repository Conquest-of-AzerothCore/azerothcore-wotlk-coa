import json
import math
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
    for phase in ['normal', 'critical']:
        deficit = values[phase + '_max'] - values[phase + '_health']
        critical = values[phase + '_crits']
        assert critical in (0, 1)
        if phase == 'critical':
            assert critical == 1
        base = math.floor(deficit * 0.2)
        expected = base + math.floor(base / 2) if critical else base
        actual = values[phase + '_heal']
        assert abs(actual - expected) <= 1, (phase, actual, expected, deficit)
        print(f'{phase}: {actual:g} healing from {deficit:g} missing health; expected {expected}')
    assert values['removed_heal'] == 0


if __name__ == '__main__':
    main()
