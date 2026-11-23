NAME = 'player_ranged_attack_power'
ORDER = 2


def parse(raw) -> int:
    if isinstance(raw, bool) or not isinstance(raw, int) or raw <= 0:
        raise ValueError(f'player_ranged_attack_power is a positive ranged attack power, not {raw!r}')
    return raw


def fixtures(class_file: dict, spec, ranged_attack_power: int, scenario: dict):
    scenario['players'][0]['ranged_attack_power'] = ranged_attack_power
    scenario['contract'] += f' The caster holds {ranged_attack_power} more ranged attack power (harness fixture).'
