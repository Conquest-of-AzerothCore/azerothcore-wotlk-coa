import unittest

from procs import proc_plan, proc_scenario
from profile import DBC_DIR
from test_compare import CLASS_FILE
import run

OFF_HAND = {'item': 2027, 'slot': 16, 'subclass': 7, 'min_damage': 17.25, 'max_damage': 28.75, 'speed_ms': 1800,
            'inventory_type': 13, 'normalized_speed': 2.4, 'skill_line': 43}


def dual_wielding() -> dict:
    main = {**CLASS_FILE['weapon'], 'skill_line': 44}
    return {**CLASS_FILE, 'weapon_sets': {'Pair': {'main_hand': main, 'off_hand': OFF_HAND, 'ranged': None}},
            'default_weapon_set': 'Pair'}


def entry(**changes) -> dict:
    found = next(proc for proc in CLASS_FILE['procs'] if proc['aura'] == 560648)
    return {**found, 'trial_hand': 'both', **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class BothHandTrialTests(unittest.TestCase):
    def test_both_hand_trials_read_the_sum_of_both_hands(self):
        class_file = dual_wielding()
        scenario, [expectation, *_] = proc_scenario(class_file, entry())
        run.validate(scenario)
        reads = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        labels = expectation.model['measurements']
        self.assertEqual(reads[labels['trials']]['metric'], 'melee_damage_count')
        self.assertNotIn('hand', reads[labels['trials']])
        self.assertNotIn('hand', reads[labels['attempts']])
        self.assertIn('either hand', expectation.rule)

    def test_the_attempt_interval_is_the_combined_swing_rate(self):
        class_file = dual_wielding()
        main = CLASS_FILE['weapon']['speed_ms']
        self.assertEqual(proc_plan(class_file, entry()).attempt_ms, main * 1800 // (main + 1800))

    def test_a_main_hand_entry_still_reads_hand_zero(self):
        scenario, [expectation, *_] = proc_scenario(dual_wielding(), entry(trial_hand=0))
        reads = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertEqual(reads[expectation.model['measurements']['trials']]['hand'], 0)

    def test_both_hand_trials_need_an_off_hand_weapon_and_a_plain_attack_trigger(self):
        with self.assertRaises(ValueError):
            proc_plan(CLASS_FILE, entry())
        for changes in ({'trial_hand': 'either'},
                        {'trigger': {'action': 'cast', 'spell': 504561, 'target': 'dummy'}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                proc_plan(dual_wielding(), entry(**changes))


if __name__ == '__main__':
    unittest.main()
