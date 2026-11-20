import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

HIT = 500237


def ring_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (ring of hit shares)', 'kind': 'metric_delta',
            'label_suffix': 'ring', 'quote': "to increase your and your Undead minion's haste",
            'expected': 15, 'before_expected': 0, 'trigger_spell': HIT, 'target': 'dummy',
            'setup_casts': [HIT, HIT, HIT], 'setup_target': 'dummy', 'setup_wait_ms': 1600,
            'metric': 'spell_damage_count', 'fields': {'spell': HIT, 'target': 'dummy'},
            'ring_sum': {'spell': HIT, 'share_pct': 15, 'slots': 3}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RingSumTests(unittest.TestCase):
    def scenario(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), ring_entry(**changes))

    def test_a_damage_read_comes_before_each_treatment_cast_and_before_the_judged_reading(self):
        scenario, [expectation] = self.scenario()
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        reads = expectation.model['ring_sum']['reads']
        self.assertEqual(len(reads), 5)
        start, end = labels.index(expectation.model['before_label']), labels.index(expectation.model['after_label'])
        casts = [index for index in range(start, end) if steps[index].get('action') == 'cast'
                 and steps[index].get('spell') == HIT]
        positions = [labels.index(label) for label in reads]
        self.assertEqual(len(casts), 4)
        self.assertTrue(all(read < cast for read, cast in zip(positions, casts)))
        self.assertTrue(all(cast < read for cast, read in zip(casts, positions[1:])))
        self.assertLess(positions[-1], end)
        self.assertEqual((steps[positions[0]]['metric'], steps[positions[0]]['spell']), ('spell_damage_total', HIT))

    def test_without_the_option_no_ring_read_is_made(self):
        entry = {key: value for key, value in ring_entry().items() if key != 'ring_sum'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('ring_sum', expectation.model)
        self.assertFalse(any('ring read' in str(step.get('label', '')) for step in scenario['steps']))

    def test_too_few_casts_or_a_malformed_ring_is_refused(self):
        for changes in ({'setup_casts': [HIT, HIT]}, {'ring_sum': {'spell': HIT, 'share_pct': 15}},
                        {'ring_sum': {'spell': HIT, 'share_pct': 0, 'slots': 3}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.scenario(**changes)

    def judged(self, hits, increase):
        _, [expectation] = self.scenario()
        ring = expectation.model['ring_sum']
        values = {ring['before']: 0.0, ring['after']: float(increase)}
        total = 0.0
        values[ring['reads'][0]] = total
        for label, hit in zip(ring['reads'][1:], hits):
            total += hit
            values[label] = total
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_last_three_shares_pass_and_the_sum_of_every_hit_alerts(self):
        hits = [400, 420, 410, 430]
        last_three = 420 * 15 // 100 + 410 * 15 // 100 + 430 * 15 // 100
        every = 400 * 15 // 100 + last_three
        self.assertEqual(self.judged(hits, last_three).status, 'ok')
        self.assertEqual(self.judged(hits, every).status, 'alert')
        self.assertEqual(self.judged(hits, last_three + 1).status, 'alert')
        self.assertEqual(self.judged([400, 0, 410, 430], last_three).status, 'unmeasured')
        self.assertEqual(self.judged([5, 420, 410, 430], last_three).status, 'unmeasured')


    def max_health(self, **changes):
        return self.scenario(**{'metric': 'max_health', 'fields': {}, 'measure_actor': 'caster',
                                'ring_sum': {'spell': HIT, 'share_pct': 15, 'slots': 3, 'read': 'max_health'},
                                **changes})

    def test_a_max_health_read_is_its_own_state_with_a_health_or_stack_promise(self):
        from coverage import METRIC_EVIDENCE, STATE, STATE_PROMISES, metric_evidence, promised_state, state_promises
        scenario, [expectation] = self.max_health()
        run.validate(scenario)
        model = expectation.model
        reads = [step for step in scenario['steps'] if step.get('label') in (model['before_label'], model['after_label'])]
        self.assertEqual([(step['metric'], step['actor']) for step in reads], [('max_health', 'caster')] * 2)
        self.assertEqual(model['evidence_metric'], 'ring_sum_max_health')
        self.assertNotIn('ring_sum_max_health', METRIC_EVIDENCE)
        self.assertNotIn('ring_sum_max_health', STATE_PROMISES)
        self.assertEqual(metric_evidence()['ring_sum_max_health'], STATE)
        self.assertEqual(state_promises()['ring_sum_max_health'], r'health|stack\w*')
        hits = [400, 420, 410, 430]
        last_three = 420 * 15 // 100 + 410 * 15 // 100 + 430 * 15 // 100
        ring = model['ring_sum']
        values = {ring['before']: 5000.0, ring['after']: 5000.0 + last_three, ring['reads'][0]: 0.0}
        total = 0.0
        for label, hit in zip(ring['reads'][1:], hits):
            total += hit
            values[label] = total
        found = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(found.status, 'ok')
        self.assertEqual(found.detail['metric'], 'ring_sum_max_health')
        self.assertTrue(promised_state(found, 'stacking 3 times.'))
        self.assertTrue(promised_state(found, 'increases your health by 15% of the damage dealt'))
        self.assertFalse(promised_state(found, 'for 8 sec,'))
        values[ring['after']] = 5000.0 + last_three + 400 * 15 // 100
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')

    def test_without_the_read_the_aura_amount_keeps_its_readback_metric(self):
        _, [expectation] = self.scenario()
        self.assertNotIn('evidence_metric', expectation.model)
        self.assertNotIn('read', expectation.model['ring_sum'])

    def test_a_read_that_is_not_the_caster_max_health_is_refused(self):
        for changes in ({'metric': 'aura_amount', 'fields': {'spell': 524669, 'effect': 0}},
                        {'measure_actor': 'dummy'},
                        {'ring_sum': {'spell': HIT, 'share_pct': 15, 'slots': 3, 'read': 'health'}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.max_health(**changes)


if __name__ == '__main__':
    unittest.main()
