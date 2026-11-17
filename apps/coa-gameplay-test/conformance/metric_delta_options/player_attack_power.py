NAME = 'player_attack_power'
ORDER = 2


def parse(raw) -> int:
    if isinstance(raw, bool) or not isinstance(raw, int) or raw <= 0:
        raise ValueError(f'player_attack_power is a positive attack power, not {raw!r}')
    return raw


def fixtures(class_file: dict, spec, attack_power: int, scenario: dict):
    scenario['players'][0]['attack_power'] = attack_power
    scenario['contract'] += f' The caster holds {attack_power} more attack power (harness fixture).'
