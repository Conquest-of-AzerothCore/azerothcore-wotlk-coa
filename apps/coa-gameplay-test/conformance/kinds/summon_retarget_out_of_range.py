from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, describe_failures, failure_reasons, missing_measurement
from hits import MAX_SCENARIO_MS, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_ENTRY, Expectation, TARGET, dataset

KIND = 'summon_retarget_out_of_range'
ORDER = 62
METRIC = 'aura'
SECONDARY = 'area1'
CONTROL, TREATMENT = 'control', 'treatment'
ARMS = (CONTROL, TREATMENT)
MAX_MOVE_YD = 100.0
FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'trigger_spell', 'entry', 'effect_aura',
          'primary_dx', 'primary_dy', 'secondary_dx', 'secondary_dy', 'move_dx', 'move_dy', 'max_range_yd',
          'secondary_max_range_yd', 'speed_aura', 'initial_wait_ms', 'pre_pulse_wait_ms', 'post_pulse_wait_ms',
          'expire_wait_ms', 'cast_power', 'dummy_entry', 'learn', 'observe_source'}


@dataclass(frozen=True)
class SummonRetargetSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    entry: int
    effect_aura: int
    primary_dx: float
    primary_dy: float
    secondary_dx: float
    secondary_dy: float
    move_dx: float
    move_dy: float
    max_range_yd: float
    secondary_max_range_yd: float
    speed_aura: int | None
    initial_wait_ms: int
    pre_pulse_wait_ms: int
    post_pulse_wait_ms: int
    expire_wait_ms: int
    cast_power: int | None
    dummy_entry: int
    learn: tuple[int, ...]
    label_suffix: str = KIND


def summon_retarget_spec(entry: dict) -> SummonRetargetSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry.get("spell")} {KIND} unknown fields: {sorted(unknown)}')
    spell = int(entry['spell'])
    trigger_spell = int(entry.get('trigger_spell', spell))
    summon_entry = int(entry['entry'])
    effect_aura = int(entry['effect_aura'])
    primary_dx = float(entry.get('primary_dx', 3.0))
    primary_dy = float(entry.get('primary_dy', 0.0))
    secondary_dx = float(entry.get('secondary_dx', 3.0))
    secondary_dy = float(entry.get('secondary_dy', 8.0))
    move_dx = float(entry['move_dx'])
    move_dy = float(entry.get('move_dy', 0.0))
    max_range_yd = float(entry['max_range_yd'])
    secondary_max_range_yd = float(entry['secondary_max_range_yd'])
    speed_raw = entry.get('speed_aura')
    speed_aura = int(speed_raw) if speed_raw is not None else None
    initial_wait_ms = entry.get('initial_wait_ms', 300)
    pre_pulse_wait_ms = entry['pre_pulse_wait_ms']
    post_pulse_wait_ms = entry['post_pulse_wait_ms']
    expire_wait_ms = entry['expire_wait_ms']
    cast_power_raw = entry.get('cast_power')
    cast_power = int(cast_power_raw) if cast_power_raw is not None else None
    dummy_entry = int(entry.get('dummy_entry', DUMMY_ENTRY))
    learn = tuple(int(s) for s in entry.get('learn', ()))
    if summon_entry < 1 or effect_aura < 1 or dummy_entry < 1:
        raise ValueError(f'{spell} {KIND} needs positive entry, effect_aura and dummy_entry')
    if speed_aura is not None and speed_aura < 1:
        raise ValueError(f'{spell} {KIND} speed_aura must be a positive spell id')
    if cast_power is not None and cast_power < 0:
        raise ValueError(f'{spell} {KIND} cast_power must be non-negative')
    if max_range_yd <= 0.0 or secondary_max_range_yd <= 0.0:
        raise ValueError(f'{spell} {KIND} range bounds must be positive')
    if math.hypot(primary_dx, primary_dy) > MAX_MOVE_YD or math.hypot(secondary_dx, secondary_dy) > MAX_MOVE_YD:
        raise ValueError(f'{spell} {KIND} creature spawn offsets exceed {MAX_MOVE_YD:g} yd')
    if (primary_dx, primary_dy) == (secondary_dx, secondary_dy):
        raise ValueError(f'{spell} {KIND} primary and secondary creatures must not share a position')
    if not -MAX_MOVE_YD <= move_dx <= MAX_MOVE_YD or not -MAX_MOVE_YD <= move_dy <= MAX_MOVE_YD:
        raise ValueError(f'{spell} {KIND} move_dx and move_dy must lie in [-{MAX_MOVE_YD:g}, {MAX_MOVE_YD:g}]')
    if math.hypot(move_dx, move_dy) <= max_range_yd:
        raise ValueError(f'{spell} {KIND} move distance must exceed max_range_yd ({max_range_yd:g})')
    if math.hypot(secondary_dx - primary_dx, secondary_dy - primary_dy) >= secondary_max_range_yd:
        raise ValueError(f'{spell} {KIND} secondary enemy must start inside secondary_max_range_yd of primary')
    for field_name, ms in (('initial_wait_ms', initial_wait_ms), ('pre_pulse_wait_ms', pre_pulse_wait_ms),
                           ('post_pulse_wait_ms', post_pulse_wait_ms), ('expire_wait_ms', expire_wait_ms)):
        if not isinstance(ms, int) or isinstance(ms, bool) or ms < 100:
            raise ValueError(f'{spell} {KIND} {field_name} must be an int >= 100, not {ms!r}')
    return SummonRetargetSpec(spell, entry['name'], entry['quote'], trigger_spell, summon_entry, effect_aura,
                              primary_dx, primary_dy, secondary_dx, secondary_dy, move_dx, move_dy, max_range_yd,
                              secondary_max_range_yd, speed_aura, initial_wait_ms, pre_pulse_wait_ms,
                              post_pulse_wait_ms, expire_wait_ms, cast_power, dummy_entry, learn,
                              entry.get('label_suffix', KIND))


def retarget_mark(spec: SummonRetargetSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def snapshot_reads(spec: SummonRetargetSpec, prefix: str) -> tuple[list[dict], dict[str, str]]:
    labels = {
        'summon_count': retarget_mark(spec, f'{prefix} summon_count'),
        'primary_aura': retarget_mark(spec, f'{prefix} primary_aura'),
        'secondary_aura': retarget_mark(spec, f'{prefix} secondary_aura'),
        'secondary_combat': retarget_mark(spec, f'{prefix} secondary_combat'),
        'primary_dist': retarget_mark(spec, f'{prefix} primary_dist'),
        'secondary_dist': retarget_mark(spec, f'{prefix} secondary_dist'),
    }
    steps = [
        measurement(labels['summon_count'], CASTER, 'owned_creature_count', entry=spec.entry),
        measurement(labels['primary_aura'], TARGET, 'aura', spell=spec.effect_aura),
        measurement(labels['secondary_aura'], SECONDARY, 'aura', spell=spec.effect_aura),
        measurement(labels['secondary_combat'], SECONDARY, 'combat'),
        measurement(labels['primary_dist'], CASTER, 'owned_creature_distance_2d', entry=spec.entry, target=TARGET),
        measurement(labels['secondary_dist'], CASTER, 'owned_creature_distance_2d', entry=spec.entry, target=SECONDARY),
    ]
    return steps, labels


def summon_retarget_scenario(class_file: dict, spec: SummonRetargetSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    learned = tuple(dict.fromkeys((*spec.learn, spec.trigger_spell)))
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': s} for s in learned]

    def summon_setup() -> list[dict]:
        part = []
        if spec.speed_aura is not None:
            part.append({'action': 'set_aura', 'actor': CASTER, 'target': TARGET, 'spell': spec.speed_aura,
                         'stacks': 1})
        part.append({'action': 'creature_attack', 'actor': SECONDARY, 'target': CASTER})
        if spec.cast_power is not None:
            part.append({'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': spec.cast_power})
        part.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
        part.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET})
        part.append({'action': 'wait', 'label': 'initial apply', 'ms': spec.initial_wait_ms})
        return part

    ctrl_init_steps, ctrl_init = snapshot_reads(spec, 'control initial')
    ctrl_end_steps, ctrl_end = snapshot_reads(spec, 'control end')
    between_labels = {
        'summon_count': retarget_mark(spec, 'between summon_count'),
        'primary_aura': retarget_mark(spec, 'between primary_aura'),
        'secondary_aura': retarget_mark(spec, 'between secondary_aura'),
    }
    between_steps = [
        {'action': 'wait', 'label': 'expire between arms', 'ms': spec.expire_wait_ms},
        measurement(between_labels['summon_count'], CASTER, 'owned_creature_count', entry=spec.entry),
        measurement(between_labels['primary_aura'], TARGET, 'aura', spell=spec.effect_aura),
        measurement(between_labels['secondary_aura'], SECONDARY, 'aura', spell=spec.effect_aura),
    ]
    treat_init_steps, treat_init = snapshot_reads(spec, 'treatment initial')
    treat_mid_steps, treat_mid = snapshot_reads(spec, 'treatment mid')
    treat_end_steps, treat_end = snapshot_reads(spec, 'treatment end')
    move_step = {'action': 'move_point', 'actor': TARGET, 'dx': spec.move_dx}
    if spec.move_dy != 0.0:
        move_step['dy'] = spec.move_dy
    steps += (
        summon_setup()
        + ctrl_init_steps
        + [{'action': 'wait', 'label': 'control hold', 'ms': spec.pre_pulse_wait_ms + spec.post_pulse_wait_ms}]
        + ctrl_end_steps
        + between_steps
        + summon_setup()
        + treat_init_steps
        + [move_step, {'action': 'wait', 'label': 'run out of range', 'ms': spec.pre_pulse_wait_ms}]
        + treat_mid_steps
        + [{'action': 'wait', 'label': 'retarget pulse', 'ms': spec.post_pulse_wait_ms}]
        + treat_end_steps
    )
    base_creature = {k: v for k, v in creature_fixture(class_file).items() if k != 'distance'}
    primary = {**base_creature, 'id': TARGET, 'entry': spec.dummy_entry,
               'dx': spec.primary_dx, 'dy': spec.primary_dy, 'stationary': False}
    secondary = {**base_creature, 'id': SECONDARY, 'entry': spec.dummy_entry,
                 'dx': spec.secondary_dx, 'dy': spec.secondary_dy, 'stationary': True}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon retarget',
        'contract': (f'Two enemies stand near caster: movable {TARGET} at ({spec.primary_dx:g}, {spec.primary_dy:g}) '
                     f'and stationary {SECONDARY} at ({spec.secondary_dx:g}, {spec.secondary_dy:g}) engaged in combat '
                     f'with caster via creature_attack. Both arms apply speed_aura {spec.speed_aura} symmetrically to '
                     f'{TARGET} and cast {spec.trigger_spell} at {TARGET}, summoning {spec.entry} and applying aura '
                     f'{spec.effect_aura} to {TARGET} while {SECONDARY} starts at 0. Control keeps {TARGET} within '
                     f'{spec.max_range_yd:g} yd across {spec.initial_wait_ms + spec.pre_pulse_wait_ms + spec.post_pulse_wait_ms} '
                     f'ms and requires {SECONDARY} aura {spec.effect_aura} == 0. After despawn cleanup, treatment '
                     f'orders move_point ({spec.move_dx:g}, {spec.move_dy:g}) on {TARGET}, verifies {TARGET} exceeds '
                     f'{spec.max_range_yd:g} yd from {spec.entry} while {spec.entry} lives, and requires {SECONDARY} '
                     f'aura {spec.effect_aura} == 1 after the retarget window.'),
        'players': [player_fixture(class_file)],
        'creatures': [primary, secondary],
        'steps': steps,
    }
    model = {
        'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'trigger_spell': spec.trigger_spell,
        'entry': spec.entry, 'effect_aura': spec.effect_aura, 'max_range_yd': spec.max_range_yd,
        'secondary_max_range_yd': spec.secondary_max_range_yd,
        'control': {'initial': ctrl_init, 'end': ctrl_end},
        'between': between_labels,
        'treatment': {'initial': treat_init, 'mid': treat_mid, 'end': treat_end},
    }
    expectation = Expectation(retarget_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell,
                              None, f'{SECONDARY} aura {spec.effect_aura}: control 0, treatment 1',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def check_initial(values: dict[str, float], snap: dict[str, str], max_range: float, sec_range: float,
                  label: str) -> str | None:
    if values[snap['summon_count']] != 1.0:
        return f'{label} summon_count was {values[snap["summon_count"]]:g}, expected 1'
    if values[snap['primary_aura']] != 1.0:
        return f'{label} primary aura was {values[snap["primary_aura"]]:g}, expected 1'
    if values[snap['secondary_aura']] != 0.0:
        return f'{label} secondary aura started at {values[snap["secondary_aura"]]:g}, expected 0'
    if values[snap['secondary_combat']] != 1.0:
        return f'{label} secondary combat was {values[snap["secondary_combat"]]:g}, expected 1'
    if values[snap['primary_dist']] > max_range:
        return f'{label} primary distance {values[snap["primary_dist"]]:.2f} yd exceeded {max_range:g} yd'
    if values[snap['secondary_dist']] > sec_range:
        return f'{label} secondary distance {values[snap["secondary_dist"]]:.2f} yd exceeded {sec_range:g} yd'
    return None


def summon_retarget_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    snapshots = (model['control']['initial'], model['control']['end'], model['between'],
                 model['treatment']['initial'], model['treatment']['mid'], model['treatment']['end'])
    all_labels = [lbl for snap in snapshots for lbl in snap.values()]
    missing = next((lbl for lbl in all_labels if run.values.get(lbl) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    failures = failure_reasons(run, int(model['trigger_spell']))
    if failures:
        return replace(base, status='unmeasured',
                       explanation=f'trigger cast refused ({describe_failures(failures)})')
    values = run.values
    max_range = float(model['max_range_yd'])
    sec_range = float(model['secondary_max_range_yd'])
    for name, snap in (('control initial', model['control']['initial']),
                       ('treatment initial', model['treatment']['initial'])):
        problem = check_initial(values, snap, max_range, sec_range, name)
        if problem is not None:
            return replace(base, status='unmeasured', explanation=problem)
    between = model['between']
    for key in ('summon_count', 'primary_aura', 'secondary_aura'):
        if values[between[key]] != 0.0:
            return replace(base, status='unmeasured',
                           explanation=f'between-arm cleanup left {key} = {values[between[key]]:g}, expected 0')
    ctrl_end = model['control']['end']
    if values[ctrl_end['summon_count']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'control end summon_count was {values[ctrl_end["summon_count"]]:g}, expected 1')
    if values[ctrl_end['primary_dist']] > max_range:
        return replace(base, status='unmeasured',
                       explanation=f'control primary drifted to {values[ctrl_end["primary_dist"]]:.2f} yd > {max_range:g}')
    if values[ctrl_end['secondary_dist']] > sec_range or values[ctrl_end['secondary_combat']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'control end secondary lost range/combat '
                                   f'(dist={values[ctrl_end["secondary_dist"]]:.2f}, '
                                   f'combat={values[ctrl_end["secondary_combat"]]:g})')
    treat_mid = model['treatment']['mid']
    if values[treat_mid['summon_count']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'treatment mid summon_count was {values[treat_mid["summon_count"]]:g}, expected 1')
    if values[treat_mid['primary_dist']] <= max_range:
        return replace(base, status='unmeasured',
                       explanation=f'treatment primary only reached {values[treat_mid["primary_dist"]]:.2f} yd by mid '
                                   f'(needs > {max_range:g} yd before retarget pulse)')
    treat_end = model['treatment']['end']
    if values[treat_end['summon_count']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'treatment end summon_count was {values[treat_end["summon_count"]]:g}, expected 1')
    if values[treat_end['primary_dist']] <= max_range:
        return replace(base, status='unmeasured',
                       explanation=f'treatment end primary distance {values[treat_end["primary_dist"]]:.2f} yd '
                                   f'did not exceed {max_range:g} yd')
    if values[treat_end['secondary_dist']] > sec_range or values[treat_end['secondary_combat']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'treatment end secondary lost range/combat '
                                   f'(dist={values[treat_end["secondary_dist"]]:.2f}, '
                                   f'combat={values[treat_end["secondary_combat"]]:g})')
    ctrl_sec = values[ctrl_end['secondary_aura']]
    treat_sec = values[treat_end['secondary_aura']]
    detail = {
        'control_primary_dist_yd': values[ctrl_end['primary_dist']],
        'control_secondary_aura': ctrl_sec,
        'treatment_mid_primary_dist_yd': values[treat_mid['primary_dist']],
        'treatment_end_primary_dist_yd': values[treat_end['primary_dist']],
        'treatment_secondary_dist_yd': values[treat_end['secondary_dist']],
        'treatment_secondary_aura': treat_sec,
    }
    if ctrl_sec != 0.0:
        return replace(base, status='alert', measured=ctrl_sec, expected=0.0, detail=detail,
                       explanation=f'control arm afflicted {SECONDARY} ({ctrl_sec:g}) while {TARGET} stayed in range '
                                   f'({values[ctrl_end["primary_dist"]]:.2f} yd <= {max_range:g} yd)')
    if treat_sec != 1.0:
        return replace(base, status='alert', measured=treat_sec, expected=1.0, detail=detail,
                       explanation=f'treatment arm did not afflict {SECONDARY} ({treat_sec:g}) after {TARGET} ran '
                                   f'{values[treat_end["primary_dist"]]:.2f} yd (> {max_range:g} yd)')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0, detail=detail,
                   explanation=f'control kept {TARGET} at {values[ctrl_end["primary_dist"]]:.2f} yd ({SECONDARY} aura 0); '
                               f'treatment ran {TARGET} to {values[treat_mid["primary_dist"]]:.2f} -> '
                               f'{values[treat_end["primary_dist"]]:.2f} yd (> {max_range:g} yd) and afflicted '
                               f'{SECONDARY} ({values[treat_end["secondary_dist"]]:.2f} yd, aura 1)')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_retarget_scenario(class_file, summon_retarget_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: summon_retarget_verdict}
