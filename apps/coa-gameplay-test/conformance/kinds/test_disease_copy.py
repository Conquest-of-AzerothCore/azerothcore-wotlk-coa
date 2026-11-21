import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from kinds.disease_copy import disease_copy_spec
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 801938, 'name': 'Virulency (copy)', 'kind': 'disease_copy', 'label_suffix': 'copy',
         'quote': 'copying them, preserving their power and duration.', 'disease': 500338, 'infest': 803781,
         'duration_ms': 18000, 'power_aura': [10062, 0, 1000]}

KEPT = {'source_amount': 40.0, 'source_before': 16400.0, 'source_refreshed': 17700.0, 'copy_aura': 1.0,
        'copy_amount': 40.0, 'copy_duration': 17700.0, 'source_at_copy': 13000.0, 'control_amount': 122.0,
        'virulency_time': 1000.0, 'infest_time': 5700.0, 'copy_time': 6000.0}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class DiseaseCopyTests(unittest.TestCase):
    def judged(self, **changes) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = {expectation.model['reads'][name]: value for name, value in {**KEPT, **changes}.items()}
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_copy_is_cast_after_the_raise_and_the_control_after_the_copy(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        casts = [(step['spell'], step['target']) for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [(500338, 'extra1'), (801938, 'extra1'), (803781, 'primary'), (500338, 'extra2')])
        steps = scenario['steps']
        raise_at = next(index for index, step in enumerate(steps) if step.get('spell') == 10062)
        infest_at = next(index for index, step in enumerate(steps) if step.get('spell') == 803781
                         and step['action'] == 'cast')
        self.assertLess(raise_at, infest_at)
        self.assertEqual((steps[raise_at]['effect'], steps[raise_at]['amount']), (0, 1000))

    def test_a_kept_copy_passes(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_mutants_alert(self):
        for change in ({'copy_amount': 122.0}, {'copy_duration': 13000.0}, {'copy_aura': 0.0},
                       {'source_refreshed': 16100.0}):
            with self.subTest(change=change):
                self.assertEqual(self.judged(**change).status, 'alert')

    def test_an_unraised_control_or_a_short_gap_is_unmeasured(self):
        self.assertEqual(self.judged(control_amount=40.0).status, 'unmeasured')
        self.assertEqual(self.judged(virulency_time=5500.0).status, 'unmeasured')

    def test_waits_outside_the_disease_are_refused(self):
        for change in ({'copy_wait_ms': 18000}, {'power_aura': [10062, 3, 1000]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                disease_copy_spec({**ENTRY, **change})


if __name__ == '__main__':
    unittest.main()
