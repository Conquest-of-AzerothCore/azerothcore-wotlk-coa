from pathlib import Path
import sys
import unittest

from behaviours import BEHAVIOUR_HIT_RATIO, behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
from test_behaviours import FakeRun, base_verdict
from values import Expectation

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

RESIDUAL = 1e-4
OPTION = {'residual': RESIDUAL}


def control_hits(trials: int) -> list[float]:
    return [1000.0 + 10.0 * ((index * 7) % 11 - 5) for index in range(trials)]


def judged(expected: float, control: list[float], treatment: list[float], option: dict | None = OPTION):
    trials = len(control)
    reads = {arm: [(f'{arm} {mark} total', f'{arm} {mark} count') for mark in ('start', *range(1, trials + 1))]
             for arm in ('control', 'treatment')}
    values, total, count = {}, 0.0, 0.0
    for arm, hits in (('control', control), ('treatment', treatment)):
        marks = reads[arm]
        values[marks[0][0]], values[marks[0][1]] = total, count
        for (total_label, count_label), hit in zip(marks[1:], hits):
            total, count = total + hit, count + 1
            values[total_label], values[count_label] = total, count
    model = {'kind': 'hit_ratio', 'reads': reads, 'expected': expected, 'expected_bonus': (expected - 1) * 100,
             'trials': trials, 'trial_limit': 4000, 'minimum_hits': 1, 'metric': 'spell_damage_total',
             **({'control_excluded': option} if option else {})}
    expectation = Expectation('label', BEHAVIOUR_HIT_RATIO, 300571, 681350, None, str(expected),
                              'prose: "increases the damage dealt by Stake and Dawn Blade by 2%"', model)
    return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)


def stake_entry(**changes) -> dict:
    entry = next(entry for entry in load_class_file(15)['behaviours']
                 if entry['spell'] == 300571 and entry.get('label_suffix') == 'stake')
    entry = {key: value for key, value in entry.items() if key != 'control_excluded'}
    return {**entry, 'parts': 1, **changes}


class ControlExcludedJudgeTests(unittest.TestCase):
    def test_a_sized_two_percent_bonus_excludes_the_control_and_passes(self):
        control = control_hits(400)
        verdict = judged(1.02, control, [hit * 1.02 for hit in control])
        self.assertEqual(verdict.status, 'ok')
        exclusion = verdict.detail['control_excluded']
        self.assertGreater(exclusion['bound'], 0)
        self.assertEqual(exclusion['residual'], RESIDUAL)
        self.assertLessEqual(exclusion['standard_error'], exclusion['error_limit'])
        self.assertIn('excludes the control (0)', verdict.explanation)
        self.assertIn('400 trials per arm', verdict.explanation)

    def test_mutant_a_zero_effect_alerts_where_the_plain_judge_withholds(self):
        control = control_hits(400)
        plain = judged(1.02, control, list(control), option=None)
        mutant = judged(1.02, control, list(control))
        self.assertEqual(plain.status, 'insufficient_trials')
        self.assertEqual(mutant.status, 'alert')
        self.assertIn('does not exclude the control', mutant.explanation)

    def test_a_small_effect_inside_the_band_but_not_excluding_the_control_alerts(self):
        control = control_hits(400)
        self.assertEqual(judged(1.02, control, [hit * 1.003 for hit in control]).status, 'alert')

    def test_a_shortfall_that_still_excludes_the_control_counts_inside_the_band(self):
        control = control_hits(1600)
        self.assertEqual(judged(1.02, control, [hit * 1.0104 for hit in control]).status, 'ok')

    def test_an_estimate_outside_the_band_alerts(self):
        control = control_hits(400)
        verdict = judged(1.02, control, [hit * 1.045 for hit in control])
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('outside the band', verdict.explanation)

    def test_too_few_trials_are_not_judged_and_name_the_trials(self):
        control = control_hits(100)
        verdict = judged(1.02, control, [hit * 1.02 for hit in control])
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertGreater(verdict.detail['trials_needed'], 100)

    def test_a_stated_decrease_needs_its_upper_bound_below_zero(self):
        control = control_hits(400)
        self.assertEqual(judged(0.98, control, [hit * 0.98 for hit in control]).status, 'ok')
        self.assertEqual(judged(0.98, control, list(control)).status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ControlExcludedScenarioTests(unittest.TestCase):
    def test_the_option_reaches_the_model_and_the_contract(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), stake_entry(control_excluded=OPTION))
        run.validate(scenario)
        self.assertEqual(expectation.model['control_excluded'], OPTION)
        self.assertIn('one-sided 0.9999 lower bound', scenario['contract'])
        self.assertIn(f'probability at most {RESIDUAL:g}', scenario['contract'])

    def test_without_the_option_the_scenario_is_unchanged(self):
        plain, [expectation] = behaviour_scenario(load_class_file(15), stake_entry())
        opted, _ = behaviour_scenario(load_class_file(15), stake_entry(control_excluded=OPTION))
        self.assertNotIn('control_excluded', expectation.model)
        self.assertEqual(plain['steps'], opted['steps'])
        self.assertTrue(opted['contract'].startswith(plain['contract']))

    def test_a_band_without_zero_or_a_bad_residual_is_refused(self):
        for changes in ({'control_excluded': OPTION, 'expected': 1.2}, {'control_excluded': {'residual': 0}},
                        {'control_excluded': {'residual': 0.05}}, {'control_excluded': {'p': 1e-4}},
                        {'control_excluded': True}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(15), stake_entry(**changes))


if __name__ == '__main__':
    unittest.main()
