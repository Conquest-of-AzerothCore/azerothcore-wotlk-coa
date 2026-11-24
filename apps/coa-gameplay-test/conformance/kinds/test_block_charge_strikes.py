import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 680647, 'name': 'Paying The Tithe (blocks)', 'kind': 'block_charge_strikes',
         'label_suffix': 'bulwark_blocks', 'quote': 'and your Seraphic Bulwark now lasts for $s1 additional blocks.',
         'aura': 560095, 'effect': 0, 'shield': 231296, 'strike_spell': 2118233, 'cast_power': 1000}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BlockChargeStrikesTests(unittest.TestCase):
    def generated(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        return scenario, expectation

    def judged(self, lasted, blocked_every_strike=True):
        _, expectation = self.generated()
        values, total = {}, 0.0
        for arm in ('control', 'treatment'):
            for index, read in enumerate(expectation.model['reads'][arm]):
                if index:
                    total += 1.0 if blocked_every_strike or index > 1 else 0.0
                values[read['aura']] = 1.0 if index < lasted[arm] else 0.0
                values[read['blocked']] = total
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def test_the_scenario_forces_blocks_and_strikes_one_past_the_expected_count(self):
        scenario, expectation = self.generated()
        run.validate(scenario)
        self.assertEqual(expectation.model['expected'], {'control': 5, 'treatment': 7})
        fixtures = [step for step in scenario['steps'] if step['action'] == 'set_combat_avoidance']
        self.assertEqual([(step['block'], step['dodge'], step['parry']) for step in fixtures], [(100, 0, 0)] * 2)
        strikes = [step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 2118233]
        self.assertEqual(len(strikes), 6 + 8)

    def test_the_stated_block_counts_are_ok(self):
        self.assertEqual(self.judged({'control': 5, 'treatment': 7}), 'ok')

    def test_mutant_without_the_extra_blocks_alerts(self):
        self.assertEqual(self.judged({'control': 5, 'treatment': 5}), 'alert')
        self.assertEqual(self.judged({'control': 5, 'treatment': 8}), 'alert')

    def test_an_aura_that_never_ends_alerts(self):
        self.assertEqual(self.judged({'control': 5, 'treatment': 99}), 'alert')

    def test_an_unblocked_strike_is_unmeasured(self):
        self.assertEqual(self.judged({'control': 5, 'treatment': 7}, blocked_every_strike=False), 'unmeasured')

    def test_a_missing_read_is_unmeasured(self):
        _, expectation = self.generated()
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun({}), expectation).status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
