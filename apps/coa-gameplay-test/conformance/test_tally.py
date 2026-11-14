import json
from pathlib import Path
import tempfile
import unittest

from tally import (NOT_FINAL, Decisions, TallyError, TallyInputs, classify, flips, judge_changed, load_decisions,
                   status_markdown, tally, tally_lines, write_status)

FIXTURES = Path(__file__).resolve().parent / 'fixtures' / 'cycle'
RULING = 'mentor ruling on X 18:39, confirmed (c8 brief): status 3'
DECISIONS = Decisions({}, {'81.0': ('3', RULING)}, frozenset(), frozenset({'125.2', '273.1'}))
LABEL = '900001 behaviour_metric_delta probe'
KEY = ('behaviour_metric_delta', 'scenario-a')


def pair_inputs(name: str, decisions: Decisions = DECISIONS, record_status: Path | None = None) -> TallyInputs:
    pair = FIXTURES / name
    return TallyInputs(FIXTURES / 'clauses.json', record_status or FIXTURES / 'record-status.json',
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
        self.assertEqual((row['record_status'], row['status'], row['basis']), ('1', '1', 'kept'))
        self.assertEqual(result['record_final'], 13)
        self.assertEqual([row['key'] for row in result['gained']], [])

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


class FlipRuleTest(unittest.TestCase):
    def check(self, pair, record=None, old_sha=None, now_sha=None, changed=frozenset()):
        new_runs = [{LABEL: {KEY: status}} if status else {} for status in pair]
        old_runs = [{LABEL: {KEY: status}} if status else {} for status in (record or [None, None])]
        sha = {'scenario-a': 'x'}
        return flips([LABEL], new_runs, old_runs, sha if old_sha is None else old_sha,
                     sha if now_sha is None else now_sha, changed)

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

    def test_the_pair_flips_against_the_record(self):
        _, against = self.check(['alert', 'alert'], ['ok', 'ok'])
        self.assertEqual(against, [{'label': LABEL, 'check': KEY[0], 'scenario': KEY[1], 'record': ['ok', 'ok'],
                                    'pair': ['alert', 'alert']}])

    def test_a_changed_scenario_or_judge_is_not_compared_with_the_record(self):
        self.assertEqual(self.check(['alert', 'alert'], ['ok', 'ok'], now_sha={'scenario-a': 'y'}), ([], []))
        self.assertEqual(self.check(['alert', 'alert'], ['ok', 'ok'], changed={LABEL}), ([], []))

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
            path.write_text(json.dumps({'rulings': {'2.0': {'status': 6}}}), encoding='utf-8')
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
