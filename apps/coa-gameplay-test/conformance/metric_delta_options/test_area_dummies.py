import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file, load_fixture_class_file
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
                       {'area_dummies': [4.0] * 12}, {'setup_target': 'caster'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), area_entry(**change))

    def test_eleven_area_dummies_fill_the_twelve_creatures_a_scenario_admits(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), area_entry(area_dummies=[4.0] * 11))
        run.validate(scenario)
        self.assertEqual(len(scenario['creatures']), 12)

    def test_an_unmarked_reading_passes_and_a_marked_reading_mutant_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), area_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        held = judge_behaviour(base_verdict(expectation), FakeRun({before: 855.0, after: 1735.0}), expectation)
        self.assertEqual(held.status, 'ok', held.explanation)
        mutant = judge_behaviour(base_verdict(expectation), FakeRun({before: 855.0, after: 1765.0}), expectation)
        self.assertEqual(mutant.status, 'alert', mutant.explanation)


COST_GATE_ENTRY = {
    'spell': 681433, 'name': 'Solar Nova (Conquest cooldown cut per target struck)', 'kind': 'cost_gate',
    'variant': 'cd_conquest_area', 'label_suffix': 'cd_conquest_area',
    'quote': 'Reduces the cooldown of your Solar Invocation spells by $/1000;524858s1 sec for each target struck.',
    'gated_spell': 800764, 'resource': 'cooldown', 'reduction': 3000, 'target': 'caster', 'margin_ms': 60,
    'after_casts': [[681433, 'dummy']], 'after_wait_ms': 1600, 'dummy_distance': 5, 'cast_power': 1363,
    'area_dummies': [5.0, 5.0]}


def cost_gate_entry(**changes) -> dict:
    return {**COST_GATE_ENTRY, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CostGateAreaDummiesTests(unittest.TestCase):
    def test_the_after_casts_strike_the_dummy_beside_two_area_dummies(self):
        scenario, expectations = behaviour_scenario(load_class_file(27), cost_gate_entry())
        run.validate(scenario)
        self.assertEqual(creature_distances(scenario), {'dummy': 5.0, 'area1': 5.0, 'area2': 5.0})
        targets = {step['target'] for step in scenario['steps'] if step['action'] == 'cast'
                   and step['spell'] == 681433}
        self.assertEqual(targets, {'dummy'})
        levels = {expectation.model['arm']: expectation.model['level'] for expectation in expectations}
        self.assertEqual(levels, {'without': 27060.0, 'with': 27060.0, 'beyond': 26940.0})

    def test_without_the_option_the_cost_gate_keeps_one_dummy(self):
        entry = cost_gate_entry(reduction=1000)
        del entry['area_dummies']
        scenario, _ = behaviour_scenario(load_class_file(27), entry)
        self.assertEqual(set(creature_distances(scenario)), {'dummy'})

    def test_area_dummies_need_a_cooldown_cut_by_after_casts_at_the_dummy(self):
        for change in ({'area_dummies': []}, {'area_dummies': [0]}, {'after_casts': []},
                       {'after_casts': [[681433, 'caster']]}, {'resource': 'power'}, {'resets': True}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(27), cost_gate_entry(**change))

    def test_three_targets_pass_and_two_or_four_target_mutants_alert(self):
        _, expectations = behaviour_scenario(load_class_file(27), cost_gate_entry())
        arms = {expectation.model['arm']: expectation for expectation in expectations}
        for name, reads, wanted in (('three targets', {'without': 67, 'with': 0, 'beyond': 67}, 'ok'),
                                    ('two targets', {'without': 67, 'with': 67, 'beyond': 67}, 'alert'),
                                    ('four targets', {'without': 67, 'with': 0, 'beyond': 0}, 'alert')):
            statuses = {judge_behaviour(base_verdict(arms[arm]), FakeRun({arms[arm].label: float(value)}),
                                        arms[arm]).status for arm, value in reads.items()}
            with self.subTest(name=name):
                self.assertEqual('alert' in statuses, wanted == 'alert', statuses)
                if wanted == 'ok':
                    self.assertEqual(statuses, {'ok'})


if __name__ == '__main__':
    unittest.main()
