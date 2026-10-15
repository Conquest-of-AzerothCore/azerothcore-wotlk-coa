import json
import sys
from pathlib import Path


folder = Path(sys.argv[1])
result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
assert result['status'] == summary['status'] == 'passed'
values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
          for step in result['steps'] if step['action'] == 'snapshot'}
base = values['baseline_armor_pen']
for phase in ['learned', 'intellect']:
    expected = int(values[phase+'_intellect'] * .5)
    actual = values[phase+'_armor_pen'] - base
    assert actual == expected, (phase, actual, expected)
    print(f'{phase}: {values[phase+"_intellect"]:g} Intellect grants {actual:g} armor penetration rating')
assert values['intellect_intellect'] > values['learned_intellect']
assert values['removed_armor_pen'] == base
