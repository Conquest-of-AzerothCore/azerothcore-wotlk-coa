import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run

SETUP = 803872


def strikes_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(19)['behaviours']
                 if entry.get('spell') == 804897 and entry.get('kind') == 'metric_delta')
    return {**entry, 'trigger_reset_after_setup': True, **changes}


def cast_order(scenario: dict, trigger: int) -> str:
    letters = []
    for step in scenario['steps']:
        if step['action'] == 'cast' and step.get('spell') == SETUP:
            letters.append('S')
        elif step['action'] == 'cast' and step.get('spell') == trigger:
            letters.append('T')
        elif step['action'] == 'reset_cooldown' and step.get('spell') == trigger:
            letters.append('R')
    return ''.join(letters)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TriggerResetAfterSetupTests(unittest.TestCase):
    def test_the_trigger_cooldown_is_cleared_after_the_setup_cast_of_each_phase(self):
        entry = strikes_entry()
        scenario, _ = behaviour_scenario(load_fixture_class_file(19), entry)
        run.validate(scenario)
        self.assertEqual(cast_order(scenario, entry['trigger_spell']), 'RSRT' * 2)
        self.assertIn('cleared again after the last setup cast', scenario['contract'])

    def test_without_the_option_the_setup_cast_comes_last_before_the_trigger(self):
        entry = {key: value for key, value in strikes_entry().items() if key != 'trigger_reset_after_setup'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(19), entry)
        self.assertEqual(cast_order(scenario, entry['trigger_spell']), 'RST' * 2)

    def test_only_the_last_of_several_setup_casts_is_followed_by_the_reset(self):
        entry = strikes_entry(setup_casts=[SETUP, SETUP])
        scenario, _ = behaviour_scenario(load_fixture_class_file(19), entry)
        self.assertEqual(cast_order(scenario, entry['trigger_spell']), 'RSSRT' * 2)

    def test_the_option_is_true_and_needs_setup_casts(self):
        for raw in (False, 1, 'yes'):
            with self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), strikes_entry(trigger_reset_after_setup=raw))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(19), strikes_entry(setup_casts=[]))


if __name__ == '__main__':
    unittest.main()
