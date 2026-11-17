import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 806086, 'name': 'Muck Summoner (Rotling fuse)', 'kind': 'spawn_fuse', 'label_suffix': 'fuse',
         'quote': 'and explode after $807640t2 sec', 'talent': 806086, 'trigger_spell': 500237, 'entry': 50133,
         'fuse_spell': 500585, 'expected_ms': 5000, 'casts': 12, 'control_casts': 3, 'settle_ms': 7000}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SpawnFuseTests(unittest.TestCase):
    def judged(self, control=0.0, spawns=2.0, spawn=11836.0, fuse=16841.0, released=0.0):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        reads = expectation.model['reads']
        values = {reads['control spawns']: control, reads['spawns']: spawns, reads['first spawn']: spawn,
                  reads['first fuse']: fuse, reads['released']: released}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_timeline_starts_before_the_control_and_the_talent_follows_it(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        start = next(index for index, step in enumerate(steps) if step['action'] == 'encounter_start')
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 806086)
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertLess(start, casts[0])
        self.assertEqual(len(casts), 15)
        self.assertEqual(sum(index < learn for index in casts), 3)

    def test_a_fuse_inside_the_band_passes_and_outside_alerts(self):
        self.assertEqual(self.judged().status, 'ok')
        self.assertEqual(self.judged(fuse=11836.0 + 5900.0).status, 'alert')

    def test_a_control_spawn_or_a_kept_mutant_alerts(self):
        self.assertEqual(self.judged(control=2.0).status, 'alert')
        self.assertEqual(self.judged(released=1.0).status, 'alert')

    def test_no_spawn_is_unmeasured_and_a_spawn_without_its_fuse_alerts(self):
        self.assertEqual(self.judged(spawns=0.0, spawn=float('nan'), fuse=float('nan')).status, 'unmeasured')
        self.assertEqual(self.judged(fuse=float('nan')).status, 'alert')

    def test_a_settle_shorter_than_the_fuse_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'settle_ms': 5000})
