"""Build explicit, unspawned creature reconstructions from local, source-attributed exports.

Inputs remain local. No database connections or network calls are made by this generator.
"""
import argparse
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation
import gzip
import hashlib
import json
import math
from pathlib import Path
import re
import struct

MARKER = -12341
CHILD_KEYS = {
    'creature_template_model': 'CreatureID', 'creature_template_spell': 'CreatureID',
    'creature_template_addon': 'entry', 'creature_template_resistance': 'CreatureID',
    'creature_template_movement': 'CreatureId', 'creature_equip_template': 'CreatureID',
    'creature_text': 'CreatureID', 'creature_text_locale': 'CreatureID',
}

def canonical(name):
    return re.sub(r'\s+#\d+$', '', name.strip()).casefold()

def indexed(rows, key):
    result = defaultdict(list)
    for row in rows:
        result[row[key]].append(row)
    return result

def dbc_ids(path):
    data = path.read_bytes()
    magic, count, fields, size, strings = struct.unpack_from('<4s4I', data)
    if magic != b'WDBC' or size < 4 or len(data) != 20 + count * size + strings:
        raise ValueError('Invalid DBC structure: ' + path.name)
    return {struct.unpack_from('<I', data, 20 + i * size)[0] for i in range(count)}

def literal(value):
    if value is None:
        return 'NULL'
    if isinstance(value, str):
        if not value:
            return "''"
        encoded = value.encode('utf8').hex()
        parts = ["0x" + encoded[i:i+64] for i in range(0, len(encoded), 64)]
        binary = parts[0] if len(parts) == 1 else "CONCAT(" + ", ".join(parts) + ")"
        return "CONVERT(" + binary + " USING utf8mb4)"
    if isinstance(value, bool) or not isinstance(value, (int, float, Decimal)) or not math.isfinite(value):
        raise ValueError('Non-finite or unsupported SQL value')
    return str(value)

def source_chance(value):
    if not isinstance(value, str) or not re.fullmatch(r'\d+(?:\.\d+)?%', value):
        return None
    try:
        result = Decimal(value[:-1])
    except InvalidOperation:
        return None
    return result if 0 < result <= 100 else None

def load_inputs(directory):
    def load(prefix):
        return {p.name[len(prefix)+1:-5]: json.loads(p.read_text(encoding='utf8'))
                for p in sorted(directory.glob(prefix + '.*.json'))}
    return load('coa_world'), load('asc_world')

def prepare(records, target, archive, dbc, items, quests):
    from coa_creature_ai import prepare_ai_tables, transform_ai
    ai_tables = prepare_ai_tables(target)
    existing = {r['entry']: r for r in target['creature_template']}
    shells = {r['entry']: r for r in archive['creature_template']}
    by_name = indexed(target['creature_template'], 'name')
    names = defaultdict(list)
    for name, rows in by_name.items():
        names[canonical(name)].extend(rows)
    child = {t: indexed(target.get(t, []), key) for t, key in CHILD_KEYS.items()}
    models = indexed(archive['creature_template_model'], 'CreatureID')
    items = {r['entry']: r for r in items}
    protected = {i for i, r in items.items() if r['class'] == 12 or r['Bonding'] == 4 or r['startquest']}
    for q in quests:
        protected.update(q.get('RequiredItemId' + str(i), 0) for i in range(1, 7))
        protected.update(q.get('ItemDrop' + str(i), 0) for i in range(1, 5))
    report = {'candidates': [], 'excluded': [], 'loot_exclusions': Counter(), 'policy': {
        'marker': MARKER, 'no_spawns': True, 'mirror_levels_preferred': True,
        'missing_mirror_level': 'explicit donor level fallback; reported per creature',
        'difficulty_links': 'cleared: no automatic redirection into donor encounters',
        'unrecovered_loot_fields': 'Reference=0 QuestRequired=0 LootMode=1 GroupId=0 MinCount=MaxCount=1',
    }}
    cohorts = []
    for npc in sorted(records, key=lambda r: int(r['id'])):
        entry = int(npc['id'])
        shell = shells.get(entry)
        identity = shell['name'] if shell else npc['name']
        if not npc.get('drops') or entry in existing or len(names[canonical(identity)]) != 1:
            continue
        donor = names[canonical(identity)][0]
        info = {'entry': entry, 'name': npc['name'], 'donor': donor['entry'], 'notes': []}
        report['candidates'].append(info)
        shell = shells.get(entry)
        reasons = []
        if shell and canonical(shell['name']) != canonical(npc['name']):
            info['notes'].append('captured name differs from mirror: ' + shell['name'])
        if not shell:
            shell = donor
            info['notes'].append('no captured template; donor model, health and mana retained')
        selected_models = models.get(entry, []) or child['creature_template_model'][donor['entry']]
        if not models.get(entry):
            info['notes'].append('no captured model; donor model retained')
        valid_models = [dict(r) for r in selected_models if r['CreatureDisplayID'] in dbc['CreatureDisplayInfo']]
        if len(valid_models) != len(selected_models):
            info['notes'].append('unsupported captured displays omitted for target DBC')
        if not valid_models:
            valid_models = [dict(r) for r in child['creature_template_model'][donor['entry']]
                            if r['CreatureDisplayID'] in dbc['CreatureDisplayInfo']]
            info['notes'].append('captured displays unavailable; target-valid donor appearance retained')
        selected_models = valid_models
        if not selected_models:
            reasons.append('no target-valid captured or donor display model')
        total_weight = sum(r['Probability'] for r in selected_models)
        if selected_models and (total_weight <= 0 or any(r['Probability'] < 0 for r in selected_models)):
            reasons.append('invalid display probability weights')
        elif selected_models:
            for idx, model in enumerate(selected_models):
                model['Idx'] = idx
                model['Probability'] /= total_weight
        if donor['faction'] not in dbc['FactionTemplate'] or donor['unit_class'] not in (1, 2, 4, 8):
            reasons.append('invalid donor faction or class')
        if reasons:
            report['excluded'].append(dict(info, reasons=reasons))
            continue
        row = dict(donor)
        row.update(entry=entry, name=shell['name'], VerifiedBuild=MARKER, lootid=entry,
                   difficulty_entry_1=0, difficulty_entry_2=0, difficulty_entry_3=0,
                   KillCredit1=0, KillCredit2=0, pickpocketloot=0, skinloot=0, movementId=0,
                   MovementType=0, ScriptName='', npcflag=0, gossip_menu_id=0, RacialLeader=0)
        if donor.get('npcflag') or donor.get('gossip_menu_id'):
            info['notes'].append('service flags and gossip cleared; vendor/quest/trainer services not reconstructed')
        if donor.get('VehicleId'):
            info['notes'].append('donor vehicle reference retained; vehicle accessories not reconstructed')
        for field in ('HealthModifier', 'ManaModifier'):
            if not math.isfinite(shell[field]) or shell[field] <= 0:
                reasons.append('invalid archived ' + field)
            row[field] = shell[field]
        # Valid captured classifications supersede the donor; empty cache fields do not.
        for field, store in [('type','CreatureType'),('family','CreatureFamily')]:
            if shell[field] in dbc[store]:
                row[field] = shell[field]
        level = re.search(r'\bLevel\s+(\d+)(?:\s*(?:-|\u2013)\s*(\d+))?', npc.get('levels', ''))
        if level:
            row['minlevel'] = int(level[1])
            row['maxlevel'] = int(level[2] or level[1])
        else:
            info['notes'].append('mirror level absent; donor level range retained')
        if not 1 <= row['minlevel'] <= row['maxlevel'] <= 83:
            reasons.append('level outside supported 1..83 range')
        levels = npc.get('levels', '')
        if 'Boss' in levels:
            row['rank'] = 3
        elif 'Rare Elite' in levels:
            row['rank'] = 2
        elif 'Elite' in levels:
            row['rank'] = 1
        elif 'Rare' in levels:
            row['rank'] = 4
        elif level:
            row['rank'] = 0
        if reasons:
            report['excluded'].append(dict(info, reasons=reasons))
            continue
        rows = {'creature_template': [row]}
        for table, key in CHILD_KEYS.items():
            source = selected_models if table == 'creature_template_model' else child[table][donor['entry']]
            rows[table] = [dict(r, **{key:entry}) for r in source]
        # Spawn routes cannot be inherited without placement evidence.
        for addon in rows['creature_template_addon']:
            addon['path_id'] = 0
        if donor['ScriptName']:
            row['AIName'] = ''
            info['notes'].append('C++ ScriptName omitted; plain melee, not recovered encounter mechanics')
        # SmartAI closure is supplied by the separately reviewed transformer.
        if row['AIName'] == 'SmartAI':
            ai = transform_ai(donor['entry'], entry, ai_tables, 1900000000 + len(cohorts) * 100)
            if ai['blocked']:
                report['excluded'].append(dict(info, reasons=ai['blocked']))
                continue
            for table, values in ai['tables'].items():
                rows[table] = values
            text_keys = {(r['CreatureID'], r['GroupID'], r['ID']) for r in rows['creature_text']}
            rows['creature_text_locale'] = [r for r in rows['creature_text_locale']
                                            if (r['CreatureID'], r['GroupID'], r['ID']) in text_keys]
            info['notes'].extend(ai['warnings'])
        else:
            rows.pop('creature_text', None)
            rows.pop('creature_text_locale', None)
        loot = []
        drops_by_item = defaultdict(list)
        for drop in npc['drops']:
            ref = drop.get('entity', {})
            if ref.get('type') == 'item' and str(ref.get('key', '')).isdigit():
                drops_by_item[int(ref['key'])].append(drop)
        for item_id, drops in sorted(drops_by_item.items()):
            reason = None
            drop = drops[0]
            chance = source_chance(drop.get('chance'))
            item = items.get(item_id)
            if len(drops) != 1:
                reason = 'duplicate source item'
            elif chance is None:
                reason = 'unknown or zero stated chance'
            elif not item or item_id in protected:
                reason = 'missing or quest-sensitive item'
            elif (re.fullmatch(r'Item\s+#\d+', drop['entity'].get('label', '')) or
                  canonical(item['name']) != canonical(drop['entity'].get('label', ''))):
                reason = 'item name mismatch or stub'
            if reason:
                report['loot_exclusions'][reason] += 1
                continue
            loot.append({'Entry':entry,'Item':item_id,'Reference':0,'Chance':float(chance),'QuestRequired':0,
                         'LootMode':1,'GroupId':0,'MinCount':1,'MaxCount':1,
                         'Comment':'CoA twin reconstruction; Exiles stated chance; default stack 1'})
        rows['creature_loot_template'] = loot
        if not loot:
            row['lootid'] = 0
            info['notes'].append('no safely recoverable loot rows; lootid remains zero')
        info.update(level=[row['minlevel'],row['maxlevel']], rank=row['rank'], faction=row['faction'],
                    ai=row['AIName'], loot_rows=len(loot), model_ids=[r['CreatureDisplayID'] for r in selected_models])
        cohorts.append({'info':info,'tables':rows})
    report['included'] = [c['info'] for c in cohorts]
    report['loot_exclusions'] = dict(report['loot_exclusions'])
    return cohorts, report
OWNER_KEYS = dict(CHILD_KEYS, creature_template='entry', creature_loot_template='Entry')
ORPHAN_GUARDS = (
    ('creature_template_locale', 'entry', None),
    ('creature_onkill_reputation', 'creature_id', None),
    ('creature_questitem', 'CreatureEntry', None),
    ('creature_summon_groups', 'summonerId', '`t`.`summonerType` = 0'),
    ('creature_queststarter', 'id', None),
    ('creature_questender', 'id', None),
    ('game_event_creature_quest', 'id', None),
    ('npc_vendor', 'entry', None),
    ('npc_spellclick_spells', 'npc_entry', None),
    ('creature_default_trainer', 'CreatureId', None),
    ('vehicle_template_accessory', 'entry', None),
    ('creature', 'id', None),
    ('creature_multispawn', 'entry', None),
    ('script_waypoint', 'entry', None),
)

def emit_sql(cohorts, report):
    tables = defaultdict(list)
    for cohort in cohorts:
        for table, rows in cohort['tables'].items():
            tables[table].extend((cohort['info']['entry'], row) for row in rows)
    tables = {k:v for k,v in tables.items() if v}
    out = ['-- Tier A creature reconstruction; no spawns; inferred behavior is documented per entry.',
           '-- New entries only: existing creatures and orphan dependencies block their complete cohort.',
           '-- Reapplication skips existing entries, including operator edits. No existing template is replaced.',
           'START TRANSACTION;']
    def put(line):
        out.append(line)
    for number, (table, values) in enumerate(tables.items()):
        stage = '_coa_tw_' + str(number)
        report.setdefault('sql_stages', {})[table] = stage
        columns = list(values[0][1])
        put(f'CREATE TEMPORARY TABLE `{stage}` LIKE `{table}`;')
        put(f'ALTER TABLE `{stage}` ADD COLUMN `_owner` INT UNSIGNED NOT NULL;')
        for offset in range(0, len(values), 200):
            batch = values[offset:offset+200]
            put(f'DELETE FROM `{stage}` WHERE 1 = 0;')
            put(f'INSERT INTO `{stage}` (' + ', '.join('`'+c+'`' for c in columns) + ', `_owner`) VALUES')
            for i, (owner, row) in enumerate(batch):
                put('ROW(' + ', '.join(literal(row[c]) for c in columns) + ', ' + str(owner) +
                    (');' if i == len(batch)-1 else '),'))
    stages = report['sql_stages']
    root = stages['creature_template']
    put('CREATE TEMPORARY TABLE `_coa_tw_new` (`entry` INT UNSIGNED NOT NULL PRIMARY KEY) ENGINE=InnoDB;')
    put('DELETE FROM `_coa_tw_new` WHERE 1 = 0;')
    put(f'INSERT INTO `_coa_tw_new` SELECT `_owner` FROM `{root}`;')
    # Check staged children and unstaged template-owned namespaces before activating a new entry.
    for table, key in OWNER_KEYS.items():
        put(f'DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `{table}` AS `t` ON `t`.`{key}` = `g`.`entry`;')
    for table, key, predicate in ORPHAN_GUARDS:
        suffix = ' AND ' + predicate if predicate else ''
        put(f'DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `{table}` AS `t` '
            f'ON `t`.`{key}` = `g`.`entry`{suffix};')
    put('DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `creature_template` AS `t` '
        'ON `t`.`lootid` = `g`.`entry`;')
    put('DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `conditions` AS `t` '
        'ON (`t`.`SourceTypeOrReferenceId` = 1 AND `t`.`SourceGroup` = `g`.`entry`) '
        'OR (`t`.`SourceTypeOrReferenceId` = 22 AND `t`.`SourceEntry` = `g`.`entry` AND `t`.`SourceId` = 0);')
    put('DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `smart_scripts` AS `t` '
        'ON `t`.`entryorguid` = `g`.`entry` AND `t`.`source_type` = 0;')
    if 'smart_scripts' in stages:
        stage = stages['smart_scripts']
        put(f'DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `{stage}` AS `s` ON `s`.`_owner` = `g`.`entry` '
            'INNER JOIN `smart_scripts` AS `t` ON `t`.`entryorguid` = `s`.`entryorguid` '
            'AND `t`.`source_type` = `s`.`source_type`;')
        put(f'DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `{stage}` AS `s` ON `s`.`_owner` = `g`.`entry` '
            'INNER JOIN `conditions` AS `t` ON `t`.`SourceTypeOrReferenceId` = 22 '
            'AND `t`.`SourceEntry` = `s`.`entryorguid` AND `t`.`SourceId` = `s`.`source_type`;')
    # Every planned loot item must still exist and remain outside quest-sensitive fields.
    if 'creature_loot_template' in stages:
        stage = stages['creature_loot_template']
        put(f'DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `{stage}` AS `s` ON `s`.`_owner` = `g`.`entry` '
            'LEFT JOIN `item_template` AS `i` ON `i`.`entry` = `s`.`Item` '
            'WHERE `i`.`entry` IS NULL OR `i`.`class` = 12 OR `i`.`Bonding` = 4 OR `i`.`startquest` <> 0;')
        fields = ['RequiredItemId'+str(i) for i in range(1,7)] + ['ItemDrop'+str(i) for i in range(1,5)]
        # Materialize the union once. Joining every drop against ten quest columns is quadratic.
        put('CREATE TEMPORARY TABLE `_coa_tw_quest_items` '
            '(`Item` INT UNSIGNED NOT NULL PRIMARY KEY) ENGINE=InnoDB;')
        put('DELETE FROM `_coa_tw_quest_items` WHERE 1 = 0;')
        put('INSERT INTO `_coa_tw_quest_items` (`Item`)')
        put(' UNION '.join(f'SELECT `{field}` FROM `quest_template` WHERE `{field}` > 0' for field in fields) + ';')
        put(f'DELETE `g` FROM `_coa_tw_new` AS `g` INNER JOIN `{stage}` AS `s` ON `s`.`_owner` = `g`.`entry` '
            'INNER JOIN `_coa_tw_quest_items` AS `q` ON `s`.`Item` = `q`.`Item`;')
        put('DROP TEMPORARY TABLE `_coa_tw_quest_items`;')
    for table, values in tables.items():
        stage = stages[table]
        columns = list(values[0][1])
        if table == 'smart_scripts':
            keys = ['entryorguid', 'source_type']
        elif table == 'conditions':
            keys = ['SourceTypeOrReferenceId', 'SourceEntry', 'SourceId', 'SourceGroup']
        else:
            keys = [OWNER_KEYS[table]]
        # The owned table contains only the exact keys of a proven-new cohort.
        put('CREATE TEMPORARY TABLE `_coa_tw_owned` ENGINE=InnoDB AS SELECT DISTINCT ' +
            ', '.join('`s`.`'+key+'`' for key in keys) + f' FROM `{stage}` AS `s` '
            'INNER JOIN `_coa_tw_new` AS `g` ON `g`.`entry` = `s`.`_owner`;')
        put(f'DELETE `{table}` FROM `{table}` NATURAL JOIN `_coa_tw_owned`;')
        put(f'INSERT INTO `{table}` (' + ', '.join('`'+c+'`' for c in columns) + ')')
        put('SELECT ' + ', '.join('`s`.`'+c+'`' for c in columns) + f' FROM `{stage}` AS `s` '
            'INNER JOIN `_coa_tw_new` AS `g` ON `g`.`entry` = `s`.`_owner`;')
        put('DROP TEMPORARY TABLE `_coa_tw_owned`;')
    put('DROP TEMPORARY TABLE `_coa_tw_new`;')
    for stage in reversed(list(stages.values())):
        put(f'DROP TEMPORARY TABLE `{stage}`;')
    put('COMMIT;')
    # SQL contains only ASCII string literals encoded as hex; splitting whitespace preserves values.
    import textwrap
    wrapped = []
    for line in out:
        if line.startswith('--'):
            wrapped.extend(textwrap.wrap(line, width=120, subsequent_indent='-- ', break_long_words=False,
                                         break_on_hyphens=False))
        else:
            wrapped.extend(textwrap.wrap(line, width=120, subsequent_indent='    ', break_long_words=False,
                                         break_on_hyphens=False))
    return '\n'.join(wrapped) + '\n'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exports', type=Path, required=True)
    parser.add_argument('--npcs', type=Path, required=True)
    parser.add_argument('--dbc', type=Path, required=True)
    parser.add_argument('--loot-baseline', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    target, archive = load_inputs(args.exports)
    with gzip.open(args.npcs,'rt',encoding='utf8') as stream:
        records = [json.loads(line) for line in stream]
    dbc = {name: dbc_ids(args.dbc / (name+'.dbc')) for name in
           ['FactionTemplate','CreatureDisplayInfo','CreatureType','CreatureFamily','Spell']}
    items = json.loads((args.loot_baseline/'item_template.json').read_text(encoding='utf8'))
    quests = json.loads((args.loot_baseline/'quest_template.json').read_text(encoding='utf8'))
    cohorts, report = prepare(records,target,archive,dbc,items,quests)
    source_paths = sorted(args.exports.glob('coa_world.*.json')) + sorted(args.exports.glob('asc_world.*.json'))
    source_paths += [args.npcs, args.loot_baseline / 'item_template.json',
                     args.loot_baseline / 'quest_template.json']
    source_paths += [args.dbc / (name + '.dbc') for name in dbc]
    report['sources'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}
    text = emit_sql(cohorts,report)
    args.output.write_text(text, encoding='utf8', newline='\n')
    report['sql_sha256'] = hashlib.sha256(text.encode()).hexdigest()
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf8',newline='\n')
    print(json.dumps({'candidates':len(report['candidates']),'included':len(cohorts),
                      'excluded':len(report['excluded']),'loot_rows':sum(c['info']['loot_rows'] for c in cohorts),
                      'sql_sha256':report['sql_sha256']}))

if __name__ == '__main__':
    main()
