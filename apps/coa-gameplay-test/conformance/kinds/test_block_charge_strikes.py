import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.block_charge_strikes import BLOCK_SPELL, block_charge_spec
from profile import DBC_DIR, load_class_file, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 680647, 'name': 'Paying The Tithe (blocks)', 'kind': 'block_charge_strikes',
         'label_suffix': 'bulwark_blocks', 'quote': 'and your Seraphic Bulwark now lasts for $s1 additional blocks.',
         'aura': 560095, 'effect': 0, 'shield': 231296, 'strike_spell': 2118233, 'cast_power': 1000}
NO_BLOCK_ENTRY = {'spell': 704660, 'name': 'No Mercy (extra Thick Pelt hit)', 'kind': 'block_charge_strikes',
                  'label_suffix': 'thick_pelt_hits',
                  'quote': 'Allows your Thick Pelt to affect an additional hit.',
                  'aura': 556233, 'effect': 0, 'require_block': False, 'strike_spell': 34580,
                  'striker_untriggered': True, 'striker_auras': [803393], 'cast_power': 0}


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

    def judged_no_block(self, lasted, landed_every_strike=True):
        _, [expectation] = behaviour_scenario(load_class_file(20), NO_BLOCK_ENTRY)
        values, total = {}, 0.0
        for arm in ('control', 'treatment'):
            for index, read in enumerate(expectation.model['reads'][arm]):
                if index:
                    total += 1.0 if landed_every_strike or index > 1 else 0.0
                values[read['aura']] = 1.0 if index < lasted[arm] else 0.0
                values[read['hits']] = total
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_require_block_false_skips_shield_zeroes_avoidance_and_reads_hits(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(20), NO_BLOCK_ENTRY)
        steps = run.validate(scenario)['steps']
        self.assertEqual(expectation.model['expected'], {'control': 1, 'treatment': 2})
        self.assertIs(expectation.model['require_block'], False)
        self.assertFalse(any(step['action'] == 'learn' and step.get('spell') == BLOCK_SPELL for step in steps))
        self.assertFalse(any(step['action'] == 'equip' and step.get('slot') == 16 for step in steps))
        avoidances = [step for step in steps if step['action'] == 'set_combat_avoidance']
        self.assertEqual([(step['block'], step['dodge'], step['parry']) for step in avoidances], [(0, 0, 0)] * 2)
        strikes = [step for step in steps if step['action'] == 'cast' and step['spell'] == 34580]
        self.assertEqual(len(strikes), 2 + 3)
        self.assertTrue(all(step.get('triggered') is False for step in strikes))
        self.assertTrue(any(step['action'] == 'set_aura' and step.get('target') == 'striker'
                            and step.get('spell') == 803393 for step in steps))
        reads = [step for step in steps if step['action'] == 'assert' and step['metric'] == 'spell_damage_count']
        self.assertTrue(reads)
        self.assertTrue(all('blocked' not in step for step in reads))
        self.assertIn('hits', scenario['contract'])

    def test_require_block_false_verdicts_and_mutants(self):
        ok = self.judged_no_block({'control': 1, 'treatment': 2})
        self.assertEqual((ok.status, ok.measured, ok.expected), ('ok', 1.0, 1.0))
        self.assertIn('hits lasted', ok.explanation)
        self.assertEqual(self.judged_no_block({'control': 1, 'treatment': 1}).status, 'alert')
        self.assertEqual(self.judged_no_block({'control': 1, 'treatment': 3}).status, 'alert')
        self.assertEqual(self.judged_no_block({'control': 1, 'treatment': 99}).status, 'alert')
        self.assertEqual(self.judged_no_block({'control': 1, 'treatment': 2}, landed_every_strike=False).status,
                         'unmeasured')

    def test_require_block_and_striker_option_validation(self):
        bad_cases = [
            {**ENTRY, 'require_block': 0},
            {**ENTRY, 'require_block': False},
            {**NO_BLOCK_ENTRY, 'require_block': True},
            {**NO_BLOCK_ENTRY, 'striker_untriggered': 1},
            {**NO_BLOCK_ENTRY, 'striker_auras': [803393, 803393]},
            {**NO_BLOCK_ENTRY, 'striker_auras': [0]},
            {**NO_BLOCK_ENTRY, 'cast_power': -1},
        ]
        for raw in bad_cases:
            with self.subTest(raw=raw), self.assertRaisesRegex(ValueError, 'block_charge_strikes'):
                block_charge_spec(raw)


if __name__ == '__main__':
    unittest.main()
