import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

COUNT = '704500 before_reference count'
PRESENT = '704500 before_reference present'


def beneath_entry(**changes) -> dict:
    return {'spell': 704500, 'name': 'Hexfire Adept (the ward stands beneath the target)', 'kind': 'metric_delta',
            'label_suffix': 'ward_beneath', 'quote': 'transforms your next Malefic Wrath', 'trigger_spell': 807480,
            'target': 'dummy', 'measure_actor': 'caster', 'setup_casts': [573026], 'setup_wait_ms': 1600,
            'cast_power': 2000, 'metric': 'owned_creature_distance_2d', 'fields': {'entry': 50587, 'target': 'dummy'},
            'before_reference': {'metric': 'distance_2d', 'fields': {'target': 'dummy'}}, 'dummy_distance': 20,
            'before_expected': 20, 'expected': 0, 'tolerance': 0.25, 'wait_ms': 2200, 'expire_ms': 500, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BeforeReferenceTests(unittest.TestCase):
    def scenario(self, entry: dict):
        return behaviour_scenario(load_fixture_class_file(23), entry)

    def test_the_before_read_is_the_reference_and_the_after_read_needs_the_summon(self):
        scenario, [expectation] = self.scenario(beneath_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        before, after = expectation.model['before_label'], expectation.model['after_label']
        count, read = steps[labels.index(COUNT)], steps[labels.index(before)]
        self.assertEqual((count['metric'], count['entry']), ('owned_creature_count', 50587))
        self.assertEqual(labels.index(COUNT) + 1, labels.index(before))
        self.assertEqual((read['metric'], read['target']), ('distance_2d', 'dummy'))
        self.assertNotIn('entry', read)
        present = steps[labels.index(PRESENT)]
        self.assertEqual((present['metric'], present['entry'], present['equals']), ('owned_creature_count', 50587, 1))
        self.assertEqual(labels.index(PRESENT) + 1, labels.index(after))
        self.assertEqual(steps[labels.index(after)]['metric'], 'owned_creature_distance_2d')

    def test_without_the_option_the_before_read_stays(self):
        entry = {key: value for key, value in beneath_entry().items() if key != 'before_reference'}
        scenario, [expectation] = self.scenario(entry)
        labels = [step.get('label') for step in scenario['steps']]
        self.assertNotIn('before_reference', expectation.model)
        self.assertFalse({COUNT, PRESENT} & set(labels))

    def test_refused_inputs(self):
        for changes in ({'before_reference': {'metric': 'distance_2d', 'other': 1}},
                        {'before_reference': {'metric': 'owned_creature_distance_2d'}},
                        {'metric': 'distance_2d', 'fields': {'target': 'dummy'}},
                        {'fields': {'target': 'dummy'}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.scenario(beneath_entry(**changes))

    def test_the_count_gates_the_reference(self):
        _, [expectation] = self.scenario(beneath_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(after_value: float, count: float | None) -> str:
            values = {before: 20.0, after: after_value}
            if count is not None:
                values[COUNT] = count
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(0.0, 0), 'ok')
        self.assertEqual(judged(18.5, 0), 'alert')
        self.assertEqual(judged(0.0, 1), 'alert')
        self.assertEqual(judged(0.0, None), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
