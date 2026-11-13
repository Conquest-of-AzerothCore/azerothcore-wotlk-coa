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


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ChaseHaltTests(unittest.TestCase):
    def judged(self, hooked_yd: float, chaser_yd: float) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
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
