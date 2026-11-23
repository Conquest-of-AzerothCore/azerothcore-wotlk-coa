import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.move_under_aura import MSG_MOVE_START_FORWARD, MSG_MOVE_STOP, float_bits, move_under_aura_spec
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

SPELL = 760379


def entry(**changes) -> dict:
    return {'spell': SPELL, 'name': 'Seeded move', 'kind': 'move_under_aura', 'quote': 'you can move', **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MoveUnderAuraTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(19), entry(**changes))

    def test_a_control_move_precedes_the_cast_and_the_same_move_follows_it(self):
        scenario, [expectation] = self.built()
        steps = run.validate(scenario)['steps']
        packets = [index for index, step in enumerate(steps) if step['action'] == 'client_packet']
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == SPELL)
        self.assertEqual([steps[index]['opcode'] for index in packets],
                         [MSG_MOVE_START_FORWARD, MSG_MOVE_STOP, MSG_MOVE_START_FORWARD, MSG_MOVE_STOP])
        self.assertLess(packets[1], cast)
        self.assertLess(cast, packets[2])
        self.assertTrue(all(steps[index]['consumed'] is False for index in packets))
        self.assertEqual(steps[packets[2]]['fields'][5], {'u32': float_bits(2389.03 + 4.0)})
        self.assertEqual(expectation.label, f'{SPELL} behaviour_metric_delta move')

    def values(self, expectation, aura_moved=2.0, control_moved=2.0, auras=(1, 1, 1)) -> dict:
        reads = expectation.model['reads']
        values = {}
        for phase, moved, held in (('control', control_moved, (0, 0, 0)), ('aura', aura_moved, auras)):
            start = 2389.03 if phase == 'control' else 2391.03
            for (moment, (x, aura)), state in zip(reads[phase].items(), held):
                values[x] = start if moment == 'start' else start + moved
                values[aura] = state
        return values

    def test_moving_under_a_held_aura_is_ok(self):
        _, [expectation] = self.built()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(expectation)), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_mutant_a_held_player_or_a_dropped_aura_alerts(self):
        _, [expectation] = self.built()
        for values in (self.values(expectation, aura_moved=0.0), self.values(expectation, auras=(1, 0, 0))):
            with self.subTest(values=values):
                self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status,
                                 'alert')

    def test_a_control_that_did_not_move_or_an_aura_never_held_is_unmeasured(self):
        _, [expectation] = self.built()
        for values in (self.values(expectation, control_moved=0.0), self.values(expectation, auras=(0, 0, 0))):
            with self.subTest(values=values):
                self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status,
                                 'unmeasured')

    def test_a_blocked_entry_is_ok_when_the_player_stays_under_the_held_aura(self):
        _, [expectation] = self.built(expect='blocked')
        self.assertEqual(expectation.model['metric'], 'move_under_aura_blocked')
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(expectation, aura_moved=0.0)),
                                  expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('attempt: own forward movement', verdict.explanation)

    def test_mutant_a_blocked_entry_alerts_when_the_player_moves_or_the_aura_drops(self):
        _, [expectation] = self.built(expect='blocked')
        for values in (self.values(expectation), self.values(expectation, aura_moved=0.0, auras=(1, 0, 0))):
            with self.subTest(values=values):
                self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status,
                                 'alert')

    def test_a_blocked_entry_without_a_moving_control_is_unmeasured(self):
        _, [expectation] = self.built(expect='blocked')
        values = self.values(expectation, aura_moved=0.0, control_moved=0.0)
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status,
                         'unmeasured')

    def test_the_default_entry_keeps_the_moved_metric_and_no_expect_key(self):
        _, [expectation] = self.built()
        self.assertEqual(expectation.model['metric'], 'move_under_aura_moved')
        self.assertNotIn('expect', expectation.model)

    def test_an_unknown_expect_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'move_under_aura expects'):
            move_under_aura_spec(entry(expect='stuck'))

    def test_a_step_out_of_range_is_refused(self):
        for step in (0.1, 20):
            with self.subTest(step=step), self.assertRaisesRegex(ValueError, 'move_under_aura'):
                move_under_aura_spec(entry(step_yd=step))


if __name__ == '__main__':
    unittest.main()
