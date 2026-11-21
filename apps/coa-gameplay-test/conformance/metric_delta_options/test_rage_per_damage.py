import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.rage_per_damage import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

BOLT = 500968


def rage_entry(**changes) -> dict:
    return {'spell': BOLT, 'name': 'Example bolt (Rage per damage)', 'kind': 'metric_delta',
            'label_suffix': 'rage_per_damage', 'quote': 'healing you for a portion of the damage dealt.', 'expected': 1,
            'before_expected': 1, 'tolerance': 0.05, 'trigger_spell': BOLT, 'target': 'dummy',
            'disable_regeneration': True, 'metric': 'power', 'fields': {'power': 1}, 'wait_ms': 3800,
            'expire_ms': 500, 'phase_power': [1, 0, 0], 'phase_auras': [[64481, 1, 'caster', 'caster']],
            'after_auras': [[10031, 1, 'caster', 'caster']],
            'rage_per_damage': {'spell': BOLT, 'target': 'dummy', 'min_damage_ratio': 1.5}, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RagePerDamageTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), rage_entry(**changes))

    def test_the_damage_reads_come_right_before_each_rage_reading(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        recorded = expectation.model['rage_per_damage']
        for moment in ('before', 'after'):
            read = labels.index(expectation.model[f'{moment}_label'])
            names = [recorded[moment][name] for name in ('damage', 'hits', 'crits')]
            if moment == 'after':
                names.append(recorded['after']['cap'])
            self.assertEqual(labels[read - len(names):read], names)
        crits = scenario['steps'][labels.index(recorded['before']['crits'])]
        self.assertEqual((crits['metric'], crits['critical'], crits['spell']), ('spell_damage_count', True, BOLT))
        self.assertIn('Rage per damage', scenario['contract'])

    def test_an_entry_without_the_option_is_unchanged(self):
        scenario, [expectation] = self.built(rage_per_damage=None)
        self.assertNotIn('rage_per_damage', expectation.model)
        self.assertFalse(any(str(step.get('label')).endswith((' damage', ' hits', ' crits', ' max power'))
                             for step in scenario['steps']))

    def values(self, rage=(170.0, 340.0), damage=(1040.0, 2080.0), hits=(1, 1), crits=(0, 0), cap=1000.0,
               missing=None):
        _, [expectation] = self.built()
        recorded = expectation.model['rage_per_damage']
        found = {expectation.model['before_label']: rage[0], expectation.model['after_label']: rage[1],
                 recorded['before']['damage']: damage[0], recorded['after']['damage']: damage[0] + damage[1],
                 recorded['before']['hits']: hits[0], recorded['after']['hits']: hits[0] + hits[1],
                 recorded['before']['crits']: crits[0], recorded['after']['crits']: crits[0] + crits[1],
                 recorded['after']['cap']: cap}
        if missing:
            found.pop(recorded['after'][missing])
        return expectation, found

    def judged(self, **reads):
        expectation, found = self.values(**reads)
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def test_rage_that_follows_the_damage_is_ok_within_the_truncation(self):
        verdict = self.judged(rage=(169.0, 339.0))
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, (339 / 2080) / (169 / 1040))
        self.assertEqual((verdict.low, verdict.high), (0.95, 1.05))

    def test_rage_independent_of_the_damage_alerts(self):
        verdict = self.judged(rage=(170.0, 170.0))
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 0.5)

    def test_a_fixed_rage_on_top_of_the_damage_part_alerts_once_it_moves_the_ratio(self):
        self.assertEqual(self.judged(rage=(170.0 + 30.0, 340.0 + 30.0)).status, 'alert')
        self.assertEqual(self.judged(rage=(0.0, 340.0)).status, 'alert')

    def test_a_phase_that_cannot_judge_the_ratio_is_unmeasured(self):
        for reads in ({'hits': (2, 1)}, {'hits': (1, 0)}, {'crits': (0, 1)}, {'damage': (1040.0, 1200.0)},
                      {'rage': (170.0, 1000.0)}, {'missing': 'cap'}, {'damage': (0.0, 2080.0)}):
            with self.subTest(reads=reads):
                self.assertEqual(self.judged(**reads).status, 'unmeasured')

    def test_the_damage_dealt_words_of_the_claim_make_the_ratio_behaviour(self):
        from dataclasses import replace
        from compare import observed
        from coverage import BEHAVIOUR, DATA, METRIC_EVIDENCE, STATE, STATE_PROMISES, metric_evidence, \
            verdict_evidence
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['metric'], 'rage_per_damage')
        self.assertNotIn('rage_per_damage', METRIC_EVIDENCE)
        self.assertNotIn('rage_per_damage', STATE_PROMISES)
        self.assertEqual(metric_evidence()['rage_per_damage'], STATE)
        self.assertEqual(verdict_evidence(verdict, 'based on the damage dealt.', {}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdict, 'Generates Rage', {}), DATA)
        self.assertEqual(verdict_evidence(verdict, 'healing you for a portion of the damage dealt.', {}), DATA)
        _, [plain] = self.built(rage_per_damage=None)
        self.assertNotIn('evidence_metric', plain.model)
        unstamped = replace(verdict, detail={**verdict.detail, **observed(plain)})
        self.assertEqual(unstamped.detail['metric'], 'power')
        self.assertEqual(verdict_evidence(unstamped, 'based on the damage dealt.', {}), DATA)
        self.assertNotEqual(verdict_evidence(self.judged(rage=(170.0, 170.0)), 'based on the damage dealt.', {}),
                            BEHAVIOUR)

    def test_refused_inputs(self):
        for raw in ({'spell': BOLT, 'target': 'dummy'}, {'spell': BOLT, 'target': 'dummy', 'min_damage_ratio': 1},
                    {'spell': True, 'target': 'dummy', 'min_damage_ratio': 2}, 'dummy'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'after_auras': []}, {'cast_in_before': False}, {'metric': 'health', 'fields': {}},
                        {'phase_power': None}, {'tolerance': None},
                        {'rage_per_damage': {'spell': 1, 'target': 'dummy', 'min_damage_ratio': 1.5}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
