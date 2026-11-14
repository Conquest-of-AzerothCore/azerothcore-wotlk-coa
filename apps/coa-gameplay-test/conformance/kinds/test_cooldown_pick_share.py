import unittest

from behaviours import behaviour_scenario
from compare import Verdict
from kinds.cooldown_pick_share import pick_share_verdict, share_band
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 704701, 'name': 'Underking (Animate pick at random)', 'kind': 'cooldown_pick_share',
         'label_suffix': 'pick_share', 'quote': 'is reduced by $/1000;302517s1 sec at random',
         'command_spell': 504868, 'command_power': 300, 'commands': 10, 'pool': [805032, 805044, 805048],
         'cut_ms': 15000, 'cycles': 10, 'control_cycles': 1, 'zombie_entry': 503032, 'mana': 2848}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownPickShareTests(unittest.TestCase):
    def setUp(self):
        self.scenario, [self.expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.model = self.expectation.model

    def values(self, picks: list[int | None], control_cut: bool = False, refused: bool = False) -> dict:
        values = {}
        treatment = iter(picks)
        for row in self.model['rows']:
            pick = (0 if control_cut else None) if row['phase'] == 'control' else next(treatment)
            for index, (prime, pre, post) in enumerate(zip(row['prime'], row['pre'], row['post'])):
                values[prime] = 67.0 if refused else 0.0
                values[pre] = 40000.0 + 1000.0 * index
                values[post] = values[pre] - 310.0 - (15000.0 if pick == index else 0.0)
            values[row['zombie']] = 0.0 if row['phase'] == 'control' else 1.0
        return values

    def judged(self, parts: list[list[int | None]], **options) -> Verdict:
        base = Verdict(self.expectation.label, 'alert', None, None, None, None, '', 'fake',
                       self.expectation.spell_id, self.expectation.rank_id, self.expectation.check)
        return pick_share_verdict(base, [FakeRun(self.values(picks, **options)) for picks in parts], self.model)

    def test_the_scenario_validates_and_learns_the_talent_after_the_control_cycle(self):
        run.validate(self.scenario)
        actions = [(step['action'], step.get('spell')) for step in self.scenario['steps']]
        self.assertLess(actions.index(('cast', 504868)), actions.index(('learn', 704701)))

    def test_a_uniform_pick_over_three_parts_passes(self):
        self.assertEqual(self.judged([[0, 1, 2, 0, 1, 2, 0, 1, 2, 0]] * 3).status, 'ok')

    def test_a_fixed_pick_alerts(self):
        verdict = self.judged([[1] * 10] * 3)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('never picked', verdict.explanation)

    def test_a_cycle_without_a_cut_alerts(self):
        self.assertEqual(self.judged([[0, 1, 2, 0, 1, 2, 0, 1, 2, None]] * 3).status, 'alert')

    def test_a_cut_without_the_talent_alerts(self):
        self.assertEqual(self.judged([[0, 1, 2, 0, 1, 2, 0, 1, 2, 0]] * 3, control_cut=True).status, 'alert')

    def test_a_refused_priming_cast_is_unmeasured(self):
        self.assertEqual(self.judged([[0, 1, 2, 0, 1, 2, 0, 1, 2, 0]] * 3, refused=True).status, 'unmeasured')

    def test_the_uniform_band_of_thirty_cycles_over_three(self):
        self.assertEqual(share_band(30, 3), (2, 19))

    def stamped(self, verdict: Verdict) -> Verdict:
        from dataclasses import replace
        from compare import observed
        return replace(verdict, detail={**(verdict.detail or {}), **observed(self.expectation)})

    def test_a_controlled_pick_share_is_behaviour_evidence(self):
        from coverage import BEHAVIOUR, verdict_evidence
        found = self.stamped(self.judged([[0, 1, 2, 0, 1, 2, 0, 1, 2, 0]] * 3))
        self.assertEqual(found.status, 'ok')
        self.assertEqual(found.detail['metric'], 'cooldown_pick_share')
        self.assertEqual(verdict_evidence(found, 'at random', {}), BEHAVIOUR)

    def test_a_pick_share_without_its_control_cycle_stays_data(self):
        from coverage import DATA, verdict_evidence
        self.model['rows'] = [row for row in self.model['rows'] if row['phase'] != 'control']
        found = self.stamped(self.judged([[0, 1, 2, 0, 1, 2, 0, 1, 2, 0]] * 3))
        self.assertEqual(found.status, 'ok')
        self.assertNotIn('contrast', found.detail)
        self.assertEqual(verdict_evidence(found, 'at random', {}), DATA)
