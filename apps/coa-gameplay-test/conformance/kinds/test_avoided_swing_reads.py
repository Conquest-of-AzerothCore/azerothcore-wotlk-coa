from random import Random
import unittest

from behaviours import LEARNED_CONTRAST, behaviour_scenario
from compare import judge_behaviour
from coverage import BEHAVIOUR, DATA, verdict_evidence
from kinds.avoided_swing_reads import avoided_swing_reads_spec, learned_contrast
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

STRIKERS = {'striker_entry': 36, 'strikers': 10, 'striker_auras': [42716, 62531, 2116852], 'swing_ms': 500,
            'control_windows': 10}
RADIUS = {'spell': 300476, 'kind': 'avoided_swing_reads', 'name': 'Betrayer (party radius)',
          'label_suffix': 'party_radius', 'quote': 'enrages your party and raid members within $520256a1 yds',
          'read': 'aura_edge', 'observe_spell': 520256, **STRIKERS, 'windows': 20}
CRIT = {'spell': 300476, 'kind': 'avoided_swing_reads', 'name': 'Betrayer (party crit)', 'label_suffix': 'party_crit',
        'quote': 'increasing their critical strike chance by $520256s1%', 'read': 'stat_delta',
        'observe_spell': 520256, 'metric': 'melee_crit_chance', 'ally_yd': 10, **STRIKERS, 'windows': 20}
DURATION = {'spell': 300476, 'kind': 'avoided_swing_reads', 'name': 'Betrayer (party crit duration)',
            'label_suffix': 'party_crit_duration', 'quote': 'for $520256d.', 'read': 'duration_max',
            'observe_spell': 520256, 'ally_yd': 10, **STRIKERS, 'windows': 30}
BASELINE = {**CRIT, 'metric': 'melee_crit_chance_refreshed', 'baseline_read': True}
EXPIRY = {**DURATION, 'read': 'expiry_edge', 'windows': 20}
CRIT_CLAUSE = 'increasing their critical strike chance by $520256s1%'
ENERGY = {'spell': 805249, 'kind': 'avoided_swing_reads', 'name': 'Illidari Training (energy per dodge)',
          'label_suffix': 'energy_per_dodge', 'quote': 'Dodging an attack now generates $521210s1 Energy.',
          'read': 'per_event', 'observe_spell': 521210, **STRIKERS, 'windows': 60}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedSwingReadsTests(unittest.TestCase):
    def generated(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def values(self, expectation, control: dict, treatment: dict, misplaced: float = 0.0) -> dict:
        model = expectation.model
        values = {label: yd + misplaced for (ally, label), yd in zip(model['distances'].items(),
                                                                     model['offsets'].values())}
        values.update({label: 17.0 for label in model['quiet_distances']})
        for arm, reads in (('control', control), ('treatment', treatment)):
            values.update({model['reads'][arm][name]: value for name, value in reads.items()})
        return values

    def judge(self, expectation, values, failures=None):
        fake = FakeRun(values)
        fake.cast_failures = failures or {}
        return judge_behaviour(base_verdict(expectation), fake, expectation)

    def remaining_reads(self, duration_ms: float, windows: int, seed: int = 300476) -> list[float]:
        rng = Random(seed)
        applications = sorted(rng.uniform(0, windows * 500) for _ in range(windows * 4))
        reads = []
        for window in range(1, windows + 1):
            now = window * 500 + rng.uniform(0, 100)
            last = max((time for time in applications if time <= now), default=None)
            reads.append(0.0 if last is None else max(0.0, duration_ms - (now - last)))
        return reads

    def test_the_scenario_validates_learns_after_the_control_reads_and_places_the_allies(self):
        scenario, expectation = self.generated(RADIUS)
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        learn = next(index for index, step in enumerate(scenario['steps'])
                     if step['action'] == 'learn' and step['spell'] == 300476)
        self.assertLess(labels.index(expectation.model['reads']['control']['ally']), learn)
        self.assertLess(learn, labels.index(expectation.model['reads']['treatment']['ally']))
        self.assertEqual(expectation.model['offsets'], {'ally': 19.5, 'ally2': 20.5})
        self.assertEqual([player['id'] for player in scenario['players'][1:]], ['ally', 'ally2'])
        self.assertEqual(len(scenario['creatures']), 10)

    def test_an_ally_inside_the_radius_holds_the_aura_and_one_outside_does_not(self):
        _, expectation = self.generated(RADIUS)
        values = self.values(expectation, {'ally': 0, 'ally2': 0}, {'ally': 1, 'ally2': 0})
        self.assertEqual(self.judge(expectation, values).status, 'ok')

    def test_a_mutant_wider_radius_reaching_the_outer_ally_alerts(self):
        _, expectation = self.generated(RADIUS)
        values = self.values(expectation, {'ally': 0, 'ally2': 0}, {'ally': 1, 'ally2': 1})
        self.assertEqual(self.judge(expectation, values).status, 'alert')

    def test_a_mutant_narrower_radius_missing_the_inner_ally_alerts(self):
        _, expectation = self.generated(RADIUS)
        values = self.values(expectation, {'ally': 0, 'ally2': 0}, {'ally': 0, 'ally2': 0})
        self.assertEqual(self.judge(expectation, values).status, 'alert')

    def test_an_aura_held_before_the_learn_alerts(self):
        _, expectation = self.generated(RADIUS)
        values = self.values(expectation, {'ally': 1, 'ally2': 0}, {'ally': 1, 'ally2': 0})
        self.assertEqual(self.judge(expectation, values).status, 'alert')

    def test_a_misplaced_ally_or_a_missing_read_is_void(self):
        _, expectation = self.generated(RADIUS)
        values = self.values(expectation, {'ally': 0, 'ally2': 0}, {'ally': 1, 'ally2': 0}, misplaced=0.2)
        self.assertEqual(self.judge(expectation, values).status, 'unmeasured')
        values = self.values(expectation, {'ally': 0, 'ally2': 0}, {'ally': 1, 'ally2': 0})
        values.pop(expectation.model['reads']['treatment']['ally2'])
        self.assertEqual(self.judge(expectation, values).status, 'unmeasured')

    def test_the_ally_crit_gain_at_the_tooltip_value_is_ok_and_a_mutant_half_gain_alerts(self):
        _, expectation = self.generated(CRIT)
        self.assertEqual(expectation.model['band'], [1.99, 2.01])
        ok = self.values(expectation, {'ally': 0, 'stat': 5.25}, {'ally': 1, 'stat': 7.25})
        self.assertEqual(self.judge(expectation, ok).status, 'ok')
        mutant = self.values(expectation, {'ally': 0, 'stat': 5.25}, {'ally': 1, 'stat': 6.25})
        self.assertEqual(self.judge(expectation, mutant).status, 'alert')

    def test_a_crit_read_without_the_aura_on_the_ally_alerts(self):
        _, expectation = self.generated(CRIT)
        values = self.values(expectation, {'ally': 0, 'stat': 5.25}, {'ally': 0, 'stat': 7.25})
        self.assertEqual(self.judge(expectation, values).status, 'alert')

    def duration_verdict(self, duration_ms: float):
        _, expectation = self.generated(DURATION)
        values = self.values(expectation, {'ally': 0}, {'ally': 1})
        values.update(zip(expectation.model['remaining'], self.remaining_reads(duration_ms, DURATION['windows'])))
        return self.judge(expectation, values)

    def test_the_largest_remaining_duration_of_a_10_s_aura_is_ok(self):
        verdict = self.duration_verdict(10000)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_mutant_9_s_and_11_s_durations_alert(self):
        for duration in (9000, 11000):
            with self.subTest(duration=duration):
                self.assertEqual(self.duration_verdict(duration).status, 'alert')

    def test_the_energy_per_dodge_at_the_tooltip_value_is_ok_and_a_mutant_amount_alerts(self):
        _, expectation = self.generated(ENERGY)
        ok = self.values(expectation, {'events': 0, 'total': 0}, {'events': 40, 'total': 120})
        self.assertEqual(self.judge(expectation, ok).status, 'ok')
        mutant = self.values(expectation, {'events': 0, 'total': 0}, {'events': 40, 'total': 80})
        self.assertEqual(self.judge(expectation, mutant).status, 'alert')

    def test_too_few_energize_events_are_void_and_one_before_the_learn_alerts(self):
        _, expectation = self.generated(ENERGY)
        sparse = self.values(expectation, {'events': 0, 'total': 0}, {'events': 5, 'total': 15})
        self.assertEqual(self.judge(expectation, sparse).status, 'unmeasured')
        early = self.values(expectation, {'events': 1, 'total': 3}, {'events': 40, 'total': 120})
        self.assertEqual(self.judge(expectation, early).status, 'alert')

    def test_a_refused_cast_is_void(self):
        _, expectation = self.generated(ENERGY)
        values = self.values(expectation, {'events': 0, 'total': 0}, {'events': 40, 'total': 120})
        self.assertEqual(self.judge(expectation, values, failures={805249: [134]}).status, 'unmeasured')
        self.assertEqual(self.judge(expectation, values, failures={805249: [0]}).status, 'ok')

    def baseline_values(self, expectation, baseline: float, control: float, treatment: float) -> dict:
        values = self.values(expectation, {'ally': 0, 'stat': control}, {'ally': 1, 'stat': treatment})
        values[expectation.model['baseline']] = baseline
        return values

    def test_a_baseline_read_stamps_the_learned_contrast_from_the_step_list(self):
        scenario, expectation = self.generated(BASELINE)
        run.validate(scenario)
        self.assertEqual(expectation.model['contrast'], LEARNED_CONTRAST)
        labels = [step.get('label') for step in scenario['steps']]
        learn = next(index for index, step in enumerate(scenario['steps'])
                     if step['action'] == 'learn' and step['spell'] == 300476)
        self.assertLess(labels.index(expectation.model['baseline']),
                        labels.index(expectation.model['reads']['control']['stat']))
        self.assertLess(labels.index(expectation.model['reads']['control']['stat']), learn)
        _, plain = self.generated(CRIT)
        self.assertNotIn('contrast', plain.model)
        self.assertNotIn('baseline', plain.model)

    def test_a_mutant_step_list_learning_before_the_control_read_or_without_dodges_gets_no_stamp(self):
        scenario, expectation = self.generated(BASELINE)
        spec = avoided_swing_reads_spec(BASELINE)
        reads = (expectation.model['baseline'], expectation.model['reads']['control']['stat'],
                 expectation.model['reads']['treatment']['stat'])
        self.assertEqual(learned_contrast(spec, scenario['steps'], *reads), LEARNED_CONTRAST)
        steps = scenario['steps']
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 300476)
        control = [step.get('label') for step in steps].index(reads[1])
        early = steps[:control] + [steps[learn]] + steps[control:learn] + steps[learn + 1:]
        self.assertIsNone(learned_contrast(spec, early, *reads))
        undodged = [step for step in steps if step['action'] != 'set_combat_avoidance']
        self.assertIsNone(learned_contrast(spec, undodged, *reads))

    def test_a_still_control_arm_and_the_tooltip_gain_is_ok_and_reads_as_behaviour(self):
        _, expectation = self.generated(BASELINE)
        verdict = self.judge(expectation, self.baseline_values(expectation, 5.25, 5.25, 7.25))
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertEqual(verdict.detail['contrast'], LEARNED_CONTRAST)
        self.assertEqual(verdict_evidence(verdict, CRIT_CLAUSE, {}), BEHAVIOUR)
        _, plain = self.generated({**CRIT, 'metric': 'melee_crit_chance_refreshed'})
        unstamped = self.judge(plain, self.values(plain, {'ally': 0, 'stat': 5.25}, {'ally': 1, 'stat': 7.25}))
        self.assertEqual(unstamped.status, 'ok')
        self.assertEqual(verdict_evidence(unstamped, CRIT_CLAUSE, {}), DATA)

    def test_a_mutant_control_arm_drift_alerts(self):
        _, expectation = self.generated(BASELINE)
        verdict = self.judge(expectation, self.baseline_values(expectation, 5.25, 7.25, 9.25))
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 2.0)
        self.assertEqual(self.judge(expectation, self.baseline_values(expectation, 5.25, 5.255, 7.255)).status, 'ok')

    def expiry_values(self, expectation, held, gone, counts=(40, 42, 42), dodge_ms=500_000.0, held_ms=9300.0,
                      gone_ms=10300.0):
        values = self.values(expectation, {'ally': 0}, {'held': held, 'gone': gone})
        values.update(zip(expectation.model['dodge_counts'].values(), counts))
        expiry = expectation.model['expiry']
        offsets = {'last dodge read': 400.0, 'held before': held_ms, 'held after': held_ms,
                   'gone before': gone_ms, 'gone after': gone_ms}
        values[expiry['last_dodge']] = dodge_ms
        values.update({label: dodge_ms + offsets[moment] for moment, label in expiry['stamps'].items()})
        return values

    def simulated_expiry(self, expectation, duration_ms: float, rng: Random) -> dict:
        server_dodge = 500_000.0 + rng.uniform(0, 1000)
        lag = rng.uniform(0, 100)
        relocation = server_dodge + rng.uniform(0, 600)
        held_at = relocation + 9150 + rng.uniform(0, 20)
        gone_at = relocation + 10150 + rng.uniform(0, 20)
        values = self.expiry_values(expectation, int(held_at - server_dodge < duration_ms),
                                    int(gone_at - server_dodge < duration_ms), dodge_ms=server_dodge + lag,
                                    held_ms=held_at - server_dodge - lag, gone_ms=gone_at - server_dodge - lag)
        values[expectation.model['expiry']['lag_remaining']] = duration_ms - (relocation + 200 - server_dodge)
        return values

    def test_seeded_expiry_runs_keep_a_10_s_aura_and_alert_9_s_and_11_s_mutants(self):
        _, expectation = self.generated(EXPIRY)
        rng = Random(300476)
        for duration, status in ((10000, 'ok'), (9000, 'alert'), (11000, 'alert')):
            for trial in range(200):
                with self.subTest(duration=duration, trial=trial):
                    verdict = self.judge(expectation, self.simulated_expiry(expectation, duration, rng))
                    self.assertEqual(verdict.status, status, verdict.explanation)
                    if status == 'ok':
                        self.assertTrue(9000 <= verdict.low < 10000 <= verdict.high < 11000, verdict)

    def test_an_expiry_read_outside_its_window_after_the_last_dodge_is_void(self):
        _, expectation = self.generated(EXPIRY)
        for held_ms, gone_ms in ((8999, 10300), (9900, 10300), (9300, 9999), (9300, 10900)):
            with self.subTest(held_ms=held_ms, gone_ms=gone_ms):
                verdict = self.judge(expectation, self.expiry_values(expectation, 1, 0, held_ms=held_ms,
                                                                     gone_ms=gone_ms))
                self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)

    def test_the_expiry_edge_reads_held_before_and_gone_after_the_duration(self):
        scenario, expectation = self.generated(EXPIRY)
        run.validate(scenario)
        self.assertEqual(expectation.model['band'], [9000, 11000])
        self.assertEqual(expectation.model['metric'], 'aura')
        waits = {step['label']: step['ms'] for step in scenario['steps']
                 if step['action'] == 'wait' and step.get('label', '').startswith('expiry')}
        self.assertEqual(waits, {'expiry held': 8950, 'expiry gone': 1000})
        metrics = [step.get('metric') for step in scenario['steps']]
        self.assertEqual(metrics.count('melee_attack_taken_last_ms'), 1)
        self.assertEqual(metrics.count('game_time_ms'), 5)
        verdict = self.judge(expectation, self.expiry_values(expectation, 1, 0))
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_mutant_shorter_and_longer_durations_alert_at_the_edge(self):
        _, expectation = self.generated(EXPIRY)
        for held, gone in ((0, 0), (1, 1)):
            with self.subTest(held=held, gone=gone):
                self.assertEqual(self.judge(expectation, self.expiry_values(expectation, held, gone)).status, 'alert')

    def test_an_expiry_without_a_dodge_in_the_last_window_or_with_a_later_dodge_is_void(self):
        _, expectation = self.generated(EXPIRY)
        for counts in ((42, 42, 42), (40, 42, 43)):
            with self.subTest(counts=counts):
                verdict = self.judge(expectation, self.expiry_values(expectation, 1, 0, counts))
                self.assertEqual(verdict.status, 'unmeasured')

    def test_an_expiry_aura_held_before_the_learn_alerts(self):
        _, expectation = self.generated(EXPIRY)
        values = self.expiry_values(expectation, 1, 0)
        values[expectation.model['reads']['control']['ally']] = 1
        self.assertEqual(self.judge(expectation, values).status, 'alert')

    def test_entries_without_their_read_fields_are_refused(self):
        for entry in ({**CRIT, 'metric': None}, {**CRIT, 'ally_yd': 4}, {**RADIUS, 'ally_yd': 10},
                      {**ENERGY, 'learn': [805249]}, {**ENERGY, 'read': 'chance'},
                      {**RADIUS, 'baseline_read': True}, {**EXPIRY, 'swing_ms': 950}, {**EXPIRY, 'swing_ms': 800}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                self.generated({key: value for key, value in entry.items() if value is not None})


if __name__ == '__main__':
    unittest.main()
