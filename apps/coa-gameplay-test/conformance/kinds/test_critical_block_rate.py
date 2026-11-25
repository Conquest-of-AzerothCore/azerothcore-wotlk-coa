import unittest

from behaviours import behaviour_scenario
from coverage import BEHAVIOUR, BY_METRIC, EVENT, EVIDENCE, METRIC_EVIDENCE, metric_evidence, verdict_evidence
from kinds.critical_block_rate import (CONTROL, COUNT_METRIC, KIND, TOTAL_METRIC, TREATMENT,
                                       critical_block_rate_verdict, critical_block_spec, minimum_control_trials,
                                       minimum_treatment_trials)
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

SYMBIOSIS_BASE_ENTRY = {
    'spell': 680574, 'kind': KIND, 'variant': 'crit_block_rate_base', 'label_suffix': 'crit_block_rate_base',
    'name': 'Shadowy Symbiosis (20% critical block rate and exact 2x blocked amount at 0 Insanity)',
    'quote': 'Your successful blocks now have a $s2% chance to critically block for twice the normal amount.',
    'gate_spell': 680574, 'expected_pct': 20, 'shield_item': 2129,
    'striker_entry': 36, 'strikers': 10, 'striker_auras': [42716, 62531, 2116852, 35785],
    'window_ms': 10000, 'control_windows': 1, 'treatment_windows': 14, 'parts': 6,
    'phase_auras': [[500706, 0, 'caster', 'caster']], 'setup_wait_ms': 1000,
    'after_setup_stacks': [
        {'spell': 500706, 'actor': 'caster', 'stacks': 0},
        {'spell': 680603, 'actor': 'caster', 'stacks': 0},
        {'spell': 573315, 'actor': 'caster', 'stacks': 0},
    ]}

SYMBIOSIS_AT_60_ENTRY = {
    **SYMBIOSIS_BASE_ENTRY,
    'variant': 'crit_block_rate_at_60', 'label_suffix': 'crit_block_rate_at_60',
    'name': 'Shadowy Symbiosis (20% critical block rate at 60 Insanity boundary)',
    'quote': 'This effect is doubled while above 60 Insanity.',
    'phase_auras': [[500706, 60, 'caster', 'caster']], 'setup_wait_ms': 1600,
    'after_setup_stacks': [
        {'spell': 500706, 'actor': 'caster', 'stacks': 60},
        {'spell': 680603, 'actor': 'caster', 'stacks': 1},
        {'spell': 573315, 'actor': 'caster', 'stacks': 0},
    ]}

SYMBIOSIS_ABOVE_60_ENTRY = {
    **SYMBIOSIS_BASE_ENTRY,
    'variant': 'crit_block_rate_above_60', 'label_suffix': 'crit_block_rate_above_60',
    'name': 'Shadowy Symbiosis (40% critical block rate and exact 2x blocked amount at 61 Insanity)',
    'quote': 'This effect is doubled while above 60 Insanity.',
    'expected_pct': 40, 'treatment_windows': 15, 'parts': 8,
    'phase_auras': [[500706, 61, 'caster', 'caster']], 'setup_wait_ms': 1600,
    'after_setup_stacks': [
        {'spell': 500706, 'actor': 'caster', 'stacks': 61},
        {'spell': 680603, 'actor': 'caster', 'stacks': 1},
        {'spell': 573315, 'actor': 'caster', 'stacks': 1},
    ]}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(25), entry)


def seeded_runs(model: dict, ctrl_blocks: int = 100, ctrl_crits: int = 0, treat_blocks: int = 2600,
                treat_crits: int = 520, block_value: int = 45, treat_other: int = 0, treat_full: int = 0,
                crit_multiplier: int = 2, overrides: dict | None = None) -> list[FakeRun]:
    parts = int(model['parts'])
    runs = []
    for part in range(parts):
        values = {}
        cum_all = cum_norm = cum_crit = cum_other = cum_full = 0
        cum_t_all = cum_t_norm = cum_t_crit = 0
        for arm, n_all, n_crit, n_other, n_full in (
                (CONTROL, ctrl_blocks, ctrl_crits, 0, 0),
                (TREATMENT, treat_blocks, treat_crits, treat_other, treat_full)):
            am = model['arms'][arm]
            values[am['shield']] = float(model['shield_item'])
            for stack in (*am['stacks'], *am['window_stacks'], *am['end_stacks']):
                values[stack['label']] = float(stack['expected'])
            values[am['start']['block_value']] = float(block_value)
            values[am['start']['count_all']] = float(cum_all)
            values[am['start']['count_normal']] = float(cum_norm)
            values[am['start']['count_critical']] = float(cum_crit)
            values[am['start']['count_other']] = float(cum_other)
            values[am['start']['count_full']] = float(cum_full)
            values[am['start']['total_all']] = float(cum_t_all)
            values[am['start']['total_normal']] = float(cum_t_norm)
            values[am['start']['total_critical']] = float(cum_t_crit)
            n_norm = n_all - n_crit - n_other - n_full
            cum_all += n_all
            cum_norm += n_norm
            cum_crit += n_crit
            cum_other += n_other
            cum_full += n_full
            t_norm = n_norm * block_value
            t_crit = n_crit * block_value * crit_multiplier
            t_other = n_other * (block_value + 10)
            cum_t_norm += t_norm
            cum_t_crit += t_crit
            cum_t_all += t_norm + t_crit + t_other
            values[am['end']['block_value']] = float(block_value)
            values[am['end']['count_all']] = float(cum_all)
            values[am['end']['count_normal']] = float(cum_norm)
            values[am['end']['count_critical']] = float(cum_crit)
            values[am['end']['count_other']] = float(cum_other)
            values[am['end']['count_full']] = float(cum_full)
            values[am['end']['total_all']] = float(cum_t_all)
            values[am['end']['total_normal']] = float(cum_t_norm)
            values[am['end']['total_critical']] = float(cum_t_crit)
        if overrides and part in overrides:
            values.update(overrides[part])
        runs.append(FakeRun(values))
    return runs


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CriticalBlockRateTests(unittest.TestCase):
    def test_generates_valid_scenarios_and_registers_event_evidence(self):
        self.assertNotIn(COUNT_METRIC, METRIC_EVIDENCE)
        self.assertNotIn(TOTAL_METRIC, METRIC_EVIDENCE)
        self.assertEqual(metric_evidence()[COUNT_METRIC], EVENT)
        self.assertEqual(metric_evidence()[TOTAL_METRIC], EVENT)
        for entry, treat_blocks, treat_crits in (
                (SYMBIOSIS_BASE_ENTRY, 2600, 520),
                (SYMBIOSIS_AT_60_ENTRY, 2600, 520),
                (SYMBIOSIS_ABOVE_60_ENTRY, 3000, 1200)):
            with self.subTest(variant=entry['variant']):
                scenario, [exp] = scenario_of(entry)
                validated = run.validate(scenario)
                self.assertEqual(len(validated['creatures']), entry['strikers'])
                ctrl_m = exp.model['arms'][CONTROL]
                treat_m = exp.model['arms'][TREATMENT]
                self.assertEqual(len(ctrl_m['window_stacks']), 0)
                self.assertEqual(len(ctrl_m['end_stacks']), len(entry['after_setup_stacks']))
                self.assertEqual(len(treat_m['window_stacks']),
                                 (entry['treatment_windows'] - 1) * len(entry['after_setup_stacks']))
                self.assertEqual(len(treat_m['end_stacks']), len(entry['after_setup_stacks']))
                runs = seeded_runs(exp.model, treat_blocks=treat_blocks, treat_crits=treat_crits)
                verdict = critical_block_rate_verdict(base_verdict(exp), runs, exp.model)
                self.assertEqual(verdict.status, 'ok', verdict.explanation)
                self.assertAlmostEqual(verdict.detail['crit_amount_ratio'], 2.0)
                self.assertEqual(EVIDENCE[verdict.check], BY_METRIC)
                self.assertEqual(verdict_evidence(verdict, entry['quote'], {}), BEHAVIOUR)

    def test_minimum_trial_bounds_match_g20_residual_budget(self):
        self.assertGreaterEqual(minimum_treatment_trials(0.20, 1e-3), 14600)
        self.assertGreaterEqual(minimum_treatment_trials(0.40, 1e-3), 22000)
        self.assertGreaterEqual(minimum_control_trials(0.20, 1e-3), 50)

    def test_mutants_wrong_rate_control_leak_and_wrong_multiplier_alert(self):
        _, [exp] = scenario_of(SYMBIOSIS_BASE_ENTRY)
        cases = (
            ('rate_40_instead_of_20', seeded_runs(exp.model, treat_blocks=2600, treat_crits=1040)),
            ('rate_0_not_doubling', seeded_runs(exp.model, treat_blocks=2600, treat_crits=0)),
            ('rate_10_too_low', seeded_runs(exp.model, treat_blocks=2600, treat_crits=260)),
            ('control_leak', seeded_runs(exp.model, ctrl_blocks=100, ctrl_crits=1, treat_blocks=2600, treat_crits=520)),
            ('non_2x_other_amount', seeded_runs(exp.model, treat_blocks=2600, treat_crits=510, treat_other=10)),
            ('wrong_crit_multiplier_3x', seeded_runs(exp.model, treat_blocks=2600, treat_crits=520, crit_multiplier=3)),
        )
        for name, runs in cases:
            with self.subTest(mutant=name):
                verdict = critical_block_rate_verdict(base_verdict(exp), runs, exp.model)
                self.assertEqual(verdict.status, 'alert', f'{name}: {verdict.explanation}')

    def test_unmeasured_and_insufficient_trials_cases(self):
        _, [exp] = scenario_of(SYMBIOSIS_BASE_ENTRY)
        am = exp.model['arms'][TREATMENT]
        self.assertEqual(critical_block_rate_verdict(base_verdict(exp), [], exp.model).status, 'unmeasured')
        self.assertEqual(
            critical_block_rate_verdict(base_verdict(exp), seeded_runs(exp.model, treat_blocks=2600, treat_crits=520,
                                                                       treat_full=1), exp.model).status,
            'unmeasured')
        self.assertEqual(
            critical_block_rate_verdict(base_verdict(exp), seeded_runs(exp.model, treat_blocks=500, treat_crits=100),
                                        exp.model).status,
            'insufficient_trials')
        self.assertEqual(
            critical_block_rate_verdict(base_verdict(exp), seeded_runs(exp.model, ctrl_blocks=5, treat_blocks=2600,
                                                                       treat_crits=520), exp.model).status,
            'insufficient_trials')
        for name, patch in (
                ('wrong_shield', {am['shield']: 9999.0}),
                ('wrong_insanity_stack', {am['stacks'][0]['label']: 61.0}),
                ('insanity_drifted_mid_arm', {am['window_stacks'][0]['label']: 58.0}),
                ('insanity_drifted_at_end', {am['end_stacks'][0]['label']: 58.0}),
                ('block_value_drifted', {am['end']['block_value']: 60.0}),
                ('zero_block_value', {am['start']['block_value']: 0.0, am['end']['block_value']: 0.0})):
            with self.subTest(case=name):
                runs = seeded_runs(exp.model, overrides={0: patch})
                self.assertEqual(critical_block_rate_verdict(base_verdict(exp), runs, exp.model).status, 'unmeasured')
        for entry, treat_blocks, treat_crits, drifted in (
                (SYMBIOSIS_AT_60_ENTRY, 2600, 520, 58.0),
                (SYMBIOSIS_ABOVE_60_ENTRY, 3000, 1200, 59.0)):
            _, [exp_i] = scenario_of(entry)
            treat_i = exp_i.model['arms'][TREATMENT]
            for name, label in (
                    (f'{entry["variant"]}_mid_arm_drift', treat_i['window_stacks'][0]['label']),
                    (f'{entry["variant"]}_end_drift', treat_i['end_stacks'][0]['label'])):
                with self.subTest(case=name):
                    runs = seeded_runs(exp_i.model, treat_blocks=treat_blocks, treat_crits=treat_crits,
                                       overrides={0: {label: drifted}})
                    verdict = critical_block_rate_verdict(base_verdict(exp_i), runs, exp_i.model)
                    self.assertEqual(verdict.status, 'unmeasured', f'{name}: {verdict.explanation}')
            with self.subTest(case=f'{entry["variant"]}_missing_end_stack'):
                runs = seeded_runs(exp_i.model, treat_blocks=treat_blocks, treat_crits=treat_crits)
                del runs[0].values[treat_i['end_stacks'][0]['label']]
                verdict = critical_block_rate_verdict(base_verdict(exp_i), runs, exp_i.model)
                self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)

    def test_refuses_bad_specs(self):
        for bad in (
                {**SYMBIOSIS_BASE_ENTRY, 'unknown_field': 1},
                {**SYMBIOSIS_BASE_ENTRY, 'expected_pct': 0},
                {**SYMBIOSIS_BASE_ENTRY, 'expected_pct': 100},
                {**SYMBIOSIS_BASE_ENTRY, 'strikers': 0},
                {**SYMBIOSIS_BASE_ENTRY, 'strikers': 11},
                {**SYMBIOSIS_BASE_ENTRY, 'shield_slot': 15},
                {**SYMBIOSIS_BASE_ENTRY, 'learn': [680574]},
                {**SYMBIOSIS_BASE_ENTRY, 'residual': 1.0},
                {**SYMBIOSIS_BASE_ENTRY, 'setup_wait_ms': -1},
                {**SYMBIOSIS_BASE_ENTRY, 'phase_auras': [[500706, 60, 'dummy', 'caster']]},
                {**SYMBIOSIS_BASE_ENTRY, 'after_setup_stacks': [{'spell': 500706, 'actor': 'dummy', 'stacks': 0}]}):
            with self.subTest(bad=bad):
                with self.assertRaises(ValueError):
                    critical_block_spec(bad)
