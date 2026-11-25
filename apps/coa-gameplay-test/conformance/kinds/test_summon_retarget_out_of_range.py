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
    'primary_dx': 0.0, 'primary_dy': -2.0, 'secondary_dx': 7.0, 'secondary_dy': -2.0,
    'control_move_dx': 0.0, 'control_move_dy': -9.0,
    'near_move_dx': 0.0, 'near_move_dy': -22.0,
    'move_dx': 0.0, 'move_dy': -50.0,
    'max_range_yd': 15.0, 'secondary_max_range_yd': 15.0,
    'speed_aura': 11305, 'initial_wait_ms': 300, 'pre_pulse_wait_ms': 4500, 'post_pulse_wait_ms': 2000,
    'expire_wait_ms': 3000, 'cast_power': 2000, 'dummy_entry': 36,
}


def build_entry(**changes):
    return behaviour_scenario(load_class_file(25), {**ENTRY, **changes})


def seeded_run(model: dict, overrides=None, los_overrides=None, cast_failures=None, drop=None, drop_los=None):
    defaults = {
        ('control', 'initial'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_aura': 1.0,
                                 'secondary_aura': 0.0, 'secondary_combat': 1.0, 'primary_dist': 2.0,
                                 'secondary_dist': 8.0},
        ('control', 'end'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_aura': 1.0,
                             'secondary_aura': 0.0, 'secondary_combat': 1.0, 'primary_dist': 11.0,
                             'secondary_dist': 8.0},
        ('between', None): {'summon_count': 0.0, 'primary_alive': 1.0, 'primary_aura': 0.0, 'secondary_aura': 0.0},
        ('treatment', 'initial'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_aura': 1.0,
                                   'secondary_aura': 0.0, 'secondary_combat': 1.0, 'primary_dist': 2.0,
                                   'secondary_dist': 8.0},
        ('treatment', 'mid'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_dist': 48.0},
        ('treatment', 'end'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_aura': 1.0,
                               'secondary_aura': 1.0, 'secondary_combat': 1.0, 'primary_dist': 48.0,
                               'secondary_dist': 8.0},
    }
    if 'treatment_near' in model:
        defaults.update({
            ('treatment_near', 'initial'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_aura': 1.0,
                                            'secondary_aura': 0.0, 'secondary_combat': 1.0, 'primary_dist': 2.0,
                                            'secondary_dist': 8.0},
            ('treatment_near', 'mid'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_dist': 22.0},
            ('treatment_near', 'end'): {'summon_count': 1.0, 'primary_alive': 1.0, 'primary_aura': 1.0,
                                        'secondary_aura': 1.0, 'secondary_combat': 1.0, 'primary_dist': 22.0,
                                        'secondary_dist': 8.0},
            ('between_near', None): {'summon_count': 0.0, 'primary_alive': 1.0, 'primary_aura': 0.0,
                                     'secondary_aura': 0.0},
        })
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
    los_map = {
        ('control', 'end_los'): ('false', 'true'),
        ('treatment', 'mid_los'): ('false', 'true'),
        ('treatment', 'end_los'): ('false', 'true'),
    }
    if 'treatment_near' in model:
        los_map[('treatment_near', 'mid_los')] = ('false', 'true')
        los_map[('treatment_near', 'end_los')] = ('false', 'true')
    for key, pair in (los_overrides or {}).items():
        los_map[key] = pair
    steps = []
    for (section, field), (active, los) in los_map.items():
        if drop_los == (section, field):
            continue
        steps.append({'action': 'cast', 'label': model[section][field],
                      'spell_active': active, 'line_of_sight': los})
    fake = FakeRun(values)
    fake.steps = steps
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
        self.assertEqual(sum(1 for s in valid['steps'] if s['action'] == 'move_point'), 5)
        self.assertEqual(set(exp.model['treatment']['mid']), {'summon_count', 'primary_alive', 'primary_dist'})
        verdict = summon_retarget_verdict(base_verdict(exp), seeded_run(exp.model), exp.model)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict_evidence(verdict, ENTRY['quote'], {}), BEHAVIOUR)

    def test_mutants_alert_on_retarget_failure_or_spurious_control_retarget(self):
        _, [exp] = build_entry()
        with self.subTest(mutant='no_retarget_in_near_treatment'):
            fake = seeded_run(exp.model, overrides={('treatment_near', 'end', 'secondary_aura'): 0.0})
            verdict = summon_retarget_verdict(base_verdict(exp), fake, exp.model)
            self.assertEqual(verdict.status, 'alert')
            self.assertIn('near treatment arm did not afflict', verdict.explanation)
        with self.subTest(mutant='no_retarget_in_far_treatment'):
            fake = seeded_run(exp.model, overrides={('treatment', 'end', 'secondary_aura'): 0.0})
            verdict = summon_retarget_verdict(base_verdict(exp), fake, exp.model)
            self.assertEqual(verdict.status, 'alert')
            self.assertIn('treatment arm did not afflict', verdict.explanation)
        with self.subTest(mutant='spurious_retarget_in_control'):
            fake = seeded_run(exp.model, overrides={('control', 'end', 'secondary_aura'): 1.0})
            verdict = summon_retarget_verdict(base_verdict(exp), fake, exp.model)
            self.assertEqual(verdict.status, 'alert')
            self.assertIn('control arm afflicted', verdict.explanation)

    def test_mutants_void_when_los_lost_or_primary_dies(self):
        _, [exp] = build_entry()
        los_cases = [
            ('control_end_los_lost', {('control', 'end_los'): ('false', 'false')}),
            ('treatment_near_mid_los_lost', {('treatment_near', 'mid_los'): ('false', 'false')}),
            ('treatment_near_end_los_lost', {('treatment_near', 'end_los'): ('false', 'false')}),
            ('treatment_mid_los_lost', {('treatment', 'mid_los'): ('false', 'false')}),
            ('treatment_end_los_lost', {('treatment', 'end_los'): ('false', 'false')}),
            ('probe_spell_known_active', {('treatment', 'end_los'): ('true', 'true')}),
        ]
        for name, los_overrides in los_cases:
            with self.subTest(mutant=name):
                verdict = summon_retarget_verdict(
                    base_verdict(exp), seeded_run(exp.model, los_overrides=los_overrides), exp.model)
                self.assertEqual(verdict.status, 'unmeasured')
        with self.subTest(mutant='missing_los_probe_step'):
            verdict = summon_retarget_verdict(
                base_verdict(exp), seeded_run(exp.model, drop_los=('treatment', 'end_los')), exp.model)
            self.assertEqual(verdict.status, 'unmeasured')
        alive_cases = [
            ('control_end_primary_dead', {('control', 'end', 'primary_alive'): 0.0}),
            ('between_primary_dead', {('between', None, 'primary_alive'): 0.0}),
            ('treatment_near_mid_primary_dead', {('treatment_near', 'mid', 'primary_alive'): 0.0}),
            ('treatment_near_end_primary_dead', {('treatment_near', 'end', 'primary_alive'): 0.0}),
            ('treatment_mid_primary_dead', {('treatment', 'mid', 'primary_alive'): 0.0}),
            ('treatment_end_primary_dead', {('treatment', 'end', 'primary_alive'): 0.0}),
        ]
        for name, overrides in alive_cases:
            with self.subTest(mutant=name):
                verdict = summon_retarget_verdict(
                    base_verdict(exp), seeded_run(exp.model, overrides=overrides), exp.model)
                self.assertEqual(verdict.status, 'unmeasured')

    def test_unmeasured_on_precondition_and_range_failures(self):
        _, [exp] = build_entry()
        cases = [
            ('control_drifted_out_of_range', {('control', 'end', 'primary_dist'): 16.0}),
            ('near_did_not_leave_range_by_mid', {('treatment_near', 'mid', 'primary_dist'): 14.0}),
            ('primary_did_not_leave_range_by_mid', {('treatment', 'mid', 'primary_dist'): 14.0}),
            ('primary_returned_by_end', {('treatment', 'end', 'primary_dist'): 10.0}),
            ('summon_despawned_early', {('treatment', 'end', 'summon_count'): 0.0}),
            ('between_cleanup_incomplete', {('between', None, 'summon_count'): 1.0}),
            ('between_near_cleanup_incomplete', {('between_near', None, 'secondary_aura'): 1.0}),
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
        for bad in ({'move_dy': -15.0}, {'move_dx': 101.0}, {'control_move_dy': -15.0},
                    {'near_move_dy': -15.0}, {'near_move_dy': -50.0},
                    {'secondary_dx': 0.0, 'secondary_dy': -2.0}, {'secondary_dx': 20.0},
                    {'max_range_yd': 0.0}, {'los_probe_spell': 572103}, {'initial_wait_ms': 50},
                    {'speed_aura': 0}, {'unknown_key': 1}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                summon_retarget_spec({**ENTRY, **bad})
