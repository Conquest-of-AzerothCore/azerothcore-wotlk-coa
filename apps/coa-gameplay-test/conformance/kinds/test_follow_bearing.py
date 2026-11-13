import math
import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 805428, 'name': 'Animate: Frost Wyrm (flies behind the Necromancer)', 'kind': 'follow_bearing',
         'label_suffix': 'behind', 'quote': 'that flies behind the Necromancer', 'control_raise': [500971],
         'control_entry': 50073, 'follower_raise': [805428], 'follower_entry': 50177, 'front_yd': 10,
         'settle_ms': 3000}


def placed(bearing_degrees: float, follow_yd: float = 2.0, front_yd: float = 10.0) -> tuple[float, float]:
    angle = math.radians(bearing_degrees)
    x, y = follow_yd * math.cos(angle), follow_yd * math.sin(angle)
    return follow_yd, math.hypot(front_yd - x, y)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FollowBearingTests(unittest.TestCase):
    def judged(self, follower_degrees: float, control_degrees: float = 90.0) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        model = expectation.model
        values = {model['caster_front']: 10.0}
        values.update(zip(model['reads']['control'], placed(control_degrees)))
        values.update(zip(model['reads']['follower'], placed(follower_degrees)))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_control_is_read_before_the_follower_is_raised(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        casts = [step['spell'] for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [500971, 805428])
        self.assertEqual(scenario['creatures'][0]['faction'], 35)

    def test_a_follower_behind_the_caster_passes(self):
        verdict = self.judged(180.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 180.0, places=3)

    def test_a_follower_at_the_stock_side_angle_alerts(self):
        self.assertEqual(self.judged(90.0).status, 'alert')

    def test_a_control_behind_the_caster_is_unmeasured(self):
        self.assertEqual(self.judged(180.0, 180.0).status, 'unmeasured')
