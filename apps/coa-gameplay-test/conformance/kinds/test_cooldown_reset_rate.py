import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 561353, 'name': 'Unholy Runes (Corpse Explosion reset rate)', 'kind': 'cooldown_reset_rate',
         'label_suffix': 'reset_rate', 'quote': 'a $h% chance to reset the cooldown of Corpse Explosion.',
         'talent': 561353, 'trigger_spell': 500237, 'reset_spell': 533236, 'chance_pct': 5, 'casts': 3300,
         'control_casts': 200, 'cast_wait_ms': 50}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownResetRateTests(unittest.TestCase):
    def judged(self, resets: float, control_resets: float = 0.0, hits: float = 3300.0):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        reads = expectation.model['reads']
        values = {reads['control hits']: 200.0, reads['control resets']: control_resets,
                  reads['treatment hits']: 200.0 + hits, reads['treatment resets']: control_resets + resets}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_resets_are_clear_cooldown_packets_of_the_reset_spell_after_the_learn(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 561353)
        packets = [index for index, step in enumerate(steps) if step.get('metric') == 'server_packets']
        self.assertEqual([steps[index]['row'] for index in packets], [533236, 533236])
        self.assertEqual({steps[index]['opcode'] for index in packets}, {0x1DE})
        self.assertLess(packets[0], learn)
        self.assertLess(learn, packets[1])

    def test_a_rate_inside_the_band_passes_and_far_off_it_alerts(self):
        self.assertEqual(self.judged(153.0).status, 'ok')
        self.assertEqual(self.judged(660.0).status, 'alert')

    def test_a_control_reset_alerts(self):
        self.assertEqual(self.judged(153.0, control_resets=1.0).status, 'alert')

    def test_fewer_casts_than_the_band_needs_are_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'casts': 500})


FLAT_COST_TRIGGER = 504868
PERCENT_COST_TRIGGER = 707402


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownResetRateCastPowerTests(unittest.TestCase):
    def test_a_cast_power_refills_the_trigger_power_before_every_cast(self):
        entry = {**ENTRY, 'trigger_spell': FLAT_COST_TRIGGER, 'cast_power': 300, 'casts': 3200,
                 'control_casts': 100}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps)
                 if step['action'] == 'cast' and step['spell'] == FLAT_COST_TRIGGER]
        self.assertEqual(len(casts), 3300)
        self.assertTrue(all(steps[index - 1] == {'action': 'set_power', 'actor': 'caster', 'power': 6, 'value': 300}
                            for index in casts))

    def test_without_a_cast_power_a_costly_trigger_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'trigger_spell': FLAT_COST_TRIGGER})

    def test_a_cast_power_below_the_cost_or_on_a_percent_cost_is_refused(self):
        for trigger, power in ((FLAT_COST_TRIGGER, 299), (PERCENT_COST_TRIGGER, 1000)):
            with self.subTest(trigger=trigger), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'trigger_spell': trigger,
                                                                 'cast_power': power})

    def test_a_free_trigger_without_a_cast_power_sets_no_power(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertFalse(any(step['action'] == 'set_power' and step.get('power') is not None
                             and step.get('value') == 300 for step in scenario['steps']))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownResetRateAttemptAuraTests(unittest.TestCase):
    AURAS = [{'spell': 803166, 'stacks': 1, 'source': 'the trigger\'s CasterAuraSpell'}]

    def test_the_auras_are_set_before_every_cast(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'casts': 3200, 'control_casts': 10,
                                                                       'attempt_auras': self.AURAS})
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 3210)
        self.assertTrue(all(steps[index - 1] == {'action': 'set_aura', 'actor': 'caster', 'spell': 803166, 'stacks': 1}
                            for index in casts))
        self.assertIn('Aura 803166 is set on the caster', scenario['contract'])

    def test_without_attempt_auras_no_aura_is_set(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertFalse(any(step['action'] == 'set_aura' for step in scenario['steps']))

    def test_attempt_auras_name_their_spell_stacks_and_source(self):
        for raw in ([], [{'spell': 803166, 'stacks': 1}], [{'spell': '803166', 'stacks': 1, 'source': 'x'}], {}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'attempt_auras': raw})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownResetRatePooledTests(unittest.TestCase):
    POOLED = {**ENTRY, 'casts': 800, 'parts': 4}

    def runs(self, resets_per_part, control_resets=(0.0, 0.0, 0.0, 0.0)):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), self.POOLED)
        reads = expectation.model['reads']
        return expectation, [FakeRun({reads['control hits']: 200.0, reads['control resets']: control,
                                      reads['treatment hits']: 1000.0, reads['treatment resets']: control + resets})
                             for resets, control in zip(resets_per_part, control_resets)]

    def test_the_parts_are_pooled_into_one_rate(self):
        from kinds.cooldown_reset_rate import POOLED_JUDGE
        expectation, runs = self.runs((40.0, 41.0, 39.0, 40.0))
        verdict = POOLED_JUDGE(base_verdict(expectation), runs, expectation.model)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail, {'resets': 160.0, 'hits': 3200.0})
        self.assertIn('over 4 pooled parts', verdict.explanation)

    def test_a_pooled_rate_off_the_band_or_a_control_reset_in_one_part_alerts(self):
        from kinds.cooldown_reset_rate import POOLED_JUDGE
        expectation, runs = self.runs((80.0, 80.0, 80.0, 80.0))
        self.assertEqual(POOLED_JUDGE(base_verdict(expectation), runs, expectation.model).status, 'alert')
        expectation, runs = self.runs((40.0, 40.0, 40.0, 40.0), control_resets=(0.0, 1.0, 0.0, 0.0))
        self.assertEqual(POOLED_JUDGE(base_verdict(expectation), runs, expectation.model).status, 'alert')

    def test_the_pooled_casts_must_reach_the_band_trials(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**self.POOLED, 'parts': 3})
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), self.POOLED)
        self.assertIn('one of 4 identical pooled parts', scenario['contract'])
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertNotIn('pooled parts', scenario['contract'])

    def test_the_dummy_can_stand_at_a_stated_distance(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'dummy_distance': 17.5})
        self.assertEqual(scenario['creatures'][0]['distance'], 17.5)
        self.assertIn('17.5 yd from the caster', scenario['contract'])
        plain, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertNotIn('yd from the caster', plain['contract'])
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'dummy_distance': 0})
