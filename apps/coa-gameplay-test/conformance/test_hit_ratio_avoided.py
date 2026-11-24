import unittest

from behaviours import BEHAVIOUR_HIT_RATIO, behaviour_scenario, hit_ratio_spec
from compare import judge_behaviour
import hit_ratio_avoided
from profile import DBC_DIR
from test_behaviours import DARKSLAYER_DAMAGE, FakeRun, base_verdict, control_hits, witch_hunter_file
from values import Expectation

GRANT = {'proc_aura': 807163, 'striker_entry': 36, 'strikers': 2, 'striker_auras': [42716], 'swing_ms': 500,
         'grant_ms': 1500, 'lead_ms': 3000}
EARNED = {**DARKSLAYER_DAMAGE, 'target': 'striker', hit_ratio_avoided.NAME: GRANT}
PREFIX = 'grant'


def judged(control: list[float], treatment: list[float], presence: dict[str, list[float]] | None = None,
           grant: bool = True, dropped: str | None = None):
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
    if grant:
        grant_model = hit_ratio_avoided.model(hit_ratio_avoided.parse(GRANT), PREFIX, trials)
        model[hit_ratio_avoided.NAME] = grant_model
        presence = presence or {'control': [0.0] * trials, 'treatment': [1.0] * trials}
        for arm, labels in grant_model['presence'].items():
            values.update(zip(labels, presence[arm]))
        if dropped is not None:
            values.pop(dropped)
    expectation = Expectation('label', BEHAVIOUR_HIT_RATIO, 503681, 804179, None, '1.2', 'prose', model)
    return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)


class HitRatioAvoidedJudgeTests(unittest.TestCase):
    def test_a_run_that_holds_the_aura_exactly_in_the_treatment_is_judged_as_without_the_option(self):
        control = control_hits(400)
        treatment = [hit * 1.19 for hit in control]
        with_option, without = judged(control, treatment), judged(control, treatment, grant=False)
        self.assertEqual(with_option.status, 'ok')
        self.assertEqual((with_option.status, with_option.measured, with_option.explanation),
                         (without.status, without.measured, without.explanation))

    def test_seeded_treatment_trial_without_the_earned_aura_voids_the_run(self):
        control = control_hits(400)
        absent = [1.0] * 400
        absent[137] = 0.0
        verdict = judged(control, [hit * 1.19 for hit in control], {'control': [0.0] * 400, 'treatment': absent})
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('807163 is absent before treatment trial 138', verdict.explanation)

    def test_seeded_control_trial_with_the_aura_voids_the_run(self):
        control = control_hits(400)
        present = [0.0] * 400
        present[3] = 1.0
        verdict = judged(control, [hit * 1.19 for hit in control], {'control': present, 'treatment': [1.0] * 400})
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('807163 is present before control trial 4', verdict.explanation)

    def test_a_missing_presence_read_voids_the_run(self):
        control = control_hits(400)
        verdict = judged(control, [hit * 1.19 for hit in control], dropped=f'{PREFIX} treatment avoided_grant 9')
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('was not read', verdict.explanation)

    def test_seeded_mutant_fourteen_percent_still_alerts_with_the_option(self):
        control = control_hits(400)
        self.assertEqual(judged(control, [hit * 1.14 for hit in control]).status, 'alert')


class HitRatioAvoidedGenerationTests(unittest.TestCase):
    def test_malformed_options_are_refused(self):
        self.assertIsNone(hit_ratio_avoided.parse(None))
        for raw in ({**GRANT, 'grant_ms': 1200}, {**GRANT, 'lead_ms': 700}, {**GRANT, 'strikers': True},
                    {**GRANT, 'striker_auras': 42716},
                    {key: value for key, value in GRANT.items() if key != 'swing_ms'}, {**GRANT, 'dodge': 100}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                hit_ratio_avoided.parse(raw)

    def test_the_spec_carries_the_option_only_when_set(self):
        self.assertIsNone(hit_ratio_spec(DARKSLAYER_DAMAGE).avoided_grant)
        self.assertEqual(hit_ratio_spec(EARNED).avoided_grant.proc_aura, 807163)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_set_earned_aura_a_shared_learn_or_another_target_is_refused(self):
        for entry in ({**EARNED, 'treatment': {'learn': [503681], 'auras': [[807163, 1]]}},
                      {**EARNED, 'control': {'learn': [503681]}},
                      {**EARNED, 'learn': [503681], 'treatment': {'auras': [[1, 1]]}},
                      {**EARNED, 'target': 'dummy'}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                behaviour_scenario(witch_hunter_file(503681), entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_option_earns_the_aura_by_dodges_and_reads_it_before_every_cast(self):
        plain, [plain_expectation] = behaviour_scenario(witch_hunter_file(503681), DARKSLAYER_DAMAGE)
        earned, [earned_expectation] = behaviour_scenario(witch_hunter_file(503681), EARNED)
        self.assertNotIn(hit_ratio_avoided.NAME, plain_expectation.model)
        self.assertFalse(any(step['action'] == 'set_combat_avoidance' for step in plain['steps']))
        self.assertEqual([creature['id'] for creature in earned['creatures']], ['dummy', 'striker', 'striker_2'])
        presence = earned_expectation.model[hit_ratio_avoided.NAME]['presence']
        self.assertEqual({arm: len(labels) for arm, labels in presence.items()}, {'control': 4, 'treatment': 4})
        steps = earned['steps']
        reads = [index for index, step in enumerate(steps) if step.get('metric') == 'aura'
                 and step.get('spell') == 807163]
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step.get('spell') == 804179]
        self.assertEqual(len(reads), 8)
        self.assertEqual(len(casts), 8)
        self.assertTrue(all(read < cast for read, cast in zip(reads, casts)))
        self.assertTrue(all(step['target'] == 'striker' for step in (steps[index] for index in casts)))
        self.assertFalse(any(step['action'] == 'set_aura' and step.get('spell') == 807163 for step in steps))
        self.assertIn(hit_ratio_avoided.NAME, earned['contract'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_first_trial_of_each_arm_swings_for_the_lead_more(self):
        earned, _ = behaviour_scenario(witch_hunter_file(503681), EARNED)
        steps = earned['steps']
        reads = [index for index, step in enumerate(steps) if step.get('metric') == 'aura'
                 and step.get('spell') == 807163]
        windows = []
        for read in reads:
            start = read
            while steps[start - 1]['action'] in ('wait', 'set_health', 'set_combat_avoidance'):
                start -= 1
            windows.append(sum(step['ms'] for step in steps[start:read] if step['action'] == 'wait'))
        self.assertEqual(windows, [4500, 1500, 1500, 1500, 4500, 1500, 1500, 1500])


if __name__ == '__main__':
    unittest.main()
