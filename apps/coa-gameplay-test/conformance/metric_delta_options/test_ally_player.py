import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.ratio_to_metric import base_label
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

BREW = 503750


def brew_entry(**changes) -> dict:
    return {'spell': BREW, 'name': 'Rage Brew (a warrior ally regains half its Rage)', 'kind': 'metric_delta',
            'label_suffix': 'brew_rage', 'quote': 'regenerating $s1% of their maximum Rage', 'trigger_spell': BREW,
            'target': 'ally', 'measure_actor': 'ally', 'gate_timing': 'start', 'trigger_only_after': True,
            'cast_power': 1400, 'ally_player': {'class': 1, 'power': 1},
            'ratio_to_metric': {'metric': 'max_power', 'fields': {'power': 1}},
            'metric': 'power', 'fields': {'power': 1}, 'before_expected': 0, 'expected': 0.5, 'wait_ms': 1000,
            **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AllyPlayerTests(unittest.TestCase):
    def test_the_ally_of_the_class_is_emptied_cast_at_and_read(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), brew_entry())
        run.validate(scenario)
        ally = next(player for player in scenario['players'] if player['id'] == 'ally')
        self.assertEqual((ally['class'], ally['allow_regeneration']), (1, False))
        steps = scenario['steps']
        group = steps.index({'action': 'group', 'actor': 'caster', 'target': 'ally'})
        empties = [index for index, step in enumerate(steps)
                   if step == {'action': 'set_power', 'actor': 'ally', 'power': 1, 'value': 0}]
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == BREW)
        self.assertEqual(steps[cast]['target'], 'ally')
        self.assertEqual(len(empties), 2)
        self.assertLess(group, empties[0])
        self.assertLess(empties[1], cast)
        before, after = expectation.model['before_label'], expectation.model['after_label']
        reads = [step for step in steps if step.get('label') in (before, after)]
        self.assertEqual({(step['actor'], step['metric']) for step in reads}, {('ally', 'power')})
        found = judge_behaviour(base_verdict(expectation),
                                FakeRun({before: 0.0, base_label(before): 1000.0, after: 500.0,
                                         base_label(after): 1000.0}), expectation)
        self.assertEqual(found.status, 'ok')
        found = judge_behaviour(base_verdict(expectation),
                                FakeRun({before: 0.0, base_label(before): 1000.0, after: 0.0,
                                         base_label(after): 1000.0}), expectation)
        self.assertEqual(found.status, 'alert')

    def test_without_the_option_no_ally_is_added(self):
        entry = {key: value for key, value in brew_entry(target='caster', measure_actor='caster').items()
                 if key != 'ally_player'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual([player['id'] for player in scenario['players']], ['caster'])

    def test_refused_inputs(self):
        for changes in ({'ally_player': {'class': 1}}, {'ally_player': {'class': 0, 'power': 1}},
                        {'ally_player': {'class': 1, 'power': 7}}, {'target': 'caster'},
                        {'measure_actor': 'caster'}, {'setup_casts': [BREW]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), brew_entry(**changes))


if __name__ == '__main__':
    unittest.main()
