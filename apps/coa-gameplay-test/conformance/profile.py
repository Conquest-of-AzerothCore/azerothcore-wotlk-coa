import json
from pathlib import Path
from typing import Mapping

from tooltip import SKILL_PER_LEVEL, CasterStats

CLASSES_DIR = Path(__file__).resolve().parent / 'classes'
DBC_DIR = Path('/srv/coa/server-data/dbc')
SETTLE_MS = 5000
UNBOUNDED = 10**9
SPELL_POWER_SCHOOLS = range(1, 7)
STATS = range(5)
CASTER = 'caster'
EQUIPMENT_SLOT_MAIN_HAND = 15
WEAPON_ITEM_CLASS = 2
INVTYPE_WEAPON = 13
ONE_HAND_SLOT_TYPES = (1 << 21) | (1 << 22)
EQUIP_FIELDS = ('EquippedItemClass', 'EquippedItemSubClassMask', 'EquippedItemInventoryTypeMask')


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


def load_class_file(class_id: int) -> dict:
    for path in sorted(CLASSES_DIR.glob('*.json')):
        class_file = json.loads(path.read_text(encoding='utf-8'))
        if class_file['class_id'] == class_id:
            return class_file
    raise ValueError(f'No class file for class {class_id}')


def player_fixture(class_file: dict) -> dict:
    return {'id': CASTER, 'race': class_file['race'], 'class': class_file['class_id'],
            'level': class_file['level'], **class_file.get('ratings', {})}


def base_steps(class_file: dict) -> list[dict]:
    steps = [{'action': 'wait', 'label': 'settle', 'ms': SETTLE_MS}]
    weapon = class_file.get('weapon')
    if weapon:
        steps.append({'action': 'add_item', 'actor': CASTER, 'item': weapon['item']})
        steps.append({'action': 'equip', 'actor': CASTER, 'item': weapon['item'],
                      'slot': weapon.get('slot', EQUIPMENT_SLOT_MAIN_HAND)})
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


def armed(class_file: dict, requirement: Mapping[str, int]) -> dict:
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
