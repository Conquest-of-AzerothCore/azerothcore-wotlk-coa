import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def entry(**changes) -> dict:
    found = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'player_spell')
    return {**found, **changes}


def power_steps(scenario) -> list[dict]:
    return [step for step in scenario['steps'] if step['action'] == 'set_power']


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class HoldPowerDuringWaitTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), entry(**changes))[0]

    def test_power_is_refilled_every_interval_after_the_trigger_and_the_contract_says_so(self):
        plain = self.build()
        held = self.build(hold_power_during_wait={'power': 0, 'every_ms': 500, 'count': 4})
        run.validate(held)
        self.assertEqual(len(power_steps(held)) - len(power_steps(plain)), 8)
        casts = [index for index, step in enumerate(held['steps']) if step['action'] == 'cast'
                 and step.get('spell') == entry()['trigger_spell']]
        self.assertEqual(len(casts), 2)
        for index in casts:
            following = held['steps'][index + 1:index + 9]
            self.assertEqual([step['action'] for step in following], ['wait', 'set_power'] * 4)
            self.assertEqual({step['ms'] for step in following if step['action'] == 'wait'}, {500})
            self.assertEqual({(step['power'], step['value']) for step in following if step['action'] == 'set_power'},
                             {(0, entry()['cast_power'])})
        self.assertIn('every 500 ms, 4 times', held['contract'])
        self.assertNotIn('every 500 ms', plain['contract'])

    def test_absent_leaves_the_scenario_unchanged(self):
        self.assertEqual(self.build(), self.build(hold_power_during_wait=None))

    def test_the_option_is_refused_for_a_resource_claim_or_without_its_inputs(self):
        for changes in ({'quote': 'costs 30% less mana'}, {'metric': 'power', 'fields': {'power': 0}},
                        {'cast_power': None}, {'hold_power_during_wait': {}},
                        {'hold_power_during_wait': {'power': 0, 'every_ms': 50, 'count': 4}},
                        {'hold_power_during_wait': {'power': 0, 'every_ms': 500, 'count': 0}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23),
                                   entry(**{'hold_power_during_wait': {'power': 0, 'every_ms': 500, 'count': 4},
                                            **changes}))


if __name__ == '__main__':
    unittest.main()
