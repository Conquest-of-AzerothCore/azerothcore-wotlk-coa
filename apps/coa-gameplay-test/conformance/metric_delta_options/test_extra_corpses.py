import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def several_entry(**changes) -> dict:
    explodes = next(entry for entry in load_fixture_class_file(23)['behaviours']
                    if entry['spell'] == 533239 and entry.get('label_suffix') == 'corpse_explodes')
    entry = {**explodes, 'variant': 'several_corpses', 'label_suffix': 'several_corpses',
             'metric': 'spell_damage_count', 'expected': 2,
             'extra_corpses': [{'entry': 6, 'health': 100, 'distance': 7}]}
    return {**entry, **changes}


def kills(scenario: dict) -> list[tuple[int, str]]:
    return [(index, step['target']) for index, step in enumerate(scenario['steps'])
            if step['action'] == 'cast' and step['spell'] == 92559]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ExtraCorpsesTests(unittest.TestCase):
    def test_each_extra_corpse_stands_apart_and_dies_to_its_own_cast_in_the_treatment_phase(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), several_entry())
        run.validate(scenario)
        corpses = {creature['id']: creature['distance'] for creature in scenario['creatures']
                   if creature['id'].startswith('corpse')}
        self.assertEqual(corpses, {'corpse': 5.0, 'corpse2': 7.0})
        explosions = [index for index, step in enumerate(scenario['steps'])
                      if step['action'] == 'cast' and step['spell'] == 533239]
        self.assertEqual([target for _, target in kills(scenario)], ['corpse', 'corpse2'])
        self.assertTrue(all(explosions[0] < index < explosions[1] for index, _ in kills(scenario)))

    def test_without_the_option_one_corpse_dies(self):
        entry = {key: value for key, value in several_entry().items() if key != 'extra_corpses'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual([target for _, target in kills(scenario)], ['corpse'])

    def test_extra_corpses_need_the_corpse_fixture_and_a_valid_corpse(self):
        for change in ({'corpse': None, 'setup_target': 'dummy'}, {'extra_corpses': []},
                       {'extra_corpses': [{'entry': 6, 'health': 0, 'distance': 7}]},
                       {'setup_casts': [92559, 92559]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), several_entry(**change))

    def test_two_hits_pass_and_a_single_explosion_mutant_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), several_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        held = judge_behaviour(base_verdict(expectation), FakeRun({before: 0.0, after: 2.0}), expectation)
        self.assertEqual(held.status, 'ok', held.explanation)
        mutant = judge_behaviour(base_verdict(expectation), FakeRun({before: 0.0, after: 1.0}), expectation)
        self.assertEqual(mutant.status, 'alert', mutant.explanation)


if __name__ == '__main__':
    unittest.main()
