import copy
import sys
from pathlib import Path
import unittest

from profile import DBC_DIR, load_class_file

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run  # noqa: E402

PROTECTOR = 560492


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScriptHitEngageTests(unittest.TestCase):
    def setUp(self):
        self.class_file = load_class_file(27)
        self.entry = copy.deepcopy(next(entry for entry in self.class_file['behaviours']
                                        if entry['spell'] == PROTECTOR and entry.get('label_suffix') == 'flame'))

    def generated(self, entry):
        from behaviours import behaviour_scenario
        scenario, [expectation] = behaviour_scenario(self.class_file, entry)
        return scenario, expectation

    def test_the_striker_is_engaged_once_before_the_control_trials_and_guarded_after_the_treatment(self):
        scenario, expectation = self.generated(self.entry)
        run.validate(scenario)
        steps = scenario['steps']
        attacks = [index for index, step in enumerate(steps) if step['action'] == 'attack']
        stops = [index for index, step in enumerate(steps) if step['action'] == 'stop_attack']
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == PROTECTOR)
        control = next(index for index, step in enumerate(steps) if step.get('label', '').startswith('control '))
        guard = next(index for index, step in enumerate(steps) if step.get('relative_to'))
        reads = next(index for index, step in enumerate(steps)
                     if step.get('label') == f'{expectation.label} total')
        self.assertEqual(len(attacks), 1)
        self.assertEqual(steps[attacks[0]]['target'], 'striker')
        self.assertEqual(steps[attacks[0] - 1]['action'], 'set_combat_avoidance')
        self.assertEqual(len(stops), 1)
        self.assertLess(stops[0], control)
        self.assertLess(learn, guard)
        self.assertLess(guard, reads)
        self.assertEqual((steps[guard]['metric'], steps[guard]['equals']), ('melee_attack_count', 0))
        self.assertEqual(steps[stops[0] + 1]['save_as'], steps[guard]['relative_to'])
        self.assertIn('engaged once', scenario['contract'])

    def test_a_script_hit_without_caster_avoidance_has_no_engage(self):
        from behaviours import script_hit_engage, script_hit_engage_guard, script_hit_spec
        bare = {key: value for key, value in self.entry.items() if key != 'caster_avoidance'}
        bare['casts'] = [[500143, 'caster']]
        spec = script_hit_spec(bare)
        self.assertEqual(script_hit_engage(spec), [])
        self.assertEqual(script_hit_engage_guard(spec), [])


if __name__ == '__main__':
    unittest.main()
