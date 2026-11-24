import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def lasts_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'shield_lasts')
    return {**entry, 'expected': 300, 'before_expected': 100, 'after_expiry_expected': 100,
            'void_on_cast_failure': True, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class VoidOnCastFailureTests(unittest.TestCase):
    def judged(self, failures, entry=None):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry or lasts_entry())
        model = expectation.model
        values = {model['before_label']: 100.0, model['after_label']: 300.0}
        if 'expired_label' in model:
            values[model['expired_label']] = 100.0
        fake = FakeRun(values)
        fake.cast_failures = failures
        return judge_behaviour(base_verdict(expectation), fake, expectation)

    def test_a_refused_setup_cast_voids_the_trial(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), lasts_entry())
        run.validate(scenario)
        self.assertIn('unmeasured', scenario['contract'])
        for failures in ({500143: [105]}, {500143: [0, 105], 804584: [105]}):
            with self.subTest(failures=failures):
                verdict = self.judged(failures)
                self.assertEqual(verdict.status, 'unmeasured')
                self.assertIn('SPELL_IN_PROGRESS', verdict.explanation)

    def test_a_clean_run_is_judged(self):
        self.assertEqual(self.judged({}).status, 'ok')
        self.assertEqual(self.judged({500143: [0]}).status, 'ok')

    def test_mutant_without_the_flag_judges_the_refused_run(self):
        plain = {key: value for key, value in lasts_entry().items() if key != 'void_on_cast_failure'}
        self.assertEqual(self.judged({500143: [105]}, plain).status, 'ok')

    def test_the_flag_is_refused_for_a_cast_failure_metric(self):
        for changes in ({'void_on_cast_failure': False}, {'metric': 'cast_failure'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), lasts_entry(**changes))


if __name__ == '__main__':
    unittest.main()
