import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 705515, 'name': 'Strafing Shot (one Tormentor copy per ranged crit)', 'kind': 'spread_per_crit',
         'quote': 'Critical strikes with ranged abilities now spread Tormentor to a nearby enemy.',
         'seed_spell': 800162, 'aura_spell': 800162, 'target_rank': 800165, 'hit_spells': [800165, 704342],
         'spares': 6, 'radius': 10, 'force_crit': 'ranged'}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SpreadPerCritTests(unittest.TestCase):
    def judged(self, crits: float, copies: float, control_crits: float = 4.0, control_copies: float = 0.0) -> str:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        reads = expectation.model['reads']
        values = {}
        for name, (gain, spread) in (('control', (control_crits, control_copies)), ('treatment', (crits, copies))):
            for moment in ('start', 'end'):
                hits = reads[name][moment]['crits']
                values.update({label: 0.0 for label in hits})
                values[hits[-1]] = gain if moment == 'end' else 0.0
                for index, label in enumerate(reads[name][moment]['spares']):
                    values[label] = 1.0 if moment == 'end' and index < spread else 0.0
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def test_the_talent_is_learned_after_the_treatment_seed(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        steps = scenario['steps']
        seeds = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 800162]
        learn = next(index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 705515)
        self.assertEqual(len(seeds), 2)
        self.assertLess(seeds[1], learn)
        self.assertEqual(len(scenario['creatures']), 7)
        self.assertEqual(scenario['players'][0]['ranged_crit_rating'], 100000)
        critical = [step for step in steps if step.get('critical') is True]
        self.assertEqual({step['spell'] for step in critical}, {800165, 704342})

    def test_one_copy_per_crit_passes(self):
        self.assertEqual(self.judged(4.0, 4.0), 'ok')

    def test_a_single_copy_for_several_crits_alerts(self):
        self.assertEqual(self.judged(4.0, 1.0), 'alert')

    def test_a_copy_without_the_talent_alerts(self):
        self.assertEqual(self.judged(4.0, 4.0, control_copies=1.0), 'alert')

    def test_saturated_spares_or_no_crit_are_unmeasured(self):
        self.assertEqual(self.judged(6.0, 6.0), 'unmeasured')
        self.assertEqual(self.judged(0.0, 0.0), 'unmeasured')
        self.assertEqual(self.judged(4.0, 4.0, control_crits=0.0), 'unmeasured')

    def test_the_entry_needs_spares_a_radius_and_a_crit_fixture(self):
        for changes in ({'spares': 1}, {'force_crit': 'none'}, {'hit_spells': []}, {'radius': 0.5}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})


if __name__ == '__main__':
    unittest.main()
