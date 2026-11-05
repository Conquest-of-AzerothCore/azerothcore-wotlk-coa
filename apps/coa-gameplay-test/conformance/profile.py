import json
from pathlib import Path
from typing import Mapping

from tooltip import CasterStats

CLASSES_DIR = Path(__file__).resolve().parent / 'classes'
DBC_DIR = Path('/srv/coa/server-data/dbc')
SETTLE_MS = 5000
UNBOUNDED = 10**9
SPELL_POWER_SCHOOLS = range(1, 7)
STATS = range(5)
CASTER = 'caster'
EQUIPMENT_SLOT_MAIN_HAND = 15


def measurement(label: str, actor: str, metric: str, **fields) -> dict:
    return {'action': 'assert', 'label': label, 'actor': actor, 'metric': metric, **fields,
            'min': -UNBOUNDED, 'max': UNBOUNDED}


def spell_power_label(school: int) -> str:
    return f'spell_power {school}'


def stat_label(stat: int) -> str:
    return f'stat {stat}'


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


def caster_stats_from(measured: Mapping[str, float], level: int) -> CasterStats:
    return CasterStats(
        level=level,
        ap=measured['attack_power'],
        rap=measured['ranged_attack_power'],
        sp_by_school={school: measured[spell_power_label(school)] for school in SPELL_POWER_SCHOOLS},
        stats={stat: measured[stat_label(stat)] for stat in STATS})
