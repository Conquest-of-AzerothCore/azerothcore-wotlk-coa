from profile import CASTER, measurement

AURA_STACKS = 'aura_stacks'
STACK_EVENTS = 'stack_events'
STACK_AURA = 'stack_aura'
STACK_SET = 'stack_set'
STACK_PER_CAST = 'stack_per_cast'
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
    if entry['trigger']['action'] != 'cast':
        raise ValueError(f'{where}, which needs a cast trigger')
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
            'completed': attempts_label}


def baseline_model(entry: dict, attempts: int) -> dict:
    return {**stack_model(entry, baseline_casts_label(entry['aura'])),
            'reads': [read_label(entry['aura'], attempt, True) for attempt in range(1, attempts + 1)]
            + [drained_label(entry['aura'], True)]}


def rule(entry: dict, baseline_attempts: int) -> str:
    stack, held, per_cast = entry[STACK_AURA], entry[STACK_SET], entry[STACK_PER_CAST]
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


def part_offset(part_model: dict, values: dict) -> float:
    model = part_model.get(STACK_EVENTS)
    if not model:
        return 0.0
    completed = values[model['completed']] - baseline_completed(part_model, values)
    return events(model, [], part_model['part_attempts'] + 1, completed)
