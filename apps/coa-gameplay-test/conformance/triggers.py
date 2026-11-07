from dataclasses import dataclass
import math
from typing import Sequence

from hits import (DRAIN_MS, EXCLUDED_OUTCOME_MARGIN, MAIN_HAND, UNMODELLED, Unmodelled, cast_steps, creature_fixture,
                  records_of, scenario_shell, timed)
from procs import ATTACK, CAST, ENTRY_STATUSES, PART_BUDGET_MS, cast_interval, swing_interval
from profile import CASTER, SETTLE_MS, measurement, player_fixture
from values import ALLY, CHARGE_OFFSET_YD, TARGET, Expectation, facts_of

TRIGGER_CHECK = 'trigger_count'
MISSED_TRIGGER_RATE = 0.025
FALSE_OK_RISK = 0.01
TRIGGER_TRIALS = math.ceil(math.log(FALSE_OK_RISK) / math.log(1 - MISSED_TRIGGER_RATE))
BASELINE_ATTEMPTS = 20
EVENT_TOLERANCE = 1
SELF = 'self'
ALLY_HEALTH_MAX = 10000
TRIGGER_TARGETS = frozenset({SELF, TARGET, ALLY})
OBSERVE_METRICS = frozenset({'spell_cast_count', 'spell_energize_count', 'aura_apply_count'})
OBSERVE_ACTORS = {CASTER: CASTER, 'target': TARGET}
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
    if entry.get('observe_actor', CASTER) not in OBSERVE_ACTORS:
        raise ValueError(f'Unknown observe actor {entry.get("observe_actor")!r} of trigger {aura}')
    if not 0 < entry['per_trigger'] <= 1:
        raise ValueError(f'Trigger {aura} has {entry["per_trigger"]} events per trigger')
    if entry.get('attempt_auras') and trigger['action'] != CAST:
        raise ValueError(f'Trigger {aura} sets attempt auras without a cast before which to set them')
    if entry.get('ally_health_pct') is not None and trigger.get('target') != ALLY:
        raise ValueError(f'Trigger {aura} sets the ally health without a cast at an ally')
    if entry.get('restore_charges') and trigger['action'] != CAST:
        raise ValueError(f'Trigger {aura} restores charges without a cast to restore them before')
    if entry.get('caster_health_pct') is not None and trigger['action'] != CAST:
        raise ValueError(f'Trigger {aura} sets the caster health without a cast before which to set it')
    factor = entry.get('trial_attempts_factor', 1)
    if factor < 1:
        raise ValueError(f'Trigger {aura} has a trial attempts factor below 1')
    if factor != 1 and not entry.get('trial_attempts_reason'):
        raise ValueError(f'Trigger {aura} scales its trial attempts without a reason')
    return entry


def attempt_interval(class_file: dict, entry: dict) -> int:
    trigger = entry['trigger']
    cooldown = entry.get('internal_cooldown_ms', 0)
    if trigger['action'] == ATTACK:
        return swing_interval(class_file, cooldown)
    if facts_of(records_of(class_file), trigger['spell']).passive:
        raise Unmodelled(f'trigger spell {trigger["spell"]} is passive')
    return cast_interval(class_file, trigger['spell'], cooldown)


def trigger_plan(class_file: dict, entry: dict) -> TriggerPlan:
    checked_entry(entry)
    scheduled = math.ceil(TRIGGER_TRIALS * EXCLUDED_OUTCOME_MARGIN * entry.get('trial_attempts_factor', 1))
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


def observe_actor(entry: dict) -> str:
    return OBSERVE_ACTORS[entry.get('observe_actor', CASTER)]


def count_step(label: str, metric: str, spell: int, actor: str = CASTER) -> dict:
    if metric in MELEE_COUNTS:
        return measurement(label, CASTER, metric, hand=MAIN_HAND)
    fields = {'target': TARGET} if metric == 'spell_damage_count' else {}
    return measurement(label, actor, metric, spell=spell, **fields)


def health_step(actor: str, pct: int) -> dict:
    value = (pct * ALLY_HEALTH_MAX) // 100
    return {'action': 'set_health', 'actor': actor, 'value': value, 'maximum': ALLY_HEALTH_MAX}


def attempt_fixtures(entry: dict) -> list[dict]:
    fixtures = [{'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD}] \
        if entry['trigger'].get('target') == ALLY else []
    if entry.get('restore_charges'):
        fixtures.append({'action': 'restore_charges', 'actor': CASTER, 'spell': entry['trigger']['spell']})
    fixtures += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura['spell'], 'stacks': aura['stacks']}
                for aura in entry.get('attempt_auras', [])]
    if entry.get('caster_health_pct') is not None:
        fixtures.append(health_step(CASTER, entry['caster_health_pct']))
    if entry.get('ally_health_pct') is not None:
        fixtures.append(health_step(ALLY, entry['ally_health_pct']))
    return fixtures


def attempt_steps(class_file: dict, entry: dict, plan: TriggerPlan, attempts: int, phase: str) -> list[dict]:
    trigger = entry['trigger']
    if trigger['action'] == ATTACK:
        steps = [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                 {'action': 'wait', 'label': f'{phase}swings', 'ms': attempts * plan.attempt_ms},
                 {'action': 'stop_attack', 'actor': CASTER}]
    else:
        facts = facts_of(records_of(class_file), trigger['spell'])
        cast_target = trigger['target'] if trigger['target'] in (TARGET, ALLY) else None
        steps = cast_steps(facts, trigger['spell'], cast_target, plan.attempt_ms, attempts, attempt_fixtures(entry))
    return steps + [{'action': 'wait', 'label': f'{phase}drain', 'ms': DRAIN_MS}]


def counts(entry: dict, trials_label: str, events_label: str) -> list[dict]:
    return [count_step(trials_label, entry['trial_metric'], trial_spell(entry)),
            count_step(events_label, entry['observe_metric'], entry['observe_spell'], observe_actor(entry))]


def trigger_rule(entry: dict) -> str:
    trials = entry['trial_metric'] + (f' of {trial_spell(entry)}' if trial_spell(entry) else ' main hand')
    fixtures = ''.join(f'; before each attempt aura {aura["spell"]} set to {aura["stacks"]} stacks ({aura["source"]})'
                       for aura in entry.get('attempt_auras', []))
    if entry.get('caster_health_pct') is not None:
        fixtures += f'; before each attempt the caster health set to {entry["caster_health_pct"]}% of max'
    if entry.get('ally_health_pct') is not None:
        fixtures += f'; before each attempt the ally health set to {entry["ally_health_pct"]}% of max'
    if entry.get('restore_charges'):
        fixtures += f'; before each attempt the charges of {entry["trigger"]["spell"]} are restored'
    cooldown = entry.get('internal_cooldown_ms', 0)
    if cooldown:
        fixtures += f'; attempts spaced at least {cooldown} ms apart (internal cooldown)'
    factor = entry.get('trial_attempts_factor', 1)
    scaled = f'; scheduled attempts x{factor:g} ({entry["trial_attempts_reason"]})' if factor != 1 else ''
    on_target = ' on the target' if entry.get('observe_actor') == 'target' else ''
    return (f'{TRIGGER_RULE}; trials: {trials}; events: {entry["observe_metric"]} of {entry["observe_spell"]}'
            f'{on_target} ({entry["observe_source"]}); {entry["per_trigger"]:g} per trigger '
            f'("{entry["per_trigger_text"]}"){fixtures}{scaled}')


def trigger_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    labels = trigger_measurements(aura)
    attempts = plan.part_attempts[part]
    baseline = BASELINE_ATTEMPTS if part == 0 else 0
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']}] if trigger['action'] == CAST else []
    if trigger.get('target') == ALLY:
        steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
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
    if trigger.get('target') == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
             'baseline_attempts': baseline, 'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS,
             'per_trigger': entry['per_trigger'], 'trigger': dict(trigger), 'trial_metric': entry['trial_metric'],
             'observe_spell': entry['observe_spell'], 'observe_metric': entry['observe_metric'],
             'observe_actor': entry.get('observe_actor', CASTER),
             'attempt_auras': [dict(aura) for aura in entry.get('attempt_auras', [])],
             'caster_health_pct': entry.get('caster_health_pct'), 'ally_health_pct': entry.get('ally_health_pct'),
             'restore_charges': entry.get('restore_charges', False),
             'internal_cooldown_ms': entry.get('internal_cooldown_ms', 0),
             'trial_attempts_factor': entry.get('trial_attempts_factor', 1), 'measurements': labels}
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
