import argparse
from collections import Counter
import json
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1]
ROOT = MODULE.parents[1]
ITEM_BASE = 9700000
AURA_BASE = 9710000
TOOLTIP_BASE = 9720000
MAX_LEVEL = 60
APPEARANCES = {
    8: (1, 7, 16492),
    11: (0, 5, 6921),
    12: (0, 4, 25030),
    16: (1, 7, 17898),
}
PROFILES = {
    'Strength': (4, 38),
    'Agility': (3, 38),
    'Caster': (5, 45),
    'StrengthHybrid': (4, 38),
    'AgilityHybrid': (3, 38),
    'IntellectHybrid': (5, 38),
    'Universal': (7, 32),
}
CONDITIONS = {
    'Always': '',
    'Healthy': ' while at or above 80% health',
    'Wounded': ' while at or below 35% health',
    'AfterKill': ' for 8 sec after killing a non-gray creature',
    'OutOfCombat': ' while out of combat',
    'InCombat': ' while in combat',
}


def load_catalog():
    catalog = json.loads((MODULE / 'data/catalog.json').read_text())
    if [item['id'] for item in catalog] != list(range(64)):
        raise ValueError('The catalog must have exactly 64 consecutive design IDs')
    counts = Counter(item['class_id'] for item in catalog)
    if counts != Counter({0: 1, **{class_id: 3 for class_id in range(12, 33)}}):
        raise ValueError('Expected three designs per custom class and one shared design')
    if len({item['name'] for item in catalog}) != len(catalog):
        raise ValueError('Legendary names must be unique')
    for item in catalog:
        if item['profile'] not in PROFILES or item['condition'] not in CONDITIONS:
            raise ValueError('Unknown stat profile or power condition')
        if item['inventory_type'] not in APPEARANCES:
            raise ValueError('Unknown existing client appearance')
        if item['power'] not in ('Offense', 'Movement', 'Armor', 'Signature'):
            raise ValueError('Unknown legendary power')
        if item['power'] == 'Movement' and item['inventory_type'] != 8:
            raise ValueError('Movement powers belong on boots')
        if item['power'] == 'Signature':
            if not item['signature_spell'] or not 0 <= item['signature_mask_bit'] < 96:
                raise ValueError('A signature power needs its ability and a valid modifier selector')
    return catalog


def power_text(item, required_level=None):
    ilvl = required_level + 12 if required_level else None
    if item['power'] == 'Signature':
        return f"Your {item['signature_name']}'s main hit deals {item['magnitude']}% more damage (all ranks)."
    if item['power'] == 'Movement':
        benefit = f"{item['magnitude']}% movement speed"
    elif item['power'] == 'Armor':
        benefit = f"{item['magnitude']}% armor"
    elif item['profile'] == 'Caster':
        benefit = f"{ilvl if ilvl else 'item level'} spell power"
    elif item['profile'].endswith('Hybrid'):
        ap = ilvl * 2 if ilvl else '2 x item level'
        benefit = f"{ap} attack power and {ilvl if ilvl else 'item level'} spell power"
    else:
        benefit = f"{ilvl * 2 if ilvl else '2 x item level'} melee and ranged attack power"
    return f"Gain {benefit}{CONDITIONS[item['condition']]}."


def sql_value(value):
    if isinstance(value, str):
        return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"
    return str(value)


def wrap_values(values, prefix='(', suffix=')', indent='  '):
    lines = []
    line = prefix
    for index, value in enumerate(values):
        token = value + (', ' if index + 1 < len(values) else suffix)
        if len(line) + len(token) > 120 and line != prefix:
            lines.append(line.rstrip())
            line = indent
        line += token
    lines.append(line.rstrip())
    return '\n'.join(lines)


def insert_rows(table, columns, rows, delete='', upsert=False):
    header = wrap_values([f'`{column}`' for column in columns], f'INSERT INTO `{table}` (', ') VALUES')
    values = [wrap_values([sql_value(value) for value in row],
        suffix=(')' if upsert else ');') if i + 1 == len(rows) else '),')
        for i, row in enumerate(rows)]
    sql = (delete + '\n' if delete else '') + header + '\n' + '\n'.join(values)
    if upsert:
        sql += '\nON DUPLICATE KEY UPDATE\n' + ',\n'.join(
            f'  `{column}` = VALUES(`{column}`)' for column in columns[1:]) + ';'
    return sql


def item_stats(item, ilvl):
    primary, secondary = PROFILES[item['profile']]
    stats = [(primary, max(1, ilvl * 35 // 100)), (7, max(1, ilvl * 45 // 100))]
    if item['profile'] == 'Universal':
        stats = [(7, max(1, ilvl * 60 // 100))]
    stats.append((secondary, max(1, ilvl * (100 if secondary == 38 else 55) // 100)))
    if item['profile'].endswith('Hybrid'):
        stats.append((45, max(1, ilvl * 35 // 100)))
    stats += [(0, 0)] * (4 - len(stats))
    return [value for pair in stats for value in pair]


def aura_effects(item):
    if item['power'] == 'Signature':
        return [(108, 0)]
    if item['power'] == 'Movement':
        return [(31, 0)]
    if item['power'] == 'Armor':
        return [(101, 1)]
    if item['profile'] == 'Caster':
        return [(13, 126), (135, 0)]
    if item['profile'].endswith('Hybrid'):
        return [(99, 0), (13, 126), (135, 0)]
    return [(99, 0), (124, 0)]


def aura_text(item):
    if item['power'] == 'Signature':
        return f"Increases the main hit damage of your {item['signature_name']} by $s1%."
    if item['power'] == 'Movement':
        return f"Increases movement speed by {item['magnitude']}%."
    if item['power'] == 'Armor':
        return f"Increases armor by {item['magnitude']}%."
    if item['profile'] == 'Caster':
        return 'Increases spell power by an amount that grows with the item level.'
    if item['profile'].endswith('Hybrid'):
        return 'Increases attack power and spell power by amounts that grow with the item level.'
    return 'Increases melee and ranged attack power by an amount that grows with the item level.'


def render_sql(catalog):
    templates = []
    dbc_rows = []
    auras = []
    tooltips = []
    for item in catalog:
        slot = item['inventory_type']
        subclass, material, display = APPEARANCES[slot]
        mask = (1 << (item['class_id'] - 1)) if item['class_id'] else 0xFFFFF800
        if mask >= 0x80000000:
            mask -= 0x100000000
        for level in range(1, MAX_LEVEL + 1):
            entry = ITEM_BASE + item['id'] * 100 + level
            tooltip = TOOLTIP_BASE + item['id'] * 100 + level
            ilvl = level + 12
            templates.append([entry, 4, subclass, -1, item['name'], display, 5, slot, mask, -1,
                ilvl, level, 1, 1, *item_stats(item, ilvl),
                ilvl * 2 if slot == 16 else (ilvl * 3 // 2 if slot == 8 else 0),
                1, '', tooltip, 1, 0, -1, 0, -1, material, 0, 12340])
            dbc_rows.append([entry, 4, subclass, -1, material, display, slot, 0])
            tooltips.append([tooltip, 64, 65536, 1, 1, -1, 1, item['name'], power_text(item, level)])
        effects = aura_effects(item)
        timed = item['condition'] == 'AfterKill'
        text = aura_text(item)
        aura = [AURA_BASE + item['id'], 0x100 if timed else 0x1C0, 0x400, 1, 31 if timed else 21,
            1, -1, 1, item['name'], text, text, item['class_id'] + 6 if item['class_id'] else 0,
            516 if item['power'] == 'Movement' else 456]
        for index in range(3):
            if index < len(effects):
                base = item['magnitude'] - 1 if item['power'] == 'Signature' else 0
                aura += [6, 1, base, 1, effects[index][0], effects[index][1]]
            else:
                aura += [0, 0, 0, 0, 0, 0]
        bit = item.get('signature_mask_bit', 0)
        aura += [(1 << (bit % 32)) if item['power'] == 'Signature' and bit // 32 == word else 0
            for word in range(3)]
        auras.append(aura)
    low, high = ITEM_BASE, ITEM_BASE + 6400
    sections = [
        insert_rows('item_template', ['entry', 'class', 'subclass', 'SoundOverrideSubclass', 'name',
            'displayid', 'Quality', 'InventoryType', 'AllowableClass', 'AllowableRace', 'ItemLevel',
            'RequiredLevel', 'maxcount', 'stackable', *[f'stat_{field}{i}' for i in range(1, 5)
                for field in ('type', 'value')], 'armor', 'bonding', 'description', 'spellid_1', 'spelltrigger_1',
            'spellcharges_1', 'spellcooldown_1', 'spellcategory_1', 'spellcategorycooldown_1', 'Material', 'itemset',
            'VerifiedBuild'], templates, upsert=True),
        insert_rows('item_dbc', ['ID', 'ClassID', 'SubclassID', 'Sound_Override_Subclassid', 'Material',
            'DisplayInfoID', 'InventoryType', 'SheatheType'], dbc_rows,
            f'DELETE FROM `item_dbc` WHERE `ID` >= {low} AND `ID` < {high};'),
        insert_rows('spell_dbc', ['ID', 'Attributes', 'AttributesEx', 'CastingTimeIndex', 'DurationIndex',
            'RangeIndex', 'EquippedItemClass', 'SchoolMask', 'Name_Lang_enUS', 'Description_Lang_enUS',
            'AuraDescription_Lang_enUS', 'SpellClassSet', 'SpellIconID',
            *[f'{field}_{i}' for i in range(1, 4) for field in ('Effect', 'EffectDieSides', 'EffectBasePoints',
                'ImplicitTargetA', 'EffectAura', 'EffectMiscValue')],
            *[f'EffectSpellClassMaskA_{i}' for i in range(1, 4)]], auras,
            f'DELETE FROM `spell_dbc` WHERE `ID` >= {AURA_BASE} AND `ID` < {AURA_BASE + 64};'),
        insert_rows('spell_dbc', ['ID', 'Attributes', 'AttributesEx3', 'CastingTimeIndex', 'RangeIndex',
            'EquippedItemClass', 'SchoolMask', 'Name_Lang_enUS', 'Description_Lang_enUS'], tooltips,
            f'DELETE FROM `spell_dbc` WHERE `ID` >= {TOOLTIP_BASE} AND `ID` < {TOOLTIP_BASE + 6400};'),
        f'DELETE FROM `spell_script_names` WHERE `spell_id` >= {AURA_BASE} AND `spell_id` < {AURA_BASE + 64};',
    ]
    return '\n\n'.join(sections) + '\n'


def render_header(catalog):
    lines = ['#ifndef COA_LEGENDARY_CATALOG_H', '#define COA_LEGENDARY_CATALOG_H', '',
        '#include "CoALegendaryRules.h"', '#include <array>', '', 'namespace CoALegendary', '{',
        '    inline constexpr std::array<Design, DesignCount> Catalog =', '    {{']
    for item in catalog:
        lines += [f'        {{ "{item["name"]}", {item["class_id"]}, Power::{item["power"]},',
            f'            Condition::{item["condition"]}, Profile::{item["profile"]}, '
            f'{item["inventory_type"]}, {item["signature_spell"]}, {item["magnitude"]}, '
            f'{item.get("signature_mask_bit", 0)} }},']
    lines += ['    }};', '}', '', '#endif', '']
    return '\n'.join(lines)


def render_catalog(catalog):
    lines = ['# Leveling legendary catalog', '',
        '64 non-set designs. Required level is the effective creature level; item level is required level + 12.',
        f'Each design has variants for creature levels 1–{MAX_LEVEL}; the default player drop cutoff is 60.', '',
        'Stat profiles give the named primary stat, stamina and AP or SP; hybrids receive both AP and SP.',
        'The shared cloak gives stamina and critical strike rating. Powers use the fixed item level.', '',
        '| Design | Class | Name | Slot | Stats | Legendary power |',
        '| --- | --- | --- | --- | --- | --- |']
    slots = {8: 'Boots', 11: 'Ring', 12: 'Trinket', 16: 'Cloak'}
    profiles = {'Strength': 'Strength / AP', 'Agility': 'Agility / AP', 'Caster': 'Intellect / SP',
        'StrengthHybrid': 'Strength / AP / SP', 'AgilityHybrid': 'Agility / AP / SP',
        'IntellectHybrid': 'Intellect / AP / SP', 'Universal': 'Stamina / crit'}
    for item in catalog:
        lines.append(f'| {item["id"]} | {item["class_name"]} | {item["name"]} | '
            f'{slots[item["inventory_type"]]} | {profiles[item["profile"]]} | {power_text(item)} |')
    lines += ['', 'Item entry = `9700000 + design * 100 + required level`.',
        'For example, Bloodoath Signet from a level-29 creature is entry `9700029`, requires level 29 and has item level 41.',
        'Only the strongest equipped copy of a design grants its legendary power.',
        'Movement powers appear only on boots. The boots use cloth armor so every intended class can equip them at level 1.', '']
    return '\n'.join(lines)


def outputs(sql_output=None):
    catalog = load_catalog()
    generated = {
        MODULE / 'src/CoALegendaryCatalog.h': render_header(catalog),
        MODULE / 'CATALOG.md': render_catalog(catalog),
        MODULE / 'preview.html': (MODULE / 'tools/preview.template.html').read_text().replace(
            '__CATALOG__', json.dumps(catalog, ensure_ascii=False, indent=2)),
    }
    if sql_output:
        sql_output = sql_output.resolve()
        if not sql_output.is_relative_to(MODULE / 'data/sql/db-world'):
            raise ValueError('SQL output must be a new module world migration')
        generated[sql_output] = render_sql(catalog)
    return generated


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--sql-output', type=Path)
    args = parser.parse_args()
    if args.sql_output and not args.check and args.sql_output.exists():
        parser.error('--sql-output must name a new migration; existing migrations are not overwritten')
    stale = []
    for path, content in outputs(args.sql_output).items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    if stale:
        raise SystemExit('Generated files differ: ' + ', '.join(stale))


if __name__ == '__main__':
    main()
