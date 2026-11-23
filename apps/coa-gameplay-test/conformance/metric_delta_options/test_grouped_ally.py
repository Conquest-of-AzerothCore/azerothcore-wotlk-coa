import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, base_steps, load_fixture_class_file
import run


def cauldron_entry(**changes) -> dict:
    return {'spell': 807908, 'name': 'Mojo Cauldron (an ally uses it)', 'kind': 'metric_delta',
            'label_suffix': 'ally_mojo', 'quote': 'Raid members may interact with the Cauldron to acquire a',
            'expected': 1, 'before_expected': 0, 'trigger_spell': 807908, 'target': 'caster',
            'measure_actor': 'ally', 'metric': 'spell_cast_count', 'fields': {'spell': 572413},
            'gate_timing': 'start', 'trigger_only_after': True, 'cast_power': 1400, 'wait_ms': 1000,
            'expire_ms': 500, 'grouped_ally': {'dy': -1, 'grouped': True},
            'use_gameobject_after': {'entry': 129364, 'uses': 1, 'gap_ms': 2000, 'user': 'ally'}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class GroupedAllyTests(unittest.TestCase):
    def test_the_ally_stands_beside_the_caster_and_joins_its_group(self):
        class_file = load_fixture_class_file(23)
        scenario, _ = behaviour_scenario(class_file, cauldron_entry())
        run.validate(scenario)
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
        settled = len(base_steps(class_file))
        self.assertEqual(scenario['steps'][settled], {'action': 'relocate', 'actor': 'ally', 'dy': -1.0})
        self.assertEqual(scenario['steps'][settled + 1], {'action': 'group', 'actor': 'caster', 'target': 'ally'})

    def test_an_ungrouped_ally_is_not_grouped(self):
        entry = cauldron_entry(grouped_ally={'dy': 2, 'grouped': False})
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        self.assertNotIn('group', [step['action'] for step in scenario['steps']])

    def test_refused_inputs(self):
        for raw in ({'dy': 0, 'grouped': True}, {'dy': 25, 'grouped': True}, {'dy': 1}, {'dy': 1, 'grouped': 1}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), cauldron_entry(grouped_ally=raw))


if __name__ == '__main__':
    unittest.main()
