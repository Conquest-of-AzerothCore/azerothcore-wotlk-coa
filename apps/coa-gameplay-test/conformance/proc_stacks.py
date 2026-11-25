from profile import CASTER, measurement

AURA_STACKS = 'aura_stacks'
STACK_EVENTS = 'stack_events'
STACK_AURA = 'stack_aura'
STACK_SET = 'stack_set'
STACK_PER_CAST = 'stack_per_cast'
STACK_CAP = 'stack_cap'
AVOIDED = 'avoided'
TAKEN_HIT = 'taken_hit'
CAPPED_TRIGGERS = (AVOIDED, TAKEN_HIT)
CAST_COUNT = 'spell_cast_count'
REFUSED_FIELDS = ('streams', 'extra_event_terms', 'event_actor', 'trial_readings', 'most_procs_per_trigger',
                  'trigger_spells', 'events_baseline_per_attempt')


def whole(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def counts_stacks(entry: dict) -> bool:
    if entry.get('event_metric') != AURA_STACKS:
        return False
    aura, where = entry['aura'], f'Proc {entry["aura"]} counts {AURA_STACKS} events'
    stack, held, per_cast = entry.get(STACK_AURA), entry.get(STACK_SET), entry.get(STACK_PER_CAST)
    if entry['trigger']['action'] not in ('cast', *CAPPED_TRIGGERS):
        raise ValueError(f'{where}, which needs a cast, an avoided or a taken_hit trigger')
    if capped_trigger(entry) and (per_cast != 0 or not whole(entry.get(STACK_CAP)) or entry[STACK_CAP] <= held):
        raise ValueError(f'{where} on an {entry["trigger"]["action"]} trigger with a {STACK_PER_CAST} of 0 and a '
                         f'whole {STACK_CAP} above the {STACK_SET}')
    if not capped_trigger(entry) and STACK_CAP in entry:
        raise ValueError(f'{where}: {STACK_CAP} is read on an avoided or a taken_hit trigger only')
    if not (whole(stack) and stack > 0 and whole(held) and held >= 0 and whole(per_cast) and held + per_cast >= 0):
        raise ValueError(f'{where} with a positive {STACK_AURA}, a {STACK_SET} of at least 0 and a whole '
                         f'{STACK_PER_CAST} that leaves at least 0 stacks')
    fixtures = [fixture for fixture in entry.get('attempt_auras', [])
                if fixture.get('spell') == stack and 'target' not in fixture]
    if len(fixtures) != 1 or fixtures[0].get('stacks') != held or not fixtures[0].get('source'):
        raise ValueError(f'{where}: attempt_auras sets {stack} on the caster to the {STACK_SET} {held} before each '
                         f'cast, once, with its source')
    if entry.get('baseline') is not True:
        raise ValueError(f'{where} without the baseline arm that must read no event')
    per_proc = entry.get('events_per_proc')
    if not (whole(per_proc) and per_proc > 0):
        raise ValueError(f'{where} with a positive whole events_per_proc')
    present = [field for field in REFUSED_FIELDS if entry.get(field)]
    if present:
        raise ValueError(f'{where}, which cannot be combined with {present}')
    return True


def avoided(entry: dict) -> bool:
    return entry['trigger']['action'] == AVOIDED


def taken_hit(entry: dict) -> bool:
    return entry['trigger']['action'] == TAKEN_HIT


def capped_trigger(entry: dict) -> bool:
    return entry['trigger']['action'] in CAPPED_TRIGGERS


def avoided_attempt_steps(entry: dict, attempts: int, swing_ms: int, baseline: bool = False) -> list[dict]:
    from proc_avoided import avoidance_steps
    return [step for attempt in range(1, attempts + 1)
            for step in avoidance_steps(entry) + [{'action': 'wait', 'ms': swing_ms},
                                                  read_step(entry, read_label(entry['aura'], attempt, baseline))]]


def read_label(aura: int, attempt: int, baseline: bool = False) -> str:
    return f'{aura} proc {"baseline " if baseline else ""}stacks {attempt}'


def drained_label(aura: int, baseline: bool = False) -> str:
    return f'{aura} proc {"baseline " if baseline else ""}stacks after the drain'


def drain_steps(entry: dict, drain: dict, baseline: bool = False) -> list[dict]:
    reset = {'action': 'set_aura', 'actor': CASTER, 'spell': entry[STACK_AURA], 'stacks': entry[STACK_SET]}
    return [reset, drain, read_step(entry, drained_label(entry['aura'], baseline))]


def read_step(entry: dict, label: str) -> dict:
    return measurement(label, CASTER, AURA_STACKS, spell=entry[STACK_AURA])


def baseline_casts_label(aura: int) -> str:
    return f'{aura} proc baseline completed casts'


def baseline_casts_step(entry: dict) -> dict:
    return measurement(baseline_casts_label(entry['aura']), CASTER, CAST_COUNT, spell=entry['trigger']['spell'])


def stack_model(entry: dict, attempts_label: str) -> dict:
    return {'aura': entry[STACK_AURA], 'set': entry[STACK_SET], 'per_cast': entry[STACK_PER_CAST],
            'completed': attempts_label, **({'cap': entry[STACK_CAP]} if capped_trigger(entry) else {})}


def baseline_model(entry: dict, attempts: int, completed: str | None = None) -> dict:
    return {**stack_model(entry, completed or baseline_casts_label(entry['aura'])),
            'reads': [read_label(entry['aura'], attempt, True) for attempt in range(1, attempts + 1)]
            + [drained_label(entry['aura'], True)]}


def rule(entry: dict, baseline_attempts: int) -> str:
    stack, held, per_cast = entry[STACK_AURA], entry[STACK_SET], entry[STACK_PER_CAST]
    if avoided(entry):
        return (f'; events: the stacks of aura {stack} on the caster read after each swing interval, from {held} set '
                f'before it as a precondition fixture, not the subject; events = the sum of the reads - {held} x the '
                f'intervals, {entry["events_per_proc"]} per proc; the drain is one more interval without swings '
                f'counted, reset to {held} before it and read after it; a read at the {entry[STACK_CAP]}-stack cap '
                f'voids the part, since a capped gain is not read; the baseline swing intervals before the passive is '
                f'learned read the same way and must give no event')
    if taken_hit(entry):
        return (f'; events: the stacks of aura {stack} on the caster read after each strike interval, from {held} set '
                f'before the strike as a precondition fixture, not the subject; events = the sum of the reads - {held} '
                f'x the intervals, {entry["events_per_proc"]} per proc; the drain is one more interval without a '
                f'strike, reset to {held} before it and read after it; a read at the {entry[STACK_CAP]}-stack cap '
                f'voids the part, since a capped gain is not read; the {baseline_attempts} baseline strikes before the '
                f'passive is learned read the same way and must give no event')
    return (f'; events: the stacks of aura {stack} on the caster read after each cast, from {held} set before the cast '
            f'as a precondition fixture, not the subject; a completed cast without a proc changes them by '
            f'{per_cast:+d}; events = the sum of the reads - {held} x the attempts - ({per_cast:+d}) x the completed '
            f'casts, {entry["events_per_proc"]} per proc (a refused cast reads {held} and adds none); the drain is one '
            f'more window without a cast, reset to {held} before it and read after it, so late periodic events are '
            f'read like the trials they add; the baseline arm '
            f'of {baseline_attempts} casts before the passive is learned reads the same way and must give no event')


def events(model: dict, reads: list[float], attempts: float, completed: float) -> float:
    return sum(reads) - model['set'] * attempts - model['per_cast'] * completed


def baseline_held(baseline: dict, values: dict) -> list[float | None]:
    model = baseline[STACK_EVENTS]
    trials, completed = values.get(baseline['trials']), values.get(model['completed'])
    reads = [values.get(label) for label in model['reads']]
    if trials is None or completed is None or None in reads:
        return [None, None]
    return [trials, events(model, reads, len(reads), completed)]


def baseline_completed(part_model: dict, values: dict) -> float:
    baseline = part_model.get('baseline') or {}
    return values.get(baseline[STACK_EVENTS]['completed'], 0.0) if STACK_EVENTS in baseline else 0.0


def capped(part_model: dict, values: dict) -> list[str]:
    model = part_model.get(STACK_EVENTS) or {}
    if 'cap' not in model:
        return []
    baseline = (part_model.get('baseline') or {}).get(STACK_EVENTS) or {}
    labels = part_model.get('event_labels', []) + baseline.get('reads', [])
    return [label for label in labels if (values.get(label) or 0) >= model['cap']]


def part_offset(part_model: dict, values: dict) -> float:
    model = part_model.get(STACK_EVENTS)
    if not model:
        return 0.0
    completed = values[model['completed']] - baseline_completed(part_model, values)
    return events(model, [], part_model['part_attempts'] + 1, completed)
