import hashlib
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest

from mechanic_map import MechanicMap, ROOT, read_entries, source_reference

sys.path.insert(0, str(ROOT / 'apps/coa-dbc'))
from inspect_dbc import DataSet


def dbc(path, records, fields, size, strings=b''):
    path.write_bytes(struct.pack('<4s4I', b'WDBC', len(records), fields, size, len(strings))
                     + b''.join(records) + strings)


def scenario(name, entities):
    return {'id': name, 'path': name + '.json', 'contract': name + ' expected behavior', 'entities': entities,
            'metrics': ['health'], 'assertions': 1, 'checks': [], 'sha256': 'a' * 64}


class MapTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.data = self.root / 'dbc'
        self.data.mkdir()
        rows = []
        for identity in (700001, 700002):
            row = bytearray(936)
            struct.pack_into('<I', row, 0, identity)
            struct.pack_into('<I', row, 284, 6)
            struct.pack_into('<I', row, 544, 1)
            struct.pack_into('<I', row, 680, 7)
            rows.append(row)
        dbc(self.data / 'Spell.dbc', rows, 234, 936, b'\0Alpha\0Expected $s1\0')
        advancement = bytearray(692)
        struct.pack_into('<I', advancement, 0, 81)
        struct.pack_into('<II', advancement, 20, 700001, 700002)
        struct.pack_into('<I', advancement, 104, 10)
        dbc(self.data / 'CharacterAdvancement.dbc', [advancement], 179, 692)
        dispatch = self.root / 'src/server/game/Spells/SpellEffects.cpp'
        dispatch.parent.mkdir(parents=True)
        dispatch.write_text('pEffect SpellEffects[TOTAL_SPELL_EFFECTS] =\n{\n' +
                            ''.join(f'&Spell::EffectNULL, // {i}\n' for i in range(6)) +
                            '&Spell::EffectApplyAura, // 6 SPELL_EFFECT_APPLY_AURA\n};\n'
                            'void Spell::EffectApplyAura(SpellEffIndex index) {}\n')
        self.sql = {'schema': 1, 'resolved_spells': [700001, 700002, 700003], 'requested_quests': [7],
                    'tables': {
                        'spell_ranks': {'status': 'observed', 'rows': [
                            {'first_spell_id': 700001, 'spell_id': 700001, 'rank': 1},
                            {'first_spell_id': 700001, 'spell_id': 700002, 'rank': 2},
                            {'first_spell_id': 700001, 'spell_id': 700003, 'rank': 3}]},
                        'spell_script_names': {'status': 'observed', 'rows': [
                            {'spell_id': -700001, 'ScriptName': 'all_ranks'},
                            {'spell_id': 700001, 'ScriptName': 'first_rank_only'}]},
                        'quest_template': {'status': 'observed', 'rows': [
                            {'ID': 7, 'LogTitle': 'A quest', 'MinLevel': 4, 'RewardSpell': 700001,
                             'RequiredItemId1': 42, 'RequiredItemCount1': 2, 'RewardItem1': 0}]},
                        'quest_template_addon': {'status': 'observed', 'rows': [
                            {'ID': 7, 'PrevQuestID': -783, 'NextQuestID': 15}]},
                        'creature_queststarter': {'status': 'observed', 'rows': [{'id': 900, 'quest': 7}]}}}
        self.scenarios = [scenario('rank-two', {'spell': [700002]}),
                          scenario('quest-seven', {'quest': [7]}),
                          scenario('same-number-different-namespace', {'quest': [700001]})]

    def tearDown(self):
        self.temporary.cleanup()

    def maps(self, entries=None, sql=True):
        return MechanicMap(DataSet(self.data), self.sql if sql else None, self.root,
                           entries=entries or {}, scenarios=self.scenarios)

    def test_rank_groups_and_missing_records_do_not_claim_character_eligibility(self):
        result = self.maps().show('ability:700001')
        ranks = result['facts']['ranks']
        self.assertEqual([group['source'] for group in ranks['groups']],
                         ['CharacterAdvancement', 'captured spell_ranks'])
        self.assertFalse(ranks['records'][-1]['present_in_selected_dbc'])
        self.assertIn('not observed', ranks['active_for_character'])
        self.assertEqual(result['facts']['acquisition'][0]['values']['RequiredLevel'], 10)
        self.assertEqual(result['verification']['runtime_status'], 'not-evaluated')

    def test_related_rank_scenarios_are_found_without_cross_namespace_matches(self):
        result = self.maps().show('ability:700001')
        self.assertEqual([row['id'] for row in result['verification']['scenarios']], ['rank-two'])
        self.assertEqual(result['verification']['scenarios'][0]['matched_entities'], {'spell': [700002]})

    def test_negative_sql_binding_inherits_to_higher_rank_but_positive_root_does_not(self):
        result = self.maps().show('ability:700002')
        self.assertEqual([row['ScriptName'] for row in result['facts']['sql_script_bindings']], ['all_ranks'])

    def test_raw_dispatch_does_not_masquerade_as_reviewed_execution(self):
        result = self.maps().show('ability:700001')
        self.assertEqual(result['facts']['raw_dispatch'][0]['handler'], 'Spell::EffectApplyAura')
        self.assertEqual(result['execution'], [])
        self.assertEqual(result['source_review'], 'not-reviewed')
        self.assertTrue(any('raw dispatch alone' in gap for gap in result['gaps']))

    def test_misaligned_native_dispatch_annotations_fail_closed(self):
        path = self.root / 'src/server/game/Spells/SpellEffects.cpp'
        path.write_text(path.read_text().replace('// 6 SPELL_EFFECT', '// 5 SPELL_EFFECT'))
        with self.assertRaisesRegex(ValueError, 'dispatch indices changed'):
            self.maps().show('ability:700001')

    def test_absent_sql_is_explicit_even_when_dbc_ranks_exist(self):
        result = self.maps(sql=False).show('ability:700001')
        self.assertTrue(any('No SQL capture' in gap for gap in result['gaps']))
        self.assertEqual(len(result['facts']['ranks']['groups']), 1)

    def test_quest_links_preserve_signed_prerequisites_and_reward_spell_namespace(self):
        result = self.maps().show('quest:7')
        facts = result['facts']
        self.assertEqual(facts['quest_links'][0], {'table': 'quest_template_addon', 'field': 'PrevQuestID',
                                                'value': -783, 'target': 'quest:783'})
        self.assertIn('ability:700001', result['related'])
        self.assertNotIn('RewardItem1', facts['rewards'])
        self.assertEqual(facts['quest_givers']['creature_queststarter'][0]['id'], 900)
        self.assertEqual([row['id'] for row in result['verification']['scenarios']], ['quest-seven'])

    def test_unknown_quest_is_unknown_not_reported_missing_from_the_game(self):
        result = self.maps().show('quest:888')
        self.assertIsNone(result['facts']['definition']['ID'])
        self.assertTrue(any('not observed' in gap for gap in result['gaps']))
        self.assertEqual(result['implementation'], 'unreviewed')

    def test_source_movement_updates_line_but_changed_content_requires_review(self):
        path = self.root / 'source.cpp'
        path.write_text('void Important() {}\n')
        reference = {'path': 'source.cpp', 'anchor': 'void Important(',
                     'reviewed_sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
        self.assertEqual(source_reference(reference, self.root)['state'], 'current')
        path.write_text('// changed source\nvoid Important() {}\n')
        result = source_reference(reference, self.root)
        self.assertEqual((result['state'], result['line']), ('needs-review', 2))
        entries = {'ability:700001': {'execution': [{'stage': 'result', 'source': reference}]}}
        self.assertEqual(self.maps(entries).show('ability:700001')['source_review'], 'needs-review')
        path.write_text('void Important() {}\nvoid Important(int) {}\n')
        self.assertEqual(source_reference(reference, self.root)['state'], 'ambiguous-anchor')
        with self.assertRaises(ValueError):
            source_reference({**reference, 'path': '../outside.cpp'}, self.root)

    def test_registry_rejects_planned_execution_and_duplicate_keys(self):
        path = self.root / 'entries.json'
        entry = {'key': 'ability:7', 'implementation': 'planned', 'execution': [{'source': {}}]}
        path.write_text(json.dumps({'schema': 1, 'entries': [entry]}))
        with self.assertRaisesRegex(ValueError, 'Planned'):
            read_entries(path)
        entry['execution'] = []
        path.write_text(json.dumps({'schema': 1, 'entries': [entry, entry]}))
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            read_entries(path)

    def test_checked_in_maps_have_valid_links(self):
        entries = read_entries()
        result = MechanicMap(entries=entries).check()
        self.assertEqual(result['errors'], [])

    def test_compact_contracts_are_explicit_excerpts_with_full_detail_available(self):
        self.scenarios[0]['contract'] = 'A' * 600
        maps = self.maps()
        compact = maps.show('ability:700001')
        contract = compact['expected']['scenario_contracts'][0]
        self.assertTrue(contract['truncated'])
        self.assertEqual(contract['source']['pointer'], '/contract')
        details = maps.show('ability:700001', details=True)
        self.assertEqual(len(details['expected']['scenario_contracts'][0]['text']), 600)


if __name__ == '__main__':
    unittest.main()
