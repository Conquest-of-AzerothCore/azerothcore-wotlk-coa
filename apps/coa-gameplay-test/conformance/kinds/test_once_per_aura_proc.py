import unittest

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_scenario
from compare import judge_behaviour, missing_measurement
from kinds.once_per_aura_proc import once_per_aura_proc_spec, once_per_aura_proc_verdict
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict
from values import Expectation

ENDURE = 681190
ENDURE_HEAL = 681189
STRIKE = 41394

ENTRY = {
    'spell': ENDURE, 'name': 'Endure the Curse (once per application)', 'kind': 'once_per_aura_proc',
    'variant': 'once_per_aura', 'label_suffix': 'once_per_aura', 'quote': 'Can only occur once.',
    'proc_spell': ENDURE_HEAL, 'strike_spell': STRIKE, 'strike_health': 10500, 'strike_max_health': 100000,
    'caster_auras': [[33143, 1], [524861, 1]], 'wait_ms': 300}


def seeded_values(model: dict, **overrides) -> dict:
    reads = model['reads']
    values = {
        reads['baseline']['logs']: 0.0, reads['baseline']['aura']: 0.0, reads['baseline']['proc']: 0.0,
        reads['control']['logs']: 1.0, reads['control']['aura']: 0.0, reads['control']['proc']: 0.0,
        reads['app1_cast']['aura']: 1.0, reads['app1_cast']['cast_failure']: 0.0,
        reads['hit1']['logs']: 2.0, reads['hit1']['aura']: 1.0, reads['hit1']['proc']: 1.0,
        reads['hit2']['logs']: 3.0, reads['hit2']['aura']: 1.0, reads['hit2']['proc']: 1.0,
        reads['app2_cleared']: 0.0,
        reads['app2_cast']['aura']: 1.0, reads['app2_cast']['cast_failure']: 0.0,
        reads['hit3']['logs']: 4.0, reads['hit3']['aura']: 1.0, reads['hit3']['proc']: 2.0,
    }
    for key, val in overrides.items():
        if key == 'app2_cleared':
            values[reads['app2_cleared']] = val
        else:
            phase, field = key.split('__')
            values[reads[phase][field]] = val
    return values


class OncePerAuraProcPrefixTests(unittest.TestCase):
    def test_measured_hit1_violation_precedes_missing_hit2(self):
        reads = {
            'baseline': dict(logs='b_logs', aura='b_aura', proc='b_proc'),
            'control': dict(logs='c_logs', aura='c_aura', proc='c_proc'),
            'app1_cast': dict(aura='a1_aura', cast_failure='a1_failure'),
            'hit1': dict(logs='h1_logs', aura='h1_aura', proc='h1_proc'),
            'hit2': dict(logs='h2_logs', aura='h2_aura', proc='h2_proc'),
        }
        model = dict(reads=reads, metric='spell_heal_count', spell=ENDURE, proc_spell=ENDURE_HEAL,
                     strike_spell=STRIKE)
        expectation = Expectation('prefix', BEHAVIOUR_METRIC_DELTA, ENDURE, ENDURE_HEAL, None, '', '', model)
        base = base_verdict(expectation)
        run = FakeRun(dict(b_logs=0, b_aura=0, b_proc=0, c_logs=1, c_aura=0, c_proc=0,
                           a1_aura=1, a1_failure=0, h1_logs=2, h1_aura=1, h1_proc=0))

        verdict = once_per_aura_proc_verdict(base, run, model)
        self.assertEqual((verdict.status, verdict.measured, verdict.expected), ('alert', 0.0, 1.0))
        self.assertIn('application 1 hit 1', verdict.explanation)

        run.values['h1_proc'] = 1
        verdict = once_per_aura_proc_verdict(base, run, model)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertEqual(verdict.explanation, missing_measurement(run, 'h2_logs'))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class OncePerAuraProcTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.class_file = load_class_file(20)
        cls.scenario, [cls.expectation] = behaviour_scenario(cls.class_file, ENTRY)

    def judged(self, **overrides):
        return judge_behaviour(base_verdict(self.expectation),
                               FakeRun(seeded_values(self.expectation.model, **overrides)), self.expectation)

    def test_scenario_validates_and_orders_control_two_hits_cancel_and_recast(self):
        run.validate(self.scenario)
        self.assertEqual(self.expectation.label, '681190 behaviour_metric_delta once_per_aura')
        self.assertEqual(self.expectation.model['metric'], 'spell_heal_count')
        self.assertFalse(self.scenario['players'][0]['allow_regeneration'])
        casts = [(step['actor'], step['spell']) for step in self.scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [('striker', STRIKE), (CASTER, ENDURE), ('striker', STRIKE), ('striker', STRIKE),
                                 (CASTER, ENDURE), ('striker', STRIKE)])
        cancels = [step for step in self.scenario['steps']
                   if step['action'] == 'cancel_aura' and step['spell'] == ENDURE]
        self.assertEqual(len(cancels), 1)

    def test_once_per_application_and_reset_on_recast_passes(self):
        self.assertEqual(self.judged().status, 'ok')

    def test_mutants_alert_on_every_broken_invariant(self):
        for case, overrides in (('fires_without_aura', {'control__proc': 1.0, 'hit1__proc': 2.0, 'hit2__proc': 2.0,
                                                        'hit3__proc': 3.0}),
                                ('never_fires', {'hit1__proc': 0.0, 'hit2__proc': 0.0, 'hit3__proc': 0.0}),
                                ('drops_aura_on_hit1', {'hit1__aura': 0.0, 'hit2__aura': 0.0}),
                                ('fires_twice_same_aura', {'hit2__proc': 2.0, 'hit3__proc': 3.0}),
                                ('never_resets_on_recast', {'hit3__proc': 1.0})):
            with self.subTest(case=case):
                self.assertEqual(self.judged(**overrides).status, 'alert')

    def test_missed_strike_failed_cast_or_missing_read_is_unmeasured(self):
        for case, overrides in (('missed_strike', {'hit2__logs': 2.0, 'hit3__logs': 3.0}),
                                ('cast_refused', {'app1_cast__cast_failure': 22.0}),
                                ('not_cleared', {'app2_cleared': 1.0}),
                                ('dirty_baseline', {'baseline__proc': 1.0})):
            with self.subTest(case=case):
                self.assertEqual(self.judged(**overrides).status, 'unmeasured')
        self.assertEqual(judge_behaviour(base_verdict(self.expectation), FakeRun({}), self.expectation).status,
                         'unmeasured')

    def test_invalid_spec_fields_are_refused(self):
        for bad in ({'unknown': 1}, {'strike_health': 100000}, {'wait_ms': 50}, {'proc_metric': 'health'},
                    {'cast_power': -1}, {'caster_auras': [[33143]]}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                once_per_aura_proc_spec({**ENTRY, **bad})
        with self.assertRaises(ValueError):
            behaviour_scenario(self.class_file, {**ENTRY, 'wait_ms': 6000})


if __name__ == '__main__':
    unittest.main()
