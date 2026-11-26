import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

OPTION = {'casts': 4, 'min_uncritical': 2}


def entry(**changes) -> dict:
    found = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 707562 and entry.get('variant') == 'no_crit')
    return {**found, 'uncritical_casts': OPTION, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class UncriticalCastsTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), entry(**changes))

    def values(self, expectation, readings, critical, landed, before=0.0) -> dict:
        option = expectation.model['uncritical_casts']
        held = {expectation.model['before_label']: before}
        held.update(zip(option['after_labels'], readings))
        held.update(zip(option['critical'], critical))
        held.update(zip(option['landed'], landed))
        return held

    def judged(self, expectation, held: dict):
        return judge_behaviour(base_verdict(expectation), FakeRun(held), expectation)

    def test_every_treatment_cast_is_repeated_with_its_reading_and_hit_counts(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        option = expectation.model['uncritical_casts']
        self.assertEqual(len(option['after_labels']), 4)
        trigger_casts = [index for index, step in enumerate(steps) if step.get('action') == 'cast']
        self.assertEqual(len(trigger_casts), 5)
        reads = [labels.index(label) for label in option['after_labels']]
        self.assertEqual(reads, sorted(reads))
        for cast, read in zip(trigger_casts[1:], reads):
            self.assertLess(cast, read)
        for index, read in enumerate(reads, 1):
            self.assertEqual(labels[read + 1], option['critical'][index])
            self.assertEqual(steps[read + 1]['critical'], True)
            self.assertEqual(labels[read + 2], option['landed'][index])
            self.assertEqual(steps[read + 2]['critical'], False)
        self.assertEqual(labels.index(option['critical'][0]), labels.index(expectation.model['before_label']) + 1)

    def test_without_the_option_the_scenario_is_unchanged(self):
        plain = {key: value for key, value in entry().items() if key != 'uncritical_casts'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), plain)
        self.assertNotIn('uncritical_casts', expectation.model)
        self.assertEqual(sum(step.get('action') == 'cast' for step in scenario['steps']), 2)

    def test_the_option_is_refused_outside_its_shape_and_bounds(self):
        for raw in (True, {'casts': 4}, {'casts': 1, 'min_uncritical': 1}, {'casts': 4, 'min_uncritical': 5},
                    {'casts': 4, 'min_uncritical': 0}, {'casts': True, 'min_uncritical': 1}):
            with self.assertRaises(ValueError):
                self.built(uncritical_casts=raw)
        with self.assertRaises(ValueError):
            self.built(force_crit='spell')
        with self.assertRaises(ValueError):
            self.built(gate_timing='start')

    def test_a_recorded_critical_control_cast_is_dropped_and_the_others_are_judged(self):
        _, [expectation] = self.built()
        held = self.values(expectation, [1, 0, 0, 0], critical=[0, 1, 1, 1, 1], landed=[1, 2, 3, 4, 5])
        verdict = self.judged(expectation, held)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('cast 1 dropped (1 critical damage event)', verdict.explanation)

    def test_the_same_reading_without_the_critical_event_alerts(self):
        _, [expectation] = self.built()
        held = self.values(expectation, [1, 0, 0, 0], critical=[0, 0, 0, 0, 0], landed=[1, 2, 3, 4, 5])
        self.assertEqual(self.judged(expectation, held).status, 'alert')

    def test_a_mutant_that_gains_on_every_non_critical_cast_alerts(self):
        _, [expectation] = self.built()
        held = self.values(expectation, [1, 1, 1, 1], critical=[0, 1, 1, 1, 1], landed=[1, 2, 3, 4, 5])
        self.assertEqual(self.judged(expectation, held).status, 'alert')

    def test_below_the_minimum_of_non_critical_casts_the_entry_is_unmeasured(self):
        _, [expectation] = self.built()
        held = self.values(expectation, [1, 1, 1, 0], critical=[0, 1, 2, 3, 3], landed=[1, 1, 1, 1, 2])
        verdict = self.judged(expectation, held)
        self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)
        self.assertIn('below the stated minimum of 2', verdict.explanation)

    def test_a_cast_without_a_landed_hit_is_dropped(self):
        _, [expectation] = self.built()
        held = self.values(expectation, [1, 0, 0, 0], critical=[0, 0, 0, 0, 0], landed=[1, 1, 2, 3, 4])
        verdict = self.judged(expectation, held)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('cast 1 dropped (no landed non-critical hit)', verdict.explanation)

    def test_a_missing_hit_count_is_unmeasured(self):
        _, [expectation] = self.built()
        held = self.values(expectation, [0, 0, 0, 0], critical=[0, 0, 0, 0, 0], landed=[1, 2, 3, 4, 5])
        del held[expectation.model['uncritical_casts']['landed'][3]]
        self.assertEqual(self.judged(expectation, held).status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
