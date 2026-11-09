from dataclasses import dataclass, field, replace
from functools import lru_cache
from pathlib import Path
import re

from classes import PROGRESSION_HEADER, PROGRESSION_ROW, ClassSpell, class_spells, table_rows
from hits import creature_fixture
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture, stat_label
from stack import class_mask, family_flags
from tooltip import COLOR_CODE, Displayed, Records, Unreadable, read_tooltip
from values import EFFECTS, TARGET, Expectation, dataset, facts_of, structure_stats

UNMODELLED = 'unmodelled: '
ALIASED_REASON_MARKER = ' reused from effect '
UNKNOWN = 'unknown'
SCRIPTED = 'P6'
EFFECT_DUMMY = 3
ADD_FLAT_MODIFIER = 107
ADD_PCT_MODIFIER = 108
MAX_SPELLMOD = 32
SPELL_MODIFIER_BASE = 1000
CLAMPED_AT_ZERO_OPS = frozenset({1, 10})
COMBAT_RATINGS = 25
ALL_STATS = -1
PHYSICAL_SCHOOL_MASK = 1
MAGIC_SCHOOLS = range(1, 7)
SCHOOLS = range(7)
ALL_SCHOOLS_MASK = 127
SCHOOL_DAMAGE_EFFECT = 2
HEAL_EFFECT = 10
VERSUS_AURA_STATE = 303
DAMAGE_DONE_PERCENT = 79
PARRY_CHANCE = 'parry_chance'
STAT_METRIC = 'stat'
STAT_EXACT_METRIC = 'stat_exact'
AURA_STATE_METRIC = 'has_aura_state'
AURA_STATE_WAIT_MS = 1000
PASSIVE_DELTA = 'passive_delta'
BEFORE = 'before'
AFTER = 'after'
SPELL_METRICS = frozenset({'spell_modifier', 'spell_power_cost', 'spell_cast_time_ms', 'spell_max_range',
                           'spell_max_stacks', 'spell_effect_value', 'spell_done_crit_chance', 'spell_damage_done',
                           'spell_critical_damage', 'spell_healing_done', 'spell_healing_taken'})
SCHOOL_DAMAGE = 'a school damage effect'
HEALING = 'a heal effect'
PLAIN_COST = 'a plain cost'
REFERENCE_KINDS = {'spell_damage_done': SCHOOL_DAMAGE, 'spell_critical_damage': SCHOOL_DAMAGE,
                   'spell_healing_done': HEALING, 'spell_healing_taken': HEALING, 'spell_power_cost': PLAIN_COST}

FAMILIES = {
    **dict.fromkeys((ADD_FLAT_MODIFIER, ADD_PCT_MODIFIER), 'P1'),
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
    15: ('spell_critical_damage', {'target': TARGET}, 'crit_damage'),
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
MELEE_CRIT_CHANCE = 'melee_crit_chance_refreshed'
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
PROPER_NOUN_CONTINUATION = re.compile(r' [A-Z]')
SENTENCE_BREAK = re.compile(r'(?<=[.!?])\s+')
LINE_BREAKS = re.compile(r'\s+')
COUNTER_CLAUSE = re.compile(
    r'\b(?:per\s+(?:trigger|stack|charge)\s+of|for\s+each\s+time\s+you\s+triggered)\s+'
    r'((?:[A-Z][\w\']*\s*)+)')


@dataclass(frozen=True)
class MetricPlan:
    metric: str
    fields: dict = field(hash=False)
    relation: str
    source: str | None = None
    judged: bool = True


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
    points: float | None = None


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


def reached_ranks(spell_ids: set[int], level: int) -> set[int]:
    ranks = progression_ranks(PROGRESSION_HEADER)
    chained = {spell for spell in spell_ids if spell in ranks}
    reached = set(class_level_ranks(chained, level)) if chained else set()
    return (reached | (spell_ids - chained)) & spell_ids


def without_counted_names(text: str) -> str:
    def blank(match: re.Match) -> str:
        prefix = match.group(0)[:match.start(1) - match.start()]
        return prefix + ' ' * len(match.group(1))

    return COUNTER_CLAUSE.sub(blank, text)


def named_targets(records: Records, family_name: int, text: str, level: int, in_mask: frozenset[int] = frozenset(),
                  sibling_mask: frozenset[int] = frozenset()) -> list[PassiveTarget]:
    text = without_counted_names(text)
    claimed: list[tuple[int, int]] = []
    targets = []
    for name, spell_ids, pattern in name_patterns(records.dbc, family_name):
        if name not in text:
            continue
        free = [match.span() for match in pattern.finditer(text)
                if not PROPER_NOUN_CONTINUATION.match(text, match.end())
                and not any(start < match.end() and match.start() < end for start, end in claimed)]
        if not free:
            continue
        claimed += free
        masked = reached_ranks(set(spell_ids) & in_mask, level)
        if masked:
            targets += [PassiveTarget(spell_id, name, True, True) for spell_id in sorted(masked)]
        elif not spell_ids & sibling_mask:
            targets += [PassiveTarget(spell_id, name, True, spell_id in in_mask)
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


def token_sentence(text: str, token: str | None) -> str:
    holding = [sentence for sentence in SENTENCE_BREAK.split(text) if token and token in sentence]
    return holding[0] if len(holding) == 1 else text


def mask_spells(spells: dict[int, tuple[str, tuple[int, ...]]], mask: list[int]) -> frozenset[int]:
    return frozenset(identity for identity, (_, flags) in spells.items()
                     if any(word & flag for word, flag in zip(mask, flags)))


def modifier_targets(records: Records, rank_id: int, effect: int, text: str, level: int,
                     override: dict | None, siblings: tuple[int, ...] = (),
                     token: str | None = None) -> tuple[tuple[PassiveTarget, ...], str]:
    family_name = records.field('Spell', rank_id, 'SpellFamilyName')
    spells = family_spells(records.dbc, family_name)
    in_mask = mask_spells(spells, class_mask(records, rank_id, effect))
    sibling_mask = frozenset().union(*(mask_spells(spells, class_mask(records, rank_id, sibling))
                                       for sibling in siblings)) - in_mask
    if override:
        named = [replace(target, in_mask=target.spell_id in in_mask)
                 for target in overridden_targets(records, override, text)]
    else:
        named = (named_targets(records, family_name, token_sentence(text, token), level, in_mask, sibling_mask)
                 or named_targets(records, family_name, text, level, in_mask, sibling_mask))
    names = spells_by_name(spells)
    claimed = {identity for target in named for identity in names.get(target.name, ())}
    claimed |= {target.spell_id for target in named}
    mask_names = spells_by_name({identity: spells[identity] for identity in in_mask - claimed})
    mask_only = [PassiveTarget(spell_id, name, False, True) for name in sorted(mask_names)
                 for spell_id in class_level_ranks(mask_names[name], level)]
    targets = tuple(named + mask_only)
    all_mask_names = sorted(spells_by_name({identity: spells[identity] for identity in in_mask}))
    if named or category_holds(all_mask_names, text):
        return targets, ''
    return targets, (UNMODELLED + 'the tooltip names none of the spells the class mask affects '
                     f'({", ".join(all_mask_names)})')


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


def aliased_token(records: Records, rank_id: int, effect: int, effects: list[int],
                  values: list[Displayed], text: str) -> tuple[Displayed | None, float | None]:
    for sibling in effects:
        if sibling == effect:
            continue
        candidates = (value for value in values
                     if value.effect_index == sibling and SHAREABLE_TOKEN.fullmatch(value.text))
        for token in candidates:
            holding_sentences = {sentence for sentence in SENTENCE_BREAK.split(text) if token.text in sentence}
            if len(holding_sentences) < 2:
                continue
            points = signed_points(records, rank_id, sibling)
            if points is None:
                continue
            return token, points
    return None, None


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
    return [(MetricPlan(MELEE_CRIT_CHANCE, {}, 'add'), CRIT_CHANCE)] + [
        (MetricPlan('spell_crit_chance', {'school': school}, 'add', judged=False), CRIT_CHANCE)
        for school in MAGIC_SCHOOLS]


def power_plans(misc: int) -> list[tuple[MetricPlan, str]]:
    if misc not in POWER_NAMES:
        raise NotModelled(f'power {misc} has no tooltip phrase')
    return [(MetricPlan('max_power', {'power': misc}, 'scale'), POWER_NAMES[misc])]


def damage_done_plans(misc: int) -> list[tuple[MetricPlan, str]]:
    plans = []
    if misc & ~PHYSICAL_SCHOOL_MASK:
        plans.append((MetricPlan('spell_damage_done', {'target': TARGET}, 'composition'), 'damage dealt'))
    if misc & PHYSICAL_SCHOOL_MASK:
        plans.append((MetricPlan('weapon_damage_min', {'hand': 0}, 'ratio'), 'damage dealt'))
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
        47: (PARRY_CHANCE, {}, 'add', 'parry chance'),
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


def modifier_base(aura: int, op: int, points: float | None) -> int:
    if aura == ADD_FLAT_MODIFIER and op in CLAMPED_AT_ZERO_OPS and points is not None:
        return SPELL_MODIFIER_BASE + int(abs(points))
    return SPELL_MODIFIER_BASE


def modifier_plans(aura: int, op: int, points: float | None = None) -> tuple[MetricPlan, ...]:
    relation, consumer_relation = (('spell_mod_flat', 'add') if aura == ADD_FLAT_MODIFIER
                                   else ('spell_mod_pct', 'scale'))
    plans = [MetricPlan('spell_modifier', {'op': op, 'base': modifier_base(aura, op, points)}, relation)]
    if op in SPELL_MODIFIER_CONSUMERS:
        entry = SPELL_MODIFIER_CONSUMERS[op]
        metric, fields = entry[0], entry[1]
        plans.append(MetricPlan(metric, dict(fields), entry[2] if len(entry) > 2 else consumer_relation))
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


def passive_override(class_file: dict, spell_ids: set[int], effect: int) -> dict | None:
    return next((entry for entry in class_file.get('passive_targets', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)


def effect_override(class_file: dict, spell_ids: set[int], effect: int) -> int | None:
    entry = next((entry for entry in class_file.get('effect_overrides', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)
    return entry['misc_value'] if entry else None


def effect_note(class_file: dict, spell_ids: set[int], effect: int) -> str | None:
    entry = next((entry for entry in class_file.get('effect_notes', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)
    return entry['reason'] if entry else None


def effect_unmodelled(class_file: dict, spell_ids: set[int], effect: int) -> str | None:
    entry = next((entry for entry in class_file.get('unmodelled_effects', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)
    return entry['reason'] if entry else None


def signed_points(records: Records, rank_id: int, effect: int) -> float | None:
    try:
        return records.points(rank_id, effect, upper=False)
    except Unreadable:
        return None


def classify(class_file: dict, records: Records, spell_id: int, rank_id: int, effect: int, effects: list[int],
             text: str, values: list[Displayed]) -> PassiveEffect:
    def spell(name: str):
        return records.field('Spell', rank_id, name)

    aura = spell(f'EffectApplyAuraName[{effect}]')
    override = effect_override(class_file, {spell_id, rank_id}, effect)
    misc = override if override is not None else spell(f'EffectMiscValue[{effect}]')
    misc_b = spell(f'EffectMiscValueB[{effect}]')
    family = family_of(spell(f'Effect[{effect}]'), aura)
    token = own_token(values, effect) or shared_token(records, rank_id, effect, effects, values)
    alias_points: float | None = None
    alias_reason = ''
    if token is None:
        token, alias_points = aliased_token(records, rank_id, effect, effects, values, text)
        if token is not None:
            alias_reason = (f'token {token.text}{ALIASED_REASON_MARKER}{token.effect_index}; expected value '
                            f'follows effect {token.effect_index}, not own points')
    targets: tuple[PassiveTarget, ...] = ()
    plans: tuple[MetricPlan, ...] = ()
    reason = ''
    if family == 'P1':
        siblings = tuple(sibling for sibling in effects if sibling != effect
                         and family_of(spell(f'Effect[{sibling}]'), spell(f'EffectApplyAuraName[{sibling}]')) == 'P1')
        targets, reason = modifier_targets(records, rank_id, effect, text, class_file['level'],
                                           passive_override(class_file, {spell_id, rank_id}, effect), siblings,
                                           token.text if token else None)
    try:
        forced = effect_unmodelled(class_file, {spell_id, rank_id}, effect)
        if forced is not None:
            raise NotModelled(forced)
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
            plans = () if reason else modifier_plans(
                aura, misc, alias_points if alias_points is not None else signed_points(records, rank_id, effect))
        else:
            plans = effect_plans(aura, misc, text, token)
    except NotModelled as error:
        plans, reason = (), UNMODELLED + str(error)
    if not reason:
        reason = alias_reason
    if reason.startswith(UNMODELLED):
        note = effect_note(class_file, {spell_id, rank_id}, effect)
        if note is not None:
            reason = UNMODELLED + note
    points = alias_points if alias_points is not None else signed_points(records, rank_id, effect)
    return PassiveEffect(rank_id, effect, aura, misc, misc_b, family, token, plans, targets, reason, points)


def passive_effects(class_file: dict, spell: ClassSpell) -> list[PassiveEffect]:
    dbc = dataset(Path(class_file.get('dbc_dir', DBC_DIR)))
    records = Records(dbc)
    rank_id = spell.max_rank
    text = cleaned_tooltip(records.field('Spell', rank_id, 'Description[enUS]'))
    values = read_tooltip(dbc, rank_id, structure_stats(class_file)).values
    effects = [effect for effect in EFFECTS if records.field('Spell', rank_id, f'Effect[{effect}]')]
    return [classify(class_file, records, spell.spell_id, rank_id, effect, effects, text, values)
            for effect in effects]


@dataclass(frozen=True)
class Probe:
    label: str
    metric: str
    fields: dict = field(hash=False)
    target: int | None
    named: bool | None
    in_mask: bool | None
    reason: str = ''


@lru_cache(maxsize=None)
def active_class_ranks(dbc_dir: Path, class_id: int, level: int) -> tuple[int, ...]:
    return tuple(spell.max_rank for spell in class_spells(dbc_dir, class_id, PROGRESSION_HEADER, level)
                 if not spell.passive)


def serves(records: Records, rank_id: int, kind: str) -> bool:
    facts = facts_of(records, rank_id)
    if kind == PLAIN_COST:
        return facts.mana_cost > 0 and not facts.mana_cost_per_level and not facts.mana_cost_percentage
    return (SCHOOL_DAMAGE_EFFECT if kind == SCHOOL_DAMAGE else HEAL_EFFECT) in facts.effects


def reference_school_mask(effect: PassiveEffect) -> int:
    if effect.aura == VERSUS_AURA_STATE:
        return ALL_SCHOOLS_MASK
    if effect.aura == DAMAGE_DONE_PERCENT:
        return effect.misc & ~PHYSICAL_SCHOOL_MASK
    return effect.misc or ALL_SCHOOLS_MASK


def reference_spell(class_file: dict, records: Records, metric: str, school_mask: int) -> int:
    kind = REFERENCE_KINDS[metric]
    dbc_dir = Path(class_file.get('dbc_dir', DBC_DIR))
    for rank_id in active_class_ranks(dbc_dir, class_file['class_id'], class_file['level']):
        if records.field('Spell', rank_id, 'SchoolMask') & school_mask and serves(records, rank_id, kind):
            return rank_id
    raise NotModelled(f'no active class spell with {kind} in school mask {school_mask}')


def probe_label(rank_id: int, effect: int, metric: str, qualifiers) -> str:
    return ' '.join(str(part) for part in (rank_id, f'e{effect}', metric, *qualifiers))


def plan_probes(class_file: dict, records: Records, effect: PassiveEffect, plan: MetricPlan) -> list[Probe]:
    def probe(spell_id: int | None, named: bool | None = None, in_mask: bool | None = None,
              reason: str = '') -> Probe:
        fields = dict(plan.fields) if spell_id is None else {**plan.fields, 'spell': spell_id}
        qualifiers = ([spell_id] if spell_id is not None
                      else [value for key, value in plan.fields.items() if key != 'target'])
        return Probe(probe_label(effect.spell_id, effect.effect, plan.metric, qualifiers), plan.metric, fields,
                     spell_id, named, in_mask, reason)

    if plan.metric not in SPELL_METRICS:
        return [probe(None)]
    if effect.family == 'P1':
        probes = []
        for target in effect.targets:
            reason = ''
            if plan.metric == 'spell_effect_value' and not records.field(
                    'Spell', target.spell_id, f'Effect[{plan.fields["effect"]}]'):
                reason = UNMODELLED + f'target {target.spell_id} has no effect {plan.fields["effect"]}'
            elif plan.metric == 'spell_power_cost':
                facts = facts_of(records, target.spell_id)
                if not (facts.mana_cost or facts.mana_cost_per_level or facts.mana_cost_percentage):
                    reason = UNMODELLED + f'target {target.spell_id} has no power cost to modify'
            probes.append(probe(target.spell_id, target.named, target.in_mask, reason))
        return probes
    try:
        return [probe(reference_spell(class_file, records, plan.metric, reference_school_mask(effect)))]
    except NotModelled as error:
        return [probe(None, reason=UNMODELLED + str(error))]


def effect_model(effect: PassiveEffect) -> dict:
    return {'family': effect.family, 'effect': effect.effect, 'aura': effect.aura, 'misc': effect.misc}


def probe_model(effect: PassiveEffect, plan: MetricPlan, probe: Probe, aura_label: str) -> dict:
    measured = not probe.reason
    exact = measured and plan.metric == STAT_METRIC
    versus_aura_state = measured and effect.aura == VERSUS_AURA_STATE
    return {'family': effect.family, 'effect': effect.effect, 'aura': effect.aura, 'metric': plan.metric,
            'fields': probe.fields,
            'relation': plan.relation, 'source_label': plan.source,
            'before_label': f'{probe.label} {BEFORE}' if measured else None,
            'after_label': f'{probe.label} {AFTER}' if measured else None,
            'exact_before_label': f'{probe.label} exact {BEFORE}' if exact else None,
            'exact_after_label': f'{probe.label} exact {AFTER}' if exact else None,
            'aura_state_label': f'{probe.label} aura_state' if versus_aura_state else None,
            'target': probe.target, 'named': probe.named, 'in_mask': probe.in_mask, 'points': effect.points,
            'judged': plan.judged, 'aura_label': aura_label}


def passive_scenario(class_file: dict, spell: ClassSpell) -> tuple[dict | None, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    rank_id = spell.max_rank
    aura_label = f'{rank_id} aura_present'
    probes: list[Probe] = []
    expectations: list[Expectation] = []

    def expect(label: str, check: str, effect: PassiveEffect, rule: str, model: dict):
        expectations.append(Expectation(label, check, spell.spell_id, rank_id, effect.effect,
                                        effect.token.text if effect.token else '', rule, model))

    aura_state_steps: list[dict] = []
    for effect in passive_effects(class_file, spell):
        if not effect.plans:
            expect(f'{rank_id} e{effect.effect}', 'unmodelled', effect, effect.reason, effect_model(effect))
            continue
        for plan in effect.plans:
            for probe in plan_probes(class_file, records, effect, plan):
                model = probe_model(effect, plan, probe, aura_label)
                if probe.reason:
                    expect(probe.label, 'unmodelled', effect, probe.reason, model)
                    continue
                probes.append(probe)
                expect(probe.label, PASSIVE_DELTA, effect, plan.relation, model)
                if model['aura_state_label']:
                    aura_state_steps.append(measurement(model['aura_state_label'], CASTER, AURA_STATE_METRIC,
                                                        target=probe.fields.get('target', TARGET),
                                                        aura_state=effect.misc))
    labels = [expectation.label for expectation in expectations]
    if len(set(labels)) != len(labels):
        raise ValueError(f'Passive {rank_id} gives duplicate labels')
    if not probes:
        return None, expectations

    def measured(moment: str) -> list[dict]:
        steps = [measurement(f'{probe.label} {moment}', CASTER, probe.metric, **probe.fields) for probe in probes]
        steps += [measurement(f'{probe.label} exact {moment}', CASTER, STAT_EXACT_METRIC, **probe.fields)
                 for probe in probes if probe.metric == STAT_METRIC]
        return steps

    priming = []
    if any(probe.metric == PARRY_CHANCE for probe in probes):
        priming = [{'action': 'set_aura', 'actor': CASTER, 'spell': rank_id, 'stacks': 1},
                   {'action': 'set_aura', 'actor': CASTER, 'spell': rank_id, 'stacks': 0}]
    if aura_state_steps:
        priming = priming + [{'action': 'wait', 'ms': AURA_STATE_WAIT_MS}] + aura_state_steps
    learning = [{'action': 'learn', 'actor': CASTER, 'spell': rank_id},
                measurement(aura_label, CASTER, 'aura', spell=rank_id)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spell.name} {rank_id} passive',
        'contract': 'No-combat with/without check: the quantities a passive changes, measured before and after '
                    'it is learned.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + priming + measured(BEFORE) + learning + measured(AFTER)}
    if any(probe.fields.get('target') == TARGET for probe in probes):
        scenario['creatures'] = [creature_fixture(class_file)]
    return scenario, expectations
