import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def base_entry() -> dict:
    return next(entry for entry in load_fixture_class_file(23)['behaviours']
                if entry['spell'] == 707562 and entry.get('label_suffix') == 'one_stack_damage')


def area_entry(**changes) -> dict:
    entry = {**base_entry(), 'variant': 'area_other', 'label_suffix': 'area_other', 'area_dummies': [4.0, 5.0],
             'fields': {**base_entry()['fields'], 'target': 'area1'}}
    return {**entry, **changes}


def creature_distances(scenario: dict) -> dict:
    return {creature['id']: creature['distance'] for creature in scenario['creatures']}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AreaDummiesTests(unittest.TestCase):
    def test_area_dummies_copy_the_dummy_at_their_distances_and_setup_casts_keep_the_dummy(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), area_entry())
        run.validate(scenario)
        dummy = next(creature for creature in scenario['creatures'] if creature['id'] == 'dummy')
        self.assertEqual(creature_distances(scenario), {'dummy': dummy['distance'], 'area1': 4.0, 'area2': 5.0})
        area1 = next(creature for creature in scenario['creatures'] if creature['id'] == 'area1')
        self.assertEqual({**area1, 'id': 'dummy', 'distance': dummy['distance']}, dummy)
        setup = [step['target'] for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 712434]
        self.assertTrue(setup)
        self.assertEqual(set(setup), {'dummy'})
        reads = {step.get('target') for step in scenario['steps'] if step['action'] == 'assert'
                 and step.get('metric') == 'spell_damage_total'}
        self.assertEqual(reads, {'area1'})

    def test_without_the_option_only_the_dummy_stands(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), base_entry())
        self.assertEqual(set(creature_distances(scenario)), {'dummy'})

    def test_area_dummies_need_distances_and_the_dummy_as_setup_target(self):
        for change in ({'area_dummies': []}, {'area_dummies': [0]}, {'area_dummies': 4.0},
                       {'area_dummies': [4.0] * 10}, {'setup_target': 'caster'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), area_entry(**change))

    def test_an_unmarked_reading_passes_and_a_marked_reading_mutant_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), area_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        held = judge_behaviour(base_verdict(expectation), FakeRun({before: 855.0, after: 1735.0}), expectation)
        self.assertEqual(held.status, 'ok', held.explanation)
        mutant = judge_behaviour(base_verdict(expectation), FakeRun({before: 855.0, after: 1765.0}), expectation)
        self.assertEqual(mutant.status, 'alert', mutant.explanation)


if __name__ == '__main__':
    unittest.main()
