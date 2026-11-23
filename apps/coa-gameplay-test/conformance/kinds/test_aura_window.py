import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from kinds.aura_window import aura_window_spec
from profile import CASTER, DBC_DIR, load_class_file, load_fixture_class_file
from test_behaviours import FakeRun


GRAVEN = {
    'spell': 506635, 'kind': 'aura_window', 'variant': 'graven_cc', 'label_suffix': 'graven_cc', 'name': 'Graven',
    'quote': 'have the duration of crowd control effects on them increased by $504767s1%', 'trigger_spell': 802065,
    'aura': 802065, 'control_ms': 10000, 'treatment_ms': 12500, 'control_windows': [[20, 400], [9700, 10400]],
    'treatment_windows': [[20, 400], [12200, 12900]], 'trigger_power': 1400, 'poll_ms': 1,
    'setup_casts': [{'spell': 506635, 'target': 'caster', 'wait_ms': 1200}], 'treatment_band_ms': 200}


def channel_entry() -> dict:
    return next(entry for entry in load_fixture_class_file(23)['behaviours']
                if entry['kind'] == 'aura_window' and entry['label_suffix'] == 'channel')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraWindowTests(unittest.TestCase):
    def judged(self, control: tuple[float, float], treatment: tuple[float, float]) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), channel_entry())
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

    def test_setup_casts_run_in_the_treatment_phase_only_and_narrow_the_band(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(13), GRAVEN)
        casts = [(step['spell'], step['target']) for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [(802065, 'dummy'), (506635, CASTER), (802065, 'dummy')])
        self.assertEqual(expectation.model['bands'], {'treatment': 200})
        self.assertIn('first makes the real casts', scenario['contract'])
        plain, [channel] = behaviour_scenario(load_fixture_class_file(23), channel_entry())
        self.assertNotIn('bands', channel.model)
        self.assertNotIn('real casts', plain['contract'])

    def test_a_band_wider_than_the_g19_band_is_refused(self):
        with self.assertRaises(ValueError):
            aura_window_spec({**GRAVEN, 'treatment_band_ms': 700})
