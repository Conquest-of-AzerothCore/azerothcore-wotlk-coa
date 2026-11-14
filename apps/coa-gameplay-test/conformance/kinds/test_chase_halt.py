import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 504316, 'name': 'Command: Hook (a hooked enemy stops chasing)', 'kind': 'chase_halt',
         'label_suffix': 'chase_halt', 'quote': 'slowing their movement speed to a halt', 'learn': [92123],
         'raises': [[500335, 'caster', None, 4000], [531130, 'far', 1000, 4000]], 'chased_entry': 503200,
         'expected_ratio': 0.02, 'far_yd': 25, 'chaser_yd': 8, 'start_ms': 500, 'window_ms': 1000}
MOVE_ENTRY = {**{key: value for key, value in ENTRY.items() if key != 'chased_entry'},
              'raises': [[500335, 'caster', None, 4000]], 'order': 'move_point', 'move_yd': 12}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ChaseHaltTests(unittest.TestCase):
    def judged(self, hooked_yd: float, chaser_yd: float, entry: dict = ENTRY) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        start, end = (expectation.model['reads'][moment] for moment in ('start', 'end'))
        values = dict(zip(start, (1000.0, 25.0, 17.0)))
        values.update(zip(end, (2000.0, 25.0 - hooked_yd, 17.0 - chaser_yd)))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_movers_are_not_stationary(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        self.assertEqual([creature['stationary'] for creature in scenario['creatures']], [False, False, True])

    def test_a_halted_hooked_dummy_passes(self):
        self.assertEqual(self.judged(0.16, 8.0).status, 'ok')

    def test_a_hooked_dummy_that_keeps_running_alerts(self):
        self.assertEqual(self.judged(4.0, 8.0).status, 'alert')

    def test_a_control_that_does_not_chase_is_unmeasured(self):
        self.assertEqual(self.judged(0.0, 0.0).status, 'unmeasured')

    def test_the_point_move_follows_the_hook_for_both_movers(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), MOVE_ENTRY)
        run.validate(scenario)
        actions = [step['action'] for step in scenario['steps']]
        self.assertNotIn('attack_owned_creature', actions)
        moves = [step for step in scenario['steps'] if step['action'] == 'move_point']
        self.assertEqual([(step['actor'], step['dx']) for step in moves], [('hooked', 12.0), ('chaser', 12.0)])
        hook = max(index for index, step in enumerate(scenario['steps'])
                   if step['action'] == 'cast' and step.get('spell') == 504316)
        self.assertGreater(actions.index('move_point'), hook)

    def test_a_point_moved_halted_dummy_passes(self):
        self.assertEqual(self.judged(0.16, 8.0, MOVE_ENTRY).status, 'ok')

    def test_a_point_moved_dummy_without_the_slow_alerts(self):
        self.assertEqual(self.judged(8.0, 8.0, MOVE_ENTRY).status, 'alert')

    def test_a_point_move_past_the_far_dummy_is_rejected(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**MOVE_ENTRY, 'move_yd': 20})

    def test_the_halt_ratio_is_an_event_read_that_proves_the_halt(self):
        from coverage import BEHAVIOUR, EVENT, metric_evidence, verdict_evidence
        found = self.judged(0.16, 8.0, MOVE_ENTRY)
        self.assertEqual(found.detail['metric'], 'chase_travel_ratio')
        self.assertEqual(metric_evidence()['chase_travel_ratio'], EVENT)
        self.assertEqual(verdict_evidence(found, MOVE_ENTRY['quote'], {}), BEHAVIOUR)

    def test_a_halt_ratio_without_its_evidence_row_is_refused(self):
        from unittest import mock
        import coverage
        found = self.judged(0.16, 8.0, MOVE_ENTRY)
        without = {metric: kind for metric, kind in coverage.metric_evidence().items()
                   if metric != 'chase_travel_ratio'}
        with mock.patch.object(coverage, 'metric_evidence', return_value=without), \
                self.assertRaises(coverage.EvidenceError):
            coverage.verdict_evidence(found, MOVE_ENTRY['quote'], {})
