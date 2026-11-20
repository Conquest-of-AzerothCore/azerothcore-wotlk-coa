import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def channel_entry(**changes) -> dict:
    return {'spell': 805751, 'name': 'Twilight Frenzy (channel continues while moving)', 'kind': 'metric_delta',
            'label_suffix': 'moving_channel', 'quote': 'Can dodge and parry and move while active.',
            'expected': 0, 'before_expected': 0, 'after_at_least': 1, 'trigger_spell': 805751, 'target': 'caster',
            'measure_actor': 'caster', 'cast_power': 1000, 'wait_ms': 1000, 'expire_ms': 500,
            'metric': 'cast_remaining_ms', 'fields': {'spell': 805751}, 'gate_timing': 'start',
            'trigger_only_after': True, **changes}


OPTION = {'every_ms': 500, 'count': 6, 'dy': 1.5}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RelocateDuringWaitTests(unittest.TestCase):
    def test_the_caster_moves_back_and_forth_after_each_trigger_cast(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     channel_entry(relocate_during_wait=OPTION))
        run.validate(scenario)
        steps = scenario['steps']
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 805751)
        moves = steps[cast + 1:cast + 13]
        self.assertEqual([step['action'] for step in moves], ['wait', 'relocate'] * 6)
        self.assertEqual([step['ms'] for step in moves[::2]], [500] * 6)
        self.assertEqual([step['dy'] for step in moves[1::2]], [1.5, -1.5] * 3)
        self.assertEqual(steps[cast + 13], {'action': 'wait', 'ms': 1000})
        self.assertEqual(sum(step['action'] == 'relocate' for step in steps), 6)
        self.assertEqual(expectation.model['relocate_during_wait'], {'every_ms': 500, 'count': 6, 'dy': 1.5})
        self.assertIn('6 moves 500 ms apart', scenario['contract'])

    def test_without_the_option_the_caster_stays(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), channel_entry())
        self.assertFalse(any(step['action'] == 'relocate' for step in scenario['steps']))
        self.assertNotIn('relocate_during_wait', expectation.model)

    def test_a_malformed_option_is_refused(self):
        for raw in ({'every_ms': 500, 'count': 5, 'dy': 1.5}, {'every_ms': 50, 'count': 6, 'dy': 1.5},
                    {'every_ms': 500, 'count': 6, 'dy': 0}, {'every_ms': 500, 'count': 6, 'dy': 21},
                    {'every_ms': 500, 'count': 6}, {'every_ms': True, 'count': 6, 'dy': 1}, 3):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), channel_entry(relocate_during_wait=raw))


if __name__ == '__main__':
    unittest.main()
