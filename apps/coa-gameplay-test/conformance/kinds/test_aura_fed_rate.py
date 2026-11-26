import random
import unittest
from dataclasses import replace

from aura_fed_rate import rate_verdict
from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds import kind_pooled_judge
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
AGREEMENT = 'step 1: 300 rolls per arm, two runs, hasted and unhasted rates agree within their Wilson intervals'
POOLED = {**HASTED, 'variant': 'heal_rate_illumination_self_pooled', 'label_suffix': 'rate_illumination_self_pooled',
          'rolls': 1900, 'parts': 17, 'spare_parts': 1, 'haste_agreement': AGREEMENT}
SEED = 704920
NEEDED_40 = 29078
PART_ROLLS = 300
POOL_PARTS = 100


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraFedRateTests(unittest.TestCase):
    def generated(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def filled(self, reads, draws, heals=None, other=0.0, haste=1.0, total=40000.0, effective=None):
        values = {label: float(hit) for label, hit in zip(reads['rolls'], draws)}
        values.update({reads['heals']: float(len(reads['rolls']) if heals is None else heals),
                       reads['heal_total']: total, reads['effective_total']: total if effective is None else effective,
                       reads['failure']: 0.0})
        if 'other' in reads:
            values[reads['other']] = other
        if 'cast_time' in reads:
            values[reads['cast_time']] = 500.0
            values.update({label: haste for label in reads['haste']})
        return values

    def values(self, entry, rate, **options):
        _, expectation = self.generated(entry)
        reads = expectation.model['reads']
        draw = random.Random(SEED)
        return expectation, self.filled(reads, [draw.random() < rate for _ in reads['rolls']], **options)

    def status(self, entry, rate, **options):
        expectation, values = self.values(entry, rate, **options)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def sized(self, entry, rate, rolls):
        _, expectation = self.generated(entry)
        label = expectation.model['reads']['rolls'][0].rsplit(' roll ', 1)[0]
        reads = {**expectation.model['reads'], 'rolls': [f'{label} roll {index} aura' for index in range(rolls)]}
        draw = random.Random(SEED)
        values = self.filled(reads, [draw.random() < rate for _ in range(rolls)])
        return rate_verdict(base_verdict(expectation), FakeRun(values), {**expectation.model, 'reads': reads})

    def pooled(self, rate, voids=(), haste_off=(), parts=POOL_PARTS):
        _, expectation = self.generated(HASTED)
        reads = expectation.model['reads']
        draw = random.Random(SEED)
        runs = []
        for part in range(parts):
            draws = [draw.random() < rate for _ in reads['rolls']]
            void = part in voids
            runs.append(FakeRun(self.filled(reads, [True] * len(draws) if void else draws,
                                            heals=len(draws) - 1 if void else None,
                                            haste=0.0 if part in haste_off else 1.0)))
        model = {**expectation.model, 'parts': parts}
        return kind_pooled_judge('aura_fed_effect')(base_verdict(expectation), runs, model)

    def part_hits(self, part, rate=0.40):
        draw = random.Random(SEED)
        draws = [draw.random() < rate for _ in range(POOL_PARTS * PART_ROLLS)]
        return float(sum(draws[part * PART_ROLLS:(part + 1) * PART_ROLLS]))

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
                self.assertEqual(sum(step['action'] == 'set_health' for step in scenario['steps']), 1)
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
        self.assertEqual(self.status(SELF, 1 - 0.6 ** 2, heals=299), 'unmeasured')
        self.assertEqual(self.status(SELF, 1 - 0.6 ** 2, effective=39000.0), 'unmeasured')
        self.assertEqual(self.status(ALLY, 1 - 0.6 ** 2, other=900.0), 'unmeasured')
        self.assertEqual(self.status(HASTED, 1 - 0.6 ** 2, haste=0.0), 'unmeasured')

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
        values.pop(expectation.model['reads']['rolls'][7])
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(replace(verdict, explanation='').status, 'unmeasured')

    def test_pooled_parts_at_the_chance_reach_the_band(self):
        verdict = self.pooled(0.40)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('100 of 100 parts pooled', verdict.explanation)
        self.assertIn('hasted cast time read 500 ms', verdict.explanation)

    def test_pooled_mutants_beyond_the_band_edges_alert(self):
        for rate in (0.36, 0.44, 1 - 0.6 ** 2):
            with self.subTest(rate=rate):
                self.assertEqual(self.pooled(rate).status, 'alert')

    def test_a_pooled_rate_on_the_band_edge_is_never_ok(self):
        for rate in (0.38, 0.42):
            with self.subTest(rate=rate):
                self.assertNotEqual(self.pooled(rate).status, 'ok')

    def test_a_void_part_is_excluded_whole(self):
        clean, voided = self.pooled(0.40), self.pooled(0.40, voids=(4,))
        self.assertEqual(voided.status, 'ok')
        self.assertIn('99 of 100 parts pooled, excluded whole: part 5: void: 299 feed heals', voided.explanation)
        kept = [index for index in range(POOL_PARTS) if index != 4]
        self.assertAlmostEqual(voided.measured * len(kept) * PART_ROLLS,
                               clean.measured * POOL_PARTS * PART_ROLLS - self.part_hits(4))
        self.assertIn('part 7: void: the haste aura', self.pooled(0.40, haste_off=(6,)).explanation)

    def test_pooled_rolls_below_the_sized_count_are_unmeasured(self):
        verdict = self.pooled(0.40, voids=(1, 2, 3, 4))
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('28800 pooled rolls, 29078 needed', verdict.explanation)

    def test_a_pooled_entry_is_sized_with_its_spare_parts_before_the_run(self):
        scenario, expectation = self.generated(POOLED)
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertIn('Pooled: 17 identical parts of 1900 rolls, 1 of them spare', scenario['contract'])
        self.assertIn('30400 rolls if 1 part(s) drop out', scenario['contract'])
        self.assertIn(AGREEMENT, scenario['contract'])
        self.assertEqual(len(expectation.model['reads']['haste']), 2)
        for broken in ({**POOLED, 'parts': 16}, {**POOLED, 'spare_parts': 0}, {**POOLED, 'haste_agreement': ''},
                       {**SELF, 'spare_parts': 1}):
            with self.subTest(broken=broken), self.assertRaises(ValueError):
                self.generated(broken)

    def test_only_the_rate_variant_is_pooled(self):
        _, expectation = self.generated(SELF)
        model = {**expectation.model, 'variant': 'heal', 'parts': 2}
        verdict = kind_pooled_judge('aura_fed_effect')(base_verdict(expectation), [], model)
        self.assertEqual(verdict.status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
