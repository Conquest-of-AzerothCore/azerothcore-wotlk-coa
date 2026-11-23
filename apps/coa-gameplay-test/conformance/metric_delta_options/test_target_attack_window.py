import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def window_entry(**changes) -> dict:
    return {'spell': 500952, 'name': 'Amphibimorph (a frog dummy stops attacking)', 'kind': 'metric_delta',
            'label_suffix': 'frog_pacified', 'quote': 'making them unable to attack or cast spells',
            'trigger_spell': 500952, 'target': 'dummy', 'measure_actor': 'caster', 'metric': 'melee_attacks_taken',
            'fields': {'target': 'dummy'}, 'gate_timing': 'start', 'trigger_only_after': True, 'cast_power': 1400,
            'target_attack_window': {'engage_ms': 1000, 'land_ms': 1300}, 'before_expected': 2, 'expected': 0,
            'expected_ratio': 0, 'tolerance': 0.01, 'wait_ms': 6000, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TargetAttackWindowTests(unittest.TestCase):
    def test_the_dummy_attacks_and_each_reading_counts_its_own_window(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), window_entry())
        run.validate(scenario)
        steps = scenario['steps']
        actions = [step['action'] for step in steps]
        self.assertEqual(actions.count('creature_attack'), 1)
        attack = steps[actions.index('creature_attack')]
        self.assertEqual((attack['actor'], attack['target']), ('dummy', 'caster'))
        labels = [step.get('label') for step in steps]
        before = steps[labels.index(expectation.model['before_label'])]
        after = steps[labels.index(expectation.model['after_label'])]
        self.assertEqual((before['relative_to'], after['relative_to']),
                         ('attack_window_before', 'attack_window_after'))
        cast = next(index for index, step in enumerate(steps)
                    if step['action'] == 'cast' and step['spell'] == 500952)
        snapshot = next(index for index, step in enumerate(steps) if step.get('save_as') == 'attack_window_after')
        self.assertEqual(steps[cast + 1], {'action': 'wait', 'label': 'let the trigger land', 'ms': 1300})
        self.assertEqual(snapshot, cast + 2)

    def test_without_the_option_the_dummy_does_not_attack(self):
        entry = {key: value for key, value in window_entry().items() if key != 'target_attack_window'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'creature_attack' or 'relative_to' in step
                             for step in scenario['steps']))

    def test_refused_inputs(self):
        for changes in ({'target_attack_window': {'engage_ms': 1000}},
                        {'target_attack_window': {'engage_ms': -1, 'land_ms': 1300}},
                        {'trigger_only_after': False}, {'gate_timing': 'between'},
                        {'metric': 'spell_cast_count', 'fields': {'spell': 1}},
                        {'fields': {'target': 'caster'}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), window_entry(**changes))

    def test_a_self_cast_trigger_keeps_the_dummy_attacking(self):
        entry = window_entry(spell=602220, trigger_spell=602220, target='caster', label_suffix='draught_ignored',
                             quote='which may trick enemies into ignoring you')
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 602220]
        self.assertEqual([step['target'] for step in casts], ['caster'])
        self.assertTrue(any(step['action'] == 'creature_attack' for step in scenario['steps']))

    def test_one_swing_under_the_debuff_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), window_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(control: int, treatment: int) -> str:
            return judge_behaviour(base_verdict(expectation), FakeRun({before: control, after: treatment}),
                                   expectation).status

        self.assertEqual(judged(3, 0), 'ok')
        self.assertEqual(judged(3, 1), 'alert')
        self.assertEqual(judged(1, 0), 'alert')


if __name__ == '__main__':
    unittest.main()
