import copy
import json
import math
from pathlib import Path
import unittest

from compare import compare
from procs import (PROC_CHECK, PROC_ENERGIZE_CHECK, baseline_attempts, baseline_labels, energize_labels,
                   proc_measurements, proc_plan, proc_scenario)
from profile import DBC_DIR
from test_compare import Workspace, assert_step, constant_reader
from tooltip import Displayed
from triggers import (COOLDOWN_CHECK, COOLDOWN_GATE_CHECK, MINION_COOLDOWN_BAND, TRIGGER_TRIALS, checked_entry,
                      cooldown_gate_label, cooldown_gate_scenario, cooldown_label, cooldown_measurement_labels,
                      cooldown_trial_label, magnitude_measurement_labels, magnitude_ratio_scenario,
                      minion_cooldown_event_label, minion_cooldown_scenario, trigger_scenario)
from values import Expectation

CLASSES_DIR = Path(__file__).resolve().parent / 'classes'
NECROMANCER = json.loads((CLASSES_DIR / 'necromancer.json').read_text(encoding='utf-8'))
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

    def test_pandemic_has_no_settle_step(self):
        entry = necromancer_entry('triggers', PANDEMIC, 'cooldown_delta')
        scenario, _ = minion_cooldown_scenario(NECROMANCER, entry)
        self.assertFalse([step for step in scenario['steps'] if str(step.get('label', '')).endswith(' settle')])


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


if __name__ == '__main__':
    unittest.main()
