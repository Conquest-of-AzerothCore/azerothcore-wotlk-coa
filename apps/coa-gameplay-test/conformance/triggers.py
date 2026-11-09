from dataclasses import dataclass
import math
from typing import Sequence

from behaviours import STRIKER, STRIKER_DISTANCE, STRIKER_HEALTH
from hits import (DRAIN_MS, EXCLUDED_OUTCOME_MARGIN, MAIN_HAND, UNMODELLED, Unmodelled, cast_steps, creature_fixture,
                  records_of, scenario_shell, timed)
from procs import ATTACK, CAST, ENTRY_STATUSES, PART_BUDGET_MS, cast_interval, swing_interval, tick_spacing
from profile import CASTER, SETTLE_MS, measurement, player_fixture
from values import (ALLY, CHARGE_OFFSET_YD, FORCED_CRIT_RATING, TARGET, Expectation, RankFacts, armed_for,
                    closes_distance, facts_of, fixture_health_step)

TRIGGER_CHECK = 'trigger_count'
COOLDOWN_DELTA_KIND = 'cooldown_delta'
COOLDOWN_CHECK = 'trigger_cooldown_delta'
MISSED_TRIGGER_RATE = 0.025
FALSE_OK_RISK = 0.01
TRIGGER_TRIALS = math.ceil(math.log(FALSE_OK_RISK) / math.log(1 - MISSED_TRIGGER_RATE))
BASELINE_ATTEMPTS = 20
EVENT_TOLERANCE = 1
SELF = 'self'
PERIODIC = 'periodic'
TAKEN_HIT = 'taken_hit'
TAKEN_HIT_MIN_INTERVAL_MS = 500
TRIGGER_TARGETS = frozenset({SELF, TARGET, ALLY})
OBSERVE_METRICS = frozenset({'spell_cast_count', 'spell_energize_count', 'aura_apply_count'})
OBSERVE_ACTORS = {CASTER: CASTER, 'target': TARGET}
MELEE_COUNTS = frozenset({'melee_attack_count', 'melee_damage_count'})
PERIODIC_TRIAL_METRICS = frozenset({'spell_cast_count'})
TAKEN_HIT_TRIAL_METRICS = frozenset({'spell_damage_count'})
TRIAL_METRICS = {CAST: frozenset({'spell_cast_count', 'spell_damage_count'}), ATTACK: MELEE_COUNTS,
                PERIODIC: PERIODIC_TRIAL_METRICS, TAKEN_HIT: TAKEN_HIT_TRIAL_METRICS}
FORCE_CRIT_RATINGS = {'melee': 'melee_crit_rating', 'spell': 'spell_crit_rating'}
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


def checked_cooldown_entry(entry: dict) -> dict:
    aura = entry['aura']
    trigger = entry['trigger']
    if trigger['action'] != CAST:
        raise ValueError(f'Cooldown-delta trigger {aura} must cast, not {trigger["action"]!r}')
    if trigger.get('target') not in TRIGGER_TARGETS:
        raise ValueError(f'Cooldown-delta trigger {aura} casts at {trigger.get("target")!r}, not one of '
                         f'{sorted(TRIGGER_TARGETS)}')
    if entry.get('observe_metric') != 'cooldown_ms':
        raise ValueError(f'Cooldown-delta trigger {aura} observe_metric must be cooldown_ms, not '
                         f'{entry.get("observe_metric")!r}')
    if not entry.get('expected_delta_ms', 0) > 0:
        raise ValueError(f'Cooldown-delta trigger {aura} needs a positive expected_delta_ms')
    if entry.get('force_crit') is not None and entry['force_crit'] not in FORCE_CRIT_RATINGS:
        raise ValueError(f'Trigger {aura} has an unknown force_crit {entry["force_crit"]!r}, not one of '
                         f'{sorted(FORCE_CRIT_RATINGS)}')
    return entry


def checked_entry(entry: dict) -> dict:
    aura = entry['aura']
    if entry.get('status'):
        raise ValueError(f'Trigger {aura} is {entry["status"]}: {entry.get("reason", "")}')
    if entry.get('kind') == COOLDOWN_DELTA_KIND:
        return checked_cooldown_entry(entry)
    trigger = entry['trigger']
    if trigger['action'] not in TRIAL_METRICS:
        raise ValueError(f'Unknown trigger action {trigger["action"]!r} of trigger {aura}')
    if entry['trial_metric'] not in TRIAL_METRICS[trigger['action']]:
        raise ValueError(f'Trial metric {entry["trial_metric"]!r} of trigger {aura} does not count a '
                         f'{trigger["action"]}')
    if trigger['action'] == CAST and trigger.get('target') not in TRIGGER_TARGETS:
        raise ValueError(f'Trigger {aura} casts at {trigger.get("target")!r}, not one of {sorted(TRIGGER_TARGETS)}')
    if trigger['action'] == TAKEN_HIT and not trigger.get('striker_entry', 0) > 0:
        raise ValueError(f'Trigger {aura} taken_hit action needs a positive striker_entry')
    if trigger['action'] == PERIODIC and trigger.get('amplitude_ms', 0) <= 0:
        raise ValueError(f'Trigger {aura} periodic action needs a positive amplitude_ms')
    if entry.get('periodic_initial_tick') and trigger['action'] != PERIODIC:
        raise ValueError(f'Trigger {aura} has an initial tick without a periodic action')
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
    if any(not isinstance(spell, int) for spell in entry.get('co_learn', [])):
        raise ValueError(f'Trigger {aura} has a non-integer co_learn spell')
    if entry.get('force_crit') is not None and entry['force_crit'] not in FORCE_CRIT_RATINGS:
        raise ValueError(f'Trigger {aura} has an unknown force_crit {entry["force_crit"]!r}, not one of '
                         f'{sorted(FORCE_CRIT_RATINGS)}')
    factor = entry.get('trial_attempts_factor', 1)
    if factor < 1:
        raise ValueError(f'Trigger {aura} has a trial attempts factor below 1')
    if factor != 1 and not entry.get('trial_attempts_reason'):
        raise ValueError(f'Trigger {aura} scales its trial attempts without a reason')
    return entry


def attempt_interval(class_file: dict, entry: dict) -> int:
    trigger = entry['trigger']
    if trigger['action'] == PERIODIC:
        return trigger['amplitude_ms']
    cooldown = entry.get('internal_cooldown_ms', 0)
    if trigger['action'] == ATTACK:
        return swing_interval(class_file, cooldown)
    if trigger['action'] == TAKEN_HIT:
        return max(cast_interval(class_file, trigger['spell'], cooldown), TAKEN_HIT_MIN_INTERVAL_MS)
    facts = facts_of(records_of(class_file), trigger['spell'])
    if facts.passive:
        raise Unmodelled(f'trigger spell {trigger["spell"]} is passive')
    interval = max(cast_interval(class_file, trigger['spell'], cooldown),
                   tick_spacing(class_file, facts, trigger['spell']))
    if entry.get('kind') == COOLDOWN_DELTA_KIND:
        interval += cast_interval(class_file, entry['observe_spell'], 0)
    return interval


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
    return entry['trigger']['spell'] if entry['trigger']['action'] in (CAST, TAKEN_HIT) else 0


def observe_actor(entry: dict) -> str:
    return OBSERVE_ACTORS[entry.get('observe_actor', CASTER)]


def count_step(label: str, metric: str, spell: int, actor: str = CASTER, target: str = TARGET,
              caster: str | None = None) -> dict:
    if metric in MELEE_COUNTS:
        return measurement(label, CASTER, metric, hand=MAIN_HAND)
    fields = {}
    if metric == 'spell_damage_count':
        fields['target'] = target
        if caster is not None:
            fields['caster'] = caster
    return measurement(label, actor, metric, spell=spell, **fields)


def attempt_fixtures(entry: dict, facts: RankFacts) -> list[dict]:
    fixtures = [{'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD}] \
        if entry['trigger'].get('target') == ALLY and closes_distance(facts) else []
    if entry.get('restore_charges'):
        fixtures.append({'action': 'restore_charges', 'actor': CASTER, 'spell': entry['trigger']['spell']})
    fixtures += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura['spell'], 'stacks': aura['stacks']}
                for aura in entry.get('attempt_auras', [])]
    if entry.get('caster_health_pct') is not None:
        fixtures.append(fixture_health_step(CASTER, entry['caster_health_pct']))
    if entry.get('ally_health_pct') is not None:
        fixtures.append(fixture_health_step(ALLY, entry['ally_health_pct']))
    return fixtures


def attempt_steps(class_file: dict, entry: dict, plan: TriggerPlan, attempts: int, phase: str) -> list[dict]:
    trigger = entry['trigger']
    if trigger['action'] == PERIODIC:
        return [{'action': 'wait', 'label': f'{phase}ticks', 'ms': attempts * plan.attempt_ms}]
    if trigger['action'] == ATTACK:
        steps = [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                 {'action': 'wait', 'label': f'{phase}swings', 'ms': attempts * plan.attempt_ms},
                 {'action': 'stop_attack', 'actor': CASTER}]
    elif trigger['action'] == TAKEN_HIT:
        steps = []
        for _ in range(attempts):
            steps.append({'action': 'cast', 'actor': STRIKER, 'spell': trigger['spell'], 'target': CASTER})
            steps.append({'action': 'wait', 'ms': plan.attempt_ms})
    else:
        facts = facts_of(records_of(class_file), trigger['spell'])
        cast_target = trigger['target'] if trigger['target'] in (TARGET, ALLY) else None
        steps = cast_steps(facts, trigger['spell'], cast_target, plan.attempt_ms, attempts,
                           attempt_fixtures(entry, facts))
    return steps + [{'action': 'wait', 'label': f'{phase}drain', 'ms': DRAIN_MS}]


def counts(entry: dict, trials_label: str, events_label: str) -> list[dict]:
    action = entry['trigger']['action']
    if action == PERIODIC:
        steps = []
    elif action == TAKEN_HIT:
        steps = [count_step(trials_label, entry['trial_metric'], trial_spell(entry), target=CASTER, caster=STRIKER)]
    else:
        steps = [count_step(trials_label, entry['trial_metric'], trial_spell(entry))]
    steps.append(count_step(events_label, entry['observe_metric'], entry['observe_spell'], observe_actor(entry)))
    return steps


def trigger_rule(entry: dict) -> str:
    trigger = entry['trigger']
    if trigger['action'] == PERIODIC:
        trials = f'periodic ticks every {trigger["amplitude_ms"]} ms'
    else:
        trials = entry['trial_metric'] + (f' of {trial_spell(entry)}' if trial_spell(entry) else ' main hand')
    fixtures = ''.join(f'; before each attempt aura {aura["spell"]} set to {aura["stacks"]} stacks ({aura["source"]})'
                       for aura in entry.get('attempt_auras', []))
    fixtures += ''.join(f'; {entry["aura"]} also learns {spell}' for spell in entry.get('co_learn', []))
    if entry.get('caster_health_pct') is not None:
        fixtures += f'; before each attempt the caster health set to {entry["caster_health_pct"]}% of max'
    if entry.get('ally_health_pct') is not None:
        fixtures += f'; before each attempt the ally health set to {entry["ally_health_pct"]}% of max'
    if entry.get('restore_charges'):
        fixtures += f'; before each attempt the charges of {entry["trigger"]["spell"]} are restored'
    if entry.get('periodic_initial_tick'):
        fixtures += '; one extra tick on every learn (SPELL_ATTR5_EXTRA_INITIAL_PERIOD)'
    if entry.get('force_crit'):
        fixtures += f'; every attempt forced to crit ({entry["force_crit"]})'
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
    if entry['trigger']['action'] == CAST:
        class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
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
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in entry.get('co_learn', [])]
    steps += attempt_steps(class_file, entry, plan, attempts, '')
    steps += counts(entry, labels['trials'], labels['events'])
    steps.append(measurement(labels['aura'], CASTER, 'aura', spell=aura))
    parts = len(plan.part_attempts)
    name = f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {parts}'
    contract = ('Events of an always-on passive trigger: none before the learn, one per trigger after it, summed over '
                'its parts, against its tooltip.')
    scenario = scenario_shell(class_file, name, contract, steps)
    force_crit = entry.get('force_crit')
    if force_crit:
        scenario['players'][0][FORCE_CRIT_RATINGS[force_crit]] = FORCED_CRIT_RATING
    if trigger['action'] == TAKEN_HIT:
        scenario['creatures'] = [{'id': STRIKER, 'owner': CASTER, 'entry': trigger['striker_entry'],
                                  'level': class_file['level'], 'health': STRIKER_HEALTH,
                                  'distance': STRIKER_DISTANCE, 'reaction': 0, 'stationary': True}]
    elif trigger['action'] == ATTACK or trigger.get('target') == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    if trigger.get('target') == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
             'baseline_attempts': baseline, 'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS,
             'per_trigger': entry['per_trigger'], 'trigger': dict(trigger), 'trial_metric': entry['trial_metric'],
             'observe_spell': entry['observe_spell'], 'observe_metric': entry['observe_metric'],
             'observe_actor': entry.get('observe_actor', CASTER),
             'attempt_auras': [dict(aura) for aura in entry.get('attempt_auras', [])],
             'co_learn': list(entry.get('co_learn', [])), 'force_crit': force_crit,
             'caster_health_pct': entry.get('caster_health_pct'), 'ally_health_pct': entry.get('ally_health_pct'),
             'restore_charges': entry.get('restore_charges', False),
             'internal_cooldown_ms': entry.get('internal_cooldown_ms', 0),
             'trial_attempts_factor': entry.get('trial_attempts_factor', 1),
             'periodic_initial_tick': entry.get('periodic_initial_tick', False), 'measurements': labels}
    expectation = Expectation(trigger_label(aura), TRIGGER_CHECK, aura, aura, None, entry['trigger_text'],
                              trigger_rule(entry), model)
    baseline_ms = baseline * plan.attempt_ms + DRAIN_MS if baseline else 0
    return timed(scenario, SETTLE_MS + baseline_ms + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def cooldown_label(aura: int) -> str:
    return f'{aura} trigger_cooldown_delta'


def cooldown_trial_label(aura: int, phase: str, index: int, moment: str) -> str:
    return f'{aura} trigger cooldown {phase} {index} {moment}'


def cooldown_measurement_labels(aura: int) -> dict[str, str]:
    return {'aura': f'{aura} trigger cooldown aura'}


def cooldown_trial_steps(class_file: dict, entry: dict, count: int, phase: str) -> list[dict]:
    if count <= 0:
        return []
    aura, trigger = entry['aura'], entry['trigger']
    observe_facts = facts_of(records_of(class_file), entry['observe_spell'])
    trigger_facts = facts_of(records_of(class_file), trigger['spell'])
    observe_interval = cast_interval(class_file, entry['observe_spell'], 0)
    trigger_interval = cast_interval(class_file, trigger['spell'], entry.get('internal_cooldown_ms', 0))
    trigger_target = trigger['target'] if trigger['target'] in (TARGET, ALLY) else None
    steps = []
    for index in range(count):
        steps += cast_steps(observe_facts, entry['observe_spell'], None, 0, 1)
        steps.append(measurement(cooldown_trial_label(aura, phase, index, 'before'), CASTER, 'cooldown_ms',
                                 spell=entry['observe_spell']))
        steps += cast_steps(trigger_facts, trigger['spell'], trigger_target, 0, 1)
        steps.append(measurement(cooldown_trial_label(aura, phase, index, 'after'), CASTER, 'cooldown_ms',
                                 spell=entry['observe_spell']))
        steps.append({'action': 'wait', 'label': f'{phase}spacing', 'ms': observe_interval + trigger_interval})
    return steps


def cooldown_trigger_rule(entry: dict) -> str:
    return (f'baseline delta 0 ms over {BASELINE_ATTEMPTS} attempts without the passive; measured delta of '
            f'{entry["observe_metric"]} of {entry["observe_spell"]} between a cast of {entry["observe_spell"]} and '
            f'a cast of {entry["trigger"]["spell"]} matches {entry["expected_delta_ms"]:g} ms within '
            f'max(1, 0.5% of expected), over at least {TRIGGER_TRIALS} trials ("{entry["per_trigger_text"]}")')


def cooldown_trigger_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    class_file = armed_for(class_file, records_of(class_file), entry['observe_spell'])
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    attempts = plan.part_attempts[part]
    baseline = BASELINE_ATTEMPTS if part == 0 else 0
    labels = cooldown_measurement_labels(aura)
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']},
             {'action': 'learn', 'actor': CASTER, 'spell': entry['observe_spell']}]
    if trigger.get('target') == ALLY:
        steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
    if baseline:
        steps += cooldown_trial_steps(class_file, entry, baseline, 'baseline')
        steps.append({'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS})
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': aura})
    steps += cooldown_trial_steps(class_file, entry, attempts, 'measured')
    steps.append({'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS})
    steps.append(measurement(labels['aura'], CASTER, 'aura', spell=aura))
    parts = len(plan.part_attempts)
    name = f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {parts}'
    contract = ('Cooldown delta of an always-on passive: no change before the learn, a fixed cooldown reduction per '
               'trigger after it, summed over its parts, against its tooltip.')
    scenario = scenario_shell(class_file, name, contract, steps)
    if trigger['action'] == ATTACK or trigger.get('target') == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    if trigger.get('target') == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
            'baseline_attempts': baseline, 'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS,
            'trigger': dict(trigger), 'observe_spell': entry['observe_spell'],
            'observe_metric': entry['observe_metric'], 'expected_delta_ms': entry['expected_delta_ms'],
            'measurements': labels}
    expectation = Expectation(cooldown_label(aura), COOLDOWN_CHECK, aura, aura, None, entry['trigger_text'],
                              cooldown_trigger_rule(entry), model)
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
