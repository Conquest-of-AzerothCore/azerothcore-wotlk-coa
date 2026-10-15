import json
import math
import sys
from pathlib import Path


def check_probability(successes, trials, chance):
    probabilities = [math.comb(trials, k) * chance**k * (1-chance)**(trials-k)
                     for k in range(trials+1)]
    p_value = sum(p for p in probabilities if p <= probabilities[successes] + 1e-14)
    assert 0 < successes < trials and p_value >= .001, (successes, trials, p_value)
    return p_value


def main():
    folder = Path(sys.argv[1])
    mode = sys.argv[2]
    result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
    summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
    scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
    assert result['status'] == summary['status'] == 'passed'
    values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    if mode == 'pendant':
        for phase in ['first', 'highest', 'ap_sp', 'single_first', 'single_highest']:
            damage = values[phase+'_damage']
            offhand = values[phase+'_offhand']
            candidates = [int(damage) // 10]
            if phase in ['first', 'highest', 'ap_sp']:
                assert offhand > 0, (phase, offhand)
                candidates.append(int(offhand) // 10)
            else:
                assert offhand == 0
            healing = values[phase+'_heals']
            assert healing in candidates, (phase, candidates, healing)
            print(f'{phase}: main-hand {damage:g}, off-hand {offhand:g}, one 10% heal {healing:g}')
        assert values['baseline_heals'] == values['removed_heals'] == 0
        candidates = [int(values['area_'+who+'_damage']) // 10 for who in ['target', 'extra1', 'extra2']]
        assert values['area_heals'] in candidates, (values['area_heals'], candidates)
        print('Three simultaneous victims produced one correctly sized heal')
    elif mode == 'thorns':
        for phase in ['dealt', 'taken']:
            successes = int(values[phase+'_procs'])
            p_value = check_probability(successes, 100, .1)
            print(f'{phase}: {successes}/100 procs, exact binomial p={p_value:.5f}')
        assert values['magic_procs'] == 0
        base_tick = 43 + 1
        pvp_tuning_level = min(80, 60) - 10
        pvp_damage_percent = -11 + int(pvp_tuning_level * -.4) + 1
        outgoing_tick = base_tick * (100 + pvp_damage_percent) // 100
        expected_damage = 6 * (outgoing_tick * 90 // 100)
        assert values['six_tick_damage'] == expected_damage, (values['six_tick_damage'], expected_damage)
        assert all(values['break_initial_'+str(i)] == 1 for i in range(30))
        breaks = sum(values['break_after_'+str(i)] == 0 for i in range(30))
        p_value = check_probability(breaks, 30, .4)
        print(f'Direct-hit breaks: {breaks}/30, exact binomial p={p_value:.5f}')
    elif mode == 'judgement':
        trials = [values['trial_'+str(i)] for i in range(100)]
        assert all(value in (0, 3) for value in trials), trials
        successes = sum(value == 3 for value in trials)
        p_value = check_probability(successes, 100, .2)
        for key, expected in [('spell_power_gain', 72 * .325 * .85),
                              ('nature_power_gain', 66 * .325 * .85),
                              ('attack_power_gain', 100 * .278 * .85)]:
            assert abs(values[key]-expected) <= 1, (key, values[key], expected)
        assert 1.48 <= values['mountain_damage'] / values['base_damage'] <= 1.52
        print(f'{successes}/100 three-hammer procs, exact binomial p={p_value:.5f}; coefficients/modifiers passed')
    elif mode == 'bloody':
        baseline = values['baseline_heal']
        assert baseline > 0
        for stacks in [1, 2, 3]:
            expected = baseline * (1-stacks*.1)
            actual = values['stack_'+str(stacks)+'_heal']
            assert abs(actual-expected) <= 2, (stacks, baseline, actual, expected)
            print(f'{stacks} stacks: native HoT tick {actual:g}, baseline {baseline:g}')
    else:
        raise ValueError('Expected pendant, thorns, judgement or bloody')


if __name__ == '__main__':
    main()
