import re
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import LEARNED_CONTRAST, READBACK, contrast_proof, metric_evidence, state_promises
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

FELSWORN = 14
UNPHASED = 803645
SHADOW_PROTECTION = 976
SHIFTED = {'aura': [SHADOW_PROTECTION, 0], 'amount': 150, 'shift': 60, 'shift_spell': [UNPHASED, 0], 'school': 5,
           'tolerance_share': 0.05, 'discrimination_share': 0.5, 'source': 'a seeded shifted control'}


def entry(**changes) -> dict:
    return {'spell': UNPHASED, 'name': 'Unphased (seeded)', 'kind': 'metric_delta', 'variant': 'seeded',
            'label_suffix': 'seeded', 'quote': 'Increases your spell penetration by ${-($m1+0)}',
            'trigger_spell': 804247, 'gate_spell': UNPHASED, 'target': 'caster', 'measure_actor': 'dummy',
            'metric': 'resistance', 'fields': {'school': 5}, 'before_expected': 150, 'expected': 150,
            'wait_ms': 500, 'expire_ms': 500, 'phase_auras': [[SHADOW_PROTECTION, 1, 'dummy', 'dummy']],
            'phase_aura_amounts': [[SHADOW_PROTECTION, 0, 150]], 'evidence_metric': 'spell_resist_chance',
            'shifted_control': SHIFTED, **changes}


def built(**changes):
    scenario, [expectation] = behaviour_scenario(load_class_file(FELSWORN), entry(**changes))
    return scenario, expectation


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ShiftedControlScenarioTests(unittest.TestCase):
    def test_the_shifted_control_is_read_between_the_control_and_the_restored_fixture(self):
        scenario, expectation = built()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        model = expectation.model['shifted_control']
        control, shifted, treatment = (labels.index(model[key]) for key in ('control', 'shifted', 'treatment'))
        resistance = labels.index(model['shifted_resistance'])
        self.assertEqual(control, labels.index(expectation.model['before_label']) + 1)
        self.assertEqual(treatment, labels.index(expectation.model['after_label']) + 1)
        self.assertEqual([steps[index]['amount'] for index in range(control, shifted) if 'amount' in steps[index]],
                         [90])
        self.assertLess(resistance, shifted)
        self.assertEqual(steps[shifted + 1]['amount'], 150)
        self.assertEqual((steps[shifted]['metric'], steps[shifted]['target'], steps[shifted]['school']),
                         ('spell_resist_chance', 'dummy', 5))
        self.assertEqual(model['shifted_expected'], 90)
        self.assertFalse(any(step['action'] == 'set_level' for step in steps))

    def test_the_shift_is_derived_from_the_dbc_at_the_caster_level(self):
        for changes in ({'shift': 59}, {'caster_level': 40}):
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, 'gives'):
                built(shifted_control={**SHIFTED, **changes})
        scenario, expectation = built(shifted_control={**SHIFTED, 'shift': 40, 'caster_level': 40})
        run.validate(scenario)
        levels = [step for step in scenario['steps'] if step['action'] == 'set_level']
        self.assertEqual([step['value'] for step in levels], [40])
        self.assertEqual(expectation.model['shifted_control']['shifted_expected'], 110)

    def test_without_the_option_no_resist_chance_is_read(self):
        scenario, expectation = built(shifted_control=None)
        self.assertNotIn('shifted_control', expectation.model)
        self.assertFalse(any(step.get('metric') == 'spell_resist_chance' for step in scenario['steps']))

    def test_the_option_is_refused_outside_its_shape(self):
        refused = [{'shifted_control': {**SHIFTED, 'tolerance_share': 0.5}},
                   {'shifted_control': {**SHIFTED, 'amount': 119}, 'phase_aura_amounts': [[SHADOW_PROTECTION, 0, 119]],
                    'before_expected': 119, 'expected': 119},
                   {'shifted_control': {**SHIFTED, 'shift_spell': [UNPHASED, 1]}},
                   {'phase_auras': []}, {'phase_aura_amounts': [[SHADOW_PROTECTION, 0, 140]]},
                   {'evidence_metric': None}, {'metric': 'stat'}, {'expected': 90},
                   {'phase_caster_level': [60, 40]}]
        for changes in refused:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                built(**changes)

    def test_the_metric_is_a_readback_behaviour_only_in_a_learned_contrast_with_the_penetration_words(self):
        self.assertEqual(metric_evidence()['spell_resist_chance'], READBACK)
        self.assertEqual(contrast_proof()['spell_resist_chance'], LEARNED_CONTRAST)
        words = state_promises()['spell_resist_chance']
        self.assertTrue(re.search(words, 'Increases your spell penetration by 60', re.IGNORECASE))
        self.assertFalse(re.search(words, 'Increases your Shadow resistance by 60', re.IGNORECASE))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ShiftedControlJudgeTests(unittest.TestCase):
    def judged(self, control=10.0, shifted=7.0, treatment=7.0, resistance=90.0, fixture=150.0):
        _, expectation = built()
        model = expectation.model
        labels = model['shifted_control']
        values = {model['before_label']: fixture, model['after_label']: 150.0, labels['control']: control,
                  labels['shifted']: shifted, labels['treatment']: treatment,
                  labels['shifted_resistance']: resistance}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_treatment_equal_to_the_shifted_control_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertAlmostEqual(verdict.measured, 1.0)

    def test_mutant_no_penetration_fails_on_control_minus_treatment(self):
        verdict = self.judged(treatment=10.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('control - treatment 0 (at least 1.5: off)', verdict.explanation)

    def test_mutant_half_the_penetration_fails_on_the_shifted_control_equality(self):
        verdict = self.judged(treatment=8.5)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('(at least 1.5: ok)', verdict.explanation)
        self.assertIn('|shifted control - treatment| 1.5 (at most 0.15: off)', verdict.explanation)

    def test_a_read_that_does_not_move_or_a_wrong_fixture_is_void(self):
        for changes in ({'shifted': 10.0}, {'resistance': 100.0}, {'fixture': 140.0}):
            with self.subTest(changes=changes):
                self.assertEqual(self.judged(**changes).status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
