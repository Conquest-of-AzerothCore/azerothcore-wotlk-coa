NAME = 'player_spell_power'
ORDER = 2


def parse(raw) -> int:
    return raw


def fixtures(class_file: dict, spec, spell_power: int, scenario: dict):
    scenario['players'][0]['spell_power'] = spell_power
