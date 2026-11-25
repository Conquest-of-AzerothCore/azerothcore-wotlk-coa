import unittest

from behaviours import STRIKER, behaviour_scenario
from kinds.offensive_dispel_resist_rate import (CONTROL, GATE_OFF, TREATMENT, arm_risk, arm_trials,
                                                clamped_survive_rate, gate_label, offensive_dispel_resist_spec,
                                                offensive_dispel_resist_verdict, read_label)
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict
from values import ALLY

BASE_ENTRY = {
    'spell': 804633, 'kind': 'offensive_dispel_resist_rate', 'variant': 'dispel_resist',
    'label_suffix': 'dispel_resist', 'name': 'Void-Enchanted Armor',
    'quote': 'Increases your chance to resist dispel effects by $s1%.',
    'buff_spell': 48161, 'treatment_resist_pct': 20, 'parts': 6}
GATED_ENTRY = {
    'spell': 300287, 'kind': 'offensive_dispel_resist_rate', 'variant': 'dispel_resist',
    'label_suffix': 'dispel_resist', 'name': 'Forbidden Resilience',
    'quote': 'and have a $s1% increased chance to resist dispel effects.',
    'buff_spell': 48161, 'treatment_resist_pct': 25, 'learn': [92131, 520326], 'gate_cast': 520326, 'parts': 6}
ALLY_ENTRY = {
    'spell': 525060, 'kind': 'offensive_dispel_resist_rate', 'variant': 'dispel_resist',
    'label_suffix': 'dispel_resist', 'name': 'Crystalline Reflection',
    'quote': 'Increases the chance for Void Shield to resist dispel effects on allies by $s2%',
    'buff_spell': 578115, 'target': ALLY, 'treatment_resist_pct': 50, 'parts': 6}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(25), entry)


def survived_reads(prefix: str, arm: str, trials: int, survived: int) -> dict:
    return {read_label(prefix, arm, trial): 1.0 if trial <= survived else 0.0 for trial in range(1, trials + 1)}


def seeded_runs(model: dict, rates: dict, parts: int, gate_values: dict | None = None) -> list[FakeRun]:
    runs = []
    for _ in range(parts):
        values = {}
        for arm in model['arms']:
            trials = model['trials'][arm]
            values.update(survived_reads(model['prefix'], arm, trials, round(rates[arm] * trials)))
            if model.get('gate_cast') is not None:
                default = 0.0 if arm == GATE_OFF else 1.0
                for edge in ('before', 'after'):
                    val = (gate_values or {}).get((arm, edge), default)
                    values[gate_label(model['prefix'], arm, edge)] = val
        runs.append(FakeRun(values))
    return runs


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class OffensiveDispelResistRateTests(unittest.TestCase):
    def test_clamped_survive_rate_follows_calc_dispel_chance_bounds(self):
        self.assertEqual(clamped_survive_rate(-20), 0.0)
        self.assertEqual(clamped_survive_rate(0), 0.0)
        self.assertEqual(clamped_survive_rate(20), 0.2)
        self.assertEqual(clamped_survive_rate(100), 1.0)
        self.assertEqual(clamped_survive_rate(135), 1.0)

    def test_generates_valid_scenarios_for_caster_gated_and_ally_entries(self):
        for entry, expected_labels in (
                (BASE_ENTRY, ['804633 behaviour_metric_delta dispel_resist']),
                (GATED_ENTRY, ['300287 behaviour_metric_delta dispel_resist',
                               '300287 behaviour_metric_delta dispel_resist_gate_off']),
                (ALLY_ENTRY, ['525060 behaviour_metric_delta dispel_resist'])):
            with self.subTest(spell=entry['spell']):
                scenario, expectations = scenario_of(entry)
                validated = run.validate(scenario)
                self.assertEqual([item.label for item in expectations], expected_labels)
                striker = next(creature for creature in validated['creatures'] if creature['id'] == STRIKER)
                self.assertEqual(striker['spell_hit_bonus'], 100)
                self.assertEqual(striker['reaction'], 0)
                steps = validated['steps']
                learn = next(index for index, step in enumerate(steps)
                             if step['action'] == 'learn' and step.get('spell') == entry['spell'])
                dispels = [index for index, step in enumerate(steps)
                           if step['action'] == 'cast' and step['actor'] == STRIKER and step['spell'] == 527]
                trials = expectations[0].model['trials']
                self.assertEqual(len(dispels), sum(trials.values()))
                self.assertEqual(sum(index < learn for index in dispels), trials[CONTROL])
                if entry.get('target') == ALLY:
                    self.assertEqual([player['id'] for player in validated['players']], [CASTER, ALLY])
                    self.assertTrue(all(steps[index]['target'] == ALLY for index in dispels))
                else:
                    self.assertTrue(all(steps[index]['target'] == CASTER for index in dispels))

    def test_trials_are_sized_within_residual_for_both_false_fail_and_false_pass(self):
        for entry in (BASE_ENTRY, GATED_ENTRY, ALLY_ENTRY):
            with self.subTest(spell=entry['spell']):
                spec = offensive_dispel_resist_spec(entry)
                risk = arm_risk(spec)
                self.assertLessEqual(risk['false_fail_pair'], spec.residual)
                self.assertLessEqual(risk['max_false_pass_pair'], spec.residual)

    def test_seeded_ok_for_interior_gated_and_clamped_boundary_rates(self):
        _, [exp] = scenario_of(BASE_ENTRY)
        verdict = offensive_dispel_resist_verdict(base_verdict(exp),
                                                  seeded_runs(exp.model, {CONTROL: 0.0, TREATMENT: 0.2}, 6),
                                                  exp.model)
        self.assertEqual(verdict.status, 'ok')

        _, [main_exp, gate_exp] = scenario_of(GATED_ENTRY)
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(main_exp), seeded_runs(main_exp.model, {CONTROL: 0.0, TREATMENT: 0.25}, 6),
            main_exp.model).status, 'ok')
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(gate_exp), seeded_runs(gate_exp.model, {CONTROL: 0.0, GATE_OFF: 0.0}, 6),
            gate_exp.model).status, 'ok')

        clamped_entry = {**BASE_ENTRY, 'control_resist_pct': -20, 'treatment_resist_pct': 125, 'parts': 1}
        _, [clamped_exp] = scenario_of(clamped_entry)
        self.assertEqual(clamped_exp.model['rates'], {CONTROL: 0.0, TREATMENT: 1.0})
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(clamped_exp), seeded_runs(clamped_exp.model, {CONTROL: 0.0, TREATMENT: 1.0}, 1),
            clamped_exp.model).status, 'ok')

    def test_mutant_wrong_expectation_alerts(self):
        mutant_entry = {**BASE_ENTRY, 'treatment_resist_pct': 30}
        _, [exp] = scenario_of(mutant_entry)
        verdict = offensive_dispel_resist_verdict(base_verdict(exp),
                                                  seeded_runs(exp.model, {CONTROL: 0.0, TREATMENT: 0.2}, 6),
                                                  exp.model)
        self.assertEqual(verdict.status, 'alert')

    def test_alerts_when_treatment_fails_control_leaks_or_clamped_boundary_leaks(self):
        _, [exp] = scenario_of(BASE_ENTRY)
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(exp), seeded_runs(exp.model, {CONTROL: 0.0, TREATMENT: 0.0}, 6), exp.model).status, 'alert')
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(exp), seeded_runs(exp.model, {CONTROL: 0.2, TREATMENT: 0.2}, 6), exp.model).status, 'alert')
        _, [_, gate_exp] = scenario_of(GATED_ENTRY)
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(gate_exp), seeded_runs(gate_exp.model, {CONTROL: 0.0, GATE_OFF: 0.25}, 6),
            gate_exp.model).status, 'alert')
        clamped_entry = {**BASE_ENTRY, 'control_resist_pct': 0, 'treatment_resist_pct': 120, 'parts': 1}
        _, [clamped_exp] = scenario_of(clamped_entry)
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(clamped_exp), seeded_runs(clamped_exp.model, {CONTROL: 0.0, TREATMENT: 0.9}, 1),
            clamped_exp.model).status, 'alert')

    def test_unmeasured_on_missing_read_or_failed_gate_precondition(self):
        _, [exp] = scenario_of(BASE_ENTRY)
        runs = seeded_runs(exp.model, {CONTROL: 0.0, TREATMENT: 0.2}, 6)
        runs[0].values.pop(read_label(exp.model['prefix'], TREATMENT, 1))
        self.assertEqual(offensive_dispel_resist_verdict(base_verdict(exp), runs, exp.model).status, 'unmeasured')

        _, [main_exp, gate_exp] = scenario_of(GATED_ENTRY)
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(main_exp),
            seeded_runs(main_exp.model, {CONTROL: 0.0, TREATMENT: 0.25}, 6, {(TREATMENT, 'after'): 0.0}),
            main_exp.model).status, 'unmeasured')
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(gate_exp),
            seeded_runs(gate_exp.model, {CONTROL: 0.0, GATE_OFF: 0.0}, 6, {(GATE_OFF, 'before'): 1.0}),
            gate_exp.model).status, 'unmeasured')

    def test_refuses_inseparable_rates_clamped_equal_undersized_and_bad_spells(self):
        for bad in (
                {**BASE_ENTRY, 'control_resist_pct': 20, 'treatment_resist_pct': 20},
                {**BASE_ENTRY, 'control_resist_pct': -20, 'treatment_resist_pct': 0},
                {**BASE_ENTRY, 'control_resist_pct': 100, 'treatment_resist_pct': 130},
                {**BASE_ENTRY, 'control_resist_pct': 0, 'treatment_resist_pct': 1.5, 'parts': 1},
                {**BASE_ENTRY, 'control_resist_pct': 20, 'treatment_resist_pct': 23},
                {**BASE_ENTRY, 'control_trials': 1},
                {**BASE_ENTRY, 'control_trials': 5},
                {**BASE_ENTRY, 'trials': 50},
                {**BASE_ENTRY, 'target': 'dummy'},
                {**BASE_ENTRY, 'learn': [804633]},
                {**BASE_ENTRY, 'parts': 1}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                scenario_of(bad)
        for bad_spell in (
                {**BASE_ENTRY, 'buff_spell': 804633},
                {**BASE_ENTRY, 'dispel_spell': 48161}):
            with self.subTest(bad_spell=bad_spell), self.assertRaises(ValueError):
                scenario_of(bad_spell)

    def test_interior_to_interior_rates_separate_cleanly(self):
        entry = {**BASE_ENTRY, 'control_resist_pct': 20, 'treatment_resist_pct': 35, 'parts': 12}
        spec = offensive_dispel_resist_spec(entry)
        trials = arm_trials(spec)
        self.assertGreater(trials[CONTROL], 0)
        self.assertGreater(trials[TREATMENT], 0)
        _, [exp] = scenario_of(entry)
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(exp), seeded_runs(exp.model, {CONTROL: 0.20, TREATMENT: 0.35}, 12), exp.model).status, 'ok')
        self.assertEqual(offensive_dispel_resist_verdict(
            base_verdict(exp), seeded_runs(exp.model, {CONTROL: 0.20, TREATMENT: 0.20}, 12), exp.model).status, 'alert')


if __name__ == '__main__':
    unittest.main()
