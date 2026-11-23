import unittest

from behaviours import STRIKER, behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

NECROMANCER = 23
STUN = 853


def stun_entry(variant: str = 'stun_held', **changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(NECROMANCER)['behaviours']
                 if entry.get('spell') == 681460 and entry.get('variant') == variant)
    return {**entry, 'vehicle_landed': True, **changes}


def generated(entry: dict):
    scenario, [expectation] = behaviour_scenario(load_fixture_class_file(NECROMANCER), entry)
    return scenario, expectation


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class VehicleLandedTests(unittest.TestCase):
    def test_the_counts_are_read_outside_every_timed_interval(self):
        scenario, expectation = generated(stun_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        reads = expectation.model['vehicle_landed']['labels']
        self.assertEqual(labels.index(reads['start']), 1)
        self.assertEqual(labels.index(reads['before']), labels.index(expectation.model['before_label']) + 1)
        self.assertEqual(labels.index(reads['after']), labels.index(expectation.model['after_label']) + 1)
        for name in reads.values():
            step = scenario['steps'][labels.index(name)]
            self.assertEqual((step['actor'], step['metric'], step['spell']), ('caster', 'aura_apply_count', STUN))

    def test_the_timed_steps_keep_their_order_and_spacing(self):
        plain = {key: value for key, value in stun_entry().items() if key != 'vehicle_landed'}
        without, _ = generated(plain)
        with_option, expectation = generated(stun_entry())
        added = set(expectation.model['vehicle_landed']['labels'].values())
        kept = [step for step in with_option['steps'] if step.get('label') not in added]
        self.assertEqual(kept, without['steps'])

    def test_without_the_option_nothing_is_read(self):
        plain = {key: value for key, value in stun_entry().items() if key != 'vehicle_landed'}
        scenario, expectation = generated(plain)
        self.assertNotIn('vehicle_landed', expectation.model)
        self.assertFalse(any(step.get('metric') == 'aura_apply_count' for step in scenario['steps']))

    def test_each_phase_counts_its_own_vehicle_casts(self):
        scenario, expectation = generated(stun_entry())
        strikes = sum(1 for step in scenario['steps'] if step.get('actor') == STRIKER and step.get('action') == 'cast')
        casts = expectation.model['vehicle_landed']['casts']
        self.assertEqual(casts['before'] + casts['after'], strikes)
        self.assertEqual(casts, {'before': 1, 'after': 1})

    def test_the_option_is_true_and_needs_a_strike_at_the_caster(self):
        for raw in ({'spell': STUN}, 1, False, {'max_step_ms': 0}, {'max_step_ms': 25.0}, {'max_step_ms': True},
                    {'max_step_ms': 25, 'spell': STUN}):
            with self.assertRaises(ValueError):
                generated(stun_entry(vehicle_landed=raw))
        with self.assertRaises(ValueError):
            generated(stun_entry(strike={'spell': STUN, 'health': 100000, 'max_health': 100000,
                                         'owned_entry': 50073}))

    def test_a_phase_whose_vehicle_did_not_land_is_unmeasured(self):
        _, expectation = generated(stun_entry())
        model = expectation.model
        reads = model['vehicle_landed']['labels']

        def judged(after_value: float, counts: tuple | None) -> str:
            values = {model['before_label']: 1, model['after_label']: after_value}
            if counts is not None:
                values.update(dict(zip((reads['start'], reads['before'], reads['after']), counts)))
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        held = float(stun_entry()['expected'])
        self.assertEqual(judged(held, (0, 1, 2)), 'ok')
        self.assertEqual(judged(1 - held, (0, 1, 2)), 'alert')
        self.assertEqual(judged(1 - held, (0, 1, 1)), 'unmeasured')
        self.assertEqual(judged(held, (0, 0, 1)), 'unmeasured')
        self.assertEqual(judged(held, (3, 3, 4)), 'unmeasured')
        self.assertEqual(judged(held, None), 'unmeasured')

    def test_a_mutant_that_never_voids_is_caught(self):
        import metric_delta_options.vehicle_landed as module
        _, expectation = generated(stun_entry())
        model = expectation.model
        reads = model['vehicle_landed']['labels']
        values = {model['before_label']: 1, model['after_label']: 1 - float(stun_entry()['expected']),
                  reads['start']: 0, reads['before']: 1, reads['after']: 1}
        original = module.verdict
        try:
            module.verdict = lambda verdict, run, landed: verdict
            mutant = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status
        finally:
            module.verdict = original
        real = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status
        self.assertEqual((mutant, real), ('alert', 'unmeasured'))

    def bounded(self):
        _, expectation = generated(stun_entry(vehicle_landed={'max_step_ms': 25}))
        model = expectation.model
        reads = model['vehicle_landed']['labels']
        values = {model['before_label']: 1, model['after_label']: float(stun_entry()['expected']),
                  reads['start']: 0, reads['before']: 1, reads['after']: 2}
        return expectation, values

    def test_the_step_bound_is_carried_and_stated(self):
        scenario, expectation = generated(stun_entry(vehicle_landed={'max_step_ms': 25}))
        self.assertEqual(expectation.model['vehicle_landed']['max_step_ms'], 25)
        self.assertIn('bounds one world step by 25 ms', scenario['contract'])
        plain, unbounded = generated(stun_entry())
        self.assertNotIn('max_step_ms', unbounded.model['vehicle_landed'])
        self.assertEqual([step for step in scenario['steps']], plain['steps'])

    def test_a_run_whose_step_exceeds_the_bound_is_unmeasured(self):
        expectation, values = self.bounded()

        def judged(max_step_ms) -> str:
            return judge_behaviour(base_verdict(expectation), FakeRun(values, max_step_ms), expectation).status

        self.assertEqual(judged(25), 'ok')
        self.assertEqual(judged(10), 'ok')
        self.assertEqual(judged(26), 'unmeasured')
        self.assertEqual(judged(None), 'unmeasured')
        unbounded = generated(stun_entry())[1]
        self.assertEqual(judge_behaviour(base_verdict(unbounded), FakeRun(values, 26), unbounded).status, 'ok')

    def test_a_mutant_that_ignores_the_step_bound_is_caught(self):
        import metric_delta_options.vehicle_landed as module
        expectation, values = self.bounded()
        original = module.verdict
        try:
            module.verdict = lambda verdict, run, landed: original(
                verdict, run, {key: value for key, value in landed.items() if key != 'max_step_ms'})
            mutant = judge_behaviour(base_verdict(expectation), FakeRun(values, 40), expectation).status
        finally:
            module.verdict = original
        real = judge_behaviour(base_verdict(expectation), FakeRun(values, 40), expectation).status
        self.assertEqual((mutant, real), ('ok', 'unmeasured'))


if __name__ == '__main__':
    unittest.main()
