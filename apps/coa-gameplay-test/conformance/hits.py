from dataclasses import asdict, dataclass
from fractions import Fraction
import math
from pathlib import Path
import struct
from typing import Mapping, Sequence

from classes import ClassSpell
from mitigation import PHYSICAL_SCHOOL_MASK, REFERENCE_TARGET, MitigationModel, TargetProfile, expected_mitigation
from profile import (CASTER, DBC_DIR, SETTLE_MS, base_steps, caster_stats_from, known_aura_label, measurement,
                     player_fixture)
from tooltip import CasterStats, Readout, Records, Unreadable, read_tooltip
from values import (CAST_MARGIN_MS, DUMMY_DISTANCE, DUMMY_ENTRY, DUMMY_HEALTH, EFFECTS, TARGET, UNREADABLE,
                    Expectation, RankFacts, dataset, facts_of)

HIT_CHECKS = ('hit_mean', 'melee_mean', 'unmodelled')
UNMODELLED = 'unmodelled: '
Z_99 = 2.576
MEAN_HALF_WIDTH = 0.01
EXCLUDED_OUTCOME_MARGIN = Fraction(3, 2)
ATTACK_POWER_PER_DPS = 14.0
SCHOOL_DAMAGE = 2
APPLY_AURA = 6
HEAL = 10
WEAPON_DAMAGE_NOSCHOOL = 17
WEAPON_PERCENT_DAMAGE = 31
WEAPON_DAMAGE = 58
NORMALIZED_WEAPON_DMG = 121
WEAPON_FLAT_EFFECTS = frozenset({WEAPON_DAMAGE_NOSCHOOL, WEAPON_DAMAGE, NORMALIZED_WEAPON_DMG})
WEAPON_EFFECTS = WEAPON_FLAT_EFFECTS | {WEAPON_PERCENT_DAMAGE}
PERIODIC_KINDS = {3: 'periodic_damage', 8: 'periodic_heal'}
HEAL_KINDS = frozenset({'heal', 'periodic_heal'})
MODIFIER_AURAS = {341: 'damage', 136: 'heal'}
MAGIC_SCHOOLS = range(1, 7)
NO_MITIGATION = MitigationModel(mean=1.0, variance=0.0)
DRAIN_MS = 3000
MAX_SCENARIO_MS = 600000
TIMEOUT_MARGIN_MS = 60000
MAIN_HAND = 0
MELEE_LABEL = 'melee melee_mean'
ARMOR_LABEL = 'target armor'
VIEW_LEVEL_LABEL = 'target view_level'
FLOAT32 = struct.Struct('<f')


class Unmodelled(Exception):
    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


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


def hit_kind(effects: Sequence[int], aura_names: Sequence[int]) -> tuple[str, list[int]]:
    kinds: dict[str, list[int]] = {}
    for index, effect in enumerate(effects):
        if effect in WEAPON_EFFECTS:
            kinds.setdefault('weapon', []).append(index)
        elif effect == SCHOOL_DAMAGE:
            kinds.setdefault('school', []).append(index)
        elif effect == HEAL:
            kinds.setdefault('heal', []).append(index)
        elif effect == APPLY_AURA and aura_names[index] in PERIODIC_KINDS:
            kinds.setdefault(PERIODIC_KINDS[aura_names[index]], []).append(index)
    if not kinds:
        raise Unmodelled(f'no damage or healing effect among effects {list(effects)}')
    if len(kinds) > 1:
        raise Unmodelled(f'effects of several hit models: {sorted(kinds)}')
    kind, indexes = next(iter(kinds.items()))
    if kind in PERIODIC_KINDS.values() and len(indexes) > 1:
        raise Unmodelled(f'several periodic effects: {indexes}')
    return kind, indexes


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


def weapon_hit(readout: Readout, effects: Sequence[int], caster: CasterStats,
               weapon: WeaponProfile | None) -> tuple[Distribution, float, list[str]]:
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
    distribution = mapped(roll, lambda damage: math.floor(damage * percent) + flat_floor)
    tooltip_mean = float(percent) * ((weapon.min_damage + weapon.max_damage) / 2 + bonus) + flat
    return distribution, tooltip_mean, ordered(readout, texts)


def effect_hit(readout: Readout, indexes: list[int]) -> tuple[Distribution, float, list[str]]:
    distribution: Distribution = {0: 1.0}
    tooltip_mean = 0.0
    texts: list[str] = []
    for index in indexes:
        low, high, shown = value_range(readout, index)
        distribution = summed(distribution, effect_roll(low, high))
        tooltip_mean += (low + high) / 2
        texts += shown
    return distribution, tooltip_mean, ordered(readout, texts)


def ordered(readout: Readout, texts: list[str]) -> list[str]:
    return [value.text for value in readout.values if value.text in texts]


def applicable(modifiers: Sequence[Modifier], kind: str) -> tuple[Modifier, ...]:
    wanted = 'heal' if kind in HEAL_KINDS else 'damage'
    return tuple(modifier for modifier in modifiers if modifier.applies_to == wanted)


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
                 ticks: int = 1) -> HitModel:
    names = tuple(aura_names) or (0,) * len(spell_effects)
    kind, indexes = hit_kind(spell_effects, names)
    if kind == 'weapon':
        distribution, tooltip_mean, texts = weapon_hit(readout, spell_effects, caster, weapon)
    else:
        distribution, tooltip_mean, texts = effect_hit(readout, indexes)
    used = applicable(modifiers, kind)
    mean, sigma = moments(mitigated(done(distribution, used), mitigation))
    return HitModel(kind=kind, mean=mean, sigma=sigma, tooltip_mean=tooltip_mean,
                    hits_per_cast=ticks if kind in PERIODIC_KINDS.values() else 1, modifiers=used,
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


def for_school(modifiers: Sequence[Modifier], school_mask: int) -> tuple[Modifier, ...]:
    return tuple(modifier for modifier in modifiers
                 if modifier.applies_to != 'damage' or modifier.school_mask & school_mask)


def records_of(class_file: dict) -> Records:
    return Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))


def mitigation_for(school_mask: int, target: TargetProfile, level: int) -> MitigationModel:
    try:
        return expected_mitigation(school_mask, target, level)
    except ValueError as error:
        raise Unmodelled(str(error)) from error


@dataclass(frozen=True)
class RankHit:
    model: HitModel
    readout: Readout
    facts: RankFacts
    school_mask: int
    indexes: list[int]
    duration_ms: int


def periodic_ticks(records: Records, rank_id: int, effect: int) -> tuple[int, int]:
    amplitude = records.field('Spell', rank_id, f'EffectAmplitude[{effect}]')
    try:
        duration = int(records.duration_ms(rank_id))
    except Unreadable as error:
        raise Unmodelled(f'duration of spell {rank_id} is unreadable {error.reason}'.rstrip()) from error
    if amplitude <= 0 or duration < amplitude:
        raise Unmodelled(f'periodic effect {effect} ticks {amplitude} ms over {duration} ms')
    return duration // amplitude, duration


def rank_hit(class_file: dict, rank_id: int, caster: CasterStats, target: TargetProfile,
             auras: Sequence[int]) -> RankHit:
    records = records_of(class_file)
    facts = facts_of(records, rank_id)
    if facts.passive:
        raise Unmodelled('passive spell is never cast')
    kind, indexes = hit_kind(facts.effects, facts.aura_names)
    school_mask = records.field('Spell', rank_id, 'SchoolMask')
    ticks, duration = periodic_ticks(records, rank_id, indexes[0]) if kind in PERIODIC_KINDS.values() else (1, 0)
    mitigation = NO_MITIGATION if kind in HEAL_KINDS else mitigation_for(school_mask, target, caster.level)
    readout = read_tooltip(records.dbc, rank_id, caster)
    modifiers = for_school(aura_modifiers(records, auras, class_file['level']), school_mask)
    model = expected_hit(readout, facts.effects, caster, weapon_profile(class_file), mitigation,
                         aura_names=facts.aura_names, modifiers=modifiers, ticks=ticks)
    return RankHit(model, readout, facts, school_mask, indexes, duration)


def reference_caster(class_file: dict) -> CasterStats:
    return caster_stats_from(class_file['reference_stats'], class_file['level'])


def reference_hit_model(class_file: dict, rank_id: int) -> HitModel:
    return rank_hit(class_file, rank_id, reference_caster(class_file), REFERENCE_TARGET,
                    class_file.get('known_auras', [])).model


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


def measured_hit_model(class_file: dict, expectation: Expectation, measured: Mapping[str, float]) -> HitModel:
    labels = expectation.model['measurements']
    caster = caster_stats_from(measured, class_file['level'])
    target = REFERENCE_TARGET
    if ARMOR_LABEL in labels.values():
        target = TargetProfile(
            entry=DUMMY_ENTRY, level=int(measured[VIEW_LEVEL_LABEL]), armor=int(measured[ARMOR_LABEL]),
            resistances={1 << school: int(measured[resistance_label(school)])
                         for school in magic_schools(expectation.model['school_mask'])})
    auras = [aura for aura in class_file.get('known_auras', []) if measured[known_aura_label(aura)] > 0]
    if expectation.model['kind'] == 'melee':
        return melee_model(class_file, caster, target, auras)
    return rank_hit(class_file, expectation.rank_id, caster, target, auras).model


def creature_fixture(class_file: dict) -> dict:
    return {'id': TARGET, 'owner': CASTER, 'entry': DUMMY_ENTRY, 'level': class_file['level'],
            'health': DUMMY_HEALTH, 'distance': DUMMY_DISTANCE, 'stationary': True}


def target_steps(school_mask: int) -> tuple[list[dict], dict[str, str]]:
    steps = [measurement(ARMOR_LABEL, TARGET, 'armor'),
             measurement(VIEW_LEVEL_LABEL, CASTER, 'view_level', target=TARGET)]
    labels = {'armor': ARMOR_LABEL, 'view_level': VIEW_LEVEL_LABEL}
    for school in magic_schools(school_mask):
        steps.append(measurement(resistance_label(school), TARGET, 'resistance', school=school))
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


def timed(scenario: dict, waited_ms: int) -> dict:
    if waited_ms + TIMEOUT_MARGIN_MS > MAX_SCENARIO_MS:
        raise ValueError(f'{scenario["name"]} waits {waited_ms} ms; split its casts over several scenarios')
    scenario['timeout_ms'] = waited_ms + TIMEOUT_MARGIN_MS
    return scenario


def scenario_shell(class_file: dict, name: str, contract: str, steps: list[dict]) -> dict:
    return {'schema': 1, 'name': name, 'contract': contract, 'players': [player_fixture(class_file)],
            'steps': base_steps(class_file) + steps}


def cast_steps(facts: RankFacts, rank_id: int, hostile: bool, interval_ms: int, casts: int) -> list[dict]:
    steps = []
    for _ in range(casts):
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                          'value': facts.mana_cost})
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': rank_id})
        cast = {'action': 'cast', 'actor': CASTER, 'spell': rank_id}
        if hostile:
            cast['target'] = TARGET
        steps.append(cast)
        steps.append({'action': 'wait', 'ms': interval_ms})
    return steps


def hit_scenario(class_file: dict, spell: ClassSpell, casts: int) -> tuple[dict, list[Expectation]]:
    if casts < 1:
        raise ValueError(f'{spell.name} needs at least one cast, not {casts}')
    rank_id = spell.max_rank
    label = f'{rank_id} hit_mean'
    name = f'Conformance hit {class_file["name"]} {spell.name} {rank_id}'
    contract = 'Mean non-critical hit of the highest rank against its tooltip, its known modifiers and mitigation.'
    learn = [{'action': 'learn', 'actor': CASTER, 'spell': rank_id}]
    try:
        hit = rank_hit(class_file, rank_id, reference_caster(class_file), REFERENCE_TARGET,
                       class_file.get('known_auras', []))
    except Unmodelled as error:
        unmodelled = Expectation(label, 'unmodelled', spell.spell_id, rank_id, None, '', UNMODELLED + error.reason)
        return timed(scenario_shell(class_file, name, contract, learn), SETTLE_MS), [unmodelled]
    model, facts = hit.model, hit.facts
    hostile = model.kind not in HEAL_KINDS
    steps = list(learn)
    labels: dict[str, str] = {}
    if hostile:
        steps, labels = target_steps(hit.school_mask)
        steps = learn + steps
    start_recovery = records_of(class_file).field('Spell', rank_id, 'StartRecoveryTime')
    interval = max(start_recovery, facts.cast_time_ms, hit.duration_ms) + CAST_MARGIN_MS
    performed = scheduled_casts(casts)
    steps += cast_steps(facts, rank_id, hostile, interval, performed)
    steps.append({'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS})
    family = 'spell_damage' if hostile else 'spell_heal'
    unblocked = {'blocked': False} if hostile else {}
    receiver = TARGET if hostile else CASTER
    labels.update({'total': f'{label} total', 'count': f'{label} count'})
    for part in ('total', 'count'):
        steps.append(measurement(labels[part], CASTER, f'{family}_{part}', spell=rank_id, target=receiver,
                                 critical=False, **unblocked))
    steps.append(measurement(f'{rank_id} critical_hits', CASTER, f'{family}_count', spell=rank_id, target=receiver,
                             critical=True))
    if hostile:
        steps.append(measurement(f'{rank_id} blocked_hits', CASTER, f'{family}_count', spell=rank_id,
                                 target=receiver, blocked=True))
    steps.append(measurement(f'{rank_id} cast_count', CASTER, 'spell_cast_count', spell=rank_id))
    scenario = scenario_shell(class_file, name, contract, steps)
    if hostile:
        scenario['creatures'] = [creature_fixture(class_file)]
    weapon = weapon_profile(class_file) if model.kind == 'weapon' else None
    order = ', percent of the roll before the flat bonus (ADR 0010)' if model.kind == 'weapon' else ''
    expectations = [Expectation(label, 'hit_mean', spell.spell_id, rank_id, hit.indexes[0],
                                ' | '.join(model.displayed), f'{model.kind} hit{order}, integer steps modelled',
                                model_record(model, hit.school_mask, weapon, labels, casts))]
    for ordinal, entry in enumerate(hit.readout.unreadable):
        expectations.append(Expectation(f'{label} unreadable #{ordinal}', 'hit_mean', spell.spell_id, rank_id, None,
                                        entry, UNREADABLE + entry))
    return timed(scenario, SETTLE_MS + performed * interval + DRAIN_MS), expectations


def melee_scenario(class_file: dict, swings: int) -> tuple[dict, list[Expectation]]:
    if swings < 1:
        raise ValueError(f'melee needs at least one swing, not {swings}')
    name = f'Conformance melee {class_file["name"]}'
    contract = 'Mean plain melee hit of the reference weapon against its weapon damage, known modifiers and armor.'
    try:
        model = reference_melee_model(class_file)
    except Unmodelled as error:
        unmodelled = Expectation(MELEE_LABEL, 'unmodelled', 0, 0, None, '', UNMODELLED + error.reason)
        return timed(scenario_shell(class_file, name, contract, []), SETTLE_MS), [unmodelled]
    weapon = weapon_profile(class_file)
    steps, labels = target_steps(PHYSICAL_SCHOOL_MASK)
    swing_ms = scheduled_casts(swings) * weapon.speed_ms
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
    expectation = Expectation(MELEE_LABEL, 'melee_mean', 0, 0, None, f'weapon {weapon.item}',
                              'melee hit at weapon speed, integer steps modelled',
                              model_record(model, PHYSICAL_SCHOOL_MASK, weapon, labels, swings))
    return timed(scenario, SETTLE_MS + swing_ms), [expectation]
