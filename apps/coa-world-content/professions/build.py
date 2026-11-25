import argparse
from collections import defaultdict
import csv
from fractions import Fraction
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
BASELINE = ROOT / 'apps/coa-tests/tbc_jewelcrafting_rescale/baseline.json'
MIGRATION = ROOT / 'data/sql/updates/pending_db_world/rev_20261122_03_coa_tbc_jewelcrafting_level60.sql'
SLOTS = {1: 1, 2: 3, 11: 3, 12: 2}


def rounded(value):
    value = Fraction(value)
    sign = -1 if value < 0 else 1
    return sign * ((abs(value.numerator) * 2 + value.denominator) // (2 * value.denominator))


def mapped(level, minimum, maximum, low, high):
    if minimum == maximum:
        if low != high:
            raise ValueError('One original item level requires a single target')
        return low
    return low + rounded(Fraction((level - minimum) * (high - low), maximum - minimum))


def equipment(data):
    return [row for row in data['items'] if int(row['InventoryType']) and not int(row['GemProperties'])]


def profile(row):
    return {(int(row[f'Effect_{n}']), int(row[f'EffectArg_{n}'])): int(row[f'EffectPointsMin_{n}'])
            for n in range(1, 4) if int(row[f'Effect_{n}'])}


def build(data, low=60, high=77):
    if not 0 < low <= high:
        raise ValueError('Invalid target band')
    gear = equipment(data)
    minimum = min(int(row['ItemLevel']) for row in gear if int(row['ItemLevel']) > 60)
    maximum = max(int(row['ItemLevel']) for row in gear)
    enchants = {int(row['ID']): row for row in data['enchants']}
    pools = defaultdict(list)
    for row in data['property_pools']:
        pools[int(row['entry'])].append(row)
    properties = {row['id']: row for row in data['property_profiles']}
    families = defaultdict(list)
    for row in properties.values():
        families[(row['name'], tuple(tuple(key) for key, value in row['effects']))].append(row)
    changes, budgets, mappings, new_pools, details = {}, [], [], [], []
    for item in sorted(gear, key=lambda row: int(row['entry'])):
        entry, original = int(item['entry']), int(item['ItemLevel'])
        target = mapped(original, minimum, maximum, low, high) if original > 60 else original
        if target > original:
            raise ValueError(f'Item {entry} would be upscaled')
        quality = {2: 'Good', 3: 'Superior', 4: 'Epic'}[int(item['Quality'])]
        column = quality + '_' + str(SLOTS[int(item['InventoryType'])])
        factor = Fraction(int(data['points'][str(target)][column]), int(data['points'][str(original)][column]))
        update = {'ItemLevel': target, 'RequiredLevel': min(60, int(item['RequiredLevel']))}
        fields = [f'stat_value{n}' for n in range(1, 11)]
        fields += [school + '_res' for school in ('holy', 'fire', 'nature', 'frost', 'shadow', 'arcane')]
        fields += ['armor', 'block']
        for field in fields:
            update[field] = rounded(int(item[field]) * factor)
        if int(item['InventoryType']) == 1 and int(item['armor']):
            donors = [row for row in data['armor_donors'] if int(row['ItemLevel']) == target and
                      int(row['Quality']) == int(item['Quality'])]
            assert donors and len({int(row['armor']) for row in donors}) == 1
            update['armor'] = int(donors[0]['armor'])
        old_bonus = int(item['socketBonus'])
        if old_bonus:
            original_bonus = profile(enchants[old_bonus])
            wanted = {key: max(1, rounded(value * factor)) for key, value in original_bonus.items()}
            options = [(sum(abs(profile(row)[key] - value) for key, value in wanted.items()), identifier)
                       for identifier, row in enchants.items() if set(profile(row)) == set(wanted)]
            difference, selected = min(options)
            if difference:
                raise ValueError(f'No exact client-known socket bonus for {entry}: {wanted}')
            update['socketBonus'] = selected
        power = [0, 0]
        for n in range(1, 6):
            sid = int(item[f'spellid_{n}'])
            for index, base in enumerate((101600, 101700)):
                if base < sid < base + 100:
                    power[index] += rounded((sid - base) * factor)
                    update[f'spellid_{n}'] = base + rounded((sid - base) * factor)
            if sid == 33488:
                amount = max(1, rounded(5 * factor))
                update[f'spellid_{n}'] = {1: 26596, 2: 26597, 3: 26598, 4: 25901, 5: 33488}[amount]
        original_group = int(item['RandomProperty'])
        group_families = defaultdict(list)
        for choice in pools[original_group]:
            row = properties[int(choice['ench'])]
            key = row['name'], tuple(tuple(key) for key, value in row['effects'])
            group_families[key].append(choice)
        local = {}
        for key, choices in group_families.items():
            total = sum(Fraction(choice['chance']) for choice in choices)
            wanted = [sum(Fraction(choice['chance']) * properties[int(choice['ench'])]['effects'][n][1]
                          for choice in choices) / total * factor for n in range(len(key[1]))]
            def distance(candidate):
                return sum(abs(Fraction(value) - want) / max(1, abs(want))
                           for (stat, value), want in zip(candidate['effects'], wanted))
            selected = min(families[key], key=lambda row: (distance(row), row['id']))['id']
            for choice in choices:
                local[int(choice['ench'])] = selected
            local[selected] = selected
        assert all(local.get(value, value) == value for value in local.values())
        combined = defaultdict(Fraction)
        for choice in pools[original_group]:
            combined[local[int(choice['ench'])]] += Fraction(choice['chance'])
        group = 6100000 + entry
        update['RandomProperty'] = group
        new_pools.extend((group, key, float(chance)) for key, chance in sorted(combined.items()))
        mappings.extend((entry, source, target) for source, target in sorted(local.items()))
        budgets.append((entry, 755, 1, original, target, *power))
        changes[entry] = update
        details.append({'entry': entry, 'name': item['name'], 'original': original, 'target': target,
                        'factor': float(factor), 'before': item, 'after': dict(item, **update),
                        'property_mapping': local})
    for item in data['items'] + data['recipe_books']:
        if int(item['RequiredLevel']) > 60:
            changes.setdefault(int(item['entry']), {})['RequiredLevel'] = 60
    return {'changes': changes, 'budgets': budgets, 'properties': mappings, 'pools': new_pools, 'details': details,
            'anchors': [minimum, maximum], 'band': [low, high]}


def rows_sql(table, columns, rows):
    return ('INSERT INTO `' + table + '` (' + ', '.join('`' + name + '`' for name in columns) + ')\nVALUES\n' +
            ',\n'.join('(' + ', '.join(str(value) for value in row) + ')' for row in rows) + ';\n')


def migration(plan):
    text = '''CREATE TABLE IF NOT EXISTS `coa_profession_item_budget` (
    `entry` INT UNSIGNED NOT NULL,
    `profession_id` SMALLINT UNSIGNED NOT NULL,
    `expansion` TINYINT UNSIGNED NOT NULL,
    `original_item_level` SMALLINT UNSIGNED NOT NULL,
    `item_level` SMALLINT UNSIGNED NOT NULL,
    `pve_power` SMALLINT UNSIGNED NOT NULL,
    `pvp_power` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `coa_profession_property_mapping` (
    `entry` INT UNSIGNED NOT NULL,
    `original_property` SMALLINT UNSIGNED NOT NULL,
    `scaled_property` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entry`, `original_property`)
) ENGINE=InnoDB;

START TRANSACTION;

'''
    ids = ', '.join(str(row[0]) for row in plan['budgets'])
    text += f'DELETE FROM `coa_profession_item_budget` WHERE `entry` IN ({ids});\n'
    text += rows_sql('coa_profession_item_budget', ['entry', 'profession_id', 'expansion', 'original_item_level',
                    'item_level', 'pve_power', 'pvp_power'], plan['budgets']) + '\n'
    text += f'DELETE FROM `coa_profession_property_mapping` WHERE `entry` IN ({ids});\n'
    text += rows_sql('coa_profession_property_mapping', ['entry', 'original_property', 'scaled_property'], plan['properties']) + '\n'
    groups = ', '.join(str(group) for group in sorted({row[0] for row in plan['pools']}))
    text += f'DELETE FROM `item_enchantment_template` WHERE `entry` IN ({groups});\n'
    text += rows_sql('item_enchantment_template', ['entry', 'ench', 'chance'], plan['pools']) + '\n'
    for entry, fields in sorted(plan['changes'].items()):
        text += ('UPDATE `item_template`\nSET ' + ', '.join('`' + key + '` = ' + str(value)
                 for key, value in fields.items()) + f'\nWHERE `entry` = {entry};\n\n')
    return text + 'COMMIT;\n'


def header(plan):
    budgets = ',\n'.join('    { ' + ', '.join(str(value) for value in
        (row[0], row[4], row[5], row[6], 6100000 + row[0])) + ' }' for row in plan['budgets'])
    refresh = ',\n'.join('    ' + ', '.join(str(entry) for entry in sorted(plan['changes'])[offset:offset + 12])
                         for offset in range(0, len(plan['changes']), 12))
    mappings = ',\n'.join('    { ' + ', '.join(str(value) for value in row) + ' }' for row in plan['properties'])
    return ('/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */\n'
            '#ifndef COA_PROFESSION_RESCALE_DATA_H\n#define COA_PROFESSION_RESCALE_DATA_H\n\n'
            '#include <array>\n#include <cstdint>\n\nnamespace ProfessionRescale\n{\n'
            'struct Budget\n{\n    std::uint32_t entry, level, pve, pvp, propertyPool;\n};\n'
            'struct Property\n{\n    std::uint32_t entry, original, scaled;\n};\n\n'
            f'inline constexpr std::array<Budget, {len(plan["budgets"])}> Budgets = {{{{\n{budgets}\n}}}};\n\n'
            f'inline constexpr std::array<Property, {len(plan["properties"])}> Properties = {{{{\n{mappings}\n}}}};\n'
            f'inline constexpr std::array<std::uint32_t, {len(plan["changes"])}> RefreshEntries = {{\n{refresh}\n}};\n'
            '}\n\n#endif\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--low', type=int, default=60)
    parser.add_argument('--high', type=int, default=77)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(BASELINE.read_text())
    plan = build(data, args.low, args.high)
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'migration.sql').write_text(migration(plan))
    (args.output / 'CoAProfessionRescaleData.h').write_text(header(plan))
    (args.output / 'preview.json').write_text(json.dumps(plan, indent=2) + '\n')
    with (args.output / 'before-after.csv').open('w') as handle:
        writer = csv.writer(handle)
        writer.writerow(['ID', 'Name', 'Field', 'Original', 'Proposed'])
        for row in plan['details']:
            for field, value in plan['changes'][row['entry']].items():
                if str(row['before'][field]) != str(value):
                    writer.writerow([row['entry'], row['name'], field, row['before'][field], value])
    print(f'Prepared {len(plan["budgets"])} equipment budgets; {len(plan["changes"])} changed templates; '
          f'original anchors {plan["anchors"]}, target {plan["band"]}; effects preserved.')


if __name__ == '__main__':
    main()
