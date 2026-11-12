from dataclasses import dataclass
import math
from typing import Sequence

from behaviours import STRIKER, STRIKER_DISTANCE, STRIKER_HEALTH
from hits import (DRAIN_MS, EXCLUDED_OUTCOME_MARGIN, MAIN_HAND, UNMODELLED, Unmodelled, cast_steps, creature_fixture,
                  magic_schools, records_of, scenario_shell, target_steps, timed)
from mitigation import PHYSICAL_SCHOOL_MASK
from procs import ATTACK, CAST, ENTRY_STATUSES, PART_BUDGET_MS, cast_interval, swing_interval, tick_spacing
from profile import CASTER, SETTLE_MS, measurement, off_hand_steps, one_hand_main, player_fixture
from values import (ALLY, CAST_MARGIN_MS, CHARGE_OFFSET_YD, FORCE_CRIT_RATINGS, FORCED_CRIT_RATING, TARGET, Expectation,
                    RankFacts, armed_for, closes_distance, facts_of, fixture_health_step)

TRIGGER_CHECK = 'trigger_count'
COOLDOWN_DELTA_KIND = 'cooldown_delta'
COOLDOWN_CHECK = 'trigger_cooldown_delta'
DURATION_DELTA_KIND = 'duration_delta'
DURATION_CHECK = 'trigger_duration_delta'
MAGNITUDE_RATIO_KIND = 'magnitude_ratio'
MAGNITUDE_CHECK = 'trigger_magnitude_ratio'
SELF_TRIGGER_KIND = 'self_trigger'
SELF_TRIGGER_CHECK = 'self_trigger_count'
GATE_ABSENCE_KIND = 'gate_absence'
GATE_ABSENCE_CHECK = 'gate_absence_count'
MAGNITUDE_TRIGGER_METRICS_BY_ACTION = {'cast': frozenset({'spell_damage_total'}),
                                       'attack': frozenset({'melee_damage_total'}),
                                       'taken_hit': frozenset({'spell_damage_total'})}
MAGNITUDE_OBSERVE_METRICS = frozenset({'spell_damage_total', 'spell_heal_total'})
MISSED_TRIGGER_RATE = 0.025
FALSE_OK_RISK = 0.01
TRIGGER_TRIALS = math.ceil(math.log(FALSE_OK_RISK) / math.log(1 - MISSED_TRIGGER_RATE))
BASELINE_ATTEMPTS = 20
EVENT_TOLERANCE = 1
SELF = 'self'
PERIODIC = 'periodic'
TAKEN_HIT = 'taken_hit'
TAKEN_HIT_MIN_INTERVAL_MS = 500
TAKEN_HIT_HEALTH_PCT = 100
TRIGGER_TARGETS = frozenset({SELF, TARGET, ALLY})
OBSERVE_METRICS = frozenset({'spell_cast_count', 'spell_energize_count', 'aura_apply_count'})
OBSERVE_ACTORS = {CASTER: CASTER, 'target': TARGET}
MELEE_COUNTS = frozenset({'melee_attack_count', 'melee_damage_count'})
DUAL_WIELD_FIELDS = (frozenset({'spell', 'off_hand_item', 'source'}),
                     frozenset({'known_spell', 'off_hand_item', 'source'}))
PERIODIC_TRIAL_METRICS = frozenset({'spell_cast_count'})
TAKEN_HIT_TRIAL_METRICS = frozenset({'spell_damage_count'})
TRIAL_METRICS = {CAST: frozenset({'spell_cast_count', 'spell_damage_count'}), ATTACK: MELEE_COUNTS,
                PERIODIC: PERIODIC_TRIAL_METRICS, TAKEN_HIT: TAKEN_HIT_TRIAL_METRICS}
TRIGGER_RULE = (f'|events - trials x per_trigger| <= {EVENT_TOLERANCE} over at least {TRIGGER_TRIALS} trials, '
                f'no event in the {BASELINE_ATTEMPTS} baseline attempts without the passive')


@dataclass(frozen=True)
class TriggerPlan:
    scheduled: int
    attempt_ms: int
    part_attempts: tuple[int, ...]


def trigger_label(aura: int, trigger_spell: int | str | None = None) -> str:
    return f'{aura} trigger_count' if trigger_spell is None else f'{aura} trigger_count {trigger_spell}'


def shares_trigger_aura(class_file: dict, entry: dict) -> bool:
    return sum(1 for other in class_file.get('triggers', [])
              if other.get('kind') is None and not other.get('status') and other['aura'] == entry['aura']) > 1


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
    if any(not isinstance(spell, int) for spell in entry.get('setup_casts', [])):
        raise ValueError(f'Cooldown-delta trigger {aura} has a non-integer setup_casts spell')
    if entry.get('observe_target') is not None and entry['observe_target'] not in TRIGGER_TARGETS:
        raise ValueError(f'Cooldown-delta trigger {aura} has an unknown observe_target '
                         f'{entry["observe_target"]!r}, not one of {sorted(TRIGGER_TARGETS)}')
    return entry


def checked_duration_entry(entry: dict) -> dict:
    aura = entry['aura']
    trigger = entry['trigger']
    if trigger['action'] != CAST:
        raise ValueError(f'Duration-delta trigger {aura} must cast, not {trigger["action"]!r}')
    if trigger.get('target') not in TRIGGER_TARGETS:
        raise ValueError(f'Duration-delta trigger {aura} casts at {trigger.get("target")!r}, not one of '
                         f'{sorted(TRIGGER_TARGETS)}')
    if entry.get('observe_metric') != 'aura_duration_ms':
        raise ValueError(f'Duration-delta trigger {aura} observe_metric must be aura_duration_ms, not '
                         f'{entry.get("observe_metric")!r}')
    if not entry.get('expected_delta_ms', 0) > 0:
        raise ValueError(f'Duration-delta trigger {aura} needs a positive expected_delta_ms')
    if not entry.get('decay_wait_ms', 0) > entry.get('expected_delta_ms', 0):
        raise ValueError(f'Duration-delta trigger {aura} needs decay_wait_ms greater than expected_delta_ms')
    return entry


def checked_magnitude_entry(entry: dict) -> dict:
    aura = entry['aura']
    trigger = entry['trigger']
    if trigger['action'] not in MAGNITUDE_TRIGGER_METRICS_BY_ACTION:
        raise ValueError(f'Magnitude-ratio trigger {aura} must cast, attack or take a hit, not {trigger["action"]!r}')
    if trigger['action'] == CAST:
        if trigger.get('target') not in TRIGGER_TARGETS:
            raise ValueError(f'Magnitude-ratio trigger {aura} casts at {trigger.get("target")!r}, not one of '
                             f'{sorted(TRIGGER_TARGETS)}')
    elif trigger['action'] == TAKEN_HIT:
        if not trigger.get('spell', 0) > 0 or not trigger.get('striker_entry', 0) > 0:
            raise ValueError(f'Magnitude-ratio taken_hit trigger {aura} needs a striker spell and a positive '
                             f'striker_entry')
    elif trigger.get('spell', 0) != 0:
        raise ValueError(f'Magnitude-ratio attack trigger {aura} must not name a spell')
    if entry.get('trigger_metric') not in MAGNITUDE_TRIGGER_METRICS_BY_ACTION[trigger['action']]:
        raise ValueError(f'Magnitude-ratio trigger {aura} trigger_metric must be one of '
                         f'{sorted(MAGNITUDE_TRIGGER_METRICS_BY_ACTION[trigger["action"]])} for a '
                         f'{trigger["action"]!r} trigger, not {entry.get("trigger_metric")!r}')
    if entry.get('observe_metric') not in MAGNITUDE_OBSERVE_METRICS:
        raise ValueError(f'Magnitude-ratio trigger {aura} observe_metric must be one of '
                         f'{sorted(MAGNITUDE_OBSERVE_METRICS)}, not {entry.get("observe_metric")!r}')
    if not entry.get('expected_ratio', 0) > 0:
        raise ValueError(f'Magnitude-ratio trigger {aura} needs a positive expected_ratio')
    if entry.get('force_crit') is not None and entry['force_crit'] not in FORCE_CRIT_RATINGS:
        raise ValueError(f'Trigger {aura} has an unknown force_crit {entry["force_crit"]!r}, not one of '
                         f'{sorted(FORCE_CRIT_RATINGS)}')
    factor = entry.get('trial_attempts_factor', 1)
    if factor < 1:
        raise ValueError(f'Trigger {aura} has a trial attempts factor below 1')
    if factor != 1 and not entry.get('trial_attempts_reason'):
        raise ValueError(f'Trigger {aura} scales its trial attempts without a reason')
    return entry


def checked_self_trigger_entry(entry: dict) -> dict:
    aura = entry['aura']
    trigger = entry['trigger']
    if trigger['action'] != CAST:
        raise ValueError(f'Self-trigger {aura} must cast, not {trigger["action"]!r}')
    if trigger['spell'] != aura:
        raise ValueError(f'Self-trigger {aura} trigger spell must equal the aura (its own cast is the trigger, '
                         f'with no separate passive to gate a baseline against), not {trigger["spell"]}')
    if trigger.get('target') not in TRIGGER_TARGETS:
        raise ValueError(f'Self-trigger {aura} casts at {trigger.get("target")!r}, not one of '
                         f'{sorted(TRIGGER_TARGETS)}')
    if entry['trial_metric'] not in TRIAL_METRICS[CAST]:
        raise ValueError(f'Trial metric {entry["trial_metric"]!r} of self-trigger {aura} does not count a cast')
    if entry['observe_metric'] not in OBSERVE_METRICS:
        raise ValueError(f'Unknown observe metric {entry["observe_metric"]!r} of self-trigger {aura}')
    if entry.get('observe_actor', CASTER) not in OBSERVE_ACTORS:
        raise ValueError(f'Unknown observe actor {entry.get("observe_actor")!r} of self-trigger {aura}')
    if not 0 < entry['per_trigger'] <= 1:
        raise ValueError(f'Self-trigger {aura} has {entry["per_trigger"]} events per trigger')
    if any(not isinstance(spell, int) for spell in entry.get('co_learn', [])):
        raise ValueError(f'Self-trigger {aura} has a non-integer co_learn spell')
    if entry.get('force_crit') is not None and entry['force_crit'] not in FORCE_CRIT_RATINGS:
        raise ValueError(f'Self-trigger {aura} has an unknown force_crit {entry["force_crit"]!r}, not one of '
                         f'{sorted(FORCE_CRIT_RATINGS)}')
    factor = entry.get('trial_attempts_factor', 1)
    if factor < 1:
        raise ValueError(f'Self-trigger {aura} has a trial attempts factor below 1')
    if factor != 1 and not entry.get('trial_attempts_reason'):
        raise ValueError(f'Self-trigger {aura} scales its trial attempts without a reason')
    return entry


RELOCATE_LIMIT_YD = 20.0


def checked_gate_absence_entry(entry: dict) -> dict:
    aura = entry['aura']
    trigger = entry['trigger']
    if trigger['action'] not in (CAST, TAKEN_HIT):
        raise ValueError(f'Gate-absence trigger {aura} must cast or take a hit, not {trigger["action"]!r}')
    if trigger['action'] == CAST and trigger.get('target') not in TRIGGER_TARGETS:
        raise ValueError(f'Gate-absence trigger {aura} casts at {trigger.get("target")!r}, not one of '
                         f'{sorted(TRIGGER_TARGETS)}')
    if trigger['action'] == TAKEN_HIT and not trigger.get('striker_entry', 0) > 0:
        raise ValueError(f'Gate-absence trigger {aura} taken_hit action needs a positive striker_entry')
    if entry['trial_metric'] not in TRIAL_METRICS[trigger['action']]:
        raise ValueError(f'Trial metric {entry["trial_metric"]!r} of gate-absence trigger {aura} does not count '
                         f'a {trigger["action"]}')
    if entry['observe_metric'] not in OBSERVE_METRICS:
        raise ValueError(f'Unknown observe metric {entry["observe_metric"]!r} of gate-absence trigger {aura}')
    if entry.get('observe_actor', CASTER) not in OBSERVE_ACTORS:
        raise ValueError(f'Unknown observe actor {entry.get("observe_actor")!r} of gate-absence trigger {aura}')
    if entry.get('attempt_auras'):
        raise ValueError(f'Gate-absence trigger {aura} must not set any attempt_auras: it tests their absence')
    if not entry.get('gate_text'):
        raise ValueError(f'Gate-absence trigger {aura} needs gate_text naming the withheld condition')
    away = entry.get('away_yd')
    if away is not None and (trigger.get('target') != TARGET or not 0 < away <= RELOCATE_LIMIT_YD):
        raise ValueError(f'Gate-absence trigger {aura} steps {away!r} yd away; it needs a dummy target and at most '
                         f'{RELOCATE_LIMIT_YD:g} yd')
    return entry


def checked_entry(entry: dict) -> dict:
    aura = entry['aura']
    if entry.get('status'):
        raise ValueError(f'Trigger {aura} is {entry["status"]}: {entry.get("reason", "")}')
    if entry.get('kind') == COOLDOWN_DELTA_KIND:
        return checked_cooldown_entry(entry)
    if entry.get('kind') == DURATION_DELTA_KIND:
        return checked_duration_entry(entry)
    if entry.get('kind') == MAGNITUDE_RATIO_KIND:
        return checked_magnitude_entry(entry)
    if entry.get('kind') == SELF_TRIGGER_KIND:
        return checked_self_trigger_entry(entry)
    if entry.get('kind') == GATE_ABSENCE_KIND:
        return checked_gate_absence_entry(entry)
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
    if not (0 < entry['per_trigger'] <= 1 or (isinstance(entry['per_trigger'], int) and entry['per_trigger'] > 1)):
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
    if entry.get('trial_metric_fields') and entry['trial_metric'] not in MELEE_COUNTS:
        raise ValueError(f'Trigger {aura} sets trial_metric_fields on a non-melee trial_metric '
                         f'{entry["trial_metric"]!r}')
    if entry.get('trial_spell') is not None:
        if trigger['action'] not in (CAST, TAKEN_HIT):
            raise ValueError(f'Trigger {aura} sets trial_spell without a cast or taken_hit action')
        if entry['trial_metric'] != 'spell_damage_count':
            raise ValueError(f'Trigger {aura} sets trial_spell without trial_metric spell_damage_count')
        if not isinstance(entry['trial_spell'], int):
            raise ValueError(f'Trigger {aura} has a non-integer trial_spell')
    dual_wield = entry.get('dual_wield')
    if dual_wield is not None:
        if trigger['action'] != ATTACK:
            raise ValueError(f'Trigger {aura} sets dual_wield without an attack action')
        if set(dual_wield) not in DUAL_WIELD_FIELDS or not all(
                isinstance(dual_wield[field], int) for field in dual_wield if field != 'source'):
            raise ValueError(f'Trigger {aura} dual_wield is {{"spell" or "known_spell": int, "off_hand_item": int, '
                             f'"source": text}}')
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
        interval += 2 * cast_interval(class_file, entry['observe_spell'], 0)
        interval += sum(cast_interval(class_file, spell, 0) for spell in entry.get('setup_casts', []))
    if entry.get('kind') == DURATION_DELTA_KIND:
        interval += cast_interval(class_file, entry['observe_spell'], 0)
        interval += entry['decay_wait_ms']
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
    trigger = entry['trigger']
    if trigger['action'] not in (CAST, TAKEN_HIT):
        return 0
    return entry.get('trial_spell', trigger['spell'])


def observe_actor(entry: dict) -> str:
    return OBSERVE_ACTORS[entry.get('observe_actor', CASTER)]


def count_step(label: str, metric: str, spell: int, actor: str = CASTER, target: str = TARGET,
              caster: str | None = None, trial_metric_fields: dict | None = None) -> dict:
    if metric in MELEE_COUNTS:
        return measurement(label, CASTER, metric, **{**{'hand': MAIN_HAND}, **(trial_metric_fields or {})})
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
        steps = [step for _ in range(attempts) for step in taken_hit_attempt(trigger, plan.attempt_ms)]
    else:
        facts = facts_of(records_of(class_file), trigger['spell'])
        cast_target = trigger['target'] if trigger['target'] in (TARGET, ALLY) else None
        away = entry.get('away_yd')
        fixtures = attempt_fixtures(entry, facts) + ([relocated(away)] if away else [])
        steps = cast_steps(facts, trigger['spell'], cast_target, plan.attempt_ms, attempts, fixtures)
        if away:
            steps = [relocated(-away)] + [moved for step in steps
                                          for moved in ([step, relocated(-away)] if step['action'] == 'cast'
                                                        else [step])]
    return steps + [{'action': 'wait', 'label': f'{phase}drain', 'ms': DRAIN_MS}]


def taken_hit_attempt(trigger: dict, attempt_ms: int) -> list[dict]:
    return [fixture_health_step(CASTER, TAKEN_HIT_HEALTH_PCT),
            {'action': 'cast', 'actor': STRIKER, 'spell': trigger['spell'], 'target': CASTER},
            {'action': 'wait', 'ms': attempt_ms}]


def away_control_label(aura: int) -> str:
    return f'{aura} gate away control cast'


def relocated(dx: float) -> dict:
    return {'action': 'relocate', 'actor': CASTER, 'dx': dx}


def counts(entry: dict, trials_label: str, events_label: str) -> list[dict]:
    action = entry['trigger']['action']
    trial_metric_fields = entry.get('trial_metric_fields', {})
    if action == PERIODIC:
        steps = []
    elif action == TAKEN_HIT:
        steps = [count_step(trials_label, entry['trial_metric'], trial_spell(entry), target=CASTER, caster=STRIKER,
                            trial_metric_fields=trial_metric_fields)]
    else:
        steps = [count_step(trials_label, entry['trial_metric'], trial_spell(entry),
                            trial_metric_fields=trial_metric_fields)]
    steps.append(count_step(events_label, entry['observe_metric'], entry['observe_spell'], observe_actor(entry)))
    return steps


def trigger_rule(entry: dict) -> str:
    trigger = entry['trigger']
    if trigger['action'] == PERIODIC:
        trials = f'periodic ticks every {trigger["amplitude_ms"]} ms'
    else:
        hand = ' off hand' if entry.get('trial_metric_fields', {}).get('hand', MAIN_HAND) != MAIN_HAND else ' main hand'
        trials = entry['trial_metric'] + (f' of {trial_spell(entry)}' if trial_spell(entry) else hand)
    fixtures = ''.join(f'; before each attempt aura {aura["spell"]} set to {aura["stacks"]} stacks ({aura["source"]})'
                       for aura in entry.get('attempt_auras', []))
    fixtures += ''.join(f'; {entry["aura"]} also learns {spell}' for spell in entry.get('co_learn', []))
    if entry.get('dual_wield'):
        dual_wield = entry['dual_wield']
        granted = (f'learns {dual_wield["spell"]}' if 'spell' in dual_wield
                   else f'is read knowing {dual_wield["known_spell"]}, not granted,')
        fixtures += (f'; before the baseline the caster {granted} and equips off-hand item '
                     f'{dual_wield["off_hand_item"]} ({dual_wield["source"]})')
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


def dual_wielding(class_file: dict) -> dict:
    one_handed = one_hand_main(class_file)
    if one_handed is None:
        raise Unmodelled('dual wielding needs a one-handed main-hand weapon in the class file')
    return one_handed


def dual_wield_steps(entry: dict) -> list[dict]:
    dual_wield = entry.get('dual_wield')
    if dual_wield is None:
        return []
    item = dual_wield['off_hand_item']
    if 'spell' in dual_wield:
        known = [{'action': 'learn', 'actor': CASTER, 'spell': dual_wield['spell']}]
    else:
        known = [measurement(dual_wield_known_label(entry), CASTER, 'knows_spell', spell=dual_wield['known_spell'])]
    return known + off_hand_steps(item)


def striker_fixture(class_file: dict, trigger: dict) -> dict:
    return {'id': STRIKER, 'owner': CASTER, 'entry': trigger['striker_entry'], 'level': class_file['level'],
            'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 0, 'stationary': True}


def dual_wield_known_label(entry: dict) -> str:
    return f'{entry["aura"]} dual_wield knows {entry["dual_wield"]["known_spell"]}'


def trigger_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    if entry['trigger']['action'] == CAST:
        class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    if entry.get('dual_wield'):
        class_file = dual_wielding(class_file)
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    labels = trigger_measurements(aura)
    attempts = plan.part_attempts[part]
    baseline = BASELINE_ATTEMPTS if part == 0 else 0
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']}] if trigger['action'] == CAST else []
    steps += dual_wield_steps(entry)
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
        scenario['creatures'] = [striker_fixture(class_file, trigger)]
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
    if entry.get('dual_wield'):
        model['dual_wield'] = dict(entry['dual_wield'])
    label = trigger_label(aura, trigger.get('spell', trigger['action'])) if shares_trigger_aura(class_file, entry) \
        else trigger_label(aura)
    expectation = Expectation(label, TRIGGER_CHECK, aura, aura, None, entry['trigger_text'],
                              trigger_rule(entry), model)
    baseline_ms = baseline * plan.attempt_ms + DRAIN_MS if baseline else 0
    return timed(scenario, SETTLE_MS + baseline_ms + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def self_trigger_label(aura: int) -> str:
    return f'{aura} self_trigger_count'


def self_trigger_rule(entry: dict) -> str:
    trial = entry['trial_metric'] + f' of {entry["trigger"]["spell"]}'
    fixtures = ''.join(f'; before each attempt aura {aura["spell"]} set to {aura["stacks"]} stacks ({aura["source"]})'
                       for aura in entry.get('attempt_auras', []))
    fixtures += ''.join(f'; {entry["aura"]} also learns {spell}' for spell in entry.get('co_learn', []))
    if entry.get('force_crit'):
        fixtures += f'; every attempt forced to crit ({entry["force_crit"]})'
    factor = entry.get('trial_attempts_factor', 1)
    scaled = f'; scheduled attempts x{factor:g} ({entry["trial_attempts_reason"]})' if factor != 1 else ''
    on_target = ' on the target' if entry.get('observe_actor') == 'target' else ''
    return (f'|events - trials x per_trigger| <= {EVENT_TOLERANCE} over at least {TRIGGER_TRIALS} trials; the '
            f'trigger spell is its own tooltip clause, with no separate passive to gate a baseline against; '
            f'trials: {trial}; events: {entry["observe_metric"]} of {entry["observe_spell"]}{on_target} '
            f'({entry["observe_source"]}); {entry["per_trigger"]:g} per trigger ("{entry["per_trigger_text"]}")'
            f'{fixtures}{scaled}')


def self_trigger_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    labels = trigger_measurements(aura)
    attempts = plan.part_attempts[part]
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': aura}]
    if trigger.get('target') == ALLY:
        steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in entry.get('co_learn', [])]
    steps += attempt_steps(class_file, entry, plan, attempts, '')
    steps += counts(entry, labels['trials'], labels['events'])
    parts = len(plan.part_attempts)
    name = f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} self part {part + 1} of {parts}'
    contract = ('Events of a self-triggering cast, whose own tooltip clause is the trigger with no separate '
               'passive to gate a baseline against: judged over its scheduled trials, against its tooltip.')
    scenario = scenario_shell(class_file, name, contract, steps)
    force_crit = entry.get('force_crit')
    if force_crit:
        scenario['players'][0][FORCE_CRIT_RATINGS[force_crit]] = FORCED_CRIT_RATING
    if trigger.get('target') == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    if trigger.get('target') == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
             'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS, 'per_trigger': entry['per_trigger'],
             'trigger': dict(trigger), 'trial_metric': entry['trial_metric'], 'observe_spell': entry['observe_spell'],
             'observe_metric': entry['observe_metric'], 'observe_actor': entry.get('observe_actor', CASTER),
             'attempt_auras': [dict(aura) for aura in entry.get('attempt_auras', [])],
             'co_learn': list(entry.get('co_learn', [])), 'force_crit': force_crit,
             'trial_attempts_factor': entry.get('trial_attempts_factor', 1), 'measurements': labels}
    expectation = Expectation(self_trigger_label(aura), SELF_TRIGGER_CHECK, aura, aura, None, entry['trigger_text'],
                              self_trigger_rule(entry), model)
    return timed(scenario, SETTLE_MS + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def gate_absence_label(aura: int, suffix: str = '') -> str:
    return f'{aura} gate_absence_count' + (f' {suffix}' if suffix else '')


def gate_absence_rule(entry: dict) -> str:
    trial = entry['trial_metric'] + f' of {entry["trigger"]["spell"]}'
    on_target = ' on the target' if entry.get('observe_actor') == 'target' else ''
    return (f'0 events required over at least {TRIGGER_TRIALS} trials with the passive known but '
            f'{entry["gate_text"]!r} withheld; trials: {trial}; events: {entry["observe_metric"]} of '
            f'{entry["observe_spell"]}{on_target} ({entry["observe_source"]})')


def gate_absence_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    taken = entry['trigger']['action'] == TAKEN_HIT
    if not taken:
        class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    labels = trigger_measurements(aura)
    attempts = plan.part_attempts[part]
    steps = ([] if taken else [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']}]) + \
        [{'action': 'learn', 'actor': CASTER, 'spell': aura}]
    if trigger.get('target') == ALLY:
        steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
    steps += attempt_steps(class_file, entry, plan, attempts, '')
    steps += counts(entry, labels['trials'], labels['events'])
    control = away_control_label(aura) if entry.get('away_yd') else None
    if control:
        steps += [{'action': 'learn', 'actor': CASTER, 'spell': entry['observe_spell']},
                  {'action': 'reset_cooldown', 'actor': CASTER, 'spell': entry['observe_spell']},
                  {'action': 'cast', 'actor': CASTER, 'spell': entry['observe_spell'], 'target': TARGET},
                  {'action': 'wait', 'ms': CAST_MARGIN_MS},
                  measurement(control, CASTER, 'cast_failure', spell=entry['observe_spell'])]
    parts = len(plan.part_attempts)
    name = f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} gate part {part + 1} of {parts}'
    contract = ('Events of an always-on passive with its required gate withheld: zero expected across its '
               'scheduled attempts, with the passive itself known, against its tooltip condition.')
    scenario = scenario_shell(class_file, name, contract, steps)
    if taken:
        scenario['creatures'] = [striker_fixture(class_file, trigger)]
    if trigger.get('target') == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    if trigger.get('target') == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
             'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS, 'trigger': dict(trigger),
             'trial_metric': entry['trial_metric'], 'observe_spell': entry['observe_spell'],
             'observe_metric': entry['observe_metric'], 'observe_actor': entry.get('observe_actor', CASTER),
             'gate_text': entry['gate_text'], 'measurements': labels}
    if control:
        model['away_control'] = control
    label = gate_absence_label(aura, entry.get('label_suffix', ''))
    expectation = Expectation(label, GATE_ABSENCE_CHECK, aura, aura, None, entry['trigger_text'],
                              gate_absence_rule(entry), model)
    return timed(scenario, SETTLE_MS + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def cooldown_label(aura: int, observe_spell: int | None = None) -> str:
    return f'{aura} trigger_cooldown_delta' if observe_spell is None \
        else f'{aura} trigger_cooldown_delta {observe_spell}'


def shares_cooldown_aura(class_file: dict, entry: dict) -> bool:
    return sum(1 for other in class_file.get('triggers', [])
              if other.get('kind') == COOLDOWN_DELTA_KIND and other['aura'] == entry['aura']) > 1


def shares_cooldown_effect(class_file: dict, entry: dict) -> bool:
    return sum(1 for other in class_file.get('triggers', [])
              if other.get('kind') == COOLDOWN_DELTA_KIND and other['aura'] == entry['aura']
              and other.get('effect') == entry.get('effect')) > 1


def cooldown_trial_label(aura: int, phase: str, index: int, moment: str) -> str:
    return f'{aura} trigger cooldown {phase} {index} {moment}'


def cooldown_measurement_labels(aura: int) -> dict[str, str]:
    return {'aura': f'{aura} trigger cooldown aura'}


def cooldown_trial_steps(class_file: dict, entry: dict, count: int, phase: str) -> list[dict]:
    if count <= 0:
        return []
    aura, trigger = entry['aura'], entry['trigger']
    records = records_of(class_file)
    observe_facts = facts_of(records, entry['observe_spell'])
    trigger_facts = facts_of(records, trigger['spell'])
    setup_spells = entry.get('setup_casts', [])
    setup_facts = [facts_of(records, spell) for spell in setup_spells]
    setup_intervals = [cast_interval(class_file, spell, 0) for spell in setup_spells]
    observe_interval = cast_interval(class_file, entry['observe_spell'], 0)
    trigger_interval = cast_interval(class_file, trigger['spell'], entry.get('internal_cooldown_ms', 0))
    trigger_target = trigger['target'] if trigger['target'] in (TARGET, ALLY) else None
    observe_target = entry.get('observe_target')
    observe_target = observe_target if observe_target in (TARGET, ALLY) else None
    steps = []
    for index in range(count):
        for setup_spell, facts, interval in zip(setup_spells, setup_facts, setup_intervals):
            if phase == 'baseline' and setup_spell == aura:
                continue
            steps += cast_steps(facts, setup_spell, None, interval, 1)
        steps += cast_steps(observe_facts, entry['observe_spell'], observe_target, 0, 1)
        steps.append(measurement(cooldown_trial_label(aura, phase, index, 'before'), CASTER, 'cooldown_ms',
                                 spell=entry['observe_spell']))
        steps.append({'action': 'wait', 'ms': observe_interval})
        steps += cast_steps(trigger_facts, trigger['spell'], trigger_target, 0, 1)
        steps.append(measurement(cooldown_trial_label(aura, phase, index, 'after'), CASTER, 'cooldown_ms',
                                 spell=entry['observe_spell']))
        steps.append({'action': 'wait', 'label': f'{phase}spacing', 'ms': observe_interval + trigger_interval})
    return steps


def cooldown_trigger_rule(entry: dict) -> str:
    fixtures = ''.join(f'; before each trial, {spell} is reset and cast at self'
                       for spell in entry.get('setup_casts', []))
    if entry.get('observe_target'):
        fixtures += f'; {entry["observe_spell"]} cast at {entry["observe_target"]}, not self'
    return (f'baseline delta 0 ms over {BASELINE_ATTEMPTS} attempts without the passive; measured delta of '
            f'{entry["observe_metric"]} of {entry["observe_spell"]} between a cast of {entry["observe_spell"]} and '
            f'a cast of {entry["trigger"]["spell"]} matches {entry["expected_delta_ms"]:g} ms within '
            f'max(1, 0.5% of expected), over at least {TRIGGER_TRIALS} trials ("{entry["per_trigger_text"]}")'
            f'{fixtures}')


def cooldown_trigger_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    class_file = armed_for(class_file, records_of(class_file), entry['observe_spell'])
    for spell in entry.get('setup_casts', []):
        class_file = armed_for(class_file, records_of(class_file), spell)
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    attempts = plan.part_attempts[part]
    baseline = BASELINE_ATTEMPTS if part == 0 else 0
    labels = cooldown_measurement_labels(aura)
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']},
             {'action': 'learn', 'actor': CASTER, 'spell': entry['observe_spell']}]
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in entry.get('setup_casts', [])]
    if trigger.get('target') == ALLY or entry.get('observe_target') == ALLY:
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
    force_crit = entry.get('force_crit')
    if force_crit:
        scenario['players'][0][FORCE_CRIT_RATINGS[force_crit]] = FORCED_CRIT_RATING
    if trigger['action'] == ATTACK or trigger.get('target') == TARGET or entry.get('observe_target') == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    if trigger.get('target') == ALLY or entry.get('observe_target') == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
            'baseline_attempts': baseline, 'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS,
            'trigger': dict(trigger), 'observe_spell': entry['observe_spell'],
            'observe_metric': entry['observe_metric'], 'expected_delta_ms': entry['expected_delta_ms'],
            'measurements': labels}
    label = cooldown_label(aura, entry['observe_spell']) if shares_cooldown_aura(class_file, entry) \
        else cooldown_label(aura)
    expectation = Expectation(label, COOLDOWN_CHECK, aura, aura, None, entry['trigger_text'],
                              cooldown_trigger_rule(entry), model)
    baseline_ms = baseline * plan.attempt_ms + DRAIN_MS if baseline else 0
    return timed(scenario, SETTLE_MS + baseline_ms + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def duration_label(aura: int) -> str:
    return f'{aura} trigger_duration_delta'


def duration_trial_label(aura: int, phase: str, index: int, moment: str) -> str:
    return f'{aura} trigger duration {phase} {index} {moment}'


def duration_measurement_labels(aura: int) -> dict[str, str]:
    return {'aura': f'{aura} trigger duration aura'}


def duration_trial_steps(class_file: dict, entry: dict, count: int, phase: str) -> list[dict]:
    if count <= 0:
        return []
    aura, trigger = entry['aura'], entry['trigger']
    records = records_of(class_file)
    observe_facts = facts_of(records, entry['observe_spell'])
    trigger_facts = facts_of(records, trigger['spell'])
    observe_interval = cast_interval(class_file, entry['observe_spell'], 0)
    trigger_interval = cast_interval(class_file, trigger['spell'], 0)
    target = trigger['target']
    steps = []
    for index in range(count):
        steps += cast_steps(observe_facts, entry['observe_spell'], target, 0, 1)
        steps.append({'action': 'wait', 'label': f'{phase}decay', 'ms': entry['decay_wait_ms']})
        steps.append(measurement(duration_trial_label(aura, phase, index, 'before'), target, 'aura_duration_ms',
                                 spell=entry['observe_spell'], caster=CASTER))
        steps += cast_steps(trigger_facts, trigger['spell'], target, 0, 1)
        steps.append(measurement(duration_trial_label(aura, phase, index, 'after'), target, 'aura_duration_ms',
                                 spell=entry['observe_spell'], caster=CASTER))
        steps.append({'action': 'wait', 'label': f'{phase}spacing', 'ms': observe_interval + trigger_interval})
    return steps


def duration_trigger_rule(entry: dict) -> str:
    return (f'baseline delta 0 ms over {BASELINE_ATTEMPTS} attempts without the passive; measured delta of '
            f'{entry["observe_metric"]} of {entry["observe_spell"]} between a cast of {entry["observe_spell"]} '
            f'(after waiting {entry["decay_wait_ms"]} ms for it to decay) and a cast of '
            f'{entry["trigger"]["spell"]} matches {entry["expected_delta_ms"]:g} ms within max(1, 0.5% of '
            f'expected), over at least {TRIGGER_TRIALS} trials ("{entry["per_trigger_text"]}")')


def duration_trigger_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    class_file = armed_for(class_file, records_of(class_file), entry['observe_spell'])
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    attempts = plan.part_attempts[part]
    baseline = BASELINE_ATTEMPTS if part == 0 else 0
    labels = duration_measurement_labels(aura)
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']},
             {'action': 'learn', 'actor': CASTER, 'spell': entry['observe_spell']}]
    if baseline:
        steps += duration_trial_steps(class_file, entry, baseline, 'baseline')
        steps.append({'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS})
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': aura})
    steps += duration_trial_steps(class_file, entry, attempts, 'measured')
    steps.append({'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS})
    steps.append(measurement(labels['aura'], CASTER, 'aura', spell=aura))
    parts = len(plan.part_attempts)
    name = f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {parts}'
    contract = ('Duration delta of an always-on passive: no change before the learn, a fixed extension of a '
               'foreign aura\'s remaining duration per trigger after it, summed over its parts, against its '
               'tooltip.')
    scenario = scenario_shell(class_file, name, contract, steps)
    scenario['creatures'] = [creature_fixture(class_file)]
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
            'baseline_attempts': baseline, 'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS,
            'trigger': dict(trigger), 'observe_spell': entry['observe_spell'],
            'observe_metric': entry['observe_metric'], 'expected_delta_ms': entry['expected_delta_ms'],
            'decay_wait_ms': entry['decay_wait_ms'], 'measurements': labels}
    expectation = Expectation(duration_label(aura), DURATION_CHECK, aura, aura, None, entry['trigger_text'],
                              duration_trigger_rule(entry), model)
    baseline_ms = baseline * plan.attempt_ms + DRAIN_MS if baseline else 0
    return timed(scenario, SETTLE_MS + baseline_ms + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def magnitude_label(aura: int) -> str:
    return f'{aura} trigger_magnitude_ratio'


MAGNITUDE_OBSERVE_COUNT_METRICS = {'spell_damage_total': 'spell_damage_count', 'spell_heal_total': 'spell_heal_count'}


def magnitude_measurement_labels(aura: int) -> dict[str, str]:
    return {'aura': f'{aura} magnitude aura', 'trigger_total': f'{aura} magnitude trigger total',
            'trigger_count': f'{aura} magnitude trigger count', 'observe_total': f'{aura} magnitude observe total',
            'observe_count': f'{aura} magnitude observe count'}


def magnitude_trigger_descriptor(entry: dict) -> str:
    trigger = entry['trigger']
    if trigger['action'] == ATTACK:
        return f'{entry["trigger_metric"]} of main-hand melee attacks'
    return f'{entry["trigger_metric"]} of {trigger["spell"]}'


def magnitude_trigger_rule(entry: dict) -> str:
    return (f'mean {entry["observe_metric"]} of {entry["observe_spell"]} per its own event over '
            f'mean {magnitude_trigger_descriptor(entry)} per its own event, at least {TRIGGER_TRIALS} '
            f'{entry["observe_metric"]} events, matches {entry["expected_ratio"]:.3g} within tolerance '
            f'("{entry["per_trigger_text"]}")')


def magnitude_resisted_school(class_file: dict, entry: dict, cast_target: str | None) -> int:
    if entry['observe_metric'] != 'spell_damage_total' or cast_target not in (TARGET, STRIKER):
        return 0
    school_mask = records_of(class_file).field('Spell', entry['observe_spell'], 'SchoolMask')
    if school_mask & PHYSICAL_SCHOOL_MASK or not magic_schools(school_mask):
        return 0
    return school_mask


def magnitude_ratio_scenario(class_file: dict, entry: dict, part: int = 0) -> tuple[dict, list[Expectation]]:
    trigger = entry['trigger']
    if trigger['action'] == CAST:
        class_file = armed_for(class_file, records_of(class_file), trigger['spell'])
    plan = trigger_plan(class_file, entry)
    if not 0 <= part < len(plan.part_attempts):
        raise ValueError(f'Trigger {entry["aura"]} has parts 0 to {len(plan.part_attempts) - 1}, not {part}')
    aura, trigger = entry['aura'], entry['trigger']
    attempts = plan.part_attempts[part]
    labels = magnitude_measurement_labels(aura)
    if trigger['action'] == CAST:
        facts = facts_of(records_of(class_file), trigger['spell'])
        cast_target = trigger['target'] if trigger['target'] in (TARGET, ALLY) else None
        steps = [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']},
                 {'action': 'learn', 'actor': CASTER, 'spell': aura}]
        if trigger.get('target') == ALLY:
            steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
        steps += cast_steps(facts, trigger['spell'], cast_target, plan.attempt_ms, attempts)
    elif trigger['action'] == TAKEN_HIT:
        cast_target = STRIKER
        steps = [{'action': 'learn', 'actor': CASTER, 'spell': aura}]
        steps += [step for _ in range(attempts) for step in taken_hit_attempt(trigger, plan.attempt_ms)]
    else:
        cast_target = TARGET
        steps = [{'action': 'learn', 'actor': CASTER, 'spell': aura},
                 {'action': 'attack', 'actor': CASTER, 'target': TARGET},
                 {'action': 'wait', 'label': f'{aura} magnitude swings', 'ms': attempts * plan.attempt_ms},
                 {'action': 'stop_attack', 'actor': CASTER}]
    steps.append({'action': 'wait', 'label': f'{aura} magnitude drain', 'ms': DRAIN_MS})
    if trigger['action'] == CAST:
        steps.append(measurement(labels['trigger_total'], CASTER, entry['trigger_metric'], spell=trigger['spell']))
        steps.append(measurement(labels['trigger_count'], CASTER, 'spell_damage_count', spell=trigger['spell']))
    elif trigger['action'] == TAKEN_HIT:
        for label, metric in ((labels['trigger_total'], entry['trigger_metric']),
                              (labels['trigger_count'], 'spell_damage_count')):
            steps.append(measurement(label, CASTER, metric, spell=trigger['spell'], target=CASTER, caster=STRIKER))
    else:
        steps.append(measurement(labels['trigger_total'], CASTER, entry['trigger_metric'], hand=MAIN_HAND))
        steps.append(measurement(labels['trigger_count'], CASTER, 'melee_damage_count', hand=MAIN_HAND))
    steps.append(measurement(labels['observe_total'], CASTER, entry['observe_metric'], spell=entry['observe_spell']))
    observe_count_metric = MAGNITUDE_OBSERVE_COUNT_METRICS[entry['observe_metric']]
    steps.append(measurement(labels['observe_count'], CASTER, observe_count_metric, spell=entry['observe_spell']))
    steps.append(measurement(labels['aura'], CASTER, 'aura', spell=aura))
    resisted_school = magnitude_resisted_school(class_file, entry, cast_target)
    target_labels: dict[str, str] = {}
    if resisted_school:
        resistance_steps, target_labels = target_steps(resisted_school, cast_target)
        steps += resistance_steps
    parts = len(plan.part_attempts)
    name = f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} magnitude part {part + 1} of {parts}'
    contract = ('Mean magnitude of a triggered proc against the mean damage of the hits that triggered it, over '
               'repeated attempts, against its tooltip fraction.')
    scenario = scenario_shell(class_file, name, contract, steps)
    if cast_target == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    if cast_target == STRIKER:
        scenario['creatures'] = [striker_fixture(class_file, trigger)]
    force_crit = entry.get('force_crit')
    if force_crit:
        scenario['players'][0][FORCE_CRIT_RATINGS[force_crit]] = FORCED_CRIT_RATING
    model = {'part': part, 'parts': parts, 'scheduled_attempts': plan.scheduled, 'part_attempts': attempts,
            'attempt_ms': plan.attempt_ms, 'minimum_trials': TRIGGER_TRIALS, 'trigger': dict(trigger),
            'trigger_metric': entry['trigger_metric'], 'observe_spell': entry['observe_spell'],
            'observe_metric': entry['observe_metric'], 'expected_ratio': entry['expected_ratio'],
            'force_crit': force_crit, 'measurements': labels, 'resisted_school_mask': resisted_school,
            'caster_level': class_file['level'], 'target_measurements': target_labels}
    expectation = Expectation(magnitude_label(aura), MAGNITUDE_CHECK, aura, aura, None, entry['trigger_text'],
                              magnitude_trigger_rule(entry), model)
    return timed(scenario, SETTLE_MS + attempts * plan.attempt_ms + DRAIN_MS), [expectation]


def trigger_status_expectation(entry: dict) -> Expectation:
    status = entry.get('status')
    if status not in ENTRY_STATUSES:
        raise ValueError(f'Trigger {entry["aura"]} status {status!r} is not one of {sorted(ENTRY_STATUSES)}')
    return Expectation(trigger_label(entry['aura']), TRIGGER_CHECK, entry['aura'], entry['aura'], None,
                       entry.get('trigger_text', ''), ENTRY_STATUSES[status] + entry['reason'])


def trigger_unmodelled_expectation(entry: dict, reason: str) -> Expectation:
    return Expectation(trigger_label(entry['aura']), TRIGGER_CHECK, entry['aura'], entry['aura'], None,
                       entry.get('trigger_text', ''), UNMODELLED + reason)


def checked_trigger_set(entries: list[dict]) -> list[dict]:
    seen: set[tuple[int, int | str]] = set()
    for entry in entries:
        if entry.get('kind') is not None or entry.get('status'):
            continue
        trigger = entry['trigger']
        key = (entry['aura'], trigger.get('spell', trigger['action']))
        if key in seen:
            raise ValueError(f'Trigger {entry["aura"]} has two trigger_count entries both triggered by '
                             f'{key[1]!r}; they would collide under the same label')
        seen.add(key)
    return entries


def trigger_entries(class_file: dict, auras: Sequence[int] | None = None) -> list[dict]:
    entries = checked_trigger_set(class_file.get('triggers', []))
    if auras is None:
        return list(entries)
    unknown = set(auras) - {entry['aura'] for entry in entries}
    if unknown:
        raise ValueError(f'Auras {sorted(unknown)} have no trigger entry in the {class_file["name"]} class file')
    return [entry for entry in entries if entry['aura'] in auras]
