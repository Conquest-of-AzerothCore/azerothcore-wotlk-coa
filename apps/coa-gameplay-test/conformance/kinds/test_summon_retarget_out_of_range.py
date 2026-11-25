import unittest

from behaviours import behaviour_scenario
from kinds.summon_retarget_out_of_range import METRIC, summon_retarget_spec, summon_retarget_verdict
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {
    'spell': 572103, 'name': "Tentacle of N'Zoth (retargets when primary runs out of range)",
    'kind': 'summon_retarget_out_of_range', 'variant': 'retarget_out_of_range',
    'label_suffix': 'retarget_out_of_range',
    'quote': 'If your target runs out of range, the tentacle will seek a new target.',
    'entry': 501464, 'effect_aura': 806596,
    'primary_dx': 3.0, 'primary_dy': 0.0, 'secondary_dx': 3.0, 'secondary_dy': 8.0,
    'move_dx': 50.0, 'move_dy': 0.0, 'max_range_yd': 40.0, 'secondary_max_range_yd': 30.0,
    'speed_aura': 11305, 'initial_wait_ms': 300, 'pre_pulse_wait_ms': 4500, 'post_pulse_wait_ms': 2000,
    'expire_wait_ms': 2500, 'cast_power': 2000, 'dummy_entry': 36,
}


def build_entry(**changes):
    return behaviour_scenario(load_class_file(25), {**ENTRY, **changes})


def seeded_run(model: dict, overrides=None, cast_failures=None, drop=None):
    defaults = {
        ('control', 'initial'): {'summon_count': 1.0, 'primary_aura': 1.0, 'secondary_aura': 0.0,
                                 'secondary_combat': 1.0, 'primary_dist': 2.0, 'secondary_dist': 8.0},
        ('control', 'end'): {'summon_count': 1.0, 'primary_aura': 1.0, 'secondary_aura': 0.0,
                             'secondary_combat': 1.0, 'primary_dist': 2.0, 'secondary_dist': 8.0},
        ('between', None): {'summon_count': 0.0, 'primary_aura': 0.0, 'secondary_aura': 0.0},
        ('treatment', 'initial'): {'summon_count': 1.0, 'primary_aura': 1.0, 'secondary_aura': 0.0,
                                   'secondary_combat': 1.0, 'primary_dist': 2.0, 'secondary_dist': 8.0},
        ('treatment', 'mid'): {'summon_count': 1.0, 'primary_aura': 1.0, 'secondary_aura': 0.0,
                               'secondary_combat': 1.0, 'primary_dist': 48.0, 'secondary_dist': 8.0},
        ('treatment', 'end'): {'summon_count': 1.0, 'primary_aura': 1.0, 'secondary_aura': 1.0,
                               'secondary_combat': 1.0, 'primary_dist': 48.0, 'secondary_dist': 8.0},
    }
    values = {}
    for (section, sub), fields in defaults.items():
        snap = model[section] if sub is None else model[section][sub]
        for key, val in fields.items():
            values[snap[key]] = val
    for (section, sub, key), val in (overrides or {}).items():
        snap = model[section] if sub is None else model[section][sub]
        values[snap[key]] = val
    if drop:
        values.pop(drop)
    fake = FakeRun(values)
    fake.cast_failures = cast_failures or {}
    return fake


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SummonRetargetOutOfRangeTests(unittest.TestCase):
    def test_generates_valid_scenario_and_proves_behaviour_evidence(self):
        from coverage import BEHAVIOUR, EVENT, metric_evidence, verdict_evidence
        scenario, [exp] = build_entry()
        valid = run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(exp.label, '572103 behaviour_metric_delta retarget_out_of_range')
        self.assertEqual(exp.model['metric'], METRIC)
        self.assertEqual(metric_evidence()[METRIC], EVENT)
        self.assertEqual(len(valid['creatures']), 2)
        self.assertFalse(valid['creatures'][0]['stationary'])
        self.assertTrue(valid['creatures'][1]['stationary'])
        self.assertEqual(sum(1 for s in valid['steps'] if s['action'] == 'move_point'), 1)
        verdict = summon_retarget_verdict(base_verdict(exp), seeded_run(exp.model), exp.model)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict_evidence(verdict, ENTRY['quote'], {}), BEHAVIOUR)

    def test_mutants_alert_when_treatment_fails_to_retarget_or_control_retargets_in_range(self):
        _, [exp] = build_entry()
        with self.subTest(mutant='no_retarget_in_treatment'):
            fake = seeded_run(exp.model, overrides={('treatment', 'end', 'secondary_aura'): 0.0})
            verdict = summon_retarget_verdict(base_verdict(exp), fake, exp.model)
            self.assertEqual(verdict.status, 'alert')
            self.assertIn('did not afflict', verdict.explanation)
        with self.subTest(mutant='spurious_retarget_in_control'):
            fake = seeded_run(exp.model, overrides={('control', 'end', 'secondary_aura'): 1.0})
            verdict = summon_retarget_verdict(base_verdict(exp), fake, exp.model)
            self.assertEqual(verdict.status, 'alert')
            self.assertIn('control arm afflicted', verdict.explanation)

    def test_unmeasured_on_precondition_and_range_failures(self):
        _, [exp] = build_entry()
        cases = [
            ('primary_did_not_leave_range_by_mid', {('treatment', 'mid', 'primary_dist'): 35.0}),
            ('primary_returned_by_end', {('treatment', 'end', 'primary_dist'): 20.0}),
            ('summon_despawned_early', {('treatment', 'end', 'summon_count'): 0.0}),
            ('between_cleanup_incomplete', {('between', None, 'summon_count'): 1.0}),
            ('secondary_not_in_combat', {('treatment', 'end', 'secondary_combat'): 0.0}),
            ('control_initial_primary_not_afflicted', {('control', 'initial', 'primary_aura'): 0.0}),
            ('treatment_initial_secondary_already_afflicted', {('treatment', 'initial', 'secondary_aura'): 1.0}),
        ]
        for name, overrides in cases:
            with self.subTest(case=name):
                verdict = summon_retarget_verdict(base_verdict(exp), seeded_run(exp.model, overrides=overrides),
                                                  exp.model)
                self.assertEqual(verdict.status, 'unmeasured')
        with self.subTest(case='cast_refused'):
            verdict = summon_retarget_verdict(base_verdict(exp), seeded_run(exp.model, cast_failures={572103: [12]}),
                                              exp.model)
            self.assertEqual(verdict.status, 'unmeasured')
        with self.subTest(case='missing_read'):
            lbl = exp.model['treatment']['end']['secondary_aura']
            verdict = summon_retarget_verdict(base_verdict(exp), seeded_run(exp.model, drop=lbl), exp.model)
            self.assertEqual(verdict.status, 'unmeasured')

    def test_refuses_invalid_specs(self):
        for bad in ({'move_dx': 40.0}, {'move_dx': 101.0}, {'secondary_dx': 3.0, 'secondary_dy': 0.0},
                    {'secondary_dy': 35.0}, {'max_range_yd': 0.0}, {'initial_wait_ms': 50},
                    {'speed_aura': 0}, {'unknown_key': 1}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                summon_retarget_spec({**ENTRY, **bad})
