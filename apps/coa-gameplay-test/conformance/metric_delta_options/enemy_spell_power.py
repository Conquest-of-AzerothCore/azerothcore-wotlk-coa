NAME = 'enemy_spell_power'
ORDER = 27


def parse(raw) -> int:
    if type(raw) is not int or raw <= 0:
        raise ValueError(f'enemy_spell_power is a positive spell power, not {raw!r}')
    return raw


def check(spec, value):
    if value is not None and not spec.enemy_player_race:
        raise ValueError(f'{spec.spell} enemy_spell_power needs the enemy player of enemy_player_race')


def fixtures(class_file: dict, spec, amount: int, scenario: dict):
    from behaviours import ENEMY_PLAYER
    enemy = next(player for player in scenario['players'] if player['id'] == ENEMY_PLAYER)
    enemy['spell_power'] = amount
    scenario['contract'] += (f' The enemy player is given {amount} spell power (the harness spell_power fixture), so '
                             f'a reduction of its spell power is read above the floor of 0.')
