import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def rising_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (damage at rising power)', 'kind': 'metric_delta',
            'label_suffix': 'rising', 'quote': "to increase your and your Undead minion's haste",
            'expected': 1, 'before_expected': 0, 'trigger_spell': 500237, 'target': 'dummy',
            'metric': 'spell_damage_total', 'fields': {'spell': 500237, 'target': 'dummy'},
            'phase_power': [0, 100, 200], 'monotone': {'levels': [300, 400], 'cumulative': True}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MonotoneTests(unittest.TestCase):
    def test_the_treatment_phase_is_repeated_at_each_level(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), rising_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        levels = expectation.model['monotone']['labels'][2:]
        self.assertEqual(levels, ['300235 spell_damage_total level 300', '300235 spell_damage_total level 400'])
        self.assertLess(labels.index(expectation.model['after_label']), labels.index(levels[0]))
        powers = [step['value'] for step in scenario['steps'] if step['action'] == 'set_power' and step['power'] == 0]
        self.assertEqual([power for power in powers if power in (100, 200, 300, 400)], [100, 200, 300, 400])
        casts = [step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 500237]
        self.assertEqual(len(casts), 4)

    def test_without_the_option_there_is_no_level(self):
        entry = {key: value for key, value in rising_entry().items() if key != 'monotone'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('monotone', expectation.model)
        self.assertFalse(any(' level ' in str(step.get('label', '')) for step in scenario['steps']))

    def test_levels_rise_from_the_phase_power_and_need_it(self):
        for changes in ({'monotone': {'levels': [150], 'cumulative': True}},
                        {'monotone': {'levels': [300, 300], 'cumulative': False}},
                        {'monotone': {'levels': [], 'cumulative': True}},
                        {'monotone': {'levels': [300]}},
                        {'phase_power': None}):
            entry = {key: value for key, value in rising_entry(**changes).items() if value is not None}
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), entry)

    def test_a_cumulative_reading_is_judged_per_phase_and_a_flat_phase_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), rising_entry())
        labels = expectation.model['monotone']['labels']

        def judged(*reads) -> str:
            values = {label: value for label, value in zip(labels, reads)}
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(600, 2700, 6900, 12600), 'ok')
        self.assertEqual(judged(600, 2700, 4800, 12600), 'alert')
        self.assertEqual(judged(600, 1200, 1800, 2400), 'alert')
        self.assertEqual(judged(600, 2700, 6900), 'alert')

    def test_a_state_reading_is_judged_as_read(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                              rising_entry(monotone={'levels': [300, 400], 'cumulative': False}))
        labels = expectation.model['monotone']['labels']

        def judged(*reads) -> str:
            return judge_behaviour(base_verdict(expectation), FakeRun(dict(zip(labels, reads))), expectation).status

        self.assertEqual(judged(1, 2, 3, 4), 'ok')
        self.assertEqual(judged(1, 2, 2, 4), 'alert')
        self.assertEqual(judged(4, 3, 2, 1), 'alert')


if __name__ == '__main__':
    unittest.main()
