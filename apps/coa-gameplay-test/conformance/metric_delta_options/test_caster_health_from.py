import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
from values import FIXTURE_MAX_HEALTH
import run

CLASS_FILE = load_fixture_class_file(23)

FORTUITOUS = {
    'spell': 561328, 'kind': 'metric_delta', 'quote': 'Removes the cast time of Glare while above 80% health.',
    'trigger_spell': 804584, 'gate_spell': 561328, 'target': 'caster', 'metric': 'spell_cast_time_ms',
    'fields': {'spell': 807870}, 'tolerance': 1, 'wait_ms': 1600, 'expire_ms': 2000,
    'name': 'Fortuitous (Glare cast time at 79% from below)', 'variant': 'glare_band_from_below',
    'label_suffix': 'glare_band_from_below', 'caster_health_pct': 79, 'caster_health_from': 50,
    'disable_regeneration': True, 'before_expected': 1500, 'expected': 1500}



def health_steps(scenario: dict) -> list[dict]:
    return [step for step in scenario['steps'] if step['action'] == 'set_health' and step['actor'] == 'caster']


def without(entry: dict, *keys: str) -> dict:
    return {key: value for key, value in entry.items() if key not in keys}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MetricDeltaHealthFromTests(unittest.TestCase):
    def test_both_phases_set_the_entry_percent_then_the_read_percent_before_the_trigger(self):
        scenario, [expectation, *_] = behaviour_scenario(CLASS_FILE, FORTUITOUS)
        run.validate(scenario)
        values = [step['value'] for step in health_steps(scenario)]
        low, read = 50 * FIXTURE_MAX_HEALTH // 100, 79 * FIXTURE_MAX_HEALTH // 100
        self.assertEqual(values, [low, read, low, read])
        steps = scenario['steps']
        first = next(index for index, step in enumerate(steps) if step['action'] == 'set_health')
        self.assertEqual(steps[first + 1], {'action': 'wait', 'label': 'health from 50% settle', 'ms': 1000})
        self.assertEqual(expectation.model['caster_health_from'], 50)
        self.assertIn('entered from below', scenario['contract'])

    def test_the_option_needs_a_caster_health_another_percent_and_no_regeneration(self):
        for entry in ({**FORTUITOUS, 'caster_health_from': 79}, without(FORTUITOUS, 'disable_regeneration'),
                      without(FORTUITOUS, 'caster_health_pct'), {**FORTUITOUS, 'caster_health_from': 101}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, entry)

    def test_without_the_option_only_the_read_percent_is_set(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, without(FORTUITOUS, 'caster_health_from'))
        self.assertEqual([step['value'] for step in health_steps(scenario)], [7900, 7900])


if __name__ == '__main__':
    unittest.main()
