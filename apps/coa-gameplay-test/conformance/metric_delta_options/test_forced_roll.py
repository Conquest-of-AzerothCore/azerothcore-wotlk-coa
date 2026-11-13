import unittest

from behaviours import FORCED_CHANCE_OWNER_AURA, behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, base_steps, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def caster_haste_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (caster haste after a landed proc)', 'kind': 'metric_delta',
            'label_suffix': 'caster_proc_haste',
            'quote': "to increase your and your Undead minion's haste by $301334s1% for $301334d.",
            'expected': 0.83333, 'before_expected': 1, 'tolerance': 0.0001, 'trigger_spell': 500237,
            'target': 'dummy', 'setup_casts': [500971], 'setup_target': 'caster', 'setup_wait_ms': 3000,
            'wait_ms': 1000, 'expire_ms': 500, 'metric': 'cast_speed_multiplier', 'fields': {},
            'forced_roll': 300235, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ForcedRollTests(unittest.TestCase):
    def test_the_roll_is_forced_after_the_settle_and_released_at_the_end(self):
        class_file = load_fixture_class_file(23)
        scenario, [expectation] = behaviour_scenario(class_file, caster_haste_entry())
        run.validate(scenario)
        steps = scenario['steps']
        mutant = steps[len(base_steps(class_file))]
        self.assertEqual((mutant['action'], mutant['spell'], mutant['percent']), ('spell_mod_mutant', 300235, 1000))
        self.assertEqual((steps[-2]['spell'], steps[-2]['stacks']), (FORCED_CHANCE_OWNER_AURA, 0))
        self.assertEqual(steps[-1]['label'], expectation.model['forced_roll']['released_label'])

    def test_without_the_option_nothing_is_forced(self):
        entry = {key: value for key, value in caster_haste_entry().items() if key != 'forced_roll'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertFalse(any(step['action'] == 'spell_mod_mutant' for step in scenario['steps']))
        self.assertNotIn('forced_roll', expectation.model)

    def test_a_forced_chance_entry_cannot_force_the_roll_again(self):
        forced = {'talent': 300235, 'aura': 301334, 'entry': 50073}
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), caster_haste_entry(forced_chance=forced))

    def test_the_landed_proc_passes_and_mutants_alert(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), caster_haste_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        released = expectation.model['forced_roll']['released_label']

        def judged(after_value: float, released_value: float) -> str:
            values = {before: 1.0, after: after_value, released: released_value}
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(0.833333, 0.0), 'ok')
        self.assertEqual(judged(1.0, 0.0), 'alert')
        self.assertEqual(judged(0.833333, 1.0), 'alert')
