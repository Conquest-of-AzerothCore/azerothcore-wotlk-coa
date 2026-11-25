from pathlib import Path
import sys
import unittest

from behaviours import behaviour_scenario, fixed_target_count_spec
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run
from values import Expectation

FLOURISH = 805365
FLAMES_DAMAGE = 802850
SWING_MS = 2000


class SeededRun:
    def __init__(self, values):
        self.values = values
        self.key = 'seeded'
        self.status = 'completed'
        self.message = ''
        self.steps = []
        self.max_step_ms = None
        self.cast_failures = {}


def base_verdict(expectation: Expectation) -> Verdict:
    return Verdict(expectation.label, 'alert', None, None, None, None, '', 'seeded-key', expectation.spell_id,
                   expectation.rank_id, expectation.check)


def flourish_entry(**changes) -> dict:
    return {'spell': FLOURISH, 'name': 'Flourish (Flames of Sin cleave on a real swing)', 'kind': 'fixed_count',
            'label_suffix': 'swing_cleave_seeded', 'quote': 'to cleave up to $s3 additional enemies', 'expected': 3,
            'setup_casts': [[FLOURISH, 'caster']], 'radius': 10.0, 'cluster_yd': 4.0,
            'primary_distance_reads': True, 'cast_spell': FLAMES_DAMAGE, 'target_rank': FLAMES_DAMAGE,
            'repeats': 1, 'swing_ms': SWING_MS, 'radius_reason': 'seeded', **changes}


def swing_readings(model: dict, extras_hit: int, primary_hit: bool = True, far_hit: bool = False) -> dict:
    values = {label: 0.0 for label in model['per_cast']['start']}
    [cast] = model['per_cast']['casts']
    values.update({label: float(index <= extras_hit and (index > 0 or primary_hit))
                   for index, label in enumerate(cast)})
    values.update({label: float(index < extras_hit) for index, label in enumerate(model['dummy_labels'])})
    values.update({label: 0.5 for label in model['primary_distances']})
    values[model['far_label']] = float(far_hit)
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FixedCountSwingTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(19), flourish_entry(**changes))

    def status(self, values: dict, **changes) -> str:
        _, [expectation] = self.built(**changes)
        return judge_behaviour(base_verdict(expectation), SeededRun(values), expectation).status

    def test_each_cast_is_an_auto_attack_window_on_the_primary(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        self.assertFalse(any(step['action'] == 'cast' and step.get('spell') == FLAMES_DAMAGE for step in steps))
        start = next(index for index, step in enumerate(steps) if step['action'] == 'attack')
        self.assertEqual([step['action'] for step in steps[start:start + 3]], ['attack', 'wait', 'stop_attack'])
        self.assertEqual((steps[start]['target'], steps[start + 1]['ms']), ('primary', SWING_MS))
        self.assertLess(max(index for index, step in enumerate(steps) if step.get('spell') == FLOURISH
                            and step['action'] == 'cast'), start)
        self.assertIn('Swing route', scenario['contract'])
        self.assertGreaterEqual(scenario['timeout_ms'], SWING_MS)
        self.assertEqual(len(expectation.model['per_cast']['casts']), 1)

    def test_without_swing_ms_the_entry_casts_as_before(self):
        entry = flourish_entry()
        del entry['swing_ms']
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), entry)
        self.assertFalse(any(step['action'] == 'attack' for step in scenario['steps']))
        self.assertTrue(any(step['action'] == 'cast' and step['spell'] == FLAMES_DAMAGE for step in scenario['steps']))
        self.assertNotIn('Swing route', scenario['contract'])
        _, [swung] = self.built()
        self.assertEqual(swung.model, expectation.model)
        self.assertEqual(fixed_target_count_spec(entry).swing_ms, 0)

    def test_seeded_three_extras_on_a_landed_swing_is_ok(self):
        _, [expectation] = self.built()
        self.assertEqual(self.status(swing_readings(expectation.model, 3)), 'ok')

    def test_mutant_a_cap_of_four_alerts(self):
        _, [expectation] = self.built()
        self.assertEqual(self.status(swing_readings(expectation.model, 4)), 'alert')

    def test_mutant_no_cleave_or_a_far_hit_alerts(self):
        _, [expectation] = self.built()
        self.assertEqual(self.status(swing_readings(expectation.model, 0)), 'alert')
        self.assertEqual(self.status(swing_readings(expectation.model, 3, far_hit=True)), 'alert')

    def test_a_window_without_a_primary_hit_is_unmeasured(self):
        _, [expectation] = self.built()
        self.assertEqual(self.status(swing_readings(expectation.model, 0, primary_hit=False)), 'unmeasured')

    def test_refuses_a_negative_window_or_a_cast_at_the_caster(self):
        for changes in ({'swing_ms': -1}, {'cast_target': 'caster', 'cluster_yd': None,
                                           'primary_distance_reads': False}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
