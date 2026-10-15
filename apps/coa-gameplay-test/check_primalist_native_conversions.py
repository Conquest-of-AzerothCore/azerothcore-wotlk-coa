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
    if sys.argv[2] == 'everlasting':
        for rank in ['first', 'highest']:
            base_duration = values[rank + '_baseline_duration']
            base_interval = values[rank + '_baseline_interval']
            assert abs(values[rank + '_talented_duration'] - base_duration - 6000) < 100
            assert values[rank + '_talented_interval'] == int(base_interval * .9)
            assert abs(values[rank + '_removed_duration'] - base_duration) < 100
            assert values[rank + '_removed_interval'] == base_interval
            print(f'{rank}: +6000 ms duration and tick interval {base_interval:g} -> {base_interval*.9:g} ms')
    elif sys.argv[2] == 'king':
        for phase in ['baseline', 'learned', 'strength', 'stamina', 'removed']:
            active = phase not in ['baseline', 'removed']
            assert values[phase + '_linked'] == int(active)
            expected = int(values[phase + '_stat_0'] * .15) if active else 0
            for rating in [2, 3, 17, 18, 19]:
                assert values[f'{phase}_rating_{rating}'] - values[f'baseline_rating_{rating}'] == expected
        assert values['strength_stat_0'] > values['learned_stat_0']
        assert values['stamina_stat_2'] > values['strength_stat_2']
        for phase, base in [('learned', 'baseline'), ('stamina', 'removed')]:
            assert values[phase + '_stat_0'] == values[base + '_stat_0']
            assert values[phase + '_stat_2'] == values[base + '_stat_2']
            assert abs(values[phase + '_ap'] - values[base + '_ap'] - int(values[phase + '_stat_2'] * .3)) <= 1
        print('All five ratings use 15% current Strength; linked AP uses 30% current Stamina')
    else:
        raise ValueError('Expected everlasting or king')


if __name__ == '__main__':
    main()
