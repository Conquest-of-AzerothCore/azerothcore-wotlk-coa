import argparse
import collections
import csv
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))

import sql_reader
import sql_writer
import tables

FAMILIES = ['Humanoid', 'Dragonkin', 'Flying', 'Undead', 'Critter', 'Magic', 'Elemental', 'Beast', 'Aquatic', 'Mechanical']
KIT_STATS = ('Stat_Power', 'Stat_Speed', 'Stat_Stamina')
EXPLICIT_STAND_IN_BASE = 9850000
EXPLICIT_STAND_IN_LIMIT = 9899999
GENERATED_TABLES = ('coa_pet_species', 'coa_pet_kit', 'coa_pet_kit_ability', 'coa_pet_presentation',
                    'coa_pet_companion', 'coa_pet_standin')
ACCEPTED_RULES = ('1 ', '2 ', '3 ', '4 ', '5 ')
WORLD_SQL = ROOT / 'data/sql/updates/pending_db_world'
GENERATED_SQL = WORLD_SQL / 'rev_20261125_02_coa_pet_companion_species.sql'
PROPOSAL = HERE.parents[1] / 'data/companion_proposal.tsv'
TEMPLATE_SCHEMA = ROOT / 'data/sql/base/db_world/creature_template.sql'

RetailKit = collections.namedtuple('RetailKit', 'species name family kind rows stats')
Generated = collections.namedtuple('Generated', 'tables notes')


def pet_sql_paths():
    return sorted(WORLD_SQL.glob('rev_2026112[34]_*_coa_pet_battles_*.sql'))


def read_proposal(path):
    lines = [line for line in Path(path).read_text(encoding='utf-8').splitlines() if not line.startswith('#')]
    return list(csv.DictReader(lines, delimiter='\t'))


def read_csv(path):
    csv.field_size_limit(10 ** 8)
    return list(csv.DictReader(open(path, encoding='utf-8', newline='')))


def read_retail(directory):
    directory = Path(directory)
    return {
        'species': read_csv(directory / 'BattlePetSpecies.csv'),
        'creatures': {r['ID']: r['Name_lang'] for r in read_csv(directory / 'Creature.csv')},
        'links': read_csv(directory / 'BattlePetSpeciesXAbility.csv'),
        'abilities': {r['ID']: r for r in read_csv(directory / 'BattlePetAbility.csv')},
        'states': {r['ID']: r['LuaName'] for r in read_csv(directory / 'BattlePetState.csv')},
        'species_states': read_csv(directory / 'BattlePetSpeciesState.csv'),
    }


def check_sources(generated, present):
    missing = sorted(entry for entry, _ in generated.tables['coa_pet_standin'] if entry not in present)
    if missing:
        raise ValueError(f'source creatures missing from creature_template: {missing[:20]}')


def taken_entries(defaults, entries):
    out = subprocess.run(['mysql', f'--defaults-extra-file={defaults}', '-N', '-B', 'acore_world', '-e',
                          'SELECT entry FROM creature_template WHERE entry IN (' + id_list(entries) + ')'],
                         capture_output=True, text=True, check=True).stdout
    return sorted(int(line) for line in out.split())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--retail', required=True)
    parser.add_argument('--retail-date', required=True)
    parser.add_argument('--state-date', required=True)
    parser.add_argument('--mysql-defaults', required=True)
    parser.add_argument('--out', default=str(GENERATED_SQL))
    args = parser.parse_args()
    generated = generate(read_proposal(PROPOSAL), sql_reader.read(pet_sql_paths()), read_retail(args.retail))
    taken = taken_entries(args.mysql_defaults, [entry for _, entry in generated.tables['coa_pet_standin']])
    if taken:
        raise SystemExit(f'stand-in entries already in creature_template: {taken[:10]}')
    check_sources(generated, set(taken_entries(args.mysql_defaults,
                                               [species for species, _ in generated.tables['coa_pet_standin']])))
    header = ('-- CoA companions as battle pets: modules/mod-coa-pet-battles/tools/pet_data/companion_species.py\n'
              '-- retail: wago.tools DB2 CSVs BattlePetSpecies, BattlePetSpeciesXAbility, BattlePetAbility, Creature '
              f'fetched {args.retail_date}; BattlePetSpeciesState, BattlePetState fetched {args.state_date}')
    sql = companion_sql(generated, sql_writer.creature_template_columns(TEMPLATE_SCHEMA), header)
    Path(args.out).write_text(sql, encoding='utf-8')
    for name in GENERATED_TABLES:
        print(f'{name:22} {len(generated.tables[name])}')
    print('notes', len(generated.notes))
    kit_family = {r[0]: r[2] for r in sql_reader.read(pet_sql_paths())['coa_pet_kit'] + generated.tables['coa_pet_kit']}
    families = collections.Counter(FAMILIES[kit_family[r[2]]] for r in generated.tables['coa_pet_species'])
    print('families', dict(sorted(families.items())))


def kind_of(name):
    words = re.sub(r'[^a-z0-9 ]', '', name.lower()).split()
    return words[-1] if words else ''


def qualifying_abilities(tables):
    known = {row[0] for row in tables['coa_pet_ability']}
    return {row[4] for row in tables['coa_pet_presentation'] if row[4] in known}


def retail_kits(retail, qualifying):
    links = collections.defaultdict(list)
    for link in retail['links']:
        slot = int(link['SlotEnum'])
        if 0 <= slot <= 2:
            links[int(link['BattlePetSpeciesID'])].append((slot, int(link['RequiredLevel']),
                                                           int(link['BattlePetAbilityID'])))
    stats = collections.defaultdict(dict)
    for state in retail['species_states']:
        name = retail['states'].get(state['BattlePetStateID'])
        if name in KIT_STATS:
            stats[int(state['BattlePetSpeciesID'])][name] = int(state['Value'])
    kits = {}
    for species in retail['species']:
        sid = int(species['ID'])
        rows = tuple(sorted(links.get(sid, ())))
        if len(rows) != 6 or [slot for slot, _, _ in rows] != [0, 0, 1, 1, 2, 2]:
            continue
        if any(ability not in qualifying for _, _, ability in rows):
            continue
        name = retail['creatures'].get(species['CreatureID'], '')
        kits[sid] = RetailKit(sid, name, int(species['PetTypeEnum']), kind_of(name), rows,
                              tuple(stats[sid].get(stat, 0) for stat in KIT_STATS))
    return kits


def existing_kit_rows(tables):
    rows = collections.defaultdict(list)
    for kit, slot, level, ability in tables['coa_pet_kit_ability']:
        rows[kit].append((slot, level, ability))
    return {kit: tuple(sorted(value)) for kit, value in rows.items()}


def pools(kits, tables):
    existing = existing_kit_rows(tables)
    known = {row[0] for row in tables['coa_pet_kit']}
    result = collections.defaultdict(list)
    for sid in sorted(kits):
        kit = kits[sid]
        if sid in known and existing.get(sid) != kit.rows:
            continue
        result[FAMILIES[kit.family]].append(kit)
    return dict(result)


def deal(companions, family_pools):
    counters = collections.Counter()
    dealt = {}
    for creature, name, family in sorted(companions):
        pool = family_pools.get(family, [])
        if not pool:
            raise ValueError(f'no kits for family {family}')
        kind = kind_of(name)
        same_kind = [kit for kit in pool if kit.kind == kind]
        key, choices = ((family, kind), same_kind) if same_kind else ((family, None), pool)
        dealt[creature] = choices[counters[key] % len(choices)].species
        counters[key] += 1
    return dealt


def presentation_sources(tables, retail):
    by_ability = collections.defaultdict(list)
    for row in tables['coa_pet_presentation']:
        by_ability[row[4]].append(row)
    sources = {}
    for ability, rows in by_ability.items():
        retail_name = retail['abilities'].get(str(ability), {}).get('Name_lang', '')
        named = [row for row in rows if row[5] == retail_name]
        if not named:
            counts = collections.Counter(row[5] for row in rows)
            best = max(counts.values())
            name = min((min(row[0] for row in rows if row[5] == n), n) for n, c in counts.items() if c == best)[1]
            named = [row for row in rows if row[5] == name]
        sources[ability] = (min(named, key=lambda row: (row[0], row[1], row[2])), retail_name)
    return sources


def family_icons(tables):
    kit_family = {row[0]: row[2] for row in tables['coa_pet_kit']}
    counts = collections.defaultdict(collections.Counter)
    for species in tables['coa_pet_species']:
        family = kit_family.get(species[2])
        if family is not None and species[8]:
            counts[family][species[8]] += 1
    return {family: min(counter.items(), key=lambda item: (-item[1], item[0]))[0] for family, counter in counts.items()}


def retail_source(row):
    match = re.match(r'retail species (\d+)', row['source'])
    return int(match.group(1)) if match else None


def matched_species(row):
    match = re.match(r'species (\d+)', row['source'])
    return int(match.group(1)) if match else None


def generate(proposal, tables, retail):
    tables = {name: [tuple(row) for row in rows] for name, rows in tables.items()}
    accepted = [row for row in proposal if row['rule'].startswith(ACCEPTED_RULES)]
    kits = retail_kits(retail, qualifying_abilities(tables))
    family_pools = pools(kits, tables)
    dealable = {kit.species for pool in family_pools.values() for kit in pool}
    species_by_entry = {row[0]: row for row in tables['coa_pet_species']}
    kit_family = {row[0]: row[2] for row in tables['coa_pet_kit']}
    known_kits = set(kit_family)
    existing_rows = existing_kit_rows(tables)
    icons = family_icons(tables)
    notes = {}

    by_creature = {}
    for row in sorted(accepted, key=lambda r: (int(r['creature']), int(r['spell']))):
        by_creature.setdefault(int(row['creature']), row)

    chosen, to_deal, copied_from = {}, [], {}
    for creature, row in by_creature.items():
        if row['rule'].startswith('1 '):
            sid = retail_source(row)
            if sid in dealable:
                chosen[creature] = sid
                continue
            notes[creature] = f'retail species {sid} kit not dealable; dealt a {row["family"]} kit'
            to_deal.append((creature, row['name'], row['family']))
        elif row['rule'].startswith('2 '):
            source = matched_species(row)
            if len(existing_rows.get(species_by_entry[source][2], ())) == 6:
                copied_from[creature] = source
                chosen[creature] = species_by_entry[source][2]
                continue
            notes[creature] = f'species {source} kit is incomplete; dealt a {row["family"]} kit'
            to_deal.append((creature, row['name'], row['family']))
        else:
            to_deal.append((creature, row['name'], row['family']))
    chosen.update(deal(to_deal, family_pools))

    sources = presentation_sources(tables, retail)
    out = {name: [] for name in GENERATED_TABLES}
    added_kits = set()
    for index, (creature, row) in enumerate(by_creature.items()):
        kit = chosen[creature]
        if creature in copied_from:
            source = species_by_entry[copied_from[creature]]
            icon = source[8]
            out['coa_pet_presentation'] += [(creature,) + p[1:] for p in sorted(tables['coa_pet_presentation'])
                                            if p[0] == source[0]]
        else:
            retail_kit = kits[kit]
            icon = icons.get(retail_kit.family, '')
            if kit not in known_kits and kit not in added_kits:
                added_kits.add(kit)
                out['coa_pet_kit'].append((kit, retail_kit.name, retail_kit.family) + retail_kit.stats)
                out['coa_pet_kit_ability'] += [(kit,) + r for r in retail_kit.rows]
            for slot, level, ability in retail_kit.rows:
                option = 1 if level == min(l for s, l, _ in retail_kit.rows if s == slot) else 2
                source_row, retail_name = sources[ability]
                out['coa_pet_presentation'].append((creature, slot, option, level, ability, source_row[5], retail_name)
                                                   + source_row[7:])
        out['coa_pet_species'].append((creature, row['name'], kit, 0, 1, 0, 1, 1, icon, 0.0))
        out['coa_pet_standin'].append((creature, EXPLICIT_STAND_IN_BASE + index))
    if len(by_creature) > EXPLICIT_STAND_IN_LIMIT - EXPLICIT_STAND_IN_BASE + 1:
        raise ValueError('too many stand-ins for the explicit range')
    out['coa_pet_companion'] = sorted((int(row['spell']), int(row['creature'])) for row in accepted)
    out['coa_pet_kit'].sort()
    out['coa_pet_kit_ability'].sort()
    return Generated(out, notes)


TABLE_KEYS = {'coa_pet_species': 'entry', 'coa_pet_kit': 'id', 'coa_pet_kit_ability': 'kit',
              'coa_pet_presentation': 'species', 'coa_pet_companion': 'spell', 'coa_pet_standin': 'species'}
STANDIN_COLUMNS = ['species', 'entry']


def table_columns(name):
    return STANDIN_COLUMNS if name == 'coa_pet_standin' else tables.TABLES[name]


def id_list(values):
    return ', '.join(str(value) for value in sorted(set(values)))


def standin_expression(column):
    return '`m`.`standin`' if column == 'entry' else sql_writer.template_expression(column)


def companion_sql(generated, template_columns, header):
    lines = [header]
    for name in GENERATED_TABLES:
        rows = generated.tables[name]
        if not rows:
            continue
        columns = table_columns(name)
        key = TABLE_KEYS[name]
        lines.append(f'DELETE FROM `{name}` WHERE `{key}` IN ({id_list(r[columns.index(key)] for r in rows)});')
        values = ',\n'.join('(' + ', '.join(sql_writer.literal(value) for value in r) + ')' for r in rows)
        lines.append(f'INSERT INTO `{name}` ({", ".join(f"`{c}`" for c in columns)}) VALUES\n{values};')
    standins = generated.tables['coa_pet_standin']
    if not standins:
        return '\n'.join(lines) + '\n'
    mapping = ', '.join(f'ROW({species}, {entry})' for species, entry in standins)

    def joined(key):
        return f'JOIN (VALUES {mapping}) AS `m` (`src_entry`, `standin`) ON `src`.`{key}` = `m`.`src_entry`'
    entries = id_list(entry for _, entry in standins)
    selected = ', '.join(f'{standin_expression(column)} AS `{column}`' for column in template_columns)
    updates = ', '.join(f'`{c}` = `coa_new`.`{c}`' for c in template_columns if c != 'entry')
    lines += [
        f'INSERT INTO `creature_template` ({", ".join(f"`{c}`" for c in template_columns)})\n'
        f'SELECT * FROM (SELECT {selected} FROM `creature_template` AS `src` {joined("entry")}) AS `coa_new`\n'
        f'ON DUPLICATE KEY UPDATE {updates};',
        f'DELETE FROM `creature_template_model` WHERE `CreatureID` IN ({entries});',
        'INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, '
        '`Probability`, `VerifiedBuild`)\nSELECT `m`.`standin`, `src`.`Idx`, `src`.`CreatureDisplayID`, '
        '`src`.`DisplayScale`, `src`.`Probability`, `src`.`VerifiedBuild` FROM `creature_template_model` AS `src` '
        f'{joined("CreatureID")};',
        f'DELETE FROM `creature_equip_template` WHERE `CreatureID` IN ({entries});',
        'INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, '
        '`VerifiedBuild`)\nSELECT `m`.`standin`, `src`.`ID`, `src`.`ItemID1`, `src`.`ItemID2`, `src`.`ItemID3`, '
        f'`src`.`VerifiedBuild` FROM `creature_equip_template` AS `src` {joined("CreatureID")};',
    ]
    return '\n'.join(lines) + '\n'


if __name__ == '__main__':
    main()
