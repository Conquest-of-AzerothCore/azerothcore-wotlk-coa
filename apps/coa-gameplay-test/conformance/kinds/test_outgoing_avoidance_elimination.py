import math
import unittest

from behaviours import behaviour_scenario
from kinds.outgoing_avoidance_elimination import (CONTROL, METRIC, OUTCOME_METRICS, TREATMENT,
                                                  outgoing_avoidance_spec, outgoing_avoidance_verdict,
                                                  required_min_swings)
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {
    'spell': 805607, 'name': 'Shadow Training (cannot miss, be parried or dodged)',
    'kind': 'outgoing_avoidance_elimination', 'variant': 'outgoing_avoidance',
    'label_suffix': 'outgoing_avoidance',
    'quote': 'In addition, you are now unable to miss your attacks and you cannot be parried or dodged.',
    'window_ms': 180000, 'min_swings': 200, 'min_control_rate': 0.05, 'residual': 0.001,
    'haste_auras': [62531, 2116852], 'dummy_entry': 36, 'dummy_distance': 3.0, 'dummy_health': 500000, 'hand': 0,
}


def build_entry(**changes):
    return behaviour_scenario(load_class_file(25), {**ENTRY, **changes})


def seeded_run(model: dict, ctrl_counts=None, treat_counts=None, state_override=None, post_stop_extra=None, drop=None):
    ctrl = {'swings': 220, 'hits': 187, 'misses': 11, 'dodges': 11, 'parries': 11, **(ctrl_counts or {})}
    treat = {'swings': 220, 'hits': 220, 'misses': 0, 'dodges': 0, 'parries': 0, **(treat_counts or {})}
    values = {}
    cumulative = {'swings': 0, 'hits': 0, 'misses': 0, 'dodges': 0, 'parries': 0}
    for arm, counts, expected_knows in ((CONTROL, ctrl, 0.0), (TREATMENT, treat, 1.0)):
        am = model['arms'][arm]
        for moment in ('start_state', 'end_state'):
            st = am[moment]
            values[st['knows']] = expected_knows
            values[st['alive']] = 1.0
            values[st['distance']] = 3.0
            values[st['caster_x']] = 100.0
            values[st['caster_y']] = 200.0
            values[st['dummy_x']] = 103.0
            values[st['dummy_y']] = 200.0
            values[st['dummy_o']] = math.pi
            for aura in model['haste_auras']:
                values[st[f'haste_{aura}']] = 1.0
        for key, lbl in am['start_counters'].items():
            values[lbl] = float(cumulative[key])
        for key in cumulative:
            cumulative[key] += counts[key]
        for key, lbl in am['end_counters'].items():
            values[lbl] = float(cumulative[key])
        extra = (post_stop_extra or {}).get(arm, 0)
        values[am['post_stop']] = float(cumulative['swings'] + extra)
    for key, val in (state_override or {}).items():
        arm, moment, field = key
        values[model['arms'][arm][moment][field]] = val
    if drop:
        values.pop(drop)
    return FakeRun(values)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class OutgoingAvoidanceEliminationTests(unittest.TestCase):
    def test_generates_valid_scenario_and_registers_event_evidence(self):
        from coverage import BEHAVIOUR, EVENT, METRIC_EVIDENCE, metric_evidence, verdict_evidence
        scenario, [exp] = build_entry()
        valid = run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(exp.label, '805607 behaviour_metric_delta outgoing_avoidance')
        self.assertEqual(exp.model['metric'], METRIC)
        self.assertTrue(valid['creatures'][0]['face_caster'])
        self.assertTrue(valid['creatures'][0]['stationary'])
        for rating in ('melee_hit_rating', 'expertise_rating', 'spell_hit_rating', 'ranged_hit_rating'):
            self.assertNotIn(rating, valid['players'][0])
        for metric in OUTCOME_METRICS:
            self.assertNotIn(metric, METRIC_EVIDENCE)
            self.assertEqual(metric_evidence()[metric], EVENT)
        verdict = outgoing_avoidance_verdict(base_verdict(exp), seeded_run(exp.model), exp.model)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict_evidence(verdict, ENTRY['quote'], {}), BEHAVIOUR)

    def test_mutants_alert_for_any_treatment_avoidance_or_missing_control_outcome(self):
        _, [exp] = build_entry()
        for field in ('misses', 'dodges', 'parries'):
            with self.subTest(treatment_mutant=field):
                fake = seeded_run(exp.model, treat_counts={'hits': 219, field: 1})
                verdict = outgoing_avoidance_verdict(base_verdict(exp), fake, exp.model)
                self.assertEqual(verdict.status, 'alert')
                self.assertIn(field, verdict.explanation)
        with self.subTest(treatment_mutant='unaccounted_non_damaging_swing'):
            fake = seeded_run(exp.model, treat_counts={'swings': 220, 'hits': 219})
            verdict = outgoing_avoidance_verdict(base_verdict(exp), fake, exp.model)
            self.assertEqual(verdict.status, 'alert')
            self.assertIn('unaccounted=1', verdict.explanation)
        for field in ('misses', 'dodges', 'parries'):
            with self.subTest(control_mutant=field):
                fake = seeded_run(exp.model, ctrl_counts={field: 0, 'hits': 198})
                verdict = outgoing_avoidance_verdict(base_verdict(exp), fake, exp.model)
                self.assertEqual(verdict.status, 'alert')
                self.assertIn(field, verdict.explanation)

    def test_unmeasured_on_pinned_state_breaks_and_insufficient_trials(self):
        _, [exp] = build_entry()
        cases = [
            ('control_start_facing_away', {(CONTROL, 'start_state', 'dummy_o'): 0.0}),
            ('treatment_end_facing_away', {(TREATMENT, 'end_state', 'dummy_o'): 0.0}),
            ('control_end_dead', {(CONTROL, 'end_state', 'alive'): 0.0}),
            ('treatment_end_haste_lost', {(TREATMENT, 'end_state', 'haste_62531'): 0.0}),
            ('control_spell_already_known', {(CONTROL, 'start_state', 'knows'): 1.0}),
            ('treatment_spell_missing', {(TREATMENT, 'end_state', 'knows'): 0.0}),
            ('out_of_melee_range', {(CONTROL, 'end_state', 'distance'): 8.0}),
        ]
        for name, override in cases:
            with self.subTest(case=name):
                verdict = outgoing_avoidance_verdict(base_verdict(exp), seeded_run(exp.model, state_override=override),
                                                     exp.model)
                self.assertEqual(verdict.status, 'unmeasured')
        with self.subTest(case='post_stop_swing'):
            verdict = outgoing_avoidance_verdict(base_verdict(exp), seeded_run(exp.model, post_stop_extra={CONTROL: 1}),
                                                 exp.model)
            self.assertEqual(verdict.status, 'unmeasured')
        with self.subTest(case='missing_read'):
            lbl = exp.model['arms'][TREATMENT]['end_counters']['parries']
            verdict = outgoing_avoidance_verdict(base_verdict(exp), seeded_run(exp.model, drop=lbl), exp.model)
            self.assertEqual(verdict.status, 'unmeasured')
        with self.subTest(case='insufficient_trials'):
            verdict = outgoing_avoidance_verdict(base_verdict(exp),
                                                 seeded_run(exp.model, treat_counts={'swings': 150, 'hits': 150}),
                                                 exp.model)
            self.assertEqual(verdict.status, 'insufficient_trials')

    def test_refuses_undersized_and_invalid_specs(self):
        self.assertEqual(required_min_swings(0.05, 0.001), 170)
        for bad in ({'min_swings': 169}, {'min_control_rate': 0.0}, {'min_control_rate': 1.0},
                    {'residual': 0.0}, {'window_ms': 500}, {'hand': 2}, {'hand': True},
                    {'haste_auras': [62531, 62531]}, {'learn': [805607]}, {'unknown_key': 1}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                outgoing_avoidance_spec({**ENTRY, **bad})
