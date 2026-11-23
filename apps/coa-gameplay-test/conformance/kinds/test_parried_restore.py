import unittest
from unittest import mock

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds import parried_restore
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 503659, 'name': 'Dark Riposte (parried swing restore)', 'kind': 'parried_restore',
         'quote': 'Parrying enemy attacks now restores $504475s1% of your missing health and Rage.',
         'percent_spell': 504475, 'heal_spell': 574335, 'energize_spell': 503659, 'health': [400000, 1000000],
         'rage': 200, 'cycles': 6, 'cycle_ms': 1000, 'attacker_swing_ms': 2000, 'attacker_auras': [42716],
         'min_parried': 2}
MAX_RAGE = 1000
PARRIED = {'control': [1, 0, 1, 0, 1, 0], 'treatment': [0, 1, 0, 1, 0, 1]}


def built(entry: dict = ENTRY):
    scenario, expectations = behaviour_scenario(load_fixture_class_file(19), entry)
    return run.validate(scenario), expectations


def seeded_values(model: dict, parried: dict[str, list[int]] = PARRIED, percent: float = 5.0,
                  control_heal: int = 0, foreign: dict[int, int] | None = None, missed: tuple[int, ...] = (),
                  unapplied: bool = False, failed: tuple[int, ...] = (), gap: dict[int, int] | None = None,
                  gap_percent: float | None = None, late_rage: tuple[int, ...] = (), gap_missed: tuple[int, ...] = ()
                  ) -> dict:
    values = {}
    health, maximum = model['health']
    gaps = gap or {}
    for arm in parried_restore.ARMS:
        labels = model['arms'][arm]
        counted = dict.fromkeys(parried_restore.COUNTED_READS, 0)
        treated_arm = arm == 'treatment'
        restore = lambda share, missing: int(missing * share / 100)

        def add(count: int, treated: bool, share: float, swings: int = 0):
            heal = restore(share, maximum - health) if treated else control_heal
            counted['swings'] += count + swings
            counted['parried'] += count
            counted['heals'] += count if treated or control_heal else 0
            counted['healed'] += count * heal
            counted['energizes'] += count if treated else 0
            counted['energized'] += count * (restore(share, MAX_RAGE - model['rage']) if treated else 0)

        values.update({labels['start'][read]: 0 for read in parried_restore.COUNTED_READS})
        for index, (cycle, count) in enumerate(zip(labels['cycles'], parried[arm])):
            number = index + 1
            add(gaps.get(number, 0) if treated_arm else 0, treated_arm,
                percent if gap_percent is None else gap_percent, int(number in gap_missed and treated_arm))
            values.update({cycle[f'base_{read}']: counted[read] for read in parried_restore.COUNTED_READS})
            treated = treated_arm and number not in failed
            heal = restore(percent, maximum - health) if treated else control_heal
            energy = restore(percent, MAX_RAGE - model['rage']) if treated else 0
            shift = (foreign or {}).get(number, 0) if treated_arm else 0
            add(count, treated, percent, int(number in missed and treated_arm))
            late = (restore(percent, MAX_RAGE - model['rage']) * gaps.get(number + 1, 0)
                    if treated_arm and number in late_rage else 0)
            values.update({cycle[read]: counted[read] for read in parried_restore.COUNTED_READS})
            values.update({cycle['set_health']: health, cycle['set_max_health']: maximum,
                           cycle['set_rage']: model['rage'], cycle['set_max_rage']: MAX_RAGE,
                           cycle['health']: health + (0 if unapplied else count * heal) - shift,
                           cycle['max_health']: maximum,
                           cycle['rage']: model['rage'] + count * energy + int(shift > 0) + late})
        add(gaps.get(len(labels['cycles']) + 1, 0) if treated_arm else 0, treated_arm, percent)
        values.update({labels['end'][read]: counted[read] for read in parried_restore.COUNTED_READS})
    return values


def window_attributed(model: dict, values: dict, cycle: int) -> dict:
    labels = model['arms']['treatment']['cycles'][cycle - 1]
    previous = model['arms']['treatment']['cycles'][cycle - 2]
    return {**values, **{labels[f'base_{read}']: values[previous[read]] for read in parried_restore.COUNTED_READS}}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ParriedRestoreTests(unittest.TestCase):
    def statuses(self, values: dict, expectations) -> list[str]:
        return [judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status
                for expectation in expectations]

    def test_each_cycle_sets_the_fixture_then_reads_the_missing_values_before_its_swing(self):
        scenario, expectations = built()
        steps = scenario['steps']
        self.assertEqual([expectation.label for expectation in expectations],
                         ['503659 behaviour_metric_delta parried_health', '503659 behaviour_metric_delta parried_rage'])
        self.assertEqual(expectations[0].model['percent'], 5)
        unlearn = steps.index({'action': 'unlearn', 'actor': 'caster', 'spell': 503659})
        learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': 503659})
        labels = [step.get('label') for step in steps]
        model = expectations[0].model
        self.assertLess(unlearn, labels.index(model['arms']['control']['cycles'][0]['set_health']))
        self.assertLess(labels.index(model['arms']['control']['cycles'][-1]['rage']), learn)
        self.assertLess(learn, labels.index(model['arms']['treatment']['cycles'][0]['set_health']))
        for arm in parried_restore.ARMS:
            for cycle in model['arms'][arm]['cycles']:
                start = labels.index(cycle['set_health'])
                self.assertEqual([step['action'] for step in steps[start - 3:start]],
                                 ['set_combat_avoidance', 'set_health', 'set_power'])
                self.assertEqual(steps[start - 3]['parry'], 100)
                self.assertEqual(steps[start - 3]['dodge'], 0)
                base = labels.index(cycle['base_swings'])
                self.assertLess(labels.index(cycle['set_max_rage']), base)
                self.assertEqual([step['action'] for step in steps[base + 6:base + 7]], ['wait'])
                self.assertLess(base + 6, labels.index(cycle['swings']))
            self.assertLess(labels.index(model['arms'][arm]['cycles'][-1]['rage']),
                            labels.index(model['arms'][arm]['end']['swings']))
        self.assertEqual(scenario['creatures'][0]['reaction'], 2)

    def test_the_stated_restore_passes_both_labels(self):
        _, expectations = built()
        self.assertEqual(self.statuses(seeded_values(expectations[0].model), expectations), ['ok', 'ok'])

    def test_a_restore_ten_percent_off_alerts(self):
        _, expectations = built()
        for percent in (4.5, 5.5):
            with self.subTest(percent=percent):
                values = seeded_values(expectations[0].model, percent=percent)
                self.assertEqual(self.statuses(values, expectations), ['alert', 'alert'])

    def test_mutant_a_stated_percent_off_its_dbc_value_alerts(self):
        _, expectations = built()
        values = seeded_values(expectations[0].model)
        for percent in (4, 6):
            with self.subTest(percent=percent), mock.patch.object(parried_restore, 'stated_percent',
                                                                  return_value=percent):
                _, mutated = built()
                self.assertEqual(self.statuses(values, mutated), ['alert', 'alert'])

    def test_a_restore_without_the_talent_alerts(self):
        _, expectations = built()
        values = seeded_values(expectations[0].model, control_heal=30000)
        self.assertEqual(self.statuses(values, expectations)[0], 'alert')

    def test_a_missed_swing_is_tolerated_and_a_foreign_change_without_a_swing_leaves_its_cycle_out(self):
        _, expectations = built()
        model = expectations[0].model
        self.assertEqual(self.statuses(seeded_values(model, missed=(1,)), expectations), ['ok', 'ok'])
        found = judge_behaviour(base_verdict(expectations[0]),
                                FakeRun(seeded_values(model, foreign={3: 18})), expectations[0])
        self.assertEqual(found.status, 'ok')
        self.assertIn('(1 with a foreign health change left out, holding 0 parried swings)', found.explanation)
        self.assertEqual(found.measured, 90000)
        wrong = seeded_values(model, percent=5.5, foreign={3: 18})
        self.assertEqual(self.statuses(wrong, expectations), ['alert', 'alert'])

    def test_a_foreign_change_in_a_cycle_that_parried_is_reported_and_not_ok(self):
        _, expectations = built()
        model = expectations[0].model
        found = judge_behaviour(base_verdict(expectations[0]),
                                FakeRun(seeded_values(model, foreign={2: 18})), expectations[0])
        self.assertEqual(found.status, 'alert')
        self.assertIn('excluded treatment cycles [2] held 1 parried swings', found.explanation)
        self.assertEqual(self.statuses(seeded_values(model, foreign={2: 18}), expectations), ['alert', 'alert'])

    def test_mutant_no_restore_on_a_parried_swing_in_a_foreign_change_cycle_alerts(self):
        _, expectations = built()
        values = seeded_values(expectations[0].model, foreign={2: 18}, failed=(2,))
        self.assertEqual(self.statuses(values, expectations), ['alert', 'alert'])

    def test_a_second_swing_too_few_parries_or_an_unapplied_heal_leave_it_unmeasured(self):
        _, expectations = built()
        model = expectations[0].model
        cases = {'second swing': seeded_values(model, {**PARRIED, 'treatment': [0, 2, 0, 1, 0, 0]}),
                 'too few': seeded_values(model, {**PARRIED, 'treatment': [0, 1, 0, 0, 0, 0]}),
                 'foreign on all but one': seeded_values(model, foreign={2: 18, 4: 18})}
        for name, values in cases.items():
            with self.subTest(case=name):
                self.assertEqual(self.statuses(values, expectations)[0], 'unmeasured')
        unapplied = seeded_values(model, unapplied=True)
        self.assertEqual(self.statuses(unapplied, expectations)[0], 'unmeasured')
        hidden = judge_behaviour(base_verdict(expectations[0]),
                                 FakeRun(cases['foreign on all but one']), expectations[0])
        self.assertIn('excluded treatment cycles [2, 4] held 2 parried swings', hidden.explanation)

    def test_a_parry_in_the_read_gap_of_run_20261116_135038_is_reported_and_judged_on_its_events(self):
        _, expectations = built()
        model = expectations[0].model
        parried = {**PARRIED, 'treatment': [0, 1, 0, 0, 0, 1]}
        values = seeded_values(model, parried, gap={4: 1}, late_rage=(3,))
        found = [judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                 for expectation in expectations]
        self.assertEqual([verdict.status for verdict in found], ['ok', 'ok'])
        for verdict in found:
            self.assertIn("1 treatment swings outside the judged windows (the read and set gaps ['before cycle 4']), "
                          "1 of them parried, 1 of those with events numbering them", verdict.explanation)
        old_view = window_attributed(model, values, 4)
        self.assertEqual(self.statuses(old_view, expectations), ['alert', 'alert'])
        self.assertIn('excluded treatment cycles [4] held 1 parried swings',
                      judge_behaviour(base_verdict(expectations[0]), FakeRun(old_view), expectations[0]).explanation)

    def test_a_gap_swing_without_a_parry_and_a_trailing_parry_are_reported(self):
        _, expectations = built()
        model = expectations[0].model
        values = seeded_values(model, {**PARRIED, 'treatment': [0, 1, 0, 1, 0, 0]}, gap_missed=(3,), gap={7: 1})
        found = judge_behaviour(base_verdict(expectations[0]), FakeRun(values), expectations[0])
        self.assertEqual(found.status, 'ok')
        self.assertIn("2 treatment swings outside the judged windows (the read and set gaps ['before cycle 3', "
                      "'after cycle 6']), 1 of them parried, 1 of those", found.explanation)

    def test_a_gap_parry_whose_gain_cannot_be_judged_is_not_ok(self):
        _, expectations = built()
        model = expectations[0].model
        parried = {**PARRIED, 'treatment': [0, 1, 0, 0, 0, 1]}
        for share in (0, 4.5, 5.5):
            with self.subTest(share=share):
                found = [judge_behaviour(base_verdict(expectation),
                                         FakeRun(seeded_values(model, parried, gap={4: 1}, gap_percent=share)),
                                         expectation) for expectation in expectations]
                self.assertEqual([verdict.status for verdict in found], ['alert', 'alert'])
                self.assertIn("treatment read and set gaps ['before cycle 4'] held 1 parried swings",
                              found[0].explanation)

    def test_mutant_a_stated_percent_off_its_dbc_value_alerts_on_a_gap_parry(self):
        _, expectations = built()
        values = seeded_values(expectations[0].model, {**PARRIED, 'treatment': [0, 1, 0, 0, 0, 1]}, gap={4: 1})
        for percent in (4, 6):
            with self.subTest(percent=percent), mock.patch.object(parried_restore, 'stated_percent',
                                                                  return_value=percent):
                _, mutated = built()
                found = judge_behaviour(base_verdict(mutated[0]), FakeRun(values), mutated[0])
                self.assertEqual(found.status, 'alert')
                self.assertIn("treatment read and set gaps ['before cycle 4']", found.explanation)

    def test_a_gap_swing_and_a_window_swing_in_one_cycle_leave_it_unmeasured(self):
        _, expectations = built()
        values = seeded_values(expectations[0].model, gap_missed=(2,))
        self.assertEqual(self.statuses(values, expectations), ['unmeasured', 'unmeasured'])

    def test_a_control_event_in_a_gap_alerts(self):
        _, expectations = built()
        model = expectations[0].model
        values = seeded_values(model)
        control = model['arms']['control']
        later = [label for cycle in control['cycles'][1:] for label in (cycle['base_heals'], cycle['heals'])]
        for label in later + [control['end']['heals']]:
            values[label] += 1
        found = judge_behaviour(base_verdict(expectations[0]), FakeRun(values), expectations[0])
        self.assertEqual(found.status, 'alert')
        self.assertIn('control: 1 events without 503659', found.explanation)

    def test_a_swing_split_across_the_baseline_reads_of_run_20261116_140210_is_judged_in_its_cycle(self):
        _, expectations = built()
        model = expectations[0].model
        values = seeded_values(model)
        cycle = model['arms']['treatment']['cycles'][3]
        for read in ('healed', 'energizes', 'energized'):
            values[cycle[f'base_{read}']] = values[cycle[read]]
        found = [judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                 for expectation in expectations]
        self.assertEqual([verdict.status for verdict in found], ['ok', 'ok'])
        self.assertIn("treatment swings split across a read sequence and judged in their cycle ['4 baseline']",
                      found[0].explanation)
        self.assertEqual(found[0].measured, 90000)

    def test_a_swing_split_across_the_end_reads_is_judged_in_its_cycle(self):
        _, expectations = built()
        model = expectations[0].model
        values = seeded_values(model)
        cycle = model['arms']['treatment']['cycles'][3]
        for read in ('swings', 'parried', 'heals'):
            values[cycle[read]] = values[cycle[f'base_{read}']]
        found = [judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                 for expectation in expectations]
        self.assertEqual([verdict.status for verdict in found], ['ok', 'ok'])
        self.assertIn("['4 end']", found[1].explanation)

    def test_a_split_swing_off_its_restore_or_without_the_mending_alerts(self):
        _, expectations = built()
        model = expectations[0].model
        cycle = model['arms']['treatment']['cycles'][3]

        def split(values: dict) -> dict:
            for read in ('healed', 'energizes', 'energized'):
                values[cycle[f'base_{read}']] = values[cycle[read]]
            return values

        self.assertEqual(self.statuses(split(seeded_values(model, percent=5.5)), expectations), ['alert', 'alert'])
        unmended = lambda cycles: [{**reading, 'torn': []} for reading in cycles]
        with mock.patch.object(parried_restore, 'mended', side_effect=unmended):
            self.assertEqual(self.statuses(split(seeded_values(model)), expectations), ['alert', 'alert'])

    def test_mutant_a_split_parry_whose_baseline_totals_hold_no_restore_alerts(self):
        _, expectations = built()
        model = expectations[0].model
        treatment = model['arms']['treatment']
        sequence = [(label, read) for cycle in treatment['cycles']
                    for label, read in [(cycle[f'base_{read}'], read) for read in parried_restore.COUNTED_READS]
                    + [(cycle[read], read) for read in parried_restore.COUNTED_READS]]
        sequence += [(treatment['end'][read], read) for read in parried_restore.COUNTED_READS]
        cycle = treatment['cycles'][3]
        cases = {'energize counted in the baseline': {'energizes': cycle['base_energizes'],
                                                      'heals': cycle['heals']},
                 'both events counted in the baseline': {'energizes': cycle['base_energizes'],
                                                         'heals': cycle['base_heals']}}
        for name, events in cases.items():
            with self.subTest(case=name):
                values = seeded_values(model, failed=(4,))
                for event, first in events.items():
                    for label, read in sequence[sequence.index((first, event)):]:
                        if read == event:
                            values[label] += 1
                self.assertEqual(values[cycle['health']], values[cycle['set_health']])
                self.assertEqual(values[cycle['base_healed']], values[cycle['healed']])
                found = [judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                         for expectation in expectations]
                self.assertEqual([verdict.status for verdict in found], ['alert', 'alert'])
                for verdict in found:
                    self.assertIn("judged in their cycle ['4 baseline']", verdict.explanation)
                    self.assertIn('treatment cycles [4] restored off', verdict.explanation)

    def test_mutant_an_end_split_parry_whose_totals_hold_no_restore_alerts(self):
        _, expectations = built()
        model = expectations[0].model
        treatment = model['arms']['treatment']
        sequence = [(label, read) for cycle in treatment['cycles']
                    for label, read in [(cycle[f'base_{read}'], read) for read in parried_restore.COUNTED_READS]
                    + [(cycle[read], read) for read in parried_restore.COUNTED_READS]]
        sequence += [(treatment['end'][read], read) for read in parried_restore.COUNTED_READS]
        cycle, following = treatment['cycles'][3], treatment['cycles'][4]
        cases = {'energize counted in the cycle': {'energizes': cycle['energizes'],
                                                   'heals': following['base_heals']},
                 'both events counted in the cycle': {'energizes': cycle['energizes'], 'heals': cycle['heals']}}
        for name, events in cases.items():
            with self.subTest(case=name):
                values = seeded_values(model, failed=(4,))
                for event, first in events.items():
                    for label, read in sequence[sequence.index((first, event)):]:
                        if read == event:
                            values[label] += 1
                for read in ('swings', 'parried'):
                    values[cycle[read]] = values[cycle[f'base_{read}']]
                self.assertEqual(values[cycle['health']], values[cycle['set_health']])
                self.assertEqual(values[cycle['rage']], values[cycle['set_rage']])
                self.assertEqual(values[following['base_healed']], values[cycle['base_healed']])
                self.assertEqual(values[following['base_energized']], values[cycle['base_energized']])
                found = [judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                         for expectation in expectations]
                self.assertEqual([verdict.status for verdict in found], ['alert', 'alert'])
                for verdict in found:
                    self.assertIn("judged in their cycle ['4 end']", verdict.explanation)
                    self.assertIn('treatment cycles [4] restored off', verdict.explanation)

    def test_a_missing_read_is_not_a_pass(self):
        _, expectations = built()
        values = seeded_values(expectations[0].model)
        del values[expectations[0].model['arms']['treatment']['cycles'][1]['healed']]
        self.assertNotEqual(self.statuses(values, expectations)[0], 'ok')

    def test_cycles_longer_than_a_swing_or_no_missing_health_are_refused(self):
        for change in ({'cycle_ms': 2000}, {'health': [1000000, 1000000]}, {'min_parried': 7}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                built({**ENTRY, **change})

    def test_the_restore_is_an_event_read_that_coverage_classes_as_behaviour_without_an_edit(self):
        from coverage import BEHAVIOUR, BY_METRIC, EVENT, EVIDENCE, METRIC_EVIDENCE, metric_evidence, verdict_evidence
        _, expectations = built()
        values = seeded_values(expectations[0].model)
        found = judge_behaviour(base_verdict(expectations[0]), FakeRun(values), expectations[0])
        self.assertEqual(EVIDENCE[found.check], BY_METRIC)
        self.assertNotIn(parried_restore.METRIC, METRIC_EVIDENCE)
        self.assertEqual(found.detail['metric'], parried_restore.METRIC)
        self.assertEqual(metric_evidence()[parried_restore.METRIC], EVENT)
        self.assertEqual(verdict_evidence(found, ENTRY['quote'], {}), BEHAVIOUR)

    def test_a_restore_without_its_kind_evidence_row_is_refused(self):
        import coverage
        _, expectations = built()
        found = judge_behaviour(base_verdict(expectations[0]),
                                FakeRun(seeded_values(expectations[0].model)), expectations[0])
        without = {metric: kind for metric, kind in coverage.metric_evidence().items()
                   if metric != parried_restore.METRIC}
        with mock.patch.object(coverage, 'metric_evidence', return_value=without), \
                self.assertRaises(coverage.EvidenceError):
            coverage.verdict_evidence(found, ENTRY['quote'], {})


if __name__ == '__main__':
    unittest.main()
