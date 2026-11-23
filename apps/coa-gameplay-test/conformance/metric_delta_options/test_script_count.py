import unittest
from dataclasses import replace
from unittest import mock

from behaviours import behaviour_scenario, metric_delta_spec
from compare import judge_behaviour
from coverage import EvidenceError
from metric_delta_options import script_count
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict
from test_coverage import BUILD, claim, evidence_of

ANNIHILATION_TEXT = 'Lasts for $n attacks or $d.'
PIT_LORD_TEXT = 'Your Annihilation now affects $s1 additional attack'
COUNTED = {'noun': 'attack'}


def annihilation(**changes) -> dict:
    return {'spell': 803904, 'name': 'Annihilation (attacks)', 'kind': 'metric_delta', 'variant': 'charges',
            'label_suffix': 'charges', 'quote': ANNIHILATION_TEXT, 'trigger_spell': 803904, 'gate_spell': 803904,
            'target': 'caster', 'metric': 'aura_script_value', 'fields': {'spell': 803904, 'key': 803904},
            'cast_in_before': False, 'before_expected': 0, 'expected': 5, 'tolerance': 0, 'wait_ms': 500,
            'expire_ms': 500, 'script_count': COUNTED, **changes}


def pit_lord(**changes) -> dict:
    return {'spell': 802076, 'name': "Pit Lord's Strength (Annihilation attacks)", 'kind': 'metric_delta',
            'variant': 'charges', 'label_suffix': 'charges', 'quote': PIT_LORD_TEXT, 'trigger_spell': 803904,
            'gate_spell': 802076, 'target': 'caster', 'metric': 'aura_script_value',
            'fields': {'spell': 803904, 'key': 803904}, 'before_expected': 5, 'expected': 6, 'tolerance': 0,
            'wait_ms': 500, 'expire_ms': 500, 'script_count': COUNTED, **changes}


def without_option(entry: dict) -> dict:
    return {key: value for key, value in entry.items() if key != 'script_count'}


def generated(entry: dict):
    return behaviour_scenario(load_fixture_class_file(19), entry)


def judged_read(entry: dict, text: str, before: float, after: float):
    _, [expectation] = generated(entry)
    values = {expectation.model['before_label']: before, expectation.model['after_label']: after}
    verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
    evidence = evidence_of([claim(text, verdict.label, spell=entry['spell'])],
                           [replace(verdict, spell_id=entry['spell'], build=BUILD)])[0]
    return verdict, evidence


SPEC_MUTANTS = (
    ('stated_count', annihilation(quote='Gorge on fel energy')),
    ('counted_read', annihilation(evidence_metric='aura')),
    ('plain_layout', pit_lord(gate_timing='start')),
    ('contrast_arm', annihilation(cast_in_before=True)),
)
SCENARIO_MUTANTS = (
    ('named_aura', pit_lord(quote='affects $s1 additional attack')),
    ('no_setter', annihilation(phase_auras=[[800058, 1, 'caster', 'caster']])),
)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScriptCountTests(unittest.TestCase):
    def test_the_opted_read_stamps_the_count_metric_and_its_driver(self):
        for entry, driver in ((annihilation(), 'absent'), (pit_lord(), 'different')):
            with self.subTest(spell=entry['spell']):
                scenario, [expectation] = generated(entry)
                run.validate(scenario)
                self.assertEqual(expectation.model['metric'], 'aura_script_value')
                self.assertEqual(expectation.model['evidence_metric'], 'aura_script_count')
                self.assertEqual(expectation.model['script_count'],
                                 {'noun': 'attack', 'aura': 803904, 'driver': driver})
                self.assertIn(f'with the driving cast {driver}', scenario['contract'])

    def test_without_the_option_the_scenario_and_model_are_unchanged(self):
        for entry in (annihilation(), pit_lord()):
            with self.subTest(spell=entry['spell']):
                plain, [expectation] = generated(without_option(entry))
                opted, _ = generated(entry)
                self.assertEqual(plain['steps'], opted['steps'])
                self.assertNotIn('evidence_metric', expectation.model)
                self.assertNotIn('script_count', expectation.model)
                self.assertNotIn('aura_script_count', plain['contract'])

    def test_the_option_is_one_counted_noun(self):
        for raw in (True, {}, {'noun': 'hit'}, {'noun': 'attack', 'other': 1}, 'attack'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                generated(annihilation(script_count=raw))

    def test_the_count_metric_is_refused_without_the_option(self):
        with self.assertRaises(ValueError):
            generated(without_option(annihilation(evidence_metric='aura_script_count')))

    def test_each_spec_refusal_rule_refuses_its_case(self):
        extra = (('counted_read', annihilation(metric='aura')), ('counted_read', annihilation(after_at_least=5)),
                 ('contrast_arm', annihilation(tolerance=2.5)), ('contrast_arm', annihilation(expected=0)))
        for rule, entry in (*SPEC_MUTANTS, *extra):
            with self.subTest(rule=rule, entry=entry), self.assertRaisesRegex(ValueError, 'script_count'):
                generated(entry)

    def test_each_scenario_refusal_rule_refuses_its_case(self):
        for rule, entry in SCENARIO_MUTANTS:
            with self.subTest(rule=rule), self.assertRaisesRegex(ValueError, 'script_count'):
                generated(entry)

    def test_mutant_without_each_rule_lets_its_case_through(self):
        for rule, entry in (*SPEC_MUTANTS, *SCENARIO_MUTANTS):
            with self.subTest(rule=rule), mock.patch(f'metric_delta_options.script_count.{rule}',
                                                     lambda *args: None):
                scenario, _ = generated(entry)
                self.assertTrue(scenario['steps'])

    def seeded(self, entry: dict, edit) -> str | None:
        scenario, _ = generated(entry)
        return edit(metric_delta_spec(entry), list(scenario['steps']))

    def test_a_non_cast_step_on_the_read_aura_is_refused_and_caught_by_its_rule(self):
        def written(spec, steps):
            return script_count.no_setter(spec, [*steps, {'action': 'unlearn', 'actor': 'caster', 'spell': 803904}])
        self.assertIn('writes the read aura 803904', self.seeded(annihilation(), written))
        self.assertIsNone(self.seeded(annihilation(), script_count.no_setter))

    def test_the_real_cast_rule_refuses_a_missing_or_early_driving_cast(self):
        def uncast(spec, steps):
            return script_count.real_cast(spec, [step for step in steps if step.get('action') != 'cast'])

        def early(spec, steps):
            return script_count.real_cast(spec, [{'action': 'cast', 'actor': 'caster', 'spell': 803904,
                                                  'target': 'caster'}, *steps])
        self.assertIn('no real cast of 803904', self.seeded(annihilation(), uncast))
        self.assertIn('driving cast is not absent', self.seeded(annihilation(), early))
        self.assertIsNone(self.seeded(annihilation(), script_count.real_cast))
        self.assertIsNone(self.seeded(pit_lord(), early))
        records = mock.Mock(field=lambda *args: 'Annihilation')
        self.assertIn('no real cast', self.seeded(annihilation(), lambda spec, steps: script_count.scenario_refusal(
            spec, [step for step in steps if step.get('action') != 'cast'], records)))
        with mock.patch('metric_delta_options.script_count.real_cast', lambda *args: None):
            self.assertIsNone(self.seeded(annihilation(), lambda spec, steps: script_count.scenario_refusal(
                spec, [step for step in steps if step.get('action') != 'cast'], records)))

    def test_an_opted_count_read_is_behaviour_and_a_wrong_count_alerts(self):
        for entry, text, before, after in ((annihilation(), ANNIHILATION_TEXT, 0, 5),
                                           (pit_lord(), PIT_LORD_TEXT, 5, 6)):
            with self.subTest(spell=entry['spell']):
                verdict, evidence = judged_read(entry, text, before, after)
                self.assertEqual((verdict.status, verdict.detail['metric'], evidence),
                                 ('ok', 'aura_script_count', ['behaviour']))
                verdict, evidence = judged_read(entry, text, before, before)
                self.assertEqual((verdict.status, evidence), ('alert', ['unproven']))

    def test_the_count_read_without_its_count_word_stays_data(self):
        _, evidence = judged_read(annihilation(), 'Gorge on fel energy.', 0, 5)
        self.assertEqual(evidence, ['data'])

    def test_the_plain_script_value_read_has_no_evidence_row(self):
        with self.assertRaises(EvidenceError):
            judged_read(without_option(annihilation()), ANNIHILATION_TEXT, 0, 5)


if __name__ == '__main__':
    unittest.main()
