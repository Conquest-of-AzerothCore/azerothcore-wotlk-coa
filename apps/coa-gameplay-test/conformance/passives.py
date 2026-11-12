from dataclasses import dataclass, field, replace
from functools import lru_cache
from pathlib import Path
import re

from classes import PROGRESSION_HEADER, ClassSpell, class_spells, progression_chains, table_rows
from hits import creature_fixture
from procs import proc_label, shares_aura, shares_proc_spell, trigger_key
from profile import CASTER, DBC_DIR, DISPEL_TYPE_NAMES, base_steps, measurement, player_fixture, stat_label
from stack import class_mask, family_flags
from tooltip import COLOR_CODE, Displayed, Records, Unreadable, read_tooltip
from triggers import (COOLDOWN_DELTA_KIND, DURATION_DELTA_KIND, cooldown_label, duration_label,
                      shares_cooldown_aura, trigger_label)
from values import EFFECT_KINDS, EFFECTS, TARGET, Expectation, dataset, facts_of, structure_stats

UNMODELLED = 'unmodelled: '
CLOSED = 'closed: '
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
LINKED_FAMILY = 'P5'
BEHAVIOUR_LABELS = {
    'count': lambda entry: [f"{entry['spell']} behaviour_count"],
    'ally_heal_breadth': lambda entry: [f"{entry['spell']} behaviour_count"],
    'party_stat_ratio': lambda entry: [f"{entry['spell']} behaviour_party_stat_ratio"],
    'spread': lambda entry: [f"{entry['spell']} behaviour_count"],
    'metric_delta': lambda entry: [f"{entry['spell']} behaviour_metric_delta"],
    'aura_metric_delta': lambda entry: [f"{entry['spell']} behaviour_metric_delta"],
    'threat_tick_ratio': lambda entry: [f"{entry['spell']} behaviour_metric_ratio_delta"
                                        + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')],
    'absorb_pierce_ratio': lambda entry: [f"{entry['spell']} behaviour_absorb_pierce_ratio"],
    'cast_applies_aura': lambda entry: [f"{entry['spell']} behaviour_cast_applies_aura"
                                        + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')],
    'hit_ratio': lambda entry: [f"{entry['spell']} behaviour_hit_ratio"
                                + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')],
    'cast_stat_ratio': lambda entry: [f"{entry['spell']} behaviour_ratio"],
    'duration_refresh': lambda entry: [f"{entry['spell']} behaviour_duration_refresh"],
    'amount_delta': lambda entry: [f"{entry['spell']} behaviour_amount_delta"],
    'duration': lambda entry: [f"{entry['spell']} behaviour_duration"],
    'health_ratio': lambda entry: [f"{entry['spell']} {pct} behaviour_ratio" for pct, _ in entry['levels']],
    'crit_guarantee': lambda entry: [f"{entry['spell']} behaviour_crit_guarantee {entry['trial_spell']}"],
    'aura_grant': lambda entry: [f"{entry['spell']} behaviour_aura_grant"],
    'oath_consumption': lambda entry: [f"{entry['spell']} behaviour_oath_consumption"],
    'oath_consumption_removal': lambda entry: [f"{entry['spell']} behaviour_oath_consumption_removal"],
    'internal_cooldown_gate': lambda entry: [f"{entry['spell']} behaviour_internal_cooldown_gate"],
    'crit_magnitude': lambda entry: [f"{entry['spell']} behaviour_crit_magnitude"],
    'internal_cooldown': lambda entry: [f"{entry['spell']} behaviour_internal_cooldown"],
    'threat_slope': lambda entry: [f"{entry['spell']} behaviour_threat_slope {entry['hit_spell']}"],
    'event_delay': lambda entry: [f"{entry['spell']} behaviour_event_delay"],
    'proc_reset': lambda entry: [f"{entry['spell']} behaviour_proc_reset"],
    'taken_hit': lambda entry: [f"{entry['spell']} "
                                + ('behaviour_hit_ratio' if entry['judge'] == 'damage_ratio' else 'behaviour_taken_hit')
                                + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')],
    'threat_redirect': lambda entry: [f"{entry['spell']} behaviour_threat_redirect"],
    'dispel_count': lambda entry: [f"{entry['spell']} behaviour_dispel_count"
                                   + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')
                                   + f" {arm['name']} {DISPEL_TYPE_NAMES[int(kind)]}"
                                   for arm in entry['arms'] for kind, _ in arm['expected']],
    'script_hit': lambda entry: [f"{entry['spell']} script_hit {entry['hit_spell']}"
                                 + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')],
    'taken_outcome': lambda entry: [f"{entry['spell']} behaviour_taken_outcome {entry['aura']}"],
    'charm_immunity': lambda entry: [f"{entry['spell']} charm_immunity {entry['charm_spell']} {arm}"
                                     for arm in ('without', 'cast', 'applied', 'with')],
    'fixed_count': lambda entry: [f"{entry['spell']} behaviour_fixed_count"],
    'source_stack': lambda entry: [f"{entry['spell']} behaviour_source_stack"],
    'detection': lambda entry: [f"{entry['spell']} behaviour_detection"
                                f"{' client' if entry.get('read') == 'client' else ''} {name} {moment}"
                                for _, name in entry['hide_auras'] for moment in ('hidden', 'revealed', 'unrevealed')],
    'group_target': lambda entry: [f"{entry['spell']} group_target {arm} {metric}"
                                   for arm in ('outsider', 'party', *(('raid',) if entry.get('raid', True) else ()))
                                   for metric in ('cast', 'aura')],
    'cost_gate': lambda entry: [f"{entry['spell']} cost_gate {entry['gated_spell']}"
                                + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '') + f" {arm}"
                                for arm in ('without', 'with',
                                            *(f'cast_{cast}' for cast in range(3, (entry.get('charges') or 0) + 3)),
                                            *(('next',) if entry.get('next_arm') else ()), 'beyond',
                                            *(('held', 'expired') if entry.get('aura_duration_ms') else ()))],
    'periodic_dispel': lambda entry: [f"{entry['spell']} periodic_dispel {moment}"
                                      for moment in ('control', 'before_first',
                                                     *(f'after_{tick}'
                                                       for tick in range(1, len(entry['debuffs']) + 1)))],
    'site_purchase': lambda entry: [f"{entry['spell']} site_purchase {arm}"
                                    for arm in ('outside', 'paid', 'spent', 'topped_up')],
    'cast_state': lambda entry: [f"{entry['spell']} cast_state {moment}" for moment in ('control', 'state', 'allowed')],
    'flee_block': lambda entry: [f"{entry['spell']} flee_block {entry['creature_entry']} {moment}"
                                 for moment in ('cast', 'branded', 'blocked', 'held', 'control')],
    'mount_block': lambda entry: [f"{entry['spell']} mount_block {entry.get('mount_spell', 458)} {moment}"
                                  for moment in ('blocked', 'unmounted', 'allowed', 'mounted', 'held',
                                                 'dismounted')],
    'immunity': lambda entry: [f"{entry['spell']} immunity {subject} {moment}"
                               for subject, moments in ((entry['spell'], ('cast', 'applied')),
                                                        *((effect['spell'], ('without', 'with'))
                                                          for effect in entry['effects']))
                               for moment in moments],
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
    'movement speed': ('movement speed', 'move speed', 'running speed'),
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


class Closed(Exception):
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
def progression_ranks(header: Path, dbc_dir: Path = DBC_DIR) -> dict[int, tuple[int, tuple[tuple[int, int], ...]]]:
    chains = progression_chains(dataset(dbc_dir), header)
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
def spell_names_by_family(records_dbc) -> dict[int, dict[int, str]]:
    grouped: dict[int, dict[int, str]] = {}
    for identity, fields in table_rows(records_dbc, 'Spell', ['SpellName[enUS]', 'SpellFamilyName']):
        if fields['SpellName[enUS]']:
            grouped.setdefault(fields['SpellFamilyName'], {})[identity] = fields['SpellName[enUS]']
    return grouped


@lru_cache(maxsize=None)
def family_spells(records_dbc, family_name: int) -> dict[int, tuple[str, tuple[int, ...]]]:
    records = Records(records_dbc)
    names = spell_names_by_family(records_dbc).get(family_name, {})
    return {identity: (name, tuple(family_flags(records, identity))) for identity, name in names.items()}


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
    return next((value for value in values if value.effect_index == effect and value.kind in EFFECT_KINDS), None)


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


def literal_token(class_file: dict, spell_ids: set[int], effect: int, text: str) -> Displayed | None:
    entry = next((entry for entry in class_file.get('literal_tokens', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)
    if entry is None:
        return None
    if entry['quote'] not in text:
        raise ValueError(f'{spell_ids} literal_tokens entry quotes {entry["quote"]!r} not found in the tooltip')
    return Displayed(entry['quote'], float(entry['value']), effect, 'percent')


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
        31: ('run_speed_rate', {}, 'scale', 'movement speed'),
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
                 if entry['spell'] in spell_ids and entry['effect'] == effect and 'misc_value' in entry), None)
    return entry['misc_value'] if entry else None


def item_armor_subclass_override(class_file: dict, spell_ids: set[int], effect: int) -> dict | None:
    return next((entry for entry in class_file.get('item_armor_subclass_effects', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)


def item_armor_subclass_priming(class_file: dict, entry: dict) -> list[dict]:
    if 'level' in entry:
        raise ValueError(f'{entry["spell"]} item {entry["item"]}: the player stays at the class file level '
                         f'{class_file["level"]}, so an item entry cannot set its own level')
    required = entry.get('required_level')
    if not isinstance(required, int) or isinstance(required, bool):
        raise ValueError(f'{entry["spell"]} item {entry["item"]} needs the RequiredLevel of its item_template row '
                         f'as required_level')
    if required > class_file['level']:
        raise ValueError(f'{entry["spell"]} item {entry["item"]} requires level {required}, above the class file '
                         f'level {class_file["level"]}')
    return [{'action': 'add_item', 'actor': CASTER, 'item': entry['item']},
            {'action': 'equip', 'actor': CASTER, 'item': entry['item'], 'slot': entry['slot']}]


def item_armor_subclass_plans(spell_id: int, effect: int, entry: dict) -> tuple[MetricPlan, ...]:
    reference = MetricPlan('item_armor_by_subclass', {'subclass': entry['subclass']}, 'add', judged=False)
    reference_label = probe_label(spell_id, effect, reference.metric, [entry['subclass']])
    return reference, MetricPlan('armor', {}, 'share', source=f'{reference_label} {BEFORE}')


def effect_note(class_file: dict, spell_ids: set[int], effect: int) -> str | None:
    entry = next((entry for entry in class_file.get('effect_notes', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)
    return entry['reason'] if entry else None


def effect_unmodelled(class_file: dict, spell_ids: set[int], effect: int) -> str | None:
    entry = next((entry for entry in class_file.get('unmodelled_effects', [])
                 if entry['spell'] in spell_ids and entry['effect'] == effect), None)
    return entry['reason'] if entry else None


def behaviour_label(entry: dict) -> list[str]:
    kind = entry['kind']
    if kind not in BEHAVIOUR_LABELS:
        raise ValueError(f'behaviour kind {kind!r} has no known label format for a P5 link')
    return BEHAVIOUR_LABELS[kind](entry)


def trigger_link(class_file: dict, spell_ids: set[int], effect: int) -> list[tuple[str, dict]] | None:
    candidates: list[tuple[str, dict]] = []
    for key, id_field in (('triggers', 'aura'), ('procs', 'aura')):
        for entry in class_file.get(key, []):
            if entry[id_field] in spell_ids:
                candidates.append((key, entry))
    for entry in class_file.get('behaviours', []):
        if entry['spell'] in spell_ids:
            candidates.append(('behaviours', entry))
    if not candidates:
        return None
    exact = [(key, entry) for key, entry in candidates if entry.get('effect') == effect and 'value_spell' not in entry]
    if exact:
        return exact
    unscoped = [(key, entry) for key, entry in candidates if entry.get('effect') is None]
    return unscoped or candidates


def check_label(class_file: dict, kind: str, entry: dict) -> list[str]:
    if kind == 'triggers':
        if entry.get('kind') == COOLDOWN_DELTA_KIND:
            return [cooldown_label(entry['aura'], entry['observe_spell'])
                   if shares_cooldown_aura(class_file, entry) else cooldown_label(entry['aura'])]
        if entry.get('kind') == DURATION_DELTA_KIND:
            return [duration_label(entry['aura'])]
        return [trigger_label(entry['aura'])]
    if kind == 'procs':
        trigger = trigger_key(entry) if shares_proc_spell(class_file, entry) else None
        return [proc_label(entry['aura'], entry['proc_spell'], trigger)
               if shares_aura(class_file, entry) else proc_label(entry['aura'])]
    return behaviour_label(entry)


def live_status(verdicts: dict[str, str] | None, label: str, entry: dict) -> str:
    if verdicts is not None and label in verdicts:
        return verdicts[label]
    return entry.get('status', 'ok')


def linked_reason(class_file: dict, links: list[tuple[str, dict]], verdicts: dict[str, str] | None = None) -> str:
    pointers = []
    for kind, entry in links:
        labels = check_label(class_file, kind, entry)
        parts = [f'"{label}" (status {live_status(verdicts, label, entry)})' for label in labels]
        pointers.append(f'{kind} entry "{entry.get("name")}" (verdict {", ".join(parts)})')
    return f'checked by {"; ".join(pointers)}'


def signed_points(records: Records, rank_id: int, effect: int) -> float | None:
    try:
        return records.points(rank_id, effect, upper=False)
    except Unreadable:
        return None


def classify(class_file: dict, records: Records, spell_id: int, rank_id: int, effect: int, effects: list[int],
             text: str, values: list[Displayed], verdicts: dict[str, str] | None = None) -> PassiveEffect:
    def spell(name: str):
        return records.field('Spell', rank_id, name)

    aura = spell(f'EffectApplyAuraName[{effect}]')
    override = effect_override(class_file, {spell_id, rank_id}, effect)
    misc = override if override is not None else spell(f'EffectMiscValue[{effect}]')
    misc_b = spell(f'EffectMiscValueB[{effect}]')
    family = family_of(spell(f'Effect[{effect}]'), aura)
    token = (own_token(values, effect) or shared_token(records, rank_id, effect, effects, values)
             or literal_token(class_file, {spell_id, rank_id}, effect, text))
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
    override = passive_override(class_file, {spell_id, rank_id}, effect)
    if family == 'P1' or override:
        siblings = tuple(sibling for sibling in effects if sibling != effect)
        targets, reason = modifier_targets(records, rank_id, effect, text, class_file['level'],
                                           override, siblings, token.text if token else None)
    try:
        forced = effect_unmodelled(class_file, {spell_id, rank_id}, effect)
        if forced is not None:
            raise NotModelled(forced)
        if family == UNKNOWN:
            raise NotModelled(f'aura {aura} has no passive measurement' if aura
                              else f'effect {spell(f"Effect[{effect}]")} applies no aura')
        if family in FAMILY_REASONS:
            link = trigger_link(class_file, {spell_id, rank_id}, effect) if family == LINKED_FAMILY else None
            if link is not None:
                raise NotModelled(linked_reason(class_file, link, verdicts))
            raise NotModelled(FAMILY_REASONS[family])
        if aura == 142:
            subclass_override = item_armor_subclass_override(class_file, {spell_id, rank_id}, effect)
            if subclass_override is None:
                raise Closed(OUT_OF_SCOPE[142])
            if token is None:
                raise NotModelled('no own token and no sibling token with equal points')
            plans = item_armor_subclass_plans(spell_id, effect, subclass_override)
        elif aura in OUT_OF_SCOPE:
            raise NotModelled(OUT_OF_SCOPE[aura])
        elif family == 'P1' and misc >= MAX_SPELLMOD:
            raise NotModelled(f'SpellModOp {misc} is not below MAX_SPELLMOD {MAX_SPELLMOD}')
        elif token is None:
            raise NotModelled('no own token and no sibling token with equal points')
        elif family == 'P1':
            plans = () if reason else modifier_plans(
                aura, misc, alias_points if alias_points is not None else signed_points(records, rank_id, effect))
        else:
            plans = effect_plans(aura, misc, text, token)
    except Closed as closed:
        plans, reason = (), CLOSED + str(closed)
    except NotModelled as error:
        plans, reason = (), UNMODELLED + str(error)
    if not reason:
        reason = alias_reason
    if reason.startswith(UNMODELLED):
        note = effect_note(class_file, {spell_id, rank_id}, effect)
        if note is not None:
            prefix = CLOSED if note.startswith('no check needed:') else UNMODELLED
            reason = prefix + note
    points = alias_points if alias_points is not None else signed_points(records, rank_id, effect)
    return PassiveEffect(rank_id, effect, aura, misc, misc_b, family, token, plans, targets, reason, points)


def passive_effects(class_file: dict, spell: ClassSpell,
                    verdicts: dict[str, str] | None = None) -> list[PassiveEffect]:
    dbc = dataset(Path(class_file.get('dbc_dir', DBC_DIR)))
    records = Records(dbc)
    rank_id = spell.max_rank
    text = cleaned_tooltip(records.field('Spell', rank_id, 'Description[enUS]'))
    values = read_tooltip(dbc, rank_id, structure_stats(class_file)).values
    effects = [effect for effect in EFFECTS if records.field('Spell', rank_id, f'Effect[{effect}]')]
    return [classify(class_file, records, spell.spell_id, rank_id, effect, effects, text, values, verdicts)
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
def active_class_ranks(dbc_dir: Path, class_id: int, level: int,
                       extra_spells: tuple[int, ...] = ()) -> tuple[int, ...]:
    return tuple(spell.max_rank for spell in class_spells(dbc_dir, class_id, PROGRESSION_HEADER, level, extra_spells)
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
    extra_spells = tuple(entry['spell'] for entry in class_file.get('extra_spells', []))
    for rank_id in active_class_ranks(dbc_dir, class_file['class_id'], class_file['level'], extra_spells):
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
    if effect.targets:
        probes = []
        for target in effect.targets:
            reason = ''
            if plan.metric == 'spell_effect_value' and not records.field(
                    'Spell', target.spell_id, f'Effect[{plan.fields["effect"]}]'):
                reason = UNMODELLED + f'target {target.spell_id} has no effect {plan.fields["effect"]}'
            elif plan.metric == 'spell_power_cost':
                facts = facts_of(records, target.spell_id)
                if not (facts.mana_cost or facts.mana_cost_per_level or facts.mana_cost_percentage):
                    reason = CLOSED + f'target {target.spell_id} has no power cost to modify'
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
    for entry in class_file.get('item_armor_subclass_effects', []):
        if entry['spell'] == rank_id:
            priming += item_armor_subclass_priming(class_file, entry)
    if any(probe.metric == PARRY_CHANCE for probe in probes):
        priming = priming + [{'action': 'set_aura', 'actor': CASTER, 'spell': rank_id, 'stacks': 1},
                             {'action': 'set_aura', 'actor': CASTER, 'spell': rank_id, 'stacks': 0}]
    if aura_state_steps:
        priming = priming + [{'action': 'wait', 'ms': AURA_STATE_WAIT_MS}] + aura_state_steps
    learning = [{'action': 'learn', 'actor': CASTER, 'spell': rank_id},
                measurement(aura_label, CASTER, 'aura', spell=rank_id)]
    caster = player_fixture(class_file)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spell.name} {rank_id} passive',
        'contract': 'No-combat with/without check: the quantities a passive changes, measured before and after '
                    'it is learned.',
        'players': [caster],
        'steps': base_steps(class_file) + priming + measured(BEFORE) + learning + measured(AFTER)}
    if any(probe.fields.get('target') == TARGET for probe in probes):
        scenario['creatures'] = [creature_fixture(class_file)]
    return scenario, expectations
