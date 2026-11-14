import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 805197, 'name': 'Graveyard (every raised Undead leaves a corpse)', 'kind': 'corpse_per_raise',
         'label_suffix': 'corpse_per_raise', 'quote': 'and creating a corpse.', 'raise_spell': 500365,
         'corpse_entry': 542065, 'death_ms': 1000, 'control_window_ms': 500, 'window_ms': 9000, 'cast_power': 1373,
         'poll_ms': 100}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CorpsePerRaiseTests(unittest.TestCase):
    def judged(self, raises=(2000.0, 2000.0, 5000.0, 5000.0), corpse_share: float = 1.0,
               control_corpse: bool = False) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = {}
        for arm, rows in expectation.model['reads'].items():
            for index, (time, raised, corpses) in enumerate(rows):
                now = index * 109.0
                values[time] = now
                if arm == 'control':
                    values[raised], values[corpses] = 0.0, 1.0 if control_corpse else 0.0
                    continue
                done = [moment for moment in raises if moment <= now]
                dead = [moment for moment in raises if moment + 500.0 <= now]
                values[raised] = float(len(done))
                values[corpses] = float(int(len(dead) * corpse_share))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_corpse_read_counts_dead_creatures(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        reads = [step for step in scenario['steps'] if step.get('metric') == 'nearby_creature_count']
        self.assertTrue(reads and all(step['dead'] is True for step in reads))

    def test_one_corpse_per_raise_passes(self):
        self.assertEqual(self.judged().status, 'ok')

    def test_missing_corpses_alert(self):
        self.assertEqual(self.judged(corpse_share=0.5).status, 'alert')
        self.assertEqual(self.judged(corpse_share=0.0).status, 'alert')

    def test_a_corpse_without_the_cast_alerts(self):
        self.assertEqual(self.judged(control_corpse=True).status, 'alert')

    def test_a_single_raise_is_unmeasured(self):
        self.assertEqual(self.judged(raises=(2000.0,)).status, 'unmeasured')
