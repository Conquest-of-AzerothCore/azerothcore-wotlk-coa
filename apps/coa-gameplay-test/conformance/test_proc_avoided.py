import copy
from pathlib import Path
import sys
import unittest

from procs import PROC_CHECK, entry_proc_label, proc_plan, proc_scenario, shares_aura
from profile import DBC_DIR
from test_compare import Workspace, assert_step, constant_reader
from tooltip import Displayed

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

DAWN_KNIGHT = 680497
VENGEFUL_INTENT = 705534


def chance_reader(value: float, text: str):
    return constant_reader(Displayed(text, value, None, 'chance_pct'))


def class_file() -> dict:
    from profile import load_class_file
    return load_class_file(15)


def avoided_entry(source: dict, aura: int) -> dict:
    return copy.deepcopy(next(entry for entry in source['procs']
                              if entry['aura'] == aura and entry['trigger']['action'] == 'avoided'))


def index_of(steps: list[dict], test) -> int:
    return next(position for position, step in enumerate(steps) if test(step))


def last_index_of(steps: list[dict], test) -> int:
    return max(position for position, step in enumerate(steps) if test(step))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedProcScenarioTest(unittest.TestCase):
    def setUp(self):
        from profile import for_entry
        self.class_file = for_entry(class_file(), DAWN_KNIGHT)
        self.entry = avoided_entry(self.class_file, DAWN_KNIGHT)

    def test_the_strikers_engage_before_the_learn_and_the_guards_hold_before_the_reads(self):
        scenario, [expectation] = proc_scenario(self.class_file, self.entry)
        run.validate(scenario)
        steps = scenario['steps']
        strikers = [creature['id'] for creature in scenario['creatures']]
        self.assertEqual(len(strikers), 10)
        self.assertTrue(all(creature['reaction'] == 2 and creature['stationary'] for creature in scenario['creatures']))
        rooted = {step['target'] for step in steps if step['action'] == 'set_aura' and step.get('spell') == 42716
                  and step.get('caster') == step.get('target')}
        self.assertEqual(rooted, set(strikers))
        learn = index_of(steps, lambda step: step['action'] == 'learn' and step.get('spell') == DAWN_KNIGHT)
        engages = [index_of(steps, lambda step, striker=striker: step['action'] == 'attack'
                            and step.get('target') == striker) for striker in strikers]
        last_stop = last_index_of(steps, lambda step: step['action'] == 'stop_attack')
        snapshots = [position for position, step in enumerate(steps) if step['action'] == 'snapshot']
        guards = [position for position, step in enumerate(steps) if 'relative_to' in step]
        trials = index_of(steps, lambda step: step.get('label') == f'{DAWN_KNIGHT} proc trials')
        self.assertLess(max(engages), last_stop)
        self.assertLess(last_stop, min(snapshots))
        self.assertLess(max(snapshots), learn)
        self.assertEqual(len(guards), 3)
        self.assertLess(learn, min(guards))
        self.assertLess(max(guards), trials)
        self.assertTrue(all(steps[position]['equals'] == 0 for position in guards))
        self.assertEqual({steps[position]['metric'] for position in guards},
                         {'melee_attacks_taken', 'melee_attack_count'})
        self.assertFalse([step for step in steps[learn:] if step['action'] == 'attack'])
        windows = [position for position, step in enumerate(steps) if step['action'] == 'wait' and 'label' not in step]
        self.assertTrue(windows)
        for position in windows:
            self.assertEqual(steps[position - 1], {'action': 'set_combat_avoidance', 'actor': 'caster',
                                                   'dodge': 50, 'parry': 50})

    def test_the_reading_sums_dodged_and_parried_swings_and_the_baseline_holds_both(self):
        _, [expectation] = proc_scenario(self.class_file, self.entry, 1)
        model = expectation.model
        self.assertEqual(expectation.label, f'{DAWN_KNIGHT} proc_rate avoided')
        self.assertEqual(model['readings'], [{'name': 'avoided swings (dodged + parried)',
                                              'labels': [f'{DAWN_KNIGHT} proc trials',
                                                         f'{DAWN_KNIGHT} proc trials parried'],
                                              'minus_events': False}])
        self.assertEqual(model['baseline']['added_trials'],
                         {f'{DAWN_KNIGHT} proc trials parried': f'{DAWN_KNIGHT} proc baseline trials parried'})
        self.assertEqual(model['baseline']['attempts'], 0)

    def test_the_d261_sizing_reaches_the_residual_trials(self):
        plan = proc_plan(self.class_file, self.entry)
        _, [expectation] = proc_scenario(self.class_file, self.entry)
        residual = expectation.model['residual']
        self.assertEqual(residual['trials'], 29078)
        self.assertGreaterEqual(plan.parts * plan.per_part * 10, residual['attempts'])

    def test_a_faulty_trigger_is_refused(self):
        trigger = self.entry['trigger']
        for change in ({'dodge': 50, 'parry': 40}, {'dodge': -10, 'parry': 110}, {'strikers': 0}, {'strikers': 11},
                       {'strikers': True}, {'swing_ms': 0}, {'striker_entry': 0}, {'spell': 41394},
                       {'striker_auras': [0]}, {'striker_auras': 42716}, {'striker_auras': [True]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                proc_plan(self.class_file, {**self.entry, 'trigger': {**trigger, **change}})
        for change in ({'trials_per_attempt': 2}, {'trial_readings': [{'name': 'own'}]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                proc_plan(self.class_file, {**self.entry, **change})

    def test_an_internal_cooldown_is_unmodelled(self):
        from hits import Unmodelled
        with self.assertRaises(Unmodelled):
            proc_plan(self.class_file, {**self.entry, 'internal_cooldown_ms': 1000})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedProcLabelTest(unittest.TestCase):
    def test_the_taken_hit_sibling_keeps_its_label_beside_the_avoided_entry(self):
        source = class_file()
        taken = next(entry for entry in source['procs']
                     if entry['aura'] == VENGEFUL_INTENT and entry['trigger']['action'] == 'taken_hit')
        avoided = avoided_entry(source, VENGEFUL_INTENT)
        self.assertFalse(shares_aura(source, taken))
        self.assertEqual(entry_proc_label(source, taken), f'{VENGEFUL_INTENT} proc_rate')
        self.assertEqual(entry_proc_label(source, avoided), f'{VENGEFUL_INTENT} proc_rate avoided')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedProcJudgeTest(unittest.TestCase):
    ENGAGE_DODGED, ENGAGE_PARRIED = 40, 35
    FIXTURE_SIZING = ('residual_target', 'min_detectable', 'min_parts')

    def setUp(self):
        from profile import for_entry
        self.workspace = Workspace()
        self.class_file = copy.deepcopy(for_entry(class_file(), VENGEFUL_INTENT))
        self.entry = next(entry for entry in self.class_file['procs']
                          if entry['aura'] == VENGEFUL_INTENT and entry['trigger']['action'] == 'avoided')
        for sizing in self.FIXTURE_SIZING:
            self.entry.pop(sizing, None)

    def tearDown(self):
        self.workspace.close()

    def verdict(self, dodged: int, parried: int, procs_on_dodges: int, procs_on_parries: int):
        from compare import compare
        plan = proc_plan(self.class_file, self.entry)
        dodged, parried = dodged // plan.parts, parried // plan.parts
        procs_on_dodges, procs_on_parries = procs_on_dodges // plan.parts, procs_on_parries // plan.parts
        for part in range(plan.parts):
            _, [expectation] = proc_scenario(self.class_file, self.entry, part)
            labels, baseline = expectation.model['measurements'], expectation.model['baseline']
            steps = [assert_step(baseline['trials'], str(self.ENGAGE_DODGED)),
                     assert_step(f'{baseline["trials"]} parried', str(self.ENGAGE_PARRIED)),
                     assert_step(baseline['events'], '0'),
                     assert_step(labels['aura'], '1'),
                     assert_step(labels['trials'], str(self.ENGAGE_DODGED + dodged)),
                     assert_step(f'{labels["trials"]} parried', str(self.ENGAGE_PARRIED + parried)),
                     assert_step(labels['attempts'], str(self.ENGAGE_DODGED + self.ENGAGE_PARRIED + dodged + parried)),
                     assert_step(labels['events'], str(procs_on_dodges + procs_on_parries))]
            self.workspace.scenario(f'conformance-witch-hunter-proc-{VENGEFUL_INTENT}-avoided-part-{part + 1}',
                                    'proc', [expectation], steps=steps, spell=VENGEFUL_INTENT, rank=VENGEFUL_INTENT)
        manifest, results = self.workspace.manifest()
        [verdict] = [verdict for verdict in compare(manifest, results, tooltips=chance_reader(10.0, '$h'))
                     if verdict.check == PROC_CHECK]
        return verdict

    def test_procs_on_dodges_and_parries_at_the_stated_chance_pass(self):
        verdict = self.verdict(4000, 4000, 400, 400)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.10)
        self.assertIn('8000 trials', verdict.explanation)

    def test_a_mutant_that_procs_on_dodges_only_alerts(self):
        verdict = self.verdict(4000, 4000, 400, 0)
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 0.05)

    def test_an_engage_proc_before_the_learn_alerts(self):
        from compare import compare
        self.assertEqual(proc_plan(self.class_file, self.entry).parts, 1)
        _, [expectation] = proc_scenario(self.class_file, self.entry, 0)
        labels, baseline = expectation.model['measurements'], expectation.model['baseline']
        steps = [assert_step(baseline['trials'], '40'), assert_step(f'{baseline["trials"]} parried', '35'),
                 assert_step(baseline['events'], '7'), assert_step(labels['aura'], '1'),
                 assert_step(labels['trials'], '4040'), assert_step(f'{labels["trials"]} parried', '4035'),
                 assert_step(labels['attempts'], '8075'), assert_step(labels['events'], '807')]
        self.workspace.scenario(f'conformance-witch-hunter-proc-{VENGEFUL_INTENT}-avoided-part-1', 'proc',
                                [expectation], steps=steps, spell=VENGEFUL_INTENT, rank=VENGEFUL_INTENT)
        manifest, results = self.workspace.manifest()
        [verdict] = [verdict for verdict in compare(manifest, results, tooltips=chance_reader(10.0, '$h'))
                     if verdict.check == PROC_CHECK]
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('baseline trials without the passive', verdict.explanation)



@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedProcMissesTest(unittest.TestCase):
    ENGAGE = (40, 35, 5)

    def setUp(self):
        from profile import for_entry
        self.workspace = Workspace()
        self.class_file = copy.deepcopy(for_entry(class_file(), VENGEFUL_INTENT))
        self.entry = next(entry for entry in self.class_file['procs']
                          if entry['aura'] == VENGEFUL_INTENT and entry['trigger']['action'] == 'avoided')
        for sizing in AvoidedProcJudgeTest.FIXTURE_SIZING:
            self.entry.pop(sizing, None)
        self.entry['trigger']['count_misses'] = True

    def tearDown(self):
        self.workspace.close()

    def test_misses_are_read_and_held_beside_the_dodged_and_parried_swings(self):
        scenario, [expectation] = proc_scenario(self.class_file, self.entry, 0)
        run.validate(scenario)
        model, trials = expectation.model, f'{VENGEFUL_INTENT} proc trials'
        self.assertEqual(model['readings'][0]['name'], 'avoided swings (dodged + parried + missed)')
        self.assertEqual(model['readings'][0]['labels'], [trials, f'{trials} parried', f'{trials} missed'])
        self.assertEqual(model['baseline']['added_trials'][f'{trials} missed'],
                         f'{VENGEFUL_INTENT} proc baseline trials missed')
        self.assertEqual(model['attack_balance'], {'total': f'{VENGEFUL_INTENT} proc attempts',
                                                   'parts': [trials, f'{trials} parried', f'{trials} missed']})
        missed = [step for step in scenario['steps'] if step.get('label', '').endswith('trials missed')]
        self.assertEqual([step['metric'] for step in missed], ['melee_missed_taken', 'melee_missed_taken'])
        self.assertIn('missed it (melee_missed_taken', expectation.rule)

    def test_the_option_is_off_by_default_and_refuses_a_non_boolean(self):
        self.entry['trigger'].pop('count_misses')
        _, [expectation] = proc_scenario(self.class_file, self.entry, 0)
        self.assertNotIn('attack_balance', expectation.model)
        self.assertEqual(len(expectation.model['readings'][0]['labels']), 2)
        with self.assertRaises(ValueError):
            proc_plan(self.class_file, {**self.entry, 'trigger': {**self.entry['trigger'], 'count_misses': 1}})

    def verdict(self, dodged: int, parried: int, missed: int, procs: int, extra_attacks: int = 0):
        from compare import compare
        _, [expectation] = proc_scenario(self.class_file, self.entry, 0)
        labels, baseline = expectation.model['measurements'], expectation.model['baseline']
        engage_dodged, engage_parried, engage_missed = self.ENGAGE
        steps = [assert_step(baseline['trials'], str(engage_dodged)),
                 assert_step(f'{baseline["trials"]} parried', str(engage_parried)),
                 assert_step(f'{baseline["trials"]} missed', str(engage_missed)),
                 assert_step(baseline['events'], '0'), assert_step(labels['aura'], '1'),
                 assert_step(labels['trials'], str(engage_dodged + dodged)),
                 assert_step(f'{labels["trials"]} parried', str(engage_parried + parried)),
                 assert_step(f'{labels["trials"]} missed', str(engage_missed + missed)),
                 assert_step(labels['attempts'], str(sum(self.ENGAGE) + dodged + parried + missed + extra_attacks)),
                 assert_step(labels['events'], str(procs))]
        self.workspace.scenario(f'conformance-witch-hunter-proc-{VENGEFUL_INTENT}-avoided-part-1', 'proc',
                                [expectation], steps=steps, spell=VENGEFUL_INTENT, rank=VENGEFUL_INTENT)
        manifest, results = self.workspace.manifest()
        [verdict] = [verdict for verdict in compare(manifest, results, tooltips=chance_reader(10.0, '$h'))
                     if verdict.check == PROC_CHECK]
        return verdict

    def test_procs_on_misses_too_pass_at_the_stated_chance(self):
        self.assertEqual(proc_plan(self.class_file, self.entry).parts, 1)
        verdict = self.verdict(3800, 3800, 400, 800)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.10)
        self.assertIn('8000 trials', verdict.explanation)

    def test_a_mutant_that_never_procs_on_a_miss_alerts(self):
        from random import Random
        rng = Random(680663)
        dodged, parried, missed = 2000, 2000, 4000
        procs = sum(rng.random() < 0.10 for _ in range(dodged + parried))
        verdict = self.verdict(dodged, parried, missed, procs)
        self.assertEqual(verdict.status, 'alert')
        self.assertLess(verdict.measured, 0.06)

    def test_the_miss_exclusion_is_off_by_default_and_validated(self):
        _, [expectation] = proc_scenario(self.class_file, self.entry, 0)
        self.assertNotIn('miss_exclusion', expectation.model)
        trigger = self.entry['trigger']
        for bad in ({'min_share': 0}, {'min_share': 0.5}, {'min_share': True}, {'share': 0.04}, 0.04):
            with self.assertRaises(ValueError):
                proc_plan(self.class_file, {**self.entry, 'trigger': {**trigger, 'miss_exclusion': bad}})
        with self.assertRaises(ValueError):
            proc_plan(self.class_file, {**self.entry, 'trigger': {k: v for k, v in
                                                                 {**trigger, 'miss_exclusion': {'min_share': 0.04}}.items()
                                                                 if k != 'count_misses'}})
        self.entry['trigger']['miss_exclusion'] = {'min_share': 0.04}
        _, [expectation] = proc_scenario(self.class_file, self.entry, 0)
        self.assertEqual(expectation.model['miss_exclusion'],
                         {'min_share': 0.04, 'missed': f'{VENGEFUL_INTENT} proc trials missed'})

    def test_a_miss_share_that_separates_the_alternative_stays_ok(self):
        self.entry['trigger']['miss_exclusion'] = {'min_share': 0.04}
        verdict = self.verdict(2400, 2400, 3200, 800)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('miss share 0.4000', verdict.explanation)
        self.assertIn('lies below the interval', verdict.explanation)

    def test_a_miss_share_under_the_threshold_is_unmeasured(self):
        self.entry['trigger']['miss_exclusion'] = {'min_share': 0.08}
        verdict = self.verdict(3800, 3800, 400, 800)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('under the 0.08', verdict.explanation)

    def test_a_server_that_ignores_misses_alerts_even_inside_the_band(self):
        from compare import miss_exclusion_judgement
        exclusion = {'min_share': 0.04, 'missed': 'missed'}
        trials, missed = 87829.0, 4507.0
        rate = 0.25 * (1 - missed / trials)
        half = 0.005
        status, low, high, why = miss_exclusion_judgement(exclusion, {'missed': missed}, trials,
                                                          ('ok', rate - half, rate + half, 'inside the band'), 0.25)
        self.assertEqual(status, 'alert')
        self.assertIn('is not excluded by the interval', why)
        status, *_ = miss_exclusion_judgement(exclusion, {'missed': missed}, trials,
                                              ('ok', 0.2449, 0.2550, 'inside the band'), 0.25)
        self.assertEqual(status, 'ok')

    def test_an_attack_outside_the_three_outcomes_voids_the_part(self):
        verdict = self.verdict(3800, 3800, 400, 800, extra_attacks=1)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('void', verdict.explanation)
        self.assertIn('8081 attacks taken against 8080', verdict.explanation)


if __name__ == '__main__':
    unittest.main()


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedProcPreconditionTest(unittest.TestCase):
    PRECONDITION = 560576
    CONDITION = 800209

    def setUp(self):
        from profile import for_entry
        self.class_file = for_entry(class_file(), DAWN_KNIGHT)
        self.entry = avoided_entry(self.class_file, DAWN_KNIGHT)

    def learning(self) -> dict:
        return {**self.entry, 'trigger': {**self.entry['trigger'], 'learn': [self.PRECONDITION]}}

    def test_the_learn_list_is_learned_before_every_engage(self):
        steps = run.validate(proc_scenario(self.class_file, self.learning())[0])['steps']
        learns = [index for index, step in enumerate(steps)
                  if step['action'] == 'learn' and step.get('spell') == self.PRECONDITION]
        engages = [index for index, step in enumerate(steps) if step['action'] == 'attack']
        passive = index_of(steps, lambda step: step['action'] == 'learn' and step.get('spell') == DAWN_KNIGHT)
        self.assertTrue(learns)
        self.assertLess(learns[0], min(engages))
        self.assertLess(learns[0], passive)

    def test_without_a_learn_list_no_precondition_is_learned(self):
        steps = run.validate(proc_scenario(self.class_file, self.entry)[0])['steps']
        self.assertFalse([step for step in steps
                          if step['action'] == 'learn' and step.get('spell') == self.PRECONDITION])

    def test_a_faulty_learn_list_is_refused(self):
        for learn in ([0], [True], self.PRECONDITION, [self.PRECONDITION, self.PRECONDITION], [DAWN_KNIGHT]):
            with self.subTest(learn=learn), self.assertRaises(ValueError):
                proc_plan(self.class_file, {**self.entry, 'trigger': {**self.entry['trigger'], 'learn': learn}})

    def test_a_learn_list_names_its_own_roll_and_keeps_the_plain_label(self):
        source = {**self.class_file, 'procs': [*self.class_file['procs'], self.learning()]}
        self.assertFalse(shares_aura(source, self.entry))
        self.assertEqual(entry_proc_label(source, self.entry), f'{DAWN_KNIGHT} proc_rate avoided')
        self.assertEqual(entry_proc_label(source, self.learning()),
                         f'{DAWN_KNIGHT} proc_rate avoided learn {self.PRECONDITION}')

    def test_attempt_auras_are_set_before_every_swing_interval(self):
        entry = {**self.entry, 'attempt_auras': [{'spell': self.CONDITION, 'stacks': 1, 'source': 'seeded'}]}
        steps = run.validate(proc_scenario(self.class_file, entry)[0])['steps']
        avoidance = [index for index, step in enumerate(steps) if step['action'] == 'set_combat_avoidance']
        self.assertTrue(avoidance)
        for index in avoidance:
            self.assertEqual(steps[index - 1]['action'], 'set_aura')
            self.assertEqual(steps[index - 1]['spell'], self.CONDITION)
            self.assertNotIn('target', steps[index - 1])

    def test_an_attempt_aura_on_another_trigger_than_a_cast_or_an_avoided_swing_is_refused(self):
        from procs import attempt_auras
        entry = {**self.entry, 'trigger': {'action': 'taken_hit'},
                 'attempt_auras': [{'spell': self.CONDITION, 'stacks': 1, 'source': 'seeded'}]}
        with self.assertRaises(ValueError):
            attempt_auras(entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedProcStackEventsTest(unittest.TestCase):
    STACK = 800058

    def setUp(self):
        from profile import for_entry
        self.class_file = for_entry(class_file(), DAWN_KNIGHT)
        self.entry = {**avoided_entry(self.class_file, DAWN_KNIGHT), 'event_metric': 'aura_stacks',
                      'stack_aura': self.STACK, 'stack_set': 0, 'stack_per_cast': 0, 'stack_cap': 6,
                      'events_per_proc': 1, 'baseline': True,
                      'attempt_auras': [{'spell': self.STACK, 'stacks': 0, 'source': 'seeded'}]}

    def test_the_stacks_are_reset_before_and_read_after_every_swing_interval(self):
        scenario, [expectation] = proc_scenario(self.class_file, self.entry)
        steps = run.validate(scenario)['steps']
        waits = [index for index, step in enumerate(steps) if step['action'] == 'wait' and 'label' not in step]
        reads = [index for index, step in enumerate(steps)
                 if step.get('metric') == 'aura_stacks' and step.get('spell') == self.STACK]
        self.assertTrue(waits)
        for wait in waits:
            self.assertIn(wait + 1, reads)
        model = expectation.model
        self.assertEqual(model['stack_events']['cap'], 6)
        self.assertEqual(model['stack_events']['per_cast'], 0)
        self.assertEqual(len(model['event_labels']), model['part_attempts'] + 1)

    def test_an_avoided_stack_entry_needs_no_cast_change_and_a_cap(self):
        for change in ({'stack_per_cast': 1}, {'stack_cap': None}, {'stack_cap': 0}):
            entry = {key: value for key, value in {**self.entry, **change}.items() if value is not None}
            with self.subTest(change=change), self.assertRaises(ValueError):
                proc_plan(self.class_file, entry)

    def test_a_read_at_the_cap_voids_the_part_and_reads_below_it_count(self):
        from proc_stacks import capped, events
        _, [expectation] = proc_scenario(self.class_file, self.entry)
        model = expectation.model
        values = {label: 1.0 for label in model['event_labels']}
        self.assertEqual(capped(model, values), [])
        self.assertEqual(events(model['stack_events'], list(values.values()), len(values), 999.0), len(values))
        values[model['event_labels'][3]] = 6.0
        self.assertEqual(capped(model, values), [model['event_labels'][3]])
