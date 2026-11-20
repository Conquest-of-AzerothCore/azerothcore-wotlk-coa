import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def shield_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'shield_hits'
                 and (entry.get('strike') or {}).get('spell') == 11976)
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CasterAvoidanceTests(unittest.TestCase):
    def test_the_caster_avoidance_is_set_right_before_every_strike(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     shield_entry(caster_avoidance={'parry': 100}))
        run.validate(scenario)
        steps = scenario['steps']
        strikes = [index for index, step in enumerate(steps) if step['action'] == 'cast'
                   and step['actor'] == 'striker']
        self.assertEqual(len(strikes), 16)
        for index in strikes:
            self.assertEqual(steps[index - 1], {'action': 'set_combat_avoidance', 'actor': 'caster', 'dodge': 0.0,
                                                'parry': 100.0})
        self.assertEqual(sum(step['action'] == 'set_combat_avoidance' for step in steps), 16)
        self.assertEqual(expectation.model['caster_avoidance'], {'dodge': 0.0, 'parry': 100.0})
        self.assertIn('0% and 100%', scenario['contract'])

    def test_without_the_option_the_avoidance_is_left_alone(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), shield_entry())
        self.assertFalse(any(step['action'] == 'set_combat_avoidance' for step in scenario['steps']))
        self.assertNotIn('caster_avoidance', expectation.model)

    def test_an_avoidance_needs_a_strike_and_percents(self):
        for changes in ({'caster_avoidance': {'parry': 100}, 'strike': None}, {'caster_avoidance': {}},
                        {'caster_avoidance': {'parry': 101}}, {'caster_avoidance': {'block': 50}},
                        {'caster_avoidance': {'dodge': True}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), shield_entry(**changes))


if __name__ == '__main__':
    unittest.main()
