import copy
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from compare import STATUSES, Verdict, alert_rows, change_decision, compare, write_levers
from profile import DBC_DIR
from stack import (MEASURED, STACK_DPS, STACK_SOURCE, TALENT_DELTA, Lever, levers, mean_interval, ratio_interval,
                   stack_scenarios, student_t_quantile)
from test_compare import CLASS_FILE, Workspace, assert_step, constant_reader
from tooltip import Displayed, Records
from values import Expectation, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import batch

ARGENT_BLADE = 807268
SCARLET_HAMMER = 807035
SCOURGEBANE_STRIKE = 801832
RETRIBUTION_STRIKE = 525028
PALADIN_TRAINING = 520009
DIVINE_STRIKES = 705255
MARTIAL_TRAINING = 806525
BASE = 'c0_base'
PALADIN = 'c1_paladin_training'
DIVINE = 'c2_divine_strikes'
CONFIGS = ['c0_base', 'c1_paladin_training', 'c2_divine_strikes', 'c3_lights_echo', 'c4_warrior_of_dawn',
           'c5_retribution', 'c6_legacy_purefocus', 'c7_scarlet']
TALENTS_2026_11_05 = [[], [520009], [705255], [520017, 520883], [560648, 520608], [707391],
                      [806522, 705253, 707852], [301065, 520812, 806525]]
DELTA_LABEL = f'stack {PALADIN} talent_delta {PALADIN_TRAINING} {ARGENT_BLADE}'
ROTATION_MS = 120000
PLAIN = {'total': f'stack source {ARGENT_BLADE} plain total', 'count': f'stack source {ARGENT_BLADE} plain count'}
HEALTH = {'health_start': 'stack target health start', 'health_end': 'stack target health end'}
SOURCE_LABELS = {'total': f'stack source {ARGENT_BLADE} total', 'count': f'stack source {ARGENT_BLADE} count'}
WITHOUT_TUNING = {'known_aura 887007': '0'}
BASE_MEANS = [100.0, 100.2, 99.8, 100.1, 99.9]
PALADIN_MEANS = [120.0, 120.2, 119.8, 120.1, 119.9]
WIDE_BASE_MEANS = [100.0, 101.0, 99.0, 100.5, 99.5]
WIDE_PALADIN_MEANS = [120.0, 121.0, 119.0, 120.5, 119.5]


def learned(scenario):
    return [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']


def by_config(scenarios):
    grouped = {}
    for scenario, expectations in scenarios:
        config = next(expectation for expectation in expectations if expectation.check == STACK_DPS).model['config']
        grouped.setdefault(config, []).append((scenario, expectations))
    return grouped


def dps_expectation(config, index, passes=5, talents=()):
    return Expectation(f'stack {config} dps', STACK_DPS, 0, 0, None, '', 'measured: target health lost',
                       {'config': config, 'index': index, 'passes': passes, 'talents': list(talents),
                        'rotation_ms': ROTATION_MS, 'measurements': HEALTH})


def source_expectation(config, index, passes=5):
    return Expectation(f'stack {config} source {ARGENT_BLADE}', STACK_SOURCE, ARGENT_BLADE, ARGENT_BLADE, None, '',
                       'measured: damage of the source', {'config': config, 'index': index, 'passes': passes,
                                                          'rotation_ms': ROTATION_MS, 'source': ARGENT_BLADE,
                                                          'measurements': SOURCE_LABELS})


def delta_expectation(passes=5, bonus=20.0, earlier=()):
    return Expectation(DELTA_LABEL, TALENT_DELTA, PALADIN_TRAINING, PALADIN_TRAINING, 0, '$s1',
                       'ratio: per-hit damage', {'config': PALADIN, 'baseline': BASE, 'index': 1, 'passes': passes,
                                                 'source': ARGENT_BLADE, 'bonus_pct': bonus, 'token': '$s1',
                                                 'effect': 0, 'composition': 'ratio', 'school_mask': 1,
                                                 'earlier_bonuses': list(earlier), 'measurements': PLAIN})


def pass_steps(hits, hit_mean, lost=60000.0):
    return [assert_step(HEALTH['health_start'], '50000000'), assert_step(HEALTH['health_end'], str(50000000 - lost)),
            assert_step(SOURCE_LABELS['total'], str(hits * hit_mean * 1.1)), assert_step(SOURCE_LABELS['count'],
                                                                                        str(hits + 3)),
            assert_step(PLAIN['total'], str(hits * hit_mean)), assert_step(PLAIN['count'], str(hits))]


def bonus_reader(value=20.0, text='$s1'):
    return constant_reader(Displayed(text, value, 0, 'percent'))


class IntervalTest(unittest.TestCase):
    def test_student_quantiles_match_the_tables(self):
        self.assertAlmostEqual(student_t_quantile(0.995, 1), 63.657, places=2)
        self.assertAlmostEqual(student_t_quantile(0.995, 4), 4.604, places=3)
        self.assertAlmostEqual(student_t_quantile(0.995, 30), 2.750, places=3)
        self.assertAlmostEqual(student_t_quantile(0.995, float('inf')), 2.576, places=3)

    def test_mean_interval_of_five_passes_uses_four_degrees_of_freedom(self):
        mean, low, high = mean_interval([10.0, 12.0, 11.0, 9.0, 13.0])
        self.assertAlmostEqual(mean, 11.0)
        half = 4.604 * (2.5 ** 0.5) / 5 ** 0.5
        self.assertAlmostEqual(high - mean, half, places=2)
        self.assertAlmostEqual(mean - low, half, places=2)

    def test_identical_passes_have_a_zero_width_interval(self):
        self.assertEqual(mean_interval([5.0, 5.0, 5.0]), (5.0, 5.0, 5.0))
        for value in ratio_interval([12.0, 12.0], [10.0, 10.0]):
            self.assertAlmostEqual(value, 20.0)

    def test_ratio_interval_is_centred_on_the_ratio_of_the_means(self):
        delta, low, high = ratio_interval([118.0, 120.0, 122.0], [99.0, 100.0, 101.0])
        self.assertAlmostEqual(delta, 20.0)
        self.assertLess(low, 20.0)
        self.assertGreater(high, 20.0)

    def test_fewer_than_two_passes_have_no_interval(self):
        with self.assertRaises(ValueError):
            mean_interval([5.0])


class StackCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def add_config(self, config, index, means, delta=None, hits=40, lost=60000.0, failures=None, extra=()):
        for number, mean in enumerate(means):
            expectations = [dps_expectation(config, index), source_expectation(config, index)]
            if delta is not None:
                expectations.append(delta)
            key = f'conformance-templar-stack-{config}-pass-{number + 1}'
            steps = pass_steps(hits, mean, lost) + (list(extra) if number == 0 else [])
            self.workspace.scenario(key, 'stack', expectations, steps=steps)
            if failures:
                self.workspace.cast_failures[key] = failures

    def verdicts(self, reader=None, base=None):
        manifest, results = self.workspace.manifest(**(base or {}))
        return {verdict.label: verdict for verdict in compare(manifest, results, tooltips=reader or bonus_reader())}

    def verdicts_with_log_query(self, label, log_query, reader=None, base=None):
        manifest_path, results = self.workspace.manifest(**(base or {}))
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
        manifest['class_file'] = {**manifest['class_file'], 'log_queries': {label: log_query}}
        manifest_path.write_text(json.dumps(manifest), encoding='utf-8')
        return {verdict.label: verdict for verdict in compare(manifest_path, results, tooltips=reader or bonus_reader())}

    def test_measured_delta_whose_interval_holds_the_tooltip_bonus_is_ok(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation())
        verdict = self.verdicts(base=WITHOUT_TUNING)[DELTA_LABEL]
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 20.0)
        self.assertEqual(verdict.expected, 20.0)
        self.assertLess(verdict.low, 20.0)
        self.assertGreater(verdict.high, 20.0)
        self.assertIn('5 and 5 passes', verdict.explanation)

    def test_measured_delta_outside_its_interval_is_an_alert_under_every_reading(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, [150.0, 150.2, 149.8, 150.1, 149.9], delta_expectation())
        verdict = self.verdicts()[DELTA_LABEL]
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('adds', verdict.explanation)

    def test_interval_wider_than_the_hit_mean_bound_is_insufficient_even_holding_the_bonus(self):
        self.add_config(BASE, 0, WIDE_BASE_MEANS)
        self.add_config(PALADIN, 1, WIDE_PALADIN_MEANS, delta_expectation())
        verdict = self.verdicts(base=WITHOUT_TUNING)[DELTA_LABEL]
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertLess(verdict.low, 20.0)
        self.assertGreater(verdict.high, 20.0)
        self.assertGreater((verdict.high - verdict.low) / 2 / 120, 0.01)
        self.assertIn('half the band', verdict.explanation)
        self.assertIn('passes per configuration would meet it', verdict.explanation)
        self.assertGreater(verdict.detail['trials_needed'], 5)

    def test_seeded_fourteen_percent_on_a_twenty_percent_tooltip_is_an_alert(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, [114.0, 114.2, 113.8, 114.1, 113.9], delta_expectation())
        verdict = self.verdicts(base=WITHOUT_TUNING)[DELTA_LABEL]
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 14.0, places=1)

    def test_nineteen_percent_on_a_twenty_percent_tooltip_passes_inside_the_owner_band(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, [119.0, 119.2, 118.8, 119.1, 118.9], delta_expectation())
        verdict = self.verdicts(base=WITHOUT_TUNING)[DELTA_LABEL]
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('passes inside +-2 points', verdict.explanation)
        low, high = verdict.detail['excluded']
        self.assertLess(low, 18.0)
        self.assertGreater(high, 22.0)
        self.assertIn(f'excludes a bonus below {low:+.4g}% or above {high:+.4g}%', verdict.explanation)

    def test_known_modifier_readings_that_disagree_are_an_ambiguous_tooltip(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation())
        verdict = self.verdicts()[DELTA_LABEL]
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        self.assertAlmostEqual(verdict.measured, 20.0, places=1)
        self.assertIn('multiplies', verdict.explanation)
        self.assertIn('known aura 887007 effect 0 aura 341 -20%', verdict.explanation)
        self.assertIn('expected 25%: alert', verdict.explanation)
        self.assertIn('expected 20%: ok', verdict.explanation)

    def test_disagreeing_readings_stay_ambiguous_without_a_recorded_log_query(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation())
        verdict = self.verdicts()[DELTA_LABEL]
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        self.assertNotIn('owner fallback', verdict.explanation)

    def test_owner_fallback_settles_a_disagreement_the_logs_say_nothing_about(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation())
        verdict = self.verdicts_with_log_query(DELTA_LABEL, 'coa-history: no 807268 crit hits in range')[DELTA_LABEL]
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.expected, 20.0)
        self.assertIn('owner fallback', verdict.explanation)
        self.assertIn('coa-history: no 807268 crit hits in range', verdict.explanation)
        self.assertIn('multiplies', verdict.explanation)
        self.assertIn('expected 25%: alert', verdict.explanation)

    def test_known_aura_present_in_some_passes_only_is_unmodelled(self):
        self.add_config(BASE, 0, BASE_MEANS, extra=[assert_step('known_aura 887007', '0')])
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation())
        verdict = self.verdicts()[DELTA_LABEL]
        self.assertEqual(verdict.status, 'unmodelled')
        self.assertIn('present in 9 of 10 passes', verdict.explanation)

    def test_missing_pass_is_insufficient_even_on_the_exact_bonus(self):
        self.add_config(BASE, 0, [100.0, 101.0, 99.0, 100.5])
        self.add_config(PALADIN, 1, [120.0, 121.0, 119.0, 120.5, 119.5], delta_expectation())
        verdict = self.verdicts()[DELTA_LABEL]
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('4 of 5 passes', verdict.explanation)

    def test_no_hit_on_the_target_source_after_failed_casts_is_unmeasured(self):
        self.add_config(BASE, 0, [100.0] * 5)
        self.add_config(PALADIN, 1, [120.0] * 5, delta_expectation(), hits=0,
                        failures=[{'spell': str(ARGENT_BLADE), 'reason': '173'}])
        verdict = self.verdicts()[DELTA_LABEL]
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('failed casts', verdict.explanation)

    def test_bonus_changed_since_generation_is_an_alert(self):
        self.add_config(BASE, 0, [100.0] * 5)
        self.add_config(PALADIN, 1, [120.0] * 5, delta_expectation())
        verdict = self.verdicts(bonus_reader(value=25.0))[DELTA_LABEL]
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('generated as 20', verdict.explanation)

    def test_composition_readings_that_disagree_are_an_ambiguous_tooltip(self):
        earlier = [{'talent': 1, 'token': '$s1', 'bonus_pct': 100.0}]
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, [110.0, 110.2, 109.8, 110.1, 109.9], delta_expectation(bonus=10.0,
                                                                                          earlier=earlier))
        verdict = self.verdicts(bonus_reader(value=10.0), base=WITHOUT_TUNING)[DELTA_LABEL]
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        self.assertIn('multiplies', verdict.explanation)
        self.assertIn('adds', verdict.explanation)
        self.assertIn('expected 5%: alert', verdict.explanation)

    def test_composition_readings_inside_one_band_are_both_conformant(self):
        earlier = [{'talent': 1, 'token': '$s1', 'bonus_pct': 20.0}]
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, [110.0, 110.2, 109.8, 110.1, 109.9], delta_expectation(bonus=10.0,
                                                                                          earlier=earlier))
        verdict = self.verdicts(bonus_reader(value=10.0), base=WITHOUT_TUNING)[DELTA_LABEL]
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('expected 8.333%: ok', verdict.explanation)

    def test_configuration_dps_and_sources_are_measured_with_their_interval(self):
        self.add_config(BASE, 0, [100.0] * 5, lost=60000.0)
        verdicts = self.verdicts()
        dps = verdicts[f'stack {BASE} dps']
        self.assertEqual(dps.status, MEASURED)
        self.assertAlmostEqual(dps.measured, 500.0)
        self.assertEqual((dps.low, dps.high), (500.0, 500.0))
        self.assertEqual(dps.detail['index'], 0)
        source = verdicts[f'stack {BASE} source {ARGENT_BLADE}']
        self.assertEqual(source.status, MEASURED)
        self.assertAlmostEqual(source.measured, 40 * 100.0 * 1.1 / 120)

    def test_configuration_with_a_missing_pass_is_insufficient(self):
        self.add_config(BASE, 0, [100.0] * 3)
        self.assertEqual(self.verdicts()[f'stack {BASE} dps'].status, 'insufficient_trials')

    def test_measured_verdicts_are_no_alerts(self):
        self.add_config(BASE, 0, [100.0] * 5)
        rows = alert_rows(list(self.verdicts().values()))
        self.assertEqual(len(rows), 1)
        self.assertIn(MEASURED, STATUSES)

    def test_status_entries_are_never_ok(self):
        status = Expectation(f'stack {DIVINE} talent_delta {DIVINE_STRIKES} {ARGENT_BLADE}', TALENT_DELTA,
                             DIVINE_STRIKES, DIVINE_STRIKES, None, '$803372s2', 'unmodelled: stack uptime',
                             {'config': DIVINE, 'baseline': PALADIN, 'index': 2, 'passes': 5,
                              'source': ARGENT_BLADE})
        self.add_config(DIVINE, 2, [100.0] * 5, status)
        verdict = self.verdicts()[status.label]
        self.assertEqual(verdict.status, 'unmodelled')
        self.assertEqual(verdict.detail['config'], DIVINE)

    def test_levers_follow_the_configurations_with_their_tooltip_bonus(self):
        self.add_config(BASE, 0, BASE_MEANS, lost=60000.0)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation(), lost=72000.0)
        result = levers(list(self.verdicts(base=WITHOUT_TUNING).values()))
        self.assertEqual([lever.config for lever in result], [BASE, PALADIN])
        base, paladin = result
        self.assertIsInstance(base, Lever)
        self.assertIsNone(base.delta_pct)
        self.assertIsNone(base.tooltip_delta_pct)
        self.assertAlmostEqual(paladin.dps_mean, 600.0)
        self.assertAlmostEqual(paladin.delta_pct, 20.0)
        self.assertEqual(paladin.tooltip_delta_pct, 20.0)
        self.assertIn(ARGENT_BLADE, paladin.sources)

    def test_levers_file_lists_configurations_deltas_and_known_modifiers(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation(), lost=72000.0)
        manifest, results = self.workspace.manifest()
        verdicts = compare(manifest, results, tooltips=bonus_reader())
        path = write_levers(manifest, results, verdicts, self.workspace.root / 'report')
        text = path.read_text(encoding='utf-8')
        self.assertIn(f'| {PALADIN} |', text)
        self.assertIn(f'| {PALADIN_TRAINING} | {ARGENT_BLADE} |', text)
        self.assertIn('887007', text)
        self.assertIn('10 of 10 runs', text)


    def test_levers_file_marks_a_dps_change_decisive_only_with_a_narrow_interval_away_from_zero(self):
        self.add_config(BASE, 0, BASE_MEANS)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation(), lost=72000.0)
        manifest, results = self.workspace.manifest()
        path = write_levers(manifest, results, compare(manifest, results, tooltips=bonus_reader()),
                            self.workspace.root / 'report')
        self.assertIn('| 20.00 to 20.00 | yes |', path.read_text(encoding='utf-8'))

    def test_levers_file_keeps_the_row_of_a_configuration_without_damage(self):
        self.add_config(BASE, 0, BASE_MEANS, lost=0.0)
        self.add_config(PALADIN, 1, PALADIN_MEANS, delta_expectation(), lost=72000.0)
        manifest, results = self.workspace.manifest()
        path = write_levers(manifest, results, compare(manifest, results, tooltips=bonus_reader()),
                            self.workspace.root / 'report')
        text = path.read_text(encoding='utf-8')
        self.assertIn(f'| {BASE} |', text)
        self.assertIn(f'| {PALADIN} |', text)
        self.assertIn('no: DPS mean is not above 0 on a side', text)


class ChangeDecisionTest(unittest.TestCase):
    @staticmethod
    def dps(values, status=MEASURED):
        return Verdict('dps', status, sum(values) / len(values), None, None, None, '', check=STACK_DPS,
                       detail={'config': 'c', 'index': 0, 'per_pass': values})

    def test_change_whose_interval_holds_zero_is_not_decisive(self):
        span, decisive = change_decision(self.dps([500.0, 620.0, 480.0, 560.0, 540.0]),
                                         self.dps([520.0, 640.0, 470.0, 600.0, 530.0]))
        self.assertTrue(span)
        self.assertEqual(decisive, 'no: the interval holds 0')

    def test_change_with_a_half_width_above_the_bound_is_not_decisive(self):
        span, decisive = change_decision(self.dps([500.0, 505.0, 495.0, 502.0, 498.0]),
                                         self.dps([600.0, 640.0, 570.0, 610.0, 590.0]))
        self.assertTrue(decisive.startswith('no: half-width'))

    def test_narrow_change_away_from_zero_is_decisive(self):
        self.assertEqual(change_decision(self.dps([500.0, 501.0, 499.0]), self.dps([600.0, 601.0, 599.0]))[1], 'yes')

    def test_change_against_a_configuration_without_damage_is_not_decisive(self):
        zero = self.dps([0.0] * 5)
        expected = 'no: DPS mean is not above 0 on a side'
        self.assertEqual(change_decision(zero, self.dps([600.0, 601.0, 599.0])), ('', expected))
        self.assertEqual(change_decision(self.dps([600.0, 601.0, 599.0]), zero), ('', expected))
        self.assertEqual(change_decision(zero, zero), ('', expected))

    def test_change_of_an_unmeasured_configuration_is_not_decisive(self):
        decisive = change_decision(self.dps([500.0] * 3), self.dps([600.0] * 2, 'insufficient_trials'))[1]
        self.assertEqual(decisive, 'no: DPS measured then insufficient_trials')
        self.assertEqual(change_decision(None, self.dps([500.0] * 3)), ('', ''))

@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class StackScenarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scenarios = stack_scenarios(CLASS_FILE, passes=2)
        cls.grouped = by_config(cls.scenarios)

    def test_configurations_are_those_of_2026_11_05(self):
        self.assertEqual([config['name'] for config in CLASS_FILE['stack']], CONFIGS)
        self.assertEqual([config['talents'] for config in CLASS_FILE['stack']], TALENTS_2026_11_05)
        self.assertEqual(list(self.grouped), CONFIGS)
        self.assertEqual(len(self.scenarios), 2 * len(CONFIGS))

    def test_each_configuration_holds_every_talent_of_the_earlier_ones(self):
        rotation = CLASS_FILE['rotation']['learn']
        for index, config in enumerate(CONFIGS):
            expected = rotation + [talent for talents in TALENTS_2026_11_05[:index + 1] for talent in talents]
            for scenario, _ in self.grouped[config]:
                self.assertEqual(learned(scenario), expected)
                for earlier in TALENTS_2026_11_05[:index]:
                    self.assertTrue(set(earlier) <= set(learned(scenario)))

    def test_each_pass_has_a_distinct_name(self):
        names = [scenario['name'] for scenario, _ in self.scenarios]
        self.assertEqual(len(set(names)), len(names))
        self.assertIn('pass 2 of 2', names[1])

    def test_rotation_is_that_of_2026_11_05(self):
        scenario, _ = self.grouped[BASE][0]
        steps = scenario['steps']
        casts = [step for step in steps if step['action'] == 'cast']
        ticks = [step for step in steps if step['action'] == 'wait' and step.get('label') == 'tick']
        self.assertEqual(len(casts), 120)
        self.assertTrue(all(step['spell'] == ARGENT_BLADE and step['target'] == 'dummy' for step in casts))
        self.assertEqual({step['ms'] for step in ticks}, {1000})
        self.assertEqual(len(ticks), 120)
        actions = [step['action'] for step in steps]
        self.assertLess(actions.index('set_power'), actions.index('attack'))
        self.assertLess(actions.index('attack'), actions.index('cast'))
        self.assertGreater(actions.index('stop_attack'), len(actions) - actions[::-1].index('cast') - 1)
        power = next(step for step in steps if step['action'] == 'set_power')
        self.assertEqual((power['power'], power['value']), (3, 100))
        drain = next(step for step in steps if step.get('label') == 'drain')
        self.assertEqual(drain['ms'], 3000)
        self.assertLessEqual(scenario['timeout_ms'], 600000)

    def test_every_source_is_measured_in_every_pass(self):
        for scenario, expectations in self.scenarios:
            labels = {step['label'] for step in scenario['steps'] if step['action'] == 'assert'}
            for source in (ARGENT_BLADE, SCARLET_HAMMER, SCOURGEBANE_STRIKE, RETRIBUTION_STRIKE):
                self.assertIn(f'stack source {source} total', labels)
                self.assertIn(f'stack source {source} plain count', labels)
            self.assertIn('stack melee total', labels)
            self.assertTrue(set(HEALTH.values()) <= labels)
            sources = [expectation.spell_id for expectation in expectations if expectation.check == STACK_SOURCE]
            self.assertEqual(sources, [ARGENT_BLADE, SCARLET_HAMMER, SCOURGEBANE_STRIKE, RETRIBUTION_STRIKE, 0])

    def test_paladin_training_expects_its_tooltip_bonus_on_argent_blade(self):
        for _, expectations in self.grouped[PALADIN]:
            deltas = [expectation for expectation in expectations if expectation.check == TALENT_DELTA]
            self.assertEqual([expectation.label for expectation in deltas], [DELTA_LABEL])
            model = deltas[0].model
            self.assertEqual(model['bonus_pct'], 20.0)
            self.assertEqual((model['baseline'], model['source'], model['composition']), (BASE, ARGENT_BLADE, 'ratio'))
            self.assertEqual(model['earlier_bonuses'], [])
            self.assertIn('aura 108', deltas[0].rule)
            self.assertIn('Increases the damage', deltas[0].rule)
        for _, expectations in self.grouped[BASE]:
            self.assertFalse([expectation for expectation in expectations if expectation.check == TALENT_DELTA])

    def test_talents_without_a_fixed_bonus_keep_their_status(self):
        rules = {expectation.spell_id: expectation.rule for _, expectations in self.scenarios
                 for expectation in expectations if expectation.check == TALENT_DELTA}
        self.assertTrue(rules[DIVINE_STRIKES].startswith('unmodelled: '))
        self.assertTrue(rules[806522].startswith('ambiguous_tooltip: '))
        self.assertTrue(rules[MARTIAL_TRAINING].startswith('unmodelled: '))

    def test_bonus_after_an_earlier_talent_of_unstated_amount_is_ambiguous(self):
        class_file = copy.deepcopy(CLASS_FILE)
        class_file['stack'] = [{'name': 'base', 'talents': []}, {'name': 'divine', 'talents': [DIVINE_STRIKES]},
                               {'name': 'paladin', 'talents': [PALADIN_TRAINING]}]
        rule = next(expectation.rule for _, expectations in stack_scenarios(class_file, passes=2)
                    for expectation in expectations if expectation.spell_id == PALADIN_TRAINING)
        self.assertTrue(rule.startswith('ambiguous_tooltip: '))
        self.assertIn(str(DIVINE_STRIKES), rule)

    def test_bonus_learned_with_another_change_of_its_source_is_unmodelled(self):
        class_file = copy.deepcopy(CLASS_FILE)
        class_file['stack'] = [{'name': 'base', 'talents': []},
                               {'name': 'both', 'talents': [PALADIN_TRAINING, DIVINE_STRIKES]}]
        rule = next(expectation.rule for _, expectations in stack_scenarios(class_file, passes=2)
                    for expectation in expectations if expectation.spell_id == PALADIN_TRAINING)
        self.assertTrue(rule.startswith('unmodelled: '))

    def test_bonus_that_is_not_a_percent_damage_modifier_is_unmodelled(self):
        class_file = copy.deepcopy(CLASS_FILE)
        entry = next(entry for entry in class_file['talent_modifiers'] if entry['talent'] == MARTIAL_TRAINING)
        del entry['status'], entry['reason']
        rule = next(expectation.rule for _, expectations in stack_scenarios(class_file, passes=2)
                    for expectation in expectations if expectation.spell_id == MARTIAL_TRAINING)
        self.assertTrue(rule.startswith('unmodelled: '))
        self.assertIn('aura 107', rule)

    def test_fewer_than_two_passes_are_refused(self):
        with self.assertRaises(ValueError):
            stack_scenarios(CLASS_FILE, passes=1)

    def test_talent_modifier_entries_cite_their_dbc_tooltip_and_effect(self):
        records = Records(dataset(DBC_DIR))
        for entry in CLASS_FILE['talent_modifiers']:
            self.assertEqual(entry['tooltip'], records.field('Spell', entry['talent'], 'Description[enUS]'))
            self.assertIn(entry['token'], entry['tooltip'])
            dbc = entry.get('dbc')
            if not dbc:
                self.assertIn(entry['status'], ('unmodelled', 'ambiguous_tooltip'))
                continue
            effect = dbc['effect']
            for name in ('Effect', 'EffectApplyAuraName', 'EffectMiscValue', 'EffectBasePoints'):
                self.assertEqual(dbc[name], records.field('Spell', entry['talent'], f'{name}[{effect}]'))
            self.assertEqual(dbc['EffectSpellClassMask'], [
                records.field('Spell', entry['talent'], f'EffectSpellClassMask[{3 * effect + word}]')
                for word in range(3)])
            self.assertEqual(dbc['source_SpellFamilyFlags'], [
                records.field('Spell', entry['source'], f'SpellFamilyFlags[{word}]') for word in range(3)])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GenerateStackTest(unittest.TestCase):
    def test_generate_writes_every_pass_of_every_configuration(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-stack-'))
        try:
            manifest = json.loads(generate(CLASS_FILE['class_id'], out, stack=True, passes=2)
                                  .read_text(encoding='utf-8'))
            entries = manifest['scenarios']
            self.assertEqual(len(entries), 2 * len(CONFIGS))
            self.assertEqual({entry['kind'] for entry in entries}, {'stack'})
            self.assertEqual(entries[0]['key'], 'conformance-templar-stack-c0-base-pass-1')
            for entry in entries:
                path = out / entry['file']
                scenario = json.loads(path.read_text(encoding='utf-8'))
                recorded = hashlib.sha256((json.dumps(scenario, indent=2) + '\n').encode('utf-8')).hexdigest()
                self.assertEqual(entry['sha256'], recorded)
                self.assertEqual(batch.exploratory_key(path, set()), entry['key'])
        finally:
            shutil.rmtree(out)


class VerdictDetailTest(unittest.TestCase):
    def test_verdicts_without_detail_keep_their_fields(self):
        verdict = Verdict('label', 'ok', 1.0, 1.0, 1.0, 1.0, 'why')
        self.assertIsNone(verdict.detail)
        self.assertEqual(asdict(verdict)['label'], 'label')


if __name__ == '__main__':
    unittest.main()
