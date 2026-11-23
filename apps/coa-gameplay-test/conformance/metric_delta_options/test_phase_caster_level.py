import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def level_entry(**changes) -> dict:
    return {'spell': 801689, 'name': 'Arcane Brew (spell power at two caster levels)', 'kind': 'metric_delta',
            'label_suffix': 'level_scaling', 'quote': 'Spell power scales with caster level.', 'expected': 73.5,
            'before_expected': 58.5, 'tolerance': 0.5, 'trigger_spell': 801689, 'target': 'caster',
            'measure_actor': 'caster', 'metric': 'spell_power', 'fields': {'school': 5}, 'cast_power': 1000,
            'wait_ms': 1500, 'expire_ms': 10500, 'phase_caster_level': [50, 60], **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PhaseCasterLevelTests(unittest.TestCase):
    def test_each_phase_starts_at_its_level(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), level_entry())
        run.validate(scenario)
        steps = scenario['steps']
        levels = [(index, step['value']) for index, step in enumerate(steps) if step['action'] == 'set_level']
        self.assertEqual([value for _, value in levels], [50, 60])
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 801689]
        labels = [step.get('label') for step in steps]
        self.assertLess(levels[0][0], casts[0])
        self.assertLess(labels.index(expectation.model['before_label']), levels[1][0])
        self.assertLess(levels[1][0], casts[1])
        self.assertEqual(expectation.model['phase_caster_level'], [50, 60])

    def test_without_the_option_the_level_is_not_set(self):
        entry = {key: value for key, value in level_entry().items() if key != 'phase_caster_level'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'set_level' for step in scenario['steps']))

    def test_refused_inputs(self):
        for changes in ({'phase_caster_level': [60, 60]}, {'phase_caster_level': [0, 60]},
                        {'phase_caster_level': [50]}, {'cast_in_before': False}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), level_entry(**changes))


if __name__ == '__main__':
    unittest.main()
