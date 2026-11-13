from dataclasses import replace
import json
import math
from pathlib import Path
import sys
import unittest

from classes import ClassSpell, class_spells
from behaviours import STRIKER, behaviour_scenario
from compare import PER_LEVEL_ROUNDING, Run, Verdict, judge_hit
from conformance import target_gate_arms
from hits import (CLOSED, HIT_CHECKS, MAX_SCENARIO_MS, UNMODELLED, HitModel, Modifier, Unmodelled, WeaponProfile,
                  casts_needed, dual_target_entry, effect_hit, expected_hit, floored_casts, hit_kind, hit_parts,
                  hit_scenario,
                  learned_weapon_part,
                  measured_hit_model, melee_scenario, records_of, periodic_tick_readout, reference_caster,
                  reference_hit_model, reference_melee_model, rolled_values, scheduled_casts,
                  self_stack_multiplier, weapon_profile)
from mitigation import REFERENCE_TARGET, MitigationModel, TargetProfile, expected_mitigation
from profile import CLASSES_DIR, load_class_file
from tooltip import CasterStats, Displayed, Readout, read_tooltip, weapon_skill_spells
from values import (ALLY, CHARGE_OFFSET_YD, DUMMY_DISTANCE, GAP_CLOSER_DISTANCE, NOMINAL_MELEE_RANGE_YD, TARGET,
                    UNREADABLE)

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

DBC_DIR = Path('/srv/coa/server-data/dbc')
HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'

TEMPLAR_CLASS_ID = 19
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
    return weapon_profile(load_class_file(TEMPLAR_CLASS_ID))


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
        templar = load_class_file(TEMPLAR_CLASS_ID)
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
class HitScenarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.templar = load_class_file(TEMPLAR_CLASS_ID)
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
        cls.templar = load_class_file(TEMPLAR_CLASS_ID)

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
        templar = load_class_file(TEMPLAR_CLASS_ID)
        spell = {spell.spell_id: spell for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER)}[SACRED_SWING]
        casts = floored_casts(templar, SACRED_SWING_MAX_RANK,
                              casts_needed(reference_hit_model(templar, SACRED_SWING_MAX_RANK)))
        model = hit_expectation(hit_parts(templar, spell, casts)[0][1]).model
        self.assertEqual(casts, 40)
        self.assertEqual((model['minimum_hits'], model['scheduled_casts']), (40, 60))

    def test_a_floor_below_one_cast_is_refused(self):
        with self.assertRaises(ValueError):
            floored_casts({'hit_casts': [{'spell': 572769, 'casts': 0}]}, 572769, 2)


if __name__ == '__main__':
    unittest.main()
