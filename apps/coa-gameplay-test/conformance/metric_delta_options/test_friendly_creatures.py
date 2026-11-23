import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def base_entry() -> dict:
    return next(entry for entry in load_fixture_class_file(23)['behaviours']
                if entry['spell'] == 707562 and entry.get('label_suffix') == 'one_stack_damage')


def friendly_entry(**changes) -> dict:
    entry = {**base_entry(), 'variant': 'friends', 'label_suffix': 'friends', 'metric': 'aura',
             'fields': {'spell': 707562}, 'measure_actor': 'caster', 'before_expected': 1, 'expected': 4,
             'tolerance': 0, 'friendly_creatures': {'entry': 631, 'distances': [3, 4, 5]}}
    entry.pop('expected_gain', None)
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FriendlyCreaturesTests(unittest.TestCase):
    def test_friendly_creatures_stand_at_their_distances_and_every_judged_read_names_each(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), friendly_entry())
        run.validate(scenario)
        friends = [creature for creature in scenario['creatures'] if creature['id'].startswith('friend')]
        self.assertEqual([(creature['distance'], creature['faction'], creature['entry']) for creature in friends],
                         [(3.0, 35, 631), (4.0, 35, 631), (5.0, 35, 631)])
        after = expectation.model['after_label']
        reads = [step['actor'] for step in scenario['steps'] if step.get('label', '').startswith(after)]
        self.assertEqual(reads, ['caster', 'friend1', 'friend2', 'friend3'])

    def test_the_summed_reading_is_ok_and_a_missing_creature_aura_mutant_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), friendly_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        values = {before: 1.0, after: 1.0, **{f'{before} friend{i}': 0.0 for i in (1, 2, 3)},
                  **{f'{after} friend{i}': 1.0 for i in (1, 2, 3)}}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'ok')
        mutant = {**values, f'{after} friend3': 0.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(mutant), expectation).status, 'alert')

    def test_without_the_option_no_friendly_creature_stands(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), base_entry())
        self.assertFalse(any(creature['id'].startswith('friend') for creature in scenario.get('creatures', ())))

    def test_bad_options_are_refused(self):
        for change in ({'friendly_creatures': {'entry': 631}}, {'friendly_creatures': {'entry': 631, 'distances': []}},
                       {'friendly_creatures': {'entry': 631, 'distances': [3], 'radius': 5}},
                       {'friendly_creatures': {'entry': 631, 'distances': [3]}, 'metric': 'spell_damage_total'},
                       {'area_dummies': [4.0]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), friendly_entry(**change))


if __name__ == '__main__':
    unittest.main()
