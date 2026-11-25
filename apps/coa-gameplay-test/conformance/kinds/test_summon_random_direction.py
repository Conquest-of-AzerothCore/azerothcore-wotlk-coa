import math
import unittest

from behaviours import behaviour_scenario
from coverage import BEHAVIOUR, BY_METRIC, EVENT, EVIDENCE, METRIC_EVIDENCE, metric_evidence, verdict_evidence
from kinds.summon_random_direction import (KIND, X_METRIC, Y_METRIC, false_fail_bound, summon_random_direction_spec,
                                           summon_random_direction_verdict)
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

HALLUCINATION_ENTRY = {
    'spell': 560301, 'kind': KIND, 'variant': 'copies_random_run', 'label_suffix': 'copies_random_run',
    'name': 'Hallucination (3 copies run in random directions)',
    'quote': 'that run in a random direction',
    'trigger_spell': 560301, 'entry': 840025, 'copies': 3, 'casts': 8, 'parts': 1,
    'duration_spell': 706932, 'start_wait_ms': 50, 'run_ms': 1500, 'despawn_wait_ms': 2000,
    'min_run_yd': 5.0, 'cast_power': 2000}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(25), entry)


def seeded_run(model: dict, angles: list[float], distance: float = 10.0,
               overrides: dict | None = None) -> list[FakeRun]:
    values = {model['control']: 0.0}
    idx = 0
    for cast in model['casts']:
        values[cast['pre']] = 0.0
        values[cast['start_count']] = float(model['copies'])
        values[cast['end_count']] = float(model['copies'])
        for copy_idx in range(int(model['copies'])):
            angle = angles[idx % len(angles)]
            idx += 1
            x0, y0 = 100.0 + copy_idx, 200.0
            values[cast['start'][copy_idx]['x']] = x0
            values[cast['start'][copy_idx]['y']] = y0
            values[cast['end'][copy_idx]['x']] = x0 + distance * math.cos(angle)
            values[cast['end'][copy_idx]['y']] = y0 + distance * math.sin(angle)
    if overrides:
        values.update(overrides)
    return [FakeRun(values)]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SummonRandomDirectionTests(unittest.TestCase):
    def test_generates_valid_scenario_and_registers_event_evidence(self):
        self.assertNotIn(X_METRIC, METRIC_EVIDENCE)
        self.assertNotIn(Y_METRIC, METRIC_EVIDENCE)
        self.assertEqual(metric_evidence()[X_METRIC], EVENT)
        self.assertEqual(metric_evidence()[Y_METRIC], EVENT)
        scenario, [exp] = scenario_of(HALLUCINATION_ENTRY)
        validated = run.validate(scenario)
        coords = [step for step in validated['steps'] if step.get('metric') in (X_METRIC, Y_METRIC)]
        self.assertEqual(len(coords), 8 * 3 * 2 * 2)
        spread = [2.0 * math.pi * k / 24.0 for k in range(24)]
        verdict = summon_random_direction_verdict(base_verdict(exp), seeded_run(exp.model, spread), exp.model)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertEqual(verdict.detail['occupied_sectors'], 8)
        self.assertLess(verdict.detail['resultant'], 0.01)
        self.assertEqual(EVIDENCE[verdict.check], BY_METRIC)
        self.assertEqual(verdict_evidence(verdict, HALLUCINATION_ENTRY['quote'], {}), BEHAVIOUR)
        self.assertLess(2 * false_fail_bound(24, 0.65, 5), 1e-3)

    def test_mutants_stationary_walk_fixed_direction_narrow_cone_fixed_fan_and_control_alert(self):
        _, [exp] = scenario_of(HALLUCINATION_ENTRY)
        spread = [2.0 * math.pi * k / 24.0 for k in range(24)]
        cases = (
            ('stationary', seeded_run(exp.model, spread, distance=0.0)),
            ('walking_only', seeded_run(exp.model, spread, distance=3.75)),
            ('single_fixed_direction', seeded_run(exp.model, [0.5] * 24)),
            ('narrow_cone', seeded_run(exp.model, [0.1, 0.3, 0.5, 0.7] * 6)),
            ('deterministic_3_way_fan', seeded_run(exp.model, [0.0, 2.0, 4.0] * 8)),
            ('two_opposite_directions', seeded_run(exp.model, [0.0, math.pi] * 12)),
            ('control_leak', seeded_run(exp.model, spread, overrides={exp.model['control']: 1.0})),
            ('wrong_copy_count', seeded_run(exp.model, spread, overrides={exp.model['casts'][0]['end_count']: 2.0})),
        )
        for name, runs in cases:
            with self.subTest(mutant=name):
                verdict = summon_random_direction_verdict(base_verdict(exp), runs, exp.model)
                self.assertEqual(verdict.status, 'alert', f'{name}: {verdict.explanation}')
        five_copy = {**HALLUCINATION_ENTRY, 'copies': 5, 'casts': 5, 'min_sectors': 6}
        _, [exp5] = scenario_of(five_copy)
        fan5 = [2.0 * math.pi * k / 5.0 for k in range(5)] * 5
        verdict5 = summon_random_direction_verdict(base_verdict(exp5), seeded_run(exp5.model, fan5), exp5.model)
        self.assertEqual(verdict5.status, 'alert', verdict5.explanation)

    def test_unmeasured_on_missing_nan_leftover_or_refused_cast(self):
        _, [exp] = scenario_of(HALLUCINATION_ENTRY)
        spread = [2.0 * math.pi * k / 24.0 for k in range(24)]
        self.assertEqual(summon_random_direction_verdict(base_verdict(exp), [], exp.model).status, 'unmeasured')
        self.assertEqual(summon_random_direction_verdict(base_verdict(exp), [FakeRun({})], exp.model).status,
                         'unmeasured')
        self.assertEqual(
            summon_random_direction_verdict(
                base_verdict(exp),
                seeded_run(exp.model, spread, overrides={exp.model['casts'][0]['pre']: 1.0}),
                exp.model).status,
            'unmeasured')
        self.assertEqual(
            summon_random_direction_verdict(
                base_verdict(exp),
                seeded_run(exp.model, spread, overrides={exp.model['casts'][0]['end'][0]['x']: float('nan')}),
                exp.model).status,
            'unmeasured')
        runs = seeded_run(exp.model, spread)
        runs[0].cast_failures = {560301: [1]}
        self.assertEqual(summon_random_direction_verdict(base_verdict(exp), runs, exp.model).status, 'unmeasured')

    def test_refuses_bad_specs_and_timings(self):
        for bad in (
                {**HALLUCINATION_ENTRY, 'unknown_field': 1},
                {**HALLUCINATION_ENTRY, 'copies': 1},
                {**HALLUCINATION_ENTRY, 'copies': 8, 'casts': 3},
                {**HALLUCINATION_ENTRY, 'copies': 5, 'casts': 5, 'min_sectors': 5},
                {**HALLUCINATION_ENTRY, 'casts': 2},
                {**HALLUCINATION_ENTRY, 'min_run_yd': 0},
                {**HALLUCINATION_ENTRY, 'max_resultant': 1.0},
                {**HALLUCINATION_ENTRY, 'min_sectors': 4},
                {**HALLUCINATION_ENTRY, 'min_sectors': 9}):
            with self.subTest(bad=bad):
                with self.assertRaises(ValueError):
                    summon_random_direction_spec(bad)
        for bad_timing in (
                {**HALLUCINATION_ENTRY, 'run_ms': 3000},
                {**HALLUCINATION_ENTRY, 'despawn_wait_ms': 500}):
            with self.subTest(bad_timing=bad_timing):
                with self.assertRaises(ValueError):
                    scenario_of(bad_timing)
