import copy
from dataclasses import asdict, replace
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import sys
import tempfile
import unittest

from compare import STATUSES, class_entry
from hits import EXCLUDED_OUTCOME_MARGIN, MAX_SCENARIO_MS, Unmodelled
from procs import (PART_BUDGET_MS, PER_TRIGGER, PER_TRIGGER_SOURCE, PROC_CHECK, proc_label, proc_plan, proc_scenario,
                   proc_status_expectation, shares_aura, shares_proc_spell, trials_needed, trigger_boundaries,
                   trigger_key, wilson_interval)
from profile import DBC_DIR
from test_compare import CLASS_FILE, Workspace, assert_step, constant_reader
from tooltip import Displayed, Records
from values import Expectation, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import batch
import run

Z_99 = 2.576
HALF_WIDTH = 0.025
SCOURGEBANE = 92111
WARRIOR_OF_DAWN = 560648
OATH_OF_VINDICATION = 805332
VINDICATION = 573324
RETRIBUTION = 707391
ARGENT_BLADE_MAX_RANK = 807268
SCOURGEBANE_STRIKE = 801832
CHANCE_TOKEN = '$520007h'
PROC_LABEL = '92111 proc_rate'
PROC_KEY = 'conformance-templar-proc-92111-part-1'
SECOND_KEY = 'conformance-templar-proc-92111-part-2'
LABELS = {'trials': '92111 proc trials', 'events': '92111 proc events', 'attempts': '92111 proc attempts',
          'aura': '92111 proc aura'}
STRIKE_TRIALS = '92111 proc trials spell_damage_count 801832'
READINGS = [{'name': 'auto attacks only', 'labels': [LABELS['trials']]},
            {'name': 'every direct damage event', 'labels': [LABELS['trials'], STRIKE_TRIALS]}]
LIGHTS_ECHO = (520017, 520883)
ARGENT_BLADE_FIRST_RANK = 804929
SCRIPTED_IN_CODE = {504808, 520017, 520883, 572548, 572554, 706325, 804571, 805332}
CONDEMNATION = 706325
BLADE_OF_FAITH = 803880
BLADE_OF_FAITH_TICK_MS = 3000
OATH_CHAIN = 704576
ZEALOTRY_STRIKE = 801450
TRANSCENDENT_GUARDIAN = 804571
TEMPLE_GUARDIAN = 803792
GUARDIAN_LABEL = '804571 proc_rate'
GUARDIAN_KEY = 'conformance-templar-proc-804571-part-1'
GUARDIAN_LABELS = {'trials': '804571 proc trials', 'events': '804571 proc events', 'attempts': '804571 proc attempts',
                   'aura': '804571 proc aura'}
CHARGE_POOL = '804571 proc charge pool'
HANDLER = re.compile(r'^Ascension\w+\.cpp:\d+-\d+ ')
TOKEN_SPELL = re.compile(r'\$(\d*)[hH]$')
LIGHTKEEPER = 560835
LIGHTKEEPER_PARRY = 561016
LIGHTKEEPER_BURST = 561277
CONDEMN = 804906
PULVERIZING = 524620
PULVERIZING_STRIKE = 524619
MIGHT_OF_AGGRAMAR = 803163
MIGHT_OF_AGGRAMAR_STACK = 803164
RIGHTEOUS_UPHEAVAL = 501562


def templar_proc(aura):
    return next(entry for entry in CLASS_FILE['procs'] if entry['aura'] == aura)


def proc_model(minimum=1699, parts=1, trigger=None, events_per_proc=1, readings=None):
    model = {'part': 0, 'parts': parts, 'chance_pct': 20.0, 'minimum_trials': minimum, 'scheduled_attempts': 2549,
            'part_attempts': 2549, 'attempt_ms': 2500, 'trigger': trigger or {'action': 'attack', 'spell': 0},
            'proc_spell': SCOURGEBANE_STRIKE, 'event_metric': 'spell_cast_count',
            'events_per_proc': events_per_proc, 'measurements': LABELS}
    if readings:
        model['readings'] = readings
    return model


def proc_expectation(**model):
    return Expectation(PROC_LABEL, PROC_CHECK, SCOURGEBANE, SCOURGEBANE, None, CHANCE_TOKEN,
                       'Wilson 99% interval of the proc rate', proc_model(**model))


def proc_steps(trials, events, aura=1, strikes=None):
    steps = [assert_step(LABELS['aura'], str(aura)), assert_step(LABELS['trials'], str(trials)),
             assert_step(LABELS['events'], str(events)), assert_step(LABELS['attempts'], str(trials))]
    if strikes is not None:
        steps.append(assert_step(STRIKE_TRIALS, str(strikes)))
    return steps


def charge_label(attempt):
    return f'804571 proc charges {attempt}'


def guardian_expectation(attempts):
    model = {'part': 0, 'parts': 1, 'chance_pct': 40.0, 'minimum_trials': attempts - 1, 'scheduled_attempts': attempts,
             'part_attempts': attempts, 'attempt_ms': 1500,
             'trigger': {'action': 'cast', 'spell': TEMPLE_GUARDIAN, 'target': 'ally'},
             'proc_spell': TEMPLE_GUARDIAN, 'event_metric': 'spell_charges', 'events_per_proc': 1,
             'measurements': GUARDIAN_LABELS, 'charge_pool': CHARGE_POOL,
             'event_labels': [charge_label(attempt) for attempt in range(1, attempts + 1)],
             'readings': [{'name': 'casts at the ally', 'labels': [GUARDIAN_LABELS['attempts']],
                           'minus_events': False}]}
    return Expectation(GUARDIAN_LABEL, PROC_CHECK, TRANSCENDENT_GUARDIAN, TRANSCENDENT_GUARDIAN, None, '$h', 'rule',
                       model)


def guardian_steps(charges, completed, pool=3):
    steps = [assert_step(GUARDIAN_LABELS['aura'], '1'), assert_step(CHARGE_POOL, str(pool)),
             assert_step(GUARDIAN_LABELS['trials'], str(completed)),
             assert_step(GUARDIAN_LABELS['attempts'], str(completed))]
    return steps + [assert_step(charge_label(attempt), str(left)) for attempt, left in enumerate(charges, 1)]


def casts_of(scenario):
    return [step for step in scenario['steps'] if step['action'] == 'cast']


def chance_reader(value=20.0, text=CHANCE_TOKEN):
    return constant_reader(Displayed(text, value, None, 'chance_pct'))


class TrialsTest(unittest.TestCase):
    def test_trials_put_the_99_percent_half_width_at_two_and_a_half_points(self):
        self.assertEqual(trials_needed(0.20), math.ceil(Z_99 ** 2 * 0.16 / HALF_WIDTH ** 2))
        self.assertEqual(trials_needed(0.20), 1699)

    def test_a_certain_or_impossible_proc_has_no_rate_to_measure(self):
        for chance in (0.0, 1.0, -0.1, 1.5):
            with self.assertRaises(ValueError):
                trials_needed(chance)

    def test_wilson_interval_of_the_expected_count_holds_the_chance(self):
        low, high = wilson_interval(340, 1699)
        self.assertLess(low, 0.20)
        self.assertGreater(high, 0.20)

    def test_wilson_interval_of_a_low_count_excludes_the_chance(self):
        low, high = wilson_interval(250, 1699)
        self.assertLess(high, 0.20)
        self.assertGreater(low, 0.0)


def first_step(steps, action):
    return next(index for index, step in enumerate(steps) if step['action'] == action)


class ProcCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self, reader=None):
        manifest, results = self.workspace.manifest()
        from compare import compare
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=reader or chance_reader())
                    if verdict.check == PROC_CHECK]
        self.assertEqual(len(verdicts), 1)
        return verdicts[0]

    def test_rate_whose_interval_holds_the_tooltip_chance_is_ok(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation()], steps=proc_steps(1699, 340))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.expected, 0.20)
        self.assertAlmostEqual(verdict.measured, 340 / 1699)
        self.assertEqual((verdict.low, verdict.high), wilson_interval(340, 1699))
        self.assertIn('1699 trials', verdict.explanation)

    def test_rate_whose_interval_excludes_the_tooltip_chance_is_an_alert(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation()], steps=proc_steps(1699, 250))
        self.assertEqual(self.verdict().status, 'alert')

    def test_parts_are_summed_into_one_verdict(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(parts=2)], steps=proc_steps(850, 170))
        self.workspace.scenario(SECOND_KEY, 'proc', [proc_expectation(parts=2)], steps=proc_steps(849, 170))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 340 / 1699)
        self.assertIn('2 of 2 parts', verdict.explanation)

    def test_too_few_trials_are_insufficient_even_on_the_exact_rate(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(parts=2)], steps=proc_steps(850, 170))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('1 of 2 parts', verdict.explanation)

    def test_several_events_per_proc_count_one_proc(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(events_per_proc=2)],
                                steps=proc_steps(1699, 680))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 340 / 1699)

    def test_failed_trigger_casts_lower_the_trials_and_are_named(self):
        trigger = {'action': 'cast', 'spell': ARGENT_BLADE_MAX_RANK}
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(trigger=trigger)], steps=proc_steps(1600, 320))
        self.workspace.cast_failures[PROC_KEY] = [{'spell': str(ARGENT_BLADE_MAX_RANK), 'reason': '22'}] * 3
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('3 x SPELL_FAILED_CASTER_AURASTATE (22)', verdict.explanation)

    def test_no_usable_trial_after_failed_casts_is_unmeasured(self):
        trigger = {'action': 'cast', 'spell': ARGENT_BLADE_MAX_RANK}
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(trigger=trigger)], steps=proc_steps(0, 0))
        self.workspace.cast_failures[PROC_KEY] = [{'spell': str(ARGENT_BLADE_MAX_RANK), 'reason': '22'}]
        self.assertEqual(self.verdict().status, 'unmeasured')

    def test_part_without_the_proc_aura_is_not_counted(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation()], steps=proc_steps(1699, 0, aura=0))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn(PROC_KEY, verdict.explanation)

    def test_chance_token_missing_from_the_tooltip_is_an_alert(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation()], steps=proc_steps(1699, 340))
        verdict = self.verdict(chance_reader(text='$h'))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn(CHANCE_TOKEN, verdict.explanation)

    def test_chance_changed_since_generation_is_an_alert(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation()], steps=proc_steps(1699, 170))
        verdict = self.verdict(chance_reader(value=10.0))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('generated as 20%', verdict.explanation)

    def test_more_procs_than_trials_is_an_alert(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(minimum=10)], steps=proc_steps(10, 11))
        self.assertEqual(self.verdict().status, 'alert')

    def test_more_procs_than_trials_is_an_alert_even_below_the_minimum(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation()], steps=proc_steps(10, 11))
        self.assertEqual(self.verdict().status, 'alert')

    def test_readings_that_disagree_are_an_ambiguous_tooltip_showing_each(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(readings=READINGS)],
                                steps=proc_steps(1699, 340, strikes=340))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        low, high = wilson_interval(340, 2039)
        self.assertLess(high, 0.20)
        self.assertIn('auto attacks only: 340 procs in 1699 trials', verdict.explanation)
        self.assertIn(f'every direct damage event: 340 procs in 2039 trials, rate {340 / 2039:.4f}, '
                      f'Wilson 99% interval [{low:.4f}, {high:.4f}]: alert', verdict.explanation)
        self.assertIn(': ok', verdict.explanation)

    def test_readings_that_agree_give_their_common_verdict(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(readings=READINGS)],
                                steps=proc_steps(1699, 380, strikes=20))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.low, verdict.high), wilson_interval(380, 1699))
        self.assertIn('every direct damage event: 380 procs in 1719 trials', verdict.explanation)

    def test_events_beyond_the_completed_player_casts_are_the_procs(self):
        trigger = {'action': 'cast', 'spell': ARGENT_BLADE_MAX_RANK}
        extra = f'92111 proc events spell_cast_count {ARGENT_BLADE_MAX_RANK}'
        model = proc_model(trigger=trigger, readings=[
            {'name': 'player casts only', 'labels': [LABELS['trials']], 'minus_events': True},
            {'name': 'every strike', 'labels': [LABELS['trials']], 'minus_events': False}])
        model.update({'part_attempts': 1700, 'exclude_trigger_casts': True,
                      'event_labels': [LABELS['events'], extra]})
        expectation = Expectation(PROC_LABEL, PROC_CHECK, SCOURGEBANE, SCOURGEBANE, None, CHANCE_TOKEN, 'rule', model)
        steps = proc_steps(2039, 0) + [assert_step(extra, '2039')]
        self.workspace.scenario(PROC_KEY, 'proc', [expectation], steps=steps)
        self.workspace.cast_failures[PROC_KEY] = [{'spell': str(ARGENT_BLADE_MAX_RANK), 'reason': '22'}]
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        self.assertIn('player casts only: 340 procs in 1699 trials', verdict.explanation)
        self.assertIn('every strike: 340 procs in 2039 trials', verdict.explanation)
        self.assertIn(f'minus the completed player casts of {ARGENT_BLADE_MAX_RANK}', verdict.explanation)

    def test_readings_that_agree_on_an_alert_stay_an_alert(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(readings=READINGS)],
                                steps=proc_steps(1699, 0, strikes=0))
        self.assertEqual(self.verdict().status, 'alert')

    def single_reading_verdict(self, entry, aura, procs, trials, chance):
        self.workspace.close()
        self.workspace = Workspace()
        scenario, [expectation] = proc_scenario(CLASS_FILE, entry)
        labels = expectation.model['measurements']
        [reading] = expectation.model['readings']
        extra_labels = [label for label in reading['labels'] if label != labels['trials']]
        steps = [assert_step(labels['aura'], '1'), assert_step(labels['events'], str(procs)),
                 assert_step(labels['trials'], str(trials))] + [assert_step(label, '0') for label in extra_labels]
        self.workspace.scenario(f'conformance-templar-proc-{entry["aura"]}-{entry["proc_spell"]}', 'proc',
                                [expectation], steps=steps, spell=aura, rank=aura)
        return self.verdict(chance_reader(chance, entry['chance_token']))

    def test_scourgebane_counts_at_most_one_strike_per_landed_swing(self):
        entry = templar_proc(SCOURGEBANE)
        self.assertNotIn('trial_readings', entry)
        self.assertEqual(entry[PER_TRIGGER], 1)
        self.assertIn('owner ruling 2026-11-11', entry[PER_TRIGGER_SOURCE])
        self.assertIn('Scourgebane does not proc off itself.', entry[PER_TRIGGER_SOURCE])

    def test_lightkeeper_and_condemnation_keep_only_the_tick_reading(self):
        for aura, proc_spell in ((LIGHTKEEPER, LIGHTKEEPER_PARRY), (LIGHTKEEPER, LIGHTKEEPER_BURST),
                                 (CONDEMNATION, ZEALOTRY_STRIKE)):
            with self.subTest(proc_spell=proc_spell):
                entry = next(entry for entry in CLASS_FILE['procs']
                            if entry['aura'] == aura and entry['proc_spell'] == proc_spell)
                self.assertEqual([reading['name'] for reading in entry['trial_readings']], ['each damage tick'])
                self.assertNotIn('readings_question', entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_lightkeeper_parry_single_reading_holds_the_tooltip_chance(self):
        entry = next(entry for entry in CLASS_FILE['procs']
                    if entry['aura'] == LIGHTKEEPER and entry['proc_spell'] == LIGHTKEEPER_PARRY)
        verdict = self.single_reading_verdict(entry, LIGHTKEEPER, 695, 4472, 15.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 695 / 4472)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_lightkeeper_burst_single_reading_holds_the_tooltip_chance(self):
        entry = next(entry for entry in CLASS_FILE['procs']
                    if entry['aura'] == LIGHTKEEPER and entry['proc_spell'] == LIGHTKEEPER_BURST)
        verdict = self.single_reading_verdict(entry, LIGHTKEEPER, 668, 4472, 15.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 668 / 4472)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_condemnation_single_reading_holds_the_tooltip_chance(self):
        entry = templar_proc(CONDEMNATION)
        verdict = self.single_reading_verdict(entry, CONDEMNATION, 622, 4134, 15.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 622 / 4134)

    def test_ambiguous_and_unmodelled_entries_are_never_ok(self):
        for status in ('ambiguous_tooltip', 'unmodelled'):
            entry = {'aura': 572548, 'name': 'Blade Sermon', 'chance_token': '$h', 'status': status,
                     'reason': 'the tooltip does not say what triggers Zealotry'}
            expectation = proc_status_expectation(entry)
            self.assertEqual(expectation.check, PROC_CHECK)
            self.fresh_scenario(expectation)
            manifest, results = self.workspace.manifest()
            from compare import compare
            verdicts = compare(manifest, results, tooltips=chance_reader())
            self.assertEqual([verdict.status for verdict in verdicts], [status])
            self.assertIn('Zealotry', verdicts[0].explanation)

    def fresh_scenario(self, expectation):
        self.workspace.close()
        self.workspace = Workspace()
        (self.workspace.root / 'out').mkdir(parents=True)
        self.workspace.scenarios.append({'key': 'conformance-templar-proc-572548', 'file': None, 'sha256': None,
                                         'kind': 'proc', 'spell_id': 572548, 'spell_name': 'Blade Sermon',
                                         'rank_id': 572548, 'tokens': [],
                                         'expectations': [asdict(expectation)]})

    def test_charges_left_after_each_cast_give_the_refunded_charges(self):
        charges = [3] * 4 + [2] * 6
        self.workspace.scenario(GUARDIAN_KEY, 'proc', [guardian_expectation(10)], steps=guardian_steps(charges, 10),
                                spell=TRANSCENDENT_GUARDIAN, rank=TRANSCENDENT_GUARDIAN)
        verdict = self.verdict(chance_reader(40.0, '$h'))
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 4 / 10)
        self.assertIn('casts at the ally: 4 procs in 10 trials', verdict.explanation)
        self.assertIn(f'charges of {TEMPLE_GUARDIAN} left after each cast', verdict.explanation)
        self.assertNotIn(charge_label(2), verdict.explanation)

    def test_a_failed_cast_keeps_its_restored_charges_without_a_proc(self):
        charges = [3] * 4 + [2] * 5 + [3]
        self.workspace.scenario(GUARDIAN_KEY, 'proc', [guardian_expectation(10)], steps=guardian_steps(charges, 9),
                                spell=TRANSCENDENT_GUARDIAN, rank=TRANSCENDENT_GUARDIAN)
        self.workspace.cast_failures[GUARDIAN_KEY] = [{'spell': str(TEMPLE_GUARDIAN), 'reason': '67'}]
        verdict = self.verdict(chance_reader(40.0, '$h'))
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 4 / 9)
        self.assertIn('SPELL_FAILED_NOT_READY (67)', verdict.explanation)

    def test_no_refunded_charge_in_many_casts_is_an_alert(self):
        self.workspace.scenario(GUARDIAN_KEY, 'proc', [guardian_expectation(40)], steps=guardian_steps([2] * 40, 40),
                                spell=TRANSCENDENT_GUARDIAN, rank=TRANSCENDENT_GUARDIAN)
        verdict = self.verdict(chance_reader(40.0, '$h'))
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 0.0)

    def test_statuses_include_every_proc_verdict(self):
        for status in ('ok', 'alert', 'ambiguous_tooltip', 'unmodelled', 'insufficient_trials', 'unmeasured'):
            self.assertIn(status, STATUSES)


def per_trigger_expectation(triggers, minimum=1699, aura=SCOURGEBANE):
    entry = templar_proc(aura)
    _, [expectation] = proc_scenario(CLASS_FILE, entry)
    model = {**expectation.model, 'part': 0, 'parts': 1, 'part_attempts': triggers, 'minimum_trials': minimum,
             'trigger_boundaries': trigger_boundaries(entry, triggers)}
    return replace(expectation, model=model)


def per_trigger_steps(outcomes, aura=1, proc=SCOURGEBANE):
    boundaries = trigger_boundaries(templar_proc(proc), len(outcomes))
    steps, hits, events = [assert_step(f'{proc} proc aura', str(aura))], 0, 0
    for index, boundary in enumerate(boundaries):
        if index:
            hits, events = hits + outcomes[index - 1][0], events + outcomes[index - 1][1]
        steps += [assert_step(boundary['hits'], str(hits))] + [assert_step(label, str(events))
                                                               for label in boundary['events']]
    return steps


def swings(*counts):
    return [outcome for procs, count in enumerate(counts) for outcome in [(1, procs)] * count]


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class PerTriggerCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self, outcomes, reader=None, minimum=1699, steps=None):
        expectation = per_trigger_expectation(len(outcomes), minimum)
        self.workspace.scenario(PROC_KEY, 'proc', [expectation], steps=steps or per_trigger_steps(outcomes),
                                spell=SCOURGEBANE, name='Scourgebane', rank=SCOURGEBANE)
        manifest, results = self.workspace.manifest()
        from compare import compare
        [verdict] = [verdict for verdict in compare(manifest, results, tooltips=reader or chance_reader())
                     if verdict.check == PROC_CHECK]
        return verdict

    def test_one_strike_in_a_fifth_of_the_swings_is_ok(self):
        verdict = self.verdict(swings(1360, 340))
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.2)
        self.assertIn('no one-hit trigger gave more than 1 proc', verdict.explanation)
        self.assertIn('340 of 1700 one-hit triggers gave a proc', verdict.explanation)

    def test_a_chaining_server_is_an_alert_even_at_a_fifth_of_the_swings(self):
        verdict = self.verdict(swings(1225, 238, 66, 9, 2), minimum=1540)
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 315 / 1540)
        self.assertIn('77 of 1540 one-hit triggers gave more than 1 proc (at most 4)', verdict.explanation)
        self.assertIn('procs per one-hit trigger 0: 1225, 1: 238, 2: 66, 3: 9, 4: 2', verdict.explanation)

    def test_one_extra_strike_is_enough_for_an_alert(self):
        verdict = self.verdict(swings(1360, 339, 1))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('1 of 1700 one-hit triggers gave more than 1 proc (at most 2)', verdict.explanation)

    def test_a_quarter_of_the_swings_without_a_chain_is_an_alert(self):
        verdict = self.verdict(swings(1275, 425))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('no one-hit trigger gave more than 1 proc', verdict.explanation)

    def test_a_seeded_tooltip_chance_other_than_the_generated_one_is_an_alert(self):
        verdict = self.verdict(swings(1360, 340), chance_reader(25.0))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('shows 25%, generated as 20%', verdict.explanation)

    def test_triggers_without_exactly_one_hit_are_left_out(self):
        verdict = self.verdict(swings(1360, 340) + [(2, 2)] * 30 + [(0, 0)] * 5)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.2)
        self.assertIn('35 triggers without exactly one landed hit left out', verdict.explanation)

    def test_fewer_one_hit_triggers_than_the_rate_needs_are_insufficient(self):
        self.assertEqual(self.verdict(swings(1000, 250)).status, 'insufficient_trials')

    def test_a_missing_boundary_reading_leaves_the_part_unmeasured(self):
        outcomes = swings(1360, 340)
        steps = [step for step in per_trigger_steps(outcomes) if step['label'] != '92111 proc trigger 7 hits']
        verdict = self.verdict(outcomes, steps=steps)
        self.assertNotEqual(verdict.status, 'ok')
        self.assertIn('no usable trial', verdict.explanation)

    def test_absent_aura_is_never_ok(self):
        outcomes = swings(1360, 340)
        verdict = self.verdict(outcomes, steps=per_trigger_steps(outcomes, aura=0))
        self.assertEqual(verdict.status, 'unmeasured')


def strikes(*counts):
    return [outcome for events, count in counts for outcome in [(1, events)] * count]


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class WholeProcsPerTriggerCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self, outcomes):
        expectation = per_trigger_expectation(len(outcomes), aura=RETRIBUTION)
        self.workspace.scenario(f'conformance-templar-proc-{RETRIBUTION}-part-1', 'proc', [expectation],
                                steps=per_trigger_steps(outcomes, proc=RETRIBUTION), spell=RETRIBUTION,
                                name='Retribution', rank=RETRIBUTION)
        manifest, results = self.workspace.manifest()
        from compare import compare
        [verdict] = [verdict for verdict in compare(manifest, results, tooltips=chance_reader(text='$h'))
                     if verdict.check == PROC_CHECK]
        return verdict

    def test_retribution_counts_one_proc_of_two_strikes_per_landed_swing(self):
        entry = templar_proc(RETRIBUTION)
        self.assertEqual((entry['events_per_proc'], entry[PER_TRIGGER]), (2, 1))
        self.assertIn("'strike 2 additional times'", entry[PER_TRIGGER_SOURCE])

    def test_two_strikes_in_a_fifth_of_the_swings_are_ok(self):
        verdict = self.verdict(strikes((0, 1360), (2, 340)))
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.2)
        self.assertIn('procs per one-hit trigger 0: 1360, 1: 340', verdict.explanation)
        self.assertNotIn('part of a proc', verdict.explanation)

    def test_one_swing_with_a_single_strike_is_an_alert(self):
        verdict = self.verdict(strikes((0, 1360), (2, 339), (1, 1)))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('1 of 1700 one-hit triggers gave a part of a proc (events not a whole multiple of 2)',
                      verdict.explanation)

    def test_a_server_striking_once_per_proc_is_an_alert(self):
        verdict = self.verdict(strikes((0, 1360), (1, 340)))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('340 of 1700 one-hit triggers gave a part of a proc', verdict.explanation)

    def test_three_strikes_in_one_swing_are_an_alert(self):
        verdict = self.verdict(strikes((0, 1360), (2, 339), (3, 1)))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('1 of 1700 one-hit triggers gave more than 1 proc (at most 1.5)', verdict.explanation)
        self.assertIn('1 of 1700 one-hit triggers gave a part of a proc', verdict.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ProcScenarioTest(unittest.TestCase):
    def test_scourgebane_reads_every_swing_in_parts_that_fit_the_timeout(self):
        entry = templar_proc(SCOURGEBANE)
        plan = proc_plan(CLASS_FILE, entry)
        swing = CLASS_FILE['weapon']['speed_ms']
        self.assertEqual(plan.chance_pct, 20.0)
        self.assertEqual(plan.needed, 1699)
        self.assertEqual(plan.scheduled, math.ceil(1699 * EXCLUDED_OUTCOME_MARGIN))
        self.assertGreater(plan.attempt_ms, swing)
        self.assertGreaterEqual(plan.parts * plan.per_part, plan.scheduled)
        for part in range(plan.parts):
            scenario, [expectation] = proc_scenario(CLASS_FILE, entry, part)
            run.validate(scenario)
            self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)
            steps = scenario['steps']
            attacks = [index for index, step in enumerate(steps) if step['action'] == 'attack']
            self.assertEqual(len(attacks), plan.per_part)
            for index in attacks:
                self.assertEqual([step['action'] for step in steps[index:index + 3]], ['attack', 'wait', 'stop_attack'])
                self.assertEqual(steps[index + 1]['ms'], swing)
            boundaries = expectation.model['trigger_boundaries']
            self.assertEqual(len(boundaries), plan.per_part + 1)
            measured = {step['label']: step for step in steps if step['action'] == 'assert'}
            for boundary in boundaries:
                self.assertEqual((measured[boundary['hits']]['metric'], measured[boundary['hits']]['hand']),
                                 ('melee_damage_count', 0))
                [events] = boundary['events']
                self.assertEqual((measured[events]['metric'], measured[events]['spell']),
                                 ('spell_cast_count', SCOURGEBANE_STRIKE))
            self.assertNotIn(LABELS['trials'], measured)
            self.assertNotIn(LABELS['events'], measured)
            self.assertEqual(measured['92111 proc aura']['metric'], 'aura')
            self.assertIn({'action': 'learn', 'actor': 'caster', 'spell': SCOURGEBANE}, steps)
            self.assertEqual((expectation.label, expectation.check, expectation.displayed),
                             (PROC_LABEL, PROC_CHECK, CHANCE_TOKEN))
            self.assertEqual((expectation.model['part'], expectation.model['parts']), (part, plan.parts))
            self.assertEqual((expectation.model['minimum_trials'], expectation.model[PER_TRIGGER]), (1699, 1))

    def test_per_trigger_limits_need_an_attack_trigger_one_reading_and_a_source(self):
        entry = templar_proc(SCOURGEBANE)
        cast = {**entry, 'trigger': {'action': 'cast', 'spell': ARGENT_BLADE_MAX_RANK}}
        readings = {**entry, 'trial_readings': [{'name': 'every strike', 'adds': []}]}
        unsourced = {key: value for key, value in entry.items() if key != PER_TRIGGER_SOURCE}
        for bad in (cast, readings, unsourced, {**entry, PER_TRIGGER: 0}, {**entry, PER_TRIGGER: True},
                    {**entry, PER_TRIGGER: 1.5}):
            with self.subTest(entry={key: bad[key] for key in ('trigger', PER_TRIGGER) if key in bad}):
                with self.assertRaises(ValueError):
                    proc_scenario(CLASS_FILE, bad)

    def test_lights_echo_casts_argent_blade_and_counts_the_strikes_of_its_first_rank(self):
        for aura, chance in zip(LIGHTS_ECHO, (10.0, 20.0)):
            with self.subTest(aura=aura):
                entry = templar_proc(aura)
                plan = proc_plan(CLASS_FILE, entry)
                self.assertEqual((plan.chance_pct, plan.needed), (chance, trials_needed(chance / 100)))
                scenario, [expectation] = proc_scenario(CLASS_FILE, entry)
                run.validate(scenario)
                casts = {step['spell'] for step in casts_of(scenario)}
                self.assertEqual(casts, {ARGENT_BLADE_MAX_RANK})
                measured = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
                self.assertEqual((measured[f'{aura} proc events']['metric'], measured[f'{aura} proc events']['spell']),
                                 ('spell_cast_count', ARGENT_BLADE_FIRST_RANK))
                cast_rank_events = measured[f'{aura} proc events spell_cast_count {ARGENT_BLADE_MAX_RANK}']
                self.assertEqual(cast_rank_events['spell'], ARGENT_BLADE_MAX_RANK)
                self.assertEqual(measured[f'{aura} proc trials']['spell'], ARGENT_BLADE_MAX_RANK)
                self.assertTrue(expectation.model['exclude_trigger_casts'])
                self.assertEqual(expectation.model['part_attempts'], len(casts_of(scenario)))
                if aura == LIGHTS_ECHO[1]:
                    self.assertEqual([reading['minus_events'] for reading in expectation.model['readings']], [True])
                    self.assertNotIn('readings_question', entry)
                else:
                    self.assertEqual([reading['minus_events'] for reading in expectation.model['readings']],
                                     [True, False])
                self.assertIn('handler: AscensionTemplarAbilities.cpp:296-300', expectation.rule)

    def test_condemnation_entry(self):
        entry = templar_proc(CONDEMNATION)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': BLADE_OF_FAITH})
        self.assertEqual((entry['proc_spell'], entry['event_metric']), (ZEALOTRY_STRIKE, 'spell_cast_count'))
        self.assertEqual([(reading['name'], reading.get('trials_metric')) for reading in entry['trial_readings']],
                         [('each damage tick', None)])
        self.assertNotIn('readings_question', entry)
        self.assertEqual(trials_needed(0.15), 1354)
        plan = proc_plan(CLASS_FILE, entry)
        self.assertEqual((plan.chance_pct, plan.needed), (15.0, 1354))
        self.assertGreater(plan.attempt_ms, 2 * BLADE_OF_FAITH_TICK_MS)
        self.assertGreaterEqual(plan.parts * plan.per_part, plan.scheduled)
        for part in range(plan.parts):
            scenario, [expectation] = proc_scenario(CLASS_FILE, entry, part)
            run.validate(scenario)
            self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)
            steps = scenario['steps']
            casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
            self.assertEqual(len(casts), plan.per_part)
            for index in casts:
                self.assertEqual(steps[index], {'action': 'cast', 'actor': 'caster', 'spell': BLADE_OF_FAITH,
                                                'target': 'dummy'})
                self.assertIn({'action': 'set_aura', 'actor': 'caster', 'spell': OATH_CHAIN, 'stacks': 1},
                              steps[index - 3:index])
            measured = {step['label']: step for step in steps if step['action'] == 'assert'}
            self.assertEqual((measured['706325 proc events']['metric'], measured['706325 proc events']['spell']),
                             ('spell_cast_count', ZEALOTRY_STRIKE))
            trials = measured['706325 proc trials']
            self.assertEqual((trials['metric'], trials['spell'], trials['target']),
                             ('spell_damage_count', BLADE_OF_FAITH, 'dummy'))
            self.assertEqual((measured['706325 proc attempts']['metric'], measured['706325 proc attempts']['spell']),
                             ('spell_cast_count', BLADE_OF_FAITH))
            self.assertEqual([reading['labels'] for reading in expectation.model['readings']],
                             [['706325 proc trials']])

    def test_ally_trigger_scenario(self):
        entry = templar_proc(TRANSCENDENT_GUARDIAN)
        self.assertNotIn('status', entry)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': TEMPLE_GUARDIAN, 'target': 'ally'})
        self.assertEqual(trials_needed(0.40), 2549)
        plan = proc_plan(CLASS_FILE, entry)
        self.assertEqual((plan.chance_pct, plan.needed), (40.0, 2549))
        self.assertGreater(plan.parts, 1)
        self.assertGreaterEqual(plan.parts * plan.per_part, plan.scheduled)
        self.assertLessEqual(plan.per_part * plan.attempt_ms, PART_BUDGET_MS)
        for part in range(plan.parts):
            scenario, [expectation] = proc_scenario(CLASS_FILE, entry, part)
            run.validate(scenario)
            self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)
            self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
            self.assertNotIn('creatures', scenario)
            steps = scenario['steps']
            casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
            self.assertEqual(len(casts), plan.per_part)
            for index in casts:
                self.assertEqual(steps[index], {'action': 'cast', 'actor': 'caster', 'spell': TEMPLE_GUARDIAN,
                                                'target': 'ally'})
                before = [step['action'] for step in steps[index - 5:index]]
                self.assertIn('restore_charges', before)
                self.assertIn('relocate', before)
                self.assertEqual(steps[index + 2]['metric'], 'spell_charges')
            measured = {step['label']: step for step in steps if step['action'] == 'assert'}
            self.assertEqual(measured['804571 proc charge pool']['metric'], 'spell_charges')
            self.assertEqual((measured['804571 proc trials']['metric'], measured['804571 proc trials']['spell']),
                             ('spell_cast_count', TEMPLE_GUARDIAN))
            self.assertEqual(expectation.model['event_labels'],
                             [charge_label(attempt) for attempt in range(1, plan.per_part + 1)])
            self.assertEqual(expectation.model['charge_pool'], '804571 proc charge pool')

    def test_fewer_attempts_than_the_trials_are_refused(self):
        entry = templar_proc(SCOURGEBANE)
        with self.assertRaises(ValueError):
            proc_scenario(CLASS_FILE, entry, attempts=1698)
        proc_scenario(CLASS_FILE, entry, attempts=1699)

    def test_cast_trigger_casts_its_rank_at_the_dummy_spaced_beyond_the_internal_cooldown(self):
        entry = {'aura': SCOURGEBANE, 'name': 'Scourgebane', 'chance_token': CHANCE_TOKEN,
                 'trigger': {'action': 'cast', 'spell': ARGENT_BLADE_MAX_RANK}, 'event_metric': 'spell_cast_count',
                 'proc_spell': SCOURGEBANE_STRIKE, 'internal_cooldown_ms': 4000}
        plan = proc_plan(CLASS_FILE, entry)
        self.assertGreater(plan.attempt_ms, 4000)
        scenario, [expectation] = proc_scenario(CLASS_FILE, entry)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(len(casts), plan.per_part)
        self.assertTrue(all(cast == {'action': 'cast', 'actor': 'caster', 'spell': ARGENT_BLADE_MAX_RANK,
                                     'target': 'dummy'} for cast in casts))
        waits = [step['ms'] for step in scenario['steps'] if step['action'] == 'wait' and 'label' not in step]
        self.assertTrue(waits and all(wait == plan.attempt_ms for wait in waits))
        measured = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertEqual(measured['92111 proc trials']['metric'], 'spell_damage_count')
        self.assertEqual(measured['92111 proc trials']['spell'], ARGENT_BLADE_MAX_RANK)
        self.assertEqual(expectation.model['trigger'], entry['trigger'])

    def test_auto_attack_cannot_be_spaced_beyond_an_internal_cooldown(self):
        entry = copy.deepcopy(templar_proc(SCOURGEBANE))
        entry['internal_cooldown_ms'] = 1000
        with self.assertRaises(Unmodelled):
            proc_plan(CLASS_FILE, entry)

    def test_status_entry_has_no_scenario(self):
        entry = {**templar_proc(SCOURGEBANE), 'status': 'unmodelled', 'reason': 'seeded'}
        with self.assertRaises(ValueError):
            proc_scenario(CLASS_FILE, entry)

    def test_an_applied_aura_must_show_its_chance_as_its_own_percent(self):
        entry = {**templar_proc(WARRIOR_OF_DAWN), 'applied_by': {'spell': WARRIOR_OF_DAWN, 'source': 'seeded'}}
        with self.assertRaises(ValueError):
            proc_plan(CLASS_FILE, entry)

    def test_the_oath_of_vindication_is_set_and_its_chance_read_from_vindication(self):
        entry = templar_proc(OATH_OF_VINDICATION)
        scenario, [expectation] = proc_scenario(CLASS_FILE, entry)
        steps = run.validate(scenario)['steps']
        self.assertFalse([step for step in steps if step['action'] == 'learn' and step['spell'] == OATH_OF_VINDICATION])
        self.assertEqual(steps[first_step(steps, 'set_aura')]['spell'], OATH_OF_VINDICATION)
        self.assertEqual(proc_plan(CLASS_FILE, entry).chance_pct, 20.0)
        model = expectation.model
        self.assertEqual((model['chance_spell'], model['chance_kind']), (VINDICATION, 'percent'))

    def test_attempt_auras_are_set_before_every_cast(self):
        entry = {**templar_proc(CONDEMNATION),
                 'attempt_auras': [{'spell': 704576, 'stacks': 0, 'source': 'seeded'}]}
        steps = run.validate(proc_scenario(CLASS_FILE, entry)[0])['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        for earlier, cast in zip([0] + casts, casts):
            fixtures = [step for step in steps[earlier:cast]
                        if step['action'] == 'set_aura' and step['stacks'] == 0]
            self.assertEqual(len(fixtures), 1)

    def test_auto_attacks_count_as_events_only_for_a_cast_trigger(self):
        entry = {**templar_proc(SCOURGEBANE), 'event_metric': 'melee_attack_count'}
        with self.assertRaises(ValueError):
            proc_plan(CLASS_FILE, entry)

    def test_auto_attack_events_are_read_on_the_main_hand(self):
        entry = {**templar_proc(CONDEMNATION), 'event_metric': 'melee_attack_count'}
        steps = run.validate(proc_scenario(CLASS_FILE, entry)[0])['steps']
        reads = [step for step in steps if step.get('metric') == 'melee_attack_count']
        self.assertTrue(reads)
        self.assertTrue(all(step['hand'] == 0 and 'spell' not in step for step in reads))

    def test_an_attempt_aura_without_its_source_is_refused(self):
        entry = {**templar_proc(CONDEMNATION),
                 'attempt_auras': [{'spell': 704576, 'stacks': 0}]}
        with self.assertRaises(ValueError):
            proc_scenario(CLASS_FILE, entry)

    def test_an_applied_by_without_its_source_is_refused(self):
        entry = {**templar_proc(WARRIOR_OF_DAWN), 'applied_by': {'spell': WARRIOR_OF_DAWN}}
        with self.assertRaises(ValueError):
            proc_plan(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TemplarProcEntriesTest(unittest.TestCase):
    def setUp(self):
        self.records = Records(dataset(DBC_DIR))

    def spell(self, spell_id, field):
        return self.records.field('Spell', spell_id, field)

    def test_entries_handled_in_code_cite_the_handler_in_their_rule(self):
        for entry in CLASS_FILE['procs']:
            with self.subTest(aura=entry['aura']):
                self.assertEqual(bool(entry.get('handler')), entry['aura'] in SCRIPTED_IN_CODE)
                if entry.get('status'):
                    self.assertRegex(entry['handler'], HANDLER)
                    self.assertIn('handler: ' + entry['handler'], proc_status_expectation(entry).rule)

    def test_source_list_is_covered(self):
        auras = {entry['aura'] for entry in CLASS_FILE['procs']}
        self.assertTrue({92111, 560648, 520017, 520883, 707391, 504808, 572548, 572554, 706325, 804571} <= auras)

    def test_every_entry_cites_its_dbc_tooltip_and_proc_fields(self):
        for entry in CLASS_FILE['procs']:
            with self.subTest(aura=entry['aura']):
                shown = entry.get('applied_by', {}).get('spell', entry['aura'])
                self.assertEqual(entry['tooltip'], self.spell(shown, 'Description[enUS]'))
                self.assertEqual(entry['name'], self.spell(entry['aura'], 'SpellName[enUS]'))
                self.assertIn(str(entry['aura']), entry['dbc'])
                for spell_id, fields in entry['dbc'].items():
                    for name in ('ProcChance', 'ProcFlags', 'ProcCharges'):
                        self.assertEqual(fields[name], self.spell(int(spell_id), name))
                token = TOKEN_SPELL.match(entry['chance_token'])
                token_spell = (token.group(1) if token else '') or str(entry['aura'])
                self.assertIn(entry['chance_token'], entry['tooltip'])
                self.assertIn(token_spell, entry['dbc'])

    def test_modelled_entries_name_a_trigger_and_a_measured_proc_spell(self):
        for entry in CLASS_FILE['procs']:
            with self.subTest(aura=entry['aura']):
                if entry.get('status'):
                    self.assertIn(entry['status'], ('ambiguous_tooltip', 'unmodelled'))
                    self.assertTrue(entry['reason'])
                    continue
                self.assertIn(entry['trigger']['action'], ('cast', 'attack'))
                self.assertIn(entry['trigger_text'], entry['tooltip'])
                self.assertIn(entry['event_metric'], ('spell_cast_count', 'spell_damage_count', 'melee_attack_count',
                                                      'spell_charges'))
                self.assertTrue(self.spell(entry['proc_spell'], 'SpellName[enUS]'))
                self.assertEqual(entry['internal_cooldown_ms'], 0)

    def test_lightkeeper_entries_share_the_aura_and_the_periodic_condemn_trigger(self):
        entries = [entry for entry in CLASS_FILE['procs'] if entry['aura'] == LIGHTKEEPER]
        self.assertEqual(len(entries), 2)
        self.assertEqual({entry['proc_spell'] for entry in entries}, {LIGHTKEEPER_PARRY, LIGHTKEEPER_BURST})
        for entry in entries:
            with self.subTest(proc_spell=entry['proc_spell']):
                self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': CONDEMN})
                self.assertTrue(shares_aura(CLASS_FILE, entry))

    def test_proc_label_disambiguates_lightkeeper_by_proc_spell(self):
        parry, burst = (next(entry for entry in CLASS_FILE['procs']
                             if entry['aura'] == LIGHTKEEPER and entry['proc_spell'] == proc_spell)
                       for proc_spell in (LIGHTKEEPER_PARRY, LIGHTKEEPER_BURST))
        [parry_expectation] = proc_scenario(CLASS_FILE, parry)[1]
        [burst_expectation] = proc_scenario(CLASS_FILE, burst)[1]
        self.assertNotEqual(parry_expectation.label, burst_expectation.label)
        self.assertEqual(parry_expectation.label, proc_label(LIGHTKEEPER, LIGHTKEEPER_PARRY))
        self.assertEqual(burst_expectation.label, proc_label(LIGHTKEEPER, LIGHTKEEPER_BURST))

    def test_proc_label_is_unchanged_for_a_single_proc_spell_aura(self):
        entry = templar_proc(SCOURGEBANE)
        self.assertFalse(shares_aura(CLASS_FILE, entry))
        [expectation] = proc_scenario(CLASS_FILE, entry)[1]
        self.assertEqual(expectation.label, PROC_LABEL)

    def test_class_entry_resolves_the_lightkeeper_entry_by_proc_spell(self):
        burst = next(entry for entry in CLASS_FILE['procs']
                    if entry['aura'] == LIGHTKEEPER and entry['proc_spell'] == LIGHTKEEPER_BURST)
        [expectation] = proc_scenario(CLASS_FILE, burst)[1]
        manifest = {'class_file': CLASS_FILE}
        self.assertEqual(class_entry(manifest, expectation)['proc_spell'], LIGHTKEEPER_BURST)

    def test_pulverizing_rolls_on_condemn_damage_ticks_not_casts(self):
        entry = templar_proc(PULVERIZING)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': CONDEMN, 'target': 'dummy'})
        self.assertEqual(entry['event_metric'], 'spell_damage_count')
        self.assertEqual(entry['proc_spell'], PULVERIZING_STRIKE)
        self.assertEqual(entry['dbc'][str(PULVERIZING)]['ProcChance'], 15)

    def test_might_of_aggramar_rolls_on_auto_attacks_only(self):
        entry = templar_proc(MIGHT_OF_AGGRAMAR)
        self.assertEqual(entry['trigger'], {'action': 'attack', 'spell': 0})
        self.assertEqual(entry['proc_spell'], MIGHT_OF_AGGRAMAR_STACK)
        self.assertEqual(entry['dbc'][str(MIGHT_OF_AGGRAMAR)]['ProcFlags'], 4)
        self.assertNotIn('trial_readings', entry)
        self.assertNotIn('readings_question', entry)
        [expectation] = proc_scenario(CLASS_FILE, entry)[1]
        trials_label = expectation.model['measurements']['trials']
        self.assertEqual(expectation.model['readings'], [{'name': 'triggering hits only', 'labels': [trials_label],
                         'minus_events': False}])

    def test_might_of_aggramar_entries_share_the_aura_and_the_proc_spell_but_differ_by_trigger(self):
        entries = [entry for entry in CLASS_FILE['procs'] if entry['aura'] == MIGHT_OF_AGGRAMAR]
        self.assertEqual(len(entries), 2)
        self.assertEqual({entry['proc_spell'] for entry in entries}, {MIGHT_OF_AGGRAMAR_STACK})
        triggers = {entry['trigger']['action'] for entry in entries}
        self.assertEqual(triggers, {'attack', 'cast'})
        spell_entry = next(entry for entry in entries if entry['trigger']['action'] == 'cast')
        self.assertEqual(spell_entry['trigger']['spell'], RIGHTEOUS_UPHEAVAL)
        for entry in entries:
            with self.subTest(trigger=entry['trigger']):
                self.assertTrue(shares_aura(CLASS_FILE, entry))
                self.assertTrue(shares_proc_spell(CLASS_FILE, entry))

    def test_proc_label_disambiguates_might_of_aggramar_by_trigger(self):
        attack, cast = (next(entry for entry in CLASS_FILE['procs']
                             if entry['aura'] == MIGHT_OF_AGGRAMAR and entry['trigger']['action'] == action)
                        for action in ('attack', 'cast'))
        [attack_expectation] = proc_scenario(CLASS_FILE, attack)[1]
        [cast_expectation] = proc_scenario(CLASS_FILE, cast)[1]
        self.assertNotEqual(attack_expectation.label, cast_expectation.label)
        self.assertEqual(attack_expectation.label,
                         proc_label(MIGHT_OF_AGGRAMAR, MIGHT_OF_AGGRAMAR_STACK, trigger_key(attack)))
        self.assertEqual(cast_expectation.label,
                         proc_label(MIGHT_OF_AGGRAMAR, MIGHT_OF_AGGRAMAR_STACK, RIGHTEOUS_UPHEAVAL))

    def test_might_of_aggramar_cast_trigger_arms_the_weapon_the_spell_needs(self):
        cast = next(entry for entry in CLASS_FILE['procs']
                   if entry['aura'] == MIGHT_OF_AGGRAMAR and entry['trigger']['action'] == 'cast')
        scenario, _ = proc_scenario(CLASS_FILE, cast)
        equips = [step for step in scenario['steps'] if step['action'] == 'equip']
        self.assertEqual(equips[0]['item'], CLASS_FILE['alternate_weapons'][0]['item'])

    def test_might_of_aggramar_scenario_keys_do_not_collide(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-might-of-aggramar-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, procs=[MIGHT_OF_AGGRAMAR])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            keys = [entry['key'] for entry in manifest['scenarios']]
            self.assertEqual(len(keys), len(set(keys)))
            self.assertTrue(any('attack' in key for key in keys))
            self.assertTrue(any(str(RIGHTEOUS_UPHEAVAL) in key for key in keys))
        finally:
            shutil.rmtree(out)

    def test_lightkeeper_scenario_keys_do_not_collide(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-lightkeeper-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, procs=[LIGHTKEEPER])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            keys = [entry['key'] for entry in manifest['scenarios']]
            self.assertEqual(len(keys), len(set(keys)))
            self.assertTrue(any(str(LIGHTKEEPER_PARRY) in key for key in keys))
            self.assertTrue(any(str(LIGHTKEEPER_BURST) in key for key in keys))
        finally:
            shutil.rmtree(out)

    def test_condemnation_has_one_entry_per_named_trigger_spell(self):
        entries = [entry for entry in CLASS_FILE['procs'] if entry['aura'] == CONDEMNATION]
        self.assertEqual(len(entries), 3)
        self.assertEqual({entry['trigger']['spell'] for entry in entries}, {CONDEMN, 801445, BLADE_OF_FAITH})
        self.assertEqual({entry['proc_spell'] for entry in entries}, {ZEALOTRY_STRIKE})
        for entry in entries:
            with self.subTest(trigger=entry['trigger']):
                self.assertTrue(shares_aura(CLASS_FILE, entry))
                self.assertTrue(shares_proc_spell(CLASS_FILE, entry))
                self.assertTrue(entry['handler'])

    def test_proc_label_disambiguates_condemnation_by_trigger_spell(self):
        condemn, cleave, blade = (next(entry for entry in CLASS_FILE['procs']
                                       if entry['aura'] == CONDEMNATION and entry['trigger']['spell'] == spell)
                                  for spell in (CONDEMN, 801445, BLADE_OF_FAITH))
        labels = [proc_scenario(CLASS_FILE, entry)[1][0].label for entry in (condemn, cleave, blade)]
        self.assertEqual(len(labels), len(set(labels)))
        self.assertEqual(labels, [proc_label(CONDEMNATION, ZEALOTRY_STRIKE, CONDEMN),
                                  proc_label(CONDEMNATION, ZEALOTRY_STRIKE, 801445),
                                  proc_label(CONDEMNATION, ZEALOTRY_STRIKE, BLADE_OF_FAITH)])

    def test_condemnation_scenario_keys_do_not_collide(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-condemnation-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, procs=[CONDEMNATION])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            keys = [entry['key'] for entry in manifest['scenarios']]
            self.assertEqual(len(keys), len(set(keys)))
            self.assertTrue(any(str(CONDEMN) in key for key in keys))
            self.assertTrue(any('801445' in key for key in keys))
            self.assertTrue(any(str(BLADE_OF_FAITH) in key for key in keys))
        finally:
            shutil.rmtree(out)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GenerateProcTest(unittest.TestCase):
    def test_generate_writes_every_part(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-procs-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, procs=[SCOURGEBANE])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            self.assertEqual({entry['kind'] for entry in manifest['scenarios']}, {'proc'})
            parts = [entry for entry in manifest['scenarios'] if entry['file']]
            plan = proc_plan(CLASS_FILE, templar_proc(SCOURGEBANE))
            self.assertEqual(len(parts), plan.parts)
            for entry in parts:
                path = out / entry['file']
                text = path.read_text(encoding='utf-8')
                self.assertEqual(entry['sha256'], hashlib.sha256(text.encode('utf-8')).hexdigest())
                self.assertEqual(batch.exploratory_key(path, set()), entry['key'])
                self.assertEqual((entry['spell_id'], entry['spell_name']), (SCOURGEBANE, 'Scourgebane'))
            self.assertFalse([entry for entry in manifest['scenarios'] if not entry['file']])
        finally:
            shutil.rmtree(out)

    def test_unknown_proc_aura_is_refused(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-procs-'))
        try:
            with self.assertRaises(ValueError):
                generate(CLASS_FILE['class_id'], out, procs=[1])
        finally:
            shutil.rmtree(out)


if __name__ == '__main__':
    unittest.main()
