import copy
import json
import math
from pathlib import Path
import unittest

from compare import compare
from procs import (EVENTS_BASELINE, PROC_CHECK, PROC_ENERGIZE_CHECK, baseline_attempts, baseline_labels,
                   energize_labels, proc_measurements, proc_plan, proc_scenario, rate_band, residual_sizing)
from profile import DBC_DIR, FIXTURE_CLASSES_DIR
from test_compare import Workspace, assert_step, constant_reader
from tooltip import Displayed
from triggers import (COOLDOWN_CHECK, COOLDOWN_GATE_CHECK, MINION_COOLDOWN_BAND, TRIGGER_TRIALS, checked_entry,
                      cooldown_gate_label, cooldown_gate_scenario, cooldown_label, cooldown_measurement_labels,
                      cooldown_trial_label, magnitude_measurement_labels, magnitude_ratio_scenario,
                      minion_cooldown_event_label, minion_cooldown_scenario, trigger_scenario)
from values import Expectation, Unmodelled

NECROMANCER = json.loads((FIXTURE_CLASSES_DIR / 'necromancer.json').read_text(encoding='utf-8'))
CHOMP = 707283
TOMB_KING = 805044
DEPRAVITY = 638403
PANDEMIC = 560798
OVERWHELMING_FORCE = 531128
GHOUL = 50073
RAISE_GHOUL = 500971
VIRULENCY = 801938
STUDY_OF_DEATH = 704721
UNRELENTING_ARMY = 705747
MUCK_SUMMONER = 806086
LESSER_ZOMBIE = 503031
ROTLING = 50133
WINDOW_MS = 3000
GRANT_CAST = 804191
ANOINTED = 280912


def necromancer_entry(section: str, aura: int, kind: str | None = None) -> dict:
    return next(entry for entry in NECROMANCER[section]
                if entry['aura'] == aura and entry.get('kind') == kind)


def minion_cooldown_model(baseline: int, attempts: int) -> dict:
    return {'part': 0, 'parts': 1, 'scheduled_attempts': attempts, 'part_attempts': attempts,
            'baseline_attempts': baseline, 'attempt_ms': 4000, 'minimum_trials': TRIGGER_TRIALS,
            'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL, 'swing_ms': 2000,
                        'swing_source': 'creature_template'},
            'observe_spell': VIRULENCY, 'observe_metric': 'cooldown_ms', 'expected_delta_ms': 1000,
            'trial_metric': 'owned_creature_damage_count', 'window_ms': WINDOW_MS, 'minion_auras': [],
            'measurements': cooldown_measurement_labels(PANDEMIC)}


def minion_cooldown_steps(baseline_cuts: list[float], measured_cuts: list[float], per_window: int = 2) -> list:
    steps, events = [], 0
    for phase, cuts in (('baseline', baseline_cuts), ('measured', measured_cuts)):
        for index, cut in enumerate(cuts):
            before = 60000.0
            steps.append(assert_step(cooldown_trial_label(PANDEMIC, phase, index, 'before'), str(before)))
            steps.append(assert_step(minion_cooldown_event_label(PANDEMIC, phase, index, 'before'), str(events)))
            steps.append({'action': 'wait', 'label': 'window', 'status': 'completed', 'elapsed_ms': str(WINDOW_MS)})
            events += per_window
            steps.append(assert_step(cooldown_trial_label(PANDEMIC, phase, index, 'after'),
                                     str(before - WINDOW_MS - cut)))
            steps.append(assert_step(minion_cooldown_event_label(PANDEMIC, phase, index, 'after'), str(events)))
    steps.append(assert_step(cooldown_measurement_labels(PANDEMIC)['aura'], '1'))
    return steps


class MinionJudgeTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self, check: str, reader=None):
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=reader or constant_reader())
                    if verdict.check == check]
        self.assertEqual(len(verdicts), 1)
        return verdicts[0]

    def minion_cooldown(self, baseline_cut: float, measured_cut: float):
        expectation = Expectation(cooldown_label(PANDEMIC), COOLDOWN_CHECK, PANDEMIC, PANDEMIC, None, 'Damage',
                                  'rule', minion_cooldown_model(20, TRIGGER_TRIALS))
        self.workspace.scenario('conformance-necromancer-trigger-560798-part-1', 'trigger', [expectation],
                                steps=minion_cooldown_steps([baseline_cut] * 20, [measured_cut] * TRIGGER_TRIALS))
        return self.verdict(COOLDOWN_CHECK)

    def test_minion_cooldown_per_event_reduction_is_ok(self):
        verdict = self.minion_cooldown(0, 2000)
        self.assertEqual(verdict.status, 'ok')
        self.assertLessEqual(abs(verdict.measured - 1000), MINION_COOLDOWN_BAND * 1000)

    def test_minion_cooldown_mutant_with_half_the_reduction_alerts(self):
        self.assertEqual(self.minion_cooldown(0, 1000).status, 'alert')

    def test_minion_cooldown_baseline_reduction_alerts(self):
        verdict = self.minion_cooldown(2000, 2000)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('without the passive', verdict.explanation)

    def cooldown_gate(self, without: int, with_: int):
        model = {'arms': {arm: cooldown_gate_label(PANDEMIC, arm) for arm in ('without', 'with')},
                 'events': {arm: f'{cooldown_gate_label(PANDEMIC, arm)} events' for arm in ('without', 'with')},
                 'primed': {arm: f'{cooldown_gate_label(PANDEMIC, arm)} primed' for arm in ('without', 'with')},
                 'gate_wait_ms': 50000, 'observe_spell': VIRULENCY,
                 'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL},
                 'measurements': cooldown_measurement_labels(PANDEMIC)}
        expectation = Expectation(f'{PANDEMIC} {COOLDOWN_GATE_CHECK}', COOLDOWN_GATE_CHECK, PANDEMIC, PANDEMIC, None,
                                  'Damage', 'rule', model)
        steps = [assert_step(model['primed'][arm], '59994') for arm in ('without', 'with')]
        steps += [assert_step(model['events'][arm], '25') for arm in ('without', 'with')]
        steps += [assert_step(model['arms']['without'], str(without)), assert_step(model['arms']['with'], str(with_)),
                  assert_step(model['measurements']['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-trigger-560798-gate-part-1', 'trigger', [expectation],
                                steps=steps)
        return self.verdict(COOLDOWN_GATE_CHECK)

    def test_cooldown_gate_refused_without_and_cast_with_is_ok(self):
        self.assertEqual(self.cooldown_gate(67, 0).status, 'ok')

    def test_cooldown_gate_mutant_refused_with_the_passive_alerts(self):
        self.assertEqual(self.cooldown_gate(67, 67).status, 'alert')

    def test_cooldown_gate_mutant_cast_without_the_passive_alerts(self):
        self.assertEqual(self.cooldown_gate(0, 0).status, 'alert')

    def proc_model(self, baseline: bool) -> dict:
        labels = proc_measurements(OVERWHELMING_FORCE)
        model = {'part': 0, 'parts': 1, 'chance_pct': 5.0, 'minimum_trials': 504, 'scheduled_attempts': 756,
                 'part_attempts': 756, 'attempt_ms': 2000,
                 'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL}, 'proc_spell': 531129,
                 'event_metric': 'spell_cast_count', 'events_per_proc': 1, 'measurements': labels,
                 'event_labels': [labels['events']], 'exclude_trigger_casts': False,
                 'readings': [{'name': 'triggering hits only', 'labels': [labels['trials']], 'minus_events': False}]}
        if baseline:
            model['baseline'] = {**baseline_labels(OVERWHELMING_FORCE), 'attempts': 90}
        return model

    def proc(self, baseline_events: int):
        labels = proc_measurements(OVERWHELMING_FORCE)
        held = baseline_labels(OVERWHELMING_FORCE)
        expectation = Expectation(f'{OVERWHELMING_FORCE} {PROC_CHECK}', PROC_CHECK, OVERWHELMING_FORCE,
                                  OVERWHELMING_FORCE, None, '$h', 'rule', self.proc_model(True))
        steps = [assert_step(held['trials'], '90'), assert_step(held['events'], str(baseline_events)),
                 assert_step(labels['trials'], '890'), assert_step(labels['attempts'], '890'),
                 assert_step(labels['events'], str(40 + baseline_events)), assert_step(labels['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-proc-531128-part-1', 'proc', [expectation], steps=steps,
                                spell=OVERWHELMING_FORCE, rank=OVERWHELMING_FORCE)
        return self.verdict(PROC_CHECK, constant_reader(Displayed('$h', 5.0, None, 'chance_pct')))

    def test_minion_proc_rate_leaves_the_baseline_out(self):
        verdict = self.proc(0)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 40 / 800)
        self.assertIn('no event in 90 baseline trials', verdict.explanation)

    def test_minion_proc_mutant_firing_without_the_passive_alerts(self):
        verdict = self.proc(3)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('baseline trials without the passive', verdict.explanation)

    def banded_proc(self, procs: int, trials: int):
        labels = proc_measurements(OVERWHELMING_FORCE)
        model = {**self.proc_model(False), 'band': 0.02, 'minimum_trials': 100}
        expectation = Expectation(f'{OVERWHELMING_FORCE} {PROC_CHECK}', PROC_CHECK, OVERWHELMING_FORCE,
                                  OVERWHELMING_FORCE, None, '$h', 'rule', model)
        steps = [assert_step(labels['trials'], str(trials)), assert_step(labels['attempts'], str(trials)),
                 assert_step(labels['events'], str(procs)), assert_step(labels['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-proc-531128-part-1', 'proc', [expectation], steps=steps,
                                spell=OVERWHELMING_FORCE, rank=OVERWHELMING_FORCE)
        return self.verdict(PROC_CHECK, constant_reader(Displayed('$h', 5.0, None, 'chance_pct')))

    def test_banded_proc_inside_the_band_is_ok(self):
        self.assertEqual(self.banded_proc(250, 5000).status, 'ok')

    def test_banded_proc_wider_than_the_band_is_measured_not_final(self):
        verdict = self.banded_proc(40, 800)
        self.assertEqual(verdict.status, 'measured')
        self.assertIn('not final', verdict.explanation)

    def test_banded_proc_mutant_at_half_the_chance_alerts(self):
        self.assertEqual(self.banded_proc(125, 5000).status, 'alert')

    def commanded_proc(self, procs: int, trials: int):
        labels = proc_measurements(OVERWHELMING_FORCE)
        model = {**self.proc_model(False), 'chance_pct': 50.0, 'band': 0.025, 'minimum_trials': 4000,
                 'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL, 'pet_attack': True,
                             'summon_target': 'dummy'}}
        expectation = Expectation(f'{OVERWHELMING_FORCE} {PROC_CHECK}', PROC_CHECK, OVERWHELMING_FORCE,
                                  OVERWHELMING_FORCE, None, '$h', 'rule', model)
        steps = [assert_step(labels['trials'], str(trials)), assert_step(labels['attempts'], str(trials)),
                 assert_step(labels['events'], str(procs)), assert_step(labels['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-proc-531128-part-1', 'proc', [expectation], steps=steps,
                                spell=OVERWHELMING_FORCE, rank=OVERWHELMING_FORCE)
        return self.verdict(PROC_CHECK, constant_reader(Displayed('$h', 50.0, None, 'chance_pct')))

    def test_a_commanded_minion_proc_at_the_stated_chance_is_ok(self):
        self.assertEqual(self.commanded_proc(5000, 10000).status, 'ok')

    def test_a_commanded_minion_proc_mutant_at_half_the_chance_alerts(self):
        self.assertEqual(self.commanded_proc(2500, 10000).status, 'alert')

    def owner_rage_proc(self, procs: int, aura: int):
        labels = proc_measurements(OVERWHELMING_FORCE)
        model = {**self.proc_model(False), 'chance_pct': 50.0, 'band': 0.025, 'minimum_trials': 4000,
                 'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL},
                 'minion_auras': [{'spell': OVERWHELMING_FORCE, 'caster': 'owner', 'source': 'fixture'}]}
        expectation = Expectation(f'{OVERWHELMING_FORCE} {PROC_CHECK}', PROC_CHECK, OVERWHELMING_FORCE,
                                  OVERWHELMING_FORCE, None, '$h', 'rule', model)
        steps = [assert_step(labels['trials'], '10000'), assert_step(labels['attempts'], '10000'),
                 assert_step(labels['events'], str(procs)), assert_step(labels['aura'], str(aura))]
        self.workspace.scenario('conformance-necromancer-proc-531128-part-1', 'proc', [expectation], steps=steps,
                                spell=OVERWHELMING_FORCE, rank=OVERWHELMING_FORCE)
        return self.verdict(PROC_CHECK, constant_reader(Displayed('$h', 50.0, None, 'chance_pct')))

    def test_an_owner_cast_minion_aura_proc_at_the_stated_chance_is_ok(self):
        self.assertEqual(self.owner_rage_proc(5000, 1).status, 'ok')

    def test_an_owner_cast_minion_aura_mutant_that_never_strikes_alerts(self):
        self.assertEqual(self.owner_rage_proc(0, 1).status, 'alert')

    def test_a_minion_aura_without_its_owner_as_caster_is_not_counted(self):
        verdict = self.owner_rage_proc(5000, 0)
        self.assertNotEqual(verdict.status, 'ok')
        self.assertIn(f'aura {OVERWHELMING_FORCE} absent', verdict.explanation)

    def granted_proc(self, procs: int, grant_reads: list[str | None]):
        labels = proc_measurements(OVERWHELMING_FORCE)
        grant_labels = [f'{OVERWHELMING_FORCE} grant {GRANT_CAST} {index}' for index in range(len(grant_reads))]
        model = {**self.proc_model(False), 'chance_pct': 50.0, 'band': 0.025, 'minimum_trials': 4000,
                 'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL},
                 'grants': [{'aura': OVERWHELMING_FORCE, 'cast': GRANT_CAST, 'entry': GHOUL,
                             'labels': grant_labels}]}
        expectation = Expectation(f'{OVERWHELMING_FORCE} {PROC_CHECK}', PROC_CHECK, OVERWHELMING_FORCE,
                                  OVERWHELMING_FORCE, None, '$h', 'rule', model)
        steps = [assert_step(label, read) for label, read in zip(grant_labels, grant_reads) if read is not None]
        steps += [assert_step(labels['trials'], '10000'), assert_step(labels['attempts'], '10000'),
                  assert_step(labels['events'], str(procs)), assert_step(labels['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-proc-531128-part-1', 'proc', [expectation], steps=steps,
                                spell=OVERWHELMING_FORCE, rank=OVERWHELMING_FORCE)
        return self.verdict(PROC_CHECK, constant_reader(Displayed('$h', 50.0, None, 'chance_pct')))

    def test_a_really_granted_minion_aura_proc_at_the_stated_chance_is_ok(self):
        verdict = self.granted_proc(5000, ['1', '1', '1'])
        self.assertEqual(verdict.status, 'ok')
        self.assertIn(f'granted by a real {GRANT_CAST} cast: present after each of the 3 grants', verdict.explanation)
        self.assertNotIn('by harness', verdict.explanation)

    def assert_ungranted(self, reads: list[str], missing: int):
        verdict = self.granted_proc(5000, reads)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('minion aura absent after its real grant', verdict.explanation)
        self.assertIn(f'{missing} of 3 reads at 0 after a {GRANT_CAST} cast', verdict.explanation)
        self.assertIn(f'granted by a real {GRANT_CAST} cast', verdict.explanation)

    def test_a_minion_aura_absent_after_one_real_grant_fails_whatever_the_rate(self):
        self.assert_ungranted(['1', '0', '1'], 1)

    def test_a_minion_aura_never_granted_fails_whatever_the_rate(self):
        self.assert_ungranted(['0', '0', '0'], 3)

    def test_a_missing_grant_read_is_not_counted(self):
        self.assertNotEqual(self.granted_proc(5000, ['1', None, '1']).status, 'ok')

    def residual_proc(self, procs: int, trials: int):
        labels = proc_measurements(OVERWHELMING_FORCE)
        residual = residual_sizing({'aura': OVERWHELMING_FORCE, 'band': True, 'residual_target': 0.001,
                                    'min_detectable': 5.0}, 50.0)
        model = {**self.proc_model(False), 'chance_pct': 50.0, 'band': 0.025, 'residual': residual,
                 'minimum_trials': residual['trials'],
                 'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL}}
        expectation = Expectation(f'{OVERWHELMING_FORCE} {PROC_CHECK}', PROC_CHECK, OVERWHELMING_FORCE,
                                  OVERWHELMING_FORCE, None, '$h', 'rule', model)
        steps = [assert_step(labels['trials'], str(trials)), assert_step(labels['attempts'], str(trials)),
                 assert_step(labels['events'], str(procs)), assert_step(labels['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-proc-531128-part-1', 'proc', [expectation], steps=steps,
                                spell=OVERWHELMING_FORCE, rank=OVERWHELMING_FORCE)
        return self.verdict(PROC_CHECK, constant_reader(Displayed('$h', 50.0, None, 'chance_pct')))

    def test_a_residual_sized_proc_at_the_chance_is_ok_and_states_its_rejection(self):
        verdict = self.residual_proc(10000, 20000)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('Wilson 0.9995 interval', verdict.explanation)
        self.assertRegex(verdict.explanation, r'a deviation of 5 points from the chance rejected with probability '
                                              r'>= (0\.99|1\.0)')
        self.assertNotIn('between-part', verdict.explanation)

    def test_a_residual_sized_proc_mutant_above_by_the_detectable_shift_alerts(self):
        self.assertEqual(self.residual_proc(11000, 20000).status, 'alert')

    def test_a_residual_sized_proc_mutant_below_by_the_detectable_shift_alerts(self):
        self.assertEqual(self.residual_proc(9000, 20000).status, 'alert')

    def test_a_residual_sized_proc_below_its_trials_is_not_judged(self):
        self.assertEqual(self.residual_proc(5000, 10000).status, 'insufficient_trials')

    def energize(self, each: int):
        labels = energize_labels(OVERWHELMING_FORCE, 6)
        model = {'part': 0, 'parts': 1, 'power': 6, 'expected': 20, 'percent_of_max': None, 'measurements': labels}
        expectation = Expectation(f'{OVERWHELMING_FORCE} {PROC_ENERGIZE_CHECK} 6', PROC_ENERGIZE_CHECK,
                                  OVERWHELMING_FORCE, OVERWHELMING_FORCE, None, '20', 'rule', model)
        steps = [assert_step(labels['total'], str(each * 41)), assert_step(labels['count'], '41')]
        self.workspace.scenario('conformance-necromancer-proc-531128-energize', 'proc', [expectation], steps=steps,
                                spell=OVERWHELMING_FORCE, rank=OVERWHELMING_FORCE)
        return self.verdict(PROC_ENERGIZE_CHECK)

    def test_proc_energize_of_the_stated_amount_is_ok(self):
        self.assertEqual(self.energize(20).status, 'ok')

    def test_proc_energize_mutant_of_another_amount_alerts(self):
        self.assertEqual(self.energize(10).status, 'alert')


class MinionPlanTest(unittest.TestCase):
    def test_baseline_attempts_follow_the_stated_chance(self):
        self.assertEqual([baseline_attempts(chance) for chance in (5, 10, 20, 50)], [90, 44, 21, 20])

    def test_a_minion_trigger_needs_its_swing_source(self):
        entry = copy.deepcopy(necromancer_entry('triggers', CHOMP))
        del entry['trigger']['swing_source']
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_minion_auras_need_a_refresh_interval(self):
        entry = copy.deepcopy(necromancer_entry('triggers', CHOMP))
        del entry['minion_aura_refresh_ms']
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_a_minion_magnitude_dummy_aura_is_a_caster_fixture_with_a_refresh(self):
        entry = copy.deepcopy(necromancer_entry('triggers', DEPRAVITY, 'magnitude_ratio'))
        entry['target_auras'] = [{'spell': 560729, 'source': 'debuff fixture'}]
        checked_entry(entry)
        for broken in ({'spell': 560729}, {'spell': 560729, 'source': 'fixture', 'amount': 1}):
            with self.subTest(broken=broken), self.assertRaises(ValueError):
                checked_entry({**entry, 'target_auras': [broken]})
        del entry['minion_auras']
        del entry['minion_aura_refresh_ms']
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_minion_command_options_take_their_documented_values_only(self):
        entry = copy.deepcopy(necromancer_entry('triggers', CHOMP))
        for changes in ({'pet_attack': True}, {'pet_attack': False}, {'summon_target': 'dummy'},
                        {'summon_target': 'caster'}):
            with self.subTest(changes=changes):
                checked_entry({**entry, 'trigger': {**entry['trigger'], **changes}})
        for changes in ({'pet_attack': 'yes'}, {'pet_attack': 1}, {'summon_target': 'self'},
                        {'summon_target': None}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                checked_entry({**entry, 'trigger': {**entry['trigger'], **changes}})

    def test_a_minion_aura_caster_is_the_owner_or_absent(self):
        entry = copy.deepcopy(necromancer_entry('triggers', CHOMP))
        fixture = entry['minion_auras'][0]
        checked_entry({**entry, 'minion_auras': [{**fixture, 'caster': 'owner'}]})
        for caster in ('caster', 'minion', None, True):
            with self.subTest(caster=caster), self.assertRaises(ValueError):
                checked_entry({**entry, 'minion_auras': [{**fixture, 'caster': caster}]})

    def residual_force(self, **options) -> dict:
        entry = copy.deepcopy(necromancer_entry('procs', OVERWHELMING_FORCE))
        chance = proc_plan(NECROMANCER, entry).chance_pct
        return {**entry, 'residual_target': 0.001, 'min_detectable': 2 * rate_band(chance / 100) * 100, **options}

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_residual_target_under_sized_plan_fails_with_its_attempt_count(self):
        entry = self.residual_force()
        chance = proc_plan(NECROMANCER, copy.deepcopy(necromancer_entry('procs', OVERWHELMING_FORCE))).chance_pct
        needed = residual_sizing(entry, chance)['attempts']
        with self.assertRaisesRegex(ValueError, f'under-sized for residual_target 0.001: needs {needed} attempts'):
            proc_plan(NECROMANCER, entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_residual_target_sized_by_its_parts_plans_and_models_the_confidence(self):
        entry = self.residual_force()
        plain = proc_plan(NECROMANCER, copy.deepcopy(necromancer_entry('procs', OVERWHELMING_FORCE)))
        residual = residual_sizing(entry, plain.chance_pct)
        sized = {**entry, 'min_parts': math.ceil(residual['attempts'] / plain.per_part)}
        plan = proc_plan(NECROMANCER, sized)
        self.assertGreaterEqual(plan.scheduled, residual['attempts'])
        scenario, expectations = proc_scenario(NECROMANCER, sized)
        model = expectations[0].model
        self.assertEqual(model['residual'], residual)
        self.assertEqual(model['minimum_trials'], max(plain.needed, residual['trials']))
        self.assertAlmostEqual(residual['confidence'], 0.9995)
        self.assertIn('residual_target 0.001 per pair', expectations[0].rule)
        _, plain_expectations = proc_scenario(NECROMANCER, copy.deepcopy(necromancer_entry('procs',
                                                                                           OVERWHELMING_FORCE)))
        self.assertNotIn('residual', plain_expectations[0].model)
        self.assertNotIn('residual_target', plain_expectations[0].rule)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_residual_target_needs_a_band_and_a_shift_outside_it(self):
        entry = self.residual_force()
        for broken in ({'band': False}, {'residual_target': 0}, {'residual_target': 1.5}, {'residual_target': True},
                       {'min_detectable': None}, {'min_detectable': 0.5}):
            with self.subTest(broken=broken), self.assertRaises(ValueError):
                proc_plan(NECROMANCER, {**entry, **broken})

    def test_a_minion_magnitude_count_is_one_its_trigger_metric_allows(self):
        entry = copy.deepcopy(necromancer_entry('triggers', DEPRAVITY, 'magnitude_ratio'))
        checked_entry(entry)
        entry['trigger_count_metric'] = 'pet_melee_swings'
        with self.assertRaises(ValueError):
            checked_entry(entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MinionScenarioTest(unittest.TestCase):
    def test_a_minion_magnitude_counts_the_melee_outcome_its_entry_names(self):
        for aura, count in ((TOMB_KING, 'pet_melee_hits'), (DEPRAVITY, 'pet_melee_crits')):
            scenario, _ = magnitude_ratio_scenario(NECROMANCER, necromancer_entry('triggers', aura, 'magnitude_ratio'))
            label = magnitude_measurement_labels(aura)['trigger_count']
            step = next(step for step in scenario['steps'] if step.get('label') == label)
            self.assertEqual((step['metric'], step['entry']), (count, GHOUL))

    def test_a_minion_magnitude_refreshes_its_dummy_aura_from_the_caster_each_window(self):
        entry = copy.deepcopy(necromancer_entry('triggers', DEPRAVITY, 'magnitude_ratio'))
        entry['target_auras'] = [{'spell': 560729, 'source': 'debuff fixture'}]
        scenario, [expectation] = magnitude_ratio_scenario(NECROMANCER, entry)
        held = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step.get('target') == 'dummy']
        windows = [step for step in scenario['steps'] if step.get('label', '').endswith('minion swings')]
        self.assertEqual(len(held), 2 * len(windows))
        self.assertEqual({(step['spell'], step['caster']) for step in held}, {(560729, 'caster')})
        self.assertEqual([step['stacks'] for step in held[:2]], [0, 1])
        self.assertIn('dummy aura 560729 from the caster', expectation.rule)

    def test_a_minion_magnitude_without_dummy_auras_sets_none(self):
        scenario, _ = magnitude_ratio_scenario(NECROMANCER, necromancer_entry('triggers', DEPRAVITY, 'magnitude_ratio'))
        self.assertFalse([step for step in scenario['steps'] if step.get('target') == 'dummy'
                          and step['action'] == 'set_aura'])

    def test_chomp_raises_its_minion_and_refreshes_the_crit_fixture_by_remove_and_add(self):
        scenario, expectations = trigger_scenario(NECROMANCER, necromancer_entry('triggers', CHOMP))
        steps = scenario['steps']
        raised = next(step for step in steps if step.get('metric') == 'owned_creature_count')
        self.assertEqual((raised['entry'], raised['equals']), (50068, 1))
        fixtures = [step for step in steps if step['action'] == 'set_aura']
        self.assertEqual([fixture['stacks'] for fixture in fixtures[:2]], [0, 1])
        self.assertEqual(fixtures[1]['amount'], 100)
        trials = next(step for step in steps if step.get('label') == f'{CHOMP} trigger trials')
        self.assertEqual((trials['metric'], trials['entry']), ('pet_melee_crits', 50068))
        events = next(step for step in steps if step.get('label') == f'{CHOMP} trigger events')
        self.assertEqual((events['metric'], events['spell'], events['entry']), ('spell_damage_count', 707284, 50068))
        self.assertEqual(expectations[0].model['trigger']['action'], 'minion')

    def test_pandemic_windows_read_the_cooldown_and_the_minion_events(self):
        entry = necromancer_entry('triggers', PANDEMIC, 'cooldown_delta')
        scenario, _ = minion_cooldown_scenario(NECROMANCER, entry)
        labels = [step.get('label') for step in scenario['steps']]
        self.assertIn(cooldown_trial_label(PANDEMIC, 'baseline', 0, 'before'), labels)
        self.assertIn(minion_cooldown_event_label(PANDEMIC, 'measured', 0, 'after'), labels)
        cleared = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == 803782]
        self.assertTrue(cleared and all(step['stacks'] == 0 for step in cleared))

    def test_pandemic_gate_attempts_virulency_in_both_arms(self):
        entry = necromancer_entry('triggers', PANDEMIC, 'cooldown_gate')
        scenario, expectations = cooldown_gate_scenario(NECROMANCER, entry)
        reads = [step for step in scenario['steps'] if step.get('metric') == 'cast_failure']
        self.assertEqual([read['label'] for read in reads],
                         [cooldown_gate_label(PANDEMIC, 'without'), cooldown_gate_label(PANDEMIC, 'with')])
        self.assertEqual(expectations[0].check, COOLDOWN_GATE_CHECK)

    def test_overwhelming_force_proc_reads_its_baseline_and_energize_amounts(self):
        entry = necromancer_entry('procs', OVERWHELMING_FORCE)
        plan = proc_plan(NECROMANCER, entry)
        scenario, expectations = proc_scenario(NECROMANCER, entry)
        labels = {step.get('label') for step in scenario['steps']}
        self.assertTrue(set(baseline_labels(OVERWHELMING_FORCE).values()) <= labels)
        self.assertEqual({expectation.check for expectation in expectations}, {PROC_CHECK, PROC_ENERGIZE_CHECK})
        self.assertEqual(expectations[0].model['baseline']['attempts'], baseline_attempts(plan.chance_pct))

    def commanded_force(self, **options) -> list[dict]:
        entry = copy.deepcopy(necromancer_entry('procs', OVERWHELMING_FORCE))
        entry['trigger'].update(options)
        scenario, expectations = proc_scenario(NECROMANCER, entry)
        return scenario['steps'], expectations

    def test_a_pet_attack_command_follows_each_caster_attack_only_when_asked(self):
        steps, expectations = self.commanded_force(pet_attack=True)
        attacks = [index for index, step in enumerate(steps) if step == {'action': 'attack', 'actor': 'caster',
                                                                          'target': 'dummy'}]
        self.assertTrue(attacks)
        for index in attacks:
            self.assertEqual(steps[index + 1], {'action': 'attack', 'actor': 'caster', 'target': 'dummy', 'pet': True})
        self.assertIn('commands its pet to attack the dummy', expectations[0].rule)
        plain, plain_expectations = self.commanded_force()
        self.assertFalse([step for step in plain if step.get('pet')])
        self.assertNotIn('commands its pet', plain_expectations[0].rule)

    def test_a_dummy_summon_target_casts_the_raise_at_the_dummy_only_when_asked(self):
        def raise_cast(steps: list[dict]) -> dict:
            return next(step for step in steps if step['action'] == 'cast' and step['spell'] == RAISE_GHOUL)
        steps, expectations = self.commanded_force(summon_target='dummy')
        self.assertEqual(raise_cast(steps)['target'], 'dummy')
        self.assertIn(f'{RAISE_GHOUL} is cast at the dummy', expectations[0].rule)
        for options in ({}, {'summon_target': 'caster'}):
            with self.subTest(options=options):
                steps, expectations = self.commanded_force(**options)
                self.assertNotIn('target', raise_cast(steps))
                self.assertNotIn('is cast at the dummy', expectations[0].rule)

    def test_an_owner_minion_aura_is_set_and_removed_with_the_caster_only_when_asked(self):
        entry = copy.deepcopy(necromancer_entry('procs', OVERWHELMING_FORCE))
        entry['minion_aura_refresh_ms'] = 8000
        fixture = {'spell': 280912, 'source': 'fixture'}
        for fixtures, caster in (([{**fixture, 'caster': 'owner'}], {'caster': 'caster'}), ([fixture], {})):
            with self.subTest(fixtures=fixtures):
                scenario, _ = proc_scenario(NECROMANCER, {**entry, 'minion_auras': fixtures})
                held = [step for step in scenario['steps'] if step['action'] == 'set_aura'
                        and step.get('owned_entry') == GHOUL and step['spell'] == 280912]
                self.assertEqual({step['stacks'] for step in held}, {0, 1})
                for step in held:
                    self.assertEqual({key: step[key] for key in step if key == 'caster'}, caster)

    def test_study_of_death_windows_open_after_the_settle(self):
        entry = necromancer_entry('triggers', STUDY_OF_DEATH, 'cooldown_delta')
        scenario, expectations = minion_cooldown_scenario(NECROMANCER, entry)
        steps = scenario['steps']
        before = [index for index, step in enumerate(steps)
                  if step.get('label') == cooldown_trial_label(STUDY_OF_DEATH, 'measured', 0, 'before')][0]
        settle = steps[before - 1]
        self.assertEqual((settle['action'], settle['label'], settle['ms']), ('wait', 'measured settle', 17000))
        cast = max(index for index, step in enumerate(steps[:before]) if step['action'] == 'cast')
        self.assertEqual(steps[cast]['spell'], 805029)
        self.assertFalse([step for step in steps[cast + 1:before - 1] if step['action'] != 'wait'])
        self.assertEqual(expectations[0].model['attempt_ms'], 2 * 500 + 3000 + 17000)
        self.assertIn('17000 ms after the cast', expectations[0].rule)

    def test_a_negative_settle_is_refused(self):
        entry = {**necromancer_entry('triggers', STUDY_OF_DEATH, 'cooldown_delta'), 'observe_settle_ms': -1}
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def granted_force(self, **fixture_options) -> tuple[dict, list]:
        entry = copy.deepcopy(necromancer_entry('procs', OVERWHELMING_FORCE))
        entry['minion_aura_refresh_ms'] = 8000
        entry['caster_power'] = {'power': 1, 'value': 400, 'source': 'fixture'}
        fixture = {'spell': ANOINTED, 'caster': 'owner', 'source': 'fixture', **fixture_options}
        return proc_scenario(NECROMANCER, {**entry, 'minion_auras': [fixture]})

    def test_a_granted_minion_aura_is_cast_for_real_instead_of_set(self):
        scenario, expectations = self.granted_force(grant_cast=GRANT_CAST)
        expectation = next(expectation for expectation in expectations if expectation.check == PROC_CHECK)
        steps = scenario['steps']
        self.assertFalse([step for step in steps if step['action'] == 'set_aura' and step['spell'] == ANOINTED])
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == GRANT_CAST]
        grants = expectation.model['grants']
        self.assertEqual([(grant['aura'], grant['cast'], grant['entry']) for grant in grants],
                         [(ANOINTED, GRANT_CAST, GHOUL)])
        self.assertEqual(len(casts), len(grants[0]['labels']))
        self.assertGreater(len(casts), 1)
        self.assertEqual(len(set(grants[0]['labels'])), len(casts))
        for index in casts:
            self.assertEqual(steps[index]['target'], 'dummy')
            self.assertEqual([step['action'] for step in steps[index - 2:index]], ['set_power', 'reset_cooldown'])
            self.assertEqual(steps[index - 2]['value'], 400)
            read = steps[index + 2]
            self.assertIn(read['label'], grants[0]['labels'])
            self.assertEqual((read['metric'], read['entry'], read['spell'], read['caster']),
                             ('owned_creature_count', GHOUL, ANOINTED, 'caster'))
        self.assertIn(f'granted every 8000 ms by a real {GRANT_CAST} cast', expectation.rule)
        self.assertNotIn(f'minion aura {ANOINTED} set every', expectation.rule)

    def test_a_granted_minion_aura_keeps_the_swing_time_of_the_set_one(self):
        def swing_ms(scenario):
            return sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait'
                       and ('minion swings' in step.get('label', '') or ' read' in step.get('label', '')))
        self.assertEqual(swing_ms(self.granted_force(grant_cast=GRANT_CAST)[0]), swing_ms(self.granted_force()[0]))

    def test_a_granted_minion_aura_is_refused_with_a_set_aura_or_an_amount(self):
        entry = copy.deepcopy(necromancer_entry('procs', OVERWHELMING_FORCE))
        entry['minion_aura_refresh_ms'] = 8000
        granted = {'spell': ANOINTED, 'source': 'fixture', 'grant_cast': GRANT_CAST}
        for auras in ([granted, {'spell': ANOINTED, 'source': 'fixture'}], [{**granted, 'amount': 100}],
                      [{**granted, 'grant_cast': 0}], [{**granted, 'grant_cast': True}],
                      [{**granted, 'grant_cast': '804191'}]):
            with self.subTest(auras=auras), self.assertRaises(ValueError):
                proc_plan(NECROMANCER, {**entry, 'minion_auras': auras})
        with self.assertRaises(ValueError):
            proc_plan(NECROMANCER, {**entry, 'minion_auras': [granted], 'minion_aura_refresh_ms': 500})
        proc_plan(NECROMANCER, {**entry, 'minion_auras': [granted]})

    def test_a_trigger_entry_refuses_a_granted_minion_aura(self):
        entry = copy.deepcopy(necromancer_entry('triggers', CHOMP))
        fixture = {**entry['minion_auras'][0], 'grant_cast': GRANT_CAST}
        fixture.pop('amount', None)
        with self.assertRaises(ValueError):
            checked_entry({**entry, 'minion_auras': [fixture]})

    def test_pandemic_has_no_settle_step(self):
        entry = necromancer_entry('triggers', PANDEMIC, 'cooldown_delta')
        scenario, _ = minion_cooldown_scenario(NECROMANCER, entry)
        self.assertFalse([step for step in scenario['steps'] if str(step.get('label', '')).endswith(' settle')])


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class SummonProcTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def test_summon_proc_counts_summons_of_its_creature(self):
        scenario, _ = proc_scenario(NECROMANCER, necromancer_entry('procs', UNRELENTING_ARMY))
        reads = [step for step in scenario['steps'] if step.get('metric') == 'owned_creature_summon_count']
        self.assertEqual([read['label'] for read in reads],
                         [baseline_labels(UNRELENTING_ARMY)['events'], proc_measurements(UNRELENTING_ARMY)['events']])
        self.assertTrue(all(read['entry'] == LESSER_ZOMBIE for read in reads))

    def test_cast_baseline_runs_before_the_passive_is_learned(self):
        scenario, expectations = proc_scenario(NECROMANCER, necromancer_entry('procs', UNRELENTING_ARMY))
        steps = scenario['steps']
        learned = next(index for index, step in enumerate(steps)
                       if step['action'] == 'learn' and step['spell'] == UNRELENTING_ARMY)
        held = next(index for index, step in enumerate(steps)
                    if step.get('label') == baseline_labels(UNRELENTING_ARMY)['events'])
        self.assertLess(held, learned)
        self.assertEqual(expectations[0].model['baseline']['attempts'], baseline_attempts(20.0))

    def test_later_parts_have_no_baseline(self):
        scenario, expectations = proc_scenario(NECROMANCER, necromancer_entry('procs', UNRELENTING_ARMY), 1)
        self.assertNotIn('baseline', expectations[0].model)

    def test_trials_per_attempt_divides_the_scheduled_casts(self):
        entry = necromancer_entry('procs', UNRELENTING_ARMY)
        single = proc_plan(NECROMANCER, {**entry, 'trials_per_attempt': 1})
        double = proc_plan(NECROMANCER, entry)
        self.assertEqual(double.scheduled, math.ceil(single.scheduled / 2))
        with self.assertRaises(ValueError):
            proc_plan(NECROMANCER, {**entry, 'trials_per_attempt': 0})

    def test_summon_proc_needs_a_cast_trigger_and_an_entry(self):
        entry = necromancer_entry('procs', MUCK_SUMMONER)
        with self.assertRaises(ValueError):
            proc_plan(NECROMANCER, {**entry, 'event_entry': 0})
        with self.assertRaises(ValueError):
            proc_plan(NECROMANCER, {**entry, 'trigger': {'action': 'minion', 'spell': RAISE_GHOUL, 'entry': GHOUL,
                                                          'swing_ms': 2000, 'swing_source': 'creature_template'}})

    def rotlings(self, baseline_events: int, events: int, per_proc: int = 2):
        entry = {**necromancer_entry('procs', MUCK_SUMMONER), 'events_per_proc': per_proc}
        _, expectations = proc_scenario(NECROMANCER, entry)
        expectation = expectations[0]
        model = {**expectation.model, 'parts': 1}
        labels, held = proc_measurements(MUCK_SUMMONER), baseline_labels(MUCK_SUMMONER)
        steps = [assert_step(held['trials'], '90'), assert_step(held['events'], str(baseline_events)),
                 assert_step(labels['trials'], '3290'), assert_step(labels['attempts'], '3290'),
                 assert_step(labels['events'], str(events + baseline_events)), assert_step(labels['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-proc-806086-part-1', 'proc',
                                [replace_model(expectation, model)], steps=steps, spell=MUCK_SUMMONER,
                                rank=MUCK_SUMMONER)
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results,
                                                   tooltips=constant_reader(Displayed('$h', 5.0, None, 'chance_pct')))
                    if verdict.check == PROC_CHECK]
        self.assertEqual(len(verdicts), 1)
        return verdicts[0]

    def test_rotling_summons_two_per_proc_at_the_chance_is_ok(self):
        verdict = self.rotlings(0, 320)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 160 / 3200)

    def test_rotling_mutant_counting_each_summon_as_a_proc_alerts(self):
        self.assertEqual(self.rotlings(0, 320, per_proc=1).status, 'alert')

    def test_rotling_mutant_summoning_without_the_passive_alerts(self):
        self.assertEqual(self.rotlings(2, 320).status, 'alert')


def replace_model(expectation: Expectation, model: dict) -> Expectation:
    return Expectation(expectation.label, expectation.check, expectation.spell_id, expectation.rank_id,
                       expectation.effect_index, expectation.displayed, expectation.rule, model)



SELF_CAST_SUMMON = 807933
OWN_SUMMONS_CHANCE_PCT = 5.0
OWN_SUMMONS_BASELINE_CASTS = baseline_attempts(OWN_SUMMONS_CHANCE_PCT)
OWN_SUMMONS_TREATMENT_CASTS = 3200
OWN_SUMMONS_PROCS = 160
OWN_SUMMONS_HELD = 2 * OWN_SUMMONS_BASELINE_CASTS
OWN_SUMMONS_WITH = 2 * OWN_SUMMONS_TREATMENT_CASTS + OWN_SUMMONS_PROCS


def muck_summoner() -> dict:
    return necromancer_entry('procs', MUCK_SUMMONER)


def own_summons_entry(per_attempt: int = 2) -> dict:
    return {**muck_summoner(), 'trial_casts': True, 'events_per_proc': 1, EVENTS_BASELINE: per_attempt}


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class OwnSummonsPlanTest(unittest.TestCase):
    def test_an_entry_without_the_field_keeps_its_model_and_rule(self):
        _, plain = proc_scenario(NECROMANCER, muck_summoner())
        self.assertNotIn(EVENTS_BASELINE, plain[0].model)
        self.assertNotIn('by itself', plain[0].rule)

    def test_the_field_reaches_the_model_and_the_rule(self):
        _, expectations = proc_scenario(NECROMANCER, own_summons_entry())
        self.assertEqual(expectations[0].model[EVENTS_BASELINE], 2)
        self.assertIn('must read exactly 2 per completed cast', expectations[0].rule)

    def test_the_field_needs_a_whole_positive_count_and_cast_trials(self):
        for value in (0, -1, True, 1.5):
            with self.assertRaises(ValueError):
                proc_plan(NECROMANCER, own_summons_entry(value))
        for removed in ('trial_casts', 'baseline'):
            entry = own_summons_entry()
            del entry[removed]
            with self.assertRaises(ValueError):
                proc_plan(NECROMANCER, entry)
        with self.assertRaises(ValueError):
            proc_plan(NECROMANCER, {**own_summons_entry(), 'event_metric': 'spell_cast_count'})

    def test_a_self_cast_trigger_is_accepted_only_with_the_field(self):
        trigger = {'action': 'cast', 'spell': SELF_CAST_SUMMON}
        plan = proc_plan(NECROMANCER, {**own_summons_entry(), 'trigger': trigger})
        self.assertGreater(plan.scheduled, 0)
        with self.assertRaises(Unmodelled):
            proc_plan(NECROMANCER, {**muck_summoner(), 'trigger': trigger})
        with self.assertRaises(Unmodelled):
            proc_plan(NECROMANCER, {**muck_summoner(), 'trigger': trigger, 'trial_casts': True})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class OwnSummonsJudgeTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def judged(self, baseline_events: int, treatment_events: int, per_attempt: int = 2,
               baseline_casts: int = OWN_SUMMONS_BASELINE_CASTS):
        _, expectations = proc_scenario(NECROMANCER, own_summons_entry(per_attempt))
        expectation = expectations[0]
        model = {**expectation.model, 'parts': 1}
        labels, held = proc_measurements(MUCK_SUMMONER), baseline_labels(MUCK_SUMMONER)
        casts = baseline_casts + OWN_SUMMONS_TREATMENT_CASTS
        steps = [assert_step(held['trials'], str(baseline_casts)), assert_step(held['events'], str(baseline_events)),
                 assert_step(labels['trials'], str(casts)), assert_step(labels['attempts'], str(casts)),
                 assert_step(labels['events'], str(baseline_events + treatment_events)),
                 assert_step(labels['aura'], '1')]
        self.workspace.scenario('conformance-necromancer-proc-806086-part-1', 'proc',
                                [replace_model(expectation, model)], steps=steps, spell=MUCK_SUMMONER,
                                rank=MUCK_SUMMONER)
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=constant_reader(
            Displayed('$h', OWN_SUMMONS_CHANCE_PCT, None, 'chance_pct'))) if verdict.check == PROC_CHECK]
        self.assertEqual(len(verdicts), 1)
        return verdicts[0]

    def test_two_own_summons_per_cast_are_subtracted_and_the_extra_rate_is_ok(self):
        verdict = self.judged(OWN_SUMMONS_HELD, OWN_SUMMONS_WITH)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertAlmostEqual(verdict.measured, OWN_SUMMONS_PROCS / OWN_SUMMONS_TREATMENT_CASTS)
        self.assertIn('exactly 2 events per completed cast', verdict.explanation)

    def test_mutant_baseline_of_one_per_cast_alerts(self):
        verdict = self.judged(OWN_SUMMONS_HELD, OWN_SUMMONS_WITH, per_attempt=1)
        self.assertEqual(verdict.status, 'alert')

    def test_mutant_extra_summon_in_the_control_arm_alerts(self):
        verdict = self.judged(OWN_SUMMONS_HELD + 1, OWN_SUMMONS_WITH)
        self.assertEqual(verdict.status, 'alert')

    def test_an_empty_control_arm_leaves_the_rate_unmeasured(self):
        verdict = self.judged(0, OWN_SUMMONS_WITH, baseline_casts=0)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_fewer_own_summons_than_subtracted_with_the_passive_alerts(self):
        verdict = self.judged(OWN_SUMMONS_HELD, 2 * OWN_SUMMONS_TREATMENT_CASTS - 10)
        self.assertEqual(verdict.status, 'alert')


if __name__ == '__main__':
    unittest.main()
