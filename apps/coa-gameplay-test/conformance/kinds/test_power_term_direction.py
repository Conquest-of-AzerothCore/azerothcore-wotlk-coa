import random
from statistics import NormalDist
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.power_term_direction import (ARMS, CONTROL_PROBABILITY, DIRECTION_PROBABILITY, control_alerts,
                                        direction_passes, judged_samples)
from profile import DBC_DIR, load_fixture_class_file
import run
from stack import student_t_quantile
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 680656, 'name': "Sun's Gift (attack power term direction)", 'kind': 'power_term_direction',
         'quote': 'Your Horusath Blast now deals additional damage scaling with your attack power',
         'talent': 680656, 'cast_spell': 572801, 'power_aura': 35785,
         'power_aura_source': 'Attack Power 980 35785, aura 99, +980', 'casts': 20, 'cast_wait_ms': 1700,
         'attempt_auras': [{'spell': 823764, 'stacks': 1, 'source': 'seeded spell penetration'}]}
BASE_MANA = {'power': 0, 'value': 1363, 'source': 'seeded base mana'}
POWER = {'control low': 70.0, 'control high': 1050.0, 'learned high': 1050.0, 'learned low': 70.0}


def class_file():
    return {**load_fixture_class_file(19), 'base_mana': BASE_MANA}


def built(entry=None):
    return behaviour_scenario(class_file(), entry or ENTRY)


def harness_values(expectation, means, power=None, crits=0, seed=7):
    rolls = random.Random(seed)
    values = {}
    for arm, reads in expectation.model['reads'].items():
        values[reads['power']] = (power or POWER)[arm]
        total = count = 0.0
        for cast, (total_label, count_label) in enumerate(zip(reads['totals'], reads['counts'])):
            if cast and cast > crits:
                total += means[arm] + rolls.uniform(-6.0, 6.0)
                count += 1
            values[total_label], values[count_label] = total, count
    return values


def judged(means, **options):
    _, [expectation] = built()
    values = harness_values(expectation, means, **options)
    return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)


WITH_TERM = {'control low': 840.0, 'control high': 840.0, 'learned high': 1102.0, 'learned low': 857.0}
NULL_PAIRS = 20000
NULL_SAMPLES = 10
BOUND = 0.001


def null_pairs():
    rolls = random.Random(20261122)
    return [[judged_samples({arm: [rolls.gauss(0.0, 1.0) for _ in range(NULL_SAMPLES)] for arm in ARMS})
             for _ in range(2)] for _ in range(NULL_PAIRS)]


def normal_quantile(probability):
    return NormalDist().inv_cdf(probability)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PowerTermDirectionTests(unittest.TestCase):
    def test_four_arms_read_the_attack_power_and_each_cast_around_the_learn_and_the_aura(self):
        scenario, [expectation] = built()
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        order = [(step['action'], step.get('spell'), step.get('stacks')) for step in steps
                 if step['action'] == 'learn' and step['spell'] == 680656
                 or step['action'] == 'set_aura' and step['spell'] == 35785]
        self.assertEqual(order, [('set_aura', 35785, 1), ('learn', 680656, None), ('set_aura', 35785, 0)])
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 80)
        self.assertTrue(all(steps[index - 1] == {'action': 'reset_cooldown', 'actor': 'caster', 'spell': 572801}
                            for index in casts))
        reads = {step['label']: step for step in steps if step['action'] == 'assert'}
        total = reads[expectation.model['reads']['learned high']['totals'][3]]
        self.assertEqual((total['metric'], total['critical'], total['target']), ('spell_damage_total', False, 'dummy'))
        self.assertEqual(reads[expectation.model['reads']['control low']['power']]['metric'], 'attack_power')
        self.assertEqual(expectation.label, '680656 behaviour_metric_delta power_direction')
        self.assertIn('direction only: no figure judged', scenario['contract'])
        self.assertIn('two-sided at the 99.975% Student t quantile at the control arms\' Welch-Satterthwaite degrees '
                      'of freedom (z 3.48 at infinite freedom): its false alert is 0.050% per run and 0.1% per pair',
                      scenario['contract'])
        self.assertIn('one-sided 99.9% Student t quantile', scenario['contract'])

    def test_a_term_that_grows_with_attack_power_only_with_the_passive_passes(self):
        verdict = judged(WITH_TERM)
        self.assertEqual(verdict.status, 'ok')
        self.assertTrue(verdict.explanation.startswith('direction only: no figure judged'))
        self.assertIn('fixture: Attack Power 980 35785 set by harness set_aura on the caster for the high arms, '
                      'beeg spellpen 823764 (1 stacks) before each cast', verdict.explanation)
        self.assertIsNone(verdict.expected)

    def test_mutant_without_the_term_alerts(self):
        flat = {**WITH_TERM, 'learned high': 857.0}
        verdict = judged(flat)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('adds no damage that grows with attack power', verdict.explanation)

    def test_mutant_with_the_term_outside_the_passive_alerts(self):
        verdict = judged({**WITH_TERM, 'control high': 1085.0})
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('without the passive', verdict.explanation)

    def test_an_aura_that_does_not_raise_the_attack_power_is_unmeasured(self):
        verdict = judged(WITH_TERM, power={**POWER, 'learned high': 70.0})
        self.assertEqual(verdict.status, 'unmeasured')

    def test_critical_hits_are_no_sample_and_too_few_samples_are_insufficient(self):
        self.assertEqual(judged(WITH_TERM, crits=5).status, 'ok')
        self.assertEqual(judged(WITH_TERM, crits=11).status, 'insufficient_trials')

    def test_a_missing_read_is_unmeasured(self):
        _, [expectation] = built()
        values = harness_values(expectation, WITH_TERM)
        del values[expectation.model['reads']['learned low']['counts'][4]]
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_a_figure_in_the_entry_or_the_quote_is_refused(self):
        for change in ({'expected': 0.25}, {'coefficient': 0.25}, {'expected_gain': 245},
                       {'quote': 'scaling with 25% of your attack power'}, {'casts': 9}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                built({**ENTRY, **change})

    def test_an_aura_without_attack_power_is_refused(self):
        with self.assertRaises(ValueError):
            built({**ENTRY, 'power_aura': 823764})


class PowerTermDirectionNullRateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pairs = null_pairs()

    def test_the_quantiles_are_the_student_t_quantiles_of_the_stated_levels(self):
        self.assertAlmostEqual(CONTROL_PROBABILITY, 1 - (1 - 0.999 ** 0.5) / 2, places=12)
        self.assertAlmostEqual(student_t_quantile(CONTROL_PROBABILITY, 36), 3.8255, places=3)
        self.assertAlmostEqual(student_t_quantile(CONTROL_PROBABILITY, float('inf')), 3.4807, places=3)
        self.assertAlmostEqual(student_t_quantile(DIRECTION_PROBABILITY, 30), 3.385, places=3)

    def test_the_control_check_false_alert_without_any_growth_is_at_most_a_tenth_percent_per_pair(self):
        alerted = sum(any(control_alerts(run) for run in pair) for pair in self.pairs)
        normal = sum(any(abs(run.control.z) >= normal_quantile(CONTROL_PROBABILITY) for run in pair)
                     for pair in self.pairs)
        self.assertLessEqual(alerted / NULL_PAIRS, BOUND)
        self.assertGreater(normal / NULL_PAIRS, 2 * BOUND)

    def test_the_direction_false_pass_without_any_term_is_at_most_a_tenth_percent_per_run(self):
        runs = [run for pair in self.pairs for run in pair]
        passed = sum(direction_passes(run) for run in runs)
        normal = sum(run.interaction.z >= normal_quantile(DIRECTION_PROBABILITY) for run in runs)
        both = sum(all(direction_passes(run) for run in pair) for pair in self.pairs)
        self.assertLessEqual(passed / len(runs), BOUND)
        self.assertLessEqual(both / NULL_PAIRS, BOUND)
        self.assertGreater(normal / len(runs), 1.5 * BOUND)
