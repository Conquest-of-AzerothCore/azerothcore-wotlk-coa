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
CONTROL_HIT = 8800.0


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

    def test_a_missing_read_is_unmeasured(self):
        self.assertEqual(self.judged(DAMAGE, {}), 'unmeasured')

    def test_the_entry_needs_a_feed_longer_than_its_channel(self):
        with self.assertRaises(ValueError):
            self.generated({**INSTANT, 'every_ms': 4000})
        with self.assertRaises(ValueError):
            self.generated({**INSTANT, 'trials': 2})


if __name__ == '__main__':
    unittest.main()
