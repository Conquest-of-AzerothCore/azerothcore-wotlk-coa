import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

READS = [{'spell': 1604, 'expected': 0}]


def snare_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 503740 and entry.get('variant') == 'snare_control')
    return {**entry, 'strike_landed': True, 'after_start_reads': READS, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterStartReadsTests(unittest.TestCase):
    def test_the_read_sits_in_the_after_phase_only(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        label = expectation.model['after_start_reads'][0]['read_label']
        self.assertEqual(labels.count(label), 1)
        read = scenario['steps'][labels.index(label)]
        self.assertEqual((read['metric'], read['spell']), ('aura_stacks', 1604))
        self.assertGreater(labels.index(label), labels.index(expectation.model['before_label']))
        self.assertLess(labels.index(label), labels.index(expectation.model['after_label']))

    def test_without_the_option_nothing_is_read(self):
        entry = {key: value for key, value in snare_entry().items() if key != 'after_start_reads'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('after_start_reads', expectation.model)
        self.assertFalse(any('after_start_reads' in str(step.get('label')) for step in scenario['steps']))

    def test_the_option_needs_spells_with_an_expected_state(self):
        for raw in (True, [], [{'spell': 1604}], [{'spell': 1604, 'expected': 2}], [{'spell': '1604', 'expected': 0}],
                    [*READS, *READS]):
            with self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), snare_entry(after_start_reads=raw))

    def test_a_mismatch_is_unmeasured_and_a_match_is_judged_as_before(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        logs = expectation.model['strike_landed']['log_label']
        read = expectation.model['after_start_reads'][0]['read_label']

        def judged(before_value: float, stacks: float | None) -> str:
            values = {before: before_value, after: 0.57143, logs: 4}
            if stacks is not None:
                values[read] = stacks
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(1.14286, 0), 'ok')
        self.assertEqual(judged(0.57143, 0), 'alert')
        self.assertEqual(judged(1.14286, 1), 'unmeasured')
        self.assertEqual(judged(0.57143, 1), 'unmeasured')
        self.assertEqual(judged(1.14286, None), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
