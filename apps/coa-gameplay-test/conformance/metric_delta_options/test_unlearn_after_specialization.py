import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict


def teach_entry(**changes) -> dict:
    return {'spell': 92131, 'name': 'Herald of the Depths (teaches 520326)', 'kind': 'metric_delta',
            'label_suffix': 'teaches_herald', 'quote': 'Teaches you Herald of the Depths.',
            'trigger_spell': 60235, 'gate_spell': 92131, 'target': 'caster', 'cast_in_before': False,
            'metric': 'knows_spell', 'fields': {'spell': 520326}, 'before_expected': 0, 'expected': 1,
            'expected_gain': 1, 'tolerance': 0, 'wait_ms': 500, 'expire_ms': 500,
            'specialization': 40, 'unlearn_after_specialization': [92131, 520326], **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class UnlearnAfterSpecializationTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(load_class_file(25), teach_entry(**changes))

    def judged(self, before=0.0, after=1.0, **changes):
        _, [expectation] = self.build(**changes)
        values = {}
        if before is not None:
            values[expectation.model['before_label']] = before
        if after is not None:
            values[expectation.model['after_label']] = after
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_unlearns_run_after_specialization_and_before_the_before_reading(self):
        scenario, [expectation] = self.build()
        run.validate(scenario)
        steps = scenario['steps']
        switched = [index for index, step in enumerate(steps) if step['action'] == 'specialization']
        unlearned = [(index, step['spell']) for index, step in enumerate(steps) if step['action'] == 'unlearn']
        learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': 92131})
        labels = [step.get('label') for step in steps]
        self.assertEqual(len(switched), 1)
        self.assertEqual([spell for _, spell in unlearned], [92131, 520326])
        self.assertLess(switched[0], unlearned[0][0])
        self.assertLess(unlearned[-1][0], labels.index(expectation.model['before_label']))
        self.assertLess(labels.index(expectation.model['before_label']), learn)
        self.assertLess(learn, labels.index(expectation.model['after_label']))

    def test_without_the_option_nothing_is_unlearned(self):
        entry = {key: value for key, value in teach_entry().items() if key != 'unlearn_after_specialization'}
        scenario, _ = behaviour_scenario(load_class_file(25), entry)
        self.assertFalse(any(step['action'] == 'unlearn' for step in scenario['steps']))

    def test_control_to_learned_is_ok_and_mutants_alert(self):
        self.assertEqual(self.judged(0.0, 1.0).status, 'ok')
        self.assertEqual(self.judged(1.0, 1.0).status, 'alert')
        self.assertEqual(self.judged(0.0, 0.0).status, 'alert')
        self.assertEqual(self.judged(0.0, 1.0, expected=0, expected_gain=0).status, 'alert')
        self.assertEqual(self.judged(0.0, None).status, 'alert')

    def test_refused_inputs(self):
        for raw in ([], [0], ['92131'], [92131, 92131], 92131, [True]):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                self.build(unlearn_after_specialization=raw)
        without_spec = {key: value for key, value in teach_entry().items() if key != 'specialization'}
        with self.assertRaises(ValueError):
            behaviour_scenario(load_class_file(25), without_spec)


if __name__ == '__main__':
    unittest.main()
