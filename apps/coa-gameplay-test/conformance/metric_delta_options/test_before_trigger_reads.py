import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

FIXTURE_AURA = 984954
READS = [{'spell': FIXTURE_AURA, 'expected': 1, 'actor': 'caster'}, {'spell': 642, 'expected': 0, 'actor': 'dummy'}]


def entry(**changes) -> dict:
    found = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 707562 and entry.get('variant') == 'no_crit')
    return {**{key: value for key, value in found.items() if key != 'before_trigger_reads'},
            'before_trigger_reads': READS, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BeforeTriggerReadsTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), entry(**changes))

    def test_the_read_follows_the_fixture_aura_and_precedes_the_cast_in_every_phase_that_casts(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        for read in expectation.model['before_trigger_reads']:
            self.assertEqual(list(read['read_labels']), ['before', 'after'])
            step = steps[labels.index(read['read_labels']['after'])]
            self.assertEqual((step['actor'], step['metric'], step['spell']),
                             (read['actor'], 'aura_stacks', read['spell']))
        index = labels.index(expectation.model['before_trigger_reads'][0]['read_labels']['after'])
        sets = [i for i, step in enumerate(steps) if step.get('action') == 'set_aura' and step['spell'] == FIXTURE_AURA]
        casts = [i for i, step in enumerate(steps) if step.get('action') == 'cast']
        self.assertEqual(len(sets), 2)
        self.assertLess(sets[1], index)
        self.assertLess(index, casts[-1])
        self.assertFalse(any(step.get('action') == 'wait' for step in steps[sets[1]:index]))

    def test_a_before_phase_that_does_not_cast_is_not_read(self):
        scenario, [expectation] = self.built(cast_in_before=False)
        for read in expectation.model['before_trigger_reads']:
            self.assertEqual(list(read['read_labels']), ['after'])
        labels = [step.get('label') for step in scenario['steps']]
        self.assertFalse(any(str(label).endswith(' before') and 'before_trigger_reads' in str(label)
                             for label in labels))

    def test_without_the_option_nothing_is_read(self):
        plain = {key: value for key, value in entry().items() if key != 'before_trigger_reads'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), plain)
        self.assertNotIn('before_trigger_reads', expectation.model)
        self.assertFalse(any('before_trigger_reads' in str(step.get('label')) for step in scenario['steps']))

    def test_the_option_needs_spells_with_an_expected_state_and_a_unit(self):
        shield = {'spell': 642, 'expected': 1, 'actor': 'dummy'}
        for raw in (True, [], [{'spell': 642, 'expected': 1}], [{'spell': 642, 'actor': 'dummy'}],
                    [{**shield, 'expected': 2}], [{**shield, 'spell': '642'}], [{**shield, 'actor': 'ally'}],
                    [shield, shield]):
            with self.assertRaises(ValueError):
                self.built(before_trigger_reads=raw)

    def test_a_missing_precondition_is_unmeasured_and_a_held_one_is_judged_as_before(self):
        plain = {key: value for key, value in entry().items() if key != 'before_trigger_reads'}
        _, [bare] = behaviour_scenario(load_fixture_class_file(23), plain)
        _, [guarded] = self.built()
        values = {bare.model['before_label']: 0.0, bare.model['after_label']: 0.0}
        reads = {label: (1.0 if read['expected'] else 0.0) for read in guarded.model['before_trigger_reads']
                 for label in read['read_labels'].values()}

        def judged(overrides: dict, expectation=guarded, extra=True) -> str:
            held = {**values, **(reads if extra else {}), **overrides}
            return judge_behaviour(base_verdict(expectation), FakeRun(held), expectation).status

        plain_status = judged({}, bare, extra=False)
        self.assertEqual(judged({}), plain_status)
        self.assertNotEqual(plain_status, 'unmeasured')
        mutant = guarded.model['before_trigger_reads'][1]['read_labels']['after']
        fixture = guarded.model['before_trigger_reads'][0]['read_labels']['after']
        self.assertEqual(judged({fixture: 0.0}), 'unmeasured')
        self.assertEqual(judged({mutant: 1.0}), 'unmeasured')
        missing = {key: value for key, value in {**values, **reads}.items() if key != fixture}
        self.assertEqual(judge_behaviour(base_verdict(guarded), FakeRun(missing), guarded).status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
