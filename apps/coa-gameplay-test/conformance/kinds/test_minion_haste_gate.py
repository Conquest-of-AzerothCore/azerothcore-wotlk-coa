import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 537208, 'name': 'Dominion of Frost (one cut per second, two swing intervals)',
         'kind': 'minion_haste_gate', 'label_suffix': 'once_per_sec_arms', 'quote': 'Can only occur once per sec.',
         'learn': [92123], 'raise': [500971, 50073, 1000], 'base_attack_ms': 2000, 'crit_aura': [280912, 100],
         'haste_aura': [525388, 0], 'gate_ms': 1000, 'cut_ms': 3000, 'observe_spell': 805029,
         'observe_power': 1373, 'cleared_auras': [805029], 'window_ms': 4000,
         'arms': [{'attack_ms': 1250, 'attempts_ms': [40000, 66000]},
                  {'attack_ms': 800, 'attempts_ms': [52000, 72000]}]}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MinionHasteGateTests(unittest.TestCase):
    def judged(self, outcomes, attack_times=(1250.0, 800.0), crits=(50.0, 85.0)) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = {}
        for arm, (early, late), attack, crit in zip(expectation.model['arms'], outcomes, attack_times, crits):
            values.update({arm['attack_time']: attack, arm['primed']: 179800.0, arm['primed_crits']: 10.0,
                           arm['attempts'][0]: early, arm['attempts'][1]: late,
                           arm['crits'][0]: 10.0 + crit / 2, arm['crits'][1]: 10.0 + crit})
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_one_minion_swings_at_each_arm_interval_through_the_haste_amount(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        hastes = {step['amount'] for step in scenario['steps']
                  if step['action'] == 'set_aura' and step['spell'] == 525388 and step['stacks'] == 1}
        self.assertEqual(hastes, {60, 150})
        raised = [step for step in scenario['steps'] if step.get('metric') == 'owned_creature_count']
        self.assertEqual([(step['entry'], step['equals']) for step in raised], [(50073, 1)])

    def test_band_arms_swing_at_the_truncated_interval_of_a_whole_haste_percent(self):
        arms = [{'attack_ms': 1047, 'attempts_ms': [38000, 58000]}, {'attack_ms': 952, 'attempts_ms': [54000, 80000]}]
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'arms': arms})
        run.validate(scenario)
        hastes = {step['amount'] for step in scenario['steps']
                  if step['action'] == 'set_aura' and step['spell'] == 525388 and step['stacks'] == 1}
        self.assertEqual(hastes, {91, 110})
        self.assertEqual([arm['accepted_ms'] for arm in expectation.model['arms']], [1047, 1904])

    def test_the_frenzy_haste_is_cleared_after_each_priming_cast(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        cleared = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == 805029]
        self.assertEqual(len(cleared), 4)
        self.assertTrue(all(step['stacks'] == 0 for step in cleared))

    def test_a_one_second_gate_passes(self):
        self.assertEqual(self.judged(((67, 0), (67, 0))).status, 'ok')

    def test_an_ungated_cut_clears_the_fast_arm_early_and_alerts(self):
        self.assertEqual(self.judged(((67, 0), (0, 67))).status, 'alert')

    def test_a_gate_longer_than_the_slow_swing_alerts(self):
        self.assertEqual(self.judged(((67, 67), (67, 0))).status, 'alert')

    def test_a_gate_longer_than_two_fast_swings_alerts(self):
        self.assertEqual(self.judged(((67, 0), (67, 67))).status, 'alert')

    def test_a_minion_off_its_interval_is_unmeasured(self):
        self.assertEqual(self.judged(((67, 0), (67, 0)), attack_times=(1250.0, 1000.0)).status, 'unmeasured')

    def test_too_few_crits_are_unmeasured(self):
        self.assertEqual(self.judged(((67, 0), (67, 0)), crits=(50.0, 20.0)).status, 'unmeasured')

    def test_attempts_that_cannot_separate_the_gate_are_rejected(self):
        for arms in ([{'attack_ms': 1250, 'attempts_ms': [40000, 90000]}, ENTRY['arms'][1]],
                     [ENTRY['arms'][0], {'attack_ms': 800, 'attempts_ms': [40000, 72000]}],
                     [ENTRY['arms'][0], {'attack_ms': 1100, 'attempts_ms': [40000, 72000]}]):
            with self.subTest(arms=arms), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'arms': arms})

    def test_the_gate_is_an_event_read_that_proves_the_behaviour(self):
        from coverage import BEHAVIOUR, verdict_evidence
        found = self.judged(((67, 0), (67, 0)))
        self.assertEqual(found.detail['metric'], 'cast_failure')
        self.assertEqual(verdict_evidence(found, ENTRY['quote'], {}), BEHAVIOUR)
