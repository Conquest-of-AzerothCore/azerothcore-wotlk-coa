import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run

BUTTONS = [[132, 500960], [133, 505339], [134, 500961]]


def rite_entry(**changes) -> dict:
    return {'spell': 575025, 'name': 'Rite of the Loa (the Ward on a button is placed)', 'kind': 'metric_delta',
            'label_suffix': 'rite_ward', 'quote': 'Simultaneously places each selected', 'trigger_spell': 575025,
            'target': 'caster', 'measure_actor': 'caster', 'metric': 'owned_creature_count',
            'fields': {'entry': 50105}, 'before_expected': 0, 'expected': 1, 'cast_power': 1497, 'wait_ms': 1500,
            'expire_ms': 500, 'learn': [500960, 505339, 500961], 'action_buttons': BUTTONS, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ActionButtonsTests(unittest.TestCase):
    def test_the_buttons_are_set_in_the_treatment_phase_only(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), rite_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        before = labels.index(expectation.model['before_label'])
        placed = [index for index, step in enumerate(steps) if step['action'] == 'set_action_button']
        self.assertEqual([[steps[index]['button'], steps[index]['spell']] for index in placed], BUTTONS)
        self.assertTrue(all(index > before for index in placed))
        rites = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 575025]
        self.assertLess(placed[-1], rites[-1])

    def test_without_the_option_no_button_is_set(self):
        entry = {key: value for key, value in rite_entry().items() if key != 'action_buttons'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'set_action_button' for step in scenario['steps']))

    def test_refused_inputs(self):
        for raw in ([], [[200, 500960]], [[132, 500960], [132, 505339]], [[132]]):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), rite_entry(action_buttons=raw))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), rite_entry(learn=[500960]))


if __name__ == '__main__':
    unittest.main()
