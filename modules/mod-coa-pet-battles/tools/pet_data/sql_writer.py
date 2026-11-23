import math
from pathlib import Path

from tables import TABLES

CHUNK = 1000
SCALE_CHUNK = 500
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
    for start in range(0, len(rows), CHUNK):
        chunk = rows[start:start + CHUNK]
        values = ',\n'.join('(' + ', '.join(literal(value) for value in row) + ')' for row in chunk)
        lines.append(f'INSERT INTO `{name}` ({columns}) VALUES\n{values};')
    return '\n'.join(lines) + '\n'


def stand_in_sql(species, scale):
    ids = ','.join(str(entry) for entry in species)
    zeroed = ', '.join(f"'{column}'" for column in ZEROED)
    lines = [
        f'DELETE FROM `creature_equip_template` WHERE `CreatureID` BETWEEN {STAND_IN_BASE} AND {STAND_IN_LIMIT};',
        f'DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN {STAND_IN_BASE} AND {STAND_IN_LIMIT};',
        f'DELETE FROM `creature_template` WHERE `entry` BETWEEN {STAND_IN_BASE} AND {STAND_IN_LIMIT};',
        'SET SESSION group_concat_max_len = 1000000;',
        f"SET @coa_pet_ids = '{ids}';",
        "SET @coa_pet_cols = (SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`') ORDER BY ORDINAL_POSITION "
        "SEPARATOR ',') FROM information_schema.columns WHERE table_schema = DATABASE() "
        "AND table_name = 'creature_template');",
        "SET @coa_pet_sel = (SELECT GROUP_CONCAT(CASE\n"
        f"    WHEN COLUMN_NAME = 'entry' THEN 'src.`entry` + {STAND_IN_BASE}'\n"
        "    WHEN COLUMN_NAME IN ('AIName', 'ScriptName') THEN '\\'\\''\n"
        "    WHEN COLUMN_NAME = 'faction' THEN '35'\n"
        "    WHEN COLUMN_NAME = 'type' THEN 'IF(src.`type` = 12, 1, src.`type`)'\n"
        "    WHEN COLUMN_NAME IN ('minlevel', 'maxlevel') THEN '60'\n"
        f"    WHEN COLUMN_NAME IN ({zeroed}) THEN '0'\n"
        "    ELSE CONCAT('src.`', COLUMN_NAME, '`') END ORDER BY ORDINAL_POSITION SEPARATOR ',') "
        "FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'creature_template');",
        "SET @coa_pet_query = CONCAT('INSERT INTO `creature_template` (', @coa_pet_cols, ') SELECT ', @coa_pet_sel, "
        "' FROM `creature_template` src WHERE FIND_IN_SET(src.`entry`, @coa_pet_ids)');",
        'PREPARE coa_pet_statement FROM @coa_pet_query;',
        'EXECUTE coa_pet_statement;',
        'DEALLOCATE PREPARE coa_pet_statement;',
        'INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, '
        f'`Probability`, `VerifiedBuild`) SELECT `CreatureID` + {STAND_IN_BASE}, `Idx`, `CreatureDisplayID`, '
        '`DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` '
        'WHERE FIND_IN_SET(`CreatureID`, @coa_pet_ids);',
        'INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) '
        f'SELECT `CreatureID` + {STAND_IN_BASE}, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild` '
        'FROM `creature_equip_template` WHERE FIND_IN_SET(`CreatureID`, @coa_pet_ids);',
    ]
    for start in range(0, len(scale), SCALE_CHUNK):
        cases = ' '.join(f"WHEN '{STAND_IN_BASE + entry}-{index}' THEN {literal(float(value))}"
                         for entry, index, value in scale[start:start + SCALE_CHUNK])
        lines.append(f"UPDATE `creature_template_model` SET `DisplayScale` = CASE CONCAT(`CreatureID`, '-', `Idx`) "
                     f'{cases} ELSE `DisplayScale` END WHERE `CreatureID` BETWEEN {STAND_IN_BASE} AND '
                     f'{STAND_IN_LIMIT};')
    return '\n'.join(lines) + '\n'


def write(export, directory, date, first_number):
    tables = export['tables']
    check_tables(tables)
    standins = export['standins']
    check_stand_ins(standins['species'])
    check_stand_ins([entry for entry, _, _ in standins['scale']])
    contents = [(name[len(PREFIX):], table_sql(name, tables[name])) for name in TABLES]
    contents.append(('standins', stand_in_sql(standins['species'], standins['scale'])))
    paths = []
    for offset, (part, text) in enumerate(contents):
        path = Path(directory) / f'rev_{date}_{first_number + offset}_coa_pet_battles_{part}.sql'
        path.write_text(text, encoding='utf-8')
        paths.append(path)
    return paths
