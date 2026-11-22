import random
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

INSTANT = {'spell': 804629, 'name': 'Spears of Glory (instant)', 'kind': 'aura_fed_effect', 'variant': 'instant',
           'label_suffix': 'fed_instant', 'quote': 'chance to grant you Spears of Glory.', 'feed_spell': 806060,
           'aura': 807299, 'effect_spell': 554406, 'every_ms': 4300, 'residual_target': 0.001, 'feed_power': 1000,
           'effect_power': 1363, 'expected': 0, 'caster_auras': [823764]}
DAMAGE = {**INSTANT, 'name': 'Spears of Glory (damage)', 'variant': 'damage', 'label_suffix': 'fed_damage',
          'expected': 1.25, 'trials': 6, 'fixture': {'spell_power': 10000}}
HEAL = {'spell': 704920, 'name': 'Cultivate Divinity (Illumination)', 'kind': 'aura_fed_effect', 'variant': 'heal',
        'label_suffix': 'fed_heal', 'quote': 'to increase the healing of your next Illumination',
        'feed_spell': 500141, 'aura': 301293, 'effect_spell': 500143, 'every_ms': 3500, 'residual_target': 0.001,
        'feed_power': 1363, 'effect_power': 1363, 'expected': 1.2, 'trials': 4}
SIZED_HEAL = {**HEAL, 'name': 'Cultivate Divinity (Radiant Cascade)', 'variant': 'heal_cascade',
              'label_suffix': 'fed_heal_cascade', 'quote': 'to increase the healing of your next Radiant Cascade',
              'feed_spell': 500143, 'aura': 300354, 'effect_spell': 500141, 'chance_spell': 707520, 'trials': 12,
              'fixture': {'spell_power': 20000}}
SIZED_DAMAGE = {**DAMAGE, 'name': 'Spears of Glory (sized damage)', 'sized': True, 'figure_effect': 1,
                'min_hits': 4, 'consumed': True, 'trials': 14, 'fixture': {'spell_power': 20000}}
COOLDOWN = {'spell': 503690, 'name': 'Dawn\'s Arrival (free Gavel)', 'kind': 'aura_fed_effect',
            'variant': 'cooldown', 'label_suffix': 'fed_cooldown', 'feed_spell': 800654, 'aura': 503691,
            'effect_spell': 800611, 'every_ms': 1700, 'residual_target': 0.001, 'feed_power': 1363,
            'effect_power': 1363, 'expected': 0, 'trials': 8,
            'quote': 'causes the next one to not incur a cooldown'}
CONTROL_HIT = 8800.0
SEED = 704920


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraFedEffectTests(unittest.TestCase):
    def generated(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def judged(self, entry, values):
        _, expectation = self.generated(entry)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def instant_values(self, control=1.0, fed=0.0, fed_aura=1.0, control_went=1.0, fed_went=2.0):
        _, expectation = self.generated(INSTANT)
        reads = expectation.model['reads']
        return {reads['control'][0]['aura']: 0.0, reads['control'][0]['casting']: control,
                reads['control'][0]['went']: control_went, reads['treatment'][0]['aura']: fed_aura,
                reads['treatment'][0]['casting']: fed, reads['treatment'][0]['went']: fed_went}

    def damage_values(self, factor, fed_aura=1.0):
        _, expectation = self.generated(DAMAGE)
        values, count, total = {}, 0.0, 0.0
        for arm, hit, aura in (('control', CONTROL_HIT, 0.0), ('treatment', CONTROL_HIT * factor, fed_aura)):
            for trial in expectation.model['reads'][arm]:
                count, total = count + 1, total + hit
                values.update({trial['aura']: aura, trial['hits']: count, trial['damage']: total})
        return values

    def sized_damage_values(self, factor, again=1.0, spread=0.0025, entry=SIZED_DAMAGE, critical=()):
        _, expectation = self.generated(entry)
        draw = random.Random(SEED)
        values, count, total = {}, 0.0, 0.0
        for arm, hit, aura in (('control', CONTROL_HIT, 0.0), ('treatment', CONTROL_HIT * factor, 1.0)):
            for index, trial in enumerate(expectation.model['reads'][arm]):
                if (arm, index) not in critical:
                    count, total = count + 1, total + hit * (1 + draw.gauss(0, spread))
                values.update({trial['aura']: aura, trial['hits']: count, trial['damage']: total})
                if 'next_hits' in trial:
                    count, total = count + 1, total + CONTROL_HIT * again * (1 + draw.gauss(0, spread))
                    values.update({trial['next_hits']: count, trial['next_damage']: total})
        return values

    def heal_values(self, factor, again=1.0, fed_aura=1.0, entry=HEAL, spread=0.0):
        _, expectation = self.generated(entry)
        draw = random.Random(SEED)
        values, count, total = {}, 0.0, 0.0
        for arm, hit, aura in (('control', CONTROL_HIT, 0.0), ('treatment', CONTROL_HIT * factor, fed_aura)):
            for trial in expectation.model['reads'][arm]:
                count, total = count + 1, total + hit * (1 + draw.gauss(0, spread))
                values.update({trial['aura']: aura, trial['hits']: count, trial['heal']: total})
                if arm == 'treatment':
                    count, total = count + 1, total + CONTROL_HIT * again * (1 + draw.gauss(0, spread))
                    values.update({trial['next_hits']: count, trial['next_heal']: total})
        return values

    def test_the_heal_variant_feeds_and_heals_the_ally_with_a_second_cast(self):
        scenario, expectation = self.generated(HEAL)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        feeds = [step for step in steps if step['action'] == 'cast_until_aura']
        self.assertEqual([(step['spell'], step['aura'], step['target']) for step in feeds],
                         [(500141, 301293, 'ally')] * 4)
        self.assertFalse(any(step['action'] == 'set_aura' and step['spell'] == 301293 for step in steps))
        casts = [step for step in steps if step['action'] == 'cast' and step['spell'] == 500143]
        self.assertEqual(len(casts), 4 + 4 * 2)
        self.assertTrue(all(step['target'] == 'ally' for step in casts))
        self.assertEqual(expectation.model['metric'], 'spell_heal_total')

    def test_heal_ratio_and_consumption(self):
        self.assertEqual(self.judged(HEAL, self.heal_values(1.2)), 'ok')
        self.assertEqual(self.judged(HEAL, self.heal_values(1.0)), 'alert')
        self.assertEqual(self.judged(HEAL, self.heal_values(1.2, again=1.2)), 'alert')
        self.assertEqual(self.judged(HEAL, self.heal_values(1.2, fed_aura=0.0)), 'unmeasured')

    def test_the_sized_heal_interval_must_lie_inside_the_figure_band(self):
        for factor, status in ((1.2, 'ok'), (1.1, 'alert'), (1.17, 'alert'), (1.23, 'alert'), (1.0, 'alert')):
            with self.subTest(factor=factor):
                self.assertEqual(self.judged(SIZED_HEAL, self.heal_values(factor, entry=SIZED_HEAL, spread=0.0025)),
                                 status)

    def test_a_heal_interval_too_wide_for_the_band_alerts(self):
        self.assertEqual(self.judged(SIZED_HEAL, self.heal_values(1.2, entry=SIZED_HEAL, spread=0.03)), 'alert')

    def test_the_heal_figure_comes_from_the_aura_and_multiplies_the_whole_heal(self):
        scenario, expectation = self.generated(SIZED_HEAL)
        self.assertAlmostEqual(expectation.model['figure'], 0.2)
        self.assertIn('spell power part included (Unit::SpellHealingBonusDone, Unit.cpp:10932)', scenario['contract'])
        self.assertIn('1.18 to 1.22', scenario['contract'])
        with self.assertRaises(ValueError):
            self.generated({**SIZED_HEAL, 'expected': 1.25})

    def test_the_feed_is_a_real_cast_step_sized_from_the_dbc(self):
        scenario, _ = self.generated(INSTANT)
        run.validate(scenario)
        feeds = [step for step in scenario['steps'] if step['action'] == 'cast_until_aura']
        self.assertEqual(len(feeds), 1)
        self.assertEqual((feeds[0]['spell'], feeds[0]['aura'], feeds[0]['max_casts']), (806060, 807299, 10))
        self.assertFalse(any(step['action'] == 'set_aura' and step['spell'] == 807299 for step in scenario['steps']))
        damage, _ = self.generated(DAMAGE)
        run.validate(damage)
        self.assertEqual([step['max_casts'] for step in damage['steps'] if step['action'] == 'cast_until_aura'],
                         [12] * 6)

    def test_instant_fed_cast_is_ok(self):
        self.assertEqual(self.judged(INSTANT, self.instant_values()), 'ok')

    def test_mutant_still_casting_with_the_aura_alerts(self):
        self.assertEqual(self.judged(INSTANT, self.instant_values(fed=1.0)), 'alert')

    def test_mutant_refused_fed_cast_alerts(self):
        self.assertEqual(self.judged(INSTANT, self.instant_values(fed_went=1.0)), 'alert')

    def test_a_control_cast_that_did_not_go_off_is_unmeasured(self):
        self.assertEqual(self.judged(INSTANT, self.instant_values(control_went=0.0, fed_went=1.0)), 'unmeasured')

    def test_the_instant_arms_read_the_judged_cast_going_off(self):
        scenario, _ = self.generated(INSTANT)
        reads = [step for step in scenario['steps'] if step.get('metric') == 'spell_go_count']
        self.assertEqual([(step['label'].split()[-3:], step['spell']) for step in reads],
                         [(['control', '0', 'went'], 554406), (['treatment', '0', 'went'], 554406)])

    def test_cap_reached_without_the_aura_is_unmeasured_not_ok(self):
        self.assertEqual(self.judged(INSTANT, self.instant_values(fed_aura=0.0)), 'unmeasured')
        self.assertEqual(self.judged(DAMAGE, self.damage_values(1.25, fed_aura=0.0)), 'unmeasured')

    def test_damage_ratio(self):
        self.assertEqual(self.judged(DAMAGE, self.damage_values(1.25)), 'ok')
        self.assertEqual(self.judged(DAMAGE, self.damage_values(1.0)), 'alert')
        self.assertEqual(self.judged(DAMAGE, self.damage_values(1.2)), 'alert')

    def test_the_sized_damage_interval_must_lie_inside_the_figure_band(self):
        for factor, status in ((1.25, 'ok'), (1.125, 'alert'), (1.2125, 'alert'), (1.2875, 'alert'), (1.0, 'alert')):
            with self.subTest(factor=factor):
                self.assertEqual(self.judged(SIZED_DAMAGE, self.sized_damage_values(factor)), status)

    def test_a_sized_damage_interval_too_wide_for_the_band_alerts(self):
        self.assertEqual(self.judged(SIZED_DAMAGE, self.sized_damage_values(1.25, spread=0.03)), 'alert')

    def test_a_sized_damage_aura_not_consumed_by_the_next_cast_alerts(self):
        self.assertEqual(self.judged(SIZED_DAMAGE, self.sized_damage_values(1.25, again=1.25)), 'alert')

    def test_an_arm_below_the_sized_hit_count_is_unmeasured(self):
        critical = {('control', index) for index in range(11)}
        self.assertEqual(self.judged(SIZED_DAMAGE, self.sized_damage_values(1.25, critical=critical)), 'unmeasured')
        critical = {('treatment', index) for index in range(10)}
        self.assertEqual(self.judged(SIZED_DAMAGE, self.sized_damage_values(1.25, critical=critical)), 'ok')

    def test_the_sized_damage_figure_comes_from_the_named_aura_effect(self):
        scenario, expectation = self.generated(SIZED_DAMAGE)
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertAlmostEqual(expectation.model['figure'], 0.25)
        self.assertEqual(expectation.model['min_hits'], 4)
        self.assertIn('spell power part included (Unit::SpellDamageBonusDone, Unit.cpp:9973)', scenario['contract'])
        self.assertIn('1.225 to 1.275', scenario['contract'])
        casts = [step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 554406]
        self.assertEqual(len(casts), 14 + 14 * 2)
        for refused in ({'expected': 1.2}, {'figure_effect': 0}, {'min_hits': 1}, {'min_hits': 15},
                        {'consumed': None}, {'variant': 'heal'}):
            with self.subTest(refused=refused), self.assertRaises(ValueError):
                self.generated({**SIZED_DAMAGE, **refused})

    def test_a_sized_damage_entry_without_a_next_claim_casts_once_per_fed_trial(self):
        entry = {**SIZED_DAMAGE, 'consumed': False}
        scenario, expectation = self.generated(entry)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 554406]
        self.assertEqual(len(casts), 14 + 14)
        self.assertIn('no second cast is judged', scenario['contract'])
        self.assertNotIn('next_hits', expectation.model['reads']['treatment'][0])
        self.assertEqual(self.judged(entry, self.sized_damage_values(1.25, entry=entry)), 'ok')
        self.assertEqual(self.judged(entry, self.sized_damage_values(1.125, entry=entry)), 'alert')

    def test_the_unsized_damage_model_carries_no_figure(self):
        _, expectation = self.generated(DAMAGE)
        self.assertNotIn('figure', expectation.model)
        self.assertNotIn('next_hits', expectation.model['reads']['treatment'][0])

    def cooldown_values(self, attempts=1, reset=0.0, free=0.0, second=0.0, third=67.0, control_second=67.0,
                        fed_aura=1.0):
        _, expectation = self.generated(COOLDOWN)
        values, fed = {}, 0.0
        for arm in ('control', 'treatment'):
            for trial in expectation.model['reads'][arm]:
                treated = arm == 'treatment'
                values.update({trial['pre']: 3400.0, trial['aura']: fed_aura if treated else 0.0,
                               trial['reset']: reset if treated else 1700.0, trial['free']: free if treated else 4500.0,
                               trial['second_go']: 3.0 if treated else 2.0,
                               trial['second_failure']: second if treated else control_second})
                if treated:
                    fed += attempts
                    values.update({trial['fed']: fed, trial['third_go']: 3.0, trial['third_failure']: third})
        return values

    def test_the_cooldown_variant_feeds_for_real_and_never_sets_the_aura(self):
        scenario, _ = self.generated(COOLDOWN)
        run.validate(scenario)
        feeds = [step for step in scenario['steps'] if step['action'] == 'cast_until_aura']
        self.assertEqual([(step['spell'], step['aura']) for step in feeds], [(800654, 503691)] * 8)
        self.assertFalse(any(step['action'] == 'set_aura' and step['spell'] == 503691 for step in scenario['steps']))

    def test_the_cooldown_variant_is_ok_when_the_reset_and_the_free_cast_hold(self):
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values()), 'ok')
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(attempts=2, reset=0.0)), 'ok')

    def test_a_cooldown_that_survives_the_roll_alerts(self):
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(reset=3400.0)), 'alert')

    def test_a_gavel_that_still_has_its_cooldown_after_the_aura_alerts(self):
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(free=4500.0)), 'alert')
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(second=67.0)), 'alert')

    def test_a_free_cast_that_is_not_one_only_alerts(self):
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(third=0.0)), 'alert')

    def test_a_control_without_a_refused_second_cast_alerts(self):
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(control_second=0.0)), 'alert')

    def test_a_late_feed_leaves_the_reset_unjudged(self):
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(attempts=3, reset=3400.0)), 'unmeasured')

    def test_a_missing_aura_is_unmeasured_and_too_few_trials_are_refused(self):
        self.assertEqual(self.judged(COOLDOWN, self.cooldown_values(fed_aura=0.0)), 'unmeasured')
        with self.assertRaises(ValueError):
            self.generated({**COOLDOWN, 'trials': 2})
        with self.assertRaises(ValueError):
            self.generated({**COOLDOWN, 'expected': 1})

    def test_a_missing_read_is_unmeasured(self):
        self.assertEqual(self.judged(DAMAGE, {}), 'unmeasured')

    def test_the_entry_needs_a_feed_longer_than_its_channel(self):
        with self.assertRaises(ValueError):
            self.generated({**INSTANT, 'every_ms': 4000})
        with self.assertRaises(ValueError):
            self.generated({**INSTANT, 'trials': 2})


if __name__ == '__main__':
    unittest.main()
