import sys
from pathlib import Path
from typing import NamedTuple

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'apps' / 'coa-dbc'))

import inspect_dbc  # noqa: E402

INTELLECT_GROUP = 1083
INTELLECT_SUBGROUP_FLOOR = 2110710
LEFT_ALONE_GROUPS = frozenset({INTELLECT_GROUP, 2112508})
FIRST_NEW_CATEGORY = 2113001
EXCLUSIVE = 1
RULE_OUTCOMES = {1: 'exclusive', 2: 'per_caster', 3: 'same_effect', 4: 'highest'}
INTELLECT_ONLY = frozenset({'stat:3'})

EXISTING_CATEGORIES = {
    2110001: frozenset({'stat:1'}),
    2110002: frozenset({'stat:2'}),
    2110003: frozenset({'ap:melee', 'ap:ranged'}),
    2110004: frozenset({'armor', 'stat:all'}),
    2110005: frozenset({'stat:4'}),
    2110006: frozenset({'stat_pct:-1'}),
    2110012: frozenset({'spell_power:126'}),
}


class Effect(NamedTuple):
    effect: str
    aura: str
    misc: int
    base_points: int
    target_a: str
    target_b: str
    trigger_spell: int


class Buff(NamedTuple):
    spell_id: int
    name: str
    family: int
    effects: tuple


class Groups(NamedTuple):
    members: dict
    rules: dict
    descriptions: dict


class Plan(NamedTuple):
    categories: dict
    members: dict
    intellect_subgroups: dict
    mismatches: list
    single_class: dict
    unclassified: list


def _stat(misc):
    return 'stat:all' if misc == -1 else f'stat:{misc}'


def _resistance(misc):
    return 'armor' if misc == 1 else f'resistance:{misc}'


def _fixed(key):
    return lambda misc: key


def _by_misc(prefix):
    return lambda misc: f'{prefix}:{misc}'


STAT_KEYS = {
    'SPELL_AURA_MOD_STAT': _stat,
    'SPELL_AURA_MOD_RESISTANCE': _resistance,
    'SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE': _resistance,
    'SPELL_AURA_MOD_BASE_RESISTANCE': _resistance,
    'SPELL_AURA_MOD_ATTACK_POWER': _fixed('ap:melee'),
    'SPELL_AURA_MOD_RANGED_ATTACK_POWER': _fixed('ap:ranged'),
    'SPELL_AURA_MOD_ATTACK_POWER_PCT': _fixed('ap_pct:melee'),
    'SPELL_AURA_MOD_RANGED_ATTACK_POWER_PCT': _fixed('ap_pct:ranged'),
    'SPELL_AURA_MOD_PERCENT_STAT': _by_misc('stat_pct'),
    'SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE': _by_misc('stat_pct'),
    'SPELL_AURA_MOD_DAMAGE_DONE': _by_misc('spell_power'),
    'SPELL_AURA_ASCENSION_MOD_SPELL_POWER_FLAT': _by_misc('spell_power'),
    'SPELL_AURA_MOD_HEALING_DONE': _by_misc('healing'),
    'SPELL_AURA_MOD_DAMAGE_PERCENT_DONE': _by_misc('damage_pct'),
    'SPELL_AURA_MOD_POWER_REGEN': _by_misc('regen'),
    'SPELL_AURA_MOD_INCREASE_HEALTH': _fixed('health'),
    'SPELL_AURA_MOD_INCREASE_HEALTH_PERCENT': _fixed('health_pct'),
    'SPELL_AURA_MOD_RATING': _by_misc('rating'),
}
for _name in ['SPELL_AURA_MOD_SPELL_CRIT_CHANCE', 'SPELL_AURA_MOD_CRIT_PCT', 'SPELL_AURA_MOD_WEAPON_CRIT_PERCENT']:
    STAT_KEYS[_name] = _fixed(f'crit:{_name}')
for _name in ['SPELL_AURA_MOD_MELEE_HASTE', 'SPELL_AURA_MOD_MELEE_RANGED_HASTE',
              'SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK', 'SPELL_AURA_HASTE_SPELLS']:
    STAT_KEYS[_name] = _fixed(f'haste:{_name}')

IGNORED_AURAS = frozenset({
    'SPELL_AURA_NONE',
    'SPELL_AURA_DUMMY',
    'SPELL_AURA_PERIODIC_DUMMY',
    'SPELL_AURA_PROC_TRIGGER_SPELL',
    'SPELL_AURA_PERIODIC_TRIGGER_SPELL',
})


def enum_values(name, root=ROOT):
    return list(inspect_dbc.enums(root).get(name, {}).values())


def signature(buff):
    keys = set()
    for effect in buff.effects:
        if effect.aura in IGNORED_AURAS:
            continue
        builder = STAT_KEYS.get(effect.aura)
        if builder is None:
            return None
        keys.add(builder(effect.misc))
    return frozenset(keys) if keys else None


def _contains(groups, group_id, spell_id, seen=frozenset()):
    if group_id in seen:
        return False
    for member in groups.members.get(group_id, ()):
        if member == spell_id:
            return True
        if member < 0 and _contains(groups, -member, spell_id, seen | {group_id}):
            return True
    return False


def deciding_group(a, b, groups, first_rank):
    a, b = first_rank.get(a, a), first_rank.get(b, b)
    for group_id in sorted(groups.members):
        if not (_contains(groups, group_id, a) and _contains(groups, group_id, b)):
            continue
        subgroups = [-member for member in groups.members[group_id] if member < 0]
        if any(_contains(groups, sub, a) and _contains(groups, sub, b) for sub in subgroups):
            continue
        rule = groups.rules.get(group_id, 0)
        if rule:
            return group_id, rule
    return None


def pair_outcome(a, b, groups, first_rank):
    decided = deciding_group(a.spell_id, b.spell_id, groups, first_rank)
    if decided:
        return RULE_OUTCOMES[decided[1]]
    return 'stacks' if a.family != b.family else 'family'


def _signature_label(keys):
    return ', '.join(sorted(keys))


def _intellect_subgroups(buffs, groups, first_rank):
    family_of = {first_rank.get(buff.spell_id, buff.spell_id): buff.family for buff in buffs}
    existing = sorted(-member for member in groups.members.get(INTELLECT_GROUP, ()) if member < 0)
    by_family = {}
    for sub in existing:
        for member in groups.members.get(sub, ()):
            if member in family_of:
                by_family.setdefault(family_of[member], sub)
    used = set(groups.members) | set(groups.rules)
    result = {}
    next_id = INTELLECT_SUBGROUP_FLOOR
    for family in sorted({buff.family for buff in buffs}):
        target = by_family.get(family)
        if target is None:
            while next_id in used:
                next_id += 1
            target = next_id
            used.add(target)
        for buff in buffs:
            if buff.family == family:
                result.setdefault(target, set()).add(first_rank.get(buff.spell_id, buff.spell_id))
    return result


def plan_categories(buffs, groups, first_rank, exceptions, manual):
    def rank(spell_id):
        return first_rank.get(spell_id, spell_id)

    signatures = {}
    unclassified = []
    for buff in buffs:
        if buff.spell_id in exceptions:
            continue
        if buff.spell_id in manual:
            if manual[buff.spell_id] is not None:
                signatures[buff.spell_id] = frozenset(manual[buff.spell_id])
            continue
        keys = signature(buff)
        if keys is None:
            unclassified.append(buff.spell_id)
        else:
            signatures[buff.spell_id] = keys

    placed = {rank(member) for group_id in EXISTING_CATEGORIES for member in groups.members.get(group_id, ())}
    left_alone = {buff.spell_id for buff in buffs
                  if any(_contains(groups, group_id, rank(buff.spell_id)) for group_id in LEFT_ALONE_GROUPS)}

    categories, members, mismatches = {}, {}, []
    for group_id, keys in EXISTING_CATEGORIES.items():
        if group_id not in groups.members:
            continue
        categories[group_id] = keys
        members[group_id] = set(groups.members[group_id])
        for member in sorted(groups.members[group_id]):
            current = next((buff for buff in buffs if rank(buff.spell_id) == member), None)
            if current is None:
                mismatches.append(f'{member} in {group_id} is not a selected class buff')
            elif signatures.get(current.spell_id) != keys:
                found = signatures.get(current.spell_id)
                label = _signature_label(found) if found else 'unclassified'
                mismatches.append(f'{member} in {group_id} gives {label}, category gives {_signature_label(keys)}')

    by_signature = {}
    intellect = []
    for buff in buffs:
        keys = signatures.get(buff.spell_id)
        if keys is None or rank(buff.spell_id) in placed or buff.spell_id in left_alone:
            continue
        if keys == INTELLECT_ONLY:
            intellect.append(buff)
        else:
            by_signature.setdefault(keys, []).append(buff)

    existing_by_signature = {keys: group_id for group_id, keys in categories.items()}
    single_class = {}
    next_id = FIRST_NEW_CATEGORY
    for keys in sorted(by_signature, key=lambda item: sorted(item)):
        group = by_signature[keys]
        ids = {rank(buff.spell_id) for buff in group}
        if keys in existing_by_signature:
            members[existing_by_signature[keys]] |= ids
        elif len({buff.family for buff in group}) >= 2:
            while next_id in groups.members or next_id in groups.rules:
                next_id += 1
            categories[next_id] = keys
            members[next_id] = ids
            next_id += 1
        else:
            single_class[keys] = sorted(ids)

    return Plan(categories, members, _intellect_subgroups(intellect, groups, first_rank), mismatches,
                single_class, unclassified)


def apply_plan(groups, plan):
    members = {group_id: set(spells) for group_id, spells in groups.members.items()}
    rules = dict(groups.rules)
    descriptions = dict(groups.descriptions)
    for group_id, spells in plan.members.items():
        members[group_id] = members.get(group_id, set()) | spells
        rules.setdefault(group_id, EXCLUSIVE)
        descriptions.setdefault(group_id, f'CoA class buffs: {_signature_label(plan.categories[group_id])}')
    for group_id, spells in plan.intellect_subgroups.items():
        members[group_id] = members.get(group_id, set()) | spells
        members.setdefault(INTELLECT_GROUP, set()).add(-group_id)
    return Groups(members, rules, descriptions)
