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
    means = {}
    for phase in ('one', 'five'):
        count = values[phase + '_stack_procs']
        damage = values[phase + '_stack_damage']
        if count < 1 or count != int(count) or damage <= 0:
            raise ValueError(f'{phase}: actual native damage and a positive integral proc count are required')
        means[phase] = damage / count
    amount = values['one_stack_amount']
    expected = {}
    for phase, stacks in [('one', 1), ('five', 5)]:
        expected[phase] = int(amount * stacks) + int(values['unchanged_rap'] * 0.15)
        if expected[phase] <= 0 or not 0.75 * expected[phase] <= means[phase] <= expected[phase] + 1:
            raise ValueError(f'{phase}: mean damage {means[phase]:g} is not {stacks} times the native aura amount '
                             f'plus 15 percent owner RAP ({expected[phase]}) less monster partial resists')
    ratio = means['five'] / means['one']
    target = expected['five'] / expected['one']
    if not 0.9 * target <= ratio <= 1.1 * target:
        raise ValueError(f'Five stacks must multiply only the proc base damage: observed ratio {ratio:g}, '
                         f'expected {target:g}')
    print(f"One stack: {values['one_stack_procs']:g} procs, mean damage {means['one']:g}; "
          f"five stacks: {values['five_stack_procs']:g} procs, mean damage {means['five']:g}; ratio {ratio:g}")


if __name__ == '__main__':
    check(Path(sys.argv[1]))
