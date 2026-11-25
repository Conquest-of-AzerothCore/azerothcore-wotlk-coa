from dataclasses import replace
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from metric_delta_options import after_start_reads
from metric_delta_options.test_ally_arm import ally_entry
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


ALLY_READS = [{'spell': 301005, 'expected': 0, 'actor': 'ally'}, {'spell': 301005, 'expected': 0, 'actor': 'ally2'}]


def ally_reads_entry(reads=None) -> dict:
    return {**ally_entry(), 'after_start_reads': ALLY_READS if reads is None else reads}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterStartActorReadsTests(unittest.TestCase):
    def test_each_ally_is_read_once_in_the_after_phase_under_its_own_label(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), ally_reads_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        reads = expectation.model['after_start_reads']
        self.assertEqual([read['actor'] for read in reads], ['ally', 'ally2'])
        for read in reads:
            self.assertTrue(read['read_label'].endswith(f' 301005 {read["actor"]}'))
            self.assertEqual(labels.count(read['read_label']), 1)
            step = scenario['steps'][labels.index(read['read_label'])]
            self.assertEqual((step['actor'], step['metric'], step['spell']), (read['actor'], 'aura_stacks', 301005))
            self.assertGreater(labels.index(read['read_label']), labels.index(expectation.model['before_label']))
            self.assertLess(labels.index(read['read_label']), labels.index(expectation.model['after_label']))

    def test_a_read_without_actor_keeps_its_caster_label_and_model(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry())
        [read] = expectation.model['after_start_reads']
        self.assertEqual(set(read), {'spell', 'expected', 'read_label'})
        self.assertTrue(read['read_label'].endswith('after_start_reads 1604'))

    def test_an_actor_outside_the_scenario_or_a_repeated_unit_is_refused(self):
        for reads in ([{'spell': 301005, 'expected': 0, 'actor': 'ally3'}],
                      [{'spell': 301005, 'expected': 0, 'actor': ''}],
                      [{'spell': 301005, 'expected': 0, 'actor': 'ally'}] * 2):
            with self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), ally_reads_entry(reads))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), snare_entry(after_start_reads=ALLY_READS))

    def test_a_leftover_aura_on_one_ally_is_unmeasured(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(19), ally_reads_entry())
        verdict = replace(base_verdict(expectation), status='ok', explanation='seeded')
        reads = expectation.model['after_start_reads']
        clean = {read['read_label']: 0 for read in reads}
        self.assertEqual(after_start_reads.verdict(verdict, FakeRun(clean), reads).status, 'ok')
        leftover = after_start_reads.verdict(verdict, FakeRun({**clean, reads[1]['read_label']: 1}), reads)
        self.assertEqual(leftover.status, 'unmeasured')
        self.assertIn('ally2 aura 301005 read 1', leftover.explanation)

    def test_mutant_reading_the_caster_in_place_of_the_ally_alerts_this_suite(self):
        original = after_start_reads.phase_steps
        def caster_only(spec, reads, after):
            return original(spec, tuple((spell, expected, None) for spell, expected, _ in reads), after)
        after_start_reads.phase_steps = caster_only
        try:
            scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), ally_reads_entry())
            labels = [step.get('label') for step in scenario['steps']]
            self.assertFalse(all(read['read_label'] in labels for read in expectation.model['after_start_reads']))
        finally:
            after_start_reads.phase_steps = original


if __name__ == '__main__':
    unittest.main()
