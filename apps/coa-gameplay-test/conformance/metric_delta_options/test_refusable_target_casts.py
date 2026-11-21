import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

STEALTH = 2144558


def refusable_entry(**changes) -> dict:
    return {'spell': 503714, 'name': 'Eye of Kimbul (a marked enemy cannot use stealth)', 'kind': 'metric_delta',
            'label_suffix': 'no_stealth', 'quote': 'Critical strikes now apply Eye of Kimbul to enemies',
            'trigger_spell': 801669, 'target': 'dummy', 'force_crit': 'spell', 'cast_power': 2000,
            'phase_auras': [[STEALTH, 0, 'dummy', 'dummy']],
            'refusable_target_casts': {'spells': [STEALTH], 'refusal': 22, 'delay_ms': 3500},
            'measure_actor': 'dummy', 'metric': 'aura', 'fields': {'spell': STEALTH}, 'before_expected': 1,
            'expected': 0, 'wait_ms': 500, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RefusableTargetCastsTests(unittest.TestCase):
    def test_each_trigger_is_followed_by_a_refusable_dummy_cast_and_its_result_read(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), refusable_entry())
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['actor'] == 'dummy']
        self.assertEqual(len(casts), 2)
        for index in casts:
            self.assertEqual(steps[index]['allowed_refusal'], 22)
            self.assertEqual(steps[index - 1]['ms'], 3500)
            self.assertEqual(steps[index - 2]['spell'], 801669)
        labels = [step.get('label') for step in steps]
        for moment in ('before', 'after'):
            label = expectation.model[f'{moment}_label']
            result = steps[labels.index(label) + 1]
            self.assertEqual((result['metric'], result['actor'], result['spell']),
                             ('creature_cast_result', 'dummy', STEALTH))

    def test_without_the_option_no_dummy_cast_is_made(self):
        entry = {key: value for key, value in refusable_entry().items() if key != 'refusable_target_casts'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'cast' and step['actor'] == 'dummy' for step in scenario['steps']))

    def test_refused_inputs(self):
        for changes in ({'refusable_target_casts': {'spells': [], 'refusal': 22, 'delay_ms': 0}},
                        {'refusable_target_casts': {'spells': [STEALTH], 'refusal': 0, 'delay_ms': 0}},
                        {'refusable_target_casts': {'spells': [STEALTH, STEALTH], 'refusal': 22, 'delay_ms': 0}},
                        {'refusable_target_casts': {'spells': [STEALTH], 'refusal': 22}},
                        {'target_casts': [STEALTH]}, {'cast_in_before': False}, {'target': 'caster'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), refusable_entry(**changes))

    def test_a_refused_control_cast_is_unmeasured(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), refusable_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(control_result, treatment_result, treatment_aura=0) -> str:
            reads = {before: 1, after: treatment_aura, f'{before} cast result {STEALTH}': control_result,
                     f'{after} cast result {STEALTH}': treatment_result}
            reads = {label: value for label, value in reads.items() if value is not None}
            return judge_behaviour(base_verdict(expectation), FakeRun(reads), expectation).status

        self.assertEqual(judged(255, 22), 'ok')
        self.assertEqual(judged(255, 255), 'ok')
        self.assertEqual(judged(255, 255, treatment_aura=1), 'alert')
        self.assertEqual(judged(22, 22), 'unmeasured')
        self.assertEqual(judged(0, 22), 'unmeasured')
        self.assertEqual(judged(255, None), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
