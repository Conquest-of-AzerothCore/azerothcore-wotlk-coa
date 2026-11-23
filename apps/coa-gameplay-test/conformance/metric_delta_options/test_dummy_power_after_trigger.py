import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def jinx_entry(**changes) -> dict:
    return {'spell': 801925, 'name': 'Mana Jinx (no mana regeneration)', 'kind': 'metric_delta',
            'label_suffix': 'jinx_no_regen', 'quote': 'and preventing mana regeneration.', 'trigger_spell': 801925,
            'target': 'dummy', 'target_entry': 11795, 'measure_actor': 'dummy', 'metric': 'power',
            'fields': {'power': 0}, 'gate_timing': 'start', 'trigger_only_after': True, 'cast_power': 2000,
            'before_expected': 1622, 'expected': 0, 'expected_ratio': 0, 'tolerance': 0.01, 'wait_ms': 7000,
            'expire_ms': 500, 'dummy_power_after_trigger': {'power': 0, 'value': 0, 'after_ms': 400}, **changes}


def power_steps(scenario: dict) -> list[int]:
    return [index for index, step in enumerate(scenario['steps'])
            if step['action'] == 'set_power' and step.get('target') == 'dummy']


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class DummyPowerAfterTriggerTests(unittest.TestCase):
    def test_each_phase_empties_the_dummy_before_its_window(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), jinx_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        before = labels.index(expectation.model['before_label'])
        after = labels.index(expectation.model['after_label'])
        trigger = next(index for index, step in enumerate(steps) if step['action'] == 'cast'
                       and step['spell'] == 801925)
        first, second = power_steps(scenario)
        self.assertLess(first, before)
        self.assertEqual(steps[first + 1]['ms'], 7000)
        self.assertTrue(trigger < second < after)
        self.assertEqual(steps[second - 1]['ms'], 400)
        self.assertEqual((steps[second]['power'], steps[second]['value']), (0, 0))

    def test_a_cast_before_phase_sets_the_power_after_each_cast(self):
        entry = jinx_entry(gate_timing='between', trigger_only_after=False, gate_spell=536213)
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        steps = scenario['steps']
        triggers = [index for index, step in enumerate(steps) if step['action'] == 'cast'
                    and step['spell'] == 801925]
        first, second = power_steps(scenario)
        self.assertTrue(triggers[0] < first < triggers[1] < second)

    def test_refused_inputs(self):
        for raw in ({'power': 0, 'value': 0}, {'power': 9, 'value': 0, 'after_ms': 0},
                    {'power': 0, 'value': -1, 'after_ms': 0}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), jinx_entry(dummy_power_after_trigger=raw))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), jinx_entry(target='caster'))


if __name__ == '__main__':
    unittest.main()
