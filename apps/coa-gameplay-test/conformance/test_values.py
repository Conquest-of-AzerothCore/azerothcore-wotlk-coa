import json
from pathlib import Path
import sys
import tempfile
import unittest

from classes import class_spells
from profile import CLASSES_DIR, base_steps, caster_stats_from, load_class_file
from test_tooltip import FIXTURE_CASTER, FIXTURE_SPELLS, FIXTURE_VARIABLES, write_fixture
from tooltip import CasterStats, DataSet, Records, read_tooltip
from values import CHECKS, UNMEASURABLE, UNREADABLE, Expectation, foreign_effect, value_scenario

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

DBC_DIR = Path('/srv/coa/server-data/dbc')
HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'

TEMPLAR_CLASS_ID = 19
WALKING_STICK = 2495
SCOURGEBANE = 92111
CLASS_TUNING_AURA = 887007
ARGENT_BLADE = 804929
ARGENT_BLADE_RANK_2 = 807263
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

    def test_every_class_file_names_its_class(self):
        files = sorted(CLASSES_DIR.glob('*.json'))
        self.assertTrue(files)
        for path in files:
            self.assertIn('class_id', json.loads(path.read_text(encoding='utf-8')), path.name)

    def test_unknown_class_is_refused(self):
        with self.assertRaises(ValueError):
            load_class_file(0)


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

    def test_caster_stats_are_rebuilt_from_labelled_measurements(self):
        measured = {'attack_power': 313.0, 'ranged_attack_power': 7.0, 'weapon_damage_min': 9.0}
        measured.update({f'spell_power {school}': float(school) for school in range(1, SPELL_POWER_SCHOOLS + 1)})
        measured.update({f'stat {stat}': 10.0 + stat for stat in range(STAT_COUNT)})
        self.assertEqual(caster_stats_from(measured, 60), CasterStats(
            level=60, ap=313.0, rap=7.0, sp_by_school={school: float(school) for school in range(1, 7)},
            stats={stat: 10.0 + stat for stat in range(STAT_COUNT)}))

    def test_class_file_without_weapon_or_auras_yields_only_measurements(self):
        steps = base_steps({'class_id': 1, 'race': 1, 'level': 60})
        self.assertNotIn('equip', {step['action'] for step in steps})
        self.assertNotIn('aura', {step.get('metric') for step in steps})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ClientDbcValueScenarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.class_file = load_class_file(TEMPLAR_CLASS_ID)
        cls.spells = {spell.spell_id: spell for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER)}

    def build(self, spell_id, rank_id):
        return value_scenario(self.class_file, self.spells[spell_id], rank_id)

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

    def test_unreadable_tooltip_part_still_gets_a_measurement_and_a_named_rule(self):
        scenario, expectations = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        unreadable = [item for item in expectations if item.rule.startswith(UNREADABLE)]
        self.assertEqual([item.displayed for item in unreadable], [ARGENT_BLADE_UNREADABLE])
        self.assertIn(unreadable[0].label, measured_labels(scenario))
        self.assertIn(ARGENT_BLADE_UNREADABLE, unreadable[0].rule)

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

    def test_cast_is_preceded_by_the_caster_aura_the_spell_record_requires(self):
        scenario, _ = self.build(RIGHTEOUS_UPHEAVAL, RIGHTEOUS_UPHEAVAL_MAX_RANK)
        run.validate(scenario)
        actions = [step['action'] for step in scenario['steps']]
        cast = actions.index('cast')
        self.assertEqual(scenario['steps'][cast - 1],
                         {'action': 'set_aura', 'actor': 'caster', 'spell': OATH_CHAIN, 'stacks': 1})

    def test_spell_without_a_required_caster_aura_sets_no_aura(self):
        scenario, _ = self.build(ARGENT_BLADE, ARGENT_BLADE_RANK_2)
        self.assertNotIn('set_aura', {step['action'] for step in scenario['steps']})

    def test_rank_outside_the_spell_is_refused(self):
        with self.assertRaises(ValueError):
            self.build(ARGENT_BLADE, SCOURGEBANE)

    def test_level_scaled_tooltip_is_unreadable_but_still_measured(self):
        scenario, expectations = self.build(HOLY_CONSTITUTION, HOLY_CONSTITUTION)
        unreadable = [item for item in expectations if item.rule.startswith(UNREADABLE)]
        self.assertTrue(unreadable)
        for item in unreadable:
            self.assertEqual(item.check, 'effect_value')

    def steps_of(self, scenario, label):
        return [step for step in scenario['steps'] if step.get('label') == label]

    def test_own_seconds_token_is_measured_on_its_effect(self):
        scenario, expectations = self.build(LIBERTY, LIBERTY)
        item = next(item for item in expectations if item.displayed == '$/1000;s1')
        self.assertEqual((item.check, item.effect_index, item.rule), ('effect_value', 0, 'read duration_ms'))
        step, = self.steps_of(scenario, item.label)
        self.assertEqual((step['metric'], step['spell'], step['effect']), ('spell_effect_value', LIBERTY, 0))

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

    def test_foreign_chance_stays_unmeasurable(self):
        scenario, expectations = self.build(SCOURGEBANE, SCOURGEBANE)
        item = next(item for item in expectations if item.displayed == '$520007h')
        self.assertTrue(item.rule.startswith(UNMEASURABLE + 'chance_pct token'), item.rule)
        self.assertFalse(self.steps_of(scenario, item.label))
        self.assertNotIn('spell_proc_chance', {step.get('metric') for step in scenario['steps']})
        self.assertNotIn('set_aura', {step['action'] for step in scenario['steps']})

    def test_every_templar_rank_has_a_valid_scenario_and_no_dropped_expectation(self):
        for spell in self.spells.values():
            for rank_id in spell.ranks:
                scenario, expectations = value_scenario(self.class_file, spell, rank_id)
                run.validate(scenario)
                labels = [item.label for item in expectations]
                self.assertEqual(len(labels), len(set(labels)), rank_id)
                self.assertTrue([item for item in expectations if item.check != 'known_aura'], rank_id)
                measured = measured_labels(scenario)
                for item in expectations:
                    self.assertIn(item.check, CHECKS)
                    self.assertIsInstance(item, Expectation)
                    if item.label not in measured:
                        self.assertTrue(item.rule.startswith((UNREADABLE, UNMEASURABLE)), (rank_id, item))
                    step_labels = [step.get('label') for step in scenario['steps']]
                    self.assertLessEqual(step_labels.count(item.label), 1, (rank_id, item.label))


class ForeignEffectFixtureTest(unittest.TestCase):
    def test_effect_that_the_referenced_record_does_not_define_is_never_measured(self):
        with tempfile.TemporaryDirectory() as temp:
            write_fixture(Path(temp), FIXTURE_SPELLS, FIXTURE_VARIABLES)
            dbc = DataSet(Path(temp))
            shown = read_tooltip(dbc, 13, FIXTURE_CASTER).values[0]
            self.assertEqual((shown.text, shown.spell_id), ('$10s2', 10))
            self.assertEqual(foreign_effect(Records(dbc), 13, shown), (None, 'effect 1 of spell 10 does not exist'))


if __name__ == '__main__':
    unittest.main()
