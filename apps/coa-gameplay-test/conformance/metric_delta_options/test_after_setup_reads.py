import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

READS = [{'spell': 707421, 'expected': 1}]


def minion_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 92122 and entry.get('variant') == 'minion_crit_third')
    return {**entry, 'after_setup_reads': READS, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterSetupReadsTests(unittest.TestCase):
    def built(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        return scenario, expectation

    def test_each_phase_reads_after_its_last_setup_cast(self):
        scenario, expectation = self.built(minion_entry())
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        read_labels = expectation.model['after_setup_reads'][0]['read_labels']
        last_setup = [index for index, step in enumerate(steps)
                      if step.get('action') == 'cast' and step.get('spell') == 707421]
        for phase, phase_end in (('before', expectation.model['before_label']),
                                 ('after', expectation.model['after_label'])):
            with self.subTest(phase=phase):
                index = labels.index(read_labels[phase])
                self.assertEqual((steps[index]['metric'], steps[index]['spell']), ('aura_stacks', 707421))
                self.assertLess(index, labels.index(phase_end))
                self.assertTrue(any(cast < index for cast in last_setup))
        self.assertEqual(labels.count(read_labels['after']), 1)
        self.assertGreater(labels.index(read_labels['after']), labels.index(expectation.model['before_label']))
        self.assertIn('voids the trial', scenario['contract'])

    def test_without_the_option_the_scenario_is_unchanged(self):
        plain = {key: value for key, value in minion_entry().items() if key != 'after_setup_reads'}
        scenario, expectation = self.built(plain)
        self.assertNotIn('after_setup_reads', expectation.model)
        self.assertFalse(any('after_setup_reads' in str(step.get('label')) for step in scenario['steps']))
        reference, _ = behaviour_scenario(load_fixture_class_file(23), plain)
        self.assertEqual(scenario, reference)

    def test_a_phase_without_setup_casts_reads_nothing(self):
        scenario, expectation = self.built(minion_entry(setup_in_before=False))
        labels = [step.get('label') for step in scenario['steps']]
        read_labels = expectation.model['after_setup_reads'][0]['read_labels']
        self.assertNotIn(read_labels['before'], labels)
        self.assertEqual(labels.count(read_labels['after']), 1)

    def test_the_option_needs_spells_with_an_expected_state_and_setup_casts(self):
        for raw in (True, [], [{'spell': 707421}], [{'spell': 707421, 'expected': 2}],
                    [{'spell': '707421', 'expected': 1}], [{'spell': 707421, 'expected': True}], [*READS, *READS]):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), minion_entry(after_setup_reads=raw))
        no_setup = {key: value for key, value in minion_entry().items() if key not in ('setup_casts', 'setup_target')}
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), no_setup)

    def test_a_mismatch_or_a_missing_after_read_is_unmeasured_and_a_match_is_judged_as_before(self):
        _, expectation = self.built(minion_entry())
        model = expectation.model
        read_labels = model['after_setup_reads'][0]['read_labels']
        good_before, good_after = float(model['before_expected']), float(model['expected'])
        mutant_after = good_before

        def judged(after_value, before_stacks, after_stacks) -> str:
            values = {model['before_label']: good_before, model['after_label']: after_value}
            for phase, stacks in (('before', before_stacks), ('after', after_stacks)):
                if stacks is not None:
                    values[read_labels[phase]] = stacks
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        plain = {key: value for key, value in minion_entry().items() if key != 'after_setup_reads'}
        _, plain_expectation = self.built(plain)
        plain_status = judge_behaviour(base_verdict(plain_expectation),
                                       FakeRun({plain_expectation.model['before_label']: good_before,
                                                plain_expectation.model['after_label']: good_after}),
                                       plain_expectation).status
        self.assertEqual(plain_status, 'ok')
        self.assertEqual(judged(good_after, 1, 1), 'ok')
        self.assertEqual(judged(good_after, None, 1), 'ok')
        self.assertEqual(judged(mutant_after, 1, 1), 'alert')
        self.assertEqual(judged(good_after, 1, 0), 'unmeasured')
        self.assertEqual(judged(good_after, 0, 1), 'unmeasured')
        self.assertEqual(judged(mutant_after, 1, 0), 'unmeasured')
        self.assertEqual(judged(good_after, 1, None), 'unmeasured')

    def test_an_absent_expectation_voids_a_present_read(self):
        _, expectation = self.built(minion_entry(after_setup_reads=[{'spell': 707421, 'expected': 0}]))
        model = expectation.model
        read_labels = model['after_setup_reads'][0]['read_labels']
        values = {model['before_label']: float(model['before_expected']), model['after_label']: float(model['expected']),
                  read_labels['after']: 1}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'unmeasured')
        values[read_labels['after']] = 0
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'ok')


if __name__ == '__main__':
    unittest.main()
