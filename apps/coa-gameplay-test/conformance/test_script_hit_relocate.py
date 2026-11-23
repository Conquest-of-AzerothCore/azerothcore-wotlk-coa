import copy
import sys
from pathlib import Path
import unittest

from profile import DBC_DIR, load_fixture_class_file

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run  # noqa: E402

TEMPLAR = 19
SPELL = 807268
POSITION = {'map': 0, 'x': -9617.06, 'y': -288.949, 'z': 57.3053, 'o': 0}
DASH_YD = 10.0


def within(step: dict, value: float) -> bool:
    return step['min'] <= value <= step['max']


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScriptHitRelocateTests(unittest.TestCase):
    def setUp(self):
        self.class_file = load_fixture_class_file(TEMPLAR)
        self.entry = copy.deepcopy(next(entry for entry in self.class_file['behaviours']
                                        if entry['spell'] == SPELL and entry['kind'] == 'script_hit'))
        self.entry['trials'] = 3

    def generated(self, entry):
        from behaviours import behaviour_scenario
        scenario, [expectation] = behaviour_scenario(self.class_file, entry)
        return scenario, expectation

    def relocated(self):
        return {**self.entry, 'trial_position': dict(POSITION)}

    def test_an_entry_without_trial_position_has_no_location_teleport_or_position_read(self):
        scenario, _ = self.generated(self.entry)
        self.assertNotIn('location', scenario)
        self.assertFalse([step for step in scenario['steps'] if step['action'] == 'teleport'
                          or str(step.get('metric', '')).startswith('position_')])
        self.assertNotIn('teleports it back', scenario['contract'])

    def test_every_trial_of_both_arms_is_restored_and_read_before_its_casts(self):
        scenario, expectation = self.generated(self.relocated())
        run.validate(scenario)
        steps = scenario['steps']
        self.assertEqual(scenario['location'], POSITION)
        teleports = [index for index, step in enumerate(steps) if step['action'] == 'teleport']
        self.assertEqual(len(teleports), 2 * self.entry['trials'])
        learn = max(index for index, step in enumerate(steps)
                    if step['action'] == 'learn' and step['spell'] == SPELL)
        self.assertEqual(sum(index < learn for index in teleports), self.entry['trials'])
        ends = teleports[1:] + [len(steps)]
        for start, end in zip(teleports, ends):
            self.assertEqual(steps[start], {'action': 'teleport', 'actor': 'caster', **POSITION})
            reads = steps[start + 1:start + 5]
            self.assertEqual([(step['actor'], step['metric']) for step in reads],
                             [('caster', 'position_x'), ('caster', 'position_y'),
                              ('dummy', 'position_x'), ('dummy', 'position_y')])
            for step, axis in zip(reads[:2], ('x', 'y')):
                self.assertEqual(step['action'], 'assert')
                self.assertIn('SETUP position', step['label'])
                self.assertEqual((step['min'], step['max']), (POSITION[axis] - 0.5, POSITION[axis] + 0.5))
            casts = [index for index in range(start, end) if steps[index]['action'] in ('cast', 'set_aura')]
            self.assertTrue(all(index > start + 4 for index in casts))
        self.assertIn('teleports it back', scenario['contract'])
        self.assertNotIn('trial_position', expectation.model)

    def test_a_caster_left_where_its_dash_ends_fails_the_position_assert(self):
        scenario, _ = self.generated(self.relocated())
        guard = next(step for step in scenario['steps']
                     if step['action'] == 'assert' and step['metric'] == 'position_x')
        self.assertTrue(within(guard, POSITION['x']))
        self.assertFalse(within(guard, POSITION['x'] + DASH_YD))
        self.assertFalse(within(guard, POSITION['x'] + 0.6))

    def test_the_judged_expectation_is_the_same_with_and_without_trial_position(self):
        _, plain = self.generated(self.entry)
        _, relocated = self.generated(self.relocated())
        self.assertEqual(plain, relocated)

    def test_a_malformed_trial_position_is_refused(self):
        from behaviours import behaviour_scenario
        for position in ({'map': 0, 'x': 1.0, 'y': 2.0}, {'map': '0', 'x': 1.0, 'y': 2.0, 'z': 3.0},
                         {**POSITION, 'facing': 1}, [0, 1.0, 2.0, 3.0], {**POSITION, 'x': '1'}):
            with self.subTest(position=position), self.assertRaisesRegex(ValueError, 'trial_position'):
                behaviour_scenario(self.class_file, {**self.entry, 'trial_position': position})

    def test_trial_position_needs_casts_at_the_dummy_receiver(self):
        from behaviours import behaviour_scenario
        with self.assertRaisesRegex(ValueError, 'trial_position'):
            behaviour_scenario(self.class_file, {**self.relocated(), 'receiver': 'caster'})


if __name__ == '__main__':
    unittest.main()
