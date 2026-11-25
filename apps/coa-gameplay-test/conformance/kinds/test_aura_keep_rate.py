import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.aura_keep_rate import keep_rate_verdict, residual_failure
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 680538, 'name': "Lightbringer (kept by Purifier's Edge)", 'kind': 'aura_keep_rate',
         'label_suffix': 'keep_rate', 'quote': "This effect has a 25% chance to not be consumed by Purifier's Edge.",
         'aura': 680539, 'consumer': 802434, 'control_spell': 803369, 'chance_pct': 25, 'trials': 40,
         'control_trials': 4, 'control_auras': [[680486, 1]], 'learn': [680538], 'off_hand_item': 2492}
PREFIX = '680538 behaviour_metric_delta keep_rate'


def readings(kept: int, trials: int = 40, control_kept: int = 4, failed: int = 0) -> dict:
    values = {}
    for trial in range(1, 5):
        values[f'{PREFIX} control {trial} aura'] = 1.0 if trial <= control_kept else 0.0
        values[f'{PREFIX} control {trial} cast'] = 0.0
    for trial in range(1, trials + 1):
        values[f'{PREFIX} treatment {trial} aura'] = 1.0 if trial <= kept else 0.0
        values[f'{PREFIX} treatment {trial} cast'] = 31.0 if trial > trials - failed else 0.0
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraKeepRateTests(unittest.TestCase):
    def generated(self, entry=None):
        return behaviour_scenario(load_fixture_class_file(19), entry or ENTRY)

    def test_every_cast_sets_the_aura_first_and_reads_it_after(self):
        scenario, _ = self.generated()
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 44)
        self.assertEqual({steps[index]['spell'] for index in casts[:4]}, {803369})
        self.assertEqual({steps[index]['spell'] for index in casts[4:]}, {802434})
        for index in casts:
            fixture = max(position for position in range(index) if steps[position]['action'] == 'set_aura'
                          and steps[position]['spell'] == 680539)
            self.assertGreater(fixture, max(position for position in range(index)
                                            if steps[position]['action'] == 'cast' or position == 0))
            self.assertEqual(steps[index + 2]['metric'], 'aura')
            self.assertEqual(steps[index + 3]['metric'], 'cast_failure')
        equip = next(index for index, step in enumerate(steps) if step['action'] == 'equip' and step['slot'] == 16)
        self.assertLess(equip, casts[0])

    def test_the_contract_states_the_sizing(self):
        pilot, _ = self.generated()
        self.assertIn('fewer than the 12443 the band needs', pilot['contract'])
        pooled, _ = self.generated({**ENTRY, 'trials': 320, 'parts': 59})
        self.assertIn('probability 1.6e-04 per run', pooled['contract'])

    def test_the_residual_failure_follows_the_band(self):
        self.assertAlmostEqual(residual_failure(0.25, 18880), 1.63e-4, delta=0.01e-4)
        self.assertIsNone(residual_failure(0.25, 320))

    def test_a_pilot_states_its_interval_without_a_verdict(self):
        _, [expectation] = self.generated()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(readings(10)), expectation)
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIsNotNone(verdict.low)
        self.assertIn('680539 set by harness set_aura', verdict.explanation)

    def test_pooled_parts_inside_the_band_pass_and_far_off_alert(self):
        _, [expectation] = self.generated()
        base = base_verdict(expectation)
        inside = [FakeRun(readings(10)) for _ in range(500)]
        self.assertEqual(keep_rate_verdict(base, inside, expectation.model).status, 'ok')
        far = [FakeRun(readings(20)) for _ in range(500)]
        self.assertEqual(keep_rate_verdict(base, far, expectation.model).status, 'alert')

    def test_a_consumed_control_alerts_and_failed_casts_are_no_trials(self):
        _, [expectation] = self.generated()
        base = base_verdict(expectation)
        self.assertEqual(keep_rate_verdict(base, [FakeRun(readings(10, control_kept=3))] * 500,
                                           expectation.model).status, 'alert')
        verdict = keep_rate_verdict(base, [FakeRun(readings(10, failed=40))], expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertEqual(verdict.detail['failed'], 40)

    def test_a_missing_read_is_unmeasured(self):
        _, [expectation] = self.generated()
        values = readings(10)
        del values[f'{PREFIX} treatment 7 aura']
        verdict = keep_rate_verdict(base_verdict(expectation), [FakeRun(values)], expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_aura_stacks_set_the_consumer_cost_before_every_cast(self):
        scenario, _ = self.generated({**ENTRY, 'aura_stacks': 2})
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 44)
        for index in casts:
            self.assertEqual(steps[index - 2], {'action': 'set_aura', 'actor': 'caster', 'spell': 680539,
                                                'stacks': 2})
        self.assertIn('680539 is set at 2 stacks', scenario['contract'])

    def test_without_aura_stacks_one_stack_is_set(self):
        scenario, expectations = self.generated()
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        for index in casts[4:]:
            self.assertEqual(steps[index - 2], {'action': 'set_aura', 'actor': 'caster', 'spell': 680539,
                                                'stacks': 1})
            self.assertNotEqual(steps[index - 3]['action'], 'set_aura')
        self.assertNotIn('stacks, the consumer', scenario['contract'])
        self.assertEqual((scenario, expectations), self.generated({**ENTRY, 'aura_stacks': 1}))

    def test_a_talent_that_never_keeps_the_stacked_aura_alerts(self):
        _, [expectation] = self.generated({**ENTRY, 'aura_stacks': 2})
        never = [FakeRun(readings(0)) for _ in range(500)]
        self.assertEqual(keep_rate_verdict(base_verdict(expectation), never, expectation.model).status, 'alert')

    def test_stacks_below_one_are_refused(self):
        with self.assertRaises(ValueError):
            self.generated({**ENTRY, 'aura_stacks': 0})

    def test_the_control_spell_must_differ_from_the_consumer(self):
        with self.assertRaises(ValueError):
            self.generated({**ENTRY, 'control_spell': 802434})
