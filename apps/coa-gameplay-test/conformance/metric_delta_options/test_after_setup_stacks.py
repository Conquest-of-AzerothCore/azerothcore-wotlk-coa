import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

READS = [{'spell': 707901, 'actor': 'dummy', 'stacks': 1}]


def one_bane_entry(**changes) -> dict:
    return {'spell': 706420, 'name': 'Bane of Chaos (only one Bane on a target)', 'kind': 'metric_delta',
            'label_suffix': 'one_bane', 'quote': 'Can only have 1 Bane active on a target at a time.',
            'trigger_spell': 706420, 'target': 'dummy', 'measure_actor': 'dummy', 'cast_power': 100,
            'cast_in_before': False, 'setup_casts': [707901], 'setup_in_before': True, 'setup_wait_ms': 1700,
            'metric': 'aura', 'fields': {'spell': 707901}, 'before_expected': 1, 'expected': 0, 'wait_ms': 500,
            'expire_ms': 500, 'after_setup_stacks': READS, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterSetupStacksTests(unittest.TestCase):
    def built(self, entry):
        scenario, [expectation] = behaviour_scenario(load_class_file(14), entry)
        run.validate(scenario)
        return scenario, expectation

    def test_each_phase_reads_the_unit_after_its_last_setup_cast_and_before_the_trigger(self):
        scenario, expectation = self.built(one_bane_entry())
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        read_labels = expectation.model['after_setup_stacks'][0]['read_labels']
        setups = [index for index, step in enumerate(steps) if step.get('action') == 'cast' and step['spell'] == 707901]
        trigger = next(index for index, step in enumerate(steps)
                       if step.get('action') == 'cast' and step['spell'] == 706420)
        before, after = labels.index(read_labels['before']), labels.index(read_labels['after'])
        self.assertEqual((steps[after]['actor'], steps[after]['metric'], steps[after]['spell']),
                         ('dummy', 'aura_stacks', 707901))
        self.assertTrue(setups[0] < before < labels.index(expectation.model['before_label']))
        self.assertTrue(setups[1] < after < trigger)
        self.assertIn('read at exactly 1 stacks', scenario['contract'])

    def test_without_the_option_the_scenario_is_unchanged(self):
        plain = {key: value for key, value in one_bane_entry().items() if key != 'after_setup_stacks'}
        scenario, expectation = self.built(plain)
        self.assertNotIn('after_setup_stacks', expectation.model)
        self.assertFalse(any('after_setup_stacks' in str(step.get('label')) for step in scenario['steps']))

    def test_a_wrong_count_or_a_missing_after_read_is_unmeasured_and_a_match_is_judged_as_before(self):
        _, expectation = self.built(one_bane_entry(after_setup_stacks=[{'spell': 800058, 'actor': 'caster',
                                                                        'stacks': 5}]))
        model = expectation.model
        read_labels = model['after_setup_stacks'][0]['read_labels']

        def judged(after_value, before_stacks, after_stacks) -> str:
            values = {model['before_label']: 1, model['after_label']: after_value}
            for phase, stacks in (('before', before_stacks), ('after', after_stacks)):
                if stacks is not None:
                    values[read_labels[phase]] = stacks
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(0, 5, 5), 'ok')
        self.assertEqual(judged(1, 5, 5), 'alert')
        self.assertEqual(judged(0, 5, 6), 'unmeasured')
        self.assertEqual(judged(0, 4, 5), 'unmeasured')
        self.assertEqual(judged(1, 5, 4), 'unmeasured')
        self.assertEqual(judged(0, 5, None), 'unmeasured')
        self.assertEqual(judged(0, None, 5), 'ok')

    def test_refused_inputs(self):
        for raw in (True, [], [{'spell': 707901, 'actor': 'dummy'}], [{'spell': 707901, 'actor': 'ally', 'stacks': 1}],
                    [{'spell': 707901, 'actor': 'dummy', 'stacks': -1}],
                    [{'spell': 707901, 'actor': 'dummy', 'stacks': True}], [*READS, *READS]):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(14), one_bane_entry(after_setup_stacks=raw))
        no_setup = {key: value for key, value in one_bane_entry().items()
                    if key not in ('setup_casts', 'setup_in_before', 'setup_wait_ms')}
        with self.assertRaises(ValueError):
            behaviour_scenario(load_class_file(14), no_setup)


if __name__ == '__main__':
    unittest.main()
