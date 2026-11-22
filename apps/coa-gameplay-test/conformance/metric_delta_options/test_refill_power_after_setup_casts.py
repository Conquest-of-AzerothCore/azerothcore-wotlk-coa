import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def entry(**changes) -> dict:
    found = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'player_spell')
    return {**found, 'setup_casts': [805044, 805044, 805044], **changes}


def power_steps(scenario) -> list[dict]:
    return [step for step in scenario['steps'] if step['action'] == 'set_power']


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RefillPowerAfterSetupCastsTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), entry(**changes))[0]

    def test_power_is_set_again_after_every_setup_cast_and_the_contract_says_so(self):
        plain = self.build()
        refilled = self.build(refill_power_after_setup_casts={'power': 0})
        run.validate(refilled)
        self.assertEqual(len(power_steps(refilled)) - len(power_steps(plain)), 3)
        setup = [index for index, step in enumerate(refilled['steps']) if step.get('spell') == 805044
                 and step['action'] == 'cast']
        for index in setup:
            follow = next(step for step in refilled['steps'][index + 1:] if step['action'] == 'set_power')
            self.assertEqual((follow['power'], follow['value']), (0, 1373))
        self.assertIn('set to 1373 again after every setup cast', refilled['contract'])
        self.assertNotIn('again after every setup cast', plain['contract'])

    def test_absent_leaves_the_scenario_unchanged(self):
        self.assertEqual(self.build(), self.build(refill_power_after_setup_casts=None))

    def test_the_option_is_refused_for_a_resource_claim_or_without_its_inputs(self):
        for changes in ({'quote': 'costs 30% less mana'}, {'metric': 'power', 'fields': {'power': 0}},
                        {'cast_power': None}, {'setup_casts': []}, {'refill_power_after_setup_casts': {}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23),
                                   entry(**{'refill_power_after_setup_casts': {'power': 0}, **changes}))


if __name__ == '__main__':
    unittest.main()
