from pathlib import Path
import sys
import unittest

from behaviours import (BEHAVIOUR_COUNT, BEHAVIOUR_RATIO, behaviour_entries, behaviour_entry, behaviour_scenario,
                        healing_ratio_scenario, healing_ratio_spec, target_count_scenario, target_count_spec)
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_class_file
from tooltip import Records
from values import Expectation, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

CLASS_FILE = load_class_file(19)
RECORDS = Records(dataset(DBC_DIR))
SCARLET_JUDICATOR = 525024
JUSTICE = 712437
FINAL_PRAYER = 705268
DIVINE_FORCE_MAX_RANK = 807805
INTERDICT = 560116
TESTAMENT_OF_FAITH = 801478


def scarlet_judicator_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SCARLET_JUDICATOR)


def justice_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == JUSTICE)


def final_prayer_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == FINAL_PRAYER)


class BehaviourEntryTests(unittest.TestCase):
    def test_scarlet_judicator_entry(self):
        spec = target_count_spec(scarlet_judicator_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'count', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 2)
        self.assertEqual(spec.target_rank, DIVINE_FORCE_MAX_RANK)

    def test_justice_entry(self):
        spec = target_count_spec(justice_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'count', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.target_rank, INTERDICT)

    def test_final_prayer_entry(self):
        spec = healing_ratio_spec(final_prayer_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'ratio', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 2.0)
        self.assertEqual(spec.targets, ((TESTAMENT_OF_FAITH, 'Testament of Faith'),))

    def test_quote_must_be_in_tooltip(self):
        with self.assertRaises(ValueError):
            behaviour_entry(RECORDS, SCARLET_JUDICATOR, 'Scarlet Judicator', 'count', 'not in the tooltip at all', 2)

    def test_unknown_kind_is_rejected(self):
        with self.assertRaises(ValueError):
            behaviour_entry(RECORDS, SCARLET_JUDICATOR, 'Scarlet Judicator', 'ghost', 'strikes', 2)


class BehaviourEntriesLookupTests(unittest.TestCase):
    def test_behaviour_entries_filters_by_spell(self):
        chosen = behaviour_entries(CLASS_FILE, [SCARLET_JUDICATOR])
        self.assertEqual([entry['spell'] for entry in chosen], [SCARLET_JUDICATOR])

    def test_behaviour_entries_rejects_unknown_spell(self):
        with self.assertRaises(ValueError):
            behaviour_entries(CLASS_FILE, [1])

    def test_behaviour_entries_everything_by_default(self):
        self.assertEqual(len(behaviour_entries(CLASS_FILE, None)), 3)


class TargetCountScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_fixtures(self):
        spec = target_count_spec(scarlet_judicator_entry())
        scenario, expectations = target_count_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 3)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_COUNT)
        self.assertTrue(expectation.rule.startswith('prose: "strikes 2 additional enemies'))
        self.assertEqual(len(expectation.model['dummy_labels']), 2)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, justice_entry())
        self.assertEqual(len(run.validate(scenario)['creatures']), 2)
        self.assertEqual(expectations[0].check, BEHAVIOUR_COUNT)

    def test_justice_entry_reads_the_silence_aura_not_spell_damage_count(self):
        spec = target_count_spec(justice_entry())
        self.assertEqual(spec.metric, 'aura')
        scenario, _ = target_count_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura' and step.get('spell') == INTERDICT]
        self.assertEqual(len(measure_steps), 4)
        for step in measure_steps:
            self.assertEqual(step['caster'], 'caster')
            self.assertIn(step['actor'], ('primary', 'extra1'))

    def test_scarlet_judicator_entry_reads_spell_damage_count(self):
        spec = target_count_spec(scarlet_judicator_entry())
        self.assertEqual(spec.metric, 'spell_damage_count')


class HealingRatioScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = healing_ratio_spec(final_prayer_entry())
        scenario, expectations = healing_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        self.assertEqual(expectations[0].check, BEHAVIOUR_RATIO)
        self.assertEqual(expectations[0].model['expected'], 2.0)


class FakeRun:
    def __init__(self, values):
        self.values = values
        self.key = 'fake'
        self.status = 'completed'
        self.message = ''
        self.steps = []
        self.max_step_ms = None
        self.cast_failures = {}


def base_verdict(expectation: Expectation) -> Verdict:
    return Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake-key', expectation.spell_id,
                   expectation.rank_id, expectation.check)


class JudgeTargetCountTests(unittest.TestCase):
    def expectation(self, expected=2):
        model = {'kind': 'count', 'expected': expected, 'quote': 'strikes 2 additional enemies',
                 'dummy_labels': [('b1', 'a1'), ('b2', 'a2')]}
        return Expectation('label', BEHAVIOUR_COUNT, SCARLET_JUDICATOR, DIVINE_FORCE_MAX_RANK, None, '2',
                           'prose: "strikes 2 additional enemies" (525024)', model)

    def test_delta_matches_expected_is_ok(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_delta_below_expected_is_alert(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 0.0, 'b2': 0.0, 'a2': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_delta_one_below_expected_is_ok_within_the_shared_tolerance_floor(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_zero_delta_against_expected_one_is_alert_not_ok(self):
        model = {'kind': 'count', 'expected': 1, 'quote': 'strikes 1 additional nearby target',
                 'dummy_labels': [('b1', 'a1')]}
        expectation = Expectation('label', BEHAVIOUR_COUNT, JUSTICE, INTERDICT, None, '1',
                                  'prose: "strikes 1 additional nearby target" (712437)', model)
        values = {'b1': 0.0, 'a1': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.expected, 1.0)

    def test_already_hit_before_learn_is_unmeasured(self):
        expectation = self.expectation()
        values = {'b1': 1.0, 'a1': 1.0, 'b2': 0.0, 'a2': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'b1': 0.0, 'a1': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('b2', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


class JudgeHealingRatioTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'ratio', 'before_label': 'before', 'after_label': 'after', 'expected': 2.0,
                 'quote': 'Doubles the healing done to you', 'target_name': 'Testament of Faith'}
        return Expectation('label', BEHAVIOUR_RATIO, FINAL_PRAYER, TESTAMENT_OF_FAITH, None, '2.0',
                           'prose: "Doubles the healing done to you" (705268)', model)

    def test_ratio_matches_expected_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 100.0, 'after': 200.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_ratio_mismatch_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 100.0, 'after': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_ratio_half_the_claimed_increase_is_alert_not_floored_to_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 100.0, 'after': 150.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_ratio_exactly_one_against_expected_doubling_is_alert_not_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 800.0, 'after': 800.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 1.0)
        self.assertEqual(verdict.expected, 2.0)

    def test_zero_before_is_unmeasured(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 50.0}), expectation)
        self.assertEqual(verdict.status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
