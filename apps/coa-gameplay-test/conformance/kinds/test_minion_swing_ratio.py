import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict, cast_indices, ratio_values


class MinionSwingRatioTests(unittest.TestCase):
    def built(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours'] if entry['kind'] == 'minion_swing_ratio')
        return behaviour_scenario(load_fixture_class_file(23), entry)

    def judged(self, strike_hit: float) -> str:
        _, [expectation] = self.built()
        values = ratio_values(expectation.model, strike_hit, 200.0)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_strike_and_the_swings_of_the_minion_are_read_after_every_command(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        reads = [step for step in scenario['steps'] if step['action'] == 'assert']
        strikes = [step for step in reads if step['metric'] == 'spell_damage_total' and step.get('spell') == 570042]
        swings = [step for step in reads if step['metric'] == 'pet_melee_plain_damage']
        self.assertEqual(len(strikes), len(swings))
        self.assertEqual(len(strikes), expectation.model['trials'] + 1)
        self.assertTrue(all(step['caster_entry'] == 51065 and step['critical'] is False for step in strikes))
        self.assertTrue(all(step['entry'] == 51065 for step in swings))
        commands = cast_indices(scenario['steps'], 504905)
        self.assertEqual(len(commands), expectation.model['trials'] + 1)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_spell_power_arm_sets_the_fixture_and_its_flat_part(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry.get('label_suffix') == 'weapon_ratio_sp')
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(scenario['players'][0]['spell_power'], 1000)
        self.assertEqual(expectation.model['treatment_flat'], 137.5)
        plain, _ = self.built()
        self.assertNotIn('spell_power', plain['players'][0])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_band_is_five_percent_of_the_stated_ratio_after_the_flat_part(self):
        self.assertEqual(self.judged(401.0), 'ok')
        self.assertEqual(self.judged(381.0), 'ok')
        self.assertEqual(self.judged(421.0), 'ok')
        self.assertEqual(self.judged(379.0), 'alert')
        self.assertEqual(self.judged(423.0), 'alert')
        self.assertEqual(self.judged(201.0), 'alert')
