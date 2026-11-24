import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_class_file
import run

TARGETS = ['caster', 'dummy', 'dummy']


def below_six_entry(**changes) -> dict:
    return {'spell': 520257, 'name': 'Demonic Embrace (Inner Demon with five Felfury)', 'kind': 'metric_delta',
            'label_suffix': 'below_six', 'quote': 'Casting Inner Demon with at least 6 Felfury',
            'trigger_spell': 804216, 'gate_spell': 520257, 'target': 'caster', 'select_dummy': True,
            'metric': 'spell_energize_total', 'fields': {'spell': 520258}, 'before_expected': 0, 'expected': 0,
            'tolerance': 0, 'wait_ms': 500, 'expire_ms': 500, 'setup_casts': [805239, 802060, 707901],
            'setup_wait_ms': 1600, 'setup_cast_targets': TARGETS, **changes}


def setup_targets(scenario: dict) -> list[tuple[int, str]]:
    return [(step['spell'], step['target']) for step in scenario['steps']
            if step['action'] == 'cast' and step['spell'] in (805239, 802060, 707901)]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SetupCastTargetsTests(unittest.TestCase):
    def test_each_setup_cast_goes_to_its_own_target_in_both_phases(self):
        scenario, _ = behaviour_scenario(load_class_file(14), below_six_entry())
        run.validate(scenario)
        self.assertEqual(setup_targets(scenario), [(805239, 'caster'), (802060, 'dummy'), (707901, 'dummy')] * 2)
        self.assertIn('805239 at the caster, 802060 at the dummy, 707901 at the dummy', scenario['contract'])

    def test_a_swapped_list_moves_the_casts(self):
        scenario, _ = behaviour_scenario(load_class_file(14),
                                         below_six_entry(setup_cast_targets=['dummy', 'caster', 'dummy']))
        self.assertEqual(setup_targets(scenario)[:3], [(805239, 'dummy'), (802060, 'caster'), (707901, 'dummy')])

    def test_without_the_option_every_setup_cast_goes_to_the_entry_target(self):
        plain = {key: value for key, value in below_six_entry().items() if key != 'setup_cast_targets'}
        scenario, _ = behaviour_scenario(load_class_file(14), plain)
        self.assertEqual({target for _, target in setup_targets(scenario)}, {'caster'})
        self.assertNotIn('at their own targets', scenario['contract'])

    def test_refused_inputs(self):
        for changes in ({'setup_cast_targets': []}, {'setup_cast_targets': 'dummy'},
                        {'setup_cast_targets': ['caster', 'dummy']}, {'setup_cast_targets': ['caster', 'ally', 'dummy']},
                        {'setup_target': 'dummy'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(14), below_six_entry(**changes))


if __name__ == '__main__':
    unittest.main()
