import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def tick_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['kind'] == 'metric_delta' and entry.get('label_suffix') == 'tick_sp')
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class PlayerSpellPowerTests(unittest.TestCase):
    def test_the_option_sets_the_caster_spell_power_and_its_absence_leaves_it_unset(self):
        entry = tick_entry()
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(scenario['players'][0]['spell_power'], entry['player_spell_power'])
        plain = {key: value for key, value in entry.items() if key != 'player_spell_power'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), plain)
        self.assertNotIn('spell_power', scenario['players'][0])

    def hit_arm(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), tick_entry(
            player_spell_power={'amount': 20000, 'hit_arm': True}, **changes))

    def test_a_hit_arm_reads_the_spell_power_right_before_the_judged_reading(self):
        scenario, [expectation] = self.hit_arm()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        read = expectation.model['player_spell_power']['read']
        after = labels.index(expectation.model['after_label'])
        self.assertEqual(labels.index(read), after - 1)
        self.assertEqual((steps[after - 1]['metric'], steps[after - 1]['actor']), ('spell_power', 'caster'))
        self.assertIn(steps[after - 1]['school'], range(1, 7))
        self.assertEqual(scenario['players'][0]['spell_power'], 20000)

    def judged(self, read):
        _, [expectation] = self.hit_arm()
        model = expectation.model
        values = {model['before_label']: 0.0, model['after_label']: float(model['expected'])}
        if read is not None:
            values[model['player_spell_power']['read']] = read
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_hit_arm_verdict_records_the_spell_power_read_and_only_a_positive_one(self):
        found = self.judged(20000.0)
        self.assertEqual(found.status, 'ok')
        self.assertEqual(found.detail['spell_power'], 20000.0)
        for read in (0.0, None):
            with self.subTest(read=read):
                self.assertNotIn('spell_power', self.judged(read).detail or {})

    def test_a_plain_spell_power_records_nothing_and_reads_nothing(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), tick_entry())
        self.assertNotIn('player_spell_power', expectation.model)
        self.assertFalse(any(str(step.get('label', '')).endswith('after spell power') for step in scenario['steps']))

    def test_a_hit_arm_needs_a_hit_metric_and_a_positive_amount(self):
        for changes in ({'metric': 'aura', 'fields': {'spell': 570131},
                         'player_spell_power': {'amount': 20000, 'hit_arm': True}},
                        {'player_spell_power': {'amount': 0, 'hit_arm': True}},
                        {'player_spell_power': {'amount': 20000, 'hit_arm': False}},
                        {'player_spell_power': {'amount': 20000}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), tick_entry(**changes))


if __name__ == '__main__':
    unittest.main()
