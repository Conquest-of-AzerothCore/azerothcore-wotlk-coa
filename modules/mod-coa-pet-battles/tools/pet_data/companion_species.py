import collections
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

FAMILIES = ['Humanoid', 'Dragonkin', 'Flying', 'Undead', 'Critter', 'Magic', 'Elemental', 'Beast', 'Aquatic', 'Mechanical']
KIT_STATS = ('Stat_Power', 'Stat_Speed', 'Stat_Stamina')
EXPLICIT_STAND_IN_BASE = 9850000
EXPLICIT_STAND_IN_LIMIT = 9899999
GENERATED_TABLES = ('coa_pet_species', 'coa_pet_kit', 'coa_pet_kit_ability', 'coa_pet_presentation',
                    'coa_pet_companion', 'coa_pet_standin')
ACCEPTED_RULES = ('1 ', '2 ', '3 ', '4 ', '5 ')

RetailKit = collections.namedtuple('RetailKit', 'species name family kind rows stats')
Generated = collections.namedtuple('Generated', 'tables notes')


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
    accepted = [row for row in proposal if row['rule'].startswith(ACCEPTED_RULES)]
    kits = retail_kits(retail, qualifying_abilities(tables))
    family_pools = pools(kits, tables)
    dealable = {kit.species for pool in family_pools.values() for kit in pool}
    species_by_entry = {row[0]: row for row in tables['coa_pet_species']}
    kit_family = {row[0]: row[2] for row in tables['coa_pet_kit']}
    known_kits = set(kit_family)
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
            copied_from[creature] = source
            chosen[creature] = species_by_entry[source][2]
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
