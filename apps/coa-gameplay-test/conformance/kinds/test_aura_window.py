import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from kinds.aura_window import aura_window_spec
from profile import DBC_DIR, load_class_file
from test_behaviours import FakeRun


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
