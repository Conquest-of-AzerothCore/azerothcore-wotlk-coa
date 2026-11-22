import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 707629, 'name': 'Sunflare Aegis (extension)', 'kind': 'block_extension_trials',
         'label_suffix': 'block_extension',
         'quote': 'If Hammer of Kings is already active, you increase the duration by 4 sec.', 'aura': 804751,
         'extension_spell': 712469, 'extension_effect': 0, 'shield': 231296, 'strike_spell': 2118233,
         'cast_power': 1363, 'trials': 6, 'void_on_cast_failure': True}
STEP_DRIFT_MS = 15


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BlockExtensionTrialsTests(unittest.TestCase):
    def generated(self, **changes):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})
        return scenario, expectation

    def values(self, expiries, blocked=None):
        scenario, expectation = self.generated()
        offsets = [step['ms'] for step in scenario['steps']
                   if step['action'] == 'wait' and ' read ' in step.get('label', '') and 'trial 0 ' in step['label']]
        values, totals = {}, (0.0, 0.0)
        for index, (trial, expiry) in enumerate(zip(expectation.model['trials'], expiries)):
            start = 100000.0 * (index + 1)
            values[trial['cast_time']] = start
            values[trial['cast_aura']] = 1.0
            hit = 1.0 if blocked is None or blocked[index] else 0.0
            totals = (totals[0] + hit, totals[1] + 1.0 - hit)
            values[trial['blocked']], values[trial['unblocked']] = totals
            elapsed = 600.0
            for read, wait in zip(trial['reads'], offsets):
                elapsed += wait + STEP_DRIFT_MS
                values[read['time']] = start + elapsed
                values[read['aura']] = 1.0 if elapsed < expiry else 0.0
        return expectation, values

    def judged(self, expiries, blocked=None, cast_failures=None):
        expectation, values = self.values(expiries, blocked)
        fake = FakeRun(values)
        fake.cast_failures = cast_failures or {}
        return judge_behaviour(base_verdict(expectation), fake, expectation)

    def test_the_scenario_strikes_once_per_fresh_application_with_forced_blocks(self):
        scenario, expectation = self.generated()
        run.validate(scenario)
        steps = scenario['steps']
        strikes = [step for step in steps if step['action'] == 'cast' and step['actor'] == 'striker']
        casts = [step for step in steps if step['action'] == 'cast' and step['actor'] == 'caster'
                 and step['spell'] == 804751]
        self.assertEqual((len(strikes), len(casts)), (6, 6))
        fixtures = [step for step in steps if step['action'] == 'set_combat_avoidance']
        self.assertEqual({(step['block'], step['dodge'], step['parry']) for step in fixtures}, {(100, 0, 0)})
        self.assertEqual((expectation.model['base_ms'], expectation.model['extension_ms']), (12000, 4000))
        self.assertEqual(expectation.model['bands'], {'base': [10800.0, 12000 * 1.1], 'extended': [15600.0, 16400.0]})
        self.assertIn('number of extensions', scenario['contract'])
        self.assertEqual([creature['reaction'] for creature in scenario['creatures']], [0])

    def test_plain_and_extended_trials_are_ok_and_the_share_is_reported(self):
        verdict = self.judged([12000, 16000, 12000, 16000, 12000, 12000])
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('extended share 2/6', verdict.explanation)

    def test_mutant_extensions_of_three_and_five_seconds_alert(self):
        for expiry in (15000, 17000):
            with self.subTest(expiry=expiry):
                self.assertEqual(self.judged([12000, expiry, 12000, 16000, 12000, 12000]).status, 'alert')

    def test_mutant_base_durations_outside_the_band_alert(self):
        for expiry in (10000, 14500):
            with self.subTest(expiry=expiry):
                self.assertEqual(self.judged([expiry, 16000, 12000, 16000, 12000, 12000]).status, 'alert')

    def test_never_extended_is_unmeasured(self):
        self.assertEqual(self.judged([12000] * 6).status, 'unmeasured')

    def test_a_strike_not_blocked_voids_its_trial(self):
        verdict = self.judged([12000, 17000, 16000, 12000, 12000, 12000],
                              blocked=[True, False, True, True, True, True])
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['void'], 1)

    def test_a_refused_cast_voids_the_run(self):
        verdict = self.judged([12000, 16000, 12000, 16000, 12000, 12000], cast_failures={804751: [97]})
        self.assertEqual(verdict.status, 'unmeasured')

    def test_a_missing_read_is_unmeasured(self):
        _, expectation = self.generated()
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun({}), expectation).status, 'unmeasured')

    def test_unknown_keys_and_bad_trials_are_refused(self):
        for changes in ({'trials': 0}, {'trials': True}, {'block': 100}, {'void_on_cast_failure': 'yes'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.generated(**changes)


if __name__ == '__main__':
    unittest.main()
