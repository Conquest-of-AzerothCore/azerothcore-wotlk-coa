from dataclasses import dataclass
from functools import lru_cache
import math
from statistics import NormalDist, fmean, variance
from typing import Iterable, Sequence

from hits import APPLY_AURA, UNMODELLED, creature_fixture, records_of, reference_caster, scenario_shell, timed
from procs import AMBIGUOUS_TOOLTIP, ENTRY_STATUSES
from profile import CASTER, SETTLE_MS, measurement
from tooltip import read_tooltip
from values import TARGET, Expectation

STACK_KIND = 'stack'
STACK_DPS = 'stack_dps'
STACK_SOURCE = 'stack_source'
TALENT_DELTA = 'talent_delta'
STACK_CHECKS = frozenset({STACK_DPS, STACK_SOURCE, TALENT_DELTA})
MEASURED = 'measured'
MEASURED_RULE = 'measured: '
MELEE_SOURCE = 0
PASSES = 5
MINIMUM_PASSES = 2
TWO_SIDED_99 = 0.995
QUANTILE_STEPS = 2000
BISECTIONS = 100
CLASS_MASK_WORDS = 3
ADD_PCT_MODIFIER = 108
SPELLMOD_DAMAGE = 0
RATIO = 'ratio'
MULTIPLIES = 'multiplies'
ADDS = 'adds'
HEALTH_START = 'stack target health start'
HEALTH_END = 'stack target health end'
DPS_RULE = (MEASURED_RULE + 'health the target lost from the start of the rotation to the end of the drain, per '
            'second of rotation')
SOURCE_RULE = (MEASURED_RULE + 'damage of the source on the target (every direct and periodic hit), per second of '
               'rotation')
CONTRACT = ('One pass of a fixed rotation with the cumulative talents of a stack configuration: damage in total and '
            'per source.')


@dataclass(frozen=True)
class Lever:
    config: str
    dps_mean: float | None
    dps_low: float | None
    dps_high: float | None
    delta_pct: float | None
    sources: dict[int, float]
    tooltip_delta_pct: float | None


@lru_cache(maxsize=None)
def student_t_quantile(probability: float, dof: float) -> float:
    if not 0.5 < probability < 1:
        raise ValueError(f'No two-sided quantile at probability {probability}')
    if math.isinf(dof):
        return NormalDist().inv_cdf(probability)
    if dof < 1:
        raise ValueError(f'{dof} degrees of freedom are fewer than one')
    scale = math.exp(math.lgamma((dof + 1) / 2) - math.lgamma(dof / 2)) / math.sqrt(math.pi)

    def area(theta: float) -> float:
        step = theta / QUANTILE_STEPS
        total = 1.0 + math.cos(theta) ** (dof - 1)
        for index in range(1, QUANTILE_STEPS):
            total += (4 if index % 2 else 2) * math.cos(index * step) ** (dof - 1)
        return scale * total * step / 3

    low, high = 0.0, math.pi / 2
    for _ in range(BISECTIONS):
        middle = (low + high) / 2
        if area(middle) < probability - 0.5:
            low = middle
        else:
            high = middle
    return math.sqrt(dof) * math.tan((low + high) / 2)


def mean_interval(values: Sequence[float]) -> tuple[float, float, float]:
    if len(values) < MINIMUM_PASSES:
        raise ValueError(f'{len(values)} passes have no interval')
    mean = fmean(values)
    spread = variance(values)
    if spread == 0:
        return mean, mean, mean
    half = student_t_quantile(TWO_SIDED_99, len(values) - 1) * math.sqrt(spread / len(values))
    return mean, mean - half, mean + half


def ratio_interval(current: Sequence[float], baseline: Sequence[float]) -> tuple[float, float, float]:
    if min(len(current), len(baseline)) < MINIMUM_PASSES:
        raise ValueError(f'{len(current)} and {len(baseline)} passes have no interval')
    upper, lower = fmean(current), fmean(baseline)
    if upper <= 0 or lower <= 0:
        raise ValueError(f'means {upper} and {lower} have no ratio')
    ratio = upper / lower
    upper_share = variance(current) / len(current) / upper ** 2
    lower_share = variance(baseline) / len(baseline) / lower ** 2
    delta = (ratio - 1) * 100
    if upper_share + lower_share == 0:
        return delta, delta, delta
    dof = (upper_share + lower_share) ** 2 / (upper_share ** 2 / (len(current) - 1)
                                               + lower_share ** 2 / (len(baseline) - 1))
    half = student_t_quantile(TWO_SIDED_99, dof) * ratio * math.sqrt(upper_share + lower_share) * 100
    return delta, delta - half, delta + half


def source_labels(spell: int) -> dict[str, str]:
    prefix = 'stack melee' if spell == MELEE_SOURCE else f'stack source {spell}'
    return {'total': f'{prefix} total', 'count': f'{prefix} count', 'plain_total': f'{prefix} plain total',
            'plain_count': f'{prefix} plain count'}


def cast_label(spell: int) -> str:
    return f'stack source {spell} casts'


def source_steps(spell: int) -> list[dict]:
    labels = source_labels(spell)
    if spell == MELEE_SOURCE:
        return [measurement(labels['total'], CASTER, 'melee_damage_total', target=TARGET),
                measurement(labels['count'], CASTER, 'melee_damage_count', target=TARGET)]
    plain = {'critical': False, 'blocked': False}
    return [measurement(labels['total'], CASTER, 'spell_damage_total', spell=spell, target=TARGET),
            measurement(labels['count'], CASTER, 'spell_damage_count', spell=spell, target=TARGET),
            measurement(labels['plain_total'], CASTER, 'spell_damage_total', spell=spell, target=TARGET, **plain),
            measurement(labels['plain_count'], CASTER, 'spell_damage_count', spell=spell, target=TARGET, **plain)]


def rotation_ms(rotation: dict) -> int:
    return rotation['cycles'] * sum(step['ms'] for step in rotation['cycle'] if step['action'] == 'wait')


def rotation_steps(rotation: dict) -> list[dict]:
    steps = []
    power = rotation.get('set_power')
    if power:
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': power['power'], 'value': power['value']})
    steps.append(measurement(HEALTH_START, TARGET, 'health'))
    if rotation.get('auto_attack'):
        steps.append({'action': 'attack', 'actor': CASTER, 'target': TARGET})
    for step in rotation['cycle']:
        if step.get('target', TARGET) != TARGET:
            raise ValueError(f'Rotation step {step} targets {step["target"]}, not the fixture {TARGET}')
    cycle = [dict(step) if step['action'] == 'wait' else {**step, 'actor': CASTER} for step in rotation['cycle']]
    for _ in range(rotation['cycles']):
        steps += [dict(step) for step in cycle]
    if rotation.get('auto_attack'):
        steps.append({'action': 'stop_attack', 'actor': CASTER})
    steps.append({'action': 'wait', 'label': 'drain', 'ms': rotation['drain_ms']})
    steps.append(measurement(HEALTH_END, TARGET, 'health'))
    return steps


def class_mask(records, talent: int, effect: int) -> list[int]:
    return [records.field('Spell', talent, f'EffectSpellClassMask[{CLASS_MASK_WORDS * effect + word}]')
            for word in range(CLASS_MASK_WORDS)]


def family_flags(records, spell: int) -> list[int]:
    return [records.field('Spell', spell, f'SpellFamilyFlags[{word}]') for word in range(CLASS_MASK_WORDS)]


def modifier_effect(records, entry: dict) -> int:
    talent, source = entry['talent'], entry['source']
    flags = family_flags(records, source)
    family = records.field('Spell', source, 'SpellFamilyName')
    if records.field('Spell', talent, 'SpellFamilyName') != family:
        raise ValueError(f'Talent {talent} and source {source} belong to different spell families')
    for effect in range(CLASS_MASK_WORDS):
        if records.field('Spell', talent, f'Effect[{effect}]') != APPLY_AURA:
            continue
        if any(mask & flag for mask, flag in zip(class_mask(records, talent, effect), flags)):
            return effect
    raise ValueError(f'No effect of talent {talent} has a class mask that matches the SpellFamilyFlags {flags} of '
                     f'{source}')


def tooltip_value(class_file: dict, spell: int, token: str):
    readout = read_tooltip(records_of(class_file).dbc, spell, reference_caster(class_file))
    return next((value for value in readout.values if value.text == token), None)


def fixed_bonus(class_file: dict, entry: dict) -> dict:
    records = records_of(class_file)
    talent, source = entry['talent'], entry['source']
    effect = modifier_effect(records, entry)
    aura = records.field('Spell', talent, f'EffectApplyAuraName[{effect}]')
    misc = records.field('Spell', talent, f'EffectMiscValue[{effect}]')
    mask = class_mask(records, talent, effect)
    cite = (f'Spell.dbc {talent} effect {effect}: aura {aura}, misc {misc}, class mask {mask} matching the '
            f'SpellFamilyFlags {family_flags(records, source)} of {source}')
    if (aura, misc) != (ADD_PCT_MODIFIER, SPELLMOD_DAMAGE):
        return {'rule': UNMODELLED + f'{cite} is not a percent damage modifier (aura {ADD_PCT_MODIFIER} '
                                     f'SPELL_AURA_ADD_PCT_MODIFIER, misc {SPELLMOD_DAMAGE} SPELLMOD_DAMAGE), so no '
                                     f'ratio of the hits of {source} follows from {entry["token"]}'}
    shown = tooltip_value(class_file, talent, entry['token'])
    if shown is None:
        raise ValueError(f'The tooltip of {talent} shows no {entry["token"]}')
    if shown.effect_index != effect:
        return {'rule': UNMODELLED + f'{entry["token"]} shows effect {shown.effect_index} of {talent}, while {cite} '
                                     f'is the effect that changes {source}'}
    return {'effect': effect, 'bonus_pct': shown.value,
            'rule': (f'{RATIO}: {talent} multiplies the non-critical, unblocked hits of {source} by 1 + '
                     f'{entry["token"]}/100 against the previous configuration; tooltip "{entry["claim"]}"; '
                     f'{cite}, aura {ADD_PCT_MODIFIER} SPELL_AURA_ADD_PCT_MODIFIER with misc {SPELLMOD_DAMAGE} '
                     f'SPELLMOD_DAMAGE, a percent of the damage of the spell')}


def talent_expectations(class_file: dict, index: int, passes: int) -> list[Expectation]:
    configs = class_file['stack']
    config = configs[index]
    added = config['talents']
    earlier = [talent for previous in configs[:index] for talent in previous['talents']]
    entries = class_file.get('talent_modifiers', [])
    expectations = []
    for entry in (entry for entry in entries if entry['talent'] in added):
        talent, source = entry['talent'], entry['source']
        label = f'stack {config["name"]} talent_delta {talent} {source}'
        model = {'config': config['name'], 'baseline': configs[index - 1]['name'] if index else None,
                 'index': index, 'passes': passes, 'source': source, 'token': entry['token'],
                 'measurements': {'total': source_labels(source)['plain_total'],
                                  'count': source_labels(source)['plain_count']}}

        def expect(rule: str, effect_index: int | None = None, **fields):
            expectations.append(Expectation(label, TALENT_DELTA, talent, talent, effect_index, entry['token'], rule,
                                            {**model, **fields}))

        if entry.get('status'):
            if entry['status'] not in ENTRY_STATUSES:
                raise ValueError(f'Talent {talent} status {entry["status"]!r} is not one of {sorted(ENTRY_STATUSES)}')
            expect(ENTRY_STATUSES[entry['status']] + entry['reason'])
            continue
        if not index:
            raise ValueError(f'Talent {talent} is learned in the first configuration, which has no baseline')
        bonus = fixed_bonus(class_file, entry)
        if 'bonus_pct' not in bonus:
            expect(bonus['rule'])
            continue
        alongside = [other['talent'] for other in entries
                     if other is not entry and other['talent'] in added and other['source'] == source]
        if alongside:
            expect(UNMODELLED + f'the delta of {source} in {config["name"]} also holds the change of talents '
                                f'{alongside} learned with {talent}')
            continue
        before = [(other, None if other.get('status') else fixed_bonus(class_file, other)) for other in entries
                  if other['talent'] in earlier and other['source'] == source]
        unstated = [other['talent'] for other, found in before if not found or 'bonus_pct' not in found]
        if unstated:
            expect(AMBIGUOUS_TOOLTIP + f'the tooltips do not say how {entry["token"]} of {talent} combines with the '
                                       f'change of {source} by talents {unstated} of an earlier configuration, '
                                       f'whose amount is not a stated percent of its damage')
            continue
        earlier_bonuses = [{'talent': other['talent'], 'token': other['token'], 'bonus_pct': found['bonus_pct']}
                           for other, found in before]
        expect(bonus['rule'], bonus['effect'], bonus_pct=bonus['bonus_pct'], effect=bonus['effect'],
               composition=RATIO, earlier_bonuses=earlier_bonuses,
               school_mask=records_of(class_file).field('Spell', source, 'SchoolMask'))
    return expectations


def checked_configs(class_file: dict) -> list[dict]:
    configs = class_file.get('stack') or []
    if not configs or not class_file.get('rotation'):
        raise ValueError(f'The {class_file["name"]} class file has no rotation or stack')
    names = [config['name'] for config in configs]
    if len(set(names)) != len(names):
        raise ValueError(f'Stack configuration names repeat: {names}')
    talents = [talent for config in configs for talent in config['talents']]
    if len(set(talents)) != len(talents):
        raise ValueError(f'Stack talents repeat: {talents}')
    rotation = class_file['rotation']
    records = records_of(class_file)
    for spell in rotation['learn'] + talents + rotation['sources']:
        if not records.has_spell(spell):
            raise ValueError(f'Spell {spell} of the stack is not in Spell.dbc')
    return configs


def stack_scenarios(class_file: dict, passes: int = PASSES) -> list[tuple[dict, list[Expectation]]]:
    if passes < MINIMUM_PASSES:
        raise ValueError(f'{passes} passes give no interval; at least {MINIMUM_PASSES} are needed')
    configs = checked_configs(class_file)
    rotation = class_file['rotation']
    duration = rotation_ms(rotation)
    sources = rotation['sources'] + [MELEE_SOURCE]
    measured = [step for spell in sources for step in source_steps(spell)]
    measured += [measurement(cast_label(spell), CASTER, 'spell_cast_count', spell=spell)
                 for spell in rotation.get('cast_sources', [])]
    learned = list(rotation['learn'])
    result = []
    for index, config in enumerate(configs):
        learned += config['talents']
        common = {'config': config['name'], 'index': index, 'passes': passes, 'talents': list(config['talents']),
                  'learned': list(learned), 'rotation_ms': duration}
        expectations = [Expectation(f'stack {config["name"]} dps', STACK_DPS, 0, 0, None, '', DPS_RULE,
                                    {**common, 'measurements': {'health_start': HEALTH_START,
                                                                'health_end': HEALTH_END}})]
        expectations += [Expectation(f'stack {config["name"]} source {spell}', STACK_SOURCE, spell, spell, None, '',
                                     SOURCE_RULE, {**common, 'source': spell, 'measurements': {
                                         part: source_labels(spell)[part] for part in ('total', 'count')}})
                         for spell in sources]
        expectations += talent_expectations(class_file, index, passes)
        steps = ([{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
                 + rotation_steps(rotation) + measured)
        for number in range(passes):
            name = f'Conformance stack {class_file["name"]} {config["name"]} pass {number + 1} of {passes}'
            scenario = scenario_shell(class_file, name, CONTRACT, [dict(step) for step in steps])
            scenario['creatures'] = [creature_fixture(class_file)]
            result.append((timed(scenario, SETTLE_MS + duration + rotation['drain_ms']), list(expectations)))
    return result


def stack_verdicts(verdicts: Iterable, check: str) -> list:
    return [verdict for verdict in verdicts if verdict.check == check and verdict.detail]


def levers(verdicts) -> list[Lever]:
    verdicts = list(verdicts)
    configurations = sorted(stack_verdicts(verdicts, STACK_DPS), key=lambda verdict: verdict.detail['index'])
    result = []
    previous = None
    for verdict in configurations:
        config = verdict.detail['config']
        sources = {source.spell_id: source.measured for source in stack_verdicts(verdicts, STACK_SOURCE)
                   if source.detail['config'] == config and source.measured is not None}
        bonuses = [delta.expected for delta in stack_verdicts(verdicts, TALENT_DELTA)
                   if delta.detail['config'] == config and delta.expected is not None]
        delta = None
        if previous is not None and previous.measured and verdict.measured is not None:
            delta = (verdict.measured / previous.measured - 1) * 100
        result.append(Lever(config=config, dps_mean=verdict.measured, dps_low=verdict.low, dps_high=verdict.high,
                            delta_pct=delta, sources=sources,
                            tooltip_delta_pct=bonuses[0] if len(bonuses) == 1 else None))
        previous = verdict
    return result
