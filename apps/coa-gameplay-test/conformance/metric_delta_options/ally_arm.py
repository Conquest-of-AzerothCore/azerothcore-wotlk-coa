from dataclasses import dataclass, replace

NAME = 'ally_arm'
ORDER = 24
ALLY_IDS = ('ally', 'ally2', 'ally3', 'ally4', 'ally5')
ALLY_CAST_SETTLE_MS = 2000
KEYS = {'allies', 'ally_health', 'ally_casts', 'control_wait', 'arms'}
ARM_KEYS = {'actors', 'metric', 'fields', 'before_expected', 'expected', 'tolerance', 'source'}


@dataclass(frozen=True)
class Arm:
    actors: tuple[str, ...]
    metric: str
    fields: dict
    before_expected: float
    expected: float
    tolerance: float
    source: str


@dataclass(frozen=True)
class AllyArm:
    allies: int
    ally_health: tuple[int, int] | None
    ally_casts: tuple[int, ...]
    control_wait: bool
    arms: tuple[Arm, ...]

    @property
    def ally_ids(self) -> tuple[str, ...]:
        return ALLY_IDS[:self.allies]


def number(value) -> bool:
    return type(value) in (int, float)


def parse_arm(raw) -> Arm:
    if not isinstance(raw, dict) or not ARM_KEYS - {'fields'} <= set(raw) <= ARM_KEYS \
            or not isinstance(raw['actors'], list) or not raw['actors'] \
            or not all(isinstance(actor, str) and actor for actor in raw['actors']) \
            or len(set(raw['actors'])) != len(raw['actors']) \
            or not isinstance(raw['metric'], str) or not raw['metric'] \
            or not isinstance(raw.get('fields', {}), dict) \
            or not all(number(raw[key]) for key in ('before_expected', 'expected', 'tolerance')) \
            or raw['tolerance'] < 0 or not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError(f'an ally_arm arm is {{actors: [unit, ...], metric, fields?, before_expected, expected, '
                         f'tolerance >= 0, source: text}}, every expectation stated with its source, not {raw!r}')
    return Arm(tuple(raw['actors']), raw['metric'], dict(raw.get('fields', {})), float(raw['before_expected']),
               float(raw['expected']), float(raw['tolerance']), raw['source'])


def parse(raw) -> AllyArm:
    if not isinstance(raw, dict) or not raw or not set(raw) <= KEYS:
        raise ValueError(f'ally_arm is a non-empty object of {sorted(KEYS)}, not {raw!r}')
    allies = raw.get('allies', 1)
    health = raw.get('ally_health')
    casts = raw.get('ally_casts', [])
    if type(allies) is not int or not 1 <= allies <= len(ALLY_IDS):
        raise ValueError(f'ally_arm allies is an integer from 1 to {len(ALLY_IDS)}, not {allies!r}')
    if health is not None and (not isinstance(health, list) or len(health) != 2
                               or not all(type(value) is int for value in health) or not 1 <= health[0] <= health[1]):
        raise ValueError(f'ally_arm ally_health is [value, maximum], integers with 1 <= value <= maximum, '
                         f'not {health!r}')
    if not isinstance(casts, list) or not all(type(spell) is int and spell > 0 for spell in casts):
        raise ValueError(f'ally_arm ally_casts is a list of spell ids, not {casts!r}')
    if raw.get('control_wait', True) is not True:
        raise ValueError(f'ally_arm control_wait is true, not {raw["control_wait"]!r}')
    arms = raw.get('arms', [])
    if not isinstance(arms, list):
        raise ValueError(f'ally_arm arms is a list, not {arms!r}')
    return AllyArm(allies, tuple(health) if health is not None else None, tuple(casts),
                   'control_wait' in raw, tuple(parse_arm(arm) for arm in arms))


def check(spec, ally):
    if ally is None:
        return
    from coverage import READBACK, metric_evidence
    from profile import CASTER
    from values import TARGET
    dummy = spec.select_dummy or TARGET in (spec.target, spec.measure_actor, spec.fields.get('target'))
    units = {CASTER, *ally.ally_ids, *((TARGET,) if dummy else ())}
    for arm in ally.arms:
        unknown = sorted(set(arm.actors) - units)
        if unknown:
            raise ValueError(f'{spec.spell} ally_arm reads {unknown}, not a unit of its scenario {sorted(units)}')
        evidence = metric_evidence().get(arm.metric)
        if evidence is None or evidence == READBACK:
            raise ValueError(f'{spec.spell} ally_arm metric {arm.metric!r} needs a METRIC_EVIDENCE row that is not '
                             f'a readback, found {evidence!r}')
    if ally.control_wait and (spec.cast_in_before or spec.gate_timing != 'between' or spec.setup_only_after
                              or spec.setup_in_before or spec.attack_swings or spec.strike is not None
                              or spec.target_casts_before or spec.enemy_casts_in_before):
        raise ValueError(f'{spec.spell} ally_arm control_wait times an uncast before phase only: cast_in_before '
                         f'false, the default gate timing, no setup_only_after, setup_in_before, swings, strike, '
                         f'target casts before or enemy casts in before')


def phase_steps(spec, ally: AllyArm, after: bool) -> list[dict]:
    from profile import CASTER
    steps = [step for spell in ally.ally_casts for step in (
        {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell},
        {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': ALLY_IDS[0]},
        {'action': 'wait', 'label': f'{spell} at the ally, past the global cooldown', 'ms': ALLY_CAST_SETTLE_MS})]
    if ally.ally_health is not None:
        value, maximum = ally.ally_health
        steps += [{'action': 'set_health', 'actor': unit, 'value': value, 'maximum': maximum}
                  for unit in ally.ally_ids]
    if ally.control_wait and not after:
        steps.append({'action': 'wait', 'label': 'timed no-cast control', 'ms': spec.wait_ms})
    return steps


def arm_label(spec, moment: str, index: int, actor: str) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, moment)} ally_arm {index} {actor}'


def arm_reads(spec, ally: AllyArm, moment: str) -> list[dict]:
    from profile import measurement
    return [measurement(arm_label(spec, moment, index, actor), actor, arm.metric, **arm.fields)
            for index, arm in enumerate(ally.arms) for actor in arm.actors]


def fixtures(class_file: dict, spec, ally: AllyArm, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, base_steps, player_fixture
    players = scenario['players']
    for unit in ally.ally_ids:
        players.append({**player_fixture(class_file), 'id': unit,
                        **({'allow_regeneration': False} if spec.disable_regeneration else {})})
    steps = scenario['steps']
    settled = len(base_steps(class_file))
    steps[settled:settled] = [{'action': 'group', 'actor': CASTER, 'target': unit} for unit in ally.ally_ids]
    for moment in ('after', 'before'):
        read = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, moment))
        steps[read + 1:read + 1] = arm_reads(spec, ally, moment)
    contract = (f' {ally.allies} grouped ally player(s) {list(ally.ally_ids)} stand with the caster'
                + (', regeneration off' if spec.disable_regeneration else '') + '.')
    if ally.ally_casts:
        contract += (f' Each phase first casts {list(ally.ally_casts)} at {ALLY_IDS[0]}, waiting '
                     f'{ALLY_CAST_SETTLE_MS} ms after each.')
    if ally.ally_health is not None:
        contract += f' Each phase sets the allies\' health to {ally.ally_health[0]} of {ally.ally_health[1]}.'
    if ally.control_wait:
        contract += (f' The uncast before phase waits {spec.wait_ms} ms, the after phase\'s wait, before its '
                     f'reading (timed no-cast control).')
    for index, arm in enumerate(ally.arms):
        contract += (f' Arm {index}: {arm.metric} {arm.fields} summed over {list(arm.actors)}, read right after each '
                     f'main reading, expected {arm.before_expected:g} then {arm.expected:g} within '
                     f'{arm.tolerance:g} ({arm.source}).')
    scenario['contract'] += contract


def model(spec, ally: AllyArm) -> dict:
    return {NAME: {'allies': list(ally.ally_ids), 'arms': [
        {'metric': arm.metric, 'before_expected': arm.before_expected, 'expected': arm.expected,
         'tolerance': arm.tolerance, 'source': arm.source,
         'before': [arm_label(spec, 'before', index, actor) for actor in arm.actors],
         'after': [arm_label(spec, 'after', index, actor) for actor in arm.actors]}
        for index, arm in enumerate(ally.arms)]}}


def verdict(verdict, run, ally: dict):
    if not ally['arms'] or verdict.status == 'unmeasured':
        return verdict
    texts = []
    off = False
    for index, arm in enumerate(ally['arms']):
        missing = next((label for label in (*arm['before'], *arm['after']) if run.values.get(label) is None), None)
        if missing is not None:
            return replace(verdict, status='unmeasured',
                           explanation=f'{verdict.explanation}; ally arm {index}: {missing} was not read')
        before = sum(run.values[label] for label in arm['before'])
        after = sum(run.values[label] for label in arm['after'])
        held = (abs(before - arm['before_expected']) <= arm['tolerance']
                and abs(after - arm['expected']) <= arm['tolerance'])
        off = off or not held
        texts.append(f'ally arm {index} {arm["metric"]}: {before:g} before (expected {arm["before_expected"]:g}) '
                     f'and {after:g} after (expected {arm["expected"]:g}), within {arm["tolerance"]:g}: '
                     f'{"ok" if held else "off"} ({arm["source"]})')
    explanation = '; '.join([verdict.explanation, *texts])
    return replace(verdict, status='alert' if off else verdict.status, explanation=explanation)
