from dataclasses import replace
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from behaviours import (BEHAVIOUR_AMOUNT_DELTA, BEHAVIOUR_AURA_GRANT, BEHAVIOUR_CHARGE_RECHARGE, BEHAVIOUR_COUNT,
                        BEHAVIOUR_CRIT_GUARANTEE, BEHAVIOUR_CRIT_MAGNITUDE, BEHAVIOUR_DURATION,
                        BEHAVIOUR_DURATION_RATIO, BEHAVIOUR_DURATION_REFRESH, BEHAVIOUR_EXCLUSIVITY,
                        BEHAVIOUR_FIXED_COUNT, BEHAVIOUR_GROUP_STACK_CAP, BEHAVIOUR_INTERNAL_COOLDOWN_GATE,
                        BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_OATH_CONSUMPTION, BEHAVIOUR_OATH_CONSUMPTION_REMOVAL,
                        BEHAVIOUR_PARTY_STAT_RATIO, BEHAVIOUR_RATIO, BEHAVIOUR_SINGLE_TARGET, BEHAVIOUR_TRIGGER,
                        MECHANIC_LAND_ATTEMPTS, STRIKER,
                        NotModelled,
                        AuraGrantSpec, CritGuaranteeSpec, HealingRatioTarget, IcdGateSpec, OathConsumptionSpec,
                        OathConsumptionRemovalSpec,
                        ally_heal_breadth_scenario, ally_heal_breadth_spec,
                        amount_delta_scenario, amount_delta_spec, aura_grant_scenario, aura_grant_spec,
                        aura_spread_scenario, aura_spread_spec, behaviour_entries, behaviour_entry,
                        behaviour_scenario, charge_recharge_scenario, charge_recharge_spec,
                        crit_guarantee_scenario, crit_guarantee_spec,
                        crit_magnitude_scenario, crit_magnitude_spec,
                        duration_refresh_scenario, duration_refresh_spec, duration_scenario, duration_spec,
                        exclusivity_chain_scenario, exclusivity_chain_spec,
                        fixed_target_count_scenario, fixed_target_count_spec,
                        group_stack_cap_scenario, group_stack_cap_spec,
                        health_ratio_spec, health_threshold_ratio_scenario, healing_ratio_scenario,
                        healing_ratio_spec, icd_gate_scenario, icd_gate_spec, leech_heal_modifier_factor,
                        leech_ratio_scenario, leech_ratio_spec,
                        mechanic_duration_scenario, mechanic_duration_spec, metric_delta_scenario,
                        metric_delta_spec, nearby_ally_id, oath_consumption_scenario, oath_consumption_spec,
                        oath_consumption_removal_scenario, oath_consumption_removal_spec,
                        party_ally_id, party_stat_ratio_scenario, party_stat_ratio_spec,
                        shield_break_trigger_scenario, shield_break_trigger_spec,
                        single_target_scenario, single_target_spec,
                        target_count_scenario, target_count_spec)
from compare import Verdict, judge_behaviour
from hits import aura_modifiers
from procs import cast_interval
from profile import DBC_DIR, load_class_file
from tooltip import Records
from values import Expectation, FORCED_CRIT_RATING, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

CLASS_FILE = load_class_file(19)
RECORDS = Records(dataset(DBC_DIR))
SCARLET_JUDICATOR = 525024
JUSTICE = 712437
FINAL_PRAYER = 705268
DIVINE_FORCE_MAX_RANK = 807805
INTERDICT = 560116
TESTAMENT_OF_FAITH = 501606
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
FINESSE_RANK_1 = 705271
FINESSE_RANK_2 = 707851
COURAGE_RANK_1 = 707754
COURAGE_RANK_2 = 712466
MELT_WEAPON = 301235
HAMSTRING = 1715
BLESSING_OF_AGGRAMAR = 300502
BLADE_OF_FAITH = 803872
OATH_CHAIN = 704576
RIGHTEOUS_UPHEAVAL = 501562
WARRIOR_OF_TYR = 301253
CONDEMN = 567541
SACRED_RESISTANCE = 301309
RECKONING_AT_60 = 572741
RECKONING_ARMOR = 680870
KEEPING_THE_OATH_PASSIVE = 92109
HOLY_BOOKS = 706468
LIBRAM_OF_CONSECRATION = 801441
LIBRAM_OF_TENACITY = 801461
LIBRAM_OF_GRACE = 801463
LIBRAM_OF_ZEAL = 801466
LIBRAM_OF_FERVOR = 805423
TRANSCENDING_STRIKES = 804897
DIVINE_FORCE = 806153
WHIRLING_TEMPEST = 300504
RIGHTEOUS_TEMPEST = 805409
SERENDIPITY = 300929
RUNIC_POWER = 300944
CALL_OF_THE_MONASTERY = 560550
UNLEASHED_RAGE = 30802
RIGHTEOUS_CUSTODIAN = 572808
FORTIFIED_BODY = 300515
TREE_OF_LIFE = 34123
SANCTIFY = 705274
LIBRAM_OF_TENACITY = 801461
CHAKRA_OF_POWER = 803158
CHAKRA_OF_POWER_ENERGIZE = 804181
PATIENCE = 712678
CHASTISE = 503141
MARTIAL_TRAINING = 806525
LIBRAM_OF_TENACITY = 801461
TENACIOUS_DEFENDER = 707385
TEMPLE_GUARDIAN = 803792


HOLY_CLEAVE = 573049
CALL_OF_THE_MONASTERY = 560550
DEVOTION_OF_KHAZGOROTH = 560096
SERENDIPITY = 300929
FORTIFIED_BODY = 300515
LIBRAM_OF_GRACE = 801463
CHAKRA_OF_LIGHT = 803159


def scarlet_judicator_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SCARLET_JUDICATOR)


def holy_cleave_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == HOLY_CLEAVE)


def call_of_the_monastery_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == CALL_OF_THE_MONASTERY)


def devotion_of_khazgoroth_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == DEVOTION_OF_KHAZGOROTH)


def serendipity_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SERENDIPITY)


def fortified_body_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == FORTIFIED_BODY)


def libram_of_grace_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == LIBRAM_OF_GRACE)


def chakra_of_light_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == CHAKRA_OF_LIGHT)


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


def finesse_rank_1_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == FINESSE_RANK_1)


def finesse_rank_2_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == FINESSE_RANK_2)


def courage_rank_1_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == COURAGE_RANK_1)


def courage_rank_2_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == COURAGE_RANK_2)


def blessing_of_aggramar_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == BLESSING_OF_AGGRAMAR)


def warrior_of_tyr_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == WARRIOR_OF_TYR)


def sacred_resistance_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SACRED_RESISTANCE)


def keeping_the_oath_passive_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == KEEPING_THE_OATH_PASSIVE)


def holy_books_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == HOLY_BOOKS)


def libram_exclusivity_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == LIBRAM_OF_CONSECRATION and entry['kind'] == 'exclusivity')


def transcending_strikes_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TRANSCENDING_STRIKES
               and 'variant' not in entry)


def transcending_strikes_target_gate_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == TRANSCENDING_STRIKES and entry.get('variant') == 'target_gate')


def whirling_tempest_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == WHIRLING_TEMPEST and 'variant' not in entry)


def whirling_tempest_stacks_with_courage_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == WHIRLING_TEMPEST and entry.get('variant') == 'stacks_with_courage')


def serendipity_group_stack_cap_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == SERENDIPITY and entry['kind'] == 'group_stack_cap')


def call_of_the_monastery_group_stack_cap_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == CALL_OF_THE_MONASTERY and entry['kind'] == 'group_stack_cap')


def fortified_body_group_stack_cap_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == FORTIFIED_BODY and entry['kind'] == 'group_stack_cap')


def righteous_custodian_single_target_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == RIGHTEOUS_CUSTODIAN and entry['kind'] == 'single_target')


def sanctify_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SANCTIFY)


def chakra_of_power_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == CHAKRA_OF_POWER)


def patience_duration_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == PATIENCE and 'variant' not in entry)


def patience_cooldown_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == PATIENCE and entry.get('variant') == 'cooldown')


def chastise_weapon_damage_gate_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == CHASTISE)


def libram_of_tenacity_heal_gate_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == LIBRAM_OF_TENACITY)


def temple_guardian_charge_recharge_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TEMPLE_GUARDIAN)


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
            HealingRatioTarget(TESTAMENT_OF_FAITH, 'Testament of Faith', 'taken'),
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

    def test_finesse_rank_1_entry(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'ratio', spec.quote, spec.expected_ratio)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.expected_ratio, 0.85)
        self.assertEqual(spec.vehicle_spell, MELT_WEAPON)

    def test_finesse_rank_2_entry(self):
        spec = mechanic_duration_spec(finesse_rank_2_entry())
        self.assertEqual(spec.expected_ratio, 0.70)
        self.assertEqual(spec.vehicle_spell, MELT_WEAPON)

    def test_courage_rank_1_entry(self):
        spec = mechanic_duration_spec(courage_rank_1_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'ratio', spec.quote, spec.expected_ratio)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.expected_ratio, 0.90)
        self.assertEqual(spec.vehicle_spell, HAMSTRING)

    def test_courage_rank_2_entry(self):
        spec = mechanic_duration_spec(courage_rank_2_entry())
        self.assertEqual(spec.expected_ratio, 0.80)
        self.assertEqual(spec.vehicle_spell, HAMSTRING)

    def test_tyrs_guard_entry(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 3)
        self.assertEqual(spec.trigger_spell, TESTAMENT_OF_HOPE)
        self.assertEqual(spec.metric, 'owned_creature_count')
        self.assertEqual(spec.fields, {'entry': TESTAMENT_OF_HOPE_COPY_ENTRY})
        self.assertEqual(spec.before_expected, 2)
        self.assertEqual(spec.setup_casts, ())

    def test_transcending_strikes_entry(self):
        spec = metric_delta_spec(transcending_strikes_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.trigger_spell, DIVINE_FORCE)
        self.assertEqual(spec.metric, 'cooldown_ms')
        self.assertEqual(spec.fields, {'spell': DIVINE_FORCE})
        self.assertEqual(spec.setup_casts, (BLADE_OF_FAITH,))
        self.assertEqual(spec.target, 'dummy')

    def test_spiritual_abdicator_entry(self):
        spec = metric_delta_spec(spiritual_abdicator_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, -15)
        self.assertEqual(spec.trigger_spell, TESTAMENT_OF_HOPE)
        self.assertEqual(spec.metric, 'aura_amount')
        self.assertEqual(spec.fields, {'spell': TESTAMENT_OF_HOPE_AURA, 'effect': 1})
        self.assertEqual(spec.before_expected, -10)

    def test_sacred_resistance_entry(self):
        spec = metric_delta_spec(sacred_resistance_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.trigger_spell, RECKONING_AT_60)
        self.assertEqual(spec.metric, 'aura')
        self.assertEqual(spec.fields, {'spell': RECKONING_ARMOR})
        self.assertEqual(spec.before_expected, 0)
        self.assertEqual(spec.target, 'dummy')

    def test_keeping_the_oath_passive_entry(self):
        spec = metric_delta_spec(keeping_the_oath_passive_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.trigger_spell, RECKONING_AT_60)
        self.assertEqual(spec.metric, 'aura')
        self.assertEqual(spec.fields, {'spell': OATH_CHAIN})
        self.assertEqual(spec.before_expected, 0)
        self.assertEqual(spec.target, 'dummy')

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

    def test_whirling_tempest_entry(self):
        spec = metric_delta_spec(whirling_tempest_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.trigger_spell, RIGHTEOUS_TEMPEST)
        self.assertEqual(spec.metric, 'run_speed_rate')
        self.assertEqual(spec.expected, 1.20)
        self.assertEqual(spec.before_expected, 1.0)
        self.assertIsNone(spec.setup_actor_aura)

    def test_whirling_tempest_stacks_with_courage_entry(self):
        spec = metric_delta_spec(whirling_tempest_stacks_with_courage_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, WHIRLING_TEMPEST)
        self.assertEqual(spec.setup_actor_aura, COURAGE_RANK_1)
        self.assertEqual(spec.expected, 1.32)
        self.assertEqual(spec.before_expected, 1.10)


class BehaviourEntriesLookupTests(unittest.TestCase):
    def test_behaviour_entries_filters_by_spell(self):
        chosen = behaviour_entries(CLASS_FILE, [SCARLET_JUDICATOR])
        self.assertEqual([entry['spell'] for entry in chosen], [SCARLET_JUDICATOR])

    def test_behaviour_entries_rejects_unknown_spell(self):
        with self.assertRaises(ValueError):
            behaviour_entries(CLASS_FILE, [1])

    def test_behaviour_entries_everything_by_default(self):
        self.assertEqual(len(behaviour_entries(CLASS_FILE, None)), 60)


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


class FixedTargetCountScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_fixtures(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        scenario, expectations = fixed_target_count_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 3)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_FIXED_COUNT)
        self.assertTrue(expectation.rule.startswith('prose: "and an additional nearby enemy'))
        self.assertEqual(len(expectation.model['dummy_labels']), 1)
        self.assertIsNotNone(expectation.model['far_label'])

    def test_far_dummy_sits_beyond_the_radius(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        scenario, _ = fixed_target_count_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        creatures_by_id = {c['id']: c for c in validated['creatures']}
        self.assertGreater(creatures_by_id['extra2']['distance'] - creatures_by_id['primary']['distance'],
                           spec.radius)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, holy_cleave_entry())
        self.assertEqual(len(run.validate(scenario)['creatures']), 3)
        self.assertEqual(expectations[0].check, BEHAVIOUR_FIXED_COUNT)

    def test_single_phase_has_no_before_measurement(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        scenario, _ = fixed_target_count_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('action') == 'assert' and step.get('metric') == spec.metric
                         and step.get('spell') == spec.target_rank]
        self.assertEqual(len(measure_steps), 3)

    def test_cast_spell_defaults_to_the_claim_spell(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        self.assertEqual(spec.cast_spell, HOLY_CLEAVE)
        self.assertEqual(spec.target_rank, HOLY_CLEAVE)

    def test_cast_spell_and_target_rank_can_be_overridden(self):
        entry = {**holy_cleave_entry(), 'cast_spell': 1, 'target_rank': 2}
        spec = fixed_target_count_spec(entry)
        self.assertEqual(spec.cast_spell, 1)
        self.assertEqual(spec.target_rank, 2)


class PartyStatRatioScenarioTests(unittest.TestCase):
    def test_raid_wide_scenario_has_one_ally_no_far_ally(self):
        spec = party_stat_ratio_spec(call_of_the_monastery_entry())
        scenario, expectations = party_stat_ratio_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['players']), 2)
        ally_ids = {p['id'] for p in validated['players']}
        self.assertEqual(ally_ids, {'caster', party_ally_id(0)})
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_PARTY_STAT_RATIO)
        self.assertTrue(expectation.rule.startswith('prose: "Increases the attack power'))
        self.assertIsNone(expectation.model['far_before_label'])
        self.assertEqual(expectation.model['expected'], 1.05)

    def test_radius_scenario_adds_a_second_far_ally_grouped_too(self):
        spec = party_stat_ratio_spec(fortified_body_entry())
        scenario, expectations = party_stat_ratio_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        ally_ids = {p['id'] for p in validated['players']}
        self.assertEqual(ally_ids, {'caster', party_ally_id(0), party_ally_id(1)})
        group_targets = {step['target'] for step in scenario['steps'] if step.get('action') == 'group'}
        self.assertEqual(group_targets, {party_ally_id(0), party_ally_id(1)})
        far_distance = sum(step['dx'] for step in scenario['steps']
                          if step.get('action') == 'relocate' and step.get('actor') == party_ally_id(1))
        self.assertGreater(far_distance, spec.radius)
        expectation = expectations[0]
        self.assertIsNotNone(expectation.model['far_before_label'])
        self.assertIsNotNone(expectation.model['far_after_label'])

    def test_needs_dummy_target_adds_a_creature_and_target_field(self):
        spec = party_stat_ratio_spec(serendipity_entry())
        self.assertTrue(spec.needs_dummy_target)
        scenario, _ = party_stat_ratio_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 1)
        measure_steps = [step for step in scenario['steps']
                         if step.get('action') == 'assert' and step.get('metric') == 'spell_damage_done']
        self.assertEqual(len(measure_steps), 2)
        for step in measure_steps:
            self.assertEqual(step['target'], 'primary')
            self.assertEqual(step['spell'], 572741)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, call_of_the_monastery_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_PARTY_STAT_RATIO)

    def test_before_measurement_precedes_the_learn_step(self):
        spec = party_stat_ratio_spec(call_of_the_monastery_entry())
        scenario, expectations = party_stat_ratio_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        before_index = next(index for index, step in enumerate(steps)
                            if step.get('label') == expectations[0].model['near_before_label'])
        learn_index = next(index for index, step in enumerate(steps)
                           if step.get('action') == 'learn' and step.get('spell') == spec.spell)
        after_index = next(index for index, step in enumerate(steps)
                           if step.get('label') == expectations[0].model['near_after_label'])
        self.assertLess(before_index, learn_index)
        self.assertLess(learn_index, after_index)

    def test_devotion_of_khazgoroth_reads_attack_time_ms_on_the_ally_only(self):
        spec = party_stat_ratio_spec(devotion_of_khazgoroth_entry())
        self.assertEqual(spec.metric, 'attack_time_ms')
        self.assertIsNone(spec.radius)
        self.assertAlmostEqual(spec.expected, 1.0 / 1.1, places=9)
        scenario, expectations = party_stat_ratio_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        ally_ids = {p['id'] for p in validated['players']}
        self.assertEqual(ally_ids, {'caster', party_ally_id(0)})
        measure_steps = [step for step in scenario['steps']
                         if step.get('action') == 'assert' and step.get('metric') == 'attack_time_ms']
        self.assertEqual(len(measure_steps), 2)
        for step in measure_steps:
            self.assertEqual(step['actor'], party_ally_id(0))
            self.assertNotIn('hand', step)
        self.assertEqual(expectations[0].displayed, str(spec.expected))


class AllyHealBreadthScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_fixtures(self):
        spec = ally_heal_breadth_spec(libram_of_grace_entry())
        scenario, expectations = ally_heal_breadth_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 1)
        ally_ids = {p['id'] for p in validated['players']} - {'caster'}
        self.assertEqual(ally_ids, {nearby_ally_id(0), nearby_ally_id(1)})
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_COUNT)
        self.assertTrue(expectation.rule.startswith('prose: "causing your damaging abilities to restore'))
        self.assertEqual(len(expectation.model['dummy_labels']), 2)

    def test_measures_spell_heal_count_on_each_ally_target(self):
        spec = ally_heal_breadth_spec(chakra_of_light_entry())
        scenario, _ = ally_heal_breadth_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('action') == 'assert' and step.get('metric') == 'spell_heal_count']
        self.assertEqual(len(measure_steps), 4)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')
            self.assertEqual(step['spell'], spec.heal_spell)
            self.assertIn(step['target'], (nearby_ally_id(0), nearby_ally_id(1)))

    def test_allies_are_grouped_with_the_caster(self):
        spec = ally_heal_breadth_spec(libram_of_grace_entry())
        scenario, _ = ally_heal_breadth_scenario(CLASS_FILE, spec)
        group_targets = {step['target'] for step in scenario['steps'] if step.get('action') == 'group'}
        self.assertEqual(group_targets, {nearby_ally_id(0), nearby_ally_id(1)})

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, chakra_of_light_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_COUNT)

    def test_before_measurement_precedes_the_passive_learn_which_precedes_after(self):
        spec = ally_heal_breadth_spec(libram_of_grace_entry())
        scenario, expectations = ally_heal_breadth_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        before_label, after_label = expectations[0].model['dummy_labels'][0]
        before_index = next(index for index, step in enumerate(steps) if step.get('label') == before_label)
        learn_index = next(index for index, step in enumerate(steps)
                           if step.get('action') == 'learn' and step.get('spell') == spec.spell)
        after_index = next(index for index, step in enumerate(steps) if step.get('label') == after_label)
        self.assertLess(before_index, learn_index)
        self.assertLess(learn_index, after_index)

    def test_trigger_spell_is_learned_before_the_first_cast(self):
        spec = ally_heal_breadth_spec(libram_of_grace_entry())
        scenario, _ = ally_heal_breadth_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        learn_index = next(index for index, step in enumerate(steps)
                           if step.get('action') == 'learn' and step.get('spell') == spec.trigger_spell)
        first_cast_index = next(index for index, step in enumerate(steps)
                                if step.get('action') == 'cast' and step.get('spell') == spec.trigger_spell)
        self.assertLess(learn_index, first_cast_index)


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
            self.assertEqual(step['metric'], 'spell_healing_taken')
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


class MechanicDurationScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectation(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        scenario, expectations = mechanic_duration_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 1)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_DURATION_RATIO)
        self.assertTrue(expectation.rule.startswith('prose: "reduces the duration of disarm effects against you '
                                                     'by"'))
        self.assertEqual(expectation.model['expected'], 0.85)
        self.assertEqual(expectation.rank_id, MELT_WEAPON)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, finesse_rank_1_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_DURATION_RATIO)

    def test_striker_casts_the_vehicle_spell_at_the_caster_up_to_land_attempts_times_per_phase(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        scenario, _ = mechanic_duration_scenario(CLASS_FILE, spec)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == MELT_WEAPON]
        self.assertEqual(len(cast_steps), 2 * MECHANIC_LAND_ATTEMPTS)
        for step in cast_steps:
            self.assertEqual(step['actor'], 'striker')
            self.assertEqual(step['target'], 'caster')

    def test_learn_happens_between_the_two_phases(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        scenario, _ = mechanic_duration_scenario(CLASS_FILE, spec)
        actions = [step.get('action') for step in scenario['steps'] if step.get('action') in ('cast', 'learn')]
        self.assertEqual(actions, ['cast'] * MECHANIC_LAND_ATTEMPTS + ['learn'] + ['cast'] * MECHANIC_LAND_ATTEMPTS)

    def test_each_phase_forces_the_caster_dodge_and_parry_to_zero_before_the_land_attempts(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        scenario, _ = mechanic_duration_scenario(CLASS_FILE, spec)
        avoidance_steps = [step for step in scenario['steps'] if step.get('action') == 'set_combat_avoidance']
        self.assertEqual(len(avoidance_steps), 2, 'one override per phase, since learn may recompute stats')
        for step in avoidance_steps:
            self.assertEqual(step['actor'], 'caster')
            self.assertEqual(step['dodge'], 0)
            self.assertEqual(step['parry'], 0)
        first_cast_indexes = []
        steps = scenario['steps']
        for index, step in enumerate(steps):
            if step.get('action') == 'cast' and step.get('spell') == MELT_WEAPON:
                first_cast_indexes.append(index)
        avoidance_indexes = [index for index, step in enumerate(steps) if step.get('action') == 'set_combat_avoidance']
        self.assertLess(avoidance_indexes[0], first_cast_indexes[0])
        self.assertLess(avoidance_indexes[1], first_cast_indexes[MECHANIC_LAND_ATTEMPTS])

    def test_measures_aura_duration_ms_of_the_vehicle_spell_before_and_after(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        scenario, expectations = mechanic_duration_scenario(CLASS_FILE, spec)
        model = expectations[0].model
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_duration_ms' and step.get('spell') == MELT_WEAPON]
        self.assertEqual(len(measure_steps), 2)
        self.assertEqual({step['label'] for step in measure_steps}, {model['before_label'], model['after_label']})
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')

    def test_striker_cannot_miss_the_vehicle_spell(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        scenario, _ = mechanic_duration_scenario(CLASS_FILE, spec)
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == 'striker')
        self.assertEqual(striker.get('spell_hit_bonus'), 100,
                         'a missed vehicle cast reads an absent aura as duration 0 on that phase, which is '
                         'indistinguishable from the vehicle spell actually missing nothing to do with the check')

    def test_gap_between_casts_clears_the_diminishing_returns_window(self):
        spec = mechanic_duration_spec(finesse_rank_1_entry())
        scenario, _ = mechanic_duration_scenario(CLASS_FILE, spec)
        waits = [step['ms'] for step in scenario['steps']
                if step.get('action') == 'wait' and 'DR window' in step.get('label', '')]
        self.assertEqual(len(waits), 1)
        self.assertGreaterEqual(waits[0], 6000 + 15000)

    def test_snare_vehicle_has_a_longer_gap_than_disarm(self):
        disarm_spec = mechanic_duration_spec(finesse_rank_1_entry())
        snare_spec = mechanic_duration_spec(courage_rank_1_entry())
        disarm_scenario, _ = mechanic_duration_scenario(CLASS_FILE, disarm_spec)
        snare_scenario, _ = mechanic_duration_scenario(CLASS_FILE, snare_spec)

        def gap(scenario):
            return next(step['ms'] for step in scenario['steps']
                       if step.get('action') == 'wait' and 'DR window' in step.get('label', ''))

        self.assertGreater(gap(snare_scenario), gap(disarm_scenario))


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

    def test_default_target_stays_caster_without_a_creature_fixture(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_HOPE]
        self.assertTrue(all(step['target'] == 'caster' for step in cast_steps))
        self.assertNotIn('creatures', scenario)

    def test_dummy_target_casts_at_the_creature_fixture_and_adds_it(self):
        spec = metric_delta_spec(warrior_of_tyr_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == CONDEMN]
        self.assertTrue(all(step['target'] == 'dummy' for step in cast_steps))
        self.assertEqual(len(scenario['creatures']), 1)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_dispatch_warrior_of_tyr_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, warrior_of_tyr_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 10)
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['metric'], 'power')

    def test_disable_regeneration_overrides_the_player_fixture(self):
        spec = metric_delta_spec(warrior_of_tyr_entry())
        self.assertTrue(spec.disable_regeneration)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['players'][0]['allow_regeneration'], False)

    def test_regeneration_stays_enabled_by_default(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        self.assertFalse(spec.disable_regeneration)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        self.assertNotIn('allow_regeneration', scenario['players'][0])

    def test_sacred_resistance_casts_reckoning_at_the_dummy_fixture(self):
        spec = metric_delta_spec(sacred_resistance_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == RECKONING_AT_60]
        self.assertEqual(len(cast_steps), 2)
        self.assertTrue(all(step['target'] == 'dummy' for step in cast_steps))
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_sacred_resistance_measures_the_reckoning_armor_aura(self):
        spec = metric_delta_spec(sacred_resistance_entry())
        scenario, expectations = metric_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura' and step.get('spell') == RECKONING_ARMOR]
        self.assertEqual(len(measure_steps), 2)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)

    def test_dispatch_sacred_resistance_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, sacred_resistance_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['metric'], 'aura')

    def test_label_suffix_disambiguates_a_second_metric_delta_check_on_the_same_spell(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        _, plain = metric_delta_scenario(CLASS_FILE, spec)
        _, suffixed = metric_delta_scenario(CLASS_FILE, replace(spec, label_suffix='owned_creature_count'))
        self.assertEqual(plain[0].label, f'{TYRS_GUARD} behaviour_metric_delta')
        self.assertEqual(suffixed[0].label, f'{TYRS_GUARD} behaviour_metric_delta owned_creature_count')

    def test_measure_actor_defaults_to_caster(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        self.assertEqual(spec.measure_actor, 'caster')

    def test_measure_actor_reads_the_metric_on_the_named_actor_instead_of_the_caster(self):
        spec = metric_delta_spec(patience_duration_entry())
        self.assertEqual(spec.measure_actor, 'dummy')
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_duration_ms' and step.get('spell') == INTERDICT]
        self.assertEqual(len(measure_steps), 2)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'dummy')
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_measure_actor_on_a_dummy_adds_the_creature_fixture_even_without_a_dummy_cast_target(self):
        spec = replace(metric_delta_spec(tyrs_guard_entry()), measure_actor='dummy')
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_dispatch_patience_duration_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, patience_duration_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'aura_duration_ms')
        self.assertEqual(expectations[0].model['tolerance'], 10)
        self.assertEqual(expectations[0].label, f'{PATIENCE} behaviour_metric_delta duration')

    def test_entries_without_an_explicit_tolerance_omit_it_from_the_model(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, tyrs_guard_entry())
        self.assertNotIn('tolerance', expectations[0].model)
        scenario, expectations = behaviour_scenario(CLASS_FILE, patience_cooldown_entry())
        self.assertNotIn('tolerance', expectations[0].model)

    def test_dispatch_patience_cooldown_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, patience_cooldown_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'cooldown_ms')
        self.assertEqual(expectations[0].label, f'{PATIENCE} behaviour_metric_delta cooldown')

    def test_chastise_weapon_damage_gate_learns_martial_training_only_between_phases(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, chastise_weapon_damage_gate_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'spell_effect_value')
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['expected'], 150)
        learn_steps = [step for step in scenario['steps']
                      if step.get('action') == 'learn' and step.get('spell') == MARTIAL_TRAINING]
        self.assertEqual(len(learn_steps), 1)
        before_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('label') == '503141 spell_effect_value before')
        after_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('label') == '503141 spell_effect_value after')
        learn_index = scenario['steps'].index(learn_steps[0])
        self.assertTrue(before_index < learn_index < after_index)

    def test_chastise_weapon_damage_gate_judges_a_wrong_after_value_as_alert(self):
        _, expectations = behaviour_scenario(CLASS_FILE, chastise_weapon_damage_gate_entry())
        expectation = expectations[0]
        correct = {'503141 spell_effect_value before': 0.0, '503141 spell_effect_value after': 150.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(correct), expectation).status, 'ok')
        seeded_wrong = {'503141 spell_effect_value before': 0.0, '503141 spell_effect_value after': 0.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(seeded_wrong), expectation).status,
                         'alert')

    def test_libram_of_tenacity_heal_gate_learns_tenacious_defender_only_between_phases(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, libram_of_tenacity_heal_gate_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'spell_effect_value')
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['expected'], 20)
        learn_steps = [step for step in scenario['steps']
                      if step.get('action') == 'learn' and step.get('spell') == TENACIOUS_DEFENDER]
        self.assertEqual(len(learn_steps), 1)
        before_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('label') == '801461 spell_effect_value before')
        after_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('label') == '801461 spell_effect_value after')
        learn_index = scenario['steps'].index(learn_steps[0])
        self.assertTrue(before_index < learn_index < after_index)

    def test_libram_of_tenacity_heal_gate_judges_a_wrong_after_value_as_alert(self):
        _, expectations = behaviour_scenario(CLASS_FILE, libram_of_tenacity_heal_gate_entry())
        expectation = expectations[0]
        correct = {'801461 spell_effect_value before': 0.0, '801461 spell_effect_value after': 20.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(correct), expectation).status, 'ok')
        seeded_wrong = {'801461 spell_effect_value before': 0.0, '801461 spell_effect_value after': 0.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(seeded_wrong), expectation).status,
                         'alert')

    def test_temple_guardian_charge_recharge_consumes_three_charges_then_brackets_the_recharge_window(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, temple_guardian_charge_recharge_entry())
        run.validate(scenario)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_CHARGE_RECHARGE)
        self.assertEqual(expectation.model['max_charges'], 3)
        self.assertEqual(expectation.model['recharge_ms'], 35000)
        self.assertEqual(len(expectation.model['attempt_labels']), 3)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == TEMPLE_GUARDIAN]
        self.assertEqual(len(cast_steps), 4)
        self.assertTrue(all(step.get('target') == 'ally' for step in cast_steps))
        group_steps = [step for step in scenario['steps'] if step.get('action') == 'group']
        self.assertEqual(len(group_steps), 1)
        self.assertEqual(scenario['players'][1]['id'], 'ally')
        recharge_wait_ms = [step['ms'] for step in scenario['steps']
                            if step.get('label') in ('up to the recharge window', 'through the recharge window')]
        elapsed_before_window_ms = 4 * cast_interval(CLASS_FILE, TEMPLE_GUARDIAN)
        self.assertEqual(sum(recharge_wait_ms), round(35000 * 1.05) - elapsed_before_window_ms)

    def test_temple_guardian_charge_recharge_judges_seeded_wrong_values_as_alert(self):
        _, expectations = behaviour_scenario(CLASS_FILE, temple_guardian_charge_recharge_entry())
        expectation = expectations[0]
        model = expectation.model
        correct = {model['initial_label']: 3.0, model['attempt_labels'][0]: 2.0, model['attempt_labels'][1]: 1.0,
                  model['attempt_labels'][2]: 0.0, model['overcast_label']: 0.0,
                  model['cast_failure_label']: 24.0, model['before_recharge_label']: 0.0,
                  model['after_recharge_label']: 1.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(correct), expectation).status, 'ok')
        seeded_wrong = {**correct, model['after_recharge_label']: 0.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(seeded_wrong), expectation).status,
                         'alert')

    def test_patience_casts_interdict_at_the_dummy_fixture_for_both_clauses(self):
        for entry in (patience_duration_entry(), patience_cooldown_entry()):
            spec = metric_delta_spec(entry)
            scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
            cast_steps = [step for step in scenario['steps']
                         if step.get('action') == 'cast' and step.get('spell') == INTERDICT]
            self.assertEqual(len(cast_steps), 2)
            self.assertTrue(all(step['target'] == 'dummy' for step in cast_steps))

    def test_the_two_patience_entries_share_a_spell_id_but_differ_by_variant(self):
        plain = patience_duration_entry()
        with_variant = patience_cooldown_entry()
        self.assertNotIn('variant', plain)
        self.assertEqual(with_variant.get('variant'), 'cooldown')
        self.assertNotEqual(plain['metric'], with_variant['metric'])

    def test_empty_setup_casts_reproduces_the_scenario_byte_for_byte(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        with_field, _ = metric_delta_scenario(CLASS_FILE, spec)
        without_field, _ = metric_delta_scenario(CLASS_FILE, replace(spec, setup_casts=()))
        self.assertEqual(with_field, without_field)

    def test_setup_casts_cast_blade_of_faith_at_the_dummy_before_each_divine_force_cast(self):
        spec = metric_delta_spec(transcending_strikes_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        steps = scenario['steps']
        setup_casts = [index for index, step in enumerate(steps)
                      if step.get('action') == 'cast' and step.get('spell') == BLADE_OF_FAITH]
        trigger_casts = [index for index, step in enumerate(steps)
                         if step.get('action') == 'cast' and step.get('spell') == DIVINE_FORCE]
        self.assertEqual(len(setup_casts), 2)
        self.assertEqual(len(trigger_casts), 2)
        self.assertTrue(all(step['target'] == 'dummy' for step in steps
                            if step.get('action') == 'cast' and step.get('spell') in (BLADE_OF_FAITH, DIVINE_FORCE)))
        for setup_index, trigger_index in zip(setup_casts, trigger_casts):
            self.assertLess(setup_index, trigger_index)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_setup_casts_learn_blade_of_faith_once_before_the_first_cast(self):
        spec = metric_delta_spec(transcending_strikes_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        learn_steps = [index for index, step in enumerate(scenario['steps'])
                      if step.get('action') == 'learn' and step.get('spell') == BLADE_OF_FAITH]
        first_cast_index = next(index for index, step in enumerate(scenario['steps'])
                                if step.get('action') == 'cast' and step.get('spell') == BLADE_OF_FAITH)
        self.assertEqual(len(learn_steps), 1)
        self.assertLess(learn_steps[0], first_cast_index)

    def test_setup_casts_restore_the_trigger_spells_own_power_before_its_cast(self):
        spec = metric_delta_spec(transcending_strikes_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        divine_force_index = steps.index({'action': 'cast', 'actor': 'caster', 'spell': DIVINE_FORCE,
                                          'target': 'dummy'})
        preceding_power = steps[divine_force_index - 1]
        self.assertEqual(preceding_power, {'action': 'set_power', 'actor': 'caster', 'power': 3, 'value': 15})

    def test_dispatch_transcending_strikes_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, transcending_strikes_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'cooldown_ms')

    def test_setup_actor_aura_defaults_to_no_extra_set_aura_steps(self):
        spec = metric_delta_spec(whirling_tempest_entry())
        self.assertIsNone(spec.setup_actor_aura)
        with_field, _ = metric_delta_scenario(CLASS_FILE, spec)
        without_field, _ = metric_delta_scenario(CLASS_FILE, replace(spec, setup_actor_aura=None))
        self.assertEqual(with_field, without_field)
        set_aura_spells = {step['spell'] for step in with_field['steps'] if step.get('action') == 'set_aura'}
        self.assertNotIn(COURAGE_RANK_1, set_aura_spells)

    def test_setup_actor_aura_applies_courage_before_each_phase_cast(self):
        spec = metric_delta_spec(whirling_tempest_stacks_with_courage_entry())
        self.assertEqual(spec.setup_actor_aura, COURAGE_RANK_1)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        steps = scenario['steps']
        set_aura_steps = [index for index, step in enumerate(steps)
                         if step.get('action') == 'set_aura' and step.get('spell') == COURAGE_RANK_1]
        cast_steps = [index for index, step in enumerate(steps)
                     if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_TEMPEST]
        self.assertEqual(len(set_aura_steps), 2)
        self.assertEqual(len(cast_steps), 2)
        self.assertEqual(steps[set_aura_steps[0]]['stacks'], 1)
        self.assertLess(set_aura_steps[0], cast_steps[0])
        self.assertLess(set_aura_steps[1], cast_steps[1])

    def test_whirling_tempest_waits_500ms_not_the_default_3000ms(self):
        spec = metric_delta_spec(whirling_tempest_entry())
        self.assertEqual(spec.wait_ms, 500)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        wait_steps = [step for step in scenario['steps']
                     if step.get('action') == 'wait' and step.get('ms') == 500 and 'label' not in step]
        self.assertTrue(wait_steps)

    def test_dispatch_whirling_tempest_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, whirling_tempest_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1.20)
        self.assertEqual(expectations[0].model['before_expected'], 1.0)
        self.assertEqual(expectations[0].model['metric'], 'run_speed_rate')

    def test_dispatch_whirling_tempest_stacks_with_courage_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, whirling_tempest_stacks_with_courage_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1.32)
        self.assertEqual(expectations[0].model['before_expected'], 1.10)
        self.assertEqual(expectations[0].model['metric'], 'run_speed_rate')

    def test_dispatch_sanctify_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, sanctify_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 2272.727294921875)
        self.assertEqual(expectations[0].model['before_expected'], 2500.0)
        self.assertEqual(expectations[0].model['metric'], 'attack_time_ms')

    def test_sanctify_casts_libram_of_tenacity_at_self_in_both_phases(self):
        spec = metric_delta_spec(sanctify_entry())
        self.assertEqual(spec.trigger_spell, LIBRAM_OF_TENACITY)
        self.assertEqual(spec.target, 'caster')
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == LIBRAM_OF_TENACITY]
        self.assertEqual(len(cast_steps), 2)

    def test_dispatch_transcending_strikes_target_gate_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, transcending_strikes_target_gate_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 86994)
        self.assertEqual(expectations[0].model['before_expected'], 116994)
        self.assertEqual(expectations[0].model['metric'], 'cooldown_ms')
        self.assertTrue(expectations[0].label.endswith('target_gate'))

    def test_transcending_strikes_target_gate_withholds_blade_of_faith_in_the_first_phase_only(self):
        spec = metric_delta_spec(transcending_strikes_target_gate_entry())
        self.assertTrue(spec.setup_only_after)
        self.assertEqual(spec.setup_casts, (BLADE_OF_FAITH,))
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        steps = scenario['steps']
        divine_force_indices = [index for index, step in enumerate(steps)
                                if step.get('action') == 'cast' and step.get('spell') == DIVINE_FORCE]
        blade_of_faith_indices = [index for index, step in enumerate(steps)
                                  if step.get('action') == 'cast' and step.get('spell') == BLADE_OF_FAITH]
        self.assertEqual(len(divine_force_indices), 2)
        self.assertEqual(len(blade_of_faith_indices), 1)
        self.assertLess(blade_of_faith_indices[0], divine_force_indices[1])
        self.assertGreater(blade_of_faith_indices[0], divine_force_indices[0])
        learn_gate_indices = [index for index, step in enumerate(steps)
                             if step.get('action') == 'learn' and step.get('spell') == TRANSCENDING_STRIKES]
        self.assertEqual(len(learn_gate_indices), 1)
        self.assertLess(learn_gate_indices[0], divine_force_indices[0])

    def test_metric_delta_setup_only_after_without_setup_casts_is_rejected(self):
        entry = dict(transcending_strikes_target_gate_entry())
        entry['setup_casts'] = []
        with self.assertRaises(ValueError):
            metric_delta_scenario(CLASS_FILE, metric_delta_spec(entry))

    def test_dispatch_chakra_of_power_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, chakra_of_power_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_CRIT_MAGNITUDE)
        self.assertEqual(expectations[0].model['base_expected'], 1.0)
        self.assertEqual(expectations[0].model['crit_bonus_expected'], 2.0)
        self.assertEqual(expectations[0].model['metric'], 'spell_energize_total')

    def test_chakra_of_power_forces_melee_crit_and_attacks_the_dummy(self):
        spec = crit_magnitude_spec(chakra_of_power_entry())
        self.assertEqual(spec.observe_spell, CHAKRA_OF_POWER_ENERGIZE)
        self.assertEqual(spec.force_crit, 'melee')
        scenario, _ = crit_magnitude_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)
        attack_steps = [step for step in scenario['steps'] if step.get('action') == 'attack']
        self.assertEqual(len(attack_steps), 1)
        self.assertEqual(attack_steps[0]['target'], 'dummy')

    def test_chakra_of_power_measures_attempts_crits_and_total_energize(self):
        spec = crit_magnitude_spec(chakra_of_power_entry())
        _, expectations = crit_magnitude_scenario(CLASS_FILE, spec)
        model = expectations[0].model
        self.assertEqual(model['attempts_label'], '803158 804181 crit_magnitude attempts')
        self.assertEqual(model['crits_label'], '803158 804181 crit_magnitude crits')
        self.assertEqual(model['total_label'], '803158 804181 crit_magnitude total')

    def test_crit_magnitude_rejects_an_unknown_metric(self):
        spec = replace(crit_magnitude_spec(chakra_of_power_entry()), metric='spell_damage_total')
        with self.assertRaises(ValueError):
            crit_magnitude_scenario(CLASS_FILE, spec)

    def test_the_two_whirling_tempest_entries_share_a_spell_id_but_differ_by_variant(self):
        plain = whirling_tempest_entry()
        stacking = whirling_tempest_stacks_with_courage_entry()
        self.assertEqual(plain['spell'], stacking['spell'])
        self.assertNotEqual(plain.get('variant'), stacking.get('variant', ''))

    def test_keeping_the_oath_passive_casts_reckoning_at_the_dummy_fixture(self):
        spec = metric_delta_spec(keeping_the_oath_passive_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == RECKONING_AT_60]
        self.assertEqual(len(cast_steps), 2)
        self.assertTrue(all(step['target'] == 'dummy' for step in cast_steps))

    def test_keeping_the_oath_passive_measures_the_oath_chain_aura(self):
        spec = metric_delta_spec(keeping_the_oath_passive_entry())
        scenario, expectations = metric_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura' and step.get('spell') == OATH_CHAIN]
        self.assertEqual(len(measure_steps), 2)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)

    def test_dispatch_keeping_the_oath_passive_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, keeping_the_oath_passive_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['metric'], 'aura')


TEMPLAR_CLASS_ID = 19


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GenerateBehaviourVariantTest(unittest.TestCase):
    def setUp(self):
        self.out = Path(tempfile.mkdtemp(prefix='conformance-behaviour-variant-'))

    def tearDown(self):
        shutil.rmtree(self.out)

    def test_two_behaviour_entries_sharing_a_spell_id_get_distinct_manifest_keys(self):
        from conformance import generate
        manifest = json.loads(
            generate(TEMPLAR_CLASS_ID, self.out, behaviours=[WHIRLING_TEMPEST]).read_text(encoding='utf-8'))
        entries = [entry for entry in manifest['scenarios'] if entry['spell_id'] == WHIRLING_TEMPEST]
        self.assertEqual(len(entries), 2)
        self.assertEqual(len({entry['key'] for entry in entries}), 2)

    def test_the_plain_entry_keeps_its_pre_variant_key(self):
        from conformance import scenario_key
        self.assertEqual(scenario_key('Templar', 'behaviour', WHIRLING_TEMPEST, ''),
                         scenario_key('Templar', 'behaviour', WHIRLING_TEMPEST))


class DurationRefreshScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectation(self):
        spec = duration_refresh_spec(blessing_of_aggramar_entry())
        scenario, expectations = duration_refresh_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_DURATION_REFRESH)
        self.assertTrue(expectation.rule.startswith('prose: "now refreshes the duration of Blade of Faith'))
        self.assertEqual(expectation.rank_id, BLADE_OF_FAITH)
        self.assertEqual(expectation.model['full_duration_ms'], 30000.0)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, blessing_of_aggramar_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_DURATION_REFRESH)

    def test_without_phase_comes_before_the_learn_which_comes_before_the_with_phase(self):
        spec = duration_refresh_spec(blessing_of_aggramar_entry())
        scenario, _ = duration_refresh_scenario(CLASS_FILE, spec)
        learn_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('action') == 'learn' and step.get('spell') == BLESSING_OF_AGGRAMAR)
        breaker_casts = [index for index, step in enumerate(scenario['steps'])
                        if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_UPHEAVAL]
        self.assertEqual(len(breaker_casts), 2)
        self.assertLess(breaker_casts[0], learn_index)
        self.assertLess(learn_index, breaker_casts[1])

    def test_gating_stacks_are_set_before_each_breaker_cast(self):
        spec = duration_refresh_spec(blessing_of_aggramar_entry())
        scenario, _ = duration_refresh_scenario(CLASS_FILE, spec)
        breaker_casts = [index for index, step in enumerate(scenario['steps'])
                        if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_UPHEAVAL]
        for index in breaker_casts:
            preceding = [step for step in scenario['steps'][:index]
                        if step.get('action') == 'set_aura' and step.get('spell') == OATH_CHAIN]
            self.assertEqual(preceding[-1]['stacks'], spec.gating_stacks)

    def test_measures_aura_duration_ms_of_the_target_aura_four_times(self):
        spec = duration_refresh_spec(blessing_of_aggramar_entry())
        scenario, _ = duration_refresh_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_duration_ms' and step.get('spell') == BLADE_OF_FAITH]
        self.assertEqual(len(measure_steps), 4)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'dummy')
            self.assertEqual(step['caster'], 'caster')

    def test_arms_the_weapon_the_breaker_spell_needs(self):
        spec = duration_refresh_spec(blessing_of_aggramar_entry())
        scenario, _ = duration_refresh_scenario(CLASS_FILE, spec)
        equip_step = next(step for step in scenario['steps'] if step.get('action') == 'equip')
        self.assertEqual(equip_step['item'], CLASS_FILE['alternate_weapons'][0]['item'])
        self.assertNotEqual(equip_step['item'], CLASS_FILE['weapon']['item'])


class AmountDeltaScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectation(self):
        spec = amount_delta_spec(holy_books_entry())
        scenario, expectations = amount_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_AMOUNT_DELTA)
        self.assertTrue(expectation.rule.startswith('prose: "Using a Libram now removes"'))
        self.assertEqual(expectation.rank_id, OATHKEEPER)
        self.assertEqual(expectation.model['fraction'], 0.70)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, holy_books_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_AMOUNT_DELTA)

    def test_without_phase_comes_before_the_learn_which_comes_before_the_with_phase(self):
        spec = amount_delta_spec(holy_books_entry())
        scenario, _ = amount_delta_scenario(CLASS_FILE, spec)
        learn_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('action') == 'learn' and step.get('spell') == HOLY_BOOKS)
        trigger_casts = [index for index, step in enumerate(scenario['steps'])
                        if step.get('action') == 'cast' and step.get('spell') == LIBRAM_OF_CONSECRATION
                        and step.get('actor') == 'caster']
        self.assertEqual(len(trigger_casts), 2)
        self.assertLess(trigger_casts[0], learn_index)
        self.assertLess(learn_index, trigger_casts[1])

    def test_each_phase_re_establishes_its_own_debt_from_a_fresh_striker_hit(self):
        spec = amount_delta_spec(holy_books_entry())
        scenario, _ = amount_delta_scenario(CLASS_FILE, spec)
        breaker_casts = [index for index, step in enumerate(scenario['steps'])
                        if step.get('action') == 'cast' and step.get('spell') == SMITE
                        and step.get('actor') == 'striker']
        self.assertEqual(len(breaker_casts), 2)
        set_aura_steps = [step for step in scenario['steps']
                         if step.get('action') == 'set_aura' and step.get('spell') == KEEPING_THE_OATH]
        self.assertEqual(len(set_aura_steps), 2)

    def test_measures_aura_amount_of_the_target_aura_effect_0_four_times(self):
        spec = amount_delta_spec(holy_books_entry())
        scenario, _ = amount_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_amount' and step.get('spell') == OATHKEEPER
                         and 'max' in step]
        self.assertEqual(len(measure_steps), 4)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')
            self.assertEqual(step['effect'], 0)

    def test_asserts_a_nonzero_debt_before_measuring_each_before_label(self):
        spec = amount_delta_spec(holy_books_entry())
        scenario, _ = amount_delta_scenario(CLASS_FILE, spec)
        debt_asserts = [step for step in scenario['steps']
                       if step.get('action') == 'assert' and step.get('metric') == 'aura_amount'
                       and step.get('spell') == OATHKEEPER and step.get('min') == 1]
        self.assertEqual(len(debt_asserts), 2)
        for debt_assert in debt_asserts:
            self.assertNotIn('max', debt_assert)

    def test_striker_is_forced_to_hit(self):
        spec = amount_delta_spec(holy_books_entry())
        scenario, _ = amount_delta_scenario(CLASS_FILE, spec)
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == 'striker')
        self.assertEqual(striker.get('spell_hit_bonus'), 100)


class ExclusivityChainScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectations(self):
        spec = exclusivity_chain_spec(libram_exclusivity_entry())
        scenario, expectations = exclusivity_chain_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 5)
        for expectation in expectations:
            self.assertEqual(expectation.check, BEHAVIOUR_EXCLUSIVITY)
            self.assertTrue(expectation.rule.startswith(
                'prose: "Only 1 Libram spell can be active at a time."'))

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, libram_exclusivity_entry())
        run.validate(scenario)
        self.assertEqual(len(expectations), 5)
        self.assertEqual(expectations[0].check, BEHAVIOUR_EXCLUSIVITY)

    def test_chain_wraps_back_to_the_first_member(self):
        spec = exclusivity_chain_spec(libram_exclusivity_entry())
        _, expectations = exclusivity_chain_scenario(CLASS_FILE, spec)
        removed_spells = [expectation.model['removed_spell'] for expectation in expectations]
        self.assertEqual(removed_spells, [LIBRAM_OF_CONSECRATION, LIBRAM_OF_TENACITY, LIBRAM_OF_GRACE,
                                          LIBRAM_OF_ZEAL, LIBRAM_OF_FERVOR])
        kept_spells = [expectation.model['kept_spell'] for expectation in expectations]
        self.assertEqual(kept_spells, [LIBRAM_OF_TENACITY, LIBRAM_OF_GRACE, LIBRAM_OF_ZEAL, LIBRAM_OF_FERVOR,
                                       LIBRAM_OF_CONSECRATION])

    def test_each_cast_resets_its_own_cooldown_first(self):
        spec = exclusivity_chain_spec(libram_exclusivity_entry())
        scenario, _ = exclusivity_chain_scenario(CLASS_FILE, spec)
        for spell in spec.chain:
            resets = [index for index, step in enumerate(scenario['steps'])
                     if step.get('action') == 'reset_cooldown' and step.get('spell') == spell]
            casts = [index for index, step in enumerate(scenario['steps'])
                    if step.get('action') == 'cast' and step.get('spell') == spell]
            self.assertTrue(resets)
            self.assertTrue(casts)
            self.assertLess(resets[0], casts[0])

    def test_measures_aura_presence_on_the_removed_and_kept_spell_after_each_cast(self):
        spec = exclusivity_chain_spec(libram_exclusivity_entry())
        scenario, expectations = exclusivity_chain_scenario(CLASS_FILE, spec)
        for expectation in expectations:
            labels = {step['label'] for step in scenario['steps'] if step.get('action') == 'assert'}
            self.assertIn(expectation.model['removed_label'], labels)
            self.assertIn(expectation.model['kept_label'], labels)

    def test_chain_of_fewer_than_two_spells_is_rejected(self):
        entry = dict(libram_exclusivity_entry())
        entry['chain'] = [LIBRAM_OF_CONSECRATION]
        with self.assertRaises(ValueError):
            exclusivity_chain_scenario(CLASS_FILE, exclusivity_chain_spec(entry))


class GroupStackCapScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectation(self):
        spec = group_stack_cap_spec(serendipity_group_stack_cap_entry())
        scenario, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_GROUP_STACK_CAP)
        self.assertEqual(expectation.spell_id, SERENDIPITY)
        self.assertEqual(expectation.rank_id, RUNIC_POWER)
        self.assertTrue(expectation.rule.startswith('prose: "Does not stack with similar effects."'))

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, serendipity_group_stack_cap_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_GROUP_STACK_CAP)

    def test_own_pct_and_partner_pct_are_read_from_the_dbc(self):
        spec = group_stack_cap_spec(serendipity_group_stack_cap_entry())
        _, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        records = Records(dataset(DBC_DIR))
        own_pct = records.single_value(SERENDIPITY, 0)
        partner_pct = records.single_value(RUNIC_POWER, 0)
        self.assertEqual(expectations[0].model['own_pct'], own_pct)
        self.assertEqual(expectations[0].model['partner_pct'], partner_pct)
        self.assertEqual(float(expectations[0].displayed), max(own_pct, partner_pct))

    def test_baseline_measured_before_either_spell_is_learned(self):
        spec = group_stack_cap_spec(serendipity_group_stack_cap_entry())
        scenario, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        baseline_index = next(index for index, step in enumerate(scenario['steps'])
                             if step.get('action') == 'assert'
                             and step.get('label') == expectations[0].model['baseline_label'])
        learn_indices = [index for index, step in enumerate(scenario['steps'])
                        if step.get('action') == 'learn']
        self.assertTrue(all(baseline_index < index for index in learn_indices))

    def test_own_measured_after_learning_own_but_before_the_partner(self):
        spec = group_stack_cap_spec(serendipity_group_stack_cap_entry())
        scenario, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        own_learn_index = next(index for index, step in enumerate(scenario['steps'])
                              if step.get('action') == 'learn' and step.get('spell') == SERENDIPITY)
        own_label_index = next(index for index, step in enumerate(scenario['steps'])
                              if step.get('action') == 'assert'
                              and step.get('label') == expectations[0].model['own_label'])
        partner_learn_index = next(index for index, step in enumerate(scenario['steps'])
                                  if step.get('action') == 'learn' and step.get('spell') == RUNIC_POWER)
        self.assertLess(own_learn_index, own_label_index)
        self.assertLess(own_label_index, partner_learn_index)

    def test_combined_measured_after_learning_the_partner(self):
        spec = group_stack_cap_spec(serendipity_group_stack_cap_entry())
        scenario, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        partner_learn_index = next(index for index, step in enumerate(scenario['steps'])
                                  if step.get('action') == 'learn' and step.get('spell') == RUNIC_POWER)
        combined_label_index = next(index for index, step in enumerate(scenario['steps'])
                                   if step.get('action') == 'assert'
                                   and step.get('label') == expectations[0].model['combined_label'])
        self.assertLess(partner_learn_index, combined_label_index)

    def test_attack_power_entry_uses_the_attack_power_metric_with_no_target(self):
        spec = group_stack_cap_spec(call_of_the_monastery_group_stack_cap_entry())
        self.assertEqual(spec.metric, 'attack_power')
        self.assertEqual(spec.fields, {})
        scenario, _ = group_stack_cap_scenario(CLASS_FILE, spec)
        self.assertNotIn('creatures', scenario)

    def test_spell_damage_entry_adds_a_creature_fixture_for_its_target_field(self):
        spec = group_stack_cap_spec(serendipity_group_stack_cap_entry())
        self.assertEqual(spec.metric, 'spell_damage_done')
        self.assertEqual(spec.fields, {'target': 'dummy', 'spell': 133})
        scenario, _ = group_stack_cap_scenario(CLASS_FILE, spec)
        self.assertIn('creatures', scenario)
        self.assertGreaterEqual(len(scenario['creatures']), 1)

    def test_mechanism_defaults_to_spell_group_for_entries_that_do_not_set_it(self):
        spec = group_stack_cap_spec(serendipity_group_stack_cap_entry())
        self.assertEqual(spec.mechanism, 'spell_group')
        _, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        self.assertEqual(expectations[0].model['mechanism'], 'spell_group')

    def test_aura_cap_entry_is_a_healing_taken_self_query_with_no_creature_fixture(self):
        spec = group_stack_cap_spec(fortified_body_group_stack_cap_entry())
        self.assertEqual(spec.mechanism, 'aura_cap')
        self.assertEqual(spec.metric, 'spell_healing_taken')
        self.assertEqual(spec.fields, {'spell': BENEDICTION, 'target': 'caster'})
        scenario, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertNotIn('creatures', scenario)
        self.assertEqual(expectations[0].model['mechanism'], 'aura_cap')

    def test_an_unknown_mechanism_raises_rather_than_silently_mislabel_the_contract(self):
        entry = dict(fortified_body_group_stack_cap_entry())
        entry['mechanism'] = 'not_a_real_mechanism'
        spec = group_stack_cap_spec(entry)
        with self.assertRaises(KeyError):
            group_stack_cap_scenario(CLASS_FILE, spec)


class SingleTargetScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectation(self):
        spec = single_target_spec(righteous_custodian_single_target_entry())
        scenario, expectations = single_target_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_SINGLE_TARGET)
        self.assertEqual(expectation.spell_id, RIGHTEOUS_CUSTODIAN)
        self.assertEqual(expectation.rank_id, RIGHTEOUS_CUSTODIAN)
        self.assertTrue(expectation.rule.startswith('prose: "Can only be placed on 1 target at a time."'))

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, righteous_custodian_single_target_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_SINGLE_TARGET)

    def test_scenario_fixtures_two_grouped_allies_alongside_the_caster(self):
        spec = single_target_spec(righteous_custodian_single_target_entry())
        scenario, _ = single_target_scenario(CLASS_FILE, spec)
        ids = {player['id'] for player in scenario['players']}
        self.assertEqual(ids, {'caster', 'ally', 'ally2'})
        groups = [step for step in scenario['steps'] if step.get('action') == 'group']
        self.assertEqual([step['target'] for step in groups], ['ally', 'ally2'])

    def test_first_ally_measured_after_the_first_cast_and_before_the_second(self):
        spec = single_target_spec(righteous_custodian_single_target_entry())
        scenario, expectations = single_target_scenario(CLASS_FILE, spec)
        casts = [index for index, step in enumerate(scenario['steps']) if step.get('action') == 'cast']
        first_label_index = next(index for index, step in enumerate(scenario['steps'])
                                if step.get('action') == 'assert'
                                and step.get('label') == expectations[0].model['first_label'])
        self.assertEqual(len(casts), 2)
        self.assertLess(casts[0], first_label_index)
        self.assertLess(first_label_index, casts[1])

    def test_removed_and_second_measured_after_the_second_cast(self):
        spec = single_target_spec(righteous_custodian_single_target_entry())
        scenario, expectations = single_target_scenario(CLASS_FILE, spec)
        casts = [index for index, step in enumerate(scenario['steps']) if step.get('action') == 'cast']
        removed_label_index = next(index for index, step in enumerate(scenario['steps'])
                                  if step.get('action') == 'assert'
                                  and step.get('label') == expectations[0].model['removed_label'])
        second_label_index = next(index for index, step in enumerate(scenario['steps'])
                                 if step.get('action') == 'assert'
                                 and step.get('label') == expectations[0].model['second_label'])
        self.assertLess(casts[1], removed_label_index)
        self.assertLess(casts[1], second_label_index)

    def test_each_cast_resets_the_spell_cooldown_first(self):
        spec = single_target_spec(righteous_custodian_single_target_entry())
        scenario, _ = single_target_scenario(CLASS_FILE, spec)
        resets = [index for index, step in enumerate(scenario['steps'])
                 if step.get('action') == 'reset_cooldown' and step.get('spell') == spec.spell]
        casts = [index for index, step in enumerate(scenario['steps'])
                if step.get('action') == 'cast' and step.get('spell') == spec.spell]
        self.assertEqual(len(resets), 2)
        self.assertEqual(len(casts), 2)
        self.assertLess(resets[0], casts[0])
        self.assertLess(resets[1], casts[1])

    def test_first_cast_targets_ally_and_second_targets_ally2(self):
        spec = single_target_spec(righteous_custodian_single_target_entry())
        scenario, _ = single_target_scenario(CLASS_FILE, spec)
        casts = [step for step in scenario['steps'] if step.get('action') == 'cast']
        self.assertEqual([step['target'] for step in casts], ['ally', 'ally2'])

    def test_second_cast_waits_out_the_global_cooldown_from_the_first(self):
        spec = single_target_spec(righteous_custodian_single_target_entry())
        scenario, _ = single_target_scenario(CLASS_FILE, spec)
        casts = [index for index, step in enumerate(scenario['steps']) if step.get('action') == 'cast']
        gcd_waits = [index for index, step in enumerate(scenario['steps'])
                    if step.get('action') == 'wait' and step.get('label') == 'Global cooldown'
                    and step.get('ms') >= 1500]
        self.assertTrue(gcd_waits)
        self.assertLess(casts[0], gcd_waits[0])
        self.assertLess(gcd_waits[0], casts[1])


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


class JudgeAllyHealBreadthTests(unittest.TestCase):
    def expectation(self):
        spec = ally_heal_breadth_spec(libram_of_grace_entry())
        _, expectations = ally_heal_breadth_scenario(CLASS_FILE, spec)
        return expectations[0]

    def test_both_allies_healed_after_the_learn_is_ok(self):
        expectation = self.expectation()
        (b0, a0), (b1, a1) = expectation.model['dummy_labels']
        values = {b0: 0.0, a0: 1.0, b1: 0.0, a1: 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_seeded_zero_healed_allies_against_expected_two_is_alert(self):
        expectation = self.expectation()
        (b0, a0), (b1, a1) = expectation.model['dummy_labels']
        values = {b0: 0.0, a0: 0.0, b1: 0.0, a1: 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.expected, 2.0)

    def test_only_one_of_two_allies_healed_is_ok_within_the_shared_tolerance_floor(self):
        expectation = self.expectation()
        (b0, a0), (b1, a1) = expectation.model['dummy_labels']
        values = {b0: 0.0, a0: 1.0, b1: 0.0, a1: 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')


class JudgeFixedTargetCountTests(unittest.TestCase):
    def expectation(self, expected=1, far_label='far'):
        model = {'kind': 'fixed_count', 'expected': expected, 'quote': 'and an additional nearby enemy',
                 'dummy_labels': ['a1'], 'far_label': far_label}
        return Expectation('label', BEHAVIOUR_FIXED_COUNT, HOLY_CLEAVE, HOLY_CLEAVE, None, '1',
                           'prose: "and an additional nearby enemy" (573049)', model)

    def test_measured_count_matches_expected_and_far_dummy_unhit_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0, 'far': 0.0}), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 1.0)

    def test_seeded_zero_hit_against_a_nonzero_expectation_fails(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 0.0, 'far': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.expected, 1.0)

    def test_seeded_far_dummy_hit_fails_even_though_the_near_count_matches(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0, 'far': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('beyond-radius dummy hit count 1', verdict.explanation)

    def test_missing_far_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('far', verdict.explanation)

    def test_no_far_label_skips_the_radius_check(self):
        expectation = self.expectation(far_label=None)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('a1', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


class JudgePartyStatRatioTests(unittest.TestCase):
    def expectation(self, expected=1.05, radius=None):
        model = {'kind': 'party_stat_ratio', 'expected': expected, 'metric': 'attack_power',
                 'near_before_label': 'nb', 'near_after_label': 'na',
                 'far_before_label': 'fb' if radius is not None else None,
                 'far_after_label': 'fa' if radius is not None else None,
                 'quote': 'Increases the attack power of all party and raid members $s1%.'}
        return Expectation('label', BEHAVIOUR_PARTY_STAT_RATIO, CALL_OF_THE_MONASTERY, CALL_OF_THE_MONASTERY, None,
                           '1.05', 'prose: "Increases the attack power of all party and raid members $s1%." '
                           '(560550)', model)

    def test_near_ratio_matching_expected_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'nb': 300.0, 'na': 315.0}), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 1.05)

    def test_seeded_wrong_ratio_fails(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'nb': 300.0, 'na': 300.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 1.0)

    def test_far_ally_unchanged_is_ok(self):
        expectation = self.expectation(radius=40.0)
        values = {'nb': 300.0, 'na': 315.0, 'fb': 300.0, 'fa': 300.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_far_ally_also_changing_is_an_alert(self):
        expectation = self.expectation(radius=40.0)
        values = {'nb': 300.0, 'na': 315.0, 'fb': 300.0, 'fa': 315.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'nb': 300.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('na', verdict.explanation)

    def test_zero_baseline_is_unmeasured(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'nb': 0.0, 'na': 0.0}), expectation)
        self.assertEqual(verdict.status, 'unmeasured')

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

    def test_run_speed_rate_tolerates_float32_round_trip_noise(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 1.32,
                 'before_expected': 1.10, 'metric': 'run_speed_rate', 'quote': 'stacks with Courage'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, WHIRLING_TEMPEST, RIGHTEOUS_TEMPEST, None,
                                  '1.32', 'prose: "stacks with Courage" (300504)', model)
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'before': 1.1000000238418579, 'after': 1.3200000524520874}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_run_speed_rate_still_alerts_on_the_pre_fix_non_stacking_reading(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 1.32,
                 'before_expected': 1.10, 'metric': 'run_speed_rate', 'quote': 'stacks with Courage'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, WHIRLING_TEMPEST, RIGHTEOUS_TEMPEST, None,
                                  '1.32', 'prose: "stacks with Courage" (300504)', model)
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'before': 1.1000000238418579, 'after': 1.2000000476837158}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_attack_time_ms_haste_matches_the_exact_float32_division(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after',
                 'expected': 2272.727294921875, 'before_expected': 2500.0, 'metric': 'attack_time_ms',
                 'quote': 'now grant you $705275s1% increased melee haste'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, SANCTIFY, LIBRAM_OF_TENACITY, None,
                                  '2272.727294921875',
                                  'prose: "now grant you $705275s1% increased melee haste" (705274)', model)
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'before': 2500.0, 'after': 2272.727294921875}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_seeded_wrong_haste_reading_is_alert(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after',
                 'expected': 2272.727294921875, 'before_expected': 2500.0, 'metric': 'attack_time_ms',
                 'quote': 'now grant you $705275s1% increased melee haste'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, SANCTIFY, LIBRAM_OF_TENACITY, None,
                                  '2272.727294921875',
                                  'prose: "now grant you $705275s1% increased melee haste" (705274)', model)
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'before': 2500.0, 'after': 2250.0}), expectation)
        self.assertEqual(verdict.status, 'alert')


    def test_transcending_strikes_target_gate_matches_the_exact_cooldown_readings(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 86994,
                 'before_expected': 116994, 'metric': 'cooldown_ms',
                 'quote': 'when used on enemies affected by Blade of Faith'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, TRANSCENDING_STRIKES, DIVINE_FORCE, None,
                                  '86994', 'prose: "when used on enemies affected by Blade of Faith" (804897)',
                                  model)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 116994.0, 'after': 86994.0}),
                                 expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_seeded_wrong_target_gate_reading_without_the_debuff_gate_is_alert(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 86994,
                 'before_expected': 116994, 'metric': 'cooldown_ms',
                 'quote': 'when used on enemies affected by Blade of Faith'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, TRANSCENDING_STRIKES, DIVINE_FORCE, None,
                                  '86994', 'prose: "when used on enemies affected by Blade of Faith" (804897)',
                                  model)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 86994.0, 'after': 86994.0}),
                                 expectation)
        self.assertEqual(verdict.status, 'alert')


class JudgeCritMagnitudeTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'crit_magnitude', 'attempts_label': 'attempts', 'crits_label': 'crits',
                 'total_label': 'total', 'base_expected': 1.0, 'crit_bonus_expected': 2.0,
                 'metric': 'spell_energize_total',
                 'quote': 'an additional 2 Energy when they critically strike'}
        return Expectation('label', BEHAVIOUR_CRIT_MAGNITUDE, CHAKRA_OF_POWER, CHAKRA_OF_POWER_ENERGIZE, None, '3.0',
                           'prose: "an additional 2 Energy when they critically strike" (803158)', model)

    def test_all_crits_matches_base_plus_bonus_times_attempts(self):
        expectation = self.expectation()
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'attempts': 10.0, 'crits': 10.0, 'total': 30.0}), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 30.0)
        self.assertEqual(verdict.expected, 30.0)

    def test_a_few_missed_crits_still_matches_the_measured_crit_count(self):
        expectation = self.expectation()
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'attempts': 10.0, 'crits': 8.0, 'total': 26.0}), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.expected, 26.0)

    def test_a_seeded_wrong_total_missing_the_crit_bonus_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'attempts': 10.0, 'crits': 10.0, 'total': 10.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 10.0)
        self.assertEqual(verdict.expected, 30.0)

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'attempts': 10.0, 'crits': 10.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('total', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


class JudgePatienceMetricDeltaTests(unittest.TestCase):
    def test_patience_duration_matches_the_scripted_plus_2000ms_hook_is_ok(self):
        entry = patience_duration_entry()
        spec = metric_delta_spec(entry)
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after',
                 'expected': spec.expected, 'before_expected': spec.before_expected, 'metric': spec.metric,
                 'quote': entry['quote']}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, PATIENCE, INTERDICT, None, str(spec.expected),
                                  'prose', model)
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'before': spec.before_expected, 'after': spec.expected}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_patience_cooldown_reads_the_seeded_wrong_sign_mistake_as_alert(self):
        entry = patience_cooldown_entry()
        spec = metric_delta_spec(entry)
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after',
                 'expected': spec.expected, 'before_expected': spec.before_expected, 'metric': spec.metric,
                 'quote': entry['quote']}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, PATIENCE, INTERDICT, None, str(spec.expected),
                                  'prose', model)
        wrong_sign_after = spec.before_expected + (spec.before_expected - spec.expected)
        verdict = judge_behaviour(
            base_verdict(expectation),
            FakeRun({'before': spec.before_expected, 'after': wrong_sign_after}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_explicit_tolerance_absorbs_simulated_clock_jitter_within_its_margin(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 7940,
                 'before_expected': 5944, 'metric': 'aura_duration_ms', 'tolerance': 10,
                 'quote': 'Increases the duration of Interdict by $/1000;s1 sec'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, PATIENCE, INTERDICT, None, '7940', 'prose',
                                  model)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 5944, 'after': 7938}), expectation)
        self.assertEqual(verdict.status, 'ok')
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 5944, 'after': 7941}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_explicit_tolerance_still_alerts_outside_its_own_margin(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 7940,
                 'before_expected': 5944, 'metric': 'aura_duration_ms', 'tolerance': 10,
                 'quote': 'Increases the duration of Interdict by $/1000;s1 sec'}
        expectation = Expectation('label', BEHAVIOUR_METRIC_DELTA, PATIENCE, INTERDICT, None, '7940', 'prose',
                                  model)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 5944, 'after': 5944}), expectation)
        self.assertEqual(verdict.status, 'alert')


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


class JudgeDurationRatioTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'duration_ratio', 'before_label': 'before', 'after_label': 'after', 'expected': 0.85,
                 'quote': 'reduces the duration of disarm effects against you by', 'target_name': 'Finesse',
                 'vehicle_spell': MELT_WEAPON}
        return Expectation('label', BEHAVIOUR_DURATION_RATIO, FINESSE_RANK_1, MELT_WEAPON, None, '0.85',
                           'prose: "reduces the duration of disarm effects against you by" (705271)', model)

    def test_exact_expected_ratio_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 6000.0, 'after': 5100.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_absent_effect_leaving_the_duration_unchanged_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 6000.0, 'after': 6000.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_a_too_strong_reduction_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 6000.0, 'after': 4200.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_a_diff_beyond_the_settle_margin_alone_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 6000.0, 'after': 4590.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_tick_overshoot_widens_the_margin_enough_to_cover_that_same_diff(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 6000.0, 'after': 4590.0},
                                                                      max_step_ms=20.0), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_zero_baseline_is_unmeasured(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 0.0}), expectation)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 6000.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('after', verdict.explanation)


class JudgeDurationRefreshTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'duration_refresh', 'without_before_label': 'wb', 'without_after_label': 'wa',
                 'with_before_label': 'tb', 'with_after_label': 'ta', 'full_duration_ms': 30000.0,
                 'refresh_margin_ms': 500, 'quote': 'now refreshes the duration of Blade of Faith'}
        return Expectation('label', BEHAVIOUR_DURATION_REFRESH, BLESSING_OF_AGGRAMAR, BLADE_OF_FAITH, None, '30000.0',
                           'prose: "now refreshes the duration of Blade of Faith" (300502)', model)

    def test_refreshed_to_near_full_duration_without_the_passive_decaying_is_ok(self):
        expectation = self.expectation()
        values = {'wb': 20000.0, 'wa': 19500.0, 'tb': 20000.0, 'ta': 29800.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_without_the_passive_the_breaker_must_not_increase_the_duration(self):
        expectation = self.expectation()
        values = {'wb': 20000.0, 'wa': 25000.0, 'tb': 20000.0, 'ta': 29800.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_with_the_passive_a_duration_that_stays_merely_decayed_is_alert(self):
        expectation = self.expectation()
        values = {'wb': 20000.0, 'wa': 19500.0, 'tb': 20000.0, 'ta': 19500.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'wb': 20000.0, 'wa': 19500.0, 'tb': 20000.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('ta', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


class JudgeAmountDeltaTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'amount_delta', 'without_before_label': 'wb', 'without_after_label': 'wa',
                 'with_before_label': 'tb', 'with_after_label': 'ta', 'fraction': 0.70,
                 'quote': 'Using a Libram now removes'}
        return Expectation('label', BEHAVIOUR_AMOUNT_DELTA, HOLY_BOOKS, OATHKEEPER, None, '0.7',
                           'prose: "Using a Libram now removes" (706468)', model)

    def test_a_truncating_70_percent_reduction_is_ok(self):
        expectation = self.expectation()
        values = {'wb': 100.0, 'wa': 100.0, 'tb': 101.0, 'ta': 101.0 - (101 * 70) // 100}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_without_the_passive_any_change_is_alert(self):
        expectation = self.expectation()
        values = {'wb': 100.0, 'wa': 90.0, 'tb': 100.0, 'ta': 30.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_absent_effect_leaving_the_amount_unchanged_with_the_passive_known_is_alert(self):
        expectation = self.expectation()
        values = {'wb': 100.0, 'wa': 100.0, 'tb': 100.0, 'ta': 100.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_rounding_instead_of_truncating_is_alert(self):
        expectation = self.expectation()
        values = {'wb': 100.0, 'wa': 100.0, 'tb': 101.0, 'ta': 101.0 - round(101 * 0.70)}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'wb': 100.0, 'wa': 100.0, 'tb': 101.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('ta', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


SCOURGEBANE = 92111
SCOURGEBANE_EXTRA_DAMAGE = 801832


class JudgeExclusivityTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'exclusivity', 'removed_label': 'removed', 'kept_label': 'kept',
                 'removed_spell': LIBRAM_OF_CONSECRATION, 'kept_spell': LIBRAM_OF_TENACITY,
                 'quote': 'Only 1 Libram spell can be active at a time.'}
        return Expectation('label', BEHAVIOUR_EXCLUSIVITY, LIBRAM_OF_CONSECRATION, LIBRAM_OF_TENACITY, None, '0',
                           'prose: "Only 1 Libram spell can be active at a time." (801441)', model)

    def test_previous_removed_and_new_kept_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'removed': 0.0, 'kept': 1.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_both_auras_held_at_once_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'removed': 1.0, 'kept': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_the_newly_cast_libram_missing_its_own_aura_is_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'removed': 0.0, 'kept': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'removed': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('kept', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


class CritGuaranteeScenarioTests(unittest.TestCase):
    def spec(self):
        return CritGuaranteeSpec(SCOURGEBANE, 'Scourgebane',
                                 'This is guaranteed to critically strike against Undead enemies.',
                                 SCOURGEBANE_EXTRA_DAMAGE, 1501, 6, 'Undead (Mindless Zombie)')

    def test_scenario_attacks_the_overridden_creature_entry_not_the_shared_dummy(self):
        scenario, [expectation] = crit_guarantee_scenario(CLASS_FILE, self.spec())
        creature, _control = scenario['creatures']
        self.assertEqual(creature['entry'], 1501)
        self.assertEqual(creature['reaction'], 0)
        self.assertEqual(expectation.check, BEHAVIOUR_CRIT_GUARANTEE)
        self.assertEqual(expectation.spell_id, SCOURGEBANE)
        self.assertEqual(expectation.rank_id, SCOURGEBANE_EXTRA_DAMAGE)

    def test_scenario_measures_both_critical_and_non_critical_hits_of_the_trial_spell(self):
        scenario, [expectation] = crit_guarantee_scenario(CLASS_FILE, self.spec())
        model = expectation.model
        crit_step = next(step for step in scenario['steps'] if step.get('label') == model['crit_label'])
        noncrit_step = next(step for step in scenario['steps'] if step.get('label') == model['noncrit_label'])
        self.assertEqual(crit_step['spell'], SCOURGEBANE_EXTRA_DAMAGE)
        self.assertTrue(crit_step['critical'])
        self.assertFalse(noncrit_step['critical'])

    def test_entry_from_class_file_round_trips_through_the_spec_parser(self):
        entry = next(entry for entry in CLASS_FILE['behaviours']
                    if entry['spell'] == SCOURGEBANE and entry['kind'] == 'crit_guarantee')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        self.assertEqual(scenario['creatures'][0]['entry'], entry['target_entry'])
        self.assertEqual(expectation.rule, f'prose: "{entry["quote"]}" ({SCOURGEBANE})')

    def test_scenario_also_attacks_a_non_undead_control_target(self):
        scenario, [expectation] = crit_guarantee_scenario(CLASS_FILE, self.spec())
        target, control = scenario['creatures']
        validated = run.validate(scenario)
        self.assertEqual(target['entry'], 1501)
        self.assertNotEqual(control['entry'], 1501)
        self.assertNotEqual(control['id'], target['id'])
        model = expectation.model
        control_crit_step = next(step for step in validated['steps']
                                 if step.get('label') == model['control_crit_label'])
        control_noncrit_step = next(step for step in validated['steps']
                                    if step.get('label') == model['control_noncrit_label'])
        self.assertEqual(control_crit_step['target'], control['id'])
        self.assertTrue(control_crit_step['critical'])
        self.assertFalse(control_noncrit_step['critical'])


class JudgeCritGuaranteeTests(unittest.TestCase):
    def expectation(self):
        model = {'crit_label': 'crit', 'noncrit_label': 'noncrit', 'minimum_events': 5,
                 'trial_spell': SCOURGEBANE_EXTRA_DAMAGE, 'target_name': 'Undead (Mindless Zombie) (entry 1501)',
                 'creature_type_source': 'creature_template.type 6 (Undead (Mindless Zombie))',
                 'quote': 'This is guaranteed to critically strike against Undead enemies.'}
        return Expectation('label', BEHAVIOUR_CRIT_GUARANTEE, SCOURGEBANE, SCOURGEBANE_EXTRA_DAMAGE, None, '1.0',
                           'prose: "This is guaranteed to critically strike against Undead enemies." (92111)',
                           model)

    def expectation_with_control(self):
        model = {**self.expectation().model, 'control_crit_label': 'control_crit',
                 'control_noncrit_label': 'control_noncrit', 'control_target_name': 'a non-Undead control',
                 'control_max_ratio': 0.9}
        return replace(self.expectation(), model=model)

    def test_every_triggered_hit_critical_is_ok(self):
        expectation = self.expectation()
        values = {'crit': 28.0, 'noncrit': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 1.0)

    def test_a_seeded_6_percent_deviation_is_an_alert(self):
        expectation = self.expectation()
        values = {'crit': 47.0, 'noncrit': 3.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.measured, 0.94)
        self.assertEqual(verdict.status, 'alert')

    def test_a_seeded_4_percent_deviation_is_tolerated(self):
        expectation = self.expectation()
        values = {'crit': 48.0, 'noncrit': 2.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.measured, 0.96)
        self.assertEqual(verdict.status, 'tolerated')

    def test_fewer_events_than_the_minimum_is_insufficient_trials(self):
        expectation = self.expectation()
        values = {'crit': 2.0, 'noncrit': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'insufficient_trials')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'crit': 10.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('noncrit', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)

    def test_a_specific_undead_only_guarantee_with_a_low_control_ratio_is_ok(self):
        expectation = self.expectation_with_control()
        values = {'crit': 20.0, 'noncrit': 0.0, 'control_crit': 5.0, 'control_noncrit': 45.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_seeded_universal_crit_on_the_control_target_is_an_alert(self):
        expectation = self.expectation_with_control()
        values = {'crit': 20.0, 'noncrit': 0.0, 'control_crit': 50.0, 'control_noncrit': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('not specific', verdict.explanation)

    def test_insufficient_control_trials_overrides_an_otherwise_ok_primary_verdict(self):
        expectation = self.expectation_with_control()
        values = {'crit': 20.0, 'noncrit': 0.0, 'control_crit': 1.0, 'control_noncrit': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'insufficient_trials')

    def test_missing_control_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation_with_control()
        values = {'crit': 20.0, 'noncrit': 0.0, 'control_crit': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('control_noncrit', verdict.explanation)


UPHEAVAL_BREAKER = 572027
OATH_HOLY_CLEAVE = 804903
OATH_CONDEMN = 804922


class OathConsumptionScenarioTests(unittest.TestCase):
    def ratio_spec(self):
        return OathConsumptionSpec(UPHEAVAL_BREAKER, 'Righteous Upheaval',
                                   'Consumes your Oaths, dealing additional damage for each consumed.',
                                   UPHEAVAL_BREAKER, OATH_RIGHTEOUS_LUNGE, 'ratio', 1.365, 'spell_damage_done')

    def flat_spec(self):
        return OathConsumptionSpec(BLADE_OF_FAITH, 'Blade of Faith',
                                   'Consumes your Oaths, dealing additional damage for each consumed.',
                                   BLADE_OF_FAITH, OATH_HOLY_CLEAVE, 'flat', 25, 'spell_damage_done',
                                   periodic=True)

    def test_a_bad_relation_is_not_modelled(self):
        with self.assertRaises(NotModelled):
            oath_consumption_scenario(CLASS_FILE, replace(self.ratio_spec(), relation='nonsense'))

    def test_scenario_reads_the_metric_before_and_after_fixturing_the_oath_then_casts_and_confirms_consumption(self):
        scenario, [expectation] = oath_consumption_scenario(CLASS_FILE, self.ratio_spec())
        validated = run.validate(scenario)
        self.assertEqual(expectation.check, BEHAVIOUR_OATH_CONSUMPTION)
        self.assertEqual(expectation.spell_id, UPHEAVAL_BREAKER)
        self.assertEqual(expectation.rank_id, UPHEAVAL_BREAKER)
        model = expectation.model
        before_step = next(step for step in validated['steps'] if step.get('label') == model['before_label'])
        after_step = next(step for step in validated['steps'] if step.get('label') == model['after_label'])
        stacks_step = next(step for step in validated['steps'] if step.get('label') == model['stacks_label'])
        self.assertEqual(before_step['metric'], 'spell_damage_done')
        self.assertEqual(before_step['spell'], UPHEAVAL_BREAKER)
        self.assertEqual(stacks_step['metric'], 'aura_stacks')
        self.assertEqual(stacks_step['spell'], OATH_RIGHTEOUS_LUNGE)
        set_aura_steps = [step for step in validated['steps']
                          if step.get('action') == 'set_aura' and step.get('spell') == OATH_RIGHTEOUS_LUNGE]
        self.assertEqual(len(set_aura_steps), 1)
        self.assertEqual(set_aura_steps[0]['stacks'], 1)
        cast_steps = [step for step in validated['steps']
                     if step.get('action') == 'cast' and step.get('spell') == UPHEAVAL_BREAKER]
        self.assertEqual(len(cast_steps), 1)
        before_index = validated['steps'].index(before_step)
        set_aura_index = validated['steps'].index(set_aura_steps[0])
        after_index = validated['steps'].index(after_step)
        cast_index = validated['steps'].index(cast_steps[0])
        stacks_index = validated['steps'].index(stacks_step)
        self.assertLess(before_index, set_aura_index)
        self.assertLess(set_aura_index, after_index)
        self.assertLess(after_index, cast_index)
        self.assertLess(cast_index, stacks_index)

    def test_a_periodic_flat_spec_reads_the_metric_with_periodic_true(self):
        scenario, [_expectation] = oath_consumption_scenario(CLASS_FILE, self.flat_spec())
        validated = run.validate(scenario)
        before_step = next(step for step in validated['steps']
                           if step.get('label', '').endswith('oath_consumption_before'))
        self.assertTrue(before_step['periodic'])

    def test_a_second_oath_spec_fixtures_both_oaths_together_and_checks_both_are_consumed(self):
        spec = replace(self.ratio_spec(), other_oath_spell=OATH_CONDEMN)
        scenario, [expectation] = oath_consumption_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        model = expectation.model
        self.assertIn('other_oath_spell', model)
        other_alone_step = next(step for step in validated['steps']
                                if step.get('label') == model['other_alone_label'])
        both_step = next(step for step in validated['steps'] if step.get('label') == model['both_label'])
        other_stacks_step = next(step for step in validated['steps']
                                 if step.get('label') == model['other_stacks_label'])
        self.assertEqual(other_alone_step['metric'], 'spell_damage_done')
        self.assertEqual(other_stacks_step['spell'], OATH_CONDEMN)
        set_aura_steps = [step for step in validated['steps']
                         if step.get('action') == 'set_aura' and step.get('spell') == OATH_RIGHTEOUS_LUNGE]
        self.assertEqual([step['stacks'] for step in set_aura_steps], [1, 0, 1])
        other_set_aura = next(step for step in validated['steps']
                              if step.get('action') == 'set_aura' and step.get('spell') == OATH_CONDEMN)
        self.assertEqual(other_set_aura['stacks'], 1)
        other_alone_index = validated['steps'].index(other_alone_step)
        both_index = validated['steps'].index(both_step)
        cast_index = next(index for index, step in enumerate(validated['steps'])
                          if step.get('action') == 'cast' and step.get('spell') == UPHEAVAL_BREAKER)
        self.assertLess(other_alone_index, both_index)
        self.assertLess(both_index, cast_index)

    def test_no_second_oath_spec_omits_the_additive_measurements(self):
        scenario, [expectation] = oath_consumption_scenario(CLASS_FILE, self.ratio_spec())
        self.assertNotIn('other_oath_spell', expectation.model)
        self.assertNotIn('both_label', expectation.model)

    def test_entries_from_the_class_file_round_trip_through_the_spec_parser(self):
        entries = [entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'oath_consumption']
        self.assertEqual(len(entries), 5)
        for entry in entries:
            scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
            self.assertEqual(expectation.rule, f'prose: "{entry["quote"]}" ({entry["spell"]})')
            run.validate(scenario)


class JudgeOathConsumptionTests(unittest.TestCase):
    def ratio_expectation(self):
        model = {'kind': 'oath_consumption', 'before_label': 'before', 'after_label': 'after',
                 'stacks_label': 'stacks', 'relation': 'ratio', 'expected': 1.365, 'metric': 'spell_damage_done',
                 'oath_spell': OATH_RIGHTEOUS_LUNGE,
                 'quote': 'Consumes your Oaths, dealing additional damage for each consumed.'}
        return Expectation('label', BEHAVIOUR_OATH_CONSUMPTION, UPHEAVAL_BREAKER, UPHEAVAL_BREAKER, None,
                           '1.365', 'prose: "..." (572027)', model)

    def flat_expectation(self):
        model = {'kind': 'oath_consumption', 'before_label': 'before', 'after_label': 'after',
                 'stacks_label': 'stacks', 'relation': 'flat', 'expected': 25, 'metric': 'spell_damage_done',
                 'oath_spell': OATH_HOLY_CLEAVE,
                 'quote': 'Consumes your Oaths, dealing additional damage for each consumed.'}
        return Expectation('label', BEHAVIOUR_OATH_CONSUMPTION, BLADE_OF_FAITH, BLADE_OF_FAITH, None, '25',
                           'prose: "..." (803872)', model)

    def test_a_delta_matching_the_expected_ratio_and_a_consumed_oath_is_ok(self):
        expectation = self.ratio_expectation()
        values = {'before': 800.0, 'after': 1092.0, 'stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_flat_delta_matching_25_and_a_consumed_oath_is_ok(self):
        expectation = self.flat_expectation()
        values = {'before': 1000.0, 'after': 1025.0, 'stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_6_percent_deviation_from_the_expected_ratio_delta_is_an_alert(self):
        expectation = self.ratio_expectation()
        expected_delta = 800.0 * (1.365 - 1.0)
        values = {'before': 800.0, 'after': 800.0 + expected_delta * 1.06, 'stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_a_4_percent_deviation_from_the_expected_ratio_delta_is_tolerated(self):
        expectation = self.ratio_expectation()
        expected_delta = 800.0 * (1.365 - 1.0)
        values = {'before': 800.0, 'after': 800.0 + expected_delta * 1.04, 'stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'tolerated')

    def test_a_correct_delta_with_the_oath_not_consumed_is_an_alert(self):
        expectation = self.ratio_expectation()
        values = {'before': 800.0, 'after': 1092.0, 'stacks': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('consumed', verdict.explanation)

    def test_a_seeded_unchanged_reading_is_an_alert(self):
        expectation = self.ratio_expectation()
        values = {'before': 800.0, 'after': 800.0, 'stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.ratio_expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 800.0, 'after': 1092.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('stacks', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.ratio_expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)

    def both_expectation(self):
        expectation = self.ratio_expectation()
        model = {**expectation.model, 'other_oath_spell': OATH_CONDEMN, 'other_alone_label': 'other_alone',
                 'both_label': 'both', 'other_stacks_label': 'other_stacks'}
        return replace(expectation, model=model)

    def flat_both_expectation(self):
        expectation = self.flat_expectation()
        model = {**expectation.model, 'other_oath_spell': OATH_RIGHTEOUS_LUNGE, 'other_alone_label': 'other_alone',
                 'both_label': 'both', 'other_stacks_label': 'other_stacks'}
        return replace(expectation, model=model)

    def test_a_both_delta_matching_the_multiplicative_product_and_both_oaths_consumed_is_ok(self):
        expectation = self.both_expectation()
        values = {'before': 800.0, 'after': 1092.0, 'stacks': 0.0, 'other_alone': 950.0, 'both': 1296.75,
                  'other_stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_both_delta_that_credits_only_one_oath_is_an_alert(self):
        expectation = self.both_expectation()
        values = {'before': 800.0, 'after': 1092.0, 'stacks': 0.0, 'other_alone': 950.0, 'both': 1092.0,
                  'other_stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('not additive', verdict.explanation)

    def test_a_second_oath_not_consumed_by_the_cast_is_an_alert(self):
        expectation = self.both_expectation()
        values = {'before': 800.0, 'after': 1092.0, 'stacks': 0.0, 'other_alone': 950.0, 'both': 1296.75,
                  'other_stacks': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('every held Oath', verdict.explanation)

    def test_a_non_contributing_second_oath_still_consumed_is_ok(self):
        expectation = self.flat_both_expectation()
        values = {'before': 1000.0, 'after': 1025.0, 'stacks': 0.0, 'other_alone': 1000.0, 'both': 1025.0,
                  'other_stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_non_contributing_second_oath_not_consumed_is_an_alert(self):
        expectation = self.flat_both_expectation()
        values = {'before': 1000.0, 'after': 1025.0, 'stacks': 0.0, 'other_alone': 1000.0, 'both': 1025.0,
                  'other_stacks': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('every held Oath', verdict.explanation)

    def test_missing_both_measurement_leaves_alert_with_explanation(self):
        expectation = self.both_expectation()
        values = {'before': 800.0, 'after': 1092.0, 'stacks': 0.0, 'other_alone': 950.0, 'other_stacks': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('both', verdict.explanation)


RIGHTEOUS_LUNGE = 570233
OATH_RIGHTEOUS_LUNGE = 804904
OATH_CHAIN = 704576


class AuraGrantScenarioTests(unittest.TestCase):
    def spec(self):
        return AuraGrantSpec(RIGHTEOUS_LUNGE, 'Righteous Lunge', 'and granting an Oath', RIGHTEOUS_LUNGE,
                             OATH_RIGHTEOUS_LUNGE)

    def test_scenario_casts_once_and_measures_the_chain_stack_and_the_oath_aura(self):
        scenario, [expectation] = aura_grant_scenario(CLASS_FILE, self.spec())
        validated = run.validate(scenario)
        self.assertEqual(expectation.check, BEHAVIOUR_AURA_GRANT)
        self.assertEqual(expectation.spell_id, RIGHTEOUS_LUNGE)
        self.assertEqual(expectation.rank_id, RIGHTEOUS_LUNGE)
        model = expectation.model
        before_step = next(step for step in validated['steps'] if step.get('label') == model['before_label'])
        after_step = next(step for step in validated['steps'] if step.get('label') == model['after_label'])
        oath_step = next(step for step in validated['steps'] if step.get('label') == model['oath_label'])
        self.assertEqual(before_step['metric'], 'aura_stacks')
        self.assertEqual(before_step['spell'], OATH_CHAIN)
        self.assertEqual(after_step['spell'], OATH_CHAIN)
        self.assertEqual(oath_step['metric'], 'aura')
        self.assertEqual(oath_step['spell'], OATH_RIGHTEOUS_LUNGE)
        cast_steps = [step for step in validated['steps']
                     if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_LUNGE]
        self.assertEqual(len(cast_steps), 1)
        before_index = validated['steps'].index(before_step)
        cast_index = validated['steps'].index(cast_steps[0])
        after_index = validated['steps'].index(after_step)
        self.assertLess(before_index, cast_index)
        self.assertLess(cast_index, after_index)

    def test_entries_from_the_class_file_round_trip_through_the_spec_parser(self):
        entries = [entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'aura_grant']
        self.assertEqual(len(entries), 4)
        for entry in entries:
            scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
            self.assertEqual(expectation.rule, f'prose: "{entry["quote"]}" ({entry["spell"]})')
            run.validate(scenario)


class JudgeAuraGrantTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'aura_grant', 'before_label': 'before', 'after_label': 'after', 'oath_label': 'oath',
                 'oath_aura': OATH_RIGHTEOUS_LUNGE, 'chain_aura': OATH_CHAIN, 'expected': 1,
                 'quote': 'and granting an Oath'}
        return Expectation('label', BEHAVIOUR_AURA_GRANT, RIGHTEOUS_LUNGE, RIGHTEOUS_LUNGE, None, '1',
                           'prose: "and granting an Oath" (570233)', model)

    def test_a_chain_stack_up_by_one_with_the_oath_present_is_ok(self):
        expectation = self.expectation()
        values = {'before': 0.0, 'after': 1.0, 'oath': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 1.0)

    def test_a_seeded_unchanged_chain_stack_is_an_alert(self):
        expectation = self.expectation()
        values = {'before': 0.0, 'after': 0.0, 'oath': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.status, 'alert')

    def test_a_chain_stack_up_by_one_without_the_oath_aura_present_is_an_alert(self):
        expectation = self.expectation()
        values = {'before': 0.0, 'after': 1.0, 'oath': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('oath', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


RIGHTEOUS_TEMPEST = 805409
OATH_CONDEMN = 804922


class OathConsumptionRemovalScenarioTests(unittest.TestCase):
    def spec(self):
        return OathConsumptionRemovalSpec(RIGHTEOUS_TEMPEST, 'Righteous Tempest',
                                          'Consumes your Oaths, dealing additional damage for each consumed.',
                                          RIGHTEOUS_TEMPEST, (OATH_RIGHTEOUS_LUNGE, OATH_CONDEMN))

    def test_a_spec_with_no_oaths_is_not_modelled(self):
        with self.assertRaises(NotModelled):
            oath_consumption_removal_scenario(CLASS_FILE, replace(self.spec(), oath_spells=()))

    def test_scenario_fixtures_every_oath_reads_the_bonus_then_proves_removal_timing(self):
        scenario, [expectation] = oath_consumption_removal_scenario(CLASS_FILE, self.spec())
        validated = run.validate(scenario)
        self.assertEqual(expectation.check, BEHAVIOUR_OATH_CONSUMPTION_REMOVAL)
        self.assertEqual(expectation.spell_id, RIGHTEOUS_TEMPEST)
        self.assertEqual(expectation.rank_id, RIGHTEOUS_TEMPEST)
        model = expectation.model
        self.assertEqual(model['oath_spells'], [OATH_RIGHTEOUS_LUNGE, OATH_CONDEMN])
        amount_steps = [next(step for step in validated['steps'] if step.get('label') == label)
                        for label in model['amount_labels']]
        script_step = next(step for step in validated['steps'] if step.get('label') == model['script_label'])
        held_steps = [next(step for step in validated['steps'] if step.get('label') == label)
                     for label in model['before_removal_labels']]
        removed_steps = [next(step for step in validated['steps'] if step.get('label') == label)
                         for label in model['after_removal_labels']]
        for step, oath in zip(amount_steps, (OATH_RIGHTEOUS_LUNGE, OATH_CONDEMN)):
            self.assertEqual(step['metric'], 'aura_amount')
            self.assertEqual(step['spell'], oath)
            self.assertEqual(step['effect'], 2)
        self.assertEqual(script_step['metric'], 'aura_script_value')
        self.assertEqual(script_step['spell'], RIGHTEOUS_TEMPEST)
        self.assertEqual(script_step['key'], RIGHTEOUS_TEMPEST)
        for step, oath in zip(held_steps, (OATH_RIGHTEOUS_LUNGE, OATH_CONDEMN)):
            self.assertEqual(step['metric'], 'aura_stacks')
            self.assertEqual(step['spell'], oath)
        for step, oath in zip(removed_steps, (OATH_RIGHTEOUS_LUNGE, OATH_CONDEMN)):
            self.assertEqual(step['metric'], 'aura_stacks')
            self.assertEqual(step['spell'], oath)
        set_aura_steps = [step for step in validated['steps'] if step.get('action') == 'set_aura']
        self.assertLessEqual({OATH_RIGHTEOUS_LUNGE, OATH_CONDEMN}, {step['spell'] for step in set_aura_steps})
        cast_steps = [step for step in validated['steps']
                     if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_TEMPEST]
        self.assertEqual(len(cast_steps), 1)
        indices = {step['label']: validated['steps'].index(step) for step in validated['steps'] if 'label' in step}
        for label in model['amount_labels']:
            self.assertLess(indices[label], validated['steps'].index(cast_steps[0]))
        cast_index = validated['steps'].index(cast_steps[0])
        self.assertLess(cast_index, indices[model['script_label']])
        for label in model['before_removal_labels']:
            self.assertLess(indices[model['script_label']], indices[label])
        for before_label, after_label in zip(model['before_removal_labels'], model['after_removal_labels']):
            self.assertLess(indices[before_label], indices[after_label])

    def test_entries_from_the_class_file_round_trip_through_the_spec_parser(self):
        entries = [entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'oath_consumption_removal']
        self.assertEqual(len(entries), 1)
        for entry in entries:
            scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
            self.assertEqual(expectation.rule, f'prose: "{entry["quote"]}" ({entry["spell"]})')
            run.validate(scenario)


class JudgeOathConsumptionRemovalTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'oath_consumption_removal', 'amount_labels': ['amount_0', 'amount_1'],
                 'script_label': 'script', 'before_removal_labels': ['held_0', 'held_1'],
                 'after_removal_labels': ['removed_0', 'removed_1'],
                 'oath_spells': [OATH_RIGHTEOUS_LUNGE, OATH_CONDEMN],
                 'quote': 'Consumes your Oaths, dealing additional damage for each consumed.'}
        return Expectation('label', BEHAVIOUR_OATH_CONSUMPTION_REMOVAL, RIGHTEOUS_TEMPEST, RIGHTEOUS_TEMPEST, None,
                           'sum(oath aura_amount)', 'prose: "..." (805409)', model)

    def values(self, script=60.0, held=(1.0, 1.0), removed=(0.0, 0.0)):
        return {'amount_0': 30.0, 'amount_1': 30.0, 'script': script, 'held_0': held[0], 'held_1': held[1],
                'removed_0': removed[0], 'removed_1': removed[1]}

    def test_the_summed_amount_matching_the_script_value_with_correct_timing_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values()), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 60.0)
        self.assertEqual(verdict.expected, 60.0)

    def test_a_6_percent_deviation_from_the_summed_amount_is_an_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(script=60.0 * 1.06)), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_a_4_percent_deviation_from_the_summed_amount_is_tolerated(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(script=60.0 * 1.04)), expectation)
        self.assertEqual(verdict.status, 'tolerated')

    def test_an_oath_consumed_too_early_is_an_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(held=(0.0, 1.0))), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('held', verdict.explanation)

    def test_an_oath_never_consumed_after_removal_is_an_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(removed=(1.0, 0.0))), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('removed', verdict.explanation)

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        values = self.values()
        del values['script']
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('script', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


DISCIPLINED_BLOWS = 680397
BENEDICTION = 578276
DISCIPLINED_BLOWS_TICK = 680398
SCARLET_CHAMPION = 805415
ARGENT_BLADE = 807268
SCARLET_CHAMPION_STACK = 805416
SACRED_DEFENSE = 705306
KARAZHAN_CHESS_FOOTMAN_MELEE = 32247
SACRED_DEFENSE_STRIKE = 707720


class IcdGateScenarioTests(unittest.TestCase):
    def spec(self):
        return IcdGateSpec(DISCIPLINED_BLOWS, 'Disciplined Blows', 'Cnly occur once every 0.5 sec.', BENEDICTION,
                           DISCIPLINED_BLOWS_TICK, 500, target='self', caster_health_pct=50)

    def test_a_non_positive_internal_cooldown_is_not_modelled(self):
        with self.assertRaises(NotModelled):
            icd_gate_scenario(CLASS_FILE, replace(self.spec(), internal_cooldown_ms=0))

    def test_scenario_casts_three_times_with_the_second_gap_inside_the_cooldown(self):
        scenario, [expectation] = icd_gate_scenario(CLASS_FILE, self.spec())
        validated = run.validate(scenario)
        self.assertEqual(expectation.check, BEHAVIOUR_INTERNAL_COOLDOWN_GATE)
        self.assertEqual(expectation.spell_id, DISCIPLINED_BLOWS)
        model = expectation.model
        self.assertEqual(model['short_gap_ms'], 250)
        self.assertEqual(model['reopen_gap_ms'], 750)
        cast_steps = [step for step in validated['steps']
                     if step.get('action') == 'cast' and step.get('spell') == BENEDICTION]
        self.assertEqual(len(cast_steps), 3)
        for label in (model['after1_label'], model['after2_label'], model['after3_label']):
            step = next(step for step in validated['steps'] if step.get('label') == label)
            self.assertEqual(step['metric'], 'spell_cast_count')
            self.assertEqual(step['spell'], DISCIPLINED_BLOWS_TICK)
        health_steps = [step for step in validated['steps'] if step.get('action') == 'set_health']
        self.assertGreaterEqual(len(health_steps), 3)

    def test_a_force_crit_scenario_sets_the_player_fixture(self):
        spec = IcdGateSpec(SCARLET_CHAMPION, 'Scarlet Champion', 'Can only occur once per sec.', ARGENT_BLADE,
                           SCARLET_CHAMPION_STACK, 1000, target='dummy', force_crit='melee')
        scenario, _ = icd_gate_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)

    def test_entries_from_the_class_file_round_trip_through_the_spec_parser(self):
        entries = [entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'internal_cooldown_gate']
        self.assertEqual(len(entries), 4)
        for entry in entries:
            scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
            self.assertEqual(expectation.rule, f'prose: "{entry["quote"]}" ({entry["spell"]})')
            run.validate(scenario)

    def test_a_striker_trigger_without_an_entry_is_not_modelled(self):
        spec = IcdGateSpec(SACRED_DEFENSE, 'Sacred Defense', 'Can only occur once per sec.', KARAZHAN_CHESS_FOOTMAN_MELEE,
                           SACRED_DEFENSE_STRIKE, 1000, target=None, trigger_actor=STRIKER, striker_entry=0)
        with self.assertRaises(ValueError):
            icd_gate_scenario(CLASS_FILE, spec)

    def test_a_striker_trigger_casts_the_trigger_spell_from_the_fixtured_creature(self):
        spec = IcdGateSpec(SACRED_DEFENSE, 'Sacred Defense', 'Can only occur once per sec.', KARAZHAN_CHESS_FOOTMAN_MELEE,
                           SACRED_DEFENSE_STRIKE, 1000, target=None, trigger_actor=STRIKER, striker_entry=36)
        scenario, [expectation] = icd_gate_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(expectation.spell_id, SACRED_DEFENSE)
        striker_casts = [step for step in validated['steps']
                        if step.get('action') == 'cast' and step.get('actor') == STRIKER]
        self.assertEqual(len(striker_casts), 3)
        for step in striker_casts:
            self.assertEqual(step['spell'], KARAZHAN_CHESS_FOOTMAN_MELEE)
            self.assertEqual(step['target'], 'caster')
        self.assertFalse(any(step.get('action') == 'learn' and step.get('spell') == KARAZHAN_CHESS_FOOTMAN_MELEE
                             for step in validated['steps']))
        self.assertEqual(scenario['creatures'][0]['entry'], 36)
        self.assertEqual(scenario['creatures'][0]['reaction'], 0)
        self.assertTrue(scenario['creatures'][0]['stationary'])


class JudgeIcdGateTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'internal_cooldown_gate', 'after1_label': 'after1', 'after2_label': 'after2',
                 'after3_label': 'after3', 'internal_cooldown_ms': 500, 'short_gap_ms': 250,
                 'reopen_gap_ms': 750, 'quote': 'Cnly occur once every 0.5 sec.'}
        return Expectation('label', BEHAVIOUR_INTERNAL_COOLDOWN_GATE, DISCIPLINED_BLOWS, BENEDICTION, None, '1',
                           'prose: "Cnly occur once every 0.5 sec." (680397)', model)

    def test_blocked_then_reopened_is_ok(self):
        expectation = self.expectation()
        values = {'after1': 1.0, 'after2': 1.0, 'after3': 2.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 1.0)

    def test_a_seeded_early_second_fire_is_an_alert(self):
        expectation = self.expectation()
        values = {'after1': 1.0, 'after2': 2.0, 'after3': 3.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 1.0)
        self.assertIn('before its own', verdict.explanation)

    def test_a_seeded_missing_reopen_is_an_alert(self):
        expectation = self.expectation()
        values = {'after1': 1.0, 'after2': 1.0, 'after3': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'after1': 1.0, 'after2': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('after3', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


class JudgeGroupStackCapTests(unittest.TestCase):
    def expectation(self, own_pct=5.0, partner_pct=4.0, personal_pct=0.0):
        model = {'kind': 'group_stack_cap', 'baseline_label': 'baseline', 'own_label': 'own',
                 'combined_label': 'combined', 'own_pct': own_pct, 'partner_pct': partner_pct,
                 'personal_pct': personal_pct, 'quote': 'Does not stack with similar effects.'}
        return Expectation('label', BEHAVIOUR_GROUP_STACK_CAP, CALL_OF_THE_MONASTERY, UNLEASHED_RAGE, None,
                           str(max(own_pct, partner_pct)), 'prose: "Does not stack with similar effects." (560550)',
                           model)

    def test_an_uncapped_personal_effect_keeps_compounding_on_top_of_the_capped_area_effect(self):
        expectation = self.expectation(own_pct=5.0, partner_pct=4.0, personal_pct=5.0)
        baseline = 1000.0
        own = baseline * 1.05 * 1.05
        combined = baseline * 1.05 * 1.05
        run = FakeRun({'baseline': baseline, 'own': own, 'combined': combined})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_the_personal_effect_also_counted_toward_the_group_cap_is_an_alert(self):
        expectation = self.expectation(own_pct=5.0, partner_pct=4.0, personal_pct=5.0)
        baseline = 1000.0
        own = baseline * 1.05 * 1.05
        combined = baseline * 1.05
        run = FakeRun({'baseline': baseline, 'own': own, 'combined': combined})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_combined_capped_at_the_stronger_own_percentage_is_ok(self):
        expectation = self.expectation(own_pct=5.0, partner_pct=4.0)
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 1.05, 'combined': baseline * 1.05})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_combined_summing_both_percentages_is_an_alert(self):
        expectation = self.expectation(own_pct=5.0, partner_pct=4.0)
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 1.05, 'combined': baseline * 1.09})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_own_reading_missing_the_single_percentage_is_an_alert(self):
        expectation = self.expectation(own_pct=5.0, partner_pct=4.0)
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline, 'combined': baseline * 1.05})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_combined_capped_at_the_stronger_partner_percentage_when_partner_wins(self):
        expectation = self.expectation(own_pct=3.0, partner_pct=3.0)
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 1.03, 'combined': baseline * 1.03})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        run = FakeRun({'baseline': 1000.0, 'own': 1050.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('combined', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)

    def test_spell_group_mechanism_explanation_names_the_spell_group_rule(self):
        expectation = self.expectation(own_pct=5.0, partner_pct=4.0)
        expectation.model['mechanism'] = 'spell_group'
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 1.05, 'combined': baseline * 1.05})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertIn('SPELL_GROUP_STACK_RULE_EXCLUSIVE_SAME_EFFECT', verdict.explanation)

    def test_aura_cap_mechanism_explanation_does_not_claim_a_spell_group(self):
        expectation = self.expectation(own_pct=6.0, partner_pct=6.0)
        expectation.model['mechanism'] = 'aura_cap'
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 1.06, 'combined': baseline * 1.06})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertNotIn('SPELL_GROUP_STACK_RULE_EXCLUSIVE_SAME_EFFECT', verdict.explanation)
        self.assertIn('global cap', verdict.explanation)

    def test_aura_cap_mechanism_still_catches_a_summed_combined_reading(self):
        expectation = self.expectation(own_pct=6.0, partner_pct=6.0)
        expectation.model['mechanism'] = 'aura_cap'
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 1.06, 'combined': baseline * 1.12})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')


class JudgeSingleTargetTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'single_target', 'first_label': 'first', 'removed_label': 'removed',
                 'second_label': 'second', 'quote': 'Can only be placed on 1 target at a time.'}
        return Expectation('label', BEHAVIOUR_SINGLE_TARGET, RIGHTEOUS_CUSTODIAN, RIGHTEOUS_CUSTODIAN, None, '0',
                           'prose: "Can only be placed on 1 target at a time." (572808)', model)

    def test_first_present_then_removed_once_the_second_is_cast_is_ok(self):
        expectation = self.expectation()
        run = FakeRun({'first': 1.0, 'removed': 0.0, 'second': 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_first_still_held_after_the_second_cast_is_an_alert(self):
        expectation = self.expectation()
        run = FakeRun({'first': 1.0, 'removed': 1.0, 'second': 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_second_ally_never_receiving_the_aura_is_an_alert(self):
        expectation = self.expectation()
        run = FakeRun({'first': 1.0, 'removed': 0.0, 'second': 0.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_first_cast_never_applying_the_aura_is_an_alert(self):
        expectation = self.expectation()
        run = FakeRun({'first': 0.0, 'removed': 0.0, 'second': 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        run = FakeRun({'first': 1.0, 'removed': 0.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('second', verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


if __name__ == '__main__':
    unittest.main()
