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
from values import MAX_SCENARIO_STEPS, TARGET, Expectation, armed_for, dataset, facts_of

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
        if arm.trials * spec.parts < needed:
            raise ValueError(f'{spec.spell} {KIND} arm of {arm.stacks} stacks casts {arm.trials * spec.parts} times, '
                             f'fewer than the {needed} flip-proof trials the band of its total chance needs')
    for role, trials in ((CONTROL, spec.control_trials), (UNLEARNED, spec.unlearned_trials)):
        if trials * spec.parts < CONTROL_MINIMUM_TRIALS:
            raise ValueError(f'{spec.spell} {KIND} {role} arm casts {trials * spec.parts} times, fewer than '
                             f'{CONTROL_MINIMUM_TRIALS}')
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

    def trials(stacks: int, count: int) -> list[dict]:
        one = [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.stack_aura, 'stacks': stacks}]
        if costed:
            one.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power})
        if facts.recast_ms:
            one.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
        one += [{'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET},
                {'action': 'wait', 'label': 'cast', 'ms': spec.cast_wait_ms}]
        return [dict(step) for _ in range(count) for step in one]

    def reads(name: str, edge: str) -> list[dict]:
        return [measurement(chance_mark(spec, f'{name} {edge} trials'), CASTER, METRIC, spell=spec.trial_spell),
                measurement(chance_mark(spec, f'{name} {edge} events'), CASTER, METRIC, spell=spec.event_spell)]

    top = max(arm.stacks for arm in spec.arms)
    planned = ([(UNLEARNED, top, spec.unlearned_trials), (CONTROL, 0, spec.control_trials)]
               + [(TREATMENT, arm.stacks, arm.trials) for arm in spec.arms])
    arms, steps = [], (base_steps(armed) + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                                             for spell in spec.learn])
    chance = spec.chance_pct / 100
    for role, stacks, count in planned:
        if role == CONTROL:
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.talent})
        name = arm_name(role, stacks)
        steps += reads(name, 'start') + trials(stacks, count) + reads(name, 'end')
        minimum = (CONTROL_MINIMUM_TRIALS if role != TREATMENT
                   else PILOT_TRIALS if spec.pilot else arm_trials_needed(chance, stacks, spec.parts))
        arms.append({'name': name, 'role': role, 'stacks': stacks, 'minimum': minimum,
                     'expected': arm_total_chance(chance, stacks),
                     'reads': {edge: chance_mark(spec, f'{name} {edge}') for edge in EDGES}})
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
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'chance_pct': spec.chance_pct,
             'stack_aura': spec.stack_aura, 'trial_spell': spec.trial_spell, 'event_spell': spec.event_spell,
             'event_offset': spec.event_offset, 'pilot': spec.pilot, 'arms': arms}
    expectation = Expectation(chance_mark(spec, ''), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell, None,
                              f'{spec.chance_pct:g}% per stack, judged on each arm total',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def arm_counts(runs: list[Run], arm: dict, offset: int) -> list[tuple[float, float]] | str:
    parts = []
    for run in runs:
        values = {edge: run.values.get(label) for edge, label in arm['reads'].items()}
        missing = next((edge for edge, value in values.items() if value is None), None)
        if missing:
            return missing_measurement(run, arm['reads'][missing])
        counted = values['end trials'] - values['start trials']
        parts.append((values['end events'] - values['start events'] - offset * counted, counted))
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
