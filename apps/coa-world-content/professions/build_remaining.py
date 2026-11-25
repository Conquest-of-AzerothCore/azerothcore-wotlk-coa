import argparse
from fractions import Fraction
import json
from pathlib import Path
import textwrap

from build import mapped, rows_sql


BASELINE = Path(__file__).with_name('tbc_remaining_baseline.json')


def validate(data):
    rows = data['equipment']
    assert len(rows) == len({row['entry'] for row in rows})
    assert not {row['entry'] for row in rows} & {row['entry'] for row in data['item_gates']}
    pools = {profile['pool']: profile for profile in data['affixes']}
    assert len(pools) == len(data['affixes'])
    for row in rows:
        levels = [peer['level'] for peer in rows if peer['skill'] == row['skill']]
        assert row['skill'] in (164, 165, 171, 197, 202)
        assert row['target'] == mapped(row['level'], min(levels), max(levels), 60, 77) <= row['level']
        assert row['changes']['ItemLevel'] == row['target']
        assert row['pool'] in pools or not row['pool']
        assert row['recipes']
    for profile in pools.values():
        chances = {entry: Fraction(chance) for entry, chance in profile['chances']}
        assert chances and all(chance > 0 for chance in chances.values())
        assert all(source not in chances and target in chances for source, target in profile['mapping'])


def groups_sql(table, columns, values):
    if not values:
        return ''
    keys = sorted({value[0] for value in values})
    lines = textwrap.fill(', '.join(map(str, keys)), width=110, initial_indent='    ', subsequent_indent='    ')
    return (f'DELETE FROM `{table}` WHERE `{columns[0]}` IN (\n{lines}\n);\n' +
            rows_sql(table, columns, values) + '\n')


def update(table, changes, keys):
    assignments = ', '.join(f'`{key}` = {value}' for key, value in changes.items())
    where = ' AND '.join(f'`{key}` = {value}' for key, value in keys.items())
    return (f'UPDATE `{table}`\n' +
            textwrap.fill(assignments, width=116, initial_indent='SET ', subsequent_indent='    ') +
            f'\nWHERE {where};\n\n')


def migration(data):
    text = 'START TRANSACTION;\n\n'
    equipment = data['equipment']
    text += groups_sql('coa_profession_item_budget',
                       ['entry', 'profession_id', 'expansion', 'original_item_level', 'item_level',
                        'pve_power', 'pvp_power'],
                       [(row['entry'], row['skill'], 1, row['level'], row['target'], row['pve'], row['pvp'])
                        for row in equipment])
    text += groups_sql('item_enchantment_template', ['entry', 'ench', 'chance'],
                       [(profile['pool'], entry, float(Fraction(chance))) for profile in data['affixes']
                        for entry, chance in profile['chances']])
    for row in equipment:
        text += update('item_template', row['changes'], {'entry': row['entry']})
    for row in data['item_gates']:
        text += update('item_template', {'RequiredLevel': 60}, {'entry': row['entry'], 'RequiredLevel': row['required']})
    for table, rows in data['trainer_gates'].items():
        key_names = ('ID', 'SpellID') if table == 'npc_trainer' else ('TrainerId', 'SpellId')
        for row in rows:
            text += update(table, {'ReqLevel': 60}, {key: int(row[key]) for key in (*key_names, 'ReqLevel')})
    for row in data['quest_gates']:
        text += update('quest_template', {'MinLevel': 60}, {'ID': int(row['ID']), 'MinLevel': int(row['MinLevel'])})
    return text + 'COMMIT;\n'


def header(data):
    budgets = [(row['entry'], row['target'], row['pve'], row['pvp'], row['pool']) for row in data['equipment']]
    properties = [(profile['pool'], source, target) for profile in data['affixes']
                  for source, target in profile['mapping']]
    refresh = sorted(row['entry'] for row in data['equipment'] + data['item_gates'])

    def array(kind, name, rows):
        values = ',\n'.join('    { ' + ', '.join(map(str, row)) + ' }' for row in rows)
        return f'inline constexpr std::array<{kind}, {len(rows)}> {name} = {{{{\n{values}\n}}}};\n\n'

    refresh_lines = ',\n'.join('    ' + ', '.join(map(str, refresh[start:start+12]))
                               for start in range(0, len(refresh), 12))
    return ('/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */\n'
            '#ifndef COA_PROFESSION_RESCALE_REMAINING_DATA_H\n#define COA_PROFESSION_RESCALE_REMAINING_DATA_H\n\n'
            '#include "CoAProfessionRescaleData.h"\n\n'
            'namespace ProfessionRescale::RemainingTbc\n{\n' +
            array('Budget', 'Budgets', budgets) + array('Property', 'Properties', properties) +
            f'inline constexpr std::array<std::uint32_t, {len(refresh)}> RefreshEntries = {{\n{refresh_lines}\n}};\n'
            '}\n\n#endif\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(BASELINE.read_text())
    validate(data)
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'migration.sql').write_text(migration(data))
    (args.output / 'CoAProfessionRescaleRemainingData.h').write_text(header(data))


if __name__ == '__main__':
    main()
