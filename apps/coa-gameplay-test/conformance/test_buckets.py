import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from buckets import (BucketError, bucket_document, class_family, class_glob, clause_keys, clause_token_kind,
                     family_hits, id_hits, literals_of, read_sources, source_masks, tokens_of)
from conformance import main
from profile import DBC_DIR
from tooltip import Unreadable

FAMILY = 29
SPELL = 900001
RANK = 900011
TOKEN_SPELL = 900021
OTHER = 900002
SOURCE = (f'if (spellInfo->Id == {SPELL}) return;\n'
          'if (spellInfo->SpellFamilyFlags[0] & 8) return;\n'
          f'auto other = {OTHER}0;\n')


class FakeRecords:
    def __init__(self, rows):
        self.rows = rows

    def field(self, table, identity, name):
        if identity not in self.rows or name not in self.rows[identity]:
            raise Unreadable(f'{table} {identity} {name}')
        return self.rows[identity][name]


def spell_row(family=FAMILY, flags=(0, 0, 0), name='Seeded'):
    return {'SpellFamilyName': family, 'SpellName[enUS]': name,
            **{f'SpellFamilyFlags[{word}]': flag for word, flag in enumerate(flags)}}


RECORDS = FakeRecords({SPELL: spell_row(name='Seeded Strike'), RANK: spell_row(flags=(8, 0, 0)),
                       TOKEN_SPELL: spell_row(family=FAMILY + 1, flags=(8, 0, 0)), OTHER: spell_row(name='Other')})


def audit_row(index, text, evidence, spell=SPELL, labels=(), statuses=None, alerts=(), claims=1):
    return {'index': index, 'spell': spell, 'clause': text, 'evidence': evidence, 'claim_evidence': [evidence] * claims,
            'labels': list(labels), 'missing_labels': [], 'label_statuses': statuses or {},
            'alert_labels': list(alerts), 'alert_explanations': {}}


COVERAGE = {'clauses': [
    audit_row(0, 'Deals $s1 damage over $d.', 'unproven', labels=['900001 effect_value #0'],
              statuses={'900001 effect_value #0': 'ok'}),
    audit_row(1, 'Increases your strength by 5%.', 'data', spell=OTHER),
    audit_row(2, 'Strikes the target.', 'behaviour', spell=OTHER),
    audit_row(3, 'Your $900021s1 heals.', 'data', alerts=['900001 hit_mean'],
              statuses={'900001 hit_mean': 'alert'}),
    audit_row(4, 'Quoted text here.', 'behaviour', spell=OTHER),
    audit_row(5, 'Settled clause.', 'data', spell=OTHER, alerts=['900002 proc_rate'],
              statuses={'900002 proc_rate': 'alert'})],
    'statuses': {'900001 effect_value #0': 'ok', '900001 hit_mean': 'alert', '900002 proc_rate': 'alert',
                 '900002 trigger_count': 'alert'}}
MANIFEST = {'scenarios': [
    {'kind': 'value', 'spell_id': SPELL, 'rank_id': RANK, 'spell_name': 'Seeded Strike', 'expectations': [
        {'label': '900001 effect_value #0', 'spell_id': SPELL, 'rank_id': RANK, 'displayed': '$s1', 'rule': 'r'}]},
    {'kind': 'behaviour', 'spell_id': OTHER, 'rank_id': OTHER, 'expectations': [
        {'label': '900002 trigger_count', 'spell_id': OTHER, 'rank_id': OTHER, 'displayed': '',
         'rule': 'tooltip "Quoted text here." holds'}]}]}


def document(settled=None, standing=None, coverage=COVERAGE, manifest=MANIFEST):
    return bucket_document(coverage, manifest, {}, {'src/Seeded.cpp': SOURCE}, 'src/Seeded*', FAMILY, RECORDS,
                           settled or {}, standing or {}, {'coverage': 'c.json'})


class TokenTest(unittest.TestCase):
    def test_token_kinds_are_sorted_and_joined_with_literal(self):
        self.assertEqual(tokens_of('Deals $s1 damage over $d, @s:5:1@ and $?s1[a][b].'), ['$s1', '$d'])
        self.assertEqual(clause_token_kind(tokens_of('Deals $s1 damage over $d.'), []), 'duration+value')
        self.assertEqual(clause_token_kind(tokens_of('Lasts $d, 5 times.'), literals_of('Lasts $d, 5 times.')),
                         'duration+literal')
        self.assertEqual(clause_token_kind([], ['5']), 'literal')
        self.assertEqual(clause_token_kind([], []), 'prose')
        self.assertEqual(clause_token_kind(['${$s1*2}', '$<rage>'], []), 'formula+variable')

    def test_literals_ignore_numbers_inside_tokens(self):
        self.assertEqual(literals_of('Deals $12345s1 damage, 5 times or 2.5%.'), ['5', '2.5'])


class ScriptTouchTest(unittest.TestCase):
    def test_an_id_matches_only_as_a_whole_word(self):
        self.assertEqual(id_hits({'a.cpp': SOURCE}, SPELL), ['a.cpp:1'])
        self.assertEqual(id_hits({'a.cpp': SOURCE}, OTHER), [])

    def test_a_family_mask_matches_only_in_the_class_family(self):
        masks = source_masks({'a.cpp': SOURCE})
        self.assertEqual(masks, [(0, 8)])
        self.assertEqual(family_hits(RECORDS, RANK, FAMILY, masks), ['SpellFamilyFlags[0] & 8'])
        self.assertEqual(family_hits(RECORDS, TOKEN_SPELL, FAMILY, masks), [])
        self.assertEqual(family_hits(RECORDS, 1, FAMILY, masks), [])

    def test_the_family_is_the_most_common_spell_family(self):
        self.assertEqual(class_family(RECORDS, [SPELL, RANK, TOKEN_SPELL, 1]), FAMILY)
        with self.assertRaises(BucketError):
            class_family(RECORDS, [1])

    def test_sources_come_from_listed_paths_or_a_class_glob(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            (root / 'src/server/coa').mkdir(parents=True)
            for file in ('AscensionSunCleric.cpp', 'AscensionSunClericData.h', 'AscensionTemplar.cpp'):
                (root / 'src/server/coa' / file).write_text(file, encoding='utf-8')
            self.assertEqual(class_glob('Sun Cleric'), 'src/server/coa/**/AscensionSunCleric*')
            self.assertEqual(sorted(read_sources(root, pattern=class_glob('Sun Cleric'))),
                             ['src/server/coa/AscensionSunCleric.cpp', 'src/server/coa/AscensionSunClericData.h'])
            self.assertEqual(list(read_sources(root, paths=['src/server/coa/AscensionTemplar.cpp'])),
                             ['src/server/coa/AscensionTemplar.cpp'])


class BucketTest(unittest.TestCase):
    def test_buckets_follow_evidence_and_alerts(self):
        rows = document()['clauses']
        self.assertEqual([row['bucket'] for row in rows], ['U', 'D', 'out_of_scope', 'A', 'A', 'A'])

    def test_rows_carry_the_guide_fields(self):
        row = document()['clauses'][0]
        for field in ('index', 'spell', 'spell_name', 'clause', 'bucket', 'evidence', 'alert_source', 'script_touch',
                      'script_touch_hits', 'token_kind', 'tokens', 'literals', 'token_readbacks', 'readable_token',
                      'labels', 'missing_labels', 'label_statuses'):
            self.assertIn(field, row)
        self.assertEqual(row['spell_name'], 'Seeded Strike')
        self.assertEqual(row['token_kind'], 'duration+value')
        self.assertEqual(row['script_touch_hits'], {str(SPELL): {'id': ['src/Seeded.cpp:1'], 'family': []},
                                                    str(RANK): {'id': [], 'family': ['SpellFamilyFlags[0] & 8']}})
        self.assertEqual(row['token_readbacks'], {'$s1': {'900001 effect_value #0': 'ok'}, '$d': {}})
        self.assertFalse(row['readable_token'])

    def test_a_spell_named_by_a_token_is_checked_by_id_and_family(self):
        row = document()['clauses'][3]
        self.assertEqual(row['tokens'], ['$900021s1'])
        self.assertEqual(sorted(row['script_touch_hits']), [str(SPELL), str(RANK)])
        self.assertEqual(row['script_touch_hits'][str(RANK)]['family'], ['SpellFamilyFlags[0] & 8'])

    def test_an_uncited_alert_verdict_quoting_the_clause_makes_it_a(self):
        built = document()
        self.assertEqual(built['clauses'][4]['alert_source'],
                         ['uncited alert verdict 900002 trigger_count quotes this clause'])
        self.assertEqual(built['uncited_alert_verdicts'], ['900002 trigger_count'])

    def test_a_standing_alert_makes_a_clause_a_and_a_settled_alert_clears_it(self):
        standing = {(OTHER, 'Increases your strength by 5%.'): ''}
        settled = {(OTHER, 'Settled clause.'): 'ruled'}
        rows = document(settled=settled, standing=standing)['clauses']
        self.assertEqual((rows[1]['bucket'], rows[5]['bucket']), ('A', 'D'))
        self.assertEqual(document(settled=settled)['inputs']['settled_alerts'],
                         [{'spell': OTHER, 'clause': 'Settled clause.', 'why': 'ruled'}])

    def test_without_a_manifest_the_name_comes_from_the_dbc_and_ranks_are_unknown(self):
        rows = document(manifest={})['clauses']
        self.assertEqual(rows[0]['spell_name'], 'Seeded Strike')
        self.assertEqual(sorted(rows[0]['script_touch_hits']), [str(SPELL)])
        self.assertEqual(rows[4]['bucket'], 'out_of_scope')

    def test_a_new_class_audit_buckets_every_claim_as_u(self):
        unproven = {'clauses': [audit_row(index, text, 'unproven') for index, text in
                                enumerate(['Deals $s1 damage.', 'Strikes the target.'])], 'statuses': {}}
        self.assertEqual([row['bucket'] for row in document(coverage=unproven)['clauses']], ['U', 'U'])

    def test_clause_lists_are_checked(self):
        self.assertEqual(clause_keys([{'spell': 1, 'clause': 'x', 'why': 'y'}], 'f'), {(1, 'x'): 'y'})
        with self.assertRaises(BucketError):
            clause_keys([{'spell': '1', 'clause': 'x'}], 'f')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BucketCommandTest(unittest.TestCase):
    def test_the_command_reads_the_family_and_files_from_a_class_map(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            (root / 'src').mkdir()
            (root / 'src/Seeded.cpp').write_text('if (spellInfo->Id == 92111) return;\n', encoding='utf-8')
            coverage = root / 'coverage.json'
            coverage.write_text(json.dumps({'clauses': [audit_row(0, 'Strikes for $s1.', 'unproven', spell=92111)],
                                            'statuses': {}}), encoding='utf-8')
            class_map = root / 'class-map.json'
            class_map.write_text(json.dumps({'classes': {'19': {'family': 25, 'own_files': ['src/Seeded.cpp']}}}),
                                 encoding='utf-8')
            out = root / 'buckets.json'
            with mock.patch('sys.stdout'):
                code = main(['buckets', '--class', '19', '--coverage', str(coverage), '--class-map', str(class_map),
                             '--source-root', str(root), '--out', str(out)])
            self.assertEqual(code, 0)
            built = json.loads(out.read_text(encoding='utf-8'))
            self.assertEqual(built['inputs']['family'], 25)
            self.assertEqual(built['clauses'][0]['script_touch_hits'], {'92111': {'id': ['src/Seeded.cpp:1'],
                                                                                  'family': []}})
            self.assertEqual(built['clauses'][0]['bucket'], 'U')

    def test_a_class_missing_from_the_class_map_is_refused(self):
        with tempfile.TemporaryDirectory() as name:
            class_map = Path(name) / 'class-map.json'
            class_map.write_text(json.dumps({'classes': {}}), encoding='utf-8')
            coverage = Path(name) / 'coverage.json'
            coverage.write_text(json.dumps({'clauses': [], 'statuses': {}}), encoding='utf-8')
            with mock.patch('sys.stderr'):
                self.assertEqual(main(['buckets', '--class', '19', '--coverage', str(coverage), '--class-map',
                                       str(class_map), '--out', str(Path(name) / 'b.json')]), 2)


if __name__ == '__main__':
    unittest.main()
