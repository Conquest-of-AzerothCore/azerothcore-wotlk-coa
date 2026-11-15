import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import CASTER, DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


class StrikeBurstsTests(unittest.TestCase):
    def entry(self, spell: int, kind: str, suffix: str | None = None) -> dict:
        return next(entry for entry in load_fixture_class_file(23)['behaviours']
                    if entry['spell'] == spell and entry['kind'] == kind
                    and (suffix is None or entry.get('label_suffix') == suffix))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_strike_bursts_need_the_range_and_both_ends(self):
        _, expectations = behaviour_scenario(load_fixture_class_file(23), self.entry(500969, 'strike_bursts'))
        above = next(expectation for expectation in expectations if expectation.label.endswith('bursts_above'))

        def run_of(counts):
            values = {}
            for (before, after), count in zip(above.model['reads'], counts):
                values[before], values[after] = 10.0, 10.0 + count
            return FakeRun(values)

        def status(counts):
            return judge_behaviour(base_verdict(above), run_of(counts), above).status

        cycles = len(above.model['reads'])
        self.assertEqual(status([2, 3, 4, 5] * (cycles // 4)), 'ok')
        self.assertEqual(status([2] * cycles), 'alert')
        self.assertEqual(status([2, 5] * (cycles // 2 - 1) + [6, 5]), 'alert')
        self.assertEqual(status([3, 4] * (cycles // 2)), 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_strike_burst_arms_lower_the_health(self):
        entry = self.entry(500969, 'strike_bursts')
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        self.assertEqual([step['pct'] for step in scenario['steps'] if step['action'] == 'set_health_pct'], [37, 33])
        self.assertEqual(scenario['creatures'][0]['distance'], 6)
        raised = {'spell': 500969, 'action': 'cast', 'actor': CASTER, 'target': CASTER}
        first_raise = next(index for index, step in enumerate(scenario['steps']) if step == raised)
        first_command = next(index for index, step in enumerate(scenario['steps'])
                             if step.get('action') == 'cast' and step.get('spell') == 504318)
        self.assertLess(first_command, first_raise)
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**entry, 'arms': list(reversed(entry['arms']))})
