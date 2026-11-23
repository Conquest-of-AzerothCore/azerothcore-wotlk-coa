from dataclasses import dataclass, replace
import math
from pathlib import Path
from statistics import NormalDist

from behaviours import (BEHAVIOUR_METRIC_DELTA, LEARNED_CONTRAST, METRIC_DELTA_MAX_DUMMY_DISTANCE, behaviour_entry,
                        prose_rule, waited_ms)
from compare import (CONTRAST, MINIMUM_BETWEEN_PARTS, Run, Verdict, banded_rate, between_part_judgement,
                     missing_measurement)
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from procs import Z_99, rate_band, wilson_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from stack import TWO_SIDED_99, student_t_quantile
from tooltip import Records
from values import DUMMY_DISTANCE, MAX_SCENARIO_STEPS, TARGET, Expectation, armed_for, dataset, facts_of

KIND = 'stack_chance_rate'
ORDER = 43
METRIC = 'spell_cast_count'
PILOT_TRIALS = 300
CONTROL_MINIMUM_TRIALS = 50
USES_RANGED_SLOT = 0x2
RANGED_CAST_MS = 500
WAIT_MARGIN_MS = 100
TREATMENT = 'treatment'
CONTROL = 'control'
UNLEARNED = 'unlearned'
STATUS_ORDER = ('alert', 'unmeasured', 'insufficient_trials', 'measured', 'ok')
EDGES = ('start trials', 'start events', 'end trials', 'end events')
FLIP_ONE_SIDED = 1e-4
Z_FLIP = NormalDist().inv_cdf(1 - FLIP_ONE_SIDED)
STREAM_LOCATION = {'map': 1, 'x': -6400.0, 'y': -3765.0, 'z': -58.75, 'o': 1.570796}
STREAM_SPAN_YD = 100.0
STREAM_UNIT_REACH_YD = 2.0
STREAM_TOLERANCE_YD = 0.5
STREAM_RELOCATE_YD = 20.0
MAX_STREAMS = 12
SCHEMA_ONE_PLAYERS = 8
STREAM_COPIED_ACTIONS = ('add_item', 'equip', 'set_skill')
STREAM_KEYS = ('actor', 'target', 'caster')
ISOLATION_MARK = ' isolation s'
CROSSING_METRICS = ('spell_damage_count', 'spell_heal_count')


@dataclass(frozen=True)
class Ward:
    entries: tuple[int, ...]
    within_yd: float
    reach_yd: float
    combat_reach_yd: float
    spells: tuple[int, ...]


@dataclass(frozen=True)
class Isolation:
    streams: int
    offset_yd: float
    reach_yd: float
    source: str
    wards: tuple[Ward, ...]


@dataclass(frozen=True)
class Stream:
    index: int
    caster: str
    dummy: str
    suffix: str


@dataclass(frozen=True)
class StackArm:
    stacks: int
    trials: int


@dataclass(frozen=True)
class StackChanceSpec:
    spell: int
    name: str
    quote: str
    talent: int
    stack_aura: int
    trigger_spell: int
    trial_spell: int
    event_spell: int
    event_offset: int
    chance_pct: float
    arms: tuple[StackArm, ...]
    control_trials: int
    unlearned_trials: int
    cast_wait_ms: int
    cast_power: int | None
    learn: tuple[int, ...]
    parts: int
    pilot: bool
    label_suffix: str
    dummy_distance: float | None = None
    isolation: Isolation = Isolation(1, DUMMY_DISTANCE, 0.0, '', ())


def stream_spacing(streams: int) -> float:
    return STREAM_SPAN_YD / (streams - 1)


def isolation_of(entry: dict, kind: str, offset_yd: float | None) -> Isolation:
    spell, streams, raw = int(entry['spell']), int(entry.get('streams', 1)), entry.get('isolation')
    offset = DUMMY_DISTANCE if offset_yd is None else offset_yd
    if streams == 1:
        if raw is not None:
            raise ValueError(f'{spell} {kind} declares an isolation for a single stream')
        return Isolation(1, offset, 0.0, '', ())
    if not 1 < streams <= MAX_STREAMS:
        raise ValueError(f'{spell} {kind} runs {streams} streams, outside 1 to {MAX_STREAMS} (one dummy each)')
    if raw is None or not str(raw.get('source', '')).strip():
        raise ValueError(f'{spell} {kind} runs {streams} streams: settle their isolation (reach_yd, source, wards)')
    wards = tuple(Ward(tuple(int(item) for item in ward['entries']), float(ward['within_yd']),
                       float(ward['reach_yd']), float(ward['combat_reach_yd']),
                       tuple(int(item) for item in ward.get('spells', ()))) for ward in raw.get('wards', ()))
    isolation = Isolation(streams, offset, float(raw['reach_yd']), raw['source'], wards)
    spacing = stream_spacing(streams)
    if spacing <= isolation.reach_yd + 2 * STREAM_UNIT_REACH_YD:
        raise ValueError(f'{spell} {kind} spaces {streams} streams {spacing:.2f} yd apart, not beyond the '
                         f'{isolation.reach_yd:g} yd reach plus two {STREAM_UNIT_REACH_YD:g} yd combat reaches')
    for ward in wards:
        nearest = math.hypot(spacing, offset) - ward.within_yd
        needed = ward.reach_yd + ward.combat_reach_yd + STREAM_UNIT_REACH_YD
        if not ward.entries or nearest <= needed:
            raise ValueError(f'{spell} {kind} puts a ward of {list(ward.entries)} {nearest:.2f} yd from another '
                             f'dummy, not beyond its {ward.reach_yd:g} yd reach and both combat reaches ({needed:g})')
    return isolation


def streams_of(isolation: Isolation) -> list[Stream]:
    if isolation.streams == 1:
        return [Stream(0, CASTER, TARGET, '')]
    return [Stream(index, CASTER if index == 0 else f'{CASTER}{index}', TARGET if index == 0 else f'{TARGET}{index}',
                   f' s{index}') for index in range(isolation.streams)]


def on_stream(step: dict, stream: Stream) -> dict:
    moved = dict(step)
    for key in STREAM_KEYS:
        if moved.get(key) == CASTER:
            moved[key] = stream.caster
        elif moved.get(key) == TARGET:
            moved[key] = stream.dummy
    return moved


def each_stream(steps: list[dict], streams: list[Stream]) -> list[dict]:
    expanded, run = [], []
    for step in steps + [None]:
        if step is not None and step['action'] != 'wait':
            run.append(step)
            continue
        expanded += [on_stream(item, stream) for stream in streams for item in run]
        run = []
        if step is not None:
            expanded.append(step)
    return expanded


def stream_base_steps(armed: dict, streams: list[Stream]) -> list[dict]:
    steps = base_steps(armed)
    copies = [step for step in steps if step['action'] in STREAM_COPIED_ACTIONS]
    return steps + [on_stream(step, stream) for stream in streams[1:] for step in copies]


def bounded(label: str, actor: str, metric: str, low: float, high: float, **fields) -> dict:
    return {'action': 'assert', 'label': label, 'actor': actor, 'metric': metric, **fields, 'min': low, 'max': high}


def relocation(actor: str, axis: str, distance: float) -> list[dict]:
    steps, remaining = [], abs(distance)
    while remaining > 1e-9:
        chunk = min(remaining, STREAM_RELOCATE_YD)
        steps.append({'action': 'relocate', 'actor': actor, axis: round(math.copysign(chunk, distance), 3)})
        remaining -= chunk
    return steps


def placement_steps(isolation: Isolation, streams: list[Stream], mark) -> list[dict]:
    if isolation.streams == 1:
        return []
    spacing, ground = stream_spacing(isolation.streams), STREAM_LOCATION['z']
    steps = []
    for stream in streams:
        steps += relocation(stream.caster, 'dx', stream.index * spacing)
        steps += relocation(stream.caster, 'dy', -isolation.offset_yd)
    for stream in streams:
        for unit, role in ((stream.caster, 'caster'), (stream.dummy, 'dummy')):
            for metric in ('ground_height', 'position_z'):
                steps.append(bounded(mark(f'isolation s{stream.index} {role} {metric}'), unit, metric,
                                     ground - STREAM_TOLERANCE_YD, ground + STREAM_TOLERANCE_YD))
            steps.append(bounded(mark(f'isolation s{stream.index} {role} combat_reach'), unit, 'combat_reach', 0,
                                 STREAM_UNIT_REACH_YD))
        for other in streams:
            gap = math.hypot((stream.index - other.index) * spacing, isolation.offset_yd)
            steps.append(bounded(mark(f'isolation s{stream.index} to s{other.index} distance'), stream.caster,
                                 'distance', round(gap - STREAM_TOLERANCE_YD, 3), round(gap + STREAM_TOLERANCE_YD, 3),
                                 target=other.dummy))
    return steps


def ward_placement_steps(isolation: Isolation, streams: list[Stream], mark, tag: str) -> list[dict]:
    if isolation.streams == 1:
        return []
    return [bounded(mark(f'isolation s{stream.index} ward {entry} {tag} placement'), stream.caster,
                    'owned_creature_count', 0, 0, entry=entry, min_distance=ward.within_yd)
            for stream in streams for ward in isolation.wards for entry in ward.entries]


def ward_hit_steps(isolation: Isolation, streams: list[Stream], mark, tag: str, entry_of) -> list[dict]:
    if isolation.streams == 1:
        return []
    return [bounded(mark(f'isolation s{stream.index} ward {entry_of(ward)} {spell} on s{other.index} {tag}'),
                    stream.caster, 'spell_damage_count', 0, 0, spell=spell, entry=entry_of(ward), target=other.dummy)
            for stream in streams for ward in isolation.wards if ward.spells for other in streams
            if other is not stream for spell in ward.spells]


def crossing_steps(isolation: Isolation, streams: list[Stream], mark, damage: tuple[int, ...],
                   healing: tuple[int, ...]) -> list[dict]:
    if isolation.streams == 1:
        return []
    steps = [bounded(mark(f'isolation s{owner.index} dummy {spell} from s{other.index}'), owner.caster,
                     'spell_damage_count', 0, 0, spell=spell, caster=other.caster, target=owner.dummy)
             for owner in streams for other in streams if other is not owner for spell in damage]
    return steps + [bounded(mark(f'isolation s{owner.index} caster {spell} from s{other.index}'), other.caster,
                            'spell_heal_count', 0, 0, spell=spell, target=owner.caster)
                    for owner in streams for other in streams if other is not owner for spell in healing]


def isolation_bounds(steps: list[dict]) -> list[dict]:
    return [{'label': step['label'], 'min': step['min'], 'max': step['max'],
             'status': 'alert' if step['metric'] in CROSSING_METRICS else 'unmeasured'} for step in steps
            if step['action'] == 'assert' and ISOLATION_MARK in step['label']]


def triggered_spells(records: Records, spell: int) -> tuple[int, ...]:
    found = []
    for effect in range(3):
        triggered = int(records.field('Spell', spell, f'EffectTriggerSpell[{effect}]') or 0)
        if triggered and records.has_spell(triggered):
            found.append(triggered)
    return tuple(found)


def isolation_reading(runs: list[Run], bounds: list[dict]) -> tuple[str, str] | None:
    for run in runs:
        for item in bounds:
            value = run.values.get(item['label'])
            if value is not None and not item['min'] <= value <= item['max']:
                return item['status'], (f'stream isolation: {item["label"]} read {value:g} in {run.key}, outside '
                                        f'[{item["min"]:g}, {item["max"]:g}]')
    for run in runs:
        for item in bounds:
            if run.values.get(item['label']) is None:
                return 'unmeasured', missing_measurement(run, item['label'])
    return None


def stream_scenario(scenario: dict, armed: dict, isolation: Isolation, streams: list[Stream]) -> dict:
    if isolation.streams == 1:
        return scenario
    spacing = stream_spacing(isolation.streams)
    dummy = scenario['creatures'][0]
    scenario['schema'] = 1 if isolation.streams <= SCHEMA_ONE_PLAYERS else 2
    scenario['location'] = dict(STREAM_LOCATION)
    scenario['players'] = [{**player_fixture(armed), 'id': stream.caster} for stream in streams]
    scenario['creatures'] = [{**dummy, 'id': stream.dummy, 'owner': stream.caster,
                              'distance': round(stream.index * spacing, 3)} for stream in streams]
    scenario['contract'] += (f'; {isolation.streams} streams, each its own caster and dummy: the dummies stand '
                             f'{spacing:.2f} yd apart along x on flat open ground at map {STREAM_LOCATION["map"]} '
                             f'({STREAM_LOCATION["x"]:g}, {STREAM_LOCATION["y"]:g}, {STREAM_LOCATION["z"]:g}), each '
                             f'caster {isolation.offset_yd:g} yd from its own dummy and facing it, no group, every '
                             f'cast at its own stream\'s dummy or caster by id; reads per stream, summed per part; '
                             f'isolation: {isolation.source}; asserted: ground, positions, combat reaches and the '
                             f'distance from every caster to every dummy'
                             + (', every ward within its stated distance of its owner' if isolation.wards else '')
                             + ', and no damage or healing from one stream on another stream\'s dummy or caster')
    return scenario


def arm_total_chance(chance: float, stacks: int) -> float:
    return chance * stacks


def flip_proof_trials(total: float, quantile: float) -> int:
    return math.ceil(total * (1 - total) * ((quantile + Z_FLIP) / rate_band(total)) ** 2)


def arm_trials_needed(chance: float, stacks: int, parts: int = 1) -> int:
    quantile = Z_99 if parts < MINIMUM_BETWEEN_PARTS else student_t_quantile(TWO_SIDED_99, parts - 1)
    return flip_proof_trials(arm_total_chance(chance, stacks), quantile)


def interval_name(parts: int) -> str:
    return 'Wilson 99% interval' if parts < MINIMUM_BETWEEN_PARTS else 'between-part Student t 99% interval'


def minimum_wait_ms(records: Records, spell: int) -> int:
    cast_ms = facts_of(records, spell).cast_time_ms
    if cast_ms and records.field('Spell', spell, 'Attributes') & USES_RANGED_SLOT:
        cast_ms += RANGED_CAST_MS
    return max(int(records.field('Spell', spell, 'StartRecoveryTime')), cast_ms) + WAIT_MARGIN_MS


def stack_chance_spec(entry: dict) -> StackChanceSpec:
    trigger = int(entry['trigger_spell'])
    learn = tuple(int(spell) for spell in entry.get('learn', ()))
    spec = StackChanceSpec(
        int(entry['spell']), entry['name'], entry['quote'], int(entry.get('talent', entry['spell'])),
        int(entry['stack_aura']), trigger, int(entry.get('trial_spell', trigger)), int(entry['event_spell']),
        int(entry.get('event_offset', 0)), float(entry['chance_pct']),
        tuple(StackArm(int(arm['stacks']), int(arm['trials'])) for arm in entry['arms']),
        int(entry['control_trials']), int(entry['unlearned_trials']), int(entry['cast_wait_ms']),
        int(entry['cast_power']) if entry.get('cast_power') is not None else None,
        learn if trigger in learn else (trigger, *learn), int(entry.get('parts', 1)), bool(entry.get('pilot', False)),
        entry.get('label_suffix', 'stack_chance'),
        float(entry['dummy_distance']) if entry.get('dummy_distance') is not None else None)
    spec = replace(spec, isolation=isolation_of(entry, KIND, spec.dummy_distance))
    streams = spec.isolation.streams
    if spec.dummy_distance is not None and not 0 < spec.dummy_distance <= METRIC_DELTA_MAX_DUMMY_DISTANCE:
        raise ValueError(f'{spec.spell} {KIND} places the dummy {spec.dummy_distance:g} yd away, outside (0, '
                         f'{METRIC_DELTA_MAX_DUMMY_DISTANCE}] yd')
    chance = spec.chance_pct / 100
    stacks = [arm.stacks for arm in spec.arms]
    if not 0 < chance < 1 or not stacks or len(set(stacks)) != len(stacks) or spec.event_offset < 0:
        raise ValueError(f'{spec.spell} {KIND} needs a chance below 100%, distinct stack arms and no negative offset')
    if spec.talent in spec.learn:
        raise ValueError(f'{spec.spell} {KIND} learns {spec.talent} only between the unlearned and control arms')
    for arm in spec.arms:
        if arm.stacks < 1 or arm_total_chance(chance, arm.stacks) >= 1:
            raise ValueError(f'{spec.spell} {KIND} arm of {arm.stacks} stacks has no chance below 100% to measure')
        needed = PILOT_TRIALS if spec.pilot else arm_trials_needed(chance, arm.stacks, spec.parts)
        planned = arm.trials * spec.parts * streams
        if planned < needed:
            raise ValueError(f'{spec.spell} {KIND} arm of {arm.stacks} stacks casts {planned} times, '
                             f'fewer than the {needed} flip-proof trials the band of its total chance needs')
    for role, trials in ((CONTROL, spec.control_trials), (UNLEARNED, spec.unlearned_trials)):
        if trials * spec.parts * streams < CONTROL_MINIMUM_TRIALS:
            raise ValueError(f'{spec.spell} {KIND} {role} arm casts {trials * spec.parts * streams} times, fewer '
                             f'than {CONTROL_MINIMUM_TRIALS}')
    return spec


def chance_mark(spec: StackChanceSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'.rstrip()


def arm_name(role: str, stacks: int) -> str:
    return f'stacks {stacks}' if role == TREATMENT else role


def stack_chance_scenario(class_file: dict, spec: StackChanceSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.chance_pct)
    facts = facts_of(records, spec.trigger_spell)
    if spec.cast_wait_ms < minimum_wait_ms(records, spec.trigger_spell):
        raise ValueError(f'{spec.spell} {KIND} waits {spec.cast_wait_ms} ms between casts of {spec.trigger_spell}, '
                         f'less than its {minimum_wait_ms(records, spec.trigger_spell)} ms cast and global cooldown')
    costed = facts.mana_cost > 0 or facts.mana_cost_percentage > 0 or facts.mana_cost_per_level > 0
    if costed and spec.cast_power is None:
        raise ValueError(f'{spec.spell} {KIND} casts {spec.trigger_spell}, which costs power: name cast_power')
    if records.field('Spell', spec.trigger_spell, 'Attributes') & USES_RANGED_SLOT and spec.dummy_distance is None:
        raise ValueError(f'{spec.spell} {KIND} casts {spec.trigger_spell}, a ranged-slot spell refused as too close '
                         f'at the default dummy distance: name dummy_distance')
    stack_limit = max(1, int(records.field('Spell', spec.stack_aura, 'StackAmount')))
    if max(arm.stacks for arm in spec.arms) > stack_limit:
        raise ValueError(f'{spec.spell} {KIND} sets more than the {stack_limit} stacks of {spec.stack_aura}')
    armed = armed_for(class_file, records, spec.trigger_spell)
    streams = streams_of(spec.isolation)

    def mark(text: str) -> str:
        return chance_mark(spec, text)

    def trials(stacks: int, count: int) -> list[dict]:
        one = [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.stack_aura, 'stacks': stacks}]
        if costed:
            one.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power})
        if facts.recast_ms:
            one.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
        one += [{'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET},
                {'action': 'wait', 'label': 'cast', 'ms': spec.cast_wait_ms}]
        return each_stream([dict(step) for _ in range(count) for step in one], streams)

    def reads(name: str, edge: str) -> list[dict]:
        return [step for stream in streams for step in (
            measurement(mark(f'{name}{stream.suffix} {edge} trials'), stream.caster, METRIC, spell=spec.trial_spell),
            measurement(mark(f'{name}{stream.suffix} {edge} events'), stream.caster, METRIC, spell=spec.event_spell))]

    def arm_reads(name: str) -> dict | list[dict]:
        groups = [{edge: mark(f'{name}{stream.suffix} {edge}') for edge in EDGES} for stream in streams]
        return groups if spec.isolation.streams > 1 else groups[0]

    top = max(arm.stacks for arm in spec.arms)
    planned = ([(UNLEARNED, top, spec.unlearned_trials), (CONTROL, 0, spec.control_trials)]
               + [(TREATMENT, arm.stacks, arm.trials) for arm in spec.arms])
    arms = []
    steps = stream_base_steps(armed, streams) + each_stream(
        [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.learn], streams)
    steps += placement_steps(spec.isolation, streams, mark)
    chance = spec.chance_pct / 100
    for role, stacks, count in planned:
        if role == CONTROL:
            steps += each_stream([{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}], streams)
        name = arm_name(role, stacks)
        steps += reads(name, 'start') + trials(stacks, count) + reads(name, 'end')
        minimum = (CONTROL_MINIMUM_TRIALS if role != TREATMENT
                   else PILOT_TRIALS if spec.pilot else arm_trials_needed(chance, stacks, spec.parts))
        arms.append({'name': name, 'role': role, 'stacks': stacks, 'minimum': minimum,
                     'expected': arm_total_chance(chance, stacks), 'reads': arm_reads(name)})
    steps += crossing_steps(spec.isolation, streams, mark,
                            tuple(dict.fromkeys((spec.trigger_spell, *triggered_spells(records, spec.trigger_spell)))),
                            ())
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} needs {len(steps)} steps, more than {MAX_SCENARIO_STEPS}: '
                         f'split the trials over more parts')
    dummy = creature_fixture(armed)
    placement = ''
    if spec.dummy_distance is not None:
        dummy['distance'] = spec.dummy_distance
        placement = f' The dummy stands {spec.dummy_distance:g} yd from the caster.'
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour stack chance rate',
        'contract': (f'{spec.trigger_spell} is cast at the dummy with {spec.stack_aura} set by harness set_aura '
                     f'before every cast (precondition fixture): {spec.unlearned_trials} casts at {top} stacks before '
                     f'{spec.talent} is learned and {spec.control_trials} at 0 stacks after (controls: no event), '
                     f'then ' + ', '.join(f'{arm.trials} at {arm.stacks}' for arm in spec.arms)
                     + f'; an event is a cast of {spec.event_spell} beyond {spec.event_offset} per counted cast of '
                       f'{spec.trial_spell}, and each arm\'s total chance, its stacks times {spec.chance_pct:g}%, '
                       f'must hold in a {interval_name(spec.parts)} inside the G-19 band of that total' + placement),
        'players': [player_fixture(armed)],
        'creatures': [dummy],
        'steps': steps}
    scenario = stream_scenario(scenario, armed, spec.isolation, streams)
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'chance_pct': spec.chance_pct,
             'stack_aura': spec.stack_aura, 'trial_spell': spec.trial_spell, 'event_spell': spec.event_spell,
             'event_offset': spec.event_offset, 'pilot': spec.pilot, 'arms': arms}
    if spec.isolation.streams > 1:
        model.update(streams=spec.isolation.streams, isolation=isolation_bounds(steps))
    expectation = Expectation(chance_mark(spec, ''), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell, None,
                              f'{spec.chance_pct:g}% per stack, judged on each arm total',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def arm_counts(runs: list[Run], arm: dict, offset: int) -> list[tuple[float, float]] | str:
    parts = []
    groups = arm['reads'] if isinstance(arm['reads'], list) else [arm['reads']]
    for run in runs:
        events = trials = 0.0
        for reads in groups:
            values = {edge: run.values.get(label) for edge, label in reads.items()}
            missing = next((edge for edge, value in values.items() if value is None), None)
            if missing:
                return missing_measurement(run, reads[missing])
            counted = values['end trials'] - values['start trials']
            trials += counted
            events += values['end events'] - values['start events'] - offset * counted
        parts.append((events, trials))
    return parts


def control_reading(arm: dict, trials: float, events: float) -> tuple[str, str]:
    if trials < arm['minimum']:
        return 'insufficient_trials', f'{arm["name"]}: {trials:g} casts, fewer than the {arm["minimum"]} it needs'
    if events != 0:
        return 'alert', f'{arm["name"]}: {events:g} events in {trials:g} casts, where none may occur'
    return 'ok', (f'{arm["name"]}: 0 events in {trials:g} casts (a rate above '
                  f'{wilson_interval(0, trials)[1]:.4f} excluded at 99%)')


def treatment_reading(arm: dict, parts: list[tuple[float, float]], events: float, trials: float
                      ) -> tuple[str, float | None, float | None, str]:
    expected = float(arm['expected'])
    status, low, high, why = between_part_judgement(parts, arm['minimum'], expected)
    if low is not None:
        status, low, high, why = banded_rate(status, low, high, expected, why)
    return status, low, high, (f'{arm["name"]}: {events:g} events in {trials:g} casts against a total chance of '
                               f'{expected:.4f}, {why}')


def stack_chance_judgement(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    isolation = isolation_reading(runs, model.get('isolation', []))
    if isolation:
        return replace(base, status=isolation[0], explanation=isolation[1])
    detail, treated = [], []
    controls_held = True
    for arm in model['arms']:
        parts = arm_counts(runs, arm, int(model['event_offset']))
        if isinstance(parts, str):
            return replace(base, status='unmeasured', explanation=parts)
        events, trials = sum(count for count, _ in parts), sum(count for _, count in parts)
        reading = {'arm': arm['name'], 'stacks': arm['stacks'], 'casts': trials, 'events': events}
        if arm['role'] != TREATMENT:
            status, why = control_reading(arm, trials, events)
            controls_held = controls_held and status == 'ok'
        else:
            status, low, high, why = treatment_reading(arm, parts, events, trials)
            reading.update(expected=arm['expected'], band=rate_band(arm['expected']), low=low, high=high,
                           measured=events / trials if trials > 0 else None)
        reading.update(status=status, reason=why)
        detail.append(reading)
        if arm['role'] == TREATMENT:
            treated.append(reading)
    status = min((item['status'] for item in detail), key=STATUS_ORDER.index)
    deciding = min(treated, key=lambda item: STATUS_ORDER.index(item['status']), default={})
    fixture = (f'{model["stack_aura"]} stacks set by harness set_aura before every cast (precondition fixture, '
               f'G-21 point 6)')
    notes = '; '.join(item['reason'] for item in detail)
    contrast = {CONTRAST: LEARNED_CONTRAST} if controls_held else {}
    return replace(base, status=status, measured=deciding.get('measured'), expected=deciding.get('expected'),
                   low=deciding.get('low'), high=deciding.get('high'),
                   detail={'arms': detail, 'parts': len(runs), **contrast}, explanation=f'{fixture}; {notes}')


def stack_chance_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return stack_chance_judgement(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return stack_chance_scenario(class_file, stack_chance_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'stack_chance')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: stack_chance_verdict}
POOLED_JUDGE = stack_chance_judgement
