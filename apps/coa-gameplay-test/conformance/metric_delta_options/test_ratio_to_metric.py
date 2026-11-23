import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def ratio_entry(**changes) -> dict:
    return {'spell': 705911, 'name': 'Spiritual Traditions (regeneration while casting)', 'kind': 'metric_delta',
            'label_suffix': 'regen_casting', 'quote': 'Allows $s2% of your mana regeneration to continue while casting',
            'expected': 0.4, 'before_expected': 0, 'tolerance': 0.001, 'trigger_spell': 801663, 'target': 'caster',
            'metric': 'mana_regen_interrupted', 'fields': {}, 'ratio_to_metric': {'metric': 'mana_regen'},
            **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RatioToMetricTests(unittest.TestCase):
    def test_each_judged_reading_is_followed_by_its_base_read(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ratio_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        for moment in ('before', 'after'):
            label = expectation.model[f'{moment}_label']
            base = scenario['steps'][labels.index(label) + 1]
            self.assertEqual((base['label'], base['actor'], base['metric']),
                             (f'{label} ratio base', 'caster', 'mana_regen'))
        self.assertIn('divided by mana_regen', scenario['contract'])

    def test_without_the_option_no_base_read_is_made(self):
        entry = {key: value for key, value in ratio_entry().items() if key != 'ratio_to_metric'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('ratio_to_metric', expectation.model)
        self.assertFalse(any(str(step.get('label', '')).endswith('ratio base') for step in scenario['steps']))

    def test_refused_inputs(self):
        for raw in ({}, [1], {'metric': 'mana_regen', 'other': 1}, {'metric': 'mana_regen_interrupted'},
                    {'metric': 'mana_regen', 'fields': [1]}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), ratio_entry(ratio_to_metric=raw))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), ratio_entry(fields_sum={'power': 0}))

    def test_the_judge_reads_the_share(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ratio_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(before_value, before_base, after_value, after_base) -> str:
            reads = {before: before_value, f'{before} ratio base': before_base, after: after_value,
                     f'{after} ratio base': after_base}
            reads = {label: value for label, value in reads.items() if value is not None}
            return judge_behaviour(base_verdict(expectation), FakeRun(reads), expectation).status

        self.assertEqual(judged(0, 5.5, 2.2, 5.5), 'ok')
        self.assertEqual(judged(0, 5.5, 5.5, 5.5), 'alert')
        self.assertEqual(judged(0.5, 5.5, 2.2, 5.5), 'alert')
        self.assertEqual(judged(0, 5.5, 2.2, 0), 'alert')
        self.assertEqual(judged(0, 5.5, 2.2, None), 'alert')

    def test_increments_divide_the_after_phase_growth(self):
        entry = ratio_entry(ratio_to_metric={'metric': 'mana_regen', 'increments': True})
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(after_value, after_base) -> str:
            reads = {before: 0, f'{before} ratio base': 500, after: after_value, f'{after} ratio base': after_base}
            return judge_behaviour(base_verdict(expectation), FakeRun(reads), expectation).status

        self.assertEqual(judged(200, 1000), 'ok')
        self.assertEqual(judged(200, 500), 'alert')
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23),
                               ratio_entry(ratio_to_metric={'metric': 'mana_regen', 'increments': 1}))


if __name__ == '__main__':
    unittest.main()
