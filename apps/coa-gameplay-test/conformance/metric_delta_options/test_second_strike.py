import unittest

from behaviours import STRIKER, behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

SEEDED_ENTRY = {
    'spell': 704941, 'kind': 'metric_delta', 'trigger_spell': 805301, 'target': 'caster', 'before_expected': 0,
    'wait_ms': 500, 'expire_ms': 2000,
    'strike': {'spell': 2118233, 'health': 50000, 'max_health': 100000, 'count': 1, 'wait_ms': 300},
    'caster_avoidance': {'parry': 100}, 'name': 'seeded next attack', 'variant': 'seeded', 'label_suffix': 'seeded',
    'quote': 'and increases your chance to parry the next attack by $707843s1%.', 'metric': 'aura_amount',
    'fields': {'spell': 707843, 'effect': 0}, 'expected': 0,
    'second_strike': {'spell': 23583, 'present': 30}}


def entry(**changes) -> dict:
    return {key: value for key, value in {**SEEDED_ENTRY, **changes}.items() if value is not None}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SecondStrikeTests(unittest.TestCase):
    def test_the_second_strike_follows_each_trigger_cast_and_is_never_parried_by_the_fixture(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), entry())
        run.validate(scenario)
        steps = scenario['steps']
        triggers = [index for index, step in enumerate(steps) if step['action'] == 'cast'
                    and step['actor'] == 'caster' and step['spell'] == 805301]
        seconds = [index for index, step in enumerate(steps) if step['action'] == 'cast'
                   and step['actor'] == STRIKER and step['spell'] == 23583]
        self.assertEqual(len(triggers), 2)
        self.assertEqual(len(seconds), 2)
        for index in seconds:
            self.assertEqual(steps[index - 1], {'action': 'set_combat_avoidance', 'actor': 'caster', 'dodge': 0.0,
                                                'parry': 0.0})
            self.assertNotEqual(steps[index - 2]['action'], 'set_combat_avoidance')
        labels = [step.get('label') for step in steps]
        model = expectation.model['second_strike']
        self.assertEqual(labels.count(model['present_label']), 1)
        present = labels.index(model['present_label'])
        self.assertEqual(present, triggers[1] + 1)
        self.assertLess(present, seconds[1])
        self.assertLess(seconds[1], labels.index(expectation.model['after_label']))
        self.assertEqual(labels.index(model['log_label']), labels.index(expectation.model['after_label']) + 1)
        self.assertEqual(labels.index(model['log_before_label']), labels.index(expectation.model['before_label']) + 1)
        read = steps[labels.index(model['log_label'])]
        self.assertEqual((read['metric'], read['spell'], read['caster']), ('spell_log_count', 23583, STRIKER))

    def test_without_the_option_no_second_strike_is_made(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), entry(second_strike=None))
        self.assertNotIn('second_strike', expectation.model)
        self.assertFalse(any(step.get('spell') == 23583 for step in scenario['steps']))
        self.assertFalse(any(step.get('parry') == 0.0 for step in scenario['steps']))

    def test_the_option_needs_a_strike_and_another_spell(self):
        for changes in ({'strike': None, 'caster_avoidance': None},
                        {'second_strike': {'spell': 2118233, 'present': 30}},
                        {'second_strike': {'spell': 23583}}, {'second_strike': {'spell': 23583, 'present': True}},
                        {'second_strike': {'spell': 23583, 'present': 30, 'count': 2}},
                        {'second_strike': {'spell': 23583, 'present': 30, 'wait_ms': -1}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), entry(**changes))

    def test_a_consumed_state_is_ok_a_kept_one_alerts_and_a_missing_state_or_strike_is_unmeasured(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(19), entry())
        model = expectation.model
        strike = model['second_strike']

        def judged(after: float, present: float | None, logs: float | None, before_logs: float | None = 1) -> str:
            values = {model['before_label']: 0, model['after_label']: after}
            if present is not None:
                values[strike['present_label']] = present
            if before_logs is not None:
                values[strike['log_before_label']] = before_logs
            if logs is not None:
                values[strike['log_label']] = logs
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(0, 30, 2), 'ok')
        self.assertEqual(judged(30, 30, 2), 'alert')
        self.assertEqual(judged(0, 0, 2), 'unmeasured')
        self.assertEqual(judged(0, None, 2), 'unmeasured')
        self.assertEqual(judged(0, 30, 1), 'unmeasured')
        self.assertEqual(judged(0, 30, None), 'unmeasured')
        self.assertEqual(judged(0, 30, 2, 0), 'unmeasured')
        self.assertEqual(judged(0, 30, 2, None), 'unmeasured')
        self.assertEqual(judged(0, 30, 3), 'unmeasured')
        self.assertEqual(judged(0, 30, 2, 2), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
