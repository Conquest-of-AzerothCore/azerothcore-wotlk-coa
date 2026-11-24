import argparse
import struct
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))

import sql_reader

SPELL_FIELDS = 234
EFFECTS = slice(71, 74)
MISC_VALUES = slice(110, 113)
SUMMON_EFFECTS = (28, 41, 42, 56)
STOCK_UNMAPPED = (49964, 50049, 62609, 62746)
STATUS_ORDER = ('species-match', 'kit-match', 'needs-review', 'missing-creature', 'mapped')


def read_summons(path):
    raw = Path(path).read_bytes()
    magic, records, fields, size, _ = struct.unpack_from('<4s4I', raw, 0)
    if magic != b'WDBC' or fields != SPELL_FIELDS:
        raise ValueError(f'{path} is not a {SPELL_FIELDS}-field Spell.dbc')
    summons = {}
    for index in range(records):
        row = struct.unpack_from(f'<{fields}I', raw, 20 + index * size)
        created = [misc for effect, misc in zip(row[EFFECTS], row[MISC_VALUES]) if effect in SUMMON_EFFECTS and misc]
        if created:
            summons[row[0]] = created
    return summons


def classify(spell, creatures, creature_names, species_entries, species_by_name, kits_by_name, mapped):
    if spell in mapped:
        return 'mapped', f'species {mapped[spell]}'
    if not creatures:
        return 'missing-creature', 'no summon effect'
    for creature in creatures:
        if creature in species_entries:
            return 'species-match', f'species {creature}'
    named = [creature_names[creature] for creature in creatures if creature in creature_names]
    if not named:
        return 'missing-creature', ''
    for name in named:
        if name.lower() in species_by_name:
            return 'species-match', f'species {species_by_name[name.lower()]}'
    for name in named:
        if name.lower() in kits_by_name:
            return 'kit-match', f'kit {kits_by_name[name.lower()]}'
    return 'needs-review', ''


def query(defaults, sql):
    output = subprocess.run(['mysql', f'--defaults-extra-file={defaults}', '-N', '-B', '-e', sql],
                            check=True, capture_output=True, text=True).stdout
    return [line.split('\t') for line in output.splitlines() if line]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--spell-dbc', required=True)
    parser.add_argument('--mysql-defaults', required=True)
    parser.add_argument('--world-db', default='acore_world')
    parser.add_argument('--pet-sql-dir', default=str(ROOT / 'data/sql/updates/pending_db_world'))
    parser.add_argument('--out', default=str(ROOT / 'modules/mod-coa-pet-battles/data/companion_review.tsv'))
    args = parser.parse_args()

    tables = sql_reader.read(sorted(Path(args.pet_sql_dir).glob('rev_2026112[34]_*_coa_pet_battles_*.sql')))
    species_entries = {row[0] for row in tables['coa_pet_species']}
    species_by_name = {}
    for row in sorted(tables['coa_pet_species']):
        species_by_name.setdefault(row[1].lower(), row[0])
    kits_by_name = {}
    for row in sorted(tables['coa_pet_kit']):
        kits_by_name.setdefault(row[1].lower(), row[0])
    mapped = {row[0]: row[1] for row in tables['coa_pet_companion']}

    spells = {int(row[0]) for row in query(args.mysql_defaults,
              f'SELECT DISTINCT `spellid_2` FROM `{args.world_db}`.`item_template` '
              'WHERE `class` = 15 AND `subclass` = 2 AND `spellid_2` > 0')}
    spells.update(STOCK_UNMAPPED)
    summons = read_summons(args.spell_dbc)
    creatures = sorted({creature for spell in spells for creature in summons.get(spell, [])})
    names = {}
    if creatures:
        for entry, name in query(args.mysql_defaults,
                                 f'SELECT `entry`, `name` FROM `{args.world_db}`.`creature_template` '
                                 f'WHERE `entry` IN ({",".join(map(str, creatures))})'):
            names[int(entry)] = name

    rows = []
    for spell in sorted(spells):
        summoned = summons.get(spell, [])
        status, suggestion = classify(spell, summoned, names, species_entries, species_by_name, kits_by_name, mapped)
        creature = summoned[0] if summoned else 0
        rows.append((STATUS_ORDER.index(status), spell, creature, names.get(creature, ''), status, suggestion))
    rows.sort()
    lines = ['spell\tcreature\tname\tstatus\tsuggestion']
    lines += [f'{spell}\t{creature}\t{name}\t{status}\t{suggestion}' for _, spell, creature, name, status, suggestion
              in rows]
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_text('\n'.join(lines) + '\n', encoding='utf-8')
    counts = {}
    for row in rows:
        counts[row[4]] = counts.get(row[4], 0) + 1
    print({'spells': len(rows), **counts})


if __name__ == '__main__':
    main()
