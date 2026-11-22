import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.same_arm_ratio import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

DANCE = 804912
STACKS = 560651
RATIO = {'metric': 'melee_damage_count', 'fields': {}, 'ratio': 1, 'tolerance': 0.05, 'least': 5,
         'main_below': 20, 'source': 'example tooltip "1 stack per auto attack"'}


def ratio_entry(**changes) -> dict:
    return {'spell': DANCE, 'name': 'Parry Dance (stacks per swing)', 'kind': 'metric_delta',
            'label_suffix': 'per_swing', 'quote': 'stacking', 'expected': 1, 'before_expected': 0,
            'trigger_spell': STACKS, 'metric': 'aura_stacks', 'fields': {'spell': STACKS}, 'target': 'dummy',
            'attack_swings': 10, 'expire_ms': 6000, 'same_arm_ratio': dict(RATIO), **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SameArmRatioTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(19), ratio_entry(**changes))

    def test_the_second_metric_is_read_right_after_each_reading(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        recorded = expectation.model['same_arm_ratio']
        for moment in ('before', 'after'):
            read = labels.index(expectation.model[f'{moment}_label'])
            self.assertEqual(labels[read + 1], recorded['parts'][moment])
            part = scenario['steps'][read + 1]
            self.assertEqual((part['metric'], part['actor']), ('melee_damage_count', 'caster'))
        self.assertIn('Same-arm ratio', scenario['contract'])

    def test_an_entry_without_the_option_is_unchanged(self):
        scenario, [expectation] = self.built(same_arm_ratio=None)
        self.assertNotIn('same_arm_ratio', expectation.model)
        self.assertFalse(any('same_arm_ratio' in str(step.get('label')) for step in scenario['steps']))

    def judged(self, main=(0.0, 6.0), part=(10.0, 16.0), drop=None):
        _, [expectation] = self.built()
        recorded = expectation.model['same_arm_ratio']
        found = {expectation.model['before_label']: main[0], expectation.model['after_label']: main[1],
                 recorded['parts']['before']: part[0], recorded['parts']['after']: part[1]}
        if drop:
            found.pop(recorded['parts'][drop])
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def test_one_stack_per_landed_swing_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 1.0)
        self.assertEqual((verdict.low, verdict.high), (0.95, 1.05))
        self.assertEqual(verdict.detail['same_arm_gains'], [6.0, 6.0])

    def test_two_stacks_per_swing_alerts(self):
        verdict = self.judged(main=(0.0, 12.0), part=(10.0, 16.0))
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 2.0)

    def test_a_count_off_by_one_alerts(self):
        self.assertEqual(self.judged(main=(0.0, 6.0), part=(5.0, 12.0)).status, 'alert')
        self.assertEqual(self.judged(main=(1.0, 8.0), part=(5.0, 11.0)).status, 'alert')

    def test_an_arm_that_cannot_judge_the_ratio_is_unmeasured(self):
        for reads in ({'part': (10.0, 14.0), 'main': (0.0, 4.0)}, {'main': (0.0, 20.0), 'part': (0.0, 20.0)},
                      {'drop': 'after'}, {'drop': 'before'}):
            with self.subTest(reads=reads):
                self.assertEqual(self.judged(**reads).status, 'unmeasured')

    def test_refused_inputs(self):
        for raw in ({**RATIO, 'source': ''}, {**RATIO, 'ratio': 0}, {**RATIO, 'least': True},
                    {**RATIO, 'extra': 1}, {key: RATIO[key] for key in RATIO if key != 'least'},
                    {**RATIO, 'tolerance': -0.1}, {**RATIO, 'fields': []}, 'melee_damage_count'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'same_arm_ratio': {**RATIO, 'metric': 'aura_stacks', 'fields': {'spell': STACKS}}},
                        {'expected_ratio': 2.0, 'tolerance': 0.2}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
