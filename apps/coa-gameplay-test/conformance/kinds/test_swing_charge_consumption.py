import unittest

from behaviours import behaviour_scenario
from coverage import BEHAVIOUR, BY_METRIC, EVIDENCE, verdict_evidence
from kinds.swing_charge_consumption import KIND, swing_charge_spec, swing_charge_verdict
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

SARONITE_ENTRY = {
    'spell': 301262, 'kind': KIND, 'variant': 'swing_charges', 'label_suffix': 'swing_charges',
    'name': 'Saronite Blessing (ends on 10th melee auto-attack before 15 sec duration)',
    'quote': 'Lasts for $d or $n attacks.', 'quote_spell': 600327,
    'gate_spell': 301262, 'trigger_spell': 502122, 'aura': 600327,
    'haste_auras': [62531, 2116852], 'no_crit_aura': 64481, 'no_crit_amount': -10000, 'force_crit': 'melee',
    'cast_power': 2000}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(25), entry)


def seeded_run(model: dict, overrides: dict | None = None, cast_failures: dict | None = None) -> FakeRun:
    reads = model['reads']
    expected = int(model['expected_charges'])
    values = {
        reads['control']['aura']: 0.0,
        reads['control']['charges']: 0.0,
        reads['start']['time']: 10000.0,
        reads['start']['aura']: 1.0,
        reads['start']['charges']: float(expected),
        reads['start']['swings']: 0.0,
        reads['start']['hits']: 0.0,
        reads['start']['crits']: 0.0,
        reads['penultimate']['time']: 15400.0,
        reads['penultimate']['aura']: 1.0,
        reads['penultimate']['charges']: 1.0,
        reads['penultimate']['swings']: float(expected - 1),
        reads['penultimate']['hits']: float(expected - 1),
        reads['penultimate']['crits']: 0.0,
        reads['final']['time']: 16060.0,
        reads['final']['aura']: 0.0,
        reads['final']['charges']: 0.0,
        reads['final']['swings']: float(expected),
        reads['final']['hits']: float(expected),
        reads['final']['crits']: 0.0,
    }
    if overrides:
        values.update(overrides)
    fake = FakeRun(values)
    fake.cast_failures = dict(cast_failures or {})
    return fake


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SwingChargeConsumptionTests(unittest.TestCase):
    def test_generates_valid_scenario_and_proves_behaviour_evidence(self):
        scenario, [exp] = scenario_of(SARONITE_ENTRY)
        validated = run.validate(scenario)
        swings = [step for step in validated['steps'] if step['action'] == 'attack_until_swings']
        self.assertEqual([step['swings'] for step in swings], [9, 1])
        self.assertEqual(exp.model['expected_charges'], 10)
        self.assertEqual(exp.model['duration_ms'], 15000)
        verdict = swing_charge_verdict(base_verdict(exp), seeded_run(exp.model), exp.model)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertEqual(EVIDENCE[verdict.check], BY_METRIC)
        self.assertEqual(verdict_evidence(verdict, SARONITE_ENTRY['quote'], {}), BEHAVIOUR)

    def test_mutants_wrong_charge_count_early_end_or_non_consumption_alert(self):
        _, [exp] = scenario_of(SARONITE_ENTRY)
        reads = exp.model['reads']
        cases = (
            ('control_leak', {reads['control']['aura']: 1.0, reads['control']['charges']: 10.0}),
            ('wrong_initial_9', {reads['start']['charges']: 9.0}),
            ('wrong_initial_11', {reads['start']['charges']: 11.0}),
            ('ended_at_9', {reads['penultimate']['aura']: 0.0, reads['penultimate']['charges']: 0.0}),
            ('charges_not_decrementing_at_9', {reads['penultimate']['charges']: 2.0}),
            ('still_present_at_10', {reads['final']['aura']: 1.0, reads['final']['charges']: 1.0}),
            ('not_applied', {reads['start']['aura']: 0.0, reads['start']['charges']: 0.0}),
        )
        for name, overrides in cases:
            with self.subTest(mutant=name):
                verdict = swing_charge_verdict(base_verdict(exp), seeded_run(exp.model, overrides), exp.model)
                self.assertEqual(verdict.status, 'alert', f'{name}: {verdict.explanation}')

    def test_unmeasured_on_missing_read_refused_cast_crit_swing_mismatch_or_slow_window(self):
        _, [exp] = scenario_of(SARONITE_ENTRY)
        reads = exp.model['reads']
        self.assertEqual(swing_charge_verdict(base_verdict(exp), FakeRun({}), exp.model).status, 'unmeasured')
        self.assertEqual(
            swing_charge_verdict(base_verdict(exp), seeded_run(exp.model, cast_failures={502122: [1]}),
                                 exp.model).status,
            'unmeasured')
        for name, overrides in (
                ('missed_swing_at_9', {reads['penultimate']['hits']: 8.0}),
                ('extra_swing_at_9', {reads['penultimate']['swings']: 10.0, reads['penultimate']['hits']: 10.0}),
                ('crit_swing_at_9', {reads['penultimate']['crits']: 1.0}),
                ('crit_swing_at_10', {reads['final']['crits']: 1.0}),
                ('elapsed_too_close_to_duration', {reads['final']['time']: 23000.0})):
            with self.subTest(case=name):
                verdict = swing_charge_verdict(base_verdict(exp), seeded_run(exp.model, overrides), exp.model)
                self.assertEqual(verdict.status, 'unmeasured', f'{name}: {verdict.explanation}')

    def test_refuses_bad_specs_and_missing_proc_charges(self):
        for bad in (
                {**SARONITE_ENTRY, 'unknown_field': 1},
                {**SARONITE_ENTRY, 'learn': [301262]},
                {**SARONITE_ENTRY, 'force_crit': 'bogus'},
                {**SARONITE_ENTRY, 'hand': 2},
                {**SARONITE_ENTRY, 'trigger_wait_ms': 50},
                {**SARONITE_ENTRY, 'final_timeout_ms': 100},
                {**SARONITE_ENTRY, 'haste_auras': [0]},
                {**SARONITE_ENTRY, 'no_crit_aura': 0},
                {**SARONITE_ENTRY, 'no_crit_amount': 0},
                {**SARONITE_ENTRY, 'no_crit_aura': None, 'no_crit_amount': -100}):
            with self.subTest(bad=bad):
                with self.assertRaises(ValueError):
                    swing_charge_spec(bad)
        for bad_dbc in (
                {**SARONITE_ENTRY, 'aura': 64481},
                {**SARONITE_ENTRY, 'quote_spell': 502122}):
            with self.subTest(bad_dbc=bad_dbc):
                with self.assertRaises(ValueError):
                    scenario_of(bad_dbc)
