import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from passives import behaviour_label
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict


class AuraExpiryTests(unittest.TestCase):
    def entry(self) -> dict:
        return next(entry for entry in load_class_file(23)['behaviours']
                    if entry['spell'] == 503740 and entry.get('label_suffix') == 'frenzied_expiry')

    def expectation(self):
        _, [expectation] = behaviour_scenario(load_class_file(23), self.entry())
        return expectation

    def judged(self, marks, present, released=0.0, step=100.0):
        expectation = self.expectation()
        reads = expectation.model['reads']
        values = {expectation.model['released_label']: released}
        for index, (time, aura, marker) in enumerate(reads):
            values[time] = 1000.0 + step * index
            values[aura] = present(index)
            values[marker] = marks(index)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_roll_is_forced_then_stopped_and_the_mutant_removed(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(23), self.entry())
        run.validate(scenario)
        mutants = [step for step in scenario['steps'] if step['action'] == 'spell_mod_mutant']
        self.assertEqual([(step['spell'], step['op'], step['percent']) for step in mutants],
                         [(503740, 18, 1000), (503740, 18, -100)])
        self.assertEqual(scenario['steps'][-2], {'action': 'set_aura', 'actor': 'caster', 'spell': 100523, 'stacks': 0})
        self.assertEqual(expectation.model['switch_index'], 41)
        self.assertEqual(expectation.model['band_ms'], 500)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_duration_bracketed_inside_the_band_is_ok(self):
        verdict = self.judged(lambda index: 1.0 if index >= 20 else 0.0,
                              lambda index: 1.0 if 20 <= index < 120 else 0.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.low, verdict.high), (9500.0, 10500.0))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_short_or_long_duration_alerts(self):
        short = self.judged(lambda index: 1.0 if index >= 20 else 0.0, lambda index: 1.0 if 20 <= index < 110 else 0.0)
        self.assertEqual(short.status, 'alert')
        long = self.judged(lambda index: 1.0 if index >= 20 else 0.0, lambda index: 1.0 if 20 <= index < 130 else 0.0)
        self.assertEqual(long.status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_roll_after_the_switch_or_no_stamp_is_not_ok(self):
        rolled = self.judged(lambda index: 2.0 if index >= 60 else (1.0 if index >= 20 else 0.0),
                             lambda index: 1.0 if index >= 20 else 0.0)
        self.assertEqual(rolled.status, 'alert')
        unstamped = self.judged(lambda index: 0.0, lambda index: 1.0)
        self.assertEqual(unstamped.status, 'unmeasured')
        kept = self.judged(lambda index: 1.0 if index >= 20 else 0.0, lambda index: 1.0 if 20 <= index < 120 else 0.0,
                           released=1.0)
        self.assertEqual(kept.status, 'alert')


class AuraExpiryPassiveLinkTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_p5_link_names_the_aura_expiry_label(self):
        entry = next(entry for entry in load_class_file(23)['behaviours'] if entry['kind'] == 'aura_expiry')
        _, [expectation] = behaviour_scenario(load_class_file(23), entry)
        self.assertEqual(behaviour_label(entry), [expectation.label])
