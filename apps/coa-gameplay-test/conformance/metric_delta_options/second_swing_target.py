import re

NAME = 'second_swing_target'
ORDER = 7
AREA_ID = re.compile(r'area[1-9]')
SWINGS_LABEL = 'swings'
SECOND_SWINGS_LABEL = 'second target swings'


def parse(raw) -> str:
    if not isinstance(raw, str) or not AREA_ID.fullmatch(raw):
        raise ValueError(f'second_swing_target names an area dummy (area1 to area9), not {raw!r}')
    return raw


def check(spec, target):
    if target is None:
        return
    from metric_delta_options.area_dummies import NAME as AREA_DUMMIES
    distances = dict(spec.options).get(AREA_DUMMIES)
    if not spec.attack_swings or spec.gate_cast or distances is None or int(target[4:]) > len(distances):
        raise ValueError(f'{spec.spell} second_swing_target {target} needs attack swings at the dummy, no gate cast '
                         f'and that area dummy in area_dummies')


def fixtures(class_file: dict, spec, target: str, scenario: dict):
    from behaviours import CASTER, TARGET
    creatures = {creature['id']: creature for creature in scenario['creatures']}
    if creatures[target]['distance'] != creatures[TARGET]['distance']:
        raise ValueError(f'{spec.spell} second_swing_target {target} stands at {creatures[target]["distance"]:g} yd, '
                         f'not at the dummy\'s {creatures[TARGET]["distance"]:g} yd melee placement')
    steps = scenario['steps']
    blocks = [index for index in range(len(steps) - 2)
              if steps[index] == {'action': 'attack', 'actor': CASTER, 'target': TARGET}
              and steps[index + 1].get('label') == SWINGS_LABEL
              and steps[index + 2] == {'action': 'stop_attack', 'actor': CASTER}]
    if len(blocks) != 2:
        raise ValueError(f'{spec.spell} second_swing_target finds {len(blocks)} attack phases, not 2')
    for index in reversed(blocks):
        wait = steps[index + 1]['ms']
        steps[index + 3:index + 3] = [{'action': 'attack', 'actor': CASTER, 'target': target},
                                      {'action': 'wait', 'label': SECOND_SWINGS_LABEL, 'ms': wait},
                                      {'action': 'stop_attack', 'actor': CASTER}]
    from hits import timed
    scenario.pop('timeout_ms', None)
    timed(scenario, sum(step['ms'] for step in steps if step['action'] == 'wait'))
    wait = steps[blocks[0] + 1]['ms']
    scenario['contract'] += (f' In each phase, after the swings at the dummy, the caster stops attacking and attacks '
                             f'{target} (a copy of the dummy at its distance) for the same {wait} ms, then stops.')


def model(spec, target: str) -> dict:
    return {NAME: target}
