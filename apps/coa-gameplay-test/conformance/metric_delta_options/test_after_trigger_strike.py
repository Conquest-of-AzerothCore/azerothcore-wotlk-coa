import unittest

from behaviours import STRIKER, behaviour_scenario
from profile import CASTER, DBC_DIR, load_fixture_class_file
import run


def summon_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 805049 and entry.get('label_suffix') == 'summon')
    return {**entry, 'cast_in_before': True, 'metric': 'owned_creature_health', 'fields': {'entry': 500482},
            'after_trigger_strike': {'spell': 41394, 'delay_ms': 1500}, **changes}


def strike_indexes(steps: list[dict]) -> list[int]:
    return [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['actor'] == STRIKER]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterTriggerStrikeTests(unittest.TestCase):
    def test_the_striker_hits_the_caster_after_the_treatment_cast_only(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), summon_entry())
        run.validate(scenario)
        steps = scenario['steps']
        strikes = strike_indexes(steps)
        triggers = [index for index, step in enumerate(steps)
                    if step['action'] == 'cast' and step['actor'] == CASTER and step['spell'] == 805049]
        before = next(index for index, step in enumerate(steps) if step.get('label', '').endswith(' before'))
        self.assertEqual(len(strikes), 1)
        self.assertEqual(steps[strikes[0]]['spell'], 41394)
        self.assertEqual(steps[strikes[0]]['target'], CASTER)
        self.assertLess(before, triggers[-1])
        self.assertLess(triggers[-1], strikes[0])
        self.assertEqual(steps[strikes[0] - 1], {'action': 'wait', 'label': 'before the strike', 'ms': 1500})
        self.assertIn(STRIKER, [creature['id'] for creature in scenario['creatures']])

    def test_a_count_repeats_the_strike_with_its_wait(self):
        entry = summon_entry(after_trigger_strike={'spell': 41394, 'delay_ms': 0, 'count': 3, 'wait_ms': 200})
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        steps = scenario['steps']
        strikes = strike_indexes(steps)
        self.assertEqual(len(strikes), 3)
        self.assertTrue(all(steps[index + 1] == {'action': 'wait', 'label': 'strike', 'ms': 200}
                            for index in strikes))

    def test_without_the_option_nobody_strikes(self):
        entry = {key: value for key, value in summon_entry().items() if key != 'after_trigger_strike'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(strike_indexes(scenario['steps']), [])
        self.assertNotIn(STRIKER, [creature['id'] for creature in scenario.get('creatures', [])])

    def test_one_striker_only_and_a_complete_option(self):
        strike = {'spell': 41394, 'health': 100000, 'max_health': 100000}
        for entry in (summon_entry(strike=strike), summon_entry(after_trigger_strike={'spell': 41394}),
                      summon_entry(after_trigger_strike={'spell': 41394, 'delay_ms': 0, 'count': 0}),
                      summon_entry(after_trigger_strike={'spell': 41394, 'delay_ms': 0, 'repeats': 2})):
            with self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), entry)


if __name__ == '__main__':
    unittest.main()
