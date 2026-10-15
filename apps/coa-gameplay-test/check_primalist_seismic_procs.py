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

    def probability(successes, trials, chance, label):
        p_value = check_probability(successes, trials, chance)
        print(f'{label}: {successes}/{trials}, exact binomial p={p_value:.5f}')

    if mode == 'quakeformer':
        samples = [values[f'talented_{family}_{i}_gain']
                   for family in ['claw', 'crash', 'spike', 'tremor', 'grasp'] for i in range(20)]
        assert all(value in (0, 1) for value in samples), samples
        probability(int(sum(samples)), 100, .25, 'One charge restored')
    elif mode == 'tremors':
        for start, ticks in [(0, 3), (50, 5)]:
            successes = 0
            for i in range(start, start + 50):
                free = values['free_'+str(i)]
                assert free in (0, 1)
                successes += int(free)
                crash = 803981 if i < 50 else 503264
                cds = [values[f'cd_{i}_{spell}'] for spell in [crash, 804433, 680442, 807432]]
                assert all(cd == 0 for cd in cds) if free else all(cd > 5000 for cd in cds), (i, free, cds)
            probability(successes, 50, 1-.9**ticks, f'{ticks} periodic hits per cast')
    elif mode == 'cataclysm':
        successes = 0
        for i in range(100):
            cds = [values[f'talented_{i}_{spell}'] for spell in [503264, 582532, 681114, 807432]]
            assert all(cd == 0 for cd in cds) or all(cd > 500 for cd in cds), (i, cds)
            successes += int(all(cd == 0 for cd in cds))
        probability(successes, 100, .1, 'All four Seismic cooldowns reset')
    elif mode == 'journey':
        direct = [values[f'talented_{i}_proc'] for i in range(100)]
        assert all(value in (0, 1) for value in direct), direct
        probability(int(sum(direct)), 100, .2, 'Direct Tremor hits')
        assert values['talented_bursts'] == sum(direct), (values['talented_bursts'], sum(direct))
        assert values['baseline_bursts'] == values['removed_bursts'] == 0
        ticks = sum(values[f'periodic_{i}_ticks'] for i in range(4))
        procs = sum(values[f'periodic_{i}_procs'] for i in range(4))
        assert ticks == 32, ticks
        probability(int(procs), int(ticks), .2, 'Periodic Tremor hits')
    elif mode == 'quaking-thane':
        for phase in ['normal', 'strength', 'stamina']:
            strength = values[phase+'_without_0']
            assert strength == values[phase+'_with_0']
            stamina = values[phase+'_with_2']
            expected_stamina = int(strength * .1)
            expected_ap = int(stamina * .2)
            delta_stamina = stamina - values[phase+'_without_2']
            delta_ap = values[phase+'_with_ap'] - values[phase+'_without_ap']
            assert delta_stamina == expected_stamina, (phase, strength, delta_stamina, expected_stamina)
            assert abs(delta_ap-expected_ap) <= 1, (phase, stamina, delta_ap, expected_ap)
            print(f'{phase}: Strength {strength:g}, +{delta_stamina:g} Stamina, +{delta_ap:g} AP')
        assert values['strength_without_0'] > values['normal_without_0']
        assert values['stamina_without_2'] > values['strength_without_2']
    else:
        raise ValueError('Expected quakeformer, tremors, cataclysm, journey or quaking-thane')


if __name__ == '__main__':
    main()
