import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 537208, 'name': 'Dominion of Frost (one cut per second)', 'kind': 'minion_crit_gate',
         'label_suffix': 'once_per_sec', 'quote': 'Can only occur once per sec.', 'learn': [92123],
         'raises': [[500971, 50073, 1000], [500970, 50065, 1000]], 'crit_aura': [280912, 100],
         'observe_spell': 805029, 'observe_power': 1373, 'cut_ms': 3000, 'windows': 3, 'window_ms': 4000}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MinionCritGateTests(unittest.TestCase):
    def judged(self, cuts_per_window: int, crits_per_minion: int = 2, ran_out: bool = False) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = {}
        for index, window in enumerate(expectation.model['windows']):
            start = 10000.0 * index
            values.update(zip(window['before'], (start, 120000.0, 2.0 * index, 2.0 * index)))
            values.update(zip(window['after'], (start + 4000.0,
                                                0.0 if ran_out else 116000.0 - 3000.0 * cuts_per_window,
                                                2.0 * index + crits_per_minion, 2.0 * index + crits_per_minion)))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_both_minions_get_the_forced_crit(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        owned = {step['owned_entry'] for step in scenario['steps'] if step['action'] == 'set_aura'}
        self.assertEqual(owned, {50073, 50065})

    def test_one_cut_for_two_crits_passes(self):
        self.assertEqual(self.judged(2).status, 'ok')

    def test_a_cut_for_every_crit_alerts(self):
        self.assertEqual(self.judged(4).status, 'alert')

    def test_too_few_crits_are_unmeasured(self):
        self.assertEqual(self.judged(1, crits_per_minion=0).status, 'unmeasured')

    def test_a_cooldown_that_runs_out_is_unmeasured(self):
        self.assertEqual(self.judged(2, ran_out=True).status, 'unmeasured')

    def attempted(self, early: int, late: int) -> Verdict:
        entry = {**ENTRY, 'variant': 'attempts', 'label_suffix': 'once_per_sec_gate', 'windows': 1,
                 'attempts_ms': [50000, 100000]}
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        values = {expectation.model['primed']: 179997.0, **dict(zip(expectation.model['attempts'], (early, late)))}
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_refused_early_and_cast_late_passes(self):
        self.assertEqual(self.attempted(67, 0).status, 'ok')

    def test_an_ungated_cut_that_clears_early_alerts(self):
        self.assertEqual(self.attempted(0, 67).status, 'alert')

    def test_a_gate_too_long_to_clear_late_alerts(self):
        self.assertEqual(self.attempted(67, 67).status, 'alert')
