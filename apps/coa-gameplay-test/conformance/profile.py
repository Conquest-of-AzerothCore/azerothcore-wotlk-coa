from functools import lru_cache
import hashlib
import json
from pathlib import Path
from typing import Mapping

from tooltip import SKILL_PER_LEVEL, CasterStats

CLASSES_DIR = Path(__file__).resolve().parent / 'classes'
FIXTURE_CLASSES_DIR = Path(__file__).resolve().parent / 'fixtures' / 'classes'
CONTROLS_DIR = Path(__file__).resolve().parent / 'controls'
DBC_DIR = Path('/srv/coa/server-data/dbc')
SETTLE_MS = 5000
UNBOUNDED = 10**15
SPELL_POWER_SCHOOLS = range(1, 7)
STATS = range(5)
CASTER = 'caster'
DISPEL_TYPE_NAMES = {1: 'magic', 2: 'curse', 3: 'disease', 4: 'poison'}
EQUIPMENT_SLOT_MAIN_HAND = 15
EQUIPMENT_SLOT_OFF_HAND = 16
WEAPON_ITEM_CLASS = 2
INVTYPE_WEAPON = 13
INVTYPE_WEAPON_MAIN_HAND = 21
ONE_HAND_SLOT_TYPES = (1 << 21) | (1 << 22)
ONE_HAND_MAIN = {'EquippedItemClass': WEAPON_ITEM_CLASS, 'EquippedItemSubClassMask': 0,
                 'EquippedItemInventoryTypeMask': 1 << INVTYPE_WEAPON | ONE_HAND_SLOT_TYPES}
EQUIP_FIELDS = ('EquippedItemClass', 'EquippedItemSubClassMask', 'EquippedItemInventoryTypeMask')
ATTACK_FIELDS = ('DmgClass', 'SpellFamilyName', 'SpellFamilyFlags[1]', 'Attributes', 'AttributesEx2', 'AttributesEx3')
WEAPON_REQUIREMENT_FIELDS = EQUIP_FIELDS + ATTACK_FIELDS
INVENTORY_TYPE_MASK_FIELD = 'EquippedItemInventoryTypeMask'
SERVER_INVENTORY_MASKS = 'server_inventory_masks'
WEAPON_SET_SPELLS = 'weapon_set_spells'
EQUIPMENT_SLOT_RANGED = 17
MAIN_HAND, OFF_HAND, RANGED = 'main_hand', 'off_hand', 'ranged'
WEAPON_SET_HANDS = ((MAIN_HAND, EQUIPMENT_SLOT_MAIN_HAND), (OFF_HAND, EQUIPMENT_SLOT_OFF_HAND),
                    (RANGED, EQUIPMENT_SLOT_RANGED))
MELEE_DAMAGE_CLASS = 2
RANGED_DAMAGE_CLASS = 3
RANGED_WEAPON_SUBCLASS_MASK = (1 << 2) | (1 << 3) | (1 << 16) | (1 << 18)
USES_RANGED_SLOT_ATTRIBUTE = 0x2
AUTO_REPEAT_ATTRIBUTE_EX2 = 0x20
REQUIRES_MAIN_HAND_ATTRIBUTE_EX3 = 0x400
REQUIRES_OFF_HAND_ATTRIBUTE_EX3 = 0x1000000
HUNTER_FAMILY = 9
HUNTER_MELEE_FAMILY_FLAG_1 = 0x10000000


def measurement(label: str, actor: str, metric: str, **fields) -> dict:
    return {'action': 'assert', 'label': label, 'actor': actor, 'metric': metric, **fields,
            'min': -UNBOUNDED, 'max': UNBOUNDED}


def spell_power_label(school: int) -> str:
    return f'spell_power {school}'


def stat_label(stat: int) -> str:
    return f'stat {stat}'


def skill_label(line: int) -> str:
    return f'skill {line}'


def known_aura_label(spell_id: int) -> str:
    return f'known_aura {spell_id}'


def probe_aura_label(spell_id: int) -> str:
    return f'probe_aura {spell_id}'


CLAUSE_LEDGER_SUFFIX = '_clauses'
CONSUMPTION_SUFFIX = '_consumption'
SPELL_DBC = 'Spell.dbc'


class DbcSetMismatch(ValueError):
    pass


@lru_cache(maxsize=8)
def file_sha256(path: Path, size: int, mtime_ns: int) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def spell_dbc_sha256(dbc_dir: Path) -> str:
    path = Path(dbc_dir).resolve() / SPELL_DBC
    if not path.is_file():
        raise DbcSetMismatch(f'{path} does not exist')
    stat = path.stat()
    return file_sha256(path, stat.st_size, stat.st_mtime_ns)


def server_spell_dbc_sha256() -> str:
    return spell_dbc_sha256(DBC_DIR)


def require_server_sha(sha: str | None, source: str) -> str:
    server = server_spell_dbc_sha256()
    if sha != server:
        raise DbcSetMismatch(f'{source} has {SPELL_DBC} sha256 {sha}, the server set {DBC_DIR} has {server}; '
                             f'measure and judge on the server set only')
    return sha


def server_dbc_dir(dbc_dir: Path) -> Path:
    dbc_dir = Path(dbc_dir)
    require_server_sha(spell_dbc_sha256(dbc_dir), str(dbc_dir))
    return dbc_dir


def class_file_paths() -> list[Path]:
    return sorted(path for path in CLASSES_DIR.glob('*.json')
                  if not path.stem.endswith((CLAUSE_LEDGER_SUFFIX, CONSUMPTION_SUFFIX)))


def ledger_consumption_path(ledger: Path) -> Path:
    ledger = Path(ledger)
    stem = ledger.stem.removesuffix(CLAUSE_LEDGER_SUFFIX)
    return ledger.with_name(f'{stem}{CONSUMPTION_SUFFIX}.json')


def check_weapon_sets(class_file: dict) -> None:
    sets = class_file['weapon_sets']
    named = {class_file['default_weapon_set'], *class_file.get('spell_weapon_sets', {}).values()}
    if named - sets.keys():
        raise ValueError(f'weapon sets {sorted(named - sets.keys())} are not in weapon_sets')
    for name, hands in sets.items():
        if set(hands) != {hand for hand, _ in WEAPON_SET_HANDS}:
            raise ValueError(f'weapon set {name} needs the hands {[hand for hand, _ in WEAPON_SET_HANDS]}')
        for hand, slot in WEAPON_SET_HANDS:
            if hands[hand] is not None and hands[hand]['slot'] != slot:
                raise ValueError(f'weapon set {name} {hand} item {hands[hand]["item"]} is not in slot {slot}')
    if class_file.get('weapon') != sets[class_file['default_weapon_set']][MAIN_HAND]:
        raise ValueError('weapon must be the default weapon set main hand')


def check_weapon_set_spells(class_file: dict) -> None:
    sets = class_file.get('weapon_sets', {})
    for name, spells in class_file.get(WEAPON_SET_SPELLS, {}).items():
        if name not in sets:
            raise ValueError(f'{WEAPON_SET_SPELLS} {name} is not in weapon_sets')
        if not isinstance(spells, list) or not spells or any(
                isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0 for spell in spells):
            raise ValueError(f'{WEAPON_SET_SPELLS} {name} must be a non-empty list of positive spell ids')
        if len(set(spells)) != len(spells):
            raise ValueError(f'{WEAPON_SET_SPELLS} {name} names a spell twice')


def weapon_set_spells(class_file: dict, name: str | None) -> list[int]:
    return class_file.get(WEAPON_SET_SPELLS, {}).get(name, [])


def check_weapon_set_relearns(class_file: dict, key: str, scenario: dict) -> None:
    set_spells = {spell for spells in class_file.get(WEAPON_SET_SPELLS, {}).values() for spell in spells}
    known: set[int] = set()
    for step in scenario['steps']:
        spell = step.get('spell')
        if spell not in set_spells or step['action'] not in ('learn', 'unlearn'):
            continue
        if step['action'] == 'unlearn':
            known.discard(spell)
        elif spell in known:
            raise ValueError(f'Scenario {key} learns {spell} again while its weapon set has it learned; give its spell '
                             f'a spell_weapon_sets set without {WEAPON_SET_SPELLS} {spell}')
        else:
            known.add(spell)


def check_server_inventory_masks(class_file: dict) -> None:
    for spell_id, entry in class_file.get(SERVER_INVENTORY_MASKS, {}).items():
        if set(entry) != {'mask', 'source'}:
            raise ValueError(f'{SERVER_INVENTORY_MASKS} {spell_id} needs exactly mask and source')
        if not isinstance(entry['source'], str) or not entry['source'].strip():
            raise ValueError(f'{SERVER_INVENTORY_MASKS} {spell_id} needs the server source of the repair')
        if isinstance(entry['mask'], bool) or not isinstance(entry['mask'], int) or entry['mask'] <= 0:
            raise ValueError(f'{SERVER_INVENTORY_MASKS} {spell_id} mask must be a positive integer')


def server_requirement(class_file: dict, spell_id: int, requirement: Mapping[str, int]) -> Mapping[str, int]:
    entry = class_file.get(SERVER_INVENTORY_MASKS, {}).get(str(spell_id))
    if entry is None:
        return requirement
    raw = requirement[INVENTORY_TYPE_MASK_FIELD]
    if raw & ~entry['mask']:
        raise ValueError(f'{SERVER_INVENTORY_MASKS} {spell_id} mask {entry["mask"]} drops bits of the DBC mask {raw}')
    return {**requirement, INVENTORY_TYPE_MASK_FIELD: entry['mask']}


def class_file_among(paths: list[Path], class_id: int) -> dict:
    for path in paths:
        class_file = json.loads(path.read_text(encoding='utf-8'))
        if class_file['class_id'] == class_id:
            if 'dbc_dir' in class_file:
                server_dbc_dir(class_file['dbc_dir'])
            if 'weapon_sets' in class_file:
                check_weapon_sets(class_file)
            check_weapon_set_spells(class_file)
            check_server_inventory_masks(class_file)
            return class_file
    raise ValueError(f'No class file for class {class_id}')


def load_class_file(class_id: int) -> dict:
    return class_file_among(class_file_paths(), class_id)


def load_fixture_class_file(class_id: int) -> dict:
    return class_file_among(sorted(path for path in FIXTURE_CLASSES_DIR.glob('*.json')
                                   if not path.stem.endswith((CLAUSE_LEDGER_SUFFIX, CONSUMPTION_SUFFIX))), class_id)


def control_entries(class_id: int) -> list[dict]:
    for path in sorted(CONTROLS_DIR.glob('*.json')):
        controls = json.loads(path.read_text(encoding='utf-8'))
        if controls['class_id'] == class_id:
            return controls['behaviours']
    return []


def player_fixture(class_file: dict) -> dict:
    return {'id': CASTER, 'race': class_file['race'], 'class': class_file['class_id'],
            'level': class_file['level'], **class_file.get('ratings', {})}


def equipped_weapons(class_file: dict) -> list[tuple[dict, int]]:
    if 'weapon_sets' not in class_file:
        weapon = class_file.get('weapon')
        return [(weapon, weapon.get('slot', EQUIPMENT_SLOT_MAIN_HAND))] if weapon else []
    hands = class_file['weapon_sets'][class_file['weapon_set']]
    return [(hands[hand], slot) for hand, slot in WEAPON_SET_HANDS if hands.get(hand)]


def base_steps(class_file: dict) -> list[dict]:
    if 'weapon_sets' in class_file and 'weapon_set' not in class_file:
        class_file = with_weapon_set(class_file, class_file['default_weapon_set'], {})
    steps = [{'action': 'wait', 'label': 'settle', 'ms': SETTLE_MS}]
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell}
              for spell in weapon_set_spells(class_file, class_file.get('weapon_set'))]
    for weapon, slot in equipped_weapons(class_file):
        steps.append({'action': 'add_item', 'actor': CASTER, 'item': weapon['item']})
        steps.append({'action': 'equip', 'actor': CASTER, 'item': weapon['item'], 'slot': slot})
    for line in class_file.get('skill_lines', []):
        steps.append({'action': 'set_skill', 'actor': CASTER, 'skill': line, 'value': skill_target(class_file),
                      'maximum': skill_target(class_file)})
        steps.append(measurement(skill_label(line), CASTER, 'skill_value', skill=line))
    steps.append(measurement('attack_power', CASTER, 'attack_power'))
    steps.append(measurement('ranged_attack_power', CASTER, 'ranged_attack_power'))
    for school in SPELL_POWER_SCHOOLS:
        steps.append(measurement(spell_power_label(school), CASTER, 'spell_power', school=school))
    for stat in STATS:
        steps.append(measurement(stat_label(stat), CASTER, 'stat', stat=stat))
    steps.append(measurement('weapon_damage_min', CASTER, 'weapon_damage_min'))
    for spell_id in class_file.get('known_auras', []):
        steps.append(measurement(known_aura_label(spell_id), CASTER, 'aura', spell=spell_id))
    for spell_id in class_file.get('probe_auras', []):
        steps.append(measurement(probe_aura_label(spell_id), CASTER, 'aura', spell=spell_id))
    return steps


def skill_target(class_file: dict) -> int:
    return SKILL_PER_LEVEL * class_file['level']


def unfit_reason(weapon: dict | None, requirement: Mapping[str, int]) -> str | None:
    if requirement['EquippedItemClass'] != WEAPON_ITEM_CLASS:
        return None
    if weapon is None:
        return f'EquippedItemClass {WEAPON_ITEM_CLASS} needs a reference weapon'
    subclasses = requirement['EquippedItemSubClassMask']
    if subclasses and not subclasses & 1 << weapon['subclass']:
        return f'EquippedItemSubClassMask {subclasses} excludes the reference weapon subclass {weapon["subclass"]}'
    types = requirement['EquippedItemInventoryTypeMask']
    if (types and not types & 1 << weapon['inventory_type']
            and not (weapon['inventory_type'] == INVTYPE_WEAPON and types & ONE_HAND_SLOT_TYPES)):
        return (f'EquippedItemInventoryTypeMask {types} excludes the reference weapon inventory type '
                f'{weapon["inventory_type"]}')
    return None


def ranged_weapon_spell(spell: Mapping[str, int]) -> bool:
    return bool((spell.get('SpellFamilyName') == HUNTER_FAMILY
                 and not spell.get('SpellFamilyFlags[1]', 0) & HUNTER_MELEE_FAMILY_FLAG_1)
                or spell['EquippedItemSubClassMask'] & RANGED_WEAPON_SUBCLASS_MASK
                or spell.get('Attributes', 0) & USES_RANGED_SLOT_ATTRIBUTE)


def attack_hand(spell: Mapping[str, int]) -> str:
    damage_class = spell.get('DmgClass', 0)
    if damage_class == MELEE_DAMAGE_CLASS:
        return OFF_HAND if spell.get('AttributesEx3', 0) & REQUIRES_OFF_HAND_ATTRIBUTE_EX3 else MAIN_HAND
    if damage_class == RANGED_DAMAGE_CLASS:
        return RANGED if ranged_weapon_spell(spell) else MAIN_HAND
    return RANGED if spell.get('AttributesEx2', 0) & AUTO_REPEAT_ATTRIBUTE_EX2 else MAIN_HAND


def weapon_set_unfit_reason(hands: Mapping[str, dict | None], requirement: Mapping[str, int]) -> str | None:
    for attribute, hand in ((REQUIRES_MAIN_HAND_ATTRIBUTE_EX3, MAIN_HAND), (REQUIRES_OFF_HAND_ATTRIBUTE_EX3, OFF_HAND)):
        if requirement.get('AttributesEx3', 0) & attribute:
            reason = unfit_reason(hands.get(hand), requirement)
            if reason is not None:
                return f'{hand}: {reason}'
    reasons = [unfit_reason(hands.get(hand), requirement) for hand, _ in WEAPON_SET_HANDS]
    if None in reasons:
        return None
    return '; '.join(f'{hand}: {reason}' for (hand, _), reason in zip(WEAPON_SET_HANDS, reasons))


def with_weapon_set(class_file: dict, name: str, requirement: Mapping[str, int]) -> dict:
    hands = class_file['weapon_sets'][name]
    lines = list(class_file.get('skill_lines', []))
    stats = dict(class_file['reference_stats'])
    for hand, _ in WEAPON_SET_HANDS:
        weapon = hands.get(hand)
        if weapon and weapon['skill_line'] not in lines:
            lines.append(weapon['skill_line'])
            stats[skill_label(weapon['skill_line'])] = skill_target(class_file)
    return {**class_file, 'weapon_set': name, 'weapon': hands.get(attack_hand(requirement)), 'skill_lines': lines,
            'reference_stats': stats}


def spec_weapon_set(class_file: dict, spell_id: int | None) -> str:
    return class_file.get('spell_weapon_sets', {}).get(str(spell_id), class_file['default_weapon_set'])


def armed_with_sets(class_file: dict, requirement: Mapping[str, int], spell_id: int | None) -> dict:
    sets = class_file['weapon_sets']
    if 'weapon_set' in class_file and weapon_set_unfit_reason(sets[class_file['weapon_set']], requirement) is None:
        return with_weapon_set(class_file, class_file['weapon_set'], requirement)
    order = list(dict.fromkeys([spec_weapon_set(class_file, spell_id), class_file['default_weapon_set'], *sets]))
    name = next((name for name in order if weapon_set_unfit_reason(sets[name], requirement) is None), order[0])
    return with_weapon_set(class_file, name, requirement)


def for_entry(class_file: dict, spell_id: int) -> dict:
    if 'weapon_sets' not in class_file:
        return class_file
    return with_weapon_set(class_file, spec_weapon_set(class_file, spell_id), {})


def armed(class_file: dict, requirement: Mapping[str, int], spell_id: int | None = None) -> dict:
    if 'weapon_sets' in class_file:
        return armed_with_sets(class_file, requirement, spell_id)
    if unfit_reason(class_file.get('weapon'), requirement) is None:
        return class_file
    weapon = next((weapon for weapon in class_file.get('alternate_weapons', [])
                   if unfit_reason(weapon, requirement) is None), None)
    if weapon is None:
        return class_file
    lines = list(class_file.get('skill_lines', []))
    stats = dict(class_file['reference_stats'])
    if weapon['skill_line'] not in lines:
        lines.append(weapon['skill_line'])
        stats[skill_label(weapon['skill_line'])] = skill_target(class_file)
    return {**class_file, 'weapon': weapon, 'skill_lines': lines, 'reference_stats': stats}


def one_hand_main(class_file: dict) -> dict | None:
    one_handed = armed(class_file, ONE_HAND_MAIN)
    if one_handed.get('weapon', {}).get('inventory_type') not in (INVTYPE_WEAPON, INVTYPE_WEAPON_MAIN_HAND):
        return None
    return one_handed


def off_hand_weapon(class_file: dict, item: int) -> dict:
    weapon = next((weapon for weapon in class_file.get('off_hand_weapons', []) if weapon['item'] == item), None)
    if weapon is None:
        raise ValueError(f'off-hand item {item} is not in the class file off_hand_weapons')
    grants = weapon.get('grants', [])
    if not isinstance(grants, list) or not all(type(spell) is int and spell > 0 for spell in grants):
        raise ValueError(f'off-hand item {item} grants is a list of spell ids learned before it is equipped, not '
                         f'{grants!r}')
    return weapon


def off_hand_steps(item: int, grants: tuple[int, ...] = ()) -> list[dict]:
    return [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in grants] + [
            {'action': 'add_item', 'actor': CASTER, 'item': item},
            {'action': 'equip', 'actor': CASTER, 'item': item, 'slot': EQUIPMENT_SLOT_OFF_HAND}]


def weapon_subclass(class_file: dict) -> int | None:
    weapon = class_file.get('weapon')
    return weapon['subclass'] if weapon else None


def character_of(class_file: dict, skills: dict[int, float]) -> dict:
    return {'level': class_file['level'], 'skills': skills, 'weapon_subclass': weapon_subclass(class_file),
            'race': class_file.get('race'), 'class_id': class_file.get('class_id')}


def caster_stats_from(measured: Mapping[str, float], class_file: dict,
                      known_spells: frozenset[int] = frozenset()) -> CasterStats:
    skills = {line: measured[skill_label(line)] for line in class_file.get('skill_lines', [])
              if skill_label(line) in measured}
    return CasterStats(
        ap=measured['attack_power'],
        rap=measured['ranged_attack_power'],
        sp_by_school={school: measured[spell_power_label(school)] for school in SPELL_POWER_SCHOOLS},
        stats={stat: measured[stat_label(stat)] for stat in STATS},
        known_spells=known_spells,
        **character_of(class_file, skills))
