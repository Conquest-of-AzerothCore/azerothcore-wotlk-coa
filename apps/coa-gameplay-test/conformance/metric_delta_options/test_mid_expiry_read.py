import unittest

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_scenario
from compare import Verdict
from metric_delta_options.mid_expiry_read import parse, verdict
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun


class MidExpiryReadUnitTests(unittest.TestCase):
    def test_parse_validation_and_verdict(self):
        parsed = parse({'wait_ms': 4000, 'expected': 19094, 'tolerance': 15, 'source': '4 of 5 ticks paid'})
        self.assertEqual((parsed.wait_ms, parsed.expected, parsed.tolerance), (4000, 19094.0, 15.0))
        for bad in (
            {'wait_ms': 0, 'expected': 1, 'tolerance': 1, 'source': 's'},
            {'wait_ms': True, 'expected': 1, 'tolerance': 1, 'source': 's'},
            {'wait_ms': 100, 'expected': 1, 'tolerance': -1, 'source': 's'},
            {'wait_ms': 100, 'expected': 1, 'tolerance': 1, 'source': '   '},
            {'wait_ms': 100, 'expected': 1, 'tolerance': 1},
        ):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse(bad)
        base = Verdict(
            label='807733 behaviour_metric_delta stagger_payout', status='ok', measured=19285.0, expected=19285.0,
            low=19260.0, high=19310.0, explanation='base', scenario='s', spell_id=807733, rank_id=807733,
            check=BEHAVIOUR_METRIC_DELTA, build='a' * 64)
        mid_model = {'mid_label': '807733 stagger_payout mid_expiry', 'wait_ms': 4000, 'expected': 19094.0,
                     'tolerance': 15.0, 'source': '4 ticks'}
        self.assertEqual(verdict(base, FakeRun({mid_model['mid_label']: 19094.0}), mid_model).status, 'ok')
        early = verdict(base, FakeRun({mid_model['mid_label']: 19047.0}), mid_model)
        self.assertEqual(early.status, 'alert')
        self.assertIn('19047 at 4000 ms into the expiry wait', early.explanation)
        self.assertEqual(verdict(base, FakeRun({}), mid_model).status, 'unmeasured')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MidExpiryReadScenarioTests(unittest.TestCase):
    def test_splits_expiry_wait_and_rejects_out_of_range_wait(self):
        wh = load_class_file(15)
        entry = next(item for item in wh['behaviours']
                     if item.get('spell') == 807733 and item.get('label_suffix') == 'stagger_payout')
        with_mid = {**entry, 'mid_expiry_read': {'wait_ms': 4000, 'expected': 19094, 'tolerance': 15,
                                                 'source': '4 of 5 ticks paid'}}
        scenario, expectations = behaviour_scenario(wh, with_mid)
        run.validate(scenario)
        steps = scenario['steps']
        mid_label = expectations[0].model['mid_expiry_read']['mid_label']
        mid_idx = next(index for index, step in enumerate(steps) if step.get('label') == mid_label)
        self.assertEqual(steps[mid_idx - 1], {'action': 'wait', 'label': 'mid-expiry wait', 'ms': 4000})
        self.assertEqual(steps[mid_idx + 1], {'action': 'wait', 'label': 'let the triggering aura actually expire',
                                              'ms': entry['expiry_wait_ms'] - 4000})
        self.assertEqual(steps[mid_idx + 2]['label'], expectations[0].model['expired_label'])
        bad = {**entry, 'mid_expiry_read': {'wait_ms': entry['expiry_wait_ms'], 'expected': 19094, 'tolerance': 15,
                                            'source': 'equal to expiry'}}
        with self.assertRaises(ValueError):
            behaviour_scenario(wh, bad)


if __name__ == '__main__':
    unittest.main()
