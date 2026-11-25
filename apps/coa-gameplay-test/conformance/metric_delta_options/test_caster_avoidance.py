import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def shield_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'shield_hits'
                 and (entry.get('strike') or {}).get('spell') == 11976)
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CasterAvoidanceTests(unittest.TestCase):
    def test_the_caster_avoidance_is_set_right_before_every_strike(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     shield_entry(caster_avoidance={'parry': 100}))
        run.validate(scenario)
        steps = scenario['steps']
        strikes = [index for index, step in enumerate(steps) if step['action'] == 'cast'
                   and step['actor'] == 'striker']
        self.assertEqual(len(strikes), 16)
        for index in strikes:
            self.assertEqual(steps[index - 1], {'action': 'set_combat_avoidance', 'actor': 'caster', 'dodge': 0.0,
                                                'parry': 100.0})
        self.assertEqual(sum(step['action'] == 'set_combat_avoidance' for step in steps), 16)
        self.assertEqual(expectation.model['caster_avoidance'], {'dodge': 0.0, 'parry': 100.0})
        self.assertIn('0% and 100%', scenario['contract'])

    def test_without_the_option_the_avoidance_is_left_alone(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), shield_entry())
        self.assertFalse(any(step['action'] == 'set_combat_avoidance' for step in scenario['steps']))
        self.assertNotIn('caster_avoidance', expectation.model)

    def test_an_avoidance_needs_a_strike_and_percents(self):
        for changes in ({'caster_avoidance': {'parry': 100}, 'strike': None}, {'caster_avoidance': {}},
                        {'caster_avoidance': {'parry': 101}}, {'caster_avoidance': {'block': 50}}, {'caster_avoidance': {'block': 101}},
                        {'caster_avoidance': {'dodge': True}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), shield_entry(**changes))

    def block_values(self, block: float, blocked: tuple[int, int], unblocked: tuple[int, int]):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     shield_entry(caster_avoidance={'block': block}))
        model = expectation.model
        values = {model['before_label']: 0.0, model['after_label']: 1.0}
        for phase, done, hit in zip(('before', 'after'), blocked, unblocked):
            values[model['caster_avoidance']['guards'][phase]['blocked']] = float(done)
            values[model['caster_avoidance']['guards'][phase]['unblocked']] = float(hit)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_block_is_set_before_every_strike_and_guarded_after_each_reading(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23),
                                                     shield_entry(caster_avoidance={'block': 100}))
        run.validate(scenario)
        fixtures = [step for step in scenario['steps'] if step['action'] == 'set_combat_avoidance']
        self.assertEqual(len(fixtures), 16)
        self.assertTrue(all(step['block'] == 100.0 for step in fixtures))
        guards = expectation.model['caster_avoidance']['guards']
        self.assertEqual((guards['before']['strikes'], guards['after']['strikes']), (8, 16))
        reads = [step for step in scenario['steps'] if 'caster_avoidance' in step.get('label', '')]
        self.assertEqual([step['blocked'] for step in reads], [True, False, True, False])
        self.assertIn('block chance is set to 100%', scenario['contract'])

    def test_every_strike_blocked_keeps_the_reading_verdict(self):
        self.assertEqual(self.block_values(100, (8, 16), (0, 0)).status, 'ok')

    def test_block_100_with_an_unblocked_strike_is_unmeasured(self):
        self.assertEqual(self.block_values(100, (8, 15), (0, 1)).status, 'unmeasured')

    def test_block_0_with_a_blocked_strike_is_unmeasured(self):
        self.assertEqual(self.block_values(0, (0, 1), (8, 15)).status, 'unmeasured')
        self.assertEqual(self.block_values(0, (0, 0), (8, 16)).status, 'ok')

    def test_a_strike_that_did_not_land_is_unmeasured(self):
        self.assertEqual(self.block_values(100, (8, 15), (0, 0)).status, 'unmeasured')

    def test_a_block_between_the_extremes_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), shield_entry(caster_avoidance={'block': 30}))


if __name__ == '__main__':
    unittest.main()
