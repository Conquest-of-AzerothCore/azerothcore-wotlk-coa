from dataclasses import replace
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from audit import audit_document, hooked_labels, merged_verdicts
from compare import BASE_ROLL_ONLY, LINKED_FROM, NOT_MEASURED, Verdict, write_verdicts
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
CONTRAST = f'{SPELL} hit_mean rap'
ROLL = f'{SPELL} effect_value base #1'


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

    def test_a_layered_label_its_run_did_not_select_keeps_the_earlier_verdict(self):
        base = self.results('base', [replace(verdict(HIT), runs=['b1']),
                                     replace(verdict(VALUE, check='effect_value'), runs=['b1'])])
        latest = self.results('latest', [replace(verdict(HIT, 'unmeasured'), runs=[]),
                                         replace(verdict(VALUE, 'alert', check='effect_value'), runs=['l1']),
                                         replace(verdict(PASSIVE, 'unmeasured', spell=OTHER_SPELL), runs=[])])
        document = audit_document(23, self.ledger, [latest], base_results=base)
        self.assertEqual(document['statuses'][HIT], 'ok')
        self.assertEqual(document['statuses'][VALUE], 'alert')
        self.assertEqual(document['statuses'][PASSIVE], 'unmeasured')
        self.assertEqual(document['results_replaced'], [VALUE])
        self.assertEqual(document['results_not_selected'], [HIT])
        self.assertEqual(document['results_added'], [PASSIVE])
        self.assertEqual(document['clauses'][0]['evidence'], 'behaviour')

    def test_a_later_results_directory_that_did_not_select_a_label_keeps_the_earlier_one(self):
        first = self.results('first', [replace(verdict(HIT), runs=['f1'])])
        second = self.results('second', [replace(verdict(HIT, 'unmeasured'), runs=[])])
        document = audit_document(23, self.ledger, [first, second])
        self.assertEqual(document['statuses'][HIT], 'ok')
        self.assertEqual(document['results_not_selected'], [HIT])
        self.assertEqual(document['results_disagree'], [])

    def test_a_rule_only_verdict_replaces_an_unselected_one_does_not_and_a_measured_alert_does(self):
        base = self.results('base', [replace(verdict(label, check=check, spell=spell), runs=['b1'], selected=True)
                                     for label, check, spell in ((HIT, 'hit_mean', SPELL),
                                                                 (VALUE, 'effect_value', SPELL),
                                                                 (PASSIVE, 'effect_value', OTHER_SPELL))])
        latest = self.results('latest', [
            replace(verdict(HIT, 'unmeasured'), runs=[], selected=False),
            replace(verdict(VALUE, 'unmodelled', 'unmodelled', explanation='unmodelled: the ledger changed'),
                    runs=[], selected=True),
            replace(verdict(PASSIVE, 'alert', 'effect_value', spell=OTHER_SPELL), runs=['l1'], selected=True)])
        document = audit_document(23, self.ledger, [latest], base_results=base)
        self.assertEqual([document['statuses'][label] for label in (HIT, VALUE, PASSIVE)],
                         ['ok', 'unmodelled', 'alert'])
        self.assertEqual(document['results_replaced'], [VALUE, PASSIVE])
        self.assertEqual(document['results_not_selected'], [HIT])
        self.assertEqual(document['results_disagree'], [])
        with mock.patch('audit.selected', lambda verdict: bool(verdict.runs)):
            self.assertEqual(audit_document(23, self.ledger, [latest], base_results=base)['statuses'][VALUE], 'ok')

    def test_a_kept_link_closed_by_the_base_is_resolved_again_over_a_later_alert(self):
        for detail in ({LINKED_FROM: 'unmodelled'}, None):
            with self.subTest(detail=detail):
                base = self.results(f'base-{detail is None}', [
                    replace(verdict(VALUE, 'closed', 'unmodelled', detail=detail,
                                    explanation=f'unmodelled: checked by triggers entry "Hit" (verdict "{HIT}" '
                                                f'(status ok))'), runs=[], selected=True),
                    replace(verdict(HIT), runs=['b1'], selected=True)])
                latest = self.results(f'latest-{detail is None}', [replace(verdict(HIT, 'alert'), runs=['l1'],
                                                                           selected=True)])
                document = audit_document(23, self.ledger, [latest], base_results=base)
                self.assertEqual(document['statuses'][VALUE], 'unmodelled')
                self.assertEqual(document['clauses'][1]['evidence'], 'unproven')
                with mock.patch('audit.relinked', lambda merged: [verdict for _, verdict in merged]):
                    self.assertEqual(audit_document(23, self.ledger, [latest], base_results=base)['statuses'][VALUE],
                                     'closed')

    def test_a_replacing_rule_only_link_closes_again_over_a_kept_conformant_label(self):
        link = f'unmodelled: checked by triggers entry "Hit" (verdict "{HIT}" (status unmeasured))'
        base = self.results('base', [
            replace(verdict(VALUE, 'closed', 'unmodelled', explanation=link.replace('unmeasured', 'ok'),
                            detail={LINKED_FROM: 'unmodelled'}), runs=[], selected=True),
            replace(verdict(HIT), runs=['b1'], selected=True)])
        latest = self.results('latest', [
            replace(verdict(VALUE, 'unmodelled', 'unmodelled', explanation=link, detail={LINKED_FROM: 'unmodelled'}),
                    runs=[], selected=True),
            replace(verdict(HIT, 'unmeasured'), runs=[], selected=False)])
        document = audit_document(23, self.ledger, [latest], base_results=base)
        self.assertEqual((document['statuses'][HIT], document['statuses'][VALUE]), ('ok', 'closed'))
        self.assertEqual(document['results_replaced'], [VALUE])
        self.assertEqual(document['results_not_selected'], [HIT])
        with mock.patch('audit.relinked', lambda merged: [verdict for _, verdict in merged]):
            self.assertEqual(audit_document(23, self.ledger, [latest], base_results=base)['statuses'][VALUE],
                             'unmodelled')

    def roll_layers(self, roll, name):
        base = self.results(f'base-{name}', [
            roll, replace(verdict(HIT), runs=['b1'], selected=True),
            replace(verdict(CONTRAST), runs=['b1'], selected=True)])
        latest = self.results(f'latest-{name}', [
            replace(verdict(ROLL, 'unmeasured', 'effect_value'), runs=[], selected=False),
            replace(verdict(HIT, 'alert'), runs=['l1'], selected=True)])
        return base, latest

    def test_a_base_roll_accepted_by_the_base_turns_alert_over_a_later_alert_on_its_power_term(self):
        links = {'power_term_label': HIT, 'contrast_label': CONTRAST}
        for roll_detail in ({**links, 'read_status': 'ok'}, links):
            with self.subTest(roll_detail=roll_detail):
                roll = replace(verdict(ROLL, 'ok', 'effect_value', explanation='base roll only',
                                       detail={BASE_ROLL_ONLY: roll_detail}), runs=['b1'], selected=True)
                base, latest = self.roll_layers(roll, len(roll_detail))
                document = audit_document(23, self.ledger, [latest], base_results=base)
                self.assertEqual((document['statuses'][HIT], document['statuses'][ROLL]), ('alert', 'alert'))
                self.assertEqual(document['results_not_selected'], [ROLL])
                with mock.patch('audit.resolve_base_roll_links', lambda verdicts, labels=None: verdicts):
                    self.assertEqual(audit_document(23, self.ledger, [latest], base_results=base)['statuses'][ROLL],
                                     'ok')

    def test_a_label_added_by_one_layer_is_also_listed_as_not_selected_by_a_later_one(self):
        latest = [self.results(name, [replace(verdict(PASSIVE, 'unmeasured', spell=OTHER_SPELL), runs=[],
                                              selected=False)]) for name in ('first', 'second')]
        document = audit_document(23, self.ledger, latest, base_results=self.results('base', [verdict(HIT)]))
        self.assertEqual((document['results_added'], document['results_not_selected']), ([PASSIVE], [PASSIVE]))

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

    def test_merge_skips_an_unselected_verdict_only_over_an_earlier_layer(self):
        merged = merged_verdicts([[verdict('a')], [replace(verdict('a', 'unmeasured'), runs=[]),
                                                  replace(verdict('b', 'unmeasured'), runs=[]),
                                                  replace(verdict('b', 'alert'), runs=[])]])
        self.assertEqual([(item.label, item.status) for item in merged], [('a', 'ok'), ('b', 'alert')])

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
