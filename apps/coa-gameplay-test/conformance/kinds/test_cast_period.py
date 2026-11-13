import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from kinds.cast_period import cast_period_spec
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun


def bone_toss_entry() -> dict:
    return next(entry for entry in load_fixture_class_file(23)['behaviours']
                if entry['kind'] == 'cast_period' and entry['label_suffix'] == 'bone_toss_period')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CastPeriodTests(unittest.TestCase):
    def expectation(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), bone_toss_entry())
        return scenario, expectation

    def judged(self, period: float, control: float = 0.0, offset: float = 430.0, step: float = 112.0) -> Verdict:
        _, expectation = self.expectation()
        model = expectation.model
        values = {model['control_label']: control, model['start_label']: 10000.0}
        for index, (time_label, casts_label) in enumerate(model['reads']):
            now = 10000.0 + index * step
            values[time_label] = now
            values[casts_label] = float(sum(1 for cast in range(100) if offset + cast * period <= now - 10000.0))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_command_follows_an_uncommanded_control_and_the_polls_follow_the_command(self):
        scenario, expectation = self.expectation()
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        command = next(index for index, step in enumerate(steps)
                       if step['action'] == 'cast' and step['spell'] == 504868)
        self.assertLess(labels.index(expectation.model['control_label']), command)
        self.assertLess(command, labels.index(expectation.model['reads'][0][0]))
        self.assertEqual(len(expectation.model['reads']), 9500 // 100 + 1)
        self.assertEqual(expectation.model['metric'], 'owned_creature_spell_cast_count')

    def test_a_one_second_period_passes(self):
        verdict = self.judged(1000.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertLess(verdict.low, verdict.measured)

    def test_the_live_period_and_a_slow_pulse_alert(self):
        self.assertEqual(self.judged(1240.0).status, 'alert')
        self.assertEqual(self.judged(3000.0).status, 'alert')
        self.assertEqual(self.judged(900.0).status, 'alert')

    def test_a_cast_without_a_command_alerts(self):
        self.assertEqual(self.judged(1000.0, control=1.0).status, 'alert')

    def test_too_few_casts_are_unmeasured(self):
        self.assertEqual(self.judged(20000.0).status, 'unmeasured')

    def test_polls_wider_than_half_the_period_are_refused(self):
        with self.assertRaises(ValueError):
            cast_period_spec({**bone_toss_entry(), 'poll_ms': 600})
        with self.assertRaises(ValueError):
            cast_period_spec({**bone_toss_entry(), 'control_ms': 1000})
