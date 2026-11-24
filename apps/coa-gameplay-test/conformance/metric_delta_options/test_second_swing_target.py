import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options import second_swing_target
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {
    'spell': 680643, 'name': 'Valiance (a second target gets its own extra attack)', 'kind': 'metric_delta',
    'variant': 'second_target', 'label_suffix': 'second_target',
    'quote': 'your first auto attack on a target hits twice', 'attack_swings': 3, 'target': 'dummy',
    'trigger_spell': 681472, 'metric': 'spell_cast_count', 'fields': {'spell': 681472}, 'before_expected': 0,
    'expected': 2, 'expire_ms': 500, 'area_dummies': [3.0], 'second_swing_target': 'area1'}


def entry(**changes) -> dict:
    return {key: value for key, value in {**ENTRY, **changes}.items() if value is not None}


class ParseTests(unittest.TestCase):
    def test_an_area_dummy_id_parses(self):
        self.assertEqual(second_swing_target.parse('area2'), 'area2')

    def test_other_values_are_refused(self):
        for raw in ('dummy', 'area0', 'area10', '', 1, True, ['area1'], None):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                second_swing_target.parse(raw)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScenarioTests(unittest.TestCase):
    def test_each_phase_attacks_the_dummy_then_the_area_dummy_for_the_same_wait(self):
        scenario, _ = behaviour_scenario(load_class_file(27), entry())
        run.validate(scenario)
        attacks = [(step['action'], step.get('target'), step.get('ms')) for step in scenario['steps']
                   if step['action'] in ('attack', 'stop_attack') or step.get('label', '').endswith('swings')]
        phase = [('attack', 'dummy', None), ('wait', None, 7500), ('stop_attack', None, None),
                 ('attack', 'area1', None), ('wait', None, 7500), ('stop_attack', None, None)]
        self.assertEqual(attacks, phase * 2)
        waited = sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait')
        self.assertGreater(scenario['timeout_ms'], waited)

    def test_without_the_option_each_phase_attacks_the_dummy_only(self):
        scenario, _ = behaviour_scenario(load_class_file(27), entry(second_swing_target=None))
        targets = [step['target'] for step in scenario['steps'] if step['action'] == 'attack']
        self.assertEqual(targets, ['dummy', 'dummy'])

    def test_the_option_needs_swings_and_its_area_dummy_at_the_dummy_distance(self):
        for change in ({'area_dummies': None}, {'second_swing_target': 'area2'}, {'area_dummies': [5.0]},
                       {'attack_swings': None}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(27), entry(**change))

    def test_one_extra_attack_per_target_passes_and_per_caster_or_per_swing_mutants_alert(self):
        _, [expectation] = behaviour_scenario(load_class_file(27), entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        for casts, status in ((2.0, 'ok'), (1.0, 'alert'), (6.0, 'alert')):
            verdict = judge_behaviour(base_verdict(expectation), FakeRun({before: 0.0, after: casts}), expectation)
            with self.subTest(casts=casts):
                self.assertEqual(verdict.status, status, verdict.explanation)


if __name__ == '__main__':
    unittest.main()
