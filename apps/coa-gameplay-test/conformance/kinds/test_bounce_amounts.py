import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun


def bounce_entry(**changes) -> dict:
    return {'spell': 560596, 'name': 'Crypt Keeper (reduced value per enemy struck)', 'kind': 'bounce_amounts',
            'label_suffix': 'reduced_value', 'quote': 'at ${-($800343f1-1)*100}% reduced value per enemy struck.',
            'cast_spell': 501886, 'hit_spell': 800343, 'distances': [5, 8, 11], 'cast_wait_ms': 3600,
            'cast_power': 1373, 'caster_auras': [984954, 823764], **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BounceAmountsTests(unittest.TestCase):
    def judged(self, control: list[tuple[float, float]], treatment: list[tuple[float, float]]) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), bounce_entry())
        values = {}
        for arm, rows in (('control', control), ('treatment', treatment)):
            for labels, (total, count) in zip(expectation.model['reads'][arm], rows):
                values[labels[0]], values[labels[1]] = total, count
        for labels, (total, count), (before_total, before_count) in zip(expectation.model['reads']['treatment'],
                                                                          treatment, control):
            values[labels[0]], values[labels[1]] = before_total + total, before_count + count
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_dummies_and_both_arms_are_placed(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), bounce_entry())
        run.validate(scenario)
        self.assertEqual([creature['distance'] for creature in scenario['creatures']], [5.0, 8.0, 11.0, 27.0])
        self.assertEqual([round(ratio, 4) for ratio in expectation.model['ratios']], [0.7, 0.49])
        learned = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learned[-1], 560596)

    def test_the_stated_bounces_pass_and_mutants_alert(self):
        control = [(2088.0, 6.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0)]
        stated = [(2088.0, 6.0), (1458.0, 6.0), (1020.0, 6.0), (0.0, 0.0)]
        self.assertEqual(self.judged(control, stated).status, 'ok')
        unreduced = [(2088.0, 6.0), (2088.0, 6.0), (2088.0, 6.0), (0.0, 0.0)]
        self.assertEqual(self.judged(control, unreduced).status, 'alert')
        unbounced = [(2088.0, 6.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0)]
        self.assertEqual(self.judged(control, unbounced).status, 'alert')
        far = [(2088.0, 6.0), (1458.0, 6.0), (1020.0, 6.0), (348.0, 1.0)]
        self.assertEqual(self.judged(control, far).status, 'alert')
        bounced_control = [(2088.0, 6.0), (1458.0, 6.0), (0.0, 0.0), (0.0, 0.0)]
        self.assertEqual(self.judged(bounced_control, stated).status, 'alert')

    def test_dummies_out_of_order_are_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), bounce_entry(distances=[8, 5, 11]))
