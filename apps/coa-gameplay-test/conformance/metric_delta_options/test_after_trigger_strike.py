import unittest

from behaviours import BEHAVIOUR_METRIC_DELTA, STRIKER, behaviour_scenario
from compare import Verdict
from metric_delta_options.after_trigger_strike import parse, verdict
from profile import CASTER, DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun


def summon_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 805049 and entry.get('label_suffix') == 'summon')
    return {**entry, 'cast_in_before': True, 'metric': 'owned_creature_health', 'fields': {'entry': 500482},
            'after_trigger_strike': {'spell': 41394, 'delay_ms': 1500}, **changes}


def strike_indexes(steps: list[dict]) -> list[int]:
    return [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['actor'] == STRIKER]


class AfterTriggerStrikeUnitTests(unittest.TestCase):
    def test_before_aura_validation_and_verdict(self):
        self.assertEqual(parse({'spell': 41394, 'delay_ms': 2500, 'before_aura': 802281}).before_aura, 802281)
        for bad in (0, -1, True, '802281'):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse({'spell': 41394, 'delay_ms': 2500, 'before_aura': bad})
        base = Verdict(
            label='802281 behaviour_metric_delta receive_damage_cancels', status='ok', measured=0.0, expected=0.0,
            low=0.0, high=0.0, explanation='base', scenario='s', spell_id=802281, rank_id=802281,
            check=BEHAVIOUR_METRIC_DELTA, build='a' * 64)
        strike_model = {'before_aura': 802281, 'before_aura_label': '802281 after_trigger_strike before_aura 802281'}
        present = verdict(base, FakeRun({strike_model['before_aura_label']: 1}), strike_model)
        self.assertEqual(present.status, 'ok')
        self.assertIn('held aura 802281 before the strike', present.explanation)
        absent = verdict(base, FakeRun({strike_model['before_aura_label']: 0}), strike_model)
        self.assertEqual(absent.status, 'alert')
        self.assertIn('did not hold aura 802281 before the strike', absent.explanation)
        missing = verdict(base, FakeRun({}), strike_model)
        self.assertEqual(missing.status, 'unmeasured')
        self.assertIn('was not measured', missing.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterTriggerStrikeTests(unittest.TestCase):
    def test_the_striker_hits_the_caster_after_the_treatment_cast_only(self):
        scenario, expectations = behaviour_scenario(load_fixture_class_file(23), summon_entry())
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
        self.assertNotIn('after_trigger_strike', expectations[0].model)

    def test_before_aura_reads_caster_aura_after_delay_and_before_strike(self):
        entry = summon_entry(after_trigger_strike={'spell': 41394, 'delay_ms': 2500, 'count': 1, 'wait_ms': 500,
                                                   'before_aura': 805049})
        scenario, expectations = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        steps = scenario['steps']
        strikes = strike_indexes(steps)
        self.assertEqual(len(strikes), 1)
        self.assertEqual(steps[strikes[0] - 2], {'action': 'wait', 'label': 'before the strike', 'ms': 2500})
        read = steps[strikes[0] - 1]
        self.assertEqual(read['action'], 'assert')
        self.assertEqual(read['actor'], CASTER)
        self.assertEqual(read['metric'], 'aura')
        self.assertEqual(read['spell'], 805049)
        self.assertEqual(read['caster'], CASTER)
        self.assertEqual(expectations[0].model['after_trigger_strike'],
                         {'before_aura': 805049, 'before_aura_label': read['label']})

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
