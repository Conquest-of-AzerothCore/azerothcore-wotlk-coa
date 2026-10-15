import json
import sys
from pathlib import Path


def main():
    folder = Path(sys.argv[1])
    mode = sys.argv[2]
    result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
    summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
    scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
    assert result['status'] == summary['status'] == 'passed'
    values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    if mode == 'infused':
        rates = {scenario['steps'][int(step['index'])]['trigger_spell']: float(step['actual'])
                 for step in result['steps'] if step.get('metric') == 'aura_proc_rate'}
        for phase, trigger in [('hand', 502808), ('hammer', 806073)]:
            trials = [values[f'{phase}_proc_{i}'] for i in range(100)]
            assert all(value in (0, 1) for value in trials)
            triggered = [values[f'{phase}_events_after_{i}'] - values[f'{phase}_events_before_{i}']
                         for i in range(100)]
            assert triggered == trials, (phase, triggered, trials)
            successes = int(sum(trials))
            assert successes > 0, (phase, successes)
            print(f'{phase}: {successes}/100 actual procs, matching aura observations; '
                  f'native decision rate={rates[trigger]:.3f}%')
    elif mode == 'cascade':
        assert values['natural_heals'] == values['natural_crits'] < 5
        print(f'Five ordinary Wildclaws: {values["natural_crits"]:g} critical hits and matching heals')
    elif mode == 'carnage':
        for phase in ['first', 'highest']:
            hits = sorted((values[phase + '_' + who] for who in
                           ['target', 'extra1', 'extra2', 'extra3', 'extra4', 'extra5']), reverse=True)
            assert hits[-1] == 0 and hits[-2] > 0, hits
            for previous, current in zip(hits[:4], hits[1:5]):
                assert .82 <= current / previous <= .88, (phase, hits)
            print(f'{phase}: five hits with 15% attenuation per jump: {hits[:5]}')
    else:
        raise ValueError('Expected infused, cascade or carnage')


if __name__ == '__main__':
    main()
