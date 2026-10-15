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
    if sys.argv[2] == 'lacerations':
        normal = 0
        for index in range(12):
            critical = bool(values[f'natural_crit_{index}'] or values[f'natural_offhand_{index}'])
            assert values[f'natural_aura_{index}'] == critical
            normal += critical == 0
        assert normal > 0
        print(f'{normal}/12 ordinary hits correctly produced no Lacerations debuff')
    elif sys.argv[2] == 'verdant':
        for phase in ['baseline', 'talented', 'removed']:
            for rank in ['first', 'highest']:
                for spell in ['charge', 'rush']:
                    tag = f'{phase}_{rank}_{spell}'
                    start, middle, end = [values[tag + '_' + part] for part in ['start', 'middle', 'end']]
                    first_recovery = 4000 + (start - 2500) * .05 if phase == 'talented' else 4000
                    second_recovery = 2500 + (middle - 1000) * .05 if phase == 'talented' else 2500
                    assert abs(start - middle - first_recovery) < 180, (tag, start, middle, first_recovery)
                    assert abs(middle - end - second_recovery) < 180, (tag, middle, end, second_recovery)
                    print(f'{tag}: cooldown {start:g} -> {middle:g} -> {end:g} ms')
    else:
        raise ValueError('Expected lacerations or verdant')


if __name__ == '__main__':
    main()
