import random
import unittest
from dataclasses import replace

from aura_fed_rate import rate_verdict
from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
from test_behaviours import FakeRun, base_verdict
import run

SELF = {'spell': 704920, 'name': 'Cultivate Divinity (rate per Illumination heal, self)', 'kind': 'aura_fed_effect',
        'variant': 'heal_rate_illumination_self', 'label_suffix': 'rate_illumination_self',
        'quote': 'has a $707520h% chance to increase the healing of your next Radiant Cascade', 'feed_spell': 500143,
        'aura': 300354, 'chance_spell': 707520, 'feed_target': 'self', 'feed_power': 1363, 'rolls': 300,
        'residual_target': 0.001, 'min_detectable': 4}
ALLY = {**SELF, 'variant': 'heal_rate_illumination_ally', 'label_suffix': 'rate_illumination_ally',
        'feed_target': 'ally'}
CASCADE = {**SELF, 'variant': 'heal_rate_cascade_self', 'label_suffix': 'rate_cascade_self',
           'quote': 'has a $h% chance to increase the healing of your next Illumination', 'feed_spell': 500141,
           'aura': 301293, 'chance_spell': 704920}
HASTED = {**SELF, 'variant': 'heal_rate_illumination_self_haste', 'label_suffix': 'rate_illumination_self_haste',
          'haste_aura': 50336}
SEED = 704920
NEEDED_40 = 29078


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraFedRateTests(unittest.TestCase):
    def generated(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def values(self, entry, rate, rolls=None, heals=None, other=0.0):
        _, expectation = self.generated(entry)
        reads = expectation.model['reads']
        draw = random.Random(SEED)
        values = {}
        for index, roll in enumerate(reads['rolls']):
            values[roll['aura']] = float(draw.random() < rate)
            values[roll['heals']] = float(index + 1 if heals is None else heals(index))
        values[reads['failure']] = 0.0
        if 'other' in reads:
            values[reads['other']] = other
        if 'cast_time' in reads:
            values[reads['cast_time']] = 500.0
        return expectation, values

    def status(self, entry, rate, **options):
        expectation, values = self.values(entry, rate, **options)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def sized(self, entry, rate, rolls):
        _, expectation = self.generated(entry)
        label = expectation.model['reads']['rolls'][0]['aura'].rsplit(' roll ', 1)[0]
        reads = {'rolls': [{'aura': f'{label} roll {index} aura', 'heals': f'{label} roll {index} heals'}
                           for index in range(rolls)], 'failure': f'{label} failure'}
        draw = random.Random(SEED)
        values = {reads['failure']: 0.0}
        for index, roll in enumerate(reads['rolls']):
            values.update({roll['aura']: float(draw.random() < rate), roll['heals']: float(index + 1)})
        model = {**expectation.model, 'reads': reads}
        return rate_verdict(base_verdict(expectation), FakeRun(values), model)

    def test_the_rolls_are_real_feed_casts_on_the_feed_target(self):
        for entry, target in ((SELF, 'caster'), (ALLY, 'ally')):
            with self.subTest(target=target):
                scenario, expectation = self.generated(entry)
                run.validate(scenario, run.SIMULATED_CLOCK)
                casts = [step for step in scenario['steps'] if step['action'] == 'cast']
                self.assertEqual({(step['spell'], step['target']) for step in casts}, {(500143, target)})
                self.assertEqual(len(casts), 300)
                self.assertFalse(any(step['action'] == 'set_aura' and step['spell'] == 300354
                                     for step in scenario['steps']))
                self.assertEqual(expectation.model['metric'], 'aura')
                self.assertEqual([player['id'] for player in scenario['players']],
                                 ['caster'] + (['ally'] if target == 'ally' else []))
                self.assertIn('2500 ms later (cast time 2000 + 500 ms)', scenario['contract'])
                self.assertIn('38% to 42%', scenario['contract'])
                self.assertIn('29078 rolls', scenario['contract'])

    def test_the_band_and_count_come_from_the_g20_rule(self):
        scenario, expectation = self.generated(CASCADE)
        self.assertAlmostEqual(expectation.model['band'], 0.02)
        self.assertEqual(expectation.model['needed'], 19386)
        self.assertIn('18% to 22%', scenario['contract'])
        self.assertIn('3000 ms later (cast time 2500 + 500 ms)', scenario['contract'])

    def test_a_rate_inside_the_band_at_the_sized_count_is_ok(self):
        self.assertEqual(self.sized(SELF, 0.40, NEEDED_40).status, 'ok')

    def test_a_doubled_roll_alerts(self):
        self.assertEqual(self.status(SELF, 1 - 0.6 ** 2), 'alert')
        self.assertEqual(self.status(CASCADE, 1 - 0.8 ** 2), 'alert')
        self.assertEqual(self.sized(SELF, 1 - 0.6 ** 2, NEEDED_40).status, 'alert')

    def test_a_rate_four_points_off_alerts_at_the_sized_count(self):
        self.assertEqual(self.sized(SELF, 0.44, NEEDED_40).status, 'alert')
        self.assertEqual(self.sized(SELF, 0.36, NEEDED_40).status, 'alert')

    def test_three_hundred_rolls_at_the_chance_state_the_interval(self):
        expectation, values = self.values(SELF, 0.40)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('interval stated, the band needs 29078 rolls', verdict.explanation)

    def test_a_refused_or_missing_heal_voids_the_run(self):
        self.assertEqual(self.status(SELF, 1 - 0.6 ** 2, heals=lambda index: min(index + 1, 150)), 'unmeasured')
        self.assertEqual(self.status(ALLY, 1 - 0.6 ** 2, other=900.0), 'unmeasured')

    def test_the_haste_aura_is_a_casting_speed_fixture_only(self):
        scenario, expectation = self.generated(HASTED)
        run.validate(scenario, run.SIMULATED_CLOCK)
        auras = [step['spell'] for step in scenario['steps'] if step['action'] == 'set_aura']
        self.assertEqual(auras, [50336])
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertTrue(all(step.get('ignore_gcd') for step in casts))
        self.assertIn('1000 ms later (cast time 500 + 500 ms)', scenario['contract'])
        self.assertIn('cast_time', expectation.model['reads'])
        for aura in (300354, 707520):
            with self.subTest(aura=aura), self.assertRaises(ValueError):
                self.generated({**HASTED, 'haste_aura': aura})

    def test_entries_outside_the_contract_are_refused(self):
        for broken in ({**SELF, 'feed_target': 'dummy'}, {**SELF, 'rolls': 0}, {**SELF, 'every_ms': 3500},
                       {**SELF, 'rolls': NEEDED_40}):
            with self.subTest(broken=broken), self.assertRaises(ValueError):
                self.generated(broken)

    def test_an_unmeasured_status_never_reads_as_ok(self):
        expectation, values = self.values(SELF, 0.40)
        values.pop(expectation.model['reads']['rolls'][7]['aura'])
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(replace(verdict, explanation='').status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
