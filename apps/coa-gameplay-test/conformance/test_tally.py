import json
from pathlib import Path
import tempfile
import unittest

from tally import (NOT_FINAL, Decisions, TallyError, TallyInputs, check_decisions, classify, flips, judge_changed,
                   label_statuses, labels_pass, ledger_keys, load_decisions, match_line, record_match, record_rows,
                   record_verdicts, status_markdown, tally, tally_lines, verdict_line, write_status)

FIXTURES = Path(__file__).resolve().parent / 'fixtures' / 'cycle'
RULING = 'mentor ruling on X 18:39, confirmed (c8 brief): status 3'
DECISIONS = Decisions({}, {'81.0': ('3', RULING)}, frozenset(), frozenset({'125.2'}))
LABEL = '900001 behaviour_metric_delta probe'
VALUE_LABEL = '301303 effect_value e0 #0'
NO_SKIPPED_VERDICT = {'no_scenario_file': 0, 'other': 0, 'other_verdicts': []}
KEY = ('behaviour_metric_delta', 'scenario-a')


def pair_inputs(name: str, decisions: Decisions = DECISIONS, record_status: Path | None = None,
                ledger: Path | None = None) -> TallyInputs:
    pair = FIXTURES / name
    return TallyInputs(ledger or FIXTURES / 'clauses.json', record_status or FIXTURES / 'record-status.json',
                       (FIXTURES / 'record' / 'cmp-run1', FIXTURES / 'record' / 'cmp-run2'),
                       FIXTURES / 'record' / 'manifest.json', (pair / 'cmp-run1', pair / 'cmp-run2'),
                       (pair / 'coverage-run1.json', pair / 'coverage-run2.json'), pair / 'manifest.json', decisions)


def recorded(name: str) -> list:
    return json.loads((FIXTURES / f'{name}-status.json').read_text(encoding='utf-8'))


def by_key(result: dict) -> dict:
    return {row['key']: row for row in result['rows']}


class RecordedPairTest(unittest.TestCase):
    def test_the_c17_pair_reproduces_its_recorded_rows_with_the_389_flip(self):
        result = tally(pair_inputs('final15'))
        self.assertEqual(result['rows'], recorded('final15'))
        self.assertEqual(result['counts'], {'1': 8, '2': 4, '3': 1, NOT_FINAL: 1})
        self.assertEqual([row['key'] for row in result['lost']], ['389.0'])
        self.assertEqual(result['flips_in_pair'], ['389.0'])
        self.assertEqual(result['flips_vs_record'], ['389.0'])
        self.assertEqual(result['judge_changed'], ['503740 behaviour_metric_delta frenzied_snare_immune'])

    def test_the_c18_pair_reproduces_its_recorded_rows_without_a_flip(self):
        result = tally(pair_inputs('final16'))
        self.assertEqual(result['rows'], recorded('final16'))
        self.assertEqual(result['counts'], {'1': 9, '2': 4, '3': 1})
        self.assertEqual((result['final'], result['record_final'], result['total']), (14, 14, 14))
        self.assertEqual((result['flips_in_pair'], result['flips_vs_record'], result['lost']), ([], [], []))

    def test_a_ruling_sets_its_status_and_keeps_alerting_labels_as_evidence(self):
        row = by_key(tally(pair_inputs('final16')))['81.0']
        self.assertEqual((row['status'], row['basis']), ('3', 'ruled'))
        self.assertTrue(row['detail'].startswith(RULING + '; alerting labels kept as evidence: '))

    def test_an_unlisted_text_change_stops_the_tally(self):
        decisions = Decisions({}, DECISIONS.rulings, frozenset(), frozenset())
        with self.assertRaisesRegex(TallyError, '125.2'):
            tally(pair_inputs('final16', decisions))

    def test_the_lines_name_the_lost_claim_and_the_flips(self):
        lines = tally_lines(tally(pair_inputs('final15')))
        self.assertIn("14 {'1': 8, '2': 4, '3': 1, 'not final': 1} record 14 final 13", lines)
        self.assertTrue(any(line.startswith('LOST 389.0 flip ') for line in lines))
        self.assertIn('FLIP 389.0', lines)
        self.assertIn('FLIP-RECORD 389.0', lines)


class RecordDecisionTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        rows = recorded('record')
        for row in rows:
            if row['key'] in ('0.0', '26.0'):
                row.update({'status': NOT_FINAL, 'detail': 'before the fix'})
        self.record = Path(self.directory.name) / 'record.json'
        self.record.write_text(json.dumps(rows), encoding='utf-8')

    def tearDown(self):
        self.directory.cleanup()

    def test_a_record_claim_not_final_stays_carried_without_a_decision(self):
        rows = by_key(tally(pair_inputs('final16', record_status=self.record)))
        self.assertEqual((rows['0.0']['status'], rows['0.0']['basis']), (NOT_FINAL, 'carried'))
        self.assertEqual(rows['0.0']['detail'], 'before the fix')

    def test_a_ledger_only_re_audit_correction_counts_at_once(self):
        decisions = Decisions({}, DECISIONS.rulings, frozenset({'0.0'}), DECISIONS.text_changed)
        result = tally(pair_inputs('final16', decisions, self.record))
        row = by_key(result)['0.0']
        self.assertEqual((row['record_status'], row['status'], row['basis']), (NOT_FINAL, '1', 'counted'))
        self.assertEqual(result['record_final'], 12)
        self.assertEqual([row['key'] for row in result['gained']], ['0.0'])

    def test_a_recorded_status_3_to_5_claim_without_a_ruling_stops_the_tally(self):
        rows = recorded('record')
        next(row for row in rows if row['key'] == '29.0')['status'] = '4'
        self.record.write_text(json.dumps(rows), encoding='utf-8')
        with self.assertRaisesRegex(TallyError, r"without a ruling.*'29.0'"):
            tally(pair_inputs('final16', record_status=self.record))

    def test_an_unknown_decision_key_stops_the_tally_and_names_the_key(self):
        cases = {'999.0': Decisions({'999.0': 'typo'}, DECISIONS.rulings, frozenset(), DECISIONS.text_changed),
                 '81.9': Decisions({}, {**DECISIONS.rulings, '81.9': ('3', 'typo')}, frozenset(),
                                   DECISIONS.text_changed),
                 '0.9': Decisions({}, DECISIONS.rulings, frozenset({'0.9'}), DECISIONS.text_changed)}
        for key, decisions in cases.items():
            with self.assertRaisesRegex(TallyError, f"no claim of this ledger: \\['{key}'\\]"):
                tally(pair_inputs('final16', decisions))

    def test_a_ruling_of_status_2_stands_over_a_flip_and_the_flip_stays_listed(self):
        decisions = Decisions({}, {**DECISIONS.rulings, '389.0': ('2', 'owner ruling')}, frozenset(),
                              DECISIONS.text_changed)
        result = tally(pair_inputs('final15', decisions))
        row = by_key(result)['389.0']
        self.assertEqual((row['status'], row['basis']), ('2', 'ruled'))
        self.assertEqual((result['flips_in_pair'], result['flips_vs_record']), (['389.0'], ['389.0']))

    def test_the_key_of_a_new_claim_is_a_known_decision_key(self):
        record = record_rows(FIXTURES / 'record-status.json')
        rows = [row for row in json.loads((FIXTURES / 'clauses.json').read_text(encoding='utf-8'))
                if row['kind'] == 'claim']
        keys = ledger_keys([*rows, {'clause': 'a new claim', 'spell': 1}], record)
        self.assertEqual(keys[(7, 0)], 'new 7.0')
        check_decisions(keys, record, Decisions({'new 7.0': 'cycle 19 entry'}, DECISIONS.rulings, frozenset(),
                                                DECISIONS.text_changed))

    def test_a_record_row_no_ledger_claim_reaches_is_lost_and_counted(self):
        ledger = json.loads((FIXTURES / 'clauses.json').read_text(encoding='utf-8'))
        row = [row for row in ledger if row['kind'] == 'claim'][2]
        row['claims'] = row['claims'][:2]
        path = Path(self.directory.name) / 'clauses.json'
        path.write_text(json.dumps(ledger), encoding='utf-8')
        result = tally(pair_inputs('final16', ledger=path))
        self.assertEqual((result['total'], result['final'], result['record_final']), (13, 13, 14))
        self.assertEqual([(row['key'], row['basis']) for row in result['lost']], [('26.2', 'missing')])
        lines = tally_lines(result)
        self.assertIn('13 {\'1\': 9, \'2\': 3, \'3\': 1} record 14 final 13', lines)
        self.assertIn('LOST 26.2 missing record row 2.2 reached by no ledger claim', lines)

    def test_a_candidate_with_behaviour_and_conformant_labels_gains_status_1(self):
        decisions = Decisions({'0.0': 'cycle 19 entry'}, DECISIONS.rulings, frozenset(),
                              DECISIONS.text_changed)
        result = tally(pair_inputs('final16', decisions, self.record))
        rows = by_key(result)
        self.assertEqual((rows['0.0']['status'], rows['0.0']['basis']), ('1', 'candidate'))
        self.assertTrue(rows['0.0']['detail'].startswith('cycle 19 entry; behaviour both runs'))
        self.assertEqual([row['key'] for row in result['gained']], ['0.0'])
        self.assertEqual((rows['26.0']['status'], rows['26.0']['basis']), (NOT_FINAL, 'carried'))

    def test_a_flipping_candidate_is_not_final(self):
        decisions = Decisions({'389.0': 'cycle 18 entry'}, DECISIONS.rulings, frozenset(), DECISIONS.text_changed)
        row = by_key(tally(pair_inputs('final15', decisions)))['389.0']
        self.assertEqual((row['status'], row['basis']), (NOT_FINAL, 'flip'))


class RecordMatchTest(unittest.TestCase):
    def rewritten(self, name: str, change) -> Path:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        manifest = json.loads((FIXTURES / name / 'manifest.json').read_text(encoding='utf-8'))
        change(manifest)
        path = Path(self.directory.name) / 'manifest.json'
        path.write_text(json.dumps(manifest), encoding='utf-8')
        return path

    def inputs(self, name: str, manifest: Path) -> TallyInputs:
        values = pair_inputs(name)
        return TallyInputs(values.ledger, values.record_status, values.record_compare, values.record_manifest,
                           values.compare, values.coverage, manifest, values.decisions)

    def test_a_rehashed_scenario_is_compared_with_the_record_by_entry_and_label(self):
        def rehash(manifest):
            for scenario in manifest['scenarios']:
                scenario['sha256'] = 'rehashed-' + scenario['sha256']
        result = tally(self.inputs('final15', self.rewritten('final15', rehash)))
        self.assertEqual(result['flips_vs_record'], ['389.0'])
        self.assertEqual(result['record_scenarios'], {'matched': 22, 'unmatched': 0, 'unmatched_scenarios': []})
        self.assertEqual(result['record_verdicts'], NO_SKIPPED_VERDICT)

    def test_a_record_scenario_missing_from_the_pair_is_counted_as_unmatched(self):
        def drop(manifest):
            manifest['scenarios'] = manifest['scenarios'][1:]
        result = tally(self.inputs('final16', self.rewritten('final16', drop)))
        self.assertEqual(result['record_scenarios'], {'matched': 21, 'unmatched': 1,
                                                      'unmatched_scenarios': ['conformance-necromancer-value-301303']})
        self.assertTrue(match_line(result['record_scenarios']).startswith(
            'WARNING record scenarios matched by entry and label: 21, UNMATCHED: 1, not compared with the record'))

    def test_a_record_scenario_without_its_label_in_the_pair_is_unmatched(self):
        def relabel(manifest):
            manifest['scenarios'][0]['expectations'][0]['label'] += ' renamed'
        record = json.loads((FIXTURES / 'record' / 'manifest.json').read_text(encoding='utf-8'))
        now = json.loads(self.rewritten('final16', relabel).read_text(encoding='utf-8'))
        self.assertEqual(record_match(record, now)['unmatched_scenarios'], ['conformance-necromancer-value-301303'])


class RecordVerdictTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)

    def with_verdicts(self, source: Path, name: str, added: list) -> Path:
        out = self.root / name
        out.mkdir()
        document = json.loads((source / 'verdicts.json').read_text(encoding='utf-8'))
        document['verdicts'] += added
        (out / 'verdicts.json').write_text(json.dumps(document), encoding='utf-8')
        return out

    def inputs(self, scenario: str, record_status: str, pair_status: str, file_less: bool) -> TallyInputs:
        values = pair_inputs('final16')
        verdict = {'label': VALUE_LABEL, 'check': 'effect_value', 'scenario': scenario}
        record = tuple(self.with_verdicts(path, f'record-{index}', [{**verdict, 'status': record_status}])
                       for index, path in enumerate(values.record_compare))
        pair = tuple(self.with_verdicts(path, f'pair-{index}', [{**verdict, 'status': pair_status}])
                     for index, path in enumerate(values.compare))
        manifest = json.loads(values.record_manifest.read_text(encoding='utf-8'))
        if file_less:
            manifest['scenarios'].append({'key': scenario, 'sha256': None, 'expectations': [
                {'label': VALUE_LABEL, 'check': 'effect_value'}]})
        record_manifest = self.root / 'record-manifest.json'
        record_manifest.write_text(json.dumps(manifest), encoding='utf-8')
        return TallyInputs(values.ledger, values.record_status, record, record_manifest, pair, values.coverage,
                           values.manifest, values.decisions)

    def test_a_file_less_closed_record_verdict_is_counted_as_not_compared(self):
        result = tally(self.inputs('conformance-necromancer-unmodelled-301303', 'closed', 'alert', file_less=True))
        self.assertEqual(result['flips_vs_record'], [])
        self.assertEqual(result['record_verdicts'], {'no_scenario_file': 1, 'other': 0, 'other_verdicts': []})
        self.assertEqual(verdict_line(result['record_verdicts']),
                         'record verdicts not compared with the record: no scenario file 1, other 0')

    def test_a_record_verdict_naming_no_manifest_scenario_is_other_and_warned(self):
        result = tally(self.inputs('derived-301303', 'ok', 'alert', file_less=False))
        self.assertEqual(result['record_scenarios']['unmatched'], 0)
        self.assertEqual(result['record_verdicts'], {'no_scenario_file': 0, 'other': 1, 'other_verdicts': [
            [VALUE_LABEL, 'effect_value', 'derived-301303']]})
        self.assertEqual(verdict_line(result['record_verdicts']),
                         'WARNING record verdicts not compared with the record: no scenario file 0, OTHER 1 '
                         f'({VALUE_LABEL} | effect_value | derived-301303)')

    def test_a_verdict_check_without_its_expectation_is_other(self):
        matched = {(LABEL, 'other_check', 'scenario-a')}
        old_runs = [{LABEL: {KEY: 'ok'}}] * 2
        self.assertEqual(record_verdicts([LABEL], [{}, {}], old_runs, matched, set())['other'], 1)
        self.assertEqual(record_verdicts([LABEL], [{}, {}], old_runs, {(LABEL, *KEY)}, set()),
                         NO_SKIPPED_VERDICT)

    def test_a_pooled_record_verdict_is_file_less_only_when_every_part_is(self):
        pooled = {LABEL: {(KEY[0], 'part-1 + part-2'): 'closed'}}
        self.assertEqual(record_verdicts([LABEL], [{}, {}], [pooled] * 2, set(), {'part-1', 'part-2'})
                         ['no_scenario_file'], 1)
        self.assertEqual(record_verdicts([LABEL], [{}, {}], [pooled] * 2, set(), {'part-1'})['other'], 1)


class FlipRuleTest(unittest.TestCase):
    def check(self, pair, record=None, matched=None, changed=frozenset(), key=KEY):
        new_runs = [{LABEL: {key: status}} if status else {} for status in pair]
        old_runs = [{LABEL: {key: status}} if status else {} for status in (record or [None, None])]
        return flips([LABEL], new_runs, old_runs, {(LABEL, *KEY)} if matched is None else matched, changed)

    def test_ok_against_tolerated_is_not_a_flip(self):
        self.assertEqual(self.check(['ok', 'tolerated'], ['closed', 'ok']), ([], []))

    def test_conformant_against_non_conformant_flips_within_the_pair(self):
        inside, _ = self.check(['ok', 'unmeasured'])
        self.assertEqual(inside, [{'label': LABEL, 'check': KEY[0], 'scenario': KEY[1],
                                   'statuses': ['ok', 'unmeasured']}])

    def test_a_label_in_one_run_only_flips(self):
        inside, _ = self.check(['ok', None])
        self.assertEqual(len(inside), 1)

    def test_an_unjudged_run_is_not_a_flip(self):
        self.assertEqual(self.check(['ok', 'insufficient_trials']), ([], []))

    def test_a_scenario_missing_from_both_runs_flips_against_the_record(self):
        self.assertEqual(self.check([None, None], ['ok', 'ok']),
                         ([], [{'label': LABEL, 'check': KEY[0], 'scenario': KEY[1], 'record': ['ok', 'ok'],
                                'pair': [None, None]}]))

    def test_the_pair_flips_against_the_record(self):
        _, against = self.check(['alert', 'alert'], ['ok', 'ok'])
        self.assertEqual(against, [{'label': LABEL, 'check': KEY[0], 'scenario': KEY[1], 'record': ['ok', 'ok'],
                                    'pair': ['alert', 'alert']}])

    def test_an_unmatched_scenario_or_a_changed_judge_is_not_compared_with_the_record(self):
        self.assertEqual(self.check(['alert', 'alert'], ['ok', 'ok'], matched=set()), ([], []))
        self.assertEqual(self.check(['alert', 'alert'], ['ok', 'ok'], changed={LABEL}), ([], []))

    def test_a_pooled_scenario_matches_only_when_every_part_matches(self):
        pooled = (KEY[0], 'part-1 + part-2')
        both = {(LABEL, KEY[0], 'part-1'), (LABEL, KEY[0], 'part-2')}
        self.assertEqual(len(self.check(['alert', 'alert'], ['ok', 'ok'], both, key=pooled)[1]), 1)
        self.assertEqual(self.check(['alert', 'alert'], ['ok', 'ok'], both - {(LABEL, KEY[0], 'part-2')},
                                    key=pooled), ([], []))

    def test_an_ordinal_free_label_reaches_its_ordinal_run_labels(self):
        runs = [{f'{LABEL} #0': {KEY: 'ok'}, f'{LABEL} #1': {KEY: 'tolerated'}, f'{LABEL} #1x': {KEY: 'alert'}}] * 2
        self.assertEqual(label_statuses(runs, [LABEL]), {LABEL: [['ok', 'tolerated'], ['ok', 'tolerated']]})
        self.assertEqual(labels_pass(runs, [LABEL]), (True, {}))
        self.assertEqual(label_statuses(runs, [f'{LABEL} #2']), {f'{LABEL} #2': [[], []]})
        flipping = [{f'{LABEL} #1': {KEY: 'ok'}}, {f'{LABEL} #1': {KEY: 'unmeasured'}}]
        inside, _ = flips([LABEL], flipping, [{}, {}], set(), frozenset())
        self.assertEqual(inside, [{'label': f'{LABEL} #1', 'check': KEY[0], 'scenario': KEY[1],
                                   'statuses': ['ok', 'unmeasured']}])

    def test_judge_changed_names_changed_expectations_and_new_value_links(self):
        old = {'class_file': {}, 'scenarios': [{'key': 'a', 'expectations': [{'label': LABEL, 'low': 1}]}]}
        now = {'class_file': {'value_links': [{'label': 'linked'}]},
               'scenarios': [{'key': 'a', 'expectations': [{'label': LABEL, 'low': 2}]}]}
        self.assertEqual(judge_changed(old, now), {LABEL, 'linked'})

    def test_a_status_2_claim_keeps_its_recorded_evidence_kind(self):
        rec = {'key': 'k', 'evidence': 'data', 'labels': [], 'flips_in_pair': [], 'flips_vs_record': [],
               'run1': 'data', 'run2': 'data'}
        prior = {'status': '2', 'evidence': 'data', 'detail': 'rounding rule'}
        self.assertEqual(classify(rec, prior, [{}, {}], DECISIONS), ('2', 'kept', 'rounding rule'))
        self.assertEqual(classify({**rec, 'evidence': 'unproven'}, prior, [{}, {}], DECISIONS)[:2],
                         (NOT_FINAL, 'lost'))


class DecisionFileTest(unittest.TestCase):
    def test_decisions_are_read_by_claim_key(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'decisions.json'
            path.write_text(json.dumps({'candidates': {'1.0': 'why'}, 'rulings': {'2.0': {'status': 5, 'why': 'q'}},
                                        'counted': ['3.0'], 'text_changed': ['4.0']}), encoding='utf-8')
            self.assertEqual(load_decisions(path), Decisions({'1.0': 'why'}, {'2.0': ('5', 'q')},
                                                             frozenset({'3.0'}), frozenset({'4.0'})))
            for status in (6, 1, '1'):
                path.write_text(json.dumps({'rulings': {'2.0': {'status': status}}}), encoding='utf-8')
                with self.assertRaisesRegex(TallyError, 'status'):
                    load_decisions(path)
            path.write_text(json.dumps({'candidate': {}}), encoding='utf-8')
            with self.assertRaisesRegex(TallyError, 'unknown'):
                load_decisions(path)

    def test_no_decision_file_means_no_decisions(self):
        self.assertEqual(load_decisions(None), Decisions({}, {}, frozenset(), frozenset()))


class StatusFileTest(unittest.TestCase):
    def test_the_status_files_hold_the_rows_and_the_count(self):
        result = tally(pair_inputs('final16'))
        with tempfile.TemporaryDirectory() as directory:
            json_path, markdown_path = Path(directory) / 's.json', Path(directory) / 's.md'
            write_status(result, json_path, markdown_path, 'final16')
            self.assertEqual(json.loads(json_path.read_text(encoding='utf-8')), recorded('final16'))
            self.assertIn('Final: **14 / 14 = 100.0%**; record 14.', markdown_path.read_text(encoding='utf-8'))
        self.assertIn('| 389.0 | 503740 | 1 | kept | behaviour | 1 |', status_markdown(result, 't'))


if __name__ == '__main__':
    unittest.main()
