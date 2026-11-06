from dataclasses import dataclass, field, replace
from functools import lru_cache
from pathlib import Path
import re

from classes import PROGRESSION_HEADER, PROGRESSION_ROW, ClassSpell, table_rows
from profile import CASTER, DBC_DIR, stat_label
from stack import class_mask, family_flags
from tooltip import COLOR_CODE, Displayed, Records, Unreadable, read_tooltip
from values import EFFECTS, TARGET, dataset, structure_stats

UNMODELLED = 'unmodelled: '
UNKNOWN = 'unknown'
SCRIPTED = 'P6'
EFFECT_DUMMY = 3
ADD_FLAT_MODIFIER = 107
ADD_PCT_MODIFIER = 108
MAX_SPELLMOD = 32
SPELL_MODIFIER_BASE = 1000
COMBAT_RATINGS = 25
ALL_STATS = -1
PHYSICAL_SCHOOL_MASK = 1
MAGIC_SCHOOLS = range(1, 7)
SCHOOLS = range(7)

FAMILIES = {
    **dict.fromkeys((107, 108), 'P1'),
    **dict.fromkeys((29, 31, 47, 49, 132, 133, 137, 138, 142, 166, 167, 174, 220, 237, 240, 290, 327, 333), 'P2'),
    **dict.fromkeys((59, 79, 118, 122, 136, 163, 286, 303), 'P3'),
    **dict.fromkeys((87, 229, 283), 'P4'),
    **dict.fromkeys((42, 354, 23, 231), 'P5'),
    **dict.fromkeys((4, 232, 112, 178), 'P6'),
    **dict.fromkeys((72, 110), 'P7'),
}
OUT_OF_SCOPE = {
    142: 'mail armor is out of scope',
    59: 'damage versus a creature type is level-scaled',
    122: 'no off-hand weapon damage metric',
    110: 'no energy regeneration metric',
}
FAMILY_REASONS = {
    'P5': 'proc or trigger effect without a trigger entry',
    'P6': 'scripted or crowd-control effect',
}
SPELL_MODIFIER_CONSUMERS = {
    14: ('spell_power_cost', {}),
    10: ('spell_cast_time_ms', {}),
    5: ('spell_max_range', {}),
    31: ('spell_max_stacks', {}),
    3: ('spell_effect_value', {'effect': 0}),
    12: ('spell_effect_value', {'effect': 1}),
    23: ('spell_effect_value', {'effect': 2}),
    7: ('spell_done_crit_chance', {'target': TARGET}),
}

STAT_NAMES = ('Strength', 'Agility', 'Stamina', 'Intellect', 'Spirit')
ALL_STATS_QUANTITY = 'all primary attributes'
ATTACK_POWER = 'attack power'
SOURCE_LABELS = {**{name.lower(): stat_label(stat) for stat, name in enumerate(STAT_NAMES)},
                 ATTACK_POWER: 'attack_power'}
SCHOOL_NAMES = {1: 'Holy', 2: 'Fire', 3: 'Nature', 4: 'Frost', 5: 'Shadow', 6: 'Arcane'}
POWER_NAMES = {0: 'mana', 1: 'rage', 2: 'focus', 3: 'Energy', 6: 'runic power'}
RATING_NAMES = {1: 'defense rating', 2: 'dodge rating', 3: 'parry rating', 4: 'block rating',
                **dict.fromkeys((5, 6, 7), 'hit rating'), **dict.fromkeys((8, 9, 10), 'critical strike rating'),
                **dict.fromkeys((17, 18, 19), 'haste rating'), 23: 'expertise rating', 24: 'armor penetration'}
CRIT_CHANCE = 'critical strike chance'
SPELL_POWER = 'spell power'

PHRASES: dict[str, tuple[str, ...]] = {
    **{name: (name,) for name in STAT_NAMES},
    ALL_STATS_QUANTITY: (ALL_STATS_QUANTITY, 'all attributes', 'all stats'),
    'maximum health': ('maximum health',),
    **{name: (name,) for name in POWER_NAMES.values()},
    ATTACK_POWER: (ATTACK_POWER,),
    'ranged attack power': ('ranged attack power',),
    'expertise': ('expertise',),
    'parry chance': ('parry chance', 'parry and dodge chance', 'chance to parry'),
    'dodge chance': ('dodge chance', 'chance to dodge'),
    CRIT_CHANCE: (CRIT_CHANCE, 'chance to critically strike'),
    **{f'{school} {CRIT_CHANCE}': (f'{school} {CRIT_CHANCE}',) for school in SCHOOL_NAMES.values()},
    'chance to hit': ('chance to hit', 'hit chance'),
    'melee haste': ('melee haste', 'attack speed'),
    **{name: (name,) for name in RATING_NAMES.values()},
    SPELL_POWER: (SPELL_POWER,),
    **{f'{school} spell damage': (f'{school} spell damage', f'{school} spell power')
       for school in SCHOOL_NAMES.values()},
    'damage dealt': ('damage dealt', 'damage done'),
    'healing done': ('healing done',),
    'healing received': ('healing received', 'healing taken', 'receive'),
    'critical damage': ('critical damage', 'critical strike damage'),
    'damage': ('damage',),
    'damage taken from area of effect': ('damage taken from area of effect', 'area of effect damage'),
    'cost': ('cost',),
}

SHAREABLE_TOKEN = re.compile(r'\$(?:/\d+;)?s[1-3]')
CATEGORY_WORD = re.compile(r'[A-Z][a-z]{3,}\b')
LINE_BREAKS = re.compile(r'\s+')


@dataclass(frozen=True)
class MetricPlan:
    metric: str
    fields: dict = field(hash=False)
    relation: str
    source: str | None = None


@dataclass(frozen=True)
class PassiveTarget:
    spell_id: int
    name: str
    named: bool
    in_mask: bool


@dataclass(frozen=True)
class PassiveEffect:
    spell_id: int
    effect: int
    aura: int
    misc: int
    misc_b: int
    family: str
    token: Displayed | None
    plans: tuple[MetricPlan, ...]
    targets: tuple[PassiveTarget, ...]
    reason: str


class NotModelled(Exception):
    pass


def family_of(effect: int, aura: int) -> str:
    if effect == EFFECT_DUMMY:
        return SCRIPTED
    return FAMILIES.get(aura, UNKNOWN)


def stat_after_token(text: str, token: str) -> str | None:
    names = '|'.join([*STAT_NAMES, ATTACK_POWER])
    match = re.search(re.escape(token) + rf'%\s+of\s+(?:your\s+)?({names})\b', text, re.IGNORECASE)
    return match.group(1) if match else None


def cleaned_tooltip(description: str) -> str:
    return LINE_BREAKS.sub(' ', COLOR_CODE.sub('', description))


def names_phrase(text: str, quantity: str) -> bool:
    lowered = text.lower()
    return any(phrase.lower() in lowered for phrase in PHRASES[quantity])


@lru_cache(maxsize=None)
def progression_ranks(header: Path) -> dict[int, tuple[int, tuple[tuple[int, int], ...]]]:
    chains: dict[int, list[tuple[int, int]]] = {}
    for _, first_spell, spell, required_level in PROGRESSION_ROW.findall(header.read_text(encoding='utf-8')):
        chains.setdefault(int(first_spell), []).append((int(spell), int(required_level)))
    ranks = {}
    for first_spell, chain in chains.items():
        for spell in [first_spell] + [rank for rank, _ in chain]:
            ranks[spell] = (first_spell, tuple(chain))
    return ranks


def class_level_ranks(spell_ids: set[int], level: int) -> list[int]:
    ranks = progression_ranks(PROGRESSION_HEADER)
    chains = {ranks[spell] for spell in spell_ids if spell in ranks}
    if not chains:
        return sorted(spell_ids)
    reached = set()
    for first_spell, chain in chains:
        reached.add(([first_spell] + [rank for rank, required in chain if required <= level])[-1])
    return sorted(reached)


@lru_cache(maxsize=None)
def family_spells(records_dbc, family_name: int) -> dict[int, tuple[str, tuple[int, ...]]]:
    records = Records(records_dbc)
    return {identity: (fields['SpellName[enUS]'], tuple(family_flags(records, identity)))
            for identity, fields in table_rows(records_dbc, 'Spell', ['SpellName[enUS]', 'SpellFamilyName'])
            if fields['SpellFamilyName'] == family_name and fields['SpellName[enUS]']}


def spells_by_name(spells: dict[int, tuple[str, tuple[int, ...]]]) -> dict[str, set[int]]:
    names: dict[str, set[int]] = {}
    for identity, (name, _) in spells.items():
        names.setdefault(name, set()).add(identity)
    return names


@lru_cache(maxsize=None)
def name_patterns(records_dbc, family_name: int) -> tuple[tuple[str, frozenset[int], re.Pattern], ...]:
    names = spells_by_name(family_spells(records_dbc, family_name))
    return tuple((name, frozenset(names[name]), re.compile(rf'(?<!\w){re.escape(name)}(?!\w)'))
                 for name in sorted(names, key=lambda candidate: (-len(candidate), candidate)))


def named_targets(records: Records, family_name: int, text: str, level: int) -> list[PassiveTarget]:
    claimed: list[tuple[int, int]] = []
    targets = []
    for name, spell_ids, pattern in name_patterns(records.dbc, family_name):
        if name not in text:
            continue
        free = [match.span() for match in pattern.finditer(text)
                if not any(start < match.end() and match.start() < end for start, end in claimed)]
        if free:
            claimed += free
            targets += [PassiveTarget(spell_id, name, True, False)
                        for spell_id in class_level_ranks(set(spell_ids), level)]
    return targets


def overridden_targets(records: Records, override: dict, text: str) -> list[PassiveTarget]:
    words = override['tooltip_words']
    if words not in text:
        raise ValueError(f'passive_targets of {override["spell"]} effect {override["effect"]} quotes "{words}", '
                         f'which its tooltip does not contain')
    return [PassiveTarget(spell_id, records.field('Spell', spell_id, 'SpellName[enUS]'), True, False)
            for spell_id in override['targets']]


def category_holds(names: list[str], text: str) -> bool:
    def first_word_in_tooltip(name: str) -> bool:
        word = CATEGORY_WORD.match(name)
        return bool(word) and re.search(rf'(?<!\w){word.group(0)}', text) is not None

    return bool(names) and all(first_word_in_tooltip(name) for name in names)


def modifier_targets(records: Records, rank_id: int, effect: int, text: str, level: int,
                     override: dict | None) -> tuple[tuple[PassiveTarget, ...], str]:
    family_name = records.field('Spell', rank_id, 'SpellFamilyName')
    spells = family_spells(records.dbc, family_name)
    mask = class_mask(records, rank_id, effect)
    in_mask = {identity for identity, (_, flags) in spells.items()
               if any(word & flag for word, flag in zip(mask, flags))}
    named = (overridden_targets(records, override, text) if override
             else named_targets(records, family_name, text, level))
    named = [replace(target, in_mask=target.spell_id in in_mask) for target in named]
    named_names = {target.name for target in named}
    mask_names = spells_by_name({identity: spells[identity] for identity in in_mask})
    mask_only = [PassiveTarget(spell_id, name, False, True) for name in sorted(mask_names)
                 if name not in named_names for spell_id in class_level_ranks(mask_names[name], level)]
    targets = tuple(named + mask_only)
    if named or category_holds(sorted(mask_names), text):
        return targets, ''
    return targets, (UNMODELLED + 'the tooltip names none of the spells the class mask affects '
                     f'({", ".join(sorted(mask_names))})')


def own_token(values: list[Displayed], effect: int) -> Displayed | None:
    return next((value for value in values if value.effect_index == effect), None)


def shared_token(records: Records, rank_id: int, effect: int, effects: list[int],
                 values: list[Displayed]) -> Displayed | None:
    try:
        points = abs(records.single_value(rank_id, effect))
    except Unreadable:
        return None
    for sibling in effects:
        token = own_token(values, sibling) if sibling != effect else None
        if token is None or not SHAREABLE_TOKEN.fullmatch(token.text):
            continue
        try:
            if abs(records.single_value(rank_id, sibling)) == points:
                return token
        except Unreadable:
            continue
    return None


def bits(mask: int, positions) -> list[int]:
    return [position for position in positions if mask & (1 << position)]


def stat_plans(metric_relation: str, misc: int) -> list[tuple[MetricPlan, str]]:
    if misc == ALL_STATS:
        return [(MetricPlan('stat', {'stat': stat}, metric_relation), ALL_STATS_QUANTITY)
                for stat in range(len(STAT_NAMES))]
    if not 0 <= misc < len(STAT_NAMES):
        raise NotModelled(f'stat {misc} is not a primary attribute')
    return [(MetricPlan('stat', {'stat': misc}, metric_relation), STAT_NAMES[misc])]


def school_spell_power_plans(misc: int) -> list[tuple[MetricPlan, str]]:
    schools = bits(misc, MAGIC_SCHOOLS)
    if not schools:
        raise NotModelled(f'school mask {misc} holds no magic school')
    if len(schools) == len(MAGIC_SCHOOLS):
        return [(MetricPlan('spell_power', {'school': school}, 'share'), SPELL_POWER) for school in schools]
    return [(MetricPlan('spell_power', {'school': school}, 'share'), f'{SCHOOL_NAMES[school]} spell damage')
            for school in schools]


def rating_plans(misc: int) -> list[tuple[MetricPlan, str]]:
    ratings = bits(misc, range(32))
    if not ratings:
        raise NotModelled(f'rating mask {misc} holds no combat rating')
    unnamed = [rating for rating in ratings if rating >= COMBAT_RATINGS or rating not in RATING_NAMES]
    if unnamed:
        raise NotModelled(f'combat rating {unnamed[0]} has no tooltip phrase')
    return [(MetricPlan('combat_rating', {'rating': rating}, 'share'), RATING_NAMES[rating]) for rating in ratings]


def crit_plans(text: str) -> list[tuple[MetricPlan, str]]:
    for school, name in SCHOOL_NAMES.items():
        quantity = f'{name} {CRIT_CHANCE}'
        if names_phrase(text, quantity):
            return [(MetricPlan('spell_crit_chance', {'school': school}, 'add'), quantity)]
    return [(MetricPlan('melee_crit_chance', {}, 'add'), CRIT_CHANCE)]


def power_plans(misc: int) -> list[tuple[MetricPlan, str]]:
    if misc not in POWER_NAMES:
        raise NotModelled(f'power {misc} has no tooltip phrase')
    return [(MetricPlan('max_power', {'power': misc}, 'scale'), POWER_NAMES[misc])]


def damage_done_plans(misc: int) -> list[tuple[MetricPlan, str]]:
    plans = []
    if misc & ~PHYSICAL_SCHOOL_MASK:
        plans.append((MetricPlan('spell_damage_done', {'target': TARGET}, 'composition'), 'damage dealt'))
    if misc & PHYSICAL_SCHOOL_MASK:
        plans.append((MetricPlan('melee_damage_done', {'target': TARGET}, 'composition'), 'damage dealt'))
    return plans


def aura_plans(aura: int, misc: int, text: str) -> list[tuple[MetricPlan, str]]:
    if aura == 29:
        return stat_plans('add', misc)
    if aura == 137:
        return stat_plans('scale', misc)
    if aura == 327:
        if not 0 <= misc < len(STAT_NAMES):
            raise NotModelled(f'stat {misc} is not a primary attribute')
        return [(MetricPlan('stat', {'stat': misc}, 'share'), STAT_NAMES[misc])]
    simple = {
        133: ('max_health', {}, 'scale', 'maximum health'),
        166: ('attack_power', {}, 'scale', ATTACK_POWER),
        167: ('ranged_attack_power', {}, 'scale', 'ranged attack power'),
        240: ('expertise', {}, 'add', 'expertise'),
        47: ('parry_chance', {}, 'add', 'parry chance'),
        49: ('dodge_chance', {}, 'add', 'dodge chance'),
        138: ('attack_time_ms', {'hand': 0}, 'haste', 'melee haste'),
        136: ('spell_healing_done', {'target': CASTER}, 'composition', 'healing done'),
        118: ('spell_healing_taken', {'target': CASTER}, 'ratio', 'healing received'),
        163: ('spell_critical_damage', {'target': TARGET}, 'crit_damage', 'critical damage'),
        303: ('spell_damage_done', {'target': TARGET}, 'ratio', 'damage'),
        72: ('spell_power_cost', {}, 'scale', 'cost'),
    }
    if aura in simple:
        metric, fields, relation, quantity = simple[aura]
        return [(MetricPlan(metric, dict(fields), relation), quantity)]
    if aura == 132:
        return power_plans(misc)
    if aura == 290:
        return crit_plans(text)
    if aura == 333:
        return [(MetricPlan('melee_hit_chance', {}, 'add'), 'chance to hit'),
                (MetricPlan('spell_hit_chance', {}, 'add'), 'chance to hit')]
    if aura == 220:
        return rating_plans(misc)
    if aura in (174, 237):
        return school_spell_power_plans(misc)
    if aura == 79:
        return damage_done_plans(misc)
    if aura == 229:
        return [(MetricPlan('aoe_damage_taken', {'school': school}, 'ratio'), 'damage taken from area of effect')
                for school in bits(misc, SCHOOLS)]
    raise NotModelled(f'aura {aura} has no passive measurement')


def modifier_plans(aura: int, op: int) -> tuple[MetricPlan, ...]:
    relation, consumer_relation = (('spell_mod_flat', 'add') if aura == ADD_FLAT_MODIFIER
                                   else ('spell_mod_pct', 'scale'))
    plans = [MetricPlan('spell_modifier', {'op': op, 'base': SPELL_MODIFIER_BASE}, relation)]
    if op in SPELL_MODIFIER_CONSUMERS:
        metric, fields = SPELL_MODIFIER_CONSUMERS[op]
        plans.append(MetricPlan(metric, dict(fields), consumer_relation))
    return tuple(plans)


def sourced(plans: list[tuple[MetricPlan, str]], text: str, token: Displayed) -> list[tuple[MetricPlan, str]]:
    if not any(plan.relation == 'share' for plan, _ in plans):
        return plans
    stat = stat_after_token(text, token.text)
    if stat is None:
        raise NotModelled(f'the tooltip names no stat or attack power after {token.text}% of')
    return [(replace(plan, source=SOURCE_LABELS[stat.lower()]), quantity) for plan, quantity in plans]


def effect_plans(aura: int, misc: int, text: str, token: Displayed) -> tuple[MetricPlan, ...]:
    plans = sourced(aura_plans(aura, misc, text), text, token)
    missing = next((quantity for _, quantity in plans if not names_phrase(text, quantity)), None)
    if missing is not None:
        raise NotModelled(f'the tooltip does not name {missing}')
    if not plans:
        raise NotModelled(f'aura {aura} with misc value {misc} has no measured quantity')
    return tuple(plan for plan, _ in plans)


def passive_override(class_file: dict, rank_id: int, effect: int) -> dict | None:
    return next((entry for entry in class_file.get('passive_targets', [])
                 if entry['spell'] == rank_id and entry['effect'] == effect), None)


def classify(class_file: dict, records: Records, rank_id: int, effect: int, effects: list[int], text: str,
             values: list[Displayed]) -> PassiveEffect:
    def spell(name: str):
        return records.field('Spell', rank_id, name)

    aura = spell(f'EffectApplyAuraName[{effect}]')
    misc = spell(f'EffectMiscValue[{effect}]')
    misc_b = spell(f'EffectMiscValueB[{effect}]')
    family = family_of(spell(f'Effect[{effect}]'), aura)
    token = own_token(values, effect) or shared_token(records, rank_id, effect, effects, values)
    targets: tuple[PassiveTarget, ...] = ()
    plans: tuple[MetricPlan, ...] = ()
    reason = ''
    if family == 'P1':
        targets, reason = modifier_targets(records, rank_id, effect, text, class_file['level'],
                                           passive_override(class_file, rank_id, effect))
    try:
        if family == UNKNOWN:
            raise NotModelled(f'aura {aura} has no passive measurement' if aura
                              else f'effect {spell(f"Effect[{effect}]")} applies no aura')
        if family in FAMILY_REASONS:
            raise NotModelled(FAMILY_REASONS[family])
        if aura in OUT_OF_SCOPE:
            raise NotModelled(OUT_OF_SCOPE[aura])
        if family == 'P1' and misc >= MAX_SPELLMOD:
            raise NotModelled(f'SpellModOp {misc} is not below MAX_SPELLMOD {MAX_SPELLMOD}')
        if token is None:
            raise NotModelled('no own token and no sibling token with equal points')
        if family == 'P1':
            plans = () if reason else modifier_plans(aura, misc)
        else:
            plans = effect_plans(aura, misc, text, token)
    except NotModelled as error:
        plans, reason = (), UNMODELLED + str(error)
    return PassiveEffect(rank_id, effect, aura, misc, misc_b, family, token, plans, targets, reason)


def passive_effects(class_file: dict, spell: ClassSpell) -> list[PassiveEffect]:
    dbc = dataset(Path(class_file.get('dbc_dir', DBC_DIR)))
    records = Records(dbc)
    rank_id = spell.max_rank
    text = cleaned_tooltip(records.field('Spell', rank_id, 'Description[enUS]'))
    values = read_tooltip(dbc, rank_id, structure_stats(class_file['level'])).values
    effects = [effect for effect in EFFECTS if records.field('Spell', rank_id, f'Effect[{effect}]')]
    return [classify(class_file, records, rank_id, effect, effects, text, values) for effect in effects]
