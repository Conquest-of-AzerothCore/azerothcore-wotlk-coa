from dataclasses import replace
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest import mock

from classes import class_spells
from profile import (CASTER, armed, base_steps, caster_stats_from, class_file_paths, load_class_file, skill_label,
                    unfit_reason)
from test_tooltip import FIXTURE_CASTER, FIXTURE_SPELLS, FIXTURE_VARIABLES, write_fixture
from tooltip import CasterStats, DataSet, Displayed, Records, read_tooltip
from values import (ALLY, AURA_STATE_HEALTHLESS_35_PERCENT, CALC_AMOUNT_HOOKS_METRIC, CHECKS, FIXTURE_MAX_HEALTH,
                    GCD_WAIT_MS, GENERIC, TARGET, UNMEASURABLE, UNREADABLE, Expectation, Unmodelled,
                    calc_amount_hooks_label, conditional_extra_values, effect_modifier_label,
                    disabled_foreign_effects, facts_of, fixture_health_step, foreign_aura_grants, foreign_effect,
                    foreign_radius, periodic_reason, required_target_health_steps, sample_labels, value_scenario)

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

DBC_DIR = Path('/srv/coa/server-data/dbc')
HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'

TEMPLAR_CLASS_ID = 19
WALKING_STICK = 2495
FROSTMANE_CLUB = 2259
MACES_SKILL_LINE = 54
VINDICATION = 801446
VINDICATION_RANKS = (801446, 501589, 501590, 501591, 501592, 501593, 573324)
VINDICATION_RANK_2 = 501589
VINDICATION_ROLLED_LABEL = '501589 effect_value e0 #0'
ONE_HAND_MASK = 41105
TWO_HAND_MASK = 1378
TWO_HAND_INVENTORY_MASK = 131072
MAIN_HAND_INVENTORY_MASK = 1 << 21
SCOURGEBANE = 92111
CLASS_TUNING_AURA = 887007
ARGENT_BLADE = 804929
ARGENT_BLADE_RANK_2 = 807263
SPIRITUAL_ASCENSION = 500688
SPIRITUAL_ASCENSION_MAX_RANK = 500758
ARGENT_BLADE_RANK_2_ENERGY_COST = 50
ARGENT_BLADE_RECAST_MS = 5000
ENERGY = 3
ARGENT_BLADE_TOOLTIP_TOKENS = {
    1: ('$s2', 'read percent'),
    0: ('${$AP*0.4725+$sph*1.35+$m1+0}', 'read flat'),
}
ARGENT_BLADE_UNREADABLE = '${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}'
HOLY_CONSTITUTION = 706323
RIGHTEOUS_UPHEAVAL = 501562
RIGHTEOUS_UPHEAVAL_MAX_RANK = 572027
OATH_CHAIN = 704576
SPELL_POWER_SCHOOLS = 6
STAT_COUNT = 5
SETTLE_MS = 5000
LIBERTY = 705266
SCOURGEBANE_STRIKE = 801832
IRON_PENANCE = 523712
IRON_PENANCE_DEBUFF = 523713
KEEPING_THE_OATH = 92109
KEEPING_THE_OATH_AURA = 803237
ZEALOTRY_PASSIVE = 92108
ZEALOTRY = 801450
SACRED_OATH = 712346
GLORY = 801481
DOWNFALL = 801482
REDEMPTION = 801483
LIBRAM_OF_TENACITY = 801461
ETERNAL_BLESSING = 705300
OATH_BREAKERS = 573452
LIBRAMS = 806106
LIGHTS_HOPE = 807814
LIGHTKEEPER = 560835
RIGHTEOUS_TEMPEST = 805409
RIGHTEOUS_TEMPEST_MAX_RANK = 807274
RIGHTEOUS_TEMPEST_GATING = 300512
CHASTISE = 803157
CHASTISE_GATING = 806525
BLADE_OF_FAITH = 803872
BLADE_OF_FAITH_MAX_RANK = 803880
BLADE_OF_FAITH_TOTAL = '${($d*1000/$T1)*($m1+0+$SP*.2+$AP*0.1)}'
CRUSADERS_PRESENCE = 562302
TESTAMENT_OF_HOPE = 1397742
TESTAMENT_OF_HOPE_RADIUS_SPELL = 704409
RIGHTEOUS_CUSTODIAN = 572808
CONDEMN = 804906
NORGANNONS_WRATH = 524739
TESTAMENT_OF_RESOLVE = 804228
SACRED_RESTRAINT = 102208
TOME_OF_LIGHT = 805422
TOME_OF_LIGHT_AURAS = (806354, 807004)
NORGANNONS_WRATH_RADIUS_SPELL = 524740
NON_PERIODIC_AURA_WITH_AMPLITUDE = 43
PERIODIC_AURA_WITH_SECONDS = 44
HUMAN = 1
STAFF_SUBCLASS = 10
ITEM_RECORD = struct.Struct('<3i')
TEMPLAR_SKILL_LINES = (70, 71, 72, 136)
LEVEL_60_SKILL = 300
HOLY_CONSTITUTION_BASE_POINTS, HOLY_CONSTITUTION_PER_LEVEL, HOLY_CONSTITUTION_BASE_LEVEL = 4, 1.5, 28
TITANSTRIKE_MAX_RANK = 806835


def measured_labels(scenario):
    return {step['label'] for step in scenario['steps'] if step['action'] == 'assert'}


class ClassFileTest(unittest.TestCase):
    def test_templar_file_names_the_weapon_and_the_known_auras(self):
        templar = load_class_file(TEMPLAR_CLASS_ID)
        self.assertEqual(templar['weapon']['item'], WALKING_STICK)
        self.assertEqual(templar['known_auras'], [CLASS_TUNING_AURA])
        self.assertEqual(templar['probe_auras'], [SCOURGEBANE])
        for section in ('talent_modifiers', 'rotation', 'stack'):
            self.assertTrue(templar[section])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_templar_weapon_subclass_is_the_item_record_subclass(self):
        table = DataSet(DBC_DIR).load('Item')[0]
        records = {item: (item_class, subclass) for item, item_class, subclass
                   in (ITEM_RECORD.unpack_from(table.record(row)) for row in range(table.rows))}
        templar = load_class_file(TEMPLAR_CLASS_ID)
        self.assertEqual(records[WALKING_STICK], (2, templar['weapon']['subclass']))
        self.assertEqual(templar['weapon']['subclass'], STAFF_SUBCLASS)

    def test_every_class_file_names_its_class(self):
        files = class_file_paths()
        self.assertTrue(files)
        for path in files:
            self.assertIn('class_id', json.loads(path.read_text(encoding='utf-8')), path.name)

    def test_class_file_paths_leaves_out_the_clause_ledger(self):
        self.assertNotIn('templar_clauses.json', [path.name for path in class_file_paths()])

    def test_unknown_class_is_refused(self):
        with self.assertRaises(ValueError):
            load_class_file(0)


def requirement(item_class=2, subclasses=0, inventory_types=0):
    return {'EquippedItemClass': item_class, 'EquippedItemSubClassMask': subclasses,
            'EquippedItemInventoryTypeMask': inventory_types}


class ArmedTest(unittest.TestCase):
    def setUp(self):
        self.templar = load_class_file(TEMPLAR_CLASS_ID)

    def test_a_spell_the_main_weapon_fits_keeps_the_class_file(self):
        for fitting in (requirement(-1, ONE_HAND_MASK), requirement(2, TWO_HAND_MASK, TWO_HAND_INVENTORY_MASK),
                        requirement(2, 0), requirement(4, 1 << 6)):
            with self.subTest(requirement=fitting):
                self.assertIs(armed(self.templar, fitting), self.templar)

    def test_a_spell_the_main_weapon_does_not_fit_takes_the_first_fitting_alternate_and_its_skill(self):
        one_hand = armed(self.templar, requirement(2, ONE_HAND_MASK))
        self.assertEqual(one_hand['weapon'], self.templar['alternate_weapons'][0])
        self.assertEqual(one_hand['skill_lines'], list(TEMPLAR_SKILL_LINES) + [MACES_SKILL_LINE])
        self.assertEqual(one_hand['reference_stats'][skill_label(MACES_SKILL_LINE)], LEVEL_60_SKILL)
        self.assertIs(armed(one_hand, requirement(2, ONE_HAND_MASK)), one_hand)
        self.assertEqual(armed(self.templar, requirement(2, 0, MAIN_HAND_INVENTORY_MASK))['weapon']['item'],
                         FROSTMANE_CLUB)

    def test_no_fitting_weapon_keeps_the_class_file_and_names_the_excluding_field(self):
        dagger_only = requirement(2, 1 << 15)
        self.assertIs(armed(self.templar, dagger_only), self.templar)
        self.assertEqual(unfit_reason(self.templar['weapon'], dagger_only),
                         'EquippedItemSubClassMask 32768 excludes the reference weapon subclass 10')
        self.assertEqual(unfit_reason(self.templar['weapon'], requirement(2, 0, MAIN_HAND_INVENTORY_MASK)),
                         'EquippedItemInventoryTypeMask 2097152 excludes the reference weapon inventory type 17')
        self.assertEqual(unfit_reason(None, dagger_only), 'EquippedItemClass 2 needs a reference weapon')
        self.assertIsNone(unfit_reason(self.templar['weapon'], requirement(-1, 1 << 15)))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_alternate_weapon_subclass_is_the_item_record_subclass(self):
        table = DataSet(DBC_DIR).load('Item')[0]
        records = {item: (item_class, subclass) for item, item_class, subclass
                   in (ITEM_RECORD.unpack_from(table.record(row)) for row in range(table.rows))}
        for weapon in self.templar['alternate_weapons']:
            self.assertEqual(records[weapon['item']], (2, weapon['subclass']))


class BaseStepsTest(unittest.TestCase):
    def setUp(self):
        self.steps = base_steps(load_class_file(TEMPLAR_CLASS_ID))

    def test_settle_wait_comes_first_then_the_weapon_is_equipped(self):
        self.assertEqual(self.steps[0], {'action': 'wait', 'label': 'settle', 'ms': SETTLE_MS})
        add, equip = self.steps[1:3]
        self.assertEqual((add['action'], add['item']), ('add_item', WALKING_STICK))
        self.assertEqual((equip['action'], equip['item'], equip['slot']), ('equip', WALKING_STICK, 15))

    def test_aura_step_exists_for_each_known_and_probed_aura(self):
        auras = {step['label']: step['spell'] for step in self.steps if step.get('metric') == 'aura'}
        self.assertEqual(auras, {f'known_aura {CLASS_TUNING_AURA}': CLASS_TUNING_AURA,
                                 f'probe_aura {SCOURGEBANE}': SCOURGEBANE})

    def test_caster_measurements_cover_power_schools_stats_and_weapon(self):
        by_metric = {}
        for step in self.steps:
            by_metric.setdefault(step.get('metric'), []).append(step)
        self.assertEqual({step['school'] for step in by_metric['spell_power']}, set(range(1, 7)))
        self.assertEqual({step['stat'] for step in by_metric['stat']}, set(range(STAT_COUNT)))
        for metric in ('attack_power', 'ranged_attack_power', 'weapon_damage_min'):
            self.assertEqual(len(by_metric[metric]), 1)

    def test_measurements_are_assertions_with_extreme_bounds_and_unique_labels(self):
        measurements = [step for step in self.steps if step['action'] == 'assert']
        self.assertEqual(len({step['label'] for step in measurements}), len(measurements))
        for step in measurements:
            self.assertLessEqual(step['min'], -10**9)
            self.assertGreaterEqual(step['max'], 10**9)

    def test_base_steps_measure_skills(self):
        lines = []
        for position, step in enumerate(self.steps):
            if step['action'] == 'set_skill':
                self.assertEqual((step['actor'], step['value'], step['maximum']), ('caster', LEVEL_60_SKILL,
                                                                                    LEVEL_60_SKILL))
                measured = self.steps[position + 1]
                self.assertEqual((measured['label'], measured['metric'], measured['skill']),
                                 (skill_label(step['skill']), 'skill_value', step['skill']))
                lines.append(step['skill'])
        self.assertEqual(tuple(lines), TEMPLAR_SKILL_LINES)

    def test_caster_stats_are_rebuilt_from_labelled_measurements(self):
        measured = {'attack_power': 313.0, 'ranged_attack_power': 7.0, 'weapon_damage_min': 9.0}
        measured.update({f'spell_power {school}': float(school) for school in range(1, SPELL_POWER_SCHOOLS + 1)})
        measured.update({f'stat {stat}': 10.0 + stat for stat in range(STAT_COUNT)})
        measured.update({skill_label(line): 295.0 for line in TEMPLAR_SKILL_LINES[:3]})
        self.assertEqual(caster_stats_from(measured, load_class_file(TEMPLAR_CLASS_ID)), CasterStats(
            level=60, ap=313.0, rap=7.0, sp_by_school={school: float(school) for school in range(1, 7)},
            stats={stat: 10.0 + stat for stat in range(STAT_COUNT)},
            skills=dict.fromkeys(TEMPLAR_SKILL_LINES[:3], 295.0), weapon_subclass=STAFF_SUBCLASS, race=HUMAN,
            class_id=TEMPLAR_CLASS_ID))

    def test_class_file_without_weapon_or_auras_yields_only_measurements(self):
        steps = base_steps({'class_id': 1, 'race': 1, 'level': 60})
        self.assertNotIn('equip', {step['action'] for step in steps})
        self.assertNotIn('set_skill', {step['action'] for step in steps})
        self.assertNotIn('aura', {step.get('metric') for step in steps})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ClientDbcValueScenarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.class_file = load_class_file(TEMPLAR_CLASS_ID)
        cls.spells = {spell.spell_id: spell for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER)}
        extra = tuple(entry['spell'] for entry in cls.class_file.get('extra_spells', []))
        cls.extra_spells = {spell.spell_id: spell
                           for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER, extra_spells=extra)}

    def build(self, spell_id, rank_id):
        scenario, expectations, _ = value_scenario(self.class_file, self.spells[spell_id], rank_id)
        return scenario, expectations

    def build_extra(self, spell_id, rank_id):
        scenario, expectations, _ = value_scenario(self.class_file, self.extra_spells[spell_id], rank_id)
        return scenario, expectations

    def test_rank_two_of_argent_blade_learns_the_rank_and_passes_the_harness_validator(self):
        scenario, expectations = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        run.validate(scenario)
        learns = [step for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual([(step['actor'], step['spell']) for step in learns], [('caster', ARGENT_BLADE_RANK_2)])
        self.assertLess(scenario['steps'].index(learns[0]),
                        next(index for index, step in enumerate(scenario['steps'])
                             if step.get('metric') == 'spell_effect_value'))

    def test_effect_zero_value_is_asserted_under_the_label_of_its_expectation(self):
        scenario, expectations = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        by_effect = {item.effect_index: item for item in expectations
                     if item.check == 'effect_value' and item.effect_index is not None}
        for effect, (token, rule) in ARGENT_BLADE_TOOLTIP_TOKENS.items():
            item = by_effect[effect]
            self.assertEqual((item.displayed, item.rule, item.spell_id, item.rank_id),
                             (token, rule, ARGENT_BLADE, ARGENT_BLADE_RANK_2))
            steps = [step for step in scenario['steps'] if step.get('label') == item.label]
            self.assertEqual(len(steps), 1)
            self.assertEqual((steps[0]['metric'], steps[0]['spell'], steps[0]['effect'], steps[0]['actor']),
                             ('spell_effect_value', ARGENT_BLADE_RANK_2, effect, 'caster'))

    def test_every_judged_effect_value_read_carries_a_calc_amount_hook_count_of_the_same_effect(self):
        scenario, expectations = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        judged = [item for item in expectations if item.check == 'effect_value' and item.rule.startswith('read ')]
        self.assertTrue(judged)
        for item in judged:
            read, = self.steps_of(scenario, item.label)
            hooks, = self.steps_of(scenario, calc_amount_hooks_label(item.label))
            self.assertEqual((hooks['metric'], hooks['spell'], hooks['effect'], hooks['actor']),
                             (CALC_AMOUNT_HOOKS_METRIC, read['spell'], read['effect'], read['actor']))
        run.validate(scenario)

    def test_scalingbp_token_reads_as_a_foreign_effect_value_and_gets_a_measurement(self):
        scenario, expectations = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        unreadable = [item for item in expectations if item.rule.startswith(UNREADABLE)]
        self.assertEqual(unreadable, [])
        scourgebane = next(item for item in expectations if item.displayed == ARGENT_BLADE_UNREADABLE)
        self.assertEqual(scourgebane.check, 'effect_value')
        self.assertEqual(scourgebane.model['effect_spell'], SCOURGEBANE_STRIKE)
        self.assertIn(scourgebane.label, measured_labels(scenario))

    def test_cost_and_recast_come_from_the_spell_record_and_are_measured_after_a_cast(self):
        scenario, expectations = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        by_check = {item.check: item for item in expectations if item.check in ('power_cost', 'cooldown_ms')}
        self.assertEqual((by_check['power_cost'].displayed, by_check['power_cost'].rule),
                         (str(ARGENT_BLADE_RANK_2_ENERGY_COST), 'ManaCost divisor 1'))
        self.assertEqual((by_check['cooldown_ms'].displayed, by_check['cooldown_ms'].rule),
                         (str(ARGENT_BLADE_RECAST_MS), 'max(RecoveryTime, CategoryRecoveryTime)'))
        actions = [step['action'] for step in scenario['steps']]
        cast = scenario['steps'][actions.index('cast')]
        self.assertEqual((cast['spell'], cast['target']), (ARGENT_BLADE_RANK_2, 'dummy'))
        power = scenario['steps'][actions.index('set_power')]
        self.assertEqual((power['power'], power['value']), (ENERGY, ARGENT_BLADE_RANK_2_ENERGY_COST))
        steps = {step.get('metric'): step for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertEqual(steps['cooldown_ms']['label'], by_check['cooldown_ms'].label)
        self.assertEqual(steps['spell_power_cost']['label'], by_check['power_cost'].label)
        self.assertGreater(scenario['steps'].index(steps['cooldown_ms']), actions.index('cast'))
        self.assertLess(scenario['steps'].index(steps['spell_power_cost']), actions.index('cast'))
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')

    def test_known_aura_is_listed_as_an_expectation_and_measured_in_the_base_steps(self):
        scenario, expectations = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        known = {item.spell_id: item for item in expectations if item.check == 'known_aura'}
        self.assertEqual(set(known), {CLASS_TUNING_AURA})
        for spell_id, item in known.items():
            steps = [step for step in scenario['steps'] if step.get('label') == item.label]
            self.assertEqual([(step['metric'], step['spell']) for step in steps], [('aura', spell_id)])

    def test_passive_rank_is_never_cast_and_has_no_cost_or_recast_expectation(self):
        scenario, expectations = self.build(SCOURGEBANE, SCOURGEBANE)
        run.validate(scenario)
        self.assertNotIn('cast', {step['action'] for step in scenario['steps']})
        self.assertNotIn('creatures', scenario)
        self.assertFalse({'power_cost', 'cooldown_ms'} & {item.check for item in expectations})

    def test_resurrect_rank_casts_on_a_dead_ally(self):
        scenario, _ = self.build_extra(SPIRITUAL_ASCENSION, SPIRITUAL_ASCENSION_MAX_RANK)
        run.validate(scenario)
        actions = [step['action'] for step in scenario['steps']]
        die = actions.index('die')
        cast = actions.index('cast')
        self.assertEqual(scenario['steps'][die], {'action': 'die', 'actor': 'ally'})
        self.assertLess(die, cast)
        self.assertEqual((scenario['steps'][cast]['spell'], scenario['steps'][cast]['target']),
                         (SPIRITUAL_ASCENSION_MAX_RANK, 'ally'))
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
        self.assertNotIn('creatures', scenario)

    def test_cast_is_preceded_by_the_caster_aura_the_spell_record_requires(self):
        scenario, _ = self.build(RIGHTEOUS_UPHEAVAL, RIGHTEOUS_UPHEAVAL_MAX_RANK)
        run.validate(scenario)
        actions = [step['action'] for step in scenario['steps']]
        cast = actions.index('cast')
        self.assertEqual(scenario['steps'][cast - 1],
                         {'action': 'set_aura', 'actor': 'caster', 'spell': OATH_CHAIN, 'stacks': 1})

    def test_every_vindication_rank_and_upheaval_rank_one_equip_the_one_hand_weapon(self):
        cases = [(VINDICATION, rank) for rank in VINDICATION_RANKS] + [(RIGHTEOUS_UPHEAVAL, RIGHTEOUS_UPHEAVAL)]
        for spell_id, rank_id in cases:
            with self.subTest(rank=rank_id):
                scenario, _ = self.build(spell_id, rank_id)
                run.validate(scenario)
                equipped = [step['item'] for step in scenario['steps'] if step['action'] == 'equip']
                self.assertEqual(equipped, [FROSTMANE_CLUB])
                self.assertIn(skill_label(MACES_SKILL_LINE), measured_labels(scenario))
        scenario, _ = self.build(RIGHTEOUS_UPHEAVAL, RIGHTEOUS_UPHEAVAL_MAX_RANK)
        self.assertEqual([step['item'] for step in scenario['steps'] if step['action'] == 'equip'], [WALKING_STICK])

    def test_rolled_effect_value_is_read_as_often_as_its_mean_needs(self):
        scenario, expectations = self.build(VINDICATION, VINDICATION_RANK_2)
        run.validate(scenario)
        item = next(item for item in expectations if item.label == VINDICATION_ROLLED_LABEL)
        samples = item.model['samples']
        self.assertGreater(samples, 1)
        reads = [step for step in scenario['steps'] if step.get('label') in sample_labels(item.label, samples)]
        self.assertEqual([step['label'] for step in reads], sample_labels(item.label, samples))
        self.assertEqual({(step['metric'], step['spell'], step['effect']) for step in reads},
                         {('spell_effect_value', VINDICATION_RANK_2, 0)})

    def test_rolled_effect_value_whose_reads_exceed_the_step_limit_is_read_once(self):
        with mock.patch('values.MAX_SCENARIO_STEPS', 60):
            scenario, expectations = self.build(VINDICATION, VINDICATION_RANK_2)
        item = next(item for item in expectations if item.label == VINDICATION_ROLLED_LABEL)
        self.assertEqual(item.model['samples'], 1)
        self.assertEqual([step['label'] for step in scenario['steps'] if step.get('label', '').startswith(item.label)],
                         [item.label, calc_amount_hooks_label(item.label), effect_modifier_label(item.label, 'all'),
                          effect_modifier_label(item.label, 0)])

    def test_an_effect_value_with_a_per_level_term_reads_its_effect_modifiers(self):
        scenario, expectations = self.build(VINDICATION, VINDICATION_RANK_2)
        item = next(item for item in expectations if item.label == VINDICATION_ROLLED_LABEL)
        labels = (effect_modifier_label(item.label, 'all'), effect_modifier_label(item.label, 0))
        reads = [step for step in scenario['steps'] if step.get('label') in labels]
        self.assertEqual([(step['metric'], step['op'], step['base'], step['spell']) for step in reads],
                         [('spell_modifier', 8, 1000, VINDICATION_RANK_2),
                          ('spell_modifier', 3, 1000, VINDICATION_RANK_2)])

    def test_spell_without_a_required_caster_aura_sets_no_aura(self):
        scenario, _ = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        self.assertNotIn('set_aura', {step['action'] for step in scenario['steps']})

    def test_rank_outside_the_spell_is_refused(self):
        with self.assertRaises(ValueError):
            self.build(ARGENT_BLADE, SCOURGEBANE)

    def test_level_scaled_tooltip_is_read_through_the_skill_rank(self):
        scenario, expectations = self.build(HOLY_CONSTITUTION, HOLY_CONSTITUTION)
        self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])
        item = next(item for item in expectations if item.displayed == '${$m1+0}')
        self.assertEqual((item.check, item.effect_index, item.rule), ('effect_value', 0, 'read flat'))
        readout = read_tooltip(DataSet(DBC_DIR), HOLY_CONSTITUTION, caster_stats_from(
            {**self.class_file['reference_stats'], **{skill_label(line): float(LEVEL_60_SKILL)
                                                      for line in TEMPLAR_SKILL_LINES}}, self.class_file))
        level_points = HOLY_CONSTITUTION_PER_LEVEL * (60 - HOLY_CONSTITUTION_BASE_LEVEL)
        self.assertEqual(next(value.value for value in readout.values if value.text == '${$m1+0}'),
                         HOLY_CONSTITUTION_BASE_POINTS + 1 + level_points)

    def steps_of(self, scenario, label):
        return [step for step in scenario['steps'] if step.get('label') == label]

    def test_own_seconds_token_is_measured_on_its_effect(self):
        scenario, expectations = self.build(LIBERTY, LIBERTY)
        item = next(item for item in expectations if item.displayed == '$/1000;s1')
        self.assertEqual((item.check, item.effect_index, item.rule), ('effect_value', 0, 'read duration_ms'))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect']), ('spell_effect_value', LIBERTY, 0))

    def test_periodic_total_is_left_to_the_hit_scenario(self):
        scenario, expectations, periodic_totals = value_scenario(self.class_file, self.spells[BLADE_OF_FAITH],
                                                                  BLADE_OF_FAITH_MAX_RANK)
        self.assertFalse([item for item in expectations if item.displayed == BLADE_OF_FAITH_TOTAL])
        self.assertEqual(periodic_totals, [{'label': f'{BLADE_OF_FAITH_MAX_RANK} effect_value #0', 'effect': 0}])
        self.assertFalse(self.steps_of(scenario, periodic_totals[0]['label']))

    def test_own_amplitude_token_is_measured_after_a_cast(self):
        scenario, expectations = self.build(RIGHTEOUS_TEMPEST, RIGHTEOUS_TEMPEST_MAX_RANK)
        item, = [item for item in expectations if item.displayed == '$t1']
        self.assertEqual((item.check, item.effect_index, item.rule), ('aura_amplitude_ms', 0, 'read amplitude_ms'))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect'], step['caster']),
                         ('aura_amplitude_ms', RIGHTEOUS_TEMPEST_MAX_RANK, 0, 'caster'))

    def test_own_radius_token(self):
        scenario, expectations = self.build_extra(CRUSADERS_PRESENCE, CRUSADERS_PRESENCE)
        item, = [item for item in expectations if item.displayed == '$a1']
        self.assertEqual((item.check, item.effect_index, item.rule), ('effect_radius', 0, 'read radius_yards'))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect']), ('spell_effect_radius', CRUSADERS_PRESENCE, 0))

    def test_foreign_radius_token(self):
        scenario, expectations = self.build(NORGANNONS_WRATH, NORGANNONS_WRATH)
        item, = [item for item in expectations if item.displayed == '$524740a1']
        self.assertEqual((item.check, item.effect_index, item.rule, item.model),
                         ('effect_radius', None, 'read radius_yards',
                          {'effect_spell': NORGANNONS_WRATH_RADIUS_SPELL, 'effect': 0}))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect']),
                         ('spell_effect_radius', NORGANNONS_WRATH_RADIUS_SPELL, 0))

    def test_foreign_radius_token_of_a_server_disabled_effect_stays_unmeasurable(self):
        scenario, expectations = self.build(TESTAMENT_OF_HOPE, TESTAMENT_OF_HOPE)
        item, = [item for item in expectations if item.displayed == '$704409a1']
        reason = 'effect 0 of spell 704409 is disabled by a server correction'
        self.assertEqual((item.check, item.effect_index, item.rule), ('effect_radius', None, UNMEASURABLE + reason))
        self.assertFalse(self.steps_of(scenario, item.label))

    def test_own_amplitude_token(self):
        scenario, expectations = self.build_extra(RIGHTEOUS_CUSTODIAN, RIGHTEOUS_CUSTODIAN)
        item, = [item for item in expectations if item.displayed == '$t1']
        self.assertEqual((item.check, item.effect_index, item.rule), ('aura_amplitude_ms', 0, 'read amplitude_ms'))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect'], step['caster']),
                         ('aura_amplitude_ms', RIGHTEOUS_CUSTODIAN, 0, 'caster'))

    def test_own_stack_token(self):
        scenario, expectations = self.build_extra(CONDEMN, CONDEMN)
        item, = [item for item in expectations if item.displayed == '$u']
        self.assertEqual((item.check, item.rule, item.model), ('max_stacks', 'read count', None))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['actor']),
                         ('spell_max_stacks', CONDEMN, 'caster'))

    def test_foreign_value_token(self):
        scenario, expectations = self.build(SCOURGEBANE, SCOURGEBANE)
        run.validate(scenario)
        item = next(item for item in expectations if item.displayed == '$801832s2')
        self.assertEqual((item.check, item.effect_index, item.rule), ('effect_value', None, 'read percent'))
        self.assertEqual(item.model, {'effect_spell': SCOURGEBANE_STRIKE, 'effect': 1})
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect'], step['actor']),
                         ('spell_effect_value', SCOURGEBANE_STRIKE, 1, 'caster'))

    def test_foreign_expression_is_measured_on_its_first_effect_token(self):
        scenario, expectations = self.build(SCOURGEBANE, SCOURGEBANE)
        item = next(item for item in expectations if item.displayed.startswith('${$801832m1'))
        self.assertEqual((item.rule, item.model), ('read flat', {'effect_spell': SCOURGEBANE_STRIKE, 'effect': 0}))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['spell'], step['effect']), (SCOURGEBANE_STRIKE, 0))

    def test_foreign_stack_token(self):
        scenario, expectations = self.build(IRON_PENANCE, IRON_PENANCE)
        run.validate(scenario)
        item = next(item for item in expectations if item.displayed == '$523713u')
        self.assertEqual((item.check, item.rule, item.model),
                         ('max_stacks', 'read count', {'effect_spell': IRON_PENANCE_DEBUFF}))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['actor']),
                         ('spell_max_stacks', IRON_PENANCE_DEBUFF, 'caster'))

    def test_foreign_duration_token(self):
        scenario, expectations = self.build(KEEPING_THE_OATH, KEEPING_THE_OATH)
        run.validate(scenario)
        item = next(item for item in expectations if item.displayed == '$803237d')
        self.assertEqual((item.check, item.effect_index, item.rule, item.model),
                         ('spell_duration', None, 'read duration_ms', {'effect_spell': KEEPING_THE_OATH_AURA}))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['actor']),
                         ('spell_duration_ms', KEEPING_THE_OATH_AURA, 'caster'))

    def test_foreign_aura_grant_is_proven_live_on_the_actual_ally(self):
        scenario, expectations = self.build_extra(TESTAMENT_OF_RESOLVE, TESTAMENT_OF_RESOLVE)
        run.validate(scenario)
        self.assertIn((TESTAMENT_OF_RESOLVE, SACRED_RESTRAINT), foreign_aura_grants(self.class_file))
        label = f'{TESTAMENT_OF_RESOLVE} aura_duration_ms {SACRED_RESTRAINT} #1'
        item = next(item for item in expectations if item.label == label)
        self.assertEqual(item.check, 'aura_duration_ms')
        step, = self.steps_of(scenario, label)
        self.assertEqual((step['metric'], step['spell'], step['actor'], step['caster']),
                         ('aura_duration_ms', SACRED_RESTRAINT, ALLY, 'caster'))
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual([step.get('target') for step in casts], [None, ALLY])
        reset_step = next(step for step in scenario['steps'] if step['action'] == 'reset_cooldown'
                          and step['spell'] == TESTAMENT_OF_RESOLVE)
        self.assertIn(ALLY, {player['id'] for player in scenario['players']})
        own_duration_step, = self.steps_of(scenario, f'{TESTAMENT_OF_RESOLVE} aura_duration_ms #0')
        self.assertEqual(own_duration_step['actor'], 'caster')
        self.assertLess(scenario['steps'].index(own_duration_step), scenario['steps'].index(step))
        second_cast = next(step for step in scenario['steps']
                           if step['action'] == 'cast' and step.get('target') == ALLY)
        reset_index = scenario['steps'].index(reset_step)
        second_cast_index = scenario['steps'].index(second_cast)
        waits_between = [step for step in scenario['steps'][reset_index + 1:second_cast_index]
                         if step['action'] == 'wait']
        self.assertTrue(waits_between, 'the recast after reset_cooldown needs a global-cooldown wait')
        self.assertGreaterEqual(sum(w['ms'] for w in waits_between), GCD_WAIT_MS)

    def test_foreign_aura_grant_on_a_self_targeted_spell_stays_on_the_caster(self):
        scenario, expectations = self.build(TESTAMENT_OF_HOPE, TESTAMENT_OF_HOPE)
        run.validate(scenario)
        label = f'{TESTAMENT_OF_HOPE} aura_duration_ms {SACRED_RESTRAINT} #4'
        item = next(item for item in expectations if item.label == label)
        self.assertEqual(item.check, 'aura_duration_ms')
        step, = self.steps_of(scenario, label)
        self.assertEqual((step['metric'], step['spell'], step['actor']),
                         ('aura_duration_ms', SACRED_RESTRAINT, 'caster'))
        self.assertNotIn(ALLY, {player['id'] for player in scenario['players']})
        self.assertEqual([step for step in scenario['steps'] if step['action'] == 'reset_cooldown'], [])

    def test_foreign_duration_without_a_grant_entry_stays_computed_only(self):
        scenario, expectations = self.build(KEEPING_THE_OATH, KEEPING_THE_OATH)
        label = f'{KEEPING_THE_OATH} aura_duration_ms {KEEPING_THE_OATH_AURA} #0'
        self.assertNotIn((KEEPING_THE_OATH, KEEPING_THE_OATH_AURA), foreign_aura_grants(self.class_file))
        self.assertFalse([item for item in expectations if item.label == label])
        self.assertFalse(self.steps_of(scenario, label))

    def test_foreign_chance_stays_unmeasurable(self):
        scenario, expectations = self.build(SCOURGEBANE, SCOURGEBANE)
        item = next(item for item in expectations if item.displayed == '$520007h')
        self.assertTrue(item.rule.startswith(UNMEASURABLE + 'chance_pct token'), item.rule)
        self.assertIn('"92111 proc_rate"', item.rule)
        self.assertFalse(self.steps_of(scenario, item.label))
        self.assertNotIn('spell_proc_chance', {step.get('metric') for step in scenario['steps']})
        self.assertNotIn('set_aura', {step['action'] for step in scenario['steps']})

    def test_foreign_count_stays_unmeasurable_without_a_chance_cross_reference(self):
        scenario, expectations = self.build(NORGANNONS_WRATH, NORGANNONS_WRATH)
        item = next(item for item in expectations if item.displayed == '$524740i')
        self.assertEqual(item.rule, UNMEASURABLE + 'count token without a no-combat metric')
        self.assertFalse(self.steps_of(scenario, item.label))

    def test_expanded_token_is_measured_on_the_referenced_spell(self):
        scenario, expectations = self.build(ZEALOTRY_PASSIVE, ZEALOTRY_PASSIVE)
        run.validate(scenario)
        item = next(item for item in expectations if item.displayed == '$s2')
        self.assertEqual((item.check, item.effect_index, item.rule, item.model),
                         ('effect_value', None, 'read percent', {'effect_spell': ZEALOTRY, 'effect': 1}))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect']), ('spell_effect_value', ZEALOTRY, 1))
        self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])

    def test_expanded_durations_are_measured_on_the_referenced_spells(self):
        scenario, expectations = self.build(GLORY, GLORY)
        run.validate(scenario)
        durations = [(item.check, item.model) for item in expectations if item.displayed == '$d']
        self.assertEqual(durations, [('aura_duration_ms', None), ('spell_duration', {'effect_spell': DOWNFALL}),
                                     ('spell_duration', {'effect_spell': REDEMPTION})])

    def test_expansion_without_token(self):
        scenario, expectations = self.build(SACRED_OATH, SACRED_OATH)
        run.validate(scenario)
        unreadable = [item.rule for item in expectations if item.rule.startswith(UNREADABLE)]
        self.assertEqual(unreadable, [])
        generic = [item.rule for item in expectations if item.rule.startswith(GENERIC)]
        self.assertEqual(generic, [GENERIC + 'tooltip has no $ token to check (prose-only effect; see README '
                                           '"Tooltip reading")'])

    def test_client_extension_note_is_classified_as_generic_not_unreadable(self):
        scenario, expectations = self.build(LIBRAM_OF_TENACITY, LIBRAM_OF_TENACITY)
        run.validate(scenario)
        self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])
        generic = [item.rule for item in expectations if item.rule.startswith(GENERIC)]
        self.assertEqual(len(generic), 1)
        self.assertIn('@ext:', generic[0])

    def test_known_spells_parameter_still_adds_a_live_learn_step_for_a_future_state_dependent_conditional(self):
        scenario, _, _ = value_scenario(self.class_file, self.spells[VINDICATION], VINDICATION, frozenset({707385}))
        learns = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learns, [VINDICATION, 707385])

    def test_conditional_true_branch_names_a_foreign_spells_own_effect(self):
        scenario, expectations = self.build(ETERNAL_BLESSING, ETERNAL_BLESSING)
        run.validate(scenario)
        self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])
        foreign = next(item for item in expectations if item.model and item.model.get('effect_spell') == LIBRAMS)
        self.assertEqual(foreign.check, 'effect_value')
        self.assertIn('the true branch of the $?s573452 conditional', foreign.rule)
        self.assertIn(foreign.label, measured_labels(scenario))
        learns = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learns, [ETERNAL_BLESSING])

    def test_conditional_true_branch_names_the_gating_spells_own_effect(self):
        scenario, expectations = self.build_extra(CHASTISE, CHASTISE)
        run.validate(scenario)
        self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])
        foreign = next(item for item in expectations
                      if item.model and item.model.get('effect_spell') == CHASTISE_GATING)
        self.assertEqual((foreign.check, foreign.model['effect']), ('effect_value', 0))
        self.assertIn('the true branch of the $?s806525 conditional', foreign.rule)
        self.assertIn(foreign.label, measured_labels(scenario))
        learns = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learns, [CHASTISE])

    def test_conditional_true_branch_on_a_mid_sentence_gate_is_the_token_after_it_not_a_trailing_one(self):
        scenario, expectations = self.build(RIGHTEOUS_TEMPEST, RIGHTEOUS_TEMPEST)
        run.validate(scenario)
        foreign = next(item for item in expectations
                      if item.model and item.model.get('effect_spell') == RIGHTEOUS_TEMPEST_GATING)
        self.assertEqual((foreign.check, foreign.model['effect'], foreign.displayed), ('effect_value', 1,
                                                                                       '$300512s2'))
        self.assertIn(foreign.label, measured_labels(scenario))
        self.assertTrue([item for item in expectations if item.check == 'aura_duration_ms'])

    def spell_owning_rank(self, rank_id):
        return next(spell for group in (self.spells, self.extra_spells) for spell in group.values()
                    if rank_id in spell.ranks)

    def test_every_static_conditional_entry_yields_its_declared_gating_spell_token(self):
        for entry in self.class_file['conditional_spells']:
            with self.subTest(spell=entry['spell']):
                spell = self.spell_owning_rank(entry['spell'])
                scenario, expectations, _ = value_scenario(self.class_file, spell, entry['spell'])
                run.validate(scenario)
                conditional = [item for item in expectations if 'the true branch of the $?s' in item.rule]
                self.assertEqual(len(conditional), 1, entry)
                self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])

    def test_periodic_total_token_is_routed_through_the_existing_periodic_explanation(self):
        scenario, expectations, periodic_totals = value_scenario(self.class_file, self.extra_spells[LIGHTS_HOPE],
                                                                  LIGHTS_HOPE)
        run.validate(scenario)
        self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])
        self.assertEqual(len(periodic_totals), 1)

    def test_trailing_digit_on_a_proc_count_token_is_unmeasurable_not_unreadable(self):
        scenario, expectations = self.build(LIGHTKEEPER, LIGHTKEEPER)
        run.validate(scenario)
        self.assertFalse([item for item in expectations if item.rule.startswith(UNREADABLE)])

    def test_every_templar_rank_has_a_valid_scenario_and_no_dropped_expectation(self):
        all_periodic_total_labels = []
        for spell in self.spells.values():
            for rank_id in spell.ranks:
                scenario, expectations, periodic_totals = value_scenario(self.class_file, spell, rank_id)
                run.validate(scenario)
                labels = [item.label for item in expectations]
                self.assertEqual(len(labels), len(set(labels)), rank_id)
                self.assertTrue([item for item in expectations if item.check != 'known_aura'], rank_id)
                measured = measured_labels(scenario)
                for item in expectations:
                    self.assertIn(item.check, CHECKS)
                    self.assertIsInstance(item, Expectation)
                    if item.label not in measured:
                        self.assertTrue(item.rule.startswith((UNREADABLE, UNMEASURABLE, GENERIC)), (rank_id, item))
                    step_labels = [step.get('label') for step in scenario['steps']]
                    self.assertLessEqual(step_labels.count(item.label), 1, (rank_id, item.label))
                total_labels = [item['label'] for item in periodic_totals]
                self.assertFalse(set(total_labels) & set(labels), rank_id)
                all_periodic_total_labels += total_labels
        self.assertEqual(len(all_periodic_total_labels), len(set(all_periodic_total_labels)))


class ConditionalExtraValuesTest(unittest.TestCase):
    def shown(self, text):
        return Displayed(text, 1.0, None, 'flat', None)

    def test_the_inserted_token_is_found_even_when_it_is_not_trailing(self):
        base = [self.shown('$a'), self.shown('$b')]
        gated = [self.shown('$a'), self.shown('$new'), self.shown('$b')]
        self.assertEqual(conditional_extra_values(base, gated, 1, 2), [gated[1]])

    def test_a_trailing_insertion_is_found_too(self):
        base = [self.shown('$a')]
        gated = [self.shown('$a'), self.shown('$new')]
        self.assertEqual(conditional_extra_values(base, gated, 1, 2), [gated[1]])

    def test_no_extra_token_raises_instead_of_silently_passing(self):
        base = [self.shown('$a')]
        with self.assertRaises(ValueError):
            conditional_extra_values(base, base, 1, 2)

    def test_a_missing_base_token_raises_instead_of_guessing(self):
        base = [self.shown('$a'), self.shown('$b')]
        gated = [self.shown('$a'), self.shown('$new')]
        with self.assertRaises(ValueError):
            conditional_extra_values(base, gated, 1, 2)


class ForeignEffectFixtureTest(unittest.TestCase):
    def test_effect_that_the_referenced_record_does_not_define_is_never_measured(self):
        with tempfile.TemporaryDirectory() as temp:
            write_fixture(Path(temp), FIXTURE_SPELLS, FIXTURE_VARIABLES)
            dbc = DataSet(Path(temp))
            shown = read_tooltip(dbc, 13, FIXTURE_CASTER).values[0]
            self.assertEqual((shown.text, shown.spell_id), ('$10s2', 10))
            self.assertEqual(foreign_effect(Records(dbc), 13, shown), (None, 'effect 1 of spell 10 does not exist'))

    def test_foreign_radius_of_a_disabled_effect_is_unmeasurable(self):
        with tempfile.TemporaryDirectory() as temp:
            write_fixture(Path(temp), FIXTURE_SPELLS, FIXTURE_VARIABLES)
            records = Records(DataSet(Path(temp)))
            shown = Displayed('$43a1', 8.0, None, 'radius_yards', 43)
            self.assertEqual(foreign_radius(records, 99, shown), ({'effect_spell': 43, 'effect': 0}, ''))
            disabled = frozenset({(43, 0)})
            self.assertEqual(foreign_radius(records, 99, shown, disabled),
                             (None, 'effect 0 of spell 43 is disabled by a server correction'))

    def test_disabled_foreign_effects_reads_the_class_file_entries(self):
        self.assertEqual(disabled_foreign_effects({'disabled_foreign_effects': [{'spell': 43, 'effect': 0}]}),
                         frozenset({(43, 0)}))
        self.assertEqual(disabled_foreign_effects({}), frozenset())

    def test_seconds_of_an_aura_with_an_amplitude_stay_a_judged_value(self):
        with tempfile.TemporaryDirectory() as temp:
            write_fixture(Path(temp), FIXTURE_SPELLS, FIXTURE_VARIABLES)
            records = Records(DataSet(Path(temp)))
            for spell_id in (NON_PERIODIC_AURA_WITH_AMPLITUDE, PERIODIC_AURA_WITH_SECONDS):
                with self.subTest(spell=spell_id):
                    shown = read_tooltip(records.dbc, spell_id, FIXTURE_CASTER).values[0]
                    self.assertEqual((shown.text, shown.effect_index, shown.kind), ('$/1000;s1', 0, 'duration_ms'))
                    self.assertEqual(periodic_reason(records, spell_id, FIXTURE_CASTER, shown), '')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class RequiredTargetHealthStepsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.records = Records(DataSet(DBC_DIR))

    def test_a_spell_without_a_target_aura_state_needs_no_fixture(self):
        facts = facts_of(self.records, VINDICATION_RANK_2)
        self.assertEqual(facts.target_aura_state, 0)
        self.assertEqual(required_target_health_steps(facts), [])

    def test_titanstrike_establishes_the_healthless_35_percent_fixture(self):
        facts = facts_of(self.records, TITANSTRIKE_MAX_RANK)
        self.assertEqual(facts.target_aura_state, AURA_STATE_HEALTHLESS_35_PERCENT)
        self.assertEqual(required_target_health_steps(facts),
                         [{'action': 'set_health_pct', 'actor': CASTER, 'target': TARGET, 'pct': 30},
                          {'action': 'wait', 'ms': 1000}])

    def test_a_different_target_id_is_used_verbatim(self):
        facts = facts_of(self.records, TITANSTRIKE_MAX_RANK)
        steps = required_target_health_steps(facts, 'leech_before')
        self.assertEqual(steps[0]['target'], 'leech_before')

    def test_an_unmapped_aura_state_raises_unmodelled_instead_of_a_silent_skip(self):
        facts = replace(facts_of(self.records, TITANSTRIKE_MAX_RANK), target_aura_state=99)
        with self.assertRaises(Unmodelled) as raised:
            required_target_health_steps(facts)
        self.assertIn('target aura state 99 has no scenario fixture', raised.exception.reason)


class FixtureHealthStepTest(unittest.TestCase):
    def test_sets_health_to_a_percentage_of_the_shared_fixture_maximum(self):
        self.assertEqual(fixture_health_step('ally', 50),
                         {'action': 'set_health', 'actor': 'ally', 'value': FIXTURE_MAX_HEALTH // 2,
                          'maximum': FIXTURE_MAX_HEALTH})

    def test_the_actor_is_used_verbatim(self):
        self.assertEqual(fixture_health_step(CASTER, 100)['actor'], CASTER)


if __name__ == '__main__':
    unittest.main()
