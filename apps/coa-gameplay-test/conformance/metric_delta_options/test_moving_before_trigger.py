import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def moving_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (cast while moving)', 'kind': 'metric_delta',
            'label_suffix': 'moving', 'quote': "to increase your and your Undead minion's haste",
            'expected': 0, 'before_expected': 51, 'trigger_spell': 500237, 'target': 'dummy',
            'wait_ms': 3000, 'expire_ms': 500, 'metric': 'cast_failure', 'fields': {'spell': 500237}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MovingBeforeTriggerTests(unittest.TestCase):
    def test_the_caster_moves_from_each_trigger_cast_until_the_reading_after_it(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     moving_entry(moving_before_trigger={'flag': 'strafe_left'}))
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 500237]
        reads = [labels.index(expectation.model['before_label']), labels.index(expectation.model['after_label'])]
        self.assertEqual(len(casts), 2)
        start = {'action': 'set_moving', 'actor': 'caster', 'enabled': True, 'flag': 'strafe_left'}
        stop = {'action': 'set_moving', 'actor': 'caster', 'enabled': False, 'flag': 'strafe_left'}
        for cast, read in zip(casts, reads):
            self.assertEqual(steps[cast - 1], start)
            self.assertEqual(steps[read + 1], stop)
            self.assertFalse(any(step['action'] == 'set_moving' for step in steps[cast:read]))
        self.assertEqual(sum(step['action'] == 'set_moving' for step in steps), 4)
        self.assertEqual(expectation.model['moving_before_trigger'], 'strafe_left')
        self.assertIn('strafe_left movement flag', scenario['contract'])

    def test_an_uncast_before_phase_does_not_move(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), moving_entry(
            cast_in_before=False, moving_before_trigger={'flag': 'forward'}))
        moves = [step for step in scenario['steps'] if step['action'] == 'set_moving']
        self.assertEqual([step['enabled'] for step in moves], [True, False])

    def test_without_the_option_the_caster_never_moves(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), moving_entry())
        self.assertFalse(any(step['action'] == 'set_moving' for step in scenario['steps']))
        self.assertNotIn('moving_before_trigger', expectation.model)

    def test_a_flag_is_one_of_the_four_directions(self):
        for raw in ({'flag': 'falling'}, {'flag': 'up'}, {}, 'forward', {'flag': 'forward', 'dx': 1}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), moving_entry(moving_before_trigger=raw))


if __name__ == '__main__':
    unittest.main()
