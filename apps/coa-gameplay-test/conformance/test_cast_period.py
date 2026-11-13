from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from behaviours import behaviour_scenario
from cast_period import aura_window_spec, cast_period_spec
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_class_file
import run


class FakeRun:
    def __init__(self, values):
        self.values = values
        self.key = 'fake'
        self.status = 'completed'
        self.message = ''
        self.steps = []
        self.max_step_ms = None
        self.cast_failures = {}


def bone_toss_entry() -> dict:
    return next(entry for entry in load_class_file(23)['behaviours']
                if entry['kind'] == 'cast_period' and entry['label_suffix'] == 'bone_toss_period')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CastPeriodTests(unittest.TestCase):
    def expectation(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(23), bone_toss_entry())
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
        scenario, expectation = behaviour_scenario(load_class_file(23), bonestorm_cap_entry())
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


def channel_entry() -> dict:
    return next(entry for entry in load_class_file(23)['behaviours']
                if entry['kind'] == 'aura_window' and entry['label_suffix'] == 'channel')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraWindowTests(unittest.TestCase):
    def judged(self, control: tuple[float, float], treatment: tuple[float, float]) -> Verdict:
        _, [expectation] = behaviour_scenario(load_class_file(23), channel_entry())
        values = {}
        for name, (start, end) in (('control', control), ('treatment', treatment)):
            phase = expectation.model['reads'][name]
            values[phase['cast']] = 0.0
            for index, (time_label, aura_label) in enumerate(phase['rows']):
                now = 500.0 + index * 10.0 if index < len(phase['rows']) // 2 else start + end + index * 10.0
                values[time_label] = now
            times = [values[time_label] for time_label, _ in phase['rows']]
            half = len(times) // 2
            starts = [500.0 + index * 10.0 for index in range(half)]
            ends = [end - 50.0 + index * 10.0 for index in range(len(times) - half)]
            for (time_label, aura_label), now in zip(phase['rows'], starts + ends):
                values[time_label] = now
                values[aura_label] = 1.0 if start <= now < end else 0.0
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_stated_channels_pass_and_an_unshortened_one_alerts(self):
        self.assertEqual(self.judged((540.0, 1540.0), (540.0, 1290.0)).status, 'ok')
        self.assertEqual(self.judged((540.0, 1540.0), (540.0, 1540.0)).status, 'alert')

    def test_a_window_that_misses_the_start_is_unmeasured(self):
        self.assertEqual(self.judged((100.0, 1100.0), (540.0, 1290.0)).status, 'unmeasured')

    def test_windows_out_of_order_are_refused(self):
        with self.assertRaises(ValueError):
            aura_window_spec({**channel_entry(), 'control_windows': [[3040, 3160], [2060, 2180]]})


if __name__ == '__main__':
    unittest.main()
