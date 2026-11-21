from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, LEARNED_CONTRAST, METRIC_DELTA_MAX_DUMMY_DISTANCE, behaviour_entry, \
    prose_rule, waited_ms
from compare import CONTRAST, Verdict, Run, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from kinds.stack_chance_rate import (CONTROL_MINIMUM_TRIALS, PILOT_TRIALS, STATUS_ORDER, arm_trials_needed,
                                     control_reading, interval_name, minimum_wait_ms, treatment_reading)
from procs import rate_band
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import MAX_SCENARIO_STEPS, TARGET, Expectation, armed_for, dataset, facts_of, fixture_health_step

KIND = 'flat_chance_rate'
ORDER = 46
METRIC = 'flat_chance_rate'
UNLEARNED = 'unlearned'
TREATMENT = 'treatment'
TRIGGER, SETUP, START, END, WAIT = 'trigger', 'setup', 'start', 'end', 'wait'
TOKENS = (TRIGGER, SETUP, START, END, WAIT)
TRIAL_METRICS = ('spell_damage_count', 'spell_heal_count', 'spell_cast_count', 'owned_creature_spell_cast_count')
EVENT_METRICS = ('spell_cast_count', 'owned_creature_summon_count', 'owned_creature_spell_cast_count')
OWNED_METRICS = ('owned_creature_spell_cast_count',)
TARGETS = (TARGET, CASTER)
EDGES = ('start trials', 'start events', 'end trials', 'end events')


@dataclass(frozen=True)
class Read:
    metric: str
    spell: int | None
    entry: int | None
    target: str | None
    periodic: bool | None


@dataclass(frozen=True)
class Setup:
    spell: int
    target: str
    power: int | None
    every: int


@dataclass(frozen=True)
class Step:
    token: str
    wait_ms: int


@dataclass(frozen=True)
class FlatChanceSpec:
    spell: int
    name: str
    quote: str
    chance_pct: float
    talents: tuple[int, ...]
    learn: tuple[int, ...]
    trigger_spell: int
    trigger_target: str
    cast_power: int | None
    caster_health_pct: int | None
    attempt_auras: tuple[tuple[int, int, str], ...]
    stop_trigger_aura: bool
    setup: Setup | None
    unlearned_setup: Setup | None
    unlearned_entry: int | None
    layout: tuple[Step, ...]
    trial: Read
    event: Read
    events_per_proc: int
    cycles: int
    unlearned_cycles: int
    trials_per_cycle: float
    parts: int
    pilot: bool
    label_suffix: str
    dummy_distance: float | None


def read_of(entry: dict, allowed: tuple[str, ...], role: str, spell: int) -> Read:
    metric = entry['metric']
    if metric not in allowed:
        raise ValueError(f'{spell} {KIND} {role} metric {metric!r} is not one of {allowed}')
    target = entry.get('target')
    if target is not None and target not in TARGETS:
        raise ValueError(f'{spell} {KIND} {role} target {target!r} is not one of {TARGETS}')
    read = Read(metric, int(entry['spell']) if entry.get('spell') is not None else None,
                int(entry['entry']) if entry.get('entry') is not None else None, target,
                bool(entry['periodic']) if entry.get('periodic') is not None else None)
    if metric == 'owned_creature_summon_count' and (read.entry is None or read.spell is not None):
        raise ValueError(f'{spell} {KIND} {role} counts summons of one creature entry and names no spell')
    if metric != 'owned_creature_summon_count' and read.spell is None:
        raise ValueError(f'{spell} {KIND} {role} metric {metric} needs its spell')
    if metric in OWNED_METRICS and read.entry is None:
        raise ValueError(f'{spell} {KIND} {role} metric {metric} needs the owned creature entry')
    if read.periodic is not None and metric != 'spell_damage_count':
        raise ValueError(f'{spell} {KIND} {role} filters periodic events of spell_damage_count only')
    return read


def setup_of(entry: dict | None) -> Setup | None:
    if entry is None:
        return None
    setup = Setup(int(entry['spell']), entry.get('target', CASTER),
                  int(entry['power']) if entry.get('power') is not None else None, int(entry.get('every', 1)))
    if setup.target not in TARGETS or setup.every < 1:
        raise ValueError(f'setup {entry!r} needs a target of {TARGETS} and a positive every')
    return setup


def layout_of(entry: dict, has_setup: bool) -> tuple[Step, ...]:
    raw = entry.get('layout') or ([{'do': SETUP, 'wait_ms': int(entry['setup_wait_ms'])}] if has_setup else []) + [
        {'do': TRIGGER, 'wait_ms': int(entry['cast_wait_ms'])}]
    layout = tuple(Step(item['do'], int(item.get('wait_ms', item.get('ms', 0)))) for item in raw)
    tokens = [step.token for step in layout]
    if any(token not in TOKENS for token in tokens) or TRIGGER not in tokens:
        raise ValueError(f'{entry["spell"]} {KIND} layout {tokens} needs a trigger and only {TOKENS}')
    if (SETUP in tokens) != has_setup or tokens.count(SETUP) > 1:
        raise ValueError(f'{entry["spell"]} {KIND} layout {tokens} and its setup disagree')
    if tokens.count(START) != tokens.count(END) or tokens.count(START) > 1 or (
            START in tokens and tokens.index(START) > tokens.index(END)):
        raise ValueError(f'{entry["spell"]} {KIND} layout {tokens} needs one start read before one end read or none')
    if any(step.wait_ms < 0 for step in layout):
        raise ValueError(f'{entry["spell"]} {KIND} layout {tokens} has a negative wait')
    return layout


def flat_chance_spec(entry: dict) -> FlatChanceSpec:
    spell = int(entry['spell'])
    setup = setup_of(entry.get('setup'))
    unlearned = entry.get('unlearned', {})
    spec = FlatChanceSpec(
        spell, entry['name'], entry['quote'], float(entry['chance_pct']),
        tuple(int(talent) for talent in entry.get('talents', (spell,))),
        tuple(int(item) for item in entry.get('learn', ())), int(entry['trigger_spell']),
        entry.get('trigger_target', TARGET), int(entry['cast_power']) if entry.get('cast_power') is not None else None,
        int(entry['caster_health_pct']) if entry.get('caster_health_pct') is not None else None,
        tuple((int(aura['spell']), int(aura['stacks']), aura['source']) for aura in entry.get('attempt_auras', ())),
        bool(entry.get('stop_trigger_aura', False)), setup, setup_of(unlearned.get('setup')),
        int(unlearned['entry']) if unlearned.get('entry') is not None else None, layout_of(entry, setup is not None),
        read_of(entry['trial'], TRIAL_METRICS, 'trial', spell), read_of(entry['event'], EVENT_METRICS, 'event', spell),
        int(entry.get('events_per_proc', 1)), int(entry['cycles']), int(entry['unlearned_cycles']),
        float(entry['trials_per_cycle']), int(entry.get('parts', 1)), bool(entry.get('pilot', False)),
        entry.get('label_suffix', 'flat_chance'),
        float(entry['dummy_distance']) if entry.get('dummy_distance') is not None else None)
    chance = spec.chance_pct / 100
    if not 0 < chance < 1 or spec.events_per_proc < 1 or spec.trials_per_cycle <= 0:
        raise ValueError(f'{spell} {KIND} needs a chance below 100%, a positive events_per_proc and trials_per_cycle')
    if spec.trigger_target not in TARGETS:
        raise ValueError(f'{spell} {KIND} trigger target {spec.trigger_target!r} is not one of {TARGETS}')
    if any(talent in spec.learn for talent in spec.talents):
        raise ValueError(f'{spell} {KIND} learns its talents only between the unlearned and treatment arms')
    if spec.caster_health_pct is not None and not 0 < spec.caster_health_pct < 100:
        raise ValueError(f'{spell} {KIND} holds the caster at {spec.caster_health_pct}%, outside (0, 100)')
    if spec.stop_trigger_aura and spec.trigger_target != TARGET:
        raise ValueError(f'{spell} {KIND} removes the trigger aura from the dummy only')
    if spec.dummy_distance is not None and not 0 < spec.dummy_distance <= METRIC_DELTA_MAX_DUMMY_DISTANCE:
        raise ValueError(f'{spell} {KIND} places the dummy {spec.dummy_distance:g} yd away, outside (0, '
                         f'{METRIC_DELTA_MAX_DUMMY_DISTANCE}] yd')
    if (spec.unlearned_setup is not None or spec.unlearned_entry is not None) and spec.setup is None:
        raise ValueError(f'{spell} {KIND} overrides the unlearned setup of an entry with no setup')
    planned = spec.cycles * spec.trials_per_cycle * spec.parts
    needed = PILOT_TRIALS if spec.pilot else arm_trials_needed(chance, 1, spec.parts)
    if planned < needed:
        raise ValueError(f'{spell} {KIND} plans {planned:g} trials over {spec.parts} part(s), fewer than the '
                         f'{needed} flip-proof trials the band of {spec.chance_pct:g}% needs')
    if spec.unlearned_cycles * spec.trials_per_cycle * spec.parts < CONTROL_MINIMUM_TRIALS:
        raise ValueError(f'{spell} {KIND} unlearned arm plans fewer than {CONTROL_MINIMUM_TRIALS} trials')
    return spec


def chance_mark(spec: FlatChanceSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'.rstrip()


def read_step(label: str, read: Read, entry: int | None) -> dict:
    fields = {}
    if read.spell is not None:
        fields['spell'] = read.spell
    if read.entry is not None:
        fields['entry'] = read.entry if entry is None or read.metric not in OWNED_METRICS else entry
    if read.target is not None:
        fields['target'] = read.target
    if read.periodic is not None:
        fields['periodic'] = read.periodic
    return measurement(label, CASTER, read.metric, **fields)


def costed(records: Records, spell: int) -> bool:
    facts = facts_of(records, spell)
    return facts.mana_cost > 0 or facts.mana_cost_percentage > 0 or facts.mana_cost_per_level > 0


def cast_steps(records: Records, spell: int, target: str, power: int | None) -> list[dict]:
    facts = facts_of(records, spell)
    steps = []
    if costed(records, spell):
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power})
    if facts.recast_ms:
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell})
    return steps + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target}]


def check_power(records: Records, spec: FlatChanceSpec, spell: int, power: int | None, role: str):
    if costed(records, spell) and power is None:
        raise ValueError(f'{spec.spell} {KIND} {role} {spell} costs power: name its power')


def check_spacing(records: Records, spec: FlatChanceSpec, setup: Setup | None):
    casts = []
    for step in spec.layout:
        if step.token == TRIGGER:
            casts.append((spec.trigger_spell, step.wait_ms))
        elif step.token == SETUP and setup is not None:
            casts.append((setup.spell, step.wait_ms))
        elif casts:
            casts[-1] = (casts[-1][0], casts[-1][1] + step.wait_ms)
    for spell, waited in casts:
        if waited < minimum_wait_ms(records, spell):
            raise ValueError(f'{spec.spell} {KIND} waits {waited} ms after {spell}, less than its '
                             f'{minimum_wait_ms(records, spell)} ms cast and global cooldown')


def cycle_steps(records: Records, spec: FlatChanceSpec, setup: Setup | None, index: int, reads) -> list[dict]:
    steps = []
    for step in spec.layout:
        if step.token == SETUP:
            if setup is not None and index % setup.every == 0:
                steps += cast_steps(records, setup.spell, setup.target, setup.power)
                steps.append({'action': 'wait', 'label': 'setup', 'ms': step.wait_ms})
            continue
        if step.token == TRIGGER:
            if spec.caster_health_pct is not None:
                steps.append(fixture_health_step(CASTER, spec.caster_health_pct))
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}
                      for aura, stacks, _ in spec.attempt_auras]
            steps += cast_steps(records, spec.trigger_spell, spec.trigger_target, spec.cast_power)
            steps.append({'action': 'wait', 'label': 'cast', 'ms': step.wait_ms})
            if spec.stop_trigger_aura:
                steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.trigger_spell, 'stacks': 0,
                              'target': TARGET})
            continue
        if step.token in (START, END):
            steps += reads(index, step.token)
            continue
        steps.append({'action': 'wait', 'label': 'cycle', 'ms': step.wait_ms})
    return steps


def per_cycle(spec: FlatChanceSpec) -> bool:
    return any(step.token == START for step in spec.layout)


def arm_plan(records: Records, spec: FlatChanceSpec, role: str, cycles: int) -> tuple[list[dict], list[dict]]:
    setup = spec.unlearned_setup or spec.setup if role == UNLEARNED else spec.setup
    entry = spec.unlearned_entry if role == UNLEARNED else None
    segments, steps = [], []

    def reads(index: int | None, edge: str) -> list[dict]:
        name = role if index is None else f'{role} c{index}'
        segment = {f'{edge} trials': chance_mark(spec, f'{name} {edge} trials'),
                   f'{edge} events': chance_mark(spec, f'{name} {edge} events')}
        if edge == START:
            segments.append(segment)
        else:
            segments[-1].update(segment)
        return [read_step(segment[f'{edge} trials'], spec.trial, entry),
                read_step(segment[f'{edge} events'], spec.event, entry)]

    if not per_cycle(spec):
        steps += reads(None, START)
    for index in range(cycles):
        steps += cycle_steps(records, spec, setup, index, reads if per_cycle(spec) else None)
    if not per_cycle(spec):
        steps += reads(None, END)
    return steps, segments


def flat_chance_scenario(class_file: dict, spec: FlatChanceSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.chance_pct)
    check_power(records, spec, spec.trigger_spell, spec.cast_power, 'trigger')
    for setup in (spec.setup, spec.unlearned_setup):
        if setup is not None:
            check_power(records, spec, setup.spell, setup.power, 'setup')
            check_spacing(records, spec, setup)
    check_spacing(records, spec, None)
    armed = armed_for(class_file, records, spec.trigger_spell)
    chance = spec.chance_pct / 100
    needed = PILOT_TRIALS if spec.pilot else arm_trials_needed(chance, 1, spec.parts)
    steps = base_steps(armed) + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                                 for spell in dict.fromkeys((spec.trigger_spell, *spec.learn))]
    unlearned_steps, unlearned_segments = arm_plan(records, spec, UNLEARNED, spec.unlearned_cycles)
    treatment_steps, treatment_segments = arm_plan(records, spec, TREATMENT, spec.cycles)
    steps += unlearned_steps + [{'action': 'learn', 'actor': CASTER, 'spell': talent} for talent in spec.talents]
    steps += treatment_steps
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} needs {len(steps)} steps, more than {MAX_SCENARIO_STEPS}: split the '
                         f'cycles over more parts')
    arms = [{'name': UNLEARNED, 'role': UNLEARNED, 'minimum': CONTROL_MINIMUM_TRIALS, 'expected': 0.0,
             'segments': unlearned_segments},
            {'name': TREATMENT, 'role': TREATMENT, 'minimum': needed, 'expected': chance,
             'segments': treatment_segments}]
    dummy = creature_fixture(armed)
    if spec.dummy_distance is not None:
        dummy['distance'] = spec.dummy_distance
    fixtures = '; '.join([f'{aura} ({stacks} stack) set by harness set_aura before every trigger cast: {source}'
                          for aura, stacks, source in spec.attempt_auras]
                         + ([f'the caster held at {spec.caster_health_pct}% of the 10000 health fixture before every '
                             f'trigger cast'] if spec.caster_health_pct is not None else [])
                         + ([f'{spec.trigger_spell} removed from the dummy after each cast wait (harness set_aura 0)']
                            if spec.stop_trigger_aura else []))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour flat chance rate',
        'contract': (f'{spec.trigger_spell} is cast at the {spec.trigger_target} in cycles '
                     f'{[step.token for step in spec.layout]}; {spec.unlearned_cycles} cycles before '
                     f'{list(spec.talents)} are learned (the unlearned control: no event) and {spec.cycles} after; a '
                     f'trial is a {spec.trial.metric} of {spec.trial.spell}, an event a {spec.event.metric} of '
                     f'{spec.event.spell or spec.event.entry} ({spec.events_per_proc} per proc), and the rate must '
                     f'hold {spec.chance_pct:g}% in a {interval_name(spec.parts)} inside its G-19 band'
                     + (f'; fixtures: {fixtures}' if fixtures else '')),
        'players': [player_fixture(armed)],
        'creatures': [dummy],
        'steps': steps}
    model = {'kind': KIND, 'metric': METRIC, 'evidence_metric': METRIC, 'quote': entry.quote,
             'chance_pct': spec.chance_pct, 'events_per_proc': spec.events_per_proc, 'fixtures': fixtures,
             'trial': spec.trial.metric, 'event': spec.event.metric, 'arms': arms}
    expectation = Expectation(chance_mark(spec, ''), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell, None,
                              f'{spec.chance_pct:g}% per trial', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def arm_counts(runs: list[Run], arm: dict, per_proc: int) -> list[tuple[float, float]] | str:
    parts = []
    for run in runs:
        events = trials = 0.0
        for segment in arm['segments']:
            values = {edge: run.values.get(segment[edge]) for edge in EDGES}
            missing = next((edge for edge, value in values.items() if value is None), None)
            if missing:
                return missing_measurement(run, segment[missing])
            trials += values['end trials'] - values['start trials']
            events += values['end events'] - values['start events']
        parts.append((events / per_proc, trials))
    return parts


def flat_chance_judgement(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    detail, controls_held, deciding = [], True, {}
    for arm in model['arms']:
        parts = arm_counts(runs, arm, int(model['events_per_proc']))
        if isinstance(parts, str):
            return replace(base, status='unmeasured', explanation=parts)
        if any(events < 0 or trials < 0 for events, trials in parts):
            return replace(base, status='alert', explanation=f'{arm["name"]}: a count fell between its reads')
        events, trials = sum(count for count, _ in parts), sum(count for _, count in parts)
        reading = {'arm': arm['name'], 'trials': trials, 'procs': events}
        if arm['role'] == UNLEARNED:
            status, why = control_reading(arm, trials, events)
            controls_held = status == 'ok'
        else:
            status, low, high, why = treatment_reading(arm, parts, events, trials)
            reading.update(expected=arm['expected'], band=rate_band(arm['expected']), low=low, high=high,
                           measured=events / trials if trials > 0 else None)
            deciding = reading
        reading.update(status=status, reason=why)
        detail.append(reading)
    status = min((item['status'] for item in detail), key=STATUS_ORDER.index)
    contrast = {CONTRAST: LEARNED_CONTRAST} if controls_held else {}
    notes = '; '.join(item['reason'] for item in detail)
    fixtures = f'fixtures: {model["fixtures"]}; ' if model.get('fixtures') else ''
    return replace(base, status=status, measured=deciding.get('measured'), expected=deciding.get('expected'),
                   low=deciding.get('low'), high=deciding.get('high'),
                   detail={'arms': detail, 'parts': len(runs), **contrast}, explanation=f'{fixtures}{notes}')


def flat_chance_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return flat_chance_judgement(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return flat_chance_scenario(class_file, flat_chance_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'flat_chance')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: flat_chance_verdict}
POOLED_JUDGE = flat_chance_judgement
METRIC_EVIDENCE = {METRIC: 'event'}
