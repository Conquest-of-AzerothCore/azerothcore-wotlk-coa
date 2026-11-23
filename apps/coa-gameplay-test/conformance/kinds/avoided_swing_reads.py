from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Verdict, describe_failures, failure_reasons, missing_measurement
from hits import timed
from metric_delta_options.ally_offsets import relocate_steps
import proc_avoided
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'avoided_swing_reads'
ORDER = 52
AURA_EDGE, STAT_DELTA, DURATION_MAX, PER_EVENT = 'aura_edge', 'stat_delta', 'duration_max', 'per_event'
READS = (AURA_EDGE, STAT_DELTA, DURATION_MAX, PER_EVENT)
STAT_METRICS = frozenset({'melee_crit_chance'})
READ_METRICS = {AURA_EDGE: 'aura', DURATION_MAX: 'aura_duration_ms', PER_EVENT: 'spell_energize_total'}
INSIDE, OUTSIDE = 'ally', 'ally2'
DODGE, PARRY = 100, 0
MARGIN_YD = 0.5
ALLY_MIN_YD = 10.0
DISTANCE_TOLERANCE_YD = 0.05
STAT_TOLERANCE = 0.01
TICK_MS = 100
MIN_EVENTS = 20
QUIET_SHIFT_YD = 20
QUIET_WAIT_MS = 200
FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'read', 'observe_spell', 'effect',
          'striker_entry', 'strikers', 'striker_auras', 'swing_ms', 'control_windows', 'windows', 'ally_yd',
          'margin_yd', 'metric', 'min_events', 'learn', 'observe_source'}


@dataclass(frozen=True)
class AvoidedSwingReadsSpec:
    spell: int
    name: str
    quote: str
    read: str
    observe_spell: int
    effect: int
    striker_entry: int
    strikers: int
    striker_auras: tuple[int, ...]
    swing_ms: int
    control_windows: int
    windows: int
    label_suffix: str
    ally_yd: float | None = None
    margin_yd: float = MARGIN_YD
    metric: str | None = None
    min_events: int = MIN_EVENTS
    learn: tuple[int, ...] = ()


def avoided_swing_reads_spec(entry: dict) -> AvoidedSwingReadsSpec:
    if set(entry) - FIELDS:
        raise ValueError(f'{entry["spell"]} {KIND} has unknown fields {sorted(set(entry) - FIELDS)}')
    spec = AvoidedSwingReadsSpec(
        int(entry['spell']), entry['name'], entry['quote'], entry['read'], int(entry['observe_spell']),
        int(entry.get('effect', 0)), int(entry['striker_entry']), int(entry['strikers']),
        tuple(int(spell) for spell in entry.get('striker_auras', ())), int(entry['swing_ms']),
        int(entry['control_windows']), int(entry['windows']), entry.get('label_suffix', KIND),
        float(entry['ally_yd']) if entry.get('ally_yd') is not None else None,
        float(entry.get('margin_yd', MARGIN_YD)), entry.get('metric'), int(entry.get('min_events', MIN_EVENTS)),
        tuple(int(spell) for spell in entry.get('learn', ())))
    if spec.read not in READS:
        raise ValueError(f'{spec.spell} {KIND} read is one of {list(READS)}, not {spec.read!r}')
    if spec.control_windows < 1 or spec.windows < 1 or spec.min_events < 1 or not 0 <= spec.effect <= 2:
        raise ValueError(f'{spec.spell} {KIND} needs positive control_windows, windows and min_events and an effect '
                         f'index 0 to 2')
    if (spec.metric is not None) != (spec.read == STAT_DELTA) or (
            spec.read == STAT_DELTA and spec.metric not in STAT_METRICS):
        raise ValueError(f'{spec.spell} {KIND} stat_delta and only it names a metric of {sorted(STAT_METRICS)}')
    wants_ally = spec.read in (STAT_DELTA, DURATION_MAX)
    if (spec.ally_yd is not None) != wants_ally or (wants_ally and spec.ally_yd < ALLY_MIN_YD):
        raise ValueError(f'{spec.spell} {KIND} {spec.read} {"needs" if wants_ally else "takes no"} ally_yd'
                         + (f' of at least {ALLY_MIN_YD:g} yd, out of the strikers\' reach' if wants_ally else ''))
    if spec.spell in spec.learn:
        raise ValueError(f'{spec.spell} {KIND} learns the passive only between the arms, not in its learn list')
    proc_avoided.checked_trigger(avoided_entry(spec))
    return spec


def avoided_entry(spec: AvoidedSwingReadsSpec) -> dict:
    return {'aura': spec.spell, 'trigger': {'action': proc_avoided.AVOIDED, 'striker_entry': spec.striker_entry,
                                            'swing_ms': spec.swing_ms, 'dodge': DODGE, 'parry': PARRY,
                                            'strikers': spec.strikers, 'striker_auras': list(spec.striker_auras)}}


def mark(spec: AvoidedSwingReadsSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def expected_value(records: Records, spec: AvoidedSwingReadsSpec) -> float:
    if spec.read == AURA_EDGE:
        return float(records.radius(spec.observe_spell, spec.effect))
    if spec.read == DURATION_MAX:
        return float(records.duration_ms(spec.observe_spell))
    return float(records.single_value(spec.observe_spell, spec.effect))


def ally_offsets(spec: AvoidedSwingReadsSpec, expected: float) -> dict[str, float]:
    if spec.read == AURA_EDGE:
        if not 0 < spec.margin_yd < expected:
            raise ValueError(f'{spec.spell} {KIND} margin {spec.margin_yd:g} yd must lie inside the radius')
        return {INSIDE: expected - spec.margin_yd, OUTSIDE: expected + spec.margin_yd}
    return {INSIDE: spec.ally_yd} if spec.ally_yd is not None else {}


def placement_steps(spec: AvoidedSwingReadsSpec, offsets: dict[str, float]) -> list[dict]:
    steps = []
    for ally, distance in offsets.items():
        steps += [{'action': 'group', 'actor': CASTER, 'target': ally}] + relocate_steps(ally, distance)
    steps += [measurement(mark(spec, f'distance {ally}'), CASTER, 'distance', target=ally) for ally in offsets]
    return steps + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.learn]


def arm_reads(spec: AvoidedSwingReadsSpec, arm: str, offsets: dict[str, float]) -> dict[str, dict]:
    aura = {'spell': spec.observe_spell}
    if spec.read == PER_EVENT:
        return {'events': measurement(mark(spec, f'{arm} events'), CASTER, 'spell_energize_count', **aura),
                'total': measurement(mark(spec, f'{arm} total'), CASTER, 'spell_energize_total', **aura)}
    reads = {ally: measurement(mark(spec, f'{arm} aura {ally}'), ally, 'aura', **aura) for ally in offsets}
    if spec.read == STAT_DELTA:
        reads['stat'] = measurement(mark(spec, f'{arm} stat'), INSIDE, spec.metric)
    return reads


def duration_label(spec: AvoidedSwingReadsSpec, window: int) -> str:
    return mark(spec, f'remaining {window}')


def treatment_steps(spec: AvoidedSwingReadsSpec, avoided: dict) -> list[dict]:
    if spec.read != DURATION_MAX:
        return proc_avoided.attempt_steps(avoided, spec.windows, spec.swing_ms)
    steps = []
    for window in range(1, spec.windows + 1):
        steps += proc_avoided.attempt_steps(avoided, 1, spec.swing_ms)
        steps.append(measurement(duration_label(spec, window), INSIDE, 'aura_duration_ms',
                                 spell=spec.observe_spell))
    return steps


def quiet_steps(spec: AvoidedSwingReadsSpec, avoided: dict) -> list[dict]:
    return ([{'action': 'relocate', 'actor': CASTER, 'dx': QUIET_SHIFT_YD},
             {'action': 'wait', 'label': 'quiet', 'ms': QUIET_WAIT_MS}]
            + [measurement(mark(spec, f'quiet distance {striker}'), CASTER, 'distance', target=striker)
               for striker in proc_avoided.striker_ids(avoided)])


def quiet_minimum_yd() -> float:
    from behaviours import STRIKER_DISTANCE
    return QUIET_SHIFT_YD - STRIKER_DISTANCE


def band(spec: AvoidedSwingReadsSpec, expected: float) -> tuple[float, float]:
    if spec.read == DURATION_MAX:
        return expected - spec.swing_ms - TICK_MS, expected
    if spec.read == STAT_DELTA:
        return expected - STAT_TOLERANCE, expected + STAT_TOLERANCE
    return expected, expected


def rule_text(spec: AvoidedSwingReadsSpec, expected: float) -> str:
    low, high = band(spec, expected)
    if spec.read == AURA_EDGE:
        return (f'an ally grouped {expected - spec.margin_yd:g} yd from the caster holds {spec.observe_spell} after '
                f'the dodges and an ally grouped {expected + spec.margin_yd:g} yd away does not (radius {expected:g} '
                f'yd; Spell.cpp WorldObjectSpellAreaTargetCheck adds no combat reach for a player target of a '
                f'player caster), and neither holds it before the learn')
    if spec.read == STAT_DELTA:
        return (f'the grouped ally\'s {spec.metric} after the dodges with {spec.spell} learned less the same read '
                f'after the dodges before the learn lies in [{low:g}, {high:g}]')
    if spec.read == DURATION_MAX:
        return (f'the largest remaining duration of {spec.observe_spell} on the grouped ally, read after each '
                f'{spec.swing_ms} ms window, lies in [{low:g}, {high:g}] ms: every read is at most the full duration, '
                f'and a read in the window after an application is at most one window and one {TICK_MS} ms tick '
                f'below it, so a duration 10% shorter or longer reads outside the band')
    return (f'the {spec.observe_spell} energize total equals its event count times {expected:g} exactly, over at '
            f'least {spec.min_events} events after the learn, and no event before it')


def avoided_swing_reads_scenario(class_file: dict, spec: AvoidedSwingReadsSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    expected = expected_value(records, spec)
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, expected)
    avoided = avoided_entry(spec)
    offsets = ally_offsets(spec, expected)
    steps = (base_steps(class_file) + placement_steps(spec, offsets) + proc_avoided.engage_steps(avoided)
             + proc_avoided.attempt_steps(avoided, spec.control_windows, spec.swing_ms)
             + list(arm_reads(spec, 'control', offsets).values())
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + treatment_steps(spec, avoided) + quiet_steps(spec, avoided) + proc_avoided.guard_steps(avoided)
             + list(arm_reads(spec, 'treatment', offsets).values()))
    low, high = band(spec, expected)
    learned = f' {spec.learn} are learned before the engage and' if spec.learn else ''
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour avoided swing reads '
                f'{spec.label_suffix}',
        'contract': (f'{spec.strikers} aggressive stationary strikers {spec.striker_entry} swing at the caster, whose '
                     f'dodge and parry are set to {DODGE}% and {PARRY}% before every {spec.swing_ms} ms window, so '
                     f'every swing is dodged;{learned} {spec.control_windows} windows run before {spec.spell} is '
                     f'learned and {spec.windows} after. '
                     + (f'Grouped allies stand {", ".join(f"{ally} {yd:g} yd" for ally, yd in offsets.items())} '
                        f'along x. ' if offsets else '')
                     + f'Judge: {rule_text(spec, expected)}. The run is void on a missing read, a refused cast, an '
                       f'ally more than {DISTANCE_TOLERANCE_YD:g} yd from its place, a caster within '
                       f'{quiet_minimum_yd():g} yd of a striker after the {QUIET_SHIFT_YD} yd relocation that quiets '
                       f'the strikers before the reads, or a landed or blocked swing or own swing since the engage.'),
        'players': [player_fixture(class_file)] + [{**player_fixture(class_file), 'id': ally} for ally in offsets],
        'creatures': proc_avoided.striker_fixtures(class_file, avoided),
        'steps': steps}
    reads = {arm: {name: step['label'] for name, step in arm_reads(spec, arm, offsets).items()}
             for arm in ('control', 'treatment')}
    model = {'kind': KIND, 'read': spec.read, 'metric': spec.metric or READ_METRICS[spec.read], 'quote': entry.quote,
             'expected': expected, 'band': [low, high], 'min_events': spec.min_events,
             'offsets': {ally: yd for ally, yd in offsets.items()},
             'distances': {ally: mark(spec, f'distance {ally}') for ally in offsets},
             'reads': reads,
             'remaining': [duration_label(spec, window) for window in range(1, spec.windows + 1)]
             if spec.read == DURATION_MAX else [],
             'quiet_distances': [mark(spec, f'quiet distance {striker}')
                                 for striker in proc_avoided.striker_ids(avoided)],
             'quiet_minimum_yd': quiet_minimum_yd()}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.observe_spell, None,
                              f'{expected:g}', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def void(base: Verdict, why: str) -> Verdict:
    return replace(base, status='unmeasured', explanation=f'void: {why}')


def judged(base: Verdict, model: dict, measured: float, why: str) -> Verdict:
    low, high = model['band']
    status = 'ok' if low <= measured <= high else 'alert'
    return replace(base, status=status, measured=measured, expected=model['expected'], low=low, high=high,
                   explanation=f'{why}; against [{low:g}, {high:g}]')


def avoided_swing_reads_verdict(base: Verdict, run, model: dict) -> Verdict:
    labels = ([*model['distances'].values(), *model['quiet_distances'], *model['remaining']]
              + [label for arm in model['reads'].values() for label in arm.values()])
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    refused = '; '.join(f'{spell}: {describe_failures(reasons)}' for spell, reasons
                        in ((spell, failure_reasons(run, spell)) for spell in run.cast_failures) if reasons)
    if refused:
        return void(base, f'refused casts {refused}')
    for ally, label in model['distances'].items():
        if abs(run.values[label] - model['offsets'][ally]) > DISTANCE_TOLERANCE_YD:
            return void(base, f'{ally} stands {run.values[label]:g} yd from the caster, not '
                              f'{model["offsets"][ally]:g} yd')
    nearest = min(run.values[label] for label in model['quiet_distances'])
    if nearest < model['quiet_minimum_yd']:
        return void(base, f'the caster stands {nearest:g} yd from a striker after the quieting relocation')
    control, treatment = ({name: run.values[label] for name, label in model['reads'][arm].items()}
                          for arm in ('control', 'treatment'))
    read = model['read']
    if read == PER_EVENT:
        if control['events']:
            return replace(base, measured=control['events'], expected=0.0,
                           explanation=f'{control["events"]:g} energize events before the passive is learned')
        events = treatment['events'] - control['events']
        total = treatment['total'] - control['total']
        if events < model['min_events']:
            return void(base, f'{events:g} energize events after the learn, fewer than {model["min_events"]}')
        return judged(base, model, total / events, f'{total:g} energy over {events:g} energize events')
    held = {ally: value for ally, value in control.items() if ally in model['offsets'] and value}
    if held:
        return replace(base, measured=1.0, expected=0.0,
                       explanation=f'{sorted(held)} hold the aura before the passive is learned')
    if read == AURA_EDGE:
        inside, outside = treatment[INSIDE], treatment[OUTSIDE]
        status = 'ok' if inside and not outside else 'alert'
        return replace(base, status=status, measured=model['expected'] if status == 'ok' else None,
                       expected=model['expected'],
                       explanation=f'ally at {model["offsets"][INSIDE]:g} yd holds the aura: {bool(inside)}; ally at '
                                   f'{model["offsets"][OUTSIDE]:g} yd holds it: {bool(outside)}')
    if not treatment[INSIDE]:
        return replace(base, measured=0.0, expected=model['expected'],
                       explanation='the grouped ally does not hold the aura after the dodges')
    if read == STAT_DELTA:
        delta = treatment['stat'] - control['stat']
        return judged(base, model, delta, f'{model["metric"]} {control["stat"]:g} before, {treatment["stat"]:g} after')
    largest = max(run.values[label] for label in model['remaining'])
    return judged(base, model, largest, f'largest remaining duration {largest:g} ms over {len(model["remaining"])} '
                                        f'reads')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return avoided_swing_reads_scenario(class_file, avoided_swing_reads_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: avoided_swing_reads_verdict}
