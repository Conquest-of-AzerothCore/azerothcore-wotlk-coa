import json
import sys
from pathlib import Path

from check_primalist_third_procs import check_probability

folder = Path(sys.argv[1])
result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
assert result['status'] == summary['status'] == 'passed'
values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
          for step in result['steps'] if step['action'] == 'snapshot'}
for phase in ['fresh', 'extend']:
    successes = 0
    for i in range(100):
        before = values[f'{phase}{i}before']
        after = values[f'{phase}{i}after']
        delta = after - before
        if phase == 'fresh':
            assert before == 0
            assert after == 0 or 4000 <= after <= 5000, (phase, i, after)
        else:
            assert 19000 <= before <= 20000, before
            assert -1000 <= delta <= 0 or 4000 <= delta <= 5000, (phase, i, delta)
        successes += int(delta > 3000)
    p_value = check_probability(successes, 100, .05)
    print(f'{phase}: {successes}/100 procs, exact binomial p={p_value:.5f}')
