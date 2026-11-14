import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 806086, 'name': 'Muck Summoner (Rotlings run towards the enemy)', 'kind': 'summon_chase',
         'label_suffix': 'run', 'quote': 'Rotlings that will run towards the enemy', 'talent': 806086,
         'trigger_spell': 500237, 'entry': 50133, 'casts': 8, 'control_casts': 3, 'cast_gap_ms': 150,
         'move_yd': 12, 'window_ms': 2500, 'fuse_ms': 5000}
START = {'start summon to enemy': 1.5, 'start summon to caster': 4.5, 'start enemy to caster': 3.0}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SummonChaseTests(unittest.TestCase):
    def judged(self, end: dict, control: float = 0.0, summons: float = 2.0, released: float = 0.0,
               start: dict | None = None) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        reads = expectation.model['reads']
        marks = {**START, **(start or {}), **{f'end {read}': value for read, value in end.items()}, 'control summons': control,
                 'summons': summons, 'released': released}
        values = {reads[mark]: value for mark, value in marks.items()}
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def chased(self) -> dict:
        return {'summon to enemy': 1.8, 'summon to caster': 13.4, 'enemy to caster': 15.0}

    def test_the_enemy_is_movable_and_moves_after_the_last_summon(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        self.assertEqual([creature['stationary'] for creature in scenario['creatures']], [False])
        actions = [step['action'] for step in scenario['steps']]
        last_cast = max(index for index, action in enumerate(actions) if action == 'cast')
        self.assertLess(last_cast, actions.index('unlearn'))
        self.assertLess(actions.index('unlearn'), actions.index('move_point'))

    def test_a_summon_that_follows_the_enemy_passes(self):
        self.assertEqual(self.judged(self.chased()).status, 'ok')

    def test_a_summon_that_spawned_beyond_the_enemy_and_ends_on_its_near_side_passes(self):
        start = {'start summon to enemy': 2.0, 'start summon to caster': 5.0}
        self.assertEqual(self.judged({'summon to enemy': 1.28, 'summon to caster': 13.89, 'enemy to caster': 15.0},
                                     start=start).status, 'ok')

    def test_a_summon_that_stays_where_it_spawned_alerts(self):
        self.assertEqual(self.judged({'summon to enemy': 10.5, 'summon to caster': 4.5,
                                      'enemy to caster': 15.0}).status, 'alert')

    def test_a_summon_that_runs_short_of_melee_reach_alerts(self):
        self.assertEqual(self.judged({'summon to enemy': 6.5, 'summon to caster': 8.5,
                                      'enemy to caster': 15.0}).status, 'alert')

    def test_a_control_that_summons_alerts(self):
        self.assertEqual(self.judged(self.chased(), control=2.0).status, 'alert')

    def test_a_forcing_fixture_left_active_alerts(self):
        self.assertEqual(self.judged(self.chased(), released=1.0).status, 'alert')

    def test_no_summon_is_unmeasured(self):
        self.assertEqual(self.judged(self.chased(), summons=0.0).status, 'unmeasured')

    def test_an_enemy_that_does_not_move_is_unmeasured(self):
        self.assertEqual(self.judged({'summon to enemy': 1.5, 'summon to caster': 4.5,
                                      'enemy to caster': 3.2}).status, 'unmeasured')

    def test_a_read_past_the_fuse_is_rejected(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'window_ms': 4500})

    def test_a_move_inside_melee_reach_is_rejected(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'move_yd': 4})

    def test_the_chase_is_an_event_read_that_proves_the_run(self):
        from coverage import BEHAVIOUR, EVENT, metric_evidence, verdict_evidence
        found = self.judged(self.chased())
        self.assertEqual(found.detail['metric'], 'owned_creature_distance_2d')
        self.assertEqual(metric_evidence()['owned_creature_distance_2d'], EVENT)
        self.assertEqual(verdict_evidence(found, ENTRY['quote'], {}), BEHAVIOUR)

    def test_a_chase_without_its_evidence_row_is_refused(self):
        from unittest import mock
        import coverage
        found = self.judged(self.chased())
        without = {metric: kind for metric, kind in coverage.metric_evidence().items()
                   if metric != 'owned_creature_distance_2d'}
        with mock.patch.object(coverage, 'metric_evidence', return_value=without), \
                self.assertRaises(coverage.EvidenceError):
            coverage.verdict_evidence(found, ENTRY['quote'], {})
