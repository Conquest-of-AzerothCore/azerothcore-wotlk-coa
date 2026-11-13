from dataclasses import dataclass
import math
from typing import Sequence

from hits import (DRAIN_MS, EXCLUDED_OUTCOME_MARGIN, MAIN_HAND, PART_BUDGET_MS, UNMODELLED, Z_99, Unmodelled,
                  cast_steps, creature_fixture, records_of, reference_caster, scenario_shell, timed, weapon_profile)
from profile import CASTER, SETTLE_MS, measurement, player_fixture
from tooltip import read_tooltip
from values import (ALLY, CAST_MARGIN_MS, CHARGE_OFFSET_YD, EFFECTS, READ_STEP_MS, TARGET, Expectation, RankFacts,
                    armed_for, facts_of, is_hostile, targets_ally)

PROC_CHECK = 'proc_rate'
AMBIGUOUS_TOOLTIP = 'ambiguous_tooltip: '
ENTRY_STATUSES = {'ambiguous_tooltip': AMBIGUOUS_TOOLTIP, 'unmodelled': UNMODELLED}
RATE_HALF_WIDTH = 0.025
CHANCE_KIND = 'chance_pct'
PERCENT_KIND = 'percent'
ATTACK = 'attack'
CAST = 'cast'
CAST_COUNT = 'spell_cast_count'
MELEE_EVENTS = 'melee_attack_count'
EVENT_METRICS = frozenset({CAST_COUNT, 'spell_damage_count', MELEE_EVENTS})
CHARGES = 'spell_charges'
TRIGGER_TARGETS = frozenset({TARGET, ALLY})
PERIODIC_DAMAGE_AURA = 3
TICKS_PER_ATTEMPT = 2
TRIGGERING_HITS = 'triggering hits only'
WILSON_RULE = f'Wilson {Z_99:g} (99%) interval of the proc rate holds the tooltip chance'
PER_TRIGGER = 'most_procs_per_trigger'
PER_TRIGGER_SOURCE = 'most_procs_per_trigger_source'
PER_TRIGGER_RULE = ('each auto attack is its own trigger, read before and after; only triggers with exactly one landed '
                    'main-hand hit count, and a trigger with more procs than the stated limit is an alert')
TRIGGER_ACTIONS = 3
DELTA_CHECK = 'proc_rate_delta'
DELTA_SANITY_FACTOR = 3
DELTA_RULE = (f'two-proportion z >= {Z_99:g} (one-sided, 99%) that the with-aura rate exceeds the baseline rate, '
             f'and the measured chance (with-rate / baseline-rate - 1) is between 0 and {DELTA_SANITY_FACTOR:g}x '
             'the tooltip chance; proves the chance is positive and roughly the right order of magnitude, not a '
             'tight match (see README \'Nested proc rate\')')


@dataclass(frozen=True)
class ProcPlan:
    chance_pct: float
    needed: int
    scheduled: int
    attempt_ms: int
    parts: int
    per_part: int


def trials_needed(p: float) -> int:
    if not 0 < p < 1:
        raise ValueError(f'A proc chance of {p} has no rate to measure')
    return math.ceil(Z_99 ** 2 * p * (1 - p) / RATE_HALF_WIDTH ** 2)


def wilson_interval(events: float, trials: float) -> tuple[float, float]:
    if trials <= 0 or not 0 <= events <= trials:
        raise ValueError(f'{events} procs in {trials} trials have no rate')
    z2 = Z_99 ** 2
    centre = (events + z2 / 2) / (trials + z2)
    half = Z_99 / (trials + z2) * math.sqrt(events * (trials - events) / trials + z2 / 4)
    return centre - half, centre + half


def proc_label(aura: int, proc_spell: int | None = None, trigger: int | str | None = None) -> str:
    label = f'{aura} proc_rate' if proc_spell is None else f'{aura} proc_rate {proc_spell}'
    return label if trigger is None else f'{label} {trigger}'


def proc_measurements(aura: int) -> dict[str, str]:
    return {part: f'{aura} proc {part}' for part in ('trials', 'events', 'attempts', 'aura')}


def shares_aura(class_file: dict, entry: dict) -> bool:
    return sum(1 for other in class_file.get('procs', []) if other['aura'] == entry['aura']) > 1


def shares_proc_spell(class_file: dict, entry: dict) -> bool:
    if 'proc_spell' not in entry:
        return False
    return sum(1 for other in class_file.get('procs', [])
              if other['aura'] == entry['aura'] and other.get('proc_spell') == entry['proc_spell']) > 1


def trigger_key(entry: dict) -> int | str:
    trigger = entry['trigger']
    return trigger['spell'] if trigger['action'] == CAST else trigger['action']


def chance_of(values: Sequence, token: str, kind: str = CHANCE_KIND) -> float | None:
    return next((value.value for value in values if value.kind == kind and value.text == token), None)


def applied_by(entry: dict) -> int | None:
    applied = entry.get('applied_by')
    if applied is None:
        return None
    if not isinstance(applied, dict) or set(applied) != {'spell', 'source'} or not isinstance(applied['spell'], int):
        raise ValueError(f'Proc {entry["aura"]} applied_by must name the spell whose cast grants it and the source')
    return applied['spell']


def chance_source(entry: dict) -> tuple[int, str]:
    granted = applied_by(entry)
    if granted is None:
        return entry['aura'], CHANCE_KIND
    if entry['chance_token'] != f'${entry["aura"]}s1':
        raise ValueError(f'Proc {entry["aura"]} applied by {granted} must show its chance as ${entry["aura"]}s1')
    return granted, PERCENT_KIND


def proc_chance(class_file: dict, entry: dict) -> float:
    shown, kind = chance_source(entry)
    readout = read_tooltip(records_of(class_file).dbc, shown, reference_caster(class_file))
    chance = chance_of(readout.values, entry['chance_token'], kind)
    if chance is None:
        raise ValueError(f'The tooltip of {shown} shows no chance token {entry["chance_token"]}')
    return chance


def chance_model(entry: dict) -> dict:
    if applied_by(entry) is None:
        return {}
    shown, kind = chance_source(entry)
    return {'chance_spell': shown, 'chance_kind': kind}


def aura_steps(entry: dict) -> list[dict]:
    if applied_by(entry) is None:
        return [{'action': 'learn', 'actor': CASTER, 'spell': entry['aura']}]
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': entry['aura'], 'stacks': 1}]


def trigger_spell(entry: dict) -> int:
    return entry['trigger']['spell'] if entry['trigger']['action'] == CAST else 0


def trigger_target(entry: dict) -> str:
    target = entry['trigger'].get('target', TARGET)
    if target not in TRIGGER_TARGETS:
        raise ValueError(f'Proc {entry["aura"]} casts at {target!r}, not one of {sorted(TRIGGER_TARGETS)}')
    return target


def counts_charges(entry: dict) -> bool:
    if entry['event_metric'] != CHARGES:
        return False
    if entry['trigger']['action'] != CAST or entry['proc_spell'] != entry['trigger']['spell']:
        raise ValueError(f'Proc {entry["aura"]} counts charges of {entry["proc_spell"]}, not of a cast trigger')
    return True


def charge_label(aura: int, attempt: int) -> str:
    return f'{aura} proc charges {attempt}'


def charge_pool_label(aura: int) -> str:
    return f'{aura} proc charge pool'


def tick_spacing(class_file: dict, facts: RankFacts, spell: int) -> int:
    ticks = [records_of(class_file).field('Spell', spell, f'EffectAmplitude[{effect}]') for effect in EFFECTS
             if facts.aura_names[effect] == PERIODIC_DAMAGE_AURA]
    return TICKS_PER_ATTEMPT * max(ticks) + CAST_MARGIN_MS if ticks else 0


def swing_interval(class_file: dict, cooldown: int = 0) -> int:
    weapon = weapon_profile(class_file)
    if weapon is None:
        raise Unmodelled('auto attacks need the weapon stats of the class file')
    if cooldown:
        raise Unmodelled(f'auto attacks cannot be spaced beyond the internal cooldown of {cooldown} ms')
    return weapon.speed_ms


def cast_interval(class_file: dict, spell: int, cooldown: int = 0) -> int:
    records = records_of(class_file)
    facts = facts_of(records, spell)
    start_recovery = records.field('Spell', spell, 'StartRecoveryTime')
    return max(start_recovery, facts.cast_time_ms, cooldown) + CAST_MARGIN_MS


def per_trigger_limit(entry: dict) -> int | None:
    limit = entry.get(PER_TRIGGER)
    if limit is None:
        return None
    if isinstance(limit, bool) or not isinstance(limit, int) or limit < 1:
        raise ValueError(f'Proc {entry["aura"]} states {limit!r} procs per trigger, not a positive whole number')
    if entry['trigger']['action'] != ATTACK:
        raise ValueError(f'Proc {entry["aura"]} counts procs per trigger, which needs an attack trigger')
    if entry.get('trial_readings'):
        raise ValueError(f'Proc {entry["aura"]} counts procs per trigger, whose trials are the triggers alone')
    if not entry.get(PER_TRIGGER_SOURCE):
        raise ValueError(f'Proc {entry["aura"]} states {limit} procs per trigger without {PER_TRIGGER_SOURCE}')
    return limit


def boundary_reads(entry: dict) -> int:
    return 1 + len(event_terms(entry))


def attempt_interval(class_file: dict, entry: dict) -> int:
    trigger = entry['trigger']
    cooldown = entry.get('internal_cooldown_ms', 0)
    if trigger['action'] == ATTACK:
        swing = swing_interval(class_file, cooldown)
        if per_trigger_limit(entry) is None:
            return swing
        return swing + (TRIGGER_ACTIONS + boundary_reads(entry)) * READ_STEP_MS
    if trigger['action'] != CAST:
        raise ValueError(f'Unknown trigger action {trigger["action"]!r} of proc {entry["aura"]}')
    facts = facts_of(records_of(class_file), trigger['spell'])
    if trigger_target(entry) == ALLY:
        if facts.passive or not targets_ally(facts):
            raise Unmodelled(f'trigger spell {trigger["spell"]} is not cast at an ally')
    elif facts.passive or not is_hostile(facts):
        raise Unmodelled(f'trigger spell {trigger["spell"]} is not cast at an enemy')
    return max(cast_interval(class_file, trigger['spell'], cooldown), tick_spacing(class_file, facts, trigger['spell']))


def proc_plan(class_file: dict, entry: dict, attempts: int | None = None) -> ProcPlan:
    if entry.get('status'):
        raise ValueError(f'Proc {entry["aura"]} is {entry["status"]}: {entry.get("reason", "")}')
    if entry['event_metric'] not in EVENT_METRICS and not counts_charges(entry):
        raise ValueError(f'Unknown event metric {entry["event_metric"]!r} of proc {entry["aura"]}')
    if entry['event_metric'] == MELEE_EVENTS and entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc {entry["aura"]} counts auto attacks as events, which needs a cast trigger')
    per_trigger_limit(entry)
    chance = proc_chance(class_file, entry)
    needed = trials_needed(chance / 100)
    scheduled = math.ceil(needed * EXCLUDED_OUTCOME_MARGIN) if attempts is None else attempts
    if scheduled < needed:
        raise ValueError(f'{scheduled} attempts are fewer than the {needed} trials a {chance:g}% proc needs')
    interval = attempt_interval(class_file, entry)
    capacity = PART_BUDGET_MS // interval
    if capacity < 1:
        raise Unmodelled(f'one attempt of {interval} ms exceeds the scenario budget of {PART_BUDGET_MS} ms')
    parts = math.ceil(scheduled / capacity)
    return ProcPlan(chance_pct=chance, needed=needed, scheduled=scheduled, attempt_ms=interval, parts=parts,
                    per_part=math.ceil(scheduled / parts))


def trial_rule(entry: dict) -> str:
    if entry['trigger']['action'] == ATTACK:
        return 'trials: main-hand melee hits dealing damage (melee_damage_count hand 0)'
    if trigger_target(entry) == ALLY:
        return f'trials: completed casts of {entry["trigger"]["spell"]} at the ally (spell_cast_count)'
    return f'trials: damage events of {entry["trigger"]["spell"]} on the target (spell_damage_count)'


def trials_step(entry: dict, label: str) -> dict:
    spell = trigger_spell(entry)
    if trigger_target(entry) == ALLY:
        return measurement(label, CASTER, CAST_COUNT, spell=spell)
    return measurement(label, CASTER, 'spell_damage_count', spell=spell, target=TARGET)


def attempt_auras(entry: dict) -> list[dict]:
    auras = entry.get('attempt_auras', [])
    if auras and entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc {entry["aura"]} sets attempt_auras without a cast trigger')
    for aura in auras:
        if set(aura) != {'spell', 'stacks', 'source'} or not isinstance(aura['stacks'], int) or aura['stacks'] < 0:
            raise ValueError(f'Proc {entry["aura"]} attempt aura {aura!r} must name its spell, stacks and source')
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': aura['spell'], 'stacks': aura['stacks']}
            for aura in auras]


def attempt_fixtures(entry: dict) -> list[dict]:
    spell = trigger_spell(entry)
    fixtures = [{'action': 'restore_charges', 'actor': CASTER, 'spell': spell}] if counts_charges(entry) else []
    fixtures += attempt_auras(entry)
    if trigger_target(entry) == ALLY:
        fixtures.append({'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD})
    return fixtures


def aimed(step: dict, target: str) -> dict:
    return {**step, 'target': ALLY} if step['action'] == 'cast' and target == ALLY else step


def cast_attempts(class_file: dict, entry: dict, plan: ProcPlan) -> list[dict]:
    spell, target = trigger_spell(entry), trigger_target(entry)
    facts = facts_of(records_of(class_file), spell)
    steps = []
    for attempt in range(1, plan.per_part + 1):
        steps += [aimed(step, target) for step in cast_steps(facts, spell, target, plan.attempt_ms, 1,
                                                             attempt_fixtures(entry))]
        if counts_charges(entry):
            steps.append(measurement(charge_label(entry['aura'], attempt), CASTER, CHARGES, spell=spell))
    return steps


def charge_pool_steps(entry: dict) -> list[dict]:
    if not counts_charges(entry):
        return []
    spell = trigger_spell(entry)
    return [{'action': 'restore_charges', 'actor': CASTER, 'spell': spell},
            measurement(charge_pool_label(entry['aura']), CASTER, CHARGES, spell=spell)]


def trigger_boundary(entry: dict, index: int) -> dict:
    aura = entry['aura']
    return {'hits': f'{aura} proc trigger {index} hits',
            'events': [f'{aura} proc trigger {index} events {term["metric"]} {term["spell"]}'
                       for _, term in event_terms(entry)]}


def trigger_boundaries(entry: dict, triggers: int) -> list[dict]:
    return [trigger_boundary(entry, index) for index in range(triggers + 1)]


def boundary_steps(boundary: dict, entry: dict) -> list[dict]:
    hits = measurement(boundary['hits'], CASTER, 'melee_damage_count', hand=MAIN_HAND)
    return [hits] + [spell_count_step(label, term['metric'], term['spell'])
                     for label, (_, term) in zip(boundary['events'], event_terms(entry))]


def per_trigger_steps(class_file: dict, entry: dict, plan: ProcPlan) -> list[dict]:
    swing = swing_interval(class_file)
    boundaries = trigger_boundaries(entry, plan.per_part)
    steps = boundary_steps(boundaries[0], entry)
    for boundary in boundaries[1:]:
        steps += [{'action': 'attack', 'actor': CASTER, 'target': TARGET}, {'action': 'wait', 'ms': swing},
                  {'action': 'stop_attack', 'actor': CASTER}] + boundary_steps(boundary, entry)
    return steps


def attempt_steps(class_file: dict, entry: dict, plan: ProcPlan, labels: dict[str, str]) -> list[dict]:
    if per_trigger_limit(entry) is not None:
        return per_trigger_steps(class_file, entry, plan)
    if entry['trigger']['action'] == ATTACK:
        return [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                {'action': 'wait', 'label': 'swings', 'ms': plan.per_part * plan.attempt_ms},
                {'action': 'stop_attack', 'actor': CASTER},
                {'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS},
                measurement(labels['trials'], CASTER, 'melee_damage_count', hand=MAIN_HAND),
                measurement(labels['attempts'], CASTER, 'melee_attack_count', hand=MAIN_HAND)]
    spell = trigger_spell(entry)
    return ([{'action': 'learn', 'actor': CASTER, 'spell': spell}] + charge_pool_steps(entry)
            + cast_attempts(class_file, entry, plan)
            + [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS}, trials_step(entry, labels['trials']),
               measurement(labels['attempts'], CASTER, CAST_COUNT, spell=spell)])


def spell_count_step(label: str, metric: str, spell: int) -> dict:
    if metric not in EVENT_METRICS:
        raise ValueError(f'Unknown count metric {metric!r}')
    if metric == MELEE_EVENTS:
        return measurement(label, CASTER, metric, hand=MAIN_HAND)
    fields = {'target': TARGET} if metric == 'spell_damage_count' else {}
    return measurement(label, CASTER, metric, spell=spell, **fields)


def event_labels(entry: dict, plan: ProcPlan) -> list[str]:
    if counts_charges(entry):
        return [charge_label(entry['aura'], attempt) for attempt in range(1, plan.per_part + 1)]
    return [label for label, _ in event_terms(entry)]


def event_terms(entry: dict) -> list[tuple[str, dict]]:
    labels = proc_measurements(entry['aura'])
    first = {'metric': entry['event_metric'], 'spell': entry['proc_spell']}
    return [(labels['events'], first)] + [(f'{entry["aura"]} proc events {term["metric"]} {term["spell"]}', term)
                                          for term in entry.get('extra_event_terms', [])]


def event_steps(entry: dict) -> list[dict]:
    if counts_charges(entry):
        return []
    return [spell_count_step(label, term['metric'], term['spell']) for label, term in event_terms(entry)]


def excludes_trigger_casts(entry: dict) -> bool:
    excluded = bool(entry.get('events_exclude_trigger_casts'))
    if excluded and entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc {entry["aura"]} excludes trigger casts without a cast trigger')
    return excluded


def added_trials_label(aura: int, term: dict) -> str:
    return f'{aura} proc trials {term["metric"]} {term["spell"]}'


def reading_trials_label(entry: dict, reading: dict) -> str:
    labels = proc_measurements(entry['aura'])
    metric = reading.get('trials_metric')
    if metric is None:
        return labels['trials']
    if metric != CAST_COUNT or entry['trigger']['action'] != CAST:
        raise ValueError(f'Reading {reading["name"]!r} of proc {entry["aura"]} counts {metric!r}, not the casts of '
                         f'a cast trigger')
    return labels['attempts']


def trial_readings(entry: dict) -> list[dict]:
    readings = entry.get('trial_readings') or [{'name': TRIGGERING_HITS, 'adds': []}]
    return [{'name': reading['name'], 'adds': list(reading.get('adds', [])),
             'minus_events': reading.get('minus_events', False),
             'labels': [reading_trials_label(entry, reading)] + [added_trials_label(entry['aura'], term)
                                                                 for term in reading.get('adds', [])]}
            for reading in readings]


def added_trial_steps(entry: dict) -> list[dict]:
    terms = {added_trials_label(entry['aura'], term): term
             for reading in trial_readings(entry) for term in reading['adds']}
    return [spell_count_step(label, term['metric'], term['spell']) for label, term in terms.items()]


def proc_scenario(class_file: dict, entry: dict, part: int = 0, *,
                  attempts: int | None = None) -> tuple[dict, list[Expectation]]:
    plan = proc_plan(class_file, entry, attempts)
    if entry['trigger']['action'] == CAST:
        class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    if not 0 <= part < plan.parts:
        raise ValueError(f'Proc {entry["aura"]} has parts 0 to {plan.parts - 1}, not {part}')
    aura = entry['aura']
    labels = proc_measurements(aura)
    steps = aura_steps(entry)
    limit = per_trigger_limit(entry)
    steps += attempt_steps(class_file, entry, plan, labels)
    if limit is None:
        steps += added_trial_steps(entry) + event_steps(entry)
    steps += [measurement(labels['aura'], CASTER, 'aura', spell=aura)]
    name = f'Conformance proc {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {plan.parts}'
    contract = 'Proc rate of an aura over enough triggering hits, summed over its parts, against its tooltip chance.'
    scenario = scenario_shell(class_file, name, contract, steps)
    if trigger_target(entry) == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    else:
        scenario['creatures'] = [creature_fixture(class_file)]
    model = {'part': part, 'parts': plan.parts, 'chance_pct': plan.chance_pct, 'minimum_trials': plan.needed,
             'scheduled_attempts': plan.scheduled, 'part_attempts': plan.per_part, 'attempt_ms': plan.attempt_ms,
             'trigger': dict(entry['trigger']), 'proc_spell': entry['proc_spell'],
             **chance_model(entry),
             'event_metric': entry['event_metric'], 'events_per_proc': entry.get('events_per_proc', 1),
             'measurements': labels, 'event_labels': event_labels(entry, plan),
             'exclude_trigger_casts': excludes_trigger_casts(entry),
             'readings': [{key: reading[key] for key in ('name', 'labels', 'minus_events')}
                          for reading in trial_readings(entry)]}
    if counts_charges(entry):
        model['charge_pool'] = charge_pool_label(aura)
    rule = f'{WILSON_RULE}; {trial_rule(entry)}'
    if limit is not None:
        model[PER_TRIGGER] = limit
        model['trigger_boundaries'] = trigger_boundaries(entry, plan.per_part)
        rule = f'{rule}; {PER_TRIGGER_RULE} ({limit})'
    trigger = trigger_key(entry) if shares_proc_spell(class_file, entry) else None
    label = proc_label(aura, entry['proc_spell'], trigger) if shares_aura(class_file, entry) else proc_label(aura)
    expectation = Expectation(label, PROC_CHECK, aura, aura, None, entry['chance_token'],
                              f'{rule}{handler_note(entry)}', model)
    return timed(scenario, SETTLE_MS + plan.per_part * plan.attempt_ms + DRAIN_MS), [expectation]


def handler_note(entry: dict) -> str:
    return f'; handler: {entry["handler"]}' if entry.get('handler') else ''


def delta_proc_measurements(aura: int) -> dict[str, str]:
    return {'baseline_trials': f'{aura} proc delta baseline trials',
            'baseline_events': f'{aura} proc delta baseline events', 'trials': f'{aura} proc delta trials',
            'events': f'{aura} proc delta events', 'aura': f'{aura} proc delta aura'}


def checked_delta_entry(entry: dict) -> dict:
    aura = entry['aura']
    if entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc delta {aura} needs a cast trigger, not {entry["trigger"]["action"]!r}')
    if entry['event_metric'] not in EVENT_METRICS:
        raise ValueError(f'Unknown event metric {entry["event_metric"]!r} of proc delta {aura}')
    if not entry.get('baseline_co_learn'):
        raise ValueError(f'Proc delta {aura} needs baseline_co_learn: the spell(s) that produce the trigger '
                         f'without {aura} itself')
    if any(not isinstance(spell, int) for spell in entry['baseline_co_learn']):
        raise ValueError(f'Proc delta {aura} has a non-integer baseline_co_learn spell')
    return entry


def delta_proc_plan(class_file: dict, entry: dict, attempts: int | None = None) -> ProcPlan:
    if entry.get('status'):
        raise ValueError(f'Proc {entry["aura"]} is {entry["status"]}: {entry.get("reason", "")}')
    checked_delta_entry(entry)
    chance = proc_chance(class_file, entry)
    scheduled = attempts if attempts is not None else entry.get('delta_attempts', trials_needed(chance / 100))
    interval = attempt_interval(class_file, entry)
    capacity = PART_BUDGET_MS // (interval * 2)
    if capacity < 1:
        raise Unmodelled(f'two attempts of {interval} ms each exceed the scenario budget of {PART_BUDGET_MS} ms')
    parts = math.ceil(scheduled / capacity)
    return ProcPlan(chance_pct=chance, needed=scheduled, scheduled=scheduled, attempt_ms=interval, parts=parts,
                    per_part=math.ceil(scheduled / parts))


def delta_attempt_block(class_file: dict, entry: dict, plan: ProcPlan, learn_spells: list[int], trials_label: str,
                        events_label: str) -> list[dict]:
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learn_spells]
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': trigger_spell(entry)}]
    steps += cast_attempts(class_file, entry, plan)
    steps += [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS}, trials_step(entry, trials_label),
             spell_count_step(events_label, entry['event_metric'], entry['proc_spell'])]
    return steps


def delta_proc_scenario(class_file: dict, entry: dict, part: int = 0, *,
                        attempts: int | None = None) -> tuple[dict, list[Expectation]]:
    plan = delta_proc_plan(class_file, entry, attempts)
    class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    if not 0 <= part < plan.parts:
        raise ValueError(f'Proc delta {entry["aura"]} has parts 0 to {plan.parts - 1}, not {part}')
    aura = entry['aura']
    labels = delta_proc_measurements(aura)
    steps = delta_attempt_block(class_file, entry, plan, entry['baseline_co_learn'],
                                labels['baseline_trials'], labels['baseline_events'])
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': aura}]
    steps += delta_attempt_block(class_file, entry, plan, [], labels['trials'], labels['events'])
    steps += [measurement(labels['aura'], CASTER, 'aura', spell=aura)]
    name = f'Conformance proc delta {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {plan.parts}'
    contract = ('Two-proportion rate delta of a nested proc chance: a baseline phase without the aura, then a '
               'phase with it, over the same trigger, summed over its parts, against a positive-effect floor.')
    scenario = scenario_shell(class_file, name, contract, steps)
    scenario['creatures'] = [creature_fixture(class_file)]
    model = {'part': part, 'parts': plan.parts, 'chance_pct': plan.chance_pct, 'scheduled_attempts': plan.scheduled,
            'part_attempts': plan.per_part, 'attempt_ms': plan.attempt_ms, 'trigger': dict(entry['trigger']),
            'proc_spell': entry['proc_spell'], 'event_metric': entry['event_metric'], 'measurements': labels,
            'baseline_co_learn': list(entry['baseline_co_learn'])}
    trigger = trigger_key(entry) if shares_proc_spell(class_file, entry) else None
    label = proc_label(aura, entry['proc_spell'], trigger) if shares_aura(class_file, entry) else proc_label(aura)
    expectation = Expectation(label, DELTA_CHECK, aura, aura, None, entry['chance_token'],
                              f'{DELTA_RULE}; {trial_rule(entry)}{handler_note(entry)}', model)
    return timed(scenario, SETTLE_MS + 2 * plan.per_part * plan.attempt_ms + 2 * DRAIN_MS), [expectation]


def proc_status_expectation(entry: dict) -> Expectation:
    status = entry.get('status')
    if status not in ENTRY_STATUSES:
        raise ValueError(f'Proc {entry["aura"]} status {status!r} is not one of {sorted(ENTRY_STATUSES)}')
    return Expectation(proc_label(entry['aura']), PROC_CHECK, entry['aura'], entry['aura'], None,
                       entry.get('chance_token', ''), ENTRY_STATUSES[status] + entry['reason'] + handler_note(entry))


def proc_unmodelled_expectation(entry: dict, reason: str) -> Expectation:
    return Expectation(proc_label(entry['aura']), PROC_CHECK, entry['aura'], entry['aura'], None,
                       entry.get('chance_token', ''), UNMODELLED + reason + handler_note(entry))


def proc_entries(class_file: dict, auras: Sequence[int] | None = None) -> list[dict]:
    entries = class_file.get('procs', [])
    if auras is None:
        return list(entries)
    unknown = set(auras) - {entry['aura'] for entry in entries}
    if unknown:
        raise ValueError(f'Auras {sorted(unknown)} have no proc entry in the {class_file["name"]} class file')
    return [entry for entry in entries if entry['aura'] in auras]
