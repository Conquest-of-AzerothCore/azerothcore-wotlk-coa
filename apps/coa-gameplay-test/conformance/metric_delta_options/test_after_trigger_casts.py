import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run

BEAM = 501117
SPLASH = 802710


def channel_entry(**changes) -> dict:
    return {'spell': BEAM, 'name': 'Mojo Beam (Splash Potion during the channel)', 'kind': 'metric_delta',
            'label_suffix': 'splash_in_channel', 'quote': 'you can instantly cast', 'trigger_spell': BEAM,
            'target': 'caster', 'measure_actor': 'caster', 'gate_timing': 'start', 'trigger_only_after': True,
            'learn': [92085, 801664, SPLASH], 'setup_casts': [801664], 'setup_target': 'caster',
            'setup_wait_ms': 1700, 'gate_spell': 92085, 'cast_power': 2000,
            'after_trigger_casts': [{'spell': SPLASH, 'target': 'caster', 'destination_unit': 'caster',
                                     'delay_ms': 1700}],
            'metric': 'spell_cast_count', 'fields': {'spell': SPLASH}, 'before_expected': 0, 'expected': 1,
            'wait_ms': 500, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterTriggerCastsTests(unittest.TestCase):
    def test_the_treatment_casts_at_a_unit_position_after_the_trigger(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), channel_entry())
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == SPLASH]
        self.assertEqual(len(casts), 1)
        cast = steps[casts[0]]
        self.assertEqual((cast['target'], cast['destination_unit']), ('caster', 'caster'))
        beam = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == BEAM)
        self.assertLess(beam, casts[0])
        between = steps[beam + 1:casts[0]]
        self.assertEqual(between[0], {'action': 'wait', 'label': f'before the cast of {SPLASH}', 'ms': 1700})
        self.assertIn({'action': 'reset_cooldown', 'actor': 'caster', 'spell': SPLASH}, between)
        self.assertIn({'action': 'set_aura', 'actor': 'caster', 'spell': 801702, 'stacks': 1}, between)

    def test_a_unit_target_cast_sends_no_destination(self):
        entry = channel_entry(after_trigger_casts=[{'spell': 801661, 'delay_ms': 1700}])
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        cast = next(step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 801661)
        self.assertNotIn('destination_unit', cast)

    def test_without_the_option_nothing_is_cast_after_the_trigger(self):
        entry = {key: value for key, value in channel_entry().items() if key != 'after_trigger_casts'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'cast' and step['spell'] == SPLASH for step in scenario['steps']))

    def test_refused_inputs(self):
        for raw in ([], [{'spell': SPLASH}], [{'spell': SPLASH, 'delay_ms': -1}],
                    [{'spell': SPLASH, 'delay_ms': 0, 'destination_unit': 'enemy'}],
                    [{'spell': SPLASH, 'delay_ms': 0, 'other': 1}],
                    [{'spell': SPLASH, 'delay_ms': 0, 'target': 'dummy'}],
                    [{'spell': SPLASH, 'delay_ms': 0, 'in_before': 1}],
                    [{'spell': SPLASH, 'delay_ms': 0, 'reset_cooldown': 'no'}]):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), channel_entry(after_trigger_casts=raw))

    def test_a_cast_in_both_phases_needs_a_cast_control_phase(self):
        entry = channel_entry(after_trigger_casts=[{'spell': 801661, 'delay_ms': 1700, 'in_before': True}])
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), entry)

    def test_a_control_cast_and_a_running_cooldown(self):
        juju = 802087
        entry = {'spell': 705844, 'name': 'Overflowing Juju (the next Bad Juju cooldown)', 'kind': 'metric_delta',
                 'label_suffix': 'next_cut_late', 'quote': 'reduced cooldown', 'trigger_spell': 500015,
                 'target': 'dummy', 'measure_actor': 'caster', 'gate_spell': 705844, 'cast_power': 1400,
                 'after_trigger_casts': [{'spell': juju, 'target': 'dummy', 'delay_ms': 3200, 'in_before': True},
                                         {'spell': juju, 'target': 'dummy', 'delay_ms': 8000, 'in_before': True,
                                          'reset_cooldown': False}],
                 'metric': 'spell_cast_count', 'fields': {'spell': juju}, 'before_expected': 1, 'expected': 3,
                 'wait_ms': 2800}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == juju]
        self.assertEqual(len(casts), 4)
        resets = [index for index, step in enumerate(steps)
                  if step['action'] == 'reset_cooldown' and step['spell'] == juju]
        for first, second in (casts[0:2], casts[2:4]):
            self.assertTrue(any(index < first for index in resets))
            self.assertFalse(any(first < index < second for index in resets))
        self.assertIn('its cooldown left running', scenario['contract'])


if __name__ == '__main__':
    unittest.main()
