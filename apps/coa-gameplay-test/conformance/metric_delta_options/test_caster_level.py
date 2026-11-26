import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict


def level_entry(**changes) -> dict:
    return {'spell': 560002, 'name': 'Voidwarding (holy resistance +14 at level 50)', 'kind': 'metric_delta',
            'label_suffix': 'res_holy_l50',
            'quote': 'In addition, increases all of your resistances by ${$floor($m2)}, scaling with level.',
            'trigger_spell': 60235, 'gate_spell': 560002, 'target': 'caster', 'metric': 'resistance',
            'fields': {'school': 1}, 'before_expected': 0, 'expected': 14, 'expected_gain': 14, 'tolerance': 0.01,
            'wait_ms': 500, 'expire_ms': 500, 'caster_level': 50, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CasterLevelTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(load_class_file(25), level_entry(**changes))

    def judged(self, before=0.0, after=14.0, before_level=50.0, after_level=50.0, **changes):
        _, [expectation] = self.build(**changes)
        info = expectation.model['caster_level']
        values = {expectation.model['before_label']: before, expectation.model['after_label']: after}
        if before_level is not None:
            values[info['before_label']] = before_level
        if after_level is not None:
            values[info['after_label']] = after_level
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_caster_spawns_at_the_requested_level_and_reads_level_in_both_phases(self):
        scenario, [expectation] = self.build()
        run.validate(scenario)
        self.assertEqual(scenario['players'][0]['level'], 50)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        info = expectation.model['caster_level']
        self.assertEqual(info['level'], 50)
        learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': 560002})
        self.assertLess(labels.index(info['before_label']), labels.index(expectation.model['before_label']))
        self.assertLess(labels.index(info['before_label']), learn)
        self.assertLess(learn, labels.index(info['after_label']))
        self.assertLess(labels.index(info['after_label']), labels.index(expectation.model['after_label']))
        self.assertFalse(any(step.get('action') == 'set_level' for step in steps))

    def test_without_the_option_the_player_keeps_the_class_level(self):
        entry = {key: value for key, value in level_entry().items() if key != 'caster_level'}
        scenario, [expectation] = behaviour_scenario(load_class_file(25), entry)
        self.assertEqual(scenario['players'][0]['level'], 60)
        self.assertNotIn('caster_level', expectation.model)
        self.assertFalse(any(step.get('metric') == 'level' for step in scenario['steps']))

    def test_matching_level_and_value_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('caster level 50 before and 50 after', verdict.explanation)

    def test_wrong_expected_value_mutant_alerts(self):
        verdict = self.judged(after=14.0, expected=19, expected_gain=19)
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_missing_or_wrong_level_read_is_unmeasured(self):
        self.assertEqual(self.judged(before_level=60.0).status, 'unmeasured')
        self.assertEqual(self.judged(after_level=60.0).status, 'unmeasured')
        self.assertEqual(self.judged(before_level=None).status, 'unmeasured')
        self.assertEqual(self.judged(after_level=None).status, 'unmeasured')

    def test_refused_inputs(self):
        for changes in ({'caster_level': 0}, {'caster_level': 60}, {'caster_level': 61},
                        {'caster_level': True}, {'caster_level': 50.0}, {'caster_level': '50'},
                        {'quote': 'Reduces damage taken by party and raid members by $s1%.'},
                        {'phase_caster_level': [50, 60]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.build(**changes)


if __name__ == '__main__':
    unittest.main()
