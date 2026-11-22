import argparse
import functools
import subprocess
import sys
from itertools import combinations
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

CLASS_FAMILIES = range(18, 39)
PASSIVE_ATTRIBUTE = 0x40
APPLY_AURA = 'SPELL_EFFECT_APPLY_AURA'
AREA_AURA_EFFECTS = frozenset({
    'SPELL_EFFECT_APPLY_AREA_AURA_PARTY',
    'SPELL_EFFECT_APPLY_AREA_AURA_RAID',
    'SPELL_EFFECT_APPLY_AREA_AURA_FRIEND',
})
ALLIED_TARGETS = frozenset({
    'TARGET_UNIT_TARGET_ALLY',
    'TARGET_UNIT_TARGET_PARTY',
    'TARGET_UNIT_TARGET_RAID',
    'TARGET_UNIT_TARGET_ANY',
    'TARGET_UNIT_CASTER_AREA_PARTY',
    'TARGET_UNIT_CASTER_AREA_RAID',
    'TARGET_UNIT_SRC_AREA_ALLY',
    'TARGET_UNIT_DEST_AREA_ALLY',
    'TARGET_UNIT_SRC_AREA_PARTY',
    'TARGET_UNIT_DEST_AREA_PARTY',
    'TARGET_UNIT_LASTTARGET_AREA_PARTY',
    'TARGET_UNIT_TARGET_CHAINHEAL_ALLY',
    'TARGET_UNIT_NEARBY_ALLY',
    'TARGET_UNIT_NEARBY_PARTY',
    'TARGET_UNIT_NEARBY_RAID',
    'TARGET_UNIT_CONE_ALLY',
    'TARGET_UNIT_TARGET_AREA_RAID_CLASS',
})

EXCEPTIONS = {
    523495: "Ascension live logs 2026-08-11 keep it next to Greater Beetle Pheromones and Greater Footpad's Adaptation",
}
MANUAL: dict = {}

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


class Record(NamedTuple):
    name: str
    family: int
    attributes: int
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
    return frozenset({'stat:all' if misc == -1 else f'stat:{misc}'})


def _resistance(misc):
    return frozenset({'armor' if misc == 1 else f'resistance:{misc}'})


def _fixed(*keys):
    return lambda misc: frozenset(keys)


def _by_misc(prefix):
    return lambda misc: frozenset({f'{prefix}:{misc}'})


STAT_KEYS = {
    'SPELL_AURA_ASCENSION_MOD_ATTACK_POWER_FLAT': _fixed('ap:melee', 'ap:ranged'),
    'SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT': _fixed('hit:all'),
    'SPELL_AURA_MOD_HIT_CHANCE': _fixed('hit:melee'),
    'SPELL_AURA_MOD_SPELL_HIT_CHANCE': _fixed('hit:spell'),
    'SPELL_AURA_MOD_POWER_COST_SCHOOL_PCT': _by_misc('cost_pct'),
    'SPELL_AURA_MOD_POWER_REGEN_PERCENT': _by_misc('regen_pct'),
    'SPELL_AURA_MOD_MANA_REGEN_INTERRUPT': _fixed('regen_casting'),
    'SPELL_AURA_MOD_RESISTANCE_PCT': _by_misc('resistance_pct'),
    'SPELL_AURA_MOD_BASE_RESISTANCE_PCT': _by_misc('base_resistance_pct'),
    'SPELL_AURA_MOD_HEALING_PCT': _fixed('healing_taken_pct'),
    'SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT': _fixed('healing_taken_pct'),
    'SPELL_AURA_MOD_HEALING_DONE_PERCENT': _fixed('healing_pct'),
    'SPELL_AURA_MOD_INCREASE_ENERGY_PERCENT': _by_misc('power_pct'),
    'SPELL_AURA_MOD_DODGE_PERCENT': _fixed('dodge'),
    'SPELL_AURA_MOD_EXPERTISE': _fixed('expertise'),
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
              'SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK', 'SPELL_AURA_HASTE_SPELLS', 'SPELL_AURA_MOD_RANGED_HASTE']:
    STAT_KEYS[_name] = _fixed(f'haste:{_name}')

SCRIPTED_AURAS = frozenset({'SPELL_AURA_DUMMY', 'SPELL_AURA_PERIODIC_DUMMY'})

IGNORED_AURAS = SCRIPTED_AURAS | frozenset({
    'SPELL_AURA_NONE',
    'SPELL_AURA_PROC_TRIGGER_SPELL',
    'SPELL_AURA_PERIODIC_TRIGGER_SPELL',
})

NON_STAT_AURAS = frozenset(f'SPELL_AURA_{name}' for name in [
    'PERIODIC_HEAL', 'OBS_MOD_HEALTH', 'OBS_MOD_POWER', 'PERIODIC_ENERGIZE', 'PERIODIC_MANA_LEECH',
    'SCHOOL_ABSORB', 'DAMAGE_SHIELD', 'SPLIT_DAMAGE_PCT', 'REFLECT_SPELLS', 'DEFLECT_SPELLS',
    'MOD_DAMAGE_PERCENT_TAKEN', 'MOD_DAMAGE_TAKEN', 'MOD_AOE_DAMAGE_AVOIDANCE', 'MOD_DAMAGE_FROM_CASTER',
    'MOD_HEALING', 'MOD_HEALING_RECEIVED',
    'MECHANIC_IMMUNITY', 'MECHANIC_IMMUNITY_MASK', 'DISPEL_IMMUNITY', 'DAMAGE_IMMUNITY', 'SCHOOL_IMMUNITY',
    'EFFECT_IMMUNITY', 'MOD_DEBUFF_RESISTANCE', 'MOD_MECHANIC_RESISTANCE', 'MECHANIC_DURATION_MOD',
    'MECHANIC_DURATION_MOD_NOT_STACK', 'REDUCE_PUSHBACK',
    'PERIODIC_TRIGGER_SPELL_WITH_VALUE', 'PROC_TRIGGER_SPELL_WITH_VALUE', 'PROC_TRIGGER_DAMAGE',
    'ASCENSION_PROC_PERCENT_EVENT', 'ADD_CASTER_HIT_TRIGGER', 'ADD_PCT_MODIFIER', 'ADD_FLAT_MODIFIER',
    'MOD_DAMAGE_DONE_VERSUS', 'MOD_MELEE_ATTACK_POWER_VERSUS', 'MOD_CRIT_CHANCE_FOR_CASTER',
    'MOD_INCREASE_SPEED', 'MOD_MINIMUM_SPEED', 'MOD_INCREASE_SWIM_SPEED', 'MOD_MOUNTED_SPEED_NOT_STACK',
    'MOD_MOUNTED_SPEED_ALWAYS', 'MOD_FLIGHT_SPEED_NOT_STACKING', 'MOD_FLIGHT_SPEED_MOUNTED_NOT_STACKING',
    'WATER_WALK', 'FEATHER_FALL', 'SAFE_FALL', 'HOVER',
    'MOD_STEALTH', 'MOD_STEALTH_DETECT', 'MOD_DETECTED_RANGE', 'MOD_TOTAL_THREAT', 'MOD_THREAT',
    'MOD_STUN', 'TRANSFORM', 'MOD_SCALE', 'PHASE', 'BIND_SIGHT', 'EMPATHY', 'CONTROL_VEHICLE',
    'MOD_IGNORE_SHAPESHIFT', 'MOD_REPUTATION_GAIN', 'MOD_XP_PCT',
])


def enum_values(name, root=ROOT):
    return list(inspect_dbc.enums(root).get(name, {}).values())


def signature(buff):
    keys = set()
    scripted = False
    for effect in buff.effects:
        if effect.aura in SCRIPTED_AURAS:
            scripted = True
        if effect.aura in IGNORED_AURAS or effect.aura in NON_STAT_AURAS:
            continue
        builder = STAT_KEYS.get(effect.aura)
        if builder is None:
            return None
        keys |= builder(effect.misc)
    if keys:
        return frozenset(keys)
    return None if scripted else frozenset()


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
        elif keys:
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


DBC_HEADER = ('SpellName[enUS]', 'SpellFamilyName', 'Attributes')
DBC_EFFECT = ('Effect[{}]', 'EffectApplyAuraName[{}]', 'EffectMiscValue[{}]', 'EffectBasePoints[{}]',
              'EffectImplicitTargetA[{}]', 'EffectImplicitTargetB[{}]', 'EffectTriggerSpell[{}]')
SPELL_DBC_HEADER = ('Name_Lang_enUS', 'SpellClassSet', 'Attributes')
SPELL_DBC_EFFECT = ('Effect_{}', 'EffectAura_{}', 'EffectMiscValue_{}', 'EffectBasePoints_{}',
                    'ImplicitTargetA_{}', 'ImplicitTargetB_{}', 'EffectTriggerSpell_{}')


@functools.cache
def _enums():
    return inspect_dbc.enums(ROOT)


def _number(value):
    return int(value) if value not in (None, '', 'NULL') else 0


def _record(get, header, templates, indices):
    names = _enums()
    effects_by_id, auras_by_id, targets_by_id = names['SpellEffects'], names['AuraType'], names['Targets']
    name, family, attributes = get(header[0]), get(header[1]), get(header[2])
    effects = []
    for index in indices:
        effect, aura_type, misc, base_points, target_a, target_b, trigger_spell = (
            _number(get(template.format(index))) for template in templates)
        if not effect:
            continue
        effects.append(Effect(effects_by_id.get(effect, str(effect)), auras_by_id.get(aura_type, str(aura_type)),
                              misc, base_points + 1, targets_by_id.get(target_a, 'TARGET_NONE'),
                              targets_by_id.get(target_b, 'TARGET_NONE'), trigger_spell))
    return Record(name if name not in (None, 'NULL') else '', _number(family), _number(attributes), tuple(effects))


def apply_overrides(records, spell_dbc_rows):
    result = dict(records)
    for row in spell_dbc_rows:
        result[_number(row['ID'])] = _record(row.get, SPELL_DBC_HEADER, SPELL_DBC_EFFECT, (1, 2, 3))
    return result


def _reaches_others(effect):
    if effect.effect in AREA_AURA_EFFECTS:
        return True
    return effect.effect == APPLY_AURA and (effect.target_a in ALLIED_TARGETS or effect.target_b in ALLIED_TARGETS)


def _is_area(buff):
    return any(effect.effect in AREA_AURA_EFFECTS for effect in buff.effects)


def select_buffs(records, learnable):
    buffs = []
    for spell_id in sorted(records):
        spell = records[spell_id]
        if spell.family not in CLASS_FAMILIES or spell_id not in learnable:
            continue
        reaching = tuple(effect for effect in spell.effects if _reaches_others(effect))
        if not reaching:
            continue
        if spell.attributes & PASSIVE_ATTRIBUTE and not any(effect.effect in AREA_AURA_EFFECTS for effect in reaching):
            continue
        buffs.append(Buff(spell_id, spell.name, spell.family, reaching))
    return buffs


def learnable_spells(advancement, skill_line, records, first_rank=None):
    learnable = set(advancement) | set(skill_line)
    learnable |= {spell_id for spell_id, first in (first_rank or {}).items() if first in learnable}
    pending = list(learnable)
    while pending:
        spell = records.get(pending.pop())
        if spell is None:
            continue
        for effect in spell.effects:
            if effect.trigger_spell and effect.trigger_spell not in learnable:
                learnable.add(effect.trigger_spell)
                pending.append(effect.trigger_spell)
    return learnable


def pending_world_files_applied(updates, pending_dir):
    return sorted(path.name for path in Path(pending_dir).glob('*.sql') if path.name not in updates)


def _cell(text):
    return str(text).replace('|', '\\|')


def _buff_label(buff):
    return _cell(f'{buff.name} ({buff.spell_id}, family {buff.family})')


def _outcome_label(a, b, groups, first_rank):
    decided = deciding_group(a.spell_id, b.spell_id, groups, first_rank)
    if decided:
        return f'{RULE_OUTCOMES[decided[1]]} {decided[0]}'
    return pair_outcome(a, b, groups, first_rank)


def _touched_groups(plan):
    touched = set(plan.members) | set(plan.intellect_subgroups)
    if plan.intellect_subgroups:
        touched.add(INTELLECT_GROUP)
    return touched


def _effect_summary(buff):
    return '; '.join(f'{effect.effect}/{effect.aura}/{effect.misc}/{effect.target_a}' for effect in buff.effects)


def review_markdown(buffs, plan, before, after, first_rank, unclassified):
    def rank(spell_id):
        return first_rank.get(spell_id, spell_id)

    by_rank = {}
    for buff in buffs:
        by_rank.setdefault(rank(buff.spell_id), buff)
    by_id = {buff.spell_id: buff for buff in buffs}

    new_count = sum(1 for group_id in plan.categories if group_id >= FIRST_NEW_CATEGORY)
    lines = ['# CoA class buff stacking review', '',
             f'- Selected class buffs: {len(buffs)}',
             f'- Categories: {len(plan.categories)} ({new_count} new)',
             f'- Intellect subgroups under {INTELLECT_GROUP}: {len(plan.intellect_subgroups)}',
             f'- Single-class signatures: {len(plan.single_class)}',
             f'- Unclassified: {len(unclassified)}', '', '## Categories', '']
    for group_id in sorted(plan.categories):
        state = 'new' if group_id not in before.members else 'existing'
        lines += [f'### {group_id} ({state}): {_signature_label(plan.categories[group_id])}', '',
                  '| Spell | Kind |', '|---|---|']
        for member in sorted(plan.members[group_id]):
            buff = by_rank.get(member)
            if buff is None:
                lines.append(f'| {member} (not selected) | |')
            else:
                lines.append(f'| {_buff_label(buff)} | {"area aura" if _is_area(buff) else "cast"} |')
        lines.append('')

    lines += ['## Area auras next to cast buffs', '']
    for group_id in sorted(plan.categories):
        members = [by_rank[member] for member in sorted(plan.members[group_id]) if member in by_rank]
        area = [buff.spell_id for buff in members if _is_area(buff)]
        cast = [buff.spell_id for buff in members if not _is_area(buff)]
        if area and cast:
            lines.append(f'- {group_id} ({_signature_label(plan.categories[group_id])}): area {area}; cast {cast}')
    lines.append('')

    lines += [f'## Intellect subgroups under {INTELLECT_GROUP}', '']
    for group_id in sorted(plan.intellect_subgroups):
        names = ', '.join(_buff_label(by_rank[member]) for member in sorted(plan.intellect_subgroups[group_id])
                          if member in by_rank)
        lines.append(f'- {group_id}: {names}')
    lines.append('')

    lines += ['## Changed pairs', '', '| A | B | Before | After | Note |', '|---|---|---|---|---|']
    seen = set()
    for group_id in sorted(_touched_groups(plan)):
        inside = sorted({buff.spell_id for buff in buffs if _contains(after, group_id, rank(buff.spell_id))})
        for a_id, b_id in combinations(inside, 2):
            if (a_id, b_id) in seen:
                continue
            seen.add((a_id, b_id))
            a, b = by_id[a_id], by_id[b_id]
            old, new = _outcome_label(a, b, before, first_rank), _outcome_label(a, b, after, first_rank)
            if old != new:
                note = 'same-class' if a.family == b.family else ''
                lines.append(f'| {_buff_label(a)} | {_buff_label(b)} | {old} | {new} | {note} |')
    lines.append('')

    lines += ['## Single-class signatures', '']
    for keys in sorted(plan.single_class, key=sorted):
        names = ', '.join(_buff_label(by_rank[member]) for member in plan.single_class[keys] if member in by_rank)
        lines.append(f'- {_signature_label(keys)}: {names}')
    lines += ['', '## Mismatches', '']
    lines += [f'- {line}' for line in plan.mismatches]
    lines += ['', '## Unclassified', '']
    lines += [f'- {_buff_label(by_id[spell_id])}: {_cell(_effect_summary(by_id[spell_id]))}'
              for spell_id in unclassified if spell_id in by_id]
    lines += ['', '## Exceptions', '']
    lines += [f'- {spell_id}: {reason}' for spell_id, reason in sorted(EXCEPTIONS.items())]
    return '\n'.join(lines) + '\n'


def _sql_text(text):
    return "'" + str(text).replace('\\', '\\\\').replace("'", "\\'") + "'"


def _in_list(prefix, ids):
    single = f'{prefix} ({", ".join(str(value) for value in ids)});'
    if len(single) <= 120:
        return [single]
    lines, current = [f'{prefix} ('], '   '
    for value in ids:
        piece = f' {value},'
        if len(current) + len(piece) > 120:
            lines.append(current)
            current = '   '
        current += piece
    lines.append(current.rstrip(','))
    lines.append(');')
    return lines


def _values(header, rows):
    return [header] + [f'({row}){";" if index == len(rows) - 1 else ","}' for index, row in enumerate(rows)]


def migration_sql(plan, groups):
    after = apply_plan(groups, plan)
    touched = sorted(_touched_groups(plan))
    members = [(group_id, member) for group_id in touched for member in sorted(after.members.get(group_id, ()))]
    ruled = [group_id for group_id in touched if after.rules.get(group_id)]
    lines = _in_list('DELETE FROM `spell_group` WHERE `id` IN', touched)
    lines += _values('INSERT INTO `spell_group` (`id`, `spell_id`) VALUES',
                     [f'{group_id}, {member}' for group_id, member in members])
    lines.append('')
    lines += _in_list('DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN', ruled)
    lines += _values('INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES',
                     [f'{group_id}, {after.rules[group_id]}, {_sql_text(after.descriptions.get(group_id, ""))}'
                      for group_id in ruled])
    return '\n'.join(lines) + '\n'


def load_dbc(dbc_dir):
    data = inspect_dbc.DataSet(dbc_dir)

    def table(name):
        rows, schema, index, _ = data.load(name)
        fields = {field.name: field for field in schema.columns}
        return index, lambda row, column: data.value(rows, row, fields[column])[0]

    spells, spell_value = table('Spell')
    records = {spell_id: _record(lambda column, row=row: spell_value(row, column), DBC_HEADER, DBC_EFFECT, (0, 1, 2))
               for spell_id, row in spells.items()}
    entries, advancement_value = table('CharacterAdvancement')
    advancement = {advancement_value(row, f'RankSpell[{index}]') for row in entries.values() for index in range(5)}
    abilities, ability_value = table('SkillLineAbility')
    skill_line = {ability_value(row, 'Spell') for row in abilities.values()}
    return records, advancement - {0}, skill_line - {0}


def _mysql(args, query):
    result = subprocess.run([args.mysql, f'--defaults-extra-file={args.defaults_extra_file}', '--batch', '--raw',
                             args.database, '-e', query], capture_output=True, text=True, encoding='utf-8', check=True)
    lines = result.stdout.splitlines()
    if not lines:
        return []
    header = lines[0].split('\t')
    return [dict(zip(header, line.split('\t'))) for line in lines[1:]]


def load_database(args):
    effect_columns = ', '.join(template.format(index) for index in (1, 2, 3) for template in SPELL_DBC_EFFECT)
    spell_dbc = _mysql(args, f'SELECT ID, {", ".join(SPELL_DBC_HEADER)}, {effect_columns} FROM spell_dbc')
    members, rules, descriptions = {}, {}, {}
    for row in _mysql(args, 'SELECT id, spell_id FROM spell_group'):
        members.setdefault(int(row['id']), set()).add(int(row['spell_id']))
    for row in _mysql(args, 'SELECT group_id, stack_rule, description FROM spell_group_stack_rules'):
        rules[int(row['group_id'])] = int(row['stack_rule'])
        descriptions[int(row['group_id'])] = row['description'] if row['description'] != 'NULL' else ''
    first_rank = {int(row['spell_id']): int(row['first_spell_id'])
                  for row in _mysql(args, 'SELECT first_spell_id, spell_id FROM spell_ranks')}
    updates = {row['name'] for row in _mysql(args, 'SELECT name FROM updates')}
    return spell_dbc, Groups(members, rules, descriptions), first_rank, updates


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('--dbc', required=True)
    parser.add_argument('--mysql', required=True)
    parser.add_argument('--defaults-extra-file', required=True)
    parser.add_argument('--database', default='coa_world')
    parser.add_argument('--review', required=True)
    parser.add_argument('--sql')
    args = parser.parse_args(argv)

    records, advancement, skill_line = load_dbc(args.dbc)
    spell_dbc, groups, first_rank, updates = load_database(args)
    records = apply_overrides(records, spell_dbc)
    learnable = learnable_spells(advancement, skill_line, records, first_rank)
    buffs = select_buffs(records, learnable)
    plan = plan_categories(buffs, groups, first_rank, EXCEPTIONS, MANUAL)
    after = apply_plan(groups, plan)
    missing = pending_world_files_applied(updates, ROOT / 'data' / 'sql' / 'updates' / 'pending_db_world')

    selected = {buff.spell_id for buff in buffs}
    unlearned = [buff for buff in select_buffs(records, set(records)) if buff.spell_id not in selected]
    text = review_markdown(buffs, plan, groups, after, first_rank, plan.unclassified)
    text += '\n## Qualifying but not learnable\n\n'
    text += ''.join(f'- {_buff_label(buff)}: {_cell(_effect_summary(buff))}\n' for buff in unlearned)
    text += '\n## Unapplied pending world files\n\n' + ''.join(f'- {name}\n' for name in missing)
    Path(args.review).write_text(text, encoding='utf-8', newline='\n')
    if args.sql:
        Path(args.sql).write_text(migration_sql(plan, groups), encoding='utf-8', newline='\n')
    print(f'buffs={len(buffs)} categories={len(plan.categories)} unclassified={len(plan.unclassified)} '
          f'unapplied={len(missing)} review={args.review}')
    return 1 if plan.unclassified or missing else 0


if __name__ == '__main__':
    sys.exit(main())
