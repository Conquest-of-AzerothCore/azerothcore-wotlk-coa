import unittest

from behaviours import behaviour_scenario
from metric_delta_options import post_trigger_casts
from profile import DBC_DIR, load_class_file
import run

ENTRY = {
    'spell': 680630, 'name': 'Pendant of the Sun (post casts)', 'kind': 'metric_delta', 'variant': 'post_casts',
    'label_suffix': 'post_casts', 'quote': 'refreshing the duration and all charges of Dawn.',
    'trigger_spell': 680630, 'target': 'caster', 'cast_in_before': False, 'setup_casts': [500143],
    'setup_target': 'caster', 'setup_wait_ms': 2600, 'setup_in_before': True, 'cast_power': 1363,
    'caster_health_pct': 50, 'phase_auras': [[807440, 1, 'caster', 'caster']], 'metric': 'aura',
    'fields': {'spell': 807440}, 'before_expected': 1, 'expected': 1, 'wait_ms': 500, 'expire_ms': 500}
OPTION = {'spell': 500143, 'count': 3, 'health_pct': 50}


class ParseTests(unittest.TestCase):
    def test_a_valid_option_parses_with_the_global_cooldown_default(self):
        value = post_trigger_casts.parse(OPTION)
        self.assertEqual((value.spell, value.count, value.gap_ms, value.health_pct), (500143, 3, 1600, 50))

    def test_bad_options_are_refused(self):
        for raw in ({}, {'spell': 1}, {'spell': 1, 'count': 0}, {'spell': 1, 'count': 21},
                    {'spell': 1, 'count': 2, 'gap_ms': 1000}, {'spell': 1, 'count': 2, 'health_pct': 100},
                    {'spell': 1, 'count': True}, {'spell': 1, 'count': 2, 'other': 1}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                post_trigger_casts.parse(raw)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScenarioTests(unittest.TestCase):
    def test_the_casts_follow_the_trigger_cast_with_health_and_cooldown_resets(self):
        scenario, _ = behaviour_scenario(load_class_file(27), {**ENTRY, 'post_trigger_casts': OPTION})
        run.validate(scenario)
        steps = scenario['steps']
        trigger = next(index for index, step in enumerate(steps) if step.get('action') == 'cast'
                       and step.get('spell') == 680630)
        casts = [step for step in steps[trigger + 1:] if step.get('action') == 'cast' and step.get('spell') == 500143]
        self.assertEqual(len(casts), 3)
        self.assertEqual(steps[trigger + 1]['action'], 'set_health')

    def test_without_the_option_no_post_casts_are_added(self):
        scenario, _ = behaviour_scenario(load_class_file(27), ENTRY)
        self.assertFalse(any(step.get('label', '').startswith('post cast') for step in scenario['steps']))


if __name__ == '__main__':
    unittest.main()
