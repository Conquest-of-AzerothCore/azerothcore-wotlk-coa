import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds import kind_pooled_judge
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 707629, 'name': 'Sunflare Aegis (extension)', 'kind': 'block_extension_trials',
         'label_suffix': 'block_extension',
         'quote': 'If Hammer of Kings is already active, you increase the duration by 4 sec.', 'aura': 804751,
         'extension_spell': 712469, 'extension_effect': 0, 'shield': 231296, 'strike_spell': 2118233,
         'cast_power': 1363, 'trials': 6, 'void_on_cast_failure': True}
STEP_DRIFT_MS = 15


class ExtensionHelpers:
    entry = ENTRY

    def generated(self, **changes):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), {**self.entry, **changes})
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



@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BlockExtensionTrialsTests(ExtensionHelpers, unittest.TestCase):
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
        for changes in ({'trials': 0}, {'trials': True}, {'block': 30}, {'block': 0, 'trials': 6},
                        {'void_on_cast_failure': 'yes'}, {'mode': 'other'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.generated(**changes)


ZERO = {'block': 0, 'trials': 32, 'label_suffix': 'block_extension_unblocked'}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BlockZeroExtensionTests(ExtensionHelpers, unittest.TestCase):
    entry = {**ENTRY, **ZERO}

    def zero(self, expiries, blocked):
        return self.judged(expiries, blocked)

    def test_the_scenario_forces_block_zero_and_judges_unblocked_strikes(self):
        scenario, expectation = self.generated()
        steps = scenario['steps']
        self.assertEqual({step['block'] for step in steps if step['action'] == 'set_combat_avoidance'}, {0})
        self.assertEqual(expectation.model['block'], 0)
        self.assertIn('void, not as a failure', scenario['contract'])

    def test_unblocked_trials_in_the_base_band_are_ok(self):
        self.assertEqual(self.zero([12000] * 32, [False] * 32).status, 'ok')

    def test_a_strike_blocked_anyway_is_void_not_a_failure(self):
        blocked = [True, True] + [False] * 30
        verdict = self.zero([16000, 16000] + [12000] * 30, blocked)
        self.assertEqual((verdict.status, verdict.detail['void']), ('ok', 2))

    def test_an_extension_after_an_unblocked_strike_alerts(self):
        for expiry in (16000, 15000):
            with self.subTest(expiry=expiry):
                self.assertEqual(self.zero([12000] * 5 + [expiry] + [12000] * 26, [False] * 32).status, 'alert')

    def test_too_many_blocked_anyway_is_unmeasured(self):
        self.assertEqual(self.zero([12000] * 32, [True] * 9 + [False] * 23).status, 'unmeasured')


GRANT = {'mode': 'grant', 'spell': 707629, 'name': 'Sunflare Aegis (grant)', 'kind': 'block_extension_trials',
         'variant': 'block_grant_rate', 'label_suffix': 'block_grant_rate',
         'quote': 'Blocking attacks now has a $h% chance to grant you Hammer of Kings for $/1000;712448s1 sec.',
         'aura': 804751, 'shield': 231296, 'strike_spell': 2118233, 'trials': 950, 'parts': 6, 'control_trials': 24,
         'block': 100, 'chance_pct': 30, 'half_width_points': 1.6, 'void_on_cast_failure': True}
ZERO_GRANT = {**GRANT, 'variant': 'block_grant_unblocked', 'label_suffix': 'block_grant_unblocked', 'trials': 48,
              'parts': 1, 'control_trials': 0, 'block': 0, 'chance_pct': None, 'half_width_points': None}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BlockGrantTrialsTests(unittest.TestCase):
    def generated(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def part(self, expectation, grants, control_grants=frozenset(), voids=0, leftover=0):
        model = expectation.model
        values, totals = {}, (0.0, 0.0)
        for arm, trials in model['arms'].items():
            for index, trial in enumerate(trials):
                void = arm == 'treatment' and index < voids
                hit_blocked = bool(model['block']) != void
                totals = (totals[0] + hit_blocked, totals[1] + (not hit_blocked))
                values[trial['blocked']], values[trial['unblocked']] = totals
                values[trial['aura before']] = 1.0 if arm == 'treatment' and voids <= index < voids + leftover else 0.0
                granted = index in (grants if arm == 'treatment' else control_grants)
                values[trial['aura after']] = 1.0 if granted else 0.0
        return values

    def judge(self, expectation, parts):
        runs = []
        for values in parts:
            run = FakeRun(values)
            run.cast_failures = {}
            runs.append(run)
        return kind_pooled_judge('block_extension_trials')(base_verdict(expectation), runs, expectation.model)

    def rate_parts(self, expectation, per_part_grants, **changes):
        return [self.part(expectation, set(range(per_part_grants)), **changes) for _ in range(6)]

    def test_the_rate_scenario_fits_the_step_cap_and_sizes_the_claim(self):
        scenario, expectation = self.generated(GRANT)
        self.assertLessEqual(len(scenario['steps']), 10000)
        self.assertEqual(expectation.model['minimum_judged'], 5444)
        self.assertGreaterEqual(950 * 6, 5444)
        self.assertEqual(expectation.model['parts'], 6)

    def test_a_conformant_rate_is_ok(self):
        _, expectation = self.generated(GRANT)
        self.assertEqual(self.judge(expectation, self.rate_parts(expectation, 285)).status, 'ok')

    def test_a_25_and_a_35_percent_server_alert(self):
        _, expectation = self.generated(GRANT)
        for per_part in (237, 332):
            with self.subTest(per_part=per_part):
                self.assertEqual(self.judge(expectation, self.rate_parts(expectation, per_part)).status, 'alert')

    def test_the_edges_of_the_range_decide(self):
        _, expectation = self.generated(GRANT)
        for per_part, status in ((269, 'alert'), (270, 'ok'), (300, 'ok'), (301, 'alert')):
            with self.subTest(per_part=per_part):
                verdict = self.judge(expectation, self.rate_parts(expectation, per_part))
                self.assertEqual(verdict.status, status, verdict.explanation)

    def test_a_grant_before_the_learn_alerts(self):
        _, expectation = self.generated(GRANT)
        parts = [self.part(expectation, set(range(285)), control_grants={3}) for _ in range(6)]
        self.assertEqual(self.judge(expectation, parts).status, 'alert')

    def test_a_leftover_aura_or_an_unblocked_strike_voids_and_too_few_judged_is_unmeasured(self):
        _, expectation = self.generated(GRANT)
        parts = self.rate_parts(expectation, 285, voids=100)
        self.assertEqual(self.judge(expectation, parts).status, 'unmeasured')
        parts = self.rate_parts(expectation, 285, leftover=100)
        self.assertEqual(self.judge(expectation, parts).status, 'unmeasured')

    def test_the_zero_arm_alerts_on_a_grant_after_an_unblocked_strike(self):
        scenario, expectation = self.generated(ZERO_GRANT)
        self.assertEqual({step['block'] for step in scenario['steps'] if step['action'] == 'set_combat_avoidance'},
                         {0})
        self.assertEqual(self.judge(expectation, [self.part(expectation, set())]).status, 'ok')
        self.assertEqual(self.judge(expectation, [self.part(expectation, {7})]).status, 'alert')

    def test_the_zero_arm_voids_strikes_blocked_anyway_and_needs_24_judged(self):
        _, expectation = self.generated(ZERO_GRANT)
        verdict = self.judge(expectation, [self.part(expectation, {1}, voids=3)])
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(self.judge(expectation, [self.part(expectation, set(), voids=30)]).status, 'unmeasured')

    def test_bad_entries_are_refused(self):
        for changes in ({'block': 30}, {'chance_pct': None}, {'trials': 0}, {'parts': 0}, {'extension_spell': 1}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.generated({**GRANT, **changes})


if __name__ == '__main__':
    unittest.main()
