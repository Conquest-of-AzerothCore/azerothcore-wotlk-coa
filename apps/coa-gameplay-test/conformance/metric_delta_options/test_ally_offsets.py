import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run

SPELL = 527023
HEALTH_ARM = {'actors': ['ally'], 'metric': 'health', 'before_expected': 5000, 'expected': 5000, 'tolerance': 0,
              'source': 'the ally fixture health, no heal in the scenario'}


def steed_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(19)['behaviours']
                 if entry.get('spell') == SPELL and entry.get('variant') == 'steed_speed')
    return {**entry, **changes}


def offset_entry(offsets, allies: int = 2) -> dict:
    return steed_entry(ally_arm={'allies': allies, 'arms': [HEALTH_ARM]}, ally_offsets=offsets)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AllyOffsetsTests(unittest.TestCase):
    def test_allies_move_in_bounded_steps_right_after_grouping(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19),
                                                     offset_entry({'ally': 39, 'ally2': 41}))
        run.validate(scenario)
        steps = scenario['steps']
        grouped = max(index for index, step in enumerate(steps) if step['action'] == 'group')
        moves = steps[grouped + 1:grouped + 6]
        self.assertEqual(moves, [{'action': 'relocate', 'actor': 'ally', 'dx': 20.0},
                                 {'action': 'relocate', 'actor': 'ally', 'dx': 19.0},
                                 {'action': 'relocate', 'actor': 'ally2', 'dx': 20.0},
                                 {'action': 'relocate', 'actor': 'ally2', 'dx': 20.0},
                                 {'action': 'relocate', 'actor': 'ally2', 'dx': 1.0}])
        self.assertEqual(sum(step['action'] == 'relocate' for step in steps), 5)
        self.assertFalse(any(step['action'] == 'relocate' and step['actor'] == 'caster' for step in steps))
        self.assertEqual(expectation.model['ally_offsets'], {'ally': 39.0, 'ally2': 41.0})
        self.assertIn('ally 39 yd, ally2 41 yd', scenario['contract'])

    def test_without_the_option_no_ally_moves(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19),
                                                     steed_entry(ally_arm={'allies': 2, 'arms': [HEALTH_ARM]}))
        self.assertFalse(any(step['action'] == 'relocate' for step in scenario['steps']))
        self.assertNotIn('ally_offsets', expectation.model)

    def test_an_offset_is_positive_bounded_and_names_a_grouped_ally(self):
        for raw in ({}, {'ally': 0}, {'ally': -3}, {'ally': 101}, {'ally': True}, {'caster': 5}, {'ally': 'far'}, 5):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), offset_entry(raw))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(19), offset_entry({'ally2': 10}, allies=1))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(19), steed_entry(ally_offsets={'ally': 10}))


if __name__ == '__main__':
    unittest.main()
