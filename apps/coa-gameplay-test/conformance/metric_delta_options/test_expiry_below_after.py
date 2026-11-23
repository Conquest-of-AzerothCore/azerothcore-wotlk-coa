import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def lasts_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'shield_lasts')
    return {**entry, 'expected': 300, 'before_expected': 100, 'after_at_least': 101, 'after_expiry_expected': 100,
            'expiry_below_after': True, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ExpiryBelowAfterTests(unittest.TestCase):
    def judged(self, expired, after=300.0, before=100.0, **changes):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), lasts_entry(**changes))
        model = expectation.model
        values = {model['before_label']: before, model['after_label']: after, model['expired_label']: expired}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_expired_reading_is_judged_below_the_after_reading_and_above_its_floor(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), lasts_entry())
        run.validate(scenario)
        self.assertTrue(expectation.model['expiry_below_after'])
        self.assertIn('direction only', scenario['contract'])
        self.assertEqual(self.judged(250.0).status, 'ok')
        self.assertEqual(self.judged(100.0).status, 'ok')
        for expired in (300.0, 310.0, 99.0):
            with self.subTest(expired=expired):
                self.assertEqual(self.judged(expired).status, 'alert')

    def test_the_before_and_after_readings_are_judged_as_before(self):
        self.assertEqual(self.judged(150.0, after=100.5).status, 'alert')
        self.assertEqual(self.judged(150.0, before=120.0).status, 'alert')

    def test_mutant_without_the_option_the_expired_reading_must_equal_its_floor(self):
        plain = {key: value for key, value in lasts_entry().items() if key != 'expiry_below_after'}
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), plain)
        model = expectation.model
        self.assertNotIn('expiry_below_after', model)
        values = {model['before_label']: 100.0, model['after_label']: 300.0, model['expired_label']: 250.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')

    def test_the_option_needs_an_expiry_read_and_a_floor_below_the_after_floor(self):
        for changes in ({'expiry_below_after': False}, {'after_at_least': None}, {'after_expiry_expected': 101},
                        {'expiry_wait_ms': None, 'after_expiry_expected': None}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), lasts_entry(**changes))


if __name__ == '__main__':
    unittest.main()
