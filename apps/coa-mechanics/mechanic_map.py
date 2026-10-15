CLI_DESCRIPTION = """Compact mechanic maps: derived references plus explicitly reviewed interpretation."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'apps/coa-gameplay-test'))
import catalog


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_reference(reference, root=ROOT):
    path = (root / reference['path']).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('Source reference must stay inside the repository')
    result = {'path': reference['path'], 'anchor': reference['anchor']}
    if not path.is_file():
        return {**result, 'state': 'missing'}
    lines = path.read_text(encoding='utf-8').splitlines()
    matches = [i + 1 for i, line in enumerate(lines) if reference['anchor'] in line]
    if len(matches) != 1:
        return {**result, 'state': 'missing-anchor' if not matches else 'ambiguous-anchor'}
    current = digest(path)
    return {**result, 'line': matches[0], 'sha256': current,
            'state': 'current' if current == reference['reviewed_sha256'] else 'needs-review'}


def read_entries(path=HERE / 'entries.json'):
    data = catalog.read_json(path)
    if data.get('schema') != 1 or not isinstance(data.get('entries'), list):
        raise ValueError('Unsupported mechanic map registry')
    seen = set()
    for entry in data['entries']:
        key = entry['key']
        if not re.fullmatch(r'((ability|quest):[1-9][0-9]*|feature:[a-z0-9-]+)', key) or key in seen:
            raise ValueError(f'Invalid or duplicate mechanic key: {key}')
        seen.add(key)
        if entry['implementation'] not in ('source-present', 'partial', 'planned'):
            raise ValueError(f'Invalid implementation state for {key}')
        if entry['implementation'] == 'planned' and entry['execution']:
            raise ValueError('Planned features cannot claim an actual execution path')
        for node in [*entry['execution'], *entry.get('checks', [])]:
            reference = node['source']
            if not reference.get('anchor') or not re.fullmatch('[0-9a-f]{64}', reference['reviewed_sha256']):
                raise ValueError('Source references need a nonempty anchor and reviewed file hash')
        for entity, ids in entry.get('entities', {}).items():
            if entity not in ('spell', 'quest', 'talent', 'item') or not isinstance(ids, list):
                raise ValueError('Unsupported mechanic entity selector')
            if any(type(value) is not int or value <= 0 for value in ids):
                raise ValueError('Mechanic entity IDs must be positive integers')
    return {entry['key']: entry for entry in data['entries']}


class MechanicMap:
    def __init__(self, dataset=None, sql=None, root=ROOT, entries=None, scenarios=None):
        self.root = Path(root)
        self.dataset = dataset
        self.sql = sql if sql is not None else (dataset.sql if dataset else None)
        if self.sql is not None and (not isinstance(self.sql, dict) or self.sql.get('schema') != 1
                                     or not isinstance(self.sql.get('tables'), dict)):
            raise ValueError('Unsupported SQL capture')
        self.entries = read_entries() if entries is None else entries
        self.scenarios = catalog.catalog() if scenarios is None else scenarios

    def table_rows(self, name):
        table = self.sql.get('tables', {}).get(name, {}) if self.sql else {}
        if table.get('status') != 'observed':
            return []
        return table['rows']

    def source_nodes(self, nodes):
        return [{**node, 'source': source_reference(node['source'], self.root)} for node in nodes]

    def scenario_refs(self, selectors, explicit=()):
        result = []
        for row in self.scenarios:
            matched = {kind: sorted(set(ids).intersection(row.get('entities', {}).get(kind, [])))
                       for kind, ids in selectors.items()}
            matched = {kind: ids for kind, ids in matched.items() if ids}
            if not matched and row['id'] not in explicit:
                continue
            result.append({'id': row['id'], 'path': row['path'], 'contract': row['contract'],
                           'matched_entities': matched, 'metrics': row['metrics'], 'assertions': row['assertions'],
                           'checks': row['checks'], 'definition_sha256': row['sha256'],
                           'evidence': 'definition only; relevance is not a runtime pass or complete coverage'})
        return result

    def record_values(self, table, identity):
        return {field['name']: field['value'] for field in self.dataset.record(table, identity)['fields']
                if field['type'] != 'bytes'}

    def ability(self, identity):
        if self.dataset is None:
            raise ValueError('Ability maps require --data with the selected DBC directory')
        selected = self.dataset.record('Spell', identity)
        edges = self.dataset.relationships('Spell', identity)
        groups, acquisition, sources = [], [], {}
        ids = {identity}
        for edge in edges['incoming']:
            table = edge['table']
            if table not in ('CharacterAdvancement', 'Talent', 'SkillLineAbility'):
                continue
            if any(row['table'] == table and row['id'] == edge['id'] for row in acquisition):
                continue
            values = self.record_values(table, edge['id'])
            sources[table] = self.dataset.load(table)[3]
            context = {}
            joins = [('ClassType', 'CharacterAdvancementClassTypes'), ('Tab', 'CharacterAdvancementTabTypes')] \
                if table == 'CharacterAdvancement' else [('TalentTab', 'TalentTab')] if table == 'Talent' else []
            for field, target in joins:
                target_id = values.get(field)
                if target.casefold() not in self.dataset.files or not target_id:
                    continue
                _, _, target_index, origin = self.dataset.load(target)
                context[target] = self.record_values(target, target_id) if target_id in target_index else {
                    'id': target_id, 'status': 'referenced record absent'}
                sources[target] = origin
            acquisition.append({'table': table, 'id': edge['id'], 'values': values, 'context': context,
                                'scope': 'data reference; eligibility and server-side filtering still apply'})
            prefix = 'RankSpell[' if table == 'CharacterAdvancement' else 'RankID[' if table == 'Talent' else None
            if prefix:
                ranks = [{'rank': int(name.split('[')[1][:-1]) + 1, 'spell': value}
                         for name, value in values.items() if name.startswith(prefix) and value]
                groups.append({'source': table, 'id': edge['id'], 'ranks': ranks})
                ids.update(rank['spell'] for rank in ranks)
        sql_observed = bool(self.sql and identity in self.sql.get('resolved_spells', []))
        ranks = self.table_rows('spell_ranks') if sql_observed else []
        roots = {row['first_spell_id'] for row in ranks if row['spell_id'] == identity}
        for root in sorted(roots):
            chain = sorted((row for row in ranks if row['first_spell_id'] == root), key=lambda row: row['rank'])
            groups.append({'source': 'captured spell_ranks', 'id': root,
                           'ranks': [{'rank': row['rank'], 'spell': row['spell_id']} for row in chain]})
            ids.update(row['spell_id'] for row in chain)
        available = self.dataset.load('Spell')[2]
        rank_records, descriptions = [], {}
        for spell_id in sorted(ids):
            record = self.dataset.record('Spell', spell_id) if spell_id in available else None
            rank_records.append({'spell': spell_id, 'name': record['name'] if record else None,
                                 'present_in_selected_dbc': record is not None})
            if record:
                text = next(f['value'] for f in record['fields'] if f['name'] == 'Description[enUS]')
                if text:
                    descriptions.setdefault(text, []).append(spell_id)
        sql_scripts = [row for row in self.table_rows('spell_script_names')
                       if sql_observed and (abs(row['spell_id']) == identity
                                            or row['spell_id'] in {-r for r in roots})]
        facts = {'ranks': {'groups': groups, 'records': rank_records,
                          'active_for_character': 'not observed; DBC membership is not acquisition/active-rank proof'},
                 'acquisition': acquisition, 'relationships': edges,
                 'descriptions': [{'spells': spell_ids, 'text': text, 'basis': 'raw client description'}
                                  for text, spell_ids in descriptions.items()],
                 'raw_dispatch': self.dispatch(selected), 'sql_script_bindings': sql_scripts,
                 'data_notes': selected['notes'],
                 'observations': selected.get('observations', []),
                 'provenance': {'Spell': selected['origin'], **sources}}
        if 'CharacterAdvancement' in sources:
            facts['acquisition_path'] = self.source_nodes(
                self.entries.get('feature:spell-acquisition', {}).get('execution', []))
        gaps = ['Player eligibility and active rank require character state and the native acquisition path.',
                'Raw effect dispatch precedes SQL/C++ corrections; trigger references are not an observed call graph.']
        if not groups:
            gaps.append('No rank group found in the inspected sources; do not assume this is a single-rank ability.')
        if not sql_observed:
            gaps.append('No SQL capture for this spell; rank chains and script bindings are incomplete.')
        if sql_observed:
            facts['sql_source'] = {key: self.sql.get(key) for key in ('source', 'captured_at', 'scope')}
            facts['sql_table_status'] = {name: self.sql['tables'].get(name, {}).get('status', 'not observed')
                                         for name in ('spell_ranks', 'spell_script_names')}
        return selected['name'], {'spell': sorted(ids)}, facts, gaps

    def dispatch(self, record):
        path = self.root / 'src/server/game/Spells/SpellEffects.cpp'
        text = path.read_text(encoding='utf-8')
        marker = 'pEffect SpellEffects[TOTAL_SPELL_EFFECTS] ='
        if text.count(marker) != 1:
            raise ValueError('Native effect dispatch declaration changed; review its parser')
        body = text.split(marker, 1)[1].split('};', 1)[0]
        handlers = {}
        for index, (symbol, number) in enumerate(re.findall(
                r'^\s*&Spell::(\w+)\s*,?\s*(?://\s*(\d+))?', body, re.M)):
            if number and int(number) != index:
                raise ValueError('Native effect dispatch indices changed; review its parser')
            handlers[index] = symbol
        if not handlers:
            raise ValueError('Native effect dispatch table is empty')
        fields = {field['name']: field for field in record['fields']}
        result = []
        for slot in range(3):
            field = fields[f'Effect[{slot}]']
            if not field['value']:
                continue
            handler = handlers.get(field['value'])
            result.append({'slot': slot, 'effect': field['value'], 'labels': field.get('labels', []),
                           'handler': 'Spell::' + handler if handler else None,
                           'source': str(path.relative_to(self.root)),
                           'line': next((i + 1 for i, line in enumerate(text.splitlines())
                                         if handler and f'void Spell::{handler}(' in line), None),
                           'scope': 'raw DBC dispatch; custom hooks/corrections may replace behavior'})
        return result

    def quest(self, identity):
        captured = bool(self.sql and identity in self.sql.get('requested_quests', []))
        rows = {name: [row for row in self.table_rows(name) if row.get('ID', row.get('quest')) == identity]
                for name in ('quest_template', 'quest_template_addon', 'quest_offer_reward', 'quest_request_items',
                             'creature_queststarter', 'creature_questender',
                             'gameobject_queststarter', 'gameobject_questender')} if captured else {}
        template = next(iter(rows.get('quest_template', [])), {})
        addon = next(iter(rows.get('quest_template_addon', [])), {})
        links = []
        for source, values, keys in [('quest_template', template, ('RewardNextQuest',)),
                                     ('quest_template_addon', addon,
                                      ('PrevQuestID', 'NextQuestID', 'BreadcrumbForQuestId'))]:
            for key in keys:
                if values.get(key):
                    links.append({'table': source, 'field': key, 'value': values[key],
                                  'target': 'quest:' + str(abs(values[key]))})
        spell_links = [{'field': key, 'value': values[key], 'target': 'ability:' + str(abs(values[key]))}
                       for values, keys in [(template, ('RewardSpell', 'RewardDisplaySpell')),
                                             (addon, ('SourceSpellID',))]
                       for key in keys if values.get(key)]
        def useful(values):
            return {name: value for name, value in values.items() if value not in (0, None, '')}
        facts = {'definition': {key: template.get(key) for key in
                               ('ID', 'LogTitle', 'LogDescription', 'QuestLevel', 'MinLevel', 'Flags')},
                 'objectives': useful({k: v for k, v in template.items()
                                       if k.startswith(('Required', 'ObjectiveText', 'TimeAllowed'))}),
                 'rewards': useful({k: v for k, v in template.items() if k.startswith('Reward')}),
                 'prerequisites_and_flags': useful(addon),
                 'quest_givers': {name: values for name, values in rows.items() if 'queststarter' in name
                                 or 'questender' in name}, 'quest_links': links, 'spell_links': spell_links,
                 'omitted': 'zero/empty objective, reward and addon values; full rows remain in the SQL capture',
                 'scope': 'captured quest definition and direct relations; signed prerequisites remain unmodified'}
        if captured:
            facts['sql_source'] = {key: self.sql.get(key) for key in ('source', 'captured_at', 'scope')}
            facts['table_status'] = {name: self.sql['tables'].get(name, {}).get('status', 'not observed')
                                     for name in rows}
        gaps = ['Character eligibility, conditions, SmartAI and custom scripts need a task-specific trace.',
                'Template objectives/rewards are data; observed acceptance/completion/reward delivery is separate.']
        if not template:
            gaps.append('Quest template not observed; capture --quest for this ID before interpreting its definition.')
        return template.get('LogTitle', f'Quest {identity}'), {'quest': [identity]}, facts, gaps

    def show(self, key, details=False):
        if not re.fullmatch(r'(ability:[1-9][0-9]*|quest:[1-9][0-9]*|feature:[a-z0-9-]+)', key):
            raise ValueError('Use ability:ID, quest:ID or feature:slug')
        kind, value = key.split(':', 1)
        entry = self.entries.get(key, {})
        if kind == 'feature' and not entry:
            raise ValueError(f'Unknown feature {key}; use list to discover mapped features')
        facts, gaps = {}, []
        selectors = entry.get('entities', {})
        title = entry.get('title', key)
        if kind in ('ability', 'quest'):
            title, selectors, facts, gaps = getattr(self, kind)(int(value))
        flow = self.entries.get('feature:quests', {}) if kind == 'quest' and not entry else entry
        execution = self.source_nodes(flow.get('execution', []))
        checks = self.source_nodes(entry.get('checks', []))
        scenarios = self.scenario_refs(selectors, entry.get('scenarios', []))
        related = [topic for topic, other in self.entries.items() if topic != key
                   and (key in other.get('related', []) or topic in entry.get('related', [])
                        or any(set(ids).intersection(other.get('entities', {}).get(entity, []))
                               for entity, ids in selectors.items()))]
        if kind == 'quest' and 'feature:quests' not in related:
            related.append('feature:quests')
        related = sorted(set(related) | {link['target'] for link in facts.get('spell_links', [])})
        source_nodes = [*execution, *checks, *facts.get('acquisition_path', [])]
        stale = [node['source'] for node in source_nodes if node['source']['state'] != 'current']
        if stale:
            gaps.append('Source interpretation needs review: sources changed or cannot be located.')
        if not scenarios:
            gaps.append('No matching registered gameplay scenario; other check references are not an executed pass.')
        if not execution and kind != 'feature':
            gaps.append('No reviewed ability-specific execution explanation; raw dispatch alone is incomplete.')
        result = {'schema': 1, 'key': key, 'kind': kind, 'title': title,
                'implementation': entry.get('implementation', 'unreviewed'),
                'source_review': 'needs-review' if stale else 'current' if execution or checks else 'not-reviewed',
                'summary': entry.get('summary', ''), 'facts': facts,
                'expected': {'interpretation': entry.get('expectations', []),
                             'scenario_contracts': [{'scenario': row['id'], 'text': row['contract']}
                                                    for row in scenarios if row['contract']]},
                'execution': execution, 'state_model': entry.get('state_model', []),
                'verification': {'scenarios': [{k: v for k, v in row.items() if k != 'contract'} for row in scenarios],
                                 'other_checks': checks, 'runtime_status': 'not-evaluated'},
                'related': related, 'gaps': [*entry.get('gaps', []), *gaps],
                'scope': 'investigation map; source/data presence and scenario definitions do not prove runtime parity'}
        if not details:
            result['view'] = 'compact; --details includes complete contracts, metrics, checks and rank descriptions'
            contracts = [row for row in scenarios if row['contract']]
            result['expected']['scenario_contracts'] = [
                {'scenario': row['id'], 'excerpt': row['contract'][:320], 'truncated': len(row['contract']) > 320,
                 'source': {'path': row['path'], 'pointer': '/contract'}} for row in contracts[:3]]
            result['expected']['additional_contracts'] = max(0, len(contracts) - 3)
            result['verification']['scenarios'] = [
                {k: v for k, v in row.items() if k in ('id', 'path', 'matched_entities', 'assertions')}
                for row in scenarios]
            if kind == 'ability':
                result['facts']['descriptions'] = [
                    description if int(value) in description['spells'] else
                    {'spells': description['spells'], 'different_from_selected': True, 'details_required': True}
                    for description in facts['descriptions']]
        return result

    def list(self, query=''):
        words = query.casefold().split()
        return [{'key': key, 'title': entry['title'], 'implementation': entry['implementation']}
                for key, entry in self.entries.items()
                if all(word in json.dumps(entry).casefold() for word in words)]

    def check(self):
        errors, stale = [], []
        scenarios = {row['id'] for row in self.scenarios}
        for key, entry in self.entries.items():
            for related in entry.get('related', []):
                if related not in self.entries:
                    errors.append(f'{key}: missing related map {related}')
            for scenario in entry.get('scenarios', []):
                if scenario not in scenarios:
                    errors.append(f'{key}: missing scenario {scenario}')
            for node in [*entry['execution'], *entry.get('checks', [])]:
                source = source_reference(node['source'], self.root)
                if source['state'] == 'needs-review':
                    stale.append({'key': key, **source})
                elif source['state'] != 'current':
                    errors.append(f"{key}: {source['state']}: {source['path']} :: {source['anchor']}")
        return {'entries': len(self.entries), 'errors': errors, 'needs_review': stale,
                'scope': 'reference integrity only; source changes flag interpretation for review'}


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('command', choices=['list', 'show', 'check'])
    parser.add_argument('key', nargs='?')
    parser.add_argument('--query', default='')
    parser.add_argument('--data', type=Path)
    parser.add_argument('--sql', type=Path)
    parser.add_argument('--observations', type=Path, action='append', default=[])
    parser.add_argument('--details', action='store_true', help='Include complete contracts and rank descriptions')
    args = parser.parse_args(argv)
    try:
        dataset = None
        if args.data:
            sys.path.insert(0, str(ROOT / 'apps/coa-dbc'))
            from inspect_dbc import DataSet
            dataset = DataSet(args.data, sql=args.sql, observations=args.observations)
        sql = catalog.read_json(args.sql) if args.sql else None
        maps = MechanicMap(dataset, sql)
        if args.command == 'show' and not args.key:
            raise ValueError('show requires a mechanic key')
        if args.command == 'show':
            result = maps.show(args.key, args.details)
        elif args.command == 'list':
            result = maps.list(args.query)
        else:
            result = maps.check()
        print(json.dumps(result, indent=2, allow_nan=False))
        return int(bool(result.get('errors'))) if args.command == 'check' else 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({'error': str(error)}), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
