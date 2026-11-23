from random import Random
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 560492, 'kind': 'avoided_icd', 'name': 'Protector of the Flame (once per sec)', 'variant': 'icd',
         'label_suffix': 'icd', 'quote': 'Can only occur once per sec.', 'hit_spell': 560493, 'timer_ms': 1000,
         'striker_entry': 36, 'strikers': 10, 'striker_auras': [42716, 62531, 2116852], 'swing_ms': 500,
         'control_windows': 10, 'windows': 60}
ENGAGE = (30, 28, 4)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedIcdTests(unittest.TestCase):
    def generated(self, entry=ENTRY):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def timed_hits(self, timer_ms: float, seed: int = 560492) -> tuple[int, float, int]:
        rng = Random(seed)
        swings = sorted(rng.uniform(0, 30000) for _ in range(600))
        hits, ready = [], 0.0
        for swing in swings:
            if swing >= ready:
                hits.append(swing)
                ready = swing + timer_ms
        shortest = min(later - earlier for earlier, later in zip(hits, hits[1:]))
        return len(hits), round(shortest), len(swings)

    def verdict(self, hits=30, shortest=1010.0, avoided=300, control=0, extra_attacks=0, failures=None, drop=None,
                first_attacks=0, distance=17.0):
        _, expectation = self.generated()
        reads = expectation.model['reads']
        start = dict(zip(reads['start_avoided'], ENGAGE))
        split = (avoided // 2, avoided - avoided // 2 - avoided // 10, avoided // 10)
        values = {**start, **{label: start_value + gained for (label, gained), start_value
                              in zip(zip(reads['avoided'], split), ENGAGE)}}
        values[reads['attacks']] = sum(ENGAGE) + avoided + extra_attacks
        values[reads['attacks_first']] = values[reads['attacks']] - first_attacks
        values.update({label: distance for label in reads['quiet_distances']})
        values.update({reads['control_hits']: control, reads['hits']: hits, reads['shortest']: shortest,
                       reads['median']: shortest + 30})
        if drop:
            values.pop(reads[drop])
        fake = FakeRun(values)
        fake.cast_failures = failures or {}
        return judge_behaviour(base_verdict(expectation), fake, expectation)

    def test_the_scenario_validates_and_learns_after_the_control_windows(self):
        scenario, expectation = self.generated()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == ENTRY['spell'])
        self.assertLess(labels.index(expectation.model['reads']['control_hits']), learn)
        self.assertLess(learn, labels.index(expectation.model['reads']['shortest']))
        self.assertEqual(len(scenario['creatures']), 10)
        self.assertIn('2^-20', scenario['contract'])
        self.assertEqual(expectation.model['band'], [950.0, 1050.0])

    def test_a_shortest_interval_at_the_timer_is_ok(self):
        hits, shortest, swings = self.timed_hits(1000)
        verdict = self.verdict(hits=hits, shortest=float(shortest), avoided=swings)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_a_mutant_900_ms_timer_alerts(self):
        hits, shortest, swings = self.timed_hits(900)
        verdict = self.verdict(hits=hits, shortest=float(shortest), avoided=swings)
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_a_mutant_1100_ms_timer_alerts(self):
        hits, shortest, swings = self.timed_hits(1100)
        verdict = self.verdict(hits=hits, shortest=float(shortest), avoided=swings)
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_a_mutant_without_a_timer_alerts(self):
        self.assertEqual(self.verdict(hits=30, shortest=40.0).status, 'alert')

    def test_a_hit_before_the_learn_alerts(self):
        verdict = self.verdict(control=1)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('before the passive', verdict.explanation)

    def test_window_conditions_not_met_are_void(self):
        for change in ({'hits': 20}, {'avoided': 299}, {'extra_attacks': 1}, {'failures': {560492: [12]}},
                       {'drop': 'hits'}):
            with self.subTest(change=change):
                verdict = self.verdict(**change)
                self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)

    def test_the_strikers_are_quieted_before_the_outcome_reads(self):
        scenario, expectation = self.generated()
        steps = scenario['steps']
        reads = expectation.model['reads']
        labels = [step.get('label') for step in steps]
        relocation = next(index for index, step in enumerate(steps) if step['action'] == 'relocate')
        self.assertEqual(steps[relocation]['dx'], 20)
        self.assertEqual(steps[relocation + 1]['action'], 'wait')
        self.assertGreaterEqual(steps[relocation + 1]['ms'], 200)
        self.assertEqual(labels.index(reads['attacks_first']), relocation + 2 + len(reads['quiet_distances']))
        self.assertEqual(len(reads['quiet_distances']), 10)
        self.assertLess(labels.index(reads['attacks_first']), labels.index(reads['avoided'][0]))
        self.assertLess(labels.index(reads['avoided'][0]), labels.index(reads['attacks']))
        self.assertEqual(expectation.model['quiet_minimum_yd'], 17.0)

    def test_a_total_that_changed_while_the_outcomes_were_read_is_void(self):
        verdict = self.verdict(first_attacks=1)
        self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)
        self.assertIn('changed', verdict.explanation)

    def test_a_failed_relocation_is_void(self):
        verdict = self.verdict(distance=16.9)
        self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)
        self.assertIn('quiets the strikers', verdict.explanation)
        self.assertEqual(self.verdict(distance=17.0).status, 'ok')

    def test_a_missing_quiet_read_is_void(self):
        self.assertEqual(self.verdict(drop='attacks_first').status, 'unmeasured')

    def test_a_cast_failure_list_without_a_refusal_is_not_void(self):
        self.assertEqual(self.verdict(failures={560492: [0]}).status, 'ok')

    def test_faulty_entries_are_refused(self):
        for change in ({'windows': 40}, {'timer_ms': 0}, {'strikers': 11}, {'control_windows': 0}, {'extra': 1}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.generated({**ENTRY, **change})


if __name__ == '__main__':
    unittest.main()
