import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def relog_entry(**changes) -> dict:
    return {'spell': 807056, 'name': 'Brew Stew (the Bisque after a relog)', 'kind': 'metric_delta',
            'label_suffix': 'logout_expiry', 'quote': 'Brewed items disappear if logged out for more than 15 minutes.',
            'trigger_spell': 807056, 'target': 'caster', 'measure_actor': 'caster', 'metric': 'item_count',
            'fields': {'item': 339008}, 'cast_power': 1400, 'before_expected': 1, 'expected': 0, 'wait_ms': 3500,
            'expire_ms': 500, 'relog_before_read': {'before_offline_s': 870, 'after_offline_s': 930}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RelogBeforeReadTests(unittest.TestCase):
    def test_each_reading_follows_a_relog_and_is_a_share_of_its_snapshot(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), relog_entry())
        run.validate(scenario)
        steps = scenario['steps']
        relogs = [step['offline_seconds'] for step in steps if step['action'] == 'relog']
        self.assertEqual(relogs, [870, 930])
        labels = [step.get('label') for step in steps]
        for phase in ('before', 'after'):
            read = steps[labels.index(expectation.model[f'{phase}_label'])]
            self.assertEqual(read['ratio_to'], f'relog_{phase}')
            self.assertEqual(steps[labels.index(read['label']) - 1]['metric'], 'game_time_ms')

    def test_the_relog_time_must_keep_the_arms_apart(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), relog_entry())
        model = expectation.model
        stamps = model['relog_before_read']['stamps']

        def judged(control_span_ms: float) -> str:
            values = {model['before_label']: 1, model['after_label']: 0,
                      stamps['before'][0]: 0, stamps['before'][1]: control_span_ms,
                      stamps['after'][0]: 0, stamps['after'][1]: 1000}
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(2000), 'ok')
        self.assertEqual(judged(40000), 'unmeasured')

    def test_without_the_option_nothing_is_relogged(self):
        entry = {key: value for key, value in relog_entry().items() if key != 'relog_before_read'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'relog' for step in scenario['steps']))

    def test_refused_inputs(self):
        for raw in ({'before_offline_s': 870}, {'before_offline_s': 930, 'after_offline_s': 870},
                    {'before_offline_s': 0, 'after_offline_s': 930}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), relog_entry(relog_before_read=raw))


if __name__ == '__main__':
    unittest.main()
