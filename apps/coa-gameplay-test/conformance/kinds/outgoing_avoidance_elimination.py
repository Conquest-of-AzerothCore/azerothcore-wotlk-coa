from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import MAX_SCENARIO_MS, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_DISTANCE, DUMMY_ENTRY, Expectation, TARGET, dataset

KIND = 'outgoing_avoidance_elimination'
ORDER = 61
OUTCOME_METRICS = ('melee_misses_dealt', 'melee_dodges_dealt', 'melee_parries_dealt')
METRIC = OUTCOME_METRICS[0]
METRIC_EVIDENCE = {metric: 'event' for metric in OUTCOME_METRICS}
CONTROL, TREATMENT = 'control', 'treatment'
ARMS = (CONTROL, TREATMENT)
DEFAULT_MIN_CONTROL_RATE = 0.05
DEFAULT_RESIDUAL = 1e-3
PAIR_RUNS = 2
OUTCOME_COUNT = 3
DEFAULT_DUMMY_HEALTH = 500000
MAX_MELEE_DISTANCE_YD = 5.0
FACING_TOLERANCE_RAD = 0.15
STOP_SETTLE_MS = 300
POST_STOP_WAIT_MS = 200
FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'gate_spell', 'window_ms', 'min_swings',
          'min_control_rate', 'residual', 'haste_auras', 'dummy_entry', 'dummy_distance', 'dummy_health', 'hand',
          'learn', 'observe_source'}


@dataclass(frozen=True)
class OutgoingAvoidanceSpec:
    spell: int
    name: str
    quote: str
    gate_spell: int
    window_ms: int
    min_swings: int
    min_control_rate: float
    residual: float
    haste_auras: tuple[int, ...]
    dummy_entry: int
    dummy_distance: float
    dummy_health: int
    hand: int
    learn: tuple[int, ...]
    label_suffix: str = KIND


def required_min_swings(min_control_rate: float, residual: float) -> int:
    if not 0.0 < min_control_rate < 1.0:
        raise ValueError(f'{KIND} min_control_rate must lie in (0, 1), not {min_control_rate!r}')
    if not 0.0 < residual < 1.0:
        raise ValueError(f'{KIND} residual must lie in (0, 1), not {residual!r}')
    log_stay = math.log(1.0 - min_control_rate)
    control_floor = math.ceil(math.log(residual / (OUTCOME_COUNT * PAIR_RUNS)) / log_stay)
    treatment_floor = math.ceil(math.log(residual / OUTCOME_COUNT) / (PAIR_RUNS * log_stay))
    return max(control_floor, treatment_floor)


def pair_control_false_fail(swings: int, rate: float) -> float:
    return min(1.0, OUTCOME_COUNT * PAIR_RUNS * ((1.0 - rate) ** swings))


def pair_treatment_false_pass(swings: int, rate: float) -> float:
    return min(1.0, OUTCOME_COUNT * ((1.0 - rate) ** (PAIR_RUNS * swings)))


def outgoing_avoidance_spec(entry: dict) -> OutgoingAvoidanceSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry.get("spell")} {KIND} unknown fields: {sorted(unknown)}')
    spell = int(entry['spell'])
    gate_spell = int(entry.get('gate_spell', spell))
    window_ms = entry['window_ms']
    min_swings = entry['min_swings']
    if not isinstance(window_ms, int) or isinstance(window_ms, bool) or window_ms < 1000:
        raise ValueError(f'{spell} {KIND} window_ms must be an int >= 1000, not {window_ms!r}')
    if not isinstance(min_swings, int) or isinstance(min_swings, bool) or min_swings < 1:
        raise ValueError(f'{spell} {KIND} min_swings must be a positive int, not {min_swings!r}')
    min_control_rate = float(entry.get('min_control_rate', DEFAULT_MIN_CONTROL_RATE))
    residual = float(entry.get('residual', DEFAULT_RESIDUAL))
    floor = required_min_swings(min_control_rate, residual)
    if min_swings < floor:
        raise ValueError(f'{spell} {KIND} min_swings {min_swings} is below the {floor} required for '
                         f'rate {min_control_rate:g} and pair residual {residual:g}')
    haste_raw = entry.get('haste_auras', ())
    if not isinstance(haste_raw, (list, tuple)) or any(not isinstance(a, int) or isinstance(a, bool) or a < 1
                                                       for a in haste_raw):
        raise ValueError(f'{spell} {KIND} haste_auras must be a list of positive spell ids')
    haste_auras = tuple(haste_raw)
    if len(set(haste_auras)) != len(haste_auras):
        raise ValueError(f'{spell} {KIND} haste_auras must not contain duplicates')
    dummy_entry = int(entry.get('dummy_entry', DUMMY_ENTRY))
    dummy_distance = float(entry.get('dummy_distance', DUMMY_DISTANCE))
    dummy_health = int(entry.get('dummy_health', DEFAULT_DUMMY_HEALTH))
    hand = entry.get('hand', 0)
    if dummy_entry < 1 or not 0.5 <= dummy_distance <= MAX_MELEE_DISTANCE_YD or dummy_health < 10000:
        raise ValueError(f'{spell} {KIND} dummy_entry/distance/health out of range')
    if not isinstance(hand, int) or isinstance(hand, bool) or hand not in (0, 1):
        raise ValueError(f'{spell} {KIND} hand must be 0 or 1, not {hand!r}')
    learn = tuple(int(s) for s in entry.get('learn', ()))
    if gate_spell in learn:
        raise ValueError(f'{spell} {KIND} must not pre-learn gate_spell {gate_spell} in learn')
    return OutgoingAvoidanceSpec(spell, entry['name'], entry['quote'], gate_spell, window_ms, min_swings,
                                 min_control_rate, residual, haste_auras, dummy_entry, dummy_distance, dummy_health,
                                 hand, learn, entry.get('label_suffix', KIND))


def avoidance_mark(spec: OutgoingAvoidanceSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def arm_state_reads(spec: OutgoingAvoidanceSpec, arm: str, moment: str) -> tuple[list[dict], dict[str, str]]:
    prefix = f'{arm} {moment}'
    labels = {
        'knows': avoidance_mark(spec, f'{prefix} knows'),
        'alive': avoidance_mark(spec, f'{prefix} alive'),
        'distance': avoidance_mark(spec, f'{prefix} distance'),
        'caster_x': avoidance_mark(spec, f'{prefix} caster x'),
        'caster_y': avoidance_mark(spec, f'{prefix} caster y'),
        'dummy_x': avoidance_mark(spec, f'{prefix} dummy x'),
        'dummy_y': avoidance_mark(spec, f'{prefix} dummy y'),
        'dummy_o': avoidance_mark(spec, f'{prefix} dummy o'),
    }
    steps = [
        measurement(labels['knows'], CASTER, 'knows_spell', spell=spec.gate_spell),
        measurement(labels['alive'], TARGET, 'alive'),
        measurement(labels['distance'], CASTER, 'distance_2d', target=TARGET),
        measurement(labels['caster_x'], CASTER, 'position_x'),
        measurement(labels['caster_y'], CASTER, 'position_y'),
        measurement(labels['dummy_x'], TARGET, 'position_x'),
        measurement(labels['dummy_y'], TARGET, 'position_y'),
        measurement(labels['dummy_o'], TARGET, 'position_o'),
    ]
    for aura in spec.haste_auras:
        key = f'haste_{aura}'
        labels[key] = avoidance_mark(spec, f'{prefix} haste {aura}')
        steps.append(measurement(labels[key], CASTER, 'aura', spell=aura))
    return steps, labels


def counter_reads(spec: OutgoingAvoidanceSpec, arm: str, moment: str) -> tuple[list[dict], dict[str, str]]:
    prefix = f'{arm} {moment}'
    fields = {'hand': spec.hand}
    metrics = (
        ('swings', 'melee_attack_count'),
        ('hits', 'melee_damage_count'),
        ('misses', 'melee_misses_dealt'),
        ('dodges', 'melee_dodges_dealt'),
        ('parries', 'melee_parries_dealt'),
    )
    labels = {key: avoidance_mark(spec, f'{prefix} {key}') for key, _ in metrics}
    steps = [measurement(labels[key], CASTER, metric, **fields) for key, metric in metrics]
    return steps, labels


def outgoing_avoidance_scenario(class_file: dict, spec: OutgoingAvoidanceSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 0.0)
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': s} for s in spec.learn]
    steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.haste_auras]
    arm_models = {}
    for arm in ARMS:
        steps.append({'action': 'set_health', 'actor': TARGET, 'value': spec.dummy_health})
        if arm == TREATMENT:
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.gate_spell})
        start_state_steps, start_state = arm_state_reads(spec, arm, 'start')
        start_counter_steps, start_counters = counter_reads(spec, arm, 'start')
        end_counter_steps, end_counters = counter_reads(spec, arm, 'end')
        end_state_steps, end_state = arm_state_reads(spec, arm, 'end')
        post_stop_label = avoidance_mark(spec, f'{arm} post_stop swings')
        steps += (start_state_steps + start_counter_steps
                  + [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                     {'action': 'wait', 'label': f'{arm} swings', 'ms': spec.window_ms},
                     {'action': 'stop_attack', 'actor': CASTER},
                     {'action': 'wait', 'label': f'{arm} stop settle', 'ms': STOP_SETTLE_MS}]
                  + end_counter_steps + end_state_steps
                  + [{'action': 'wait', 'label': f'{arm} post stop', 'ms': POST_STOP_WAIT_MS},
                     measurement(post_stop_label, CASTER, 'melee_attack_count', hand=spec.hand)])
        arm_models[arm] = {
            'start_state': start_state, 'end_state': end_state,
            'start_counters': start_counters, 'end_counters': end_counters,
            'post_stop': post_stop_label,
        }
    ctrl_ff = pair_control_false_fail(spec.min_swings, spec.min_control_rate)
    treat_fp = pair_treatment_false_pass(spec.min_swings, spec.min_control_rate)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour outgoing avoidance',
        'contract': (f'Control (without {spec.gate_spell}) and treatment (after real learn of {spec.gate_spell}) '
                     f'each swing hand {spec.hand} for {spec.window_ms} ms against a level-{class_file["level"]} '
                     f'stationary facing dummy (entry {spec.dummy_entry}, distance {spec.dummy_distance:g} yd, '
                     f'face_caster true, health {spec.dummy_health}) under identical haste fixtures '
                     f'{list(spec.haste_auras)}. Facing, alive state, distance, haste auras and knows_spell are '
                     f'verified at both start and end of every arm plus a post-stop stillness check. Control must '
                     f'record >= 1 miss, >= 1 dodge and >= 1 parry; treatment must record 0 misses, 0 dodges, '
                     f'0 parries and damaging_hits == swings. Sizing at rate {spec.min_control_rate:g} with '
                     f'min_swings {spec.min_swings}/arm/run ({PAIR_RUNS * spec.min_swings}/pair): control pair '
                     f'false-fail <= {ctrl_ff:.6f} and treatment pair false-pass <= {treat_fp:.6g} '
                     f'(both <= residual {spec.residual:g}).'),
        'players': [{k: v for k, v in player_fixture(class_file).items()
                     if k not in ('melee_hit_rating', 'expertise_rating', 'spell_hit_rating', 'ranged_hit_rating')}],
        'creatures': [{**creature_fixture(class_file, spec.dummy_distance),
                       'entry': spec.dummy_entry, 'health': spec.dummy_health,
                       'stationary': True, 'face_caster': True}],
        'steps': steps,
    }
    model = {
        'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'gate_spell': spec.gate_spell,
        'min_swings': spec.min_swings, 'min_control_rate': spec.min_control_rate, 'residual': spec.residual,
        'haste_auras': list(spec.haste_auras), 'arms': arm_models,
    }
    expectation = Expectation(avoidance_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.gate_spell,
                              None, '0 misses, 0 dodges, 0 parries (control >= 1 each)',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def angle_error_rad(caster_x: float, caster_y: float, dummy_x: float, dummy_y: float, dummy_o: float) -> float:
    expected = math.atan2(caster_y - dummy_y, caster_x - dummy_x)
    return abs((dummy_o - expected + math.pi) % (2.0 * math.pi) - math.pi)


def check_state(values: dict[str, float], state: dict[str, str], expected_knows: int,
                haste_auras: list[int], label: str) -> str | None:
    if values[state['knows']] != expected_knows:
        return f'{label} knows_spell was {values[state["knows"]]:g}, expected {expected_knows}'
    if values[state['alive']] != 1.0:
        return f'{label} dummy alive was {values[state["alive"]]:g}, expected 1'
    if values[state['distance']] > MAX_MELEE_DISTANCE_YD:
        return f'{label} distance {values[state["distance"]]:.2f} yd exceeds {MAX_MELEE_DISTANCE_YD:g} yd'
    err = angle_error_rad(values[state['caster_x']], values[state['caster_y']],
                          values[state['dummy_x']], values[state['dummy_y']], values[state['dummy_o']])
    if err > FACING_TOLERANCE_RAD:
        return f'{label} dummy facing error {err:.3f} rad exceeds {FACING_TOLERANCE_RAD:g} rad'
    for aura in haste_auras:
        if values[state[f'haste_{aura}']] != 1.0:
            return f'{label} haste aura {aura} was {values[state[f"haste_{aura}"]]:g}, expected 1'
    return None


def outgoing_avoidance_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    all_labels = []
    for arm in ARMS:
        am = model['arms'][arm]
        all_labels.extend(am['start_state'].values())
        all_labels.extend(am['end_state'].values())
        all_labels.extend(am['start_counters'].values())
        all_labels.extend(am['end_counters'].values())
        all_labels.append(am['post_stop'])
    missing = next((lbl for lbl in all_labels if run.values.get(lbl) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    values = run.values
    haste_auras = list(model['haste_auras'])
    min_swings = int(model['min_swings'])
    deltas = {}
    for arm in ARMS:
        am = model['arms'][arm]
        expected_knows = 0 if arm == CONTROL else 1
        for moment, state in (('start', am['start_state']), ('end', am['end_state'])):
            problem = check_state(values, state, expected_knows, haste_auras, f'{arm} {moment}')
            if problem is not None:
                return replace(base, status='unmeasured', explanation=problem)
        if values[am['post_stop']] != values[am['end_counters']['swings']]:
            return replace(base, status='unmeasured',
                           explanation=f'{arm} swings kept rising after stop_attack '
                                       f'({values[am["end_counters"]["swings"]]:g} -> {values[am["post_stop"]]:g})')
        d = {key: int(round(values[am['end_counters'][key]] - values[am['start_counters'][key]]))
             for key in ('swings', 'hits', 'misses', 'dodges', 'parries')}
        if any(v < 0 for v in d.values()):
            return replace(base, status='unmeasured', explanation=f'{arm} counter decreased: {d}')
        if d['swings'] == 0:
            return replace(base, status='unmeasured', explanation=f'{arm} delivered 0 melee swings')
        if d['hits'] + d['misses'] + d['dodges'] + d['parries'] > d['swings']:
            return replace(base, status='unmeasured',
                           explanation=f'{arm} outcomes exceed swings: {d}')
        if d['swings'] < min_swings:
            return replace(base, status='insufficient_trials',
                           explanation=f'{arm} delivered {d["swings"]} swings, below min_swings {min_swings}')
        deltas[arm] = d
    ctrl, treat = deltas[CONTROL], deltas[TREATMENT]
    detail = {'metric': METRIC, 'control': ctrl, 'treatment': treat, 'min_swings': min_swings}
    ctrl_missing = [name for name in ('misses', 'dodges', 'parries') if ctrl[name] < 1]
    if ctrl_missing:
        return replace(base, status='alert', measured=float(ctrl[ctrl_missing[0]]), expected=1.0, detail=detail,
                       explanation=f'control arm saw 0 for {ctrl_missing} over {ctrl["swings"]} swings ({ctrl})')
    treat_avoided = treat['misses'] + treat['dodges'] + treat['parries']
    unaccounted = treat['swings'] - treat['hits'] - treat_avoided
    if treat_avoided > 0 or unaccounted != 0:
        return replace(base, status='alert', measured=float(treat_avoided), expected=0.0, low=0.0, high=0.0,
                       detail=detail,
                       explanation=f'treatment arm did not eliminate outgoing avoidance over {treat["swings"]} swings '
                                   f'(misses={treat["misses"]}, dodges={treat["dodges"]}, parries={treat["parries"]}, '
                                   f'hits={treat["hits"]}, unaccounted={unaccounted}; control={ctrl})')
    return replace(base, status='ok', measured=0.0, expected=0.0, low=0.0, high=0.0, detail=detail,
                   explanation=f'control ({ctrl["swings"]} swings): {ctrl["misses"]} misses, {ctrl["dodges"]} dodges, '
                               f'{ctrl["parries"]} parries; treatment ({treat["swings"]} swings): 0 misses, 0 dodges, '
                               f'0 parries, {treat["hits"]}/{treat["swings"]} damaging hits')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return outgoing_avoidance_scenario(class_file, outgoing_avoidance_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: outgoing_avoidance_verdict}
