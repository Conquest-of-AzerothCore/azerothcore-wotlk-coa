import json
import sys
from pathlib import Path

from check_primalist_third_procs import check_probability


def main():
    folder = Path(sys.argv[1])
    mode = sys.argv[2]
    result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
    summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
    scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
    assert result['status'] == summary['status'] == 'passed'
    values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    if mode == 'earths-guidance':
        probes = [503264, 582532, 681114, 807432, 805462, 300693]
        for kind in ['damage', 'healing']:
            baselines = {spell: values[f'{kind}_baseline_0_{spell}'] for spell in probes}
            successes = 0
            for i in range(100):
                reductions = []
                for spell in probes:
                    actual = values[f'{kind}_talented_{i}_{spell}']
                    baseline = baselines[spell]
                    if not baseline:
                        assert actual == 0
                        continue
                    delta = baseline - actual
                    assert -250 <= delta <= 250 or 750 <= delta <= 1250, (kind, i, spell, delta)
                    reductions.append(delta > 500)
                assert reductions and len(set(reductions)) == 1, (kind, i, reductions)
                successes += int(reductions[0])
            p_value = check_probability(successes, 100, .2)
            print(f'{kind}: {successes}/100 reductions, exact binomial p={p_value:.5f}')
            for phase in ['baseline', 'removed']:
                for i in range(2):
                    for spell in probes:
                        assert abs(values[f'{kind}_{phase}_{i}_{spell}']-baselines[spell]) <= 250
    elif mode == 'lithic-lance':
        samples = [values[f'talented_{i}'] for i in range(100)]
        assert all(value in (0, 1) for value in samples)
        successes = int(sum(samples))
        p_value = check_probability(successes, 100, .2)
        print(f'Lithic Lance: {successes}/100 resource procs, exact binomial p={p_value:.5f}')
    elif mode == 'empowered-boons':
        assert values['wolf_339'] + values['wolf_116'] == 1, values
        expected_heal = 2250 if values['hawk_critical'] else 1500
        assert abs(values['hawk_heal']-expected_heal) <= 1, (values['hawk_heal'], expected_heal)
        expected_mana = int((values['hawk_max_mana']-1000)*.15)
        assert abs(values['hawk_mana']-expected_mana) <= 5, (values['hawk_mana'], expected_mana)
        print(f"Hawk: {values['hawk_heal']:g} healing, {values['hawk_mana']:g} mana; Wolf removed one impairment")
    elif mode == 'druid-training':
        for phase in ['talented', 'power']:
            maximum = int(values[phase+'_damage']*.1)
            for target in ['primalist', 'near', 'edge']:
                actual = values[phase+'_'+target+'_healed']
                assert maximum-2 <= actual <= maximum, (phase, target, actual, maximum)
            print(f"{phase}: {values[phase+'_damage']:g} source damage, {values[phase+'_near_healed']:g} healing per ally")
        assert values['power_source_damage'] > values['talented_source_damage']
        print(f"Fixed-base source damage: {values['talented_source_damage']:g} -> "
              f"{values['power_source_damage']:g}")
    elif mode == 'spiritual-frenzy':
        for phase in ['baseline', 'first', 'highest', 'removed']:
            assert values[phase+'_target_delta'] < 0
            extras = [values[f'{phase}_extra{i}_delta'] for i in range(1, 6)]
            count = sum(value < 0 for value in extras)
            expected = 3 if phase in ['first', 'highest'] else 0
            assert count == expected, (phase, extras, expected)
            assert values[phase+'_far_delta'] == 0
            print(f'{phase}: primary plus {count} additional victims')
    else:
        raise ValueError('Unknown check mode: '+mode)


if __name__ == '__main__':
    main()
