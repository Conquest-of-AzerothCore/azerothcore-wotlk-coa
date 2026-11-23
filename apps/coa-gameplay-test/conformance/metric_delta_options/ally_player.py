from dataclasses import dataclass

NAME = 'ally_player'
ORDER = 34
MAX_POWER_INDEX = 6


@dataclass(frozen=True)
class AllyPlayer:
    player_class: int
    power: int


def parse(raw) -> AllyPlayer:
    if not isinstance(raw, dict) or set(raw) != {'class', 'power'} or type(raw['class']) is not int \
            or not 1 <= raw['class'] <= 255 or type(raw['power']) is not int \
            or not 0 <= raw['power'] <= MAX_POWER_INDEX:
        raise ValueError(f'ally_player is {{"class": a class id, "power": a power index 0..{MAX_POWER_INDEX}}}, '
                         f'not {raw!r}')
    return AllyPlayer(raw['class'], raw['power'])


def check(spec, ally: AllyPlayer | None):
    if ally is None:
        return
    from values import ALLY
    if spec.target != ALLY or spec.measure_actor != ALLY:
        raise ValueError(f'{spec.spell} ally_player casts the trigger at the ally and reads the ally')
    if spec.enemy_player_race or spec.attack_swings or spec.setup_casts or spec.trigger_item is not None:
        raise ValueError(f'{spec.spell} ally_player takes a plain cast trigger, without an enemy player, attack '
                         f'swings or setup casts')


def phase_steps(spec, ally: AllyPlayer, after: bool) -> list[dict]:
    from values import ALLY
    return [{'action': 'set_power', 'actor': ALLY, 'power': ally.power, 'value': 0}]


def fixtures(class_file: dict, spec, ally: AllyPlayer, scenario: dict):
    from profile import CASTER, base_steps, player_fixture
    from values import ALLY
    scenario['players'].append({**player_fixture(class_file), 'id': ALLY, 'class': ally.player_class,
                                'allow_regeneration': False})
    settled = len(base_steps(class_file))
    scenario['steps'][settled:settled] = [{'action': 'group', 'actor': CASTER, 'target': ALLY}]
    scenario['contract'] += (f' The target and the measured unit is a grouped ally player of class '
                             f'{ally.player_class} (regeneration off); its power {ally.power} is set to 0 at the '
                             f'start of each phase.')
