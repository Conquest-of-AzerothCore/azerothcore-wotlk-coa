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
DEFAULT_LOS_PROBE_SPELL = 133
MAX_MOVE_YD = 100.0
FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'trigger_spell', 'entry', 'effect_aura',
          'primary_dx', 'primary_dy', 'secondary_dx', 'secondary_dy', 'control_move_dx', 'control_move_dy',
          'near_move_dx', 'near_move_dy', 'move_dx', 'move_dy', 'max_range_yd', 'secondary_max_range_yd',
          'los_probe_spell', 'speed_aura', 'initial_wait_ms', 'pre_pulse_wait_ms', 'post_pulse_wait_ms',
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
    control_move_dx: float
    control_move_dy: float
    near_move_dx: float | None
    near_move_dy: float | None
    move_dx: float
    move_dy: float
    max_range_yd: float
    secondary_max_range_yd: float
    los_probe_spell: int
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
    control_move_dx = float(entry.get('control_move_dx', 0.0))
    control_move_dy = float(entry.get('control_move_dy', 0.0))
    has_near = 'near_move_dx' in entry or 'near_move_dy' in entry
    near_move_dx = float(entry.get('near_move_dx', 0.0)) if has_near else None
    near_move_dy = float(entry.get('near_move_dy', 0.0)) if has_near else None
    move_dx = float(entry['move_dx'])
    move_dy = float(entry.get('move_dy', 0.0))
    max_range_yd = float(entry['max_range_yd'])
    secondary_max_range_yd = float(entry['secondary_max_range_yd'])
    los_probe_spell = int(entry.get('los_probe_spell', DEFAULT_LOS_PROBE_SPELL))
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
    if los_probe_spell < 1 or los_probe_spell == trigger_spell or los_probe_spell in learn:
        raise ValueError(f'{spell} {KIND} los_probe_spell must be a positive unlearned non-trigger spell id')
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
    if not -MAX_MOVE_YD <= control_move_dx <= MAX_MOVE_YD or not -MAX_MOVE_YD <= control_move_dy <= MAX_MOVE_YD:
        raise ValueError(f'{spell} {KIND} control_move offsets must lie in [-{MAX_MOVE_YD:g}, {MAX_MOVE_YD:g}]')
    if math.hypot(control_move_dx, control_move_dy) >= max_range_yd:
        raise ValueError(f'{spell} {KIND} control move distance must stay below max_range_yd ({max_range_yd:g})')
    if not -MAX_MOVE_YD <= move_dx <= MAX_MOVE_YD or not -MAX_MOVE_YD <= move_dy <= MAX_MOVE_YD:
        raise ValueError(f'{spell} {KIND} move_dx and move_dy must lie in [-{MAX_MOVE_YD:g}, {MAX_MOVE_YD:g}]')
    far_dist = math.hypot(move_dx, move_dy)
    if far_dist <= max_range_yd:
        raise ValueError(f'{spell} {KIND} move distance must exceed max_range_yd ({max_range_yd:g})')
    if has_near:
        if (not -MAX_MOVE_YD <= near_move_dx <= MAX_MOVE_YD
                or not -MAX_MOVE_YD <= near_move_dy <= MAX_MOVE_YD):
            raise ValueError(f'{spell} {KIND} near_move offsets must lie in [-{MAX_MOVE_YD:g}, {MAX_MOVE_YD:g}]')
        near_dist = math.hypot(near_move_dx, near_move_dy)
        if near_dist <= max_range_yd:
            raise ValueError(f'{spell} {KIND} near move distance must exceed max_range_yd ({max_range_yd:g})')
        if near_dist >= far_dist:
            raise ValueError(f'{spell} {KIND} near move distance must be shorter than far move distance')
    if math.hypot(secondary_dx - primary_dx, secondary_dy - primary_dy) >= secondary_max_range_yd:
        raise ValueError(f'{spell} {KIND} secondary enemy must start inside secondary_max_range_yd of primary')
    for field_name, ms in (('initial_wait_ms', initial_wait_ms), ('pre_pulse_wait_ms', pre_pulse_wait_ms),
                           ('post_pulse_wait_ms', post_pulse_wait_ms), ('expire_wait_ms', expire_wait_ms)):
        if not isinstance(ms, int) or isinstance(ms, bool) or ms < 100:
            raise ValueError(f'{spell} {KIND} {field_name} must be an int >= 100, not {ms!r}')
    return SummonRetargetSpec(spell, entry['name'], entry['quote'], trigger_spell, summon_entry, effect_aura,
                              primary_dx, primary_dy, secondary_dx, secondary_dy, control_move_dx, control_move_dy,
                              near_move_dx, near_move_dy, move_dx, move_dy, max_range_yd, secondary_max_range_yd,
                              los_probe_spell, speed_aura, initial_wait_ms, pre_pulse_wait_ms, post_pulse_wait_ms,
                              expire_wait_ms, cast_power, dummy_entry, learn, entry.get('label_suffix', KIND))


def retarget_mark(spec: SummonRetargetSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def move_point_step(dx: float, dy: float) -> dict:
    step = {'action': 'move_point', 'actor': TARGET, 'dx': dx}
    if dy != 0.0:
        step['dy'] = dy
    return step


def los_probe_step(spec: SummonRetargetSpec, prefix: str) -> tuple[dict, str]:
    label = retarget_mark(spec, f'{prefix} los_probe')
    return {'action': 'cast', 'actor': CASTER, 'spell': spec.los_probe_spell, 'target': TARGET, 'label': label}, label


def full_snapshot_reads(spec: SummonRetargetSpec, prefix: str) -> tuple[list[dict], dict[str, str]]:
    labels = {
        'summon_count': retarget_mark(spec, f'{prefix} summon_count'),
        'primary_alive': retarget_mark(spec, f'{prefix} primary_alive'),
        'primary_aura': retarget_mark(spec, f'{prefix} primary_aura'),
        'secondary_aura': retarget_mark(spec, f'{prefix} secondary_aura'),
        'secondary_combat': retarget_mark(spec, f'{prefix} secondary_combat'),
        'primary_dist': retarget_mark(spec, f'{prefix} primary_dist'),
        'secondary_dist': retarget_mark(spec, f'{prefix} secondary_dist'),
    }
    steps = [
        measurement(labels['summon_count'], CASTER, 'owned_creature_count', entry=spec.entry),
        measurement(labels['primary_alive'], TARGET, 'alive'),
        measurement(labels['primary_aura'], TARGET, 'aura', spell=spec.effect_aura),
        measurement(labels['secondary_aura'], SECONDARY, 'aura', spell=spec.effect_aura),
        measurement(labels['secondary_combat'], SECONDARY, 'combat'),
        measurement(labels['primary_dist'], CASTER, 'owned_creature_distance_2d', entry=spec.entry, target=TARGET),
        measurement(labels['secondary_dist'], CASTER, 'owned_creature_distance_2d', entry=spec.entry, target=SECONDARY),
    ]
    return steps, labels


def mid_snapshot_reads(spec: SummonRetargetSpec, prefix: str) -> tuple[list[dict], dict[str, str]]:
    labels = {
        'summon_count': retarget_mark(spec, f'{prefix} summon_count'),
        'primary_alive': retarget_mark(spec, f'{prefix} primary_alive'),
        'primary_dist': retarget_mark(spec, f'{prefix} primary_dist'),
    }
    steps = [
        measurement(labels['summon_count'], CASTER, 'owned_creature_count', entry=spec.entry),
        measurement(labels['primary_alive'], TARGET, 'alive'),
        measurement(labels['primary_dist'], CASTER, 'owned_creature_distance_2d', entry=spec.entry, target=TARGET),
    ]
    return steps, labels


def between_cleanup_steps(spec: SummonRetargetSpec, prefix: str, return_dx: float = 0.0,
                          return_dy: float = 0.0) -> tuple[list[dict], dict[str, str]]:
    labels = {
        'summon_count': retarget_mark(spec, f'{prefix} summon_count'),
        'primary_alive': retarget_mark(spec, f'{prefix} primary_alive'),
        'primary_aura': retarget_mark(spec, f'{prefix} primary_aura'),
        'secondary_aura': retarget_mark(spec, f'{prefix} secondary_aura'),
    }
    steps: list[dict] = []
    if return_dx != 0.0 or return_dy != 0.0:
        steps.append(move_point_step(return_dx, return_dy))
    steps += [
        {'action': 'wait', 'label': f'expire {prefix}', 'ms': spec.expire_wait_ms},
        measurement(labels['summon_count'], CASTER, 'owned_creature_count', entry=spec.entry),
        measurement(labels['primary_alive'], TARGET, 'alive'),
        measurement(labels['primary_aura'], TARGET, 'aura', spell=spec.effect_aura),
        measurement(labels['secondary_aura'], SECONDARY, 'aura', spell=spec.effect_aura),
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

    def treatment_arm(prefix: str, dx: float, dy: float) -> tuple[list[dict], dict]:
        init_steps, init_lbls = full_snapshot_reads(spec, f'{prefix} initial')
        mid_steps, mid_lbls = mid_snapshot_reads(spec, f'{prefix} mid')
        mid_los_step, mid_los_lbl = los_probe_step(spec, f'{prefix} mid')
        end_steps, end_lbls = full_snapshot_reads(spec, f'{prefix} end')
        end_los_step, end_los_lbl = los_probe_step(spec, f'{prefix} end')
        arm_steps = (
            summon_setup()
            + init_steps
            + [move_point_step(dx, dy),
               {'action': 'wait', 'label': f'{prefix} run out of range', 'ms': spec.pre_pulse_wait_ms}]
            + mid_steps
            + [mid_los_step,
               {'action': 'wait', 'label': f'{prefix} retarget pulse', 'ms': spec.post_pulse_wait_ms}]
            + end_steps
            + [end_los_step]
        )
        return arm_steps, {'initial': init_lbls, 'mid': mid_lbls, 'mid_los': mid_los_lbl,
                           'end': end_lbls, 'end_los': end_los_lbl}

    ctrl_init_steps, ctrl_init = full_snapshot_reads(spec, 'control initial')
    ctrl_end_steps, ctrl_end = full_snapshot_reads(spec, 'control end')
    ctrl_los_step, ctrl_los = los_probe_step(spec, 'control end')
    ctrl_move = [move_point_step(spec.control_move_dx, spec.control_move_dy)] if (
        spec.control_move_dx != 0.0 or spec.control_move_dy != 0.0) else []
    between_steps, between_labels = between_cleanup_steps(
        spec, 'between', -spec.control_move_dx, -spec.control_move_dy)
    steps += (
        summon_setup()
        + ctrl_init_steps
        + ctrl_move
        + [{'action': 'wait', 'label': 'control hold', 'ms': spec.pre_pulse_wait_ms + spec.post_pulse_wait_ms}]
        + ctrl_end_steps
        + [ctrl_los_step]
        + between_steps
    )
    near_model = None
    between_near_labels = None
    if spec.near_move_dx is not None and spec.near_move_dy is not None:
        near_steps, near_model = treatment_arm('treatment_near', spec.near_move_dx, spec.near_move_dy)
        between_near_steps, between_near_labels = between_cleanup_steps(
            spec, 'between_near', -spec.near_move_dx, -spec.near_move_dy)
        steps += near_steps + between_near_steps
    treat_steps, treat_model = treatment_arm('treatment', spec.move_dx, spec.move_dy)
    steps += treat_steps
    base_creature = {k: v for k, v in creature_fixture(class_file).items() if k != 'distance'}
    primary = {**base_creature, 'id': TARGET, 'entry': spec.dummy_entry,
               'dx': spec.primary_dx, 'dy': spec.primary_dy, 'stationary': False}
    secondary = {**base_creature, 'id': SECONDARY, 'entry': spec.dummy_entry,
                 'dx': spec.secondary_dx, 'dy': spec.secondary_dy, 'stationary': True}
    near_note = (f' An intermediate treatment arm moves {TARGET} by ({spec.near_move_dx:g}, {spec.near_move_dy:g}) '
                 f'just beyond {spec.max_range_yd:g} yd before returning for the far arm.'
                 if spec.near_move_dx is not None else '')
    ctrl_note = (f'moves {TARGET} by ({spec.control_move_dx:g}, {spec.control_move_dy:g}) inside'
                 if ctrl_move else f'keeps {TARGET} within')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon retarget',
        'contract': (f'Two enemies stand near caster: movable {TARGET} at ({spec.primary_dx:g}, {spec.primary_dy:g}) '
                     f'and stationary {SECONDARY} at ({spec.secondary_dx:g}, {spec.secondary_dy:g}) engaged in combat '
                     f'with caster via creature_attack. Every arm applies speed_aura {spec.speed_aura} symmetrically '
                     f'to {TARGET} and casts {spec.trigger_spell} at {TARGET}, summoning {spec.entry} and applying '
                     f'aura {spec.effect_aura} to {TARGET} while {SECONDARY} starts at 0. Control {ctrl_note} '
                     f'{spec.max_range_yd:g} yd across '
                     f'{spec.initial_wait_ms + spec.pre_pulse_wait_ms + spec.post_pulse_wait_ms} ms, verifies '
                     f'{TARGET} alive and line_of_sight true, and requires {SECONDARY} aura {spec.effect_aura} == 0.'
                     f'{near_note} Treatment orders move_point ({spec.move_dx:g}, {spec.move_dy:g}) on {TARGET}, '
                     f'verifies {TARGET} exceeds {spec.max_range_yd:g} yd while alive and in line of sight of caster '
                     f'(unlearned cast probe {spec.los_probe_spell}), and requires {SECONDARY} aura '
                     f'{spec.effect_aura} == 1 after the retarget window.'),
        'players': [player_fixture(class_file)],
        'creatures': [primary, secondary],
        'steps': steps,
    }
    model = {
        'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'trigger_spell': spec.trigger_spell,
        'los_probe_spell': spec.los_probe_spell, 'entry': spec.entry, 'effect_aura': spec.effect_aura,
        'max_range_yd': spec.max_range_yd, 'secondary_max_range_yd': spec.secondary_max_range_yd,
        'control': {'initial': ctrl_init, 'end': ctrl_end, 'end_los': ctrl_los},
        'between': between_labels,
        'treatment': treat_model,
    }
    if near_model is not None and between_near_labels is not None:
        model['treatment_near'] = near_model
        model['between_near'] = between_near_labels
    expectation = Expectation(retarget_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell,
                              None, f'{SECONDARY} aura {spec.effect_aura}: control 0, treatment 1',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def check_initial(values: dict[str, float], snap: dict[str, str], max_range: float, sec_range: float,
                  label: str) -> str | None:
    if values[snap['summon_count']] != 1.0:
        return f'{label} summon_count was {values[snap["summon_count"]]:g}, expected 1'
    if values[snap['primary_alive']] != 1.0:
        return f'{label} primary alive was {values[snap["primary_alive"]]:g}, expected 1'
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


def check_between(values: dict[str, float], between: dict[str, str], label: str) -> str | None:
    if values[between['primary_alive']] != 1.0:
        return f'{label} primary alive was {values[between["primary_alive"]]:g}, expected 1'
    for key in ('summon_count', 'primary_aura', 'secondary_aura'):
        if values[between[key]] != 0.0:
            return f'{label} left {key} = {values[between[key]]:g}, expected 0'
    return None


def check_los(run: Run, step_label: str, label: str) -> tuple[bool | None, str | None]:
    step = next((s for s in run.steps if s.get('action') == 'cast' and s.get('label') == step_label), None)
    if step is None:
        return None, f'{label} missing line-of-sight probe step {step_label!r}'
    active = step.get('spell_active')
    if str(active).lower() != 'false':
        return None, f'{label} line-of-sight probe spell was active ({active!r}), expected unlearned probe'
    los = step.get('line_of_sight')
    if str(los).lower() != 'true':
        return False, f'{label} lost line of sight to {TARGET} (line_of_sight={los!r})'
    return True, None


def check_treatment_arm(values: dict[str, float], run: Run, arm: dict, max_range: float, sec_range: float,
                        label: str) -> tuple[dict | None, str | None]:
    problem = check_initial(values, arm['initial'], max_range, sec_range, f'{label} initial')
    if problem is not None:
        return None, problem
    mid = arm['mid']
    if values[mid['summon_count']] != 1.0:
        return None, f'{label} mid summon_count was {values[mid["summon_count"]]:g}, expected 1'
    if values[mid['primary_alive']] != 1.0:
        return None, f'{label} mid primary alive was {values[mid["primary_alive"]]:g}, expected 1'
    if values[mid['primary_dist']] <= max_range:
        return None, (f'{label} primary only reached {values[mid["primary_dist"]]:.2f} yd by mid '
                      f'(needs > {max_range:g} yd before retarget pulse)')
    mid_los, problem = check_los(run, arm['mid_los'], f'{label} mid')
    if problem is not None:
        return None, problem
    end = arm['end']
    if values[end['summon_count']] != 1.0:
        return None, f'{label} end summon_count was {values[end["summon_count"]]:g}, expected 1'
    if values[end['primary_alive']] != 1.0:
        return None, f'{label} end primary alive was {values[end["primary_alive"]]:g}, expected 1'
    if values[end['primary_dist']] <= max_range:
        return None, (f'{label} end primary distance {values[end["primary_dist"]]:.2f} yd '
                      f'did not exceed {max_range:g} yd')
    end_los, problem = check_los(run, arm['end_los'], f'{label} end')
    if problem is not None:
        return None, problem
    if values[end['secondary_dist']] > sec_range or values[end['secondary_combat']] != 1.0:
        return None, (f'{label} end secondary lost range/combat '
                      f'(dist={values[end["secondary_dist"]]:.2f}, combat={values[end["secondary_combat"]]:g})')
    return {
        'mid_primary_dist_yd': values[mid['primary_dist']],
        'mid_primary_alive': values[mid['primary_alive']],
        'mid_primary_los': mid_los,
        'end_primary_dist_yd': values[end['primary_dist']],
        'end_primary_alive': values[end['primary_alive']],
        'end_primary_los': end_los,
        'secondary_dist_yd': values[end['secondary_dist']],
        'secondary_aura': values[end['secondary_aura']],
    }, None


def summon_retarget_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    snapshots = [model['control']['initial'], model['control']['end'], model['between'],
                 model['treatment']['initial'], model['treatment']['mid'], model['treatment']['end']]
    if 'treatment_near' in model:
        snapshots += [model['treatment_near']['initial'], model['treatment_near']['mid'],
                      model['treatment_near']['end'], model['between_near']]
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
    problem = check_initial(values, model['control']['initial'], max_range, sec_range, 'control initial')
    if problem is not None:
        return replace(base, status='unmeasured', explanation=problem)
    ctrl_end = model['control']['end']
    if values[ctrl_end['summon_count']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'control end summon_count was {values[ctrl_end["summon_count"]]:g}, expected 1')
    if values[ctrl_end['primary_alive']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'control end primary alive was {values[ctrl_end["primary_alive"]]:g}, expected 1')
    if values[ctrl_end['primary_dist']] > max_range:
        return replace(base, status='unmeasured',
                       explanation=f'control primary drifted to {values[ctrl_end["primary_dist"]]:.2f} yd '
                                   f'> {max_range:g}')
    ctrl_los, problem = check_los(run, model['control']['end_los'], 'control end')
    if problem is not None:
        return replace(base, status='unmeasured', explanation=problem)
    if values[ctrl_end['secondary_dist']] > sec_range or values[ctrl_end['secondary_combat']] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'control end secondary lost range/combat '
                                   f'(dist={values[ctrl_end["secondary_dist"]]:.2f}, '
                                   f'combat={values[ctrl_end["secondary_combat"]]:g})')
    problem = check_between(values, model['between'], 'between-arm cleanup')
    if problem is not None:
        return replace(base, status='unmeasured', explanation=problem)
    near_info = None
    if 'treatment_near' in model:
        near_info, problem = check_treatment_arm(values, run, model['treatment_near'], max_range, sec_range,
                                                 'treatment_near')
        if problem is not None:
            return replace(base, status='unmeasured', explanation=problem)
        problem = check_between(values, model['between_near'], 'between-treatment cleanup')
        if problem is not None:
            return replace(base, status='unmeasured', explanation=problem)
    treat_info, problem = check_treatment_arm(values, run, model['treatment'], max_range, sec_range, 'treatment')
    if problem is not None:
        return replace(base, status='unmeasured', explanation=problem)
    ctrl_sec = values[ctrl_end['secondary_aura']]
    treat_sec = treat_info['secondary_aura']
    detail = {
        'metric': METRIC,
        'control_primary_dist_yd': values[ctrl_end['primary_dist']],
        'control_primary_alive': values[ctrl_end['primary_alive']],
        'control_primary_los': ctrl_los,
        'control_secondary_aura': ctrl_sec,
        'treatment_mid_primary_dist_yd': treat_info['mid_primary_dist_yd'],
        'treatment_mid_primary_alive': treat_info['mid_primary_alive'],
        'treatment_mid_primary_los': treat_info['mid_primary_los'],
        'treatment_end_primary_dist_yd': treat_info['end_primary_dist_yd'],
        'treatment_end_primary_alive': treat_info['end_primary_alive'],
        'treatment_end_primary_los': treat_info['end_primary_los'],
        'treatment_secondary_dist_yd': treat_info['secondary_dist_yd'],
        'treatment_secondary_aura': treat_sec,
    }
    if near_info is not None:
        detail.update({
            'treatment_near_mid_primary_dist_yd': near_info['mid_primary_dist_yd'],
            'treatment_near_mid_primary_alive': near_info['mid_primary_alive'],
            'treatment_near_mid_primary_los': near_info['mid_primary_los'],
            'treatment_near_end_primary_dist_yd': near_info['end_primary_dist_yd'],
            'treatment_near_end_primary_alive': near_info['end_primary_alive'],
            'treatment_near_end_primary_los': near_info['end_primary_los'],
            'treatment_near_secondary_dist_yd': near_info['secondary_dist_yd'],
            'treatment_near_secondary_aura': near_info['secondary_aura'],
        })
    if ctrl_sec != 0.0:
        return replace(base, status='alert', measured=ctrl_sec, expected=0.0, detail=detail,
                       explanation=f'control arm afflicted {SECONDARY} ({ctrl_sec:g}) while {TARGET} stayed in range '
                                   f'({values[ctrl_end["primary_dist"]]:.2f} yd <= {max_range:g} yd, '
                                   f'los={ctrl_los}, alive=1)')
    if near_info is not None and near_info['secondary_aura'] != 1.0:
        return replace(base, status='alert', measured=near_info['secondary_aura'], expected=1.0, detail=detail,
                       explanation=f'near treatment arm did not afflict {SECONDARY} '
                                   f'({near_info["secondary_aura"]:g}) after {TARGET} ran '
                                   f'{near_info["end_primary_dist_yd"]:.2f} yd (> {max_range:g} yd, '
                                   f'los={near_info["end_primary_los"]}, alive=1); '
                                   f'far treatment at {treat_info["end_primary_dist_yd"]:.2f} yd had '
                                   f'{SECONDARY} aura {treat_sec:g}')
    if treat_sec != 1.0:
        return replace(base, status='alert', measured=treat_sec, expected=1.0, detail=detail,
                       explanation=f'treatment arm did not afflict {SECONDARY} ({treat_sec:g}) after {TARGET} ran '
                                   f'{treat_info["end_primary_dist_yd"]:.2f} yd (> {max_range:g} yd, '
                                   f'los={treat_info["end_primary_los"]}, alive=1)')
    near_text = (f'; near treatment ran {TARGET} to {near_info["mid_primary_dist_yd"]:.2f} -> '
                 f'{near_info["end_primary_dist_yd"]:.2f} yd (> {max_range:g} yd, los=True, alive=1) and afflicted '
                 f'{SECONDARY} ({near_info["secondary_dist_yd"]:.2f} yd, aura 1)' if near_info is not None else '')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0, detail=detail,
                   explanation=f'control kept {TARGET} at {values[ctrl_end["primary_dist"]]:.2f} yd '
                               f'(los=True, alive=1, {SECONDARY} aura 0){near_text}; '
                               f'treatment ran {TARGET} to {treat_info["mid_primary_dist_yd"]:.2f} -> '
                               f'{treat_info["end_primary_dist_yd"]:.2f} yd (> {max_range:g} yd, los=True, alive=1) '
                               f'and afflicted {SECONDARY} ({treat_info["secondary_dist_yd"]:.2f} yd, aura 1)')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_retarget_scenario(class_file, summon_retarget_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: summon_retarget_verdict}
