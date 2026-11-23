from random import Random
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
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

    def test_entries_without_their_read_fields_are_refused(self):
        for entry in ({**CRIT, 'metric': None}, {**CRIT, 'ally_yd': 4}, {**RADIUS, 'ally_yd': 10},
                      {**ENERGY, 'learn': [805249]}, {**ENERGY, 'read': 'chance'}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                self.generated({key: value for key, value in entry.items() if value is not None})


if __name__ == '__main__':
    unittest.main()
