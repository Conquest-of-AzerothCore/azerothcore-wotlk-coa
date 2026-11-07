from pathlib import Path
import sys
import unittest

from behaviours import (BEHAVIOUR_COUNT, BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_RATIO, BEHAVIOUR_TRIGGER,
                        aura_spread_scenario, aura_spread_spec, behaviour_entries, behaviour_entry,
                        behaviour_scenario, healing_ratio_scenario, healing_ratio_spec, metric_delta_scenario,
                        metric_delta_spec, shield_break_trigger_scenario, shield_break_trigger_spec,
                        target_count_scenario, target_count_spec)
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
HOLY_TEMPEST = 301339
CONDEMN_RANK = 567539
RIGHTEOUS_TEMPEST_RANK = 807274
ARMOR_OF_FAITH = 804930
STAFFGUARD_SHIELD = 706583
ARMOR_OF_FAITH_DAMAGE = 801546
TYRS_GUARD = 560649
SPIRITUAL_ABDICATOR = 803219
TESTAMENT_OF_HOPE = 1397742
TESTAMENT_OF_HOPE_COPY_ENTRY = 50250
TESTAMENT_OF_HOPE_AURA = 704409


def scarlet_judicator_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SCARLET_JUDICATOR)


def justice_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == JUSTICE)


def final_prayer_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == FINAL_PRAYER)


def holy_tempest_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == HOLY_TEMPEST)


def armor_of_faith_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == ARMOR_OF_FAITH)


def tyrs_guard_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TYRS_GUARD)


def spiritual_abdicator_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SPIRITUAL_ABDICATOR)


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

    def test_holy_tempest_entry(self):
        spec = aura_spread_spec(holy_tempest_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'count', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.seed_spell, CONDEMN_RANK)
        self.assertEqual(spec.aura_spell, CONDEMN_RANK)
        self.assertEqual(spec.target_rank, RIGHTEOUS_TEMPEST_RANK)

    def test_armor_of_faith_entry(self):
        spec = shield_break_trigger_spec(armor_of_faith_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'trigger', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.shield_aura, STAFFGUARD_SHIELD)
        self.assertEqual(spec.trigger_spell, ARMOR_OF_FAITH_DAMAGE)

    def test_quote_must_be_in_tooltip(self):
        with self.assertRaises(ValueError):
            behaviour_entry(RECORDS, SCARLET_JUDICATOR, 'Scarlet Judicator', 'count', 'not in the tooltip at all', 2)

    def test_shield_break_trigger_spec_rejects_a_quote_not_in_the_tooltip(self):
        with self.assertRaises(ValueError):
            spec = shield_break_trigger_spec(armor_of_faith_entry())
            behaviour_entry(RECORDS, spec.spell, spec.name, 'trigger', 'not in the tooltip at all', spec.expected)

    def test_unknown_kind_is_rejected(self):
        with self.assertRaises(ValueError):
            behaviour_entry(RECORDS, SCARLET_JUDICATOR, 'Scarlet Judicator', 'ghost', 'strikes', 2)

    def test_tyrs_guard_entry(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 3)
        self.assertEqual(spec.trigger_spell, TESTAMENT_OF_HOPE)
        self.assertEqual(spec.metric, 'owned_creature_count')
        self.assertEqual(spec.fields, {'entry': TESTAMENT_OF_HOPE_COPY_ENTRY})
        self.assertEqual(spec.before_expected, 2)

    def test_spiritual_abdicator_entry(self):
        spec = metric_delta_spec(spiritual_abdicator_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, -15)
        self.assertEqual(spec.trigger_spell, TESTAMENT_OF_HOPE)
        self.assertEqual(spec.metric, 'aura_amount')
        self.assertEqual(spec.fields, {'spell': TESTAMENT_OF_HOPE_AURA, 'effect': 1})
        self.assertEqual(spec.before_expected, -10)


class BehaviourEntriesLookupTests(unittest.TestCase):
    def test_behaviour_entries_filters_by_spell(self):
        chosen = behaviour_entries(CLASS_FILE, [SCARLET_JUDICATOR])
        self.assertEqual([entry['spell'] for entry in chosen], [SCARLET_JUDICATOR])

    def test_behaviour_entries_rejects_unknown_spell(self):
        with self.assertRaises(ValueError):
            behaviour_entries(CLASS_FILE, [1])

    def test_behaviour_entries_everything_by_default(self):
        self.assertEqual(len(behaviour_entries(CLASS_FILE, None)), 7)


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


class AuraSpreadScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_fixtures(self):
        spec = aura_spread_spec(holy_tempest_entry())
        scenario, expectations = aura_spread_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 2)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_COUNT)
        self.assertTrue(expectation.rule.startswith('prose: "spreads Condemn on affected enemies'))
        self.assertEqual(len(expectation.model['dummy_labels']), 1)
        self.assertEqual(expectation.model['expected'], 1)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, holy_tempest_entry())
        self.assertEqual(len(run.validate(scenario)['creatures']), 2)
        self.assertEqual(expectations[0].check, BEHAVIOUR_COUNT)

    def test_seed_cast_targets_the_primary_dummy_before_the_tempest_cast(self):
        spec = aura_spread_spec(holy_tempest_entry())
        scenario, _ = aura_spread_scenario(CLASS_FILE, spec)
        seed_casts = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == CONDEMN_RANK]
        self.assertTrue(seed_casts)
        for step in seed_casts:
            self.assertEqual(step['target'], 'primary')
        tempest_casts = [step for step in scenario['steps']
                         if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_TEMPEST_RANK]
        self.assertTrue(tempest_casts)
        for step in tempest_casts:
            self.assertNotIn('target', step)

    def test_measures_aura_of_the_seeded_spell_on_the_extra_dummy_only(self):
        spec = aura_spread_spec(holy_tempest_entry())
        scenario, _ = aura_spread_scenario(CLASS_FILE, spec)
        aura_steps = [step for step in scenario['steps']
                     if step.get('metric') == 'aura' and step.get('spell') == CONDEMN_RANK
                     and step.get('actor') != 'primary']
        self.assertEqual(len(aura_steps), 2)
        for step in aura_steps:
            self.assertEqual(step['actor'], 'extra1')
            self.assertEqual(step['caster'], 'caster')


class HealingRatioScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = healing_ratio_spec(final_prayer_entry())
        scenario, expectations = healing_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        self.assertEqual(expectations[0].check, BEHAVIOUR_RATIO)
        self.assertEqual(expectations[0].model['expected'], 2.0)


class ShieldBreakTriggerScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = shield_break_trigger_spec(armor_of_faith_entry())
        scenario, expectations = shield_break_trigger_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 1)
        self.assertEqual(validated['creatures'][0]['reaction'], 1)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_TRIGGER)
        self.assertTrue(expectation.rule.startswith('prose: "Whenever the absorption shield from Staffguard'))
        self.assertEqual(expectation.model['expected'], 1)
        self.assertEqual(expectation.model['trigger_spell'], ARMOR_OF_FAITH_DAMAGE)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, armor_of_faith_entry())
        self.assertEqual(len(run.validate(scenario)['creatures']), 1)
        self.assertEqual(expectations[0].check, BEHAVIOUR_TRIGGER)

    def test_learn_comes_between_the_without_and_with_phases(self):
        spec = shield_break_trigger_spec(armor_of_faith_entry())
        scenario, _ = shield_break_trigger_scenario(CLASS_FILE, spec)
        learn_steps = [index for index, step in enumerate(scenario['steps'])
                      if step.get('action') == 'learn' and step.get('spell') == ARMOR_OF_FAITH]
        set_aura_steps = [index for index, step in enumerate(scenario['steps'])
                         if step.get('action') == 'set_aura' and step.get('spell') == STAFFGUARD_SHIELD]
        self.assertEqual(len(learn_steps), 1)
        self.assertEqual(len(set_aura_steps), 2)
        self.assertLess(set_aura_steps[0], learn_steps[0])
        self.assertLess(learn_steps[0], set_aura_steps[1])

    def test_striker_casts_the_breaker_spell_directly_at_the_caster(self):
        spec = shield_break_trigger_spec(armor_of_faith_entry())
        scenario, _ = shield_break_trigger_scenario(CLASS_FILE, spec)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == spec.breaker_spell]
        self.assertEqual(len(cast_steps), 2)
        for step in cast_steps:
            self.assertEqual(step['actor'], 'striker')
            self.assertEqual(step['target'], 'caster')

    def test_measures_trigger_spell_damage_count_on_the_striker(self):
        spec = shield_break_trigger_spec(armor_of_faith_entry())
        scenario, _ = shield_break_trigger_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'spell_damage_count' and step.get('spell') == ARMOR_OF_FAITH_DAMAGE]
        self.assertEqual(len(measure_steps), 4)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')
            self.assertEqual(step['target'], 'striker')


class MetricDeltaScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, expectations = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_METRIC_DELTA)
        self.assertTrue(expectation.rule.startswith('prose: "now summons an additional copy of yourself"'))
        self.assertEqual(expectation.model['expected'], 3)
        self.assertEqual(expectation.model['before_expected'], 2)
        self.assertEqual(expectation.model['metric'], 'owned_creature_count')

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, spiritual_abdicator_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], -15)
        self.assertEqual(expectations[0].model['before_expected'], -10)

    def test_learn_comes_between_the_before_and_after_casts(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        learn_steps = [index for index, step in enumerate(scenario['steps'])
                      if step.get('action') == 'learn' and step.get('spell') == TYRS_GUARD]
        cast_steps = [index for index, step in enumerate(scenario['steps'])
                     if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_HOPE]
        self.assertEqual(len(learn_steps), 1)
        self.assertEqual(len(cast_steps), 2)
        self.assertLess(cast_steps[0], learn_steps[0])
        self.assertLess(learn_steps[0], cast_steps[1])

    def test_measures_the_declared_metric_and_fields_before_and_after(self):
        spec = metric_delta_spec(spiritual_abdicator_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_amount' and step.get('spell') == 704409]
        self.assertEqual(len(measure_steps), 2)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')
            self.assertEqual(step['effect'], 1)

    def test_waits_the_expire_ms_between_the_learn_and_the_second_cast(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        learn_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('action') == 'learn' and step.get('spell') == TYRS_GUARD)
        expire_wait = scenario['steps'][learn_index + 1]
        self.assertEqual(expire_wait['action'], 'wait')
        self.assertEqual(expire_wait['ms'], spec.expire_ms)

    def test_learns_the_trigger_spell_once_before_the_first_cast(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        trigger_learn_steps = [index for index, step in enumerate(scenario['steps'])
                               if step.get('action') == 'learn' and step.get('spell') == TESTAMENT_OF_HOPE]
        first_cast_index = next(index for index, step in enumerate(scenario['steps'])
                                if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_HOPE)
        self.assertEqual(len(trigger_learn_steps), 1)
        self.assertLess(trigger_learn_steps[0], first_cast_index)


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


class JudgeHolyTempestTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'count', 'expected': 1, 'quote': 'spreads Condemn on affected enemies to a nearby enemy',
                 'dummy_labels': [('b1', 'a1')]}
        return Expectation('label', BEHAVIOUR_COUNT, HOLY_TEMPEST, RIGHTEOUS_TEMPEST_RANK, None, '1',
                           'prose: "spreads Condemn on affected enemies to a nearby enemy" (301339)', model)

    def test_condemn_observed_on_the_nearby_dummy_is_ok(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_no_spread_at_all_is_alert_not_ok(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.expected, 1.0)

    def test_condemn_already_present_before_the_learn_is_unmeasured(self):
        expectation = self.expectation()
        values = {'b1': 1.0, 'a1': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'unmeasured')


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


class JudgeShieldBreakTriggerTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'trigger', 'without_before_label': 'wb', 'without_after_label': 'wa',
                 'with_before_label': 'tb', 'with_after_label': 'ta', 'expected': 1,
                 'trigger_spell': ARMOR_OF_FAITH_DAMAGE,
                 'quote': 'Whenever the absorption shield from Staffguard breaks, inflict'}
        return Expectation('label', BEHAVIOUR_TRIGGER, ARMOR_OF_FAITH, ARMOR_OF_FAITH_DAMAGE, None, '1',
                           'prose: "Whenever the absorption shield from Staffguard breaks, inflict" (804930)', model)

    def test_fires_only_with_the_passive_is_ok(self):
        expectation = self.expectation()
        values = {'wb': 0.0, 'wa': 0.0, 'tb': 0.0, 'ta': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_absent_effect_with_the_passive_known_is_alert(self):
        expectation = self.expectation()
        values = {'wb': 0.0, 'wa': 0.0, 'tb': 0.0, 'ta': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)

    def test_fires_without_the_passive_known_is_alert(self):
        expectation = self.expectation()
        values = {'wb': 0.0, 'wa': 1.0, 'tb': 0.0, 'ta': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        values = {'wb': 0.0, 'wa': 0.0, 'tb': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('ta', verdict.explanation)


class JudgeMetricDeltaTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 3,
                 'before_expected': 2, 'metric': 'owned_creature_count',
                 'quote': 'now summons an additional copy of yourself'}
        return Expectation('label', BEHAVIOUR_METRIC_DELTA, TYRS_GUARD, TESTAMENT_OF_HOPE, None, '3',
                           'prose: "now summons an additional copy of yourself" (560649)', model)

    def test_exact_match_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 2.0, 'after': 3.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_absent_effect_leaving_after_at_the_before_value_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 2.0, 'after': 2.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 2.0)
        self.assertEqual(verdict.expected, 3.0)

    def test_wrong_baseline_is_alert_even_if_after_matches(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1.0, 'after': 3.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_off_by_one_after_value_is_alert_not_tolerated(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 2.0, 'after': 4.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 2.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('after', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)

    def test_negative_aura_amount_exact_match_is_ok(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': -15,
                 'before_expected': -10, 'metric': 'aura_amount',
                 'quote': 'reduces damage taken by an additional 5% per copy'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, SPIRITUAL_ABDICATOR, TESTAMENT_OF_HOPE, None,
                                  '-15', 'prose: "reduces damage taken by an additional 5% per copy" (803219)', model)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': -10.0, 'after': -15.0}), expectation)
        self.assertEqual(verdict.status, 'ok')


if __name__ == '__main__':
    unittest.main()
