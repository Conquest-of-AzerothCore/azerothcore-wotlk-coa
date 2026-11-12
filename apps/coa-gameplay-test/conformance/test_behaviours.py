from dataclasses import replace
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from behaviours import (AFTER, AGGRO_REDIRECT_REACTION, BEFORE, BEHAVIOUR_ABSORB_PIERCE_RATIO, BEHAVIOUR_TAKEN_HIT,
                        BEHAVIOUR_THREAT_REDIRECT, BEHAVIOUR_DISPEL_COUNT, BEHAVIOUR_TAKEN_OUTCOME,
                        BEHAVIOUR_CRIT_RATE,
                        BEHAVIOUR_AGGRO_REDIRECT, BEHAVIOUR_AMOUNT_DELTA,
                        BEHAVIOUR_AURA_GRANT, BEHAVIOUR_CAST_APPLIES_AURA, BEHAVIOUR_CAST_COMBAT, BEHAVIOUR_HEAL_BLOCK,
                        BEHAVIOUR_CAST_CONDITION,
                        BEHAVIOUR_CAST_GATE,
                        BEHAVIOUR_CHARGE_RECHARGE, BEHAVIOUR_COUNT, BEHAVIOUR_CRIT_GUARANTEE,
                        BEHAVIOUR_CRIT_MAGNITUDE, BEHAVIOUR_DURATION, BEHAVIOUR_DURATION_RATIO,
                        BEHAVIOUR_DURATION_REFRESH, BEHAVIOUR_EXCLUSIVITY, BEHAVIOUR_FIXED_COUNT,
                        BEHAVIOUR_GROUP_STACK_CAP, BEHAVIOUR_IMMUNITY, BEHAVIOUR_INTERNAL_COOLDOWN,
                        BEHAVIOUR_INTERNAL_COOLDOWN_GATE, BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_METRIC_RATIO_DELTA,
                        BEHAVIOUR_MOUNT_GRANT, BEHAVIOUR_OATH_CONSUMPTION, BEHAVIOUR_OATH_CONSUMPTION_REMOVAL,
                        BEHAVIOUR_PARTY_STAT_RATIO, BEHAVIOUR_RATIO, BEHAVIOUR_SINGLE_TARGET,
                        BEHAVIOUR_EVENT_DELAY, BEHAVIOUR_THREAT_SLOPE, BEHAVIOUR_TRIGGER, IMMUNITY_CASTS,
                        MECHANIC_LAND_ATTEMPTS,
                        NO_CAST_FAILURE, SPELL_FAILED_ONLY_MOUNTED,
                        SPELL_FAILED_ONLY_OUTDOORS, SPELL_FAILED_TARGET_AURASTATE, STRIKER, TAKEN_HIT_PVP_LOCATION,
                        BEHAVIOUR_HIT_RATIO, NotModelled, sized_behaviour,
                        AuraGrantSpec, CritGuaranteeSpec, HealingRatioTarget, IcdGateSpec, OathConsumptionSpec,
                        OathConsumptionRemovalSpec,
                        absorb_pierce_ratio_scenario, absorb_pierce_ratio_spec,
                        aggro_redirect_label, aggro_redirect_scenario, aggro_redirect_spec,
                        ally_heal_breadth_scenario, ally_heal_breadth_spec,
                        amount_delta_scenario, amount_delta_spec, aura_grant_scenario, aura_grant_spec,
                        aura_metric_delta_scenario, aura_metric_delta_spec,
                        aura_presence_scenario, aura_presence_spec,
                        aura_spread_scenario, aura_spread_spec, behaviour_entries, behaviour_entry,
                        behaviour_scenario, cast_applies_aura_scenario, cast_applies_aura_spec,
                        cast_combat_scenario, cast_combat_spec,
                        cast_condition_scenario, cast_condition_spec,
                        cast_gate_scenario, cast_gate_spec,
                        cast_leech_ratio_scenario, cast_leech_ratio_spec,
                        cast_stat_ratio_scenario, cast_stat_ratio_spec,
                        charge_recharge_scenario, charge_recharge_spec,
                        crit_guarantee_scenario, crit_guarantee_spec,
                        crit_magnitude_scenario, crit_magnitude_spec,
                        dispel_removal_scenario, dispel_removal_spec,
                        duration_refresh_scenario, duration_refresh_spec, duration_scenario, duration_spec,
                        dummy_id,
                        exclusivity_chain_scenario, exclusivity_chain_spec,
                        fixed_target_count_scenario, fixed_target_count_spec,
                        group_stack_cap_scenario, group_stack_cap_spec, strongest_percent, taken_hit_scenario, hit_arm,
                        taken_hit_spec,
                        health_ratio_spec, health_threshold_ratio_scenario, healing_ratio_scenario,
                        healing_ratio_spec, heal_block_scenario, heal_block_spec,
                        icd_gate_scenario, icd_gate_spec, ignores_caster_heal_modifiers,
                        internal_cooldown_scenario, internal_cooldown_spec, leech_heal_modifier_factor,
                        leech_ratio_scenario, leech_ratio_spec,
                        mechanic_duration_scenario, mechanic_duration_spec, metric_delta_label, metric_delta_scenario,
                        metric_delta_spec, mount_grant_scenario, mount_grant_spec,
                        nearby_ally_id, oath_consumption_scenario, oath_consumption_spec,
                        oath_consumption_removal_scenario, oath_consumption_removal_spec,
                        party_ally_id, party_stat_ratio_scenario, party_stat_ratio_spec,
                        shield_break_trigger_scenario, shield_break_trigger_spec,
                        single_target_scenario, single_target_spec,
                        target_count_scenario, target_count_spec, threat_tick_ratio_scenario,
                        threat_tick_ratio_spec)
from bonus import bonus_band
from compare import Verdict, judge_behaviour
from hits import MAX_SCENARIO_MS, aura_modifiers
from procs import cast_interval
from profile import CASTER, DBC_DIR, control_entries, load_class_file
from tooltip import Records
from values import ALLY, Expectation, FORCED_CRIT_RATING, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run
import compare as compare_module

CLASS_FILE = load_class_file(19)
RECORDS = Records(dataset(DBC_DIR)) if DBC_DIR.is_dir() else None
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
TRANQUIL_CIRCLE = 801205
PIOUS_SWEEP = 520034
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
TITANSTRIKE = 806521
TESTAMENT_OF_STRENGTH = 300514
DIVINE_CHARGE = 527023
CRUSADERS_PRESENCE = 562302
DISCIPLINED_BLOWS = 680397
DISCIPLINED_BLOWS_PULSE = 680398
SPIRITUAL_ASCENSION = 500688
BECKON = 804914
ABSOLUTION = 800424
REBUKE = 525051
HARMONIC_DISPOSITION = 560653
INTERDICT = 560116
ARGENT_KNIGHT = 300512
BINDING_SCRIPTURE = 801457
BINDING_SCRIPTURE_DAMAGE_REDUCTION = 707307
TESTAMENT_OF_STRENGTH = 300514
SACRED_RESTRAINT = 102208
ARGENT_BLADE_CAST = 804929
ARGENT_BLADE_HEAL = 807414
TOME_OF_LIGHT = 805422
RIGHTEOUS_CUSTODIAN = 572808
NORGANNONS_WRATH = 524739
NORGANNONS_WRATH_DAMAGE = 524740


def scarlet_judicator_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SCARLET_JUDICATOR)


def holy_cleave_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == HOLY_CLEAVE)


def call_of_the_monastery_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == CALL_OF_THE_MONASTERY and entry['kind'] == 'party_stat_ratio')


def devotion_of_khazgoroth_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == DEVOTION_OF_KHAZGOROTH and entry['kind'] == 'party_stat_ratio')


def serendipity_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SERENDIPITY)


def fortified_body_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == FORTIFIED_BODY
                and entry['kind'] == 'party_stat_ratio')


def libram_of_grace_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == LIBRAM_OF_GRACE)


def chakra_of_light_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == CHAKRA_OF_LIGHT and entry['kind'] == 'ally_heal_breadth')


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


def titanstrike_cast_gate_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TITANSTRIKE)


def divine_charge_cast_condition_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == DIVINE_CHARGE
                and entry['kind'] == 'cast_condition')


def crusaders_presence_cast_condition_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == CRUSADERS_PRESENCE and entry['kind'] == 'cast_condition')


def crusaders_presence_speed_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == CRUSADERS_PRESENCE and entry['kind'] == 'metric_delta')


def divine_charge_mount_grant_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == DIVINE_CHARGE and entry['kind'] == 'mount_grant')


def spiritual_ascension_cast_combat_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SPIRITUAL_ASCENSION)


def beckon_aggro_redirect_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == BECKON)


def absolution_aggro_redirect_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == ABSOLUTION)


def disciplined_blows_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == DISCIPLINED_BLOWS and entry['kind'] == 'internal_cooldown')


def spiritual_abdicator_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == SPIRITUAL_ABDICATOR
                and entry['kind'] == 'metric_delta' and 'variant' not in entry)


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


def rebuke_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == REBUKE)


def testament_of_fortitude_dispel_entry() -> dict:
    return {'spell': TESTAMENT_OF_FORTITUDE, 'name': 'Testament of Fortitude', 'kind': 'dispel_removal',
            'quote': 'remove 1 disease effect from yourself', 'target': 'caster', 'wait_ms': 15200,
            'gameplay_clock': 'real', 'debuffs': [55095]}


def harmonic_disposition_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == HARMONIC_DISPOSITION)


def interdict_heal_block_entry(variant: str) -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == INTERDICT and entry.get('variant') == variant)


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
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == SANCTIFY and entry['kind'] == 'metric_delta')


def chakra_of_power_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == CHAKRA_OF_POWER)


def patience_duration_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == PATIENCE and 'variant' not in entry)


def patience_cooldown_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == PATIENCE and entry.get('variant') == 'cooldown')


def chastise_weapon_damage_gate_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == CHASTISE and entry['kind'] == 'metric_delta')


def libram_of_tenacity_heal_gate_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == LIBRAM_OF_TENACITY and entry.get('label_suffix') == 'heal_gate')


def temple_guardian_charge_recharge_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TEMPLE_GUARDIAN)


def sacred_resistance_armor_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == SACRED_RESISTANCE and entry.get('variant') == 'armor')


def argent_knight_while_active_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == ARGENT_KNIGHT and entry.get('variant') == 'while_active')


def righteous_tempest_requires_argent_knight_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == RIGHTEOUS_TEMPEST and entry.get('variant') == 'requires_argent_knight')


def binding_scripture_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == BINDING_SCRIPTURE)


def testament_of_strength_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TESTAMENT_OF_STRENGTH
                and entry['kind'] == 'cast_applies_aura' and 'variant' not in entry)


def argent_blade_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == ARGENT_BLADE_CAST)


def tome_of_light_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == TOME_OF_LIGHT)


def righteous_custodian_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
               if entry['spell'] == RIGHTEOUS_CUSTODIAN and entry['kind'] == 'threat_tick_ratio')


def set_aura_custodian_entry() -> dict:
    return {key: value for key, value in righteous_custodian_entry().items() if key != 'cast_target'}


def cast_applied(model: dict, before: float = 0.0, after: float = 1799000.0) -> dict:
    return {model['aura_before_label']: before, model['aura_after_label']: after}


def norgannons_wrath_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == NORGANNONS_WRATH and entry['kind'] == 'absorb_pierce_ratio')


class BehaviourEntryTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scarlet_judicator_entry(self):
        spec = target_count_spec(scarlet_judicator_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'count', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 2)
        self.assertEqual(spec.target_rank, DIVINE_FORCE_MAX_RANK)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_justice_entry(self):
        spec = target_count_spec(justice_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'count', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.target_rank, INTERDICT)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_final_prayer_entry(self):
        spec = healing_ratio_spec(final_prayer_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'ratio', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 2.0)
        self.assertEqual(spec.targets, (
            HealingRatioTarget(TESTAMENT_OF_FAITH, 'Testament of Faith', 'taken'),
            HealingRatioTarget(TESTAMENT_OF_FORTITUDE, 'Testament of Fortitude', 'effect_value', 0)))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_holy_tempest_entry(self):
        spec = aura_spread_spec(holy_tempest_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'count', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.seed_spell, CONDEMN_RANK)
        self.assertEqual(spec.aura_spell, CONDEMN_RANK)
        self.assertEqual(spec.target_rank, RIGHTEOUS_TEMPEST_RANK)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_armor_of_faith_entry(self):
        spec = shield_break_trigger_spec(armor_of_faith_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'trigger', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1)
        self.assertEqual(spec.shield_aura, STAFFGUARD_SHIELD)
        self.assertEqual(spec.trigger_spell, ARMOR_OF_FAITH_DAMAGE)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_quote_must_be_in_tooltip(self):
        with self.assertRaises(ValueError):
            behaviour_entry(RECORDS, SCARLET_JUDICATOR, 'Scarlet Judicator', 'count', 'not in the tooltip at all', 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_shield_break_trigger_spec_rejects_a_quote_not_in_the_tooltip(self):
        with self.assertRaises(ValueError):
            spec = shield_break_trigger_spec(armor_of_faith_entry())
            behaviour_entry(RECORDS, spec.spell, spec.name, 'trigger', 'not in the tooltip at all', spec.expected)

    def test_unknown_kind_is_rejected(self):
        with self.assertRaises(ValueError):
            behaviour_entry(RECORDS, SCARLET_JUDICATOR, 'Scarlet Judicator', 'ghost', 'strikes', 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_transcending_strikes_entry(self):
        spec = metric_delta_spec(transcending_strikes_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.trigger_spell, DIVINE_FORCE)
        self.assertEqual(spec.metric, 'cooldown_ms')
        self.assertEqual(spec.fields, {'spell': DIVINE_FORCE})
        self.assertEqual(spec.setup_casts, (BLADE_OF_FAITH,))
        self.assertEqual(spec.target, 'dummy')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_spiritual_abdicator_entry(self):
        spec = metric_delta_spec(spiritual_abdicator_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, -15)
        self.assertEqual(spec.trigger_spell, TESTAMENT_OF_HOPE)
        self.assertEqual(spec.metric, 'aura_amount')
        self.assertEqual(spec.fields, {'spell': TESTAMENT_OF_HOPE_AURA, 'effect': 1})
        self.assertEqual(spec.before_expected, -10)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_battlepriest_entry(self):
        spec = health_ratio_spec(battlepriest_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'ratio', spec.quote, spec.levels[0][1])
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.probe_spell, FIREBALL)
        self.assertEqual(spec.levels, ((90, 0.8), (50, 1.0), (10, 0.8)))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_battlepriest_quote_matches_dbc(self):
        self.assertEqual(
            behaviour_entry(RECORDS, BATTLEPRIEST, 'Battlepriest', 'ratio',
                            'take 20% reduced Magic damage', 0.8).quote,
            'take 20% reduced Magic damage')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_sacred_oath_entry(self):
        spec = duration_spec(sacred_oath_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'duration', spec.quote, spec.expected_ms)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(entry.expected, 1000)
        self.assertEqual(spec.target_aura, OATHKEEPER)
        self.assertEqual(spec.debt_aura, KEEPING_THE_OATH)
        self.assertEqual(spec.breaker_spell, SMITE)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_whirling_tempest_entry(self):
        spec = metric_delta_spec(whirling_tempest_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.trigger_spell, RIGHTEOUS_TEMPEST)
        self.assertEqual(spec.metric, 'run_speed_rate')
        self.assertEqual(spec.expected, 1.20)
        self.assertEqual(spec.before_expected, 1.0)
        self.assertIsNone(spec.setup_actor_aura)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_whirling_tempest_stacks_with_courage_entry(self):
        spec = metric_delta_spec(whirling_tempest_stacks_with_courage_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, WHIRLING_TEMPEST)
        self.assertEqual(spec.setup_actor_aura, COURAGE_RANK_1)
        self.assertEqual(spec.expected, 1.32)
        self.assertEqual(spec.before_expected, 1.10)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_sacred_resistance_armor_entry(self):
        spec = metric_delta_spec(sacred_resistance_armor_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.trigger_spell, RECKONING_AT_60)
        self.assertEqual(spec.metric, 'armor')
        self.assertEqual(spec.fields, {})
        self.assertEqual(spec.target, 'dummy')
        self.assertEqual(spec.before_expected, 299)
        self.assertEqual(spec.expected, 343)
        self.assertEqual(spec.gate_timing, 'between')
        self.assertFalse(spec.trigger_only_after)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_argent_knight_while_active_entry(self):
        spec = metric_delta_spec(argent_knight_while_active_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, ARGENT_KNIGHT)
        self.assertEqual(spec.trigger_spell, RIGHTEOUS_TEMPEST)
        self.assertEqual(spec.gate_spell, ARGENT_KNIGHT)
        self.assertEqual(spec.metric, 'aura_amount')
        self.assertEqual(spec.fields, {'spell': RIGHTEOUS_TEMPEST, 'effect': 1})
        self.assertEqual(spec.before_expected, 0)
        self.assertEqual(spec.expected, -20)
        self.assertEqual(spec.gate_timing, 'start')
        self.assertTrue(spec.trigger_only_after)
        self.assertEqual(spec.expiry_wait_ms, 4000)
        self.assertEqual(spec.after_expiry_expected, 0)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_righteous_tempest_requires_argent_knight_entry(self):
        spec = metric_delta_spec(righteous_tempest_requires_argent_knight_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, RIGHTEOUS_TEMPEST)
        self.assertEqual(spec.trigger_spell, RIGHTEOUS_TEMPEST)
        self.assertEqual(spec.gate_spell, ARGENT_KNIGHT)
        self.assertEqual(spec.metric, 'aura_amount')
        self.assertEqual(spec.fields, {'spell': RIGHTEOUS_TEMPEST, 'effect': 1})
        self.assertEqual(spec.before_expected, 0)
        self.assertEqual(spec.expected, -20)
        self.assertEqual(spec.gate_timing, 'between')
        self.assertFalse(spec.trigger_only_after)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_binding_scripture_entry(self):
        spec = aura_metric_delta_spec(binding_scripture_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'aura_metric_delta', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, BINDING_SCRIPTURE)
        self.assertEqual(spec.aura_spell, BINDING_SCRIPTURE_DAMAGE_REDUCTION)
        self.assertEqual(spec.metric, 'melee_damage_taken')
        self.assertEqual(spec.fields, {'target': 'dummy'})
        self.assertEqual(spec.aura_stacks, 1)
        self.assertEqual(spec.target, 'dummy')
        self.assertEqual(spec.before_expected, 1000)
        self.assertEqual(spec.expected, 950)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_testament_of_strength_entry(self):
        spec = cast_applies_aura_spec(testament_of_strength_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'cast_applies_aura', spec.quote, spec.expected_ms)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, TESTAMENT_OF_STRENGTH)
        self.assertEqual(spec.applied_aura, SACRED_RESTRAINT)
        self.assertEqual(spec.target, 'caster')
        self.assertEqual(spec.expected_ms, 60000)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_argent_blade_entry(self):
        spec = cast_leech_ratio_spec(argent_blade_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'ratio', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, ARGENT_BLADE_CAST)
        self.assertEqual(spec.heal_spell, ARGENT_BLADE_HEAL)
        self.assertEqual(spec.expected, 1.0)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_tome_of_light_entry(self):
        spec = cast_stat_ratio_spec(tome_of_light_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'cast_stat_ratio', spec.quote, spec.expected)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, TOME_OF_LIGHT)
        self.assertEqual(spec.stat_metric, 'max_health')
        self.assertEqual(spec.effect, 1)
        self.assertEqual(spec.expected, 1.0)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_righteous_custodian_entry(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        entry = behaviour_entry(RECORDS, spec.spell, spec.name, 'threat_tick_ratio', spec.quote,
                                spec.expected_ratio)
        self.assertIn(spec.quote, entry.tooltip)
        self.assertEqual(spec.spell, RIGHTEOUS_CUSTODIAN)
        self.assertEqual(spec.aura_spell, RIGHTEOUS_CUSTODIAN)
        self.assertEqual(spec.expected_ratio, 0.98)
        self.assertEqual(spec.aura_stacks, 1)


class BehaviourEntriesLookupTests(unittest.TestCase):
    def test_behaviour_entries_filters_by_spell(self):
        chosen = behaviour_entries(CLASS_FILE, [SCARLET_JUDICATOR])
        self.assertEqual([entry['spell'] for entry in chosen], [SCARLET_JUDICATOR])

    def test_behaviour_entries_rejects_unknown_spell(self):
        with self.assertRaises(ValueError):
            behaviour_entries(CLASS_FILE, [1])

    def test_behaviour_entries_everything_by_default(self):
        self.assertEqual(len(behaviour_entries(CLASS_FILE, None)), 506)


class TargetCountScenarioTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_validates_and_shapes_fixtures(self):
        spec = target_count_spec(scarlet_judicator_entry())
        scenario, expectations = target_count_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 4)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_COUNT)
        self.assertTrue(expectation.rule.startswith('prose: "strikes 2 additional enemies'))
        self.assertEqual(len(expectation.model['dummy_labels']), 3)
        self.assertEqual(expectation.model['headroom'], 1)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_candidate_lies_inside_the_radius_of_the_primary(self):
        spec = target_count_spec(scarlet_judicator_entry())
        scenario, _ = target_count_scenario(CLASS_FILE, spec)
        creatures = {c['id']: c for c in run.validate(scenario)['creatures']}
        primary = creatures.pop('primary')['distance']
        self.assertEqual(len(creatures), spec.expected + 1)
        for creature in creatures.values():
            self.assertLess(creature['distance'] - primary, spec.radius)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_damage_counts_are_read_on_every_dummy_after_every_cast_of_the_judged_phase(self):
        spec = target_count_spec(scarlet_judicator_entry())
        scenario, expectations = target_count_scenario(CLASS_FILE, spec)
        per_cast = expectations[0].model['per_cast']
        self.assertEqual(len(per_cast['casts']), spec.repeats)
        self.assertEqual(per_cast['start'][0], f'{SCARLET_JUDICATOR} primary spell_damage_count before')
        labels = {step.get('label') for step in run.validate(scenario)['steps']}
        self.assertTrue(all(label in labels for cast in per_cast['casts'] for label in cast))
        _, justice = target_count_scenario(CLASS_FILE, target_count_spec(justice_entry()))
        self.assertNotIn('per_cast', justice[0].model)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, justice_entry())
        self.assertEqual(len(run.validate(scenario)['creatures']), 3)
        self.assertEqual(expectations[0].check, BEHAVIOUR_COUNT)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_justice_entry_reads_the_silence_aura_not_spell_damage_count(self):
        spec = target_count_spec(justice_entry())
        self.assertEqual(spec.metric, 'aura')
        scenario, _ = target_count_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura' and step.get('spell') == INTERDICT]
        self.assertEqual(len(measure_steps), 6)
        for step in measure_steps:
            self.assertEqual(step['caster'], 'caster')
            self.assertIn(step['actor'], ('primary', 'extra1', 'extra2'))

    def test_scarlet_judicator_entry_reads_spell_damage_count(self):
        spec = target_count_spec(scarlet_judicator_entry())
        self.assertEqual(spec.metric, 'spell_damage_count')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_validates_and_shapes_fixtures(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        scenario, expectations = fixed_target_count_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 4)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_FIXED_COUNT)
        self.assertTrue(expectation.rule.startswith('prose: "and an additional nearby enemy'))
        self.assertEqual(len(expectation.model['dummy_labels']), 2)
        self.assertEqual(expectation.model['headroom'], 1)
        self.assertIsNotNone(expectation.model['far_label'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_far_dummy_sits_beyond_the_radius(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        scenario, _ = fixed_target_count_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        creatures_by_id = {c['id']: c for c in validated['creatures']}
        self.assertGreater(creatures_by_id['extra3']['distance'] - creatures_by_id['primary']['distance'],
                           spec.radius)
        for near in ('extra1', 'extra2'):
            self.assertLess(creatures_by_id[near]['distance'] - creatures_by_id['primary']['distance'], spec.radius)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, holy_cleave_entry())
        self.assertEqual(len(run.validate(scenario)['creatures']), 4)
        self.assertEqual(expectations[0].check, BEHAVIOUR_FIXED_COUNT)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_single_phase_has_no_before_measurement(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        scenario, _ = fixed_target_count_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('action') == 'assert' and step.get('metric') == spec.metric
                         and step.get('spell') == spec.target_rank]
        self.assertEqual(len([step for step in measure_steps if step['label'].endswith(' after')]), 4)
        self.assertFalse([step for step in measure_steps if step['label'].endswith(' before')])
        self.assertEqual(len(measure_steps), 4 + 3 * (spec.repeats + 1))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_listed_auras_are_cleared_before_every_cast(self):
        spec = fixed_target_count_spec({**holy_cleave_entry(), 'clear_auras': [804903]})
        scenario, _ = fixed_target_count_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), spec.repeats)
        for index in casts:
            cleared = [step for step in steps[max(0, index - 4):index]
                       if step['action'] == 'set_aura' and step['spell'] == 804903 and step['stacks'] == 0]
            self.assertEqual(len(cleared), 1)

    def test_the_templar_holy_cleave_entry_clears_its_own_oath(self):
        entry = next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == HOLY_CLEAVE
                     and entry['kind'] == 'fixed_count')
        self.assertEqual(fixed_target_count_spec(entry).clear_auras, (804903,))

    def test_cast_spell_defaults_to_the_claim_spell(self):
        spec = fixed_target_count_spec(holy_cleave_entry())
        self.assertEqual(spec.cast_spell, HOLY_CLEAVE)
        self.assertEqual(spec.target_rank, HOLY_CLEAVE)

    def test_cast_spell_and_target_rank_can_be_overridden(self):
        entry = {**holy_cleave_entry(), 'cast_spell': 1, 'target_rank': 2}
        spec = fixed_target_count_spec(entry)
        self.assertEqual(spec.cast_spell, 1)
        self.assertEqual(spec.target_rank, 2)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    def test_active_aura_is_cast_on_the_caster_between_its_learn_and_the_after_phase(self):
        spec = ally_heal_breadth_spec(libram_of_grace_entry())
        scenario, _ = ally_heal_breadth_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        learn_index = next(index for index, step in enumerate(steps)
                           if step.get('action') == 'learn' and step.get('spell') == spec.spell)
        aura_casts = [index for index, step in enumerate(steps)
                      if step.get('action') == 'cast' and step.get('spell') == spec.spell]
        self.assertEqual(len(aura_casts), 1)
        self.assertEqual(steps[aura_casts[0]]['target'], 'caster')
        later_trigger_casts = [index for index, step in enumerate(steps)
                               if index > aura_casts[0] and step.get('action') == 'cast'
                               and step.get('spell') == spec.trigger_spell]
        self.assertEqual(len(later_trigger_casts), spec.repeats)
        self.assertLess(learn_index, aura_casts[0])
        self.assertTrue(any(step.get('action') == 'reset_cooldown' and step.get('spell') == spec.spell
                            for step in steps[learn_index:aura_casts[0]]))

    def test_passive_is_learned_without_a_cast(self):
        spec = ally_heal_breadth_spec(chakra_of_light_entry())
        scenario, _ = ally_heal_breadth_scenario(CLASS_FILE, spec)
        self.assertFalse(any(step.get('action') == 'cast' and step.get('spell') == spec.spell
                             for step in scenario['steps']))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AuraSpreadScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_fixtures(self):
        spec = aura_spread_spec(holy_tempest_entry())
        scenario, expectations = aura_spread_scenario(CLASS_FILE, spec)
        validated = run.validate(scenario)
        self.assertEqual(len(validated['creatures']), 3)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_COUNT)
        self.assertTrue(expectation.rule.startswith('prose: "spreads Condemn on affected enemies'))
        self.assertEqual(len(expectation.model['dummy_labels']), 2)
        self.assertEqual(expectation.model['expected'], 1)
        self.assertEqual(expectation.model['headroom'], 1)

    def test_first_tick_extras_sit_beyond_the_tick_reach_and_within_the_spread_radius(self):
        spec = aura_spread_spec(holy_tempest_entry())
        scenario, _ = aura_spread_scenario(CLASS_FILE, spec)
        reach = RECORDS.radius(RECORDS.field('Spell', RIGHTEOUS_TEMPEST_RANK, 'EffectTriggerSpell[0]'), 0)
        primary, *extras = [creature['distance'] for creature in scenario['creatures']]
        for distance in extras:
            self.assertGreater(distance, reach + 2.0)
            self.assertLess(distance - primary, spec.radius)

    def test_first_tick_reads_once_per_phase_before_the_second_tick(self):
        spec = aura_spread_spec(holy_tempest_entry())
        scenario, _ = aura_spread_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        amplitude = RECORDS.field('Spell', RIGHTEOUS_TEMPEST_RANK, 'EffectAmplitude[0]')
        casts = [index for index, step in enumerate(steps)
                 if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_TEMPEST_RANK]
        self.assertEqual(len(casts), 2)
        for index in casts:
            moment = 'before' if index == casts[0] else 'after'
            self.assertEqual(steps[index - 1]['label'], f'{HOLY_TEMPEST} primary hits {moment} start')
            self.assertLess(steps[index + 1]['ms'], amplitude)
            self.assertEqual(steps[index + 2]['spell'], RECORDS.field('Spell', RIGHTEOUS_TEMPEST_RANK,
                                                                       'EffectTriggerSpell[0]'))
        learned = first_index(steps, action='learn', spell=HOLY_TEMPEST)
        settle = steps[learned - 1]
        self.assertEqual(settle['label'], 'periodic buff end')
        self.assertGreaterEqual(steps[casts[0] + 1]['ms'] + settle['ms'],
                                RECORDS.duration_ms(RIGHTEOUS_TEMPEST_RANK))

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, holy_tempest_entry())
        self.assertEqual(len(run.validate(scenario)['creatures']), 3)
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
        self.assertEqual(len(aura_steps), 4)
        self.assertEqual([step['actor'] for step in aura_steps], ['extra1', 'extra2'] * 2)
        for step in aura_steps:
            self.assertEqual(step['caster'], 'caster')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, spiritual_abdicator_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], -15)
        self.assertEqual(expectations[0].model['before_expected'], -10)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_measures_the_declared_metric_and_fields_before_and_after(self):
        spec = metric_delta_spec(spiritual_abdicator_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_amount' and step.get('spell') == 704409]
        self.assertEqual(len(measure_steps), 2)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')
            self.assertEqual(step['effect'], 1)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_waits_the_expire_ms_between_the_learn_and_the_second_cast(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        learn_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('action') == 'learn' and step.get('spell') == TYRS_GUARD)
        expire_wait = scenario['steps'][learn_index + 1]
        self.assertEqual(expire_wait['action'], 'wait')
        self.assertEqual(expire_wait['ms'], spec.expire_ms)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_learns_the_trigger_spell_once_before_the_first_cast(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        trigger_learn_steps = [index for index, step in enumerate(scenario['steps'])
                               if step.get('action') == 'learn' and step.get('spell') == TESTAMENT_OF_HOPE]
        first_cast_index = next(index for index, step in enumerate(scenario['steps'])
                                if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_HOPE)
        self.assertEqual(len(trigger_learn_steps), 1)
        self.assertLess(trigger_learn_steps[0], first_cast_index)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_default_target_stays_caster_without_a_creature_fixture(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_HOPE]
        self.assertTrue(all(step['target'] == 'caster' for step in cast_steps))
        self.assertNotIn('creatures', scenario)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dummy_target_casts_at_the_creature_fixture_and_adds_it(self):
        spec = metric_delta_spec(warrior_of_tyr_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == CONDEMN]
        self.assertTrue(all(step['target'] == 'dummy' for step in cast_steps))
        self.assertEqual(len(scenario['creatures']), 1)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_warrior_of_tyr_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, warrior_of_tyr_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 10)
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['metric'], 'power')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_disable_regeneration_overrides_the_player_fixture(self):
        spec = metric_delta_spec(warrior_of_tyr_entry())
        self.assertTrue(spec.disable_regeneration)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['players'][0]['allow_regeneration'], False)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_regeneration_stays_enabled_by_default(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        self.assertFalse(spec.disable_regeneration)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        self.assertNotIn('allow_regeneration', scenario['players'][0])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_sacred_resistance_casts_reckoning_at_the_dummy_fixture(self):
        spec = metric_delta_spec(sacred_resistance_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == RECKONING_AT_60]
        self.assertEqual(len(cast_steps), 2)
        self.assertTrue(all(step['target'] == 'dummy' for step in cast_steps))
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_sacred_resistance_measures_the_reckoning_armor_aura(self):
        spec = metric_delta_spec(sacred_resistance_entry())
        scenario, expectations = metric_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura' and step.get('spell') == RECKONING_ARMOR]
        self.assertEqual(len(measure_steps), 2)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_sacred_resistance_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, sacred_resistance_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['metric'], 'aura')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_trigger_only_after_skips_the_trigger_cast_in_the_before_phase(self):
        spec = metric_delta_spec(argent_knight_while_active_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == RIGHTEOUS_TEMPEST]
        self.assertEqual(len(cast_steps), 1)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_gate_timing_start_learns_the_gate_before_the_before_measurement(self):
        spec = metric_delta_spec(argent_knight_while_active_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        gate_index = next(index for index, step in enumerate(steps)
                          if step.get('action') == 'learn' and step.get('spell') == ARGENT_KNIGHT)
        before_index = next(index for index, step in enumerate(steps)
                            if step.get('metric') == 'aura_amount' and step.get('spell') == RIGHTEOUS_TEMPEST)
        self.assertLess(gate_index, before_index)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_gate_timing_between_learns_the_gate_after_the_before_measurement(self):
        spec = metric_delta_spec(righteous_tempest_requires_argent_knight_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        gate_index = next(index for index, step in enumerate(steps)
                          if step.get('action') == 'learn' and step.get('spell') == ARGENT_KNIGHT)
        before_index = next(index for index, step in enumerate(steps)
                            if step.get('metric') == 'aura_amount' and step.get('spell') == RIGHTEOUS_TEMPEST)
        self.assertGreater(gate_index, before_index)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_while_active_shape_catches_a_wrong_after_reading(self):
        spec = metric_delta_spec(argent_knight_while_active_entry())
        _, expectations = metric_delta_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        expired_label = expectation.model['expired_label']
        wrong_run = FakeRun({expectation.model['before_label']: 0.0, expectation.model['after_label']: 0.0,
                             expired_label: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        right_run = FakeRun({expectation.model['before_label']: 0.0, expectation.model['after_label']: -20.0,
                            expired_label: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), right_run, expectation)
        self.assertEqual(verdict.status, 'ok')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_while_active_shape_catches_the_effect_outliving_its_own_aura(self):
        spec = metric_delta_spec(argent_knight_while_active_entry())
        _, expectations = metric_delta_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        expired_label = expectation.model['expired_label']
        self.assertEqual(expectation.model['after_expiry_expected'], 0)
        leaking_run = FakeRun({expectation.model['before_label']: 0.0, expectation.model['after_label']: -20.0,
                               expired_label: -20.0})
        verdict = judge_behaviour(base_verdict(expectation), leaking_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        expired_run = FakeRun({expectation.model['before_label']: 0.0, expectation.model['after_label']: -20.0,
                               expired_label: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), expired_run, expectation)
        self.assertEqual(verdict.status, 'ok')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_expiry_wait_phase_adds_a_third_measurement_past_the_triggering_aura_duration(self):
        spec = metric_delta_spec(argent_knight_while_active_entry())
        scenario, expectations = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura_amount' and step.get('spell') == RIGHTEOUS_TEMPEST]
        self.assertEqual(len(measure_steps), 3)
        self.assertEqual(measure_steps[-1]['label'], expectations[0].model['expired_label'])
        total_wait_after_cast = spec.wait_ms + spec.expiry_wait_ms
        self.assertGreater(total_wait_after_cast, 3000)

    def test_expiry_wait_requires_gate_timing_start(self):
        spec = replace(metric_delta_spec(argent_knight_while_active_entry()), gate_timing='between')
        with self.assertRaises(ValueError):
            metric_delta_scenario(CLASS_FILE, spec)

    def test_expiry_wait_and_after_expiry_expected_are_required_together(self):
        spec = replace(metric_delta_spec(argent_knight_while_active_entry()), after_expiry_expected=None)
        with self.assertRaises(ValueError):
            metric_delta_scenario(CLASS_FILE, spec)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_label_suffix_disambiguates_a_second_metric_delta_check_on_the_same_spell(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        _, plain = metric_delta_scenario(CLASS_FILE, spec)
        _, suffixed = metric_delta_scenario(CLASS_FILE, replace(spec, label_suffix='owned_creature_count'))
        self.assertEqual(plain[0].label, f'{TYRS_GUARD} behaviour_metric_delta')
        self.assertEqual(suffixed[0].label, f'{TYRS_GUARD} behaviour_metric_delta owned_creature_count')

    def test_measure_actor_defaults_to_caster(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        self.assertEqual(spec.measure_actor, 'caster')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_measure_actor_on_a_dummy_adds_the_creature_fixture_even_without_a_dummy_cast_target(self):
        spec = replace(metric_delta_spec(tyrs_guard_entry()), measure_actor='dummy')
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_patience_duration_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, patience_duration_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'aura_duration_ms')
        self.assertEqual(expectations[0].model['tolerance'], 10)
        self.assertEqual(expectations[0].label, f'{PATIENCE} behaviour_metric_delta duration')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_entries_without_an_explicit_tolerance_omit_it_from_the_model(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, tyrs_guard_entry())
        self.assertNotIn('tolerance', expectations[0].model)
        scenario, expectations = behaviour_scenario(CLASS_FILE, patience_cooldown_entry())
        self.assertNotIn('tolerance', expectations[0].model)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_patience_cooldown_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, patience_cooldown_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'cooldown_ms')
        self.assertEqual(expectations[0].label, f'{PATIENCE} behaviour_metric_delta cooldown')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_chastise_weapon_damage_gate_judges_a_wrong_after_value_as_alert(self):
        _, expectations = behaviour_scenario(CLASS_FILE, chastise_weapon_damage_gate_entry())
        expectation = expectations[0]
        correct = {'503141 spell_effect_value before': 0.0, '503141 spell_effect_value after': 150.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(correct), expectation).status, 'ok')
        seeded_wrong = {'503141 spell_effect_value before': 0.0, '503141 spell_effect_value after': 0.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(seeded_wrong), expectation).status,
                         'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_libram_of_tenacity_heal_gate_judges_a_wrong_after_value_as_alert(self):
        _, expectations = behaviour_scenario(CLASS_FILE, libram_of_tenacity_heal_gate_entry())
        expectation = expectations[0]
        correct = {'801461 spell_effect_value before': 0.0, '801461 spell_effect_value after': 20.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(correct), expectation).status, 'ok')
        seeded_wrong = {'801461 spell_effect_value before': 0.0, '801461 spell_effect_value after': 0.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(seeded_wrong), expectation).status,
                         'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_empty_setup_casts_reproduces_the_scenario_byte_for_byte(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        with_field, _ = metric_delta_scenario(CLASS_FILE, spec)
        without_field, _ = metric_delta_scenario(CLASS_FILE, replace(spec, setup_casts=()))
        self.assertEqual(with_field, without_field)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AuraMetricDeltaScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = aura_metric_delta_spec(binding_scripture_entry())
        scenario, expectations = aura_metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_METRIC_DELTA)
        self.assertTrue(expectation.rule.startswith('prose: "reduces your damage taken by"'))
        self.assertEqual(expectation.model['kind'], 'metric_delta')
        self.assertEqual(expectation.model['expected'], 950)
        self.assertEqual(expectation.model['before_expected'], 1000)
        self.assertEqual(expectation.model['metric'], 'melee_damage_taken')

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, binding_scripture_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 950)
        self.assertEqual(expectations[0].model['before_expected'], 1000)

    def test_measures_the_metric_before_and_after_setting_the_aura(self):
        spec = aura_metric_delta_spec(binding_scripture_entry())
        scenario, _ = aura_metric_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'melee_damage_taken' and step.get('target') == 'dummy']
        self.assertEqual(len(measure_steps), 2)
        for step in measure_steps:
            self.assertEqual(step['actor'], 'caster')

    def test_set_aura_happens_between_the_before_and_after_measurements(self):
        spec = aura_metric_delta_spec(binding_scripture_entry())
        scenario, _ = aura_metric_delta_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        measure_indexes = [index for index, step in enumerate(steps) if step.get('metric') == 'melee_damage_taken']
        reduction = BINDING_SCRIPTURE_DAMAGE_REDUCTION
        set_aura_index = next(index for index, step in enumerate(steps)
                              if step.get('action') == 'set_aura' and step.get('spell') == reduction)
        self.assertEqual(len(measure_indexes), 2)
        self.assertLess(measure_indexes[0], set_aura_index)
        self.assertLess(set_aura_index, measure_indexes[1])
        set_aura_step = steps[set_aura_index]
        self.assertEqual(set_aura_step['actor'], 'caster')
        self.assertEqual(set_aura_step['stacks'], 1)

    def test_dummy_target_adds_the_creature_fixture(self):
        spec = aura_metric_delta_spec(binding_scripture_entry())
        scenario, _ = aura_metric_delta_scenario(CLASS_FILE, spec)
        self.assertEqual(len(scenario['creatures']), 1)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_caster_target_skips_the_creature_fixture(self):
        spec = aura_metric_delta_spec(binding_scripture_entry())
        scenario, _ = aura_metric_delta_scenario(CLASS_FILE, replace(spec, target='caster', fields={}))
        self.assertNotIn('creatures', scenario)

    def test_wrong_after_reading_is_caught(self):
        spec = aura_metric_delta_spec(binding_scripture_entry())
        _, expectations = aura_metric_delta_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        wrong_run = FakeRun({expectation.model['before_label']: 1000.0, expectation.model['after_label']: 1000.0})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        right_run = FakeRun({expectation.model['before_label']: 1000.0, expectation.model['after_label']: 950.0})
        verdict = judge_behaviour(base_verdict(expectation), right_run, expectation)
        self.assertEqual(verdict.status, 'ok')


class CastAppliesAuraScenarioTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_validates_and_shapes_expectations(self):
        spec = cast_applies_aura_spec(testament_of_strength_entry())
        scenario, expectations = cast_applies_aura_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_CAST_APPLIES_AURA)
        self.assertTrue(expectation.rule.startswith('prose: "Applies Sacred Restraint for"'))
        self.assertEqual(expectation.model['kind'], 'cast_applies_aura')
        self.assertEqual(expectation.model['expected_ms'], 60000)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, testament_of_strength_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_CAST_APPLIES_AURA)
        self.assertEqual(expectations[0].model['expected_ms'], 60000)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_learn_then_cast_happens_between_the_before_and_after_measurements(self):
        spec = cast_applies_aura_spec(testament_of_strength_entry())
        scenario, _ = cast_applies_aura_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        measure_indexes = [index for index, step in enumerate(steps)
                           if step.get('metric') == 'aura_duration_ms' and step.get('spell') == SACRED_RESTRAINT]
        cast_index = next(index for index, step in enumerate(steps)
                          if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_STRENGTH)
        learn_index = next(index for index, step in enumerate(steps)
                           if step.get('action') == 'learn' and step.get('spell') == TESTAMENT_OF_STRENGTH)
        self.assertEqual(len(measure_indexes), 2)
        self.assertLess(learn_index, measure_indexes[0])
        self.assertLess(measure_indexes[0], cast_index)
        self.assertLess(cast_index, measure_indexes[1])
        cast_step = steps[cast_index]
        self.assertEqual(cast_step['actor'], 'caster')
        self.assertEqual(cast_step['target'], 'caster')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_caster_target_skips_the_creature_fixture(self):
        spec = cast_applies_aura_spec(testament_of_strength_entry())
        scenario, _ = cast_applies_aura_scenario(CLASS_FILE, spec)
        self.assertNotIn('creatures', scenario)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_wrong_after_reading_is_caught(self):
        spec = cast_applies_aura_spec(testament_of_strength_entry())
        _, expectations = cast_applies_aura_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        wrong_run = FakeRun({expectation.model['before_label']: 0.0, expectation.model['after_label']: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        right_run = FakeRun({expectation.model['before_label']: 0.0, expectation.model['after_label']: 59985.0})
        verdict = judge_behaviour(base_verdict(expectation), right_run, expectation)
        self.assertEqual(verdict.status, 'ok')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_aura_present_before_the_cast_is_caught(self):
        spec = cast_applies_aura_spec(testament_of_strength_entry())
        _, expectations = cast_applies_aura_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        wrong_run = FakeRun({expectation.model['before_label']: 60000.0, expectation.model['after_label']: 59985.0})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_setup_casts_learn_blade_of_faith_once_before_the_first_cast(self):
        spec = metric_delta_spec(transcending_strikes_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        learn_steps = [index for index, step in enumerate(scenario['steps'])
                      if step.get('action') == 'learn' and step.get('spell') == BLADE_OF_FAITH]
        first_cast_index = next(index for index, step in enumerate(scenario['steps'])
                                if step.get('action') == 'cast' and step.get('spell') == BLADE_OF_FAITH)
        self.assertEqual(len(learn_steps), 1)
        self.assertLess(learn_steps[0], first_cast_index)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_setup_casts_restore_the_trigger_spells_own_power_before_its_cast(self):
        spec = metric_delta_spec(transcending_strikes_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        divine_force_index = steps.index({'action': 'cast', 'actor': 'caster', 'spell': DIVINE_FORCE,
                                          'target': 'dummy'})
        preceding_power = steps[divine_force_index - 1]
        self.assertEqual(preceding_power, {'action': 'set_power', 'actor': 'caster', 'power': 3, 'value': 15})

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_transcending_strikes_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, transcending_strikes_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['metric'], 'cooldown_ms')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_setup_actor_aura_defaults_to_no_extra_set_aura_steps(self):
        spec = metric_delta_spec(whirling_tempest_entry())
        self.assertIsNone(spec.setup_actor_aura)
        with_field, _ = metric_delta_scenario(CLASS_FILE, spec)
        without_field, _ = metric_delta_scenario(CLASS_FILE, replace(spec, setup_actor_aura=None))
        self.assertEqual(with_field, without_field)
        set_aura_spells = {step['spell'] for step in with_field['steps'] if step.get('action') == 'set_aura'}
        self.assertNotIn(COURAGE_RANK_1, set_aura_spells)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_whirling_tempest_waits_500ms_not_the_default_3000ms(self):
        spec = metric_delta_spec(whirling_tempest_entry())
        self.assertEqual(spec.wait_ms, 500)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        wait_steps = [step for step in scenario['steps']
                     if step.get('action') == 'wait' and step.get('ms') == 500 and 'label' not in step]
        self.assertTrue(wait_steps)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_whirling_tempest_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, whirling_tempest_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1.20)
        self.assertEqual(expectations[0].model['before_expected'], 1.0)
        self.assertEqual(expectations[0].model['metric'], 'run_speed_rate')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_whirling_tempest_stacks_with_courage_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, whirling_tempest_stacks_with_courage_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1.32)
        self.assertEqual(expectations[0].model['before_expected'], 1.10)
        self.assertEqual(expectations[0].model['metric'], 'run_speed_rate')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_sanctify_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, sanctify_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 2272.727294921875)
        self.assertEqual(expectations[0].model['before_expected'], 2500.0)
        self.assertEqual(expectations[0].model['metric'], 'attack_time_ms')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_sanctify_casts_libram_of_tenacity_at_self_in_both_phases(self):
        spec = metric_delta_spec(sanctify_entry())
        self.assertEqual(spec.trigger_spell, LIBRAM_OF_TENACITY)
        self.assertEqual(spec.target, 'caster')
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == LIBRAM_OF_TENACITY]
        self.assertEqual(len(cast_steps), 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_transcending_strikes_target_gate_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, transcending_strikes_target_gate_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 86994)
        self.assertEqual(expectations[0].model['before_expected'], 116994)
        self.assertEqual(expectations[0].model['metric'], 'cooldown_ms')
        self.assertTrue(expectations[0].label.endswith('target_gate'))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_chakra_of_power_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, chakra_of_power_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_CRIT_MAGNITUDE)
        self.assertEqual(expectations[0].model['base_expected'], 1.0)
        self.assertEqual(expectations[0].model['crit_bonus_expected'], 2.0)
        self.assertEqual(expectations[0].model['metric'], 'spell_energize_total')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_keeping_the_oath_passive_casts_reckoning_at_the_dummy_fixture(self):
        spec = metric_delta_spec(keeping_the_oath_passive_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == RECKONING_AT_60]
        self.assertEqual(len(cast_steps), 2)
        self.assertTrue(all(step['target'] == 'dummy' for step in cast_steps))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_keeping_the_oath_passive_measures_the_oath_chain_aura(self):
        spec = metric_delta_spec(keeping_the_oath_passive_entry())
        scenario, expectations = metric_delta_scenario(CLASS_FILE, spec)
        measure_steps = [step for step in scenario['steps']
                         if step.get('metric') == 'aura' and step.get('spell') == OATH_CHAIN]
        self.assertEqual(len(measure_steps), 2)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_keeping_the_oath_passive_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, keeping_the_oath_passive_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 1)
        self.assertEqual(expectations[0].model['before_expected'], 0)
        self.assertEqual(expectations[0].model['metric'], 'aura')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cast_in_before_defaults_to_true_and_casts_the_trigger_in_both_phases(self):
        spec = metric_delta_spec(tyrs_guard_entry())
        self.assertTrue(spec.cast_in_before)
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        cast_steps = [step for step in scenario['steps']
                     if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_HOPE]
        self.assertEqual(len(cast_steps), 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cast_in_before_false_skips_casting_the_trigger_before_the_baseline_measurement(self):
        spec = metric_delta_spec(crusaders_presence_speed_entry())
        self.assertFalse(spec.cast_in_before)
        scenario, expectations = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        before_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('metric') == 'run_speed_rate' and step.get('label') ==
                            metric_delta_label(spec, BEFORE))
        cast_steps_before_baseline = [step for step in scenario['steps'][:before_index]
                                      if step.get('action') == 'cast' and step.get('spell') == CRUSADERS_PRESENCE]
        self.assertEqual(len(cast_steps_before_baseline), 0)
        all_cast_steps = [step for step in scenario['steps']
                         if step.get('action') == 'cast' and step.get('spell') == CRUSADERS_PRESENCE]
        self.assertEqual(len(all_cast_steps), 1)
        self.assertEqual(expectations[0].model['before_expected'], 1.60)
        self.assertEqual(expectations[0].model['expected'], 2.40)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cast_in_before_false_still_sets_the_setup_actor_aura_in_the_baseline_phase(self):
        spec = metric_delta_spec(crusaders_presence_speed_entry())
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        before_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('metric') == 'run_speed_rate' and step.get('label') ==
                            metric_delta_label(spec, BEFORE))
        set_aura_before_baseline = [step for step in scenario['steps'][:before_index]
                                    if step.get('action') == 'set_aura' and step.get('spell') == spec.setup_actor_aura]
        self.assertEqual(len(set_aura_before_baseline), 1)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cast_in_before_false_with_a_seeded_wrong_before_expected_alerts(self):
        spec = replace(metric_delta_spec(crusaders_presence_speed_entry()), before_expected=1.0)
        _, expectations = metric_delta_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        values = {metric_delta_label(spec, BEFORE): 1.60, metric_delta_label(spec, AFTER): 2.40}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_crusaders_presence_speed_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, crusaders_presence_speed_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectations[0].model['expected'], 2.40)
        self.assertEqual(expectations[0].model['before_expected'], 1.60)
        self.assertEqual(expectations[0].model['metric'], 'run_speed_rate')


class ThreatTickRatioScenarioTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_validates_and_shapes_expectations(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        scenario, expectations = threat_tick_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_METRIC_RATIO_DELTA)
        self.assertTrue(expectation.rule.startswith('prose: "reducing their total threat by"'))
        self.assertEqual(expectation.model['kind'], 'metric_ratio_delta')
        self.assertEqual(expectation.model['expected_ratio'], 0.98)
        self.assertEqual(expectation.model['metric'], 'threat')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, righteous_custodian_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_METRIC_RATIO_DELTA)
        self.assertEqual(expectations[0].model['expected_ratio'], 0.98)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_attack_builds_threat_before_the_before_measurement(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        scenario, _ = threat_tick_ratio_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        attack_index = next(index for index, step in enumerate(steps) if step.get('action') == 'attack')
        stop_index = next(index for index, step in enumerate(steps) if step.get('action') == 'stop_attack')
        before_index = next(index for index, step in enumerate(steps)
                            if step.get('metric') == 'threat' and step.get('label', '').endswith('before'))
        self.assertLess(attack_index, stop_index)
        self.assertLess(stop_index, before_index)
        self.assertEqual(steps[attack_index]['actor'], 'caster')
        self.assertEqual(steps[attack_index]['target'], 'dummy')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_set_aura_happens_between_the_before_and_after_measurements(self):
        spec = threat_tick_ratio_spec(set_aura_custodian_entry())
        scenario, _ = threat_tick_ratio_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        measure_indexes = [index for index, step in enumerate(steps) if step.get('metric') == 'threat']
        set_aura_index = next(index for index, step in enumerate(steps)
                              if step.get('action') == 'set_aura' and step.get('spell') == RIGHTEOUS_CUSTODIAN)
        self.assertEqual(len(measure_indexes), 2)
        self.assertLess(measure_indexes[0], set_aura_index)
        self.assertLess(set_aura_index, measure_indexes[1])
        for index in measure_indexes:
            self.assertEqual(steps[index]['actor'], 'dummy')
            self.assertEqual(steps[index]['target'], 'caster')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_always_has_the_creature_fixture(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        scenario, _ = threat_tick_ratio_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_wrong_after_reading_is_caught(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        _, expectations = threat_tick_ratio_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        applied = cast_applied(expectation.model)
        wrong_run = FakeRun({expectation.model['before_label']: 1000.0, expectation.model['after_label']: 1000.0,
                             **applied})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        right_run = FakeRun({expectation.model['before_label']: 1000.0, expectation.model['after_label']: 980.0,
                             **applied})
        verdict = judge_behaviour(base_verdict(expectation), right_run, expectation)
        self.assertEqual(verdict.status, 'ok')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cast_replaces_set_aura_and_brackets_the_threat_baseline(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        scenario, (expectation,) = threat_tick_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        steps = scenario['steps']
        self.assertFalse(any(step.get('action') == 'set_aura' and step.get('spell') == RIGHTEOUS_CUSTODIAN
                             for step in steps))
        position = {step.get('label', step['action']): index for index, step in enumerate(steps)}
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == RIGHTEOUS_CUSTODIAN)
        cast = next(index for index, step in enumerate(steps)
                    if step['action'] == 'cast' and step['spell'] == RIGHTEOUS_CUSTODIAN)
        self.assertEqual(steps[cast]['actor'], 'caster')
        self.assertEqual(steps[cast]['target'], 'caster')
        order = [learn, position['stop_attack'], position[expectation.model['aura_before_label']], cast,
                 position[expectation.model['aura_after_label']], position[expectation.model['before_label']],
                 position[expectation.model['after_label']]]
        self.assertEqual(order, sorted(order))
        for label in (expectation.model['aura_before_label'], expectation.model['aura_after_label']):
            self.assertEqual(steps[position[label]]['metric'], 'aura_duration_ms')
            self.assertEqual(steps[position[label]]['spell'], RIGHTEOUS_CUSTODIAN)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_set_aura_entry_keeps_no_cast_reads(self):
        spec = threat_tick_ratio_spec(set_aura_custodian_entry())
        scenario, (expectation,) = threat_tick_ratio_scenario(CLASS_FILE, spec)
        self.assertNotIn('aura_before_label', expectation.model)
        self.assertFalse(any(step['action'] == 'cast' for step in scenario['steps']))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_aura_present_before_or_absent_after_the_cast_is_alert(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        _, (expectation,) = threat_tick_ratio_scenario(CLASS_FILE, spec)
        threat = {expectation.model['before_label']: 1000.0, expectation.model['after_label']: 980.0}
        for before, after, status in ((0.0, 1799000.0, 'ok'), (1799000.0, 1799000.0, 'alert'), (0.0, 0.0, 'alert')):
            values = FakeRun({**threat, **cast_applied(expectation.model, before, after)})
            verdict = judge_behaviour(base_verdict(expectation), values, expectation)
            self.assertEqual(verdict.status, status)
            self.assertIn('aura_duration_ms threat_tick_cast before', verdict.explanation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_missing_aura_read_is_not_ok(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        _, (expectation,) = threat_tick_ratio_scenario(CLASS_FILE, spec)
        values = FakeRun({expectation.model['before_label']: 1000.0, expectation.model['after_label']: 980.0,
                          expectation.model['aura_before_label']: 0.0})
        self.assertNotEqual(judge_behaviour(base_verdict(expectation), values, expectation).status, 'ok')

    def test_unknown_cast_target_or_threat_unit_is_refused(self):
        with self.assertRaises(ValueError):
            threat_tick_ratio_spec({**righteous_custodian_entry(), 'cast_target': 'dummy'})
        with self.assertRaises(ValueError):
            threat_tick_ratio_spec({**righteous_custodian_entry(), 'threat_unit': 'ally'})
        with self.assertRaises(ValueError):
            threat_tick_ratio_spec({**righteous_custodian_entry(), 'aura_stacks': 2})

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_ally_arm_groups_the_ally_and_reads_its_threat(self):
        scenario, (expectation,) = behaviour_scenario(
            CLASS_FILE, variant_entry(RIGHTEOUS_CUSTODIAN, 'threat_tick_ratio', 'ally'))
        run.validate(scenario)
        steps = scenario['steps']
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
        self.assertIn({'action': 'group', 'actor': 'caster', 'target': 'ally'}, steps)
        self.assertIn({'action': 'attack', 'actor': 'ally', 'target': 'dummy'}, steps)
        cast = next(step for step in steps if step['action'] == 'cast' and step['spell'] == RIGHTEOUS_CUSTODIAN)
        self.assertEqual((cast['actor'], cast['target']), ('caster', 'ally'))
        reads = {step['label']: step for step in steps if step.get('label') in (
            expectation.model['before_label'], expectation.model['after_label'],
            expectation.model['aura_before_label'], expectation.model['aura_after_label'])}
        self.assertEqual(reads[expectation.model['before_label']]['target'], 'ally')
        self.assertEqual(reads[expectation.model['after_label']]['target'], 'ally')
        self.assertEqual(reads[expectation.model['aura_after_label']]['actor'], 'ally')
        self.assertEqual(expectation.label, '572808 behaviour_metric_ratio_delta ally')
        self.assertEqual(expectation.model['expected_ratio'], 0.98)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_ally_control_reads_the_casters_threat_and_alerts_on_a_caster_side_tick(self):
        scenario, (expectation,) = behaviour_scenario(
            CLASS_FILE, variant_entry(RIGHTEOUS_CUSTODIAN, 'threat_tick_ratio', 'ally_caster_control'))
        steps = scenario['steps']
        threat = [step for step in steps if step.get('metric') == 'threat']
        self.assertEqual({step['target'] for step in threat}, {'caster'})
        cast = next(step for step in steps if step['action'] == 'cast' and step['spell'] == RIGHTEOUS_CUSTODIAN)
        self.assertEqual(cast['target'], 'ally')
        model = expectation.model
        for after, status in ((1000.0, 'ok'), (980.0, 'alert')):
            values = FakeRun({model['before_label']: 1000.0, model['after_label']: after, **cast_applied(model)})
            self.assertEqual(judge_behaviour(base_verdict(expectation), values, expectation).status, status)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_permanent_aura_after_the_cast_counts_as_applied(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        _, (expectation,) = threat_tick_ratio_scenario(CLASS_FILE, spec)
        values = FakeRun({expectation.model['before_label']: 1000.0, expectation.model['after_label']: 980.0,
                          **cast_applied(expectation.model, 0.0, -1.0)})
        self.assertEqual(judge_behaviour(base_verdict(expectation), values, expectation).status, 'ok')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_zero_baseline_is_unmeasured_not_alert(self):
        spec = threat_tick_ratio_spec(righteous_custodian_entry())
        _, expectations = threat_tick_ratio_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        zero_run = FakeRun({expectation.model['before_label']: 0.0, expectation.model['after_label']: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), zero_run, expectation)
        self.assertEqual(verdict.status, 'unmeasured')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AbsorbPierceRatioScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = absorb_pierce_ratio_spec(norgannons_wrath_entry())
        scenario, expectations = absorb_pierce_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_ABSORB_PIERCE_RATIO)
        self.assertTrue(expectation.rule.startswith(
            'prose: "Damage dealt pierces all immunities, resistances, and damage absorption effects."'))
        self.assertEqual(expectation.model['kind'], 'absorb_pierce_ratio')
        self.assertEqual(expectation.model['expected_ratio'], 1.0)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, norgannons_wrath_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_ABSORB_PIERCE_RATIO)
        self.assertEqual(expectations[0].model['expected_ratio'], 1.0)

    def test_scenario_always_has_the_creature_fixture(self):
        spec = absorb_pierce_ratio_spec(norgannons_wrath_entry())
        scenario, _ = absorb_pierce_ratio_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_shield_is_set_on_the_dummy_between_the_two_casts(self):
        spec = absorb_pierce_ratio_spec(norgannons_wrath_entry())
        scenario, _ = absorb_pierce_ratio_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        cast_indexes = [index for index, step in enumerate(steps)
                        if step.get('action') == 'cast' and step.get('spell') == NORGANNONS_WRATH]
        set_aura_index = next(index for index, step in enumerate(steps)
                              if step.get('action') == 'set_aura' and step.get('spell') == STAFFGUARD_SHIELD)
        self.assertEqual(len(cast_indexes), 2)
        self.assertEqual(steps[set_aura_index]['target'], 'dummy')
        self.assertLess(cast_indexes[0], set_aura_index)
        self.assertLess(set_aura_index, cast_indexes[1])

    def test_wrong_full_absorption_is_caught(self):
        spec = absorb_pierce_ratio_spec(norgannons_wrath_entry())
        _, expectations = absorb_pierce_ratio_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        model = expectation.model
        wrong_run = FakeRun({model['zero_label']: 0.0, model['unshielded_label']: 1000.0,
                             model['shielded_label']: 1000.0, model['shield_before_label']: 500.0,
                             model['shield_after_label']: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        right_run = FakeRun({model['zero_label']: 0.0, model['unshielded_label']: 1000.0,
                             model['shielded_label']: 2000.0, model['shield_before_label']: 500.0,
                             model['shield_after_label']: 500.0})
        verdict = judge_behaviour(base_verdict(expectation), right_run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_zero_baseline_is_unmeasured_not_alert(self):
        spec = absorb_pierce_ratio_spec(norgannons_wrath_entry())
        _, expectations = absorb_pierce_ratio_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        model = expectation.model
        zero_run = FakeRun({model['zero_label']: 0.0, model['unshielded_label']: 0.0, model['shielded_label']: 0.0,
                            model['shield_before_label']: 500.0, model['shield_after_label']: 500.0})
        verdict = judge_behaviour(base_verdict(expectation), zero_run, expectation)
        self.assertEqual(verdict.status, 'unmeasured')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CastLeechRatioScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = cast_leech_ratio_spec(argent_blade_entry())
        scenario, expectations = cast_leech_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_RATIO)
        self.assertTrue(expectation.rule.startswith('prose: "healing you equal to the damage dealt"'))
        self.assertEqual(expectation.model['kind'], 'leech_ratio')
        self.assertEqual(expectation.model['heal_baseline_label'], None)
        self.assertEqual(expectation.model['expected'], 1.0)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, argent_blade_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_RATIO)
        self.assertEqual(expectations[0].model['kind'], 'leech_ratio')

    def test_single_cast_at_a_dummy_then_measures_damage_and_self_heal(self):
        spec = cast_leech_ratio_spec(argent_blade_entry())
        scenario, _ = cast_leech_ratio_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        cast_steps = [index for index, step in enumerate(steps)
                     if step.get('action') == 'cast' and step.get('spell') == ARGENT_BLADE_CAST]
        damage_steps = [index for index, step in enumerate(steps)
                        if step.get('metric') == 'spell_damage_total' and step.get('spell') == ARGENT_BLADE_CAST]
        heal_steps = [index for index, step in enumerate(steps)
                     if step.get('metric') == 'spell_heal_total' and step.get('spell') == ARGENT_BLADE_HEAL]
        self.assertEqual(len(cast_steps), 1)
        self.assertEqual(len(damage_steps), 1)
        self.assertEqual(len(heal_steps), 1)
        self.assertLess(cast_steps[0], damage_steps[0])
        self.assertLess(cast_steps[0], heal_steps[0])
        heal_step = steps[heal_steps[0]]
        self.assertEqual(heal_step['target'], 'caster')
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_wrong_heal_reading_is_caught(self):
        spec = cast_leech_ratio_spec(argent_blade_entry())
        _, expectations = cast_leech_ratio_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        wrong_run = FakeRun({expectation.model['damage_label']: 1000.0, expectation.model['heal_label']: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        right_run = FakeRun({expectation.model['damage_label']: 1000.0, expectation.model['heal_label']: 1000.0})
        verdict = judge_behaviour(base_verdict(expectation), right_run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_ignores_caster_heal_modifiers_reads_the_dbc_attribute(self):
        self.assertTrue(ignores_caster_heal_modifiers(RECORDS, ARGENT_BLADE_HEAL))
        self.assertFalse(ignores_caster_heal_modifiers(RECORDS, TITANSTRIKE_MAX_RANK))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CastStatRatioScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = cast_stat_ratio_spec(tome_of_light_entry())
        scenario, expectations = cast_stat_ratio_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_RATIO)
        self.assertTrue(expectation.rule.startswith(
            'prose: "Grants a shield equal to 100% of your maximum health"'))
        self.assertEqual(expectation.model['kind'], 'stat_ratio')
        self.assertEqual(expectation.model['stat_metric'], 'max_health')
        self.assertEqual(expectation.model['expected'], 1.0)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, tome_of_light_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_RATIO)
        self.assertEqual(expectations[0].model['kind'], 'stat_ratio')

    def test_stat_is_measured_before_the_cast_and_amount_after_it(self):
        spec = cast_stat_ratio_spec(tome_of_light_entry())
        scenario, expectations = cast_stat_ratio_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        model = expectations[0].model
        stat_index = next(index for index, step in enumerate(steps)
                          if step.get('metric') == 'max_health' and step.get('label') == model['stat_label'])
        cast_index = next(index for index, step in enumerate(steps)
                          if step.get('action') == 'cast' and step.get('spell') == TOME_OF_LIGHT)
        amount_index = next(index for index, step in enumerate(steps)
                            if step.get('metric') == 'aura_amount' and step.get('label') == model['amount_label'])
        self.assertLess(stat_index, cast_index)
        self.assertLess(cast_index, amount_index)
        amount_step = steps[amount_index]
        self.assertEqual(amount_step['spell'], TOME_OF_LIGHT)
        self.assertEqual(amount_step['effect'], 1)

    def test_wrong_amount_reading_is_caught(self):
        spec = cast_stat_ratio_spec(tome_of_light_entry())
        _, expectations = cast_stat_ratio_scenario(CLASS_FILE, spec)
        expectation = expectations[0]
        wrong_run = FakeRun({expectation.model['stat_label']: 40000.0, expectation.model['amount_label']: 1.0})
        verdict = judge_behaviour(base_verdict(expectation), wrong_run, expectation)
        self.assertEqual(verdict.status, 'alert')
        right_run = FakeRun({expectation.model['stat_label']: 40000.0, expectation.model['amount_label']: 40000.0})
        verdict = judge_behaviour(base_verdict(expectation), right_run, expectation)
        self.assertEqual(verdict.status, 'ok')


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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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
        self.assertEqual(float(expectations[0].displayed), strongest_percent(own_pct, partner_pct))

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


class StrongestPercentTests(unittest.TestCase):
    def test_increases_pick_the_largest(self):
        self.assertEqual(strongest_percent(5.0, 4.0), 5.0)
        self.assertEqual(strongest_percent(3.0, 3.0), 3.0)

    def test_seeded_reductions_pick_the_most_negative_not_the_largest_value(self):
        self.assertEqual(strongest_percent(-6.0, -10.0), -10.0)
        self.assertNotEqual(strongest_percent(-6.0, -10.0), max(-6.0, -10.0))

    def test_opposite_directions_are_refused(self):
        with self.assertRaisesRegex(ValueError, 'opposite directions'):
            strongest_percent(5.0, -4.0)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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
    def expectation(self, expected=2, headroom=1):
        pairs = [(f'b{index}', f'a{index}') for index in range(1, expected + 1 + headroom)]
        model = {'kind': 'count', 'expected': expected, 'quote': 'strikes 2 additional enemies',
                 'dummy_labels': pairs, 'headroom': headroom}
        return Expectation('label', BEHAVIOUR_COUNT, SCARLET_JUDICATOR, DIVINE_FORCE_MAX_RANK, None, '2',
                           'prose: "strikes 2 additional enemies" (525024)', model)

    def test_delta_matches_expected_is_ok(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 1.0, 'b3': 0.0, 'a3': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('3 candidates offered for 2 stated', verdict.explanation)

    def test_delta_below_expected_is_alert(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 0.0, 'b2': 0.0, 'a2': 0.0, 'b3': 0.0, 'a3': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_seeded_one_below_expected_is_an_alert(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 0.0, 'b3': 0.0, 'a3': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual((verdict.status, verdict.measured), ('alert', 1.0))

    def test_seeded_one_above_expected_is_an_alert(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 1.0, 'b3': 0.0, 'a3': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual((verdict.status, verdict.measured), ('alert', 3.0))

    def test_a_match_without_a_candidate_beyond_the_count_is_not_judged(self):
        expectation = self.expectation(headroom=0)
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('no candidate beyond the stated 2', verdict.explanation)
        short = judge_behaviour(base_verdict(expectation), FakeRun({**values, 'a2': 0.0}), expectation)
        self.assertEqual(short.status, 'alert')

    def test_zero_delta_against_expected_one_is_alert_not_ok(self):
        model = {'kind': 'count', 'expected': 1, 'quote': 'strikes 1 additional nearby target',
                 'dummy_labels': [('b1', 'a1'), ('b2', 'a2')], 'headroom': 1}
        expectation = Expectation('label', BEHAVIOUR_COUNT, JUSTICE, INTERDICT, None, '1',
                                  'prose: "strikes 1 additional nearby target" (712437)', model)
        values = {'b1': 0.0, 'a1': 0.0, 'b2': 0.0, 'a2': 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.expected, 1.0)

    def test_already_hit_before_learn_is_unmeasured(self):
        expectation = self.expectation()
        values = {'b1': 1.0, 'a1': 1.0, 'b2': 0.0, 'a2': 1.0, 'b3': 0.0, 'a3': 0.0}
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


def per_cast_run(per_cast_hits, start=None):
    dummies = len(per_cast_hits[0])
    start_labels = [f's{index}' for index in range(dummies)]
    casts = [[f'c{cast}d{index}' for index in range(dummies)] for cast in range(1, len(per_cast_hits) + 1)]
    values = dict(zip(start_labels, start or [0.0] * dummies))
    running = list(start or [0.0] * dummies)
    for labels, hits in zip(casts, per_cast_hits):
        running = [value + hit for value, hit in zip(running, hits)]
        values.update(zip(labels, running))
    return {'start': start_labels, 'casts': casts}, values


class JudgePerCastCountTests(unittest.TestCase):
    def expectation(self, per_cast, expected=2):
        pairs = [(f'b{index}', f'a{index}') for index in range(1, expected + 2)]
        model = {'kind': 'count', 'expected': expected, 'quote': 'strikes 2 additional enemies',
                 'dummy_labels': pairs, 'headroom': 1, 'per_cast': per_cast}
        return Expectation('label', BEHAVIOUR_COUNT, SCARLET_JUDICATOR, DIVINE_FORCE_MAX_RANK, None, '2',
                           'prose: "strikes 2 additional enemies" (525024)', model)

    def judged(self, per_cast_hits):
        per_cast, values = per_cast_run(per_cast_hits)
        values.update({'b1': 0.0, 'b2': 0.0, 'b3': 0.0, 'a1': 1.0, 'a2': 1.0, 'a3': 1.0})
        expectation = self.expectation(per_cast)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_selection_that_moves_between_casts_is_judged_per_cast(self):
        verdict = self.judged([[1, 1, 1, 0], [1, 0, 1, 1], [1, 1, 0, 1]])
        self.assertEqual((verdict.status, verdict.measured), ('ok', 2.0))
        self.assertIn('[2, 2, 2] of 3 casts', verdict.explanation)

    def test_seeded_one_cast_striking_one_target_too_many_is_an_alert(self):
        verdict = self.judged([[1, 1, 1, 0], [1, 1, 1, 1]])
        self.assertEqual((verdict.status, verdict.measured), ('alert', 3.0))

    def test_seeded_every_cast_one_short_is_an_alert(self):
        verdict = self.judged([[1, 1, 0, 0], [1, 0, 1, 0]])
        self.assertEqual((verdict.status, verdict.measured), ('alert', 1.0))

    def test_a_cast_that_missed_the_primary_is_left_out(self):
        verdict = self.judged([[0, 1, 1, 1], [1, 1, 1, 0]])
        self.assertEqual((verdict.status, verdict.measured), ('ok', 2.0))

    def test_no_cast_on_the_primary_is_unmeasured(self):
        verdict = self.judged([[0, 1, 0, 0], [0, 0, 0, 0]])
        self.assertEqual(verdict.status, 'unmeasured')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    def test_seeded_one_of_two_allies_healed_is_an_alert(self):
        expectation = self.expectation()
        (b0, a0), (b1, a1) = expectation.model['dummy_labels']
        values = {b0: 0.0, a0: 1.0, b1: 0.0, a1: 0.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_every_offered_ally_is_stated_so_a_match_is_judged(self):
        expectation = self.expectation()
        self.assertTrue(expectation.model['all_offered'])
        (b0, a0), (b1, a1) = expectation.model['dummy_labels']
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({b0: 0.0, a0: 1.0, b1: 0.0, a1: 1.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('every offered candidate is stated', verdict.explanation)


class JudgeFixedTargetCountTests(unittest.TestCase):
    def expectation(self, expected=1, far_label='far'):
        model = {'kind': 'fixed_count', 'expected': expected, 'quote': 'and an additional nearby enemy',
                 'dummy_labels': ['a1', 'a2'], 'far_label': far_label, 'headroom': 1}
        return Expectation('label', BEHAVIOUR_FIXED_COUNT, HOLY_CLEAVE, HOLY_CLEAVE, None, '1',
                           'prose: "and an additional nearby enemy" (573049)', model)

    def test_measured_count_matches_expected_and_far_dummy_unhit_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0, 'a2': 0.0, 'far': 0.0}), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 1.0)

    def test_seeded_zero_hit_against_a_nonzero_expectation_fails(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 0.0, 'a2': 0.0, 'far': 0.0}),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.expected, 1.0)

    def test_per_cast_reads_judge_the_widest_landed_cast_and_keep_the_radius_check(self):
        per_cast, values = per_cast_run([[1, 1, 0], [0, 0, 0], [1, 0, 1]])
        expectation = self.expectation()
        expectation = replace(expectation, model={**expectation.model, 'per_cast': per_cast})
        verdict = judge_behaviour(base_verdict(expectation),
                                  FakeRun({**values, 'a1': 1.0, 'a2': 1.0, 'far': 0.0}), expectation)
        self.assertEqual((verdict.status, verdict.measured), ('ok', 1.0))
        far = judge_behaviour(base_verdict(expectation), FakeRun({**values, 'a1': 1.0, 'a2': 1.0, 'far': 1.0}),
                              expectation)
        self.assertEqual(far.status, 'alert')

    def test_seeded_both_near_candidates_hit_against_one_stated_fails(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0, 'a2': 1.0, 'far': 0.0}),
                                  expectation)
        self.assertEqual((verdict.status, verdict.measured), ('alert', 2.0))

    def test_seeded_far_dummy_hit_fails_even_though_the_near_count_matches(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0, 'a2': 0.0, 'far': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('beyond-radius dummy hit count 1', verdict.explanation)

    def test_missing_far_measurement_leaves_alert_with_explanation(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0, 'a2': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('far', verdict.explanation)

    def test_no_far_label_skips_the_radius_check(self):
        expectation = self.expectation(far_label=None)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'a1': 1.0, 'a2': 0.0}), expectation)
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


def pious_sweep_hit_ratio_entry():
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'hit_ratio'
                and entry['spell'] == PIOUS_SWEEP)


class HitRatioScenarioTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_pious_sweep_entry_reads_both_arms_after_every_trial(self):
        entry = pious_sweep_hit_ratio_entry()
        scenario, expectations = behaviour_scenario(CLASS_FILE, entry)
        validated = run.validate(scenario)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_HIT_RATIO)
        self.assertEqual(expectation.label, f'{PIOUS_SWEEP} behaviour_hit_ratio tranquil_circle')
        reads = expectation.model['reads']
        self.assertEqual([len(reads[arm]) for arm in ('control', 'treatment')], [entry['trials'] + 1] * 2)
        labels = {step['label'] for step in validated['steps'] if step.get('label')}
        self.assertTrue(all(label in labels for arm in reads.values() for pair in arm for label in pair))
        filtered = [step for step in validated['steps'] if step.get('metric') == 'spell_damage_count']
        self.assertTrue(all(step.get('critical') is False for step in filtered))
        casts = [step['spell'] for step in validated['steps'] if step['action'] == 'cast']
        self.assertEqual(casts.count(CHASTISE), 2 * entry['trials'])
        self.assertEqual(casts.count(TRANQUIL_CIRCLE), entry['trials'])
        self.assertLess(casts.index(TRANQUIL_CIRCLE), len(casts) - casts[::-1].index(CHASTISE))
        self.assertEqual(expectation.model['expected_bonus'], 25.0)
        self.assertLessEqual(entry['trials'], expectation.model['trial_limit'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_more_trials_than_one_scenario_holds_are_refused(self):
        entry = {**pious_sweep_hit_ratio_entry(), 'trials': 10000}
        with self.assertRaises(NotModelled) as raised:
            behaviour_scenario(CLASS_FILE, entry)
        self.assertIn('trials fit', str(raised.exception))

    def test_identical_arms_are_refused(self):
        entry = {**pious_sweep_hit_ratio_entry(), 'treatment': pious_sweep_hit_ratio_entry()['control']}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    def test_sized_behaviour_replaces_the_trials_of_its_label_only(self):
        entry = pious_sweep_hit_ratio_entry()
        label = f'{PIOUS_SWEEP} behaviour_hit_ratio tranquil_circle'
        self.assertEqual(sized_behaviour(entry, {label: 37})['trials'], 37)
        self.assertEqual(sized_behaviour(entry, {'other': 37}), entry)
        self.assertEqual(sized_behaviour(justice_entry(), {label: 37}), justice_entry())


def hit_ratio_run(expected, control_hits, treatment_hits, minimum=1):
    trials = len(control_hits)
    reads = {arm: [(f'{arm} {mark} total', f'{arm} {mark} count') for mark in ('start', *range(1, trials + 1))]
             for arm in ('control', 'treatment')}
    values, total, count = {}, 0.0, 0.0
    for arm, hits in (('control', control_hits), ('treatment', treatment_hits)):
        marks = reads[arm]
        values[marks[0][0]], values[marks[0][1]] = total, count
        for (total_label, count_label), hit in zip(marks[1:], hits):
            total, count = total + hit, count + (1 if hit else 0)
            values[total_label], values[count_label] = total, count
    model = {'kind': 'hit_ratio', 'reads': reads, 'expected': expected, 'expected_bonus': (expected - 1) * 100,
             'trials': trials, 'trial_limit': 111, 'minimum_hits': minimum, 'metric': 'spell_damage_total'}
    expectation = Expectation('label', BEHAVIOUR_HIT_RATIO, PIOUS_SWEEP, CHASTISE, None, str(expected),
                              'prose: "affected by Tranquil Circle"', model)
    return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)


def control_hits(trials):
    return [1000.0 + 10.0 * ((index * 7) % 11 - 5) for index in range(trials)]


class JudgeHitRatioTests(unittest.TestCase):
    def test_nineteen_percent_on_a_twenty_percent_tooltip_passes(self):
        control = control_hits(400)
        verdict = hit_ratio_run(1.20, control, [hit * 1.19 for hit in control])
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 19.0)
        self.assertAlmostEqual(verdict.low, 18.0)
        self.assertAlmostEqual(verdict.high, 22.0)
        self.assertLessEqual(verdict.detail['bonus']['half'], 1.0)
        self.assertEqual(verdict.detail['metric'], 'spell_damage_total')

    def test_seeded_fourteen_percent_on_a_twenty_percent_tooltip_fails(self):
        control = control_hits(400)
        verdict = hit_ratio_run(1.20, control, [hit * 1.14 for hit in control])
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 14.0)

    def test_the_old_five_percent_ratio_band_would_have_passed_the_seeded_server(self):
        self.assertLessEqual(abs(1.14 - 1.20), 0.05 * 1.20 + 1e-9)

    def test_every_judged_verdict_states_the_interval_it_excludes(self):
        control = control_hits(400)
        verdict = hit_ratio_run(1.20, control, [hit * 1.19 for hit in control])
        half = verdict.detail['bonus']['half']
        self.assertAlmostEqual(verdict.detail['bonus']['excluded_below'], 20.0 - 2.0 - half)
        self.assertAlmostEqual(verdict.detail['bonus']['excluded_above'], 20.0 + 2.0 + half)
        self.assertIn(f'excludes a bonus below {20.0 - 2.0 - half:+.4g}% or above {20.0 + 2.0 + half:+.4g}%',
                      verdict.explanation)

    def test_an_interval_wider_than_half_the_band_is_not_judged_and_names_the_trials(self):
        control = control_hits(20)
        verdict = hit_ratio_run(1.20, control, [hit * 1.19 for hit in control])
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertGreater(verdict.detail['bonus']['half'], 1.0)
        self.assertGreater(verdict.detail['trials_needed'], 20)
        self.assertGreater(verdict.detail['sized_trials'], verdict.detail['trials_needed'])

    def test_an_interval_outside_the_band_fails_without_power(self):
        control = control_hits(20)
        verdict = hit_ratio_run(1.20, control, [hit * 1.60 for hit in control])
        self.assertEqual(verdict.status, 'alert')

    def test_an_interval_holding_zero_does_not_tell_the_arms_apart(self):
        control = control_hits(400)
        verdict = hit_ratio_run(1.02, control, [hit * 1.002 for hit in control])
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('not told apart from the control arm', verdict.explanation)

    def test_too_few_hits_in_an_arm_is_unmeasured(self):
        control = control_hits(40)
        verdict = hit_ratio_run(1.20, control, [0.0] * 30 + [hit * 1.2 for hit in control[:10]], minimum=20)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_a_missing_read_names_its_label(self):
        control = control_hits(10)
        trials = len(control)
        reads = {arm: [(f'{arm} {mark} total', f'{arm} {mark} count') for mark in ('start', *range(1, trials + 1))]
                 for arm in ('control', 'treatment')}
        model = {'kind': 'hit_ratio', 'reads': reads, 'expected': 1.2, 'expected_bonus': 20.0, 'trials': trials,
                 'minimum_hits': 1, 'metric': 'spell_damage_total'}
        expectation = Expectation('label', BEHAVIOUR_HIT_RATIO, PIOUS_SWEEP, CHASTISE, None, '1.2', 'prose', model)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('control start total', verdict.explanation)


class BonusBandTests(unittest.TestCase):
    def test_the_band_is_the_larger_of_five_percent_and_two_points(self):
        self.assertEqual(bonus_band(20.0), 2.0)
        self.assertEqual(bonus_band(100.0), 5.0)
        self.assertEqual(bonus_band(-10.0), 2.0)
        self.assertEqual(bonus_band(60.0), 3.0)


class JudgeHolyTempestTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'count', 'expected': 1, 'quote': 'spreads Condemn on affected enemies to a nearby enemy',
                 'dummy_labels': [('b1', 'a1')], 'headroom': 0}
        return Expectation('label', BEHAVIOUR_COUNT, HOLY_TEMPEST, RIGHTEOUS_TEMPEST_RANK, None, '1',
                           'prose: "spreads Condemn on affected enemies to a nearby enemy" (301339)', model)

    def test_condemn_on_the_only_nearby_dummy_is_not_judged_without_a_further_candidate(self):
        expectation = self.expectation()
        values = {'b1': 0.0, 'a1': 1.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'insufficient_trials')

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

    def first_tick_expectation(self):
        model = {'kind': 'count', 'expected': 1, 'quote': 'spreads Condemn on affected enemies to a nearby enemy',
                 'dummy_labels': [('b1', 'a1'), ('b2', 'a2')], 'headroom': 1}
        return Expectation('label', BEHAVIOUR_COUNT, HOLY_TEMPEST, RIGHTEOUS_TEMPEST_RANK, None, '1',
                           'prose: "spreads Condemn on affected enemies to a nearby enemy" (301339)', model)

    def test_one_of_two_dummies_after_the_first_tick_is_ok(self):
        expectation = self.first_tick_expectation()
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 0.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'ok')

    def test_seeded_spread_to_every_nearby_enemy_alerts(self):
        expectation = self.first_tick_expectation()
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 1.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')

    def test_a_read_after_more_than_one_primary_hit_is_unmeasured(self):
        expectation = self.first_tick_expectation()
        expectation.model['primary_hits'] = [['hs0', 'he0'], ['hs1', 'he1']]
        values = {'b1': 0.0, 'a1': 1.0, 'b2': 0.0, 'a2': 0.0, 'hs0': 0.0, 'he0': 1.0, 'hs1': 6.0, 'he1': 8.0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'unmeasured')
        values['he1'] = 7.0
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'ok')


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

    def test_a_judged_ratio_states_the_range_it_excludes_with_the_tolerated_band(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 100.0, 'after': 200.0}), expectation)
        self.assertEqual(verdict.detail['excluded'], [1.95, 2.05])
        self.assertIn('excludes a reading below 1.95 or above 2.05 (one reading, no sampling interval)',
                      verdict.explanation)
        unjudged = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 200.0}), expectation)
        self.assertNotIn('excluded', unjudged.detail or {})

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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_periodic_flat_spec_reads_the_metric_with_periodic_true(self):
        scenario, [_expectation] = oath_consumption_scenario(CLASS_FILE, self.flat_spec())
        validated = run.validate(scenario)
        before_step = next(step for step in validated['steps']
                           if step.get('label', '').endswith('oath_consumption_before'))
        self.assertTrue(before_step['periodic'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_no_second_oath_spec_omits_the_additive_measurements(self):
        scenario, [expectation] = oath_consumption_scenario(CLASS_FILE, self.ratio_spec())
        self.assertNotIn('other_oath_spell', expectation.model)
        self.assertNotIn('both_label', expectation.model)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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
        return IcdGateSpec(DISCIPLINED_BLOWS, 'Disciplined Blows', 'Only occurs once every 0.5 sec.', BENEDICTION,
                           DISCIPLINED_BLOWS_TICK, 500, target='self', caster_health_pct=50)

    def test_a_non_positive_internal_cooldown_is_not_modelled(self):
        with self.assertRaises(NotModelled):
            icd_gate_scenario(CLASS_FILE, replace(self.spec(), internal_cooldown_ms=0))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_force_crit_scenario_sets_the_player_fixture(self):
        spec = IcdGateSpec(SCARLET_CHAMPION, 'Scarlet Champion', 'Can only occur once per sec.', ARGENT_BLADE,
                           SCARLET_CHAMPION_STACK, 1000, target='dummy', force_crit='melee')
        scenario, _ = icd_gate_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_entries_from_the_class_file_round_trip_through_the_spec_parser(self):
        entries = [entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'internal_cooldown_gate']
        self.assertEqual(len(entries), 5)
        for entry in entries:
            scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
            self.assertEqual(expectation.rule, f'prose: "{entry["quote"]}" ({entry["spell"]})')
            run.validate(scenario)

    def test_a_striker_trigger_without_an_entry_is_not_modelled(self):
        spec = IcdGateSpec(SACRED_DEFENSE, 'Sacred Defense', 'Can only occur once per sec.', KARAZHAN_CHESS_FOOTMAN_MELEE,
                           SACRED_DEFENSE_STRIKE, 1000, target=None, trigger_actor=STRIKER, striker_entry=0)
        with self.assertRaises(ValueError):
            icd_gate_scenario(CLASS_FILE, spec)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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
                 'reopen_gap_ms': 750, 'quote': 'Only occurs once every 0.5 sec.'}
        return Expectation('label', BEHAVIOUR_INTERNAL_COOLDOWN_GATE, DISCIPLINED_BLOWS, BENEDICTION, None, '1',
                           'prose: "Only occurs once every 0.5 sec." (680397)', model)

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
                           str(strongest_percent(own_pct, partner_pct)),
                           'prose: "Does not stack with similar effects." (560550)', model)

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

    def test_reductions_cap_at_the_larger_reduction(self):
        expectation = self.expectation(own_pct=-10.0, partner_pct=-6.0)
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 0.90, 'combined': baseline * 0.90})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.expected, 900.0)
        self.assertIn('capped at the stronger -10%', verdict.explanation)

    def test_seeded_weaker_reduction_in_the_combined_reading_is_an_alert(self):
        expectation = self.expectation(own_pct=-10.0, partner_pct=-6.0)
        baseline = 1000.0
        run = FakeRun({'baseline': baseline, 'own': baseline * 0.90, 'combined': baseline * 0.94})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

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


class CastGateScenarioTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_validates_and_shapes_expectations(self):
        spec = cast_gate_spec(titanstrike_cast_gate_entry())
        scenario, expectations = cast_gate_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 3)
        blocked, allowed, bypassed = expectations
        self.assertEqual(blocked.check, BEHAVIOUR_CAST_GATE)
        self.assertEqual(blocked.spell_id, TITANSTRIKE)
        self.assertEqual(blocked.displayed, str(SPELL_FAILED_TARGET_AURASTATE))
        self.assertEqual(allowed.spell_id, TITANSTRIKE)
        self.assertEqual(allowed.displayed, str(NO_CAST_FAILURE))
        self.assertEqual(bypassed.spell_id, TESTAMENT_OF_STRENGTH)
        self.assertEqual(bypassed.rank_id, TITANSTRIKE)
        self.assertEqual(bypassed.displayed, str(NO_CAST_FAILURE))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, titanstrike_cast_gate_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_CAST_GATE)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_blocked_attempt_precedes_casting_the_bypass_spell(self):
        spec = cast_gate_spec(titanstrike_cast_gate_entry())
        scenario, _ = cast_gate_scenario(CLASS_FILE, spec)
        blocked_cast = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('action') == 'cast' and step.get('spell') == TITANSTRIKE)
        bypass_cast = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('action') == 'cast' and step.get('spell') == TESTAMENT_OF_STRENGTH)
        self.assertLess(blocked_cast, bypass_cast)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_bypass_spell_is_unlearned_before_the_health_fixture_attempt(self):
        spec = cast_gate_spec(titanstrike_cast_gate_entry())
        scenario, _ = cast_gate_scenario(CLASS_FILE, spec)
        unlearn_index = next(index for index, step in enumerate(scenario['steps'])
                             if step.get('action') == 'unlearn' and step.get('spell') == TESTAMENT_OF_STRENGTH)
        health_fixture_index = next(index for index, step in enumerate(scenario['steps'])
                                    if step.get('action') == 'set_health_pct')
        final_cast_index = [index for index, step in enumerate(scenario['steps'])
                            if step.get('action') == 'cast' and step.get('spell') == TITANSTRIKE][-1]
        self.assertLess(unlearn_index, health_fixture_index)
        self.assertLess(health_fixture_index, final_cast_index)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_cast_attempt_resets_its_own_cooldown_first(self):
        spec = cast_gate_spec(titanstrike_cast_gate_entry())
        scenario, _ = cast_gate_scenario(CLASS_FILE, spec)
        cast_indexes = [index for index, step in enumerate(scenario['steps'])
                       if step.get('action') == 'cast' and step.get('spell') == TITANSTRIKE]
        for index in cast_indexes:
            preceding = scenario['steps'][:index]
            self.assertTrue(any(step.get('action') == 'reset_cooldown' and step.get('spell') == TITANSTRIKE
                                for step in preceding))

    def test_rejects_a_spell_without_a_target_aura_state(self):
        entry = dict(titanstrike_cast_gate_entry())
        entry['spell'] = TESTAMENT_OF_STRENGTH
        entry['quote'] = "are usable regardless of your target's health percentage,"
        with self.assertRaises(Exception):
            cast_gate_scenario(CLASS_FILE, cast_gate_spec(entry))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_expectation_label_has_a_matching_measurement_step(self):
        spec = cast_gate_spec(titanstrike_cast_gate_entry())
        scenario, expectations = cast_gate_scenario(CLASS_FILE, spec)
        measured_labels = {step.get('label') for step in scenario['steps'] if step.get('action') == 'assert'
                           and step.get('metric') == 'cast_failure'}
        for expectation in expectations:
            self.assertIn(expectation.label, measured_labels)


class JudgeCastGateTests(unittest.TestCase):
    def blocked_expectation(self):
        model = {'kind': 'cast_gate', 'quote': 'Only usable on enemies below 35% health.'}
        return Expectation('806521 cast_gate blocked', BEHAVIOUR_CAST_GATE, TITANSTRIKE, TITANSTRIKE, None,
                           str(SPELL_FAILED_TARGET_AURASTATE),
                           'prose: "Only usable on enemies below 35% health." (806521)', model)

    def allowed_expectation(self):
        model = {'kind': 'cast_gate', 'quote': 'Only usable on enemies below 35% health.'}
        return Expectation('806521 cast_gate allowed', BEHAVIOUR_CAST_GATE, TITANSTRIKE, TITANSTRIKE, None,
                           str(NO_CAST_FAILURE), 'prose: "Only usable on enemies below 35% health." (806521)', model)

    def bypassed_expectation(self):
        model = {'kind': 'cast_gate', 'quote': "are usable regardless of your target's health percentage,"}
        return Expectation('300514 cast_gate bypassed', BEHAVIOUR_CAST_GATE, TESTAMENT_OF_STRENGTH, TITANSTRIKE,
                           None, str(NO_CAST_FAILURE),
                           'prose: "are usable regardless of your target\'s health percentage," (300514)', model)

    def test_blocked_attempt_refused_with_the_right_reason_is_ok(self):
        expectation = self.blocked_expectation()
        run = FakeRun({expectation.label: float(SPELL_FAILED_TARGET_AURASTATE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_blocked_attempt_that_actually_succeeded_is_alert(self):
        expectation = self.blocked_expectation()
        run = FakeRun({expectation.label: float(NO_CAST_FAILURE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_allowed_attempt_that_succeeded_is_ok(self):
        expectation = self.allowed_expectation()
        run = FakeRun({expectation.label: float(NO_CAST_FAILURE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_allowed_attempt_still_refused_is_alert(self):
        expectation = self.allowed_expectation()
        run = FakeRun({expectation.label: float(SPELL_FAILED_TARGET_AURASTATE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_bypassed_attempt_that_succeeded_is_ok(self):
        expectation = self.bypassed_expectation()
        run = FakeRun({expectation.label: float(NO_CAST_FAILURE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_bypassed_attempt_still_refused_by_the_gate_is_alert(self):
        expectation = self.bypassed_expectation()
        run = FakeRun({expectation.label: float(SPELL_FAILED_TARGET_AURASTATE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')


class JudgeCastGateMissingMeasurementTests(unittest.TestCase):
    def blocked_expectation(self):
        model = {'kind': 'cast_gate', 'quote': 'Only usable on enemies below 35% health.'}
        return Expectation('806521 cast_gate blocked', BEHAVIOUR_CAST_GATE, TITANSTRIKE, TITANSTRIKE, None,
                           str(SPELL_FAILED_TARGET_AURASTATE),
                           'prose: "Only usable on enemies below 35% health." (806521)', model)

    def test_missing_measurement_leaves_alert_with_explanation(self):
        expectation = self.blocked_expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn(expectation.label, verdict.explanation)

    def test_no_run_reports_no_scenario(self):
        expectation = self.blocked_expectation()
        verdict = judge_behaviour(base_verdict(expectation), None, expectation)
        self.assertIn('no scenario', verdict.explanation)


class CastConditionScenarioTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_outdoors_scenario_validates_and_shapes_expectations(self):
        spec = cast_condition_spec(divine_charge_cast_condition_entry())
        scenario, expectations = cast_condition_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 2)
        blocked, allowed = expectations
        self.assertEqual(blocked.check, BEHAVIOUR_CAST_CONDITION)
        self.assertEqual(blocked.spell_id, DIVINE_CHARGE)
        self.assertEqual(blocked.displayed, str(SPELL_FAILED_ONLY_OUTDOORS))
        self.assertEqual(allowed.spell_id, DIVINE_CHARGE)
        self.assertEqual(allowed.displayed, str(NO_CAST_FAILURE))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_mounted_scenario_validates_and_shapes_expectations(self):
        spec = cast_condition_spec(crusaders_presence_cast_condition_entry())
        scenario, expectations = cast_condition_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        blocked, allowed = expectations
        self.assertEqual(blocked.spell_id, CRUSADERS_PRESENCE)
        self.assertEqual(blocked.displayed, str(SPELL_FAILED_ONLY_MOUNTED))
        self.assertEqual(allowed.displayed, str(NO_CAST_FAILURE))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, divine_charge_cast_condition_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_CAST_CONDITION)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_outdoors_blocked_attempt_precedes_the_outdoor_teleport(self):
        spec = cast_condition_spec(divine_charge_cast_condition_entry())
        scenario, _ = cast_condition_scenario(CLASS_FILE, spec)
        blocked_cast = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('action') == 'cast' and step.get('spell') == DIVINE_CHARGE)
        outdoor_teleport = next(index for index, step in enumerate(scenario['steps'])
                                if step.get('action') == 'teleport' and step.get('x') == -9617.06)
        self.assertLess(blocked_cast, outdoor_teleport)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_mounted_blocked_attempt_precedes_mounting(self):
        spec = cast_condition_spec(crusaders_presence_cast_condition_entry())
        scenario, _ = cast_condition_scenario(CLASS_FILE, spec)
        blocked_cast = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('action') == 'cast' and step.get('spell') == CRUSADERS_PRESENCE)
        mount_step = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('action') == 'set_aura' and step.get('stacks') == 1)
        self.assertLess(blocked_cast, mount_step)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_cast_attempt_resets_its_own_cooldown_first(self):
        spec = cast_condition_spec(divine_charge_cast_condition_entry())
        scenario, _ = cast_condition_scenario(CLASS_FILE, spec)
        cast_indexes = [index for index, step in enumerate(scenario['steps'])
                       if step.get('action') == 'cast' and step.get('spell') == DIVINE_CHARGE]
        for index in cast_indexes:
            preceding = scenario['steps'][:index]
            self.assertTrue(any(step.get('action') == 'reset_cooldown' and step.get('spell') == DIVINE_CHARGE
                                for step in preceding))

    def test_rejects_an_unmodelled_condition(self):
        entry = dict(divine_charge_cast_condition_entry())
        entry['condition'] = 'in_combat'
        with self.assertRaises(Exception):
            cast_condition_scenario(CLASS_FILE, cast_condition_spec(entry))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_expectation_label_has_a_matching_measurement_step(self):
        spec = cast_condition_spec(divine_charge_cast_condition_entry())
        scenario, expectations = cast_condition_scenario(CLASS_FILE, spec)
        measured_labels = {step.get('label') for step in scenario['steps'] if step.get('action') == 'assert'
                           and step.get('metric') == 'cast_failure'}
        for expectation in expectations:
            self.assertIn(expectation.label, measured_labels)


class JudgeCastConditionTests(unittest.TestCase):
    def blocked_expectation(self):
        model = {'kind': 'cast_condition', 'quote': 'Can only be used outdoors.'}
        return Expectation('527023 cast_condition blocked', BEHAVIOUR_CAST_CONDITION, DIVINE_CHARGE, DIVINE_CHARGE,
                           None, str(SPELL_FAILED_ONLY_OUTDOORS), 'prose: "Can only be used outdoors." (527023)',
                           model)

    def allowed_expectation(self):
        model = {'kind': 'cast_condition', 'quote': 'Can only be used outdoors.'}
        return Expectation('527023 cast_condition allowed', BEHAVIOUR_CAST_CONDITION, DIVINE_CHARGE, DIVINE_CHARGE,
                           None, str(NO_CAST_FAILURE), 'prose: "Can only be used outdoors." (527023)', model)

    def test_blocked_attempt_refused_with_the_right_reason_is_ok(self):
        expectation = self.blocked_expectation()
        run = FakeRun({expectation.label: float(SPELL_FAILED_ONLY_OUTDOORS)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_blocked_attempt_that_actually_succeeded_is_alert(self):
        expectation = self.blocked_expectation()
        run = FakeRun({expectation.label: float(NO_CAST_FAILURE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_allowed_attempt_that_succeeded_is_ok(self):
        expectation = self.allowed_expectation()
        run = FakeRun({expectation.label: float(NO_CAST_FAILURE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_allowed_attempt_still_refused_is_alert(self):
        expectation = self.allowed_expectation()
        run = FakeRun({expectation.label: float(SPELL_FAILED_ONLY_OUTDOORS)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CastCombatScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = cast_combat_spec(spiritual_ascension_cast_combat_entry())
        scenario, expectations = cast_combat_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 2)
        combat, cast_failure = expectations
        self.assertEqual(combat.check, BEHAVIOUR_CAST_COMBAT)
        self.assertEqual(combat.spell_id, SPIRITUAL_ASCENSION)
        self.assertEqual(combat.displayed, '1')
        self.assertEqual(cast_failure.spell_id, SPIRITUAL_ASCENSION)
        self.assertEqual(cast_failure.displayed, str(NO_CAST_FAILURE))

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, spiritual_ascension_cast_combat_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_CAST_COMBAT)

    def test_ally_dies_before_the_attack_starts(self):
        spec = cast_combat_spec(spiritual_ascension_cast_combat_entry())
        scenario, _ = cast_combat_scenario(CLASS_FILE, spec)
        die_index = next(index for index, step in enumerate(scenario['steps'])
                         if step.get('action') == 'die' and step.get('actor') == 'ally')
        attack_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('action') == 'attack')
        self.assertLess(die_index, attack_index)

    def test_attack_starts_before_the_combat_measurement(self):
        spec = cast_combat_spec(spiritual_ascension_cast_combat_entry())
        scenario, expectations = cast_combat_scenario(CLASS_FILE, spec)
        attack_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('action') == 'attack')
        combat_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('label') == expectations[0].label)
        self.assertLess(attack_index, combat_index)

    def test_combat_measurement_precedes_the_cast_attempt(self):
        spec = cast_combat_spec(spiritual_ascension_cast_combat_entry())
        scenario, expectations = cast_combat_scenario(CLASS_FILE, spec)
        combat_index = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('label') == expectations[0].label)
        cast_index = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('action') == 'cast' and step.get('spell') == SPIRITUAL_ASCENSION)
        self.assertLess(combat_index, cast_index)

    def test_cast_targets_the_ally_not_the_dummy(self):
        spec = cast_combat_spec(spiritual_ascension_cast_combat_entry())
        scenario, _ = cast_combat_scenario(CLASS_FILE, spec)
        cast_step = next(step for step in scenario['steps']
                         if step.get('action') == 'cast' and step.get('spell') == SPIRITUAL_ASCENSION)
        self.assertEqual(cast_step['target'], 'ally')

    def test_attack_stops_after_the_cast_failure_measurement(self):
        spec = cast_combat_spec(spiritual_ascension_cast_combat_entry())
        scenario, expectations = cast_combat_scenario(CLASS_FILE, spec)
        measurement_index = next(index for index, step in enumerate(scenario['steps'])
                                 if step.get('label') == expectations[1].label)
        stop_index = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('action') == 'stop_attack')
        self.assertLess(measurement_index, stop_index)


class JudgeCastCombatTests(unittest.TestCase):
    def combat_expectation(self):
        model = {'kind': 'cast_combat', 'quote': 'Usable while in combat.'}
        return Expectation('500688 cast_combat combat', BEHAVIOUR_CAST_COMBAT, SPIRITUAL_ASCENSION,
                           SPIRITUAL_ASCENSION, None, '1', 'prose: "Usable while in combat." (500688)', model)

    def cast_failure_expectation(self):
        model = {'kind': 'cast_combat', 'quote': 'Usable while in combat.'}
        return Expectation('500688 cast_combat cast_failure', BEHAVIOUR_CAST_COMBAT, SPIRITUAL_ASCENSION,
                           SPIRITUAL_ASCENSION, None, str(NO_CAST_FAILURE),
                           'prose: "Usable while in combat." (500688)', model)

    def test_actually_in_combat_is_ok(self):
        expectation = self.combat_expectation()
        run = FakeRun({expectation.label: 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_fixture_that_never_entered_combat_is_alert(self):
        expectation = self.combat_expectation()
        run = FakeRun({expectation.label: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_unrefused_cast_is_ok(self):
        expectation = self.cast_failure_expectation()
        run = FakeRun({expectation.label: float(NO_CAST_FAILURE)})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_cast_refused_while_in_combat_is_alert(self):
        expectation = self.cast_failure_expectation()
        run = FakeRun({expectation.label: 95.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AggroRedirectScenarioTests(unittest.TestCase):
    def test_single_target_scenario_validates_and_shapes_one_expectation(self):
        spec = aggro_redirect_spec(beckon_aggro_redirect_entry())
        scenario, expectations = aggro_redirect_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        self.assertEqual(expectations[0].check, BEHAVIOUR_AGGRO_REDIRECT)
        self.assertEqual(expectations[0].spell_id, BECKON)
        self.assertEqual(expectations[0].displayed, '1')

    def test_area_scenario_shapes_one_expectation_per_target(self):
        spec = aggro_redirect_spec(absolution_aggro_redirect_entry())
        scenario, expectations = aggro_redirect_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 3)
        self.assertEqual([expectation.displayed for expectation in expectations], ['1', '1', '0'])

    def test_every_dummy_fixture_is_react_defensive(self):
        spec = aggro_redirect_spec(absolution_aggro_redirect_entry())
        scenario, _ = aggro_redirect_scenario(CLASS_FILE, spec)
        for creature in scenario['creatures']:
            self.assertEqual(creature['reaction'], AGGRO_REDIRECT_REACTION)

    def test_each_attack_precedes_its_own_before_measurement(self):
        spec = aggro_redirect_spec(absolution_aggro_redirect_entry())
        scenario, _ = aggro_redirect_scenario(CLASS_FILE, spec)
        for index in range(3):
            attack_index = next(i for i, step in enumerate(scenario['steps'])
                                if step.get('action') == 'attack' and step.get('target') == dummy_id(index))
            before_index = next(i for i, step in enumerate(scenario['steps'])
                                if step.get('label') == aggro_redirect_label(ABSOLUTION, index, 'before'))
            self.assertLess(attack_index, before_index)

    def test_every_attack_is_stopped_before_its_before_measurement(self):
        spec = aggro_redirect_spec(absolution_aggro_redirect_entry())
        scenario, _ = aggro_redirect_scenario(CLASS_FILE, spec)
        for index in range(3):
            attack_index = next(i for i, step in enumerate(scenario['steps'])
                                if step.get('action') == 'attack' and step.get('target') == dummy_id(index))
            stop_index = next(i for i, step in enumerate(scenario['steps'][attack_index:])
                              if step.get('action') == 'stop_attack') + attack_index
            before_index = next(i for i, step in enumerate(scenario['steps'])
                                if step.get('label') == aggro_redirect_label(ABSOLUTION, index, 'before'))
            self.assertLess(stop_index, before_index)

    def test_all_before_measurements_precede_the_cast(self):
        spec = aggro_redirect_spec(absolution_aggro_redirect_entry())
        scenario, _ = aggro_redirect_scenario(CLASS_FILE, spec)
        cast_index = next(i for i, step in enumerate(scenario['steps'])
                          if step.get('action') == 'cast' and step.get('spell') == ABSOLUTION)
        for index in range(3):
            before_index = next(i for i, step in enumerate(scenario['steps'])
                                if step.get('label') == aggro_redirect_label(ABSOLUTION, index, 'before'))
            self.assertLess(before_index, cast_index)

    def test_self_cast_has_no_explicit_target(self):
        spec = aggro_redirect_spec(absolution_aggro_redirect_entry())
        scenario, _ = aggro_redirect_scenario(CLASS_FILE, spec)
        cast_step = next(step for step in scenario['steps']
                         if step.get('action') == 'cast' and step.get('spell') == ABSOLUTION)
        self.assertNotIn('target', cast_step)

    def test_single_target_cast_targets_the_dummy(self):
        spec = aggro_redirect_spec(beckon_aggro_redirect_entry())
        scenario, _ = aggro_redirect_scenario(CLASS_FILE, spec)
        cast_step = next(step for step in scenario['steps']
                         if step.get('action') == 'cast' and step.get('spell') == BECKON)
        self.assertEqual(cast_step['target'], dummy_id(0))

    def test_every_expectation_label_has_a_matching_measurement_step(self):
        spec = aggro_redirect_spec(absolution_aggro_redirect_entry())
        scenario, expectations = aggro_redirect_scenario(CLASS_FILE, spec)
        measured_labels = {step.get('label') for step in scenario['steps'] if step.get('action') == 'assert'
                           and step.get('metric') == 'victim'}
        for expectation in expectations:
            self.assertIn(expectation.label, measured_labels)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, beckon_aggro_redirect_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_AGGRO_REDIRECT)


class JudgeAggroRedirectTests(unittest.TestCase):
    def redirected_expectation(self):
        model = {'kind': 'aggro_redirect', 'quote': 'Taunt an enemy to attack you'}
        return Expectation(aggro_redirect_label(BECKON, 0, 'after'), BEHAVIOUR_AGGRO_REDIRECT, BECKON, BECKON, None,
                           '1', 'prose: "Taunt an enemy to attack you" (804914)', model)

    def not_redirected_expectation(self):
        model = {'kind': 'aggro_redirect', 'quote': 'Taunt all enemies within 8 yds'}
        return Expectation(aggro_redirect_label(ABSOLUTION, 2, 'after'), BEHAVIOUR_AGGRO_REDIRECT, ABSOLUTION,
                           ABSOLUTION, None, '0', 'prose: "Taunt all enemies within 8 yds" (800424)', model)

    def test_victim_switched_to_caster_as_expected_is_ok(self):
        expectation = self.redirected_expectation()
        run = FakeRun({expectation.label: 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_victim_not_switched_as_expected_is_ok(self):
        expectation = self.not_redirected_expectation()
        run = FakeRun({expectation.label: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_taunted_dummy_whose_victim_did_not_switch_is_alert(self):
        expectation = self.redirected_expectation()
        run = FakeRun({expectation.label: 0.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_out_of_radius_dummy_whose_victim_switched_anyway_is_alert(self):
        expectation = self.not_redirected_expectation()
        run = FakeRun({expectation.label: 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_names_the_missing_label(self):
        expectation = self.redirected_expectation()
        run = FakeRun({})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertIn(expectation.label, verdict.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MountGrantScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_expectations(self):
        spec = mount_grant_spec(divine_charge_mount_grant_entry())
        scenario, expectations = mount_grant_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 2)
        granted, persisted = expectations
        self.assertEqual(granted.check, BEHAVIOUR_MOUNT_GRANT)
        self.assertEqual(granted.spell_id, DIVINE_CHARGE)
        self.assertEqual(granted.displayed, '14584')
        self.assertEqual(persisted.spell_id, DIVINE_CHARGE)
        self.assertEqual(persisted.rank_id, CRUSADERS_PRESENCE)
        self.assertEqual(persisted.displayed, '14584')

    def test_scenario_groups_the_caster_with_the_ally(self):
        spec = mount_grant_spec(divine_charge_mount_grant_entry())
        scenario, _ = mount_grant_scenario(CLASS_FILE, spec)
        self.assertTrue(any(step.get('action') == 'group' and step.get('target') == 'ally'
                            for step in scenario['steps']))
        self.assertEqual({player['id'] for player in scenario['players']}, {'caster', 'ally'})

    def test_divine_charge_cast_precedes_the_persistence_cast(self):
        spec = mount_grant_spec(divine_charge_mount_grant_entry())
        scenario, _ = mount_grant_scenario(CLASS_FILE, spec)
        grant_cast = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('action') == 'cast' and step.get('spell') == DIVINE_CHARGE)
        persist_cast = next(index for index, step in enumerate(scenario['steps'])
                            if step.get('action') == 'cast' and step.get('spell') == CRUSADERS_PRESENCE)
        self.assertLess(grant_cast, persist_cast)

    def test_every_cast_resets_its_own_cooldown_first(self):
        spec = mount_grant_spec(divine_charge_mount_grant_entry())
        scenario, _ = mount_grant_scenario(CLASS_FILE, spec)
        for spell in (DIVINE_CHARGE, CRUSADERS_PRESENCE):
            cast_index = next(index for index, step in enumerate(scenario['steps'])
                              if step.get('action') == 'cast' and step.get('spell') == spell)
            preceding = scenario['steps'][:cast_index]
            self.assertTrue(any(step.get('action') == 'reset_cooldown' and step.get('spell') == spell
                                for step in preceding))

    def test_every_expectation_label_has_a_matching_measurement_step(self):
        spec = mount_grant_spec(divine_charge_mount_grant_entry())
        scenario, expectations = mount_grant_scenario(CLASS_FILE, spec)
        measured_labels = {step.get('label') for step in scenario['steps'] if step.get('action') == 'assert'
                           and step.get('metric') == 'mount_display_id'}
        for expectation in expectations:
            self.assertIn(expectation.model['caster_label'], measured_labels)
            self.assertIn(expectation.model['ally_label'], measured_labels)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, divine_charge_mount_grant_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_MOUNT_GRANT)


class JudgeMountGrantTests(unittest.TestCase):
    def granted_expectation(self):
        model = {'kind': 'mount_grant', 'caster_label': '527023 mount_grant caster granted',
                 'ally_label': '527023 mount_grant ally granted', 'expected': 14584, 'moment': 'granted',
                 'quote': 'You and your party members leap upon a divine steed,'}
        return Expectation('527023 behaviour_mount_grant granted', BEHAVIOUR_MOUNT_GRANT, DIVINE_CHARGE,
                           DIVINE_CHARGE, None, '14584',
                           'prose: "You and your party members leap upon a divine steed," (527023)', model)

    def persisted_expectation(self):
        model = {'kind': 'mount_grant', 'caster_label': '527023 mount_grant caster persisted',
                 'ally_label': '527023 mount_grant ally persisted', 'expected': 14584, 'moment': 'persisted',
                 'quote': 'While active, casting does not dismount you or your allies.'}
        return Expectation('527023 behaviour_mount_grant persisted', BEHAVIOUR_MOUNT_GRANT, DIVINE_CHARGE,
                           CRUSADERS_PRESENCE, None, '14584',
                           'prose: "While active, casting does not dismount you or your allies." (527023)', model)

    def test_both_actors_mounted_is_ok(self):
        expectation = self.granted_expectation()
        run = FakeRun({'527023 mount_grant caster granted': 14584.0, '527023 mount_grant ally granted': 14584.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_ally_not_mounted_is_alert(self):
        expectation = self.granted_expectation()
        run = FakeRun({'527023 mount_grant caster granted': 14584.0, '527023 mount_grant ally granted': 0.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_caster_not_mounted_is_alert(self):
        expectation = self.granted_expectation()
        run = FakeRun({'527023 mount_grant caster granted': 0.0, '527023 mount_grant ally granted': 14584.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_both_actors_still_mounted_after_the_unrelated_cast_is_ok(self):
        expectation = self.persisted_expectation()
        run = FakeRun({'527023 mount_grant caster persisted': 14584.0, '527023 mount_grant ally persisted': 14584.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_caster_dismounted_by_the_unrelated_cast_is_alert(self):
        expectation = self.persisted_expectation()
        run = FakeRun({'527023 mount_grant caster persisted': 0.0, '527023 mount_grant ally persisted': 14584.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_explains_which_label(self):
        expectation = self.granted_expectation()
        run = FakeRun({'527023 mount_grant caster granted': 14584.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertIn('527023 mount_grant ally granted', verdict.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class InternalCooldownScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_the_expectation(self):
        spec = internal_cooldown_spec(disciplined_blows_entry())
        scenario, expectations = internal_cooldown_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_INTERNAL_COOLDOWN)
        self.assertEqual(expectation.spell_id, DISCIPLINED_BLOWS)
        self.assertEqual(expectation.rank_id, 578276)
        self.assertEqual(expectation.model['window_ms'], 500)

    def test_the_item_use_lands_between_the_first_and_third_heal_casts(self):
        spec = internal_cooldown_spec(disciplined_blows_entry())
        scenario, _ = internal_cooldown_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        cast_indexes = [index for index, step in enumerate(steps)
                        if step.get('action') == 'cast' and step.get('spell') == 578276]
        item_index = next(index for index, step in enumerate(steps) if step.get('action') == 'use_item')
        self.assertEqual(len(cast_indexes), 2)
        self.assertLess(cast_indexes[0], item_index)
        self.assertLess(item_index, cast_indexes[1])

    def test_every_cast_resets_the_trigger_spells_own_cooldown_first(self):
        spec = internal_cooldown_spec(disciplined_blows_entry())
        scenario, _ = internal_cooldown_scenario(CLASS_FILE, spec)
        steps = scenario['steps']
        cast_indexes = [index for index, step in enumerate(steps)
                        if step.get('action') == 'cast' and step.get('spell') == 578276]
        for cast_index in cast_indexes:
            preceding = steps[:cast_index]
            self.assertTrue(any(step.get('action') == 'reset_cooldown' and step.get('spell') == 578276
                                for step in preceding))

    def test_every_measurement_label_has_a_matching_assert_step(self):
        spec = internal_cooldown_spec(disciplined_blows_entry())
        scenario, expectations = internal_cooldown_scenario(CLASS_FILE, spec)
        measured_labels = {step.get('label') for step in scenario['steps'] if step.get('action') == 'assert'
                           and step.get('metric') == 'spell_cast_count'
                           and step.get('spell') == DISCIPLINED_BLOWS_PULSE}
        model = expectations[0].model
        for key in ('first_label', 'blocked_label', 'allowed_label'):
            self.assertIn(model[key], measured_labels)

    def test_dispatch_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, disciplined_blows_entry())
        run.validate(scenario)
        self.assertEqual(expectations[0].check, BEHAVIOUR_INTERNAL_COOLDOWN)


class JudgeInternalCooldownTests(unittest.TestCase):
    def expectation(self):
        model = {'kind': 'internal_cooldown', 'first_label': '680397 internal_cooldown first',
                 'blocked_label': '680397 internal_cooldown blocked',
                 'allowed_label': '680397 internal_cooldown allowed', 'window_ms': 500,
                 'quote': 'Only occurs once every 0.5 sec.'}
        return Expectation('680397 behaviour_internal_cooldown', BEHAVIOUR_INTERNAL_COOLDOWN, DISCIPLINED_BLOWS,
                           578276, None, '500', 'prose: "Only occurs once every 0.5 sec." (680397)', model)

    def test_a_blocked_second_heal_and_a_later_third_heal_firing_is_ok(self):
        expectation = self.expectation()
        run = FakeRun({'680397 internal_cooldown first': 1.0, '680397 internal_cooldown blocked': 1.0,
                      '680397 internal_cooldown allowed': 2.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_a_second_heal_firing_inside_the_window_is_alert(self):
        expectation = self.expectation()
        run = FakeRun({'680397 internal_cooldown first': 1.0, '680397 internal_cooldown blocked': 2.0,
                      '680397 internal_cooldown allowed': 3.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_a_third_heal_still_blocked_past_the_window_is_alert(self):
        expectation = self.expectation()
        run = FakeRun({'680397 internal_cooldown first': 1.0, '680397 internal_cooldown blocked': 1.0,
                      '680397 internal_cooldown allowed': 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_missing_measurement_explains_which_label(self):
        expectation = self.expectation()
        run = FakeRun({'680397 internal_cooldown first': 1.0, '680397 internal_cooldown blocked': 1.0})
        verdict = judge_behaviour(base_verdict(expectation), run, expectation)
        self.assertIn('680397 internal_cooldown allowed', verdict.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class DispelRemovalScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_one_expectation_per_debuff(self):
        spec = dispel_removal_spec(rebuke_entry())
        scenario, expectations = dispel_removal_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 3)
        for expectation in expectations:
            self.assertEqual(expectation.check, BEHAVIOUR_METRIC_DELTA)
            self.assertEqual(expectation.model['metric'], 'aura')
            self.assertEqual(expectation.model['before_expected'], 1.0)
            self.assertEqual(expectation.model['expected'], 0.0)
            self.assertTrue(expectation.rule.startswith('prose: "dispelling $s1 magic, poison, and disease effects'))

    def test_debuffs_are_applied_to_the_ally_target_and_measured_before_and_after(self):
        spec = dispel_removal_spec(rebuke_entry())
        scenario, _ = dispel_removal_scenario(CLASS_FILE, spec)
        set_aura_steps = [step for step in scenario['steps'] if step.get('action') == 'set_aura']
        self.assertEqual({step['spell'] for step in set_aura_steps}, {31589, 2818, 55095})
        self.assertTrue(all(step['actor'] == 'ally' for step in set_aura_steps))
        aura_measurements = [step for step in scenario['steps']
                            if step.get('metric') == 'aura' and step.get('spell') in (31589, 2818, 55095)]
        self.assertEqual(len(aura_measurements), 6)
        self.assertTrue(all(step['actor'] == 'ally' for step in aura_measurements))
        self.assertEqual(len(scenario['players']), 2)
        self.assertEqual(scenario['players'][1]['id'], 'ally')

    def test_dispel_cast_comes_after_the_debuffs_and_before_the_after_measurement(self):
        spec = dispel_removal_spec(rebuke_entry())
        scenario, _ = dispel_removal_scenario(CLASS_FILE, spec)
        set_aura_indexes = [index for index, step in enumerate(scenario['steps']) if step.get('action') == 'set_aura']
        cast_index = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('action') == 'cast' and step.get('spell') == REBUKE)
        measure_after_index = next(index for index, step in enumerate(scenario['steps'])
                                   if step.get('label', '').endswith(' after'))
        self.assertTrue(all(step_index < cast_index for step_index in set_aura_indexes))
        self.assertLess(cast_index, measure_after_index)

    def test_self_target_dispel_does_not_add_a_second_player_fixture(self):
        spec = dispel_removal_spec(testament_of_fortitude_dispel_entry())
        scenario, expectations = dispel_removal_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        self.assertEqual(len(scenario['players']), 1)
        set_aura_step = next(step for step in scenario['steps'] if step.get('action') == 'set_aura')
        self.assertEqual(set_aura_step['actor'], 'caster')
        self.assertEqual(set_aura_step['spell'], 55095)

    def test_entries_declaring_gameplay_clock_carry_it_into_every_expectation(self):
        spec = dispel_removal_spec(testament_of_fortitude_dispel_entry())
        self.assertEqual(spec.gameplay_clock, 'real')
        _, expectations = dispel_removal_scenario(CLASS_FILE, spec)
        self.assertEqual(expectations[0].model['gameplay_clock'], 'real')

    def test_entries_without_gameplay_clock_leave_it_unset(self):
        spec = dispel_removal_spec(rebuke_entry())
        self.assertIsNone(spec.gameplay_clock)
        _, expectations = dispel_removal_scenario(CLASS_FILE, spec)
        self.assertTrue(all(expectation.model['gameplay_clock'] is None for expectation in expectations))

    def test_dispatch_rebuke_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, rebuke_entry())
        run.validate(scenario)
        self.assertEqual(len(expectations), 3)


class JudgeDispelRemovalTests(unittest.TestCase):
    def expectation(self, debuff: int) -> Expectation:
        model = {'kind': 'metric_delta', 'before_label': f'before_{debuff}', 'after_label': f'after_{debuff}',
                 'expected': 0.0, 'before_expected': 1.0, 'metric': 'aura',
                 'quote': 'dispelling $s1 magic, poison, and disease effects from them'}
        return Expectation('label', BEHAVIOUR_METRIC_DELTA, REBUKE, REBUKE, None, '0',
                           'prose: "dispelling $s1 magic, poison, and disease effects from them" (525051)', model)

    def test_debuff_actually_removed_is_ok(self):
        expectation = self.expectation(2818)
        verdict = judge_behaviour(base_verdict(expectation),
                                  FakeRun({'before_2818': 1.0, 'after_2818': 0.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_debuff_left_in_place_is_an_alert(self):
        expectation = self.expectation(2818)
        verdict = judge_behaviour(base_verdict(expectation),
                                  FakeRun({'before_2818': 1.0, 'after_2818': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 1.0)
        self.assertEqual(verdict.expected, 0.0)

    def test_debuff_never_applied_before_the_cast_is_an_alert(self):
        expectation = self.expectation(55095)
        verdict = judge_behaviour(base_verdict(expectation),
                                  FakeRun({'before_55095': 0.0, 'after_55095': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AuraPresenceScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_one_expectation(self):
        spec = aura_presence_spec(harmonic_disposition_entry())
        scenario, expectations = aura_presence_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(expectation.model['metric'], 'water_walk')
        self.assertEqual(expectation.model['before_expected'], 0.0)
        self.assertEqual(expectation.model['expected'], 1.0)
        self.assertTrue(expectation.rule.startswith('prose: "and granting the ability to walk on water."'))

    def test_the_ally_is_grouped_and_measured_before_and_after_the_cast(self):
        spec = aura_presence_spec(harmonic_disposition_entry())
        scenario, _ = aura_presence_scenario(CLASS_FILE, spec)
        group_steps = [step for step in scenario['steps'] if step.get('action') == 'group']
        self.assertEqual(group_steps, [{'action': 'group', 'actor': 'caster', 'target': 'ally'}])
        water_walk_measurements = [step for step in scenario['steps'] if step.get('metric') == 'water_walk']
        self.assertEqual(len(water_walk_measurements), 2)
        self.assertTrue(all(step['actor'] == 'ally' for step in water_walk_measurements))
        self.assertEqual(len(scenario['players']), 2)
        self.assertEqual(scenario['players'][1]['id'], 'ally')

    def test_cast_targets_the_caster_and_comes_between_the_two_measurements(self):
        spec = aura_presence_spec(harmonic_disposition_entry())
        scenario, _ = aura_presence_scenario(CLASS_FILE, spec)
        measure_indexes = [index for index, step in enumerate(scenario['steps']) if step.get('metric') == 'water_walk']
        cast_index = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('action') == 'cast' and step.get('spell') == HARMONIC_DISPOSITION)
        self.assertEqual(scenario['steps'][cast_index]['target'], 'caster')
        self.assertEqual(measure_indexes, sorted(measure_indexes))
        self.assertLess(measure_indexes[0], cast_index)
        self.assertLess(cast_index, measure_indexes[1])

    def test_dispatch_harmonic_disposition_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, harmonic_disposition_entry())
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)


class JudgeAuraPresenceTests(unittest.TestCase):
    def expectation(self) -> Expectation:
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after',
                 'expected': 1.0, 'before_expected': 0.0, 'metric': 'water_walk',
                 'quote': 'and granting the ability to walk on water.'}
        return Expectation('label', BEHAVIOUR_METRIC_DELTA, HARMONIC_DISPOSITION, HARMONIC_DISPOSITION, None, '1',
                           'prose: "and granting the ability to walk on water." (560653)', model)

    def test_aura_actually_granted_is_ok(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 1.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_aura_never_granted_is_an_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)
        self.assertEqual(verdict.expected, 1.0)

    def test_aura_already_present_before_the_cast_is_an_alert(self):
        expectation = self.expectation()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 1.0, 'after': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HealBlockScenarioTests(unittest.TestCase):
    def test_scenario_validates_and_shapes_one_blocked_expectation_for_undead(self):
        spec = heal_block_spec(interdict_heal_block_entry('undead'))
        scenario, expectations = heal_block_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_HEAL_BLOCK)
        self.assertEqual(expectation.model['blocked'], True)
        self.assertTrue(expectation.rule.startswith(
            'prose: "If they are an Undead or Demon they are unable to be healed for the duration."'))

    def test_scenario_shapes_an_unblocked_expectation_for_the_control(self):
        spec = heal_block_spec(interdict_heal_block_entry('control'))
        scenario, expectations = heal_block_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(expectations[0].model['blocked'], False)

    def test_silence_cast_comes_between_the_before_and_after_aura_measurements(self):
        spec = heal_block_spec(interdict_heal_block_entry('undead'))
        scenario, _ = heal_block_scenario(CLASS_FILE, spec)
        cast_index = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('action') == 'cast' and step.get('spell') == INTERDICT)
        self.assertEqual(scenario['steps'][cast_index]['target'], 'dummy')
        measure_indexes = [index for index, step in enumerate(scenario['steps'])
                          if step.get('metric') == 'aura' and step.get('spell') == 561309]
        self.assertEqual(len(measure_indexes), 2)
        self.assertTrue(all(step['actor'] == 'dummy' for index, step in enumerate(scenario['steps'])
                            if index in measure_indexes))
        self.assertLess(measure_indexes[0], cast_index)
        self.assertLess(cast_index, measure_indexes[1])

    def test_creature_fixture_uses_the_entry_s_own_creature_type(self):
        spec = heal_block_spec(interdict_heal_block_entry('demon'))
        scenario, _ = heal_block_scenario(CLASS_FILE, spec)
        self.assertEqual(scenario['creatures'][0]['entry'], 416)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_dispatch_interdict_through_behaviour_scenario(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, interdict_heal_block_entry('undead'))
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)


class JudgeHealBlockTests(unittest.TestCase):
    def expectation(self, blocked: bool) -> Expectation:
        model = {'kind': 'heal_block', 'before_label': 'before', 'after_label': 'after', 'blocked': blocked,
                 'quote': 'If they are an Undead or Demon they are unable to be healed for the duration.'}
        return Expectation('label', BEHAVIOUR_HEAL_BLOCK, INTERDICT, INTERDICT, None,
                           'blocked' if blocked else 'heals',
                           'prose: "If they are an Undead or Demon they are unable to be healed for the '
                           'duration." (560116)', model)

    def test_block_aura_present_after_the_cast_is_ok(self):
        expectation = self.expectation(True)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 1.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_block_aura_absent_although_it_should_be_present_is_an_alert(self):
        expectation = self.expectation(True)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 0.0)

    def test_block_aura_absent_on_the_unblocked_control_is_ok(self):
        expectation = self.expectation(False)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 0.0}), expectation)
        self.assertEqual(verdict.status, 'ok')

    def test_block_aura_present_on_the_control_is_an_alert(self):
        expectation = self.expectation(False)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({'before': 0.0, 'after': 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 1.0)



def class_entry(spell: int, kind: str) -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == spell and entry['kind'] == kind)


def first_index(steps: list[dict], **match) -> int:
    return next(index for index, step in enumerate(steps) if all(step.get(k) == v for k, v in match.items()))


TESTAMENT_OF_RESOLVE = 804228
TESTAMENT_OF_STRENGTH = 300514
CREATURE_FEAR = 12096
PSYCHIC_HORROR = 64044
FAITH_GUARD = 705259
FAITH = 706466


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CastStateScenarioTests(unittest.TestCase):
    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE,
                                                              class_entry(TESTAMENT_OF_RESOLVE, 'cast_state'))
        self.steps = self.scenario['steps']

    def test_scenario_validates_and_expects_control_refused_state_held_spell_allowed(self):
        run.validate(self.scenario)
        self.assertEqual([(e.label, e.check, e.displayed) for e in self.expectations],
                         [('804228 cast_state control', BEHAVIOUR_CAST_CONDITION, '34'),
                          ('804228 cast_state state', BEHAVIOUR_CAST_CONDITION, '1'),
                          ('804228 cast_state allowed', BEHAVIOUR_CAST_CONDITION, str(NO_CAST_FAILURE))])

    def test_the_dummy_applies_the_state_before_the_control_and_the_spell_come_last(self):
        state = first_index(self.steps, action='set_aura', spell=CREATURE_FEAR)
        self.assertEqual(self.steps[state]['caster'], 'dummy')
        control = first_index(self.steps, action='cast', spell=TESTAMENT_OF_STRENGTH)
        held = first_index(self.steps, label='804228 cast_state state')
        allowed = first_index(self.steps, action='cast', spell=TESTAMENT_OF_RESOLVE)
        self.assertLess(state, control)
        self.assertLess(control, held)
        self.assertLess(held, allowed)

    def test_an_allowed_control_or_a_refused_spell_is_alert(self):
        control, _, allowed = self.expectations
        for expectation, value in ((control, NO_CAST_FAILURE), (allowed, 34)):
            verdict = judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: float(value)}),
                                      expectation)
            self.assertEqual(verdict.status, 'alert')
        verdict = judge_behaviour(base_verdict(allowed), FakeRun({allowed.label: 0.0}), allowed)
        self.assertEqual(verdict.status, 'ok')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ImmunityScenarioTests(unittest.TestCase):
    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE,
                                                              class_entry(TESTAMENT_OF_RESOLVE, 'immunity'))
        self.steps = self.scenario['steps']
        self.by_label = {expectation.label: expectation for expectation in self.expectations}

    def test_scenario_validates_and_expects_each_effect_present_then_absent(self):
        run.validate(self.scenario)
        self.assertTrue(all(e.check == BEHAVIOUR_IMMUNITY for e in self.expectations))
        for effect in (CREATURE_FEAR, PSYCHIC_HORROR):
            self.assertEqual(self.by_label[f'804228 immunity {effect} without'].displayed, '1')
            self.assertEqual(self.by_label[f'804228 immunity {effect} with'].displayed, '0')
            self.assertEqual(self.by_label[f'804228 immunity {effect} control'].displayed, '1')
        self.assertEqual(self.by_label['804228 immunity 804228 applied'].displayed, '1')
        self.assertEqual(self.by_label['804228 immunity 804228 expired'].displayed, '0')

    def dummy_casts(self, effect):
        return [index for index, step in enumerate(self.steps)
                if step.get('action') == 'cast' and step.get('actor') == 'dummy' and step.get('spell') == effect]

    def test_the_dummy_casts_each_effect_after_the_spell_lands(self):
        landed = first_index(self.steps, label='804228 immunity 804228 applied')
        for effect in (CREATURE_FEAR, PSYCHIC_HORROR):
            casts = self.dummy_casts(effect)[:IMMUNITY_CASTS]
            self.assertLess(landed, casts[0])
            self.assertLess(casts[-1], first_index(self.steps, label=f'804228 immunity {effect} with'))

    def test_the_same_dummy_casts_land_once_the_spell_has_expired(self):
        landed = first_index(self.steps, label='804228 immunity 804228 applied')
        expired = first_index(self.steps, label='804228 immunity 804228 expired')
        waited = sum(step['ms'] for step in self.steps[landed:expired] if step.get('action') == 'wait')
        self.assertGreater(waited, 10000)
        for effect in (CREATURE_FEAR, PSYCHIC_HORROR):
            casts = self.dummy_casts(effect)
            self.assertEqual(len(casts), 2 * IMMUNITY_CASTS)
            control = casts[IMMUNITY_CASTS:]
            self.assertLess(expired, control[0])
            self.assertLess(control[-1], first_index(self.steps, label=f'804228 immunity {effect} control'))

    def test_a_control_effect_that_does_not_land_is_alert(self):
        expectation = self.by_label[f'804228 immunity {CREATURE_FEAR} control']
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: 0.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_an_effect_present_under_the_immunity_is_alert(self):
        expectation = self.by_label[f'804228 immunity {CREATURE_FEAR} with']
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: 1.0}), expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_an_effect_word_missing_from_the_quote_is_refused(self):
        entry = dict(class_entry(TESTAMENT_OF_RESOLVE, 'immunity'))
        entry['effects'] = [{'spell': CREATURE_FEAR, 'words': 'stun'}]
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ThreatSlopeScenarioTests(unittest.TestCase):
    def setUp(self):
        self.scenario, (self.expectation,) = behaviour_scenario(CLASS_FILE, class_entry(FAITH_GUARD, 'threat_slope'))
        self.model = self.expectation.model

    def readings(self, threat: float, lost: float, cast: float = NO_CAST_FAILURE) -> FakeRun:
        return FakeRun({self.model['cast_label']: cast, self.model['health_before_label']: 10000.0,
                        self.model['health_after_label']: 10000.0 - lost, self.model['threat_label']: threat})

    def judged(self, run_values: FakeRun) -> Verdict:
        return judge_behaviour(base_verdict(self.expectation), run_values, self.expectation)

    def test_scenario_validates_and_takes_the_flat_threat_from_the_dbc(self):
        run.validate(self.scenario)
        self.assertEqual(self.expectation.check, BEHAVIOUR_THREAT_SLOPE)
        self.assertEqual(self.model['flat'], 100.0)
        self.assertEqual(self.model['expected'], 2.0)

    def test_twice_the_damage_plus_the_flat_threat_is_ok(self):
        self.assertEqual(self.judged(self.readings(400.0, 150.0)).status, 'ok')

    def test_unscaled_damage_threat_is_alert(self):
        self.assertEqual(self.judged(self.readings(250.0, 150.0)).status, 'alert')

    def test_a_hit_that_did_not_land_is_unmeasured(self):
        self.assertEqual(self.judged(self.readings(100.0, 0.0)).status, 'unmeasured')
        self.assertEqual(self.judged(self.readings(400.0, 150.0, cast=34.0)).status, 'unmeasured')



def variant_entry(spell: int, kind: str, variant: str) -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == spell and entry['kind'] == kind and entry.get('variant') == variant)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ThreatTickPeriodTests(unittest.TestCase):
    def test_tick_count_arms_carry_their_own_labels_and_waits(self):
        for variant, wait, ratio in (('before_tick', 600, 1.0), ('period', 3200, 0.941192)):
            scenario, (expectation,) = behaviour_scenario(
                CLASS_FILE, variant_entry(RIGHTEOUS_CUSTODIAN, 'threat_tick_ratio', variant))
            run.validate(scenario)
            self.assertEqual(expectation.label, f'572808 behaviour_metric_ratio_delta {variant}')
            self.assertEqual(expectation.model['expected_ratio'], ratio)
            waits = [step['ms'] for step in scenario['steps'] if step.get('label', '').startswith('let exactly')]
            self.assertEqual(waits, [wait])

    def test_seeded_two_ticks_in_the_three_tick_window_is_alert(self):
        _, (expectation,) = behaviour_scenario(CLASS_FILE,
                                               variant_entry(RIGHTEOUS_CUSTODIAN, 'threat_tick_ratio', 'period'))
        model = expectation.model
        for after, status in ((941.192, 'ok'), (960.4, 'alert'), (922.368, 'alert')):
            values = FakeRun({model['before_label']: 1000.0, model['after_label']: after, **cast_applied(model)})
            self.assertEqual(judge_behaviour(base_verdict(expectation), values, expectation).status, status)

    def test_the_single_tick_entry_keeps_its_label(self):
        _, (expectation,) = behaviour_scenario(CLASS_FILE, righteous_custodian_entry())
        self.assertEqual(expectation.label, '572808 behaviour_metric_ratio_delta')
        self.assertNotIn('ticks', expectation.model)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GroupTargetScenarioTests(unittest.TestCase):
    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE,
                                                              class_entry(RIGHTEOUS_CUSTODIAN, 'group_target'))
        self.steps = self.scenario['steps']

    def test_outsider_is_refused_before_the_party_and_raid_arms(self):
        run.validate(self.scenario)
        self.assertEqual([(e.label, e.displayed) for e in self.expectations],
                         [('572808 group_target outsider cast', '12'), ('572808 group_target outsider aura', '0'),
                          ('572808 group_target party cast', '0'), ('572808 group_target party aura', '1'),
                          ('572808 group_target raid cast', '0'), ('572808 group_target raid aura', '1')])
        outsider = first_index(self.steps, label='572808 group_target outsider cast')
        grouped = first_index(self.steps, action='group', target='ally')
        raider = first_index(self.steps, action='group', target='ally5')
        raid_cast = first_index(self.steps, label='572808 group_target raid cast')
        self.assertLess(outsider, grouped)
        self.assertLess(grouped, raider)
        self.assertLess(raider, raid_cast)
        self.assertEqual(len(self.scenario['players']), 6)

    def test_seeded_outsider_that_receives_the_blessing_is_alert(self):
        cast, aura = self.expectations[:2]
        for expectation, value in ((cast, NO_CAST_FAILURE), (aura, 1.0)):
            verdict = judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: float(value)}),
                                      expectation)
            self.assertEqual(verdict.status, 'alert')



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitRatioHealTests(unittest.TestCase):
    def test_the_healer_observes_its_own_heals_on_the_named_target(self):
        for variant, healer, target in (('done', 'caster', 'ally'), ('received', 'ally', 'caster')):
            scenario, (expectation,) = behaviour_scenario(CLASS_FILE, variant_entry(705278, 'hit_ratio', variant))
            validated = run.validate(scenario)
            self.assertEqual(expectation.label, f'705278 behaviour_hit_ratio {variant}')
            self.assertEqual(expectation.model['metric'], 'spell_heal_total')
            reads = [step for step in validated['steps'] if step.get('metric') in ('spell_heal_total',
                                                                                   'spell_heal_count')]
            self.assertTrue(reads)
            self.assertTrue(all(step['actor'] == healer and step['target'] == target for step in reads))
            casts = [step for step in validated['steps'] if step['action'] == 'cast']
            self.assertTrue(all(step['actor'] == healer and step['target'] == target for step in casts))
            self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])

    def test_the_talent_is_set_only_in_the_treatment_arm(self):
        scenario, (expectation,) = behaviour_scenario(CLASS_FILE, variant_entry(705278, 'hit_ratio', 'received'))
        self.assertAlmostEqual(expectation.model['expected_bonus'], 8.0)
        steps = scenario['steps']
        treatment = first_index(steps, label='705278 behaviour_hit_ratio received treatment start total')
        talent = [index for index, step in enumerate(steps)
                  if step['action'] == 'set_aura' and step['spell'] == 705278 and step['stacks'] == 1]
        self.assertTrue(talent)
        self.assertTrue(all(index > treatment for index in talent))

    def test_a_healed_target_is_set_to_its_health_before_each_heal(self):
        entry = {**variant_entry(705278, 'hit_ratio', 'done'), 'target_health_pct': 50}
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        for earlier, cast in zip([0] + casts, casts):
            healths = [step for step in steps[earlier:cast] if step['action'] == 'set_health']
            self.assertEqual([step['actor'] for step in healths], ['ally'])
        self.assertFalse([step for step in steps if step['action'] == 'set_health_pct'])

    def test_an_unknown_metric_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**variant_entry(705278, 'hit_ratio', 'done'), 'metric': 'aura'})

    def test_the_observed_rank_arms_the_caster(self):
        def equipped(entry: dict) -> list[dict]:
            scenario, _ = behaviour_scenario(CLASS_FILE, entry)
            return [step for step in scenario['steps'] if step['action'] in ('add_item', 'equip_item', 'equip')]
        self.assertNotEqual(equipped(variant_entry(572547, 'hit_ratio', 'talent')),
                            equipped(variant_entry(705278, 'hit_ratio', 'done')))


def cost_gate_entry(spell: int, variant: str | None = None) -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == spell and entry['kind'] == 'cost_gate' and entry.get('variant') == variant)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TrialToolStepTests(unittest.TestCase):
    def test_a_metric_delta_arms_the_caster_for_its_trigger_spell(self):
        entry = {**class_entry(705285, 'metric_delta'), 'trigger_spell': 573324, 'setup_casts': []}
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        equipped = [step['item'] for step in run.validate(scenario)['steps'] if step['action'] == 'equip']
        self.assertIn(CLASS_FILE['alternate_weapons'][0]['item'], equipped)

    def test_a_cooldown_gate_learns_its_after_casts(self):
        entry = {**class_entry(706309, 'cost_gate'), 'after_casts': [[807268, 'dummy']], 'after_wait_ms': 2000}
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        learned = first_index(steps, action='learn', spell=807268)
        self.assertLess(learned, first_index(steps, action='cast', spell=807268))

    def test_a_talent_aura_is_set_afresh_in_each_talent_arm(self):
        entry = {**class_entry(500694, 'cost_gate'), 'talent_aura_each_arm': True}
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        sets = [step['stacks'] for step in run.validate(scenario)['steps']
                if step['action'] == 'set_aura' and step['spell'] == 500694]
        self.assertEqual(sets, [0, 1, 0, 1])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CostGateScenarioTests(unittest.TestCase):
    def free_gate_entry(self):
        return {'spell': 705256, 'name': 'Determined', 'kind': 'cost_gate', 'label_suffix': 'free',
                'quote': 'now makes your next ability within $681136d free of cost.', 'gated_spell': 573049,
                'resource': 'power', 'reduction': 35, 'target': 'dummy', 'setup_casts': [[803792, 'ally']],
                'next_arm': True, 'aura_duration_ms': 5000, 'restore_charges': True}

    def test_a_cost_reduced_to_zero_has_no_beyond_arm(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, self.free_gate_entry())
        run.validate(scenario)
        self.assertEqual([(e.model['arm'], e.displayed, e.model['level']) for e in expectations],
                         [('without', '85', 0), ('with', '0', 0), ('next', '85', 0), ('held', '0', 0),
                          ('expired', '85', 0)])

    def test_an_ally_setup_cast_adds_the_ally_and_a_charge_steps_back_with_its_charges_restored(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, self.free_gate_entry())
        steps = run.validate(scenario)['steps']
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 803792]
        self.assertTrue(casts)
        for index in casts:
            before = [step['action'] for step in steps[index - 5:index]]
            self.assertIn('relocate', before)
            self.assertIn('restore_charges', before)
        plain = {key: value for key, value in self.free_gate_entry().items() if key != 'restore_charges'}
        plain_steps = run.validate(behaviour_scenario(CLASS_FILE, plain)[0])['steps']
        self.assertFalse([step for step in plain_steps if step['action'] == 'restore_charges'])

    def test_power_gate_refuses_without_the_talent_and_one_point_beyond(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, cost_gate_entry(301059, 'sacred_swing'))
        validated = run.validate(scenario)
        self.assertEqual([(e.label, e.displayed, e.model['level']) for e in expectations],
                         [('301059 cost_gate 572769 without', '85', 10), ('301059 cost_gate 572769 with', '0', 10),
                          ('301059 cost_gate 572769 beyond', '85', 9)])
        learn = first_index(validated['steps'], action='learn', spell=301059)
        self.assertLess(first_index(validated['steps'], label='301059 cost_gate 572769 without'), learn)
        self.assertLess(learn, first_index(validated['steps'], label='301059 cost_gate 572769 with'))
        self.assertFalse(scenario['players'][0]['allow_regeneration'])

    def test_cooldown_gate_waits_either_side_of_the_reduced_cooldown(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, cost_gate_entry(706309))
        run.validate(scenario)
        self.assertEqual([(e.displayed, e.model['level']) for e in expectations],
                         [('67', 15250.0), ('0', 15250.0), ('67', 14750.0)])
        waits = [step['ms'] for step in scenario['steps'] if step.get('label', '').endswith('cooldown wait')]
        self.assertEqual(waits, [15250, 15250, 14750])

    def test_fractional_reduction_and_the_next_and_duration_arms(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, cost_gate_entry(707364))
        validated = run.validate(scenario)
        self.assertEqual([(e.model['arm'], e.displayed, e.model['level'], e.model['held_ms']) for e in expectations],
                         [('without', '85', 8, 0), ('with', '0', 8, 0), ('next', '85', 8, 0), ('beyond', '85', 6, 0),
                          ('held', '0', 8, 4100), ('expired', '85', 8, 4700)])
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
        benedictions = [index for index, step in enumerate(validated['steps'])
                        if step['action'] == 'cast' and step['spell'] == 578276]
        self.assertEqual(len(benedictions), 5)
        next_attempt = first_index(validated['steps'], label='707364 cost_gate 803792 next')
        with_attempt = first_index(validated['steps'], label='707364 cost_gate 803792 with')
        self.assertFalse(any(with_attempt < index < next_attempt for index in benedictions))

    def test_seeded_reduction_that_does_not_apply_is_alert(self):
        _, expectations = behaviour_scenario(CLASS_FILE, cost_gate_entry(301059, 'righteous_lunge'))
        allowed = next(e for e in expectations if e.model['arm'] == 'with')
        verdict = judge_behaviour(base_verdict(allowed), FakeRun({allowed.label: 85.0}), allowed)
        self.assertEqual(verdict.status, 'alert')
        verdict = judge_behaviour(base_verdict(allowed), FakeRun({allowed.label: 0.0}), allowed)
        self.assertEqual(verdict.status, 'ok')

    def test_a_reduction_that_leaves_no_separating_level_is_not_modelled(self):
        with self.assertRaises(NotModelled):
            behaviour_scenario(CLASS_FILE, {**cost_gate_entry(301059, 'sacred_swing'), 'reduction': 21})

    def after_cast_entry(self) -> dict:
        return {'spell': 680953, 'name': 'Profound Enlightenment', 'kind': 'cost_gate',
                'quote': 'reducing the remaining cooldown of Testaments by $s1%', 'gated_spell': 801478,
                'resource': 'cooldown', 'reduction': 80000, 'target': 'caster',
                'after_casts': [[680953, 'caster']], 'after_wait_ms': 20000}

    def test_after_casts_cut_the_running_cooldown_in_the_talent_arms_only(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, self.after_cast_entry())
        steps = run.validate(scenario)['steps']
        self.assertEqual([(e.model['arm'], e.displayed, e.model['level']) for e in expectations],
                         [('without', '67', 100500.0), ('with', '0', 100500.0), ('beyond', '67', 99500.0)])
        after_casts = [index for index, step in enumerate(steps)
                       if step['action'] == 'cast' and step['spell'] == 680953]
        self.assertEqual(len(after_casts), 2)
        self.assertLess(first_index(steps, label='680953 cost_gate 801478 without'), after_casts[0])
        self.assertEqual(steps[after_casts[0] - 2], {'action': 'wait', 'label': 'with wait before the after casts',
                                                     'ms': 20000})
        waits = [step['ms'] for step in steps if step.get('label', '').endswith('cooldown wait')]
        self.assertEqual(waits, [100500, 80500, 79500])

    def test_seeded_reduction_of_the_full_cooldown_lets_the_beyond_attempt_through_and_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, self.after_cast_entry())
        beyond = next(e for e in expectations if e.model['arm'] == 'beyond')
        verdict = judge_behaviour(base_verdict(beyond), FakeRun({beyond.label: 0.0}), beyond)
        self.assertEqual(verdict.status, 'alert')

    def lengthening_entry(self) -> dict:
        return {'spell': 712678, 'name': 'Patience', 'kind': 'cost_gate',
                'quote': 'and its cooldown by $/1000;s2 sec', 'gated_spell': 560116, 'resource': 'cooldown',
                'reduction': -5000, 'target': 'dummy'}

    def test_a_negative_cooldown_reduction_is_judged_from_both_ends(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, self.lengthening_entry())
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        self.assertEqual([(e.model['arm'], e.displayed, e.model['level']) for e in expectations],
                         [('without', '0', 120500.0), ('base', '67', 120500.0), ('with', '0', 125500.0),
                          ('beyond', '67', 124500.0)])
        learn = first_index(steps, action='learn', spell=712678)
        self.assertLess(first_index(steps, label='712678 cost_gate 560116 without'), learn)
        self.assertLess(learn, first_index(steps, label='712678 cost_gate 560116 base'))

    def test_seeded_cooldown_that_is_not_lengthened_alerts_on_the_base_arm(self):
        _, expectations = behaviour_scenario(CLASS_FILE, self.lengthening_entry())
        base = next(e for e in expectations if e.model['arm'] == 'base')
        verdict = judge_behaviour(base_verdict(base), FakeRun({base.label: 0.0}), base)
        self.assertEqual(verdict.status, 'alert')

    def test_a_lengthening_refused_with_an_increase_inside_two_margins(self):
        with self.assertRaises(NotModelled):
            behaviour_scenario(CLASS_FILE, {**self.lengthening_entry(), 'reduction': -900})

    def reset_entry(self) -> dict:
        return {'spell': 805422, 'name': 'Tome of Light', 'kind': 'cost_gate',
                'quote': 'resets the cooldown of Barrier of Light and Tranquil Circle', 'gated_spell': 805417,
                'resource': 'cooldown', 'reduction': 90000, 'target': 'caster',
                'after_casts': [[805422, 'caster']], 'after_wait_ms': 2000, 'resets': True}

    def test_a_reset_is_attempted_once_just_after_the_after_casts_in_both_arms(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, self.reset_entry())
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        self.assertEqual([(e.model['arm'], e.displayed, e.model['level']) for e in expectations],
                         [('without', '67', 2500.0), ('with', '0', 2500.0)])
        tomes = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 805422]
        self.assertEqual(len(tomes), 1)
        self.assertLess(first_index(steps, label='805422 cost_gate 805417 without'), tomes[0])
        waits = [step['ms'] for step in steps if step.get('label', '').endswith('cooldown wait')]
        self.assertEqual(waits, [2500, 500])

    def test_seeded_reset_that_does_not_happen_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, self.reset_entry())
        allowed = next(e for e in expectations if e.model['arm'] == 'with')
        verdict = judge_behaviour(base_verdict(allowed), FakeRun({allowed.label: 67.0}), allowed)
        self.assertEqual(verdict.status, 'alert')

    def test_a_reset_needs_after_casts_on_a_cooldown_gate(self):
        entry = {**self.reset_entry(), 'after_casts': []}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    def trigger_after_cast_entry(self) -> dict:
        return {'spell': 573452, 'name': 'Eternally Devoted', 'kind': 'cost_gate',
                'quote': 'Damage dealt through Eternal Blessing now reduces the cooldown of Libram spells by',
                'gated_spell': 801461, 'resource': 'cooldown', 'reduction': 4000, 'target': 'caster',
                'setup_casts': [[705300, 'caster'], [572027, 'dummy']], 'after_casts': [[572027, 'dummy']],
                'after_wait_ms': 2000}

    def test_the_control_arm_casts_an_after_cast_that_is_not_the_talent(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, self.trigger_after_cast_entry())
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        without = first_index(steps, label='573452 cost_gate 801461 without')
        before_control = [step for step in steps[:without]
                          if step.get('label') == 'without wait before the after casts']
        self.assertEqual(len(before_control), 1)
        waits = [step['ms'] for step in steps if step.get('label', '').endswith('cooldown wait')]
        self.assertEqual(waits, [174500, 174500, 173500])

    def test_the_talent_itself_is_neither_learned_nor_cast_in_the_control_arm(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, self.after_cast_entry())
        steps = run.validate(scenario)['steps']
        without = first_index(steps, label='680953 cost_gate 801478 without')
        self.assertFalse(any(step.get('spell') == 680953 for step in steps[:without]))

    def test_a_cooldown_gate_beyond_the_real_clock_cap_runs_accelerated_only(self):
        entry = {'spell': 573452, 'name': 'Eternally Devoted', 'kind': 'cost_gate',
                 'quote': 'Damage dealt through Eternal Blessing now reduces the cooldown of Libram spells by',
                 'gated_spell': 801461, 'resource': 'cooldown', 'reduction': 4000, 'target': 'caster',
                 'setup_casts': [[705300, 'caster'], [572027, 'dummy']], 'after_casts': [[572027, 'dummy']],
                 'after_wait_ms': 2000}
        scenario, expectations = behaviour_scenario(CLASS_FILE, entry)
        self.assertGreater(scenario['timeout_ms'], MAX_SCENARIO_MS)
        run.validate(scenario, run.SIMULATED_CLOCK)
        with self.assertRaises(ValueError):
            run.validate(scenario)
        self.assertEqual([e.model['level'] for e in expectations], [176500.0, 176500.0, 175500.0])

    def test_after_casts_need_a_cooldown_gate_and_a_wait_below_the_beyond_attempt(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**cost_gate_entry(301059, 'sacred_swing'),
                                            'after_casts': [[680953, 'caster']]})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**self.after_cast_entry(), 'after_wait_ms': 99500})



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitRatioFixtureTests(unittest.TestCase):
    def test_fixture_stats_reach_the_caster_only(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, variant_entry(705284, 'hit_ratio', 'oath_breakers'))
        run.validate(scenario)
        self.assertEqual((scenario['players'][0]['attack_power'], scenario['players'][0]['spell_power']),
                         (20000, 20000))

    def test_an_unknown_fixture_stat_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**variant_entry(705284, 'hit_ratio', 'oath_breakers'),
                                            'fixture': {'strength': 100}})

    def test_warmup_casts_open_each_arm_before_its_start_reading(self):
        scenario, (expectation,) = behaviour_scenario(CLASS_FILE, variant_entry(705284, 'hit_ratio', 'condemn'))
        steps = run.validate(scenario)['steps']
        for arm in ('control', 'treatment'):
            start = first_index(steps, label=f'705284 behaviour_hit_ratio condemn {arm} start total')
            casts = [index for index, step in enumerate(steps[:start]) if step['action'] == 'cast']
            self.assertGreaterEqual(len(casts), 3)
        treatment = first_index(steps, label='705284 behaviour_hit_ratio condemn treatment start total')
        control = first_index(steps, label='705284 behaviour_hit_ratio condemn control start total')
        talent = first_index(steps, action='set_aura', spell=705284)
        self.assertLess(control, talent)
        self.assertLess(talent, treatment)

    def cast_spell_entry(self):
        return {'spell': 805409, 'name': 'Righteous Tempest', 'kind': 'hit_ratio', 'label_suffix': 'cast_spell',
                'quote': 'Consumes your Oaths, dealing additional damage for each consumed.', 'expected': 1.6,
                'cast_spell': 807274, 'observe_spell': 570205, 'cast_wait_ms': 5500, 'learn': [807274],
                'control': {}, 'treatment': {'auras': [[804904, 1]]}, 'critical': False, 'trials': 3}

    def test_a_cast_spell_is_cast_and_another_spells_hits_are_read_after_its_wait(self):
        scenario, (expectation,) = behaviour_scenario(CLASS_FILE, self.cast_spell_entry())
        steps = run.validate(scenario)['steps']
        self.assertFalse([step for step in steps if step['action'] == 'cast' and step['spell'] == 570205])
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 807274]
        self.assertEqual(len(casts), 6)
        waits = [step for step in steps if step['action'] == 'wait' and step.get('ms') == 5500]
        self.assertEqual(len(waits), 6)
        read = first_index(steps, label='805409 behaviour_hit_ratio cast_spell control 1 total')
        self.assertEqual(steps[read]['spell'], 570205)
        self.assertLess(casts[0], read)
        self.assertEqual(sum(1 for step in steps if step['action'] == 'learn' and step['spell'] == 807274), 1)

    def test_a_cast_spell_needs_another_observed_spell_and_a_wait_is_not_negative(self):
        entry = self.cast_spell_entry()
        for bad in ({**entry, 'cast_spell': 570205}, {**entry, 'cast_wait_ms': -1}):
            with self.subTest(bad={key: bad.get(key) for key in ('cast_spell', 'cast_wait_ms')}):
                with self.assertRaises(ValueError):
                    behaviour_scenario(CLASS_FILE, bad)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CastAppliesAuraCastSpellTests(unittest.TestCase):
    def test_a_named_cast_spell_is_learned_powered_and_cast_at_its_own_target(self):
        entry = class_entry(705295, 'cast_applies_aura')
        scenario, (expectation,) = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        cast = first_index(steps, action='cast', spell=572769)
        self.assertEqual(steps[cast]['target'], 'dummy')
        self.assertLess(first_index(steps, action='learn', spell=572769), cast)
        self.assertLess(first_index(steps, action='set_aura', spell=681170), cast)
        self.assertEqual(expectation.model['expected_ms'], 8000)
        self.assertIn('creatures', scenario)

    def test_a_cast_target_health_is_set_right_before_the_cast(self):
        entry = {**class_entry(705295, 'cast_applies_aura'), 'cast_target': 'caster', 'cast_target_health_pct': 50}
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        cast = first_index(steps, action='cast', spell=572769)
        health = first_index(steps, action='set_health', actor='caster')
        self.assertLess(health, cast)
        self.assertFalse([step for step in steps[health + 1:cast] if step['action'] == 'wait'])


    def test_a_forced_crit_sets_the_rating_in_the_readback_and_the_expiry_pair(self):
        from expiry import behaviour_expiry
        entry = {**class_entry(705295, 'cast_applies_aura'), 'force_crit': 'melee'}
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        expiry, _ = behaviour_expiry(CLASS_FILE, entry)
        for built in (scenario, expiry):
            run.validate(built)
            self.assertEqual(built['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)
        plain, _ = behaviour_scenario(CLASS_FILE, class_entry(705295, 'cast_applies_aura'))
        self.assertNotEqual(plain['players'][0].get('melee_crit_rating'), FORCED_CRIT_RATING)

    def test_a_forced_crit_needs_a_known_rating_and_a_cast_spell(self):
        entry = class_entry(705295, 'cast_applies_aura')
        without_cast = {key: value for key, value in entry.items() if key not in ('cast_spell', 'cast_target')}
        for bad in ({**entry, 'force_crit': 'ranged'}, {**without_cast, 'force_crit': 'melee'}):
            with self.subTest(force_crit=bad['force_crit']), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, bad)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class SitePurchaseScenarioTests(unittest.TestCase):
    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE, class_entry(804781, 'site_purchase'))
        self.steps = run.validate(self.scenario)['steps']

    def test_arms_check_the_site_and_the_price(self):
        self.assertEqual([(e.label, e.displayed) for e in self.expectations],
                         [('804781 site_purchase outside', '0'), ('804781 site_purchase paid', '1'),
                          ('804781 site_purchase spent', '0'), ('804781 site_purchase topped_up', '1')])
        purses = [step['copper'] for step in self.steps if step['action'] == 'money']
        self.assertEqual(purses, [100, 99, 1])
        teleports = [step['x'] for step in self.steps if step['action'] == 'teleport']
        self.assertEqual(teleports, [-14297.2, 2279.65, 659.762])

    def test_seeded_reward_learned_away_from_a_site_is_alert(self):
        outside = self.expectations[0]
        verdict = judge_behaviour(base_verdict(outside), FakeRun({outside.label: 1.0}), outside)
        self.assertEqual(verdict.status, 'alert')


PARRY_DANCE = 804912


class AttackMetricDeltaTest(unittest.TestCase):
    def setUp(self):
        self.entry = next(entry for entry in CLASS_FILE['behaviours']
                          if entry['spell'] == PARRY_DANCE and entry['kind'] == 'metric_delta')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_stack_cap_is_read_after_the_same_crit_swings_without_and_with_the_passive(self):
        scenario, [expectation] = metric_delta_scenario(CLASS_FILE, metric_delta_spec(self.entry))
        steps = run.validate(scenario)['steps']
        attacks = [index for index, step in enumerate(steps) if step['action'] == 'attack']
        learned = first_index(steps, action='learn', spell=PARRY_DANCE)
        before = first_index(steps, label=metric_delta_label(metric_delta_spec(self.entry), BEFORE))
        after = first_index(steps, label=metric_delta_label(metric_delta_spec(self.entry), AFTER))
        self.assertEqual(len(attacks), 2)
        self.assertLess(attacks[0], before)
        self.assertLess(before, learned)
        self.assertLess(learned, attacks[1])
        self.assertLess(attacks[1], after)
        self.assertEqual({steps[index + 1]['ms'] for index in attacks}, {10 * CLASS_FILE['weapon']['speed_ms']})
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)
        self.assertEqual(scenario['timeout_ms'],
                         sum(step['ms'] for step in steps if step['action'] == 'wait') + 60000)
        self.assertEqual((expectation.check, expectation.model['contrast'], expectation.model['metric']),
                         (BEHAVIOUR_METRIC_DELTA, 'learned', 'aura_stacks'))
        self.assertNotIn(PARRY_DANCE, [step.get('spell') for step in steps if step['action'] == 'cast'])

    def test_an_attack_trigger_refuses_setup_casts_or_another_gate_timing(self):
        for change in ({'gate_timing': 'start'}, {'setup_casts': [572027]}, {'target': 'caster'},
                       {'force_crit': 'ranged'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                metric_delta_scenario(CLASS_FILE, metric_delta_spec({**self.entry, **change}))



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class PeriodicDispelScenarioTests(unittest.TestCase):
    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE,
                                                              class_entry(TESTAMENT_OF_FORTITUDE, 'periodic_dispel'))
        self.steps = run.validate(self.scenario)['steps']

    def test_control_then_one_removal_per_period(self):
        self.assertEqual([(e.label, e.displayed) for e in self.expectations],
                         [('500678 periodic_dispel control', '2'), ('500678 periodic_dispel before_first', '2'),
                          ('500678 periodic_dispel after_1', '1'), ('500678 periodic_dispel after_2', '0')])
        control = first_index(self.steps, label='500678 periodic_dispel control 55095')
        cast = first_index(self.steps, action='cast', spell=TESTAMENT_OF_FORTITUDE)
        self.assertLess(control, cast)
        waits = [step['ms'] for step in self.steps if step.get('label', '').endswith(' wait')]
        self.assertEqual(waits, [2200, 800, 400, 1000])

    def test_seeded_removal_of_both_diseases_at_the_first_tick_is_alert(self):
        after_1 = self.expectations[2]
        values = FakeRun({label: 0.0 for label in after_1.model['sum_labels']})
        self.assertEqual(judge_behaviour(base_verdict(after_1), values, after_1).status, 'alert')
        values = FakeRun({after_1.model['sum_labels'][0]: 1.0, after_1.model['sum_labels'][1]: 0.0})
        self.assertEqual(judge_behaviour(base_verdict(after_1), values, after_1).status, 'ok')

    def test_one_debuff_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**class_entry(TESTAMENT_OF_FORTITUDE, 'periodic_dispel'),
                                            'debuffs': [55095]})


BURSTING_IMPACT = 705276
BLADE_SERMON = 572548
FROSTMANE_CLUB = 2259
ANCIENT_BONE_MACE = 30754


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class LevelFlatHitRatioTests(unittest.TestCase):
    def values(self, model: dict, control: float, treatment: float, scale: float = -20.0, wobble: float = 1.0):
        found = {}
        for arm, marks in model['reads'].items():
            per_hit = control if arm == 'control' else treatment
            total = 0.0
            for index, (total_label, count_label) in enumerate(marks):
                total += 0.0 if index == 0 else per_hit + (wobble if index % 2 else -wobble)
                found[total_label] = total
                found[count_label] = float(index)
        for arm, labels in model.get('scale_reads', {}).items():
            found.update(dict.fromkeys(labels, scale))
        return found

    def test_a_level_entry_puts_caster_and_undead_target_at_its_level_and_refreshes_its_auras(self):
        entry = variant_entry(706323, 'hit_ratio', 'level_50')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        self.assertEqual(scenario['players'][0]['level'], 50)
        self.assertEqual((scenario['creatures'][0]['level'], scenario['creatures'][0]['entry']), (50, 1501))
        self.assertEqual(expectation.model['expected_delta'], 38.0)
        refreshed = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == 54678
                     and step['stacks'] == 1]
        self.assertEqual(len(refreshed), 2 * (1 + entry['trials']))
        scales = [step for step in steps if step.get('metric') == 'aura_amount' and step['spell'] == 887007]
        self.assertEqual(len(scales), 2)
        _, [sixty] = behaviour_scenario(CLASS_FILE, variant_entry(706323, 'hit_ratio', 'level_60'))
        self.assertEqual(sixty.model['expected_delta'], 53.0)

    def test_seeded_flat_difference_is_judged_against_the_scaled_level_value(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, variant_entry(706323, 'hit_ratio', 'level_60'))
        for treatment, scale, status in ((92.4, -20.0, 'ok'), (103.0, -20.0, 'alert'), (88.0, -20.0, 'alert'),
                                         (103.0, 0.0, 'ok')):
            with self.subTest(treatment=treatment, scale=scale):
                verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(
                    expectation.model, 50.0, treatment, scale)), expectation)
                self.assertEqual(verdict.status, status)

    def test_a_level_above_the_class_level_or_a_flat_token_without_swings_is_refused(self):
        entry = variant_entry(706323, 'hit_ratio', 'level_60')
        for broken in ({**entry, 'level': 61}, {**entry, 'swing_hand': None, 'observe_spell': 706323},
                       {**entry, 'expected_token': ''}):
            with self.subTest(broken=broken.get('level')), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, broken)


class PooledRateHitRatioTests(unittest.TestCase):
    def entry(self, **changes):
        entry = next(entry for entry in CLASS_FILE['behaviours']
                     if entry['spell'] == 301310 and entry.get('label_suffix') == 'spell_penetration')
        return {**entry, **changes}

    def run_of(self, model: dict, control: float, treatment: float, events: tuple[float, float] = (1.0, 1.0)):
        found = {}
        for arm, marks in model['reads'].items():
            per_trial = control if arm == 'control' else treatment
            for index, (total, count) in enumerate(marks):
                found[total] = index * per_trial * (events[0] if model.get('rate') else 1.0)
                found[count] = index * (events[1] if model.get('rate') else 1.0)
        return FakeRun(found)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_pooled_entry_judges_the_trials_of_every_part_together(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        self.assertEqual(expectation.model['parts'], 12)
        base = base_verdict(expectation)
        one = compare_module.behaviour_hit_ratio_verdict(base, self.run_of(expectation.model, 2000.0, 2150.0),
                                                         expectation.model)
        pooled = compare_module.behaviour_hit_ratio_verdict(
            base, [self.run_of(expectation.model, 2000.0 + wobble, 2150.0 - wobble) for wobble in (-40.0, 40.0)],
            expectation.model)
        self.assertEqual((one.status, pooled.status), ('ok', 'ok'))
        self.assertEqual(pooled.detail['parts'], 2)
        flat = compare_module.behaviour_hit_ratio_verdict(
            base, [self.run_of(expectation.model, 2000.0, 2000.0)] * 2, expectation.model)
        self.assertEqual(flat.status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_crit_rate_counts_critical_hits_over_all_hits_in_points(self):
        entry = self.entry(rate='critical', expected_points=50, critical=None, parts=1, label_suffix='crit_rate')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        totals = [step for step in steps if step.get('label', '').endswith(' total')]
        counts = [step for step in steps if step.get('label', '').endswith(' count')]
        self.assertTrue(all(step['metric'] == 'spell_damage_count' and step['critical'] for step in totals))
        self.assertTrue(all(step['metric'] == 'spell_damage_count' and 'critical' not in step for step in counts))
        model = expectation.model
        for treatment, status in ((0.6, 'ok'), (0.4, 'alert')):
            values = {}
            for arm, marks in model['reads'].items():
                rate, crits = (0.1 if arm == 'control' else treatment), 0.0
                for index, (total, count) in enumerate(marks):
                    crits += 0.0 if index == 0 else rate + (0.01 if index % 2 else -0.01)
                    values[total], values[count] = crits, float(index)
            with self.subTest(treatment=treatment):
                verdict = compare_module.behaviour_hit_ratio_verdict(base_verdict(expectation), FakeRun(values), model)
                self.assertEqual(verdict.status, status)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_control_arm_that_never_crits_is_judged(self):
        entry = variant_entry(520608, 'hit_ratio', 'argent_blade_crit_rate')
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        model = expectation.model
        self.assertEqual((model['rate'], model['parts'], model['expected_delta']), ('critical', 76, 50.0))
        for treatment, status in ((0.5, 'ok'), (0.45, 'alert')):
            values = {}
            for arm, marks in model['reads'].items():
                rate, crits = (0.0 if arm == 'control' else treatment), 0.0
                for index, (total, count) in enumerate(marks):
                    crits += 0.0 if index == 0 or not rate else rate + (0.01 if index % 2 else -0.01)
                    values[total], values[count] = crits, float(index)
            with self.subTest(treatment=treatment):
                verdict = compare_module.behaviour_hit_ratio_verdict(base_verdict(expectation), FakeRun(values), model)
                self.assertEqual(verdict.status, status)
                self.assertNotIn('ratio', verdict.explanation.split(';')[0])

    def test_a_rate_without_its_points_or_its_proc_spell_is_refused(self):
        for broken in (self.entry(rate='critical', critical=None, parts=1),
                       self.entry(rate='proc', expected_points=20, critical=None, parts=1),
                       self.entry(rate='dodge', expected_points=20, critical=None, parts=1),
                       self.entry(parts=0)):
            with self.subTest(broken={key: broken.get(key) for key in ('rate', 'parts')}), \
                    self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, broken)


class TakenResistRateTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_each_trial_reads_and_removes_the_strike_aura(self):
        entry = variant_entry(706323, 'taken_hit', 'disease_resist')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        reads = [step for step in steps if step.get('metric') == 'aura' and step['spell'] == entry['strike_spell']]
        removals = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == entry['strike_spell']]
        self.assertEqual((len(reads), len(removals)), (2 * entry['trials'], 2 * entry['trials']))
        self.assertEqual(expectation.model['kind'], 'taken_rate')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_resist_rates_are_judged_in_points_over_the_pooled_parts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, variant_entry(706323, 'taken_hit', 'disease_resist'))
        model = expectation.model

        def part(resisted: dict[str, float]):
            values = {}
            for arm, labels in model['reads'].items():
                for index, label in enumerate(labels):
                    values[label] = 0.0 if index < round(len(labels) * resisted[arm] / 100) else 1.0
            return FakeRun(values)

        base = base_verdict(expectation)
        for treatment, status in ((34.0, 'ok'), (4.0, 'alert')):
            with self.subTest(treatment=treatment):
                verdict = compare_module.behaviour_taken_rate_verdict(
                    base, [part({'control': 4.0, 'treatment': treatment})] * 40, model)
                self.assertEqual(verdict.status, status)

    def test_a_resist_rate_without_its_points_or_with_other_arms_is_refused(self):
        entry = variant_entry(706323, 'taken_hit', 'disease_resist')
        for broken in ({**entry, 'expected_points': None}, {**entry, 'arms': [{'name': 'a'}, {'name': 'b'}]},
                       {**entry, 'judge': 'absorb'}):
            with self.subTest(broken=broken.get('judge')), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, broken)


class DetectionTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_each_hide_aura_is_read_shown_hidden_revealed_and_unrevealed(self):
        entry = variant_entry(300513, 'detection', None)
        scenario, expectations = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        reads = [step['label'].rsplit(' ', 2)[-2:] for step in steps if step.get('metric') == 'can_detect']
        self.assertEqual(reads, [[name, moment] for name in ('stealth', 'invisibility')
                                 for moment in ('shown', 'hidden', 'revealed', 'unrevealed')])
        reveals = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == 300513]
        self.assertTrue(all(step['target'] == 'dummy' and step['caster'] == CASTER for step in reveals))
        self.assertEqual([expectation.model['expected'] for expectation in expectations], [0.0, 1.0, 0.0] * 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_brand_that_does_not_reveal_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, variant_entry(300513, 'detection', None))
        revealed = next(expectation for expectation in expectations if expectation.label.endswith('stealth revealed'))
        for after, status in ((1.0, 'ok'), (0.0, 'alert')):
            values = {revealed.model['before_label']: 0.0, revealed.model['after_label']: after}
            with self.subTest(after=after):
                self.assertEqual(judge_behaviour(base_verdict(revealed), FakeRun(values), revealed).status, status)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_client_read_steps_the_caster_aside_and_back_before_reading_the_visible_set(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, variant_entry(300513, 'detection', 'client'))
        steps = run.validate(scenario)['steps']
        reads = [index for index, step in enumerate(steps) if step.get('metric') == 'nearby_creature_at_client']
        self.assertEqual([steps[index]['label'].rsplit(' ', 2)[-2:] for index in reads],
                         [[name, moment] for name in ('stealth', 'invisibility')
                          for moment in ('shown', 'hidden', 'revealed', 'unrevealed')])
        for index in reads:
            moves = [(step['action'], step.get('dy'), step.get('ms')) for step in steps[index - 4:index]]
            self.assertEqual(moves, [('relocate', 3.0, None), ('wait', None, 1000), ('relocate', -3.0, None),
                                     ('wait', None, 1000)])
            self.assertEqual(steps[index]['entry'], scenario['creatures'][0]['entry'])
        self.assertFalse(any(step.get('metric') == 'can_detect' for step in steps))
        self.assertEqual([(expectation.label.split()[2], expectation.model['metric'], expectation.model['expected'])
                          for expectation in expectations],
                         [('client', 'nearby_creature_at_client', expected) for expected in (0.0, 1.0, 0.0) * 2])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_brand_that_leaves_the_dummy_out_of_the_visible_set_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, variant_entry(300513, 'detection', 'client'))
        for moment, before, after in (('revealed', 0.0, 0.0), ('hidden', 1.0, 1.0)):
            expectation = next(item for item in expectations if item.label.endswith(f'stealth {moment}'))
            with self.subTest(moment=moment):
                for reading, status in ((expectation.model['expected'], 'ok'), (after, 'alert')):
                    values = {expectation.model['before_label']: before, expectation.model['after_label']: reading}
                    self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status,
                                     status)

    def test_a_detection_read_outside_predicate_and_client_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**variant_entry(300513, 'detection', 'client'), 'read': 'packet'})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class SourceStackTests(unittest.TestCase):
    def values(self, model: dict, readings: dict[str, tuple[float, float, float]], copies: list[float]):
        found = {}
        for metric, reads in model['reads'].items():
            found.update(zip((reads[arm] for arm in ('none', 'one', 'two')), readings[metric]))
        for arm, present in zip(('none', 'one', 'two'), ([0.0, 0.0], [1.0, 0.0], copies)):
            found.update(zip(model['sources'][arm], present))
        found[model['second_source']['cast failure']] = self.failure
        found[model['second_source']['own copy']] = self.own_copy
        return FakeRun(found)

    failure, own_copy = 0.0, 1.0

    def test_both_templars_cast_and_each_stat_is_read_three_times(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, variant_entry(562302, 'source_stack', None))
        steps = run.validate(scenario)['steps']
        self.assertEqual([step['actor'] for step in steps if step['action'] == 'cast'], [CASTER, ALLY])
        self.assertEqual(sorted(expectation.model['reads']), ['flight_speed_rate', 'run_speed_rate'])

    def test_seeded_stacking_or_unmoved_stats_are_not_passed(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, variant_entry(562302, 'source_stack', None))
        model = expectation.model
        held = {'run_speed_rate': (1.6, 2.4, 2.4), 'flight_speed_rate': (1.0, 1.5, 1.5)}
        stacked = {**held, 'flight_speed_rate': (1.0, 1.5, 2.0)}
        unmoved = {'run_speed_rate': (1.6, 1.6, 1.6), 'flight_speed_rate': (1.0, 1.0, 1.0)}
        for readings, copies, status in ((held, [1.0, 0.0], 'ok'), (held, [1.0, 1.0], 'ok'),
                                         (stacked, [1.0, 1.0], 'alert'), (unmoved, [1.0, 0.0], 'unmeasured'),
                                         (held, [0.0, 0.0], 'unmeasured'), (held, [0.0, 1.0], 'unmeasured')):
            with self.subTest(readings=readings, copies=copies):
                verdict = judge_behaviour(base_verdict(expectation), self.values(model, readings, copies), expectation)
                self.assertEqual(verdict.status, status)
        for failure, own_copy in ((91.0, 1.0), (0.0, 0.0)):
            self.failure, self.own_copy = failure, own_copy
            with self.subTest(failure=failure, own_copy=own_copy):
                verdict = judge_behaviour(base_verdict(expectation), self.values(model, held, [1.0, 0.0]), expectation)
                self.assertEqual(verdict.status, 'unmeasured')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MountedCastTests(unittest.TestCase):
    def test_a_mounted_only_cast_sets_its_mount_aura_first_in_value_and_duration_scenarios(self):
        from values import cast_aura_steps
        self.assertEqual(cast_aura_steps(CLASS_FILE, 562302), [{'action': 'set_aura', 'actor': CASTER, 'spell': 458,
                                                               'stacks': 1}])
        self.assertEqual(cast_aura_steps(CLASS_FILE, 801461), [])
        scenario, _ = behaviour_scenario(CLASS_FILE, variant_entry(562302, 'cast_applies_aura', None))
        steps = run.validate(scenario)['steps']
        mount = next(index for index, step in enumerate(steps) if step['action'] == 'set_aura' and step['spell'] == 458)
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 562302)
        self.assertLess(mount, cast)

    def test_an_ally_beyond_the_radius_must_stay_without_the_aura_the_caster_carries(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, variant_entry(562302, 'aura_presence', 'outside'))
        steps = run.validate(scenario)['steps']
        self.assertEqual(sum(step.get('dx', 0) for step in steps if step['action'] == 'relocate'
                             and step['actor'] == ALLY), 45)
        self.assertEqual([expectation.model['expected'] for expectation in expectations], [0.0, 1.0])
        self.assertEqual([step['actor'] for step in steps if step.get('metric') == 'aura' and step['spell'] == 562302],
                         [ALLY, CASTER, ALLY, CASTER])
        _, [inside] = behaviour_scenario(CLASS_FILE, variant_entry(562302, 'aura_presence', 'inside'))
        self.assertEqual(inside.model['expected'], 1.0)

    def test_seeded_aura_reaching_the_outside_ally_alerts(self):
        _, [outside, caster] = behaviour_scenario(CLASS_FILE, variant_entry(562302, 'aura_presence', 'outside'))
        for model_of, after, status in ((outside, 1.0, 'alert'), (outside, 0.0, 'ok'), (caster, 0.0, 'alert')):
            values = {model_of.model['before_label']: 0.0, model_of.model['after_label']: after}
            with self.subTest(label=model_of.label, after=after):
                self.assertEqual(judge_behaviour(base_verdict(model_of), FakeRun(values), model_of).status, status)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class OffHandHitRatioTests(unittest.TestCase):
    def test_an_off_hand_hit_ratio_wields_the_off_hand_beside_a_one_hand_main_before_its_casts(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, variant_entry(BLADE_SERMON, 'hit_ratio', 'off_hand'))
        steps = run.validate(scenario)['steps']
        main = next(index for index, step in enumerate(steps) if step['action'] == 'equip' and step['slot'] == 15)
        off = next(index for index, step in enumerate(steps) if step['action'] == 'equip' and step['slot'] == 16)
        first_cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast')
        self.assertEqual((steps[main]['item'], steps[off]['item']), (FROSTMANE_CLUB, ANCIENT_BONE_MACE))
        self.assertLess(main, off)
        self.assertLess(off, first_cast)
        self.assertEqual(expectation.label, f'{BLADE_SERMON} behaviour_hit_ratio off_hand')
        self.assertIn(f'off-hand item {ANCIENT_BONE_MACE} equipped', scenario['contract'])

    def test_a_swing_hit_ratio_reads_plain_off_hand_hits_of_one_stopped_swing_interval_per_trial(self):
        entry = variant_entry(BURSTING_IMPACT, 'hit_ratio', 'swing')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        reads = [step for step in steps if step.get('metric') in ('melee_damage_total', 'melee_damage_count')]
        self.assertEqual(len(reads), 2 * 2 * (entry['trials'] + 1))
        self.assertTrue(all((step['hand'], step['critical'], step['glancing']) == (1, False, False) for step in reads))
        first = steps.index(next(step for step in steps if step['action'] == 'attack'))
        self.assertEqual([step['action'] for step in steps[first:first + 4]], ['attack', 'wait', 'stop_attack', 'wait'])
        self.assertEqual(steps[first + 1]['ms'], 1800)
        self.assertTrue(steps[first + 4]['label'].endswith('control 1 total'))
        self.assertEqual([step['action'] for step in steps].count('attack'), 2 * entry['trials'])
        self.assertFalse(any(step['action'] in ('cast', 'learn') for step in steps))
        self.assertEqual(expectation.rank_id, 0)

    def test_swing_hit_ratios_are_refused_without_their_metric_hand_or_off_hand_item(self):
        swing = variant_entry(BURSTING_IMPACT, 'hit_ratio', 'swing')
        broken = ({**swing, 'metric': 'spell_damage_total'},
                  {**swing, 'swing_hand': 2},
                  {key: value for key, value in swing.items() if key != 'off_hand_item'},
                  {**swing, 'off_hand_item': FROSTMANE_CLUB},
                  {**variant_entry(BLADE_SERMON, 'hit_ratio', 'off_hand'), 'metric': 'melee_damage_total'})
        for entry in broken:
            with self.subTest(entry={key: entry.get(key) for key in ('metric', 'swing_hand', 'off_hand_item')}):
                with self.assertRaises(ValueError):
                    behaviour_scenario(CLASS_FILE, entry)


TYRS_BLESSING = 705285
CONDEMN_BASE_RANK = 804906
BARRIER_OF_LIGHT = 805417
CHAKRA_OF_LIGHT_HEAL = 803845


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class EventDelayScenarioTests(unittest.TestCase):
    def setUp(self):
        self.entry = class_entry(NORGANNONS_WRATH, 'event_delay')
        self.scenario, (self.expectation,) = behaviour_scenario(CLASS_FILE, self.entry)
        self.reads = self.expectation.model['reads']

    def readings(self, since_cast: float, since_hit_cast: float, hits=(1.0, 2.0, 3.0)) -> FakeRun:
        values = {}
        for read, total in zip(self.reads, hits):
            values.update({read['since_cast']: since_cast, read['since_hit_cast']: since_hit_cast,
                           read['hits']: total})
        return FakeRun(values)

    def judged(self, readings: FakeRun) -> Verdict:
        return judge_behaviour(base_verdict(self.expectation), readings, self.expectation)

    def test_each_cast_stamps_the_hit_from_both_cast_packets(self):
        run.validate(self.scenario)
        self.assertEqual(self.expectation.check, BEHAVIOUR_EVENT_DELAY)
        stamps = [step for step in self.scenario['steps'] if step.get('metric') == 'event_first_ms']
        self.assertEqual([step['since_spell'] for step in stamps],
                         [NORGANNONS_WRATH, NORGANNONS_WRATH_DAMAGE] * len(self.reads))
        self.assertTrue(all(step['spell'] == NORGANNONS_WRATH_DAMAGE for step in stamps))

    def test_the_stated_delay_after_the_missile_travel_is_ok(self):
        verdict = self.judged(self.readings(1628.0, 125.0))
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 1503.0)

    def test_seeded_handler_that_casts_at_once_or_ignores_the_travel_alerts(self):
        self.assertEqual(self.judged(self.readings(125.0, 125.0)).status, 'alert')
        self.assertEqual(self.judged(self.readings(1628.0, 0.0)).status, 'alert')

    def test_seeded_handler_that_never_casts_alerts(self):
        nan = float('nan')
        self.assertEqual(self.judged(self.readings(nan, nan, (0.0, 0.0, 0.0))).status, 'alert')
        self.assertEqual(self.judged(self.readings(1628.0, 125.0, (1.0, 1.0, 2.0))).status, 'alert')

    def test_a_delay_on_its_own_cast_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**self.entry, 'observe_spell': NORGANNONS_WRATH})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class StackCapScenarioTests(unittest.TestCase):
    def test_setup_casts_wait_out_the_global_cooldown_and_five_casts_reach_each_phase(self):
        scenario, (expectation,) = behaviour_scenario(CLASS_FILE, class_entry(TYRS_BLESSING, 'metric_delta'))
        steps = run.validate(scenario)['steps']
        learned = first_index(steps, action='learn', spell=TYRS_BLESSING)
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        phases = ([index for index in casts if index < learned], [index for index in casts if index > learned])
        self.assertEqual([len(phase) for phase in phases], [5, 5])
        for phase in phases:
            for index in phase[:-1]:
                following = steps[index + 1]
                self.assertEqual(following['action'], 'wait')
                self.assertGreater(following['ms'], RECORDS.field('Spell', CONDEMN_BASE_RANK, 'StartRecoveryTime'))

    def test_seeded_cap_that_ignores_the_modifier_alerts(self):
        _, (expectation,) = behaviour_scenario(CLASS_FILE, class_entry(TYRS_BLESSING, 'metric_delta'))
        model = expectation.model
        ok = judge_behaviour(base_verdict(expectation), FakeRun({model['before_label']: 3.0,
                                                                 model['after_label']: 4.0}), expectation)
        ignored = judge_behaviour(base_verdict(expectation), FakeRun({model['before_label']: 3.0,
                                                                      model['after_label']: 3.0}), expectation)
        self.assertEqual((ok.status, ignored.status), ('ok', 'alert'))

    def test_an_entry_without_a_setup_wait_casts_back_to_back(self):
        entry = next(entry for entry in CLASS_FILE['behaviours']
                     if entry['kind'] == 'metric_delta' and entry.get('setup_casts')
                     and not entry.get('setup_wait_ms'))
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        steps = scenario['steps']
        setup = next(index for index, step in enumerate(steps)
                     if step['action'] == 'cast' and step['spell'] in entry['setup_casts'])
        self.assertNotEqual(steps[setup + 1]['action'], 'wait')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HealingReceivedAuraScenarioTests(unittest.TestCase):
    def test_the_ally_heals_the_caster_who_casts_the_area_aura_before_every_treatment_heal(self):
        entry = next(entry for entry in CLASS_FILE['behaviours']
                     if entry['spell'] == BARRIER_OF_LIGHT and entry['kind'] == 'hit_ratio')
        scenario, (expectation,) = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        heals = [step for step in steps if step['action'] == 'cast' and step['spell'] == CHAKRA_OF_LIGHT_HEAL]
        barriers = [step for step in steps if step['action'] == 'cast' and step['spell'] == BARRIER_OF_LIGHT]
        self.assertTrue(all(step['actor'] == 'ally' and step['target'] == 'caster' for step in heals))
        self.assertEqual(len(barriers), entry['trials'])
        self.assertTrue(all(step['actor'] == 'caster' for step in barriers))
        self.assertEqual(expectation.label, f'{BARRIER_OF_LIGHT} behaviour_hit_ratio received')


WARRIOR_OF_DAWN = 560648
WARRIOR_OF_DAWN_MARKER = 561156
ARGENT_BLADE_MAX_RANK = 807268


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ProcResetScenarioTests(unittest.TestCase):
    def setUp(self):
        self.entry = class_entry(WARRIOR_OF_DAWN, 'proc_reset')
        self.scenario, (self.expectation,) = behaviour_scenario(CLASS_FILE, self.entry)
        self.model = self.expectation.model

    def readings(self, without, with_):
        values = {}
        for phase, trials in (('without', without), ('with', with_)):
            reads = self.model['phases'][phase]
            values[reads['start']] = 0.0
            total = 0.0
            for read, (events, cooldown, spent) in zip(reads['reads'], trials):
                total += events
                values.update({read['procs']: total, read['cooldown']: cooldown,
                               read['power']: self.model['power_level'] - spent})
        return FakeRun(values)

    def conformant(self, fired: set[int]):
        trials, after = [], False
        for index in range(len(self.model['phases']['with']['reads'])):
            proc = index in fired
            trials.append((1.0 if proc else 0.0, 0.0 if proc else 3500.0, 25.0 if after else 50.0))
            after = proc
        return trials

    def judged(self, run_values) -> Verdict:
        return judge_behaviour(base_verdict(self.expectation), run_values, self.expectation)

    def baseline(self):
        return [(0.0, 3500.0, 50.0)] * len(self.model['phases']['without']['reads'])

    def test_casts_read_the_cooldown_power_and_procs_without_then_with_the_passive(self):
        steps = run.validate(self.scenario)['steps']
        learned = first_index(steps, action='learn', spell=WARRIOR_OF_DAWN)
        casts = [index for index, step in enumerate(steps)
                 if step['action'] == 'cast' and step['spell'] == ARGENT_BLADE_MAX_RANK]
        self.assertEqual(len([index for index in casts if index < learned]), 20)
        self.assertEqual(len([index for index in casts if index > learned]), 100)
        self.assertEqual((self.model['cost'], self.model['reduced_cost']), (50, 25.0))
        self.assertGreater(RECORDS.field('Spell', ARGENT_BLADE_MAX_RANK, 'RecoveryTime'),
                           cast_interval(CLASS_FILE, ARGENT_BLADE_MAX_RANK))

    def test_every_proc_resetting_and_discounting_the_next_cast_is_ok(self):
        verdict = self.judged(self.readings(self.baseline(), self.conformant({3, 10, 40, 41, 70})))
        self.assertEqual(verdict.status, 'ok')

    def test_seeded_proc_that_leaves_the_cooldown_alerts(self):
        trials = self.conformant({3, 10, 40, 70})
        trials[10] = (1.0, 3500.0, 50.0)
        self.assertEqual(self.judged(self.readings(self.baseline(), trials)).status, 'alert')

    def test_seeded_proc_without_a_cheaper_next_cast_alerts(self):
        trials = self.conformant({3, 10, 40, 70})
        trials[11] = (0.0, 3500.0, 50.0)
        self.assertEqual(self.judged(self.readings(self.baseline(), trials)).status, 'alert')

    def test_seeded_discount_beyond_the_next_cast_alerts(self):
        trials = self.conformant({3, 10, 40, 70})
        trials[12] = (0.0, 3500.0, 25.0)
        self.assertEqual(self.judged(self.readings(self.baseline(), trials)).status, 'alert')

    def test_seeded_reset_in_the_control_arm_alerts(self):
        baseline = self.baseline()
        baseline[5] = (1.0, 0.0, 50.0)
        verdict = self.judged(self.readings(baseline, self.conformant({3, 10, 40, 70})))
        self.assertEqual(verdict.status, 'alert')

    def test_a_marker_without_a_cost_modifier_is_not_modelled(self):
        with self.assertRaises(NotModelled):
            behaviour_scenario(CLASS_FILE, {**self.entry, 'marker_spell': 561167})

    def test_too_few_procs_are_not_judged(self):
        verdict = self.judged(self.readings(self.baseline(), self.conformant({3, 10})))
        self.assertEqual(verdict.status, 'insufficient_trials')


def route_entry(spell: int, variant: str) -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == spell and entry.get('variant') == variant)


def taken_hit_values(model: dict, trial_values) -> dict:
    values = {}
    for arm in model['arms']:
        totals = dict.fromkeys(arm['marks']['start'], 0.0)
        values.update({label: 0.0 for label in arm['marks']['start'].values()})
        for term, labels in enumerate(arm['terms']):
            values.update(dict.fromkeys(labels, 79.0 if term == 0 else 0.0))
        for trial in range(1, model['trials'] + 1):
            delta = trial_values(arm['name'], trial)
            for key in ('damage', 'count', 'absorb', 'logs', 'paid', 'returned', 'returned count', 'returned logs',
                        'returned absorb', 'returned resist'):
                if key in totals:
                    totals[key] += delta.get(key, 0.0)
            for key, label in arm['marks'][str(trial)].items():
                if key in totals:
                    values[label] = totals[key]
                elif key.startswith('paid '):
                    values[label] = totals['paid'] - delta['paid'] + delta[key]
                else:
                    values[label] = delta[key]
    return values


class TakenHitScenarioTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_debt_entry_also_counts_the_debt_payments_at_each_read(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, route_entry(92109, 'over'))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        counts = [step for step in steps if step.get('label', '').endswith(('payments early', 'payments late'))]
        self.assertTrue(counts)
        self.assertTrue(all(step['metric'] == 'spell_damage_count' and step['spell'] == 803237 for step in counts))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_striker_spell_hits_the_caster_in_every_trial_of_every_arm(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, route_entry(705295, 'absorb'))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        strikes = [step for step in steps if step['action'] == 'cast' and step['actor'] == STRIKER]
        self.assertEqual(len(strikes), 5 * 5)
        self.assertTrue(all(step['target'] == CASTER and step['spell'] == 41394 for step in strikes))
        self.assertEqual(expectations[0].check, BEHAVIOUR_TAKEN_HIT)
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == STRIKER)
        self.assertNotIn('reaction', striker)
        absorbs = [step for step in steps if step.get('metric') == 'spell_absorb_total']
        self.assertTrue(all(step['caster'] == STRIKER and step['target'] == CASTER for step in absorbs))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_absorb_without_the_stamina_term_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, route_entry(705295, 'absorb'))
        expectation = expectations[0]

        def trial(arm: str, absorbed: float):
            return {'damage': 1100.0 - absorbed, 'count': 1.0, 'absorb': absorbed, 'logs': 1.0}

        right = taken_hit_values(expectation.model, lambda arm, _: trial(arm, 0.0 if arm == 'control' else 148.0))
        wrong = taken_hit_values(expectation.model, lambda arm, _: trial(arm, 0.0 if arm == 'control' else 125.0))
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(right), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(wrong), expectation).status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_absorb_in_the_control_arm_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, route_entry(705295, 'absorb'))
        expectation = expectations[0]
        values = taken_hit_values(expectation.model, lambda arm, _: {'damage': 952.0, 'count': 1.0, 'absorb': 148.0,
                                                                     'logs': 1.0})
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')

    def oath_values(self, model: dict, early_paid: float) -> dict:
        def trial(arm: str, _):
            if arm == 'control':
                return {'damage': 1100.0, 'count': 1.0, 'absorb': 0.0, 'logs': 1.0}
            return {'damage': 660.0, 'count': 1.0, 'absorb': 440.0, 'logs': 1.0, 'paid': 440.0,
                    'paid early': early_paid, 'paid late': 440.0, 'debt early': 1.0, 'debt late': 0.0}
        return taken_hit_values(model, trial)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_debt_paid_before_its_end_alerts_only_where_the_end_is_judged(self):
        _, over = behaviour_scenario(CLASS_FILE, route_entry(92109, 'over'))
        _, delay = behaviour_scenario(CLASS_FILE, route_entry(92109, 'delay'))
        for expectations, early, status in ((over, 385.0, 'ok'), (over, 440.0, 'alert'), (delay, 440.0, 'ok')):
            expectation = expectations[0]
            verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.oath_values(expectation.model, early)),
                                      expectation)
            with self.subTest(label=expectation.label, early=early):
                self.assertEqual(verdict.status, status)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_debt_not_reduced_by_holy_books_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, route_entry(706468, 'debt'))
        expectation = expectations[0]

        def trial(paid: float):
            return {'damage': 660.0, 'count': 1.0, 'absorb': 440.0, 'logs': 1.0, 'paid': paid, 'paid early': paid,
                    'paid late': paid, 'debt early': 1.0, 'debt late': 0.0}

        right = taken_hit_values(expectation.model, lambda arm, _: trial(440.0 if arm == 'control' else 132.0))
        wrong = taken_hit_values(expectation.model, lambda arm, _: trial(440.0))
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(right), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(wrong), expectation).status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_damage_ratio_holds_the_caster_health_and_reads_noncritical_strikes(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, route_entry(801202, 'taken_10'))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        healths = [step for step in steps if step['action'] == 'set_health']
        self.assertTrue(healths and all(step['value'] == 10000 and step['maximum'] == 100000 for step in healths))
        expectation = expectations[0]
        self.assertEqual(expectation.check, BEHAVIOUR_HIT_RATIO)
        reads = expectation.model['reads']

        def values(per_hit: float) -> dict:
            found = {}
            for arm, marks in reads.items():
                for index, (total, count) in enumerate(marks):
                    found[total] = index * (1100.0 if arm == 'control' else per_hit)
                    found[count] = float(index)
            return found

        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(880.0)), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(1100.0)), expectation).status,
                         'alert')

    def test_a_share_judge_refuses_several_strikes_per_trial(self):
        entry = {**route_entry(92109, 'delay'), 'strikes': 2}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    def ratio_values(self, model: dict, control: float, treatment: float) -> dict:
        found = {}
        for arm, marks in model['reads'].items():
            for index, (total, count) in enumerate(marks):
                found[total] = index * (control if arm == 'control' else treatment)
                found[count] = float(index)
        return found

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_player_striker_is_hostile_flagged_and_strikes_beside_the_caster(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, route_entry(801461, 'players'))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        striker = next(player for player in scenario['players'] if player['id'] == STRIKER)
        self.assertEqual((striker['race'], striker['class']), (2, CLASS_FILE['class_id']))
        self.assertNotIn(STRIKER, [creature['id'] for creature in scenario['creatures']])
        self.assertEqual(scenario['location'], TAKEN_HIT_PVP_LOCATION)
        self.assertEqual(sorted(step['actor'] for step in steps if step['action'] == 'pvp'), [CASTER, STRIKER])
        self.assertIn({'action': 'learn', 'actor': STRIKER, 'spell': 92559},
                      [{key: step[key] for key in ('action', 'actor', 'spell') if key in step} for step in steps])
        strikes = [step for step in steps if step['action'] == 'cast' and step['actor'] == STRIKER]
        self.assertEqual(len(strikes), 2 * 10)
        _, creature = behaviour_scenario(CLASS_FILE, route_entry(801461, 'physical'))
        expectation = expectations[0]
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(self.ratio_values(
            expectation.model, 332.0, 282.0)), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(creature[0]), FakeRun(self.ratio_values(
            creature[0].model, 949.0, 806.0)), creature[0]).status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_area_and_periodic_reductions_alert_off_their_amount(self):
        for variant, spell, control, right, wrong in (('area', 301311, 2000.0, 1800.0, 1600.0),
                                                     ('area', 301360, 2000.0, 1600.0, 1800.0),
                                                     ('periodic', 300529, 1735.0, 1474.0, 1735.0)):
            _, expectations = behaviour_scenario(CLASS_FILE, route_entry(spell, variant))
            expectation = expectations[0]
            for per_hit, status in ((right, 'ok'), (wrong, 'alert')):
                with self.subTest(spell=spell, per_hit=per_hit):
                    verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.ratio_values(
                        expectation.model, control, per_hit)), expectation)
                    self.assertEqual(verdict.status, status)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_refreshed_arm_removes_its_auras_before_each_trial_and_waits_its_settle(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, route_entry(300529, 'periodic'))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        removed = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == 301283
                   and step['stacks'] == 0]
        self.assertEqual(len(removed), 10 + 1)
        settles = [step['ms'] for step in steps if step['action'] == 'wait' and ' settle ' in step.get('label', '')]
        self.assertEqual(settles, [2200] * 20)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_strike_back_judges_the_returned_share_with_its_resisted_part(self):
        _, expectations = behaviour_scenario(CLASS_FILE, route_entry(705306, 'strike_back'))
        expectation = expectations[0]

        def trial(returned: float, resist: float = 0.0, control_returned: float = 0.0):
            def values(arm: str, _):
                back = control_returned if arm == 'control' else returned
                return {'damage': 949.0, 'count': 1.0, 'absorb': 0.0, 'logs': 1.0, 'returned': back,
                        'returned count': float(bool(back)), 'returned logs': float(bool(back)),
                        'returned absorb': 0.0, 'returned resist': 0.0 if arm == 'control' else resist}
            return taken_hit_values(expectation.model, values)

        for values, status in ((trial(142.0), 'ok'), (trial(128.0, 14.0), 'ok'), (trial(128.0), 'alert'),
                               (trial(142.0, control_returned=142.0), 'alert'), (trial(0.0), 'unmeasured')):
            with self.subTest(status=status):
                self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status,
                                 status)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_reduction_reads_the_formula_off_the_mitigated_control_strike(self):
        _, expectations = behaviour_scenario(CLASS_FILE, route_entry(705298, 'reduction'))
        expectation = expectations[0]
        self.assertEqual(expectation.model['strike_base'], 67)

        def run_of(treatment: float):
            return FakeRun(taken_hit_values(expectation.model, lambda arm, _: {
                'damage': 64.0 if arm == 'control' else treatment, 'count': 1.0, 'absorb': 0.0, 'logs': 1.0}))

        for treatment, status in ((48.0, 'ok'), (47.0, 'ok'), (49.0, 'alert'), (57.0, 'alert'), (64.0, 'alert')):
            with self.subTest(treatment=treatment):
                self.assertEqual(judge_behaviour(base_verdict(expectation), run_of(treatment), expectation).status,
                                 status)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_reduction_or_returned_share_refuses_an_entry_that_cannot_judge_it(self):
        reduction = route_entry(705298, 'reduction')
        strike_back = route_entry(705306, 'strike_back')
        for entry in ({**reduction, 'arms': [{**arm, 'name': f'{arm["name"]}_arm'} for arm in reduction['arms']]},
                      {**reduction, 'absorb_terms': []}, {**reduction, 'strike_spell': 42395},
                      {**strike_back, 'returned_spell': 0},
                      {**strike_back, 'arms': [{**arm, 'returned_pct': 0} for arm in strike_back['arms']]}):
            with self.subTest(entry=entry['arms']), self.assertRaises((ValueError, NotModelled)):
                behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ThreatRedirectScenarioTests(unittest.TestCase):
    def test_the_ally_attacks_before_and_after_the_cast_in_a_group(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, route_entry(805417, 'redirect'))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        self.assertEqual([step['actor'] for step in steps if step['action'] == 'attack'], [ALLY, ALLY])
        self.assertTrue(any(step['action'] == 'group' and step['target'] == ALLY for step in steps))
        self.assertEqual(scenario['creatures'][0]['reaction'], AGGRO_REDIRECT_REACTION)
        self.assertEqual(expectations[0].check, BEHAVIOUR_THREAT_REDIRECT)

    def test_seeded_threat_kept_by_the_ally_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, route_entry(805417, 'redirect'))
        expectation = expectations[0]
        reads = expectation.model['reads']

        def values(ally_after: float, caster_after: float) -> dict:
            return {reads['control']['before'][ALLY]: 0.0, reads['control']['before'][CASTER]: 0.0,
                    reads['control']['after'][ALLY]: 160.0, reads['control']['after'][CASTER]: 0.0,
                    reads['treatment']['before'][ALLY]: 160.0, reads['treatment']['before'][CASTER]: 0.0,
                    reads['treatment']['after'][ALLY]: ally_after, reads['treatment']['after'][CASTER]: caster_after}

        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(160.0, 155.0)), expectation).status,
                         'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(320.0, 0.0)), expectation).status,
                         'alert')


def dispel_count_entry(spell: int, suffix: str = '') -> dict:
    return next(entry for entry in CLASS_FILE['behaviours']
                if entry['spell'] == spell and entry['kind'] == 'dispel_count'
                and entry.get('label_suffix', '') == suffix)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class DispelCountScenarioTests(unittest.TestCase):
    def test_each_arm_casts_benediction_at_an_ally_carrying_two_of_each_kind(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, dispel_count_entry(681483))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        casts = [step for step in steps if step['action'] == 'cast']
        self.assertEqual([(step['spell'], step['target']) for step in casts], [(578276, ALLY)] * 6)
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER, ALLY])
        self.assertEqual([player['level'] for player in scenario['players']], [60, 60])
        self.assertEqual([(expectation.label, expectation.check, expectation.model['expected'])
                          for expectation in expectations],
                         [('681483 behaviour_dispel_count control disease', BEHAVIOUR_DISPEL_COUNT, 0),
                          ('681483 behaviour_dispel_count control poison', BEHAVIOUR_DISPEL_COUNT, 0),
                          ('681483 behaviour_dispel_count rank_2 disease', BEHAVIOUR_DISPEL_COUNT, 2),
                          ('681483 behaviour_dispel_count rank_2 poison', BEHAVIOUR_DISPEL_COUNT, 2)])

    def test_rank_two_removing_one_of_each_alerts_and_two_passes(self):
        _, expectations = behaviour_scenario(CLASS_FILE, dispel_count_entry(681483))
        expectation = next(expectation for expectation in expectations if expectation.model['arm'] == 'rank_2')

        def values(removed: int) -> dict:
            values = {}
            for trial in expectation.model['reads']:
                for index, (before, after) in enumerate(trial):
                    values[before] = 1.0
                    values[after] = 0.0 if index < removed else 1.0
            return values

        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(2)), expectation).status, 'ok')
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values(1)), expectation)
        self.assertEqual((verdict.status, verdict.measured), ('alert', 1.0))

    def test_rank_two_on_one_disease_and_three_poisons_expects_one_and_two(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, dispel_count_entry(681483, 'uneven'))
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertTrue(scenario['name'].endswith(' uneven'))
        self.assertEqual([(expectation.label, expectation.model['expected']) for expectation in expectations
                          if expectation.model['arm'] == 'rank_2'],
                         [('681483 behaviour_dispel_count uneven rank_2 disease', 1),
                          ('681483 behaviour_dispel_count uneven rank_2 poison', 2)])

    def test_a_debuff_missing_before_the_cast_is_not_counted(self):
        _, expectations = behaviour_scenario(CLASS_FILE, dispel_count_entry(680399))
        expectation = expectations[-1]
        values = {label: 1.0 for trial in expectation.model['reads'] for pair in trial for label in pair}
        values[expectation.model['reads'][0][0][0]] = 0.0
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status,
                         'unmeasured')

    def test_a_debuff_of_the_wrong_dispel_type_is_refused(self):
        entry = {**dispel_count_entry(680399), 'debuffs': [[3, [55095, 2818]], [4, [2818, 25810]]]}
        with self.assertRaisesRegex(ValueError, 'not of dispel type 3'):
            behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class UncappedAreaAndControlledLeechTests(unittest.TestCase):
    def test_an_uncapped_area_around_the_caster_offers_dummies_inside_and_one_beyond(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, route_entry(680397, 'area'))
        run.validate(scenario, run.SIMULATED_CLOCK)
        distances = [creature['distance'] for creature in scenario['creatures']]
        self.assertEqual(distances, [1.0, 2.0, 3.0, 4.0, 10.0])
        self.assertTrue(expectations[0].model['all_offered'])
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertTrue(all(step['target'] == CASTER for step in casts))

    def test_seeded_heal_in_the_control_cast_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, route_entry(801481, 'downfall_heal'))
        expectation = expectations[0]
        model = expectation.model
        right = {model['damage_baseline_label']: 470.0, model['heal_baseline_label']: 0.0,
                 model['damage_label']: 942.0, model['heal_label']: 236.0}
        wrong = {**right, model['heal_baseline_label']: 235.0, model['heal_label']: 471.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(right), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(wrong), expectation).status, 'alert')


PARRY_DANCE_BUFF = 560651


def taken_outcome_entry() -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'taken_outcome')


def taken_outcome_values(model: dict, control: tuple[float, float], treatment: tuple[float, float]) -> dict:
    values = {}
    for arm, (swings, outcomes) in (('control', control), ('treatment', treatment)):
        reads = model['reads'][arm]
        values.update({reads['start swings']: 0.0, reads['start outcomes']: 0.0,
                       reads['end swings']: swings, reads['end outcomes']: outcomes})
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TakenOutcomeTests(unittest.TestCase):
    def test_the_aura_is_set_only_in_the_treatment_arm_and_parries_are_read_by_victim_state(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, taken_outcome_entry())
        validated = run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(len(validated['creatures']), 8)
        self.assertTrue(all(creature['reaction'] == 2 and creature['stationary']
                            for creature in validated['creatures']))
        steps = validated['steps']
        control_end = next(index for index, step in enumerate(steps)
                           if step.get('label', '').endswith('control end outcomes'))
        auras = [index for index, step in enumerate(steps) if step['action'] == 'set_aura'
                 and step.get('spell') == PARRY_DANCE_BUFF and step.get('stacks') == 5]
        self.assertTrue(auras)
        self.assertGreater(min(auras), control_end)
        outcomes = [step for step in steps if step.get('label', '').endswith('outcomes')]
        self.assertEqual(len(outcomes), 4)
        self.assertTrue(all(step['victim_state'] == 3 for step in outcomes))
        self.assertEqual(expectations[0].check, BEHAVIOUR_TAKEN_OUTCOME)
        self.assertNotIn({'action': 'learn', 'actor': CASTER, 'spell': taken_outcome_entry()['spell']}, steps)

    def test_seeded_fifteen_points_pass_and_twelve_alert(self):
        _, expectations = behaviour_scenario(CLASS_FILE, taken_outcome_entry())
        expectation = expectations[0]
        right = taken_outcome_values(expectation.model, (40000.0, 2000.0), (40000.0, 8000.0))
        wrong = taken_outcome_values(expectation.model, (40000.0, 2000.0), (40000.0, 6800.0))
        none = taken_outcome_values(expectation.model, (40000.0, 2000.0), (40000.0, 2000.0))
        for values, status in ((right, 'ok'), (wrong, 'alert'), (none, 'alert')):
            with self.subTest(status=status, treated=values):
                verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                self.assertEqual(verdict.status, status)

    def test_too_few_swings_are_not_judged(self):
        _, expectations = behaviour_scenario(CLASS_FILE, taken_outcome_entry())
        expectation = expectations[0]
        few = taken_outcome_values(expectation.model, (2000.0, 100.0), (2000.0, 400.0))
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(few), expectation)
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIsNotNone(verdict.detail['swings_needed'])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CharmImmunityTests(unittest.TestCase):
    def test_each_charm_is_read_inside_the_charm_removed_and_its_cleanup_asserted(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, class_entry(TESTAMENT_OF_RESOLVE, 'charm_immunity'))
        steps = run.validate(scenario, run.SIMULATED_CLOCK)['steps']
        charms = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 37122]
        self.assertEqual(len(charms), 2)
        self.assertTrue(all(steps[index]['actor'] == 'dummy' and steps[index]['target'] == CASTER
                            for index in charms))
        for index, arm in zip(charms, ('without', 'with')):
            read = steps[index + 2]
            self.assertEqual((read['label'], read['metric']), (f'804228 charm_immunity 37122 {arm}', 'aura'))
            self.assertEqual((steps[index + 3]['action'], steps[index + 3]['stacks']), ('set_aura', 0))
            cleanup = [step for step in steps if step.get('label', '').startswith(f'804228 {arm} CLEANUP')]
            self.assertEqual([step['metric'] for step in cleanup],
                             ['aura', 'charmed', 'controls_self', 'faction', 'victim'])
            self.assertTrue(all('equals' in step and 'min' not in step for step in cleanup))
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast'
                    and step['spell'] == TESTAMENT_OF_RESOLVE)
        self.assertLess(charms[0], cast)
        self.assertLess(cast, charms[1])
        self.assertEqual([expectation.displayed for expectation in expectations], ['1', '0', '1', '0'])

    def test_seeded_charm_landing_under_the_immunity_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, class_entry(TESTAMENT_OF_RESOLVE, 'charm_immunity'))
        landed = {expectation.label: 1.0 for expectation in expectations}
        statuses = [judge_behaviour(base_verdict(expectation), FakeRun(landed), expectation).status
                    for expectation in expectations]
        self.assertEqual(statuses, ['ok', 'alert', 'ok', 'alert'])


def side_a_entry(lookup, *args) -> dict:
    try:
        return lookup(*args)
    except StopIteration:
        raise unittest.SkipTest(f'no entry {args} in this branch\'s class file') from None


def r1a_entry(spell: int, kind: str, suffix: str = '') -> dict:
    entry = next((entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == spell and entry['kind'] == kind
                  and entry.get('label_suffix', '') == suffix), None)
    if entry is None:
        raise unittest.SkipTest(f'no {kind} entry of {spell} {suffix!r} in this branch\'s class file')
    return entry


def set_aura_indices(steps: list[dict], spell: int) -> list[int]:
    return [index for index, step in enumerate(steps) if step['action'] == 'set_aura' and step['spell'] == spell]


def cast_indices(steps: list[dict], spell: int) -> list[int]:
    return [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == spell]


FEARED_CASTER_FLEE = {'spell': 300513, 'name': "Crusader's Brand (fleeing)", 'kind': 'metric_delta', 'variant': 'flee',
                      'label_suffix': 'flee', 'quote': 'fleeing', 'expected': 0, 'trigger_spell': 801461,
                      'target': 'caster', 'measure_actor': 'caster', 'phase_auras': [[12096, 1, 'caster', 'dummy']],
                      'after_auras': [[12096, 0, 'caster', 'dummy'], [300513, 1, 'caster', 'dummy']],
                      'metric': 'moving', 'fields': {}, 'before_expected': 1, 'wait_ms': 1000, 'expire_ms': 500}


class PhaseAuraTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_flee_sets_the_fear_in_both_phases_and_the_brand_in_the_after_phase_only(self):
        scenario, _ = metric_delta_scenario(CLASS_FILE, metric_delta_spec(FEARED_CASTER_FLEE))
        run.validate(scenario)
        steps = scenario['steps']
        brand = set_aura_indices(steps, 300513)
        fear = set_aura_indices(steps, 12096)
        self.assertEqual(len(brand), 1)
        self.assertEqual([steps[index]['stacks'] for index in fear], [1, 0, 1])
        self.assertTrue(fear[0] < brand[0] < fear[2])
        self.assertTrue(fear[1] < brand[0])
        self.assertEqual(steps[brand[0]], {'action': 'set_aura', 'actor': CASTER, 'spell': 300513, 'stacks': 1,
                                           'caster': 'dummy'})

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_speed_cap_sets_courage_on_the_dummy_in_both_phases(self):
        scenario, _ = metric_delta_scenario(CLASS_FILE,
                                            metric_delta_spec(r1a_entry(300513, 'metric_delta', 'speed_cap')))
        steps = scenario['steps']
        courage = set_aura_indices(steps, 707754)
        self.assertEqual(len(courage), 2)
        self.assertEqual(steps[courage[0]], {'action': 'set_aura', 'actor': CASTER, 'spell': 707754, 'stacks': 1,
                                             'target': 'dummy', 'caster': 'caster'})
        self.assertTrue(courage[1] < cast_indices(steps, 300513)[0])
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_phase_aura_refuses_an_unknown_unit(self):
        entry = {**FEARED_CASTER_FLEE, 'phase_auras': [[12096, 1, 'caster', 'ally']]}
        with self.assertRaises(ValueError):
            metric_delta_spec(entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_flee_and_speed_readings_are_judged(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(300513, 'metric_delta', 'speed_cap'))
        expectation = expectations[0]
        model = expectation.model
        capped = {model['before_label']: model['before_expected'], model['after_label']: 1.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(capped), expectation).status, 'ok')
        uncapped = {model['before_label']: model['before_expected'], model['after_label']: model['before_expected']}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(uncapped), expectation).status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class DispelArmsTests(unittest.TestCase):
    def entry(self):
        return {'spell': 801465, 'name': 'Silverhand Incantation', 'kind': 'dispel_removal', 'label_suffix': 'arms',
                'quote': 'and removing Sacred Restraint from you and them if they are an ally', 'debuffs': [102208],
                'wait_ms': 3000, 'arms': [{'name': 'failed', 'target': 'ally', 'removed': False, 'away_yd': 60,
                                           'refused': 97},
                                          {'name': 'ally', 'target': 'ally', 'removed': True},
                                          {'name': 'hostile', 'target': 'dummy', 'removed': False}]}

    def test_each_arm_sets_and_reads_the_debuff_on_the_caster_and_its_target(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, self.entry())
        steps = run.validate(scenario)['steps']
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['dummy'])
        relocations = [step['dx'] for step in steps if step['action'] == 'relocate']
        self.assertEqual(relocations, [20.0, 20.0, 20.0, -20.0, -20.0, -20.0])
        self.assertEqual([(e.label.split(' ', 1)[1], e.displayed) for e in expectations],
                         [('failed cast_failure', '97'),
                          ('behaviour_dispel_removal 102208 failed caster', '1'),
                          ('behaviour_dispel_removal 102208 failed target', '1'),
                          ('ally cast_failure', '0'),
                          ('behaviour_dispel_removal 102208 ally caster', '0'),
                          ('behaviour_dispel_removal 102208 ally target', '0'),
                          ('hostile cast_failure', '0'),
                          ('behaviour_dispel_removal 102208 hostile caster', '1'),
                          ('behaviour_dispel_removal 102208 hostile target', '1')])
        dummy_set = [step for step in steps if step['action'] == 'set_aura' and step.get('target') == 'dummy']
        self.assertEqual(len(dummy_set), 1)

    def test_a_removal_in_a_kept_arm_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, self.entry())
        hostile = next(e for e in expectations if e.label.endswith('hostile target'))
        values = {hostile.model['before_label']: 1.0, hostile.model['after_label']: 0.0}
        self.assertEqual(judge_behaviour(base_verdict(hostile), FakeRun(values), hostile).status, 'alert')
        values[hostile.model['after_label']] = 1.0
        self.assertEqual(judge_behaviour(base_verdict(hostile), FakeRun(values), hostile).status, 'ok')

    def test_a_caster_removal_is_judged_apart_from_the_target(self):
        entry = self.entry()
        entry['arms'][2] = {'name': 'hostile', 'target': 'dummy', 'removed': False, 'caster_removed': True}
        scenario, expectations = behaviour_scenario(CLASS_FILE, entry)
        displayed = {e.label.split(' ', 1)[1]: e.displayed for e in expectations}
        self.assertEqual(displayed['behaviour_dispel_removal 102208 hostile caster'], '0')
        self.assertEqual(displayed['behaviour_dispel_removal 102208 hostile target'], '1')
        self.assertEqual(displayed['behaviour_dispel_removal 102208 ally caster'], '0')
        self.assertEqual(displayed['behaviour_dispel_removal 102208 failed caster'], '1')
        self.assertIn('hostile: cast at the dummy from 0 yd, removed on the caster, kept on the target',
                      scenario['contract'])
        caster = next(e for e in expectations if e.label.endswith('hostile caster'))
        values = {caster.model['before_label']: 1.0, caster.model['after_label']: 1.0}
        self.assertEqual(judge_behaviour(base_verdict(caster), FakeRun(values), caster).status, 'alert')
        values[caster.model['after_label']] = 0.0
        self.assertEqual(judge_behaviour(base_verdict(caster), FakeRun(values), caster).status, 'ok')

    def test_an_arm_needs_the_dummy_or_the_ally(self):
        bad = {**self.entry(), 'arms': [{'name': 'self', 'target': 'caster', 'removed': True}]}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, bad)


def hit_ratio_readings(expectation, control_mean, treatment_mean, hits_per_trial=1):
    values = {}
    for arm, mean in (('control', control_mean), ('treatment', treatment_mean)):
        for index, (total, count) in enumerate(expectation.model['reads'][arm]):
            values[total] = float(index * hits_per_trial * mean + (index % 2))
            values[count] = float(index * hits_per_trial)
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ExtensionMutantTests(unittest.TestCase):
    def judge(self, expectation, values):
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def test_a_forced_crit_aura_that_is_not_applied_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, class_entry(805415, 'cast_applies_aura'))
        model = expectation.model
        self.assertEqual(self.judge(expectation, {model['before_label']: 0.0, model['after_label']: 19997.0}), 'ok')
        self.assertEqual(self.judge(expectation, {model['before_label']: 0.0, model['after_label']: 0.0}), 'alert')

    def test_a_cast_spell_ratio_without_the_oath_bonus_alerts(self):
        entry = next(entry for entry in CLASS_FILE['behaviours']
                     if entry['spell'] == 805409 and entry.get('label_suffix') == 'oaths')
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        self.assertEqual(self.judge(expectation, hit_ratio_readings(expectation, 172.0, 275.2, 6)), 'ok')
        self.assertEqual(self.judge(expectation, hit_ratio_readings(expectation, 172.0, 172.0, 6)), 'alert')

    def test_a_free_gate_that_still_charges_alerts(self):
        entry = next(entry for entry in CLASS_FILE['behaviours']
                     if entry['spell'] == 705256 and entry.get('label_suffix') == 'next_free')
        _, expectations = behaviour_scenario(CLASS_FILE, entry)
        for arm in ('with', 'held'):
            expectation = next(e for e in expectations if e.model['arm'] == arm)
            self.assertEqual(self.judge(expectation, {expectation.label: 0.0}), 'ok')
            self.assertEqual(self.judge(expectation, {expectation.label: 85.0}), 'alert')

    def test_a_drained_channel_that_heals_nothing_more_alerts(self):
        entry = next(entry for entry in CLASS_FILE['behaviours']
                     if entry['spell'] == 500678 and entry.get('label_suffix') == 'max_health')
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        self.assertEqual(self.judge(expectation, hit_ratio_readings(expectation, 108.0, 217.0)), 'ok')
        self.assertEqual(self.judge(expectation, hit_ratio_readings(expectation, 108.0, 108.0)), 'alert')

    def test_the_spell_power_expectation_is_the_hit_models_ratio(self):
        from dataclasses import replace as replaced
        from hits import REFERENCE_TARGET, rank_hit, reference_caster, records_of
        from values import armed_for
        entry = next(entry for entry in CLASS_FILE['behaviours']
                     if entry['spell'] == 805409 and entry.get('label_suffix') == 'spell_power')
        armed = armed_for(CLASS_FILE, records_of(CLASS_FILE), 807274)
        caster = reference_caster(armed)
        boosted = replaced(caster, sp_by_school={school: power + 220 for school, power in caster.sp_by_school.items()})
        auras = armed.get('known_auras', [])
        ratio = (rank_hit(armed, 807274, boosted, REFERENCE_TARGET, auras).model.mean
                 / rank_hit(armed, 807274, caster, REFERENCE_TARGET, auras).model.mean)
        self.assertAlmostEqual(entry['expected'], ratio, places=3)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AmountMatchTests(unittest.TestCase):
    def expectation(self):
        entry = next(entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'amount_match')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        run.validate(scenario)
        return expectation

    def readings(self, expectation, first, second):
        values = {}
        for side, amount in (('first', first), ('second', second)):
            for index, (total, count) in enumerate(expectation.model['reads'][side]):
                values[total], values[count] = float(index * amount), float(index)
        return values

    def judge(self, values):
        expectation = self.expectation()
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def test_the_same_amount_is_ok_and_half_the_heal_alerts(self):
        expectation = self.expectation()
        self.assertEqual(self.judge(self.readings(expectation, 740.0, 740.0)), 'ok')
        self.assertEqual(self.judge(self.readings(expectation, 740.0, 741.0)), 'ok')
        self.assertEqual(self.judge(self.readings(expectation, 740.0, 370.0)), 'alert')

    def test_too_few_trials_with_both_amounts_are_unmeasured(self):
        expectation = self.expectation()
        values = self.readings(expectation, 740.0, 740.0)
        for total, count in expectation.model['reads']['second']:
            values[total], values[count] = 0.0, 0.0
        self.assertEqual(self.judge(values), 'unmeasured')

    def test_an_unknown_metric_is_refused(self):
        entry = next(entry for entry in CLASS_FILE['behaviours'] if entry['kind'] == 'amount_match')
        bad = {**entry, 'second': {'metric': 'melee_damage_total', 'spell': 801501, 'target': 'ally'}}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, bad)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CastPowerTests(unittest.TestCase):
    def test_a_cast_power_replaces_the_cost_before_each_cast_of_the_three_kinds(self):
        suffixes = ('max_health', 'damage_taken', 'tick_1050')
        entries = [next(entry for entry in CLASS_FILE['behaviours']
                        if entry['spell'] == 500678 and entry.get('label_suffix') == suffix) for suffix in suffixes]
        for entry in entries:
            with self.subTest(kind=entry['kind']):
                steps = run.validate(behaviour_scenario(CLASS_FILE, entry)[0])['steps']
                casts = [index for index, step in enumerate(steps)
                         if step['action'] == 'cast' and step['spell'] == 500678]
                self.assertTrue(casts)
                for index in casts:
                    power = max(i for i in range(index) if steps[i]['action'] == 'set_power')
                    self.assertEqual(steps[power]['value'], 100)
                plain = {key: value for key, value in entry.items() if key != 'cast_power'}
                plain_steps = run.validate(behaviour_scenario(CLASS_FILE, plain)[0])['steps']
                self.assertIn(15, [step['value'] for step in plain_steps if step['action'] == 'set_power'])
                self.assertNotIn(100, [step['value'] for step in plain_steps if step['action'] == 'set_power'])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FixedCountPullTests(unittest.TestCase):
    def entry(self):
        return {'spell': 520534, 'name': 'Templar Rituals', 'kind': 'fixed_count',
                'quote': 'you pull enemies within 15 yds towards you.', 'expected': 2, 'uncapped': True,
                'cast_spell': 807274, 'target_rank': 520694, 'metric': 'aura', 'cast_target': 'caster', 'repeats': 1,
                'learn': [520534], 'radius': 15.0, 'pull_reads': True, 'radius_reason': 'synthetic'}

    def readings(self, expectation, near_after=0.0, far_after=20.0):
        model = expectation.model
        values = {label: 1.0 for label in model['dummy_labels']}
        values[model['far_label']] = 0.0
        for before, after in model['pull']['near']:
            values[before], values[after] = 10.0, near_after
        values[model['pull']['far'][0]], values[model['pull']['far'][1]] = 20.0, far_after
        return values

    def test_distances_are_read_before_the_cast_and_after_it(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        steps = run.validate(scenario)['steps']
        cast = first_index(steps, action='cast', spell=807274)
        for before, after in (*expectation.model['pull']['near'], expectation.model['pull']['far']):
            self.assertLess(first_index(steps, label=before), cast)
            self.assertGreater(first_index(steps, label=after), cast)
            self.assertEqual(steps[first_index(steps, label=after)]['metric'], 'distance_2d')
        plain, _ = behaviour_scenario(CLASS_FILE, {**self.entry(), 'pull_reads': False})
        self.assertFalse([step for step in plain['steps'] if step.get('metric') == 'distance_2d'])

    def test_a_pull_that_does_not_close_or_moves_the_far_dummy_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        judge = lambda values: judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status
        self.assertEqual(judge(self.readings(expectation)), 'ok')
        self.assertEqual(judge(self.readings(expectation, near_after=9.5)), 'alert')
        self.assertEqual(judge(self.readings(expectation, far_after=10.0)), 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FixedCountAurasTests(unittest.TestCase):
    def test_libram_is_set_before_every_cast(self):
        scenario, expectations = fixed_target_count_scenario(
            CLASS_FILE, fixed_target_count_spec(r1a_entry(803893, 'fixed_count')))
        run.validate(scenario)
        steps = scenario['steps']
        casts = cast_indices(steps, 503141)
        libram = set_aura_indices(steps, 803893)
        self.assertEqual(len(casts), 5)
        self.assertEqual(len(libram), 5)
        self.assertTrue(all(aura < cast for aura, cast in zip(libram, casts)))
        self.assertEqual(expectations[0].model['expected'], 4)

    def test_seeded_breadth_of_three_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(803893, 'fixed_count'))
        expectation = expectations[0]
        model = expectation.model

        def readings(struck: int) -> dict:
            values = {label: 0.0 for label in model['per_cast']['start']}
            for cast, labels in enumerate(model['per_cast']['casts'], start=1):
                values.update({label: float(cast if index <= struck else 0) for index, label in enumerate(labels)})
            values.update({label: float(5 if index < struck else 0)
                           for index, label in enumerate(model['dummy_labels'])})
            values[model['far_label']] = 0.0
            return values

        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(readings(4)), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(readings(3)), expectation).status,
                         'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AbsorbPierceTargetAuraTests(unittest.TestCase):
    def test_crit_guard_is_set_on_the_dummy_before_both_casts(self):
        if not norgannons_wrath_entry().get('dummy_auras') and not norgannons_wrath_entry().get('target_auras'):
            self.skipTest("the other side's Norgannon's Wrath dummy auras are not in this branch's class file")
        scenario, _ = absorb_pierce_ratio_scenario(CLASS_FILE, absorb_pierce_ratio_spec(norgannons_wrath_entry()))
        steps = scenario['steps']
        guard = set_aura_indices(steps, 33143)
        casts = cast_indices(steps, NORGANNONS_WRATH)
        self.assertEqual(len(guard), 2)
        self.assertTrue(guard[0] < casts[0] < guard[1] < casts[1])
        self.assertEqual(steps[guard[0]]['target'], 'dummy')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GroupStackCapSwingTests(unittest.TestCase):
    def test_each_phase_swings_after_its_marker(self):
        spec = group_stack_cap_spec(r1a_entry(560096, 'group_stack_cap'))
        scenario, expectations = group_stack_cap_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        steps = scenario['steps']
        markers = cast_indices(steps, 801461)
        reads = [index for index, step in enumerate(steps) if step.get('label') in (
            expectations[0].model['baseline_label'], expectations[0].model['own_label'],
            expectations[0].model['combined_label'])]
        self.assertEqual(len(markers), 3)
        self.assertTrue(all(marker < read for marker, read in zip(markers, reads)))
        self.assertEqual(expectations[0].model['own_pct'], 10.0)
        self.assertEqual(expectations[0].model['relation'], 'inverse')

    def test_swings_need_the_marker_in_the_interval_read(self):
        entry = {**r1a_entry(560096, 'group_stack_cap'), 'fields': {'stream': 'melee_hit', 'hand': 0}}
        with self.assertRaises(ValueError):
            group_stack_cap_scenario(CLASS_FILE, group_stack_cap_spec(entry))

    def test_seeded_cap_passes_and_a_summed_haste_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(560096, 'group_stack_cap'))
        expectation = expectations[0]
        model = expectation.model
        capped = {model['baseline_label']: 2500.0, model['own_label']: 2500 / 1.1,
                  model['combined_label']: 2500 / 1.1}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(capped), expectation).status, 'ok')
        summed = {**capped, model['combined_label']: 2500 / 1.21}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(summed), expectation).status, 'alert')
        ignored = {**capped, model['own_label']: 2500.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(ignored), expectation).status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TakenHitOpeningCastTests(unittest.TestCase):
    def test_copies_are_summoned_once_before_the_treatment_trials(self):
        spec = taken_hit_spec(r1a_entry(1397742, 'taken_hit', 'copies'))
        scenario, _ = taken_hit_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        steps = scenario['steps']
        casts = cast_indices(steps, 1397742)
        strikes = [index for index, step in enumerate(steps)
                   if step['action'] == 'cast' and step['actor'] == 'striker']
        self.assertEqual(len(casts), 1)
        self.assertEqual(len([index for index in strikes if index < casts[0]]), spec.trials)
        self.assertEqual(len([index for index in strikes if index > casts[0]]), spec.trials)

    def test_arms_that_differ_only_by_an_opening_cast_are_distinct(self):
        spec = taken_hit_spec(r1a_entry(1397742, 'taken_hit', 'copies'))
        self.assertNotEqual(spec.arms[0], spec.arms[1])
        taken_hit_scenario(CLASS_FILE, spec)


class TakenHitSelectionTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_copies_are_placed_by_selecting_a_dummy_at_each_arm_distance(self):
        spec = taken_hit_spec(r1a_entry(1397742, 'taken_hit', 'radius'))
        scenario, _ = taken_hit_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual({creature['id']: creature['distance'] for creature in scenario['creatures']
                          if creature['id'] in ('near', 'far')}, {'near': 16.0, 'far': 24.0})
        steps = scenario['steps']
        selections = [index for index, step in enumerate(steps) if step['action'] == 'select']
        self.assertEqual([steps[index]['target'] for index in selections], ['near', 'far'])
        self.assertLess(cast_indices(steps, 1397742)[0], selections[0])
        strikes = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['actor'] == STRIKER]
        self.assertEqual(len([index for index in strikes if selections[0] < index < selections[1]]), spec.trials)
        checks = [step for step in steps if ' check ' in step.get('label', '')]
        self.assertTrue(all(step['actor'] == CASTER and 'equals' in step for step in checks))
        self.assertTrue(all(selections[0] < steps.index(step) for step in checks))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_reduction_beyond_the_radius_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(1397742, 'taken_hit', 'radius'))
        expectation = expectations[0]
        reads = expectation.model['reads']

        def values(far_hit: float) -> dict:
            found = {}
            for arm, marks in reads.items():
                for index, (total, count) in enumerate(marks):
                    found[total] = index * (890.0 if arm == 'control' else far_hit)
                    found[count] = float(index)
            return found

        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(1100.0)), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(890.0)), expectation).status,
                         'alert')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(990.0)), expectation).status,
                         'alert')

    def test_a_selection_outside_the_targets_or_a_check_without_a_bound_is_refused(self):
        entry = r1a_entry(1397742, 'taken_hit', 'radius')
        unknown = {**entry, 'arms': [entry['arms'][0], {**entry['arms'][1], 'select': 'dummy'}]}
        with self.assertRaisesRegex(ValueError, 'not one of its targets'):
            taken_hit_scenario(CLASS_FILE, taken_hit_spec(unknown))
        unbounded = {**entry, 'arms': [entry['arms'][0], {**entry['arms'][1],
                                                          'checks': [{'metric': 'owned_creature_count'}]}]}
        with self.assertRaisesRegex(ValueError, 'needs a metric and a bound'):
            taken_hit_scenario(CLASS_FILE, taken_hit_spec(unbounded))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_arms_that_differ_only_by_their_selection_are_distinct(self):
        entry = r1a_entry(1397742, 'taken_hit', 'radius')
        same = {**entry, 'arms': [entry['arms'][0], {**entry['arms'][1], 'name': 'treatment', 'checks': []}]}
        spec = taken_hit_spec(same)
        self.assertNotEqual(spec.arms[0].select, spec.arms[1].select)
        taken_hit_scenario(CLASS_FILE, spec)


class CritRateTests(unittest.TestCase):
    def built(self):
        return behaviour_scenario(CLASS_FILE, r1a_entry(520608, 'crit_rate'))

    def judged(self, control: tuple[float, float], treatment: tuple[float, float]) -> Verdict:
        _, [expectation] = self.built()
        values = {}
        for arm, (hits, crits) in (('control', control), ('treatment', treatment)):
            marks = expectation.model['reads'][arm]
            values.update({marks['start']['hits']: 10.0, marks['start']['crits']: 4.0,
                           marks['end']['hits']: 10.0 + hits, marks['end']['crits']: 4.0 + crits})
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_each_arm_casts_its_spell_300_times_with_its_auras_and_counts_hits_and_crits(self):
        scenario, [expectation] = self.built()
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(expectation.check, BEHAVIOUR_CRIT_RATE)
        steps = scenario['steps']
        self.assertEqual(len(cast_indices(steps, 807268)), 600)
        self.assertNotIn('melee_crit_rating', scenario['players'][0])
        crit_reads = [step for step in steps if step.get('critical') is True]
        self.assertEqual(len(crit_reads), 4)
        first = cast_indices(steps, 807268)[0]
        self.assertEqual([step['spell'] for step in steps[first - 4:first] if step['action'] == 'set_aura'], [561156])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_an_interval_inside_the_band_is_ok_and_one_across_it_is_measured(self):
        self.assertEqual(self.judged((3000.0, 0.0), (3000.0, 1500.0)).status, 'ok')
        verdict = self.judged((300.0, 0.0), (300.0, 150.0))
        self.assertEqual(verdict.status, 'measured')
        self.assertIn('effect present, interval stated, not final', verdict.explanation)
        self.assertGreater(verdict.detail['crit_rate']['hits_needed_per_arm'], 300)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_missing_or_older_crit_bonus_alerts(self):
        self.assertEqual(self.judged((300.0, 0.0), (300.0, 0.0)).status, 'alert')
        self.assertEqual(self.judged((300.0, 0.0), (300.0, 60.0)).status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_too_few_landed_hits_are_not_judged(self):
        self.assertEqual(self.judged((100.0, 0.0), (300.0, 150.0)).status, 'insufficient_trials')

    def test_a_forced_crit_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'no forced crit'):
            behaviour_scenario(CLASS_FILE, {**r1a_entry(520608, 'crit_rate'), 'force_crit': 'melee'})



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MetricDeltaSelectionTests(unittest.TestCase):
    def built(self):
        return behaviour_scenario(CLASS_FILE, r1a_entry(1397742, 'metric_delta', 'combat'))

    def judged(self, before: float, after: float) -> str:
        _, [expectation] = self.built()
        values = {expectation.model['before_label']: before, expectation.model['after_label']: after}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def test_the_dummy_is_selected_in_both_phases_and_only_the_second_casts(self):
        scenario, _ = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        selections = [index for index, step in enumerate(steps) if step['action'] == 'select']
        casts = cast_indices(steps, 1397742)
        self.assertEqual(len(selections), 2)
        self.assertEqual(len(casts), 1)
        self.assertLess(selections[0], casts[0])
        self.assertLess(selections[1], casts[0])
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['dummy'])

    def test_a_lower_bound_judges_the_after_read_and_the_before_read_stays_exact(self):
        self.assertEqual(self.judged(0.0, 6.0), 'ok')
        self.assertEqual(self.judged(0.0, 1.0), 'ok')
        self.assertEqual(self.judged(0.0, 0.0), 'alert')
        self.assertEqual(self.judged(1.0, 6.0), 'alert')



def binding_scripture_variant(kind: str, suffix: str) -> dict:
    return r1a_entry(801457, kind, suffix)


def ratio_values(model: dict, treatment_hit: float, control_hit: float = 1100.0) -> dict:
    found = {}
    for arm, marks in model['reads'].items():
        for index, (total, count) in enumerate(marks):
            found[total] = index * (control_hit if arm == 'control' else treatment_hit)
            found[count] = float(index)
    return found


class AllyCastTargetTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_taken_hit_cast_at_the_ally_groups_it_and_sets_its_health_before_each_cast(self):
        spec = taken_hit_spec(binding_scripture_variant('taken_hit', 'stack_cap'))
        scenario, _ = taken_hit_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER, ALLY])
        steps = scenario['steps']
        groups = [index for index, step in enumerate(steps) if step['action'] == 'group']
        heals = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['target'] == ALLY]
        self.assertEqual(len(groups), 1)
        self.assertEqual(len(heals), 4 * spec.trials)
        self.assertLess(groups[0], heals[0])
        for index in heals:
            health = next(step for step in reversed(steps[:index]) if step['action'] == 'set_health')
            self.assertEqual((health['actor'], health['value']), (ALLY, 5000))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_taken_hit_without_an_ally_cast_has_no_ally(self):
        scenario, _ = taken_hit_scenario(CLASS_FILE,
                                         taken_hit_spec(binding_scripture_variant('taken_hit', 'self_heal')))
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER])
        self.assertFalse([step for step in scenario['steps'] if step['action'] == 'group'])

    def test_ally_health_without_a_cast_at_the_ally_is_refused(self):
        entry = {**binding_scripture_variant('taken_hit', 'self_heal'), 'ally_health_pct': 50}
        with self.assertRaises(ValueError):
            taken_hit_scenario(CLASS_FILE, taken_hit_spec(entry))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_reduction_missing_or_uncapped_alerts(self):
        for suffix, right, wrongs in (('one_heal', 1045.0, (1100.0,)), ('stack_cap', 935.0, (880.0, 990.0)),
                                      ('self_heal', 1100.0, (1045.0,))):
            _, expectations = behaviour_scenario(CLASS_FILE, binding_scripture_variant('taken_hit', suffix))
            expectation = expectations[0]
            with self.subTest(suffix=suffix):
                self.assertEqual(judge_behaviour(base_verdict(expectation),
                                                 FakeRun(ratio_values(expectation.model, right)), expectation).status,
                                 'ok')
                for wrong in wrongs:
                    self.assertEqual(judge_behaviour(base_verdict(expectation),
                                                     FakeRun(ratio_values(expectation.model, wrong)),
                                                     expectation).status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_cast_applies_aura_at_the_ally_groups_it_in_the_readback_and_the_expiry(self):
        from expiry import cast_applies_aura_expiry
        entry = binding_scripture_variant('cast_applies_aura', 'reduction')
        readback, _ = cast_applies_aura_scenario(CLASS_FILE, cast_applies_aura_spec(entry))
        expiry, _ = cast_applies_aura_expiry(CLASS_FILE, entry)
        for scenario in (readback, expiry):
            run.validate(scenario)
            self.assertEqual([player['id'] for player in scenario['players']], [CASTER, ALLY])
            steps = scenario['steps']
            group = next(index for index, step in enumerate(steps) if step['action'] == 'group')
            cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast')
            self.assertLess(group, cast)
            self.assertEqual(steps[cast]['target'], ALLY)



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MountBlockScenarioTests(unittest.TestCase):
    BRAND = 300513
    MOUNT = 458

    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE, r1a_entry(self.BRAND, 'mount_block'))
        self.steps = run.validate(self.scenario)['steps']

    def test_the_mount_is_refused_under_the_brand_allowed_without_it_and_lost_when_it_lands(self):
        self.assertEqual([(e.label, e.check, e.displayed) for e in self.expectations],
                         [(f'{self.BRAND} mount_block {self.MOUNT} {moment}', BEHAVIOUR_CAST_CONDITION, code)
                          for moment, code in (('blocked', '22'), ('unmounted', '0'), ('allowed', '0'),
                                               ('mounted', '1'), ('held', '1'), ('dismounted', '0'))])

    def test_the_brand_is_set_by_the_caster_outdoors_around_the_two_mount_casts(self):
        outdoors = first_index(self.steps, action='teleport')
        brands = [index for index, step in enumerate(self.steps)
                  if step['action'] == 'set_aura' and step['spell'] == self.BRAND]
        casts = [index for index, step in enumerate(self.steps)
                 if step['action'] == 'cast' and step['spell'] == self.MOUNT]
        self.assertEqual([self.steps[index]['stacks'] for index in brands], [1, 0, 1])
        self.assertTrue(all('caster' not in self.steps[index] for index in brands))
        self.assertLess(outdoors, brands[0])
        self.assertLess(brands[0], casts[0])
        self.assertLess(casts[0], brands[1])
        self.assertLess(brands[1], casts[1])
        self.assertLess(first_index(self.steps, label=f'{self.BRAND} mount_block {self.MOUNT} held'), brands[2])

    def test_a_mount_that_goes_through_the_brand_or_survives_it_alerts(self):
        by_moment = {expectation.label.rsplit(' ', 1)[1]: expectation for expectation in self.expectations}
        for moment, value, status in (('blocked', 0.0, 'alert'), ('blocked', 22.0, 'ok'), ('unmounted', 1.0, 'alert'),
                                      ('allowed', 22.0, 'alert'), ('mounted', 0.0, 'alert'), ('held', 0.0, 'alert'),
                                      ('dismounted', 1.0, 'alert'), ('dismounted', 0.0, 'ok')):
            expectation = by_moment[moment]
            with self.subTest(moment=moment, value=value):
                verdict = judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: value}),
                                          expectation)
                self.assertEqual(verdict.status, status)

    def test_a_mount_spell_without_a_mounted_aura_is_refused(self):
        entry = {**r1a_entry(self.BRAND, 'mount_block'), 'mount_spell': self.BRAND}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FleeBlockScenarioTests(unittest.TestCase):
    BRAND = 300513
    CUB = 11360

    def setUp(self):
        self.entry = r1a_entry(self.BRAND, 'flee_block')
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE, self.entry)
        self.steps = run.validate(self.scenario)['steps']

    def label(self, moment: str) -> str:
        return f'{self.BRAND} flee_block {self.CUB} {moment}'

    def reads(self, arm: str) -> list[str]:
        return [self.label(f'{arm} read {read}') for read in range(1, self.entry['reads'] + 1)]

    def test_the_branded_creature_must_never_move_and_the_control_must_move_once(self):
        self.assertEqual([(e.label, e.check, e.displayed) for e in self.expectations],
                         [(self.label(moment), BEHAVIOUR_CAST_CONDITION, value)
                          for moment, value in (('cast', '0'), ('branded', '1'), ('blocked', '0'), ('held', '1'),
                                                ('control', '1'))])
        by_moment = {e.label.rsplit(' ', 1)[1]: e for e in self.expectations}
        self.assertEqual(by_moment['blocked'].model['sum_labels'], self.reads('branded'))
        self.assertEqual(by_moment['control'].model['sum_labels'], self.reads('control'))
        self.assertTrue(by_moment['control'].model['at_least'])
        self.assertNotIn('at_least', by_moment['blocked'].model)

    def test_two_defensive_flee_creatures_and_a_brand_cast_by_the_caster_before_the_branded_arm(self):
        self.assertEqual([(c['id'], c['entry'], c['reaction']) for c in self.scenario['creatures']],
                         [('flee_branded', self.CUB, 1), ('flee_control', self.CUB, 1)])
        brand = cast_indices(self.steps, self.BRAND)
        self.assertEqual(len(brand), 1)
        self.assertEqual(self.steps[brand[0]]['target'], 'flee_branded')
        self.assertEqual(set_aura_indices(self.steps, self.BRAND), [])
        lowered = [index for index, step in enumerate(self.steps) if step['action'] == 'set_health_pct']
        self.assertEqual([(self.steps[index]['target'], self.steps[index]['pct']) for index in lowered],
                         [('flee_branded', 10), ('flee_control', 10)])
        self.assertLess(brand[0], lowered[0])
        reads = [index for index, step in enumerate(self.steps) if step.get('metric') == 'moving']
        self.assertEqual(len(reads), 2 * self.entry['reads'])
        self.assertTrue(all(lowered[0] < index < lowered[1] for index in reads[:self.entry['reads']]))
        self.assertTrue(all(index > lowered[1] for index in reads[self.entry['reads']:]))

    def test_a_branded_move_or_a_control_that_never_moves_alerts(self):
        by_moment = {e.label.rsplit(' ', 1)[1]: e for e in self.expectations}
        still = dict.fromkeys(self.reads('branded'), 0.0)
        one_step = {**still, self.reads('branded')[2]: 1.0}
        fled_once = {**dict.fromkeys(self.reads('control'), 0.0), self.reads('control')[4]: 1.0}
        stayed = dict.fromkeys(self.reads('control'), 0.0)
        for moment, values, status in (('blocked', still, 'ok'), ('blocked', one_step, 'alert'),
                                       ('control', fled_once, 'ok'), ('control', stayed, 'alert')):
            expectation = by_moment[moment]
            with self.subTest(moment=moment, values=values):
                verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                self.assertEqual(verdict.status, status)

    def test_a_flee_health_outside_one_to_ninety_nine_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**self.entry, 'flee_health_pct': 0})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class SelfObservedPeriodicHitRatioTests(unittest.TestCase):
    FOCUSED = 300524
    BLADE_OF_FAITH = 803880

    def test_a_periodic_observed_spell_waits_for_its_own_ticks_after_each_cast(self):
        entry = r1a_entry(self.FOCUSED, 'hit_ratio', 'blade_of_faith')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual({steps[index]['spell'] for index in casts}, {self.BLADE_OF_FAITH})
        self.assertEqual(len(casts), 2 * entry['trials'])
        for index in casts:
            wait = next(step for step in steps[index + 1:] if step['action'] == 'wait' and 'label' in step)
            self.assertEqual((wait['ms'], wait['label'].endswith('hits')), (entry['cast_wait_ms'], True))
        self.assertIn(f'each followed by {entry["cast_wait_ms"]} ms for its periodic hits', scenario['contract'])
        self.assertEqual(expectation.label, f'{self.FOCUSED} behaviour_hit_ratio blade_of_faith')

    def test_a_cast_wait_beside_swings_is_still_refused(self):
        entry = {**variant_entry(BURSTING_IMPACT, 'hit_ratio', 'swing'), 'cast_wait_ms': 500}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)


def stat_gain_values(model: dict, gains: dict, stats: dict, changed: dict | None = None) -> dict:
    values = {}
    for arm in model['arms']:
        values[arm['before']] = 1000.0
        values[arm['after']] = 1000.0 + gains[arm['name']]
        for term in arm['terms']:
            for index, label in enumerate(term):
                values[label] = stats[arm['name']][index]
        reads = arm.get('attribution')
        if reads:
            values.update({label: 0.0 for _, label in reads['before']['auras']})
            values.update({label: 1.0 for _, label in reads['after']['auras']})
            values[reads['before']['count']] = 5.0
            values[reads['after']['count']] = 5.0 + len(reads['after']['auras'])
            values[reads['before']['casts']] = 3.0
            values[reads['after']['casts']] = 4.0
            values[reads['return']] = 1000.0
    return {**values, **(changed or {})}


class StatGainTests(unittest.TestCase):
    def expectation(self, spell: int, suffix: str) -> Expectation:
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(spell, 'stat_gain', suffix))
        return expectations[0]

    def judged(self, expectation: Expectation, values: dict) -> str:
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_scenario_reads_the_stats_and_the_target_around_each_cast(self):
        from behaviours import stat_gain_scenario, stat_gain_spec
        spec = stat_gain_spec(r1a_entry(705287, 'stat_gain', 'armor'))
        scenario, _ = stat_gain_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER, ALLY])
        steps = scenario['steps']
        casts = cast_indices(steps, 578276)
        self.assertEqual(len(casts), len(spec.arms))
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 705287)
        self.assertLess(casts[0], learn)
        self.assertLess(learn, casts[1])
        for cast in casts:
            before = [step for step in steps[:cast] if step.get('metric') == 'armor'][-1]
            self.assertEqual(before['actor'], ALLY)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_gain_off_the_stats_alerts(self):
        armor = self.expectation(705287, 'armor')
        stats = {'without': (132.0, 79.0), 'with': (132.0, 79.0), 'agility': (162.0, 79.0), 'stamina': (132.0, 142.0)}
        right = {'without': 0.0, 'with': 211.0, 'agility': 241.0, 'stamina': 274.0}
        self.assertEqual(self.judged(armor, stat_gain_values(armor.model, right, stats)), 'ok')
        for arm, wrong in (('without', 211.0), ('with', 132.0), ('agility', 211.0), ('stamina', 211.0)):
            with self.subTest(arm=arm):
                self.assertEqual(self.judged(armor, stat_gain_values(armor.model, {**right, arm: wrong}, stats)),
                                 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_percent_gain_passes_at_its_truncation_only(self):
        power = self.expectation(805423, 'spell_power')
        stats = {'reference': (132.0,), 'agility': (162.0,)}
        for reference, status in ((39.0, 'ok'), (40.0, 'alert'), (33.0, 'alert'), (41.0, 'alert')):
            with self.subTest(reference=reference):
                values = stat_gain_values(power.model, {'reference': reference, 'agility': 48.0}, stats)
                self.assertEqual(self.judged(power, values), status)

    def test_an_entry_without_a_formula_arm_is_refused(self):
        from behaviours import stat_gain_scenario, stat_gain_spec
        entry = {**r1a_entry(705287, 'stat_gain', 'armor'),
                 'arms': [{'name': 'a', 'gain': 0}, {'name': 'b', 'gain': 1}]}
        with self.assertRaises(ValueError):
            stat_gain_scenario(CLASS_FILE, stat_gain_spec(entry))

    ARMOR_STATS = {'without': (132.0, 79.0), 'with': (132.0, 79.0), 'agility': (162.0, 79.0),
                   'stamina': (132.0, 142.0)}
    ARMOR_GAINS = {'without': 0.0, 'with': 211.0, 'agility': 241.0, 'stamina': 274.0}
    POWER_STATS = {'reference': (132.0,), 'agility': (162.0,)}
    POWER_GAINS = {'reference': 39.0, 'agility': 48.0}

    def verdict(self, expectation: Expectation, gains: dict, stats: dict, changed: dict | None = None) -> Verdict:
        values = stat_gain_values(expectation.model, gains, stats, changed)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def evidence(self, expectation: Expectation, clause: str, gains: dict, stats: dict,
                 changed: dict | None = None) -> str:
        from coverage import verdict_evidence
        verdict = self.verdict(expectation, gains, stats, changed)
        self.assertEqual(verdict.status, 'ok')
        return verdict_evidence(verdict, clause, {verdict.label: verdict})

    def armor(self, entry: dict | None = None) -> Expectation:
        _, expectations = behaviour_scenario(CLASS_FILE, entry or r1a_entry(705287, 'stat_gain', 'armor'))
        return expectations[0]

    def power(self, entry: dict | None = None) -> Expectation:
        _, expectations = behaviour_scenario(CLASS_FILE, entry or r1a_entry(805423, 'stat_gain', 'spell_power'))
        return expectations[0]

    def reads(self, expectation: Expectation, arm: str) -> dict:
        return next(item for item in expectation.model['arms'] if item['name'] == arm)['attribution']

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_cast_aura_is_read_cleared_before_and_the_stat_read_back_after_its_removal(self):
        from behaviours import stat_gain_scenario, stat_gain_spec
        scenario, _ = stat_gain_scenario(CLASS_FILE, stat_gain_spec(r1a_entry(705287, 'stat_gain', 'armor')))
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        for arm in ('without', 'with'):
            mark = f'705287 behaviour_metric_delta armor {arm}'
            cleared, before = labels.index(f'{mark} aura 801409 before'), labels.index(f'{mark} before')
            present, after, back = (labels.index(f'{mark} aura 801409 after'), labels.index(f'{mark} after'),
                                    labels.index(f'{mark} return'))
            cast = next(index for index in cast_indices(steps, 578276) if index > before)
            removal = next(index for index in set_aura_indices(steps, 801409) if index > present)
            self.assertLess(cleared, before)
            self.assertLess(before, cast)
            self.assertLess(cast, after)
            self.assertLess(after, present)
            self.assertLess(present, removal)
            self.assertLess(removal, back)
            self.assertEqual(steps[cleared]['metric'], 'aura')
            self.assertEqual(steps[cleared]['actor'], ALLY)
            self.assertEqual(steps[back]['metric'], 'armor')
            casts_before, casts_after = labels.index(f'{mark} casts before'), labels.index(f'{mark} casts after')
            self.assertLess(casts_before, cast)
            self.assertLess(cast, casts_after)
            read = steps[casts_before]
            self.assertEqual((read['metric'], read['actor'], read['spell']), ('spell_cast_count', CASTER, 578276))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_withheld_talent_or_the_spells_own_cast_is_a_learned_contrast(self):
        armor = self.armor()
        self.assertEqual(self.evidence(armor, 'grants your target armor', self.ARMOR_GAINS, self.ARMOR_STATS),
                         'behaviour')
        verdict = self.verdict(armor, self.ARMOR_GAINS, self.ARMOR_STATS)
        self.assertEqual(verdict.detail['applied_auras'], {arm: [801409] for arm in self.ARMOR_GAINS})
        power = self.power()
        self.assertEqual(self.evidence(power, 'granting you spell power', self.POWER_GAINS, self.POWER_STATS),
                         'behaviour')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_arms_that_never_withhold_the_spell_stay_data(self):
        entry = r1a_entry(705287, 'stat_gain', 'armor')
        learned_first = self.armor({**entry, 'arms': [{**entry['arms'][1], 'learn': [705287], 'gain': 211},
                                                      *({**arm, 'learn': [705287]} for arm in entry['arms'][2:])]})
        gains = {arm: gain for arm, gain in self.ARMOR_GAINS.items() if arm != 'without'}
        stats = {arm: stat for arm, stat in self.ARMOR_STATS.items() if arm != 'without'}
        self.assertEqual(self.evidence(learned_first, 'grants your target armor', gains, stats), 'data')
        kept_aura = self.power({**r1a_entry(805423, 'stat_gain', 'spell_power'), 'clear_auras': []})
        self.assertEqual(self.evidence(kept_aura, 'granting you spell power', self.POWER_GAINS, self.POWER_STATS),
                         'data')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_verdict_names_the_stat_read(self):
        armor = self.verdict(self.armor(), self.ARMOR_GAINS, self.ARMOR_STATS)
        self.assertIn('UNIT_FIELD_RESISTANCES', armor.detail['read'])
        power = self.verdict(self.power(), self.POWER_GAINS, self.POWER_STATS)
        self.assertIn('SpellBaseDamageBonusDone', power.detail['read'])
        self.assertIn(power.detail['read'], power.explanation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_entries_without_an_attributable_contrast_stay_data(self):
        armor = r1a_entry(705287, 'stat_gain', 'armor')
        unstated_control = self.armor({**armor, 'arms': [{'name': 'without'}, *armor['arms'][1:]]})
        gains = {**self.ARMOR_GAINS, 'without': 211.0}
        self.assertEqual(self.evidence(unstated_control, 'grants your target armor', gains, self.ARMOR_STATS), 'data')
        other_cast = self.power({**r1a_entry(805423, 'stat_gain', 'spell_power'), 'cast_spell': 801832})
        self.assertEqual(self.evidence(other_cast, 'granting you spell power', self.POWER_GAINS, self.POWER_STATS),
                         'data')
        unnamed_read = self.power({**r1a_entry(805423, 'stat_gain', 'spell_power'), 'metric': 'max_health',
                                   'fields': {}})
        self.assertEqual(self.evidence(unnamed_read, 'granting you maximum health', self.POWER_GAINS,
                                       self.POWER_STATS), 'data')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_attribution_failures_keep_the_gain_at_data(self):
        power = self.power()
        reads = self.reads(power, 'reference')
        held_count = {reads['after']['count']: 5.0}
        mutants = {
            'aura not cleared, refreshed by the cast': {reads['before']['auras'][0][1]: 1.0, **held_count},
            'aura absent after the cast': {reads['after']['auras'][0][1]: 0.0, **held_count},
            'cast did not land': {reads['after']['casts']: 3.0},
            'an unlisted aura appeared': {reads['after']['count']: 7.0},
            'stat not back after removal': {reads['return']: 1039.0},
        }
        for name, changed in mutants.items():
            with self.subTest(mutant=name):
                self.assertEqual(self.evidence(power, 'granting you spell power', self.POWER_GAINS,
                                               self.POWER_STATS, changed), 'data')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_arm_without_the_talent_need_not_apply_the_aura(self):
        armor = self.armor()
        without, treated = self.reads(armor, 'without'), self.reads(armor, 'with')
        absent = {without['after']['auras'][0][1]: 0.0, without['after']['count']: 5.0}
        self.assertEqual(self.evidence(armor, 'grants your target armor', self.ARMOR_GAINS, self.ARMOR_STATS, absent),
                         'behaviour')
        missing = {treated['after']['auras'][0][1]: 0.0, treated['after']['count']: 5.0}
        self.assertEqual(self.evidence(armor, 'grants your target armor', self.ARMOR_GAINS, self.ARMOR_STATS,
                                       missing), 'data')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_control_arms_cast_must_land(self):
        armor = self.armor()
        without = self.reads(armor, 'without')
        refused = {without['after']['auras'][0][1]: 0.0, without['after']['count']: 5.0,
                   without['after']['casts']: 3.0}
        self.assertEqual(self.evidence(armor, 'grants your target armor', self.ARMOR_GAINS, self.ARMOR_STATS, refused),
                         'data')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_another_applied_aura_needs_an_arm_without_the_spell(self):
        def with_extra_aura(expectation: Expectation) -> Expectation:
            model = json.loads(json.dumps(expectation.model))
            model['attribution']['candidates'].append(999999)
            for arm in model['arms']:
                for moment in ('before', 'after'):
                    arm['attribution'][moment]['auras'].append([999999, f'{arm["name"]} aura 999999 {moment}'])
            return replace(expectation, model=model)
        power = with_extra_aura(self.power())
        self.assertEqual(self.evidence(power, 'granting you spell power', self.POWER_GAINS, self.POWER_STATS),
                         'data')
        armor = with_extra_aura(self.armor())
        self.assertEqual(self.evidence(armor, 'grants your target armor', self.ARMOR_GAINS, self.ARMOR_STATS),
                         'behaviour')
        absent_in_control = {'without aura 999999 after': 0.0, self.reads(armor, 'without')['after']['count']: 6.0}
        self.assertEqual(self.evidence(armor, 'grants your target armor', self.ARMOR_GAINS, self.ARMOR_STATS,
                                       absent_in_control), 'data')


class EnemyPlayerMetricDeltaTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_enemy_player_is_pvp_flagged_and_measured(self):
        spec = metric_delta_spec(r1a_entry(801205, 'metric_delta', 'sleep_player'))
        scenario, _ = metric_delta_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual([(player['id'], player['race']) for player in scenario['players']],
                         [(CASTER, CLASS_FILE['race']), ('enemy', 2)])
        self.assertIn('location', scenario)
        steps = scenario['steps']
        pvp = [index for index, step in enumerate(steps) if step['action'] == 'pvp']
        cast = cast_indices(steps, 801205)[0]
        self.assertEqual([steps[index]['actor'] for index in pvp], [CASTER, 'enemy'])
        self.assertLess(pvp[-1], cast)
        self.assertEqual(steps[cast]['target'], 'enemy')
        self.assertTrue(all(step['actor'] == 'enemy' for step in steps
                            if step.get('label', '').startswith('801205 aura')))

    def test_an_enemy_target_without_a_race_is_refused(self):
        entry = {**r1a_entry(801205, 'metric_delta', 'sleep_player')}
        entry.pop('enemy_player_race')
        with self.assertRaises(ValueError):
            metric_delta_scenario(CLASS_FILE, metric_delta_spec(entry))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_creature_length_sleep_on_a_player_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(801205, 'metric_delta', 'sleep_player'))
        expectation = expectations[0]
        model = expectation.model
        right = {model['before_label']: 0.0, model['after_label']: 1.0, model['expired_label']: 0.0}
        wrong = {**right, model['expired_label']: 1.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(right), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(wrong), expectation).status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class BladeOfFaithTickTests(unittest.TestCase):
    def test_a_periodic_observed_spell_waits_for_its_tick_after_each_cast(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(803872, 'hit_ratio', 'oath_condemn'))
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        casts = cast_indices(steps, 803880)
        self.assertEqual(len(casts), 2 * 20)
        for cast in casts:
            wait = next(step for step in steps[cast + 1:]
                        if step['action'] == 'wait' and 'hits' in step.get('label', ''))
            self.assertEqual(wait['ms'], 3100)

    def test_seeded_oath_without_its_damage_from_caster_bonus_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(803872, 'hit_ratio', 'oath_condemn'))
        expectation = expectations[0]
        self.assertEqual(judge_behaviour(base_verdict(expectation),
                                         FakeRun(ratio_values(expectation.model, 238.0, 191.0)), expectation).status,
                         'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation),
                                         FakeRun(ratio_values(expectation.model, 191.0, 191.0)), expectation).status,
                         'alert')



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AllyImmunityTests(unittest.TestCase):
    TESTAMENT_OF_WILL = 801455

    def setUp(self):
        entry = side_a_entry(class_entry, self.TESTAMENT_OF_WILL, 'immunity')
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE, entry)
        self.steps = run.validate(self.scenario)['steps']

    def test_the_effects_land_on_and_are_read_from_the_grouped_ally(self):
        self.assertEqual([player['id'] for player in self.scenario['players']], [CASTER, 'ally'])
        group = first_index(self.steps, action='group')
        self.assertEqual(self.steps[group]['target'], 'ally')
        cast = first_index(self.steps, action='cast', spell=self.TESTAMENT_OF_WILL)
        self.assertLess(group, cast)
        self.assertEqual(self.steps[cast]['target'], 'ally')
        fixtures = [step for step in self.steps if step['action'] == 'cast' and step['actor'] == 'dummy']
        self.assertTrue(fixtures)
        self.assertTrue(all(step['target'] == 'ally' for step in fixtures))
        reads = [step for step in self.steps if step.get('metric') == 'aura'
                 and step['spell'] in (self.TESTAMENT_OF_WILL, 35317, 47021)]
        self.assertEqual(len(reads), 8)
        self.assertTrue(all(step['actor'] == 'ally' for step in reads))

    def test_a_slow_or_root_landing_inside_the_window_alerts(self):
        for expectation in self.expectations:
            if expectation.label.endswith(' with'):
                with self.subTest(label=expectation.label):
                    verdict = judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: 1.0}),
                                              expectation)
                    self.assertEqual(verdict.status, 'alert')

    def test_a_caster_entry_keeps_its_steps(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, side_a_entry(class_entry, TESTAMENT_OF_RESOLVE, 'immunity'))
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER])
        self.assertFalse(any(step['action'] == 'group' for step in scenario['steps']))

    def test_another_target_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**side_a_entry(class_entry, self.TESTAMENT_OF_WILL, 'immunity'),
                                            'target': 'dummy'})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CostGateTargetHealthTests(unittest.TestCase):
    def entry(self):
        return side_a_entry(variant_entry, TESTAMENT_OF_STRENGTH, 'cost_gate', 'titanstrike')

    def test_the_dummy_is_lowered_once_before_the_first_cast(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, self.entry())
        steps = run.validate(scenario)['steps']
        lowered = [index for index, step in enumerate(steps) if step['action'] == 'set_health_pct']
        self.assertEqual(len(lowered), 1)
        self.assertEqual((steps[lowered[0]]['target'], steps[lowered[0]]['pct']), ('dummy', 10))
        self.assertLess(lowered[0], first_index(steps, action='cast', spell=806521))

    def test_a_target_health_on_another_target_is_refused(self):
        for bad in ({**self.entry(), 'target': 'caster'}, {**self.entry(), 'target_health_pct': 100}):
            with self.subTest(bad=bad['target'], pct=bad['target_health_pct']):
                with self.assertRaises(ValueError):
                    behaviour_scenario(CLASS_FILE, bad)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ScriptHitControlCastTests(unittest.TestCase):
    ARGENT_BLADE = 807268
    RIGHTEOUS_LUNGE = 570233

    def test_the_control_arm_makes_its_own_casts_with_the_spell_known(self):
        entry = side_a_entry(class_entry, self.ARGENT_BLADE, 'script_hit')
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        drain = first_index(steps, label='control drain')
        control = [step['spell'] for step in steps[:drain] if step['action'] == 'cast']
        treatment = [step['spell'] for step in steps[drain:] if step['action'] == 'cast']
        self.assertEqual(set(control), {self.RIGHTEOUS_LUNGE})
        self.assertEqual(set(treatment), {self.ARGENT_BLADE})
        self.assertLess(first_index(steps, action='learn', spell=self.ARGENT_BLADE), first_index(steps, action='cast'))
        self.assertIn('instead', expectation.model['control_text'])

    def test_an_empty_control_arm_strikes_without_the_brand(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, side_a_entry(class_entry, 300513, 'script_hit'))
        steps = run.validate(scenario)['steps']
        drain = first_index(steps, label='control drain')
        self.assertFalse([step for step in steps[:drain] if step['action'] == 'cast' and step['actor'] == CASTER])
        self.assertTrue([step for step in steps[drain:] if step['action'] == 'cast' and step['spell'] == 300513])

    def test_control_casts_equal_to_the_casts_are_refused(self):
        entry = side_a_entry(class_entry, self.ARGENT_BLADE, 'script_hit')
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**entry, 'control_casts': entry['casts']})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitRatioArmLearnTests(unittest.TestCase):
    def test_a_swing_arm_learns_its_talent_for_its_own_arm_and_refreshes_the_stacks_by_real_casts(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, r1a_entry(705286, 'hit_ratio', 'damage_physical'))
        run.validate(scenario)
        steps = scenario['steps']
        learns = [index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 705286]
        unlearns = [index for index, step in enumerate(steps)
                    if step['action'] == 'unlearn' and step['spell'] == 705286]
        self.assertEqual(len(learns), 1)
        self.assertEqual(len(unlearns), 1)
        swings = [index for index, step in enumerate(steps) if step['action'] == 'attack']
        control_swings = [index for index in swings if index < learns[0]]
        self.assertTrue(control_swings)
        self.assertTrue(all(learns[0] < index < unlearns[0] for index in swings if index > learns[0]))
        lunges = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 570233]
        self.assertEqual(len([index for index in lunges if index < control_swings[0]]), 6)
        self.assertFalse(any(step['action'] == 'set_aura' and step['spell'] == 560834 for step in steps))

    def test_an_arm_learn_is_not_learned_for_the_other_arm(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, r1a_entry(705286, 'hit_ratio', 'damage_holy'))
        steps = scenario['steps']
        first_read = next(index for index, step in enumerate(steps)
                          if step.get('label', '').endswith('control start total'))
        self.assertFalse(any(step['action'] == 'learn' and step['spell'] == 705286 for step in steps[:first_read]))

    def test_an_unknown_arm_field_is_refused(self):
        with self.assertRaises(ValueError):
            hit_arm({'learn': [705286], 'unlearn': [705286]})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitRatioAllyDistanceTests(unittest.TestCase):
    FORTIFIED_BODY = 300515

    def test_the_ally_is_grouped_and_moved_before_the_first_heal(self):
        for variant, distance in (('ally_inside', 30), ('ally_outside', 45)):
            entry = side_a_entry(variant_entry, self.FORTIFIED_BODY, 'hit_ratio', variant)
            scenario, _ = behaviour_scenario(CLASS_FILE, entry)
            steps = run.validate(scenario)['steps']
            cast = first_index(steps, action='cast', spell=578276)
            with self.subTest(variant=variant):
                self.assertLess(first_index(steps, action='group'), cast)
                self.assertEqual(sum(step['dx'] for step in steps[:cast] if step['action'] == 'relocate'
                                     and step['actor'] == 'ally'), distance)
                self.assertEqual(steps[cast]['actor'], 'ally')

    def test_a_distance_without_the_ally_is_refused(self):
        entry = {**side_a_entry(variant_entry, self.FORTIFIED_BODY, 'hit_ratio', 'no_stack'), 'ally_distance': 30}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ScriptHitWeaponAndValueTests(unittest.TestCase):
    def test_the_scourgebane_strike_adds_its_weapon_part_to_the_school_part(self):
        from hits import reference_script_hit_model
        whole = reference_script_hit_model(CLASS_FILE, 92111, 801832)
        school = reference_script_hit_model(CLASS_FILE, 807268, 801832)
        self.assertEqual(whole.kind, 'school')
        self.assertGreater(whole.mean - school.mean, 3 * whole.sigma / 48 ** 0.5)
        self.assertTrue(any('801832s2' in text for text in whole.displayed))

    def test_a_value_read_from_another_spell_lands_on_the_school_effect(self):
        from hits import reference_script_hit_model
        model = reference_script_hit_model(CLASS_FILE, 527023, 527269, 527270, 2)
        self.assertTrue(any('527270m3' in text for text in model.displayed))
        self.assertGreater(model.mean, 0)

    def test_a_value_spell_on_a_hit_without_a_school_effect_is_refused(self):
        from hits import Unmodelled, reference_script_hit_model
        with self.assertRaises(Unmodelled):
            reference_script_hit_model(CLASS_FILE, 527023, 527270, 527270, 2)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CostGateUnsetArmTests(unittest.TestCase):
    def test_the_unset_arm_primes_without_its_setup_cast_and_expects_a_refusal(self):
        from behaviours import cost_gate_scenario, cost_gate_spec
        scenario, expectations = cost_gate_scenario(CLASS_FILE, cost_gate_spec(r1a_entry(804897, 'cost_gate', 'blade')))
        run.validate(scenario)
        unset = next(expectation for expectation in expectations if expectation.label.endswith(' unset'))
        self.assertEqual(unset.displayed, '67')
        steps = scenario['steps']
        start = next(index for index, step in enumerate(steps) if step.get('label') == 'unset global cooldown')
        end = next(index for index, step in enumerate(steps) if step.get('label') == unset.label)
        self.assertEqual(cast_indices(steps[start:end], 803880), [])
        self.assertEqual(len(cast_indices(steps[start:end], 806153)), 2)
        self.assertEqual(len(cast_indices(steps, 803880)), 3)

    def test_an_unset_arm_without_setup_casts_is_refused(self):
        from behaviours import cost_gate_scenario, cost_gate_spec
        entry = {**r1a_entry(804897, 'cost_gate', 'blade'), 'setup_casts': []}
        with self.assertRaises(ValueError):
            cost_gate_scenario(CLASS_FILE, cost_gate_spec(entry))

    def test_seeded_reduction_without_blade_of_faith_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(804897, 'cost_gate', 'blade'))
        unset = next(expectation for expectation in expectations if expectation.label.endswith(' unset'))
        self.assertEqual(judge_behaviour(base_verdict(unset), FakeRun({unset.label: 67.0}), unset).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(unset), FakeRun({unset.label: 0.0}), unset).status, 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FixedCountSettleLayoutTests(unittest.TestCase):
    def test_every_cast_settles_and_the_dummies_stand_around_the_caster(self):
        spec = fixed_target_count_spec(r1a_entry(524620, 'fixed_count'))
        scenario, _ = fixed_target_count_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        settles = [step for step in scenario['steps'] if step.get('label', '').endswith(' settle')
                   and step['action'] == 'wait']
        self.assertEqual([step['ms'] for step in settles], [21500] * spec.repeats)
        distances = {creature['id']: creature['distance'] for creature in scenario['creatures']}
        far = dummy_id(spec.expected + 1)
        self.assertTrue(all(distance < spec.radius for name, distance in distances.items() if name != far))
        self.assertGreater(distances[far], spec.radius)
        self.assertGreater(scenario['timeout_ms'], spec.repeats * 21500)
        casts = cast_indices(scenario['steps'], 804906)
        self.assertTrue(all(scenario['steps'][index]['target'] == dummy_id(0) for index in casts))

    def test_an_unknown_layout_is_refused(self):
        entry = {**r1a_entry(524620, 'fixed_count'), 'layout': 'dummy'}
        with self.assertRaises(ValueError):
            fixed_target_count_scenario(CLASS_FILE, fixed_target_count_spec(entry))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class AvoidedCastConditionTests(unittest.TestCase):
    def test_the_swing_is_attempted_before_and_after_the_dodged_attacks_with_no_aura_set(self):
        scenario, _ = cast_condition_scenario(CLASS_FILE, cast_condition_spec(r1a_entry(572769, 'cast_condition')))
        run.validate(scenario)
        steps = scenario['steps']
        self.assertFalse([step for step in steps if step['action'] == 'set_aura' and step['spell'] == 681170])
        casts = cast_indices(steps, 572769)
        swings = next(index for index, step in enumerate(steps) if step.get('label') == 'attacker swings')
        self.assertEqual(len(casts), 2)
        self.assertLess(casts[0], swings)
        self.assertLess(swings, casts[1])
        self.assertIn('attacker', [creature['id'] for creature in scenario['creatures']])

    def test_seeded_swing_before_any_avoided_attack_alerts(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(572769, 'cast_condition'))
        blocked = expectations[0]
        self.assertEqual(judge_behaviour(base_verdict(blocked), FakeRun({blocked.label: 22.0}), blocked).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(blocked), FakeRun({blocked.label: 0.0}), blocked).status,
                         'alert')


class ScriptHitCasterHealAndModelAurasTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_heal_on_the_caster_is_read_on_the_caster_with_the_libram_in_the_model(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, r1a_entry(801463, 'script_hit'))
        run.validate(scenario, run.SIMULATED_CLOCK)
        heals = [step for step in scenario['steps'] if step.get('metric') == 'spell_heal_total']
        self.assertTrue(heals)
        self.assertTrue(all(step['target'] == CASTER for step in heals))
        self.assertEqual(expectation.model['model_auras'], [801463])
        self.assertIn(801463, [modifier['spell_id'] for modifier in expectation.model['modifiers']])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_damage_hit_on_the_caster_is_refused(self):
        entry = {**r1a_entry(803893, 'script_hit'), 'receiver': CASTER}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    def test_a_model_aura_no_cast_applies_is_refused(self):
        entry = {**r1a_entry(705300, 'script_hit'), 'model_auras': [801463]}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_damage_done_aura_and_the_unresisted_strike_shape_the_model(self):
        _, [breaker] = behaviour_scenario(CLASS_FILE, r1a_entry(705300, 'script_hit'))
        self.assertIn((705300, 79, 15), [(modifier['spell_id'], modifier['aura'], modifier['percent'])
                                         for modifier in breaker.model['modifiers']])
        _, [strike] = behaviour_scenario(CLASS_FILE, r1a_entry(524739, 'script_hit'))
        self.assertTrue(strike.model['unresisted'])
        self.assertEqual(strike.model['reference']['sigma'], 0.0)



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ScriptHitStatAuraTests(unittest.TestCase):
    def entry(self):
        return side_a_entry(variant_entry, 527023, 'script_hit', 'no_power')

    def test_the_stat_auras_come_before_the_stat_measurements(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        steps = run.validate(scenario)['steps']
        self.assertEqual(steps[0], {'action': 'set_aura', 'actor': CASTER, 'spell': 1159613, 'stacks': 1})
        self.assertLess(0, first_index(steps, label='attack_power'))
        self.assertEqual(expectation.label, '527023 script_hit 527269 no_power')

    def test_an_entry_without_stat_auras_keeps_its_label_and_first_step(self):
        entry = side_a_entry(lambda: next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == 527023
                                          and entry['kind'] == 'script_hit' and 'variant' not in entry))
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        self.assertEqual(expectation.label, '527023 script_hit 527269')
        self.assertNotEqual(scenario['steps'][0]['action'], 'set_aura')



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CostGateChargeTests(unittest.TestCase):
    def setUp(self):
        self.entry = side_a_entry(variant_entry, TESTAMENT_OF_STRENGTH, 'cost_gate', 'titanstrike')
        self.scenario, self.expectations = behaviour_scenario(CLASS_FILE, self.entry)
        self.steps = run.validate(self.scenario)['steps']
        self.by_label = {expectation.label: expectation for expectation in self.expectations}

    def label(self, arm: str) -> str:
        return f'{TESTAMENT_OF_STRENGTH} cost_gate 806521 titanstrike {arm}'

    def test_casts_after_the_with_arm_spend_the_charges_without_a_fresh_aura(self):
        self.assertEqual([self.by_label[self.label(f'cast_{cast}')].displayed for cast in (3, 4, 5)], ['0', '0', '67'])
        start = first_index(self.steps, label=self.label('with'))
        end = first_index(self.steps, label=self.label('cast_5'))
        between = self.steps[start:end]
        self.assertFalse([step for step in between if step['action'] in ('reset_cooldown', 'set_aura')])
        self.assertEqual(sum(step['action'] == 'cast' for step in between), 3)

    def test_a_fourth_reduced_cast_or_an_unreduced_control_alerts(self):
        for arm, value in (('cast_5', 0.0), ('cast_3', 67.0), ('without', 0.0)):
            expectation = self.by_label[self.label(arm)]
            with self.subTest(arm=arm):
                verdict = judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: value}), expectation)
                self.assertEqual(verdict.status, 'alert')

    def test_charges_without_a_talent_aura_are_refused(self):
        bad = {key: value for key, value in self.entry.items() if key not in ('talent_aura', 'talent_aura_each_arm')}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, bad)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ExtensionHitRatioMutantTests(unittest.TestCase):
    def judged(self, spell: int, variant: str, treatment: float, control: float) -> str:
        _, [expectation] = behaviour_scenario(CLASS_FILE, side_a_entry(variant_entry, spell, 'hit_ratio', variant))
        return judge_behaviour(base_verdict(expectation), FakeRun(ratio_values(expectation.model, treatment, control)),
                               expectation).status

    def test_an_aura_reaching_beyond_the_radius_alerts(self):
        self.assertEqual(self.judged(300515, 'ally_44', 1060.0, 1000.0), 'alert')
        self.assertEqual(self.judged(300515, 'ally_44', 1000.0, 1000.0), 'ok')
        self.assertEqual(self.judged(300515, 'ally_42', 1000.0, 1000.0), 'alert')

    def test_unraised_periodic_ticks_alert(self):
        self.assertEqual(self.judged(300524, 'blade_of_faith', 191.0, 191.0), 'alert')
        self.assertEqual(self.judged(300524, 'blade_of_faith', 239.0, 191.2), 'ok')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FixedCountCapArmTests(unittest.TestCase):
    def test_the_cap_arm_places_twelve_dummies_inside_the_radius_and_reads_their_distances(self):
        spec = fixed_target_count_spec(r1a_entry(524739, 'fixed_count', 'cap'))
        scenario, [expectation] = fixed_target_count_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(scenario['creatures']), 12)
        self.assertIsNone(expectation.model['far_label'])
        reads = [step for step in scenario['steps'] if step.get('label') in expectation.model['primary_distances']]
        self.assertEqual(len(reads), 11)
        self.assertTrue(all(step['target'] == dummy_id(0) for step in reads))
        primary = scenario['creatures'][0]['distance']
        self.assertTrue(all(creature['distance'] - primary < spec.radius for creature in scenario['creatures']))

    def test_thirteen_creatures_are_refused_by_the_harness_schema(self):
        scenario, _ = fixed_target_count_scenario(CLASS_FILE, fixed_target_count_spec(r1a_entry(524739, 'fixed_count',
                                                                                              'cap')))
        extra = {**scenario['creatures'][0], 'id': 'thirteenth'}
        with self.assertRaises(Exception):
            run.validate({**scenario, 'creatures': scenario['creatures'] + [extra]})

    def test_seeded_dummy_beyond_the_radius_or_a_cap_overrun_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, r1a_entry(524739, 'fixed_count', 'cap'))
        model = expectation.model
        per_cast = model['per_cast']

        def values(hit_per_cast: int, far: float = 1.0) -> dict:
            found = {label: 0.0 for label in per_cast['start']}
            for cast, labels in enumerate(per_cast['casts'], start=1):
                for index, label in enumerate(labels):
                    found[label] = float(cast) if index == 0 or index <= hit_per_cast else 0.0
            found.update({label: 1.0 for label in model['dummy_labels']})
            found.update({label: far for label in model['primary_distances']})
            return found

        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(9)), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(10)), expectation).status,
                         'alert')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(9, far=5.5)), expectation).status,
                         'alert')

    def test_the_cluster_arm_places_eleven_dummies_within_its_cluster_of_the_primary(self):
        spec = fixed_target_count_spec(r1a_entry(524739, 'fixed_count', 'cap_cluster'))
        scenario, [expectation] = fixed_target_count_scenario(CLASS_FILE, spec)
        run.validate(scenario)
        self.assertEqual(len(scenario['creatures']), 12)
        primary = scenario['creatures'][0]['distance']
        offsets = [creature['distance'] - primary for creature in scenario['creatures'][1:]]
        self.assertTrue(all(0 < offset < spec.cluster_yd for offset in offsets))
        self.assertEqual(expectation.model['radius'], spec.cluster_yd)
        self.assertEqual(len(expectation.model['per_cast']['casts']), 6)

    def test_seeded_dummy_outside_the_cluster_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, r1a_entry(524739, 'fixed_count', 'cap_cluster'))
        model = expectation.model
        per_cast = model['per_cast']

        def values(spread: float) -> dict:
            found = {label: 0.0 for label in per_cast['start']}
            for cast, labels in enumerate(per_cast['casts'], start=1):
                for index, label in enumerate(labels):
                    found[label] = float(cast) if index <= 9 else 0.0
            found.update({label: 1.0 for label in model['dummy_labels']})
            found.update({label: spread for label in model['primary_distances']})
            return found

        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(2.3)), expectation).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values(3.0)), expectation).status,
                         'alert')

    def test_a_cluster_not_inside_the_radius_is_refused(self):
        entry = {**r1a_entry(524739, 'fixed_count', 'cap_cluster'), 'cluster_yd': 5.0}
        with self.assertRaises(ValueError):
            fixed_target_count_scenario(CLASS_FILE, fixed_target_count_spec(entry))

    def test_the_cap_arm_keeps_the_radius_as_its_placement_bound(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, r1a_entry(524739, 'fixed_count', 'cap'))
        self.assertEqual(expectation.model['radius'], 5.0)

    def test_a_headroom_on_an_uncapped_count_is_refused(self):
        entry = {**r1a_entry(524739, 'fixed_count', 'cap_control'), 'headroom': 2}
        with self.assertRaises(ValueError):
            fixed_target_count_scenario(CLASS_FILE, fixed_target_count_spec(entry))


class BladeOfFaithCritTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_crit_arm_forces_melee_crit_and_the_control_forces_zero(self):
        crit, _ = behaviour_scenario(CLASS_FILE, r1a_entry(803872, 'metric_delta', 'crit'))
        zero, _ = behaviour_scenario(CLASS_FILE, r1a_entry(803872, 'metric_delta', 'crit_zero'))
        self.assertIn('melee_crit_rating', crit['players'][0])
        self.assertNotIn('melee_crit_rating', zero['players'][0])
        self.assertTrue([step for step in zero['steps'] if step['action'] == 'set_aura' and step['spell'] == 64481])
        self.assertEqual(len(cast_indices(crit['steps'], 803880)), 1)

    def test_the_blade_tick_ratios_force_a_zero_crit_chance_in_both_arms(self):
        for suffix in ('oaths', 'oath_lunge', 'oath_condemn', 'oath_cleave'):
            entry = r1a_entry(803872, 'hit_ratio', suffix)
            with self.subTest(suffix=suffix):
                self.assertIn([64481, 1], entry['control']['auras'])
                self.assertIn([64481, 1], entry['treatment']['auras'])


    def test_side_a_focused_blade_ratio_forces_a_zero_crit_chance_in_both_arms(self):
        entry = side_a_entry(variant_entry, 300524, 'hit_ratio', 'blade_of_faith')
        self.assertIn([64481, 1], entry['control']['auras'])
        self.assertIn([64481, 1], entry['treatment']['auras'])


class AggroRedirectRangeTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_rooted_dummies_are_read_by_distance_right_before_the_cast(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(800424, 'aggro_redirect', 'range'))
        run.validate(scenario)
        steps = scenario['steps']
        roots = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == 42716]
        self.assertEqual(len(roots), 2)
        cast = cast_indices(steps, 800424)[0]
        reads = [index for index, step in enumerate(steps) if step.get('metric') == 'distance_2d']
        self.assertEqual(len(reads), 2)
        self.assertTrue(all(index < cast for index in reads))
        self.assertEqual([expectation.displayed for expectation in expectations], ['1', '1'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_seeded_misplaced_dummy_alerts_even_when_the_victim_matches(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(800424, 'aggro_redirect', 'range'))
        inside = expectations[0]
        placed = {inside.label: 1.0, inside.model['distance_label']: 7.5}
        moved = {inside.label: 1.0, inside.model['distance_label']: 9.5}
        self.assertEqual(judge_behaviour(base_verdict(inside), FakeRun(placed), inside).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(inside), FakeRun(moved), inside).status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_geometry_reads_every_dummy_and_the_caster_before_the_cast(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, r1a_entry(800424, 'aggro_redirect', 'edge'))
        run.validate(scenario)
        steps = scenario['steps']
        cast = cast_indices(steps, 800424)[0]
        for index in range(4):
            for metric in ('combat_reach', 'position_z'):
                read = next(position for position, step in enumerate(steps)
                            if step.get('label') == aggro_redirect_label(800424, index, metric, 'edge'))
                self.assertEqual(steps[read]['actor'], dummy_id(index))
                self.assertLess(read, cast)
        caster_reads = [step for step in steps[:cast] if step.get('actor') == 'caster'
                        and step.get('metric') in ('combat_reach', 'position_z', 'run_speed_rate')]
        self.assertEqual(len(caster_reads), 3)
        self.assertEqual([expectation.displayed for expectation in expectations], ['1', '1', '0', '0'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_control_is_a_stock_area_taunt_with_a_guard_inside_its_radius(self):
        [control] = control_entries(19)
        self.assertEqual((control['spell'], control['control_for']), (1161, 800424))
        scenario, expectations = behaviour_scenario(CLASS_FILE, control)
        run.validate(scenario)
        self.assertEqual(len(cast_indices(scenario['steps'], 1161)), 1)
        self.assertEqual([expectation.displayed for expectation in expectations], ['1', '0', '0', '0', '0'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_control_stays_out_of_the_class_file_and_its_full_generation(self):
        self.assertFalse([entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == 1161])
        manifest_dir = Path(tempfile.mkdtemp())
        try:
            import conformance
            conformance.main(['generate', '--class', '19', '--out', str(manifest_dir), '--controls'])
            files = sorted(path.name for path in (manifest_dir / 'scenarios').glob('*.json'))
            self.assertEqual(files, ['conformance-templar-behaviour-1161-aggro-redirect-edge.json'])
        finally:
            shutil.rmtree(manifest_dir)

    def test_geometry_without_roots_is_refused(self):
        entry = {**r1a_entry(800424, 'aggro_redirect', 'edge'), 'rooted': False}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_range_entry_reads_no_geometry(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, r1a_entry(800424, 'aggro_redirect', 'range'))
        self.assertFalse([step for step in scenario['steps']
                          if step.get('metric') in ('combat_reach', 'position_z', 'run_speed_rate')])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_an_entry_without_roots_keeps_its_labels(self):
        _, expectations = behaviour_scenario(CLASS_FILE, next(
            entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == 800424
            and entry['kind'] == 'aggro_redirect' and 'variant' not in entry))
        self.assertEqual(expectations[0].label, '800424 aggro_redirect primary after')
        self.assertNotIn('distance_label', expectations[0].model)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitCastAuraTests(unittest.TestCase):
    def test_blade_hit_and_periodic_total_scenarios_set_the_zero_crit_aura_before_each_cast(self):
        manifest_dir = Path(tempfile.mkdtemp())
        try:
            import conformance
            conformance.main(['generate', '--class', '19', '--out', str(manifest_dir), '--spell', '803880'])
            files = sorted((manifest_dir / 'scenarios').glob('conformance-templar-*-803880-part-*.json'))
            self.assertTrue(files)
            for path in files:
                steps = json.loads(path.read_text())['steps']
                casts = cast_indices(steps, 803880)
                self.assertTrue(casts)
                for index in casts:
                    before = [step for step in steps[:index] if step['action'] == 'set_aura'
                              and step['spell'] == 64481]
                    self.assertTrue(before, path.name)
        finally:
            shutil.rmtree(manifest_dir)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FixedCountBehindTests(unittest.TestCase):
    def entry(self, **changes):
        return {'spell': 572769, 'name': 'Sacred Swing', 'kind': 'fixed_count',
                'quote': 'Swing at enemies in front of you', 'expected': 3, 'radius': 6.0, 'uncapped': True,
                'cast_spell': 572769, 'layout': 'caster', 'behind_yd': 3.0, 'radius_reason': 'synthetic', **changes}

    def readings(self, expectation, behind=0.0):
        model = expectation.model
        values = {label: 1.0 for label in model['dummy_labels']}
        values[model['far_label']] = 0.0
        values[model['behind_label']] = behind
        for cast in model['per_cast']['casts']:
            values.update({label: 1.0 for label in cast})
        values.update({label: 0.0 for label in model['per_cast']['start']})
        return values

    def test_the_caster_steps_past_one_dummy_before_the_casts(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        steps = run.validate(scenario)['steps']
        distances = [creature['distance'] for creature in scenario['creatures']]
        self.assertEqual(distances, [7.2, 8.4, 9.6, 10.8, 17.0, 3.0])
        relocate = first_index(steps, action='relocate', actor=CASTER)
        self.assertEqual(steps[relocate]['dx'], 6.0)
        self.assertLess(relocate, cast_indices(steps, 572769)[0])
        self.assertEqual(expectation.model['behind_label'], f'572769 {dummy_id(5)} spell_damage_count after')
        plain, [plain_expectation] = behaviour_scenario(CLASS_FILE, {**self.entry(), 'behind_yd': None})
        self.assertFalse([step for step in plain['steps'] if step['action'] == 'relocate'])
        self.assertNotIn('behind_label', plain_expectation.model)
        self.assertEqual([creature['distance'] for creature in plain['creatures']], [1.2, 2.4, 3.6, 4.8, 11.0])

    def test_a_behind_dummy_outside_the_radius_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, self.entry(behind_yd=7.0))

    def test_seeded_hit_behind_the_caster_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        judge = lambda values: judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status
        self.assertEqual(judge(self.readings(expectation)), 'ok')
        self.assertEqual(judge(self.readings(expectation, behind=1.0)), 'alert')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ThreatSlopeFlatSpellsTests(unittest.TestCase):
    def entry(self, **changes):
        return {'spell': 572769, 'name': 'Sacred Swing', 'kind': 'threat_slope',
                'quote': 'High Threat Weapon Damage', 'hit_spell': 572769, 'expected_slope': 2.25,
                'flat_spells': [301061], **changes}

    def test_the_triggered_flat_threat_and_the_caster_aura_enter_the_scenario(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        steps = run.validate(scenario)['steps']
        self.assertEqual(expectation.model['flat'], 50.0)
        aura = first_index(steps, action='set_aura', spell=681170)
        self.assertLess(aura, cast_indices(steps, 572769)[0])
        _, [plain] = behaviour_scenario(CLASS_FILE, self.entry(flat_spells=[]))
        self.assertEqual(plain.model['flat'], 0.0)

    def test_seeded_slope_off_the_stated_factor_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, self.entry())
        model = expectation.model
        values = lambda threat: FakeRun({model['cast_label']: NO_CAST_FAILURE, model['health_before_label']: 10000.0,
                                         model['health_after_label']: 9600.0, model['threat_label']: threat})
        judge = lambda threat: judge_behaviour(base_verdict(expectation), values(threat), expectation).status
        self.assertEqual(judge(950.0), 'ok')
        self.assertEqual(judge(850.0), 'alert')


def r3b_entry(spell: int, kind: str, suffix: str = '') -> dict:
    return r1a_entry(spell, kind, suffix)


def arm_readings(expectations: list[Expectation]) -> dict[str, tuple[float, float]]:
    return {expectation.label.rsplit(' ', 1)[1]: (expectation.model['level'], float(expectation.displayed))
            for expectation in expectations if 'level' in expectation.model}


def seeded(expectation: Expectation, value: float) -> str:
    return judge_behaviour(base_verdict(expectation), FakeRun({expectation.label: value}), expectation).status


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CostGateWeaponIncreaseRemovalTests(unittest.TestCase):
    def test_the_gated_spell_gets_a_weapon_it_can_be_cast_with(self):
        from behaviours import cost_gate_scenario, cost_gate_spec
        scenario, expectations = cost_gate_scenario(CLASS_FILE, cost_gate_spec(r3b_entry(706318, 'cost_gate')))
        run.validate(scenario)
        equipped = [step['item'] for step in scenario['steps'] if step['action'] == 'equip']
        self.assertEqual(equipped, [CLASS_FILE['alternate_weapons'][0]['item']])
        self.assertEqual(seeded(expectations[1], 0.0), 'ok')
        self.assertEqual(seeded(expectations[1], 29.0), 'alert')

    def test_a_gated_spell_the_reference_weapon_fits_keeps_its_scenario(self):
        from behaviours import cost_gate_scenario, cost_gate_spec
        scenario, _ = cost_gate_scenario(CLASS_FILE, cost_gate_spec(r3b_entry(301059, 'cost_gate')))
        equipped = [step['item'] for step in scenario['steps'] if step['action'] == 'equip']
        self.assertEqual(equipped, [CLASS_FILE['weapon']['item']])

    def test_a_cost_increase_is_refused_at_the_base_cost_and_allowed_at_the_raised_one(self):
        from behaviours import cost_gate_scenario, cost_gate_spec
        scenario, expectations = cost_gate_scenario(CLASS_FILE, cost_gate_spec(r3b_entry(707663, 'cost_gate',
                                                                                          'cost')))
        run.validate(scenario)
        self.assertEqual(arm_readings(expectations), {'without': (20, 0.0), 'base': (20, 85.0), 'with': (30, 0.0),
                                                      'beyond': (29, 85.0)})
        with_arm = next(expectation for expectation in expectations if expectation.label.endswith(' with'))
        self.assertEqual(seeded(with_arm, 85.0), 'alert')

    def test_a_removed_cooldown_is_attempted_after_the_global_cooldown_with_no_beyond_arm(self):
        from behaviours import cost_gate_scenario, cost_gate_spec
        scenario, expectations = cost_gate_scenario(CLASS_FILE, cost_gate_spec(r3b_entry(707663, 'cost_gate',
                                                                                          'cooldown')))
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(arm_readings(expectations), {'without': (1350, 67.0), 'with': (1350, 0.0)})
        with_arm = next(expectation for expectation in expectations if expectation.label.endswith(' with'))
        self.assertEqual(seeded(with_arm, 0.0), 'ok')
        self.assertEqual(seeded(with_arm, 67.0), 'alert')
        powers = {step['value'] for step in scenario['steps'] if step['action'] == 'set_power'}
        self.assertEqual(powers, {100})

    def test_cast_power_on_a_power_gate_is_refused(self):
        from behaviours import cost_gate_scenario, cost_gate_spec
        entry = {**r3b_entry(707663, 'cost_gate', 'cost'), 'cast_power': 100}
        with self.assertRaises(ValueError):
            cost_gate_scenario(CLASS_FILE, cost_gate_spec(entry))

    def test_an_increase_with_no_whole_level_between_is_not_modelled(self):
        from behaviours import NotModelled, cost_gate_scenario, cost_gate_spec
        entry = {**r3b_entry(707663, 'cost_gate', 'cost'), 'reduction': -0.5}
        with self.assertRaises(NotModelled):
            cost_gate_scenario(CLASS_FILE, cost_gate_spec(entry))

    def test_the_arm_wait_lengthens_every_global_cooldown_wait(self):
        from behaviours import SINGLE_TARGET_GCD_WAIT_MS, cost_gate_scenario, cost_gate_spec
        scenario, _ = cost_gate_scenario(CLASS_FILE, cost_gate_spec(r3b_entry(704180, 'cost_gate',
                                                                              'righteous_tempest')))
        waits = [step['ms'] for step in scenario['steps'] if step.get('label', '').endswith(' global cooldown')]
        self.assertEqual(waits, [SINGLE_TARGET_GCD_WAIT_MS + 5500] * 3)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FixedCountLabelSuffixTests(unittest.TestCase):
    def test_two_entries_of_one_spell_read_disjoint_labels(self):
        def labels(suffix: str) -> set[str]:
            scenario, [expectation] = fixed_target_count_scenario(
                CLASS_FILE, fixed_target_count_spec(r3b_entry(706312, 'fixed_count', suffix)))
            reads = {step['label'] for step in scenario['steps'] if step.get('metric') == 'spell_damage_count'}
            self.assertTrue(all(label.startswith(f'706312 {suffix} ') for label in reads))
            return reads | {expectation.label}
        self.assertFalse(labels('scourgebane') & labels('scarlet_hammer'))

    def test_the_talent_is_learned_and_the_count_label_carries_the_suffix(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, r3b_entry(707853, 'fixed_count', 'scourgebane'))
        self.assertEqual(expectation.label, '707853 scourgebane behaviour_fixed_count')
        self.assertIn(707853, [step['spell'] for step in behaviour_scenario(
            CLASS_FILE, r3b_entry(707853, 'fixed_count', 'scourgebane'))[0]['steps'] if step['action'] == 'learn'])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CastCombatResurrectTests(unittest.TestCase):
    def test_the_dead_ally_answers_before_and_after_the_cast(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, r3b_entry(500688, 'cast_combat', 'revive'))
        run.validate(scenario)
        steps = scenario['steps']
        answers = [index for index, step in enumerate(steps) if step['action'] == 'client_packet']
        casts = cast_indices(steps, 500758)
        self.assertEqual(len(answers), 2)
        self.assertEqual(len(casts), 1)
        self.assertLess(answers[0], casts[0])
        self.assertLess(casts[0], answers[1])
        alive = {expectation.label: expectation for expectation in expectations if 'alive' in expectation.label}
        before, after = alive['500688 cast_combat revive alive before'], alive['500688 cast_combat revive alive after']
        self.assertEqual((before.displayed, after.displayed), ('0', '1'))
        self.assertEqual(seeded(after, 1.0), 'ok')
        self.assertEqual(seeded(after, 0.0), 'alert')
        self.assertEqual(seeded(before, 1.0), 'alert')

    def test_the_base_entry_keeps_its_labels(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r3b_entry(500688, 'cast_combat'))
        self.assertEqual([expectation.label for expectation in expectations],
                         ['500688 cast_combat combat', '500688 cast_combat cast_failure'])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class FallDamageTests(unittest.TestCase):
    def test_the_ally_lands_before_and_after_the_aura_at_a_fixed_maximum_health(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, r3b_entry(560653, 'fall_damage', 'landing'))
        run.validate(scenario)
        steps = scenario['steps']
        falls = [index for index, step in enumerate(steps) if step['action'] == 'fall']
        casts = cast_indices(steps, 560653)
        self.assertEqual(len(falls), 2)
        self.assertEqual(len(casts), 1)
        self.assertLess(falls[0], casts[0])
        self.assertLess(casts[0], falls[1])
        self.assertTrue(all(steps[index]['actor'] == ALLY and steps[index]['height'] == 30 for index in falls))
        self.assertIn('harness-simulated', scenario['contract'])
        self.assertEqual([expectation.check for expectation in expectations],
                         ['behaviour_fall_damage', 'behaviour_cast_condition'])

    def readings(self, expectation: Expectation, without: float, with_aura: float) -> dict[str, float]:
        (before_without, after_without), (before_with, after_with) = (expectation.model['arms']['without'],
                                                                      expectation.model['arms']['with'])
        return {before_without: 10000.0, after_without: 10000.0 - without, before_with: 10000.0,
                after_with: 10000.0 - with_aura}

    def test_seeded_landings_that_are_not_reduced_alert(self):
        _, [expectation, _] = behaviour_scenario(CLASS_FILE, r3b_entry(560653, 'fall_damage', 'landing'))
        judge = lambda without, with_aura: judge_behaviour(
            base_verdict(expectation), FakeRun(self.readings(expectation, without, with_aura)), expectation).status
        self.assertEqual(judge(2974.0, 1174.0), 'ok')
        self.assertEqual(judge(2974.0, 2974.0), 'alert')
        self.assertEqual(judge(0.0, 0.0), 'alert')
        self.assertEqual(judge(1174.0, 2974.0), 'alert')

    def test_an_unknown_receiver_is_refused(self):
        entry = {**r3b_entry(560653, 'fall_damage', 'landing'), 'receiver': 'dummy'}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CostGateRemovalLimitTests(unittest.TestCase):
    def test_a_removal_verdict_states_the_global_cooldown_limit(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r3b_entry(707663, 'cost_gate', 'cooldown'))
        with_arm = next(expectation for expectation in expectations if expectation.label.endswith(' with'))
        self.assertEqual(with_arm.model['removal'], {'global_cooldown_ms': 1250, 'gcd_wait_ms': 1600})
        verdict = judge_behaviour(base_verdict(with_arm), FakeRun({with_arm.label: 0.0}), with_arm)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('1250 ms global cooldown', verdict.explanation)
        self.assertIn('1350 ms', verdict.explanation)

    def test_the_removal_reads_the_cooldown_right_after_the_first_cast(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, r3b_entry(707663, 'cost_gate', 'cooldown'))
        reads = [step for step in scenario['steps'] if step.get('metric') == 'cooldown_ms']
        self.assertEqual(len(reads), 2)
        read = next(expectation for expectation in expectations if expectation.label.endswith(' with cooldown'))
        self.assertEqual(read.displayed, '0')
        self.assertEqual(seeded(read, 0.0), 'ok')
        self.assertEqual(seeded(read, 600.0), 'alert')

    def test_a_removal_wait_inside_the_global_cooldown_is_refused(self):
        entry = {**r3b_entry(707663, 'cost_gate', 'cooldown'), 'removal_wait_ms': 1200}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    def test_a_reduction_verdict_carries_no_removal_limit(self):
        _, expectations = behaviour_scenario(CLASS_FILE, r3b_entry(706309, 'cost_gate'))
        self.assertNotIn('removal', expectations[0].model)



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitRatioStatedBonusTests(unittest.TestCase):
    def runs(self, expectation: Expectation, ratio: float, spread: float = 0.002) -> FakeRun:
        values = {}
        for arm, scale in (('control', 1.0), ('treatment', ratio)):
            for index, (total, count) in enumerate(expectation.model['reads'][arm]):
                trial = index
                values[total] = sum(10000.0 * scale * (1 + spread * ((step % 3) - 1)) for step in range(trial))
                values[count] = float(trial)
        return FakeRun(values)

    def test_the_bonus_is_judged_in_the_stated_unit(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, r3b_entry(706320, 'hit_ratio', 'oath_condemn'))
        self.assertEqual(expectation.model['stated'], {'bonus': 20.0, 'parts': [30.0]})
        from behaviours import stated_ratio
        from compare import stated_bonus_of_ratio
        self.assertAlmostEqual(stated_bonus_of_ratio(stated_ratio(20.0, (30.0,)), [30.0]), 20.0, places=6)
        self.assertAlmostEqual(stated_bonus_of_ratio(stated_ratio(11.0, (5.0, 30.0)), [5.0, 30.0]), 11.0, places=6)

    def test_a_ratio_that_was_ok_in_the_derived_unit_alerts_in_the_stated_one(self):
        from behaviours import stated_ratio
        _, [expectation] = behaviour_scenario(CLASS_FILE, r3b_entry(706320, 'hit_ratio', 'oath_condemn'))
        judge = lambda bonus: judge_behaviour(base_verdict(expectation), self.runs(
            expectation, stated_ratio(bonus, (30.0,)), 0.0), expectation)
        self.assertEqual(judge(20.0).status, 'ok')
        self.assertEqual(judge(12.0).status, 'alert')
        self.assertEqual(judge(28.0).status, 'alert')

    def test_an_expected_ratio_off_the_stated_bonus_is_refused(self):
        entry = {**r3b_entry(706320, 'hit_ratio', 'oath_condemn'), 'expected': 1.06}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitRatioEngineStepTests(unittest.TestCase):
    def judged(self, spell: int, ratio: float, spread: float = 0.0) -> Verdict:
        _, [expectation] = behaviour_scenario(CLASS_FILE, r1a_entry(spell, 'hit_ratio', 'oath_heal'))
        values = {}
        for arm, scale in (('control', 1.0), ('treatment', ratio)):
            for trial, (total, count) in enumerate(expectation.model['reads'][arm]):
                values[total] = sum(10000.0 * scale * (1 + spread * ((step % 3) - 1)) for step in range(trial))
                values[count] = float(trial)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_stated_bonus_is_read_through_int32_amounts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, r1a_entry(524822, 'hit_ratio', 'oath_heal'))
        self.assertEqual(expectation.model['stated'], {'bonus': 25.0, 'parts': [5.0, 30.0], 'truncated': True})
        from behaviours import stated_ratio
        self.assertAlmostEqual(stated_ratio(25.0, (5.0, 30.0), True), 1.06 * 1.37 / 1.365, places=9)
        self.assertAlmostEqual(stated_ratio(50.0, (5.0, 30.0), True), 1.07 * 1.45 / 1.365, places=9)
        self.assertAlmostEqual(stated_ratio(20.0, (5.0, 30.0), True), 1.06 * 1.36 / 1.365, places=9)

    def test_the_stated_step_passes_and_states_it(self):
        verdict = self.judged(524822, 1.06 * 1.37 / 1.365)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, (70 / 3 + 80 / 3) / 2, places=3)
        self.assertAlmostEqual(verdict.low, 70 / 3, places=3)
        self.assertAlmostEqual(verdict.high, 80 / 3, places=3)
        self.assertIn('[6, 37]', verdict.explanation)
        rank_two = self.judged(525080, 1.07 * 1.45 / 1.365)
        self.assertEqual(rank_two.status, 'ok')
        self.assertAlmostEqual(rank_two.low, 50.0, places=3)
        self.assertAlmostEqual(rank_two.high, 160 / 3, places=3)

    def test_seeded_mutants_one_amount_off_the_stated_step_alert(self):
        for spell, ratio, amounts in ((524822, 1.06 * 1.36 / 1.365, '[6, 36]'),
                                      (524822, 1.06 * 1.38 / 1.365, '[6, 38]'),
                                      (525080, 1.07 * 1.44 / 1.365, '[7, 44]'),
                                      (525080, 1.07 * 1.46 / 1.365, '[7, 46]')):
            with self.subTest(spell=spell, amounts=amounts):
                verdict = self.judged(spell, ratio)
                self.assertEqual(verdict.status, 'alert')
                self.assertIn(f'one engine step, the amounts {amounts}', verdict.explanation)

    def test_steps_that_leave_out_the_stated_one_alert(self):
        reading = compare_module.engine_step_reading(
            compare_module.Bonus(7.55, 0.55, 25.0, 40),
            {'bonus': 25.0, 'parts': [5.0, 30.0]})
        self.assertEqual(reading.status, 'alert')
        self.assertIn('the engine steps from the amounts [6, 38] on', reading.text)

    def test_seeded_amounts_no_bonus_in_the_band_gives_alert(self):
        self.assertEqual(self.judged(524822, 1.05 * 1.35 / 1.365).status, 'alert')
        self.assertEqual(self.judged(524822, 1.0).status, 'alert')
        self.assertEqual(self.judged(525080, 1.06 * 1.37 / 1.365).status, 'alert')

    def test_a_ratio_between_two_engine_steps_alerts(self):
        verdict = self.judged(524822, 1.06 * 1.375 / 1.365)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('between two engine steps', verdict.explanation)

    def test_an_interval_across_steps_and_outside_the_band_is_not_judged(self):
        self.assertEqual(self.judged(524822, 1.06 * 1.37 / 1.365, 0.2).status, 'insufficient_trials')

    def test_an_expected_ratio_off_the_truncated_amounts_is_refused(self):
        entry = {**r1a_entry(524822, 'hit_ratio', 'oath_heal'), 'expected': 1.0703}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)


if __name__ == '__main__':
    unittest.main()
