from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, LEARNED_CONTRAST, STRIKER_DISTANCE, STRIKER_HEALTH,
                        TAKEN_OUTCOME_ENGAGE_MS, TAKEN_OUTCOME_SWING_MARGIN_MS, behaviour_entry, prose_rule, waited_ms)
from compare import Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, TIMEOUT_MARGIN_MS
from procs import swing_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_ENTRY, Expectation, dataset

KIND = 'parried_restore'
ORDER = 2
METRIC = 'parried_restore_gain'
ATTACKER = 'attacker1'
PARRY_STATE = 3
RAGE = 1
ARMS = ('control', 'treatment')
RESOURCES = ('health', 'rage')
COUNTED_READS = ('swings', 'parried', 'heals', 'healed', 'energizes', 'energized')
BASE_READS = tuple(f'base_{read}' for read in COUNTED_READS)
CYCLE_READS = ('set_health', 'set_max_health', 'set_rage', 'set_max_rage', *BASE_READS, *COUNTED_READS, 'health',
               'max_health', 'rage')
EVENTS = {'health': ('heals', 'healed'), 'rage': ('energizes', 'energized')}


@dataclass(frozen=True)
class ParriedRestoreSpec:
    spell: int
    name: str
    quote: str
    percent_spell: int
    heal_spell: int
    energize_spell: int
    health: tuple[int, int]
    rage: int
    cycles: int
    cycle_ms: int
    attacker_swing_ms: int
    attacker_entry: int = DUMMY_ENTRY
    attacker_auras: tuple[int, ...] = ()
    min_parried: int = 10
    label_suffix: str = 'parried'


def parried_restore_spec(entry: dict) -> ParriedRestoreSpec:
    health = entry['health']
    if not (isinstance(health, list) and len(health) == 2 and all(type(value) is int for value in health)
            and 0 < health[0] < health[1]):
        raise ValueError(f'{entry["spell"]} parried_restore health is [value, maximum] with 0 < value < maximum')
    spec = ParriedRestoreSpec(entry['spell'], entry['name'], entry['quote'], int(entry['percent_spell']),
                              int(entry['heal_spell']), int(entry['energize_spell']), (health[0], health[1]),
                              int(entry['rage']), int(entry['cycles']), int(entry['cycle_ms']),
                              int(entry['attacker_swing_ms']), int(entry.get('attacker_entry', DUMMY_ENTRY)),
                              tuple(int(aura) for aura in entry.get('attacker_auras', ())),
                              int(entry.get('min_parried', 10)), entry.get('label_suffix', 'parried'))
    if not 0 < spec.cycle_ms < spec.attacker_swing_ms:
        raise ValueError(f'{spec.spell} parried_restore cycles are shorter than one attacker swing, so a cycle holds '
                         f'at most one swing')
    if spec.rage < 0 or spec.cycles < 1 or not 1 <= spec.min_parried <= spec.cycles:
        raise ValueError(f'{spec.spell} parried_restore needs a Rage of at least 0, cycles and a parried floor '
                         f'within them')
    return spec


def stated_percent(records: Records, spell: int) -> int:
    die = int(records.field('Spell', spell, 'EffectDieSides[0]') or 0)
    if die > 1:
        raise ValueError(f'{spell} parried_restore needs a fixed EffectBasePoints[0], not a roll of {die}')
    return int(records.field('Spell', spell, 'EffectBasePoints[0]') or 0) + die


def cycle_label(spec: ParriedRestoreSpec, arm: str, cycle: int, read: str) -> str:
    return f'{spec.spell} parried_restore {arm} {cycle} {read}'


def arm_label(spec: ParriedRestoreSpec, arm: str, moment: str, read: str) -> str:
    return f'{spec.spell} parried_restore {arm} {moment} {read}'


def window_reads(spec: ParriedRestoreSpec, label) -> list[dict]:
    return counted_reads(spec, label) + event_reads(spec, label)


def counted_reads(spec: ParriedRestoreSpec, label) -> list[dict]:
    return [measurement(label('swings'), CASTER, 'melee_attacks_taken', target=ATTACKER),
            measurement(label('parried'), CASTER, 'melee_attacks_taken', victim_state=PARRY_STATE, target=ATTACKER)]


def event_reads(spec: ParriedRestoreSpec, label) -> list[dict]:
    return [measurement(label('heals'), CASTER, 'spell_heal_count', spell=spec.heal_spell, target=CASTER),
            measurement(label('healed'), CASTER, 'spell_heal_total', spell=spec.heal_spell, target=CASTER),
            measurement(label('energizes'), CASTER, 'spell_energize_count', spell=spec.energize_spell,
                        target=CASTER, power=RAGE),
            measurement(label('energized'), CASTER, 'spell_energize_total', spell=spec.energize_spell,
                        target=CASTER, power=RAGE)]


def arm_steps(spec: ParriedRestoreSpec, arm: str) -> list[dict]:
    health, maximum = spec.health
    start = lambda read: arm_label(spec, arm, 'start', read)
    steps = window_reads(spec, start)
    for cycle in range(1, spec.cycles + 1):
        read = lambda name, cycle=cycle: cycle_label(spec, arm, cycle, name)
        steps += [{'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 100},
                  {'action': 'set_health', 'actor': CASTER, 'value': health, 'maximum': maximum},
                  {'action': 'set_power', 'actor': CASTER, 'power': RAGE, 'value': spec.rage},
                  measurement(read('set_health'), CASTER, 'health'),
                  measurement(read('set_max_health'), CASTER, 'max_health'),
                  measurement(read('set_rage'), CASTER, 'power', power=RAGE),
                  measurement(read('set_max_rage'), CASTER, 'max_power', power=RAGE),
                  *window_reads(spec, lambda name, read=read: read(f'base_{name}')),
                  {'action': 'wait', 'label': f'{arm} swing {cycle}', 'ms': spec.cycle_ms}]
        steps += window_reads(spec, read) + [
            measurement(read('health'), CASTER, 'health'), measurement(read('max_health'), CASTER, 'max_health'),
            measurement(read('rage'), CASTER, 'power', power=RAGE)]
    return steps + window_reads(spec, lambda read: arm_label(spec, arm, 'end', read))


def parried_restore_scenario(class_file: dict, spec: ParriedRestoreSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    percent = stated_percent(records, spec.percent_spell)
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(percent))
    health, maximum = spec.health
    engage = [{'action': 'set_aura', 'actor': CASTER, 'target': ATTACKER, 'caster': ATTACKER, 'spell': aura,
               'stacks': 1} for aura in spec.attacker_auras]
    engage += [{'action': 'set_health', 'actor': CASTER, 'value': health, 'maximum': maximum},
               {'action': 'attack', 'actor': CASTER, 'target': ATTACKER},
               {'action': 'wait', 'label': f'engage {ATTACKER}',
                'ms': swing_interval(class_file) + TAKEN_OUTCOME_SWING_MARGIN_MS},
               {'action': 'stop_attack', 'actor': CASTER},
               {'action': 'wait', 'label': 'engage', 'ms': TAKEN_OUTCOME_ENGAGE_MS}]
    steps = (base_steps(class_file) + [{'action': 'unlearn', 'actor': CASTER, 'spell': spec.spell}] + engage
             + arm_steps(spec, 'control') + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + arm_steps(spec, 'treatment'))
    waited = waited_ms(steps)
    if waited + TIMEOUT_MARGIN_MS > MAX_ACCELERATED_SCENARIO_MS:
        raise ValueError(f'{spec.spell} parried_restore waits {waited} ms, beyond the accelerated cap')
    rooted = f', carrying {list(spec.attacker_auras)}' if spec.attacker_auras else ''
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour parried restore',
        'contract': f'One aggressive, stationary attacker (creature entry {spec.attacker_entry}, level '
                    f'{class_file["level"]}{rooted}, {spec.attacker_swing_ms} ms swings) melees the caster after one '
                    f'engaging swing. Two arms of {spec.cycles} cycles of {spec.cycle_ms} ms, without {spec.spell} '
                    f'(the control) and with it learned: at each cycle start the caster\'s dodge and parry are set to '
                    f'0% and 100% (set_combat_avoidance, a named precondition fixture of both arms), its health to '
                    f'{health} of {maximum} and its Rage to {spec.rage} raw; after these set steps the health, Rage, '
                    f'swings, parried swings and events are read as the cycle\'s baseline, and at each cycle end the '
                    f'same counts, health and Rage are read; only the events between the two are the cycle\'s judged '
                    f'window. A cycle is shorter than a swing, so it holds at most one swing, taken at the set health '
                    f'and Rage. Each parried swing must restore {percent}% ($s1 of {spec.percent_spell}) of the '
                    f'missing health and Rage, truncated; the {spec.heal_spell} heals and {spec.energize_spell} '
                    f'energizes must match the parried swings. A swing between a cycle end and the next baseline (the '
                    f'read and set gap) is counted and reported; a parried one passes only when its events number it '
                    f'and total the restore at a set state it can have started from.',
        'players': [player_fixture(class_file)],
        'creatures': [{'id': ATTACKER, 'owner': CASTER, 'entry': spec.attacker_entry, 'level': class_file['level'],
                       'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 2, 'stationary': True}],
        'steps': steps,
        'timeout_ms': waited + TIMEOUT_MARGIN_MS}
    model = {'kind': KIND, 'metric': METRIC, 'contrast': LEARNED_CONTRAST, 'quote': entry.quote,
             'percent': percent, 'health': [health, maximum], 'rage': spec.rage, 'min_parried': spec.min_parried,
             'arms': {arm: {'start': {read: arm_label(spec, arm, 'start', read) for read in COUNTED_READS},
                            'end': {read: arm_label(spec, arm, 'end', read) for read in COUNTED_READS},
                            'cycles': [{read: cycle_label(spec, arm, cycle, read)
                                        for read in CYCLE_READS}
                                       for cycle in range(1, spec.cycles + 1)]}
                      for arm in ARMS}}
    rule = prose_rule(entry.quote, spec.spell)
    return scenario, [Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}_{resource}',
                                  BEHAVIOUR_METRIC_DELTA, spec.spell, spec.percent_spell, None, f'{percent}%', rule,
                                  {**model, 'resource': resource}) for resource in RESOURCES]


def restored(missing: int, percent: int) -> int:
    return missing * percent // 100


def arm_reading(run: Run, model: dict, arm: str) -> tuple[list[dict] | None, str | None]:
    labels = model['arms'][arm]
    needed = [*labels['start'].values(), *labels['end'].values(),
              *(label for cycle in labels['cycles'] for label in cycle.values())]
    missing = next((label for label in needed if run.values.get(label) is None), None)
    if missing is not None:
        return None, missing
    value = lambda label: run.values[label]
    cycles, previous = [], {read: value(labels['start'][read]) for read in COUNTED_READS}
    for cycle in labels['cycles']:
        base = {read: value(cycle[f'base_{read}']) for read in COUNTED_READS}
        counted = {read: value(cycle[read]) for read in COUNTED_READS}
        cycles.append({**{read: counted[read] - base[read] for read in COUNTED_READS},
                       **{f'gap_{read}': base[read] - previous[read] for read in COUNTED_READS},
                       **{read: value(cycle[read]) for read in CYCLE_READS
                          if read not in COUNTED_READS and read not in BASE_READS}})
        previous = counted
    cycles.append({f'gap_{read}': value(labels['end'][read]) - previous[read] for read in COUNTED_READS})
    return mended(cycles), None


def torn(earlier: dict, later: dict) -> bool:
    return earlier['swings'] == 0 and any(earlier[read] for read in COUNTED_READS) and later['swings'] >= 1


def moved(source: dict, target: dict, source_prefix: str, target_prefix: str) -> None:
    for read in COUNTED_READS:
        target[f'{target_prefix}{read}'] += source[f'{source_prefix}{read}']
        source[f'{source_prefix}{read}'] = 0


def mended(cycles: list[dict]) -> list[dict]:
    for index, cycle in enumerate(cycles[:-1]):
        cycle['torn'] = []
        gap = {read: cycle[f'gap_{read}'] for read in COUNTED_READS}
        if torn(gap, cycle):
            moved(cycle, cycle, 'gap_', '')
            cycle['torn'].append('baseline')
        following = cycles[index + 1]
        if torn(cycle, {read: following[f'gap_{read}'] for read in COUNTED_READS}):
            moved(following, cycle, 'gap_', '')
            cycle['torn'].append('end')
    return cycles


def torn_report(cycles: list[dict], arm: str) -> str:
    split = [(index + 1, reads) for index, cycle in enumerate(windows(cycles)) for reads in cycle['torn']]
    if not split:
        return f'no {arm} swing split across a read sequence'
    return (f'{arm} swings split across a read sequence and judged in their cycle '
            f'{[f"{index} {reads}" for index, reads in split]}')


def cycle_amount(model: dict, cycle: dict, resource: str) -> int:
    read = 'health' if resource == 'health' else 'rage'
    return restored(int(cycle[f'set_max_{read}'] - cycle[f'set_{read}']), model['percent'])


def reconciled(cycle: dict, resource: str) -> bool:
    read = 'health' if resource == 'health' else 'rage'
    return cycle[read] - cycle[f'set_{read}'] == cycle[EVENTS[resource][1]]


def windows(cycles: list[dict]) -> list[dict]:
    return cycles[:-1]


def gap_amounts(model: dict, cycles: list[dict], index: int, resource: str) -> set[int]:
    amounts = {cycle_amount(model, cycles[index], resource)} if index < len(cycles) - 1 else set()
    if index and cycles[index - 1]['swings'] == 0:
        amounts.add(cycle_amount(model, cycles[index - 1], resource))
    return amounts


def gap_judged(model: dict, cycles: list[dict], index: int, resource: str) -> bool:
    count, total = EVENTS[resource]
    gap = cycles[index]
    return gap[f'gap_{count}'] == gap['gap_parried'] and any(
        gap[f'gap_{total}'] == gap['gap_parried'] * amount for amount in gap_amounts(model, cycles, index, resource))


def gap_name(cycles: list[dict], index: int) -> str:
    return f'after cycle {index}' if index == len(cycles) - 1 else f'before cycle {index + 1}'


def gap_swings(cycles: list[dict]) -> list[int]:
    return [index for index, cycle in enumerate(cycles) if cycle['gap_swings']]


def unjudged_gaps(model: dict, cycles: list[dict], resource: str) -> list[int]:
    return [index for index, cycle in enumerate(cycles)
            if (cycle['gap_parried'] or cycle[f'gap_{EVENTS[resource][0]}'])
            and not gap_judged(model, cycles, index, resource)]


def gap_report(model: dict, cycles: list[dict], arm: str, resource: str) -> str:
    swung = gap_swings(cycles)
    if not swung:
        return f'no {arm} swing outside the judged windows'
    parried = [index for index in swung if cycles[index]['gap_parried']]
    judged = [index for index in parried if gap_judged(model, cycles, index, resource)]
    return (f'{sum(cycles[index]["gap_swings"] for index in swung):g} {arm} swings outside the judged windows (the '
            f'read and set gaps {[gap_name(cycles, index) for index in swung]}), {len(parried)} of them parried, '
            f'{len(judged)} of those with events numbering them and totalling the restore at a set state')


def hidden_parries(cycles: list[dict], resource: str) -> list[tuple[int, float]]:
    return [(index + 1, cycle['parried']) for index, cycle in enumerate(windows(cycles))
            if not reconciled(cycle, resource) and cycle['parried']]


def hidden_report(hidden: list[tuple[int, float]], resource: str) -> str:
    return (f'excluded treatment cycles {[index for index, _ in hidden]} held '
            f'{sum(parried for _, parried in hidden):g} parried swings, whose restore cannot be told from the foreign '
            f'{resource} change')


def unmeasured_reason(model: dict, cycles: list[dict], arm: str, resource: str) -> str | None:
    if any(cycle['swings'] + cycle['gap_swings'] > 1 for cycle in windows(cycles)):
        return (f'a {arm} cycle took more than one swing, its read and set gap included, so a later swing did not '
                f'start from the set state')
    if any(cycle['max_health'] != cycle['set_max_health'] or cycle['set_health'] >= cycle['set_max_health']
           or cycle['set_rage'] >= cycle['set_max_rage'] for cycle in windows(cycles)):
        return f'a {arm} cycle started with nothing missing or its maximum health moved within the cycle'
    judged = sum(cycle['parried'] for cycle in windows(cycles) if arm == 'control' or reconciled(cycle, resource))
    hidden = hidden_parries(cycles, resource) if arm == 'treatment' else []
    if judged < model['min_parried']:
        return (f'the {arm} arm has {judged:g} judged parried swings, fewer than {model["min_parried"]} (a treatment '
                f'cycle whose {resource} at its end is not its start plus its events took a foreign change and is '
                f'not judged)' + (f'; {hidden_report(hidden, resource)}' if hidden else ''))
    return None


def behaviour_parried_restore_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    resource = model['resource']
    count, total = EVENTS[resource]
    readings = {}
    for arm in ARMS:
        cycles, missing = arm_reading(run, model, arm)
        if cycles is None:
            return replace(base, explanation=missing_measurement(run, missing))
        reason = unmeasured_reason(model, cycles, arm, resource)
        if reason is not None:
            return replace(base, status='unmeasured', explanation=reason)
        readings[arm] = cycles
    failures = []
    control = readings['control']
    control_parried = sum(cycle['parried'] for cycle in windows(control))
    control_events = sum(cycle.get(count, 0) + cycle[f'gap_{count}'] for cycle in control)
    if control_events or sum(cycle.get(total, 0) + cycle[f'gap_{total}'] for cycle in control):
        failures.append(f'control: {control_events:g} events without {base.spell_id}')
    treatment = readings['treatment']
    kept = [(index + 1, cycle) for index, cycle in enumerate(windows(treatment)) if reconciled(cycle, resource)]
    judged = [cycle for _, cycle in kept]
    excluded = len(windows(treatment)) - len(judged)
    hidden = hidden_parries(treatment, resource)
    if hidden:
        failures.append(hidden_report(hidden, resource))
    unjudged = unjudged_gaps(model, treatment, resource)
    if unjudged:
        failures.append(f'treatment read and set gaps {[gap_name(treatment, index) for index in unjudged]} held '
                        f'{sum(treatment[index]["gap_parried"] for index in unjudged):g} parried swings and '
                        f'{sum(treatment[index][f"gap_{count}"] for index in unjudged):g} events, which do not number '
                        f'them or total {model["percent"]}% of the missing {resource} at a set state they '
                        f'can have started from')
    wrong = [index for index, cycle in kept if cycle[count] != cycle['parried']
             or cycle[total] != cycle['parried'] * cycle_amount(model, cycle, resource)]
    if wrong:
        failures.append(f'treatment cycles {wrong} restored off {model["percent"]}% of the missing {resource} read at '
                        f'their start, or their events did not number their parried swings')
    treated = sum(cycle['parried'] for cycle in judged)
    restored_total = sum(cycle[total] for cycle in judged)
    expected = sum(cycle['parried'] * cycle_amount(model, cycle, resource) for cycle in judged)
    explanation = (f'{resource}: each parried swing must restore {model["percent"]}% of the missing {resource} read '
                   f'at its cycle\'s start, truncated, and nothing without {base.spell_id}; {len(judged)} treatment '
                   f'cycles judged ({excluded} with a foreign {resource} change left out, holding '
                   f'{sum(parried for _, parried in hidden):g} parried swings) held {treated:g} parried '
                   f'swings restoring {restored_total:g} (expected {expected:g}); the control parried '
                   f'{control_parried:g} with {control_events:g} events; '
                   f'{gap_report(model, readings["control"], "control", resource)}; '
                   f'{gap_report(model, treatment, "treatment", resource)}; '
                   f'{torn_report(readings["control"], "control")}; {torn_report(treatment, "treatment")}'
                   + (f'; {"; ".join(failures)}' if failures else ''))
    return replace(base, status='alert' if failures else 'ok', measured=float(restored_total),
                   expected=float(expected), low=float(expected), high=float(expected), explanation=explanation)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return parried_restore_scenario(class_file, parried_restore_spec(entry))


def label(entry: dict) -> list[str]:
    suffix = entry.get('label_suffix', 'parried')
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {suffix}_{resource}" for resource in RESOURCES]


METRIC_EVIDENCE = {METRIC: 'event'}
JUDGES = {BEHAVIOUR_METRIC_DELTA: behaviour_parried_restore_verdict}
