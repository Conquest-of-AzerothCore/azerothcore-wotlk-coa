from dataclasses import dataclass

NAME = 'grouped_ally'
ORDER = 35
MAXIMUM_OFFSET_YD = 20


@dataclass(frozen=True)
class GroupedAlly:
    dy: float
    grouped: bool


def parse(raw) -> GroupedAlly:
    valid = (isinstance(raw, dict) and set(raw) == {'dy', 'grouped'} and type(raw['grouped']) is bool
             and type(raw['dy']) in (int, float) and 0 < abs(raw['dy']) <= MAXIMUM_OFFSET_YD)
    if not valid:
        raise ValueError(f'grouped_ally is {{"dy": yd, nonzero and at most {MAXIMUM_OFFSET_YD} either way, '
                         f'"grouped": bool}}, not {raw!r}')
    return GroupedAlly(float(raw['dy']), raw['grouped'])


def check(spec, ally):
    if ally is None:
        return
    from values import ALLY
    if spec.enemy_player_race or spec.target == ALLY:
        raise ValueError(f'{spec.spell} grouped_ally adds a second friendly player beside the caster; it is no cast '
                         f'target and no enemy player scenario')


def fixtures(class_file: dict, spec, ally: GroupedAlly, scenario: dict):
    from profile import CASTER, base_steps, player_fixture
    from values import ALLY
    scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    settled = len(base_steps(class_file))
    steps = [{'action': 'relocate', 'actor': ALLY, 'dy': ally.dy}]
    if ally.grouped:
        steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
    scenario['steps'][settled:settled] = steps
    scenario['contract'] += (f' A second player of the caster\'s race and class stands {ally.dy:g} yd beside the '
                             f'caster on the y axis, ' + ('grouped with the caster.' if ally.grouped
                                                          else 'not grouped with the caster.'))
