import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.stop_shooting_after_ms import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

SHOT = 75
WHISTLE = 801343


def duration_entry(**changes) -> dict:
    return {'spell': 705531, 'name': 'Example haste (duration)', 'kind': 'metric_delta',
            'label_suffix': 'haste_duration', 'quote': 'for $573266d.', 'expected': 1739.13, 'before_expected': 2000,
            'tolerance': 0.5, 'after_expiry_expected': 2000, 'trigger_spell': SHOT, 'target': 'dummy',
            'force_crit': 'ranged', 'setup_casts': [WHISTLE], 'setup_target': 'caster', 'setup_wait_ms': 1500,
            'gate_timing': 'start', 'gate_spell': 705531, 'trigger_only_after': True, 'wait_ms': 4575,
            'expire_ms': 500, 'expiry_wait_ms': 550, 'game_time': {'after': [4825, 4975], 'expired': [5375, 5475]},
            'dummy_distance': 8, 'metric': 'owned_creature_attack_time_ms', 'fields': {'entry': 50124},
            'stop_shooting_after_ms': {'ms': 300, 'dx': -40, 'spell': SHOT, 'target': 'dummy'}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class StopShootingAfterMsTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), duration_entry(**changes))

    def test_the_caster_leaves_the_range_after_the_treatment_cast_only(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        shots = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == SHOT]
        whistles = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == WHISTLE]
        self.assertEqual(len(shots), 1)
        self.assertEqual(len(whistles), 2)
        before = next(index for index, step in enumerate(steps)
                      if step.get('label') == expectation.model['before_label'])
        self.assertLess(whistles[0], before)
        self.assertEqual([step['action'] for step in steps[shots[0] + 1:shots[0] + 6]],
                         ['wait', 'assert', 'assert', 'relocate', 'relocate'])
        self.assertEqual(steps[shots[0] + 1]['ms'], 300)
        self.assertEqual([steps[index]['dx'] for index in (shots[0] + 4, shots[0] + 5)], [-20.0, -20.0])
        recorded = expectation.model['stop_shooting_after_ms']
        labels = [step.get('label') for step in steps]
        for moment in ('after', 'expired'):
            read = labels.index(expectation.model[f'{moment}_label'] if moment == 'after'
                                else expectation.model['expired_label'])
            self.assertEqual(labels[read - 1], recorded[moment])
        self.assertIn('no hit after it', scenario['contract'])

    def test_an_entry_without_the_option_has_no_move(self):
        scenario, [expectation] = self.built(stop_shooting_after_ms=None)
        self.assertNotIn('stop_shooting_after_ms', expectation.model)
        self.assertFalse(any(step['action'] == 'relocate' for step in scenario['steps']))

    def values(self, after=1739.13, expired=2000.0, shots=(1, 1, 1), moved=300.0, missing=None):
        _, [expectation] = self.built()
        model = expectation.model
        recorded = model['stop_shooting_after_ms']
        stamps = model['game_time']
        found = {model['before_label']: 2000.0, model['after_label']: after, model['expired_label']: expired,
                 stamps['cast_label']: 100000.0, stamps['after_label']: 104875.0, stamps['expired_label']: 105425.0,
                 recorded['relocate at']: 100000.0 + moved, recorded['relocate']: shots[0],
                 recorded['after']: shots[1], recorded['expired']: shots[2]}
        if missing:
            found.pop(recorded[missing])
        return expectation, found

    def judged(self, **reads):
        expectation, found = self.values(**reads)
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def test_the_stated_duration_is_ok_with_the_shooting_stopped(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('1 hits of 75 before the move', verdict.explanation)

    def test_a_short_or_long_aura_alerts(self):
        self.assertEqual(self.judged(after=2000.0).status, 'alert')
        self.assertEqual(self.judged(expired=1739.13).status, 'alert')

    def test_a_fixture_that_did_not_stop_the_shooting_is_unmeasured(self):
        for reads in ({'shots': (0, 0, 0)}, {'shots': (1, 2, 2)}, {'shots': (1, 1, 2)}, {'moved': 400.0},
                      {'missing': 'relocate'}, {'missing': 'relocate at'}):
            with self.subTest(reads=reads):
                self.assertEqual(self.judged(**reads).status, 'unmeasured')

    def test_the_duration_words_of_the_claim_make_the_stopped_shooting_behaviour(self):
        from dataclasses import replace
        from compare import observed
        from coverage import BEHAVIOUR, DATA, METRIC_EVIDENCE, STATE, STATE_PROMISES, metric_evidence, \
            verdict_evidence
        verdict = self.judged()
        self.assertEqual(verdict.detail['metric'], 'stop_shooting_attack_time_ms')
        self.assertNotIn('stop_shooting_attack_time_ms', METRIC_EVIDENCE)
        self.assertNotIn('stop_shooting_attack_time_ms', STATE_PROMISES)
        self.assertEqual(metric_evidence()['stop_shooting_attack_time_ms'], STATE)
        self.assertEqual(verdict_evidence(verdict, 'for $573266d', {}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdict, 'for $d.', {}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdict, 'increase the melee haste of your Shadow Hounds by $573266s1%',
                                          {}), DATA)
        self.assertEqual(verdict_evidence(verdict, 'for 5 sec', {}), DATA)
        _, [plain] = self.built(stop_shooting_after_ms=None)
        self.assertNotIn('evidence_metric', plain.model)
        unstamped = replace(verdict, detail={**verdict.detail, **observed(plain)})
        self.assertEqual(unstamped.detail['metric'], 'owned_creature_attack_time_ms')
        self.assertEqual(verdict_evidence(unstamped, 'for $573266d', {}), DATA)
        self.assertNotEqual(verdict_evidence(self.judged(after=2000.0), 'for $573266d', {}), BEHAVIOUR)

    def test_refused_inputs(self):
        for raw in ({'ms': 300, 'dx': -40, 'spell': SHOT}, {'ms': 0, 'dx': -40, 'spell': SHOT, 'target': 'dummy'},
                    {'ms': 300, 'dx': 0, 'spell': SHOT, 'target': 'dummy'},
                    {'ms': 300, 'dx': -61, 'spell': SHOT, 'target': 'dummy'},
                    {'ms': True, 'dx': -40, 'spell': SHOT, 'target': 'dummy'}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'trigger_only_after': False}, {'expiry_wait_ms': None, 'after_expiry_expected': None},
                        {'game_time': {'after': [4825, 4975]}, 'expiry_wait_ms': None, 'after_expiry_expected': None},
                        {'stop_shooting_after_ms': {'ms': 300, 'dx': -40, 'spell': 1, 'target': 'dummy'}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
