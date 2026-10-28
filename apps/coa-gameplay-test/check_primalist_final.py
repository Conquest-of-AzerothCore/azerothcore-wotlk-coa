import json
import sys
from pathlib import Path


folder = Path(sys.argv[1])
mode = sys.argv[2]
result = json.loads((folder / 'result.json').read_text(encoding='utf-8'))
summary = json.loads((folder / 'summary.json').read_text(encoding='utf-8'))
scenario = json.loads((folder / 'scenario.json').read_text(encoding='utf-8'))
assert result['status'] == summary['status'] == 'passed'
values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
          for step in result['steps'] if step['action'] == 'snapshot'}

if mode in ['douse', 'sacred-grove']:
    coefficient = .08 if mode == 'douse' else 1
    for phase in ['base', 'ap', 'sp']:
        expected = int(1000 + values[phase + 'ap'] * coefficient)
        if mode == 'douse':
            expected = int(expected * .7)
        assert abs(values[phase + 'query'] - expected) <= 1, (phase, values, expected)
    assert values['apap'] > values['baseap']
    assert values['apquery'] > values['basequery']
    assert values['spquery'] == values['apquery']
    if mode == 'sacred-grove' and 'ally_max_mana' in values:
        assert values['mana_recovery'] == int((values['ally_max_mana'] - 1000) * .03)
    print(mode, 'native AP coefficient and zero additional SP coefficient verified')
elif mode == 'stone-skin':
    assert values['active_parry'] == values['base_parry'] > 0
    assert 0 < values['rating_parry'] - values['active_parry'] < 100
    controls = {680448, 800178, 803140, 403, 302590}
    for key, baseline in values.items():
        if not key.startswith('base_') or key in ['base_parry', 'base_rating']:
            continue
        suffix = key.removeprefix('base_')
        spell = int(suffix.split('_')[0])
        assert baseline > 0
        for phase in ['active', 'rating']:
            bonus = 0 if spell in controls else values[phase + '_parry'] / 100
            expected = baseline * (1 + bonus)
            assert abs(values[phase + '_' + suffix] - expected) <= 2, (phase, key, values, expected)
        assert values['removed_' + suffix] == baseline, (key, values)
    print('Stone Skin: displayed parry gives the same damage percentage; direct/periodic families, controls and removal verified')
    print('Observed parry percentages:', values['active_parry'], values['rating_parry'])
elif mode == 'wildheart':
    expected = int((values['max_mana'] - 1000 + values['wildheart_cost']) * .05)
    assert values['mana_recovery'] == expected, (values, expected)
    print('Wildheart: five percent of missing Mana after the ordinary cast cost')
elif mode == 'ancient-war':
    for phase, percent in [('baseline', 20), ('active', 26), ('expired', 20)]:
        hit = values[phase + 'hit']
        assert hit > 0
        expected = int(hit) * percent // 100
        assert values[phase + 'heal'] == values[phase + 'copy'] == expected, (phase, values, expected)
        print(phase, hit, 'damage;', expected, 'per Hammer recipient')
elif mode == 'neptulon-wrath':
    assert values['crash_available_mana'] >= values['crash_mana_cost'] > 0
    expected = int(values['caster_ap'] * .35)
    assert expected > 0 and values['caster_ap'] != values['ally_ap']
    assert values['target_damage_taken'] == 1000
    assert values['target_resistance_3'] == values['target_resistance_4'] == 0
    scaled = int(expected * values['primalist_damage_done'] / 1000)
    for actor in ['primalist', 'ally']:
        assert values[actor + '_amount'] == expected, (actor, values, expected)
        assert min(abs(values[actor + '_hit'] - hit) for hit in [scaled, int(scaled * 1.5)]) <= 1, (actor, values)
    print('Neptulon Wrath:', expected, 'snapshotted base damage for both players; native PvE modifiers verified')
elif mode == 'sacred-grove-cap':
    recipients = [value for key, value in values.items() if key.startswith('recipient_')]
    assert len(recipients) == 13 and all(value in [0, 1] for value in recipients)
    assert sum(recipients) == 12, values
    print('Sacred Grove: exactly twelve of thirteen eligible recipients')
elif mode == 'dreamslip':
    expected = int(values['max_mana'] * .02) * 30
    assert values['total_mana_recovery'] - values['recovery_mana'] == expected, (values, expected)
    print('Dreamslip: thirty recoveries of two percent maximum Mana')
else:
    raise ValueError(mode)
