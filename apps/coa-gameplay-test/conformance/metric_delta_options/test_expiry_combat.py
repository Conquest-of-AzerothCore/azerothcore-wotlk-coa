import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

LATE = {'late_wait_ms': 3000}


def lasts_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'shield_lasts')
    return {**entry, 'expected': 300, 'before_expected': 100, 'after_at_least': 101, 'after_expiry_expected': 100,
            'expiry_below_after': True, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ExpiryCombatTests(unittest.TestCase):
    def judged(self, late=200.0, expired=250.0, combat_expired=0.0, combat_late=0.0, **changes):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                              lasts_entry(expiry_combat=LATE, **changes))
        model = expectation.model
        read = model['expiry_combat']
        values = {model['before_label']: 100.0, model['after_label']: 300.0, model['expired_label']: expired,
                  read['combat_expired']: combat_expired, read['combat_late']: combat_late, read['late_label']: late}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_combat_state_is_read_around_the_expired_and_the_late_readings(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), lasts_entry(expiry_combat=LATE))
        run.validate(scenario)
        read = expectation.model['expiry_combat']
        labels = [step.get('label') for step in scenario['steps']]
        self.assertEqual(labels.index(read['combat_expired']) + 1, labels.index(expectation.model['expired_label']))
        self.assertEqual(labels.index(read['combat_late']) + 1, labels.index(read['late_label']))
        self.assertEqual(scenario['steps'][labels.index(read['combat_late']) - 1]['ms'], 3000)

    def test_a_fall_out_of_combat_passes(self):
        self.assertEqual(self.judged().status, 'ok')

    def test_mutant_no_further_fall_alerts(self):
        for late in (250.0, 260.0, 99.0):
            with self.subTest(late=late):
                self.assertEqual(self.judged(late=late).status, 'alert')

    def test_a_caster_still_in_combat_is_unmeasured(self):
        self.assertEqual(self.judged(combat_expired=1.0).status, 'unmeasured')
        self.assertEqual(self.judged(combat_late=1.0).status, 'unmeasured')

    def test_without_the_option_nothing_is_read(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), lasts_entry())
        self.assertNotIn('expiry_combat', expectation.model)
        self.assertFalse(any(step.get('metric') == 'combat' for step in scenario['steps']))

    def test_the_option_needs_the_expiry_read_the_direction_judge_and_a_wait(self):
        for changes in ({'expiry_wait_ms': None, 'after_expiry_expected': None}, {'expiry_below_after': None},
                        {'expiry_combat': {}}, {'expiry_combat': {'late_wait_ms': 0}}, {'expiry_combat': True}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), lasts_entry(**{'expiry_combat': LATE, **changes}))


if __name__ == '__main__':
    unittest.main()
