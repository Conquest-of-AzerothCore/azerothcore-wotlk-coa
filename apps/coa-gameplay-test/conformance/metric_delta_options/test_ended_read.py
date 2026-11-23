import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.ended_read import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

MONSTROSITY = 500067
BLESS = 804247


def size_entry(**changes) -> dict:
    return {'spell': MONSTROSITY, 'name': 'Example size', 'kind': 'metric_delta', 'label_suffix': 'size',
            'quote': 'and size by $s2%.', 'trigger_spell': BLESS, 'gate_spell': MONSTROSITY, 'target': 'caster',
            'metric': 'object_scale', 'fields': {}, 'before_expected': 1.0, 'expected': 1.1, 'tolerance': 0.001,
            'wait_ms': 11000, 'expire_ms': 500, 'expected_ratio': 1.1,
            'ended_read': {'unlearn': [MONSTROSITY], 'wait_ms': 12000, 'duration_ms': 11000}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class EndedReadTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(19), size_entry(**changes))

    def test_the_ended_read_follows_the_after_read_past_the_aura_duration(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        after = labels.index(expectation.model['after_label'])
        self.assertEqual(steps[after + 1], {'action': 'unlearn', 'actor': 'caster', 'spell': MONSTROSITY})
        self.assertEqual(steps[after + 2]['ms'], 12000)
        self.assertEqual(steps[after + 3]['label'], expectation.model['ended_read']['ended_label'])
        self.assertEqual(steps[after + 3]['metric'], 'object_scale')
        self.assertEqual(len(steps), after + 4)
        self.assertIn('past the triggered aura\'s 11000 ms duration', scenario['contract'])

    def test_an_entry_without_the_option_has_no_ended_read(self):
        scenario, [expectation] = self.built(ended_read=None)
        self.assertNotIn('ended_read', expectation.model)
        self.assertFalse(any(step['action'] == 'unlearn' for step in scenario['steps']))

    def judged(self, before=1.0, after=1.1000000238418579, ended=1.0, missing=None):
        _, [expectation] = self.built()
        model = expectation.model
        found = {model['before_label']: before, model['after_label']: after,
                 model['ended_read']['ended_label']: ended}
        if missing:
            found.pop(model['ended_read']['ended_label'])
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def test_the_stated_size_that_ends_with_the_aura_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('after unlearning', verdict.explanation)

    def test_the_baseline_is_the_before_read_of_the_same_scenario(self):
        self.assertEqual(self.judged(before=1.05, after=1.15, ended=1.05).status, 'alert')
        self.assertEqual(self.judged(before=1.05, after=1.155, ended=1.0).status, 'alert')
        self.assertEqual(self.judged(before=1.0, after=1.1, ended=1.0).status, 'ok')

    def test_mutants_alert(self):
        for reads in ({'after': 1.09}, {'after': 1.11}, {'after': 1.2}, {'after': 1.0}, {'ended': 1.1},
                      {'ended': 1.0011}):
            with self.subTest(reads=reads):
                self.assertEqual(self.judged(**reads).status, 'alert')

    def test_a_missing_ended_read_is_unmeasured(self):
        self.assertEqual(self.judged(missing=True).status, 'unmeasured')

    def test_the_size_words_make_the_scale_read_behaviour(self):
        from coverage import BEHAVIOUR, STATE, metric_evidence, verdict_evidence
        verdict = self.judged()
        self.assertEqual(metric_evidence()['object_scale'], STATE)
        self.assertEqual(verdict_evidence(verdict, 'and size by $s2%.', {}), BEHAVIOUR)
        self.assertNotEqual(verdict_evidence(verdict, 'Increases your Stamina by $s1%', {}), BEHAVIOUR)
        self.assertNotEqual(verdict_evidence(self.judged(ended=1.1), 'and size by $s2%.', {}), BEHAVIOUR)

    def test_refused_inputs(self):
        for raw in ({'unlearn': [MONSTROSITY], 'wait_ms': 12000}, {'unlearn': [], 'wait_ms': 12000,
                                                                     'duration_ms': 11000},
                    {'unlearn': [MONSTROSITY], 'wait_ms': 11000, 'duration_ms': 11000},
                    {'unlearn': [True], 'wait_ms': 12000, 'duration_ms': 11000},
                    {'unlearn': [MONSTROSITY], 'wait_ms': 12000, 'duration_ms': 0}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'gate_timing': 'start'}, {'setup_only_after': True, 'setup_casts': [BLESS]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
