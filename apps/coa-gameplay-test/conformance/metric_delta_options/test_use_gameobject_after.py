import unittest

from behaviours import behaviour_scenario
from coverage import metric_evidence, state_promises
from profile import DBC_DIR, load_fixture_class_file
import run


def cauldron_entry(**changes) -> dict:
    return {'spell': 807908, 'name': 'Mojo Cauldron (charges)', 'kind': 'metric_delta', 'label_suffix': 'charges',
            'quote': 'The cauldron lasts for $d or 25 charges.', 'expected': 1, 'before_expected': 0,
            'trigger_spell': 807908, 'target': 'caster', 'measure_actor': 'caster',
            'metric': 'owned_gameobject_count', 'fields': {'entry': 129364}, 'gate_timing': 'start',
            'trigger_only_after': True, 'cast_power': 1400, 'wait_ms': 1000, 'expire_ms': 500,
            'use_gameobject_after': {'entry': 129364, 'uses': 3, 'gap_ms': 300, 'destroy_item': 576135,
                                     'lead_ms': 2000},
            **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class UseGameObjectAfterTests(unittest.TestCase):
    def test_the_treatment_phase_uses_the_object_and_destroys_each_item(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), cauldron_entry())
        run.validate(scenario)
        actions = [step['action'] for step in scenario['steps']]
        self.assertEqual(actions.count('use_gameobject'), 3)
        self.assertEqual(actions.count('destroy_item'), 3)
        cast = next(index for index, step in enumerate(scenario['steps'])
                    if step['action'] == 'cast' and step['spell'] == 807908)
        self.assertLess(cast, actions.index('use_gameobject'))
        self.assertEqual(scenario['steps'][actions.index('use_gameobject') - 1]['ms'], 2000)

    def test_without_destroy_item_nothing_is_destroyed(self):
        entry = cauldron_entry(use_gameobject_after={'entry': 129364, 'uses': 1, 'gap_ms': 300})
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('destroy_item', [step['action'] for step in scenario['steps']])

    def test_an_ally_uses_the_object_of_the_caster(self):
        entry = cauldron_entry(grouped_ally={'dy': -1, 'grouped': True},
                               use_gameobject_after={'entry': 129364, 'uses': 1, 'gap_ms': 300,
                                                     'destroy_item': 576135, 'user': 'ally'})
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        used = [step for step in scenario['steps'] if step['action'] in ('use_gameobject', 'destroy_item')]
        self.assertEqual([(step['action'], step['actor'], step.get('owner')) for step in used],
                         [('use_gameobject', 'ally', 'caster'), ('destroy_item', 'ally', None)])

    def test_an_ally_user_needs_the_ally(self):
        entry = cauldron_entry(use_gameobject_after={'entry': 129364, 'uses': 1, 'gap_ms': 300, 'user': 'ally'})
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), entry)
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), cauldron_entry(
                use_gameobject_after={'entry': 129364, 'uses': 1, 'gap_ms': 300, 'user': 'dummy'}))

    def test_the_gameobject_reads_have_evidence_rows(self):
        self.assertEqual(metric_evidence()['owned_gameobject_count'], 'event')
        self.assertEqual(metric_evidence()['gameobject_remaining_ms'], 'state')
        self.assertIn('lasts', state_promises()['gameobject_remaining_ms'])

    def test_refused_inputs(self):
        for changes in ({'use_gameobject_after': {'entry': 129364, 'uses': 0, 'gap_ms': 300}},
                        {'use_gameobject_after': {'entry': 129364, 'uses': 1}},
                        {'trigger_only_after': False, 'gate_timing': 'between'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), cauldron_entry(**changes))


if __name__ == '__main__':
    unittest.main()
