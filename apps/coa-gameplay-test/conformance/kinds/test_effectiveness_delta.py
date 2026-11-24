import unittest
from dataclasses import replace
from unittest import mock

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
READ_METRICS_BEFORE_RESISTANCE = ('spell_power', 'stat', 'dodge_chance', 'parry_chance', 'run_speed_rate')


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

    def test_a_dodge_or_parry_read_is_judged_as_its_effectiveness_state(self):
        from coverage import STATE, metric_evidence, promised_state
        for metric in ('dodge_chance', 'parry_chance'):
            with self.subTest(metric=metric):
                scenario, [expectation] = self.built(metric=metric, fields={}, before_expected=25, expected=32,
                                                     expected_gain=7, tolerance=0.01)
                run.validate(scenario, run.SIMULATED_CLOCK)
                model = expectation.model
                reads = [step for step in scenario['steps'] if step.get('label') in (model['before_label'],
                                                                                      model['after_label'])]
                self.assertEqual([step['metric'] for step in reads], [metric, metric])
                self.assertEqual(model['metric'], f'effectiveness_{metric}')
                self.assertEqual(metric_evidence()[f'effectiveness_{metric}'], STATE)

                def judged(before: float, after: float):
                    return judge_behaviour(base_verdict(expectation),
                                           FakeRun({model['before_label']: before, model['after_label']: after}),
                                           expectation)

                self.assertEqual(judged(29.6024, 36.6024).status, 'ok')
                self.assertEqual(judged(29.6024, 29.6024).status, 'alert')
                self.assertEqual(judged(29.6024, 37.1024).status, 'alert')
                self.assertTrue(promised_state(judged(29.6024, 36.6024), 'and increases its effectiveness by 25%.'))

    def test_a_slow_on_the_dummy_is_judged_as_its_effectiveness_state(self):
        from coverage import STATE, metric_evidence, promised_state
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), {
            'spell': 301361, 'name': 'Shadow Enchantments (Lethargy Jinx slow)', 'kind': 'effectiveness_delta',
            'label_suffix': 'jinx_effect', 'quote': 'and effectiveness of your Jinxes by $s1%',
            'trigger_spell': 802065, 'gate_spell': 301361, 'target': 'dummy', 'measure_actor': 'dummy',
            'metric': 'run_speed_rate', 'fields': {}, 'before_expected': 0.57143, 'expected': 0.285715,
            'tolerance': 0.0001, 'wait_ms': 1500, 'expire_ms': 10500})
        run.validate(scenario, run.SIMULATED_CLOCK)
        model = expectation.model
        reads = [step for step in scenario['steps'] if step.get('label') in (model['before_label'],
                                                                              model['after_label'])]
        self.assertEqual([(step['metric'], step['actor']) for step in reads],
                         [('run_speed_rate', 'dummy'), ('run_speed_rate', 'dummy')])
        self.assertEqual(metric_evidence()['effectiveness_run_speed_rate'], STATE)

        def judged(before: float, after: float):
            return judge_behaviour(base_verdict(expectation),
                                   FakeRun({model['before_label']: before, model['after_label']: after}),
                                   expectation)

        self.assertEqual(judged(0.57143, 0.285715).status, 'ok')
        self.assertEqual(judged(0.57143, 0.57143).status, 'alert')
        self.assertTrue(promised_state(judged(0.57143, 0.285715), 'and effectiveness of your Jinxes by 50%'))

    def test_an_ally_resistance_is_judged_as_its_effectiveness_state(self):
        from coverage import STATE, metric_evidence, promised_state
        entry = {'spell': 704612, 'name': 'Pact Hunter (Vengeful Pact Shadow resistance)',
                 'kind': 'effectiveness_delta', 'label_suffix': 'pact_effectiveness',
                 'quote': 'Increases the effectiveness of your Pacts by $s1%.',
                 'trigger_spell': 803885, 'gate_spell': 704612, 'target': 'dummy', 'measure_actor': 'ally',
                 'ally_arm': {'allies': 1}, 'metric': 'resistance', 'fields': {'school': 5}, 'before_expected': 65,
                 'expected': 97, 'tolerance': 0.5, 'wait_ms': 1500, 'expire_ms': 500}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario, run.SIMULATED_CLOCK)
        model = expectation.model
        reads = [step for step in scenario['steps'] if step.get('label') in (model['before_label'],
                                                                              model['after_label'])]
        self.assertEqual([(step['metric'], step['actor'], step['school']) for step in reads],
                         [('resistance', 'ally', 5), ('resistance', 'ally', 5)])
        self.assertEqual(model['metric'], 'effectiveness_resistance')
        self.assertEqual(metric_evidence()['effectiveness_resistance'], STATE)

        def judged(before: float, after: float):
            return judge_behaviour(base_verdict(expectation),
                                   FakeRun({model['before_label']: before, model['after_label']: after}),
                                   expectation)

        self.assertEqual(judged(65, 97).status, 'ok')
        self.assertEqual(judged(65, 65).status, 'alert')
        self.assertEqual(judged(65, 130).status, 'alert')
        self.assertTrue(promised_state(judged(65, 97), 'Increases the effectiveness of your Pacts by 50%.'))
        self.assertFalse(promised_state(judged(65, 97), "increases nearby allies' Shadow Resistance by 65"))
        with mock.patch('kinds.effectiveness_delta.READ_METRICS', READ_METRICS_BEFORE_RESISTANCE), \
                self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), entry)

    def test_an_entry_without_a_modifier_or_without_the_control_cast_is_refused(self):
        for changes in ({'gate_spell': None}, {'cast_in_before': False}, {'metric': 'aura'},
                        {'gate_timing': 'start'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)
