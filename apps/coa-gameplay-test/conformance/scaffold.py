import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from classes import CHARACTER_LEVEL, PROGRESSION_HEADER, class_skill_lines, class_spells
from profile import (EQUIPMENT_SLOT_MAIN_HAND, SPELL_POWER_SCHOOLS, STATS, base_steps, player_fixture, skill_label,
                     spell_power_label, stat_label)

ROOT = Path(__file__).resolve().parents[3]
SHARED_DEFINES = ROOT / 'src/server/shared/SharedDefines.h'
LIVE_BASELINE_HEADER = ROOT / 'src/server/coa/AscensionLiveBaselineData.h'

CLASS_TITLE_LINE = re.compile(r'^\s*CLASS_\w+\s*=\s*(\d+),\s*//\s*TITLE\s+(.+?)\s*$', re.MULTILINE)
PROFICIENCIES_ARRAY = re.compile(r'\bProficiencies\s*=\s*\{\{(.*?)\}\};', re.S)
PROFICIENCY_ROW = re.compile(r'\{\s*(\d+),\s*(\d+),\s*(\d+)\s*\}')

TWO_HAND_INVENTORY_TYPE = 17
RANGED_INVENTORY_TYPES = (15, 25, 26)
ONE_HAND_INVENTORY_TYPES = (13, 21, 22)
DAGGER_SUBCLASS = 15
WEAPON_ITEM_CLASS = 2
REFERENCE_QUALITY = 1
STAT_SLOTS = range(1, 11)
SPELL_SLOTS = range(1, 6)
REFERENCE_RATINGS = {'spell_hit_rating': 10000, 'melee_hit_rating': 10000, 'expertise_rating': 10000}
EMPTY_LIST_FIELDS = ('alternate_weapons', 'off_hand_weapons', 'known_auras', 'probe_auras', 'extra_spells',
                     'disabled_foreign_effects', 'foreign_aura_grants', 'effect_overrides',
                     'item_armor_subclass_effects', 'unmodelled_effects', 'literal_tokens',
                     'effect_notes', 'passive_targets', 'procs', 'triggers', 'talent_modifiers', 'rotation',
                     'stack', 'behaviours', 'player_observations', 'player_tooltip_readings', 'hit_notes',
                     'conditional_spells', 'weapon_percent_before_flat', 'self_stack_bonus',
                     'dual_target_effects', 'target_aura_gates', 'learned_hits', 'cast_auras', 'hit_casts')


class ScaffoldError(ValueError):
    pass


def class_title(shared_defines_text: str, class_id: int) -> str:
    for found_id, title in CLASS_TITLE_LINE.findall(shared_defines_text):
        if int(found_id) == class_id:
            return title
    raise ScaffoldError(f'No TITLE comment for class {class_id} in SharedDefines.h')


def class_proficiencies(live_baseline_text: str, class_id: int) -> list[tuple[int, int]]:
    match = PROFICIENCIES_ARRAY.search(live_baseline_text)
    if not match:
        raise ScaffoldError('No Proficiencies array found in AscensionLiveBaselineData.h')
    rows = {(int(skill), int(spell)) for row_class, skill, spell in PROFICIENCY_ROW.findall(match.group(1))
           if int(row_class) == class_id}
    if not rows:
        raise ScaffoldError(f'No Proficiencies row for class {class_id} in AscensionLiveBaselineData.h')
    return sorted(rows)


def select_weapon_rows(proficiency_rows: list[tuple[int, int]], subclass_of_spell: dict[int, int]
                       ) -> tuple[tuple[int, int, int], tuple[int, int, int] | None]:
    resolved = [(skill, spell, subclass_of_spell[spell]) for skill, spell in proficiency_rows
               if spell in subclass_of_spell]
    if not resolved:
        raise ScaffoldError('No proficiency spell resolves to a weapon item subclass')
    main = resolved[0]
    alternate = next((candidate for candidate in resolved[1:] if candidate[2] != main[2]), None)
    return main, alternate


def normalized_speed(inventory_type: int, subclass: int) -> float:
    if inventory_type == TWO_HAND_INVENTORY_TYPE:
        return 3.3
    if inventory_type in RANGED_INVENTORY_TYPES:
        return 2.8
    if inventory_type in ONE_HAND_INVENTORY_TYPES:
        return 1.7 if subclass == DAGGER_SUBCLASS else 2.4
    raise ScaffoldError(f'Unsupported reference weapon inventory type {inventory_type}')


def weapon_entry(item_row: dict, subclass: int, slot: int = EQUIPMENT_SLOT_MAIN_HAND,
                 skill_line: int | None = None) -> dict:
    inventory_type = int(item_row['InventoryType'])
    entry = {'item': int(item_row['entry']), 'slot': slot, 'subclass': subclass,
             'min_damage': float(item_row['dmg_min1']), 'max_damage': float(item_row['dmg_max1']),
             'speed_ms': int(item_row['delay']), 'inventory_type': inventory_type,
             'normalized_speed': normalized_speed(inventory_type, subclass)}
    if skill_line is not None:
        entry['skill_line'] = skill_line
    return entry


def lowest_race(races: list[int]) -> int:
    if not races:
        raise ScaffoldError('No playercreateinfo race for this class')
    return min(int(race) for race in races)


def playercreateinfo_sql(class_id: int) -> str:
    return f"SELECT JSON_OBJECT('race', race) FROM playercreateinfo WHERE class = {int(class_id)};"


def item_candidate_sql(subclass: int) -> str:
    stat_clause = ' AND '.join(f'stat_type{slot} = 0' for slot in STAT_SLOTS)
    spell_clause = ' AND '.join(f'spellid_{slot} = 0' for slot in SPELL_SLOTS)
    return (f"SELECT JSON_OBJECT('entry', entry, 'dmg_min1', dmg_min1, 'dmg_max1', dmg_max1, "
            f"'delay', delay, 'InventoryType', InventoryType) FROM item_template "
            f"WHERE class = {WEAPON_ITEM_CLASS} AND subclass = {int(subclass)} AND Quality = {REFERENCE_QUALITY} "
            f"AND ItemLevel > 0 AND {stat_clause} AND {spell_clause} ORDER BY ItemLevel, entry LIMIT 1;")


def local_select(config: Path, mysql, sql: str) -> list:
    sys.path.insert(0, str(ROOT / 'apps/coa-gameplay-test'))
    import run

    settings = run.read_config(config)
    connection = run.Connection.parse(run.source_setting(settings, 'WorldDatabaseInfo'))
    with tempfile.TemporaryDirectory(prefix='coa-scaffold-sql-') as temporary:
        defaults = Path(temporary) / 'client.cnf'
        with defaults.open('x', encoding='utf-8') as stream:
            defaults.chmod(0o600)
            stream.write('[client]\n' + '\n'.join(f'{key}={run.cnf_quote(str(value))}' for key, value in
                [('host', connection.host), ('port', connection.port), ('user', connection.user),
                 ('password', connection.password)]))
        command = [str(mysql), '--defaults-extra-file=' + str(defaults), '--no-login-paths',
                   '--batch', '--raw', '--skip-column-names', '--default-character-set=utf8mb4',
                   '--connect-timeout=10', '--database=' + connection.database]
        result = subprocess.run(command, input=sql, text=True, capture_output=True, timeout=30)
        if result.returncode:
            raise ScaffoldError('Local world database query failed; verify the selected config and MySQL client')
        return [json.loads(line) for line in result.stdout.splitlines() if line.strip()]


def build_class_file(class_id: int, title: str, race: int, main: tuple[int, int, int], weapon_item_row: dict,
                     skill_lines: list[int], alternate: tuple[int, int, int] | None = None,
                     alternate_item_row: dict | None = None, level: int = CHARACTER_LEVEL) -> dict:
    _, _, main_subclass = main
    class_file = {'class_id': class_id, 'name': title, 'race': race, 'level': level,
                 'weapon': weapon_entry(weapon_item_row, main_subclass), 'skill_lines': list(skill_lines),
                 'ratings': dict(REFERENCE_RATINGS), 'reference_stats': {}, 'log_queries': {}}
    for field in EMPTY_LIST_FIELDS:
        class_file[field] = []
    if alternate is not None and alternate_item_row is not None:
        alt_skill, _, alt_subclass = alternate
        class_file['alternate_weapons'] = [weapon_entry(alternate_item_row, alt_subclass, skill_line=alt_skill)]
    return class_file


def naked_scenario(class_file: dict) -> dict:
    sys.path.append(str(Path(__file__).resolve().parents[1]))
    import run

    scenario = {
        'schema': 1,
        'name': f'Conformance naked reference character of {class_file["name"]}',
        'contract': 'No-combat measurement of the base_steps fixture for a freshly scaffolded class file: equips '
                   'the reference weapon, sets each skill line to its cap, and reads attack power, ranged attack '
                   'power, spell power per school, the five stats and weapon_damage_min with no judgement bounds.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file),
    }
    return run.validate(scenario)


def reference_stats_from_result(result: dict, class_file: dict) -> dict:
    from compare import measured_values
    measured = measured_values(result)
    stats = {'attack_power': measured['attack_power'], 'ranged_attack_power': measured['ranged_attack_power']}
    for school in SPELL_POWER_SCHOOLS:
        stats[spell_power_label(school)] = measured[spell_power_label(school)]
    for stat in STATS:
        stats[stat_label(stat)] = measured[stat_label(stat)]
    for line in class_file.get('skill_lines', []):
        label = skill_label(line)
        if label in measured:
            stats[label] = measured[label]
    return stats


def scaffold_class(class_id: int, dbc_dir: Path, config: Path, mysql, level: int = CHARACTER_LEVEL,
                   shared_defines: Path = SHARED_DEFINES, live_baseline: Path = LIVE_BASELINE_HEADER,
                   progression_header: Path = PROGRESSION_HEADER) -> dict:
    from classes import dataset
    from tooltip import Records, weapon_skill_spells

    title = class_title(Path(shared_defines).read_text(encoding='utf-8'), class_id)
    proficiency_rows = class_proficiencies(Path(live_baseline).read_text(encoding='utf-8'), class_id)
    records = Records(dataset(dbc_dir))
    subclass_of_spell = {spell: subclass for subclass, spell in weapon_skill_spells(records).items()}
    main, alternate = select_weapon_rows(proficiency_rows, subclass_of_spell)
    races = [row['race'] for row in local_select(config, mysql, playercreateinfo_sql(class_id))]
    weapon_candidates = local_select(config, mysql, item_candidate_sql(main[2]))
    if not weapon_candidates:
        raise ScaffoldError(f'No reference item_template row for weapon subclass {main[2]}')
    alternate_candidates = local_select(config, mysql, item_candidate_sql(alternate[2])) if alternate else []
    spells = class_spells(dbc_dir, class_id, progression_header, level)
    skill_lines = class_skill_lines(dbc_dir, spells, main[2])
    return build_class_file(class_id, title, lowest_race(races), main, weapon_candidates[0], skill_lines,
                            alternate=alternate,
                            alternate_item_row=alternate_candidates[0] if alternate_candidates else None,
                            level=level)
