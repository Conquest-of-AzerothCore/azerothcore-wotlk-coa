import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun


def bonestorm_cap_entry() -> dict:
    return next(entry for entry in load_class_file(23)['behaviours']
                if entry['kind'] == 'pulse_targets' and entry['label_suffix'] == 'bonestorm_cap')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PulseTargetsTests(unittest.TestCase):
    def judged(self, struck_per_pulse: list[int], far_struck: bool = False) -> Verdict:
        _, [expectation] = behaviour_scenario(load_class_file(23), bonestorm_cap_entry())
        model = expectation.model
        counts = [0] * (model['far_index'] + 1)
        values = {}
        pulses = iter(struck_per_pulse)
        for index, row in enumerate(model['reads']):
            if index and index % 10 == 0:
                for dummy in range(next(pulses, 0)):
                    counts[dummy] += 1
            if far_struck and index == len(model['reads']) - 1:
                counts[-1] += 1
            values[row[0]] = 1000.0 + index * 50
            for label, count in zip(row[1:], counts):
                values[label] = float(count)
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_dummies_and_the_polls_are_placed(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(23), bonestorm_cap_entry())
        run.validate(scenario)
        self.assertEqual(len(scenario['creatures']), 8)
        self.assertEqual(len(expectation.model['reads'][0]), 1 + 8)

    def test_pulses_at_the_cap_pass_and_a_wider_pulse_alerts(self):
        self.assertEqual(self.judged([5, 5, 5, 5]).status, 'ok')
        self.assertEqual(self.judged([5, 6, 5, 5]).status, 'alert')
        self.assertEqual(self.judged([4, 4, 4, 4]).status, 'alert')
        self.assertEqual(self.judged([5, 5, 5, 5], far_struck=True).status, 'alert')

    def test_too_few_pulses_are_unmeasured(self):
        self.assertEqual(self.judged([5]).status, 'unmeasured')
