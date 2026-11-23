import json
from pathlib import Path
import shutil
import tempfile
import unittest

from compare import Verdict
from coverage import CONSUMED, K3, NOT_CONSUMED, EvidenceError, load_consumption
from k3 import ProbeError, Probe, k3_rows, literal_modifier_sites, load_probes, merge_consumption
from mutants import Mutant

BUILD = 'b' * 64
OTHER_BUILD = 'c' * 64
OBSERVATION = '1000002 behaviour_count'
READBACK = '1000001 effect_value e0 #0'
MUTANTS = [Mutant(OBSERVATION, 1000001, 'effect1', 0.0)]
PROBE = Probe(READBACK, 1000001, 0, OBSERVATION, OBSERVATION)
PREDICTED = Probe(READBACK, 1000001, 0, OBSERVATION, OBSERVATION, 0.0)


def observation(status, measured=2.0, expected=2.0, check='behaviour_count', label=OBSERVATION):
    return Verdict(label, status, measured, expected, expected, expected, '', 'scenario', 1000001, 1000001, check)


def run(*verdicts, build=BUILD):
    return {'build': build}, list(verdicts)


class ProbeFileTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.directory, True)

    def write(self, document) -> Path:
        path = self.directory / 'probes.json'
        path.write_text(json.dumps(document), encoding='utf-8')
        return path

    def test_probe_reads_its_fields_and_defaults_the_mutant_to_the_observation(self):
        probes = load_probes(self.write([{'label': 'r', 'spell': 1, 'effect': 0, 'observation': 'o',
                                          'predicted': 16}]))
        self.assertEqual(probes, [Probe('r', 1, 0, 'o', 'o', 16.0)])

    def test_refusals(self):
        good = {'label': 'r', 'spell': 1, 'effect': 0, 'observation': 'o'}
        for document in ([], {}, [{**good, 'extra': 1}], [{'label': 'r'}], [{**good, 'spell': '1'}],
                         [{**good, 'effect': -1}], [{**good, 'label': ''}], [good, good],
                         [{**good, 'predicted': '0.8'}], [{**good, 'predicted': True}]):
            with self.subTest(document=document), self.assertRaises(ProbeError):
                load_probes(self.write(document))


class ResultTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root, True)
        (self.root / 'AscensionSample.cpp').write_text('float chance = 20.0f;\n', encoding='utf-8')

    def rows(self, baseline, mutant, probe=PROBE, mutants=MUTANTS):
        return k3_rows([probe], mutants, [run(*verdicts) for verdicts in baseline],
                       [run(*verdicts) for verdicts in mutant], 'evidence.json', self.root)

    def test_a_mutant_that_alerts_in_every_run_is_consumed(self):
        rows, outcomes = self.rows([[observation('ok')]] * 2, [[observation('alert', 0.0)]] * 2)
        self.assertEqual(rows, [{'label': READBACK, 'route': K3, 'spell': 1000001, 'effect': 0, 'build': BUILD,
                                 'evidence': 'evidence.json', 'result': CONSUMED}])
        self.assertEqual(outcomes[0]['measured'], [0.0, 0.0])

    def test_seeded_alert_without_a_measured_reading_is_never_consumed(self):
        rows, outcomes = self.rows([[observation('ok')]] * 2, [[observation('alert', None)]] * 2)
        self.assertEqual(rows, [])
        self.assertIn('without a measured value', outcomes[0]['reason'])

    def test_one_alert_and_one_conformant_run_writes_no_row(self):
        rows, _ = self.rows([[observation('ok')]] * 2, [[observation('alert', 0.0)], [observation('ok')]])
        self.assertEqual(rows, [])

    def test_a_separable_prediction_that_stays_conformant_is_not_consumed(self):
        rows, outcomes = self.rows([[observation('ok')]] * 2, [[observation('ok')]] * 2, PREDICTED)
        self.assertEqual([row['result'] for row in rows], [NOT_CONSUMED])
        self.assertEqual((outcomes[0]['predicted'], outcomes[0]['expected']), (0.0, 2.0))

    def test_a_conformant_mutant_without_a_prediction_writes_no_row(self):
        rows, outcomes = self.rows([[observation('ok')]] * 2, [[observation('ok')]] * 2)
        self.assertEqual(rows, [])
        self.assertIn('no predicted reading', outcomes[0]['reason'])

    def test_seeded_prediction_inside_the_tolerance_is_never_not_consumed(self):
        inside = Probe(READBACK, 1000001, 0, OBSERVATION, OBSERVATION, 1.995)
        rows, outcomes = self.rows([[observation('ok')]] * 2, [[observation('ok')]] * 2, inside)
        self.assertEqual(rows, [])
        self.assertIn('within the tolerance of the expected 2', outcomes[0]['reason'])

    def test_an_observation_that_reads_back_a_value_never_shows_consumption(self):
        readback = [observation('ok', check='effect_value')]
        rows, outcomes = self.rows([readback] * 2, [[observation('alert', 0.0, check='effect_value')]] * 2)
        self.assertEqual(rows, [])
        self.assertIn('observes no acting outcome', outcomes[0]['reason'])

    def test_a_baseline_that_is_not_conformant_in_every_run_writes_no_row(self):
        rows, outcomes = self.rows([[observation('ok')], [observation('alert', 0.0)]],
                                   [[observation('alert', 0.0)]] * 2)
        self.assertEqual(rows, [])
        self.assertIn('baseline run 2 is alert', outcomes[0]['reason'])

    def test_a_literal_passed_through_the_modifier_channel_writes_no_row(self):
        (self.root / 'AscensionSample.cpp').write_text('player->ApplySpellMod(1000001, SPELLMOD_CHANCE_OF_SUCCESS, '
                                                        'chance);\n', encoding='utf-8')
        rows, outcomes = self.rows([[observation('ok')]] * 2, [[observation('alert', 0.0)]] * 2)
        self.assertEqual(rows, [])
        self.assertIn('AscensionSample.cpp:1', outcomes[0]['reason'])

    def test_literal_sites_match_the_spell_id_only(self):
        (self.root / 'AscensionSample.cpp').write_text('ApplySpellMod(10000011, SPELLMOD_DURATION, d);\n'
                                                        'ApplySpellMod( 1000001, SPELLMOD_DURATION, d);\n',
                                                        encoding='utf-8')
        self.assertEqual(literal_modifier_sites(1000001, self.root), ['AscensionSample.cpp:2'])

    def test_a_probe_whose_mutant_label_has_no_mutant_writes_no_row(self):
        rows, outcomes = self.rows([[observation('ok')]] * 2, [[observation('alert', 0.0)]] * 2,
                                   mutants=[Mutant('other', 1000001, 'effect1', 0.0)])
        self.assertEqual(rows, [])
        self.assertIn('no single mutant', outcomes[0]['reason'])

    def test_runs_of_two_builds_are_refused(self):
        with self.assertRaises(ProbeError):
            k3_rows([PROBE], MUTANTS, [run(observation('ok'))] * 2,
                    [run(observation('alert', 0.0), build=OTHER_BUILD)] * 2, 'e', self.root)

    def test_one_run_per_side_is_refused(self):
        with self.assertRaises(ProbeError):
            k3_rows([PROBE], MUTANTS, [run(observation('ok'))], [run(observation('alert', 0.0))], 'e', self.root)


class MergeTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.directory, True)

    def row(self, label=READBACK, build=BUILD, result=CONSUMED):
        return {'label': label, 'route': K3, 'spell': 1000001, 'effect': 0, 'build': build, 'evidence': 'e',
                'result': result}

    def test_a_rerun_replaces_the_row_of_its_build_and_keeps_others(self):
        path = self.directory / 'templar_consumption.json'
        merge_consumption(path, [self.row(), self.row(build=OTHER_BUILD)])
        merge_consumption(path, [self.row(result=NOT_CONSUMED)])
        rows = load_consumption(path)
        self.assertEqual(sorted((row.build, row.result) for row in rows),
                         [(BUILD, NOT_CONSUMED), (OTHER_BUILD, CONSUMED)])

    def test_seeded_wrong_route_is_refused_on_load(self):
        path = self.directory / 'templar_consumption.json'
        path.write_text(json.dumps([{**self.row(), 'route': 'K1K2'}]), encoding='utf-8')
        with self.assertRaises(EvidenceError):
            load_consumption(path)


if __name__ == '__main__':
    unittest.main()
