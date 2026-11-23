import random
import unittest

from aura_fed_rate import rate_verdict
from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds import kind_pooled_judge
from profile import DBC_DIR, load_fixture_class_file
from test_behaviours import FakeRun, base_verdict
import run

DAWN = {'spell': 503690, 'name': "Dawn's Arrival (rate per Dawnbreak cast)", 'kind': 'aura_fed_effect',
        'variant': 'damage_rate_dawnbreak', 'label_suffix': 'rate_dawnbreak',
        'quote': 'Casting Dawnbreak now has a $h% chance to reset the cooldown of Gavels', 'feed_spell': 800654,
        'aura': 503691, 'feed_target': 'dummy', 'feed_power': 1363, 'rolls': 300, 'residual_target': 0.001,
        'min_detectable': 4}
POOLED = {**DAWN, 'variant': 'damage_rate_dawnbreak_pooled', 'label_suffix': 'rate_dawnbreak_pooled',
          'rolls': 1600, 'parts': 20, 'spare_parts': 1}
CONTROL = {**DAWN, 'variant': 'damage_rate_dawnbreak_unlearned', 'label_suffix': 'rate_dawnbreak_unlearned',
           'learn_talent': False, 'rolls': 300}
SEED = 503690
NEEDED_40 = 29078
PART_ROLLS = 300
POOL_PARTS = 100


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraFedDamageRateTests(unittest.TestCase):
    def generated(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def filled(self, reads, draws, casts=None, hits=None, failure=0.0, alive=1.0, health=49000000.0):
        rolls = len(reads['rolls'])
        values = {label: float(hit) for label, hit in zip(reads['rolls'], draws)}
        values.update({reads['casts']: float(rolls if casts is None else casts),
                       reads['hits']: float(rolls if hits is None else hits), reads['failure']: failure,
                       reads['alive']: alive, reads['health']: health})
        return values

    def status(self, rate, **options):
        _, expectation = self.generated(DAWN)
        reads = expectation.model['reads']
        draw = random.Random(SEED)
        values = self.filled(reads, [draw.random() < rate for _ in reads['rolls']], **options)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def sized(self, rate, rolls=NEEDED_40):
        _, expectation = self.generated(DAWN)
        label = expectation.model['reads']['rolls'][0].rsplit(' roll ', 1)[0]
        reads = {**expectation.model['reads'], 'rolls': [f'{label} roll {index} aura' for index in range(rolls)]}
        draw = random.Random(SEED)
        values = self.filled(reads, [draw.random() < rate for _ in range(rolls)])
        return rate_verdict(base_verdict(expectation), FakeRun(values), {**expectation.model, 'reads': reads})

    def pooled(self, rate, broken=None, parts=POOL_PARTS):
        _, expectation = self.generated(DAWN)
        reads = expectation.model['reads']
        draw = random.Random(SEED)
        runs = []
        for part in range(parts):
            draws = [draw.random() < rate for _ in reads['rolls']]
            options = (broken or {}).get(part, {})
            runs.append(FakeRun(self.filled(reads, [True] * len(draws) if options else draws, **options)))
        return kind_pooled_judge('aura_fed_effect')(base_verdict(expectation), runs,
                                                     {**expectation.model, 'parts': parts})

    def test_each_roll_resets_and_casts_the_real_feed_at_the_dummy(self):
        scenario, expectation = self.generated(DAWN)
        run.validate(scenario, run.SIMULATED_CLOCK)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual({(step['spell'], step['target'], step.get('ignore_gcd')) for step in casts},
                         {(800654, 'primary', True)})
        self.assertEqual(len(casts), 300)
        resets = [step['spell'] for step in scenario['steps'] if step['action'] == 'reset_cooldown']
        self.assertEqual(resets, [800654] * 300)
        cancels = [step['spell'] for step in scenario['steps'] if step['action'] == 'cancel_aura']
        self.assertEqual(cancels, [503691] * 300)
        self.assertFalse(any(step['action'] == 'set_aura' for step in scenario['steps']))
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['primary'])
        self.assertEqual(expectation.model['metric'], 'aura')
        self.assertEqual(expectation.model['variant'], 'damage_rate')
        self.assertIn('500 ms later (cast time 0 + 500 ms)', scenario['contract'])
        self.assertIn('38% to 42%', scenario['contract'])
        self.assertIn('29078 rolls', scenario['contract'])

    def test_a_rate_inside_the_band_at_the_sized_count_is_ok(self):
        self.assertEqual(self.sized(0.40).status, 'ok')

    def test_a_rate_four_points_off_or_doubled_alerts_at_the_sized_count(self):
        for rate in (0.36, 0.44, 1 - 0.6 ** 2):
            with self.subTest(rate=rate):
                self.assertEqual(self.sized(rate).status, 'alert')

    def test_three_hundred_rolls_at_the_chance_state_the_interval(self):
        verdict = self.status(0.40)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('interval stated, the band needs 29078 rolls', verdict.explanation)

    def test_a_refused_or_empty_feed_or_a_dead_dummy_voids_the_run(self):
        for options, text in (({'casts': 299}, '299 feed casts went off'), ({'hits': 299}, '299 feed hits'),
                              ({'hits': 300, 'casts': 301}, '301 feed casts went off'),
                              ({'failure': 67.0}, 'last feed cast failure 67'),
                              ({'alive': 0.0, 'health': 0.0}, 'the dummy read alive 0'),
                              ({'health': 0.0}, 'health 0')):
            with self.subTest(options=options):
                verdict = self.status(1 - 0.6 ** 2, **options)
                self.assertEqual(verdict.status, 'unmeasured')
                self.assertIn(text, verdict.explanation)

    def test_entries_outside_the_contract_are_refused(self):
        for broken in ({**DAWN, 'feed_target': 'self'}, {**DAWN, 'haste_aura': 50336}, {**DAWN, 'rolls': 0},
                       {**DAWN, 'feed_spell': 500143}, {**POOLED, 'parts': 19}, {**POOLED, 'spare_parts': 0}):
            with self.subTest(broken=broken), self.assertRaises(ValueError):
                self.generated(broken)

    def test_the_pooled_entry_fits_the_step_limit_with_a_spare_part(self):
        scenario, _ = self.generated(POOLED)
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertIn('Pooled: 20 identical parts of 1600 rolls, 1 of them spare', scenario['contract'])
        self.assertIn('30400 rolls if 1 part(s) drop out', scenario['contract'])

    def test_pooled_parts_at_the_chance_reach_the_band(self):
        verdict = self.pooled(0.40)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('100 of 100 parts pooled', verdict.explanation)

    def test_pooled_mutants_beyond_the_band_edges_alert(self):
        for rate in (0.36, 0.44, 1 - 0.6 ** 2):
            with self.subTest(rate=rate):
                self.assertEqual(self.pooled(rate).status, 'alert')

    def test_a_pooled_rate_on_the_band_edge_is_never_ok(self):
        for rate in (0.38, 0.42):
            with self.subTest(rate=rate):
                self.assertNotEqual(self.pooled(rate).status, 'ok')

    def test_a_part_with_a_refused_or_empty_feed_is_excluded_whole(self):
        verdict = self.pooled(0.40, broken={4: {'casts': 299}, 9: {'hits': 0}, 11: {'alive': 0.0}})
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('97 of 100 parts pooled', verdict.explanation)
        self.assertIn('part 5: void: 299 feed casts went off', verdict.explanation)
        self.assertIn('part 10: void: 0 feed hits', verdict.explanation)
        self.assertIn('part 12: void: the dummy read alive 0', verdict.explanation)

    def test_pooled_rolls_below_the_sized_count_are_unmeasured(self):
        verdict = self.pooled(0.40, broken={part: {'casts': 0} for part in range(4)})
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('28800 pooled rolls, 29078 needed', verdict.explanation)

    def control_status(self, grants=0, **options):
        _, expectation = self.generated(CONTROL)
        reads = expectation.model['reads']
        draws = [index < grants for index in range(len(reads['rolls']))]
        return judge_behaviour(base_verdict(expectation), FakeRun(self.filled(reads, draws, **options)), expectation)

    def test_the_control_arm_never_learns_the_talent(self):
        scenario, expectation = self.generated(CONTROL)
        run.validate(scenario, run.SIMULATED_CLOCK)
        learned = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learned, [800654])
        self.assertEqual([step['spell'] for step in scenario['steps'] if step['action'] == 'unlearn'], [503690])
        self.assertTrue(expectation.model['control'])
        self.assertIn('Control arm: 503690 is unlearned', scenario['contract'])

    def test_the_control_arm_is_ok_with_no_grant_over_every_landed_cast(self):
        self.assertEqual(self.control_status().status, 'ok')

    def test_a_grant_in_the_control_arm_alerts(self):
        verdict = self.control_status(grants=1)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('1 of 300 rolls read the aura', verdict.explanation)

    def test_the_control_arm_voids_on_a_refused_or_empty_cast_or_a_dead_dummy(self):
        for options in ({'casts': 299}, {'hits': 299}, {'failure': 67.0}, {'alive': 0.0, 'health': 0.0}):
            with self.subTest(options=options):
                self.assertEqual(self.control_status(**options).status, 'unmeasured')

    def test_learn_talent_false_is_refused_when_pooled_and_unknown_elsewhere(self):
        for broken in ({**POOLED, 'learn_talent': False}, {**DAWN, 'learn_talent': 0}):
            with self.subTest(broken=broken), self.assertRaises(ValueError):
                self.generated(broken)

    def test_the_learned_arm_scenario_is_unchanged_by_the_field(self):
        explicit = self.generated({**DAWN, 'learn_talent': True})[0]
        self.assertEqual(explicit, self.generated(DAWN)[0])


if __name__ == '__main__':
    unittest.main()
