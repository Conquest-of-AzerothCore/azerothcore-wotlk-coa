import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def heal_entry(**changes) -> dict:
    return {'spell': 560748, 'name': 'Frenzied Spirits (heal share of three Spirits)', 'kind': 'metric_delta',
            'label_suffix': 'heal_three', 'quote': 'Consumes your Spirits', 'expected': 0.06, 'before_expected': 0,
            'tolerance': 0.0003, 'trigger_spell': 807037, 'target': 'dummy', 'measure_actor': 'caster',
            'metric': 'spell_heal_total', 'fields': {'spell': 560747, 'target': 'caster'},
            'setup_casts': [560748], 'setup_target': 'dummy', 'setup_only_after': True, 'setup_wait_ms': 300,
            'cast_power': 1400, 'wait_ms': 2800, 'expire_ms': 500,
            'ratio_to_metric': {'metric': 'spell_damage_total', 'fields': {'spell': 807037, 'target': 'dummy'}},
            'phase_since': True, 'required_aura_stacks': {'spell': 561136, 'stacks': 3}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RequiredAuraStacksTests(unittest.TestCase):
    def test_the_precondition_aura_carries_the_stated_stacks(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), heal_entry())
        run.validate(scenario)
        fixtures = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == 561136]
        self.assertEqual([step['stacks'] for step in fixtures], [3])
        self.assertIn('set to 3 stacks', scenario['contract'])

    def test_without_the_option_the_precondition_is_one_stack(self):
        entry = {key: value for key, value in heal_entry().items() if key != 'required_aura_stacks'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        fixtures = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == 561136]
        self.assertEqual([step['stacks'] for step in fixtures], [1])

    def test_refused_inputs(self):
        for raw in ({'spell': 561136}, {'spell': 561136, 'stacks': 0}, {'spell': 1, 'stacks': 3}, [561136, 3]):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), heal_entry(required_aura_stacks=raw))


if __name__ == '__main__':
    unittest.main()
