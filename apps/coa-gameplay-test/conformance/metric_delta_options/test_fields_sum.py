import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def count_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (two counted spells)', 'kind': 'metric_delta',
            'label_suffix': 'two_counts', 'quote': "to increase your and your Undead minion's haste",
            'expected': 1, 'before_expected': 0, 'trigger_spell': 500237, 'target': 'dummy',
            'metric': 'spell_damage_count', 'fields': {'spell': 500237, 'target': 'dummy'},
            'fields_sum': {'spell': 500238, 'target': 'dummy'}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FieldsSumTests(unittest.TestCase):
    def test_each_judged_reading_is_followed_by_the_second_read(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), count_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        for moment in ('before', 'after'):
            label = expectation.model[f'{moment}_label']
            part = scenario['steps'][labels.index(label) + 1]
            self.assertEqual(part['label'], f'{label} sum part')
            self.assertEqual((part['metric'], part['spell'], part['target']), ('spell_damage_count', 500238, 'dummy'))
        self.assertIn('sum of two reads', scenario['contract'])

    def test_without_the_option_no_second_read_is_made(self):
        entry = {key: value for key, value in count_entry().items() if key != 'fields_sum'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('fields_sum', expectation.model)
        self.assertFalse(any(str(step.get('label', '')).endswith('sum part') for step in scenario['steps']))

    def test_the_option_is_a_distinct_field_set(self):
        for raw in ({}, [1], {'spell': 500237, 'target': 'dummy'}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), count_entry(fields_sum=raw))

    def test_the_judge_reads_the_sum_and_a_second_hit_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), count_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(**values) -> str:
            reads = {before: values['before'], f'{before} sum part': values['before_part'],
                     after: values['after'], f'{after} sum part': values['after_part']}
            reads = {label: value for label, value in reads.items() if value is not None}
            return judge_behaviour(base_verdict(expectation), FakeRun(reads), expectation).status

        self.assertEqual(judged(before=0, before_part=0, after=1, after_part=0), 'ok')
        self.assertEqual(judged(before=0, before_part=0, after=0, after_part=1), 'ok')
        self.assertEqual(judged(before=0, before_part=0, after=1, after_part=1), 'alert')
        self.assertEqual(judged(before=0, before_part=0, after=0, after_part=0), 'alert')
        self.assertEqual(judged(before=0, before_part=1, after=0, after_part=1), 'alert')
        self.assertEqual(judged(before=0, before_part=0, after=1, after_part=None), 'alert')


if __name__ == '__main__':
    unittest.main()
