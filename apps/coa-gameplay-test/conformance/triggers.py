from dataclasses import dataclass
import math
from typing import Sequence

from hits import (DRAIN_MS, EXCLUDED_OUTCOME_MARGIN, MAIN_HAND, UNMODELLED, Unmodelled, cast_steps, creature_fixture,
                  records_of, scenario_shell, timed)
from procs import ATTACK, CAST, ENTRY_STATUSES, PART_BUDGET_MS, cast_interval, swing_interval
from profile import CASTER, SETTLE_MS, measurement
from values import TARGET, Expectation, facts_of

TRIGGER_CHECK = 'trigger_count'
MISSED_TRIGGER_RATE = 0.025
FALSE_OK_RISK = 0.01
TRIGGER_TRIALS = math.ceil(math.log(FALSE_OK_RISK) / math.log(1 - MISSED_TRIGGER_RATE))
BASELINE_ATTEMPTS = 20
EVENT_TOLERANCE = 1
SELF = 'self'
TRIGGER_TARGETS = frozenset({SELF, TARGET})
OBSERVE_METRICS = frozenset({'spell_cast_count', 'spell_energize_count'})
MELEE_COUNTS = frozenset({'melee_attack_count', 'melee_damage_count'})
TRIAL_METRICS = {CAST: frozenset({'spell_cast_count', 'spell_damage_count'}), ATTACK: MELEE_COUNTS}
TRIGGER_RULE = (f'|events - trials x per_trigger| <= {EVENT_TOLERANCE} over at least {TRIGGER_TRIALS} trials, '
                f'no event in the {BASELINE_ATTEMPTS} baseline attempts without the passive')


@dataclass(frozen=True)
class TriggerPlan:
    scheduled: int
    attempt_ms: int
    part_attempts: tuple[int, ...]


def trigger_label(aura: int) -> str:
    return f'{aura} trigger_count'


def trigger_measurements(aura: int) -> dict[str, str]:
    return {'baseline_trials': f'{aura} trigger baseline trials', 'without': f'{aura} trigger without',
            'aura': f'{aura} trigger aura', 'trials': f'{aura} trigger trials', 'events': f'{aura} trigger events'}


def checked_entry(entry: dict) -> dict:
    aura = entry['aura']
    if entry.get('status'):
        raise ValueError(f'Trigger {aura} is {entry["status"]}: {entry.get("reason", "")}')
    trigger = entry['trigger']
    if trigger['action'] not in TRIAL_METRICS:
        raise ValueError(f'Unknown trigger action {trigger["action"]!r} of trigger {aura}')
    if entry['trial_metric'] not in TRIAL_METRICS[trigger['action']]:
        raise ValueError(f'Trial metric {entry["trial_metric"]!r} of trigger {aura} does not count a '
                         f'{trigger["action"]}')
    if trigger['action'] == CAST and trigger.get('target') not in TRIGGER_TARGETS:
        raise ValueError(f'Trigger {aura} casts at {trigger.get("target")!r}, not one of {sorted(TRIGGER_TARGETS)}')
    if entry['observe_metric'] not in OBSERVE_METRICS:
        raise ValueError(f'Unknown observe metric {entry["observe_metric"]!r} of trigger {aura}')
    if not 0 < entry['per_trigger'] <= 1:
        raise ValueError(f'Trigger {aura} has {entry["per_trigger"]} events per trigger')
    if entry.get('attempt_auras') and trigger['action'] != CAST:
        raise ValueError(f'Trigger {aura} sets attempt auras without a cast before which to set them')
    return entry


def attempt_interval(class_file: dict, entry: dict) -> int:
    trigger = entry['trigger']
    if trigger['action'] == ATTACK:
        return swing_interval(class_file)
    if facts_of(records_of(class_file), trigger['spell']).passive:
        raise Unmodelled(f'trigger spell {trigger["spell"]} is passive')
    return cast_interval(class_file, trigger['spell'])


def trigger_plan(class_file: dict, entry: dict) -> TriggerPlan:
    checked_entry(entry)
    scheduled = math.ceil(TRIGGER_TRIALS * EXCLUDED_OUTCOME_MARGIN)
    interval = attempt_interval(class_file, entry)
    first = (PART_BUDGET_MS - DRAIN_MS) // interval - BASELINE_ATTEMPTS
    if first < 1:
        raise Unmodelled(f'the {BASELINE_ATTEMPTS} baseline attempts of {interval} ms leave no room in the scenario '
                         f'budget of {PART_BUDGET_MS} ms')
    parts = [min(first, scheduled)]
    while sum(parts) < scheduled:
        parts.append(min(PART_BUDGET_MS // interval, scheduled - sum(parts)))
    return TriggerPlan(scheduled=scheduled, attempt_ms=interval, part_attempts=tuple(parts))


def trial_spell(entry: dict) -> int:
    return entry['trigger']['spell'] if entry['trigger']['action'] == CAST else 0


def count_step(label: str, metric: str, spell: int) -> dict:
    if metric in MELEE_COUNTS:
        return measurement(label, CASTER, metric, hand=MAIN_HAND)
    fields = {'target': TARGET} if metric == 'spell_damage_count' else {}
    return measurement(label, CASTER, metric, spell=spell, **fields)


def attempt_fixtures(entry: dict) -> list[dict]:
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': aura['spell'], 'stacks': aura['stacks']}
            for aura in entry.get('attempt_auras', [])]


def attempt_steps(class_file: dict, entry: dict, plan: TriggerPlan, attempts: int, phase: str) -> list[dict]:
    trigger = entry['trigger']
    if trigger['action'] == ATTACK:
        steps = [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                 {'action': 'wait', 'label': f'{phase}swings', 'ms': attempts * plan.attempt_ms},
                 {'action': 'stop_attack', 'actor': CASTER}]
    else:
        facts = facts_of(records_of(class_file), trigger['spell'])
        steps = cast_steps(facts, trigger['spell'], trigger['target'] == TARGET, plan.attempt_ms, attempts,
                           attempt_fixtures(entry))
    return steps + [{'action': 'wait', 'label': f'{phase}drain', 'ms': DRAIN_MS}]


def counts(entry: dict, trials_label: str, events_label: str) -> list[dict]:
    return [count_step(trials_label, entry['trial_metric'], trial_spell(entry)),
            count_step(events_label, entry['observe_metric'], entry['observe_spell'])]


def trigger_rule(entry: dict) -> str:
    trials = entry['trial_metric'] + (f' of {trial_spell(entry)}' if trial_spell(entry) else ' main hand')
    fixtures = ''.join(f'; before each attempt aura {aura["spell"]} set to {aura["stacks"]} stacks ({aura["source"]})'
                       for aura in entry.get('attempt_auras', []))
    return (f'{TRIGGER_RULE}; trials: {trials}; events: {entry["observe_metric"]} of {entry["observe_spell"]} '
            f'({entry["observe_source"]}); {entry["per_trigger"]:g} per trigger ("{entry["per_trigger_text"]}")'
            f'{fixtures}')


def trigger_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    labels = trigger_measurements(aura)
    attempts = plan.part_attempts[part]
    baseline = BASELINE_ATTEMPTS if part == 0 else 0
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']}] if trigger['action'] == CAST else []
    if baseline:
        steps += attempt_steps(class_file, entry, plan, baseline, 'baseline ')
        steps += counts(entry, labels['baseline_trials'], labels['without'])
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': aura})
    steps += attempt_steps(class_file, entry, plan, attempts, '')
    steps += counts(entry, labels['trials'], labels['events'])
    steps.append(measurement(labels['aura'], CASTER, 'aura', spell=aura))
    parts = len(plan.part_attempts)
    name = f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {parts}'
    contract = ('Events of an always-on passive trigger: none before the learn, one per trigger after it, summed over '
                'its parts, against its tooltip.')
    scenario = scenario_shell(class_file, name, contract, steps)
    if trigger['action'] == ATTACK or trigger.get('target') == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
             'baseline_attempts': baseline, 'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS,
             'per_trigger': entry['per_trigger'], 'trigger': dict(trigger), 'trial_metric': entry['trial_metric'],
             'observe_spell': entry['observe_spell'], 'observe_metric': entry['observe_metric'],
             'attempt_auras': [dict(aura) for aura in entry.get('attempt_auras', [])], 'measurements': labels}
    expectation = Expectation(trigger_label(aura), TRIGGER_CHECK, aura, aura, None, entry['trigger_text'],
                              trigger_rule(entry), model)
    baseline_ms = baseline * plan.attempt_ms + DRAIN_MS if baseline else 0
    return timed(scenario, SETTLE_MS + baseline_ms + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def trigger_status_expectation(entry: dict) -> Expectation:
    status = entry.get('status')
    if status not in ENTRY_STATUSES:
        raise ValueError(f'Trigger {entry["aura"]} status {status!r} is not one of {sorted(ENTRY_STATUSES)}')
    return Expectation(trigger_label(entry['aura']), TRIGGER_CHECK, entry['aura'], entry['aura'], None,
                       entry.get('trigger_text', ''), ENTRY_STATUSES[status] + entry['reason'])


def trigger_unmodelled_expectation(entry: dict, reason: str) -> Expectation:
    return Expectation(trigger_label(entry['aura']), TRIGGER_CHECK, entry['aura'], entry['aura'], None,
                       entry.get('trigger_text', ''), UNMODELLED + reason)


def trigger_entries(class_file: dict, auras: Sequence[int] | None = None) -> list[dict]:
    entries = class_file.get('triggers', [])
    if auras is None:
        return list(entries)
    unknown = set(auras) - {entry['aura'] for entry in entries}
    if unknown:
        raise ValueError(f'Auras {sorted(unknown)} have no trigger entry in the {class_file["name"]} class file')
    return [entry for entry in entries if entry['aura'] in auras]
