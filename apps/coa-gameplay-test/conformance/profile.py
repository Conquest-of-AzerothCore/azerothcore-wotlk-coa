from functools import lru_cache
import hashlib
import json
from pathlib import Path
from typing import Mapping

from tooltip import SKILL_PER_LEVEL, CasterStats

CLASSES_DIR = Path(__file__).resolve().parent / 'classes'
CONTROLS_DIR = Path(__file__).resolve().parent / 'controls'
DBC_DIR = Path('/srv/coa/server-data/dbc')
SETTLE_MS = 5000
UNBOUNDED = 10**9
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


def load_class_file(class_id: int) -> dict:
    for path in class_file_paths():
        class_file = json.loads(path.read_text(encoding='utf-8'))
        if class_file['class_id'] == class_id:
            if 'dbc_dir' in class_file:
                server_dbc_dir(class_file['dbc_dir'])
            return class_file
    raise ValueError(f'No class file for class {class_id}')


def control_entries(class_id: int) -> list[dict]:
    for path in sorted(CONTROLS_DIR.glob('*.json')):
        controls = json.loads(path.read_text(encoding='utf-8'))
        if controls['class_id'] == class_id:
            return controls['behaviours']
    return []


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


def one_hand_main(class_file: dict) -> dict | None:
    one_handed = armed(class_file, ONE_HAND_MAIN)
    if one_handed.get('weapon', {}).get('inventory_type') not in (INVTYPE_WEAPON, INVTYPE_WEAPON_MAIN_HAND):
        return None
    return one_handed


def off_hand_weapon(class_file: dict, item: int) -> dict:
    weapon = next((weapon for weapon in class_file.get('off_hand_weapons', []) if weapon['item'] == item), None)
    if weapon is None:
        raise ValueError(f'off-hand item {item} is not in the class file off_hand_weapons')
    return weapon


def off_hand_steps(item: int) -> list[dict]:
    return [{'action': 'add_item', 'actor': CASTER, 'item': item},
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
