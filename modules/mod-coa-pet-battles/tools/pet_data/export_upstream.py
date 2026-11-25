import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from tables import TABLES

SCHEMA = HERE.parents[3] / 'data/sql/updates/pending_db_world/rev_20261123_80_coa_pet_battles_schema.sql'
OLD_STAND_IN_BASE = 9000000
INTEGER_RANGES = {
    'TINYINT UNSIGNED': (0, 255), 'TINYINT': (-128, 127), 'SMALLINT UNSIGNED': (0, 65535),
    'SMALLINT': (-32768, 32767), 'INT UNSIGNED': (0, 4294967295), 'INT': (-2147483648, 2147483647),
}


def schema_types():
    text = SCHEMA.read_text(encoding='utf-8')
    types = {}
    for name, body in re.findall(r'CREATE TABLE `(\w+)` \((.*?)\) ENGINE=InnoDB', text, re.S):
        types[name] = [column_type.strip() for column_type in
                       re.findall(r'^\s*`\w+`\s+([A-Z]+(?:\(\d+\))?(?: UNSIGNED)?)', body, re.M)]
    return types


def integer(value):
    if isinstance(value, bool):
        raise ValueError(f'boolean {value!r} where a number is expected')
    if isinstance(value, float) and value.is_integer():
        return int(value)
    if isinstance(value, int):
        return value
    raise ValueError(f'{value!r} is not a whole number')


def coerce(value, column_type):
    if column_type in INTEGER_RANGES:
        low, high = INTEGER_RANGES[column_type]
        number = integer(value)
        if not low <= number <= high:
            raise ValueError(f'{number} outside {column_type}')
        return number
    if column_type == 'FLOAT':
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError(f'{value!r} is not a number')
        return float(value)
    if not isinstance(value, str):
        raise ValueError(f'{value!r} is not text')
    limit = re.fullmatch(r'VARCHAR\((\d+)\)', column_type)
    if limit and len(value) > int(limit.group(1)):
        raise ValueError(f'{value!r} longer than {column_type}')
    if column_type == 'TEXT' and len(value.encode('utf-8')) > 65535:
        raise ValueError('text longer than TEXT')
    return value


def plain(lua_type, value):
    if lua_type(value) != 'table':
        return int(value) if isinstance(value, float) and value.is_integer() else value
    return {plain(lua_type, key): plain(lua_type, item) for key, item in value.items()}


def seq(table, what):
    if not table:
        return []
    if set(table) != set(range(1, len(table) + 1)):
        raise ValueError(f'{what} is not a list: keys {sorted(table, key=str)[:10]}')
    return [table[index] for index in range(1, len(table) + 1)]


def flag(value):
    return 1 if value not in (None, False, 0) else 0


def required(table, key, what):
    if key not in table or table[key] is None:
        raise ValueError(f'{what}: {key} missing')
    return table[key]


def run_lua(upstream):
    from lupa.lua51 import LuaRuntime, lua_type
    lua = LuaRuntime(unpack_returned_tuples=True)
    scripts = (Path(upstream) / 'scripts').resolve()
    lua.execute(f'package.path = {json.dumps(str(scripts) + "/?.lua")} .. ";" .. package.path')
    chunk = (HERE / 'export.lua').read_text(encoding='utf-8')
    return plain(lua_type, lua.execute(chunk))


def species_rows(data):
    rows = []
    for entry, species in sorted(data['species'].items()):
        rows.append([entry, required(species, 'name', f'species {entry}'), required(species, 'retail', f'species {entry}'),
                     flag(species.get('wild')), flag(species.get('companion')), flag(species.get('critter')),
                     flag(species.get('synthetic')), 0 if species.get('standin') is False else 1,
                     species.get('icon', ''), species.get('scale', 0.0)])
    return rows


KIT_STATS = ('Stat_Power', 'Stat_Speed', 'Stat_Stamina')


def kit_rows(data):
    families = seq(data['families'], 'families')
    kits, kit_abilities, ignored = [], [], []
    for kit_id, kit in sorted(data['kits'].items()):
        what = f'kit {kit_id}'
        family = required(kit, 'family', what)
        if family not in families:
            raise ValueError(f'{what}: unknown family {family!r}')
        stats = kit.get('stats') or {}
        ignored += [[kit_id, key, value] for key, value in sorted(stats.items()) if key not in KIT_STATS]
        kits.append([kit_id, required(kit, 'name', what), families.index(family)] +
                    [stats.get(key, 0) for key in KIT_STATS])
        for slot_entry in seq(required(kit, 'abil', what), f'{what} abil'):
            slot, level, ability = seq(slot_entry, f'{what} abil entry')
            kit_abilities.append([kit_id, slot, level, ability])
    return kits, kit_abilities, ignored


def ability_rows(data):
    abilities, turns, effects = [], [], []
    for ability_id, ability in sorted(data['abilities'].items()):
        what = f'ability {ability_id}'
        abilities.append([ability_id, required(ability, 'name', what), required(ability, 'family', what),
                          required(ability, 'cd', what), ability.get('text') or '', ability.get('base') or 0])
        for turn_index, turn in enumerate(seq(required(ability, 'turns', what), f'{what} turns'), 1):
            turns.append([ability_id, turn_index, required(turn, 'turn', what), required(turn, 'event', what)])
            for effect_index, effect in enumerate(seq(required(turn, 'fx', what), f'{what} fx'), 1):
                params = seq(required(effect, 'p', f'{what} turn {turn_index} fx {effect_index}'), f'{what} params')
                if len(params) > 6:
                    raise ValueError(f'{what}: {len(params)} params')
                effects.append([ability_id, turn_index, effect_index, required(effect, 'prop', what),
                                effect.get('aura') or 0] + params + [0] * (6 - len(params)))
    return abilities, turns, effects


def state_rows(data):
    labels = [[prop, index, label] for prop, names in sorted(data['effects'].items())
              for index, label in enumerate(seq(names, f'effect labels {prop}'))]
    states = [[state, name] for state, name in sorted(data['stateNames'].items())]
    aura_states = [[aura, name, value] for aura, values in sorted(data['states'].items())
                   for name, value in sorted(values.items())]
    xp = [[level] + seq(row, f'xp {level}') for level, row in sorted(data['xp'].items())]
    return labels, states, aura_states, xp


def zone_rows(data):
    zones, by_name = [], {}
    for zone_id, zone in sorted(data['zones'].items()):
        what = f'zone {zone_id}'
        name = required(zone, 'name', what)
        if name in by_name:
            raise ValueError(f'zone name {name!r} used by zones {by_name[name]} and {zone_id}')
        by_name[name] = zone_id
        zones.append([zone_id, name, required(zone, 'lo', what), required(zone, 'hi', what),
                      required(zone, 'minMob', what), required(zone, 'maxMob', what)])
    zone_species, dropped, seen = [], [], set()
    for name, species_list in sorted(data['zoneSpecies'].items()):
        for species in seq(species_list, f'zone species {name}'):
            if name not in by_name or species not in data['species']:
                dropped.append([name, species])
            elif (by_name[name], species) not in seen:
                seen.add((by_name[name], species))
                zone_species.append([by_name[name], species])
    return zones, sorted(zone_species), dropped


def presentation_rows(data):
    rows = []
    for entry, kit_rows_ in sorted(data['presentation'].items()):
        for row in seq(kit_rows_, f'presentation {entry}'):
            rows.append([entry, row['slot'] - 1, row['option'], row['unlock'], row['ability'], row['name'],
                         row['retailName'], row['icon'], row['text'], row['vis'], row['ranged'], row['vmode'],
                         row['vpre'], row['vhop'], row['vdmg'], row['priority']])
    return rows


def size_rows(data):
    models = [[species] + seq(size, f'model size {species}') for species, size in sorted(data['modelSizes'].items())]
    displays = [[display, size] for display, size in sorted(data['displaySizes'].items())]
    return models, displays


def companion_rows(upstream, species):
    text = (Path(upstream) / 'custom-sql/004_menagerie.sql').read_text(encoding='utf-8')
    block = re.search(r'INSERT INTO dc_companion \(spell, npc\) VALUES(.*?);', text, re.S)
    if not block:
        raise ValueError('dc_companion rows not found in 004_menagerie.sql')
    kept, dropped = [], []
    for spell, npc in re.findall(r'\((\d+),\s*(\d+)\)', block.group(1)):
        (kept if int(npc) in species else dropped).append([int(spell), int(npc)])
    return sorted(kept), dropped


def stand_ins(upstream, data):
    species = sorted(entry for entry, row in data['species'].items() if row.get('standin') is not False)
    stand_in_set = set(species)
    text = (Path(upstream) / 'custom-sql/017_pet_standin_scale.sql').read_text(encoding='utf-8')
    scale, skipped = [], 0
    for entry, index, value in re.findall(r"'(\d+)-(\d+)' THEN ([0-9.]+)", text):
        target = int(entry) - OLD_STAND_IN_BASE
        if target in stand_in_set:
            scale.append([target, int(index), float(value)])
        else:
            skipped += 1
    return {'species': species, 'scale': scale}, skipped


def typed(tables):
    types = schema_types()
    for name, rows in tables.items():
        for row in rows:
            if len(row) != len(types[name]):
                raise ValueError(f'{name}: row {row!r} does not match {len(types[name])} columns')
            for index, column_type in enumerate(types[name]):
                try:
                    row[index] = coerce(row[index], column_type)
                except ValueError as error:
                    raise ValueError(f'{name}.{TABLES[name][index]} in {row!r}: {error}') from None
    return tables


def build(upstream, commit):
    data = run_lua(upstream)
    kits, kit_abilities, ignored_kit_stats = kit_rows(data)
    abilities, turns, effects = ability_rows(data)
    labels, states, aura_states, xp = state_rows(data)
    zones, zone_species, dropped_zone_species = zone_rows(data)
    models, displays = size_rows(data)
    companions, dropped_companions = companion_rows(upstream, data['species'])
    standins, skipped_scale = stand_ins(upstream, data)
    tables = typed({
        'coa_pet_species': species_rows(data), 'coa_pet_kit': kits, 'coa_pet_kit_ability': kit_abilities,
        'coa_pet_ability': abilities, 'coa_pet_ability_turn': turns, 'coa_pet_ability_effect': effects,
        'coa_pet_effect_property': labels, 'coa_pet_state': states, 'coa_pet_aura_state': aura_states,
        'coa_pet_xp': xp, 'coa_pet_zone': zones, 'coa_pet_zone_species': zone_species,
        'coa_pet_presentation': presentation_rows(data), 'coa_pet_model_size': models,
        'coa_pet_display_size': displays, 'coa_pet_companion': companions,
    })
    manifest = {name: len(rows) for name, rows in tables.items()}
    lua_counts = data['luaCounts']
    expected = {'species': manifest['coa_pet_species'], 'kits': manifest['coa_pet_kit'],
                'abilities': manifest['coa_pet_ability'], 'zones': manifest['coa_pet_zone'],
                'auraStates': len({row[0] for row in tables['coa_pet_aura_state']})}
    for key, value in expected.items():
        if lua_counts[key] != value:
            raise ValueError(f'{key}: Lua has {lua_counts[key]}, export has {value}')
    return {'upstream': {'path': str(Path(upstream).resolve()), 'commit': commit}, 'tables': tables,
            'standins': standins, 'dropped_companions': dropped_companions,
            'dropped_zone_species': dropped_zone_species, 'skipped_scale_rows': skipped_scale,
            'ignored_kit_stats': ignored_kit_stats,
            'manifest': manifest, 'lua_counts': lua_counts}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--upstream', required=True)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    export = build(args.upstream, args.commit)
    Path(args.out).write_text(json.dumps(export, ensure_ascii=False, sort_keys=True), encoding='utf-8')
    print(json.dumps({'manifest': export['manifest'], 'lua_counts': export['lua_counts'],
                      'standins': len(export['standins']['species']), 'scale': len(export['standins']['scale']),
                      'dropped_companions': export['dropped_companions'],
                      'dropped_zone_species': len(export['dropped_zone_species']),
                      'skipped_scale_rows': export['skipped_scale_rows'],
                      'ignored_kit_stats': export['ignored_kit_stats']}, indent=1))


if __name__ == '__main__':
    main()
