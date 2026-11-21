import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 801530, 'name': 'Transfer Life (a Ghoul within 20 yd is healed, one beyond is not)',
         'kind': 'minion_range_arms', 'label_suffix': 'minion_range',
         'quote': 'Channel life into your Raised minions within $a1 yds for $d,', 'raise_spell': 500971,
         'command_spell': 504868, 'observe_spell': 801545, 'minion_entry': 50073, 'radius': 20, 'near_yd': 12,
         'far_yd': 28, 'wait_ms': 10500, 'settle_ms': 2500}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MinionRangeArmsTests(unittest.TestCase):
    def judged(self, near_heals: float, far_heals: float, near_yd: float = 13.1, far_yd: float = 29.1) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = {}
        for arm, heals, distance, offset in (('near', near_heals, near_yd, 0.0),
                                             ('far', far_heals, far_yd, near_heals)):
            reads = expectation.model['arms'][arm]
            values.update(zip(reads['heals'], (offset, offset + heals)))
            values.update(zip(reads['minion distance'], (distance, distance)))
            values.update(zip(reads['caster distance'], (distance - 1, distance - 1)))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_arms_relocate_the_caster_past_the_dummy(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        shifts = [step['dx'] for step in scenario['steps'] if step['action'] == 'relocate']
        self.assertEqual(sum(shifts), 31.0)

    def test_near_healed_and_far_spared_passes(self):
        self.assertEqual(self.judged(10, 0).status, 'ok')

    def test_a_far_heal_or_no_near_heal_alerts(self):
        self.assertEqual(self.judged(10, 10).status, 'alert')
        self.assertEqual(self.judged(0, 0).status, 'alert')

    def test_a_minion_that_followed_the_caster_is_unmeasured(self):
        self.assertEqual(self.judged(10, 0, far_yd=4.0).status, 'unmeasured')
