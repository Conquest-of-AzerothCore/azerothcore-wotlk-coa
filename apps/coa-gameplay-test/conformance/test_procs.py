import copy
from dataclasses import asdict
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import sys
import tempfile
import unittest

from compare import STATUSES
from hits import EXCLUDED_OUTCOME_MARGIN, MAX_SCENARIO_MS, Unmodelled
from procs import PROC_CHECK, proc_plan, proc_scenario, proc_status_expectation, trials_needed, wilson_interval
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
RETRIBUTION = 707391
ARGENT_BLADE_MAX_RANK = 807268
SCOURGEBANE_STRIKE = 801832
CHANCE_TOKEN = '$520007h'
PROC_LABEL = '92111 proc_rate'
PROC_KEY = 'conformance-templar-proc-92111-part-1'
SECOND_KEY = 'conformance-templar-proc-92111-part-2'
LABELS = {'trials': '92111 proc trials', 'events': '92111 proc events', 'attempts': '92111 proc attempts',
          'aura': '92111 proc aura'}
TOKEN_SPELL = re.compile(r'\$(\d*)[hH]$')


def templar_proc(aura):
    return next(entry for entry in CLASS_FILE['procs'] if entry['aura'] == aura)


def proc_model(minimum=1699, parts=1, trigger=None, events_per_proc=1):
    return {'part': 0, 'parts': parts, 'chance_pct': 20.0, 'minimum_trials': minimum, 'scheduled_attempts': 2549,
            'part_attempts': 2549, 'attempt_ms': 2500, 'trigger': trigger or {'action': 'attack', 'spell': 0},
            'proc_spell': SCOURGEBANE_STRIKE, 'event_metric': 'spell_cast_count',
            'events_per_proc': events_per_proc, 'measurements': LABELS}


def proc_expectation(**model):
    return Expectation(PROC_LABEL, PROC_CHECK, SCOURGEBANE, SCOURGEBANE, None, CHANCE_TOKEN,
                       'Wilson 99% interval of the proc rate', proc_model(**model))


def proc_steps(trials, events, aura=1):
    return [assert_step(LABELS['aura'], str(aura)), assert_step(LABELS['trials'], str(trials)),
            assert_step(LABELS['events'], str(events)), assert_step(LABELS['attempts'], str(trials))]


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

    def test_statuses_include_every_proc_verdict(self):
        for status in ('ok', 'alert', 'ambiguous_tooltip', 'unmodelled', 'insufficient_trials', 'unmeasured'):
            self.assertIn(status, STATUSES)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ProcScenarioTest(unittest.TestCase):
    def test_scourgebane_schedules_the_margin_over_the_trials_in_parts_that_fit_the_timeout(self):
        entry = templar_proc(SCOURGEBANE)
        plan = proc_plan(CLASS_FILE, entry)
        self.assertEqual(plan.chance_pct, 20.0)
        self.assertEqual(plan.needed, 1699)
        self.assertEqual(plan.scheduled, math.ceil(1699 * EXCLUDED_OUTCOME_MARGIN))
        self.assertEqual(plan.attempt_ms, CLASS_FILE['weapon']['speed_ms'])
        self.assertGreaterEqual(plan.parts * plan.per_part, plan.scheduled)
        for part in range(plan.parts):
            scenario, expectations = proc_scenario(CLASS_FILE, entry, part)
            run.validate(scenario)
            self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)
            actions = [step['action'] for step in scenario['steps']]
            self.assertIn('attack', actions)
            self.assertEqual(scenario['steps'][actions.index('attack') + 1]['ms'], plan.per_part * plan.attempt_ms)
            measured = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
            self.assertEqual(measured['92111 proc trials']['metric'], 'melee_damage_count')
            self.assertEqual(measured['92111 proc events']['metric'], 'spell_cast_count')
            self.assertEqual(measured['92111 proc events']['spell'], SCOURGEBANE_STRIKE)
            self.assertEqual(measured['92111 proc aura']['metric'], 'aura')
            self.assertIn({'action': 'learn', 'actor': 'caster', 'spell': SCOURGEBANE}, scenario['steps'])
            [expectation] = expectations
            self.assertEqual((expectation.label, expectation.check, expectation.displayed),
                             (PROC_LABEL, PROC_CHECK, CHANCE_TOKEN))
            self.assertEqual((expectation.model['part'], expectation.model['parts']), (part, plan.parts))
            self.assertEqual(expectation.model['minimum_trials'], 1699)

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
        entry = next(entry for entry in CLASS_FILE['procs'] if entry.get('status'))
        with self.assertRaises(ValueError):
            proc_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TemplarProcEntriesTest(unittest.TestCase):
    def setUp(self):
        self.records = Records(dataset(DBC_DIR))

    def spell(self, spell_id, field):
        return self.records.field('Spell', spell_id, field)

    def test_source_list_is_covered(self):
        auras = {entry['aura'] for entry in CLASS_FILE['procs']}
        self.assertTrue({92111, 560648, 520017, 520883, 707391, 504808, 572548, 572554, 804571} <= auras)

    def test_every_entry_cites_its_dbc_tooltip_and_proc_fields(self):
        for entry in CLASS_FILE['procs']:
            with self.subTest(aura=entry['aura']):
                self.assertEqual(entry['tooltip'], self.spell(entry['aura'], 'Description[enUS]'))
                self.assertEqual(entry['name'], self.spell(entry['aura'], 'SpellName[enUS]'))
                self.assertIn(str(entry['aura']), entry['dbc'])
                for spell_id, fields in entry['dbc'].items():
                    for name in ('ProcChance', 'ProcFlags', 'ProcCharges'):
                        self.assertEqual(fields[name], self.spell(int(spell_id), name))
                token_spell = TOKEN_SPELL.match(entry['chance_token']).group(1) or str(entry['aura'])
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
                self.assertIn(entry['event_metric'], ('spell_cast_count', 'spell_damage_count'))
                self.assertTrue(self.spell(entry['proc_spell'], 'SpellName[enUS]'))
                self.assertEqual(entry['internal_cooldown_ms'], 0)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GenerateProcTest(unittest.TestCase):
    def test_generate_writes_every_part_and_the_status_entries(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-procs-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, procs=[SCOURGEBANE, 572548])
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
            [ambiguous] = [entry for entry in manifest['scenarios'] if not entry['file']]
            self.assertTrue(ambiguous['expectations'][0]['rule'].startswith('ambiguous_tooltip: '))
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
