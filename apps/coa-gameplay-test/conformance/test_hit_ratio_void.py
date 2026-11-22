import unittest

from behaviours import BEHAVIOUR_HIT_RATIO, behaviour_scenario, hit_ratio_spec
from compare import judge_behaviour
import hit_ratio_void
from profile import DBC_DIR
from test_behaviours import DARKSLAYER_DAMAGE, FakeRun, base_verdict, control_hits, witch_hunter_file
from values import Expectation

NOT_READY = 67
CASTER_AURASTATE = 22


def judged(control: list[float], treatment: list[float], failures: dict[int, list[int]] | None = None,
           void: bool = True):
    trials = len(control)
    reads = {arm: [(f'{arm} {mark} total', f'{arm} {mark} count') for mark in ('start', *range(1, trials + 1))]
             for arm in ('control', 'treatment')}
    values, total, count = {}, 0.0, 0.0
    for arm, hits in (('control', control), ('treatment', treatment)):
        marks = reads[arm]
        values[marks[0][0]], values[marks[0][1]] = total, count
        for (total_label, count_label), hit in zip(marks[1:], hits):
            total, count = total + hit, count + (1 if hit else 0)
            values[total_label], values[count_label] = total, count
    model = {'kind': 'hit_ratio', 'reads': reads, 'expected': 1.2, 'expected_bonus': 20.0, 'trials': trials,
             'trial_limit': 111, 'minimum_hits': 1, 'metric': 'spell_damage_total'}
    if void:
        model[hit_ratio_void.NAME] = True
    expectation = Expectation('label', BEHAVIOUR_HIT_RATIO, 503681, 804179, None, '1.2', 'prose', model)
    run = FakeRun(values)
    run.cast_failures = failures or {}
    return judge_behaviour(base_verdict(expectation), run, expectation)


class HitRatioVoidJudgeTests(unittest.TestCase):
    def test_a_clean_run_is_judged_as_without_the_option(self):
        control = control_hits(400)
        treatment = [hit * 1.19 for hit in control]
        with_option, without = judged(control, treatment), judged(control, treatment, void=False)
        self.assertEqual(with_option.status, 'ok')
        self.assertEqual((with_option.status, with_option.measured, with_option.explanation),
                         (without.status, without.measured, without.explanation))

    def test_seeded_refused_casts_void_an_otherwise_ok_trial(self):
        control = control_hits(400)
        verdict = judged(control, [hit * 1.19 for hit in control], {503624: [NOT_READY] * 5})
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('the trial is void, 5 casts were refused', verdict.explanation)

    def test_refused_casts_are_not_voided_without_the_option(self):
        control = control_hits(400)
        verdict = judged(control, [hit * 1.19 for hit in control], {503624: [NOT_READY] * 5}, void=False)
        self.assertEqual(verdict.status, 'ok')

    def test_a_refusal_of_any_spell_voids_the_trial(self):
        control = control_hits(400)
        verdict = judged(control, [hit * 1.19 for hit in control], {804584: [CASTER_AURASTATE]})
        self.assertEqual(verdict.status, 'unmeasured')

    def test_seeded_mutant_fourteen_percent_still_alerts_with_the_option(self):
        control = control_hits(400)
        verdict = judged(control, [hit * 1.14 for hit in control])
        self.assertEqual(verdict.status, 'alert')


class HitRatioVoidGenerationTests(unittest.TestCase):
    def test_only_true_or_absent_is_accepted(self):
        self.assertFalse(hit_ratio_void.parse(None))
        self.assertTrue(hit_ratio_void.parse(True))
        for raw in (False, 1, 'true', {}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                hit_ratio_void.parse(raw)

    def test_the_spec_carries_the_option_only_when_set(self):
        self.assertFalse(hit_ratio_spec(DARKSLAYER_DAMAGE).void_on_cast_failure)
        self.assertTrue(hit_ratio_spec({**DARKSLAYER_DAMAGE, hit_ratio_void.NAME: True}).void_on_cast_failure)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_option_adds_the_model_key_and_contract_and_leaves_the_steps(self):
        plain, [plain_expectation] = behaviour_scenario(witch_hunter_file(503681), DARKSLAYER_DAMAGE)
        voided, [voided_expectation] = behaviour_scenario(witch_hunter_file(503681),
                                                          {**DARKSLAYER_DAMAGE, hit_ratio_void.NAME: True})
        self.assertNotIn(hit_ratio_void.NAME, plain_expectation.model)
        self.assertNotIn(hit_ratio_void.CONTRACT, plain['contract'])
        self.assertIs(voided_expectation.model[hit_ratio_void.NAME], True)
        self.assertIn(hit_ratio_void.CONTRACT, voided['contract'])
        self.assertEqual(plain['steps'], voided['steps'])


if __name__ == '__main__':
    unittest.main()
