import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_class_file
import run


class CorpseFixtureTests(unittest.TestCase):
    def entry(self, spell: int, suffix: str) -> dict:
        return next(entry for entry in load_class_file(23)['behaviours']
                    if entry['spell'] == spell and entry.get('label_suffix') == suffix)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_corpse_is_killed_by_a_real_cast_in_the_treatment_phase_only(self):
        scenario, _ = behaviour_scenario(load_class_file(23), self.entry(533239, 'mechanical_corpse'))
        run.validate(scenario)
        corpse = next(creature for creature in scenario['creatures'] if creature['id'] == 'corpse')
        self.assertEqual((corpse['entry'], corpse['health'], corpse['distance']), (480, 100, 5.0))
        kills = [step for step in scenario['steps'] if step['action'] == 'cast' and step.get('target') == 'corpse']
        self.assertEqual([step['spell'] for step in kills], [92559])
        explosions = [index for index, step in enumerate(scenario['steps'])
                      if step['action'] == 'cast' and step['spell'] == 533239]
        kill = scenario['steps'].index(kills[0])
        self.assertTrue(explosions[0] < kill < explosions[1])

    def test_a_corpse_needs_its_killing_cast_and_the_treatment_phase(self):
        entry = self.entry(533239, 'corpse_explodes')
        for change in ({'setup_only_after': False}, {'setup_target': 'dummy'}, {'corpse': {'entry': 6}}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(23), {**entry, **change})
