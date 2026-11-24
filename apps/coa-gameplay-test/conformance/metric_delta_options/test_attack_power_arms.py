from functools import cache
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.attack_power_arms import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

SPELL = 300235
AURA = 35785
ARMS = {'aura': AURA, 'wait_ms': 3600, 'source': 'Attack Power 980 35785, its gain read'}


def armor_entry(**changes) -> dict:
    return {'spell': SPELL, 'name': 'Death Commander (armor at two attack powers)', 'kind': 'metric_delta',
            'label_suffix': 'armor_arms', 'quote': "to increase your and your Undead minion's haste",
            'expected': 1, 'before_expected': 0, 'tolerance': 0.01, 'trigger_spell': 500237, 'target': 'caster',
            'metric': 'armor', 'fields': {}, 'wait_ms': 3600, 'attack_power_arms': ARMS, **changes}


@cache
def armed():
    _, [expectation] = behaviour_scenario(load_fixture_class_file(23), armor_entry())
    return expectation


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AttackPowerArmsTests(unittest.TestCase):
    def test_each_arm_reads_attack_power_around_the_fixture_aura_and_the_metric_at_the_high_power(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), armor_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        recorded = expectation.model['attack_power_arms']
        before = labels.index(expectation.model['before_label'])
        after = labels.index(expectation.model['after_label'])
        learn = max(index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == SPELL)
        control = steps[before + 1:before + 7]
        self.assertEqual([step['action'] for step in control], ['assert', 'set_aura', 'wait', 'assert', 'assert',
                                                                'set_aura'])
        self.assertEqual([control[1]['stacks'], control[5]['stacks']], [1, 0])
        self.assertEqual({control[1]['spell'], control[5]['spell']}, {AURA})
        self.assertEqual(control[2]['ms'], 3600)
        self.assertEqual([control[0]['label'], control[3]['label']],
                         [recorded['power']['control low'], recorded['power']['control high']])
        self.assertEqual(control[4]['label'], recorded['reads']['control high'])
        self.assertEqual(control[4]['metric'], 'armor')
        self.assertLess(before + 6, learn)
        learned = steps[after + 1:after + 6]
        self.assertEqual([step.get('label') for step in learned],
                         [recorded['power']['learned low'], None, None, recorded['power']['learned high'],
                          recorded['reads']['learned high']])
        self.assertEqual(learned[1]['stacks'], 1)
        self.assertIn('Attack power arms', scenario['contract'])

    def test_an_entry_without_the_option_is_unchanged(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     armor_entry(attack_power_arms=None))
        self.assertNotIn('attack_power_arms', expectation.model)
        self.assertFalse(any(step.get('spell') == AURA for step in scenario['steps']))

    def judged(self, before=270.0, after=300.0, control=270.0, learned=340.0, powers=(3100.0, 4080.0, 3100.0, 4080.0),
               drop=None):
        expectation = armed()
        recorded = expectation.model['attack_power_arms']
        found = {expectation.model['before_label']: before, expectation.model['after_label']: after,
                 recorded['reads']['control high']: control, recorded['reads']['learned high']: learned}
        found.update(zip((recorded['power'][arm] for arm in ('control low', 'control high', 'learned low',
                                                             'learned high')), powers))
        if drop:
            found.pop(drop(recorded))
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def test_a_positive_gain_rising_with_attack_power_is_ok_without_asserting_the_before_value(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['arm_gains'], [30.0, 70.0])
        self.assertEqual(verdict.detail['attack_power'], [3100.0, 4080.0, 3100.0, 4080.0])

    def test_a_flat_bonus_alerts(self):
        self.assertEqual(self.judged(learned=300.0).status, 'alert')

    def test_no_bonus_alerts(self):
        self.assertEqual(self.judged(after=270.0, learned=270.0).status, 'alert')
        self.assertEqual(self.judged(after=270.0, learned=320.0).status, 'alert')

    def test_a_falling_gain_alerts(self):
        self.assertEqual(self.judged(learned=290.0).status, 'alert')

    def test_attack_powers_that_do_not_compare_the_same_two_levels_void_the_trial(self):
        for powers in ((3100.0, 3100.0, 3100.0, 3100.0), (3100.0, 4080.0, 3200.0, 4080.0),
                       (3100.0, 4080.0, 3100.0, 4180.0), (3100.0, 3000.0, 3100.0, 3000.0)):
            with self.subTest(powers=powers):
                self.assertEqual(self.judged(powers=powers).status, 'unmeasured')

    def test_a_missing_read_voids_the_trial(self):
        for drop in (lambda recorded: recorded['reads']['control high'],
                     lambda recorded: recorded['power']['learned high']):
            with self.subTest(drop=drop):
                self.assertEqual(self.judged(drop=drop).status, 'unmeasured')

    def test_refused_inputs(self):
        for raw in ({**ARMS, 'wait_ms': 0}, {**ARMS, 'aura': True}, {**ARMS, 'source': ' '}, {**ARMS, 'extra': 1},
                    {key: ARMS[key] for key in ARMS if key != 'wait_ms'}, AURA):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'expected_gain': 1}, {'after_at_least': 1}, {'metric': 'attack_power'}):
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, 'attack_power_arms'):
                behaviour_scenario(load_fixture_class_file(23), armor_entry(**changes))


if __name__ == '__main__':
    unittest.main()
