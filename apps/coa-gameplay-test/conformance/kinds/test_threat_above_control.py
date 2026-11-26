import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 500610, 'name': 'Fel Torpedo (threat per damage above a control hit)',
         'kind': 'threat_above_control', 'label_suffix': 'threat_above_control',
         'quote': 'Generates a large amount of threat.', 'hit_spell': 500761, 'control_spell': 803715, 'samples': 5}
DAMAGE = (303.0, 290.0, 315.0, 298.0, 307.0)


def fel_torpedo_threat(damage: float) -> float:
    return damage * 3.25 + 225.0


def carve_threat(damage: float) -> float:
    return damage + 11.0


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ThreatAboveControlTests(unittest.TestCase):
    def expectation(self, **changes):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})
        return expectation

    def judged(self, treatment=fel_torpedo_threat, control=carve_threat, failure=None, lost=None) -> Verdict:
        expectation = self.expectation()
        values = {}
        for arm, threat in (('treatment', treatment), ('control', control)):
            for index, labels in enumerate(expectation.model['samples'][arm]):
                damage = DAMAGE[index]
                values[labels['health before']] = 1000000.0
                values[labels['health after']] = 1000000.0 - (damage if lost is None else lost)
                values[labels['threat before']] = 0.0
                values[labels['threat after']] = threat(damage) if callable(threat) else threat[index]
                values[labels['cast_failure after']] = failure if failure is not None and arm == 'control' else 0.0
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_each_sample_is_one_cast_at_its_own_dummy_after_a_step_along_the_line(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual([step['spell'] for step in casts], [500761, 803715] * 5)
        self.assertEqual(len({step['target'] for step in casts}), 10)
        self.assertEqual(len([step for step in scenario['steps'] if step['action'] == 'relocate']), 9)
        self.assertEqual([creature['distance'] for creature in scenario['creatures']],
                         [3.0 + 10.0 * position for position in range(10)])
        self.assertEqual((expectation.model['metric'], expectation.model['contrast']), ('threat', 'own_cast'))

    def test_a_hit_whose_threat_per_damage_lies_above_every_control_sample_passes(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('direction only', verdict.explanation)

    def test_a_seeded_server_with_equal_threat_per_damage_alerts(self):
        self.assertEqual(self.judged(treatment=carve_threat).status, 'alert')

    def test_one_overlapping_sample_alerts(self):
        threats = [fel_torpedo_threat(damage) for damage in DAMAGE]
        threats[2] = carve_threat(DAMAGE[0]) / DAMAGE[0] * DAMAGE[2]
        self.assertEqual(self.judged(treatment=threats).status, 'alert')

    def test_a_failed_cast_or_a_hit_without_damage_is_unmeasured(self):
        self.assertEqual(self.judged(failure=12.0).status, 'unmeasured')
        self.assertEqual(self.judged(lost=0.0).status, 'unmeasured')

    def test_a_missing_read_is_not_judged(self):
        expectation = self.expectation()
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        self.assertNotEqual(judge_behaviour(base, FakeRun({}), expectation).status, 'ok')

    def test_an_entry_outside_the_sample_range_or_without_another_control_is_refused(self):
        for changes in ({'samples': 2}, {'samples': 6}, {'samples': 4.0}, {'control_spell': 500761},
                        {'settle_ms': -1}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.expectation(**changes)


if __name__ == '__main__':
    unittest.main()
