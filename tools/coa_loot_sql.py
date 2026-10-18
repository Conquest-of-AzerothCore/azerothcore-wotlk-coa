"""Generate conservative Exiles loot patches from explicit, local source inputs.

No database connection, network calls or archive writes. Baseline is a directory of
JSON row exports named after the world tables. Source JSON is never an output.
"""
import argparse
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation
import gzip
import hashlib
import json
from pathlib import Path
import re


def canonical(name):
    return re.sub(r'\s+#\d+$', '', name.strip()).casefold()


def chance(value):
    if not isinstance(value, str) or not re.fullmatch(r'\d+(?:\.\d+)?%', value):
        return None
    try:
        number = Decimal(value[:-1])
    except InvalidOperation:
        return None
    return number if 0 < number <= 100 else None


def literal(value):
    if isinstance(value, str):
        return "CONVERT(0x" + value.encode('utf8').hex() + " USING utf8mb4)"
    return str(value)


def plan(records, baseline):
    creatures = {r['entry']: r for r in baseline['creature_template']}
    items = {r['entry']: r for r in baseline['item_template']}
    loot = defaultdict(list)
    owners = defaultdict(set)
    for row in baseline['creature_loot_template']:
        loot[row['Entry']].append(row)
    for row in creatures.values():
        if row['lootid']:
            owners[row['lootid']].add(row['entry'])
    protected = {r['entry'] for r in items.values() if r['class'] == 12 or r['startquest'] or r['Bonding'] == 4}
    for quest in baseline['quest_template']:
        protected.update(quest.get('RequiredItemId' + str(i), 0) for i in range(1, 7))
        protected.update(quest.get('ItemDrop' + str(i), 0) for i in range(1, 5))
    conditional = {r['SourceGroup'] for r in baseline['conditions'] if r['SourceTypeOrReferenceId'] == 1}
    skips = Counter()
    examples = defaultdict(list)
    patches = []

    def skip(reason, npc, item=None):
        skips[reason] += 1
        if len(examples[reason]) < 5:
            examples[reason].append({'npc': npc['key'], 'name': npc['name'], 'item': item})

    for npc in records:
        if not npc.get('drops'):
            continue
        entry = int(npc['key'])
        creature = creatures.get(entry)
        if creature is None:
            skip('missing_creature', npc)
            continue
        if canonical(creature['name']) != canonical(npc['name']):
            skip('creature_name_conflict', npc)
            continue
        target = creature['lootid'] or entry
        if target != entry or owners[target] - {entry}:
            skip('shared_or_redirected_loot', npc)
            continue
        if target in conditional or (creature['lootid'] == 0 and loot[target]):
            skip('conditional_or_unassigned_existing_loot', npc)
            continue
        rows = loot[target]
        has_reference = any(r['Reference'] for r in rows)
        by_item = defaultdict(list)
        for row in rows:
            if row['Reference'] == 0:
                by_item[row['Item']].append(row)
        source_items = defaultdict(list)
        for drop in npc['drops']:
            entity = drop.get('entity', {})
            if entity.get('type') != 'item' or not str(entity.get('key', '')).isdigit():
                skip('malformed_item', npc)
                continue
            source_items[int(entity['key'])].append(drop)
        for item_id, drops in sorted(source_items.items()):
            if len(drops) != 1:
                skip('duplicate_source_item', npc, item_id)
                continue
            drop = drops[0]
            probability = chance(drop.get('chance'))
            if probability is None:
                skip('unknown_or_zero_chance', npc, item_id)
                continue
            item = items.get(item_id)
            if item is None or item_id in protected:
                skip('missing_or_quest_sensitive_item', npc, item_id)
                continue
            label = drop['entity'].get('label', '')
            if re.fullmatch(r'Item\s+#\d+', label) or canonical(item['name']) != canonical(label):
                skip('item_name_conflict_or_stub', npc, item_id)
                continue
            existing = by_item[item_id]
            if existing:
                skip('existing_item_preserved', npc, item_id)
                continue
            if has_reference:
                skip('reference_template_requires_review', npc, item_id)
                continue
            patches.append({'entry': entry, 'name': creature['name'], 'lootid': creature['lootid'],
                            'item': item_id, 'item_name': item['name'], 'chance': str(probability),
                            'source_url': npc.get('url', ''), 'source_page_sha256': npc.get('source_sha256', '')})
    return patches, {'exclusions': dict(skips), 'named_exclusions': dict(examples)}


def sql(patches):
    if not patches:
        raise ValueError('No eligible loot changes')
    lines = [
        '-- Exiles visible lists are capped at 20 rows; absence never means a drop should be removed.',
        '-- Stated probabilities; observed counts are zero. No empirical drop-rate claim.',
        '-- New rows: Reference=0, QuestRequired=0, LootMode=1, GroupId=0, MinCount=MaxCount=1.',
        '-- Existing stacks and unrelated rows are preserved. Shared/reference/conditional loot is excluded.',
        'CREATE TEMPORARY TABLE `_coa_loot_patch` (',
        '  `Entry` INT UNSIGNED NOT NULL, `Name` VARBINARY(400) NOT NULL, `OldLootId` INT UNSIGNED NOT NULL,',
        '  `Item` INT UNSIGNED NOT NULL, `Chance` FLOAT NOT NULL,',
        '  PRIMARY KEY (`Entry`, `Item`)',
        ') ENGINE=InnoDB;',
        'DELETE FROM `_coa_loot_patch`;',
        'INSERT INTO `_coa_loot_patch` VALUES'
    ]
    for index, row in enumerate(patches):
        values = [row[k] for k in ('entry', 'name', 'lootid', 'item')]
        values.append(Decimal(row['chance']))
        lines.append('(' + ', '.join(literal(v) for v in values) + (');' if index == len(patches) - 1 else '),'))
    lines.extend([
        'CREATE TEMPORARY TABLE `_coa_loot_scope` (`Entry` INT UNSIGNED PRIMARY KEY) ENGINE=InnoDB;',
        'DELETE FROM `_coa_loot_scope`;',
        'INSERT INTO `_coa_loot_scope`',
        'SELECT DISTINCT `c`.`entry` FROM `creature_template` AS `c`',
        'JOIN `_coa_loot_patch` AS `p` ON `p`.`Entry` = `c`.`entry`',
        'WHERE `c`.`name` = `p`.`Name` AND `c`.`lootid` IN (0, `c`.`entry`)',
        'AND (`c`.`lootid` = `p`.`OldLootId` OR `c`.`lootid` = `c`.`entry`)',
        'AND NOT EXISTS (SELECT 1 FROM `creature_template` AS `o`',
        '  WHERE `o`.`lootid` = `c`.`entry` AND `o`.`entry` <> `c`.`entry`)',
        'AND NOT EXISTS (SELECT 1 FROM `conditions` AS `k`',
        '  WHERE `k`.`SourceTypeOrReferenceId` = 1 AND `k`.`SourceGroup` = `c`.`entry`)',
        'AND NOT EXISTS (SELECT 1 FROM `creature_loot_template` AS `r`',
        '  WHERE `r`.`Entry` = `c`.`entry` AND (`r`.`Reference` <> 0 OR `c`.`lootid` = 0));',
        'CREATE TEMPORARY TABLE `_coa_quest_items` (`Item` INT UNSIGNED PRIMARY KEY) ENGINE=InnoDB;',
        'DELETE FROM `_coa_quest_items`;',
        'INSERT INTO `_coa_quest_items`',
        'SELECT `entry` FROM `item_template` WHERE `class` = 12 OR `startquest` <> 0 OR `Bonding` = 4'
    ])
    for col in [f'RequiredItemId{i}' for i in range(1, 7)] + [f'ItemDrop{i}' for i in range(1, 5)]:
        lines.append(f'UNION SELECT `{col}` FROM `quest_template` WHERE `{col}` <> 0')
    lines[-1] += ';'
    lines.extend([
        'START TRANSACTION;',
        'DELETE `p` FROM `_coa_loot_patch` AS `p`',
        'LEFT JOIN `_coa_loot_scope` AS `s` ON `s`.`Entry` = `p`.`Entry`',
        'LEFT JOIN `item_template` AS `i` ON `i`.`entry` = `p`.`Item`',
        'LEFT JOIN `_coa_quest_items` AS `q` ON `q`.`Item` = `p`.`Item`',
        'WHERE `s`.`Entry` IS NULL OR `i`.`entry` IS NULL OR `q`.`Item` IS NOT NULL;',
        'UPDATE `creature_template` AS `c` JOIN `_coa_loot_patch` AS `p` ON `p`.`Entry` = `c`.`entry`',
        'SET `c`.`lootid` = `c`.`entry` WHERE `c`.`lootid` = 0;',
        '-- Only unchanged rows previously added by this migration can be replaced.',
        'CREATE TEMPORARY TABLE `_coa_owned` (',
        '  `Entry` INT UNSIGNED NOT NULL, `Item` INT UNSIGNED NOT NULL,',
        '  `Reference` INT NOT NULL, `GroupId` TINYINT UNSIGNED NOT NULL,',
        '  PRIMARY KEY (`Entry`, `Item`, `Reference`, `GroupId`)',
        ') ENGINE=InnoDB;',
        'DELETE FROM `_coa_owned`;',
        'INSERT INTO `_coa_owned`',
        'SELECT `l`.`Entry`, `l`.`Item`, `l`.`Reference`, `l`.`GroupId` FROM `creature_loot_template` AS `l`',
        'JOIN `_coa_loot_patch` AS `p` ON `p`.`Entry` = `l`.`Entry` AND `p`.`Item` = `l`.`Item`',
        'WHERE `l`.`Reference` = 0 AND `l`.`GroupId` = 0 AND `l`.`QuestRequired` = 0 AND `l`.`LootMode` = 1',
        'AND `l`.`MinCount` = 1 AND `l`.`MaxCount` = 1 AND `l`.`Chance` = `p`.`Chance`',
        "AND BINARY `l`.`Comment` = BINARY 'Exiles stated chance; default stack 1';",
        '-- _coa_owned contains exactly the four primary-key columns; NATURAL JOIN matches all four.',
        'DELETE `l` FROM `creature_loot_template` AS `l` NATURAL JOIN `_coa_owned`;',
        'INSERT INTO `creature_loot_template`',
        '(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, '
        '`GroupId`, `MinCount`, `MaxCount`, `Comment`)',
        'SELECT `p`.`Entry`, `p`.`Item`, 0, `p`.`Chance`, 0, 1, 0, 1, 1, \'Exiles stated chance; default stack 1\'',
        'FROM `_coa_loot_patch` AS `p`',
        'WHERE NOT EXISTS (SELECT 1 FROM `creature_loot_template` AS `l`',
        '  WHERE `l`.`Entry` = `p`.`Entry` AND `l`.`Item` = `p`.`Item`);',
        'COMMIT;',
        'DROP TEMPORARY TABLE `_coa_owned`, `_coa_quest_items`, `_coa_loot_scope`, `_coa_loot_patch`;'
    ])
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--npcs', type=Path, required=True)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--creatures', help='Comma-separated explicit creature ids; omitted means all eligible')
    args = parser.parse_args()
    tables = ('creature_template', 'item_template', 'creature_loot_template', 'quest_template', 'conditions')
    baseline = {t: json.loads((args.baseline / (t + '.json')).read_text(encoding='utf8')) for t in tables}
    with gzip.open(args.npcs, 'rt', encoding='utf8') as source:
        records = [json.loads(line) for line in source]
    if args.creatures:
        selected = {int(value) for value in args.creatures.split(',')}
        found = {int(r['key']) for r in records}
        if selected - found:
            raise ValueError('Selected creatures missing from source: ' + str(sorted(selected - found)))
        records = [r for r in records if int(r['key']) in selected]
    patches, report = plan(records, baseline)
    patches.sort(key=lambda r: (r['entry'], r['item']))
    args.output.write_text(sql(patches), encoding='utf8', newline='\n')
    report.update({'changes': len(patches), 'creatures': len({r['entry'] for r in patches}),
                   'additions': len(patches), 'named_changes': patches,
                   'source_sha256': hashlib.sha256(args.npcs.read_bytes()).hexdigest()})
    args.report.write_text(json.dumps(report, indent=2), encoding='utf8')
    print(json.dumps({k: v for k, v in report.items() if k not in ('named_changes', 'named_exclusions')}))


if __name__ == '__main__':
    main()
