import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

SHIELD = [{'spell': 642, 'expected': 1, 'actor': 'dummy'}]


def control_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(27)['behaviours']
                 if entry.get('spell') == 807372 and entry.get('variant') == 'immune_all_control')
    return {**{key: value for key, value in entry.items() if key != 'before_trigger_reads'},
            'before_trigger_reads': SHIELD, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BeforeTriggerReadsTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(27), control_entry(**changes))

    def test_the_read_follows_the_fixture_aura_and_precedes_the_cast_in_the_after_phase_only(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        read_labels = expectation.model['before_trigger_reads'][0]['read_labels']
        self.assertEqual(list(read_labels), ['after'])
        index = labels.index(read_labels['after'])
        read = scenario['steps'][index]
        self.assertEqual((read['actor'], read['metric'], read['spell']), ('dummy', 'aura_stacks', 642))
        shield_sets = [i for i, step in enumerate(scenario['steps'])
                       if step.get('action') == 'set_aura' and step.get('spell') == 642]
        casts = [i for i, step in enumerate(scenario['steps']) if step.get('action') == 'cast']
        self.assertEqual(len(shield_sets), 2)
        self.assertLess(shield_sets[1], index)
        self.assertLess(index, casts[0])
        self.assertFalse(any(step.get('action') == 'wait' for step in scenario['steps'][shield_sets[1]:index]))

    def test_a_before_phase_that_casts_is_read_too(self):
        scenario, [expectation] = self.built(cast_in_before=True)
        read_labels = expectation.model['before_trigger_reads'][0]['read_labels']
        self.assertEqual(list(read_labels), ['before', 'after'])
        labels = [step.get('label') for step in scenario['steps']]
        self.assertLess(labels.index(read_labels['before']), labels.index(read_labels['after']))

    def test_without_the_option_nothing_is_read(self):
        entry = {key: value for key, value in control_entry().items() if key != 'before_trigger_reads'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(27), entry)
        self.assertNotIn('before_trigger_reads', expectation.model)
        self.assertFalse(any('before_trigger_reads' in str(step.get('label')) for step in scenario['steps']))

    def test_the_option_needs_spells_with_an_expected_state_and_a_unit(self):
        for raw in (True, [], [{'spell': 642, 'expected': 1}], [{'spell': 642, 'actor': 'dummy'}],
                    [{'spell': 642, 'expected': 2, 'actor': 'dummy'}],
                    [{'spell': '642', 'expected': 1, 'actor': 'dummy'}],
                    [{'spell': 642, 'expected': 1, 'actor': 'ally'}], [*SHIELD, *SHIELD]):
            with self.assertRaises(ValueError):
                self.built(before_trigger_reads=raw)

    def test_a_missing_shield_is_unmeasured_and_a_present_one_is_judged_as_before(self):
        _, [expectation] = self.built()
        before, after = expectation.model['before_label'], expectation.model['after_label']
        read = expectation.model['before_trigger_reads'][0]['read_labels']['after']

        def judged(damage: float, shield: float | None) -> str:
            values = {before: 0.0, after: damage}
            if shield is not None:
                values[read] = shield
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(0.0, 1), 'ok')
        self.assertEqual(judged(300.0, 1), 'alert')
        self.assertEqual(judged(0.0, 0), 'unmeasured')
        self.assertEqual(judged(300.0, 0), 'unmeasured')
        self.assertEqual(judged(0.0, None), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
