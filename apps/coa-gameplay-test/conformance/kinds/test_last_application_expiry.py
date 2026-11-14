import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 707007, 'name': 'March of the Dead (slow lasts 3 sec after the last explosion)',
         'kind': 'last_application_expiry', 'label_suffix': 'slow_expiry', 'quote': 'for $707010d.',
         'gate_spell': 707007, 'trigger_spell': 707007, 'aura': 707010, 'expected_ms': 3000,
         'control_window_ms': 500, 'window_ms': 5000, 'poll_ms': 25}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class LastApplicationExpiryTests(unittest.TestCase):
    def judged(self, lasts_ms: float, applications=(300.0, 400.0, 900.0), control_applied: bool = False) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = {}
        for arm, rows in expectation.model['reads'].items():
            for index, (time, applied, aura) in enumerate(rows):
                now = 1000.0 + index * 34.0
                values[time] = now
                if arm == 'control':
                    values[applied] = 1.0 if control_applied and index else 0.0
                    values[aura] = 0.0
                    continue
                done = [moment for moment in applications if 1000.0 + moment <= now]
                values[applied] = float(len(done))
                values[aura] = 1.0 if done and now < 1000.0 + done[-1] + lasts_ms else 0.0
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_polls_are_valid(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        self.assertEqual(len(expectation.model['reads']['treatment'][0]), 3)

    def test_three_seconds_after_the_last_application_passes(self):
        verdict = self.judged(3000.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertLess(abs(verdict.measured - 3000.0), 60.0)

    def test_a_longer_or_shorter_aura_alerts(self):
        self.assertEqual(self.judged(3600.0).status, 'alert')
        self.assertEqual(self.judged(2400.0).status, 'alert')

    def test_timing_from_the_first_application_would_not_pass(self):
        self.assertEqual(self.judged(2400.0, applications=(300.0, 900.0)).status, 'alert')

    def test_a_control_application_alerts(self):
        self.assertEqual(self.judged(3000.0, control_applied=True).status, 'alert')

    def test_an_aura_never_applied_is_unmeasured(self):
        self.assertEqual(self.judged(3000.0, applications=()).status, 'unmeasured')
