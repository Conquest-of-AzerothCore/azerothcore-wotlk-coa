import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.before_strike_reads import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def templar():
    return load_fixture_class_file(19)


def strike_entry(**changes) -> dict:
    entry = next(entry for entry in templar()['behaviours']
                 if entry.get('spell') == 527023 and entry.get('variant') == 'steed_speed')
    return {**entry,
            'strike': {'spell': 41394, 'health': 50000, 'max_health': 100000, 'count': 1,
                       'wait_ms': 500, 'after_trigger_ms': 500},
            **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BeforeStrikeReadsTests(unittest.TestCase):
    READ = {'actor': 'caster', 'metric': 'aura_charges', 'fields': {'spell': 807440},
            'before_phase_expected': 0, 'expected': 10, 'after_expected': 10, 'tolerance': 0,
            'source': 'Dawn holds 10 charges before and after incoming strike'}

    def test_read_is_placed_before_and_after_treatment_strike_and_judged(self):
        scenario, [expectation] = behaviour_scenario(templar(), strike_entry(before_strike_reads=[self.READ]))
        run.validate(scenario)
        steps = scenario['steps']
        model = expectation.model
        record = model['before_strike_reads'][0]
        read_label = record['label']
        after_label = record['after_label']
        before_phase_label = record['before_phase_label']
        read_idx = next(i for i, step in enumerate(steps) if step.get('label') == read_label)
        self.assertEqual((steps[read_idx + 1]['action'], steps[read_idx + 1]['actor'], steps[read_idx + 1]['spell']),
                         ('cast', 'striker', 41394))
        after_idx = next(i for i, step in enumerate(steps) if step.get('label') == after_label)
        self.assertEqual(steps[after_idx - 1].get('label'), model['after_label'])
        before_phase_idx = next(i for i, step in enumerate(steps) if step.get('label') == before_phase_label)
        self.assertEqual(steps[before_phase_idx - 1].get('label'), model['before_label'])
        ok_values = {model['before_label']: float(model['before_expected']),
                     model['after_label']: float(model['expected']),
                     before_phase_label: 0.0, read_label: 10.0, after_label: 10.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(ok_values), expectation).status, 'ok')
        spent_before = {**ok_values, read_label: 9.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(spent_before), expectation).status, 'alert')
        spent_after = {**ok_values, after_label: 9.0}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(spent_after), expectation).status, 'alert')

    def test_requires_strike_and_rejects_malformed_reads(self):
        for bad in ([], {}, [{'actor': 'caster', 'metric': 'aura_charges', 'expected': 10, 'tolerance': -1,
                              'source': 'bad'}]):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse(bad)
        no_strike = {k: v for k, v in strike_entry(before_strike_reads=[self.READ]).items() if k != 'strike'}
        with self.assertRaises(ValueError):
            behaviour_scenario(templar(), no_strike)


if __name__ == '__main__':
    unittest.main()
