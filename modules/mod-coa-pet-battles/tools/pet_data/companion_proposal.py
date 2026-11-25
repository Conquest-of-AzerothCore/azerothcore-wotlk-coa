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

MODULE = HERE.parents[1]
FAMILIES = ['Humanoid', 'Dragonkin', 'Flying', 'Undead', 'Critter', 'Magic', 'Elemental', 'Beast', 'Aquatic', 'Mechanical']
CREATURE_TYPE_FAMILY = {1: 'Beast', 2: 'Dragonkin', 3: 'Magic', 4: 'Elemental', 5: 'Humanoid', 6: 'Undead', 7: 'Humanoid',
                        8: 'Critter', 9: 'Mechanical'}
KEYWORDS = (
    (('glimmerfly', 'moth', 'butterfly', 'dragonfly', 'firefly', 'falcon', 'hawk', 'owl', 'owlet', 'parrot', 'raven',
      'crow', 'chick', 'gryphon', 'hippogryph', 'wyvern', 'bat', 'skyray'), 'Flying'),
    (('whelp', 'whelpling', 'drake', 'wyrmling', 'dragonhawk', 'hatchling'), 'Dragonkin'),
    (('pup', 'cub', 'kitten', 'cat', 'wolf', 'bear', 'calf', 'fawn', 'stag', 'boar', 'raptor', 'tiger', 'lion', 'fox',
      'hound', 'panther', 'saber', 'crocolisk', 'turtle', 'spider', 'scorpid', 'beetle'), 'Beast'),
    (('hare', 'rabbit', 'bunny', 'mouse', 'rat', 'squirrel', 'toad', 'toadlet', 'frog', 'snail', 'roach', 'cockroach',
      'prairie dog', 'skunk', 'chipmunk', 'larva', 'worm', 'grub', 'swoglet'), 'Critter'),
    (('crab', 'fish', 'murloc', 'murky', 'murkling', 'tadpole', 'eel', 'jellyfish', 'shark', 'otter', 'seal',
      'penguin', 'pengu', 'turtle'), 'Aquatic'),
    (('bot', 'robot', 'mech', 'mechanical', 'golem', 'construct', 'balloon', 'reaper', 'harvester', 'shredder',
      'clockwork', 'tank', 'rocket'), 'Mechanical'),
    (('elemental', 'geode', 'flame', 'ember', 'spark', 'wisp', 'pebble', 'cinder', 'gust', 'tempest', 'sproutling',
      'lasher', 'treant', 'seedling'), 'Elemental'),
    (('ghost', 'ghostly', 'skull', 'skeleton', 'zombie', 'ghoul', 'spirit', 'soul', 'banshee', 'lich', 'wight',
      'abomination', 'bone', 'risen'), 'Undead'),
    (('imp', 'fel', 'demon', 'eye', 'orb', 'arcane', 'mana', 'crystal', 'shard', 'shardling', 'voidling', 'void',
      'wisdomball', 'familiar', 'netherwhelp'), 'Magic'),
    (('squire', 'gruntling', 'peon', 'gnome', 'goblin', 'orc', 'troll', 'dwarf', 'mage', 'magus', 'priest', 'knight',
      'lord', 'lady', 'king', 'queen', 'warrior', 'soldier', 'sentinel', 'guard', 'butcher', 'merchant', 'trader'),
     'Humanoid'),
)
STANDIN_LIMIT = 49999
COLUMNS = ('spell', 'creature', 'name', 'rule', 'confidence', 'family', 'kit', 'abilities', 'missing_abilities',
           'source', 'stand_in', 'note')


def norm(name):
    name = name.lower().replace("'", '').replace('-', ' ').replace('.', '')
    return re.sub(r'\s+', ' ', name).strip()


def read_csv(path):
    csv.field_size_limit(10 ** 8)
    return list(csv.DictReader(open(path, encoding='utf-8', newline='')))


def query(defaults, sql):
    out = subprocess.run(['mysql', f'--defaults-extra-file={defaults}', '-N', '-B', 'acore_world', '-e', sql],
                         capture_output=True, text=True, check=True).stdout
    return [line.split('\t') for line in out.splitlines() if line]


def keyword_family(name):
    words = norm(name).split()
    text = ' '.join(words)
    for keywords, family in KEYWORDS:
        for keyword in keywords:
            if keyword in words or (' ' in keyword and keyword in text):
                return family, keyword
    return None, None


def load(args):
    tables = sql_reader.read(sorted((ROOT / 'data/sql/updates/pending_db_world').glob(
        'rev_2026112[34]_*_coa_pet_battles_*.sql')))
    review = list(csv.DictReader(open(MODULE / 'data/companion_review.tsv', encoding='utf-8'), delimiter='\t'))
    retail = Path(args.retail)
    return tables, review, {
        'creatures': {r['ID']: r['Name_lang'] for r in read_csv(retail / 'Creature.csv')},
        'species': read_csv(retail / 'BattlePetSpecies.csv'),
        'links': read_csv(retail / 'BattlePetSpeciesXAbility.csv'),
        'abilities': {r['ID']: r for r in read_csv(retail / 'BattlePetAbility.csv')},
    }


def build(args):
    tables, review, retail = load(args)
    picks = {norm(row['name']): row for row in csv.DictReader(open(HERE / 'companion_picks.tsv', encoding='utf-8'),
                                                                 delimiter='\t')}
    ability_names = {row[0]: row[1] for row in tables['coa_pet_ability']}
    kit_rows = collections.defaultdict(list)
    for kit, slot, unlock, ability in tables['coa_pet_kit_ability']:
        kit_rows[kit].append((slot, unlock, ability))
    kits = {row[0]: row for row in tables['coa_pet_kit']}
    species = {row[0]: row for row in tables['coa_pet_species']}

    retail_by_name = collections.defaultdict(list)
    for row in retail['species']:
        name = retail['creatures'].get(row['CreatureID'], '')
        if name:
            retail_by_name[norm(name)].append(row)
    retail_links = collections.defaultdict(list)
    for link in retail['links']:
        retail_links[link['BattlePetSpeciesID']].append(
            (int(link['SlotEnum']) + 1, int(link['RequiredLevel']), int(link['BattlePetAbilityID'])))

    todo = [r for r in review if r['status'] in ('needs-review', 'kit-match')]
    unmappable = [r for r in review if r['status'] == 'missing-creature']
    creatures = sorted({int(r['creature']) for r in todo if r['creature'].isdigit()} | set(species))
    in_list = ','.join(map(str, creatures))
    displays = collections.defaultdict(set)
    for creature, display in query(args.mysql_defaults, 'SELECT CreatureID, CreatureDisplayID FROM '
                                   f'creature_template_model WHERE CreatureID IN ({in_list})'):
        displays[int(creature)].add(int(display))
    species_by_display = collections.defaultdict(set)
    for entry in species:
        for display in displays.get(entry, ()):
            species_by_display[display].add(entry)
    companion_creatures = {int(r['creature']) for r in review if r['creature'].isdigit()}
    origins = collections.defaultdict(list)
    for entry, name, kind in query(args.mysql_defaults, 'SELECT entry, name, type FROM creature_template WHERE type <> 12'):
        if int(entry) not in companion_creatures:
            origins[norm(name)].append((int(entry), int(kind)))

    def kit_abilities(kit):
        rows = sorted(kit_rows.get(kit, ()))
        shift = 1 if rows and min(slot for slot, _, _ in rows) == 0 else 0
        return ' '.join(f'{slot + shift}.{unlock}:{ability_names.get(ability, ability)}' for slot, unlock, ability in rows)

    proposals = []
    for row in todo:
        creature = int(row['creature'])
        base = {'spell': row['spell'], 'creature': row['creature'], 'name': row['name'],
                'stand_in': 'fits' if creature <= STANDIN_LIMIT else 'needs new stand-in id', 'missing_abilities': '',
                'note': ''}
        hits = retail_by_name.get(norm(row['name']))
        if hits:
            best = max(hits, key=lambda r: sum(1 for link in retail_links[r['ID']] if 1 <= link[0] <= 3))
            links = sorted(link for link in retail_links[best['ID']] if 1 <= link[0] <= 3)
            missing = [str(a) for _, _, a in links if a not in ability_names]
            names = ' '.join(f'{s}.{lvl}:{ability_names.get(a, retail["abilities"].get(str(a), {}).get("Name_lang", a))}'
                             for s, lvl, a in links)
            existing = int(best['ID']) in kits
            proposals.append({**base, 'rule': '1 retail pet', 'confidence': 'high' if not missing and len(links) == 6
                              else 'medium', 'family': FAMILIES[int(best['PetTypeEnum'])],
                              'kit': f"{best['ID']} ({'existing' if existing else 'new retail kit'})",
                              'abilities': names, 'missing_abilities': ' '.join(missing),
                              'source': f"retail species {best['ID']}"})
            continue
        shared = set().union(*(species_by_display[d] for d in displays.get(creature, ()))) if displays.get(creature) else set()
        if shared:
            match = min(shared)
            kit = species[match][2]
            family = FAMILIES[kits[kit][2]] if kit in kits and 0 <= kits[kit][2] < len(FAMILIES) else ''
            proposals.append({**base, 'rule': '2 same model', 'confidence': 'medium', 'family': family,
                              'kit': f'{kit} (existing)', 'abilities': kit_abilities(kit),
                              'source': f'species {match} {species[match][1]}',
                              'note': 'check: CoA reuses some models across unrelated companions'})
            continue
        origin = origins.get(norm(row['name']))
        if origin:
            entry, kind = collections.Counter(origin).most_common(1)[0][0]
            family = CREATURE_TYPE_FAMILY.get(kind)
            if family:
                proposals.append({**base, 'rule': '3 original creature', 'confidence': 'medium', 'family': family,
                                  'kit': f'generate from creature {entry}', 'abilities': '',
                                  'source': f'creature {entry} type {kind}',
                                  'note': 'kit to be generated like the wild kits'})
                continue
        family, keyword = keyword_family(row['name'])
        if family:
            proposals.append({**base, 'rule': '4 keyword', 'confidence': 'low', 'family': family,
                              'kit': f'generate ({family})', 'abilities': '', 'source': f'keyword "{keyword}"',
                              'note': 'kit to be generated for the family'})
            continue
        pick = picks.get(norm(row['name']))
        if pick:
            proposals.append({**base, 'rule': '5 picked', 'confidence': 'low', 'family': pick['family'],
                              'kit': f"generate ({pick['family']})", 'abilities': '', 'source': 'companion_picks.tsv',
                              'note': pick['reason']})
            continue
        proposals.append({**base, 'rule': '5 decision', 'confidence': 'none', 'family': '', 'kit': '', 'abilities': '',
                          'source': '', 'note': 'needs a family'})
    for row in unmappable:
        proposals.append({'spell': row['spell'], 'creature': row['creature'], 'name': row['name'], 'rule': '6 no creature',
                          'confidence': 'none', 'family': '', 'kit': '', 'abilities': '', 'missing_abilities': '',
                          'source': '', 'stand_in': '', 'note': 'ignored: the summoned creature is not in the database'})
    return proposals


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--retail', required=True)
    parser.add_argument('--retail-date', required=True)
    parser.add_argument('--mysql-defaults', required=True)
    parser.add_argument('--out', default=str(MODULE / 'data/companion_proposal.tsv'))
    args = parser.parse_args()
    proposals = build(args)
    with open(args.out, 'w', encoding='utf-8', newline='') as handle:
        handle.write(f'# retail battle pet tables: wago.tools BattlePetSpecies, BattlePetSpeciesXAbility, '
                     f'BattlePetAbility, Creature, fetched {args.retail_date}\n')
        writer = csv.DictWriter(handle, COLUMNS, delimiter='\t', lineterminator='\n')
        writer.writeheader()
        writer.writerows(sorted(proposals, key=lambda p: (p['rule'], p['name'].lower(), int(p['spell']))))
    counts = collections.Counter((p['rule'], p['confidence']) for p in proposals)
    for key in sorted(counts):
        print(f'{key[0]:22} {key[1]:7} {counts[key]}')


if __name__ == '__main__':
    main()
