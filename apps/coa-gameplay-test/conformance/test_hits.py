import json
import math
from pathlib import Path
import sys
import unittest

from classes import class_spells
from hits import (HIT_CHECKS, MAX_SCENARIO_MS, HitModel, Modifier, Unmodelled, WeaponProfile, casts_needed,
                  expected_hit, hit_parts, hit_scenario, measured_hit_model, melee_scenario, records_of,
                  reference_caster, reference_hit_model, reference_melee_model, rolled_values, scheduled_casts,
                  weapon_profile)
from mitigation import REFERENCE_TARGET, MitigationModel, TargetProfile, expected_mitigation
from profile import CLASSES_DIR, load_class_file
from tooltip import CasterStats, Displayed, Readout, read_tooltip, weapon_skill_spells
from values import UNREADABLE

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
PVE_DAMAGE_DONE_PCT = 341
HEALING_DONE_PCT = 136
CLASS_TUNING_PERCENT_AT_60 = -20
NO_MITIGATION = MitigationModel(mean=1.0, variance=0.0)
ARMOR_528 = TargetProfile(entry=36, level=60, armor=528, resistances={})
PHYSICAL = 1
HOLY = 2
SCHOOL_DAMAGE = 2
HEAL = 10
APPLY_AURA = 6
PERIODIC_DAMAGE = 3
DUMMY = 3
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
        model = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(), NO_MITIGATION)
        weapon_average = (WALKING_STICK_MIN + WALKING_STICK_MAX) / 2
        self.assertAlmostEqual(
            model.tooltip_mean,
            2.15 * (weapon_average + REFERENCE_ATTACK_POWER / 14 * TWO_HANDED_NORMALIZED_SPEED) + ARGENT_BLADE_FLAT,
            places=6)

    def test_argent_blade_mean_truncates_the_roll_the_percent_and_the_flat_bonus(self):
        model = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(), NO_MITIGATION)
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
                             modifiers=(tuning(),))
        mean, sigma = moments([541, 542, 543, 544, 546])
        self.assertAlmostEqual(model.mean, mean, places=9)
        self.assertAlmostEqual(model.sigma, sigma, places=9)
        self.assertEqual([modifier.spell_id for modifier in model.modifiers], [CLASS_TUNING_AURA])

    def test_healing_modifier_never_changes_damage(self):
        with_heal_modifier = expected_hit(argent_blade_readout(), ARGENT_BLADE_EFFECTS, caster(), walking_stick(),
                                          NO_MITIGATION, modifiers=(tuning('heal', HEALING_DONE_PCT),))
        self.assertAlmostEqual(with_heal_modifier.mean, 744.0, places=9)
        self.assertEqual(with_heal_modifier.modifiers, ())

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
        self.assertEqual([expectation.displayed for expectation in unreadable],
                         ['${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}'])

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
                        self.assertTrue(expectation.rule.startswith('unmodelled: '))
                    elif not expectation.rule.startswith(UNREADABLE):
                        self.assertIn(expectation.label + ' total', labels)
                        self.assertIn(expectation.label + ' count', labels)
                    checks[expectation.check] = checks.get(expectation.check, 0) + 1
        self.assertTrue(checks.get('hit_mean'))
        self.assertTrue(checks.get('unmodelled'))


if __name__ == '__main__':
    unittest.main()
