from dataclasses import dataclass, replace
import math
import re
from statistics import NormalDist
from typing import Sequence

from hits import (DRAIN_MS, EXCLUDED_OUTCOME_MARGIN, MAIN_HAND, PART_BUDGET_MS, UNMODELLED, Z_99, Unmodelled,
                  base_mana_steps, cast_steps, creature_fixture, records_of, reference_caster, scenario_shell, timed,
                  weapon_profile)
from profile import (CASTER, EQUIPMENT_SLOT_MAIN_HAND, INVTYPE_WEAPON, INVTYPE_WEAPON_MAIN_HAND, SETTLE_MS,
                     measurement, player_fixture)
from tooltip import read_tooltip
from values import (ALLY, CAST_MARGIN_MS, CHARGE_OFFSET_YD, DUMMY_DISTANCE, EFFECTS, READ_STEP_MS, TARGET, Expectation,
                    RankFacts, armed_for, facts_of, is_hostile, targets_ally)

PROC_CHECK = 'proc_rate'
PROC_ENERGIZE_CHECK = 'proc_energize_amount'
AMBIGUOUS_TOOLTIP = 'ambiguous_tooltip: '
ENTRY_STATUSES = {'ambiguous_tooltip': AMBIGUOUS_TOOLTIP, 'unmodelled': UNMODELLED}
RATE_HALF_WIDTH = 0.025
BAND_RELATIVE = 0.05
BAND_POINTS = 0.02
CHANCE_KIND = 'chance_pct'
ADD_FLAT_MODIFIER = 107
SPELLMOD_CHANCE_OF_SUCCESS = 18
PERCENT_KIND = 'percent'
ATTACK = 'attack'
CAST = 'cast'
MINION = 'minion'
TAKEN_HIT = 'taken_hit'
TAKEN_HIT_STRIKER = 'striker'
TAKEN_HIT_MIN_INTERVAL_MS = 500
MINION_PROC_TRIALS = frozenset({'pet_melee_crits', 'owned_creature_damage_count'})
MINION_BASELINE_ATTEMPTS = 20
BASELINE_MISS_RISK = 0.01
CAST_COUNT = 'spell_cast_count'
MELEE_EVENTS = 'melee_attack_count'
MINION_PROC_COUNT = 'owned_creature_spell_proc_count'
ENERGIZE_EVENTS = 'spell_energize_count'
EVENT_METRICS = frozenset({CAST_COUNT, 'spell_damage_count', MELEE_EVENTS, MINION_PROC_COUNT, ENERGIZE_EVENTS})
SUMMON_EVENTS = 'owned_creature_summon_count'
CHARGES = 'spell_charges'
TRIGGER_TARGETS = frozenset({TARGET, ALLY})
PERIODIC_DAMAGE_AURA = 3
PERIODIC_LEECH_AURA = 53
TICKS_PER_ATTEMPT = 2
TRIGGERING_HITS = 'triggering hits only'
TRIGGER_SPELLS = 'trigger_spells'
TRIGGER_SPELLS_SOURCE = 'trigger_spells_source'
LANDED_HIT_METRIC = 'spell_damage_count'
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

BASE_MANA_PER_ATTEMPT = 'base_mana_per_attempt'
CONTROL_WEAPON = 'control_weapon'
INVTYPE_TWO_HAND_WEAPON = 17
ONE_HAND_INVENTORY_TYPES = (INVTYPE_WEAPON, INVTYPE_WEAPON_MAIN_HAND)
DUMMY_DISTANCE_FIELD = 'dummy_distance'
MAX_DUMMY_DISTANCE_YD = 100
RESIDUAL_TARGET = 'residual_target'
MIN_DETECTABLE = 'min_detectable'
EVENTS_BASELINE = 'events_baseline_per_attempt'


@dataclass(frozen=True)
class ProcPlan:
    chance_pct: float
    needed: int
    scheduled: int
    attempt_ms: int
    parts: int
    per_part: int


def rate_band(p: float) -> float:
    return max(BAND_RELATIVE * p, BAND_POINTS)


def band_trials_needed(p: float) -> int:
    return math.ceil(Z_99 ** 2 * p * (1 - p) / (rate_band(p) / 2) ** 2)


def trials_needed(p: float) -> int:
    if not 0 < p < 1:
        raise ValueError(f'A proc chance of {p} has no rate to measure')
    return math.ceil(Z_99 ** 2 * p * (1 - p) / RATE_HALF_WIDTH ** 2)


def wilson_interval(events: float, trials: float, z: float = Z_99) -> tuple[float, float]:
    if trials <= 0 or not 0 <= events <= trials:
        raise ValueError(f'{events} procs in {trials} trials have no rate')
    z2 = z ** 2
    centre = (events + z2 / 2) / (trials + z2)
    half = z / (trials + z2) * math.sqrt(events * (trials - events) / trials + z2 / 4)
    return centre - half, centre + half


def residual_z(target: float) -> float:
    return NormalDist().inv_cdf(1 - target / 4)


def residual_sizing(entry: dict, chance_pct: float) -> dict | None:
    if RESIDUAL_TARGET not in entry and MIN_DETECTABLE not in entry:
        return None
    aura, target, detectable = entry['aura'], entry.get(RESIDUAL_TARGET), entry.get(MIN_DETECTABLE)
    if not entry.get('band') or isinstance(target, bool) or not isinstance(target, (int, float)) \
            or not 0 < target < 1 or isinstance(detectable, bool) or not isinstance(detectable, (int, float)):
        raise ValueError(f'Proc {aura} {RESIDUAL_TARGET} is a per-pair probability in (0, 1) with a '
                         f'{MIN_DETECTABLE} in percentage points, on a banded entry')
    p, band, shift = chance_pct / 100, rate_band(chance_pct / 100), detectable / 100
    if shift < band - 1e-12:
        raise ValueError(f'Proc {aura} {MIN_DETECTABLE} {detectable:g} points lies inside the band of '
                         f'{band * 100:g} points (D-198)')
    room = (shift - band) / 2
    z = residual_z(target)
    if room <= 0:
        raise ValueError(f'Proc {aura} is under-sized: {MIN_DETECTABLE} {detectable:g} points equals the band, so '
                         f'no trial count leaves room for an interval')
    trials = math.ceil(z ** 2 * p * (1 - p) / room ** 2)
    return {'target': float(target), 'z': z, 'confidence': 1 - target / 2, 'min_detectable': shift,
            'trials': trials, 'attempts': math.ceil(trials * EXCLUDED_OUTCOME_MARGIN)}


def residual_probabilities(residual: dict, chance: float, trials: float) -> tuple[float, float]:
    normal, band, z, shift = NormalDist(), rate_band(chance), residual['z'], residual['min_detectable']

    def spread(rate: float) -> float:
        return math.sqrt(max(rate * (1 - rate), 0.0) / trials)

    room = band - z * spread(chance)
    false_alert = 2 * normal.cdf(-room / spread(chance)) if spread(chance) > 0 else 0.0
    passes = [normal.cdf((room - shift) / spread(rate)) if spread(rate) > 0 else float(shift <= room)
              for rate in (chance + shift, chance - shift) if 0 <= rate <= 1]
    return 1 - max(passes, default=0.0), min(1.0, 2 * false_alert)


def residual_note(residual: dict, chance: float, trials: float) -> str:
    rejected, false_alert = residual_probabilities(residual, chance, trials)
    return (f'; residual_target {residual["target"]:g} per pair: Wilson confidence {residual["confidence"]:g} per run '
            f'(z {residual["z"]:.3f}), {trials:g} trials (at least {residual["trials"]}); a deviation of '
            f'{residual["min_detectable"] * 100:g} points from the chance rejected with probability >= '
            f'{rejected:.6f}; false alert at the chance <= {false_alert:.2e} per pair (normal approximation, Wilson '
            f'coverage nominal)')


def proc_label(aura: int, proc_spell: int | None = None, trigger: int | str | None = None) -> str:
    label = f'{aura} proc_rate' if proc_spell is None else f'{aura} proc_rate {proc_spell}'
    return label if trigger is None else f'{label} {trigger}'


def proc_measurements(aura: int) -> dict[str, str]:
    return {part: f'{aura} proc {part}' for part in ('trials', 'events', 'attempts', 'aura')}


def baseline_attempts(chance_pct: float) -> int:
    return max(MINION_BASELINE_ATTEMPTS, math.ceil(math.log(BASELINE_MISS_RISK) / math.log(1 - chance_pct / 100)))


def cast_baseline_steps(class_file: dict, entry: dict, plan: ProcPlan) -> list[dict]:
    if entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc {entry["aura"]} has a baseline without a minion or cast trigger')
    labels = baseline_labels(entry['aura'])
    held = replace(plan, per_part=baseline_attempts(plan.chance_pct))
    return ([{'action': 'learn', 'actor': CASTER, 'spell': trigger_spell(entry)}] + cast_attempts(class_file, entry, held)
            + [{'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS}, trials_step(entry, labels['trials']),
               {**event_steps(entry)[0], 'label': labels['events']}])


def control_weapon(class_file: dict, entry: dict) -> dict | None:
    name = entry.get(CONTROL_WEAPON)
    if name is None:
        return None
    aura = entry['aura']
    if entry['trigger']['action'] != ATTACK or per_trigger_limit(entry) is not None or trial_hand(entry) != MAIN_HAND:
        raise ValueError(f'Proc {aura} sets {CONTROL_WEAPON}, which needs a main-hand attack trigger')
    if entry.get('baseline') or entry.get('extra_event_terms') or entry.get('trial_readings') \
            or counts_charges(entry):
        raise ValueError(f'Proc {aura} sets {CONTROL_WEAPON} with a baseline, extra event terms, trial readings or '
                         f'charges, which its control arm does not count')
    sets = class_file.get('weapon_sets', {})
    control = sets.get(name, {}).get('main_hand') if isinstance(name, str) else None
    if control is None:
        raise ValueError(f'Proc {aura} {CONTROL_WEAPON} {name!r} is not a weapon set of the class file with a '
                         f'main hand')
    treatment = sets.get(class_file.get('weapon_set'), {}).get('main_hand') or {}
    if treatment.get('inventory_type') != INVTYPE_TWO_HAND_WEAPON:
        raise ValueError(f'Proc {aura} sets {CONTROL_WEAPON}, but its own weapon set '
                         f'{class_file.get("weapon_set")!r} holds no two-handed main hand')
    if control.get('inventory_type') not in ONE_HAND_INVENTORY_TYPES:
        raise ValueError(f'Proc {aura} {CONTROL_WEAPON} {name!r} holds no one-handed main hand')
    return control


def control_swings(chance_pct: float) -> int:
    return math.ceil(baseline_attempts(chance_pct) * EXCLUDED_OUTCOME_MARGIN)


def control_weapon_ms(class_file: dict, entry: dict, chance_pct: float) -> int:
    control = control_weapon(class_file, entry)
    return control_swings(chance_pct) * control['speed_ms'] + DRAIN_MS if control else 0


def control_weapon_steps(class_file: dict, entry: dict, plan: ProcPlan) -> list[dict]:
    control = control_weapon(class_file, entry)
    treatment = class_file['weapon_sets'][class_file['weapon_set']]['main_hand']
    labels = baseline_labels(entry['aura'])
    return [{'action': 'add_item', 'actor': CASTER, 'item': control['item']},
            {'action': 'equip', 'actor': CASTER, 'item': control['item'], 'slot': EQUIPMENT_SLOT_MAIN_HAND},
            {'action': 'attack', 'actor': CASTER, 'target': TARGET},
            {'action': 'wait', 'label': 'control swings',
             'ms': control_swings(plan.chance_pct) * control['speed_ms']},
            {'action': 'stop_attack', 'actor': CASTER},
            {'action': 'wait', 'label': 'control drain', 'ms': DRAIN_MS},
            measurement(labels['trials'], CASTER, 'melee_damage_count', hand=MAIN_HAND),
            {**event_steps(entry)[0], 'label': labels['events']},
            {'action': 'equip', 'actor': CASTER, 'item': treatment['item'], 'slot': EQUIPMENT_SLOT_MAIN_HAND}]


def excluded_trial_labels(entry: dict) -> list[str]:
    return [f'{entry["aura"]} proc trials excluded {spell}' for spell in entry.get('trial_excluded_spells', [])]


def excluded_trial_steps(entry: dict) -> list[dict]:
    if entry.get('trial_excluded_spells') and minion_entry(entry) is None:
        raise ValueError(f'Proc {entry["aura"]} excludes trial spells without a minion trigger')
    return [measurement(label, CASTER, 'spell_damage_count', spell=spell, entry=minion_entry(entry))
            for label, spell in zip(excluded_trial_labels(entry), entry.get('trial_excluded_spells', []))]


def baseline_labels(aura: int) -> dict[str, str]:
    return {'trials': f'{aura} proc baseline trials', 'events': f'{aura} proc baseline events'}


def minion_baseline_steps(class_file: dict, entry: dict, plan: ProcPlan) -> list[dict]:
    from triggers import minion_attempt_steps
    labels = baseline_labels(entry['aura'])
    creature = entry['trigger']['entry']
    events = event_steps(entry)[0]
    return (minion_attempt_steps(entry, baseline_attempts(plan.chance_pct) * plan.attempt_ms, 'baseline ')
            + [{'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS},
               measurement(labels['trials'], CASTER, entry['trial_metric'], entry=creature),
               {**events, 'label': labels['events']}])


def cast_baseline_steps(class_file: dict, entry: dict, plan: ProcPlan) -> list[dict]:
    labels = baseline_labels(entry['aura'])
    spell, target = trigger_spell(entry), trigger_target(entry)
    facts = facts_of(records_of(class_file), spell)
    events = event_steps(entry)[0]
    casts = [aimed(step, target) for _ in range(stream_baseline_attempts(entry, plan.chance_pct))
             for step in attempt_power_steps(class_file, entry, facts)
             + cast_steps(facts, spell, target, plan.attempt_ms, 1, attempt_fixtures(entry))]
    return ([{'action': 'learn', 'actor': CASTER, 'spell': spell}] + casts
            + [{'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS}, {**trials_step(entry, labels['trials'])},
               {**events, 'label': labels['events']}]
            + [spell_count_step(baseline_trigger_label(entry['aura'], term['spell']), term['metric'], term['spell'])
               for term in trigger_spell_terms(entry)])


def same_roll(entry: dict, other: dict) -> bool:
    from proc_avoided import is_avoided
    return other['aura'] == entry['aura'] and chance_modifiers(other) == chance_modifiers(entry) \
        and is_avoided(other) == is_avoided(entry)


def shares_aura(class_file: dict, entry: dict) -> bool:
    return sum(1 for other in class_file.get('procs', []) if same_roll(entry, other)) > 1


def shares_proc_spell(class_file: dict, entry: dict) -> bool:
    if 'proc_spell' not in entry:
        return False
    return sum(1 for other in class_file.get('procs', [])
              if same_roll(entry, other) and other.get('proc_spell') == entry['proc_spell']) > 1


def chance_modifiers(entry: dict) -> tuple[tuple[int, str], ...]:
    raw = entry.get('chance_modifiers', ())
    if not isinstance(raw, list | tuple) or not all(
            isinstance(pair, list | tuple) and len(pair) == 2 and isinstance(pair[0], int)
            and isinstance(pair[1], str) for pair in raw):
        raise ValueError(f'Proc {entry["aura"]} chance_modifiers must list [spell, tooltip token] pairs')
    return tuple((spell, token) for spell, token in raw)


def modifier_key(entry: dict) -> tuple:
    from proc_avoided import AVOIDED, is_avoided
    return tuple(part for spell, _ in chance_modifiers(entry) for part in ('with', spell)) \
        + ((AVOIDED,) if is_avoided(entry) else ())


def entry_proc_label(class_file: dict, entry: dict) -> str:
    trigger = trigger_key(entry) if shares_proc_spell(class_file, entry) else None
    label = (proc_label(entry['aura'], entry['proc_spell'], trigger) if shares_aura(class_file, entry)
             else proc_label(entry['aura']))
    return ' '.join((label, *map(str, modifier_key(entry))))


def modifier_shown(class_file: dict, entry: dict, spell: int, token: str) -> tuple[float, int, int]:
    records = records_of(class_file)
    caster = reference_caster(class_file)
    shown = next((value for value in read_tooltip(records.dbc, spell, caster).values
                  if value.text == token and value.kind == PERCENT_KIND), None)
    if shown is not None and shown.effect_index is not None:
        return shown.value, shown.effect_index, spell
    reference = re.fullmatch(rf'\${spell}s([1-3])', token)
    stated = next((value for value in read_tooltip(records.dbc, entry['aura'], caster).values
                   if value.text == token and value.kind == PERCENT_KIND), None) if reference else None
    if shown is None and stated is not None:
        return stated.value, int(reference[1]) - 1, entry['aura']
    raise ValueError(f'The tooltip of {spell} shows no percent token {token}')


def modifier_points(class_file: dict, entry: dict) -> float:
    records = records_of(class_file)
    points = 0.0
    for spell, token in chance_modifiers(entry):
        value, effect, _ = modifier_shown(class_file, entry, spell, token)
        aura = records.field('Spell', spell, f'EffectApplyAuraName[{effect}]')
        modifier = records.field('Spell', spell, f'EffectMiscValue[{effect}]')
        if aura != ADD_FLAT_MODIFIER or modifier != SPELLMOD_CHANCE_OF_SUCCESS:
            raise ValueError(f'{token} of {spell} is effect {effect}, aura {aura} on modifier {modifier}, not a flat '
                             f'SPELLMOD_CHANCE_OF_SUCCESS modifier')
        points += value
    return points


def modifier_tooltips(class_file: dict, entry: dict) -> dict:
    shown = {str(spell): modifier_shown(class_file, entry, spell, token)[2] for spell, token in chance_modifiers(entry)}
    borrowed = {spell: tooltip for spell, tooltip in shown.items() if tooltip != int(spell)}
    return {'chance_modifier_tooltips': borrowed} if borrowed else {}


def trigger_key(entry: dict) -> int | str:
    trigger = entry['trigger']
    return trigger['spell'] if trigger['action'] in (CAST, MINION) else trigger['action']


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
    return chance + modifier_points(class_file, entry) if chance_modifiers(entry) else chance


def chance_model(entry: dict) -> dict:
    if applied_by(entry) is None:
        return {}
    shown, kind = chance_source(entry)
    return {'chance_spell': shown, 'chance_kind': kind}


def aura_steps(entry: dict) -> list[dict]:
    modifiers = [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell, _ in chance_modifiers(entry)]
    if applied_by(entry) is None:
        return [{'action': 'learn', 'actor': CASTER, 'spell': entry['aura']}] + modifiers
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': entry['aura'], 'stacks': 1}] + modifiers


def trigger_spell(entry: dict) -> int:
    return entry['trigger']['spell'] if entry['trigger']['action'] == CAST else 0


def trigger_spells(entry: dict) -> list[int]:
    spells = entry.get(TRIGGER_SPELLS)
    if spells is None:
        return []
    where = f'Proc {entry["aura"]} {TRIGGER_SPELLS} {spells!r}'
    if entry['trigger']['action'] != CAST or trigger_target(entry) == ALLY or entry.get('trial_casts'):
        raise ValueError(f'{where} needs a cast trigger whose trials are its landed hits on the dummy')
    if (not isinstance(spells, list) or len(spells) < 2 or len(set(spells)) != len(spells)
            or not all(isinstance(spell, int) for spell in spells) or spells[0] != trigger_spell(entry)):
        raise ValueError(f'{where} lists the trigger spell first, then at least one other spell, each once')
    if entry.get('trial_readings') or not entry.get(TRIGGER_SPELLS_SOURCE):
        raise ValueError(f'{where} needs {TRIGGER_SPELLS_SOURCE} and no trial_readings')
    return spells


def trigger_spell_terms(entry: dict) -> list[dict]:
    return [{'metric': LANDED_HIT_METRIC, 'spell': spell} for spell in trigger_spells(entry)[1:]]


def baseline_trigger_label(aura: int, spell: int) -> str:
    return f'{aura} proc baseline trials {spell}'


def minion_entry(entry: dict) -> int | None:
    return entry['trigger']['entry'] if entry['trigger']['action'] == MINION else None


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
             if facts.aura_names[effect] in (PERIODIC_DAMAGE_AURA, PERIODIC_LEECH_AURA)]
    return TICKS_PER_ATTEMPT * max(ticks) + CAST_MARGIN_MS if ticks else 0


OFF_HAND = 1
TRIAL_HAND = 'trial_hand'


def trial_hand(entry: dict) -> int:
    hand = entry.get(TRIAL_HAND, MAIN_HAND)
    if hand not in (MAIN_HAND, OFF_HAND) or isinstance(hand, bool):
        raise ValueError(f'Proc {entry["aura"]} trial_hand is {MAIN_HAND} or {OFF_HAND}, not {hand!r}')
    if hand == OFF_HAND and (entry['trigger']['action'] != ATTACK or entry.get(PER_TRIGGER) is not None):
        raise ValueError(f'Proc {entry["aura"]} counts off-hand trials only for an attack trigger without '
                         f'{PER_TRIGGER}')
    return hand


def off_hand_weapon_of(class_file: dict) -> dict:
    name = class_file.get('weapon_set', class_file.get('default_weapon_set'))
    off_hand = class_file.get('weapon_sets', {}).get(name, {}).get('off_hand')
    if not off_hand or 'speed_ms' not in off_hand:
        raise ValueError(f'off-hand trials need an off-hand weapon in the {name!r} weapon set')
    return off_hand


def hand_swing_interval(class_file: dict, entry: dict) -> int:
    if trial_hand(entry) == OFF_HAND:
        return off_hand_weapon_of(class_file)['speed_ms']
    return swing_interval(class_file)


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
    off_hand = trial_hand(entry) == OFF_HAND
    if trigger['action'] == ATTACK:
        swing = swing_interval(class_file, cooldown)
        if off_hand:
            return hand_swing_interval(class_file, entry)
        if per_trigger_limit(entry) is None:
            return swing
        return swing + (TRIGGER_ACTIONS + boundary_reads(entry)) * READ_STEP_MS
    if trigger['action'] == MINION:
        from triggers import checked_minion_trigger
        checked_minion_trigger(entry['aura'], trigger, entry)
        if entry.get('trial_metric') not in MINION_PROC_TRIALS:
            raise ValueError(f'Proc {entry["aura"]} counts {entry.get("trial_metric")!r} minion trials, not one of '
                             f'{sorted(MINION_PROC_TRIALS)}')
        return trigger['swing_ms']
    if trigger['action'] == TAKEN_HIT:
        if not (trigger.get('spell', 0) > 0 and trigger.get('striker_entry', 0) > 0):
            raise ValueError(f'Proc {entry["aura"]} taken_hit trigger needs a positive spell and striker_entry')
        return max(cast_interval(class_file, trigger['spell'], cooldown), TAKEN_HIT_MIN_INTERVAL_MS)
    from proc_avoided import AVOIDED, checked_trigger
    if trigger['action'] == AVOIDED:
        if cooldown:
            raise Unmodelled(f'avoided swings cannot be spaced beyond the internal cooldown of {cooldown} ms')
        return checked_trigger(entry)['swing_ms']
    if trigger['action'] != CAST:
        raise ValueError(f'Unknown trigger action {trigger["action"]!r} of proc {entry["aura"]}')
    facts = facts_of(records_of(class_file), trigger['spell'])
    if trigger_target(entry) == ALLY:
        if facts.passive or not targets_ally(facts):
            raise Unmodelled(f'trigger spell {trigger["spell"]} is not cast at an ally')
    elif facts.passive or not (is_hostile(facts) or events_baseline(entry)):
        raise Unmodelled(f'trigger spell {trigger["spell"]} is not cast at an enemy')
    return max(cast_interval(class_file, trigger['spell'], cooldown), tick_spacing(class_file, facts, trigger['spell']))


def proc_plan(class_file: dict, entry: dict, attempts: int | None = None) -> ProcPlan:
    if entry.get('status'):
        raise ValueError(f'Proc {entry["aura"]} is {entry["status"]}: {entry.get("reason", "")}')
    minion_cast_events = entry.get('event_actor') == MINION and entry['event_metric'] == 'spell_go_count'
    events_baseline(entry)
    if counts_summons(entry):
        checked_summon_entry(entry)
    elif entry['event_metric'] not in EVENT_METRICS and not counts_charges(entry) and not minion_cast_events:
        raise ValueError(f'Unknown event metric {entry["event_metric"]!r} of proc {entry["aura"]}')
    if entry['event_metric'] == MINION_PROC_COUNT and entry.get('event_actor') != MINION:
        raise ValueError(f'Proc {entry["aura"]} counts minion procs without a minion event actor')
    if entry['event_metric'] == MELEE_EVENTS and entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc {entry["aura"]} counts auto attacks as events, which needs a cast trigger')
    per_trigger_limit(entry)
    trigger_spells(entry)
    chance = proc_chance(class_file, entry)
    needed = band_trials_needed(chance / 100) if entry.get('band') else trials_needed(chance / 100)
    from proc_avoided import is_avoided, strikers
    avoided = is_avoided(entry)
    if avoided:
        attempt_interval(class_file, entry)
    per_attempt = strikers(entry) if avoided else entry.get('trials_per_attempt', 1)
    if not isinstance(per_attempt, int) or per_attempt < 1:
        raise ValueError(f'Proc {entry["aura"]} needs a positive integer trials_per_attempt')
    scheduled = math.ceil(needed * EXCLUDED_OUTCOME_MARGIN / per_attempt) if attempts is None else attempts
    if scheduled * per_attempt < needed:
        raise ValueError(f'{scheduled} attempts are fewer than the {needed} trials a {chance:g}% proc needs')
    interval = attempt_interval(class_file, entry)
    held = baseline_attempts(chance) * interval + DRAIN_MS \
        if entry['trigger']['action'] in (MINION, CAST, TAKEN_HIT) and entry.get('baseline') else 0
    if avoided:
        from proc_avoided import engage_ms
        held = engage_ms(entry) + (baseline_attempts(chance) * interval + DRAIN_MS if entry.get('baseline') else 0)
    held += control_weapon_ms(class_file, entry, chance)
    capacity = (PART_BUDGET_MS - held) // interval
    if capacity < 1:
        raise Unmodelled(f'one attempt of {interval} ms exceeds the scenario budget of {PART_BUDGET_MS} ms')
    parts = math.ceil(scheduled / capacity)
    per_part = math.ceil(scheduled / parts)
    minimum_parts = entry.get('min_parts', 1)
    if not isinstance(minimum_parts, int) or minimum_parts < 1:
        raise ValueError(f'Proc {entry["aura"]} needs a positive integer min_parts')
    if parts < minimum_parts:
        parts, scheduled = minimum_parts, per_part * minimum_parts
    residual = residual_sizing(entry, chance)
    if residual and scheduled * per_attempt < residual['attempts']:
        raise ValueError(f'Proc {entry["aura"]} is under-sized for {RESIDUAL_TARGET} {residual["target"]:g}: needs '
                         f'{residual["attempts"]} attempts ({residual["trials"]} trials with the '
                         f'{float(EXCLUDED_OUTCOME_MARGIN):g}x outcome margin), has {scheduled * per_attempt}')
    return ProcPlan(chance_pct=chance, needed=needed, scheduled=scheduled, attempt_ms=interval, parts=parts,
                    per_part=per_part)


def trial_rule(entry: dict) -> str:
    trigger = entry['trigger']
    if trigger['action'] == MINION:
        from triggers import MINION_GRANT_READ_MS, minion_command_note
        fixtures = minion_command_note(trigger) + ''.join(
            f'; minion aura {aura["spell"]} granted every {entry["minion_aura_refresh_ms"]} ms by a real '
            f'{aura["grant_cast"]} cast at the dummy, its presence on the creature {trigger["entry"]} read '
            f'{MINION_GRANT_READ_MS} ms after each cast ({aura["source"]})' if 'grant_cast' in aura
            else f'; minion aura {aura["spell"]}' + (f' at amount {aura["amount"]}' if 'amount' in aura else '')
            + f' set every {entry["minion_aura_refresh_ms"]} ms by harness set_aura ({aura["source"]})'
            for aura in entry.get('minion_auras', []))
        return (f'trials: {entry["trial_metric"]} of the creature {trigger["entry"]} raised by {trigger["spell"]}, '
                f'attacking the dummy with the caster, {trigger["swing_ms"]} ms swings ({trigger["swing_source"]})'
                f'{fixtures}')
    if entry['trigger']['action'] == ATTACK and trial_hand(entry) == OFF_HAND:
        return (f'trials: off-hand melee hits dealing damage (melee_damage_count hand {OFF_HAND}), the caster '
                f'dual wielding; main-hand swings are not trials')
    if entry['trigger']['action'] == ATTACK:
        return 'trials: main-hand melee hits dealing damage (melee_damage_count hand 0)'
    from proc_avoided import is_avoided, trial_rule as avoided_trial_rule
    if is_avoided(entry):
        return avoided_trial_rule(entry)
    if entry['trigger']['action'] == TAKEN_HIT:
        return (f'trials: damage events of {trigger["spell"]} cast by the striker {trigger["striker_entry"]} at the '
                f'caster (spell_damage_count, caster striker, target caster)')
    if trigger_target(entry) == ALLY:
        return f'trials: completed casts of {entry["trigger"]["spell"]} at the ally (spell_cast_count)'
    if trigger_spells(entry):
        return (f'trials: damage events of {" or ".join(map(str, trigger_spells(entry)))} on the target '
                f'(spell_damage_count of each), one trial per landed hit of any listed spell')
    return f'trials: damage events of {entry["trigger"]["spell"]} on the target (spell_damage_count)'


def trials_step(entry: dict, label: str) -> dict:
    spell = trigger_spell(entry)
    if trigger_target(entry) == ALLY or entry.get('trial_casts'):
        return measurement(label, CASTER, CAST_COUNT, spell=spell)
    return measurement(label, CASTER, 'spell_damage_count', spell=spell, target=TARGET)


def attempt_auras(entry: dict) -> list[dict]:
    auras = entry.get('attempt_auras', [])
    if auras and entry['trigger']['action'] != CAST:
        raise ValueError(f'Proc {entry["aura"]} sets attempt_auras without a cast trigger')
    for aura in auras:
        if set(aura) - {'target'} != {'spell', 'stacks', 'source'} or not isinstance(aura['stacks'], int) \
                or aura['stacks'] < 0:
            raise ValueError(f'Proc {entry["aura"]} attempt aura {aura!r} must name its spell, stacks and source')
        if aura.get('target', TARGET) != TARGET:
            raise ValueError(f'Proc {entry["aura"]} attempt aura {aura!r} sets an aura on the caster or the {TARGET}')
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': aura['spell'], 'stacks': aura['stacks'],
             **({'target': TARGET} if 'target' in aura else {})}
            for aura in auras]


def attempt_fixtures(entry: dict) -> list[dict]:
    spell = trigger_spell(entry)
    fixtures = [{'action': 'restore_charges', 'actor': CASTER, 'spell': spell}] if counts_charges(entry) else []
    fixtures += attempt_auras(entry)
    if trigger_target(entry) == ALLY:
        fixtures.append({'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD})
    return fixtures


def attempt_power_steps(class_file: dict, entry: dict, facts) -> list[dict]:
    if not entry.get(BASE_MANA_PER_ATTEMPT):
        return []
    steps = base_mana_steps(class_file, facts)
    if not steps:
        raise ValueError(f'Proc {entry["aura"]} sets {BASE_MANA_PER_ATTEMPT}, but its trigger costs no percentage of '
                         f'base mana or the class file states no base mana')
    return steps


def aimed(step: dict, target: str) -> dict:
    return {**step, 'target': ALLY} if step['action'] == 'cast' and target == ALLY else step


def cast_attempts(class_file: dict, entry: dict, plan: ProcPlan) -> list[dict]:
    spell, target = trigger_spell(entry), trigger_target(entry)
    facts = facts_of(records_of(class_file), spell)
    steps = []
    for attempt in range(1, plan.per_part + 1):
        steps += attempt_power_steps(class_file, entry, facts)
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
    if entry['trigger']['action'] == MINION:
        from triggers import minion_attempt_steps
        creature = entry['trigger']['entry']
        return (minion_attempt_steps(entry, plan.per_part * plan.attempt_ms, '')
                + [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS},
                   measurement(labels['trials'], CASTER, entry['trial_metric'], entry=creature),
                   measurement(labels['attempts'], CASTER, 'pet_melee_swings', entry=creature)])
    if entry['trigger']['action'] == ATTACK:
        return [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                {'action': 'wait', 'label': 'swings', 'ms': plan.per_part * plan.attempt_ms},
                {'action': 'stop_attack', 'actor': CASTER},
                {'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS},
                measurement(labels['trials'], CASTER, 'melee_damage_count', hand=trial_hand(entry)),
                measurement(labels['attempts'], CASTER, 'melee_attack_count', hand=trial_hand(entry))]
    from proc_avoided import attempt_steps as avoided_attempts, guard_steps, is_avoided, trial_steps
    if is_avoided(entry):
        return (avoided_attempts(entry, plan.per_part, plan.attempt_ms)
                + [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS}] + guard_steps(entry)
                + trial_steps(labels['trials'], labels['attempts']))
    if entry['trigger']['action'] == TAKEN_HIT:
        return (taken_hit_attempts(entry, plan, plan.per_part)
                + [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS}, taken_hit_trials(entry, labels['trials']),
                   taken_hit_trials(entry, labels['attempts'])])
    spell = trigger_spell(entry)
    return ([{'action': 'learn', 'actor': CASTER, 'spell': spell}] + charge_pool_steps(entry)
            + cast_attempts(class_file, entry, plan)
            + [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS}, trials_step(entry, labels['trials']),
               measurement(labels['attempts'], CASTER, CAST_COUNT, spell=spell)])


def taken_hit_attempts(entry: dict, plan: ProcPlan, attempts: int) -> list[dict]:
    from values import fixture_health_step
    return [step for _ in range(attempts) for step in (
        fixture_health_step(CASTER, 100),
        {'action': 'cast', 'actor': TAKEN_HIT_STRIKER, 'spell': entry['trigger']['spell'], 'target': CASTER},
        {'action': 'wait', 'ms': plan.attempt_ms})]


def taken_hit_trials(entry: dict, label: str) -> dict:
    return measurement(label, CASTER, 'spell_damage_count', spell=entry['trigger']['spell'], target=CASTER,
                       caster=TAKEN_HIT_STRIKER)


def taken_hit_baseline_steps(entry: dict, plan: ProcPlan) -> list[dict]:
    labels = baseline_labels(entry['aura'])
    return (taken_hit_attempts(entry, plan, baseline_attempts(plan.chance_pct))
            + [{'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS},
               taken_hit_trials(entry, labels['trials']), {**event_steps(entry)[0], 'label': labels['events']}])


def taken_hit_striker(class_file: dict, entry: dict) -> dict:
    from behaviours import STRIKER_DISTANCE, STRIKER_HEALTH
    return {'id': TAKEN_HIT_STRIKER, 'owner': CASTER, 'entry': entry['trigger']['striker_entry'],
            'level': class_file['level'], 'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 0,
            'stationary': True}


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


def counts_summons(entry: dict) -> bool:
    return entry['event_metric'] == SUMMON_EVENTS


def checked_summon_entry(entry: dict) -> None:
    if entry['trigger']['action'] != CAST or entry.get('event_actor') or entry.get('extra_event_terms'):
        raise ValueError(f'Proc {entry["aura"]} counts summons, which needs a cast trigger and no other event terms')
    if not isinstance(entry.get('event_entry'), int) or entry['event_entry'] <= 0:
        raise ValueError(f'Proc {entry["aura"]} counts summons of a positive creature event_entry')


def events_baseline(entry: dict) -> int:
    if EVENTS_BASELINE not in entry:
        return 0
    per_attempt = entry[EVENTS_BASELINE]
    if isinstance(per_attempt, bool) or not isinstance(per_attempt, int) or per_attempt < 1:
        raise ValueError(f'Proc {entry["aura"]} {EVENTS_BASELINE} is a positive whole number of events per cast')
    if not counts_summons(entry) or not entry.get('baseline') or not entry.get('trial_casts') \
            or entry.get('trial_readings') or excludes_trigger_casts(entry):
        raise ValueError(f'Proc {entry["aura"]} sets {EVENTS_BASELINE}, which needs summon events, a measured '
                         f'baseline arm and the completed casts as its only trials')
    return per_attempt


def events_baseline_rule(entry: dict, plan: 'ProcPlan') -> str:
    per_attempt = events_baseline(entry)
    return (f'; each completed cast of {trigger_spell(entry)} summons {per_attempt} creature {entry["event_entry"]} by '
            f'itself: the baseline arm of {baseline_attempts(plan.chance_pct)} casts before the passive is learned '
            f'must read exactly {per_attempt} per completed cast (a missing or empty arm leaves the rate unmeasured, '
            f'another count alerts), and {per_attempt} per completed cast is subtracted from the events of every '
            f'part')


def event_steps(entry: dict) -> list[dict]:
    if counts_charges(entry):
        return []
    if counts_summons(entry):
        return [measurement(proc_measurements(entry['aura'])['events'], CASTER, SUMMON_EVENTS,
                            entry=entry['event_entry'])]
    if entry.get('event_actor') == MINION:
        if entry['event_metric'] not in ('spell_damage_count', 'spell_go_count', MINION_PROC_COUNT) \
                or minion_entry(entry) is None:
            raise ValueError(f'Proc {entry["aura"]} reads minion events other than damage, casts or '
                             f'{MINION_PROC_COUNT} of a minion')
        on_target = {'target': TARGET} \
            if entry['event_metric'] == 'spell_damage_count' and not entry.get('extra_dummies') else {}
        return [measurement(label, CASTER, term['metric'], spell=term['spell'], entry=minion_entry(entry),
                            **on_target) for label, term in event_terms(entry)]
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
    readings = entry.get('trial_readings') or [{'name': TRIGGERING_HITS, 'adds': trigger_spell_terms(entry)}]
    return [{'name': reading['name'], 'adds': list(reading.get('adds', [])),
             'minus_events': reading.get('minus_events', False),
             'labels': [reading_trials_label(entry, reading)] + [added_trials_label(entry['aura'], term)
                                                                 for term in reading.get('adds', [])]}
            for reading in readings]


def added_trial_steps(entry: dict) -> list[dict]:
    terms = {added_trials_label(entry['aura'], term): term
             for reading in trial_readings(entry) for term in reading['adds']}
    return [spell_count_step(label, term['metric'], term['spell']) for label, term in terms.items()]


STREAMS_FIELD = 'streams'


def proc_isolation(entry: dict):
    from kinds.stack_chance_rate import isolation_of
    isolation = isolation_of({**entry, 'spell': entry['aura']}, 'procs', proc_dummy_distance(entry))
    if isolation.streams > 1 and (entry['trigger']['action'] != CAST or trigger_target(entry) != TARGET
                                  or counts_charges(entry) or entry.get('extra_dummies') or entry.get('event_actor')
                                  or entry.get('trial_excluded_spells')):
        raise ValueError(f'Proc {entry["aura"]} runs {isolation.streams} streams, which needs a cast trigger at the '
                         f'dummy, no charges, extra dummies, minion events or excluded trial spells')
    return isolation


def stream_count(entry: dict) -> int:
    return proc_isolation(entry).streams


def stream_baseline_attempts(entry: dict, chance_pct: float) -> int:
    return math.ceil(baseline_attempts(chance_pct) / stream_count(entry))


def streamed_steps(steps: list[dict], streams: list) -> list[dict]:
    from kinds.stack_chance_rate import on_stream
    expanded, run = [], []
    for step in steps + [None]:
        if step is not None and step['action'] != 'wait':
            run.append(step)
            continue
        for stream in streams:
            for item in run:
                moved = on_stream(item, stream)
                if moved['action'] == 'assert':
                    moved['label'] = f'{moved["label"]}{stream.suffix}'
                expanded.append(moved)
        run = []
        if step is not None:
            expanded.append(step)
    return expanded


def stream_proc_scenario(class_file: dict, entry: dict, scenario: dict, model: dict,
                         steps: list[dict]) -> dict:
    from kinds.stack_chance_rate import (crossing_steps, isolation_bounds, placement_steps, stream_base_steps,
                                         stream_scenario, streams_of, triggered_spells)
    isolation = proc_isolation(entry)
    streams = streams_of(isolation)
    aura = entry['aura']

    def mark(text: str) -> str:
        return f'{entry_proc_label(class_file, entry)} {text}'

    spell = trigger_spell(entry)
    damage = tuple(dict.fromkeys((spell, *triggered_spells(records_of(class_file), spell),
                                  *trigger_spells(entry)[1:])))
    body = streamed_steps(steps, streams)
    isolation_steps = placement_steps(isolation, streams, mark)
    crossing = crossing_steps(isolation, streams, mark, damage, ())
    scenario['steps'] = stream_base_steps(class_file, streams) + isolation_steps + body + crossing
    scenario = stream_scenario(scenario, class_file, isolation, streams)
    model[STREAMS_FIELD] = isolation.streams
    model['stream_suffixes'] = [stream.suffix for stream in streams]
    model['summed_labels'] = list(dict.fromkeys(step['label'] for step in steps if step['action'] == 'assert'))
    model['isolation'] = isolation_bounds(isolation_steps + crossing)
    scenario['contract'] += (f'; every stream makes {model["part_attempts"] // isolation.streams} attempts of this '
                             f'part, and the reads of the {isolation.streams} streams are summed per label before '
                             f'the unchanged proc judge (aura {aura})')
    return scenario


def proc_scenario(class_file: dict, entry: dict, part: int = 0, *,
                  attempts: int | None = None) -> tuple[dict, list[Expectation]]:
    plan = proc_plan(class_file, entry, attempts)
    streams = stream_count(entry)
    if streams > 1:
        plan = replace(plan, per_part=math.ceil(plan.per_part / streams))
    if entry['trigger']['action'] == CAST:
        class_file = armed_for(class_file, records_of(class_file), entry['trigger']['spell'])
    if not 0 <= part < plan.parts:
        raise ValueError(f'Proc {entry["aura"]} has parts 0 to {plan.parts - 1}, not {part}')
    aura = entry['aura']
    labels = proc_measurements(aura)
    minion = entry['trigger']['action'] == MINION
    cast_baseline = entry['trigger']['action'] == CAST and part == 0 and entry.get('baseline', False)
    taken_baseline = entry['trigger']['action'] == TAKEN_HIT and part == 0 and entry.get('baseline', False)
    baseline = (minion and part == 0 and entry.get('baseline', False)) or cast_baseline or taken_baseline
    from proc_avoided import is_avoided
    avoided = is_avoided(entry)
    control = control_weapon(class_file, entry) if part == 0 else None
    if minion:
        from triggers import minion_setup_steps
        steps = minion_setup_steps(class_file, entry['trigger'])
        steps += minion_baseline_steps(class_file, entry, plan) if baseline else []
        steps += aura_steps(entry)
    elif avoided:
        from proc_avoided import baseline_steps
        steps = baseline_steps(entry, plan, entry.get('baseline', False) and part == 0) + aura_steps(entry)
    elif taken_baseline:
        steps = taken_hit_baseline_steps(entry, plan) + aura_steps(entry)
    else:
        steps = (cast_baseline_steps(class_file, entry, plan) if cast_baseline else []) + aura_steps(entry)
        steps += control_weapon_steps(class_file, entry, plan) if control else []
    limit = per_trigger_limit(entry)
    steps += attempt_steps(class_file, entry, plan, labels)
    if limit is None:
        steps += added_trial_steps(entry) + event_steps(entry) + energize_steps(entry) + excluded_trial_steps(entry)
    if entry.get('aura_on_minion'):
        if minion_entry(entry) is None:
            raise ValueError(f'Proc {aura} reads its aura on a minion without a minion trigger')
        steps += [measurement(labels['aura'], CASTER, 'owned_creature_count', entry=minion_entry(entry), spell=aura,
                              caster=CASTER)]
    else:
        steps += [measurement(labels['aura'], CASTER, 'aura', spell=aura)]
    name = f'Conformance proc {class_file["name"]} {entry["name"]} {aura} part {part + 1} of {plan.parts}'
    contract = 'Proc rate of an aura over enough triggering hits, summed over its parts, against its tooltip chance.'
    if trigger_spells(entry):
        contract += (f' Each landed hit of {" or ".join(map(str, trigger_spells(entry)))} rolls the proc and is one '
                     f'trial: {entry[TRIGGER_SPELLS_SOURCE]}')
    scenario = scenario_shell(class_file, name, contract, steps)
    if trigger_target(entry) == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    elif avoided:
        from proc_avoided import striker_fixtures
        scenario['creatures'] = striker_fixtures(class_file, entry)
    elif entry['trigger']['action'] == TAKEN_HIT:
        scenario['creatures'] = [taken_hit_striker(class_file, entry)]
    else:
        scenario['creatures'] = [creature_fixture(class_file, proc_dummy_distance(entry))] + extra_dummies(class_file,
                                                                                                         entry)
        if entry.get(DUMMY_DISTANCE_FIELD) is not None:
            scenario['contract'] += f' The dummy stands {proc_dummy_distance(entry):g} yd from the caster.'
    model = {'part': part, 'parts': plan.parts, 'chance_pct': plan.chance_pct, 'minimum_trials': plan.needed,
             'scheduled_attempts': plan.scheduled, 'part_attempts': plan.per_part * streams,
             'attempt_ms': plan.attempt_ms,
             'trigger': dict(entry['trigger']), 'proc_spell': entry['proc_spell'],
             **chance_model(entry), **({'chance_modifiers': [list(pair) for pair in chance_modifiers(entry)]}
                                        if chance_modifiers(entry) else {}), **modifier_tooltips(class_file, entry),
             'event_metric': entry['event_metric'], 'events_per_proc': entry.get('events_per_proc', 1),
             'measurements': labels, 'event_labels': event_labels(entry, plan),
             'exclude_trigger_casts': excludes_trigger_casts(entry),
             **({EVENTS_BASELINE: events_baseline(entry)} if events_baseline(entry) else {}),
             'readings': [{key: reading[key] for key in ('name', 'labels', 'minus_events')}
                          for reading in trial_readings(entry)]}
    if counts_charges(entry):
        model['charge_pool'] = charge_pool_label(aura)
    if minion:
        from triggers import minion_grants
        reads = [step.get('label', '') for step in steps if step['action'] == 'assert']
        grants = [{'aura': fixture['spell'], 'cast': fixture['grant_cast'], 'entry': entry['trigger']['entry'],
                   'labels': [label for label in reads if label.startswith(f'{fixture["spell"]} grant '
                                                                           f'{fixture["grant_cast"]} ')]}
                  for fixture in minion_grants(entry)]
        if grants:
            model['grants'] = grants
    if baseline:
        model['baseline'] = {**baseline_labels(aura),
                             'attempts': stream_baseline_attempts(entry, plan.chance_pct) * streams}
        if cast_baseline and trigger_spells(entry):
            model['baseline']['added_trials'] = {
                added_trials_label(aura, term): baseline_trigger_label(aura, term['spell'])
                for term in trigger_spell_terms(entry)}
    if avoided:
        from proc_avoided import avoided_baseline_model, reading
        model['readings'] = [reading(labels['trials'])]
        model['baseline'] = avoided_baseline_model(entry, plan, part)
    if control:
        model['baseline'] = {**baseline_labels(aura), 'attempts': baseline_attempts(plan.chance_pct),
                             CONTROL_WEAPON: entry[CONTROL_WEAPON], 'control_item': control['item'],
                             'minimum_trials': baseline_attempts(plan.chance_pct)}
    if entry.get('band'):
        model['band'] = rate_band(plan.chance_pct / 100)
    residual = residual_sizing(entry, plan.chance_pct)
    if residual:
        model['residual'] = residual
        model['minimum_trials'] = max(plan.needed, residual['trials'])
    if entry.get('trial_excluded_spells'):
        model['trial_exclusions'] = excluded_trial_labels(entry)
    rule = f'{WILSON_RULE}; {trial_rule(entry)}'
    if entry.get('band'):
        rule += (f'; the 99% interval inside the band of {rate_band(plan.chance_pct / 100) * 100:g} points around '
                 f'the chance (G-19, ADR 0346)')
    if residual:
        rule += (f'; {RESIDUAL_TARGET} {residual["target"]:g} per pair: Wilson confidence {residual["confidence"]:g} '
                 f'per run instead of 99%, at least {residual["trials"]} trials so that a deviation of '
                 f'{residual["min_detectable"] * 100:g} points is outside the band')
    if entry.get('trial_excluded_spells'):
        rule += (f'; the minion hits of {entry["trial_excluded_spells"]} are left out of the trials '
                 f'({entry["trial_excluded_reason"]})')
    if entry.get('extra_dummies'):
        rule += (f'; {len(entry["extra_dummies"])} more dummies at {entry["extra_dummies"]} yd from the caster, the '
                 f'events counted on every dummy')
    if events_baseline(entry):
        rule += events_baseline_rule(entry, plan)
    elif entry.get('baseline') and entry['trigger']['action'] in (MINION, CAST):
        beyond = ' beyond their own completed casts' if excludes_trigger_casts(entry) else ''
        rule += (f'; no event{beyond} in the {baseline_attempts(plan.chance_pct)} baseline attempts before the passive '
                 f'is learned, which a {plan.chance_pct:g}% roll passes with under {BASELINE_MISS_RISK:g} probability')
    if control_weapon(class_file, entry):
        rule += (f'; control arm in part 1: the {entry[CONTROL_WEAPON]} one-handed main hand '
                 f'{control_weapon(class_file, entry)["item"]} wielded with the passive learned, '
                 f'{control_swings(plan.chance_pct)} swings, at least {baseline_attempts(plan.chance_pct)} landed '
                 f'main-hand hits and no event; a server that ignores the two-handed condition at {plan.chance_pct:g}% '
                 f'passes it with under {BASELINE_MISS_RISK:g} probability per run')
    if limit is not None:
        model[PER_TRIGGER] = limit
        model['trigger_boundaries'] = trigger_boundaries(entry, plan.per_part)
        rule = f'{rule}; {PER_TRIGGER_RULE} ({limit})'
    label = entry_proc_label(class_file, entry)
    expectation = Expectation(label, PROC_CHECK, aura, aura, None, entry['chance_token'],
                              f'{rule}{handler_note(entry)}', model)
    baseline_ms = stream_baseline_attempts(entry, plan.chance_pct) * plan.attempt_ms + DRAIN_MS if baseline else 0
    if avoided:
        from proc_avoided import baseline_ms as avoided_baseline_ms
        baseline_ms = avoided_baseline_ms(entry, plan, part)
    baseline_ms += control_weapon_ms(class_file, entry, plan.chance_pct) if control else 0
    if streams > 1:
        scenario = stream_proc_scenario(class_file, entry, scenario, model, steps)
    return (timed(scenario, SETTLE_MS + baseline_ms + plan.per_part * plan.attempt_ms + DRAIN_MS),
            [expectation] + energize_expectations(entry, part, plan.parts))


def energize_labels(aura: int, power: int) -> dict[str, str]:
    return {part: f'{aura} proc energize {power} {part}' for part in ('total', 'count', 'max_power')}


def energize_steps(entry: dict) -> list[dict]:
    steps = []
    for amount in entry.get('energize_amounts', []):
        labels = energize_labels(entry['aura'], amount['power'])
        steps += [measurement(labels['total'], CASTER, 'spell_energize_total', spell=entry['proc_spell'],
                              power=amount['power']),
                  measurement(labels['count'], CASTER, 'spell_energize_count', spell=entry['proc_spell'],
                              power=amount['power'])]
        if 'percent_of_max' in amount:
            steps.append(measurement(labels['max_power'], CASTER, 'max_power', power=amount['power']))
    return steps


def energize_expectations(entry: dict, part: int, parts: int) -> list[Expectation]:
    expectations = []
    for amount in entry.get('energize_amounts', []):
        if set(amount) - {'power', 'expected', 'percent_of_max', 'source'} or ('expected' in amount) == \
                ('percent_of_max' in amount) or not amount.get('source'):
            raise ValueError(f'Proc {entry["aura"]} energize amount is {{"power", "expected" or "percent_of_max", '
                             f'"source"}}')
        stated = (f'{amount["expected"]:g}' if 'expected' in amount
                  else f'{amount["percent_of_max"]:g}% of the maximum')
        rule = (f'every energize of power {amount["power"]} by {entry["proc_spell"]} restores {stated}, summed over '
                f'the proc parts ({amount["source"]})')
        model = {'part': part, 'parts': parts, 'power': amount['power'], 'expected': amount.get('expected'),
                 'percent_of_max': amount.get('percent_of_max'),
                 'measurements': energize_labels(entry['aura'], amount['power'])}
        expectations.append(Expectation(f'{entry["aura"]} {PROC_ENERGIZE_CHECK} {amount["power"]}',
                                        PROC_ENERGIZE_CHECK, entry['aura'], entry['aura'], None, stated, rule, model))
    return expectations


def proc_dummy_distance(entry: dict) -> float:
    stated = entry.get(DUMMY_DISTANCE_FIELD)
    if stated is None:
        return DUMMY_DISTANCE
    if isinstance(stated, bool) or not 0 < stated <= MAX_DUMMY_DISTANCE_YD:
        raise ValueError(f'Proc {entry["aura"]} places the dummy {stated!r} yd away, outside (0, '
                         f'{MAX_DUMMY_DISTANCE_YD}] yd')
    return float(stated)


def extra_dummies(class_file: dict, entry: dict) -> list[dict]:
    extras = entry.get('extra_dummies', [])
    if extras and minion_entry(entry) is None:
        raise ValueError(f'Proc {entry["aura"]} places extra dummies without a minion trigger')
    return [{**creature_fixture(class_file), 'id': f'{TARGET}_{index + 2}', 'distance': distance}
            for index, distance in enumerate(extras)]


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
    label = entry_proc_label(class_file, entry)
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
