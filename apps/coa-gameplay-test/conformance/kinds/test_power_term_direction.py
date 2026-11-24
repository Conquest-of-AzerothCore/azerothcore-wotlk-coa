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


AGILITY_ENTRY = {**ENTRY, 'name': 'Felcaked Blades (Twin Slice Agility term direction)', 'spell': 574145,
                 'talent': 574145, 'quote': 'Twin Slice and Sargeron Smite now additionally scale with your Agility.',
                 'cast_spell': 801901, 'hit_spell': 808303, 'cast_power': 100, 'power_metric': 'agility',
                 'power_aura': 300111, 'power_aura_source': 'QA Test +100 Agility 300111, aura 29 Agility, seeded',
                 'power_stacks': 3, 'casts': 12, 'cast_wait_ms': 1100, 'attempt_auras': [],
                 'power_companions': [{'spell': 530003, 'stacks': 1, 'source': 'seeded -312 attack power'},
                                      {'spell': 9141, 'stacks': 1, 'source': 'seeded +12 attack power'}]}
ABSORB_ENTRY = {**ENTRY, 'name': 'Pure Hatred (Hateforged Barrier maximum health term direction)', 'spell': 803478,
                'talent': 803478, 'quote': 'Your Hateforged Barrier now also scales with your maximum health.',
                'cast_spell': 707527, 'power_metric': 'max_health', 'power_aura': 805256,
                'power_aura_source': 'Infernal Constitution 805256, aura 133, seeded', 'casts': 12,
                'cast_wait_ms': 1000, 'attempt_auras': [], 'sample': 'absorb', 'strike_spell': 54416,
                'refill_spell': 17683}
STAT = {'control low': 130.0, 'control high': 430.0, 'learned high': 430.0, 'learned low': 130.0}
HEALTH = {'control low': 4050.0, 'control high': 4455.0, 'learned high': 4455.0, 'learned low': 4050.0}
AGILITY_TERM = {'control low': 300.0, 'control high': 300.0, 'learned high': 385.0, 'learned low': 320.0}
ABSORB_TERM = {'control low': 845.0, 'control high': 845.0, 'learned high': 1290.0, 'learned low': 1250.0}


def variant_values(expectation, means, power, after=None, seed=11, held=1, remaining=0, attack_after=None):
    rolls = random.Random(seed)
    values = {}
    for arm, reads in expectation.model['reads'].items():
        values[reads['power']] = power[arm]
        values[reads['power after']] = (after or power)[arm]
        values[reads['attack power']] = 312.0
        values[reads['attack power after']] = (attack_after or {}).get(arm, 312.0)
        if 'absorbs' in reads:
            absorbed = 0.0
            for cast in range(len(reads['absorbs'])):
                if cast:
                    values[reads['held'][cast - 1]], values[reads['remaining'][cast - 1]] = held, remaining
                    absorbed += means[arm] + rolls.uniform(-16.0, 16.0)
                values[reads['absorbs'][cast]], values[reads['logs'][cast]] = absorbed, float(cast)
            continue
        total = 0.0
        for cast, (total_label, count_label) in enumerate(zip(reads['totals'], reads['counts'])):
            if cast:
                total += means[arm] + rolls.uniform(-6.0, 6.0)
            values[total_label], values[count_label] = total, float(cast)
    return values


def variant_judged(entry, means, power, **options):
    _, [expectation] = built(entry)
    values = variant_values(expectation, means, power, **options)
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


    def test_the_default_entry_keeps_its_reads_and_model_without_the_options(self):
        scenario, [expectation] = built()
        self.assertEqual(set(expectation.model['reads']['control low']), {'power', 'totals', 'counts'})
        self.assertNotIn('power_name', expectation.model)
        self.assertNotIn('sample', expectation.model)
        self.assertEqual(len(scenario['creatures']), 1)
        self.assertEqual({(step['power'], step['value']) for step in scenario['steps'] if step['action'] == 'set_power'},
                         {(0, 1363)})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PowerTermDirectionAgilityTests(unittest.TestCase):
    def test_agility_arms_read_agility_before_and_after_the_attack_power_and_the_hit_spell(self):
        scenario, [expectation] = built(AGILITY_ENTRY)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        reads = {step['label']: step for step in steps if step['action'] == 'assert'}
        arm = expectation.model['reads']['control high']
        self.assertEqual((reads[arm['power']]['metric'], reads[arm['power']]['stat']), ('stat', 1))
        self.assertEqual((reads[arm['power after']]['metric'], reads[arm['power after']]['stat']), ('stat', 1))
        self.assertEqual(reads[arm['attack power']]['metric'], 'attack_power')
        self.assertEqual(reads[arm['attack power after']]['metric'], 'attack_power')
        order = [step['label'] for step in steps if step['action'] == 'assert']
        self.assertEqual(order.index(arm['attack power after']), order.index(arm['power after']) + 1)
        self.assertGreater(order.index(arm['power after']), order.index(arm['totals'][-1]))
        self.assertEqual(reads[arm['totals'][2]]['spell'], 808303)
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 48)
        self.assertTrue(all(steps[index - 2] == {'action': 'set_power', 'actor': 'caster', 'power': 3, 'value': 100}
                            for index in casts))
        self.assertIn('The Agility and the attack power are read before and after each arm', scenario['contract'])
        self.assertIn('each non-critical hit of 808303 is one sample', scenario['contract'])
        self.assertEqual(expectation.model['power_name'], 'Agility')
        fixtures = [(step['spell'], step['stacks']) for step in steps
                    if step['action'] == 'set_aura' and step['spell'] in (300111, 530003, 9141)]
        self.assertEqual(fixtures, [(300111, 3), (530003, 1), (9141, 1), (300111, 0), (530003, 0), (9141, 0)])
        self.assertIn('Aura 530003 is set at 1 stacks with the Agility aura in the high arms', scenario['contract'])

    def test_a_term_that_grows_with_agility_only_with_the_passive_passes(self):
        verdict = variant_judged(AGILITY_ENTRY, AGILITY_TERM, STAT)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('Agility 130 / 430 (control)', verdict.explanation)
        self.assertIn('fixture: QA Test +100 Agility 300111 (3 stacks) with Raid Debuff 3 (70) 530003 (1 stacks) with '
                      'Attack Power 12 9141 (1 stacks) set by harness set_aura', verdict.explanation)
        self.assertIn('attack power control low 312', verdict.explanation)

    def test_mutant_without_the_agility_term_alerts(self):
        verdict = variant_judged(AGILITY_ENTRY, {**AGILITY_TERM, 'learned high': 320.0}, STAT)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('adds no damage that grows with Agility', verdict.explanation)

    def test_mutant_whose_fixture_lost_its_agility_by_the_end_of_the_arm_is_unmeasured(self):
        verdict = variant_judged(AGILITY_ENTRY, AGILITY_TERM, STAT, after={**STAT, 'control high': 130.0})
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('did not raise the Agility', verdict.explanation)

    def test_mutant_whose_attack_power_moved_inside_a_high_arm_is_unmeasured_not_alerted(self):
        for arm in ARMS:
            with self.subTest(arm=arm):
                verdict = variant_judged(AGILITY_ENTRY, AGILITY_TERM, STAT, attack_after={arm: 255.0})
                self.assertEqual(verdict.status, 'unmeasured')
                self.assertIn(f'{arm} 312 / 255', verdict.explanation)

    def test_mutant_whose_agility_drifted_inside_an_arm_is_unmeasured(self):
        verdict = variant_judged(AGILITY_ENTRY, AGILITY_TERM, STAT, after={**STAT, 'learned high': 330.0})
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('a fixture moved inside an arm', verdict.explanation)
        self.assertIn('learned high 430 / 330', verdict.explanation)

    def test_an_aura_of_another_stat_and_a_short_power_are_refused(self):
        for change in ({'power_aura': 35785}, {'power_metric': 'max_health'}, {'power_metric': 'spirit'},
                       {'cast_power': 10}, {'cast_power': 0}, {'power_stacks': 0},
                       {'power_companions': [{'spell': 9141, 'stacks': 1}]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                built({**AGILITY_ENTRY, **change})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PowerTermDirectionAbsorbTests(unittest.TestCase):
    def test_each_barrier_is_cleared_refilled_cast_and_broken_by_one_strike(self):
        scenario, [expectation] = built(ABSORB_ENTRY)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        barrier = next(index for index, step in enumerate(steps)
                       if step == {'action': 'cast', 'actor': 'caster', 'spell': 707527})
        self.assertEqual([step['action'] for step in steps[barrier - 3:barrier + 6]],
                         ['set_aura', 'cast', 'reset_cooldown', 'cast', 'wait', 'assert', 'cast', 'wait', 'assert'])
        self.assertEqual(steps[barrier - 3], {'action': 'set_aura', 'actor': 'caster', 'spell': 707527, 'stacks': 0})
        self.assertEqual(steps[barrier - 2]['spell'], 17683)
        self.assertEqual(steps[barrier + 3], {'action': 'cast', 'actor': 'striker', 'spell': 54416,
                                              'target': 'caster'})
        reads = {step['label']: step for step in steps if step['action'] == 'assert'}
        arm = expectation.model['reads']['learned high']
        self.assertEqual(reads[arm['power']]['metric'], 'max_health')
        self.assertEqual((reads[arm['absorbs'][4]]['metric'], reads[arm['absorbs'][4]]['caster']),
                         ('spell_absorb_total', 'striker'))
        self.assertEqual(expectation.model['metric'], 'spell_absorb_total')
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['dummy', 'striker'])
        self.assertIn('proves the direction of the term only', scenario['contract'])

    def test_a_barrier_that_grows_with_maximum_health_only_with_the_passive_passes(self):
        verdict = variant_judged(ABSORB_ENTRY, ABSORB_TERM, HEALTH)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('maximum health 4050 / 4455 (control)', verdict.explanation)
        self.assertIn('mean barrier', verdict.explanation)

    def test_mutant_without_the_health_term_alerts(self):
        verdict = variant_judged(ABSORB_ENTRY, {**ABSORB_TERM, 'learned high': 1250.0}, HEALTH)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('adds no absorb that grows with maximum health', verdict.explanation)

    def test_mutant_unbroken_or_refused_barriers_are_no_sample(self):
        self.assertEqual(variant_judged(ABSORB_ENTRY, ABSORB_TERM, HEALTH, remaining=1).status, 'insufficient_trials')
        self.assertEqual(variant_judged(ABSORB_ENTRY, ABSORB_TERM, HEALTH, held=0).status, 'insufficient_trials')

    def test_an_absorb_sample_needs_its_strike_refill_and_a_school_absorb_cast(self):
        for change in ({'strike_spell': None}, {'refill_spell': None}, {'hit_spell': 808303},
                       {'cast_spell': 801901}, {'power_aura': 27976}, {'sample': 'heal'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                built({**ABSORB_ENTRY, **change})
        with self.assertRaises(ValueError):
            built({**AGILITY_ENTRY, 'strike_spell': 54416, 'refill_spell': 17683})


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
