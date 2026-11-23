import math
import re
from pathlib import Path

from tables import TABLES

STAND_IN_BASE = 9800000
STAND_IN_LIMIT = 9849999
PREFIX = 'coa_pet_'
ZEROED = ('difficulty_entry_1', 'difficulty_entry_2', 'difficulty_entry_3', 'KillCredit1', 'KillCredit2', 'npcflag',
          'unit_flags', 'unit_flags2', 'dynamicflags', 'lootid', 'pickpocketloot', 'skinloot', 'gossip_menu_id',
          'mingold', 'maxgold', 'VehicleId', 'PetSpellDataId', 'flags_extra', 'rank', 'MovementType', 'type_flags')
ESCAPES = {'\\': '\\\\', "'": "\\'", '"': '\\"', '\0': '\\0', '\n': '\\n', '\r': '\\r', '\t': '\\t', '\x1a': '\\Z'}


def literal(value):
    if isinstance(value, bool) or value is None:
        raise ValueError(f'unsupported value {value!r}')
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError(f'unsupported value {value!r}')
        return repr(value)
    if isinstance(value, str):
        return "'" + ''.join(ESCAPES.get(char, char) for char in value) + "'"
    raise ValueError(f'unsupported value {value!r}')


def check_tables(tables):
    unknown = sorted(set(tables) - set(TABLES))
    missing = sorted(set(TABLES) - set(tables))
    if unknown or missing:
        raise ValueError(f'unknown tables {unknown}, missing tables {missing}')
    for name, rows in tables.items():
        for row in rows:
            if len(row) != len(TABLES[name]):
                raise ValueError(f'{name}: row {row!r} has {len(row)} values, expected {len(TABLES[name])}')


def check_stand_ins(species):
    for entry in species:
        if isinstance(entry, bool) or not isinstance(entry, int) or entry < 0 or STAND_IN_BASE + entry > STAND_IN_LIMIT:
            raise ValueError(f'stand-in species {entry!r} is outside the reserved range')


def table_sql(name, rows):
    columns = ', '.join(f'`{column}`' for column in TABLES[name])
    lines = [f'DELETE FROM `{name}`;']
    if rows:
        values = ',\n'.join('(' + ', '.join(literal(value) for value in row) + ')' for row in rows)
        lines.append(f'INSERT INTO `{name}` ({columns}) VALUES\n{values};')
    return '\n'.join(lines) + '\n'


def creature_template_columns(path):
    text = Path(path).read_text(encoding='utf-8')
    body = re.search(r'CREATE TABLE `creature_template` \((.*?)\) ENGINE=', text, re.S)
    if not body:
        raise ValueError(f'creature_template definition not found in {path}')
    return re.findall(r'^\s*`(\w+)`\s', body.group(1), re.M)


def template_expression(column):
    if column == 'entry':
        return f'`src`.`entry` + {STAND_IN_BASE}'
    if column in ('AIName', 'ScriptName'):
        return "''"
    if column == 'faction':
        return '35'
    if column == 'type':
        return 'IF(`src`.`type` = 12, 1, `src`.`type`)'
    if column in ('minlevel', 'maxlevel'):
        return '60'
    if column in ZEROED:
        return '0'
    return f'`src`.`{column}`'


def stand_in_sql(species, scale, template_columns):
    if 'entry' not in template_columns:
        raise ValueError('creature_template columns must include entry')
    ids = ', '.join(str(entry) for entry in species)
    columns = ', '.join(f'`{column}`' for column in template_columns)
    selected = ', '.join(f'{template_expression(column)} AS `{column}`' for column in template_columns)
    updates = ', '.join(f'`{column}` = `coa_new`.`{column}`' for column in template_columns if column != 'entry')
    range_clause = f'BETWEEN {STAND_IN_BASE} AND {STAND_IN_LIMIT}'
    lines = [
        f'INSERT INTO `creature_template` ({columns})',
        f'SELECT * FROM (SELECT {selected} FROM `creature_template` AS `src` '
        f'WHERE `src`.`entry` IN ({ids})) AS `coa_new`',
        f'ON DUPLICATE KEY UPDATE {updates};',
        f'DELETE FROM `creature_template_model` WHERE `CreatureID` {range_clause};',
        'INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, '
        f'`Probability`, `VerifiedBuild`) SELECT `CreatureID` + {STAND_IN_BASE}, `Idx`, `CreatureDisplayID`, '
        f'`DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` IN ({ids});',
        f'DELETE FROM `creature_equip_template` WHERE `CreatureID` {range_clause};',
        'INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) '
        f'SELECT `CreatureID` + {STAND_IN_BASE}, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild` '
        f'FROM `creature_equip_template` WHERE `CreatureID` IN ({ids});',
    ]
    lines += [f'UPDATE `creature_template_model` SET `DisplayScale` = {literal(float(value))} '
              f'WHERE `CreatureID` = {STAND_IN_BASE + entry} AND `Idx` = {index};' for entry, index, value in scale]
    return '\n'.join(lines) + '\n'


def write(export, directory, date, first_number, template_columns):
    tables = export['tables']
    check_tables(tables)
    standins = export['standins']
    check_stand_ins(standins['species'])
    check_stand_ins([entry for entry, _, _ in standins['scale']])
    contents = [(name[len(PREFIX):], table_sql(name, tables[name])) for name in TABLES]
    contents.append(('standins', stand_in_sql(standins['species'], standins['scale'], template_columns)))
    paths = []
    for offset, (part, text) in enumerate(contents):
        path = Path(directory) / f'rev_{date}_{first_number + offset}_coa_pet_battles_{part}.sql'
        path.write_text(text, encoding='utf-8')
        paths.append(path)
    return paths
