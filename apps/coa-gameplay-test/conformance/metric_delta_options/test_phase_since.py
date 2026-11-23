import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def share_entry(**changes) -> dict:
    return {'spell': 92084, 'name': "Puppeteer's Threads (the released share)", 'kind': 'metric_delta',
            'label_suffix': 'stored_share',
            'quote': "Damaging abilities now leave behind Puppeteer's Threads on enemies for $572836d.",
            'trigger_spell': 807037, 'target': 'dummy', 'measure_actor': 'caster', 'metric': 'spell_damage_total',
            'fields': {'spell': 572837, 'target': 'dummy'}, 'cast_power': 1400, 'before_expected': 0,
            'expected': 0.15, 'tolerance': 0.0002, 'wait_ms': 12600, 'expire_ms': 500,
            'ratio_to_metric': {'metric': 'spell_damage_total', 'fields': {'spell': 807037, 'target': 'dummy'}},
            'phase_since': True, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PhaseSinceTests(unittest.TestCase):
    def test_each_reading_and_base_is_relative_to_its_phase_trigger(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), share_entry())
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 807037]
        self.assertEqual(len(casts), 2)
        for cast, phase in zip(casts, ('before', 'after')):
            snapshots = [step['save_as'] for step in steps[cast - 2:cast] if step['action'] == 'snapshot']
            self.assertEqual(snapshots, [f'since_{phase}', f'since_{phase}_base'])
        labels = [step.get('label') for step in steps]
        for moment in ('before', 'after'):
            label = expectation.model[f'{moment}_label']
            self.assertEqual(steps[labels.index(label)]['relative_to'], f'since_{moment}')
            self.assertEqual(steps[labels.index(f'{label} ratio base')]['relative_to'], f'since_{moment}_base')
        self.assertIn('counts only its own phase', scenario['contract'])

    def test_without_the_option_no_snapshot_is_taken(self):
        entry = {key: value for key, value in share_entry().items() if key != 'phase_since'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'snapshot' or 'relative_to' in step for step in scenario['steps']))

    def test_refused_inputs(self):
        for changes in ({'phase_since': False}, {'phase_since': 1}, {'cast_in_before': False},
                        {'setup_casts': [807037]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), share_entry(**changes))


if __name__ == '__main__':
    unittest.main()
