import json
import sys
from pathlib import Path


def main():
    folder = Path(sys.argv[1])
    result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
    summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
    scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
    assert result['status'] == summary['status'] == 'passed'
    values = {scenario['steps'][int(step['index'])]['save_as']: int(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    per_tick = values['mend_amount'] * 20 // 100
    assert per_tick > 0
    for tick in range(1, 4):
        assert values[f'echo_{tick}'] == per_tick * tick, (
            f'Tick {tick}: expected {per_tick * tick}, got {values[f"echo_{tick}"]}'
        )
    print(f'Sanguine Mend healed {values["mend_amount"]}; three ticks of {per_tick} verified')


if __name__ == '__main__':
    main()
