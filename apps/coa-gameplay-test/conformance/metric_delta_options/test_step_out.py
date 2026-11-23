import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def veil_entry(side: str = 'inside', **changes) -> dict:
    return {'spell': 802100, 'name': 'Veil of Darkness (the pulse inside the 40 yd range)', 'kind': 'metric_delta',
            'label_suffix': f'range_{side}', 'quote': 'If you are within $806473r yds of the target',
            'trigger_spell': 802100, 'target': 'dummy', 'measure_actor': 'caster', 'dummy_distance': 38,
            'cast_power': 1400, 'gate_timing': 'start', 'trigger_only_after': True, 'metric': 'spell_damage_count',
            'fields': {'spell': 806473, 'target': 'dummy'}, 'before_expected': 0,
            'expected': 1 if side == 'inside' else 0, 'wait_ms': 250, 'expire_ms': 500,
            'step_out': {'dx': -4.275 if side == 'inside' else -5.275, 'after_ms': 750, 'hold_ms': 1200,
                         'radius': 40, 'side': side}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class StepOutTests(unittest.TestCase):
    def judged(self, side: str, after: float, distance: float) -> str:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), veil_entry(side))
        reads = {expectation.model['before_label']: 0.0, expectation.model['after_label']: after}
        for moment in expectation.model['step_out']['labels'].values():
            reads.update({moment['distance']: distance, moment['caster z']: 50.0, moment['target z']: 50.0,
                          moment['caster reach']: 1.5, moment['target reach']: 1.275})
        return judge_behaviour(base_verdict(expectation), FakeRun(reads), expectation).status

    def test_the_caster_steps_out_and_back_after_the_trigger(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), veil_entry())
        run.validate(scenario)
        moves = [step['dx'] for step in scenario['steps'] if step['action'] == 'relocate']
        self.assertEqual(moves, [-4.275, 4.275])

    def test_a_held_layout_is_judged_by_the_reading(self):
        self.assertEqual(self.judged('inside', 1, 42.275), 'ok')
        self.assertEqual(self.judged('inside', 0, 42.275), 'alert')
        self.assertEqual(self.judged('beyond', 0, 43.275), 'ok')
        self.assertEqual(self.judged('beyond', 1, 43.275), 'alert')

    def test_a_caster_off_its_side_is_unmeasured(self):
        self.assertEqual(self.judged('inside', 1, 42.7), 'unmeasured')
        self.assertEqual(self.judged('beyond', 0, 42.9), 'unmeasured')

    def test_refused_inputs(self):
        for raw in ({'dx': 0, 'after_ms': 750, 'hold_ms': 1200, 'radius': 40, 'side': 'inside'},
                    {'dx': -25, 'after_ms': 750, 'hold_ms': 1200, 'radius': 40, 'side': 'inside'},
                    {'dx': -4, 'after_ms': 750, 'hold_ms': 1200, 'radius': 40, 'side': 'edge'}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), veil_entry(step_out=raw))


if __name__ == '__main__':
    unittest.main()
