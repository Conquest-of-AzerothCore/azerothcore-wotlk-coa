from pathlib import Path
import sys
import unittest

from behaviours import behaviour_scenario
from profile import CASTER, DBC_DIR, load_fixture_class_file

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run


def libram_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(19)['behaviours']
                 if entry['kind'] == 'cost_gate' and entry.get('label_suffix') == 'libram')
    return {**entry, **changes}


def attempts(steps: list[dict], spell: int) -> list[int]:
    return [index for index, step in enumerate(steps)
            if step['action'] == 'assert' and step.get('metric') == 'cast_failure' and step.get('spell') == spell]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CostGateRelocateBeforeAttemptTests(unittest.TestCase):
    def test_the_caster_moves_right_before_each_judged_attempt_only(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(19),
                                         libram_entry(relocate_before_attempt={'dx': -18}))
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        gated = libram_entry()['gated_spell']
        reads = attempts(steps, gated)
        self.assertGreaterEqual(len(reads), 2)
        for read in reads:
            cast = max(index for index in range(read) if steps[index]['action'] == 'cast'
                       and steps[index]['spell'] == gated)
            self.assertEqual(steps[cast - 1], {'action': 'relocate', 'actor': CASTER, 'dx': -18.0})
        self.assertEqual(sum(step['action'] == 'relocate' for step in steps), len(reads))
        self.assertIn('moved -18 yd along x', scenario['contract'])

    def test_without_the_option_nothing_moves_and_the_readings_match(self):
        plain, plain_expectations = behaviour_scenario(load_fixture_class_file(19), libram_entry())
        moved, moved_expectations = behaviour_scenario(load_fixture_class_file(19),
                                                       libram_entry(relocate_before_attempt={'dx': -18}))
        self.assertFalse(any(step['action'] == 'relocate' for step in plain['steps']))
        self.assertNotIn('along x', plain['contract'])
        self.assertEqual(plain_expectations, moved_expectations)
        self.assertEqual([step for step in moved['steps'] if step['action'] != 'relocate'], plain['steps'])

    def test_a_shift_is_nonzero_and_bounded(self):
        for raw in ({'dx': 0}, {'dx': 21}, {'dx': -20.5}, {'dx': True}, {'dy': 3}, -12):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), libram_entry(relocate_before_attempt=raw))


if __name__ == '__main__':
    unittest.main()
