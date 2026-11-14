import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from audit import audit_document, hooked_labels, merged_verdicts
from compare import NOT_MEASURED, Verdict, write_verdicts
from conformance import main
from passives import PASSIVE_DELTA

CLASS = {'class_id': 23, 'class_name': 'Seeded', 'level': 60}
SPELL = 900001
OTHER_SPELL = 900002
BUILD = 'c' * 64
OTHER_BUILD = 'd' * 64
HIT = f'{SPELL} hit_mean'
VALUE = f'{SPELL} effect_value #0'
PASSIVE = f'{OTHER_SPELL} passive_delta #0'


def verdict(label, status='ok', check='hit_mean', spell=SPELL, build=BUILD, explanation='', detail=None):
    return Verdict(label, status, 1.0, 1.0, 1.0, 1.0, explanation, f'conformance-seeded-{spell}', spell, spell, check,
                   detail=detail, build=build)


def claim(text, *labels, spell=SPELL):
    return {'spell': spell, 'clause': text, 'kind': 'claim', 'labels': list(labels)}


LEDGER = [claim('deals damage', HIT), claim('raises the value', VALUE),
          claim('raises strength', PASSIVE, spell=OTHER_SPELL),
          {'spell': SPELL, 'clause': 'Flavour text.', 'kind': 'no_claim'}]


class AuditTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.ledger = self.root / 'ledger.json'
        self.ledger.write_text(json.dumps(LEDGER), encoding='utf-8')

    def tearDown(self):
        self.temporary.cleanup()

    def results(self, name, verdicts):
        directory = self.root / name
        directory.mkdir()
        write_verdicts(CLASS, directory / 'manifest.json', self.root / 'r', verdicts, directory)
        return directory

    def test_a_ledger_without_verdicts_leaves_every_claim_unproven(self):
        document = audit_document(23, self.ledger, [])
        self.assertEqual(document['figures']['claims'], 3)
        self.assertEqual(document['figures']['unproven'], 3)
        self.assertEqual(document['no_claim_entries'], 1)
        self.assertEqual([row['evidence'] for row in document['clauses']], ['unproven'] * 3)
        self.assertEqual(document['clauses'][0]['missing_labels'], [HIT])
        self.assertEqual(document['statuses'], {})

    def test_rows_carry_the_coverage_fields_and_alert_explanations(self):
        run = self.results('run', [verdict(HIT), verdict(VALUE, 'alert', 'effect_value', explanation='x' * 400)])
        document = audit_document(23, self.ledger, [run])
        first, second, third = document['clauses']
        self.assertEqual(sorted(first), ['alert_explanations', 'alert_labels', 'claim_evidence', 'clause', 'evidence',
                                         'index', 'label_statuses', 'labels', 'missing_labels', 'spell'])
        self.assertEqual((first['index'], first['evidence'], first['claim_evidence']), (0, 'behaviour', ['behaviour']))
        self.assertEqual(second['alert_labels'], [VALUE])
        self.assertEqual(len(second['alert_explanations'][VALUE]), 300)
        self.assertEqual(third['missing_labels'], [PASSIVE])
        self.assertEqual(document['figures'], {'claims': 3, 'behaviour': 1, 'data': 0, 'unproven': 2, 'resolved': 1,
                                               'not_measured': 0, 'tool_gaps_pending': 0})

    def test_a_later_run_replaces_earlier_labels_and_disagreements_are_listed(self):
        first = self.results('first', [verdict(HIT, 'alert'), verdict(VALUE, check='effect_value')])
        second = self.results('second', [verdict(HIT)])
        document = audit_document(23, self.ledger, [first, second])
        self.assertEqual(document['statuses'][HIT], 'ok')
        self.assertEqual(document['clauses'][0]['evidence'], 'behaviour')
        self.assertEqual([row['label'] for row in document['results_disagree']], [HIT])
        self.assertEqual([run['status'] for run in document['results_disagree'][0]['runs']], ['alert', 'ok'])

    def test_results_replace_the_base_and_the_replaced_and_added_labels_are_listed(self):
        base = self.results('base', [verdict(HIT, 'alert'), verdict(VALUE, check='effect_value')])
        latest = self.results('latest', [verdict(HIT), verdict(PASSIVE, check='effect_value', spell=OTHER_SPELL)])
        document = audit_document(23, self.ledger, [latest], base_results=base)
        self.assertEqual(document['results_replaced'], [HIT])
        self.assertEqual(document['results_added'], [PASSIVE])
        self.assertEqual(document['figures']['unproven'], 0)

    def test_mixed_builds_are_refused_unless_a_build_is_named(self):
        first = self.results('first', [verdict(HIT)])
        second = self.results('second', [verdict(VALUE, check='effect_value', build=OTHER_BUILD)])
        with self.assertRaises(ValueError):
            audit_document(23, self.ledger, [first, second])
        document = audit_document(23, self.ledger, [first, second], build='audit')
        self.assertEqual(document['figures']['data'], 1)

    def test_hooked_labels_are_not_measured(self):
        hooked = self.root / 'hooked.json'
        hooked.write_text(json.dumps([{'spell': SPELL, 'labels': [HIT]}]), encoding='utf-8')
        document = audit_document(23, self.ledger, [self.results('run', [verdict(HIT)])], hooked=hooked)
        self.assertEqual(document['statuses'][HIT], NOT_MEASURED)
        self.assertEqual(document['figures']['not_measured'], 1)
        self.assertEqual(hooked_labels({'labels': ['a', 'b']}), {'a', 'b'})

    def test_the_manifest_stamps_a_missing_metric(self):
        manifest = self.root / 'manifest.json'
        expectation = {'label': PASSIVE, 'check': PASSIVE_DELTA, 'spell_id': OTHER_SPELL, 'rank_id': OTHER_SPELL,
                       'effect_index': 0, 'displayed': '$s1', 'rule': 'r', 'model': {'metric': 'spell_damage_count'}}
        manifest.write_text(json.dumps({'scenarios': [{'expectations': [expectation]}]}), encoding='utf-8')
        run = self.results('run', [verdict(PASSIVE, check=PASSIVE_DELTA, spell=OTHER_SPELL)])
        with self.assertRaises(ValueError):
            audit_document(23, self.ledger, [run])
        document = audit_document(23, self.ledger, [run], manifest=manifest)
        self.assertEqual(document['clauses'][2]['evidence'], 'behaviour')

    def test_merge_keeps_first_seen_order(self):
        merged = merged_verdicts([[verdict('a'), verdict('b')], [verdict('b', 'alert'), verdict('c')]])
        self.assertEqual([(item.label, item.status) for item in merged], [('a', 'ok'), ('b', 'alert'), ('c', 'ok')])

    def test_audit_command_writes_the_document(self):
        out = self.root / 'out' / 'coverage.json'
        with mock.patch('sys.stdout'):
            self.assertEqual(main(['audit', '--class', '23', '--clauses', str(self.ledger), '--out', str(out)]), 0)
        self.assertEqual(json.loads(out.read_text(encoding='utf-8'))['figures']['unproven'], 3)

    def test_audit_command_reports_a_refusal(self):
        first = self.results('first', [verdict(HIT)])
        second = self.results('second', [verdict(VALUE, check='effect_value', build=OTHER_BUILD)])
        with mock.patch('sys.stderr'):
            self.assertEqual(main(['audit', '--class', '23', '--clauses', str(self.ledger), '--results', str(first),
                                   str(second), '--out', str(self.root / 'x.json')]), 2)
            self.assertEqual(main(['audit', '--class', '23', '--clauses', str(self.root / 'missing.json'), '--out',
                                   str(self.root / 'x.json')]), 2)


if __name__ == '__main__':
    unittest.main()
