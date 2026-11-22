import math
from dataclasses import dataclass, replace

NAME = 'ally_interact'
ORDER = 27
ACTOR = 'ally'
SETTLE_MS = 1500
REFUSED_SHARE = 0.9
ACCEPTED_SHARE = 1.1
MOMENTS = ('before', 'after')
READS = ('start x', 'start y', 'start o', 'end x', 'end y')
DEFAULT_BEARING_TOLERANCE = 15.0
MINIMUM_YD = 1.0
FIRST_LABEL = 'ally interact first'
REFUSED_LABEL = 'ally interact refused'
ACCEPTED_LABEL = 'ally interact accepted'
BLINK_LABEL = 'ally interact'
LOCKOUT_WAIT_LABEL = 'ally lockout wait'
RELOCATE_STEP_YD = 20.0
RECORD_LABEL = 'record'


@dataclass(frozen=True)
class AllyInteract:
    entry: int
    lockout_aura: int | None = None
    return_yd: float | None = None
    bearing: float | None = None
    bearing_tolerance: float = DEFAULT_BEARING_TOLERANCE
    judged_spell: int | None = None


def number(raw, key: str) -> float:
    if isinstance(raw, bool) or not isinstance(raw, (int, float)) or not math.isfinite(raw):
        raise ValueError(f'ally_interact {key} is a finite number, not {raw!r}')
    return float(raw)


def parse(raw) -> AllyInteract:
    keys = {'entry', 'lockout_aura', 'return_yd', 'bearing', 'bearing_tolerance', 'judged_spell'}
    if not isinstance(raw, dict) or not set(raw) <= keys or isinstance(raw.get('entry'), bool) \
            or not isinstance(raw.get('entry'), int) or raw['entry'] <= 0:
        raise ValueError(f'ally_interact is {{"entry": creature, "lockout_aura"?, "return_yd"?, "bearing"?, '
                         f'"bearing_tolerance"?, "judged_spell"?}}, not {raw!r}')
    lockout = raw.get('lockout_aura')
    if lockout is not None and (isinstance(lockout, bool) or not isinstance(lockout, int) or lockout <= 0):
        raise ValueError(f'ally_interact lockout_aura is a spell id, not {lockout!r}')
    if (lockout is None) != ('return_yd' not in raw) or (lockout is not None and 'bearing' in raw):
        raise ValueError('ally_interact lockout_aura and return_yd go together, and bearing only without them')
    judged = raw.get('judged_spell')
    if 'judged_spell' in raw and (lockout is None or isinstance(judged, bool) or not isinstance(judged, int)
                                  or judged <= 0 or judged == lockout):
        raise ValueError(f'ally_interact judged_spell is a spell id other than the lockout aura, with it, not '
                         f'{judged!r}')
    if 'bearing_tolerance' in raw and 'bearing' not in raw:
        raise ValueError('ally_interact bearing_tolerance needs a bearing')
    value = AllyInteract(raw['entry'], lockout, judged_spell=judged)
    if lockout is not None:
        distance = number(raw['return_yd'], 'return_yd')
        if not 0 < distance <= 2 * RELOCATE_STEP_YD:
            raise ValueError(f'ally_interact return_yd {distance:g} lies in (0, {2 * RELOCATE_STEP_YD:g}]')
        value = replace(value, return_yd=distance)
    if 'bearing' in raw:
        bearing = number(raw['bearing'], 'bearing')
        tolerance = number(raw.get('bearing_tolerance', DEFAULT_BEARING_TOLERANCE), 'bearing_tolerance')
        if not -180 < bearing <= 180 or not 0 < tolerance < 90:
            raise ValueError(f'ally_interact bearing {bearing:g} lies in (-180, 180] and its tolerance '
                             f'{tolerance:g} in (0, 90)')
        value = replace(value, bearing=bearing, bearing_tolerance=tolerance)
    return value


def lockout(value: AllyInteract) -> bool:
    return value.lockout_aura is not None


def judged_spell(value: AllyInteract) -> int | None:
    return value.lockout_aura if value.judged_spell is None else value.judged_spell


def record_label(spec, value: AllyInteract, moment: str) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, moment)} {ACTOR} {RECORD_LABEL} {value.lockout_aura}'


def check(spec, value):
    if value is None:
        return
    from metric_delta_options.ally_arm import NAME as ALLY_ARM
    from profile import CASTER
    ally = dict(spec.options).get(ALLY_ARM)
    if ally is None or ACTOR not in ally.ally_ids or spec.target != CASTER or spec.measure_actor != ACTOR \
            or spec.attack_swings or spec.setup_casts:
        raise ValueError(f'{spec.spell} ally_interact needs a grouped {ACTOR} as the measured actor, a self-cast '
                         f'trigger, no setup casts and no swings')
    if lockout(value) and (not spec.cast_in_before or spec.cast_power is None or spec.metric != 'aura_apply_count'
                           or spec.fields != {'spell': judged_spell(value)}):
        raise ValueError(f'{spec.spell} ally_interact lockout casts in both phases with cast_power and reads the '
                         f'{ACTOR}\'s aura_apply_count of {judged_spell(value)}')
    if not lockout(value) and (spec.cast_in_before or spec.metric != 'position_x' or spec.fields):
        raise ValueError(f'{spec.spell} ally_interact blink casts in the after phase only and reads the {ACTOR}\'s '
                         f'position_x without fields')


def gossip(value: AllyInteract, label: str) -> dict:
    return {'action': 'gossip_hello', 'label': label, 'actor': ACTOR, 'entry': value.entry}


def relocated(actor: str, distance: float) -> list[dict]:
    steps, left = [], distance
    while left > 0:
        chunk = min(left, RELOCATE_STEP_YD)
        steps.append({'action': 'relocate', 'actor': actor, 'dx': -chunk})
        left -= chunk
    return steps


def phase_steps(spec, value: AllyInteract, after: bool) -> list[dict]:
    from profile import CASTER
    if not lockout(value) or after:
        return []
    return ([{'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': spec.cast_power},
             {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
             {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': CASTER},
             {'action': 'wait', 'label': 'first gate', 'ms': SETTLE_MS}, gossip(value, FIRST_LABEL),
             {'action': 'wait', 'label': 'first blink', 'ms': SETTLE_MS}]
            + relocated(CASTER, value.return_yd) + relocated(ACTOR, value.return_yd)
            + [{'action': 'wait', 'label': LOCKOUT_WAIT_LABEL, 'ms': 0}])


def after_trigger_steps(spec, value: AllyInteract, after: bool) -> list[dict]:
    from profile import CASTER
    steps = [{'action': 'wait', 'label': 'gate', 'ms': SETTLE_MS}]
    if not lockout(value):
        return steps + [gossip(value, BLINK_LABEL)] if after else []
    if after:
        return steps + [gossip(value, ACCEPTED_LABEL)]
    return steps + [gossip(value, REFUSED_LABEL), {'action': 'wait', 'label': 'refused blink', 'ms': SETTLE_MS}] \
        + relocated(CASTER, value.return_yd)


def labels(spec, moment: str) -> dict[str, str]:
    from behaviours import metric_delta_label
    base = metric_delta_label(spec, moment)
    return {read: f'{base} {ACTOR} {read}' for read in READS}


def lockout_duration_ms(class_file: dict, aura: int) -> int:
    from pathlib import Path
    from profile import DBC_DIR
    from tooltip import Records
    from values import dataset
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    index = int(records.field('Spell', aura, 'DurationIndex'))
    duration = int(records.field('SpellDuration', index, 'Duration')) if index else 0
    if duration <= 0:
        raise ValueError(f'ally_interact lockout aura {aura} has no duration in the DBC')
    return duration


def waited_between(steps: list[dict], first: int, last: int) -> int:
    return sum(step['ms'] for step in steps[first:last] if step['action'] == 'wait')


def lockout_fixtures(class_file: dict, spec, value: AllyInteract, scenario: dict):
    steps = scenario['steps']
    duration = lockout_duration_ms(class_file, value.lockout_aura)
    refused_ms, accepted_ms = round(duration * REFUSED_SHARE), round(duration * ACCEPTED_SHARE)
    index = {label: next(i for i, step in enumerate(steps) if step.get('label') == label)
             for label in (FIRST_LABEL, LOCKOUT_WAIT_LABEL, REFUSED_LABEL, ACCEPTED_LABEL)}
    steps[index[LOCKOUT_WAIT_LABEL]]['ms'] = refused_ms - waited_between(steps, index[FIRST_LABEL],
                                                                         index[REFUSED_LABEL])
    if steps[index[LOCKOUT_WAIT_LABEL]]['ms'] <= 0:
        raise ValueError(f'{spec.spell} ally_interact lockout {duration} ms leaves no wait before the refused try')
    gap = waited_between(steps, index[REFUSED_LABEL], index[ACCEPTED_LABEL])
    if gap != accepted_ms - refused_ms:
        raise ValueError(f'{spec.spell} ally_interact waits {gap} ms between the refused and the accepted try, not '
                         f'{accepted_ms - refused_ms}: set expire_ms {spec.expire_ms + accepted_ms - refused_ms - gap}')
    if value.judged_spell is not None:
        record_lockout(spec, value, scenario)
    scenario['contract'] += (
        f' The grouped {ACTOR} stands at the gate the caster leaves ({value.entry}) and interacts with it (native '
        f'gossip_hello within the interaction distance, no walk): first after a Sun Gate cast at the start of the '
        f'before phase, then {refused_ms} ms later at a new gate ({REFUSED_SHARE:g} of the {duration} ms lockout '
        f'aura {value.lockout_aura}, DBC duration: refused), then {accepted_ms} ms after the first ({ACCEPTED_SHARE:g} '
        f'of it: accepted). After each blink the caster and the {ACTOR} are moved back {value.return_yd:g} yd along '
        f'x, so each new gate stands where the {ACTOR} is.')


def record_lockout(spec, value: AllyInteract, scenario: dict):
    from behaviours import metric_delta_label
    from profile import measurement
    steps = scenario['steps']
    for moment in MOMENTS:
        read = next(i for i, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, moment))
        steps.insert(read, measurement(record_label(spec, value, moment), ACTOR, 'aura_apply_count',
                                       spell=value.lockout_aura))
    scenario['contract'] += (
        f' The judged count is the {ACTOR}\'s {value.judged_spell} applications; its lockout aura '
        f'{value.lockout_aura} application count is read beside each reading and recorded, never judged.')


def blink_fixtures(spec, value: AllyInteract, scenario: dict):
    from behaviours import metric_delta_label
    from profile import measurement
    steps = scenario['steps']
    marks = {}
    for moment in MOMENTS:
        read = next(i for i, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, moment))
        interact = [i for i, step in enumerate(steps[:read]) if step.get('label') == BLINK_LABEL]
        if moment == 'after' and len(interact) != 1:
            raise ValueError(f'{spec.spell} ally_interact finds {len(interact)} interactions in the after phase')
        begin = interact[0] if moment == 'after' else read
        names = labels(spec, moment)
        marks.setdefault(begin, []).extend(
            measurement(names[f'start {axis}'], ACTOR, f'position_{axis}') for axis in ('x', 'y', 'o'))
        marks.setdefault(read, []).extend(
            measurement(names[f'end {axis}'], ACTOR, f'position_{axis}') for axis in ('x', 'y'))
    scenario['steps'] = [step for index, step in enumerate(steps) for step in (*marks.get(index, ()), step)]
    scenario['contract'] += (
        f' After the after phase\'s cast, the grouped {ACTOR} interacts with the gate {value.entry} the caster leaves '
        f'(native gossip_hello within the interaction distance, no walk). The judged readings are the {ACTOR}\'s 2D '
        f'displacement: its position is read right before the interaction (right before the reading in the before '
        f'phase, which casts nothing) and right before the reading.'
        + (f' The treatment displacement must point {value.bearing:g} degrees from the {ACTOR}\'s facing at its start, '
           f'within {value.bearing_tolerance:g} degrees, and be at least {MINIMUM_YD:g} yd long.'
           if value.bearing is not None else ''))


def fixtures(class_file: dict, spec, value: AllyInteract, scenario: dict):
    from hits import MAX_ACCELERATED_SCENARIO_MS, timed
    if lockout(value):
        lockout_fixtures(class_file, spec, value, scenario)
    else:
        blink_fixtures(spec, value, scenario)
    scenario.pop('timeout_ms', None)
    timed(scenario, sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait'),
          MAX_ACCELERATED_SCENARIO_MS)


def model(spec, value: AllyInteract) -> dict:
    if lockout(value):
        if value.judged_spell is None:
            return {NAME: {'lockout_aura': value.lockout_aura}}
        return {NAME: {'lockout_aura': value.lockout_aura, 'judged_spell': value.judged_spell,
                       'recorded': {moment: record_label(spec, value, moment) for moment in MOMENTS}}}
    shift = {moment: labels(spec, moment) for moment in MOMENTS}
    shift['judged'] = {moment: f'{spec.spell} {spec.metric} {moment}' for moment in MOMENTS}
    if value.bearing is not None:
        shift.update(bearing=value.bearing, bearing_tolerance=value.bearing_tolerance)
    return {NAME: shift, 'evidence_metric': 'displacement_2d'}


def moved(values: dict, names: dict) -> tuple[float, float, float] | None:
    found = [values.get(names[read]) for read in READS]
    if any(reading is None for reading in found):
        return None
    x, y, facing, end_x, end_y = found
    return end_x - x, end_y - y, facing


def run_values(values: dict, shift: dict) -> dict:
    if 'judged' not in shift:
        return values
    out = dict(values)
    for moment in MOMENTS:
        found = moved(values, shift[moment])
        out.pop(shift['judged'][moment], None)
        if found is not None:
            out[shift['judged'][moment]] = math.hypot(found[0], found[1])
    return out


def verdict(verdict, run, shift: dict):
    from metric_delta_options.displacement import bearing_of
    if 'bearing' not in shift or verdict.status == 'unmeasured':
        return verdict
    found = moved(run.values, shift['after'])
    if found is None:
        return verdict
    dx, dy, facing = found
    length = math.hypot(dx, dy)
    if length < MINIMUM_YD:
        return replace(verdict, status='alert', explanation=f'{verdict.explanation}; the {ACTOR}\'s displacement of '
                                                            f'{length:.3g} yd is too short to show a direction')
    angle = bearing_of(dx, dy, facing)
    off = abs((angle - shift['bearing'] + 180.0) % 360.0 - 180.0)
    text = (f'{verdict.explanation}; {ACTOR} displacement {length:.3g} yd at {angle:.1f} degrees from its start '
            f'facing (stated {shift["bearing"]:g}, within {shift["bearing_tolerance"]:g})')
    return replace(verdict, status=verdict.status if off <= shift['bearing_tolerance'] else 'alert', explanation=text)
