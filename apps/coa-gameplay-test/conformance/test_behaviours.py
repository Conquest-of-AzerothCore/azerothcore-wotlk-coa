from pathlib import Path
import sys
import unittest

from behaviours import (BEHAVIOUR_COUNT, BEHAVIOUR_DURATION, BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_RATIO,
                        BEHAVIOUR_TRIGGER, HealingRatioTarget, aura_spread_scenario, aura_spread_spec,
                        behaviour_entries, behaviour_entry, behaviour_scenario, duration_scenario, duration_spec,
                        health_ratio_spec, health_threshold_ratio_scenario, healing_ratio_scenario,
                        healing_ratio_spec, leech_heal_modifier_factor, leech_ratio_scenario, leech_ratio_spec,
                        metric_delta_scenario, metric_delta_spec, shield_break_trigger_scenario,
                        shield_break_trigger_spec, target_count_scenario, target_count_spec)
from compare import Verdict, judge_behaviour
from hits import aura_modifiers
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
TESTAMENT_OF_FORTITUDE = 500678
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
BATTLEPRIEST = 801202
FIREBALL = 133
TITANFALL = 300607
TITANSTRIKE_MAX_RANK = 806835
SACRED_OATH = 712346
OATHKEEPER = 803237
KEEPING_THE_OATH = 803149
SMITE = 48123


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


def battlepriest_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == BATTLEPRIEST)


def titanfall_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TITANFALL)


def sacred_oath_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SACRED_OATH)


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
        self.assertEqual(spec.targets, (
            HealingRatioTarget(TESTAMENT_OF_FAITH, 'Testament of Faith'),
            HealingRatioTarget(TESTAMENT_OF_FORTITUDE, 'Testament of Fortitude', 'effect_value', 0)))

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

    def test_battlepriest_entry(self):
        spec = health_ratio_spec(battlepriest_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'ratio', spec.quote, spec.levels[0][1])
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.probe_spell, FIREBALL)
        self.assertEqual(spec.levels, ((90, 0.8), (50, 1.0), (10, 0.8)))

    def test_battlepriest_quote_matches_dbc(self):
        self.assertEqual(
            behaviour_entry(RECORDS, BATTLEPRIEST, 'Battlepriest', 'ratio',
                            'take 20% reduced Magic damage', 0.8).quote,
            'take 20% reduced Magic damage')

    def test_sacred_oath_entry(self):
        spec = duration_spec(sacred_oath_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'duration', spec.quote, spec.expected_ms)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1000)
        self.assertEqual(spec.target_aura, OATHKEEPER)
        self.assertEqual(spec.debt_aura, KEEPING_THE_OATH)
        self.assertEqual(spec.breaker_spell, SMITE)


class BehaviourEntriesLookupTests(unittest.TestCase):
    def test_behaviour_entries_filters_by_spell(self):
        chosen = behaviour_entries(CLASS_FILE, [SCARLET_JUDICATOR])
        self.assertEqual([entry['spell'] for entry in chosen], [SCARLET_JUDICATOR])

    def test_behaviour_entries_rejects_unknown_spell(self):
        with self.assertRaises(ValueError):
            behaviour_entries(CLASS_FILE, [1])

    def test_behaviour_entries_everything_by_default(self):
        self.assertEqual(len(behaviour_entries(CLASS_FILE, None)), 10)


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

    def test_target_rank_is_learned_before_the_first_cast(self):
        for entry in (scarlet_judicator_entry(), justice_entry()):
            spec = target_count_spec(entry)
            scenario, _ = target_count_scenario(CLASS_FILE, spec)
            steps = scenario['steps']
            learn_index = next(i for i, step in enumerate(steps)
                               if step.get('action') == 'learn' and step.get('spell') == spec.target_rank)
            first_cast_index = next(i for i, step in enumerate(steps)
                                    if step.get('action') == 'cast' and step.get('spell') == spec.target_rank)
            self.assertLess(learn_index, first_cast_index,
                            f'{spec.target_rank} must be learned before it is first cast')


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
        self.assertEqual(len(expectations), 2)
        for expectation in expectations:
            self.assertEqual(expectation.check, BEHAVIOUR_RATIO)
            self.assertEqual(expectation.model['expected'], 2.0)

    def test_scenario_adds_fortitude_effect_value_target(self):
        spec = healing_ratio_spec(final_prayer_entry())
        scenario, expectations = healing_ratio_scenario(CLASS_FILE, spec)
        fortitude = next(expectation for expectation in expectations
                         if expectation.rank_id == TESTAMENT_OF_FORTITUDE)
        steps_by_label = {step['label']: step for step in scenario['steps'] if step.get('action') == 'assert'}
        before_step = steps_by_label[fortitude.model['before_label']]
        after_step = steps_by_label[fortitude.model['after_label']]
        for step in (before_step, after_step):
            self.assertEqual(step['metric'], 'spell_effect_value')
            self.assertEqual(step['spell'], TESTAMENT_OF_FORTITUDE)
            self.assertEqual(step['effect'], 0)
        cast_targets = [step['spell'] for step in scenario['steps'] if step.get('action') == 'cast']
        self.assertNotIn(TESTAMENT_OF_FORTITUDE, cast_targets)

    def test_scenario_keeps_faith_cast_based(self):
        spec = healing_ratio_spec(final_prayer_entry())
        scenario, expectations = healing_ratio_scenario(CLASS_FILE, spec)
        faith = next(expectation for expectation in expectations if expectation.rank_id == TESTAMENT_OF_FAITH)
        steps_by_label = {step['label']: step for step in scenario['steps'] if step.get('action') == 'assert'}
        before_step = steps_by_label[faith.model['before_label']]
        after_step = steps_by_label[faith.model['after_label']]
        for step in (before_step, after_step):
            self.assertEqual(step['metric'], 'spell_healing_done')
            self.assertEqual(step['spell'], TESTAMENT_OF_FAITH)
        cast_targets = [step['spell'] for step in scenario['steps'] if step.get('action') == 'cast']
        self.assertNotIn(TESTAMENT_OF_FORTITUDE, cast_targets)
        self.assertIn(TESTAMENT_OF_FAITH, cast_targets)


class HealthRatioScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = health_ratio_spec(battlepriest_entry())
        scenario, expectations = health_threshold_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 3)
        for expectation in expectations:
            self.assertEqual(expectation.check, BEHAVIOUR_RATIO)
            self.assertTrue(expectation.rule.startswith('prose: "take 20% reduced Magic damage"'))
        self.assertEqual([expectation.model['expected'] for expectation in expectations], [0.8, 1.0, 0.8])
        self.assertEqual([expectation.model['target_name'] for expectation in expectations],
                         ['90% health', '50% health', '10% health'])

    def test_mid_health_is_not_naively_reusing_the_reduced_ratio(self):
        spec = health_ratio_spec(battlepriest_entry())
        _, expectations = health_threshold_ratio_scenario(CLASS_FILE, spec)
        mid = next(expectation for expectation in expectations if expectation.model['target_name'] == '50% health')
        self.assertEqual(mid.model['expected'], 1.0)
        self.assertNotEqual(mid.model['expected'], 0.8)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, battlepriest_entry())
        run.validate(scenario)
        self.assertEqual(len(expectations), 3)
        self.assertTrue(all(expectation.check == BEHAVIOUR_RATIO for expectation in expectations))

    def test_set_health_steps_fix_a_round_maximum_before_and_after_the_learn(self):
        spec = health_ratio_spec(battlepriest_entry())
        scenario, _ = health_threshold_ratio_scenario(CLASS_FILE, spec)
        set_health_steps = [step for step in scenario['steps'] if step.get('action') == 'set_health']
        self.assertEqual(len(set_health_steps), 6)
        for step in set_health_steps:
            self.assertEqual(step['maximum'], 10000)
            self.assertEqual(step['actor'], 'caster')
        self.assertEqual([step['value'] for step in set_health_steps], [9000, 5000, 1000, 9000, 5000, 1000])

    def test_learn_comes_between_the_before_and_after_measurements(self):
        spec = health_ratio_spec(battlepriest_entry())
        scenario, _ = health_threshold_ratio_scenario(CLASS_FILE, spec)
        actions = [step.get('action') for step in scenario['steps']]
        learn_index = actions.index('learn')
        set_health_indexes = [index for index, action in enumerate(actions) if action == 'set_health']
        self.assertTrue(all(index < learn_index for index in set_health_indexes[:3]))
        self.assertTrue(all(index > learn_index for index in set_health_indexes[3:]))

    def test_measurements_use_the_probe_spell_on_the_dummy(self):
        spec = health_ratio_spec(battlepriest_entry())
        scenario, _ = health_threshold_ratio_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'script_spell_damage_taken']
        self.assertEqual(len(measure_steps), 6)
        for step in measure_steps:
            self.assertEqual(step['spell'], FIREBALL)
            self.assertEqual(step['target'], 'dummy')
            self.assertEqual(step['actor'], 'caster')


class LeechRatioScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = leech_ratio_spec(titanfall_entry())
        scenario, expectations = leech_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 2)
        for expectation in expectations:
            self.assertEqual(expectation.check, BEHAVIOUR_RATIO)
            self.assertEqual(expectation.rank_id, TITANSTRIKE_MAX_RANK)
            self.assertEqual(expectation.model['kind'], 'leech_ratio')
        before = next(item for item in expectations if item.label.endswith('leech_ratio before'))
        after = next(item for item in expectations if item.label.endswith('leech_ratio after'))
        heal_factor = leech_heal_modifier_factor(RECORDS, CLASS_FILE)
        self.assertAlmostEqual(before.model['expected'], 1.0 * heal_factor, places=9)
        self.assertAlmostEqual(after.model['expected'], 2.0 * heal_factor, places=9)

    def test_known_healing_done_modifiers_are_folded_into_the_expected_ratio(self):
        heal_factor = leech_heal_modifier_factor(RECORDS, CLASS_FILE)
        heal_modifiers = [modifier for modifier in aura_modifiers(RECORDS, CLASS_FILE['known_auras'],
                                                                  CLASS_FILE['level'])
                         if modifier.applies_to == 'heal']
        self.assertTrue(heal_modifiers)
        expected_factor = 1.0
        for modifier in heal_modifiers:
            expected_factor *= (100 + modifier.percent) / 100
        self.assertAlmostEqual(heal_factor, expected_factor, places=9)
        self.assertNotEqual(heal_factor, 1.0)

    def test_scenario_uses_two_separate_dummies_since_leeched_health_cannot_be_raised_back(self):
        spec = leech_ratio_spec(titanfall_entry())
        scenario, _ = leech_ratio_scenario(CLASS_FILE, spec)
        creature_ids = {creature['id'] for creature in scenario['creatures']}
        self.assertEqual(len(creature_ids), 2)
        set_health_steps = [step for step in scenario['steps'] if step.get('action') == 'set_health_pct']
        self.assertEqual(len(set_health_steps), 2)
        self.assertEqual({step['target'] for step in set_health_steps}, creature_ids)
        self.assertEqual({step['pct'] for step in set_health_steps}, {30})

    def test_learn_titanfall_comes_between_the_two_casts(self):
        spec = leech_ratio_spec(titanfall_entry())
        scenario, _ = leech_ratio_scenario(CLASS_FILE, spec)
        actions = [(step.get('action'), step.get('spell')) for step in scenario['steps']]
        learn_titanfall = actions.index(('learn', TITANFALL))
        casts = [index for index, (action, _) in enumerate(actions) if action == 'cast']
        self.assertEqual(len(casts), 2)
        self.assertLess(casts[0], learn_titanfall)
        self.assertGreater(casts[1], learn_titanfall)

    def test_measures_real_damage_and_heal_of_the_same_cast(self):
        spec = leech_ratio_spec(titanfall_entry())
        scenario, expectations = leech_ratio_scenario(CLASS_FILE, spec)
        steps_by_label = {step['label']: step for step in scenario['steps'] if step.get('action') == 'assert'}
        for expectation in expectations:
            damage_step = steps_by_label[expectation.model['damage_label']]
            heal_step = steps_by_label[expectation.model['heal_label']]
            self.assertEqual(damage_step['metric'], 'spell_damage_total')
            self.assertEqual(damage_step['spell'], TITANSTRIKE_MAX_RANK)
            self.assertEqual(heal_step['metric'], 'spell_heal_total')
            self.assertEqual(heal_step['target'], 'caster')

    def test_the_after_phase_baselines_its_cumulative_heal_total_on_the_before_phase(self):
        spec = leech_ratio_spec(titanfall_entry())
        _, expectations = leech_ratio_scenario(CLASS_FILE, spec)
        before = next(item for item in expectations if item.label.endswith('leech_ratio before'))
        after = next(item for item in expectations if item.label.endswith('leech_ratio after'))
        self.assertIsNone(before.model['heal_baseline_label'])
        self.assertEqual(after.model['heal_baseline_label'], before.model['heal_label'])

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, titanfall_entry())
        run.validate(scenario)
        self.assertEqual(len(expectations), 2)
        self.assertTrue(all(expectation.check == BEHAVIOUR_RATIO for expectation in expectations))


class JudgeLeechRatioTests(unittest.TestCase):
    def expectation(self, label_suffix, expected, heal_baseline_label=None):
        model = {'kind': 'leech_ratio', 'damage_label': 'damage', 'heal_label': 'heal',
                 'heal_baseline_label': heal_baseline_label, 'expected': expected,
                 'quote': 'now heals you for twice the damage dealt', 'target_name': f'Titanfall ({label_suffix})'}
        return Expectation(f'label {label_suffix}', BEHAVIOUR_RATIO, TITANFALL, TITANSTRIKE_MAX_RANK, None,
                           str(expected), 'prose: "now heals you for twice the damage dealt" (300607)', model)

    def test_titanfall_absent_doubling_reads_as_alert_not_a_false_ok(self):
        expectation = self.expectation('after', 2.0)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'damage': 100.0, 'heal': 100.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_titanfall_working_doubling_is_ok(self):
        expectation = self.expectation('after', 2.0)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'damage': 100.0, 'heal': 200.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_titanstrike_without_titanfall_matches_the_1_to_1_ratio(self):
        expectation = self.expectation('before', 1.0)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'damage': 100.0, 'heal': 100.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_the_cumulative_heal_total_is_baselined_before_the_ratio_is_judged(self):
        expectation = self.expectation('after', 2.0, heal_baseline_label='baseline')
        verdict = judge_behaviour(base_verdict(expectation),
                                  FakeRun({'damage': 100.0, 'heal': 300.0, 'baseline': 100.0}), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 2.0)

    def test_an_unbaselined_cumulative_heal_total_would_misreport_the_ratio(self):
        expectation = self.expectation('after', 2.0, heal_baseline_label='baseline')
        contaminated = Expectation(expectation.label, expectation.check, expectation.spell_id, expectation.rank_id,
                                   expectation.effect_index, expectation.displayed, expectation.rule,
                                   {**expectation.model, 'heal_baseline_label': None})
        verdict = judge_behaviour(base_verdict(contaminated),
                                  FakeRun({'damage': 100.0, 'heal': 300.0, 'baseline': 100.0}), contaminated)
        self.assertEqual(verdict.status, 'alert')


class DurationScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectation(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, expectations = duration_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 2)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_DURATION)
        self.assertTrue(expectation.rule.startswith('prose: "remove 1 sec from the duration of"'))
        self.assertEqual(expectation.model['expected_ms'], 1000)
        self.assertEqual(expectation.rank_id, OATHKEEPER)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, sacred_oath_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_DURATION)

    def test_steps_order_debt_setup_then_learn_then_before_attack_after_count(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, _ = duration_scenario(CLASS_FILE, spec)
        actions = [step.get('action') for step in scenario['steps']
                  if step.get('action') in ('set_aura', 'cast', 'learn', 'attack', 'stop_attack')]
        set_aura_index = actions.index('set_aura')
        cast_index = actions.index('cast')
        learn_index = actions.index('learn')
        attack_index = actions.index('attack')
        stop_index = actions.index('stop_attack')
        self.assertLess(set_aura_index, cast_index)
        self.assertLess(cast_index, learn_index)
        self.assertLess(learn_index, attack_index)
        self.assertLess(attack_index, stop_index)

    def test_player_fixture_overrides_melee_crit_rating_without_touching_the_class_file(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, _ = duration_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], 100000)
        self.assertNotIn('melee_crit_rating', CLASS_FILE.get('ratings', {}))

    def test_measures_aura_duration_ms_of_the_target_aura_before_and_after(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, _ = duration_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_duration_ms' and step.get('spell') == OATHKEEPER]
        self.assertEqual(len(measure_steps), 2)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')

    def test_measures_exactly_one_forced_crit_via_melee_damage_count(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, expectations = duration_scenario(CLASS_FILE, spec)
        count_label = expectations[0].model['count_label']
        step, = [step for step in scenario['steps'] if step.get('label') == count_label]
        self.assertEqual(step['metric'], 'melee_damage_count')
        self.assertTrue(step['critical'])
        self.assertEqual(step['hand'], 0)

    def test_striker_cannot_miss_the_breaker_spell(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, _ = duration_scenario(CLASS_FILE, spec)
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == 'striker')
        self.assertEqual(striker.get('spell_hit_bonus'), 100,
                         'the striker must be forced to hit or the debt_amount assert is flaky '
                         '(Unit::MagicSpellHitResult gives Smite only ~96% hit at equal level)')

    def test_striker_spell_hit_bonus_round_trips_through_validate(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, _ = duration_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        striker = next(creature for creature in validated['creatures'] if creature['id'] == 'striker')
        self.assertEqual(striker.get('spell_hit_bonus'), 100)

    def test_sets_the_debt_aura_and_has_a_striker_cast_the_breaker_spell_at_the_caster(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, _ = duration_scenario(CLASS_FILE, spec)
        set_aura_steps = [step for step in scenario['steps']
                         if step.get('action') == 'set_aura' and step.get('spell') == KEEPING_THE_OATH]
        self.assertEqual(len(set_aura_steps), 1)
        self.assertEqual(set_aura_steps[0]['actor'], 'caster')
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == SMITE]
        self.assertEqual(len(cast_steps), 1)
        self.assertEqual(cast_steps[0]['actor'], 'striker')
        self.assertEqual(cast_steps[0]['target'], 'caster')

    def test_asserts_a_nonzero_debt_before_measuring_the_before_label(self):
        spec = duration_spec(sacred_oath_entry())
        scenario, _ = duration_scenario(CLASS_FILE, spec)
        actions = scenario['steps']
        debt_assert = next(step for step in actions
                           if step.get('metric') == 'aura_amount' and step.get('spell') == OATHKEEPER)
        self.assertEqual(debt_assert['min'], 1)
        self.assertNotIn('max', debt_assert)
        before_index = next(index for index, step in enumerate(actions)
                            if step.get('metric') == 'aura_duration_ms')
        self.assertLess(actions.index(debt_assert), before_index)


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
    def __init__(self, values, max_step_ms=None):
        self.values = values
        self.key = 'fake'
        self.status = 'completed'
        self.message = ''
        self.steps = []
        self.max_step_ms = max_step_ms
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

    def fortitude_expectation(self):
        model = {'kind': 'ratio', 'before_label': 'before', 'after_label': 'after', 'expected': 2.0,
                 'quote': 'Doubles the healing done to you', 'target_name': 'Testament of Fortitude'}
        return Expectation('label', BEHAVIOUR_RATIO, FINAL_PRAYER, TESTAMENT_OF_FORTITUDE, None, '2.0',
                           'prose: "Doubles the healing done to you" (705268)', model)

    def test_fortitude_unchanged_effect_value_is_alert_not_ok(self):
        expectation = self.fortitude_expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 5.0, 'after': 5.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

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


class JudgeHealthRatioTests(unittest.TestCase):
    def expectation(self, health_pct, expected_ratio):
        model = {'kind': 'ratio', 'before_label': 'before', 'after_label': 'after', 'expected': expected_ratio,
                 'quote': 'take 20% reduced Magic damage', 'target_name': f'{health_pct}% health'}
        return Expectation('label', BEHAVIOUR_RATIO, BATTLEPRIEST, health_pct, None, str(expected_ratio),
                           'prose: "take 20% reduced Magic damage" (801202)', model)

    def test_90_percent_reduction_matches_is_ok(self):
        expectation = self.expectation(90, 0.8)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1000.0, 'after': 800.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_10_percent_reduction_matches_is_ok(self):
        expectation = self.expectation(10, 0.8)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1000.0, 'after': 800.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_50_percent_no_reduction_is_ok(self):
        expectation = self.expectation(50, 1.0)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1000.0, 'after': 1000.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_90_percent_absent_effect_is_alert(self):
        expectation = self.expectation(90, 0.8)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1000.0, 'after': 1000.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 1.0)
        self.assertEqual(verdict.expected, 0.8)

    def test_10_percent_absent_effect_is_alert(self):
        expectation = self.expectation(10, 0.8)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1000.0, 'after': 1000.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 1.0)
        self.assertEqual(verdict.expected, 0.8)

    def test_50_percent_reduction_applying_when_it_should_not_is_alert(self):
        expectation = self.expectation(50, 1.0)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1000.0, 'after': 800.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')


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


class JudgeDurationTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'duration', 'before_label': 'before', 'after_label': 'after', 'count_label': 'crits',
                 'expected_ms': 1000, 'wait_ms': 500, 'quote': 'remove 1 sec from the duration of'}
        return Expectation('label', BEHAVIOUR_DURATION, SACRED_OATH, OATHKEEPER, None, '1000',
                           'prose: "remove 1 sec from the duration of" (712346)', model)

    def test_duration_drops_by_the_wait_plus_the_extra_second_is_ok(self):
        expectation = self.expectation()
        values = {'before': 8000.0, 'after': 8000.0 - 500 - 1000, 'crits': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_duration_drops_by_only_the_wait_is_alert_not_ok(self):
        expectation = self.expectation()
        values = {'before': 8000.0, 'after': 8000.0 - 500, 'crits': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_duration_drops_by_the_wait_plus_the_extra_second_and_tick_overshoot_is_ok(self):
        expectation = self.expectation()
        values = {'before': 8000.0, 'after': 8000.0 - 512 - 1000, 'crits': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values, max_step_ms=20.0), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_tick_overshoot_beyond_max_step_ms_is_still_alert(self):
        expectation = self.expectation()
        values = {'before': 8000.0, 'after': 8000.0 - 521 - 1000, 'crits': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values, max_step_ms=20.0), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_forced_swing_that_did_not_crit_is_unmeasured_not_ok_or_alert(self):
        expectation = self.expectation()
        values = {'before': 8000.0, 'after': 8000.0 - 500, 'crits': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_two_forced_crits_is_unmeasured_not_ok_or_alert(self):
        expectation = self.expectation()
        values = {'before': 8000.0, 'after': 0.0, 'crits': 2.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 8000.0, 'crits': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('after', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


if __name__ == '__main__':
    unittest.main()
