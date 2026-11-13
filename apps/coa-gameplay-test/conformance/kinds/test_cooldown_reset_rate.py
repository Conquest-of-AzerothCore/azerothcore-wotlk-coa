import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 561353, 'name': 'Unholy Runes (Corpse Explosion reset rate)', 'kind': 'cooldown_reset_rate',
         'label_suffix': 'reset_rate', 'quote': 'a $h% chance to reset the cooldown of Corpse Explosion.',
         'talent': 561353, 'trigger_spell': 500237, 'reset_spell': 533236, 'chance_pct': 5, 'casts': 3300,
         'control_casts': 200, 'cast_wait_ms': 50}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownResetRateTests(unittest.TestCase):
    def judged(self, resets: float, control_resets: float = 0.0, hits: float = 3300.0):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        reads = expectation.model['reads']
        values = {reads['control hits']: 200.0, reads['control resets']: control_resets,
                  reads['treatment hits']: 200.0 + hits, reads['treatment resets']: control_resets + resets}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_resets_are_clear_cooldown_packets_of_the_reset_spell_after_the_learn(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        steps = scenario['steps']
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 561353)
        packets = [index for index, step in enumerate(steps) if step.get('metric') == 'server_packets']
        self.assertEqual([steps[index]['row'] for index in packets], [533236, 533236])
        self.assertEqual({steps[index]['opcode'] for index in packets}, {0x1DE})
        self.assertLess(packets[0], learn)
        self.assertLess(learn, packets[1])

    def test_a_rate_inside_the_band_passes_and_far_off_it_alerts(self):
        self.assertEqual(self.judged(153.0).status, 'ok')
        self.assertEqual(self.judged(660.0).status, 'alert')

    def test_a_control_reset_alerts(self):
        self.assertEqual(self.judged(153.0, control_resets=1.0).status, 'alert')

    def test_fewer_casts_than_the_band_needs_are_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'casts': 500})
