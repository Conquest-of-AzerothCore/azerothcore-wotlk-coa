import unittest

from behaviours import behaviour_scenario
from kinds.avoided_charge_restore import (CONTROL, METRIC, TREATMENT, avoided_charge_restore_spec,
                                          avoided_charge_restore_verdict, minimum_control_trials,
                                          minimum_treatment_trials)
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {
    'spell': 300278, 'name': 'Bulwark of Horror (charge restore on avoided swing)',
    'kind': 'avoided_charge_restore', 'variant': 'avoided_charge_restore',
    'label_suffix': 'avoided_charge_restore',
    'quote': 'Avoiding an attack now has a $h% chance to refresh a charge of Blade of the Empire.',
    'charge_spell': 502122, 'max_charges': 3, 'spend_charges': 3, 'expected_pct': 40,
    'striker_entry': 36, 'strikers': 3, 'striker_auras': [42716, 62531, 2116852],
    'window_ms': 400, 'dodge': 100, 'parry': 0, 'count_misses': True,
    'miss_exclusion': {'min_share': 0.04}, 'dummy_distance': 20.0,
    'control_cycles': 10, 'treatment_cycles': 50, 'parts': 1,
}


def build_entry(**changes):
    return behaviour_scenario(load_class_file(25), {**ENTRY, **changes})


def seeded_run(model: dict, ctrl_swings=2, ctrl_restores=0, treat_swings=2, treat_restores_seq=None,
               miss_every=10, guard_override=None, cast_failures=None, c_before=0, extra_total=0, drop=None):
    values = {label: 0.0 for label in model['guards'].values()}
    if guard_override:
        for key, val in guard_override.items():
            values[model['guards'][key]] = val
    dodged = parried = missed = total = 0
    values[model['start']['trials']['dodged']] = 0.0
    values[model['start']['trials']['parried']] = 0.0
    if model['count_misses']:
        values[model['start']['trials']['missed']] = 0.0
    values[model['start']['total']] = 0.0
    for arm, swings, restores_fn in (
            (CONTROL, ctrl_swings, lambda idx: ctrl_restores if idx == 0 else 0),
            (TREATMENT, treat_swings,
             (lambda idx: treat_restores_seq[idx % len(treat_restores_seq)]) if treat_restores_seq else (lambda _: 0))):
        for idx, cycle in enumerate(model['arms'][arm]):
            w_swings = swings(idx) if callable(swings) else swings
            w_miss = 1 if (model['count_misses'] and miss_every and (idx % miss_every == 0) and w_swings > 0) else 0
            w_dodge = w_swings - w_miss
            dodged += w_dodge
            missed += w_miss
            total += w_swings + (extra_total if arm == TREATMENT and idx == 0 else 0)
            w_rest = restores_fn(idx)
            values[cycle['charges_before']] = float(c_before)
            values[cycle['charges_after']] = float(c_before + w_rest)
            values[cycle['trials']['dodged']] = float(dodged)
            values[cycle['trials']['parried']] = float(parried)
            if model['count_misses']:
                values[cycle['trials']['missed']] = float(missed)
            values[cycle['total']] = float(total)
    if drop:
        values.pop(drop)
    fake = FakeRun(values)
    fake.cast_failures = cast_failures or {}
    return fake


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedChargeRestoreTests(unittest.TestCase):
    def test_generates_valid_scenario_and_registers_event_evidence(self):
        from coverage import EVENT, METRIC_EVIDENCE, metric_evidence
        scenario, [exp] = build_entry()
        valid = run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(exp.label, '300278 behaviour_metric_delta avoided_charge_restore')
        self.assertEqual(exp.model['metric'], METRIC)
        self.assertNotIn(METRIC, METRIC_EVIDENCE)
        self.assertEqual(metric_evidence()[METRIC], EVENT)
        self.assertIn('Residual per counted pair', valid['contract'])
        self.assertEqual(len(valid['creatures']), 4)
        self.assertEqual(valid['creatures'][0]['distance'], 20.0)
        restores = [step for step in valid['steps'] if step['action'] == 'restore_charges']
        self.assertEqual(len(restores), 60)

    def test_pooled_ok_alert_mutant_and_miss_exclusion(self):
        from coverage import BEHAVIOUR, verdict_evidence
        _, [exp] = build_entry(control_cycles=10, treatment_cycles=50)
        model = {**exp.model, 'min_control_trials': 50, 'min_treatment_trials': 22014}
        one_ok = seeded_run(model, treat_swings=2, treat_restores_seq=[1, 1, 0, 1, 1], miss_every=5)
        runs_ok = [one_ok] * 250
        ok_verdict = avoided_charge_restore_verdict(base_verdict(exp), runs_ok, model)
        self.assertEqual(ok_verdict.status, 'ok')
        self.assertEqual(verdict_evidence(ok_verdict, ENTRY['quote'], {}), BEHAVIOUR)

        mutant_model = {**model, 'expected_rate': 0.50}
        self.assertEqual(avoided_charge_restore_verdict(base_verdict(exp), runs_ok, mutant_model).status, 'alert')

        runs_zero = [seeded_run(model, treat_swings=2, treat_restores_seq=[0], miss_every=5)] * 250
        self.assertEqual(avoided_charge_restore_verdict(base_verdict(exp), runs_zero, model).status, 'alert')

        runs_ctrl_proc = [seeded_run(model, ctrl_restores=1, treat_swings=2, treat_restores_seq=[1, 1, 0, 1, 1],
                                     miss_every=5)] * 250
        self.assertEqual(avoided_charge_restore_verdict(base_verdict(exp), runs_ctrl_proc, model).status, 'alert')

        runs_extra_restore = [seeded_run(model, treat_swings=1, treat_restores_seq=[2], miss_every=5)]
        self.assertEqual(avoided_charge_restore_verdict(base_verdict(exp), runs_extra_restore, model).status, 'alert')

        runs_low_miss = [seeded_run(model, treat_swings=2, treat_restores_seq=[1, 1, 0, 1, 1], miss_every=0)] * 250
        self.assertEqual(avoided_charge_restore_verdict(base_verdict(exp), runs_low_miss, model).status, 'unmeasured')

        seq_39 = [1] * 39 + [0] * 11
        runs_unproven_miss = [seeded_run(model, treat_swings=2, treat_restores_seq=seq_39, miss_every=13)] * 250
        unproven_miss_verdict = avoided_charge_restore_verdict(base_verdict(exp), runs_unproven_miss, model)
        self.assertEqual(unproven_miss_verdict.status, 'alert')
        self.assertIn('misses not proven counted', unproven_miss_verdict.explanation)

    def test_unmeasured_on_capping_risk_guard_failure_imbalance_or_missing_read(self):
        _, [exp] = build_entry(control_cycles=30, treatment_cycles=50)
        model = {**exp.model, 'min_control_trials': 50, 'min_treatment_trials': 100}
        self.assertEqual(avoided_charge_restore_verdict(
            base_verdict(exp), [seeded_run(model, treat_swings=4, treat_restores_seq=[1])], model).status, 'unmeasured')
        self.assertEqual(avoided_charge_restore_verdict(
            base_verdict(exp), [seeded_run(model, guard_override={'landed': 1.0})], model).status, 'unmeasured')
        self.assertEqual(avoided_charge_restore_verdict(
            base_verdict(exp), [seeded_run(model, cast_failures={502122: [67]})], model).status, 'unmeasured')
        self.assertEqual(avoided_charge_restore_verdict(
            base_verdict(exp), [seeded_run(model, extra_total=1)], model).status, 'unmeasured')
        self.assertEqual(avoided_charge_restore_verdict(
            base_verdict(exp), [seeded_run(model, drop=model['arms'][TREATMENT][0]['charges_after'])], model).status,
            'unmeasured')
        self.assertEqual(avoided_charge_restore_verdict(
            base_verdict(exp), [seeded_run(model, treat_swings=1, treat_restores_seq=[0])], model).status,
            'insufficient_trials')

    def test_sizing_meets_residual_and_refuses_invalid_entries(self):
        self.assertGreaterEqual(minimum_treatment_trials(0.40, 1e-3), 22000)
        self.assertGreaterEqual(minimum_control_trials(0.40, 1e-3), 50)
        for bad in (
                {'expected_pct': 0}, {'expected_pct': 100}, {'max_charges': 0}, {'spend_charges': 4},
                {'dodge': 50, 'parry': 40}, {'window_ms': 0}, {'residual': 0}, {'residual': 1},
                {'count_misses': False, 'miss_exclusion': {'min_share': 0.04}},
                {'unknown_key': 1}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                avoided_charge_restore_spec({**ENTRY, **bad})


if __name__ == '__main__':
    unittest.main()
