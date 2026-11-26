import json
import unittest
from pathlib import Path

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.enemy_shooter import parse
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

CALM = 804057
RANGED_ENTRY = Path(__file__).with_name('fixtures_enemy_shooter_ranged.json')


def class_file() -> dict:
    return load_class_file(27)


def shooter_entry(variant='shooter_ranged', **changes) -> dict:
    if variant == 'shooter_ranged':
        entry = json.loads(RANGED_ENTRY.read_text(encoding='utf-8'))
    else:
        entry = next(entry for entry in class_file()['behaviours'] if entry['spell'] == CALM
                     and entry.get('variant') == variant)
    return {**entry, **changes}


def shooter(entry: dict, **changes) -> dict:
    return {**entry, 'enemy_shooter': {**entry['enemy_shooter'], **changes}}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class EnemyShooterTests(unittest.TestCase):
    def judged(self, values, failures=None, entry=None):
        _, [expectation] = behaviour_scenario(class_file(), entry or shooter_entry())
        model = expectation.model
        shot = model['enemy_shooter']
        timed = {shot['attack_time']['label']: shot['attack_time']['value']} if 'attack_time' in shot else {}
        fake = FakeRun({model['before_label']: 1.0, model['after_label']: 1.0, shot['distance_label']: 12.0,
                        shot['applied_label']: 1.0, **timed, **values})
        fake.cast_failures = failures or {807778: [27]}
        return judge_behaviour(base_verdict(expectation), fake, expectation)

    def test_the_enemy_is_a_coa_player_set_up_and_moved_before_the_control_window(self):
        scenario, _ = behaviour_scenario(class_file(), shooter_entry())
        run.validate(scenario)
        enemy = next(player for player in scenario['players'] if player['id'] == 'enemy')
        self.assertEqual((enemy['class'], enemy['ranged_hit_rating']), (15, 10000))
        actions = [(step['action'], step.get('actor')) for step in scenario['steps']]
        for needed in (('learn', 'enemy'), ('equip', 'enemy'), ('set_skill', 'enemy'), ('relocate', 'enemy'),
                       ('cast', 'enemy')):
            self.assertIn(needed, actions)
        self.assertIn('control window', scenario['contract'])

    def test_a_held_shot_count_under_the_trigger_is_judged_ok(self):
        self.assertEqual(self.judged({}).status, 'ok')

    def test_shots_added_under_the_trigger_alert(self):
        _, [expectation] = behaviour_scenario(class_file(), shooter_entry())
        model = expectation.model
        self.assertEqual(self.judged({model['after_label']: 3.0}).status, 'alert')

    def test_each_void_cause_makes_the_trial_unmeasured(self):
        _, [expectation] = behaviour_scenario(class_file(), shooter_entry())
        shot = expectation.model['enemy_shooter']
        causes = (({expectation.model['before_label']: 0.0}, None), ({shot['distance_label']: 2.0}, None),
                  ({shot['applied_label']: 0.0}, None), ({}, {807778: [27], 75: [27]}))
        for values, failures in causes:
            with self.subTest(values=values, failures=failures):
                self.assertEqual(self.judged(values, failures).status, 'unmeasured')

    def test_the_ability_mode_does_not_void_on_the_refusal_it_tests(self):
        entry = shooter_entry('shooter_ability')
        _, [expectation] = behaviour_scenario(class_file(), entry)
        near = {expectation.model['enemy_shooter']['distance_label']: 2.0}
        self.assertEqual(self.judged(near, {807778: [27], 572848: [29]}, entry).status, 'ok')

    def test_the_attack_time_guard_reads_the_enemy_before_the_control_window(self):
        timed = shooter_entry()
        timed = shooter(timed, attack_time_ms={'hand': 2, 'value': 2434.78, 'tolerance': 0.5})
        scenario, [expectation] = behaviour_scenario(class_file(), timed)
        run.validate(scenario)
        label = expectation.model['enemy_shooter']['attack_time']['label']
        reads = [(index, step) for index, step in enumerate(scenario['steps']) if step.get('label') == label]
        self.assertEqual(len(reads), 1)
        index, step = reads[0]
        self.assertEqual((step['actor'], step['metric'], step['hand']), ('enemy', 'attack_time_ms', 2))
        waits = [at for at, other in enumerate(scenario['steps'])
                 if other.get('label') == 'enemy control window without the trigger']
        self.assertTrue(index < waits[0])
        self.assertIn('attack time of hand 2', scenario['contract'])
        self.assertEqual(self.judged({}, entry=timed).status, 'ok')
        self.assertEqual(self.judged({label: 2434.3}, entry=timed).status, 'ok')

    def test_a_different_attack_time_or_no_read_makes_the_trial_unmeasured_never_ok(self):
        timed = shooter(shooter_entry(), attack_time_ms={'hand': 2, 'value': 2434.78, 'tolerance': 0.5})
        _, [expectation] = behaviour_scenario(class_file(), timed)
        label = expectation.model['enemy_shooter']['attack_time']['label']
        for read in (2800.0, 2433.0, 2436.0, None):
            with self.subTest(read=read):
                verdict = self.judged({label: read}, entry=timed) if read is not None else self.judged_without(
                    label, timed)
                self.assertEqual(verdict.status, 'unmeasured')
                self.assertIn('attack time of hand 2', verdict.explanation)

    def judged_without(self, label, entry):
        _, [expectation] = behaviour_scenario(class_file(), entry)
        model = expectation.model
        shot = model['enemy_shooter']
        fake = FakeRun({model['before_label']: 1.0, model['after_label']: 1.0, shot['distance_label']: 12.0,
                        shot['applied_label']: 1.0})
        fake.cast_failures = {807778: [27]}
        return judge_behaviour(base_verdict(expectation), fake, expectation)

    def test_without_the_attack_time_option_the_scenario_and_model_are_unchanged(self):
        scenario, [expectation] = behaviour_scenario(class_file(), shooter_entry())
        self.assertNotIn('attack_time', expectation.model['enemy_shooter'])
        self.assertFalse([step for step in scenario['steps'] if step.get('metric') == 'attack_time_ms'])
        self.assertNotIn('attack time of hand', scenario['contract'])

    def test_a_malformed_attack_time_option_is_refused(self):
        good = shooter_entry()['enemy_shooter']
        for bad in ({'hand': 3, 'value': 2434.78, 'tolerance': 0.5}, {'hand': 2, 'value': 0, 'tolerance': 0.5},
                    {'hand': 2, 'value': 2434.78, 'tolerance': -1}, {'hand': 2, 'value': 2434.78},
                    {'hand': True, 'value': 2434.78, 'tolerance': 0.5}, 'fast'):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse({**good, 'attack_time_ms': bad})

    def test_a_malformed_option_is_refused(self):
        good = shooter_entry()['enemy_shooter']
        for changes in ({'class': 11}, {'class': 33}, {'mode': 'melee'}, {'window_ms': 100}, {'weapons': []},
                        {'distance_yd': [5, 5]}, {'source': ''}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                parse({**good, **changes})
        with self.assertRaises(ValueError):
            parse({key: value for key, value in good.items() if key != 'spell'})

    def test_the_option_needs_an_enemy_player_a_gain_and_an_uncast_before_phase(self):
        for changes in ({'enemy_player_race': 0}, {'expected_gain': None}, {'cast_in_before': True},
                        {'target': 'dummy'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                entry = shooter_entry(**changes)
                if entry.get('expected_gain', 0) is None:
                    del entry['expected_gain']
                behaviour_scenario(class_file(), entry)

    def test_without_the_option_the_scenario_has_no_enemy_actions(self):
        entry = {key: value for key, value in shooter_entry().items() if key != 'enemy_shooter'}
        scenario, _ = behaviour_scenario(class_file(), entry)
        self.assertNotIn(('cast', 'enemy'), [(step['action'], step.get('actor')) for step in scenario['steps']])


if __name__ == '__main__':
    unittest.main()
