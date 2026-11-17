import unittest
from dataclasses import replace

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 560613, 'name': 'Improved Mandates (Grim Mandate spell power)', 'kind': 'effectiveness_delta',
         'variant': 'grim_mandate', 'label_suffix': 'grim_mandate',
         'quote': 'Increases the effectiveness of your Mandates by $s1%.', 'expected': 58, 'before_expected': 49,
         'trigger_spell': 572789, 'gate_spell': 560613, 'target': 'caster', 'expire_ms': 1801000, 'wait_ms': 1000,
         'metric': 'spell_power', 'fields': {'school': 5}}
CLAUSE = 'Increases the effectiveness of your Mandates by 20%.'


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class EffectivenessDeltaTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})

    def judged(self, before: float, after: float):
        _, [expectation] = self.built()
        model = expectation.model
        found = judge_behaviour(base_verdict(expectation), FakeRun({model['before_label']: before,
                                                                    model['after_label']: after}), expectation)
        return found

    def test_the_effect_is_cast_without_and_with_the_learned_modifier(self):
        scenario, [expectation] = self.built()
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 572789]
        learn = next(index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 560613)
        self.assertEqual(len(casts), 2)
        self.assertLess(casts[0], learn)
        self.assertLess(learn, casts[1])
        self.assertEqual(expectation.model['contrast'], 'learned')
        self.assertEqual(expectation.model['metric'], 'effectiveness_spell_power')

    def test_the_modified_amount_passes_and_an_unmodified_one_alerts(self):
        self.assertEqual(self.judged(49.0, 58.0).status, 'ok')
        self.assertEqual(self.judged(49.0, 49.0).status, 'alert')

    def test_an_effectiveness_clause_promises_the_read_state(self):
        from coverage import STATE, metric_evidence, promised_state
        found = self.judged(49.0, 58.0)
        self.assertEqual(found.detail['metric'], 'effectiveness_spell_power')
        self.assertEqual(metric_evidence()['effectiveness_spell_power'], STATE)
        self.assertTrue(promised_state(found, CLAUSE))
        self.assertFalse(promised_state(found, 'Increases your spell power by 49.'))
        self.assertFalse(promised_state(replace(found, detail={**found.detail, 'contrast': 'condition'}), CLAUSE))

    def test_an_entry_without_a_modifier_or_without_the_control_cast_is_refused(self):
        for changes in ({'gate_spell': None}, {'cast_in_before': False}, {'metric': 'aura'},
                        {'gate_timing': 'start'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)
