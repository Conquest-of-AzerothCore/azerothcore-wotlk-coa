from dataclasses import replace
from fractions import Fraction
import json
import math
from pathlib import Path
import sys
import types
import unittest
from unittest import mock

from classes import ClassSpell, class_spells
from behaviours import STRIKER, NotModelled, behaviour_scenario
from block_value import BLOCK_VALUE_LABEL, BLOCK_VALUE_TERMS
from heal_pct import HEAL_PCT_LABEL, HEAL_PCT_TERMS, heal_pct_amount, heal_pct_percent
from compare import PER_LEVEL_ROUNDING, Run, Verdict, judge_hit
from conformance import target_gate_arms
from hits import (CLOSED, HIT_CHECKS, MAX_SCENARIO_MS, UNMODELLED, HitModel, Modifier, Unmodelled, WeaponProfile,
                  casts_needed, dual_target_entry, effect_hit, expected_hit, floored_casts, hit_kind, hit_parts,
                  hit_location, hit_scenario,
                  learned_weapon_part,
                  measured_hit_model, melee_parts, melee_scenario, records_of, periodic_tick_readout, ranged_weapon_attack,
                  rank_hit, reference_caster, reference_hit_model, reference_melee_model, reference_script_hit_model,
                  rolled_values, script_hit_model, rank_hit_effect, hit_measurements,
                  scheduled_casts, self_stack_multiplier, weapon_attacker, weapon_profile, base_mana_steps,
                  taken_by, taken_modifiers)
from custom_attr import CustomAttributes
from mitigation import (REFERENCE_TARGET, MitigationModel, TargetProfile, armor_reduction, average_resist,
                        expected_mitigation, partial_resist_shares)
from profile import CASTER, load_class_file, load_fixture_class_file, measurement
from tooltip import CasterStats, Displayed, Readout, read_tooltip, weapon_skill_spells
from values import (ALLY, CAST_MARGIN_MS, CHARGE_OFFSET_YD, DUMMY_DISTANCE, GAP_CLOSER_DISTANCE, NOMINAL_MELEE_RANGE_YD,
                    TARGET, UNREADABLE, Expectation, armed_for, cast_distance, missile_wait_ms, value_scenario)

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

DBC_DIR = Path('/srv/coa/server-data/dbc')
HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'

TEMPLAR_CLASS_ID = 19
WITCH_HUNTER_CLASS_ID = 15
STAKE_RANK = 681350
DAMNATION = 520062
DAMNATION_MAX_RANK = 520217
SHADOWBLAST = 804191
SMITE_EVIL = 803364
TORMENTOR = 800162
HUNTER_RANGE = 114
HEAVY_CROSSBOW = 15809
RANGED_SLOT = 17
SCIMITAR = 2027
SOLAR_PRAYER = 806479
SOLAR_PRAYER_MAX_HEALTH = 1788
MAIN_HAND_SLOT, OFF_HAND_SLOT = 15, 16
CROSSBOWS_SKILL_LINE = 226
HEAVY_CROSSBOW_WEAPON = {'item': HEAVY_CROSSBOW, 'slot': RANGED_SLOT, 'subclass': 18, 'min_damage': 49.0,
                         'max_damage': 50.0, 'speed_ms': 2800, 'inventory_type': 26, 'normalized_speed': 2.8,
                         'skill_line': CROSSBOWS_SKILL_LINE}
WALKING_STICK = 2495
WALKING_STICK_MIN = 6.5625
WALKING_STICK_MAX = 10.9375
WALKING_STICK_DELAY_MS = 2500
TWO_HANDED_NORMALIZED_SPEED = 3.3
REFERENCE_ATTACK_POWER = 313
REFERENCE_STAMINA = 79
FROSTMANE_CLUB = 2259
ONE_HANDED_MACE_SUBCLASS = 4
MACES_SKILL_LINE = 54
ONE_HANDED_NORMALIZED_SPEED = 2.4
ARGENT_BLADE = 804929
ARGENT_BLADE_MAX_RANK = 807268
ARGENT_BLADE_EFFECTS = [121, 31, 64]
ARGENT_BLADE_PERCENT = 215.0
ARGENT_BLADE_FLAT = 421 + 0.4725 * REFERENCE_ATTACK_POWER
ARGENT_BLADE_ENERGY_COST = 50
SACRED_SWING = 705293
SACRED_SWING_MAX_RANK = 572769
ENERGY = 3
CLASS_TUNING_AURA = 887007
RIGHTEOUS_UPHEAVAL = 501562
RIGHTEOUS_UPHEAVAL_MAX_RANK = 572027
RIGHTEOUS_UPHEAVAL_BASE_POINTS = 658
RIGHTEOUS_UPHEAVAL_DIE_SIDES = 224
RIGHTEOUS_UPHEAVAL_AP_COEFFICIENT = 0.45
RIGHTEOUS_UPHEAVAL_CASTS_NEEDED = 335
RIGHTEOUS_UPHEAVAL_SCHEDULED = 503
OATH_CHAIN = 704576
DIVINE_FORCE = 806153
DIVINE_FORCE_MAX_RANK = 807805
DIVINE_FORCE_SKILL_LINE = 72
SILVERHAND_INCANTATION = 801465
RECKONING = 805421
RECKONING_MAX_RANK = 572741
RECKONING_BASE_POINTS = 165
RECKONING_DIE_SIDES = 49
RECKONING_CASTS_NEEDED = 722
RECKONING_PARTS = 4
VINDICATION = 801446
VINDICATION_MAX_RANK = 573324
VINDICATION_SUBCLASS_MASK = 41105
STAFF_SUBCLASS = 10
RIGHTEOUS_TEMPEST = 805409
RIGHTEOUS_TEMPEST_MAX_RANK = 807274
RIGHTEOUS_TEMPEST_STRIKE = 570205
RIGHTEOUS_TEMPEST_STRIKE_FLAT = 154
RIGHTEOUS_TEMPEST_TICKS = 5
BLADE_OF_FAITH = 803872
BLADE_OF_FAITH_MAX_RANK = 803880
BLADE_OF_FAITH_TOTAL = '${($d*1000/$T1)*($m1+0+$SP*.2+$AP*0.1)}'
BLADE_OF_FAITH_PERIOD_MS = 3000
BLADE_OF_FAITH_DURATION_MS = 30000
PVE_DAMAGE_DONE_PCT = 341
HEALING_DONE_PCT = 136
CLASS_TUNING_PERCENT_AT_60 = -20
NO_MITIGATION = MitigationModel(mean=1.0, variance=0.0)
ARMOR_528 = TargetProfile(entry=36, level=60, armor=528, resistances={})
PHYSICAL = 1
HOLY = 2
SCHOOL_DAMAGE = 2
HEAL = 10
HEALTH_LEECH = 9
TRIGGER_SPELL = 64
APPLY_AURA = 6
WEAPON_PERCENT_DAMAGE = 31
PERIODIC_DAMAGE = 3
DUMMY = 3
TEMPLE_GUARDIAN = 801165
TEMPLE_GUARDIAN_LIVE_RANK = 803792
TITANSTRIKE = 806521
TITANSTRIKE_MAX_RANK = 806835
CHASTISE_MAX_RANK = 503141
MARTIAL_TRAINING = 806525
TEMPLARS_MIGHT = 705291
CONDEMN_LIVE_RANK = 567539
BENEDICTION = 801448
BENEDICTION_MAX_RANK = 578276
Z_99 = 2.576


def caster(ap=REFERENCE_ATTACK_POWER):
    return CasterStats(level=60, ap=ap, rap=182, sp_by_school={school: 0 for school in range(1, 7)},
                       stats={stat: 0 for stat in range(5)})


def argent_blade_readout():
    return Readout(values=[Displayed('$s2', ARGENT_BLADE_PERCENT, 1, 'percent'),
                           Displayed('${$AP*0.4725+$sph*1.35+$m1+0}', ARGENT_BLADE_FLAT, 0, 'flat')],
                   unreadable=['${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}'])


def walking_stick():
    return weapon_profile(load_fixture_class_file(TEMPLAR_CLASS_ID))


def tuning(applies_to='damage', aura=PVE_DAMAGE_DONE_PCT):
    return Modifier(spell_id=CLASS_TUNING_AURA, effect_index=0, aura=aura, percent=CLASS_TUNING_PERCENT_AT_60,
                    applies_to=applies_to, school_mask=127)


def moments(values):
    mean = sum(values) / len(values)
    return mean, math.sqrt(sum((value - mean) ** 2 for value in values) / len(values))


def steps_with(scenario, **fields):
    return [step for step in scenario['steps'] if all(step.get(key) == value for key, value in fields.items())]


def hit_expectation(expectations):
    return next(expectation for expectation in expectations
                if expectation.check in ('hit_mean', 'unmodelled') and not expectation.rule.startswith(UNREADABLE))


def measured_reference(class_file, expectation, armor=528):
    labels = expectation.model['measurements']
    measured = {**class_file['reference_stats'], labels['armor']: armor, labels['view_level']: 60,
                f'known_aura {CLASS_TUNING_AURA}': 1}
    for label in labels.values():
        if label.startswith('target resistance'):
            measured[label] = 0
    return measured


class WeaponProfileTest(unittest.TestCase):
    def test_templar_file_freezes_the_walking_stick_item_template_row(self):
        self.assertEqual(walking_stick(), WeaponProfile(item=WALKING_STICK, min_damage=WALKING_STICK_MIN,
                                                        max_damage=WALKING_STICK_MAX,
                                                        speed_ms=WALKING_STICK_DELAY_MS,
                                                        normalized_speed=TWO_HANDED_NORMALIZED_SPEED))

    def test_class_without_weapon_has_no_profile(self):
        self.assertIsNone(weapon_profile({'class_id': 0}))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_templar_one_hand_weapon_is_a_one_handed_mace_on_the_maces_skill_line(self):
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        self.assertEqual([weapon['item'] for weapon in templar['alternate_weapons']], [FROSTMANE_CLUB])
        club = templar['alternate_weapons'][0]
        self.assertEqual((club['subclass'], club['skill_line'], club['normalized_speed']),
                         (ONE_HANDED_MACE_SUBCLASS, MACES_SKILL_LINE, ONE_HANDED_NORMALIZED_SPEED))
        self.assertTrue(VINDICATION_SUBCLASS_MASK & 1 << club['subclass'])
        self.assertFalse(VINDICATION_SUBCLASS_MASK & 1 << templar['weapon']['subclass'])
        records = records_of(templar)
        mace_skill = weapon_skill_spells(records)[club['subclass']]
        self.assertEqual([ability.line for ability in records.abilities(mace_skill)], [club['skill_line']])


class ExpectedHitTest(unittest.TestCase):
    def test_argent_blade_tooltip_mean_adds_the_flat_bonus_after_the_weapon_percent(self):
        model = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(), NO_MITIGATION,
                             percent_before_flat=True)
        weapon_average = (WALKING_STICK_MIN + WALKING_STICK_MAX) / 2
        self.assertAlmostEqual(
            model.tooltip_mean,
            2.15 * (weapon_average + REFERENCE_ATTACK_POWER / 14 * TWO_HANDED_NORMALIZED_SPEED) + ARGENT_BLADE_FLAT,
            places=6)

    def test_argent_blade_mean_truncates_the_roll_the_percent_and_the_flat_bonus(self):
        model = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(), NO_MITIGATION,
                             percent_before_flat=True)
        rolls = range(80, 85)
        mean, sigma = moments([roll * 215 // 100 + 568 for roll in rolls])
        self.assertEqual((mean, sigma), (744.0, math.sqrt(8)))
        self.assertAlmostEqual(model.mean, mean, places=9)
        self.assertAlmostEqual(model.sigma, sigma, places=9)
        self.assertEqual(model.kind, 'weapon')
        self.assertEqual(model.hits_per_cast, 1)

    def test_class_tuning_and_armor_are_applied_after_the_hit_with_their_own_rounding(self):
        armor = expected_mitigation(PHYSICAL, ARMOR_528, 60)
        model = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(), armor,
                             modifiers=(tuning(),), percent_before_flat=True)
        mean, sigma = moments([541, 542, 543, 544, 546])
        self.assertAlmostEqual(model.mean, mean, places=9)
        self.assertAlmostEqual(model.sigma, sigma, places=9)
        self.assertEqual([modifier.spell_id for modifier in model.modifiers], [CLASS_TUNING_AURA])

    def test_healing_modifier_never_changes_damage(self):
        with_heal_modifier = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(),
                                          NO_MITIGATION, modifiers=(tuning('heal', HEALING_DONE_PCT),),
                                          percent_before_flat=True)
        self.assertAlmostEqual(with_heal_modifier.mean, 744.0, places=9)
        self.assertEqual(with_heal_modifier.modifiers, ())

    def test_weapon_percent_damage_applies_after_the_flat_bonus_by_default(self):
        model = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(), NO_MITIGATION)
        rolls = range(80, 85)
        mean, sigma = moments([(roll + 568) * 215 // 100 for roll in rolls])
        self.assertAlmostEqual(model.mean, mean, places=9)
        self.assertAlmostEqual(model.sigma, sigma, places=9)
        self.assertNotAlmostEqual(model.mean, 744.0, places=0)

    def test_school_damage_keeps_the_resisted_floor_of_each_partial_resist_step(self):
        readout = Readout(values=[Displayed('$s1', 336.0, 0, 'flat')], unreadable=[])
        holy = expected_mitigation(HOLY, REFERENCE_TARGET, 60)
        model = expected_hit(readout, [SCHOOL_DAMAGE, 0, 0], caster(), None, holy, modifiers=(tuning(),))
        kept = {0: 268, 1: 268 - 26, 2: 268 - 53, 3: 268 - 80}
        shares = {0: 0.20, 1: 0.45, 2: 0.30, 3: 0.05}
        mean = sum(shares[step] * kept[step] for step in kept)
        sigma = math.sqrt(sum(shares[step] * (kept[step] - mean) ** 2 for step in kept))
        self.assertAlmostEqual(model.mean, mean, places=9)
        self.assertAlmostEqual(model.sigma, sigma, places=9)
        self.assertEqual(model.tooltip_mean, 336.0)
        self.assertEqual(model.kind, 'school')

    def test_spread_school_damage_rolls_every_integer_between_the_tooltip_bounds(self):
        readout = Readout(values=[Displayed('$m1', 100.0, 0, 'flat'), Displayed('$M1', 104.0, 0, 'flat')],
                          unreadable=[])
        model = expected_hit(readout, [SCHOOL_DAMAGE, 0, 0], caster(), None, NO_MITIGATION)
        mean, sigma = moments(range(100, 105))
        self.assertAlmostEqual(model.mean, mean, places=9)
        self.assertAlmostEqual(model.sigma, sigma, places=9)

    def test_rolled_effect_spreads_the_hit_over_the_tooltip_value_of_every_roll(self):
        readout = Readout(values=[Displayed('${$m1+0}', 10.0, 0, 'flat')], unreadable=[])
        model = expected_hit(readout, [SCHOOL_DAMAGE, 0, 0], caster(), None, NO_MITIGATION,
                             rolls={0: (10.0, 11.0, 12.5)})
        mean, sigma = moments([10, 11, 12])
        self.assertAlmostEqual(model.mean, mean, places=9)
        self.assertAlmostEqual(model.sigma, sigma, places=9)
        self.assertAlmostEqual(model.tooltip_mean, (10.0 + 11.0 + 12.5) / 3, places=9)

    def test_heal_uses_the_healing_modifier_only(self):
        readout = Readout(values=[Displayed('$s1', 501.0, 0, 'flat')], unreadable=[])
        model = expected_hit(readout, [HEAL, 0, 0], caster(), None, NO_MITIGATION,
                             modifiers=(tuning(), tuning('heal', HEALING_DONE_PCT)))
        self.assertEqual((model.kind, model.mean, model.sigma), ('heal', 400.0, 0.0))
        self.assertEqual([modifier.aura for modifier in model.modifiers], [HEALING_DONE_PCT])

    def test_periodic_damage_is_a_mean_per_tick(self):
        readout = Readout(values=[Displayed('$s1', 51.0, 0, 'flat')], unreadable=[])
        model = expected_hit(readout, [APPLY_AURA, 0, 0], caster(), None, NO_MITIGATION,
                             aura_names=(PERIODIC_DAMAGE, 0, 0), ticks=5, modifiers=(tuning(),))
        self.assertEqual((model.kind, model.mean, model.hits_per_cast), ('periodic_damage', 40.0, 5))

    def test_rolled_periodic_amount_is_unmodelled_since_its_ticks_share_one_roll(self):
        readout = Readout(values=[Displayed('${$m1+0}', 10.0, 0, 'flat')], unreadable=[])
        with self.assertRaises(Unmodelled) as raised:
            expected_hit(readout, [APPLY_AURA, 0, 0], caster(), None, NO_MITIGATION,
                         aura_names=(PERIODIC_DAMAGE, 0, 0), ticks=5, rolls={0: (10.0, 11.0, 12.0)})
        self.assertIn('once per aura', raised.exception.reason)

    def test_spread_periodic_amount_is_unmodelled_since_its_ticks_share_one_roll(self):
        readout = Readout(values=[Displayed('$m1', 10.0, 0, 'flat'), Displayed('$M1', 14.0, 0, 'flat')],
                          unreadable=[])
        with self.assertRaises(Unmodelled):
            expected_hit(readout, [APPLY_AURA, 0, 0], caster(), None, NO_MITIGATION,
                         aura_names=(PERIODIC_DAMAGE, 0, 0), ticks=5)

    def test_effects_outside_every_model_are_unmodelled(self):
        cases = {
            'dummy only': (Readout([Displayed('$s1', 10.0, 0, 'flat')], []), [DUMMY, 0, 0], ()),
            'two models': (Readout([Displayed('$s1', 10.0, 0, 'flat'), Displayed('$s2', 10.0, 1, 'flat')], []),
                           [SCHOOL_DAMAGE, HEAL, 0], ()),
            'no value': (Readout([], ['$o1']), [SCHOOL_DAMAGE, 0, 0], ()),
            'percent as damage': (Readout([Displayed('$s1', 10.0, 0, 'percent')], []), [SCHOOL_DAMAGE, 0, 0], ()),
            'weapon without weapon': (argent_blade_readout(), ARGENT_BLADE_EFFECTS, None),
        }
        for name, (readout, effects, weapon) in cases.items():
            with self.subTest(name=name), self.assertRaises(Unmodelled) as raised:
                expected_hit(readout, effects, caster(), walking_stick() if weapon == () else weapon,
                             NO_MITIGATION)
            self.assertTrue(raised.exception.reason)

    def test_health_leech_is_recognised_as_its_own_kind(self):
        kind, indexes = hit_kind([HEALTH_LEECH, TRIGGER_SPELL, 0], (0, 0, 0))
        self.assertEqual((kind, indexes), ('leech', [0]))

    def test_health_leech_without_a_readable_value_still_raises(self):
        readout = Readout(values=[], unreadable=[])
        with self.assertRaises(Unmodelled) as raised:
            expected_hit(readout, [HEALTH_LEECH, 0, 0], caster(), None, NO_MITIGATION)
        self.assertIn('no readable tooltip value', raised.exception.reason)

    def test_chastise_prefers_the_token_bearing_kind(self):
        readout = Readout(values=[Displayed('${$m1+0+$sph*0.6+$AP*0.45}', 478.85, 0, 'flat')], unreadable=[])
        kind, indexes = hit_kind([SCHOOL_DAMAGE, 0, WEAPON_PERCENT_DAMAGE], (0, 0, 0), readout=readout)
        self.assertEqual((kind, indexes), ('school', [0]))

    def test_a_learned_weapon_part_is_added_to_the_school_hit_after_each_takes_the_modifiers(self):
        school = Displayed('$s1', 100.0, 0, 'flat')
        token = Displayed('$806525s1', 150.0, 0, 'percent', MARTIAL_TRAINING)
        effects = [SCHOOL_DAMAGE, 0, WEAPON_PERCENT_DAMAGE]
        part = learned_weapon_part(Readout(values=[school, token], unreadable=[]), effects, caster(),
                                   walking_stick(), MARTIAL_TRAINING)
        model = expected_hit(Readout(values=[school], unreadable=[]), effects, caster(), walking_stick(),
                             NO_MITIGATION, modifiers=[tuning()], weapon_part=part)
        bonus = REFERENCE_ATTACK_POWER / 14 * 2.5
        rolls = range(math.floor(6.5625 + bonus), math.floor(10.9375 + bonus) + 1)
        hits = [math.floor(100 * 0.8) + math.floor(math.floor(roll * 1.5) * 0.8) for roll in rolls]
        self.assertAlmostEqual(model.mean, sum(hits) / len(hits), places=9)
        self.assertEqual(model.displayed, ('$s1', '$806525s1'))

    def test_a_learned_spell_whose_weapon_percent_is_not_shown_is_unmodelled(self):
        readout = Readout(values=[Displayed('$s1', 100.0, 0, 'flat')], unreadable=[])
        with self.assertRaises(Unmodelled) as raised:
            learned_weapon_part(readout, [SCHOOL_DAMAGE, 0, WEAPON_PERCENT_DAMAGE], caster(), walking_stick(),
                                MARTIAL_TRAINING)
        self.assertIn('0 weapon percents', raised.exception.reason)

    def test_several_token_bearing_kinds_still_raises(self):
        readout = Readout(values=[Displayed('$s1', 10.0, 0, 'flat'), Displayed('$s3', 50.0, 2, 'percent')],
                          unreadable=[])
        with self.assertRaises(Unmodelled) as raised:
            hit_kind([SCHOOL_DAMAGE, 0, WEAPON_PERCENT_DAMAGE], (0, 0, 0), readout=readout)
        self.assertIn('effects of several hit models', raised.exception.reason)


class CastsNeededTest(unittest.TestCase):
    def test_half_width_of_one_percent_at_99_percent_confidence(self):
        model = HitModel(kind='school', mean=100.0, sigma=10.0, tooltip_mean=100.0)
        self.assertEqual(casts_needed(model), math.ceil((Z_99 * 10.0 / 1.0) ** 2))

    def test_ticks_per_cast_divide_the_hits_needed(self):
        model = HitModel(kind='periodic_damage', mean=100.0, sigma=10.0, tooltip_mean=100.0, hits_per_cast=4)
        self.assertEqual(casts_needed(model), math.ceil(math.ceil((Z_99 * 10.0) ** 2) / 4))

    def test_a_constant_hit_still_needs_one_cast(self):
        self.assertEqual(casts_needed(HitModel(kind='heal', mean=400.0, sigma=0.0, tooltip_mean=500.0)), 1)

    def test_scenarios_schedule_half_again_the_needed_casts_for_excluded_outcomes(self):
        for needed, scheduled in ((1, 2), (2, 3), (3, 5), (42, 63)):
            self.assertEqual(scheduled_casts(needed), math.ceil(needed * 1.5))
            self.assertEqual(scheduled_casts(needed), scheduled)

    def test_a_non_positive_mean_is_refused(self):
        with self.assertRaises(ValueError):
            casts_needed(HitModel(kind='school', mean=0.0, sigma=1.0, tooltip_mean=0.0))


class SelfStackMultiplierTest(unittest.TestCase):
    def test_no_self_stack_bonus_field_is_a_no_op(self):
        self.assertEqual(self_stack_multiplier({}, 570233, 3), 1.0)

    def test_an_unlisted_rank_is_a_no_op(self):
        class_file = {'self_stack_bonus': [{'rank': 804904, 'percent_per_stack': 5.0}]}
        self.assertEqual(self_stack_multiplier(class_file, 570233, 3), 1.0)

    def test_a_single_cast_is_unscaled_regardless_of_the_percent(self):
        class_file = {'self_stack_bonus': [{'rank': 570233, 'percent_per_stack': 5.0}]}
        self.assertEqual(self_stack_multiplier(class_file, 570233, 1), 1.0)

    def test_scales_by_the_average_pre_cast_stack_count(self):
        class_file = {'self_stack_bonus': [{'rank': 570233, 'percent_per_stack': 5.0}]}
        self.assertAlmostEqual(self_stack_multiplier(class_file, 570233, 3), 1.0 + 0.05 * (3 - 1) / 2.0)
        self.assertAlmostEqual(self_stack_multiplier(class_file, 570233, 3), 1.05)

    def test_a_wrong_percent_per_stack_moves_the_multiplier_away_from_the_correct_value(self):
        correct = {'self_stack_bonus': [{'rank': 570233, 'percent_per_stack': 5.0}]}
        seeded_defect = {'self_stack_bonus': [{'rank': 570233, 'percent_per_stack': 50.0}]}
        self.assertNotAlmostEqual(self_stack_multiplier(correct, 570233, 3),
                                  self_stack_multiplier(seeded_defect, 570233, 3))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class BaseManaStepsTest(unittest.TestCase):
    BASE = {'base_mana': {'power': 0, 'value': 1720, 'source': 'seeded'}}

    def facts(self, cost=0, percent=12, power=0):
        return types.SimpleNamespace(mana_cost=cost, mana_cost_percentage=percent, power_type=power)

    def test_a_percent_of_base_mana_cost_sets_the_recorded_base_mana(self):
        self.assertEqual(base_mana_steps(self.BASE, self.facts()),
                         [{'action': 'set_power', 'actor': 'caster', 'power': 0, 'value': 1720}])

    def test_no_recorded_base_mana_a_flat_cost_or_another_power_adds_nothing(self):
        self.assertEqual(base_mana_steps({}, self.facts()), [])
        self.assertEqual(base_mana_steps(self.BASE, self.facts(cost=50, percent=0)), [])
        self.assertEqual(base_mana_steps(self.BASE, self.facts(power=3)), [])

    def test_a_cost_above_the_recorded_base_mana_is_refused(self):
        with self.assertRaises(ValueError):
            base_mana_steps(self.BASE, self.facts(cost=100, percent=95))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_stake_cast_is_preceded_by_the_base_mana_step(self):
        witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        stake = next(spell for spell in class_spells(DBC_DIR, WITCH_HUNTER_CLASS_ID, HEADER)
                     if STAKE_RANK in spell.ranks)
        scenario, _ = hit_parts(witch_hunter, stake, 2, rank_id=STAKE_RANK)[0]
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        powered = [index for index, step in enumerate(steps)
                   if step == {'action': 'set_power', 'actor': 'caster', 'power': 0, 'value': 1720}]
        self.assertEqual(len(powered), len(casts))
        self.assertTrue(all(before < cast for before, cast in zip(powered, casts)))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class IgnoredArmorTest(unittest.TestCase):
    SEEDED_MEANS = (834.2, 830.4)
    SEEDED_HITS = 333
    TOOLTIP_MEAN = 829.85
    ARMORED_MEAN = 757.3

    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        stake = next(spell for spell in class_spells(DBC_DIR, WITCH_HUNTER_CLASS_ID, HEADER)
                     if STAKE_RANK in spell.ranks)
        cls.scenario, expectations = hit_parts(cls.witch_hunter, stake, cls.SEEDED_HITS, rank_id=STAKE_RANK)[0]
        cls.hit = hit_expectation(expectations)

    def judged(self, mean: float) -> Verdict:
        measured = measured_reference(self.witch_hunter, self.hit)
        labels = self.hit.model['measurements']
        found = Run(key='seeded', status='ok', message='',
                    values={**measured, labels['total']: mean * self.SEEDED_HITS, labels['count']: self.SEEDED_HITS},
                    steps=[], max_step_ms=None)
        base = Verdict(label=self.hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')
        return judge_hit(base, self.witch_hunter, [(self.scenario, found, self.hit)], measured_hit_model)

    def test_stake_ignores_the_reference_armor_through_its_custom_attribute(self):
        model = reference_hit_model(self.witch_hunter, STAKE_RANK)
        self.assertAlmostEqual(model.tooltip_mean, self.TOOLTIP_MEAN, places=2)
        self.assertGreater(model.mean, self.TOOLTIP_MEAN - 1)
        for mean in self.SEEDED_MEANS:
            self.assertEqual(self.judged(mean).status, 'ok', mean)

    def test_without_the_custom_attribute_the_same_reads_alert(self):
        stripped = CustomAttributes({}, {})
        with mock.patch('hits.custom_attributes', return_value=stripped):
            armored = reference_hit_model(self.witch_hunter, STAKE_RANK)
            self.assertAlmostEqual(armored.mean, self.ARMORED_MEAN, places=0)
            for mean in self.SEEDED_MEANS:
                self.assertEqual(self.judged(mean).status, 'alert', mean)

    def test_an_unreadable_table_leaves_a_physical_hit_unmodelled(self):
        with mock.patch('hits.custom_attributes', return_value=CustomAttributes({}, {}, 'seeded failure')):
            with self.assertRaises(Unmodelled):
                reference_hit_model(self.witch_hunter, STAKE_RANK)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitScenarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        cls.spells = {spell.spell_id: spell for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER)}
        cls.argent_blade = cls.spells[ARGENT_BLADE]

    def test_reference_model_of_argent_blade_uses_the_class_tuning_aura_and_the_reference_armor(self):
        model = reference_hit_model(self.templar, ARGENT_BLADE_MAX_RANK)
        self.assertAlmostEqual(model.mean, moments([541, 542, 543, 544, 546])[0], places=9)
        self.assertEqual([(modifier.spell_id, modifier.effect_index, modifier.percent)
                          for modifier in model.modifiers], [(CLASS_TUNING_AURA, 0, CLASS_TUNING_PERCENT_AT_60)])

    def test_argent_blade_rank_is_the_class_files_only_percent_before_flat_entry(self):
        self.assertIn(ARGENT_BLADE_MAX_RANK, self.templar['weapon_percent_before_flat'])

    def test_sacred_swing_applies_its_weapon_percent_after_the_flat_bonus(self):
        caster = reference_caster(self.templar)
        records = records_of(self.templar)
        weapon = weapon_profile(self.templar)
        fixed = records.field('Spell', SACRED_SWING_MAX_RANK, 'EffectBasePoints[0]') + 1
        percent = records.field('Spell', SACRED_SWING_MAX_RANK, 'EffectBasePoints[1]') + 1
        bonus = caster.ap / 14 * weapon.normalized_speed
        rolls = range(math.floor(weapon.min_damage + bonus), math.floor(weapon.max_damage + bonus) + 1)
        tuned = 100 + CLASS_TUNING_PERCENT_AT_60
        kept = expected_mitigation(PHYSICAL, REFERENCE_TARGET, 60).mean
        hits = [math.ceil(math.floor((roll + fixed) * percent / 100) * tuned // 100 * kept) for roll in rolls]
        model = reference_hit_model(self.templar, SACRED_SWING_MAX_RANK)
        self.assertNotIn(SACRED_SWING_MAX_RANK, self.templar['weapon_percent_before_flat'])
        self.assertAlmostEqual(model.mean, moments(hits)[0], places=9)

    def test_righteous_upheaval_rolls_its_die_before_the_attack_power_term(self):
        model = reference_hit_model(self.templar, RIGHTEOUS_UPHEAVAL_MAX_RANK)
        bonus = RIGHTEOUS_UPHEAVAL_AP_COEFFICIENT * REFERENCE_ATTACK_POWER
        values = [RIGHTEOUS_UPHEAVAL_BASE_POINTS + roll + bonus for roll in range(1, RIGHTEOUS_UPHEAVAL_DIE_SIDES + 1)]
        kept = expected_mitigation(PHYSICAL, REFERENCE_TARGET, 60).mean
        hits = [math.ceil((math.floor(value) * 80 // 100) * kept) for value in values]
        mean, sigma = moments(hits)
        self.assertAlmostEqual(model.tooltip_mean, sum(values) / len(values), places=6)
        self.assertAlmostEqual(model.mean, mean, places=6)
        self.assertAlmostEqual(model.sigma, sigma, places=6)

    def test_argent_blade_scenario_schedules_the_needed_casts_and_resets_cooldown_and_energy_each_time(self):
        casts = casts_needed(reference_hit_model(self.templar, ARGENT_BLADE_MAX_RANK))
        for count in (casts, 3):
            scenario, expectations = hit_scenario(self.templar, self.argent_blade, count)
            self.assertIs(run.validate(scenario), scenario)
            steps = scenario['steps']
            casts_at = [index for index, step in enumerate(steps) if step['action'] == 'cast']
            self.assertEqual(len(casts_at), math.ceil(count * 1.5))
            hit = next(expectation for expectation in expectations if expectation.model)
            self.assertEqual((hit.model['minimum_hits'], hit.model['scheduled_casts']),
                             (count, math.ceil(count * 1.5)))
            for index in casts_at:
                self.assertEqual(steps[index], {'action': 'cast', 'actor': 'caster', 'spell': ARGENT_BLADE_MAX_RANK,
                                                'target': 'dummy'})
                self.assertEqual(steps[index - 1], {'action': 'reset_cooldown', 'actor': 'caster',
                                                    'spell': ARGENT_BLADE_MAX_RANK})
                self.assertEqual(steps[index - 2], {'action': 'set_power', 'actor': 'caster', 'power': ENERGY,
                                                    'value': ARGENT_BLADE_ENERGY_COST})

    def test_every_cast_is_preceded_by_the_caster_aura_the_spell_record_requires(self):
        scenario, _ = hit_scenario(self.templar, self.spells[RIGHTEOUS_UPHEAVAL], 2)
        run.validate(scenario)
        steps = scenario['steps']
        casts_at = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts_at), 3)
        for index in casts_at:
            self.assertEqual(steps[index]['spell'], RIGHTEOUS_UPHEAVAL_MAX_RANK)
            self.assertEqual(steps[index - 1], {'action': 'set_aura', 'actor': 'caster', 'spell': OATH_CHAIN,
                                                'stacks': 1})

    def test_every_hit_measurement_excludes_critical_and_blocked_hits(self):
        scenario, expectations = hit_scenario(self.templar, self.argent_blade, 2)
        hit = next(expectation for expectation in expectations if expectation.check == 'hit_mean'
                   and not expectation.rule.startswith(UNREADABLE))
        measured = [step for step in scenario['steps']
                    if step['action'] == 'assert' and step['label'].startswith(hit.label + ' ')]
        self.assertEqual({step['label'] for step in measured}, {hit.label + ' total', hit.label + ' count'})
        for step in measured:
            self.assertIs(step['critical'], False)
            self.assertIs(step['blocked'], False)
            self.assertEqual((step['metric'] in ('spell_damage_total', 'spell_damage_count'), step['target']),
                             (True, 'dummy'))

    def test_argent_blade_expectation_stores_the_inputs_compare_needs(self):
        scenario, expectations = hit_scenario(self.templar, self.argent_blade, 1)
        hit = next(expectation for expectation in expectations if expectation.check == 'hit_mean'
                   and not expectation.rule.startswith(UNREADABLE))
        self.assertEqual((hit.spell_id, hit.rank_id), (ARGENT_BLADE, ARGENT_BLADE_MAX_RANK))
        self.assertEqual(hit.displayed, '$s2 | ${$AP*0.4725+$sph*1.35+$m1+0}')
        json.dumps(hit.model)
        self.assertEqual(hit.model['kind'], 'weapon')
        self.assertEqual(hit.model['weapon']['item'], WALKING_STICK)
        self.assertEqual([modifier['spell_id'] for modifier in hit.model['modifiers']], [CLASS_TUNING_AURA])
        labels = {step['label'] for step in scenario['steps'] if step['action'] == 'assert'}
        for label in hit.model['measurements'].values():
            self.assertIn(label, labels)
        self.assertEqual(steps_with(scenario, label=hit.model['measurements']['armor'])[0]['metric'], 'armor')
        unreadable = [expectation for expectation in expectations if expectation.rule.startswith(UNREADABLE)]
        self.assertEqual(unreadable, [])

    def test_measured_model_recomputes_with_the_armor_and_auras_of_the_run(self):
        _, expectations = hit_scenario(self.templar, self.argent_blade, 1)
        hit = next(expectation for expectation in expectations if expectation.check == 'hit_mean'
                   and not expectation.rule.startswith(UNREADABLE))
        measured = dict(self.templar['reference_stats'])
        measured.update({hit.model['measurements']['armor']: 562, hit.model['measurements']['view_level']: 60,
                         f'known_aura {CLASS_TUNING_AURA}': 1})
        self.assertAlmostEqual(measured_hit_model(self.templar, hit, measured).mean,
                               moments([538, 539, 540, 541, 543])[0], places=9)
        measured[f'known_aura {CLASS_TUNING_AURA}'] = 0
        without_aura = measured_hit_model(self.templar, hit, measured)
        self.assertAlmostEqual(without_aura.mean, moments([672, 674, 676, 677, 679])[0], places=9)
        self.assertEqual(without_aura.modifiers, ())

    def test_melee_scenario_swings_and_measures_plain_hits_only(self):
        model = reference_melee_model(self.templar)
        self.assertAlmostEqual(model.mean, moments([45, 46, 47, 48, 48])[0], places=9)
        swings = casts_needed(model)
        scenario, expectations = melee_scenario(self.templar, swings)
        self.assertIs(run.validate(scenario), scenario)
        self.assertEqual(steps_with(scenario, action='attack'), [{'action': 'attack', 'actor': 'caster',
                                                                  'target': 'dummy'}])
        self.assertTrue(steps_with(scenario, action='wait', ms=math.ceil(swings * 1.5) * WALKING_STICK_DELAY_MS))
        melee = [expectation for expectation in expectations if expectation.check == 'melee_mean']
        self.assertEqual(len(melee), 1)
        self.assertEqual(melee[0].model['minimum_hits'], swings)
        measured = [step for step in scenario['steps']
                    if step['action'] == 'assert' and step['label'].startswith(melee[0].label + ' ')]
        self.assertEqual(len(measured), 2)
        for step in measured:
            self.assertEqual((step['critical'], step['glancing'], step['blocked'], step['hand']),
                             (False, False, False, 0))

    def test_upheaval_splits_into_parts(self):
        casts = casts_needed(reference_hit_model(self.templar, RIGHTEOUS_UPHEAVAL_MAX_RANK))
        self.assertEqual(casts, RIGHTEOUS_UPHEAVAL_CASTS_NEEDED)
        parts = hit_parts(self.templar, self.spells[RIGHTEOUS_UPHEAVAL], casts)
        self.assertEqual(len(parts), 2)
        cast_counts = [len(steps_with(scenario, action='cast')) for scenario, _ in parts]
        self.assertEqual(sum(cast_counts), RIGHTEOUS_UPHEAVAL_SCHEDULED)
        hits = [hit_expectation(expectations) for _, expectations in parts]
        self.assertEqual({hit.label for hit in hits}, {f'{RIGHTEOUS_UPHEAVAL_MAX_RANK} hit_mean'})
        self.assertEqual([(hit.model['part'], hit.model['parts'], hit.model['part_casts']) for hit in hits],
                         [(0, 2, cast_counts[0]), (1, 2, cast_counts[1])])
        for scenario, _ in parts:
            self.assertIs(run.validate(scenario), scenario)
            self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)
        for hit in hits:
            self.assertEqual((hit.model['minimum_hits'], hit.model['scheduled_casts']),
                             (RIGHTEOUS_UPHEAVAL_CASTS_NEEDED, RIGHTEOUS_UPHEAVAL_SCHEDULED))
        self.assertEqual(len({scenario['name'] for scenario, _ in parts}), 2)

    def test_a_hit_that_fits_one_scenario_is_one_part(self):
        parts = hit_parts(self.templar, self.argent_blade, 3)
        self.assertEqual(len(parts), 1)
        self.assertEqual(hit_expectation(parts[0][1]).model['parts'], 1)
        self.assertEqual(hit_scenario(self.templar, self.argent_blade, 3), parts[0])

    def test_temple_guardian_shares_the_heal_token(self):
        for rank_id in (TEMPLE_GUARDIAN, TEMPLE_GUARDIAN_LIVE_RANK):
            with self.subTest(rank_id=rank_id):
                model = reference_hit_model(self.templar, rank_id)
                records = records_of(self.templar)
                caster = reference_caster(self.templar)
                readout = read_tooltip(records.dbc, rank_id, caster)
                own = next(value for value in readout.values if value.effect_index == 1)
                sides = records.field('Spell', rank_id, 'EffectDieSides[1]')
                base = records.field('Spell', rank_id, 'EffectBasePoints[1]')
                rolls = rolled_values(records, rank_id, caster, readout, [1])[1]
                self.assertEqual(len(rolls), sides)
                self.assertEqual(model.hits_per_cast, 2)
                self.assertAlmostEqual(model.tooltip_mean, sum(rolls) / len(rolls), places=6)
                self.assertEqual(model.kind, 'heal')
                self.assertEqual(records.field('Spell', rank_id, 'EffectBasePoints[2]'), base)
                self.assertEqual(records.field('Spell', rank_id, 'EffectDieSides[2]'), sides)
                self.assertTrue(own.text.startswith('${$m2'))

    def temple_guardian_spell(self):
        extras = [entry['spell'] for entry in self.templar.get('extra_spells', [])]
        spells = {spell.spell_id: spell
                 for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER, extra_spells=extras)}
        return spells[TEMPLE_GUARDIAN]

    def titanstrike_spell(self):
        extras = [entry['spell'] for entry in self.templar.get('extra_spells', [])]
        spells = {spell.spell_id: spell
                 for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER, extra_spells=extras)}
        return spells[TITANSTRIKE]

    def benediction_spell(self):
        extras = [entry['spell'] for entry in self.templar.get('extra_spells', [])]
        spells = {spell.spell_id: spell
                 for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER, extra_spells=extras)}
        return spells[BENEDICTION]

    def test_titanstrike_hit_scenario_establishes_the_35_percent_health_fixture_before_casting(self):
        scenario, expectations = hit_scenario(self.templar, self.titanstrike_spell(), 1)
        hit = hit_expectation(expectations)
        self.assertEqual(hit.rank_id, TITANSTRIKE_MAX_RANK)
        steps = scenario['steps']
        cast_index = next(index for index, step in enumerate(steps)
                          if step['action'] == 'cast' and step['spell'] == TITANSTRIKE_MAX_RANK)
        fixture_steps = [step for step in steps if step['action'] == 'set_health_pct']
        self.assertEqual(fixture_steps, [{'action': 'set_health_pct', 'actor': 'caster', 'target': 'dummy',
                                          'pct': 30}])
        fixture_index = steps.index(fixture_steps[0])
        self.assertLess(fixture_index, cast_index)
        self.assertEqual(steps[fixture_index + 1], {'action': 'wait', 'ms': 1000})

    def test_titanstrike_health_fixture_is_set_once_per_part_not_per_cast(self):
        casts = casts_needed(reference_hit_model(self.templar, TITANSTRIKE_MAX_RANK))
        parts = hit_parts(self.templar, self.titanstrike_spell(), casts)
        for scenario, _ in parts:
            self.assertEqual(len(steps_with(scenario, action='set_health_pct')), 1)
            self.assertGreater(len(steps_with(scenario, action='cast', spell=TITANSTRIKE_MAX_RANK)), 1)
            self.assertIs(run.validate(scenario), scenario)

    def test_temple_guardian_hit_scenario_places_an_ally_in_range(self):
        scenario, expectations = hit_scenario(self.templar, self.temple_guardian_spell(), 1)
        hit = hit_expectation(expectations)
        records = records_of(self.templar)
        range_min = records.field('SpellRange', 54, 'RangeMin[0]')
        range_max = records.field('SpellRange', 54, 'RangeMax[0]')
        self.assertIn({'id': ALLY}, [{'id': player.get('id')} for player in scenario['players']])
        relocates = steps_with(scenario, action='relocate', actor='caster')
        self.assertTrue(relocates)
        for step in relocates:
            self.assertEqual(step['dx'], CHARGE_OFFSET_YD)
            self.assertGreater(step['dx'], range_min)
            self.assertLess(step['dx'], range_max)
        casts = steps_with(scenario, action='cast', spell=TEMPLE_GUARDIAN_LIVE_RANK)
        self.assertTrue(casts)
        for step in casts:
            self.assertEqual(step['target'], ALLY)
        total_steps = steps_with(scenario, action='assert', label=hit.model['measurements']['total'])
        count_steps = steps_with(scenario, action='assert', label=hit.model['measurements']['count'])
        self.assertTrue(total_steps)
        self.assertTrue(count_steps)
        for step in total_steps + count_steps:
            self.assertNotIn('target', step)

    def gap_closer_expectation(self, expectations):
        return next(expectation for expectation in expectations if expectation.check == GAP_CLOSER_DISTANCE)

    def test_temple_guardian_gap_closer_distance_measures_the_caster_to_ally_distance(self):
        scenario, expectations = hit_scenario(self.templar, self.temple_guardian_spell(), 1)
        gap = self.gap_closer_expectation(expectations)
        self.assertEqual((gap.spell_id, gap.rank_id, gap.displayed), (TEMPLE_GUARDIAN, TEMPLE_GUARDIAN_LIVE_RANK,
                                                                      str(NOMINAL_MELEE_RANGE_YD)))
        gap_steps = steps_with(scenario, action='assert', label=gap.label)
        self.assertEqual(len(gap_steps), 1)
        self.assertEqual((gap_steps[0]['metric'], gap_steps[0]['target']), ('distance_2d', ALLY))

    def test_divine_force_gap_closer_distance_relocates_the_caster_away_from_the_dummy(self):
        scenario, expectations = hit_scenario(self.templar, self.spells[DIVINE_FORCE], 1)
        gap = self.gap_closer_expectation(expectations)
        self.assertEqual((gap.spell_id, gap.rank_id), (DIVINE_FORCE, DIVINE_FORCE_MAX_RANK))
        records = records_of(self.templar)
        range_max = records.field('SpellRange', 11, 'RangeMax[0]')
        relocates = steps_with(scenario, action='relocate', actor='caster')
        self.assertTrue(relocates)
        for step in relocates:
            self.assertEqual(step['dx'], CHARGE_OFFSET_YD)
            self.assertLess(step['dx'] + DUMMY_DISTANCE, range_max)
        gap_steps = steps_with(scenario, action='assert', label=gap.label)
        self.assertEqual(len(gap_steps), 1)
        self.assertEqual((gap_steps[0]['metric'], gap_steps[0]['target']), ('distance_2d', TARGET))
        self.assertTrue(scenario.get('creatures'))

    def test_silverhand_incantation_closes_distance_although_its_hit_mean_is_unmodelled(self):
        scenario, expectations = hit_scenario(self.templar, self.spells[SILVERHAND_INCANTATION], 1)
        hit = hit_expectation(expectations)
        self.assertEqual(hit.check, 'unmodelled')
        gap = self.gap_closer_expectation(expectations)
        self.assertEqual((gap.spell_id, gap.rank_id), (SILVERHAND_INCANTATION, SILVERHAND_INCANTATION))
        casts = steps_with(scenario, action='cast', spell=SILVERHAND_INCANTATION)
        self.assertEqual(len(casts), 1)
        self.assertEqual(casts[0]['target'], ALLY)
        self.assertTrue(steps_with(scenario, action='relocate', actor='caster', dx=CHARGE_OFFSET_YD))
        gap_steps = steps_with(scenario, action='assert', label=gap.label)
        self.assertEqual(len(gap_steps), 1)
        self.assertEqual((gap_steps[0]['metric'], gap_steps[0]['target']), ('distance_2d', ALLY))
        self.assertIn({'id': ALLY}, [{'id': player.get('id')} for player in scenario['players']])

    def test_temple_guardian_hit_mean_alerts_if_only_the_self_heal_is_counted(self):
        scenario, expectations = hit_scenario(self.templar, self.temple_guardian_spell(), 1)
        hit = hit_expectation(expectations)
        measured = {**self.templar['reference_stats'], f'known_aura {CLASS_TUNING_AURA}': 1}
        model = measured_hit_model(self.templar, hit, measured)
        labels = hit.model['measurements']
        count = hit.model['minimum_hits']
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')
        full_run = Run(key='full', status='ok', message='',
                       values={**measured, labels['total']: model.mean * count, labels['count']: count},
                       steps=[], max_step_ms=None)
        half_run = Run(key='half', status='ok', message='',
                       values={**measured, labels['total']: model.mean * count / 2, labels['count']: count},
                       steps=[], max_step_ms=None)
        ok_verdict = judge_hit(base, self.templar, [(scenario, full_run, hit)], measured_hit_model)
        self.assertEqual(ok_verdict.status, 'ok')
        alert_verdict = judge_hit(base, self.templar, [(scenario, half_run, hit)], measured_hit_model)
        self.assertEqual(alert_verdict.status, 'alert')
        self.assertIn('usable hits', alert_verdict.explanation)

    def test_chastise_with_martial_training_learns_it_and_alerts_without_its_weapon_part(self):
        chastise = ClassSpell(CHASTISE_MAX_RANK, 'Chastise', (CHASTISE_MAX_RANK,), CHASTISE_MAX_RANK, 0, False)
        label = f'{CHASTISE_MAX_RANK} hit_mean weapon_damage'
        (scenario, expectations), = hit_parts(self.templar, chastise, 1, rank_id=CHASTISE_MAX_RANK, label=label,
                                              learned=MARTIAL_TRAINING)
        (_, plain_expectations), = hit_parts(self.templar, chastise, 1, rank_id=CHASTISE_MAX_RANK)
        hit, plain = hit_expectation(expectations), hit_expectation(plain_expectations)
        self.assertEqual(steps_with(scenario, action='learn', spell=MARTIAL_TRAINING)[0]['actor'], 'caster')
        self.assertEqual((hit.model['learned'], hit.model['weapon']['item']), (MARTIAL_TRAINING, 2495))
        self.assertNotIn('learned', plain.model)
        measured = measured_reference(self.templar, hit)
        learned_model = measured_hit_model(self.templar, hit, measured)
        plain_model = measured_hit_model(self.templar, plain, measured_reference(self.templar, plain))
        self.assertGreater(learned_model.mean - plain_model.mean, 60)
        labels = hit.model['measurements']
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')
        count = 1000
        for mean, status in ((learned_model.mean, 'ok'), (plain_model.mean, 'alert'),
                             (plain_model.mean + 2 / 3 * (learned_model.mean - plain_model.mean), 'alert')):
            with self.subTest(mean=mean):
                found = Run(key='learned', status='ok', message='',
                            values={**measured, labels['total']: mean * count, labels['count']: count},
                            steps=[], max_step_ms=None)
                self.assertEqual(judge_hit(base, self.templar, [(scenario, found, hit)], measured_hit_model).status,
                                 status)

    def test_effect_hit_mixes_instead_of_summing_several_indexes(self):
        readout = Readout(values=[Displayed('$m1', 100.0, 0, 'flat'), Displayed('$m2', 200.0, 1, 'flat')],
                          unreadable=[])
        distribution, tooltip_mean, _ = effect_hit(readout, [0, 1], {})
        mean = sum(value * share for value, share in distribution.items())
        self.assertAlmostEqual(mean, 150.0, places=6)
        self.assertAlmostEqual(tooltip_mean, 150.0, places=6)

    def test_temple_guardian_hit_mean_insufficient_when_only_one_receiver_is_measured(self):
        scenario, expectations = hit_scenario(self.templar, self.temple_guardian_spell(), 1)
        hit = hit_expectation(expectations)
        self.assertEqual(hit.model['hits_per_cast'], 2)
        measured = {**self.templar['reference_stats'], f'known_aura {CLASS_TUNING_AURA}': 1}
        model = measured_hit_model(self.templar, hit, measured)
        labels = hit.model['measurements']
        minimum = hit.model['minimum_hits']
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')
        one_receiver_only = Run(key='one-receiver', status='ok', message='',
                                values={**measured, labels['total']: model.mean * (minimum // 2),
                                        labels['count']: minimum // 2},
                                steps=[], max_step_ms=None)
        verdict = judge_hit(base, self.templar, [(scenario, one_receiver_only, hit)], measured_hit_model)
        self.assertEqual(verdict.status, 'insufficient_trials')

    def test_temple_guardian_dual_target_entry_adds_a_caster_filtered_secondary_hit(self):
        entry = dual_target_entry(self.templar, TEMPLE_GUARDIAN_LIVE_RANK)
        self.assertEqual({key: value for key, value in entry.items() if key != 'reason'},
                         {'spell': TEMPLE_GUARDIAN_LIVE_RANK, 'primary_effect': 1, 'secondary_effect': 2,
                          'secondary_actor': 'caster'})
        scenario, expectations = hit_scenario(self.templar, self.temple_guardian_spell(), 1)
        primary = hit_expectation(expectations)
        secondary = next(expectation for expectation in expectations
                         if expectation.check == 'hit_mean' and expectation is not primary)
        self.assertEqual(secondary.label, f'{primary.label} e2')
        self.assertEqual(secondary.effect_index, 2)
        self.assertEqual(secondary.displayed, primary.displayed)
        self.assertEqual(secondary.model['minimum_hits'], primary.model['minimum_hits'] // 2)
        total_label = secondary.model['measurements']['total']
        count_label = secondary.model['measurements']['count']
        total_steps = steps_with(scenario, action='assert', label=total_label)
        count_steps = steps_with(scenario, action='assert', label=count_label)
        self.assertTrue(total_steps)
        self.assertTrue(count_steps)
        for step in total_steps + count_steps:
            self.assertEqual(step['target'], 'caster')
            self.assertIs(step['critical'], False)

    def test_temple_guardian_caster_heal_alerts_if_the_caster_never_receives_it(self):
        scenario, expectations = hit_scenario(self.templar, self.temple_guardian_spell(), 1)
        primary = hit_expectation(expectations)
        secondary = next(expectation for expectation in expectations
                         if expectation.check == 'hit_mean' and expectation is not primary)
        measured = {**self.templar['reference_stats'], f'known_aura {CLASS_TUNING_AURA}': 1}
        model = measured_hit_model(self.templar, secondary, measured)
        labels = secondary.model['measurements']
        minimum = secondary.model['minimum_hits']
        base = Verdict(label=secondary.label, status='unmeasured', measured=None, expected=None, low=None,
                       high=None, explanation='')
        caster_healed = Run(key='caster-healed', status='ok', message='',
                            values={**measured, labels['total']: model.mean * minimum, labels['count']: minimum},
                            steps=[], max_step_ms=None)
        caster_never_healed = Run(key='caster-never-healed', status='ok', message='',
                                  values={**measured, labels['total']: 0.0, labels['count']: 0.0},
                                  steps=[], max_step_ms=None)
        ok_verdict = judge_hit(base, self.templar, [(scenario, caster_healed, secondary)], measured_hit_model)
        self.assertEqual(ok_verdict.status, 'ok')
        alert_verdict = judge_hit(base, self.templar, [(scenario, caster_never_healed, secondary)],
                                  measured_hit_model)
        self.assertEqual(alert_verdict.status, 'insufficient_trials')

    def chastise_spell(self):
        return ClassSpell(CHASTISE_MAX_RANK, 'Chastise', (CHASTISE_MAX_RANK,), CHASTISE_MAX_RANK, 0, False)

    def test_templars_might_gate_sets_the_casters_condemn_at_its_stack_cap_before_every_measured_hit(self):
        entry = next(entry for entry in self.templar['target_aura_gates'] if entry['spell'] == TEMPLARS_MIGHT)
        self.assertEqual({key: value for key, value in entry.items() if key != 'reason'},
                         {'spell': TEMPLARS_MIGHT, 'name': "Templar's Might", 'rank': CHASTISE_MAX_RANK,
                          'gate_spell': CONDEMN_LIVE_RANK, 'percent': 18.0, 'label_suffix': 'condemn_gate',
                          'stack_arms': [0, 1], 'quote': 'on enemies affected by your Condemn'})
        parts = hit_parts(self.templar, self.chastise_spell(), 3, rank_id=CHASTISE_MAX_RANK, label='gate test',
                          gate=(entry['gate_spell'], entry['percent'], entry['spell']))
        scenario, expectations = parts[0]
        self.assertTrue(steps_with(scenario, action='learn', spell=TEMPLARS_MIGHT))
        gate = {'action': 'set_aura', 'target': 'dummy', 'caster': 'caster', 'spell': CONDEMN_LIVE_RANK}
        rank_casts = steps_with(scenario, action='cast', spell=CHASTISE_MAX_RANK, target='dummy')
        self.assertTrue(rank_casts)
        self.assertEqual(len(steps_with(scenario, **gate, stacks=0)), len(rank_casts))
        self.assertEqual(len(steps_with(scenario, **gate, stacks=3)), len(rank_casts))
        setup = steps_with(scenario, action='assert', actor='dummy', metric='aura_stacks', spell=CONDEMN_LIVE_RANK,
                           caster='caster')
        self.assertEqual(len(setup), len(rank_casts))
        self.assertEqual({(step['min'], step['max']) for step in setup}, {(3, 3)})
        hit = hit_expectation(expectations)
        self.assertEqual(hit.model['gate_multiplier'], 1.18)

    def gate_arm(self, held: int, percent: float):
        entry = next(entry for entry in self.templar['target_aura_gates'] if entry['spell'] == TEMPLARS_MIGHT)
        casts = casts_needed(reference_hit_model(self.templar, CHASTISE_MAX_RANK))
        return hit_parts(self.templar, self.chastise_spell(), casts, rank_id=CHASTISE_MAX_RANK, label='gate arm',
                         gate=(entry['gate_spell'], percent, entry['spell']), gate_held=held)[0]

    def test_templars_might_gate_arms_are_the_cap_then_zero_and_one_stack_at_six_percent_per_stack(self):
        entry = next(entry for entry in self.templar['target_aura_gates'] if entry['spell'] == TEMPLARS_MIGHT)
        self.assertEqual(target_gate_arms(entry, 3), [(3, 18.0, ''), (0, 0.0, 'stacks 0'), (1, 6.0, 'stacks 1')])
        with self.assertRaises(ValueError):
            target_gate_arms({**entry, 'stack_arms': [3]}, 3)

    def test_templars_might_zero_stack_arm_holds_the_talent_and_no_condemn_on_the_target(self):
        scenario, expectations = self.gate_arm(0, 0.0)
        self.assertTrue(steps_with(scenario, action='learn', spell=TEMPLARS_MIGHT))
        gate = {'action': 'set_aura', 'target': 'dummy', 'caster': 'caster', 'spell': CONDEMN_LIVE_RANK}
        rank_casts = steps_with(scenario, action='cast', spell=CHASTISE_MAX_RANK, target='dummy')
        self.assertEqual(len(steps_with(scenario, **gate, stacks=0)), len(rank_casts))
        self.assertEqual(len(steps_with(scenario, action='set_aura', spell=CONDEMN_LIVE_RANK)), len(rank_casts))
        setup = steps_with(scenario, action='assert', metric='aura_stacks', spell=CONDEMN_LIVE_RANK)
        self.assertEqual({(step['min'], step['max']) for step in setup}, {(0, 0)})
        self.assertEqual(hit_expectation(expectations).model['gate_multiplier'], 1.0)

    def test_templars_might_one_stack_arm_judges_a_flat_cap_bonus_as_alert(self):
        scenario, expectations = self.gate_arm(1, 6.0)
        setup = steps_with(scenario, action='assert', metric='aura_stacks', spell=CONDEMN_LIVE_RANK)
        self.assertEqual({(step['min'], step['max']) for step in setup}, {(1, 1)})
        hit = hit_expectation(expectations)
        self.assertEqual(hit.model['gate_multiplier'], 1.06)
        measured = measured_reference(self.templar, hit)
        labels = hit.model['measurements']
        minimum = hit.model['minimum_hits']
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')

        def run_at(multiplier: float) -> Run:
            model = measured_hit_model(self.templar, replace(hit, model={**hit.model, 'gate_multiplier': multiplier}),
                                       measured)
            return Run(key=f'x{multiplier}', status='ok', message='',
                       values={**measured, labels['total']: model.mean * minimum, labels['count']: minimum},
                       steps=[], max_step_ms=None)
        self.assertEqual(judge_hit(base, self.templar, [(scenario, run_at(1.06), hit)], measured_hit_model).status,
                         'ok')
        self.assertEqual(judge_hit(base, self.templar, [(scenario, run_at(1.18), hit)], measured_hit_model).status,
                         'alert')

    def test_templars_might_gate_never_casts_condemn_the_caster_has_not_learned(self):
        entry = next(entry for entry in self.templar['target_aura_gates'] if entry['spell'] == TEMPLARS_MIGHT)
        scenario, _ = hit_parts(self.templar, self.chastise_spell(), 3, rank_id=CHASTISE_MAX_RANK, label='gate test',
                                gate=(entry['gate_spell'], entry['percent'], entry['spell']))[0]
        self.assertFalse(steps_with(scenario, action='learn', spell=CONDEMN_LIVE_RANK))
        self.assertFalse(steps_with(scenario, action='cast', spell=CONDEMN_LIVE_RANK))

    def test_templars_might_gate_judges_the_unscaled_measured_mean_as_alert(self):
        entry = next(entry for entry in self.templar['target_aura_gates'] if entry['spell'] == TEMPLARS_MIGHT)
        casts = 3
        scenario, expectations = hit_parts(self.templar, self.chastise_spell(), casts, rank_id=CHASTISE_MAX_RANK,
                                           label='gate test', gate=(entry['gate_spell'], entry['percent'],
                                                                    entry['spell']))[0]
        hit = hit_expectation(expectations)
        measured = measured_reference(self.templar, hit)
        scaled_model = measured_hit_model(self.templar, hit, measured)
        labels = hit.model['measurements']
        minimum = hit.model['minimum_hits']
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')
        correctly_gated = Run(key='gated', status='ok', message='',
                              values={**measured, labels['total']: scaled_model.mean * minimum,
                                      labels['count']: minimum},
                              steps=[], max_step_ms=None)
        ok_verdict = judge_hit(base, self.templar, [(scenario, correctly_gated, hit)], measured_hit_model)
        self.assertEqual(ok_verdict.status, 'ok')
        unscaled_hit = replace(hit, model={**hit.model, 'gate_multiplier': 1.0})
        unscaled_model = measured_hit_model(self.templar, unscaled_hit, measured)
        no_bonus_applied = Run(key='no-bonus', status='ok', message='',
                               values={**measured, labels['total']: unscaled_model.mean * minimum,
                                       labels['count']: minimum},
                               steps=[], max_step_ms=None)
        alert_verdict = judge_hit(base, self.templar, [(scenario, no_bonus_applied, hit)], measured_hit_model)
        self.assertEqual(alert_verdict.status, 'alert')

    def test_benediction_hit_scenario_does_not_relocate_the_caster(self):
        scenario, expectations = hit_scenario(self.templar, self.benediction_spell(), 1)
        hit = hit_expectation(expectations)
        self.assertEqual(hit.rank_id, BENEDICTION_MAX_RANK)
        self.assertFalse(steps_with(scenario, action='relocate', actor='caster'))

    def test_divine_force_is_modelled(self):
        scenario, expectations = hit_scenario(self.templar, self.spells[DIVINE_FORCE], 1)
        hit = hit_expectation(expectations)
        self.assertEqual((hit.check, hit.rank_id, hit.effect_index, hit.model['kind']),
                         ('hit_mean', DIVINE_FORCE_MAX_RANK, 2, 'school'))
        self.assertTrue(steps_with(scenario, action='set_skill', skill=DIVINE_FORCE_SKILL_LINE))
        self.assertTrue(steps_with(scenario, label=f'skill {DIVINE_FORCE_SKILL_LINE}', metric='skill_value'))
        measured = measured_reference(self.templar, hit)
        self.assertEqual(measured_hit_model(self.templar, hit, measured).kind, 'school')
        del measured[f'skill {DIVINE_FORCE_SKILL_LINE}']
        with self.assertRaises(Unmodelled):
            measured_hit_model(self.templar, hit, measured)

    def test_reckoning_is_modelled(self):
        caster = reference_caster(self.templar)
        records = records_of(self.templar)
        readout = read_tooltip(records.dbc, RECKONING_MAX_RANK, caster)
        bonus = 0.175 * REFERENCE_ATTACK_POWER + 0.5 * REFERENCE_STAMINA
        values = [RECKONING_BASE_POINTS + roll + bonus for roll in range(1, RECKONING_DIE_SIDES + 1)]
        rolls = rolled_values(records, RECKONING_MAX_RANK, caster, readout, [0])
        self.assertEqual(len(rolls[0]), RECKONING_DIE_SIDES)
        for value, expected in zip(rolls[0], values):
            self.assertAlmostEqual(value, expected, places=6)
        model = reference_hit_model(self.templar, RECKONING_MAX_RANK)
        self.assertEqual(model.kind, 'school')
        self.assertAlmostEqual(model.tooltip_mean, sum(values) / len(values), places=6)
        self.assertEqual(casts_needed(model), RECKONING_CASTS_NEEDED)
        parts = hit_parts(self.templar, self.spells[RECKONING], RECKONING_CASTS_NEEDED)
        self.assertEqual(len(parts), RECKONING_PARTS)
        self.assertEqual(sum(len(steps_with(scenario, action='cast')) for scenario, _ in parts),
                         scheduled_casts(RECKONING_CASTS_NEEDED))
        for scenario, expectations in parts:
            self.assertEqual(hit_expectation(expectations).check, 'hit_mean')
            self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)

    def test_a_rank_hit_with_a_truncated_per_level_term_is_ok_only_around_the_engine_mean(self):
        model = reference_hit_model(self.templar, RECKONING_MAX_RANK)
        self.assertIsNotNone(model.engine)
        self.assertIn('effect 0 loses 0.5072', model.engine_rule)
        self.assertLess(model.engine.mean, model.mean)
        self.assertGreater(model.engine.mean, model.mean - 1)
        scenario, expectations = hit_parts(self.templar, self.spells[RECKONING], RECKONING_CASTS_NEEDED)[0]
        hit = hit_expectation(expectations)
        measured = measured_reference(self.templar, hit)
        judged = measured_hit_model(self.templar, hit, measured)
        labels, count = hit.model['measurements'], 40000
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')

        def verdict(mean):
            found = Run(key='seeded', status='ok', message='', steps=[], max_step_ms=None,
                        values={**measured, labels['total']: mean * count, labels['count']: count})
            return judge_hit(base, self.templar, [(scenario, found, hit)], measured_hit_model)

        engine = verdict(judged.engine.mean)
        self.assertEqual(engine.status, 'ok')
        self.assertIn('inside the engine model mean', engine.explanation)
        self.assertEqual(engine.detail[PER_LEVEL_ROUNDING]['engine_mean'], judged.engine.mean)
        mutant = verdict(judged.engine.mean - 0.06 * judged.mean)
        self.assertEqual(mutant.status, 'alert')
        self.assertIn('does not explain it either', mutant.explanation)
        self.assertEqual(mutant.detail[PER_LEVEL_ROUNDING]['rule'], model.engine_rule)

    def test_a_listed_block_value_raises_the_rank_hit_and_is_read_in_its_scenarios(self):
        listed = {**self.templar, BLOCK_VALUE_TERMS: [{'spell': RECKONING, 'effect': 0, 'source': 'seeded code term'}]}
        block_read = measurement(BLOCK_VALUE_LABEL, CASTER, BLOCK_VALUE_LABEL)
        parts = hit_parts(listed, self.spells[RECKONING], RECKONING_CASTS_NEEDED)
        self.assertTrue(all(block_read in scenario['steps'] for scenario, _ in parts))
        self.assertTrue(all(block_read not in scenario['steps']
                            for scenario, _ in hit_parts(self.templar, self.spells[RECKONING], RECKONING_CASTS_NEEDED)))
        value, _, _ = value_scenario(listed, self.spells[RECKONING], RECKONING_MAX_RANK)
        self.assertIn(block_read, value['steps'])
        scenario, expectations = parts[0]
        hit = hit_expectation(expectations)
        measured = measured_reference(listed, hit)
        with self.assertRaises(KeyError):
            measured_hit_model(listed, hit, measured)
        blocked = {**measured, BLOCK_VALUE_LABEL: 40}
        raised = measured_hit_model(listed, hit, blocked)
        plain = measured_hit_model(self.templar, hit, measured)
        self.assertGreater(raised.mean, plain.mean * 1.1)
        labels, count = hit.model['measurements'], 40000
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')

        def verdict(mean):
            found = Run(key='seeded', status='ok', message='', steps=[], max_step_ms=None,
                        values={**blocked, labels['total']: mean * count, labels['count']: count})
            return judge_hit(base, listed, [(scenario, found, hit)], measured_hit_model)

        self.assertEqual(verdict(raised.mean).status, 'ok')
        self.assertEqual(verdict(plain.mean).status, 'alert')

    def test_a_listed_heal_pct_term_adds_the_read_percent_of_maximum_health_under_the_heal_modifiers(self):
        solar = ClassSpell(SOLAR_PRAYER, 'Solar Prayer', (SOLAR_PRAYER,), SOLAR_PRAYER, 0, False)
        listed = {**self.templar, HEAL_PCT_TERMS: [{'spell': SOLAR_PRAYER, 'effect': 0, 'source': 'seeded code term'}]}
        read = measurement(HEAL_PCT_LABEL, CASTER, 'max_health')
        parts = hit_parts(listed, solar, 1)
        self.assertTrue(all(read in scenario['steps'] for scenario, _ in parts))
        self.assertTrue(all(read not in scenario['steps'] for scenario, _ in hit_parts(self.templar, solar, 1)))
        scenario, expectations = parts[0]
        hit = hit_expectation(expectations)
        self.assertEqual((hit.model['kind'], hit.model['measurements']['max_health']), ('heal', HEAL_PCT_LABEL))
        self.assertIn('25% of the healed unit', hit.rule)
        measured = {**self.templar['reference_stats'], f'known_aura {CLASS_TUNING_AURA}': 1}
        with self.assertRaises(KeyError):
            measured_hit_model(listed, hit, measured)
        healthy = {**measured, HEAL_PCT_LABEL: SOLAR_PRAYER_MAX_HEALTH}
        raised = measured_hit_model(listed, hit, healthy)
        plain = measured_hit_model(self.templar, hit, measured)
        factor = math.prod(Fraction(100 + modifier.percent, 100) for modifier in raised.modifiers)
        self.assertEqual(raised.mean - plain.mean, math.floor(447 * factor))
        self.assertEqual((raised.sigma, raised.displayed), (plain.sigma, plain.displayed))
        labels, count = hit.model['measurements'], 40
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')

        def verdict(mean):
            found = Run(key='seeded', status='ok', message='', steps=[], max_step_ms=None,
                        values={**healthy, labels['total']: mean * count, labels['count']: count})
            return judge_hit(base, listed, [(scenario, found, hit)], measured_hit_model)

        self.assertEqual(verdict(raised.mean).status, 'ok')
        self.assertEqual(verdict(plain.mean).status, 'alert')

    def test_the_heal_pct_term_truncates_like_count_pct_from_max_health_and_needs_its_effect(self):
        records = records_of(self.templar)
        self.assertEqual(heal_pct_percent(records, SOLAR_PRAYER, 0), 25)
        self.assertEqual([heal_pct_amount(health, 25) for health in (1788, 1791, 1792)], [447, 447, 448])
        with self.assertRaises(ValueError):
            heal_pct_percent(records, SOLAR_PRAYER, 1)

    def test_vindication_equips_the_one_hand_weapon(self):
        scenario, expectations = hit_scenario(self.templar, self.spells[VINDICATION], 1)
        run.validate(scenario)
        self.assertEqual(steps_with(scenario, action='equip'),
                         [{'action': 'equip', 'actor': 'caster', 'item': FROSTMANE_CLUB, 'slot': 15}])
        self.assertEqual([step['item'] for step in steps_with(scenario, action='add_item')], [FROSTMANE_CLUB])
        self.assertTrue(steps_with(scenario, action='set_skill', skill=MACES_SKILL_LINE))
        hit = hit_expectation(expectations)
        self.assertEqual((hit.check, hit.rank_id, hit.model['kind']), ('hit_mean', VINDICATION_MAX_RANK, 'school'))
        self.assertIn(f'reference weapon {FROSTMANE_CLUB}', hit.rule)
        measured = {**measured_reference(self.templar, hit), f'skill {MACES_SKILL_LINE}': 300}
        self.assertAlmostEqual(measured_hit_model(self.templar, hit, measured).mean,
                               reference_hit_model(self.templar, VINDICATION_MAX_RANK).mean, places=9)

    def test_vindication_without_a_fitting_weapon_is_unmodelled(self):
        staff_only = {key: value for key, value in self.templar.items() if key != 'alternate_weapons'}
        scenario, expectations = hit_scenario(staff_only, self.spells[VINDICATION], 1)
        self.assertEqual([(expectation.check, expectation.rule) for expectation in expectations],
                         [('unmodelled', f'unmodelled: EquippedItemSubClassMask {VINDICATION_SUBCLASS_MASK} excludes '
                                         f'the reference weapon subclass {STAFF_SUBCLASS}')])

    def test_periodic_total_is_divided_into_ticks(self):
        readout = read_tooltip(records_of(self.templar).dbc, BLADE_OF_FAITH_MAX_RANK, reference_caster(self.templar))
        total, = [value for value in readout.values if value.text == BLADE_OF_FAITH_TOTAL]
        model = reference_hit_model(self.templar, BLADE_OF_FAITH_MAX_RANK)
        self.assertEqual((model.kind, model.hits_per_cast), ('periodic_damage', 10))
        self.assertAlmostEqual(model.tooltip_mean, total.value * BLADE_OF_FAITH_PERIOD_MS / BLADE_OF_FAITH_DURATION_MS,
                               places=9)
        self.assertEqual(model.displayed, (BLADE_OF_FAITH_TOTAL,))
        scenario, expectations = hit_scenario(self.templar, self.spells[BLADE_OF_FAITH], 1)
        run.validate(scenario)
        hit = hit_expectation(expectations)
        self.assertEqual((hit.check, hit.effect_index, hit.model['kind']), ('hit_mean', 0, 'periodic_damage'))
        self.assertTrue(steps_with(scenario, metric='spell_damage_total', spell=BLADE_OF_FAITH_MAX_RANK))

    def test_periodic_total_check_is_measured_on_a_non_max_rank(self):
        label = f'{BLADE_OF_FAITH} effect_value #0'
        parts = hit_parts(self.templar, self.spells[BLADE_OF_FAITH], 1, rank_id=BLADE_OF_FAITH, label=label,
                          check='periodic_total')
        scenario, expectations = parts[0]
        run.validate(scenario)
        hit = next(expectation for expectation in expectations if expectation.check == 'periodic_total')
        self.assertEqual((hit.check, hit.label, hit.rank_id), ('periodic_total', label, BLADE_OF_FAITH))
        self.assertTrue(steps_with(scenario, metric='spell_damage_total', spell=BLADE_OF_FAITH, critical=False))
        self.assertTrue(steps_with(scenario, metric='spell_damage_count', spell=BLADE_OF_FAITH, critical=False))

    def test_a_periodic_token_that_is_neither_a_total_nor_one_tick_is_unmodelled(self):
        readout = Readout(values=[Displayed('${($d*1000/$T1)+1}', 11, 0, 'flat', BLADE_OF_FAITH_MAX_RANK)],
                          unreadable=[])
        with self.assertRaises(Unmodelled):
            periodic_tick_readout(records_of(self.templar), BLADE_OF_FAITH_MAX_RANK, reference_caster(self.templar),
                                  readout, 0)

    def test_righteous_tempest_model(self):
        caster = reference_caster(self.templar)
        weapon = walking_stick()
        bonus = caster.ap / 14 * TWO_HANDED_NORMALIZED_SPEED
        model = reference_hit_model(self.templar, RIGHTEOUS_TEMPEST_MAX_RANK)
        self.assertEqual((model.kind, model.hits_per_cast), ('triggered_weapon', RIGHTEOUS_TEMPEST_TICKS))
        self.assertAlmostEqual(model.tooltip_mean,
                               (weapon.min_damage + weapon.max_damage) / 2 + bonus + RIGHTEOUS_TEMPEST_STRIKE_FLAT,
                               places=9)
        self.assertEqual(model.displayed, ('$570205s2', '${$570205m1+$SP*0.3}'))
        rolls = range(math.floor(weapon.min_damage + bonus), math.floor(weapon.max_damage + bonus) + 1)
        kept = expected_mitigation(PHYSICAL, REFERENCE_TARGET, 60).mean
        tuned = 100 + CLASS_TUNING_PERCENT_AT_60
        hits = [math.ceil((roll + RIGHTEOUS_TEMPEST_STRIKE_FLAT) * tuned // 100 * kept) for roll in rolls]
        self.assertAlmostEqual(model.mean, moments(hits)[0], places=9)
        scenario, expectations = hit_scenario(self.templar, self.spells[RIGHTEOUS_TEMPEST], 1)
        run.validate(scenario)
        hit = hit_expectation(expectations)
        self.assertEqual((hit.check, hit.rank_id, hit.effect_index), ('hit_mean', RIGHTEOUS_TEMPEST_MAX_RANK, 0))
        self.assertEqual((hit.model['kind'], hit.model['hit_spell']), ('triggered_weapon', RIGHTEOUS_TEMPEST_STRIKE))
        self.assertIn('ADR 0010', hit.rule)
        for metric in ('spell_damage_total', 'spell_damage_count'):
            self.assertTrue(steps_with(scenario, metric=metric, spell=RIGHTEOUS_TEMPEST_STRIKE, critical=False))
            self.assertFalse(steps_with(scenario, metric=metric, spell=RIGHTEOUS_TEMPEST_MAX_RANK))
        self.assertTrue(steps_with(scenario, metric='spell_cast_count', spell=RIGHTEOUS_TEMPEST_MAX_RANK))
        self.assertEqual(hit.model['minimum_hits'], RIGHTEOUS_TEMPEST_TICKS)
        self.assertAlmostEqual(measured_hit_model(self.templar, hit, measured_reference(self.templar, hit)).mean,
                               model.mean, places=9)

    def test_every_templar_max_rank_has_a_valid_scenario_and_a_hit_or_unmodelled_expectation(self):
        checks = {}
        for spell in self.spells.values():
            with self.subTest(spell=spell.spell_id):
                scenario, expectations = hit_scenario(self.templar, spell, 1)
                run.validate(scenario)
                self.assertTrue(expectations)
                self.assertTrue({expectation.check for expectation in expectations} <= set(HIT_CHECKS))
                labels = {step['label'] for step in scenario['steps'] if step['action'] == 'assert'}
                for expectation in expectations:
                    if expectation.check == 'unmodelled':
                        self.assertTrue(expectation.rule.startswith((UNMODELLED, CLOSED)))
                    elif expectation.check == GAP_CLOSER_DISTANCE:
                        self.assertIn(expectation.label, labels)
                    elif not expectation.rule.startswith(UNREADABLE):
                        self.assertIn(expectation.label + ' total', labels)
                        self.assertIn(expectation.label + ' count', labels)
                    checks[expectation.check] = checks.get(expectation.check, 0) + 1
        self.assertTrue(checks.get('hit_mean'))
        self.assertTrue(checks.get('unmodelled'))
        self.assertTrue(checks.get(GAP_CLOSER_DISTANCE))


DISCIPLINED_BLOWS = 680397
DISCIPLINED_BLOWS_PULSE = 680398
ARMOR_OF_FAITH = 804930
ARMOR_OF_FAITH_HIT = 801546


def script_hit_entry(class_file, spell):
    return next(entry for entry in class_file['behaviours']
                if entry['spell'] == spell and entry['kind'] == 'script_hit')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ScriptHitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.templar = load_fixture_class_file(TEMPLAR_CLASS_ID)

    def scripted(self, spell):
        scenario, expectations = behaviour_scenario(self.templar, script_hit_entry(self.templar, spell))
        return run.validate(scenario, run.SIMULATED_CLOCK), expectations[0]

    def judged(self, spell, mean, count, control=0.0, engine=False):
        scenario, hit = self.scripted(spell)
        measured = measured_reference(self.templar, hit)
        model = measured_hit_model(self.templar, hit, measured)
        labels = hit.model['measurements']
        expected = model.engine.mean if engine else model.mean
        values = {**measured, labels['total']: (expected + mean) * count, labels['count']: count,
                  hit.model['control_label']: control}
        base = Verdict(label=hit.label, status='unmeasured', measured=None, expected=None, low=None, high=None,
                       explanation='')
        found = Run(key='script', status='ok', message='', values=values, steps=[], max_step_ms=None)
        return judge_hit(base, self.templar, [(scenario, found, hit)], measured_hit_model)

    def test_the_hit_is_read_from_the_tooltip_of_the_spell_that_states_it(self):
        _, hit = self.scripted(DISCIPLINED_BLOWS)
        self.assertEqual((hit.check, hit.spell_id, hit.rank_id), ('hit_mean', DISCIPLINED_BLOWS,
                                                                  DISCIPLINED_BLOWS_PULSE))
        self.assertEqual(hit.model['tooltip_spell'], DISCIPLINED_BLOWS)
        self.assertEqual(hit.displayed, '${$680398m1*$<scalingbp>+$AP*0.05+$AGI*0.2}')

    def test_the_control_arm_runs_every_trial_before_the_spell_is_learned(self):
        scenario, hit = self.scripted(DISCIPLINED_BLOWS)
        steps = scenario['steps']
        learned = next(index for index, step in enumerate(steps)
                       if step['action'] == 'learn' and step['spell'] == DISCIPLINED_BLOWS)
        control = next(index for index, step in enumerate(steps) if step.get('label') == hit.model['control_label'])
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 578276]
        trials = script_hit_entry(self.templar, DISCIPLINED_BLOWS)['trials']
        self.assertEqual(len([index for index in casts if index < control]), trials)
        self.assertEqual(len([index for index in casts if index > learned]), trials)
        self.assertLess(control, learned)

    def test_a_hit_received_by_the_striker_is_read_on_the_striker(self):
        scenario, hit = self.scripted(ARMOR_OF_FAITH)
        reads = [step for step in scenario['steps'] if step.get('spell') == ARMOR_OF_FAITH_HIT]
        self.assertTrue(reads)
        self.assertTrue(all(step['target'] == STRIKER for step in reads))
        armor = next(step for step in scenario['steps'] if step.get('label') == hit.model['measurements']['armor'])
        self.assertEqual(armor['actor'], STRIKER)

    def test_seeded_mean_passes_and_a_tenth_low_alerts(self):
        self.assertEqual(self.judged(DISCIPLINED_BLOWS, 0.0, 150).status, 'ok')
        _, hit = self.scripted(DISCIPLINED_BLOWS)
        low = -0.1 * hit.model['reference']['mean']
        self.assertEqual(self.judged(DISCIPLINED_BLOWS, low, 150).status, 'alert')

    def test_seeded_hits_without_the_spell_alert(self):
        verdict = self.judged(DISCIPLINED_BLOWS, 0.0, 150, control=3.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('control arm', verdict.explanation)

    def test_a_truncated_per_level_term_is_ok_only_where_the_engine_model_reproduces_it(self):
        engine = self.judged(ARMOR_OF_FAITH, 0.0, 40000, engine=True)
        self.assertEqual(engine.status, 'ok')
        self.assertIn('known engine rounding', engine.explanation)
        self.assertIn(PER_LEVEL_ROUNDING, engine.detail)
        self.assertEqual(self.judged(ARMOR_OF_FAITH, 0.0, 40000).status, 'ok')
        _, hit = self.scripted(ARMOR_OF_FAITH)
        mutant = self.judged(ARMOR_OF_FAITH, -0.06 * hit.model['reference']['mean'], 40000, engine=True)
        self.assertEqual(mutant.status, 'alert')
        self.assertIn('does not explain it either', mutant.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitCastsFloorTest(unittest.TestCase):
    def test_a_floor_raises_the_casts_and_leaves_other_spells_alone(self):
        class_file = {'hit_casts': [{'spell': 572769, 'casts': 40}]}
        self.assertEqual(floored_casts(class_file, 572769, 2), 40)
        self.assertEqual(floored_casts(class_file, 572769, 55), 55)
        self.assertEqual(floored_casts(class_file, 570233, 2), 2)
        self.assertEqual(floored_casts({}, 572769, 2), 2)

    def test_a_floored_sacred_swing_mean_needs_forty_hits(self):
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        spell = {spell.spell_id: spell for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER)}[SACRED_SWING]
        casts = floored_casts(templar, SACRED_SWING_MAX_RANK,
                              casts_needed(reference_hit_model(templar, SACRED_SWING_MAX_RANK)))
        model = hit_expectation(hit_parts(templar, spell, casts)[0][1]).model
        self.assertEqual(casts, 40)
        self.assertEqual((model['minimum_hits'], model['scheduled_casts']), (40, 60))

    def test_a_floor_below_one_cast_is_refused(self):
        with self.assertRaises(ValueError):
            floored_casts({'hit_casts': [{'spell': 572769, 'casts': 0}]}, 572769, 2)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class RangedWeaponPathTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        cls.records = records_of(cls.witch_hunter)
        cls.spells = {spell.spell_id: spell for spell in class_spells(DBC_DIR, WITCH_HUNTER_CLASS_ID, HEADER)}

    def test_a_ranged_range_places_the_dummy_midway_between_its_minimum_and_maximum(self):
        self.assertEqual(self.records.field('Spell', SHADOWBLAST, 'RangeIndex'), HUNTER_RANGE)
        low = self.records.field('SpellRange', HUNTER_RANGE, 'RangeMin[0]')
        high = self.records.field('SpellRange', HUNTER_RANGE, 'RangeMax[0]')
        distance = cast_distance(self.records, SHADOWBLAST)
        self.assertEqual(distance, (low + high) / 2)
        self.assertGreater(distance, low + NOMINAL_MELEE_RANGE_YD)
        self.assertLess(distance, high)

    def test_a_melee_range_keeps_the_melee_dummy_distance(self):
        self.assertEqual(cast_distance(self.records, SMITE_EVIL), DUMMY_DISTANCE)

    def test_a_missile_from_the_ranged_distance_is_waited_for_and_the_melee_distance_keeps_its_steps(self):
        speed = self.records.field('Spell', TORMENTOR, 'Speed')
        distance = cast_distance(self.records, TORMENTOR)
        self.assertGreater(speed, 0)
        self.assertEqual(missile_wait_ms(self.records, TORMENTOR, distance),
                         math.ceil(distance / speed * 1000) + CAST_MARGIN_MS)
        self.assertEqual(missile_wait_ms(self.records, TORMENTOR, DUMMY_DISTANCE), 0)
        self.assertEqual(missile_wait_ms(self.records, SMITE_EVIL, distance), 0)

    def test_only_a_ranged_weapon_attack_takes_ranged_attack_power(self):
        self.assertTrue(ranged_weapon_attack(self.records, SHADOWBLAST))
        self.assertTrue(ranged_weapon_attack(self.records, DAMNATION_MAX_RANK))
        self.assertFalse(ranged_weapon_attack(self.records, SMITE_EVIL))
        stats = caster(ap=900)
        self.assertEqual(weapon_attacker(self.records, SHADOWBLAST, stats).ap, stats.rap)
        self.assertEqual(weapon_attacker(self.records, SMITE_EVIL, stats), stats)

    def test_a_ranged_weapon_hit_scales_with_ranged_attack_power_only(self):
        armed = {**self.witch_hunter, 'weapon': HEAVY_CROSSBOW_WEAPON}
        reference = rank_hit(armed, DAMNATION_MAX_RANK, caster(), REFERENCE_TARGET, []).model
        more_ap = rank_hit(armed, DAMNATION_MAX_RANK, caster(ap=900), REFERENCE_TARGET, []).model
        more_rap = rank_hit(armed, DAMNATION_MAX_RANK, replace(caster(), rap=caster().rap + 140), REFERENCE_TARGET,
                            []).model
        self.assertEqual(reference.kind, 'weapon')
        self.assertEqual(more_ap.tooltip_mean, reference.tooltip_mean)
        self.assertGreater(more_rap.tooltip_mean, reference.tooltip_mean)

    def test_damnation_hit_scenario_equips_the_crossbow_and_stands_inside_the_shot_range(self):
        scenario, expectations = hit_scenario(self.witch_hunter, self.spells[DAMNATION], 1)
        run.validate(scenario)
        self.assertEqual(steps_with(scenario, action='equip'),
                         [{'action': 'equip', 'actor': 'caster', 'item': SCIMITAR, 'slot': MAIN_HAND_SLOT},
                          {'action': 'equip', 'actor': 'caster', 'item': SCIMITAR, 'slot': OFF_HAND_SLOT},
                          {'action': 'equip', 'actor': 'caster', 'item': HEAVY_CROSSBOW, 'slot': RANGED_SLOT}])
        self.assertTrue(steps_with(scenario, action='set_skill', skill=CROSSBOWS_SKILL_LINE))
        self.assertEqual([creature['distance'] for creature in scenario['creatures']],
                         [cast_distance(self.records, DAMNATION_MAX_RANK)])
        hit = hit_expectation(expectations)
        self.assertEqual((hit.rank_id, hit.model['kind'], hit.model['weapon']['item']),
                         (DAMNATION_MAX_RANK, 'weapon', HEAVY_CROSSBOW))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MeleePartsTest(unittest.TestCase):
    def test_a_melee_scenario_within_the_budget_stays_one_scenario(self):
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        swings = casts_needed(reference_melee_model(templar))
        self.assertEqual(melee_parts(templar, swings), [melee_scenario(templar, swings)])

    def test_a_longer_melee_mean_splits_its_swings_over_parts_under_one_label(self):
        witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        self.assertIs(witch_hunter['melee_parts'], True)
        swings = casts_needed(reference_melee_model(witch_hunter))
        with self.assertRaisesRegex(ValueError, 'split its casts'):
            melee_scenario(witch_hunter, swings)
        unsplit = {key: value for key, value in witch_hunter.items() if key != 'melee_parts'}
        with self.assertRaisesRegex(ValueError, 'split its casts'):
            melee_parts(unsplit, swings)
        parts = melee_parts(witch_hunter, swings)
        self.assertGreater(len(parts), 1)
        models = [expectations[0].model for _, expectations in parts]
        self.assertEqual({expectations[0].label for _, expectations in parts}, {'melee melee_mean'})
        self.assertEqual([model['part'] for model in models], list(range(len(parts))))
        self.assertGreaterEqual(sum(model['part_swings'] for model in models), scheduled_casts(swings))
        self.assertEqual({model['minimum_hits'] for model in models}, {swings})
        for scenario, _ in parts:
            self.assertIs(run.validate(scenario), scenario)
            self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)



class WeaponSchoolHitTests(unittest.TestCase):
    QUICKDRAW = 806851

    def class_file(self, listed: bool) -> dict:
        witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        return {**{key: value for key, value in witch_hunter.items() if key != 'weapon_school_hits'},
                **({'weapon_school_hits': [self.QUICKDRAW]} if listed else {})}

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_an_unlisted_weapon_and_school_hit_stays_unmodelled(self):
        with self.assertRaises(Unmodelled) as raised:
            reference_hit_model(self.class_file(False), self.QUICKDRAW)
        self.assertIn('several hit models', raised.exception.reason)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_listed_hit_adds_the_weapon_percent_part_to_the_school_part(self):
        model = reference_hit_model(self.class_file(True), self.QUICKDRAW)
        self.assertEqual(model.kind, 'school')
        self.assertEqual(set(model.displayed), {'$s1', '${$m2+0+$RAP*0.2}'})
        self.assertGreater(model.tooltip_mean, 250.4 + 100)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_mutant_a_listed_hit_without_its_weapon_part_is_refused_not_judged_on_the_school_part(self):
        dropped = lambda readout, effects, caster, weapon: (readout, None)
        with mock.patch('hits.script_weapon_part', side_effect=dropped), self.assertRaises(Unmodelled):
            reference_hit_model(self.class_file(True), self.QUICKDRAW)


class WeaponSchoolPercentTests(unittest.TestCase):
    HEARTSEEKING = 807284
    QUICKDRAW = 806851
    SOURCE = 'rev_20261115_02_witch_hunter_heartseeking_bolt_text.sql'

    def class_file(self, percents: dict | None, listed: tuple[int, ...] = (HEARTSEEKING,)) -> dict:
        witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        kept = {key: value for key, value in witch_hunter.items()
                if key not in ('weapon_school_hits', 'weapon_school_percents')}
        return {**kept, 'weapon_school_hits': list(listed),
                **({'weapon_school_percents': percents} if percents is not None else {})}

    def entry(self, percent=300, source=SOURCE) -> dict:
        return {str(self.HEARTSEEKING): {'percent': percent, 'source': source}}

    def refused(self, class_file: dict, rank: int = HEARTSEEKING) -> str:
        with self.assertRaises(Unmodelled) as raised:
            reference_hit_model(class_file, rank)
        return raised.exception.reason

    def test_the_committed_entry_names_the_streamed_text_row_and_its_literal_percent(self):
        witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        self.assertIn(self.HEARTSEEKING, witch_hunter['weapon_school_hits'])
        self.assertEqual(witch_hunter['weapon_school_percents'][str(self.HEARTSEEKING)]['source'], self.SOURCE)
        self.assertEqual(witch_hunter['weapon_school_percents'][str(self.HEARTSEEKING)]['percent'], 300)

    def test_the_finished_class_files_hold_no_weapon_school_percents(self):
        for class_id in (TEMPLAR_CLASS_ID, 23):
            self.assertNotIn('weapon_school_percents', load_class_file(class_id))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_literal_percent_adds_three_weapon_hits_to_the_school_part(self):
        listed = self.class_file(self.entry())
        model = reference_hit_model(listed, self.HEARTSEEKING)
        self.assertEqual(model.kind, 'school')
        self.assertIn('300%', model.displayed)
        school = reference_hit_model(self.class_file(None, ()), self.HEARTSEEKING)
        armed = armed_for(listed, records_of(listed), self.HEARTSEEKING)
        weapon = weapon_profile(armed)
        caster = reference_caster(armed)
        weapon_mean = (weapon.min_damage + weapon.max_damage) / 2 + caster.rap / 14.0 * weapon.speed_ms / 1000
        self.assertAlmostEqual(model.tooltip_mean - school.tooltip_mean, 3 * weapon_mean, delta=0.05)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_listed_hit_without_its_percent_stays_refused(self):
        self.assertIn('shows no weapon value', self.refused(self.class_file(None)))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_percent_absent_from_the_text_is_refused(self):
        self.assertIn('shows no literal 200%', self.refused(self.class_file(self.entry(percent=200))))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_source_that_is_not_the_streamed_row_is_refused(self):
        reason = self.refused(self.class_file(self.entry(source='rev_20260908_07_witch_hunter_completion.sql')))
        self.assertIn('is not the streamed text row', reason)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_percent_that_is_not_a_whole_number_is_refused(self):
        for percent in ('300', 300.0, 0, True):
            self.assertIn('positive whole percent', self.refused(self.class_file(self.entry(percent=percent))))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_rank_that_shows_its_percent_as_a_token_is_refused(self):
        tokened = {str(self.QUICKDRAW): {'percent': 100, 'source': self.SOURCE}}
        reason = self.refused(self.class_file(tokened, (self.QUICKDRAW,)), self.QUICKDRAW)
        self.assertIn('as a token', reason)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_mutant_an_ignored_percent_is_refused_not_judged_on_the_school_part(self):
        ignored = lambda class_file, records, rank_id, effects, readout: readout
        with mock.patch('hits.with_literal_weapon_percent', side_effect=ignored):
            self.assertIn('shows no weapon value', self.refused(self.class_file(self.entry())))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class UnresistedRankHitTests(unittest.TestCase):
    DESECRATE_MAX_RANK = 681211
    SHADOW_SCHOOL_MASK = 32
    RESISTING_DUMMY = TargetProfile(entry=36, level=60, armor=528, resistances={32: 5000})

    def class_file(self, listed: list[int]) -> dict:
        witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        return {**{key: value for key, value in witch_hunter.items() if key != 'unresisted_rank_hits'},
                **({'unresisted_rank_hits': listed} if listed else {})}

    def model(self, listed: list[int], target: TargetProfile) -> HitModel:
        class_file = armed_for(self.class_file(listed), records_of(self.class_file(listed)), self.DESECRATE_MAX_RANK)
        return rank_hit(class_file, self.DESECRATE_MAX_RANK, reference_caster(class_file), target,
                        class_file.get('known_auras', [])).model

    def test_the_finished_class_files_hold_no_unresisted_rank_hits(self):
        for class_id in (TEMPLAR_CLASS_ID, 23):
            self.assertNotIn('unresisted_rank_hits', load_class_file(class_id))

    def test_an_unlisted_shadow_rank_hit_subtracts_the_measured_resistance(self):
        resisted = self.model([], self.RESISTING_DUMMY)
        self.assertLess(resisted.mean, 0.5 * resisted.tooltip_mean)
        self.assertLess(self.model([], REFERENCE_TARGET).mean, resisted.tooltip_mean)

    def test_a_listed_rank_hit_ignores_any_measured_resistance(self):
        listed = self.model([self.DESECRATE_MAX_RANK], self.RESISTING_DUMMY)
        self.assertEqual(listed.mean, self.model([self.DESECRATE_MAX_RANK], REFERENCE_TARGET).mean)
        self.assertAlmostEqual(listed.mean, listed.tooltip_mean, delta=1.0)
        self.assertGreater(listed.mean, self.model([], REFERENCE_TARGET).mean + 40)

    def test_a_listed_physical_rank_hit_is_refused(self):
        class_file = self.class_file([STAKE_RANK])
        with self.assertRaises(Unmodelled) as raised:
            reference_hit_model(class_file, STAKE_RANK)
        self.assertIn('physical', raised.exception.reason)

    def test_the_listed_hit_rule_names_the_skipped_resistance(self):
        spell = next(spell for spell in class_spells(DBC_DIR, WITCH_HUNTER_CLASS_ID, HEADER)
                     if spell.max_rank == self.DESECRATE_MAX_RANK)
        _, expectations = hit_parts(self.class_file([self.DESECRATE_MAX_RANK]), spell, 10)[0]
        self.assertIn('measured target resistance is not subtracted', expectations[0].rule)
        _, unlisted = hit_parts(self.class_file([]), spell, 10)[0]
        self.assertNotIn('resistance is not subtracted', unlisted[0].rule)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HitLocationTests(unittest.TestCase):
    REPULSE_MAX_RANK = 680273
    DESECRATE_MAX_RANK = 681211
    WALL_START = {'map': 1, 'x': -6524.53, 'y': -3824.85, 'z': -63.3, 'o': 0}
    CASTS = 30

    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        cls.repulse = next(spell for spell in class_spells(DBC_DIR, WITCH_HUNTER_CLASS_ID, HEADER)
                           if spell.max_rank == cls.REPULSE_MAX_RANK)

    def without_location(self) -> dict:
        return {key: value for key, value in self.witch_hunter.items() if key != 'hit_location'}

    def test_a_listed_location_places_every_part_and_is_named_in_the_rule(self):
        self.assertEqual(hit_location(self.witch_hunter, self.REPULSE_MAX_RANK), self.WALL_START)
        parts = hit_parts(self.witch_hunter, self.repulse, 400)
        self.assertGreater(len(parts), 1)
        for scenario, expectations in parts:
            self.assertIs(run.validate(scenario), scenario)
            self.assertEqual(scenario['location'], self.WALL_START)
            self.assertIn('listed in hit_location: cast at map 1 (-6524.53, -3824.85, -63.3)', expectations[0].rule)

    def test_mutant_without_the_location_the_part_starts_where_the_character_is_created(self):
        kept = self.without_location()
        scenario, expectations = hit_parts(kept, self.repulse, self.CASTS)[0]
        listed, _ = hit_parts(self.witch_hunter, self.repulse, self.CASTS)[0]
        self.assertNotIn('location', scenario)
        self.assertNotIn('hit_location', expectations[0].rule)
        self.assertIsNone(hit_location(kept, self.REPULSE_MAX_RANK))
        self.assertEqual({**scenario, 'location': listed['location']}, listed)

    def test_an_unlisted_rank_is_left_alone(self):
        self.assertIsNone(hit_location(self.witch_hunter, self.DESECRATE_MAX_RANK))
        self.assertIsNone(hit_location({}, self.REPULSE_MAX_RANK))

    def test_a_location_without_every_coordinate_or_a_reason_or_a_repeated_entry_is_refused(self):
        whole = dict(self.WALL_START)
        for entries in ([{'spell': self.REPULSE_MAX_RANK, 'location': {**whole, 'o': None}, 'reason': 'r'}],
                        [{'spell': self.REPULSE_MAX_RANK, 'location': {k: v for k, v in whole.items() if k != 'z'},
                          'reason': 'r'}],
                        [{'spell': self.REPULSE_MAX_RANK, 'location': {**whole, 'w': 1}, 'reason': 'r'}],
                        [{'spell': self.REPULSE_MAX_RANK, 'location': whole}],
                        [{'spell': self.REPULSE_MAX_RANK, 'location': whole, 'reason': 'r'}] * 2):
            with self.subTest(entries=entries), self.assertRaises(ValueError):
                hit_location({'hit_location': entries}, self.REPULSE_MAX_RANK)

    def test_the_finished_class_files_hold_no_hit_location(self):
        for class_id in (TEMPLAR_CLASS_ID, 23):
            self.assertNotIn('hit_location', load_class_file(class_id))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class NormalizedValueTest(unittest.TestCase):
    PURIFIERS_EDGE = 802434
    HANDS = {'main_hand': 803357, 'off_hand': 803517}
    NORMALIZED_ONE_HAND = 2.4
    OFF_HAND_FACTOR = 0.5
    PASSED = 277
    FIRE = 4

    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)

    def entry(self, hand: str, **changes) -> dict:
        found = next(entry for entry in self.witch_hunter['behaviours'] if entry['spell'] == self.PURIFIERS_EDGE
                     and entry['kind'] == 'script_hit' and entry.get('label_suffix') == hand)
        return {**found, **changes}

    def built(self, hand: str, **changes):
        scenario, [expectation] = behaviour_scenario(self.witch_hunter, self.entry(hand, **changes))
        return scenario, expectation

    def judged(self, hand: str, mean: float, hits: int = 40, armor: int = 528) -> Verdict:
        scenario, expectation = self.built(hand)
        labels = expectation.model['measurements']
        found = Run(key='seeded', status='ok', message='',
                    values={**measured_reference(self.witch_hunter, expectation, armor), labels['total']: mean * hits,
                            labels['count']: hits, expectation.model['control_label']: 0},
                    steps=[], max_step_ms=None)
        base = Verdict(label=expectation.label, status='unmeasured', measured=None, expected=None, low=None,
                       high=None, explanation='')
        return judge_hit(base, self.witch_hunter, [(scenario, found, expectation)], measured_hit_model)

    def model(self, hand: str, target: TargetProfile = REFERENCE_TARGET, **flags) -> HitModel:
        return script_hit_model(self.witch_hunter, self.PURIFIERS_EDGE, self.HANDS[hand], reference_caster(
            self.witch_hunter), target, self.witch_hunter.get('known_auras', []), self.PURIFIERS_EDGE, 0,
            normalized_value=True, **({'effective_school': True} | flags))

    def weapon_mean(self) -> float:
        weapon = self.witch_hunter['off_hand_weapons'][0]
        bonus = self.witch_hunter['reference_stats']['attack_power'] / 14 * self.NORMALIZED_ONE_HAND
        return (weapon['min_damage'] + weapon['max_damage']) / 2 + bonus

    def roll(self) -> range:
        weapon = self.witch_hunter['off_hand_weapons'][0]
        bonus = self.witch_hunter['reference_stats']['attack_power'] / 14 * self.NORMALIZED_ONE_HAND
        return range(int(weapon['min_damage'] + bonus) + self.PASSED, int(weapon['max_damage'] + bonus) + self.PASSED
                     + 1)

    def physical_records(self):
        records = records_of(self.witch_hunter)
        field = records.field

        def physical(table, key, name):
            if (table, name) == ('Spell', 'SchoolMask') and key in self.HANDS.values():
                return 1
            return field(table, key, name)
        records.field = physical
        return mock.patch('hits.records_of', return_value=records)

    def test_both_hands_take_the_full_roll_and_points_of_the_loaded_fire_mask(self):
        for hand in self.HANDS:
            model = self.model(hand)
            with self.subTest(hand=hand):
                self.assertAlmostEqual(model.tooltip_mean, self.weapon_mean() + self.PASSED, places=6)
                self.assertEqual(model.displayed[-2], f'{hand.replace("_", "-")} weapon 2027')
                self.assertEqual(model.displayed[-1], 'school mask 5 loaded as 4, resistance within armor')
                self.assertLess(model.mean, model.tooltip_mean)

    def test_each_resisted_amount_is_capped_at_the_armor_reduction(self):
        shares = partial_resist_shares(average_resist(self.FIRE, REFERENCE_TARGET, 0))
        reduction = armor_reduction(REFERENCE_TARGET.armor, self.witch_hunter['level'], REFERENCE_TARGET.level)
        values = self.roll()
        expected = sum(share * (value - min(value * step // 10, value - math.ceil(value * (1 - reduction))))
                       for value in values for step, share in enumerate(shares)) / len(values)
        self.assertAlmostEqual(self.model('off_hand').mean, expected, places=6)
        self.assertGreater(self.model('off_hand').mean, expected_mitigation(1, REFERENCE_TARGET, 60).mean
                           * self.model('off_hand').tooltip_mean)

    def test_without_armor_the_cap_removes_the_resistance(self):
        bare = replace(REFERENCE_TARGET, armor=0)
        values = self.roll()
        for hand in self.HANDS:
            with self.subTest(hand=hand):
                self.assertAlmostEqual(self.model(hand, bare).mean, sum(values) / len(values), places=6)
                self.assertEqual(self.judged(hand, sum(values) / len(values), armor=0).status, 'ok')
                self.assertEqual(self.judged(hand, self.OFF_HAND_FACTOR * self.weapon_mean()
                                             + int(self.PASSED * self.OFF_HAND_FACTOR), armor=0).status, 'alert')

    def test_seeded_hits_at_the_model_pass(self):
        for hand, hit in self.HANDS.items():
            scenario, expectation = self.built(hand)
            run.validate(scenario)
            self.assertTrue(expectation.model['normalized_value'])
            self.assertTrue(expectation.model['effective_school'])
            self.assertEqual(expectation.rank_id, hit)
            model = reference_script_hit_model(self.witch_hunter, self.PURIFIERS_EDGE, hit, self.PURIFIERS_EDGE, 0,
                                               normalized_value=True, effective_school=True)
            with self.subTest(hand=hand):
                self.assertEqual(self.judged(hand, model.mean).status, 'ok')

    def test_mutant_a_halved_off_hand_or_a_hit_without_the_points_alerts(self):
        with self.physical_records():
            halved = self.model('off_hand', effective_school=False)
        self.assertAlmostEqual(halved.tooltip_mean, self.OFF_HAND_FACTOR * self.weapon_mean()
                               + int(self.PASSED * self.OFF_HAND_FACTOR), places=6)
        self.assertEqual(self.judged('off_hand', halved.mean).status, 'alert')
        main = self.model('main_hand')
        self.assertEqual(self.judged('main_hand', main.mean - self.PASSED).status, 'alert')

    def test_a_physical_strike_keeps_the_off_hand_factor_and_armor(self):
        with self.physical_records():
            off = self.model('off_hand', effective_school=False)
            main = self.model('main_hand', effective_school=False)
            with self.assertRaises(Unmodelled) as raised:
                self.model('off_hand')
        self.assertIn('only for a mask that mixes', raised.exception.reason)
        self.assertAlmostEqual(main.tooltip_mean, self.weapon_mean() + self.PASSED, places=6)
        self.assertEqual(off.displayed[-1], 'off-hand weapon 2027')
        weapon = self.witch_hunter['off_hand_weapons'][0]
        bonus = self.witch_hunter['reference_stats']['attack_power'] / 14 * self.NORMALIZED_ONE_HAND
        halved = int(self.PASSED * self.OFF_HAND_FACTOR)
        values = range(int((weapon['min_damage'] + bonus) * self.OFF_HAND_FACTOR) + halved,
                       int((weapon['max_damage'] + bonus) * self.OFF_HAND_FACTOR) + halved + 1)
        armor = expected_mitigation(1, REFERENCE_TARGET, 60).mean
        self.assertAlmostEqual(off.mean, sum(math.ceil(value * armor) for value in values) / len(values), places=6)

    def test_a_mixed_mask_without_effective_school_is_unmodelled(self):
        with self.assertRaises(NotModelled) as raised:
            self.built('off_hand', effective_school=False)
        self.assertIn('effective_school is required', str(raised.exception))
        with self.assertRaises(ValueError):
            self.built('off_hand', effective_school='yes')
        with self.assertRaises(ValueError):
            self.built('off_hand', normalized_value=False)

    def test_without_the_part_or_for_a_non_physical_off_hand_the_hit_is_unmodelled(self):
        with self.assertRaises(NotModelled) as raised:
            self.built('off_hand', spell=802258, hit_spell=803502, value_spell=802258, value_effect=1,
                       casts=[[802258, 'dummy']], quote='Strike an enemy with both weapons', effective_school=False)
        self.assertIn('non-physical', str(raised.exception))
        with self.assertRaises(ValueError):
            self.built('off_hand', normalized_value='yes')


TORMENTOR_TOP_RANK = 501349
RANK_HIT_EFFECTS_FIELD = 'rank_hit_effects'
SPLIT_SOURCE = 'Effect[2] school damage, Effect[0] periodic damage'


def with_split(class_file: dict, entry: dict | None) -> dict:
    split = {key: value for key, value in class_file.items() if key != RANK_HIT_EFFECTS_FIELD}
    if entry is not None:
        split[RANK_HIT_EFFECTS_FIELD] = {str(TORMENTOR_TOP_RANK): entry}
    return split


class RankHitEffectsFieldTest(unittest.TestCase):
    ENTRY = {'hit_mean': 2, 'periodic_total': 0, 'source': SPLIT_SOURCE}

    def test_an_absent_entry_names_no_effect(self):
        self.assertIsNone(rank_hit_effect({}, TORMENTOR_TOP_RANK, 'hit_mean'))

    def test_each_role_names_its_effect(self):
        class_file = with_split({}, self.ENTRY)
        self.assertEqual(rank_hit_effect(class_file, TORMENTOR_TOP_RANK, 'hit_mean'), 2)
        self.assertEqual(rank_hit_effect(class_file, TORMENTOR_TOP_RANK, 'periodic_total'), 0)

    def test_malformed_entries_are_refused(self):
        for entry in ({'hit_mean': 2, 'periodic_total': 0},
                      {**self.ENTRY, 'source': ' '},
                      {**self.ENTRY, 'extra': 1},
                      {'hit_mean': 2, 'source': SPLIT_SOURCE},
                      {**self.ENTRY, 'periodic_total': 2},
                      {**self.ENTRY, 'periodic_total': True},
                      {**self.ENTRY, 'hit_mean': 3},
                      {**self.ENTRY, 'hit_mean': '2'}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                rank_hit_effect(with_split({}, entry), TORMENTOR_TOP_RANK, 'hit_mean')

    def test_another_check_is_unmodelled(self):
        with self.assertRaises(Unmodelled):
            rank_hit_effect(with_split({}, self.ENTRY), TORMENTOR_TOP_RANK, 'melee_mean')

    def test_measurements_carry_the_event_filter_only_when_asked(self):
        labels = {'total': 'x total', 'count': 'x count'}
        plain = hit_measurements(TORMENTOR_TOP_RANK, TORMENTOR_TOP_RANK, True, labels)
        self.assertFalse(any('periodic' in step for step in plain))
        for periodic in (False, True):
            steps = hit_measurements(TORMENTOR_TOP_RANK, TORMENTOR_TOP_RANK, True, labels, periodic=periodic)
            damage = [step for step in steps if str(step.get('metric', '')).startswith('spell_damage')]
            self.assertEqual(len(damage), 4)
            self.assertTrue(all(step['periodic'] is periodic for step in damage))


class MeasuredHitModelRoleTest(unittest.TestCase):
    MODEL = HitModel(kind='periodic_damage', mean=140.6, sigma=12.7, tooltip_mean=159.06)

    def roles(self, check: str) -> list[str]:
        roles = []

        def modelled(class_file, rank_id, caster, target, auras, learned=None, role='hit_mean', flat=None,
                     percent_part=None):
            roles.append(role)
            return types.SimpleNamespace(model=self.MODEL)

        expectation = Expectation(label=f'{TORMENTOR_TOP_RANK} effect_value #1', check=check,
                                  spell_id=TORMENTOR_TOP_RANK, rank_id=TORMENTOR_TOP_RANK, effect_index=0,
                                  displayed='$o1', rule='', model={'kind': 'periodic_damage', 'measurements': {}})
        with (mock.patch('hits.armed_for', side_effect=lambda class_file, records, rank_id: class_file),
              mock.patch('hits.records_of'), mock.patch('hits.caster_stats_from'),
              mock.patch('hits.rank_hit', side_effect=modelled)):
            self.assertEqual(measured_hit_model({}, expectation, {}), self.MODEL)
        return roles

    def test_a_periodic_total_models_its_own_hit_role(self):
        self.assertEqual(self.roles('periodic_total'), ['periodic_total'])

    def test_a_direct_hit_models_the_direct_role(self):
        self.assertEqual(self.roles('hit_mean'), ['hit_mean'])

    def test_another_check_keeps_the_direct_role(self):
        self.assertEqual(self.roles('script_hit'), ['hit_mean'])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class RankHitEffectsDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        cls.tormentor = next(spell for spell in class_spells(DBC_DIR, WITCH_HUNTER_CLASS_ID, HEADER)
                             if TORMENTOR_TOP_RANK in spell.ranks)

    def test_without_the_field_both_hit_models_are_refused(self):
        unsplit = with_split(self.witch_hunter, None)
        for check in ('hit_mean', 'periodic_total'):
            with self.subTest(check=check), self.assertRaises(Unmodelled) as raised:
                reference_hit_model(unsplit, TORMENTOR_TOP_RANK, check)
            self.assertEqual(str(raised.exception), "effects of several hit models: ['periodic_damage', 'school']")
        scenario, _ = hit_parts(unsplit, self.tormentor, 1, rank_id=TORMENTOR_TOP_RANK)[0]
        self.assertFalse(any('periodic' in step for step in scenario['steps']))

    def test_the_direct_hit_models_effect_2_on_direct_events_only(self):
        model = reference_hit_model(self.witch_hunter, TORMENTOR_TOP_RANK)
        self.assertEqual(model.kind, 'school')
        self.assertEqual(model.tooltip_mean, 66.5)
        self.assertEqual(model.hits_per_cast, 1)
        scenario, expectations = hit_parts(self.witch_hunter, self.tormentor, 1, rank_id=TORMENTOR_TOP_RANK)[0]
        run.validate(scenario)
        self.assertEqual(expectations[0].effect_index, 2)
        damage = [step for step in scenario['steps'] if str(step.get('metric', '')).startswith('spell_damage')]
        self.assertTrue(damage)
        self.assertTrue(all(step['periodic'] is False for step in damage))

    def test_the_periodic_effect_keeps_its_once_per_aura_roll_refusal(self):
        with self.assertRaises(Unmodelled) as raised:
            reference_hit_model(self.witch_hunter, TORMENTOR_TOP_RANK, 'periodic_total')
        self.assertIn('rolled once per aura', str(raised.exception))

    def test_the_swapped_effects_mutant_alerts(self):
        mutant = with_split(self.witch_hunter, {'hit_mean': 0, 'periodic_total': 2, 'source': 'mutant: swapped'})
        for check, effect in (('hit_mean', 0), ('periodic_total', 2)):
            with self.subTest(check=check), self.assertRaises(Unmodelled) as raised:
                reference_hit_model(mutant, TORMENTOR_TOP_RANK, check)
            self.assertIn(f'names effect {effect} for {check}', str(raised.exception))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ValueSpellRollTest(unittest.TestCase):
    SHADOW_RAGE, STRIKE, VALUE_EFFECT = 680275, 567570, 2
    BASE_POINTS, DIE_SIDES = 56, 2

    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        cls.bonus = 0.15 * reference_caster(cls.witch_hunter).rap

    def model(self, **flags) -> HitModel:
        return reference_script_hit_model(self.witch_hunter, self.SHADOW_RAGE, self.STRIKE, self.SHADOW_RAGE,
                                          self.VALUE_EFFECT, unresisted=True, **flags)

    def entry(self, **changes) -> dict:
        return {'spell': self.SHADOW_RAGE, 'name': 'Shadow Rage (ranged auto attack strike)', 'kind': 'script_hit',
                'label_suffix': 'ranged_auto_strike', 'quote': 'deal an additional ${$m3+$RAP*0.15} Shadow Damage',
                'hit_spell': self.STRIKE, 'casts': [[75, 'dummy']], 'control_casts': [], 'trials': 12,
                'minimum_hits': 8, 'unresisted': True, 'value_spell': self.SHADOW_RAGE,
                'value_effect': self.VALUE_EFFECT, **changes}

    def test_the_value_effect_carries_the_die_and_the_hit_spell_does_not(self):
        records = records_of(self.witch_hunter)
        self.assertEqual(records.field('Spell', self.SHADOW_RAGE, f'EffectBasePoints[{self.VALUE_EFFECT}]'),
                         self.BASE_POINTS)
        self.assertEqual(records.field('Spell', self.SHADOW_RAGE, f'EffectDieSides[{self.VALUE_EFFECT}]'),
                         self.DIE_SIDES)

    def test_value_rolls_spread_the_hit_over_every_roll_of_the_value_effect(self):
        model = self.model(value_rolls=True)
        rolls = [self.BASE_POINTS + roll + self.bonus for roll in range(1, self.DIE_SIDES + 1)]
        self.assertAlmostEqual(model.tooltip_mean, sum(rolls) / len(rolls), places=6)
        self.assertAlmostEqual(model.mean, sum(math.floor(value) for value in rolls) / len(rolls), places=6)
        self.assertAlmostEqual(model.sigma, 0.5, places=6)

    def test_mutant_rolling_the_hit_spell_keeps_one_value_and_misses_the_top_roll(self):
        rolled, mutant = self.model(value_rolls=True), self.model()
        self.assertAlmostEqual(mutant.tooltip_mean, self.BASE_POINTS + 1 + self.bonus, places=6)
        self.assertEqual(mutant.sigma, 0.0)
        self.assertNotAlmostEqual(mutant.tooltip_mean, rolled.tooltip_mean, places=3)
        self.assertNotAlmostEqual(mutant.sigma, rolled.sigma, places=3)

    def test_value_rolls_need_a_value_spell(self):
        with self.assertRaises(Unmodelled):
            reference_script_hit_model(self.witch_hunter, self.SHADOW_RAGE, self.STRIKE, unresisted=True,
                                       value_rolls=True)

    def test_the_option_is_recorded_only_when_set_and_is_a_boolean(self):
        _, [rolled] = behaviour_scenario(self.witch_hunter, self.entry(value_rolls=True))
        _, [plain] = behaviour_scenario(self.witch_hunter, self.entry())
        self.assertTrue(rolled.model['value_rolls'])
        self.assertNotIn('value_rolls', plain.model)
        self.assertEqual(plain.model['reference']['sigma'], 0.0)
        self.assertAlmostEqual(rolled.model['reference']['sigma'], 0.5, places=6)
        with self.assertRaises(ValueError):
            behaviour_scenario(self.witch_hunter, self.entry(value_rolls='yes'))

from test_script_hit_engage import ScriptHitEngageTests  # noqa: E402,F401
from test_script_hit_relocate import ScriptHitRelocateTests  # noqa: E402,F401
from test_tooltip_corrections import OnlyInsertedTests, TooltipCorrectionTests  # noqa: E402,F401



@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class DamageFromCasterAndLevelPointsTest(unittest.TestCase):
    VEIL, VEIL_PULSE = 802100, 806473
    VOLLEY_TALENT, VOLLEY = 503712, 504582

    @classmethod
    def setUpClass(cls):
        cls.witch_doctor = load_class_file(13)

    def test_the_casters_damage_from_caster_aura_raises_its_own_family_hit_after_the_done_truncation(self):
        plain = reference_script_hit_model(self.witch_doctor, self.VEIL, self.VEIL_PULSE, unresisted=True)
        veiled = reference_script_hit_model(self.witch_doctor, self.VEIL, self.VEIL_PULSE, model_auras=(self.VEIL,),
                                            unresisted=True, taken_auras=(self.VEIL,))
        self.assertEqual((plain.mean, plain.engine.mean), (206.0, 205.0))
        self.assertEqual((veiled.mean, veiled.engine.mean), (236.0, 235.0))
        self.assertEqual([(modifier.aura, modifier.percent) for modifier in veiled.modifiers], [(271, 15)])

    def test_a_damage_from_caster_aura_skips_a_hit_of_another_family(self):
        records = records_of(self.witch_doctor)
        self.assertEqual(taken_modifiers(records, [self.VEIL], 60, 133), ())
        self.assertEqual(len(taken_modifiers(records, [self.VEIL], 60, self.VEIL_PULSE)), 1)

    def test_a_damage_from_caster_aura_never_changes_a_heal(self):
        modifier = Modifier(self.VEIL, 0, 271, 15, 'damage_taken', 127)
        self.assertEqual(taken_by([modifier], 'heal'), ())
        self.assertEqual(taken_by([modifier], 'school'), (modifier,))

    def test_level_points_read_the_per_level_term_at_the_caster_level(self):
        client = reference_script_hit_model(self.witch_doctor, self.VOLLEY_TALENT, self.VOLLEY, unresisted=True)
        server = reference_script_hit_model(self.witch_doctor, self.VOLLEY_TALENT, self.VOLLEY, unresisted=True,
                                            level_points=True)
        self.assertEqual(client.mean, 371.0)
        self.assertEqual((server.mean, server.engine.mean), (389.0, 389.0))
        self.assertAlmostEqual(server.sigma, client.sigma)

    def test_the_record_names_the_taken_auras_and_the_measured_model_reads_them(self):
        entry = next({key: value for key, value in entry.items() if key != 'model_auras'}
                     for entry in self.witch_doctor['behaviours']
                     if entry['spell'] == self.VEIL and entry.get('variant') == 'veil_tick')
        _, [plain] = behaviour_scenario(self.witch_doctor, entry)
        _, [veiled] = behaviour_scenario(self.witch_doctor, {**entry, 'model_auras': [self.VEIL]})
        self.assertNotIn('taken_auras', plain.model)
        self.assertEqual(veiled.model['taken_auras'], [self.VEIL])
        self.assertEqual(veiled.model['reference']['mean'], 236.0)

    def test_level_points_refuse_a_weapon_hit(self):
        with self.assertRaises(Unmodelled):
            script_hit_model(self.witch_doctor, self.VOLLEY_TALENT, self.VOLLEY, reference_caster(self.witch_doctor),
                             REFERENCE_TARGET, [], weapon_only=True, level_points=True)


if __name__ == '__main__':
    unittest.main()
