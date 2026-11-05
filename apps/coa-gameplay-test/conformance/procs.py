from dataclasses import dataclass
import math
from typing import Sequence

from hits import (DRAIN_MS, EXCLUDED_OUTCOME_MARGIN, MAIN_HAND, MAX_SCENARIO_MS, TIMEOUT_MARGIN_MS, UNMODELLED, Z_99,
                  Unmodelled, cast_steps, creature_fixture, records_of, reference_caster, scenario_shell, timed,
                  weapon_profile)
from profile import CASTER, SETTLE_MS, measurement
from tooltip import read_tooltip
from values import CAST_MARGIN_MS, TARGET, Expectation, facts_of, is_hostile

PROC_CHECK = 'proc_rate'
AMBIGUOUS_TOOLTIP = 'ambiguous_tooltip: '
ENTRY_STATUSES = {'ambiguous_tooltip': AMBIGUOUS_TOOLTIP, 'unmodelled': UNMODELLED}
RATE_HALF_WIDTH = 0.025
CHANCE_KIND = 'chance_pct'
ATTACK = 'attack'
CAST = 'cast'
EVENT_METRICS = frozenset({'spell_cast_count', 'spell_damage_count'})
TRIGGERING_HITS = 'triggering hits only'
PART_BUDGET_MS = MAX_SCENARIO_MS - TIMEOUT_MARGIN_MS - SETTLE_MS - DRAIN_MS
WILSON_RULE = f'Wilson {Z_99:g} (99%) interval of the proc rate holds the tooltip chance'


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


def proc_label(aura: int) -> str:
    return f'{aura} proc_rate'


def proc_measurements(aura: int) -> dict[str, str]:
    return {part: f'{aura} proc {part}' for part in ('trials', 'events', 'attempts', 'aura')}


def chance_of(values: Sequence, token: str) -> float | None:
    return next((value.value for value in values if value.kind == CHANCE_KIND and value.text == token), None)


def proc_chance(class_file: dict, entry: dict) -> float:
    readout = read_tooltip(records_of(class_file).dbc, entry['aura'], reference_caster(class_file))
    chance = chance_of(readout.values, entry['chance_token'])
    if chance is None:
        raise ValueError(f'The tooltip of {entry["aura"]} shows no chance token {entry["chance_token"]}')
    return chance


def trigger_spell(entry: dict) -> int:
    return entry['trigger']['spell'] if entry['trigger']['action'] == CAST else 0


def attempt_interval(class_file: dict, entry: dict) -> int:
    trigger = entry['trigger']
    cooldown = entry.get('internal_cooldown_ms', 0)
    if trigger['action'] == ATTACK:
        weapon = weapon_profile(class_file)
        if weapon is None:
            raise Unmodelled('auto attacks need the weapon stats of the class file')
        if cooldown:
            raise Unmodelled(f'auto attacks cannot be spaced beyond the internal cooldown of {cooldown} ms')
        return weapon.speed_ms
    if trigger['action'] != CAST:
        raise ValueError(f'Unknown trigger action {trigger["action"]!r} of proc {entry["aura"]}')
    records = records_of(class_file)
    facts = facts_of(records, trigger['spell'])
    if facts.passive or not is_hostile(facts):
        raise Unmodelled(f'trigger spell {trigger["spell"]} is not cast at an enemy')
    start_recovery = records.field('Spell', trigger['spell'], 'StartRecoveryTime')
    return max(start_recovery, facts.cast_time_ms, cooldown) + CAST_MARGIN_MS


def proc_plan(class_file: dict, entry: dict, attempts: int | None = None) -> ProcPlan:
    if entry.get('status'):
        raise ValueError(f'Proc {entry["aura"]} is {entry["status"]}: {entry.get("reason", "")}')
    if entry['event_metric'] not in EVENT_METRICS:
        raise ValueError(f'Unknown event metric {entry["event_metric"]!r} of proc {entry["aura"]}')
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
    return f'trials: damage events of {entry["trigger"]["spell"]} on the target (spell_damage_count)'


def attempt_steps(class_file: dict, entry: dict, plan: ProcPlan, labels: dict[str, str]) -> list[dict]:
    if entry['trigger']['action'] == ATTACK:
        return [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                {'action': 'wait', 'label': 'swings', 'ms': plan.per_part * plan.attempt_ms},
                {'action': 'stop_attack', 'actor': CASTER},
                {'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS},
                measurement(labels['trials'], CASTER, 'melee_damage_count', hand=MAIN_HAND),
                measurement(labels['attempts'], CASTER, 'melee_attack_count', hand=MAIN_HAND)]
    spell = trigger_spell(entry)
    facts = facts_of(records_of(class_file), spell)
    return ([{'action': 'learn', 'actor': CASTER, 'spell': spell}]
            + cast_steps(facts, spell, True, plan.attempt_ms, plan.per_part)
            + [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS},
               measurement(labels['trials'], CASTER, 'spell_damage_count', spell=spell, target=TARGET),
               measurement(labels['attempts'], CASTER, 'spell_cast_count', spell=spell)])


def spell_count_step(label: str, metric: str, spell: int) -> dict:
    if metric not in EVENT_METRICS:
        raise ValueError(f'Unknown count metric {metric!r}')
    fields = {'target': TARGET} if metric == 'spell_damage_count' else {}
    return measurement(label, CASTER, metric, spell=spell, **fields)


def event_terms(entry: dict) -> list[tuple[str, dict]]:
    labels = proc_measurements(entry['aura'])
    first = {'metric': entry['event_metric'], 'spell': entry['proc_spell']}
    return [(labels['events'], first)] + [(f'{entry["aura"]} proc events {term["metric"]} {term["spell"]}', term)
                                          for term in entry.get('extra_event_terms', [])]


def event_steps(entry: dict) -> list[dict]:
    return [spell_count_step(label, term['metric'], term['spell']) for label, term in event_terms(entry)]


def excludes_trigger_casts(entry: dict) -> bool:
    excluded = bool(entry.get('events_exclude_trigger_casts'))
    if excluded and entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc {entry["aura"]} excludes trigger casts without a cast trigger')
    return excluded


def added_trials_label(aura: int, term: dict) -> str:
    return f'{aura} proc trials {term["metric"]} {term["spell"]}'


def trial_readings(entry: dict) -> list[dict]:
    readings = entry.get('trial_readings') or [{'name': TRIGGERING_HITS, 'adds': []}]
    labels = proc_measurements(entry['aura'])
    return [{'name': reading['name'], 'adds': list(reading['adds']), 'minus_events': reading.get('minus_events', False),
             'labels': [labels['trials']] + [added_trials_label(entry['aura'], term) for term in reading['adds']]}
            for reading in readings]


def added_trial_steps(entry: dict) -> list[dict]:
    terms = {added_trials_label(entry['aura'], term): term
             for reading in trial_readings(entry) for term in reading['adds']}
    return [spell_count_step(label, term['metric'], term['spell']) for label, term in terms.items()]


def proc_scenario(class_file: dict, entry: dict, part: int = 0, *,
                  attempts: int | None = None) -> tuple[dict, list[Expectation]]:
    plan = proc_plan(class_file, entry, attempts)
    if not 0 <= part < plan.parts:
        raise ValueError(f'Proc {entry["aura"]} has parts 0 to {plan.parts - 1}, not {part}')
    aura = entry['aura']
    labels = proc_measurements(aura)
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': aura}]
    steps += attempt_steps(class_file, entry, plan, labels)
    steps += added_trial_steps(entry)
    steps += event_steps(entry) + [measurement(labels['aura'], CASTER, 'aura', spell=aura)]
    name = f'Conformance proc {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {plan.parts}'
    contract = 'Proc rate of an aura over enough triggering hits, summed over its parts, against its tooltip chance.'
    scenario = scenario_shell(class_file, name, contract, steps)
    scenario['creatures'] = [creature_fixture(class_file)]
    model = {'part': part, 'parts': plan.parts, 'chance_pct': plan.chance_pct, 'minimum_trials': plan.needed,
             'scheduled_attempts': plan.scheduled, 'part_attempts': plan.per_part, 'attempt_ms': plan.attempt_ms,
             'trigger': dict(entry['trigger']), 'proc_spell': entry['proc_spell'],
             'event_metric': entry['event_metric'], 'events_per_proc': entry.get('events_per_proc', 1),
             'measurements': labels, 'event_labels': [label for label, _ in event_terms(entry)],
             'exclude_trigger_casts': excludes_trigger_casts(entry),
             'readings': [{key: reading[key] for key in ('name', 'labels', 'minus_events')}
                          for reading in trial_readings(entry)]}
    expectation = Expectation(proc_label(aura), PROC_CHECK, aura, aura, None, entry['chance_token'],
                              f'{WILSON_RULE}; {trial_rule(entry)}{handler_note(entry)}', model)
    return timed(scenario, SETTLE_MS + plan.per_part * plan.attempt_ms + DRAIN_MS), [expectation]


def handler_note(entry: dict) -> str:
    return f'; handler: {entry["handler"]}' if entry.get('handler') else ''


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
