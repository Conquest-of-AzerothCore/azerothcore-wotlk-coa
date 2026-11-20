import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

REFRESH = 'melee_crit_chance_refreshed'


def crit_entry(**changes) -> dict:
    return {'spell': 680514, 'name': 'Secret Society (Shadow crit chance)', 'kind': 'metric_delta',
            'label_suffix': 'shadow_crit', 'quote': 'Increases your Shadow critical strike chance',
            'trigger_spell': 802258, 'target': 'dummy', 'cast_in_before': False, 'wait_ms': 500, 'expire_ms': 500,
            'metric': 'spell_done_crit_chance', 'fields': {'spell': 802258, 'target': 'dummy'}, 'expected': 8,
            'before_expected': 0, 'expected_gain': 8, 'tolerance': 0.01, 'crit_field_refresh': True, **changes}


def built(entry: dict):
    scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), entry)
    return run.validate(scenario), expectation


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CritFieldRefreshTests(unittest.TestCase):
    def test_each_phase_refreshes_the_crit_field_before_its_reading_and_after_the_learn(self):
        scenario, expectation = built(crit_entry())
        labels = [step.get('label') for step in scenario['steps']]
        refreshes = [index for index, step in enumerate(scenario['steps']) if step.get('metric') == REFRESH]
        learn = next(index for index, step in enumerate(scenario['steps'])
                     if step['action'] == 'learn' and step['spell'] == 680514)
        before, after = labels.index(expectation.model['before_label']), labels.index(expectation.model['after_label'])
        self.assertEqual(len(refreshes), 2)
        self.assertLess(refreshes[0], before)
        self.assertLess(before, learn)
        self.assertLess(learn, refreshes[1])
        self.assertLess(refreshes[1], after)
        self.assertIn(f'reads {REFRESH}', scenario['contract'])

    def test_without_the_option_no_refresh_is_read(self):
        entry = {key: value for key, value in crit_entry().items() if key != 'crit_field_refresh'}
        scenario, expectation = built(entry)
        self.assertNotIn('crit_field_refresh', expectation.model)
        self.assertFalse([step for step in scenario['steps'] if step.get('metric') == REFRESH])

    def test_the_option_is_true_and_needs_a_learn_between_the_phases(self):
        for raw in (False, 1, 'yes'):
            with self.assertRaises(ValueError):
                built(crit_entry(crit_field_refresh=raw))
        with self.assertRaises(ValueError):
            built(crit_entry(gate_timing='start'))

    def test_a_refreshed_gain_is_judged_and_a_stale_control_alerts(self):
        _, expectation = built(crit_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        refreshed = dict.fromkeys(expectation.model['crit_field_refresh']['labels'], 2.2907)

        def judged(before_value: float, refreshes: dict) -> str:
            values = {before: before_value, after: 10.2907, **refreshes}
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(2.2907, refreshed), 'ok')
        self.assertEqual(judged(0.0, refreshed), 'alert')
        self.assertEqual(judged(2.2907, {}), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
