from dataclasses import asdict, dataclass, replace
from fractions import Fraction
import math
from pathlib import Path
import re
import struct
from typing import Mapping, Sequence

from block_value import block_value_steps, block_value_terms
from heal_pct import heal_pct_steps, heal_pct_term, heal_pct_text
from classes import ClassSpell
from custom_attr import TABLE as CUSTOM_ATTR_TABLE, custom_attributes
from mitigation import (PHYSICAL_SCHOOL_MASK, REFERENCE_TARGET, ArmorFacts, MitigationModel, TargetProfile,
                        armor_reduction, expected_mitigation)
from profile import (CASTER, DBC_DIR, OFF_HAND, RANGED_DAMAGE_CLASS, REQUIRES_OFF_HAND_ATTRIBUTE_EX3, SETTLE_MS,
                     WEAPON_REQUIREMENT_FIELDS, armed,
                     attack_hand, base_steps,
                     caster_stats_from, known_aura_label, measurement, player_fixture, ranged_weapon_spell,
                     spec_weapon_set, unfit_reason, weapon_set_unfit_reason)
from streamed import streamed_texts
from tooltip import (MIXED_PERIOD, OVER_TICKS, CasterStats, Displayed, ForcedPoints, Readout, Records, Tooltip,
                     UnscaledForcedPoints, Unreadable, mixed_period_reason, period_reading, read_tooltip)
from values import (ALLY, CAST_MARGIN_MS, CHARGE_OFFSET_YD, DUMMY_DISTANCE, DUMMY_ENTRY, DUMMY_HEALTH, EFFECT_TOKEN,
                    EFFECTS, GAP_CLOSER_DISTANCE, MEAN_HALF_WIDTH, READ_STEP_MS, TARGET, UNREADABLE,
                    Z_99, Expectation, RankFacts, Unmodelled, armed_for, cast_aura_steps, cast_distance,
                    closes_distance, dataset,
                    equip_requirement, weapon_requirement,
                    facts_of, gap_closer_expectation, gap_closer_target, is_hostile, required_aura_steps,
                    pay_power_steps, required_target_health_steps, targets_ally)

HIT_CHECKS = ('hit_mean', 'melee_mean', 'periodic_total', 'unmodelled', GAP_CLOSER_DISTANCE)
UNMODELLED = 'unmodelled: '
CLOSED = 'closed: '
NEVER_CAST = 'passive spell is never cast'
NO_HIT_EFFECT = 'no damage or healing effect'
EXCLUDED_OUTCOME_MARGIN = Fraction(3, 2)
ATTACK_POWER_PER_DPS = 14.0
SCHOOL_DAMAGE = 2
APPLY_AURA = 6
HEAL = 10
HEALTH_LEECH = 9
WEAPON_DAMAGE_NOSCHOOL = 17
WEAPON_PERCENT_DAMAGE = 31
WEAPON_DAMAGE = 58
NORMALIZED_WEAPON_DMG = 121
WEAPON_FLAT_EFFECTS = frozenset({WEAPON_DAMAGE_NOSCHOOL, WEAPON_DAMAGE, NORMALIZED_WEAPON_DMG})
WEAPON_EFFECTS = WEAPON_FLAT_EFFECTS | {WEAPON_PERCENT_DAMAGE}
PERIODIC_TRIGGER_SPELL = 23
PERIODIC_KINDS = {3: 'periodic_damage', 8: 'periodic_heal'}
TRIGGERED_WEAPON = 'triggered_weapon'
WEAPON_KINDS = frozenset({'weapon', TRIGGERED_WEAPON})
TICKING_KINDS = frozenset(PERIODIC_KINDS.values()) | {TRIGGERED_WEAPON}
HEAL_KINDS = frozenset({'heal', 'periodic_heal'})
MODIFIER_AURAS = {341: 'damage', 136: 'heal', 79: 'damage', 118: 'heal'}
MOD_DAMAGE_FROM_CASTER = 271
DAMAGE_TAKEN = 'damage_taken'
CLASS_MASK_WORDS = 3
MAGIC_SCHOOLS = range(1, 7)
NO_MITIGATION = MitigationModel(mean=1.0, variance=0.0)
UNRESISTED_RANK_HITS = 'unresisted_rank_hits'
RANK_HIT_EFFECTS = 'rank_hit_effects'
HIT_ROLES = ('hit_mean', 'periodic_total')
HIT_LOCATION = 'hit_location'
HIT_LOCATION_KEYS = ('map', 'x', 'y', 'z', 'o')
WEAPON_SCHOOL_PERCENTS = 'weapon_school_percents'
DRAIN_MS = 3000
MAX_SCENARIO_MS = 600000
MAX_ACCELERATED_SCENARIO_MS = 3600000
TIMEOUT_MARGIN_MS = 60000
PART_BUDGET_MS = MAX_SCENARIO_MS - TIMEOUT_MARGIN_MS - SETTLE_MS - DRAIN_MS
MAIN_HAND = 0
MELEE_LABEL = 'melee melee_mean'
MELEE_PARTS = 'melee_parts'
ARMOR_LABEL = 'target armor'
VIEW_LEVEL_LABEL = 'target view_level'
FLOAT32 = struct.Struct('<f')
BASE_MANA_FIELD = 'base_mana'
POWER_MANA = 0


@dataclass(frozen=True)
class WeaponProfile:
    item: int
    min_damage: float
    max_damage: float
    speed_ms: int
    normalized_speed: float


@dataclass(frozen=True)
class Modifier:
    spell_id: int
    effect_index: int
    aura: int
    percent: int
    applies_to: str
    school_mask: int


@dataclass(frozen=True)
class HitModel:
    kind: str
    mean: float
    sigma: float
    tooltip_mean: float
    hits_per_cast: int = 1
    modifiers: tuple[Modifier, ...] = ()
    displayed: tuple[str, ...] = ()
    engine: 'HitModel | None' = None
    engine_rule: str = ''


@dataclass(frozen=True)
class Triggered:
    spell_id: int
    effects: tuple[int, ...]
    aura_names: tuple[int, ...]


Distribution = dict[int, float]


def uniform(low: int, high: int) -> Distribution:
    return {value: 1.0 / (high - low + 1) for value in range(low, high + 1)}


def mapped(distribution: Distribution, step) -> Distribution:
    result: Distribution = {}
    for value, share in distribution.items():
        mapped_value = step(value)
        result[mapped_value] = result.get(mapped_value, 0.0) + share
    return result


def summed(left: Distribution, right: Distribution) -> Distribution:
    result: Distribution = {}
    for first, first_share in left.items():
        for second, second_share in right.items():
            result[first + second] = result.get(first + second, 0.0) + first_share * second_share
    return result


def moments(distribution: Distribution) -> tuple[float, float]:
    mean = sum(value * share for value, share in distribution.items())
    variance = sum(share * (value - mean) ** 2 for value, share in distribution.items())
    return mean, math.sqrt(variance)


def float32(value: float) -> float:
    return FLOAT32.unpack(FLOAT32.pack(value))[0]


def weapon_profile(class_file: dict) -> WeaponProfile | None:
    weapon = class_file.get('weapon')
    if not weapon or 'min_damage' not in weapon:
        return None
    return WeaponProfile(item=weapon['item'], min_damage=weapon['min_damage'], max_damage=weapon['max_damage'],
                         speed_ms=weapon['speed_ms'], normalized_speed=weapon['normalized_speed'])


def hit_kind(effects: Sequence[int], aura_names: Sequence[int],
             triggered: Mapping[int, Triggered] | None = None,
             readout: Readout | None = None) -> tuple[str, list[int]]:
    triggered = triggered or {}
    kinds: dict[str, list[int]] = {}
    for index, effect in enumerate(effects):
        trigger = triggered.get(index)
        if effect in WEAPON_EFFECTS:
            kinds.setdefault('weapon', []).append(index)
        elif effect == SCHOOL_DAMAGE:
            kinds.setdefault('school', []).append(index)
        elif effect == HEALTH_LEECH:
            kinds.setdefault('leech', []).append(index)
        elif effect == HEAL:
            kinds.setdefault('heal', []).append(index)
        elif effect == APPLY_AURA and aura_names[index] in PERIODIC_KINDS:
            kinds.setdefault(PERIODIC_KINDS[aura_names[index]], []).append(index)
        elif (effect == APPLY_AURA and aura_names[index] == PERIODIC_TRIGGER_SPELL and trigger
              and WEAPON_EFFECTS.intersection(trigger.effects)):
            kinds.setdefault(TRIGGERED_WEAPON, []).append(index)
    if not kinds:
        raise Unmodelled(f'{NO_HIT_EFFECT} among effects {list(effects)}')
    if len(kinds) > 1:
        tokened = kinds
        if readout is not None:
            own_tokens = {value.effect_index for value in readout.values}
            filtered = {name: indexes for name, indexes in kinds.items()
                       if own_tokens.intersection(indexes)}
            if len(filtered) == 1:
                tokened = filtered
        if len(tokened) > 1:
            raise Unmodelled(f'effects of several hit models: {sorted(kinds)}')
        kinds = tokened
    kind, indexes = next(iter(kinds.items()))
    if kind in TICKING_KINDS and len(indexes) > 1:
        raise Unmodelled(f'several periodic effects: {indexes}')
    return kind, indexes


def rank_hit_effect(class_file: dict, rank_id: int, check: str) -> int | None:
    entry = class_file.get(RANK_HIT_EFFECTS, {}).get(str(rank_id))
    if entry is None:
        return None
    source = entry.get('source')
    if not isinstance(source, str) or not source.strip():
        raise ValueError(f'{RANK_HIT_EFFECTS} {rank_id} needs a non-blank source')
    extra = set(entry) - {'source', *HIT_ROLES}
    if extra or not set(HIT_ROLES).issubset(entry):
        raise ValueError(f'{RANK_HIT_EFFECTS} {rank_id} names {sorted(HIT_ROLES)} and source, not {sorted(entry)}')
    effects = [entry[role] for role in HIT_ROLES]
    if any(type(effect) is not int or effect not in EFFECTS for effect in effects) or len(set(effects)) != 2:
        raise ValueError(f'{RANK_HIT_EFFECTS} {rank_id} needs two distinct effect indexes, not {effects}')
    if check not in HIT_ROLES:
        raise Unmodelled(f'{RANK_HIT_EFFECTS} {rank_id} models only {list(HIT_ROLES)}, not {check}')
    return entry[check]


def effect_only(readout: Readout, effect: int) -> Readout:
    return Readout([value for value in readout.values if value.effect_index == effect], readout.unreadable)


def checked_role(rank_id: int, check: str, effect: int, kind: str, indexes: Sequence[int]):
    periodic = kind in PERIODIC_KINDS.values()
    if effect not in indexes or periodic != (check == 'periodic_total'):
        raise Unmodelled(f'{RANK_HIT_EFFECTS} {rank_id} names effect {effect} for {check}, which models a {kind} '
                         f'hit of effects {list(indexes)}')


def shown_values(readout: Readout, effect: int, kind: str):
    shown = [value for value in readout.values if value.effect_index == effect]
    if not shown:
        raise Unmodelled(f'effect {effect} has no readable tooltip value')
    for value in shown:
        if value.kind != kind:
            raise Unmodelled(f'effect {effect} reads as {value.kind} ({value.text}), not {kind}')
    return shown


def fixed_value(readout: Readout, effect: int, kind: str) -> tuple[float, list[str]]:
    shown = shown_values(readout, effect, kind)
    if len({value.value for value in shown}) > 1:
        raise Unmodelled(f'effect {effect} shows several values: {[value.text for value in shown]}')
    return shown[0].value, [shown[0].text]


def value_range(readout: Readout, effect: int) -> tuple[float, float, list[str]]:
    shown = shown_values(readout, effect, 'flat')
    if len({value.value for value in shown}) == 1:
        return shown[0].value, shown[0].value, [shown[0].text]
    low = [value for value in shown if f'$m{effect + 1}' in value.text]
    high = [value for value in shown if f'$M{effect + 1}' in value.text]
    if len(shown) != 2 or len(low) != 1 or len(high) != 1:
        raise Unmodelled(f'effect {effect} shows several values: {[value.text for value in shown]}')
    spread = high[0].value - low[0].value
    if spread < 0 or spread != int(spread):
        raise Unmodelled(f'effect {effect} range {low[0].text} to {high[0].text} is not a whole roll')
    return low[0].value, high[0].value, [low[0].text, high[0].text]


def effect_roll(low: float, high: float) -> Distribution:
    return mapped(uniform(0, int(high - low)), lambda roll: math.floor(low + roll))


def weapon_hit(readout: Readout, effects: Sequence[int], caster: CasterStats, weapon: WeaponProfile | None,
               *, percent_before_flat: bool = False) -> tuple[Distribution, float, list[str]]:
    if weapon is None:
        raise Unmodelled('weapon damage needs the weapon stats of the class file')
    percent = Fraction(1)
    flat_floor = 0
    flat = 0.0
    texts: list[str] = []
    for index, effect in enumerate(effects):
        if effect == WEAPON_PERCENT_DAMAGE:
            value, shown = fixed_value(readout, index, 'percent')
            percent *= Fraction(value) / 100
            texts += shown
        elif effect in WEAPON_FLAT_EFFECTS:
            value, shown = fixed_value(readout, index, 'flat')
            flat_floor += math.floor(value)
            flat += value
            texts += shown
    speed = weapon.normalized_speed if NORMALIZED_WEAPON_DMG in effects else weapon.speed_ms / 1000
    bonus = caster.ap / ATTACK_POWER_PER_DPS * speed
    roll = uniform(math.floor(weapon.min_damage + bonus), math.floor(weapon.max_damage + bonus))
    if percent_before_flat:
        distribution = mapped(roll, lambda damage: math.floor(damage * percent) + flat_floor)
        tooltip_mean = float(percent) * ((weapon.min_damage + weapon.max_damage) / 2 + bonus) + flat
    else:
        distribution = mapped(roll, lambda damage: math.floor((damage + flat_floor) * percent))
        tooltip_mean = float(percent) * ((weapon.min_damage + weapon.max_damage) / 2 + bonus + flat)
    return distribution, tooltip_mean, ordered(readout, texts)


def triggered_readout(readout: Readout, spell_id: int) -> Readout:
    values = []
    for value in readout.values:
        token = EFFECT_TOKEN.search(value.text)
        if value.spell_id == spell_id and token:
            values.append(replace(value, effect_index=int(token.group('digit')) - 1))
    return Readout(values, readout.unreadable)


def triggered_hit(readout: Readout, trigger: Triggered, caster: CasterStats,
                  weapon: WeaponProfile | None) -> tuple[Distribution, float, list[str]]:
    try:
        kind, _ = hit_kind(trigger.effects, trigger.aura_names)
    except Unmodelled as error:
        raise Unmodelled(f'triggered spell {trigger.spell_id}: {error.reason}') from error
    if kind != 'weapon':
        raise Unmodelled(f'triggered spell {trigger.spell_id} is a {kind} hit, not weapon damage')
    return weapon_hit(triggered_readout(readout, trigger.spell_id), trigger.effects, caster, weapon)


def rolled_hit(values: Sequence[float]) -> Distribution:
    return mapped({index: 1.0 / len(values) for index in range(len(values))},
                  lambda index: math.floor(values[index]))


SHARED_TOKEN_KINDS = frozenset({'heal'})


def matching_sibling(records: Records, rank_id: int, index: int) -> int | None:
    kind = records.field('Spell', rank_id, f'Effect[{index}]')
    base = records.field('Spell', rank_id, f'EffectBasePoints[{index}]')
    sides = records.field('Spell', rank_id, f'EffectDieSides[{index}]')
    for sibling in EFFECTS:
        if sibling == index:
            continue
        if (records.field('Spell', rank_id, f'Effect[{sibling}]') == kind
                and records.field('Spell', rank_id, f'EffectBasePoints[{sibling}]') == base
                and records.field('Spell', rank_id, f'EffectDieSides[{sibling}]') == sides):
            return sibling
    return None


def mixed(distributions: Sequence[Distribution]) -> Distribution:
    result: Distribution = {}
    weight = 1.0 / len(distributions)
    for distribution in distributions:
        for value, share in distribution.items():
            result[value] = result.get(value, 0.0) + share * weight
    return result


def effect_hit(readout: Readout, indexes: list[int], rolls: Mapping[int, Sequence[float]], *, kind: str = '',
              records: Records | None = None, rank_id: int = 0) -> tuple[Distribution, float, list[str]]:
    distributions: list[Distribution] = []
    tooltip_means: list[float] = []
    texts: list[str] = []
    for index in indexes:
        source = index
        has_own = any(value.effect_index == index for value in readout.values)
        if not has_own and kind in SHARED_TOKEN_KINDS and records is not None:
            sibling = matching_sibling(records, rank_id, index)
            if sibling is not None:
                source = sibling
        low, high, shown = value_range(readout, source)
        key = index if index in rolls else source if source in rolls else None
        if key is not None:
            distributions.append(rolled_hit(rolls[key]))
            tooltip_means.append(sum(rolls[key]) / len(rolls[key]))
        else:
            distributions.append(effect_roll(low, high))
            tooltip_means.append((low + high) / 2)
        texts += shown
    return mixed(distributions), sum(tooltip_means) / len(tooltip_means), ordered(readout, texts)


def rolled_values(records: Records, rank_id: int, caster: CasterStats, readout: Readout,
                  indexes: Sequence[int], tooltip_spell: int | None = None,
                  value_source: tuple[int, int] | None = None,
                  level_points: bool = False) -> dict[int, tuple[float, ...]]:
    described = rank_id if tooltip_spell is None else tooltip_spell
    rolls = {}
    for effect in indexes:
        spell, rolled = value_source or (rank_id, effect)
        sides = records.field('Spell', spell, f'EffectDieSides[{rolled}]')
        shown = [value for value in readout.values if value.effect_index == effect]
        if len(shown) != 1 or sides < 1 or (sides == 1 and not level_points):
            continue
        base = records.field('Spell', spell, f'EffectBasePoints[{rolled}]')
        term = calc_value_term(records, spell, rolled, caster.level) if level_points else 0.0
        values = []
        for roll in range(1, sides + 1):
            forced = (UnscaledForcedPoints(records.dbc, spell, rolled, base + roll + term) if level_points
                      else ForcedPoints(records.dbc, spell, rolled, base + roll))
            reread = Tooltip(forced, described, caster).read(records.field('Spell', described, 'Description[enUS]'))
            same = [value for value in reread.values if value.text == shown[0].text]
            if len(same) != 1:
                raise Unmodelled(f'{shown[0].text} is unreadable with roll {roll} of effect {effect}')
            values.append(same[0].value)
        rolls[effect] = tuple(values)
    return rolls


def ordered(readout: Readout, texts: list[str]) -> list[str]:
    return [value.text for value in readout.values if value.text in texts]


def applicable(modifiers: Sequence[Modifier], kind: str) -> tuple[Modifier, ...]:
    wanted = 'heal' if kind in HEAL_KINDS else 'damage'
    return tuple(modifier for modifier in modifiers if modifier.applies_to == wanted)


def taken_by(modifiers: Sequence[Modifier], kind: str) -> tuple[Modifier, ...]:
    if kind in HEAL_KINDS:
        return ()
    return tuple(modifier for modifier in modifiers if modifier.applies_to == DAMAGE_TAKEN)


def done(distribution: Distribution, modifiers: Sequence[Modifier]) -> Distribution:
    factor = Fraction(1)
    for modifier in modifiers:
        factor *= Fraction(100 + modifier.percent, 100)
    return mapped(distribution, lambda value: max(0, math.floor(value * factor)))


def mitigated(distribution: Distribution, mitigation: MitigationModel) -> Distribution:
    if not mitigation.resist_shares:
        return mapped(distribution, lambda value: math.ceil(value * mitigation.mean))
    result: Distribution = {}
    for value, share in distribution.items():
        for step, step_share in enumerate(mitigation.resist_shares):
            if step_share > 0:
                kept = value - value * step // 10
                result[kept] = result.get(kept, 0.0) + share * step_share
    return result


def expected_hit(readout: Readout, spell_effects: Sequence[int], caster: CasterStats, weapon: WeaponProfile | None,
                 mitigation: MitigationModel, *, aura_names: Sequence[int] = (), modifiers: Sequence[Modifier] = (),
                 ticks: int = 1, rolls: Mapping[int, Sequence[float]] | None = None,
                 triggered: Mapping[int, Triggered] | None = None, records: Records | None = None,
                 rank_id: int = 0, percent_before_flat: bool = False,
                 weapon_part: tuple[Distribution, float, list[str]] | None = None,
                 percent_part: float | None = None, taken: Sequence[Modifier] = ()) -> HitModel:
    names = tuple(aura_names) or (0,) * len(spell_effects)
    kind, indexes = hit_kind(spell_effects, names, triggered, readout)
    events = 1
    if kind == 'weapon':
        distribution, tooltip_mean, texts = weapon_hit(readout, spell_effects, caster, weapon,
                                                        percent_before_flat=percent_before_flat)
    elif kind == TRIGGERED_WEAPON:
        distribution, tooltip_mean, texts = triggered_hit(readout, triggered[indexes[0]], caster, weapon)
    else:
        distribution, tooltip_mean, texts = effect_hit(readout, indexes, rolls or {}, kind=kind, records=records,
                                                        rank_id=rank_id)
        if kind in PERIODIC_KINDS.values() and len(distribution) > 1:
            raise Unmodelled('a periodic amount is rolled once per aura (AuraEffect::CalculateAmount) and its ticks '
                             'share it, so its ticks are not independent hits')
        events = len(indexes)
    used = applicable(modifiers, kind)
    dealt = done(distribution, used)
    if percent_part is not None:
        if kind != 'heal':
            raise Unmodelled(f'a percent of maximum health term adds to a heal, not to a {kind} hit')
        dealt = summed(dealt, done({int(percent_part): 1.0}, used))
        tooltip_mean += percent_part
    if weapon_part is not None:
        weapon_distribution, weapon_mean, weapon_texts = weapon_part
        dealt = summed(dealt, done(weapon_distribution, used))
        tooltip_mean += weapon_mean
        texts = texts + weapon_texts
    received = taken_by(taken, kind)
    if received:
        dealt = done(dealt, received)
    mean, sigma = moments(mitigated(dealt, mitigation))
    return HitModel(kind=kind, mean=mean, sigma=sigma, tooltip_mean=tooltip_mean,
                    hits_per_cast=ticks if kind in TICKING_KINDS else events, modifiers=used + received,
                    displayed=tuple(texts))


def expected_melee(caster: CasterStats, weapon: WeaponProfile | None, mitigation: MitigationModel,
                   modifiers: Sequence[Modifier] = ()) -> HitModel:
    if weapon is None:
        raise Unmodelled('melee needs the weapon stats of the class file')
    bonus = caster.ap / ATTACK_POWER_PER_DPS * weapon.speed_ms / 1000
    roll = uniform(math.floor(weapon.min_damage + bonus), math.floor(weapon.max_damage + bonus))
    used = applicable(modifiers, 'melee')
    mean, sigma = moments(mitigated(done(roll, used), mitigation))
    return HitModel(kind='melee', mean=mean, sigma=sigma,
                    tooltip_mean=(weapon.min_damage + weapon.max_damage) / 2 + bonus, modifiers=used,
                    displayed=(f'weapon {weapon.item}',))


def casts_needed(model: HitModel) -> int:
    if model.mean <= 0:
        raise ValueError(f'A {model.kind} hit with mean {model.mean} cannot be measured')
    hits = max(1, math.ceil((Z_99 * model.sigma / (MEAN_HALF_WIDTH * model.mean)) ** 2))
    return math.ceil(hits / model.hits_per_cast)


def scheduled_casts(needed: int) -> int:
    return math.ceil(needed * EXCLUDED_OUTCOME_MARGIN)


def floored_casts(class_file: dict, rank_id: int, casts: int) -> int:
    entry = next((entry for entry in class_file.get('hit_casts', []) if entry['spell'] == rank_id), None)
    if entry is None:
        return casts
    if int(entry['casts']) < 1:
        raise ValueError(f'{rank_id} hit_casts floor {entry["casts"]} must be at least one cast')
    return max(casts, int(entry['casts']))


def effect_points(records: Records, spell_id: int, effect: int, level: int) -> int:
    def spell(name: str):
        return records.field('Spell', spell_id, name)

    points = spell(f'EffectBasePoints[{effect}]')
    per_level = spell(f'EffectRealPointsPerLevel[{effect}]')
    if per_level:
        max_level, base_level = spell('MaxLevel'), spell('BaseLevel')
        if max_level > 0 and level > max_level:
            level = max_level
        elif level < base_level:
            level = base_level
        level -= max(base_level, spell('SpellLevel'))
        points += int(float32(level * float32(per_level)))
    sides = spell(f'EffectDieSides[{effect}]')
    if sides > 1:
        raise Unmodelled(f'modifier {spell_id} effect {effect} rolls {sides} sides')
    return points + sides


def aura_modifiers(records: Records, aura_ids: Sequence[int], level: int) -> tuple[Modifier, ...]:
    modifiers = []
    for spell_id in aura_ids:
        for effect in EFFECTS:
            aura = records.field('Spell', spell_id, f'EffectApplyAuraName[{effect}]')
            if records.field('Spell', spell_id, f'Effect[{effect}]') != APPLY_AURA or aura not in MODIFIER_AURAS:
                continue
            percent = effect_points(records, spell_id, effect, level)
            if percent:
                modifiers.append(Modifier(spell_id=spell_id, effect_index=effect, aura=aura, percent=percent,
                                          applies_to=MODIFIER_AURAS[aura],
                                          school_mask=records.field('Spell', spell_id, f'EffectMiscValue[{effect}]')))
    return tuple(modifiers)


def taken_modifiers(records: Records, aura_ids: Sequence[int], level: int, hit_spell: int) -> tuple[Modifier, ...]:
    def spell(spell_id: int, name: str) -> int:
        return int(records.field('Spell', spell_id, name) or 0)

    family = spell(hit_spell, 'SpellFamilyName')
    flags = [spell(hit_spell, f'SpellFamilyFlags[{word}]') for word in range(CLASS_MASK_WORDS)]
    school = spell(hit_spell, 'SchoolMask')
    modifiers = []
    for spell_id in aura_ids:
        aura_family = spell(spell_id, 'SpellFamilyName')
        for effect in EFFECTS:
            if (spell(spell_id, f'Effect[{effect}]') != APPLY_AURA
                    or spell(spell_id, f'EffectApplyAuraName[{effect}]') != MOD_DAMAGE_FROM_CASTER):
                continue
            mask = [spell(spell_id, f'EffectSpellClassMask[{effect * CLASS_MASK_WORDS + word}]')
                    for word in range(CLASS_MASK_WORDS)]
            schools = spell(spell_id, f'EffectMiscValue[{effect}]')
            if schools and not schools & school:
                continue
            if aura_family and (aura_family != family or (any(mask) and not any(
                    word & flag for word, flag in zip(mask, flags)))):
                continue
            percent = effect_points(records, spell_id, effect, level)
            if percent:
                modifiers.append(Modifier(spell_id=spell_id, effect_index=effect, aura=MOD_DAMAGE_FROM_CASTER,
                                          percent=percent, applies_to=DAMAGE_TAKEN, school_mask=schools))
    return tuple(modifiers)


def for_school(modifiers: Sequence[Modifier], school_mask: int) -> tuple[Modifier, ...]:
    return tuple(modifier for modifier in modifiers
                 if modifier.applies_to != 'damage' or modifier.school_mask & school_mask)


def records_of(class_file: dict) -> Records:
    return Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))


def armor_facts(records: Records, spell_id: int, effect: int, periodic: bool) -> ArmorFacts:
    table = custom_attributes()
    if table.unreadable:
        raise Unmodelled(f'{CUSTOM_ATTR_TABLE} is unreadable ({table.unreadable}), so whether armor reduces '
                         f'{spell_id} cannot be read')

    def spell(name: str) -> int:
        return int(records.field('Spell', spell_id, name) or 0)

    mechanic, effect_mechanic = spell('Mechanic'), spell(f'EffectMechanic[{effect}]')
    effect_type = spell(f'Effect[{effect}]')
    mask = (1 << mechanic if mechanic else 0) | (1 << effect_mechanic if effect_type and effect_mechanic else 0)
    return ArmorFacts(custom_attributes=table.of(spell_id), attributes_ex4=spell('AttributesEx4'), periodic=periodic,
                      effect=effect_type, aura=spell(f'EffectApplyAuraName[{effect}]'), mechanic_mask=mask)


def mitigation_for(school_mask: int, target: TargetProfile, level: int,
                   spell: ArmorFacts | None = None) -> MitigationModel:
    try:
        return expected_mitigation(school_mask, target, level, spell=spell)
    except ValueError as error:
        raise Unmodelled(str(error)) from error


def spell_mitigation(records: Records, spell_id: int, effect: int, kind: str, target: TargetProfile,
                     level: int) -> MitigationModel:
    school_mask = records.field('Spell', spell_id, 'SchoolMask')
    facts = (armor_facts(records, spell_id, effect, kind in PERIODIC_KINDS.values())
             if school_mask & PHYSICAL_SCHOOL_MASK else None)
    return mitigation_for(school_mask, target, level, facts)


@dataclass(frozen=True)
class RankHit:
    model: HitModel
    readout: Readout
    facts: RankFacts
    school_mask: int
    indexes: list[int]
    duration_ms: int
    hit_spell: int


def triggered_spells(records: Records, rank_id: int, facts: RankFacts) -> dict[int, Triggered]:
    triggered = {}
    for effect in EFFECTS:
        if facts.effects[effect] != APPLY_AURA or facts.aura_names[effect] != PERIODIC_TRIGGER_SPELL:
            continue
        spell_id = records.field('Spell', rank_id, f'EffectTriggerSpell[{effect}]')
        if spell_id and records.has_spell(spell_id):
            trigger = facts_of(records, spell_id)
            triggered[effect] = Triggered(spell_id, trigger.effects, trigger.aura_names)
    return triggered


def periodic_tick_readout(records: Records, rank_id: int, caster: CasterStats, readout: Readout,
                          effect: int) -> Readout:
    values = []
    for value in readout.values:
        if value.effect_index == effect:
            try:
                reading = period_reading(records, rank_id, caster, value, effect)
                if reading == OVER_TICKS:
                    value = replace(value, value=value.value * records.amplitude_ms(rank_id, effect)
                                    / records.duration_ms(rank_id))
            except Unreadable as error:
                raise Unmodelled(error.reason or f'{value.text} is unreadable with a scaled period') from error
            if reading == MIXED_PERIOD:
                raise Unmodelled(mixed_period_reason(value.text, effect))
        values.append(value)
    return Readout(values, readout.unreadable)


def periodic_ticks(records: Records, rank_id: int, effect: int) -> tuple[int, int]:
    amplitude = records.field('Spell', rank_id, f'EffectAmplitude[{effect}]')
    try:
        duration = int(records.duration_ms(rank_id))
    except Unreadable as error:
        raise Unmodelled(f'duration of spell {rank_id} is unreadable {error.reason}'.rstrip()) from error
    if amplitude <= 0 or duration < amplitude:
        raise Unmodelled(f'periodic effect {effect} ticks {amplitude} ms over {duration} ms')
    return duration // amplitude, duration


def learned_weapon_part(readout: Readout, effects: Sequence[int], caster: CasterStats,
                        weapon: WeaponProfile | None, learned: int) -> tuple[Distribution, float, list[str]]:
    weapon_effects = [index for index, effect in enumerate(effects) if effect in WEAPON_EFFECTS]
    if [effects[index] for index in weapon_effects] != [WEAPON_PERCENT_DAMAGE]:
        raise Unmodelled(f'{learned} adds a weapon part only to one weapon percent effect, not {weapon_effects}')
    shown = [value for value in readout.values if value.spell_id == learned and value.kind == 'percent']
    if len(shown) != 1:
        raise Unmodelled(f'the tooltip shows {len(shown)} weapon percents of {learned}, not one')
    remapped = Readout([replace(shown[0], effect_index=weapon_effects[0])], readout.unreadable)
    return weapon_hit(remapped, effects, caster, weapon)


def rank_hit(class_file: dict, rank_id: int, caster: CasterStats, target: TargetProfile,
             auras: Sequence[int], learned: int | None = None, check: str = 'hit_mean',
             flat: Mapping[int, float] | None = None, percent_part: float | None = None) -> RankHit:
    records = records_of(class_file)
    if learned is not None:
        caster = replace(caster, known_spells=caster.known_spells | {learned})
    facts = facts_of(records, rank_id)
    if facts.passive:
        raise Unmodelled(NEVER_CAST)
    unfit = unfit_reason(class_file.get('weapon'), equip_requirement(records, rank_id, class_file))
    if unfit:
        raise Unmodelled(unfit)
    triggered = triggered_spells(records, rank_id, facts)
    full_readout = read_tooltip(records.dbc, rank_id, caster)
    readout = full_readout if learned is None else Readout(
        [value for value in full_readout.values if value.spell_id != learned], full_readout.unreadable)
    composite = None
    if rank_id in class_file.get('weapon_school_hits', ()):
        if learned is not None:
            raise Unmodelled(f'{rank_id} is a weapon and school hit, which takes no learned weapon part')
        readout = with_literal_weapon_percent(class_file, records, rank_id, facts.effects, readout)
        readout, composite = script_weapon_part(readout, facts.effects, weapon_attacker(records, rank_id, caster),
                                                weapon_profile(class_file))
        if composite is None:
            raise Unmodelled(f'{rank_id} is listed as a weapon and school hit, but its tooltip shows no weapon value')
    chosen = rank_hit_effect(class_file, rank_id, check)
    if chosen is not None:
        readout = effect_only(readout, chosen)
    kind, indexes = hit_kind(facts.effects, facts.aura_names, triggered, readout)
    if chosen is not None:
        checked_role(rank_id, check, chosen, kind, indexes)
    if learned is not None and kind != 'school':
        raise Unmodelled(f'{learned} adds a weapon part to a school hit, not to a {kind} hit')
    hit_spell = triggered[indexes[0]].spell_id if kind == TRIGGERED_WEAPON else rank_id
    school_mask = records.field('Spell', hit_spell, 'SchoolMask')
    ticks, duration = periodic_ticks(records, rank_id, indexes[0]) if kind in TICKING_KINDS else (1, 0)
    hit_effect = 0 if kind == TRIGGERED_WEAPON else indexes[0]
    unresisted = rank_id in class_file.get(UNRESISTED_RANK_HITS, ())
    if unresisted and school_mask & PHYSICAL_SCHOOL_MASK:
        raise Unmodelled(f'{rank_id} is listed in {UNRESISTED_RANK_HITS}, but its hit school mask {school_mask} '
                         f'is physical, which armor reduces, not resistance')
    mitigation = NO_MITIGATION if kind in HEAL_KINDS or unresisted else spell_mitigation(
        records, hit_spell, hit_effect, kind, target, caster.level)
    shown = readout
    if kind in PERIODIC_KINDS.values():
        shown = periodic_tick_readout(records, rank_id, caster, readout, indexes[0])
    modifiers = for_school(aura_modifiers(records, auras, class_file['level']), school_mask)
    rolls = {} if kind in WEAPON_KINDS else rolled_values(records, rank_id, caster, shown, indexes)
    for index, amount in (flat or {}).items():
        if index not in rolls:
            raise Unmodelled(f'the block value term of {rank_id} effect {index} needs its rolled values')
        rolls[index] = tuple(value + amount for value in rolls[index])
    percent_before_flat = rank_id in class_file.get('weapon_percent_before_flat', ())
    attacker = weapon_attacker(records, hit_spell, caster)
    weapon_part = composite if learned is None else learned_weapon_part(full_readout, facts.effects, attacker,
                                                                        weapon_profile(class_file), learned)
    model = expected_hit(shown, facts.effects, attacker, weapon_profile(class_file), mitigation,
                         aura_names=facts.aura_names, modifiers=modifiers, ticks=ticks, rolls=rolls,
                         triggered=triggered, records=records, rank_id=rank_id,
                         percent_before_flat=percent_before_flat, weapon_part=weapon_part,
                         percent_part=percent_part)
    losses = {index: loss for index in indexes
              if kind in SCRIPT_HIT_KINDS and (loss := per_level_fraction(records, rank_id, index, caster.level))}
    if losses:
        try:
            engine = expected_hit(shown, facts.effects, attacker, weapon_profile(class_file), mitigation,
                                  aura_names=facts.aura_names, modifiers=modifiers, ticks=ticks,
                                  rolls=engine_rolls(shown, indexes, rolls, losses), triggered=triggered,
                                  records=records, rank_id=rank_id, percent_before_flat=percent_before_flat,
                                  weapon_part=weapon_part, percent_part=percent_part)
        except Unmodelled:
            return RankHit(model, readout, facts, school_mask, indexes, duration, hit_spell)
        terms = ', '.join(f'effect {index} loses {loss:.6g}' for index, loss in losses.items())
        model = replace(model, engine=replace(engine, displayed=model.displayed),
                        engine_rule=f'{PER_LEVEL_ENGINE_RULE}: {terms}')
    return RankHit(model, readout, facts, school_mask, indexes, duration, hit_spell)


def ranged_weapon_attack(records: Records, spell_id: int) -> bool:
    if records.field('Spell', spell_id, 'DmgClass') != RANGED_DAMAGE_CLASS:
        return False
    return ranged_weapon_spell({name: records.field('Spell', spell_id, name) for name in WEAPON_REQUIREMENT_FIELDS})


def weapon_attacker(records: Records, spell_id: int, caster: CasterStats) -> CasterStats:
    return replace(caster, ap=caster.rap) if ranged_weapon_attack(records, spell_id) else caster


def reference_caster(class_file: dict) -> CasterStats:
    return caster_stats_from(class_file['reference_stats'], class_file)


def reference_hit_model(class_file: dict, rank_id: int, check: str = 'hit_mean') -> HitModel:
    class_file = armed_for(class_file, records_of(class_file), rank_id)
    return rank_hit(class_file, rank_id, reference_caster(class_file), REFERENCE_TARGET,
                    class_file.get('known_auras', []), check=check).model


def melee_model(class_file: dict, caster: CasterStats, target: TargetProfile, auras: Sequence[int]) -> HitModel:
    records = records_of(class_file)
    modifiers = for_school(aura_modifiers(records, auras, class_file['level']), PHYSICAL_SCHOOL_MASK)
    return expected_melee(caster, weapon_profile(class_file),
                          mitigation_for(PHYSICAL_SCHOOL_MASK, target, caster.level), modifiers)


def reference_melee_model(class_file: dict) -> HitModel:
    return melee_model(class_file, reference_caster(class_file), REFERENCE_TARGET, class_file.get('known_auras', []))


def resistance_label(school: int) -> str:
    return f'target resistance {school}'


def magic_schools(school_mask: int) -> list[int]:
    return [school for school in MAGIC_SCHOOLS if school_mask & (1 << school)]


SCRIPT_HIT_KINDS = frozenset({'school', 'heal'})
PER_LEVEL_ENGINE_RULE = 'known engine rounding, per-level term truncated before the sum (SpellInfo.cpp:497)'


def calc_value_term(records: Records, spell_id: int, effect: int, level: int) -> float:
    rate = float32(float(records.field('Spell', spell_id, f'EffectRealPointsPerLevel[{effect}]') or 0))
    if not rate:
        return 0.0
    base_level, spell_level, max_level = (int(records.field('Spell', spell_id, name) or 0)
                                          for name in ('BaseLevel', 'SpellLevel', 'MaxLevel'))
    if max_level > 0 and level > max_level:
        level = max_level
    elif level < base_level:
        level = base_level
    return float32((level - max(base_level, spell_level)) * rate)


def per_level_fraction(records: Records, spell_id: int, effect: int, level: int) -> float:
    term = calc_value_term(records, spell_id, effect, level)
    return term - math.trunc(term)


def engine_rolls(readout: Readout, indexes: Sequence[int], rolls: Mapping[int, Sequence[float]],
                 losses: Mapping[int, float]) -> dict[int, tuple[float, ...]]:
    engine = {}
    for index in indexes:
        values = rolls.get(index)
        if values is None:
            low, high, _ = value_range(readout, index)
            values = tuple(low + step for step in range(int(high - low) + 1))
        engine[index] = tuple(float32(value - losses.get(index, 0.0)) for value in values)
    return engine


def with_literal_weapon_percent(class_file: dict, records: Records, rank_id: int, effects: Sequence[int],
                                readout: Readout) -> Readout:
    entry = class_file.get(WEAPON_SCHOOL_PERCENTS, {}).get(str(rank_id))
    if entry is None:
        return readout
    percent, source = entry.get('percent'), entry.get('source')
    if not isinstance(percent, int) or isinstance(percent, bool) or percent <= 0:
        raise Unmodelled(f'{WEAPON_SCHOOL_PERCENTS} of {rank_id} needs a positive whole percent, not {percent!r}')
    weapon_effects = [index for index, effect in enumerate(effects) if effect == WEAPON_PERCENT_DAMAGE]
    if len(weapon_effects) != 1:
        raise Unmodelled(f'{WEAPON_SCHOOL_PERCENTS} of {rank_id} needs one weapon percent effect, not {weapon_effects}')
    if any(value.effect_index == weapon_effects[0] for value in readout.values):
        raise Unmodelled(f'{rank_id} shows its weapon percent as a token, so {WEAPON_SCHOOL_PERCENTS} cannot supply it')
    streamed = streamed_texts().get(rank_id)
    if streamed is None or streamed.file != source:
        raise Unmodelled(f'{WEAPON_SCHOOL_PERCENTS} source {source!r} of {rank_id} is not the streamed text row that '
                         f'the tooltip reads ({streamed.file if streamed else "none"})')
    literal = f'{percent}%'
    description = records.field('Spell', rank_id, 'Description[enUS]') or ''
    if description != streamed.description or not re.search(rf'(?<![\d.$]){re.escape(literal)}', description):
        raise Unmodelled(f'the streamed text of {rank_id} in {source} shows no literal {literal}')
    shown = Displayed(literal, float(percent), weapon_effects[0], 'percent', rank_id)
    return Readout([*readout.values, shown], readout.unreadable)


def script_weapon_part(readout: Readout, effects: Sequence[int], caster: CasterStats,
                       weapon: WeaponProfile | None) -> tuple[Readout, tuple[Distribution, float, list[str]] | None]:
    weapon_effects = [index for index, effect in enumerate(effects) if effect in WEAPON_EFFECTS]
    shown = [value for value in readout.values if value.effect_index in weapon_effects]
    if not shown:
        return readout, None
    if ([effects[index] for index in weapon_effects] != [WEAPON_PERCENT_DAMAGE]
            or SCHOOL_DAMAGE not in effects):
        raise Unmodelled(f'a script-cast weapon part needs one school damage effect and one weapon percent effect, '
                         f'not effects {list(effects)}')
    school = Readout([value for value in readout.values if value.effect_index not in weapon_effects],
                     readout.unreadable)
    return school, weapon_hit(Readout(shown, readout.unreadable), effects, caster, weapon)


def value_readout(readout: Readout, effects: Sequence[int], value_effect: int) -> Readout:
    if SCHOOL_DAMAGE not in effects:
        raise Unmodelled(f'a value read from another spell needs a school damage effect, not effects {list(effects)}')
    target = list(effects).index(SCHOOL_DAMAGE)
    return Readout([replace(value, effect_index=target) for value in readout.values
                    if value.effect_index == value_effect], readout.unreadable)


def script_weapon_only_model(class_file: dict, records: Records, facts: RankFacts, hit_spell: int, readout: Readout,
                             caster: CasterStats, target: TargetProfile, auras: Sequence[int]) -> HitModel:
    weapon_effects = [index for index, effect in enumerate(facts.effects) if effect in WEAPON_EFFECTS]
    if [facts.effects[index] for index in weapon_effects] != [WEAPON_PERCENT_DAMAGE] or SCHOOL_DAMAGE in facts.effects:
        raise Unmodelled(f'a weapon-only script hit needs one weapon percent effect and no school damage effect, not '
                         f'effects {list(facts.effects)}')
    shown = Readout([value for value in readout.values if value.effect_index in weapon_effects], readout.unreadable)
    if not shown.values:
        raise Unmodelled(f'script-cast spell {hit_spell} shows no weapon percent value')
    mitigation = spell_mitigation(records, hit_spell, weapon_effects[0], 'weapon', target, caster.level)
    modifiers = for_school(aura_modifiers(records, auras, class_file['level']),
                           records.field('Spell', hit_spell, 'SchoolMask'))
    return expected_hit(shown, facts.effects, weapon_attacker(records, hit_spell, caster), weapon_profile(class_file),
                        mitigation, aura_names=facts.aura_names, modifiers=modifiers, records=records,
                        rank_id=hit_spell)


OFF_HAND_DAMAGE_FACTOR = 0.5


def effective_school_mask(school_mask: int) -> int:
    if school_mask & PHYSICAL_SCHOOL_MASK and school_mask & ~PHYSICAL_SCHOOL_MASK:
        return school_mask & ~PHYSICAL_SCHOOL_MASK
    return school_mask


def resisted_within_armor(distribution: Distribution, resist_shares: Sequence[float],
                          armor_kept: float) -> Distribution:
    result: Distribution = {}
    for value, share in distribution.items():
        armor_cut = value - math.ceil(float32(value * armor_kept))
        for step, step_share in enumerate(resist_shares):
            if step_share > 0:
                kept = value - min(value * step // 10, armor_cut)
                result[kept] = result.get(kept, 0.0) + share * step_share
    return result


def script_normalized_value_model(class_file: dict, records: Records, facts: RankFacts, hit_spell: int,
                                  readout: Readout, value_effect: int, caster: CasterStats, target: TargetProfile,
                                  auras: Sequence[int], unresisted: bool, effective_school: bool = False) -> HitModel:
    weapon_effects = [effect for effect in facts.effects if effect in WEAPON_EFFECTS]
    if weapon_effects != [NORMALIZED_WEAPON_DMG] or SCHOOL_DAMAGE in facts.effects:
        raise Unmodelled(f'a normalized value hit needs one normalized weapon damage effect and no school damage '
                         f'effect, not effects {list(facts.effects)}')
    raw_mask = records.field('Spell', hit_spell, 'SchoolMask')
    school_mask = effective_school_mask(raw_mask)
    mixed = school_mask != raw_mask
    if mixed != effective_school:
        raise Unmodelled(f'{hit_spell} has the school mask {raw_mask}, loaded as {school_mask}: effective_school is '
                         f'{"required" if mixed else "only"} for a mask that mixes physical and magic schools')
    physical = bool(school_mask & PHYSICAL_SCHOOL_MASK)
    requirement = weapon_requirement(records, hit_spell, class_file)
    off_hand = attack_hand(requirement) == OFF_HAND
    if off_hand and not physical and not mixed:
        raise Unmodelled(f'the off-hand factor of a non-physical weapon strike ({hit_spell}, school mask '
                         f'{school_mask}) is not settled')
    weapon = weapon_profile(armed(class_file, requirement, hit_spell))
    if weapon is None:
        raise Unmodelled(f'{hit_spell} needs the weapon stats of its hand')
    points, texts = fixed_value(readout, value_effect, 'flat')
    factor = OFF_HAND_DAMAGE_FACTOR if off_hand and physical else 1.0
    bonus = weapon_attacker(records, hit_spell, caster).ap / ATTACK_POWER_PER_DPS * weapon.normalized_speed
    passed = int(float32(points * factor)) if physical else int(points)
    roll = uniform(int(float32((weapon.min_damage + bonus) * factor)), int(float32((weapon.max_damage + bonus) * factor)))
    used = applicable(for_school(aura_modifiers(records, auras, class_file['level']), school_mask), 'weapon')
    hit = done(mapped(roll, lambda damage: damage + passed), used)
    if unresisted and not physical:
        landed = hit
    elif mixed:
        landed = resisted_within_armor(hit, mitigation_for(school_mask, target, caster.level).resist_shares,
                                       float32(1.0 - armor_reduction(target.armor, caster.level, target.level)))
    else:
        landed = mitigated(hit, spell_mitigation(records, hit_spell, facts.effects.index(NORMALIZED_WEAPON_DMG),
                                                 'weapon', target, caster.level))
    mean, sigma = moments(landed)
    hand = 'off-hand' if off_hand else 'main-hand'
    loaded = (f'school mask {raw_mask} loaded as {school_mask}, resistance within armor',) if mixed else ()
    return HitModel(kind='weapon', mean=mean, sigma=sigma,
                    tooltip_mean=factor * ((weapon.min_damage + weapon.max_damage) / 2 + bonus) + passed,
                    modifiers=used, displayed=(*ordered(readout, texts), f'{hand} weapon {weapon.item}', *loaded))


STATED_HANDS = {'off': OFF_HAND}


def stated_hand_requirement(requirement: Mapping[str, int], hand: str | None) -> Mapping[str, int]:
    if hand is None:
        return requirement
    if hand not in STATED_HANDS:
        raise Unmodelled(f'a stated hand is one of {sorted(STATED_HANDS)}, not {hand!r}')
    return {**requirement, 'AttributesEx3': requirement.get('AttributesEx3', 0) | REQUIRES_OFF_HAND_ATTRIBUTE_EX3}


def flat_effect_points(records: Records, hit_spell: int, effect: int) -> int:
    if records.field('Spell', hit_spell, f'EffectDieSides[{effect}]') != 1 \
            or records.field('Spell', hit_spell, f'EffectRealPointsPerLevel[{effect}]') != 0:
        raise Unmodelled(f'{hit_spell} normalized weapon damage effect {effect} needs one die side and no points per '
                         f'level')
    return records.field('Spell', hit_spell, f'EffectBasePoints[{effect}]') + 1


def script_flat_then_percent_model(class_file: dict, records: Records, facts: RankFacts, hit_spell: int,
                                   readout: Readout, caster: CasterStats, target: TargetProfile,
                                   auras: Sequence[int], hand: str | None) -> HitModel:
    flat_effect, percent_effect = [index for index, effect in enumerate(facts.effects) if effect in WEAPON_EFFECTS]
    school_mask = records.field('Spell', hit_spell, 'SchoolMask')
    if not school_mask & PHYSICAL_SCHOOL_MASK or school_mask & ~PHYSICAL_SCHOOL_MASK:
        raise Unmodelled(f'{hit_spell} normalized weapon damage then weapon percent hit is read for a physical school '
                         f'only, not mask {school_mask}')
    requirement = stated_hand_requirement(weapon_requirement(records, hit_spell, class_file), hand)
    off_hand = attack_hand(requirement) == OFF_HAND
    weapon = weapon_profile(armed(class_file, requirement, hit_spell))
    if weapon is None:
        raise Unmodelled(f'{hit_spell} needs the weapon stats of its hand')
    flat = flat_effect_points(records, hit_spell, flat_effect)
    percent, texts = fixed_value(readout, percent_effect, 'percent')
    factor = OFF_HAND_DAMAGE_FACTOR if off_hand else 1.0
    bonus = weapon_attacker(records, hit_spell, caster).ap / ATTACK_POWER_PER_DPS * weapon.normalized_speed
    passed = int(float32(flat * factor))
    roll = uniform(int(float32((weapon.min_damage + bonus) * factor)),
                   int(float32((weapon.max_damage + bonus) * factor)))
    used = applicable(for_school(aura_modifiers(records, auras, class_file['level']), school_mask), 'weapon')
    hit = done(mapped(roll, lambda damage: int(float32((damage + passed) * percent / 100.0))), used)
    landed = mitigated(hit, spell_mitigation(records, hit_spell, percent_effect, 'weapon', target, caster.level))
    mean, sigma = moments(landed)
    side = 'off-hand' if off_hand else 'main-hand'
    stated = (f'{side} stated by the tooltip',) if hand is not None else ()
    return HitModel(kind='weapon', mean=mean, sigma=sigma,
                    tooltip_mean=(factor * ((weapon.min_damage + weapon.max_damage) / 2 + bonus) + passed)
                    * percent / 100.0,
                    modifiers=used, displayed=(*ordered(readout, texts), f'effect {flat_effect} flat {flat}',
                                                f'{side} weapon {weapon.item}', *stated))


def script_normalized_percent_model(class_file: dict, records: Records, facts: RankFacts, hit_spell: int,
                                    readout: Readout, caster: CasterStats, target: TargetProfile,
                                    auras: Sequence[int], hand: str | None = None) -> HitModel:
    weapon_effects = [index for index, effect in enumerate(facts.effects) if effect in WEAPON_EFFECTS]
    kinds = [facts.effects[index] for index in weapon_effects]
    if kinds == [NORMALIZED_WEAPON_DMG, WEAPON_PERCENT_DAMAGE] and SCHOOL_DAMAGE not in facts.effects:
        return script_flat_then_percent_model(class_file, records, facts, hit_spell, readout, caster, target, auras,
                                              hand)
    if hand is not None:
        raise Unmodelled(f'a stated hand of {hit_spell} is read for a normalized weapon damage effect followed by a '
                         f'weapon percent effect only')
    if kinds != [WEAPON_PERCENT_DAMAGE, NORMALIZED_WEAPON_DMG] or SCHOOL_DAMAGE in facts.effects:
        raise Unmodelled(f'a normalized weapon percent hit needs a weapon percent effect then a normalized weapon '
                         f'damage effect and no school damage effect, not effects {list(facts.effects)}')
    percent_effect, flat_effect = weapon_effects
    if records.field('Spell', hit_spell, f'EffectBasePoints[{flat_effect}]') + 1 != 0:
        raise Unmodelled(f'{hit_spell} normalized weapon damage effect {flat_effect} adds a flat value')
    school_mask = records.field('Spell', hit_spell, 'SchoolMask')
    if not school_mask & PHYSICAL_SCHOOL_MASK or school_mask & ~PHYSICAL_SCHOOL_MASK:
        raise Unmodelled(f'{hit_spell} normalized weapon percent hit is read for a physical school only, not mask '
                         f'{school_mask}')
    requirement = weapon_requirement(records, hit_spell, class_file)
    if attack_hand(requirement) == OFF_HAND:
        raise Unmodelled(f'{hit_spell} normalized weapon percent hit is read for the main hand only')
    weapon = weapon_profile(armed(class_file, requirement, hit_spell))
    if weapon is None:
        raise Unmodelled(f'{hit_spell} needs the weapon stats of its hand')
    percent, texts = fixed_value(readout, percent_effect, 'percent')
    bonus = weapon_attacker(records, hit_spell, caster).ap / ATTACK_POWER_PER_DPS * weapon.normalized_speed
    roll = uniform(int(float32(weapon.min_damage + bonus)), int(float32(weapon.max_damage + bonus)))
    used = applicable(for_school(aura_modifiers(records, auras, class_file['level']), school_mask), 'weapon')
    hit = done(mapped(roll, lambda damage: int(float32(damage * percent / 100.0))), used)
    landed = mitigated(hit, spell_mitigation(records, hit_spell, percent_effect, 'weapon', target, caster.level))
    mean, sigma = moments(landed)
    return HitModel(kind='weapon', mean=mean, sigma=sigma,
                    tooltip_mean=((weapon.min_damage + weapon.max_damage) / 2 + bonus) * percent / 100.0,
                    modifiers=used, displayed=(*ordered(readout, texts), f'main-hand weapon {weapon.item}'))


def script_hit_model(class_file: dict, tooltip_spell: int, hit_spell: int, caster: CasterStats,
                     target: TargetProfile, auras: Sequence[int], value_spell: int | None = None,
                     value_effect: int = 0, unresisted: bool = False, hit_effect: int | None = None,
                     weapon_only: bool = False, normalized_value: bool = False,
                     effective_school: bool = False, normalized_percent: bool = False,
                     value_rolls: bool = False, taken_auras: Sequence[int] = (),
                     level_points: bool = False, hand: str | None = None) -> HitModel:
    records = records_of(class_file)
    facts = facts_of(records, hit_spell)
    from tooltip_corrections import tooltip_readout
    readout = triggered_readout(tooltip_readout(class_file, records, tooltip_spell, caster), value_spell or hit_spell)
    if hit_effect is not None:
        readout = replace(readout, values=[value for value in readout.values if value.effect_index == hit_effect])
    if level_points and (normalized_percent or normalized_value or weapon_only or value_spell is not None):
        raise Unmodelled(f'level_points of {hit_spell} reads the points of its own school or heal effect only')
    if normalized_percent:
        if not weapon_only or normalized_value or effective_school or value_spell is not None or unresisted:
            raise Unmodelled(f'a normalized percent hit of {hit_spell} is weapon-only with no value spell, no '
                             f'unresisted read and no normalized value')
        return script_normalized_percent_model(class_file, records, facts, hit_spell, readout, caster, target, auras,
                                               hand)
    if hand is not None:
        raise Unmodelled(f'a stated hand of {hit_spell} is a part of a normalized percent hit')
    if normalized_value:
        if value_spell is None or weapon_only:
            raise Unmodelled(f'a normalized value hit of {hit_spell} reads its points from a value spell, and is not '
                             f'weapon-only')
        return script_normalized_value_model(class_file, records, facts, hit_spell, readout, value_effect, caster,
                                             target, auras, unresisted, effective_school)
    if effective_school:
        raise Unmodelled(f'effective_school of {hit_spell} is a part of a normalized value hit')
    if value_rolls and value_spell is None:
        raise Unmodelled(f'value_rolls of {hit_spell} rolls the die of a value spell, and none is set')
    if value_spell is not None:
        readout = value_readout(readout, facts.effects, value_effect)
    if weapon_only:
        if value_spell is not None or unresisted:
            raise Unmodelled(f'a weapon-only script hit of {hit_spell} takes no value spell and no unresisted read')
        return script_weapon_only_model(class_file, records, facts, hit_spell, readout, caster, target, auras)
    readout, weapon_part = script_weapon_part(readout, facts.effects, caster, weapon_profile(class_file))
    kind, indexes = hit_kind(facts.effects, facts.aura_names, None, readout)
    if kind not in SCRIPT_HIT_KINDS:
        raise Unmodelled(f'script-cast spell {hit_spell} is a {kind} hit, not one direct damage or heal effect')
    school_mask = records.field('Spell', hit_spell, 'SchoolMask')
    mitigation = NO_MITIGATION if kind in HEAL_KINDS or unresisted else spell_mitigation(records, hit_spell,
                                                                                          indexes[0], kind, target,
                                                                                          caster.level)
    modifiers = for_school(aura_modifiers(records, auras, class_file['level']), school_mask)
    taken = taken_modifiers(records, taken_auras, class_file['level'], hit_spell)
    if level_points and weapon_part is not None:
        raise Unmodelled(f'level_points of {hit_spell} reads the points of its own school or heal effect only')
    rolls = rolled_values(records, hit_spell, caster, readout, indexes, tooltip_spell=tooltip_spell,
                          value_source=(value_spell, value_effect) if value_rolls else None,
                          level_points=level_points)
    if level_points and any(index not in rolls for index in indexes):
        raise Unmodelled(f'level_points of {hit_spell} needs one shown token for each effect it reads')
    model = expected_hit(readout, facts.effects, caster, None, mitigation, aura_names=facts.aura_names,
                         modifiers=modifiers, rolls=rolls, records=records, rank_id=hit_spell, weapon_part=weapon_part,
                         taken=taken)
    losses = {index: loss for index in indexes
              if (loss := per_level_fraction(records, hit_spell, index, caster.level))}
    if not losses:
        return model
    engine = expected_hit(readout, facts.effects, caster, None, mitigation, aura_names=facts.aura_names,
                          modifiers=modifiers, rolls=engine_rolls(readout, indexes, rolls, losses), records=records,
                          rank_id=hit_spell, weapon_part=weapon_part, taken=taken)
    terms = ', '.join(f'effect {index} loses {loss:.6g}' for index, loss in losses.items())
    return replace(model, engine=replace(engine, displayed=model.displayed),
                   engine_rule=f'{PER_LEVEL_ENGINE_RULE}: {terms}')


def reference_script_hit_model(class_file: dict, tooltip_spell: int, hit_spell: int, value_spell: int | None = None,
                               value_effect: int = 0, model_auras: Sequence[int] = (),
                               unresisted: bool = False, hit_effect: int | None = None,
                               weapon_only: bool = False, normalized_value: bool = False,
                               effective_school: bool = False, normalized_percent: bool = False,
                               value_rolls: bool = False, level_points: bool = False,
                               taken_auras: Sequence[int] = (), hand: str | None = None) -> HitModel:
    return script_hit_model(class_file, tooltip_spell, hit_spell, reference_caster(class_file), REFERENCE_TARGET,
                            [*class_file.get('known_auras', []), *model_auras], value_spell, value_effect, unresisted,
                            hit_effect, weapon_only, normalized_value, effective_school,
                            normalized_percent, value_rolls, taken_auras, level_points, hand=hand)


def measured_hit_model(class_file: dict, expectation: Expectation, measured: Mapping[str, float]) -> HitModel:
    labels = expectation.model['measurements']
    if expectation.model['kind'] != 'melee':
        class_file = armed_for(class_file, records_of(class_file), expectation.rank_id)
    caster = caster_stats_from(measured, class_file)
    target = REFERENCE_TARGET
    if ARMOR_LABEL in labels.values():
        target = TargetProfile(
            entry=DUMMY_ENTRY, level=int(measured[VIEW_LEVEL_LABEL]), armor=int(measured[ARMOR_LABEL]),
            resistances={1 << school: int(measured[resistance_label(school)])
                         for school in magic_schools(expectation.model['school_mask'])})
    auras = [aura for aura in class_file.get('known_auras', []) if measured[known_aura_label(aura)] > 0]
    auras += expectation.model.get('model_auras', [])
    if expectation.model['kind'] == 'melee':
        return melee_model(class_file, caster, target, auras)
    if 'tooltip_spell' in expectation.model:
        scripted = script_hit_model(class_file, expectation.model['tooltip_spell'], expectation.model['hit_spell'],
                                    caster, target, auras, expectation.model.get('value_spell'),
                                    expectation.model.get('value_effect', 0),
                                    expectation.model.get('unresisted', False), expectation.model.get('hit_effect'),
                                    expectation.model.get('weapon_only', False),
                                    expectation.model.get('normalized_value', False),
                                    expectation.model.get('effective_school', False),
                                    expectation.model.get('normalized_percent', False),
                                    expectation.model.get('value_rolls', False),
                                    expectation.model.get('taken_auras', []),
                                    expectation.model.get('level_points', False),
                                    hand=expectation.model.get('hand'))
        factor = expectation.model.get('gate_multiplier', 1.0)
        return scripted if factor == 1.0 else replace(scripted, mean=scripted.mean * factor)
    flat = block_value_terms(class_file, expectation.spell_id, measured)
    percent_part = heal_pct_term(class_file, records_of(class_file), expectation.rank_id, measured)
    role = expectation.check if expectation.check in HIT_ROLES else 'hit_mean'
    model = rank_hit(class_file, expectation.rank_id, caster, target, auras, expectation.model.get('learned'),
                     role, flat=flat, percent_part=percent_part).model
    performed = expectation.model.get('part_casts', 1)
    multiplier = self_stack_multiplier(class_file, expectation.rank_id, performed) \
        * expectation.model.get('gate_multiplier', 1.0)
    return model if multiplier == 1.0 else replace(model, mean=model.mean * multiplier)


def creature_fixture(class_file: dict, distance: float = DUMMY_DISTANCE) -> dict:
    return {'id': TARGET, 'owner': CASTER, 'entry': DUMMY_ENTRY, 'level': class_file['level'],
            'health': DUMMY_HEALTH, 'distance': distance, 'stationary': True}


def target_steps(school_mask: int, unit: str = TARGET) -> tuple[list[dict], dict[str, str]]:
    steps = [measurement(ARMOR_LABEL, unit, 'armor'),
             measurement(VIEW_LEVEL_LABEL, CASTER, 'view_level', target=unit)]
    labels = {'armor': ARMOR_LABEL, 'view_level': VIEW_LEVEL_LABEL}
    for school in magic_schools(school_mask):
        steps.append(measurement(resistance_label(school), unit, 'resistance', school=school))
        labels[f'resistance {school}'] = resistance_label(school)
    return steps, labels


def model_record(model: HitModel, school_mask: int, weapon: WeaponProfile | None, labels: dict[str, str],
                 needed: int) -> dict:
    return {'kind': model.kind, 'school_mask': school_mask, 'weapon': asdict(weapon) if weapon else None,
            'modifiers': [asdict(modifier) for modifier in model.modifiers], 'hits_per_cast': model.hits_per_cast,
            'reference': {'mean': model.mean, 'sigma': model.sigma, 'tooltip_mean': model.tooltip_mean,
                          'casts_needed': casts_needed(model) if model.mean > 0 else None},
            'minimum_hits': needed * model.hits_per_cast, 'scheduled_casts': scheduled_casts(needed),
            'measurements': labels}


def timed(scenario: dict, waited_ms: int, limit_ms: int = MAX_SCENARIO_MS) -> dict:
    if waited_ms + TIMEOUT_MARGIN_MS > limit_ms:
        raise ValueError(f'{scenario["name"]} waits {waited_ms} ms; split its casts over several scenarios')
    scenario['timeout_ms'] = waited_ms + TIMEOUT_MARGIN_MS
    return scenario


def scenario_shell(class_file: dict, name: str, contract: str, steps: list[dict]) -> dict:
    return {'schema': 1, 'name': name, 'contract': contract, 'players': [player_fixture(class_file)],
            'steps': base_steps(class_file) + steps}


def cast_steps(facts: RankFacts, rank_id: int, target: str | None, interval_ms: int, casts: int,
               fixtures: Sequence[dict] = ()) -> list[dict]:
    steps = []
    for _ in range(casts):
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.extend(pay_power_steps(facts.power_type, facts.mana_cost))
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': rank_id})
        steps += required_aura_steps(facts) + [dict(fixture) for fixture in fixtures]
        cast = {'action': 'cast', 'actor': CASTER, 'spell': rank_id}
        if target:
            cast['target'] = target
        steps.append(cast)
        steps.append({'action': 'wait', 'ms': interval_ms})
    return steps


def hit_location(class_file: dict, rank_id: int) -> dict | None:
    entries = [entry for entry in class_file.get(HIT_LOCATION, []) if entry['spell'] == rank_id]
    if len(entries) > 1:
        raise ValueError(f'{rank_id} has {len(entries)} {HIT_LOCATION} entries; one is allowed')
    if not entries:
        return None
    location, reason = entries[0].get('location'), entries[0].get('reason')
    if not reason or not isinstance(location, dict) or tuple(sorted(location)) != tuple(sorted(HIT_LOCATION_KEYS)) \
            or not all(isinstance(location[key], (int, float)) for key in HIT_LOCATION_KEYS):
        raise ValueError(f'{rank_id} {HIT_LOCATION} needs a location with {", ".join(HIT_LOCATION_KEYS)} and a reason')
    return {key: location[key] for key in HIT_LOCATION_KEYS}


def part_casts(performed: int, interval_ms: int) -> list[int]:
    capacity = PART_BUDGET_MS // interval_ms
    if capacity < 1:
        raise Unmodelled(f'one cast of {interval_ms} ms exceeds the scenario budget of {PART_BUDGET_MS} ms')
    parts = math.ceil(performed / capacity)
    return [performed // parts + (part < performed % parts) for part in range(parts)]


def hit_measurements(rank_id: int, hit_spell: int, hostile: bool, labels: dict[str, str],
                     ally: bool = False, periodic: bool | None = None) -> list[dict]:
    family = 'spell_damage' if hostile else 'spell_heal'
    unblocked = {'blocked': False} if hostile else {}
    receiver = {} if ally else {'target': TARGET if hostile else CASTER}
    if periodic is not None:
        receiver = {**receiver, 'periodic': periodic}
    steps = [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS}]
    for part in ('total', 'count'):
        steps.append(measurement(labels[part], CASTER, f'{family}_{part}', spell=hit_spell, **receiver,
                                 critical=False, **unblocked))
    steps.append(measurement(f'{rank_id} critical_hits', CASTER, f'{family}_count', spell=hit_spell,
                             **receiver, critical=True))
    if hostile:
        steps.append(measurement(f'{rank_id} blocked_hits', CASTER, f'{family}_count', spell=hit_spell,
                                 **receiver, blocked=True))
    steps.append(measurement(f'{rank_id} cast_count', CASTER, 'spell_cast_count', spell=rank_id))
    return steps


def dual_target_entry(class_file: dict, rank_id: int) -> dict | None:
    return next((entry for entry in class_file.get('dual_target_effects', []) if entry['spell'] == rank_id), None)


def secondary_heal_labels(label: str, effect: int) -> dict[str, str]:
    return {'total': f'{label} e{effect} total', 'count': f'{label} e{effect} count'}


def secondary_heal_measurements(hit_spell: int, labels: dict[str, str], actor: str) -> list[dict]:
    return [measurement(labels[part], CASTER, f'spell_heal_{part}', spell=hit_spell, target=actor, critical=False)
           for part in ('total', 'count')]


def weapon_note(class_file: dict, armed_file: dict, records: Records, rank_id: int) -> str:
    if 'weapon_sets' in class_file:
        expected = spec_weapon_set(class_file, rank_id)
        if armed_file['weapon_set'] == expected:
            return ''
        reason = weapon_set_unfit_reason(class_file['weapon_sets'][expected],
                                         weapon_requirement(records, rank_id, class_file))
        return f'; weapon set {armed_file["weapon_set"]} ({expected}: {reason})'
    if armed_file is class_file:
        return ''
    reason = unfit_reason(class_file.get('weapon'), equip_requirement(records, rank_id, class_file))
    return f'; reference weapon {armed_file["weapon"]["item"]} ({reason})'


def hit_note(class_file: dict, spell_ids: set[int]) -> str | None:
    entry = next((entry for entry in class_file.get('hit_notes', []) if entry['spell'] in spell_ids), None)
    return entry['reason'] if entry else None


def base_mana_steps(class_file: dict, facts: RankFacts) -> list[dict]:
    base = class_file.get(BASE_MANA_FIELD)
    if base is None or not facts.mana_cost_percentage or facts.power_type != POWER_MANA:
        return []
    cost = facts.mana_cost + base['value'] * facts.mana_cost_percentage // 100
    if cost > base['value']:
        raise ValueError(f'{BASE_MANA_FIELD} {base["value"]} is below the cost {cost} of ManaCost '
                         f'{facts.mana_cost} + {facts.mana_cost_percentage}% of base mana')
    return [{'action': 'set_power', 'actor': CASTER, 'power': POWER_MANA, 'value': base['value']}]


def self_stack_multiplier(class_file: dict, rank_id: int, performed: int) -> float:
    entry = next((entry for entry in class_file.get('self_stack_bonus', []) if entry['rank'] == rank_id), None)
    if entry is None:
        return 1.0
    return 1.0 + entry['percent_per_stack'] / 100.0 * (performed - 1) / 2.0


GATE_FIXTURE_STEP_COUNT = 3


def gate_stacks(records: Records, gate_spell: int) -> int:
    return max(1, int(records.field('Spell', gate_spell, 'StackAmount')))


def gate_setup_label(label: str, gate_spell: int, stacks: int) -> str:
    return f'{label} SETUP: the caster\'s {gate_spell} holds {stacks} stacks on the target'


def gate_fixture_steps(gate_spell: int, stacks: int, label: str) -> list[dict]:
    fixture = {'action': 'set_aura', 'actor': CASTER, 'target': TARGET, 'caster': CASTER, 'spell': gate_spell}
    held = [{**fixture, 'stacks': stacks}] if stacks else []
    return [{**fixture, 'stacks': 0}] + held + [
        {'action': 'assert', 'label': gate_setup_label(label, gate_spell, stacks), 'actor': TARGET,
         'metric': 'aura_stacks', 'spell': gate_spell, 'caster': CASTER, 'min': stacks, 'max': stacks}]


def hit_parts(class_file: dict, spell: ClassSpell, casts: int, rank_id: int | None = None,
             label: str | None = None, check: str = 'hit_mean',
             gate: tuple[int, float, int] | None = None,
             gate_held: int | None = None, learned: int | None = None) -> list[tuple[dict, list[Expectation]]]:
    if casts < 1:
        raise ValueError(f'{spell.name} needs at least one cast, not {casts}')
    rank_id = spell.max_rank if rank_id is None else rank_id
    label = f'{rank_id} hit_mean' if label is None else label
    name = f'Conformance hit {class_file["name"]} {spell.name} {rank_id}'
    contract = 'Mean non-critical hit of the highest rank against its tooltip, its known modifiers and mitigation.'
    learn = block_value_steps(class_file, spell.spell_id) + [{'action': 'learn', 'actor': CASTER, 'spell': rank_id}]
    if gate is not None:
        learn = learn + [{'action': 'learn', 'actor': CASTER, 'spell': gate[2]}]
    if learned is not None:
        learn = learn + [{'action': 'learn', 'actor': CASTER, 'spell': learned}]
    records = records_of(class_file)
    armed_file = armed_for(class_file, records, rank_id)
    facts = facts_of(records, rank_id)
    gap_closing = closes_distance(facts)
    try:
        hit = rank_hit(armed_file, rank_id, reference_caster(armed_file), REFERENCE_TARGET,
                       armed_file.get('known_auras', []), learned, check)
        if gate is not None and hit.model.kind in HEAL_KINDS:
            raise ValueError(f'{rank_id} target_aura_gate needs a hostile hit model, got {hit.model.kind!r}')
        stacks = (gate_stacks(records, gate[0]) if gate_held is None else gate_held) if gate is not None else 0
        gate_extra_ms = GATE_FIXTURE_STEP_COUNT * READ_STEP_MS if gate is not None else 0
        start_recovery = records.field('Spell', rank_id, 'StartRecoveryTime')
        interval = max(start_recovery, hit.facts.cast_time_ms, hit.duration_ms) + CAST_MARGIN_MS
        budget_interval = interval + gate_extra_ms
        shares = part_casts(scheduled_casts(casts), budget_interval)
    except Unmodelled as error:
        note = hit_note(class_file, {spell.spell_id, rank_id})
        prefix = CLOSED if note and note.startswith('no check needed:') else UNMODELLED
        reason = prefix + (note if note is not None else error.reason)
        unmodelled = Expectation(label, 'unmodelled', spell.spell_id, rank_id, None, '', reason)
        expectations = [unmodelled]
        steps = list(learn)
        wait_ms = SETTLE_MS
        target_kind = gap_closer_target(facts) if gap_closing else None
        if gap_closing:
            fixtures = [{'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD}]
            gap_interval = max(records.field('Spell', rank_id, 'StartRecoveryTime'), facts.cast_time_ms) \
                + CAST_MARGIN_MS
            gap_steps, gap_expectation = gap_closer_expectation(rank_id, spell.spell_id, label, target_kind)
            steps += cast_steps(facts, rank_id, target_kind, gap_interval, 1, fixtures) + gap_steps
            expectations.append(gap_expectation)
            wait_ms += gap_interval
        scenario = scenario_shell(armed_file, name, contract, steps)
        if target_kind == TARGET:
            scenario['creatures'] = [creature_fixture(armed_file, cast_distance(records, rank_id))]
        elif target_kind == ALLY:
            scenario['players'].append({**player_fixture(armed_file), 'id': ALLY})
        return [(timed(scenario, wait_ms), expectations)]
    model = hit.model
    hostile = model.kind not in HEAL_KINDS
    ally = not hostile and targets_ally(hit.facts)
    target, labels = target_steps(hit.school_mask) if hostile else ([], {})
    labels.update({'total': f'{label} total', 'count': f'{label} count'})
    percent_steps = heal_pct_steps(class_file, rank_id, ally)
    if percent_steps:
        if model.kind != 'heal' or dual_target_entry(class_file, rank_id) is not None:
            raise ValueError(f'{rank_id} heal_pct_terms needs a single-target heal model, got {model.kind!r}')
        labels['max_health'] = percent_steps[0]['label']
    weapon = weapon_profile(armed_file) if model.kind in WEAPON_KINDS or learned is not None else None
    order = ', percent of the roll before the flat bonus (ADR 0010)' if model.kind in WEAPON_KINDS else ''
    source = f' of triggered spell {hit.hit_spell} per tick' if hit.hit_spell != rank_id else ''
    gate_note = (f'; the caster\'s {gate[0]} set on the target at {stacks} stacks every trial, {gate[1]:g}% '
                 f'expected mean bonus') if gate else ''
    learned_note = (f'; {learned} learned, its weapon percent of the reference weapon roll added to the school part'
                    if learned is not None else '')
    resist_note = (f'; listed in {UNRESISTED_RANK_HITS}: the measured target resistance is not subtracted'
                   if hostile and rank_id in class_file.get(UNRESISTED_RANK_HITS, ()) else '')
    location = hit_location(class_file, rank_id)
    if location is not None and not hostile:
        raise ValueError(f'{rank_id} {HIT_LOCATION} needs a hostile hit model, got {model.kind!r}')
    rule = (f'{model.kind} hit{source}{order}, integer steps modelled'
            f'{weapon_note(class_file, armed_file, records, rank_id)}{gate_note}{learned_note}{resist_note}'
            + (f'; listed in {HIT_LOCATION}: cast at map {location["map"]} ({location["x"]:g}, {location["y"]:g}, '
               f'{location["z"]:g})' if location is not None else '')
            + (heal_pct_text(class_file, records, rank_id) if percent_steps else ''))
    unreadable = [Expectation(f'{label} unreadable #{ordinal}', check, spell.spell_id, rank_id, None, entry,
                              UNREADABLE + entry) for ordinal, entry in enumerate(hit.readout.unreadable)]
    cast_target = TARGET if hostile else (ALLY if ally else None)
    cast_fixtures = [{'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD}] \
        if (ally and closes_distance(hit.facts)) or (gap_closing and cast_target) else []
    if gate is not None:
        cast_fixtures = cast_fixtures + gate_fixture_steps(gate[0], stacks, label)
    cast_fixtures = cast_fixtures + cast_aura_steps(class_file, rank_id) + base_mana_steps(class_file, hit.facts)
    dual = dual_target_entry(class_file, rank_id) if not hostile else None
    if dual and model.kind != 'heal':
        raise ValueError(f'{rank_id} dual_target_effects needs a heal-kind model, got {model.kind!r}')
    if dual and dual['secondary_effect'] not in hit.indexes:
        raise ValueError(f'{rank_id} dual_target_effects secondary_effect {dual["secondary_effect"]} is not one '
                         f'of {hit.indexes}')
    secondary_label = f'{label} e{dual["secondary_effect"]}' if dual else None
    secondary_labels = secondary_heal_labels(label, dual['secondary_effect']) if dual else None
    gap_steps, gap_expectations = [], []
    if gap_closing and cast_target:
        gap_steps, gap_expectation = gap_closer_expectation(rank_id, spell.spell_id, label, cast_target)
        gap_expectations = [gap_expectation]
    event_filter = None if rank_hit_effect(class_file, rank_id, check) is None else check == 'periodic_total'
    if event_filter is not None and not hostile:
        raise ValueError(f'{RANK_HIT_EFFECTS} {rank_id} splits damage events only, not a {model.kind} hit')
    parts = []
    for part, performed in enumerate(shares):
        steps = (learn + [dict(step) for step in target]
                 + required_target_health_steps(hit.facts)
                 + cast_steps(hit.facts, rank_id, cast_target, interval, performed, cast_fixtures)
                 + (gap_steps if part == 0 else [])
                 + hit_measurements(rank_id, hit.hit_spell, hostile, labels, ally, event_filter)
                 + percent_steps)
        if dual:
            steps += secondary_heal_measurements(hit.hit_spell, secondary_labels, dual['secondary_actor'])
        titled = name if len(shares) == 1 else f'{name} part {part + 1} of {len(shares)}'
        scenario = scenario_shell(armed_file, titled, contract, steps)
        if hostile:
            scenario['creatures'] = [creature_fixture(armed_file, cast_distance(records, rank_id))]
        if location is not None:
            scenario['location'] = dict(location)
        if ally:
            scenario['players'].append({**player_fixture(armed_file), 'id': ALLY})
        gate_multiplier = 1.0 + gate[1] / 100.0 if gate is not None else 1.0
        scaled = replace(model, mean=model.mean * self_stack_multiplier(armed_file, rank_id, performed)
                         * gate_multiplier)
        record = {**model_record(scaled, hit.school_mask, weapon, labels, casts), 'hit_spell': hit.hit_spell,
                  'gate_multiplier': gate_multiplier, **({'learned': learned} if learned is not None else {})}
        expectation = Expectation(label, check, spell.spell_id, rank_id, hit.indexes[0],
                                  ' | '.join(model.displayed), rule,
                                  {**record, 'part': part, 'parts': len(shares), 'part_casts': performed})
        secondary_expectations = []
        if dual:
            secondary_record = {**model_record(scaled, hit.school_mask, weapon, secondary_labels, casts),
                                'hit_spell': hit.hit_spell}
            secondary_record['minimum_hits'] = casts
            secondary_expectations = [Expectation(
                secondary_label, check, spell.spell_id, rank_id, dual['secondary_effect'],
                ' | '.join(model.displayed), rule,
                {**secondary_record, 'part': part, 'parts': len(shares), 'part_casts': performed})]
        parts.append((timed(scenario, SETTLE_MS + performed * budget_interval + DRAIN_MS),
                       [expectation] + secondary_expectations + (unreadable if part == 0 else [])
                       + (gap_expectations if part == 0 else [])))
    return parts


def hit_scenario(class_file: dict, spell: ClassSpell, casts: int) -> tuple[dict, list[Expectation]]:
    parts = hit_parts(class_file, spell, casts)
    if len(parts) > 1:
        raise ValueError(f'{spell.name} needs {len(parts)} scenarios for {casts} casts; use hit_parts')
    return parts[0]


def melee_parts(class_file: dict, swings: int) -> list[tuple[dict, list[Expectation]]]:
    try:
        reference_melee_model(class_file)
        speed_ms = weapon_profile(class_file).speed_ms
    except Unmodelled:
        return [melee_scenario(class_file, swings)]
    capacity = (MAX_SCENARIO_MS - TIMEOUT_MARGIN_MS - SETTLE_MS) // speed_ms
    scheduled = scheduled_casts(swings)
    if swings < 1 or scheduled <= capacity or not class_file.get(MELEE_PARTS):
        return [melee_scenario(class_file, swings)]
    parts = math.ceil(scheduled / capacity)
    per_part = math.ceil(scheduled / parts)
    return [melee_scenario(class_file, swings, per_part, part, parts) for part in range(parts)]


def melee_scenario(class_file: dict, swings: int, part_swings: int | None = None, part_index: int = 0,
                   parts: int = 1) -> tuple[dict, list[Expectation]]:
    if swings < 1:
        raise ValueError(f'melee needs at least one swing, not {swings}')
    name = f'Conformance melee {class_file["name"]}' + (f' part {part_index + 1} of {parts}' if parts > 1 else '')
    contract = 'Mean plain melee hit of the reference weapon against its weapon damage, known modifiers and armor.'
    try:
        model = reference_melee_model(class_file)
    except Unmodelled as error:
        unmodelled = Expectation(MELEE_LABEL, 'unmodelled', 0, 0, None, '', UNMODELLED + error.reason)
        return timed(scenario_shell(class_file, name, contract, []), SETTLE_MS), [unmodelled]
    weapon = weapon_profile(class_file)
    steps, labels = target_steps(PHYSICAL_SCHOOL_MASK)
    swing_ms = (scheduled_casts(swings) if part_swings is None else part_swings) * weapon.speed_ms
    steps += [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
              {'action': 'wait', 'label': 'swings', 'ms': swing_ms},
              {'action': 'stop_attack', 'actor': CASTER}]
    plain = {'hand': MAIN_HAND, 'critical': False, 'glancing': False, 'blocked': False}
    labels.update({'total': f'{MELEE_LABEL} total', 'count': f'{MELEE_LABEL} count'})
    for part in ('total', 'count'):
        steps.append(measurement(labels[part], CASTER, f'melee_damage_{part}', **plain))
    steps.append(measurement('melee swing count', CASTER, 'melee_attack_count', hand=MAIN_HAND))
    for outcome in ('critical', 'glancing', 'blocked'):
        steps.append(measurement(f'melee {outcome} count', CASTER, 'melee_damage_count', hand=MAIN_HAND,
                                 **{outcome: True}))
    scenario = scenario_shell(class_file, name, contract, steps)
    scenario['creatures'] = [creature_fixture(class_file)]
    record = model_record(model, PHYSICAL_SCHOOL_MASK, weapon, labels, swings)
    if parts > 1:
        record = {**record, 'part': part_index, 'parts': parts, 'part_swings': part_swings}
        scenario['contract'] += (f' Part {part_index + 1} of {parts}: {part_swings} of the {scheduled_casts(swings)} '
                                 f'scheduled swings; the judge pools the plain hits of every part.')
    expectation = Expectation(MELEE_LABEL, 'melee_mean', 0, 0, None, f'weapon {weapon.item}',
                              'melee hit at weapon speed, integer steps modelled', record)
    return timed(scenario, SETTLE_MS + swing_ms), [expectation]
