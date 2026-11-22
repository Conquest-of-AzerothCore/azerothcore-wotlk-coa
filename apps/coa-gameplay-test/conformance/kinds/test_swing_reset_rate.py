from dataclasses import replace
import json
import unittest

from behaviours import behaviour_scenario
from compare import evaluate, judge_behaviour
from kinds.swing_reset_rate import POOLED_JUDGE
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict
from test_compare import FakeTooltips, Workspace, assert_step

PARTS = 8
ENTRY = {'spell': 806699, 'name': "Odyn's Vanguard (Glorious Execution swing reset rate)", 'kind': 'swing_reset_rate',
         'quote': 'Melee attacks now have a $h% chance to reset the cooldown of Glorious Execution.',
         'talent': 806699, 'reset_spell': 800626, 'chance_pct': 20, 'control_ms': 60000, 'attack_ms': 3400000,
         'parts': PARTS}
VALKYR_HAND = {'item': 2529, 'subclass': 8, 'min_damage': 73.62, 'max_damage': 103.34, 'speed_ms': 2800,
               'inventory_type': 17, 'normalized_speed': 3.3, 'skill_line': 55}
SHIELD = {'item': 2129, 'slot': 16, 'subclass': 6, 'min_damage': 0.0, 'max_damage': 0.0, 'speed_ms': 0,
          'inventory_type': 14, 'normalized_speed': None, 'skill_line': 433}
CONTROL_HITS = 30.0
LANDED = 10618.0
MISSED = 1873.0


def templar():
    return load_fixture_class_file(19)


def dual_wielder(off_hand=None):
    class_file = templar()
    hands = {'main_hand': {**VALKYR_HAND, 'slot': 15},
             'off_hand': off_hand if off_hand is not None else {**VALKYR_HAND, 'slot': 16}, 'ranged': None}
    return {**class_file, 'weapon_sets': {'Pair': hands}, 'default_weapon_set': 'Pair'}


def two_sets(mapped: bool):
    class_file = dual_wielder()
    slow = {'main_hand': {**VALKYR_HAND, 'slot': 15}, 'off_hand': {**VALKYR_HAND, 'slot': 16}, 'ranged': None}
    fast = {'main_hand': {**VALKYR_HAND, 'item': 2524, 'speed_ms': 2500, 'slot': 15}, 'off_hand': SHIELD,
            'ranged': None}
    return {**class_file, 'weapon_sets': {'Fast': fast, 'Slow': slow}, 'default_weapon_set': 'Fast',
            'spell_weapon_sets': {'806699': 'Slow'} if mapped else {}}


def phase_of(label: str) -> str:
    return 'control' if ' control ' in label else 'treatment'


def harness_values(scenario: dict, counters: dict) -> dict:
    return {step['label']: counters[step['metric']][phase_of(step['label'])] for step in scenario['steps']
            if step['action'] == 'assert' and step['metric'] in counters}


def counters(resets: float, hits: float = LANDED, control_resets: float = 0.0) -> dict:
    return {'melee_damage_count': {'control': CONTROL_HITS, 'treatment': CONTROL_HITS + hits},
            'melee_attack_count': {'control': CONTROL_HITS + 5, 'treatment': CONTROL_HITS + 5 + hits + MISSED},
            'server_packets': {'control': control_resets, 'treatment': control_resets + resets}}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SwingResetRateTests(unittest.TestCase):
    def built(self, entry=None, class_file=None):
        return behaviour_scenario(class_file or templar(), entry or ENTRY)

    def judged(self, resets: float, hits: float = LANDED, control_resets: float = 0.0, scenario=None):
        built, [expectation] = self.built()
        values = harness_values(scenario or built, counters(resets, hits, control_resets))
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_scenario_reads_landed_swings_and_clear_cooldown_packets_around_the_learn(self):
        scenario, [expectation] = self.built()
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        learns = [index for index, step in enumerate(steps) if step['action'] == 'learn'
                  and step['spell'] in (800626, 806699)]
        reads = [index for index, step in enumerate(steps) if step['action'] == 'assert'
                 and step['label'] in expectation.model['reads'].values()]
        attacks = [index for index, step in enumerate(steps) if step['action'] in ('attack', 'stop_attack')]
        self.assertEqual([steps[index]['spell'] for index in learns], [800626, 806699])
        self.assertEqual(len(reads), 4)
        self.assertLess(learns[0], attacks[0])
        self.assertLess(attacks[1], reads[0])
        self.assertLess(reads[1], learns[1])
        self.assertLess(learns[1], attacks[2])
        self.assertLess(attacks[3], reads[2])
        hits = [steps[index] for index in reads if steps[index]['metric'] != 'server_packets']
        packets = [steps[index] for index in reads if steps[index]['metric'] == 'server_packets']
        self.assertEqual({(step['metric'], step.get('target'), step.get('hand')) for step in hits},
                         {('melee_damage_count', None, None)})
        self.assertEqual({(step['opcode'], step['row']) for step in packets}, {(0x1DE, 800626)})
        self.assertEqual(expectation.label, '806699 behaviour_metric_delta swing_reset_rate')
        self.assertEqual(expectation.model['minimum_trials'], 10618)

    def test_a_rate_inside_the_band_passes_and_half_of_it_alerts(self):
        self.assertEqual(self.judged(2124.0).status, 'ok')
        self.assertEqual(self.judged(1062.0).status, 'alert')

    def test_a_control_reset_alerts(self):
        verdict = self.judged(2124.0, control_resets=1.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('control', verdict.explanation)

    def test_fewer_landed_hits_than_the_band_are_insufficient(self):
        self.assertEqual(self.judged(200.0, hits=1000.0).status, 'insufficient_trials')

    def test_mutant_counting_swing_attempts_instead_of_landed_hits_alerts(self):
        scenario, _ = self.built()
        mutant = {**scenario, 'steps': [{**step, 'metric': 'melee_attack_count'}
                                        if step.get('metric') == 'melee_damage_count' else step
                                        for step in scenario['steps']]}
        self.assertEqual(self.judged(2124.0).status, 'ok')
        self.assertEqual(self.judged(2124.0, scenario=mutant).status, 'alert')

    def test_the_parts_pool_into_one_rate(self):
        _, [expectation] = self.built()
        reads = expectation.model['reads']
        runs = [FakeRun({reads['control hits']: CONTROL_HITS, reads['control resets']: 0.0,
                         reads['treatment hits']: CONTROL_HITS + LANDED / PARTS,
                         reads['treatment resets']: 2124.0 / PARTS}) for _ in range(PARTS)]
        verdict = POOLED_JUDGE(base_verdict(expectation), runs, expectation.model)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail, {'resets': 2124.0, 'hits': LANDED})

    def test_too_few_swings_by_the_weapon_bound_are_refused(self):
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'parts': PARTS - 1})
        self.built({**ENTRY, 'parts': 5}, dual_wielder())
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'parts': 4}, dual_wielder())
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'parts': 5}, dual_wielder(SHIELD))

    def test_a_dual_wielder_counts_both_hands_in_the_bound(self):
        _, [expectation] = self.built({**ENTRY, 'parts': 5}, dual_wielder())
        self.assertEqual(expectation.model['swing_bound'], 5 * 2 * (3400000 // 2800))
        _, [single] = self.built()
        self.assertEqual(single.model['swing_bound'], PARTS * (3400000 // 2500))

    def test_an_entry_is_sized_and_armed_on_the_weapon_set_of_its_spell(self):
        scenario, [mapped] = self.built({**ENTRY, 'parts': 5}, two_sets(True))
        self.assertEqual(mapped.model['swing_bound'], 5 * 2 * (3400000 // 2800))
        self.assertIn('speeds [2800, 2800]', scenario['contract'])
        equips = [step['item'] for step in scenario['steps'] if step['action'] == 'equip']
        self.assertEqual(equips, [2529, 2529])
        scenario, [default] = self.built(class_file=two_sets(False))
        self.assertEqual(default.model['swing_bound'], PARTS * (3400000 // 2500))
        self.assertIn('speeds [2500]', scenario['contract'])
        self.assertEqual([step['item'] for step in scenario['steps'] if step['action'] == 'equip'], [2524, 2129])

    def test_a_chance_of_a_hundred_percent_or_no_attack_time_is_refused(self):
        for change in ({'chance_pct': 100}, {'chance_pct': 0}, {'attack_ms': 0}, {'control_ms': 0}, {'parts': 0}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.built({**ENTRY, **change})

    def test_generation_is_deterministic(self):
        first, _ = self.built()
        second, _ = self.built()
        self.assertEqual(json.dumps(first, sort_keys=True), json.dumps(second, sort_keys=True))
        self.assertIn(f'one of {PARTS} identical pooled parts', first['contract'])
        single, _ = self.built({**ENTRY, 'parts': 1, 'attack_ms': 3400000, 'chance_pct': 90})
        self.assertNotIn('pooled parts', single['contract'])


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SwingResetRateCompareTests(unittest.TestCase):
    def verdict(self, ran_parts: int):
        workspace = Workspace()
        self.addCleanup(workspace.close)
        _, [expectation] = behaviour_scenario(templar(), ENTRY)
        expectation = replace(expectation, model={**expectation.model, 'parts': PARTS})
        reads = expectation.model['reads']
        values = {reads['control hits']: CONTROL_HITS, reads['control resets']: 0.0,
                  reads['treatment hits']: CONTROL_HITS + LANDED / PARTS, reads['treatment resets']: 2124.0 / PARTS}
        for part in range(1, PARTS + 1):
            steps = [assert_step(label, value) for label, value in values.items()] if part <= ran_parts else None
            workspace.scenario(f'swing-reset-part-{part}', 'behaviour', [expectation], steps=steps,
                                    spell=806699, rank=806699, clock='simulated')
        manifest, results = workspace.manifest()
        comparison = evaluate(manifest, results, tooltips=FakeTooltips([]))
        return next(verdict for verdict in comparison.verdicts if verdict.label == expectation.label)

    def test_every_part_pools_to_ok_and_a_missing_part_leaves_the_claim_unmeasured(self):
        self.assertEqual(self.verdict(PARTS).status, 'ok')
        missing = self.verdict(PARTS - 1)
        self.assertEqual(missing.status, 'unmeasured')
        self.assertIn(f'{PARTS - 1} of {PARTS} pooled parts ran', missing.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SwingResetRateResidualTests(unittest.TestCase):
    RESIDUAL = {**ENTRY, 'residual_target': 0.001, 'min_detectable': 5}

    def judged(self, resets: float, entry: dict):
        built, [expectation] = behaviour_scenario(templar(), entry)
        values = harness_values(built, counters(resets))
        return expectation, judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_residual_judges_at_its_confidence_and_keeps_the_band_minimum(self):
        expectation, verdict = self.judged(2124.0, self.RESIDUAL)
        self.assertEqual(expectation.model['residual']['trials'], 8616)
        self.assertEqual(expectation.model['minimum_trials'], 10618)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('Wilson 0.9995 interval', verdict.explanation)
        self.assertIn('residual_target 0.001 per pair', verdict.explanation)

    def test_mutant_a_rate_five_points_off_alerts_under_the_residual(self):
        self.assertEqual(self.judged(2655.0, self.RESIDUAL)[1].status, 'alert')

    def test_without_the_residual_fields_the_scenario_is_unchanged(self):
        plain, [expectation] = behaviour_scenario(templar(), ENTRY)
        self.assertNotIn('residual', expectation.model)
        self.assertNotIn('residual_target', plain['contract'])
        residual, _ = behaviour_scenario(templar(), self.RESIDUAL)
        self.assertIn('residual_target 0.001 per pair', residual['contract'])
