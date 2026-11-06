from dataclasses import dataclass, field, replace
from functools import lru_cache
import math
from pathlib import Path
import re
from statistics import fmean, pstdev
from typing import Sequence

from classes import PASSIVE_ATTRIBUTE, ClassSpell, DataSet
from profile import (CASTER, DBC_DIR, EQUIP_FIELDS, armed, base_steps, character_of, known_aura_label, measurement,
                     player_fixture, skill_target)
from tooltip import (MIXED_PERIOD, OVER_TICKS, TICKING_AURAS, CasterStats, Displayed, ForcedPoints, Records, Tooltip,
                     Unreadable, mixed_period_reason, period_reading, read_tooltip)

CHECKS = ('effect_value', 'aura_amount', 'aura_duration_ms', 'max_stacks', 'spell_duration', 'power_cost',
          'cooldown_ms', 'known_aura')
TARGET = 'dummy'
DUMMY_ENTRY = 36
DUMMY_HEALTH = 50000000
DUMMY_DISTANCE = 3
EFFECTS = range(3)
HOSTILE_TARGETS = frozenset({2, 6, 15, 16, 24})
SELF_TARGETS = frozenset({0, 1})
POWER_DISPLAY_DIVISOR = {0: 1, 1: 10, 2: 1, 3: 1, 4: 1000, 5: 1, 6: 10}
MANA = 0
CAST_MARGIN_MS = 500
CAST_WAIT_LABEL = 'cast time'
UNREADABLE = 'unreadable: '
UNMEASURABLE = 'unmeasurable: '
OWN_DURATION = re.compile(r'\$(\d*)[dD]')
EFFECT_KINDS = ('flat', 'percent', 'duration_ms')
EFFECT_TOKEN = re.compile(r'\$(?:/\d+;)?(?P<spell>\d*)[sSmM](?P<digit>[1-3])')
STACKS_TOKEN = re.compile(r'\$(?P<spell>\d*)[uU]')
LEVEL_PLACEHOLDER_STAT = 1.0
Z_99 = 2.576
MEAN_HALF_WIDTH = 0.01
MAX_SCENARIO_STEPS = 10000
DEFAULT_TIMEOUT_MS = 90000
READ_STEP_MS = 25
READ_BUDGET_MS = DEFAULT_TIMEOUT_MS // 2
FIXED_DIE_SIDES = (0, 1)
SAMPLE_SUFFIX = ' sample '


@dataclass(frozen=True)
class Expectation:
    label: str
    check: str
    spell_id: int
    rank_id: int
    effect_index: int | None
    displayed: str
    rule: str
    model: dict | None = field(default=None, hash=False)


@dataclass(frozen=True)
class RankFacts:
    passive: bool
    effects: tuple[int, ...]
    aura_names: tuple[int, ...]
    target_a: tuple[int, ...]
    target_b: tuple[int, ...]
    power_type: int
    mana_cost: int
    mana_cost_per_level: int
    mana_cost_percentage: int
    recast_ms: int
    cast_time_ms: int
    caster_aura_spell: int


@lru_cache(maxsize=None)
def dataset(directory: Path) -> DataSet:
    return DataSet(directory)


def facts_of(records: Records, rank_id: int) -> RankFacts:
    def spell(name: str):
        return records.field('Spell', rank_id, name)

    def indexed(name: str) -> tuple[int, ...]:
        return tuple(spell(f'{name}[{effect}]') for effect in EFFECTS)

    try:
        cast_time = records.field('SpellCastTimes', spell('CastingTimeIndex'), 'CastTime')
    except Unreadable:
        cast_time = 0
    return RankFacts(
        passive=bool(spell('Attributes') & PASSIVE_ATTRIBUTE),
        effects=indexed('Effect'),
        aura_names=indexed('EffectApplyAuraName'),
        target_a=indexed('EffectImplicitTargetA'),
        target_b=indexed('EffectImplicitTargetB'),
        power_type=spell('PowerType'),
        mana_cost=spell('ManaCost'),
        mana_cost_per_level=spell('ManaCostPerlevel'),
        mana_cost_percentage=spell('ManaCostPercentage'),
        recast_ms=max(spell('RecoveryTime'), spell('CategoryRecoveryTime')),
        cast_time_ms=max(cast_time, 0),
        caster_aura_spell=spell('CasterAuraSpell'))


def equip_requirement(records: Records, rank_id: int) -> dict[str, int]:
    return {name: records.field('Spell', rank_id, name) for name in EQUIP_FIELDS}


def armed_for(class_file: dict, records: Records, rank_id: int) -> dict:
    return armed(class_file, equip_requirement(records, rank_id))


def structure_stats(class_file: dict) -> CasterStats:
    skills = {line: float(skill_target(class_file)) for line in class_file.get('skill_lines', [])}
    return CasterStats(
        ap=LEVEL_PLACEHOLDER_STAT, rap=LEVEL_PLACEHOLDER_STAT,
        sp_by_school={school: LEVEL_PLACEHOLDER_STAT for school in range(1, 7)},
        stats={stat: LEVEL_PLACEHOLDER_STAT for stat in range(5)},
        **character_of(class_file, skills))


def is_hostile(facts: RankFacts) -> bool:
    return any(facts.effects[effect] and (facts.target_a[effect] in HOSTILE_TARGETS
                                          or facts.target_b[effect] in HOSTILE_TARGETS)
               for effect in EFFECTS)


def aura_carrier(facts: RankFacts, effect: int) -> dict:
    if facts.target_a[effect] in SELF_TARGETS or not is_hostile(facts):
        return {'actor': CASTER, 'caster': CASTER}
    return {'actor': TARGET, 'caster': CASTER}


def required_aura_steps(facts: RankFacts) -> list[dict]:
    if not facts.caster_aura_spell:
        return []
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': facts.caster_aura_spell, 'stacks': 1}]


def first_aura_effect(facts: RankFacts) -> int | None:
    return next((effect for effect in EFFECTS if facts.effects[effect] and facts.aura_names[effect]), None)


def roll_range(base_points: int, die_sides: int) -> range:
    low, high = sorted((base_points + 1, base_points + die_sides))
    return range(low, high + 1)


def sample_labels(label: str, samples: int) -> list[str]:
    return [label] + [f'{label}{SAMPLE_SUFFIX}{index}' for index in range(1, samples)]


def mean_samples(values: Sequence[float]) -> int | None:
    mean = fmean(values)
    if abs(mean) < 1e-9:
        return None
    return max(1, math.ceil((Z_99 * pstdev(values) / (MEAN_HALF_WIDTH * abs(mean))) ** 2))


def rolled_samples(dbc: DataSet, records: Records, rank_id: int, caster: CasterStats, ordinal: int, text: str,
                   spell_id: int, effect: int) -> int | None:
    base_points = records.field('Spell', spell_id, f'EffectBasePoints[{effect}]')
    die_sides = records.field('Spell', spell_id, f'EffectDieSides[{effect}]')
    if die_sides in FIXED_DIE_SIDES:
        return None
    description = records.field('Spell', rank_id, 'Description[enUS]')
    values = []
    for roll in roll_range(base_points, die_sides):
        try:
            readout = Tooltip(ForcedPoints(dbc, spell_id, effect, roll), rank_id, caster).read(description)
        except Unreadable:
            return 1
        if ordinal >= len(readout.values) or readout.values[ordinal].text != text:
            return 1
        values.append(readout.values[ordinal].value)
    return mean_samples(values) or 1


def token_spell(digits: str, rank_id: int, shown: Displayed) -> int:
    return int(digits) if digits else shown.spell_id or rank_id


def foreign_effect(records: Records, rank_id: int, shown: Displayed) -> tuple[dict | None, str]:
    if shown.effect_index is not None or shown.spell_id in (None, rank_id) or shown.kind not in EFFECT_KINDS:
        return None, ''
    token = next((match for match in EFFECT_TOKEN.finditer(shown.text)
                  if token_spell(match.group('spell'), rank_id, shown) == shown.spell_id), None)
    if token is None:
        return None, f'{shown.kind} token of spell {shown.spell_id} without a readable effect'
    effect = int(token.group('digit')) - 1
    if not records.field('Spell', shown.spell_id, f'Effect[{effect}]'):
        return None, f'effect {effect} of spell {shown.spell_id} does not exist'
    return {'effect_spell': shown.spell_id, 'effect': effect}, ''


def foreign_counter(pattern: re.Pattern, rank_id: int, shown: Displayed) -> int | None:
    match = pattern.fullmatch(shown.text)
    if match is None:
        return None
    spell_id = token_spell(match.group(1), rank_id, shown)
    return None if spell_id == rank_id else spell_id


def foreign_stacks(rank_id: int, shown: Displayed) -> int | None:
    return foreign_counter(STACKS_TOKEN, rank_id, shown)


def foreign_duration(rank_id: int, shown: Displayed) -> int | None:
    return foreign_counter(OWN_DURATION, rank_id, shown)


def periodic_reason(records: Records, rank_id: int, caster: CasterStats, shown: Displayed) -> str:
    effect = shown.effect_index
    aura = records.field('Spell', rank_id, f'EffectApplyAuraName[{effect}]')
    if aura not in TICKING_AURAS or records.field('Spell', rank_id, f'EffectAmplitude[{effect}]') <= 0:
        return ''
    try:
        reading = period_reading(records, rank_id, caster, shown, effect)
    except Unreadable as error:
        return error.reason
    if reading == OVER_TICKS:
        return f'a total over the ticks of periodic effect {effect}; the hit scenario judges one tick'
    if reading == MIXED_PERIOD:
        return mixed_period_reason(shown.text, effect)
    return ''


def power_cost_expectation(label: str, spell_id: int, rank_id: int, facts: RankFacts) -> Expectation:
    divisor = POWER_DISPLAY_DIVISOR.get(facts.power_type, 1)
    if facts.mana_cost_per_level:
        displayed = f'{facts.mana_cost} + {facts.mana_cost_per_level} per level'
        rule = UNREADABLE + f'ManaCostPerlevel {facts.mana_cost_per_level} scales with the spell rank of the client'
    elif facts.mana_cost_percentage:
        displayed = f'{facts.mana_cost} + {facts.mana_cost_percentage}% of base power'
        rule = UNREADABLE + f'ManaCostPercentage {facts.mana_cost_percentage} needs the base power of the caster'
    else:
        displayed = str(facts.mana_cost // divisor)
        rule = f'ManaCost divisor {divisor}'
    return Expectation(label, 'power_cost', spell_id, rank_id, None, displayed, rule)


def sampled_reads(measured: list[dict], rolled: dict[str, int], budget: int) -> tuple[list[dict], dict[str, int]]:
    steps, samples = [], {}
    for step in measured:
        steps.append(step)
        wanted = rolled.get(step['label'])
        if wanted is None:
            continue
        if wanted - 1 > budget:
            wanted = 1
        budget -= wanted - 1
        samples[step['label']] = wanted
        steps += [{**step, 'label': label} for label in sample_labels(step['label'], wanted)[1:]]
    return steps, samples


def value_scenario(class_file: dict, spell: ClassSpell, rank_id: int) -> tuple[dict, list[Expectation]]:
    if rank_id not in spell.ranks:
        raise ValueError(f'Spell {rank_id} is not a rank of {spell.spell_id}')
    dbc = dataset(Path(class_file.get('dbc_dir', DBC_DIR)))
    records = Records(dbc)
    class_file = armed_for(class_file, records, rank_id)
    facts = facts_of(records, rank_id)
    caster = structure_stats(class_file)
    readout = read_tooltip(dbc, rank_id, caster)
    measured: list[dict] = []
    after_cast: list[dict] = []
    expectations: list[Expectation] = []
    cast_wanted = False
    first_effect = next((effect for effect in EFFECTS if facts.effects[effect]), None)
    rolled: dict[str, int] = {}

    def sample_rolled(label: str, ordinal: int, text: str, spell_id: int, effect: int):
        samples = rolled_samples(dbc, records, rank_id, caster, ordinal, text, spell_id, effect)
        if samples is not None:
            rolled[label] = samples

    def effect_measurement(label: str, effect: int) -> dict:
        return measurement(label, CASTER, 'spell_effect_value', spell=rank_id, effect=effect)

    def aura_measurement(label: str, metric: str, carrier_effect: int, **fields) -> dict:
        return measurement(label, metric=metric, spell=rank_id, **aura_carrier(facts, carrier_effect), **fields)

    def expect(label: str, check: str, effect: int | None, displayed: str, rule: str, model: dict | None = None):
        expectations.append(Expectation(label, check, spell.spell_id, rank_id, effect, displayed, rule, model))

    for ordinal, shown in enumerate(readout.values):
        effect = shown.effect_index
        periodic = periodic_reason(records, rank_id, caster, shown) if effect is not None else ''
        if periodic:
            expect(f'{rank_id} effect_value #{ordinal}', 'effect_value', effect, shown.text, UNMEASURABLE + periodic)
            continue
        if shown.kind in EFFECT_KINDS and effect is not None and facts.effects[effect]:
            label = f'{rank_id} effect_value e{effect} #{ordinal}'
            measured.append(effect_measurement(label, effect))
            expect(label, 'effect_value', effect, shown.text, f'read {shown.kind}')
            sample_rolled(label, ordinal, shown.text, rank_id, effect)
            if facts.aura_names[effect] and not facts.passive:
                aura_label = f'{rank_id} aura_amount e{effect} #{ordinal}'
                after_cast.append(aura_measurement(aura_label, 'aura_amount', effect, effect=effect))
                expect(aura_label, 'aura_amount', effect, shown.text, f'read {shown.kind}')
                cast_wanted = True
            continue
        stacks_spell = foreign_stacks(rank_id, shown)
        if stacks_spell:
            label = f'{rank_id} max_stacks {stacks_spell} #{ordinal}'
            measured.append(measurement(label, CASTER, 'spell_max_stacks', spell=stacks_spell))
            expect(label, 'max_stacks', None, shown.text, f'read {shown.kind}', {'effect_spell': stacks_spell})
            continue
        duration_spell = foreign_duration(rank_id, shown)
        if duration_spell:
            label = f'{rank_id} spell_duration {duration_spell} #{ordinal}'
            measured.append(measurement(label, CASTER, 'spell_duration_ms', spell=duration_spell))
            expect(label, 'spell_duration', None, shown.text, f'read {shown.kind}', {'effect_spell': duration_spell})
            continue
        foreign, unmeasurable = foreign_effect(records, rank_id, shown)
        if foreign:
            label = f'{rank_id} effect_value {foreign["effect_spell"]}e{foreign["effect"]} #{ordinal}'
            measured.append(measurement(label, CASTER, 'spell_effect_value', spell=foreign['effect_spell'],
                                        effect=foreign['effect']))
            expect(label, 'effect_value', None, shown.text, f'read {shown.kind}', foreign)
            sample_rolled(label, ordinal, shown.text, foreign['effect_spell'], foreign['effect'])
            continue
        if unmeasurable:
            expect(f'{rank_id} effect_value #{ordinal}', 'effect_value', None, shown.text, UNMEASURABLE + unmeasurable)
            continue
        own_duration = OWN_DURATION.fullmatch(shown.text)
        aura_effect = first_aura_effect(facts)
        if shown.kind == 'duration_ms' and own_duration and own_duration.group(1) in ('', str(rank_id)):
            label = f'{rank_id} aura_duration_ms #{ordinal}'
            if facts.passive or aura_effect is None:
                expect(label, 'aura_duration_ms', None, shown.text,
                       UNMEASURABLE + 'the spell is passive or applies no aura')
            elif facts.cast_time_ms:
                expect(label, 'aura_duration_ms', None, shown.text,
                       UNMEASURABLE + 'the remaining duration of a cast-time spell is read after its cast')
            else:
                after_cast.append(aura_measurement(label, 'aura_duration_ms', aura_effect))
                expect(label, 'aura_duration_ms', None, shown.text, f'read {shown.kind}')
                cast_wanted = True
            continue
        expect(f'{rank_id} effect_value #{ordinal}', 'effect_value', effect, shown.text,
               UNMEASURABLE + f'{shown.kind} token without a no-combat metric')
    for ordinal, entry in enumerate(readout.unreadable, start=len(readout.values)):
        label = f'{rank_id} effect_value #{ordinal}'
        if first_effect is not None:
            measured.append(effect_measurement(label, first_effect))
        expect(label, 'effect_value', None, entry, UNREADABLE + entry)
    if not readout.values and not readout.unreadable:
        label = f'{rank_id} effect_value #0'
        if first_effect is not None:
            measured.append(effect_measurement(label, first_effect))
        expect(label, 'effect_value', None, '', UNREADABLE + 'tooltip without value')

    cast_steps: list[dict] = []
    if not facts.passive:
        label = f'{rank_id} power_cost'
        measured.append(measurement(label, CASTER, 'spell_power_cost', spell=rank_id))
        expectations.append(power_cost_expectation(label, spell.spell_id, rank_id, facts))
        if facts.recast_ms > 0:
            label = f'{rank_id} cooldown_ms'
            after_cast.append(measurement(label, CASTER, 'cooldown_ms', spell=rank_id))
            expect(label, 'cooldown_ms', None, str(facts.recast_ms), 'max(RecoveryTime, CategoryRecoveryTime)')
            cast_wanted = True
    if cast_wanted:
        if facts.mana_cost > 0 and facts.power_type != MANA:
            cast_steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                               'value': facts.mana_cost})
        cast = {'action': 'cast', 'actor': CASTER, 'spell': rank_id}
        if is_hostile(facts):
            cast['target'] = TARGET
        cast_steps += required_aura_steps(facts)
        cast_steps.append(cast)
        if facts.cast_time_ms:
            cast_steps.append({'action': 'wait', 'label': CAST_WAIT_LABEL,
                               'ms': facts.cast_time_ms + CAST_MARGIN_MS})
        cast_steps.append(measurement(f'{rank_id} cast_failure', CASTER, 'cast_failure', spell=rank_id))
        if any(step['metric'].startswith('aura_') for step in after_cast):
            effect = first_aura_effect(facts) or 0
            cast_steps.append(aura_measurement(f'{rank_id} aura_present', 'aura', effect))

    for aura in class_file.get('known_auras', []):
        expectations.append(Expectation(
            known_aura_label(aura), 'known_aura', aura, aura, None, str(aura), 'reference profile aura'))
    learn = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': rank_id}]
    budget = min(MAX_SCENARIO_STEPS - len(learn) - len(measured) - len(cast_steps) - len(after_cast),
                 READ_BUDGET_MS // READ_STEP_MS)
    sampled, samples = sampled_reads(measured, rolled, budget)
    expectations = [replace(item, model={**(item.model or {}), 'samples': samples[item.label]})
                    if item.check == 'effect_value' and item.label in samples else item for item in expectations]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spell.name} {rank_id}',
        'contract': 'No-combat check of the effect values, cost, cooldown and aura of one rank against its tooltip.',
        'players': [player_fixture(class_file)],
        'steps': learn + sampled + cast_steps + after_cast}
    if is_hostile(facts) and cast_wanted:
        scenario['creatures'] = [{'id': TARGET, 'owner': CASTER, 'entry': DUMMY_ENTRY, 'level': class_file['level'],
                                  'health': DUMMY_HEALTH, 'distance': DUMMY_DISTANCE}]
    return scenario, expectations
