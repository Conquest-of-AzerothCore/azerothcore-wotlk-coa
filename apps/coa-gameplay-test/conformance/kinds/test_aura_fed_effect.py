from dataclasses import replace
import random
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import BEHAVIOUR, DATA, UNPROVEN, verdict_evidence
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
RESET = {**COOLDOWN, 'name': 'Dawn\'s Arrival (Gavel reset)', 'variant': 'cooldown_reset_recast',
         'label_suffix': 'fed_reset', 'trials': 15,
         'quote': 'Casting Dawnbreak now has a $h% chance to reset the cooldown of Gavels'}
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

    def instant_verdict(self, entry, values):
        _, expectation = self.generated(entry)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_opted_instant_contrast_is_behaviour_on_an_instant_clause_only(self):
        opted = {**INSTANT, 'evidence_metric': 'aura_fed_instant_casting'}
        verdict = self.instant_verdict(opted, self.instant_values())
        self.assertEqual((verdict.status, verdict.detail), ('ok', {'metric': 'aura_fed_instant_casting',
                                                                   'contrast': 'aura_fed'}))
        self.assertEqual(verdict_evidence(verdict, 'Your next Dawnsear is instant cast', {}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdict, 'within $d', {}), DATA)
        unstamped = replace(verdict, detail={'metric': 'aura_fed_instant_casting'})
        self.assertEqual(verdict_evidence(unstamped, 'Your next Dawnsear is instant cast', {}), DATA)
        plain = self.instant_verdict(INSTANT, self.instant_values())
        self.assertEqual((plain.status, plain.detail), ('ok', {'metric': 'casting'}))
        self.assertEqual(verdict_evidence(plain, 'Your next Dawnsear is instant cast', {}), DATA)

    def test_mutant_instant_contrast_without_its_control_arm_is_not_behaviour(self):
        opted = {**INSTANT, 'evidence_metric': 'aura_fed_instant_casting'}
        _, expectation = self.generated(opted)
        control = expectation.model['reads']['control'][0]['casting']
        missing = {label: value for label, value in self.instant_values().items() if label != control}
        for values in (missing, self.instant_values(control=0.0)):
            verdict = self.instant_verdict(opted, values)
            self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)
            self.assertEqual(verdict_evidence(verdict, 'Your next Dawnsear is instant cast', {}), UNPROVEN)
        self.assertEqual(self.instant_verdict(opted, self.instant_values(fed=1.0)).status, 'alert')

    def test_the_instant_evidence_metric_is_refused_off_the_instant_variant(self):
        for entry in (DAMAGE, COOLDOWN):
            with self.subTest(variant=entry['variant']), self.assertRaises(ValueError):
                self.generated({**entry, 'evidence_metric': 'aura_fed_instant_casting'})
        with self.assertRaises(ValueError):
            self.generated({**INSTANT, 'evidence_metric': 'cast_failure'})
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

    def test_the_free_cast_verdict_carries_the_evidence_metric_only_when_asked(self):
        for entry, metric in ((COOLDOWN, 'cooldown_ms'), ({**COOLDOWN, 'evidence_metric': 'cast_failure'},
                                                          'cast_failure')):
            _, expectation = self.generated(entry)
            values = self.cooldown_values()
            verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
            self.assertEqual((verdict.status, verdict.detail['metric']), ('ok', metric))

    def test_the_evidence_metric_is_a_cooldown_option_of_one_value(self):
        with self.assertRaises(ValueError):
            self.generated({**COOLDOWN, 'evidence_metric': 'spell_go_count'})
        with self.assertRaises(ValueError):
            self.generated({**DAMAGE, 'evidence_metric': 'cast_failure'})

    def reset_run(self, attempts=None, recast=0.0, control=67.0, primed=3400.0, feed_failures=(), stamp=None):
        _, expectation = self.generated(RESET)
        attempts = attempts or [1] * 15
        values, fed, go = {}, 0.0, 0.0
        for arm in ('control', 'treatment'):
            for index, trial in enumerate(expectation.model['reads'][arm]):
                treated = arm == 'treatment'
                go += 1
                failure = recast[index] if treated and isinstance(recast, list) else recast if treated else control
                values.update({trial['pre']: primed, trial['pre_go']: go, trial['aura']: 1.0 if treated else 0.0,
                               trial['recast_failure']: failure})
                go += 1 if failure == 0 else 0
                values[trial['recast_go']] = go
                if treated:
                    fed += attempts[index]
                    values[trial['fed']] = fed
        fake = FakeRun(values)
        fake.cast_failures = {800611: [67] * 15, **({800654: list(feed_failures)} if feed_failures else {})}
        return judge_behaviour(base_verdict(expectation), fake, expectation)

    def test_the_reset_recast_feeds_for_real_and_never_sets_the_aura(self):
        scenario, expectation = self.generated(RESET)
        run.validate(scenario, run.SIMULATED_CLOCK)
        feeds = [step for step in scenario['steps'] if step['action'] == 'cast_until_aura']
        self.assertEqual([(step['spell'], step['aura']) for step in feeds], [(800654, 503691)] * 15)
        self.assertFalse(any(step['action'] == 'set_aura' and step['spell'] == 503691 for step in scenario['steps']))
        self.assertIn('never on the outcome', scenario['contract'])
        self.assertEqual(expectation.model['metric'], 'cast_failure')

    def test_the_reset_recast_is_ok_when_the_granting_roll_resets_the_gavel(self):
        verdict = self.reset_run()
        self.assertEqual((verdict.status, verdict.detail['metric']), ('ok', 'cast_failure'))

    def test_a_mutant_without_the_reset_alerts(self):
        self.assertEqual(self.reset_run(recast=67.0).status, 'alert')
        self.assertEqual(self.reset_run(recast=[0.0] * 14 + [67.0]).status, 'alert')

    def test_a_control_recast_that_goes_off_alerts(self):
        self.assertEqual(self.reset_run(control=0.0).status, 'alert')

    def test_the_selection_rests_on_the_aura_timing_not_the_outcome(self):
        attempts = [1, 2] * 7 + [1]
        recast = [0.0 if count == 1 else 67.0 for count in attempts]
        self.assertEqual(self.reset_run(attempts=attempts, recast=recast).status, 'ok')
        recast[0] = 67.0
        self.assertEqual(self.reset_run(attempts=attempts, recast=recast).status, 'alert')
        self.assertEqual(self.reset_run(attempts=[2] * 15).status, 'unmeasured')

    def test_a_refused_feed_or_a_non_natural_primer_voids_the_run(self):
        self.assertEqual(self.reset_run(feed_failures=(67,)).status, 'unmeasured')
        self.assertEqual(self.reset_run(feed_failures=(0,)).status, 'ok')
        self.assertEqual(self.reset_run(primed=0.0).status, 'unmeasured')
        self.assertEqual(self.reset_run(primed=0.0, recast=67.0).status, 'unmeasured')

    def test_the_reset_recast_needs_its_trials(self):
        with self.assertRaises(ValueError):
            self.generated({**RESET, 'trials': 14})

    def test_a_missing_read_is_unmeasured(self):
        self.assertEqual(self.judged(DAMAGE, {}), 'unmeasured')

    def test_the_entry_needs_a_feed_longer_than_its_channel(self):
        with self.assertRaises(ValueError):
            self.generated({**INSTANT, 'every_ms': 4000})
        with self.assertRaises(ValueError):
            self.generated({**INSTANT, 'trials': 2})


WINDOW = {'spell': 804629, 'name': 'Spears of Glory (window)', 'kind': 'aura_fed_effect', 'variant': 'window',
          'label_suffix': 'fed_window', 'quote': 'Your next Dawnsear within $d is instant cast', 'quote_spell': 807299,
          'feed_spell': 806060, 'aura': 807299, 'effect_spell': 554406, 'every_ms': 1600, 'residual_target': 0.001,
          'feed_power': 1000, 'effect_power': 1363, 'trials': 3, 'min_judged': 2, 'held_ms': 9300, 'gone_ms': 10700,
          'caster_auras': [823764]}


def window_values(expectation, held=0.0, gone=1.0, broken=None) -> dict:
    values, went = {}, 0.0
    for side, casting in (('held', held), ('gone', gone)):
        for index, trial in enumerate(expectation.model['reads'][side]):
            went += 1
            values.update({trial['known start']: 1.0, trial['grants start']: 2.0 * went, trial['aura stop']: 1.0,
                           trial['grants stop']: 2.0 * went + 1, trial['casting clear']: 0.0,
                           trial['ticks relearn']: 10.0 * went, trial['known relearn']: 1.0,
                           trial['ticks cast']: 10.0 * went, trial['grants cast']: 2.0 * went + 1,
                           trial['aura cast']: 1.0, trial['casting']: casting, trial['went']: went})
            if broken and broken[0] == side and broken[1] >= index:
                values[trial[broken[2]]] = broken[3](values[trial[broken[2]]])
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class WindowTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), {**WINDOW, **changes})

    def judged(self, expectation, **kwargs):
        return judge_behaviour(base_verdict(expectation), FakeRun(window_values(expectation, **kwargs)), expectation)

    def test_the_talent_is_unlearned_at_the_stop_and_relearned_before_a_cast_at_the_stated_age(self):
        scenario, [expectation] = self.built()
        steps = scenario['steps']
        stops = [index for index, step in enumerate(steps) if step['action'] == 'cast_until_aura']
        self.assertEqual(len(stops), 6)
        for stop, offset in zip(stops, [9300] * 3 + [10700] * 3):
            self.assertEqual(steps[stop + 1], {'action': 'unlearn', 'actor': 'caster', 'spell': 804629})
            cast = next(index for index in range(stop, len(steps)) if steps[index]['action'] == 'cast')
            relearn = next(index for index in range(stop + 2, cast) if steps[index]['action'] == 'learn')
            self.assertEqual(sum(step['ms'] for step in steps[stop:cast] if step['action'] == 'wait'), offset)
            self.assertEqual(sum(step['ms'] for step in steps[stop:relearn] if step['action'] == 'wait'), 4500)
            self.assertEqual(steps[stop]['every_ms'], 1600)
        self.assertEqual(expectation.model['ages'], {'held': (9300, 9325), 'gone': (10700, 10725)})
        self.assertEqual(expectation.model['bounds'], {'held': (9000.0, 9650.0), 'gone': (10400.0, 11000.0)})

    def test_instant_inside_and_a_normal_cast_past_the_window_pass_and_mutants_alert(self):
        _, [expectation] = self.built()
        self.assertEqual(self.judged(expectation).status, 'ok', self.judged(expectation).explanation)
        self.assertEqual(self.judged(expectation, held=1.0).status, 'alert')
        self.assertEqual(self.judged(expectation, gone=0.0).status, 'alert')

    def test_an_aura_lost_at_the_unlearn_a_refresh_or_a_late_tick_voids_down_to_unmeasured(self):
        _, [expectation] = self.built()
        for broken in (('held', 1, 'aura stop', lambda value: 0.0), ('gone', 1, 'grants cast', lambda value: value + 1),
                       ('held', 1, 'ticks cast', lambda value: value + 1), ('gone', 2, 'known relearn', lambda v: 0.0)):
            with self.subTest(broken=broken[2]):
                verdict = self.judged(expectation, held=1.0, broken=broken)
                self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)
        one_void = self.judged(expectation, broken=('held', 0, 'aura stop', lambda value: 0.0))
        self.assertEqual(one_void.status, 'ok', one_void.explanation)

    def test_an_age_outside_its_window_is_unmeasured_not_ok(self):
        for changes in ({'held_ms': 8800}, {'gone_ms': 11200}, {'held_ms': 9640}):
            with self.subTest(changes=changes):
                _, [expectation] = self.built(**changes)
                verdict = self.judged(expectation)
                self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)
                self.assertIn('outside', verdict.explanation)

    def test_the_window_is_classed_behaviour_only_on_a_within_clause_with_its_contrast_stamped(self):
        _, [expectation] = self.built()
        verdict = self.judged(expectation)
        self.assertEqual(verdict.detail, {'metric': 'aura_fed_window_casting', 'contrast': 'aura_window'})
        self.assertEqual(verdict_evidence(verdict, 'within $d', {}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdict, 'Your next Dawnsear is instant cast', {}), DATA)
        unstamped = replace(verdict, detail={'metric': 'aura_fed_window_casting'})
        self.assertEqual(verdict_evidence(unstamped, 'within $d', {}), DATA)
        condition = replace(verdict, detail={'metric': 'aura_fed_window_casting', 'contrast': 'condition'})
        self.assertEqual(verdict_evidence(condition, 'within $d', {}), DATA)
        self.assertEqual(verdict_evidence(self.judged(expectation, held=1.0), 'within $d', {}), UNPROVEN)

    def test_a_window_entry_needs_its_minimum_and_a_feed_past_the_global_cooldown(self):
        for changes in ({'min_judged': 0}, {'min_judged': 4}, {'every_ms': 1000}, {'held_ms': 11000},
                        {'quote_spell': 554406}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
