import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 531130, 'name': "Animate: Bone Construct (moves at half the Ghoul's speed)",
         'kind': 'minion_travel_ratio', 'label_suffix': 'travel_ratio', 'quote': 'It moves at a slow speed',
         'raises': [[500971, 'caster'], [531130, 'dummy', 1000]], 'command_spell': 504868, 'slowed_entry': 503200,
         'control_entry': 50073, 'expected_ratio': 0.5, 'far_yd': 25, 'window_ms': 8000, 'settle_ms': 1000,
         'poll_ms': 100}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MinionTravelRatioTests(unittest.TestCase):
    def judged(self, slowed_speed: float, control_speed: float = 8.0, stall_yd: float = 2.5) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = dict(zip(expectation.model['rates'], (0.57143, 1.14286)))
        for index, (time, slowed, control) in enumerate(expectation.model['rows']):
            now = index * 112.0
            values[time] = now
            values[slowed] = max(stall_yd, 29.0 - slowed_speed * now / 1000)
            values[control] = max(2.5, 25.0 - control_speed * now / 1000)
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_raises_carry_their_power(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        powers = [step['value'] for step in scenario['steps'] if step['action'] == 'set_power']
        self.assertIn(1000, powers)
        self.assertEqual(scenario['creatures'][-1]['distance'], 25.0)

    def test_half_speed_passes(self):
        verdict = self.judged(4.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.5, places=2)

    def test_an_unslowed_or_slower_minion_alerts(self):
        self.assertEqual(self.judged(8.0).status, 'alert')
        self.assertEqual(self.judged(3.0).status, 'alert')

    def test_the_stalled_tail_is_left_out(self):
        verdict = self.judged(4.0, stall_yd=4.3)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.5, places=2)

    def test_a_minion_that_never_moves_is_unmeasured(self):
        self.assertEqual(self.judged(0.0).status, 'unmeasured')
