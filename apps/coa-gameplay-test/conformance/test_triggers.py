import copy
from dataclasses import asdict
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from compare import STATUSES, compare
from hits import MAX_SCENARIO_MS
from passives import cleaned_tooltip
from profile import DBC_DIR
from test_compare import CLASS_FILE, Workspace, assert_step, constant_reader
from tooltip import Records
from triggers import (BASELINE_ATTEMPTS, TRIGGER_CHECK, TRIGGER_TRIALS, trigger_entries, trigger_label,
                      trigger_measurements, trigger_plan, trigger_scenario, trigger_status_expectation)
from values import Expectation, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import batch
import run

TEMPLAR_TRIGGERS = {520812, 705274, 705290, 705295, 712677, 707606, 806273, 804932, 806516, 803158, 805420, 680891}
SCARLET_SECRETS = 520812
STAFFGUARD = 705295
CHAKRA_OF_POWER = 803158
SACRED_SWING = 572769
ARGENT_BLADE = 807268
LIBRAM_OF_TENACITY = 801461
OATH_CHAIN = 704576
OATH_OF_RETRIBUTION = 804924
SCHEDULED = 273
KEY = 'conformance-templar-trigger-520812-part-1'
SECOND_KEY = 'conformance-templar-trigger-520812-part-2'
LABELS = trigger_measurements(SCARLET_SECRETS)


def templar_trigger(aura):
    return next(entry for entry in CLASS_FILE['triggers'] if entry['aura'] == aura)


def trigger_model(per_trigger=0.5, part=0, parts=1, baseline=BASELINE_ATTEMPTS, attempts=SCHEDULED):
    return {'part': part, 'parts': parts, 'scheduled_attempts': SCHEDULED, 'part_attempts': attempts,
            'baseline_attempts': baseline, 'minimum_trials': TRIGGER_TRIALS, 'per_trigger': per_trigger,
            'trigger': {'action': 'cast', 'spell': ARGENT_BLADE, 'target': 'dummy'},
            'observe_spell': OATH_OF_RETRIBUTION, 'observe_metric': 'spell_cast_count', 'trial_metric': 'spell_cast_count', 'measurements': LABELS}


def trigger_expectation(**model):
    return Expectation(trigger_label(SCARLET_SECRETS), TRIGGER_CHECK, SCARLET_SECRETS, SCARLET_SECRETS, None,
                       'Every 2nd cast of Argent Blade', 'trigger rule', trigger_model(**model))


def trigger_steps(trials, events, without=0, baseline_trials=BASELINE_ATTEMPTS, aura=1):
    before = baseline_trials or 0
    steps = [assert_step(LABELS['aura'], str(aura)), assert_step(LABELS['trials'], str(trials + before)),
             assert_step(LABELS['events'], str(events + without))]
    if baseline_trials is not None:
        steps = [assert_step(LABELS['baseline_trials'], str(baseline_trials)),
                 assert_step(LABELS['without'], str(without))] + steps
    return steps


def casts_of(steps, spell):
    return sum(1 for step in steps if step['action'] == 'cast' and step['spell'] == spell)


class TrialsTest(unittest.TestCase):
    def test_trial_count(self):
        self.assertEqual(TRIGGER_TRIALS, math.ceil(math.log(0.01) / math.log(0.975)))
        self.assertEqual(TRIGGER_TRIALS, 182)
        self.assertEqual(BASELINE_ATTEMPTS, 20)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_staffguard_schedules_the_baseline_before_the_learn_and_the_margin_after_it(self):
        scenario, [expectation] = trigger_scenario(CLASS_FILE, templar_trigger(STAFFGUARD))
        run.validate(scenario)
        steps = scenario['steps']
        learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': STAFFGUARD})
        self.assertEqual(casts_of(steps[:learn], SACRED_SWING), BASELINE_ATTEMPTS)
        self.assertEqual(casts_of(steps[learn:], SACRED_SWING), SCHEDULED)
        self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)
        self.assertEqual((expectation.label, expectation.check), (trigger_label(STAFFGUARD), TRIGGER_CHECK))
        self.assertEqual((expectation.model['parts'], expectation.model['part_attempts'],
                          expectation.model['baseline_attempts']), (1, SCHEDULED, BASELINE_ATTEMPTS))
        auras = [step for step in steps if step['action'] == 'set_aura']
        self.assertEqual(len(auras), BASELINE_ATTEMPTS + SCHEDULED)
        self.assertTrue(all(step['spell'] == 681170 for step in auras))


class TriggerCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self):
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=constant_reader())
                    if verdict.check == TRIGGER_CHECK]
        self.assertEqual(len(verdicts), 1)
        self.assertIn(verdicts[0].status, STATUSES)
        return verdicts[0]

    def test_every_second_cast(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation()], steps=trigger_steps(273, 136))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (136, 136.5))
        self.assertEqual((verdict.low, verdict.high), (135.5, 137.5))

    def test_every_second_cast_missing_events_is_an_alert(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation()], steps=trigger_steps(273, 120))
        self.assertEqual(self.verdict().status, 'alert')

    def test_observable_without_the_passive_is_an_alert(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation()], steps=trigger_steps(273, 136, without=1))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('without the passive', verdict.explanation)

    def test_too_few_trials(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation()], steps=trigger_steps(150, 75))
        self.assertEqual(self.verdict().status, 'insufficient_trials')

    def test_baseline_without_trials_is_never_ok(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation()],
                                steps=trigger_steps(273, 136, baseline_trials=0))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('baseline', verdict.explanation)

    def test_absent_passive_aura_is_unmeasured(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation()], steps=trigger_steps(273, 0, aura=0))
        self.assertEqual(self.verdict().status, 'unmeasured')

    def test_parts_are_summed_and_only_the_first_holds_the_baseline(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation(parts=2, attempts=191)],
                                steps=trigger_steps(191, 95))
        self.workspace.scenario(SECOND_KEY, 'trigger', [trigger_expectation(part=1, parts=2, baseline=0, attempts=82)],
                                steps=trigger_steps(82, 41, baseline_trials=None))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (136, 136.5))
        self.assertIn('2 of 2 parts', verdict.explanation)

    def test_failed_trigger_casts_are_named(self):
        self.workspace.scenario(KEY, 'trigger', [trigger_expectation()], steps=trigger_steps(270, 135))
        self.workspace.cast_failures[KEY] = [{'spell': str(ARGENT_BLADE), 'reason': '22'}] * 3
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('3 x SPELL_FAILED_CASTER_AURASTATE (22)', verdict.explanation)

    def test_status_entry_is_judged_from_its_rule(self):
        entry = {'aura': SCARLET_SECRETS, 'trigger_text': 'Every 2nd cast of Argent Blade', 'status': 'unmodelled',
                 'reason': 'the trigger cast fails'}
        (self.workspace.root / 'out').mkdir(parents=True)
        self.workspace.scenarios.append({
            'key': 'conformance-templar-trigger-520812', 'file': None, 'sha256': None, 'kind': 'trigger',
            'spell_id': SCARLET_SECRETS, 'spell_name': 'Scarlet Secrets', 'rank_id': SCARLET_SECRETS, 'tokens': [],
            'expectations': [asdict(trigger_status_expectation(entry))]})
        manifest, results = self.workspace.manifest()
        [verdict] = compare(manifest, results, tooltips=constant_reader())
        self.assertEqual(verdict.status, 'unmodelled')
        self.assertIn('the trigger cast fails', verdict.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TemplarTriggerEntriesTest(unittest.TestCase):
    def setUp(self):
        self.records = Records(dataset(DBC_DIR))

    def spell(self, spell_id, field):
        return self.records.field('Spell', spell_id, field)

    def test_source_list_is_covered(self):
        self.assertEqual({entry['aura'] for entry in trigger_entries(CLASS_FILE)}, TEMPLAR_TRIGGERS)

    def test_entries_cite_the_dbc(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                description = self.spell(entry['aura'], 'Description[enUS]')
                self.assertEqual(entry['tooltip'], description)
                self.assertEqual(entry['name'], self.spell(entry['aura'], 'SpellName[enUS]'))
                cleaned = cleaned_tooltip(description)
                self.assertIn(entry['trigger_text'], cleaned)
                self.assertIn(entry['per_trigger_text'], cleaned)
                observed = entry['observe_spell']
                triggered = [self.spell(entry['aura'], f'EffectTriggerSpell[{index}]') for index in range(3)]
                if entry['observe_source'].startswith('EffectTriggerSpell'):
                    self.assertIn(observed, triggered)
                    self.assertEqual(entry['observe_source'],
                                     f'EffectTriggerSpell[{triggered.index(observed)}] of {entry["aura"]}')
                else:
                    self.assertEqual(entry['observe_source'], f'tooltip reference @s:{observed}:0@ of {entry["aura"]}')
                    self.assertIn(f'@s:{observed}:0@', description)
                    self.assertIn(self.spell(observed, 'SpellName[enUS]'), cleaned)
                    self.assertTrue(entry['observe_note'])
                self.assertEqual(self.spell(entry['aura'], 'ProcFlags'), 0)

    def test_attempt_auras_quote_the_tooltip_that_sets_them(self):
        for entry in trigger_entries(CLASS_FILE):
            for aura in entry.get('attempt_auras', []):
                with self.subTest(aura=entry['aura'], fixture=aura['spell']):
                    name, quote = aura['source'].split(f' {aura["spell"]}: ', 1)
                    self.assertEqual(name, self.spell(aura['spell'], 'SpellName[enUS]'))
                    self.assertIn(quote, cleaned_tooltip(self.spell(aura['spell'], 'Description[enUS]')))

    def test_cast_triggers_name_the_words_that_make_the_spell_a_trigger(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                trigger = entry['trigger']
                if trigger['action'] == 'attack':
                    self.assertIn(entry['trial_metric'], ('melee_attack_count', 'melee_damage_count'))
                    continue
                self.assertEqual(trigger['action'], 'cast')
                self.assertIn(trigger['target'], ('self', 'dummy'))
                spell = trigger['spell']
                own_text = self.spell(spell, 'SpellName[enUS]') + ' ' + cleaned_tooltip(
                    self.spell(spell, 'Description[enUS]'))
                self.assertIn(entry['trigger_spell_text'], own_text)
                self.assertIn(entry['trial_metric'], ('spell_cast_count', 'spell_damage_count'))

    def test_every_second_cast_is_the_only_half_rate(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                expected = 0.5 if entry['per_trigger_text'].startswith('Every 2nd') else 1
                self.assertEqual(entry['per_trigger'], expected)

    def test_every_entry_has_a_scenario_or_a_status(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                if entry.get('status'):
                    self.assertTrue(trigger_status_expectation(entry).rule.startswith(entry['status']))
                    continue
                plan = trigger_plan(CLASS_FILE, entry)
                self.assertEqual(sum(plan.part_attempts), SCHEDULED)
                for part in range(len(plan.part_attempts)):
                    scenario, _ = trigger_scenario(CLASS_FILE, entry, part)
                    run.validate(scenario)
                    self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)

    def test_auto_attack_trigger_splits_its_swings_and_keeps_the_baseline_in_the_first_part(self):
        entry = templar_trigger(CHAKRA_OF_POWER)
        plan = trigger_plan(CLASS_FILE, entry)
        self.assertGreater(len(plan.part_attempts), 1)
        first, _ = trigger_scenario(CLASS_FILE, entry, 0)
        second, [expectation] = trigger_scenario(CLASS_FILE, entry, 1)
        labels = trigger_measurements(CHAKRA_OF_POWER)
        first_labels = {step.get('label') for step in first['steps']}
        second_labels = {step.get('label') for step in second['steps']}
        self.assertTrue({labels['without'], labels['baseline_trials']} <= first_labels)
        self.assertFalse({labels['without'], labels['baseline_trials']} & second_labels)
        self.assertEqual(expectation.model['baseline_attempts'], 0)
        measured = {step['label']: step for step in first['steps'] if step['action'] == 'assert'}
        self.assertEqual((measured[labels['events']]['metric'], measured[labels['events']]['spell']),
                         ('spell_energize_count', 804181))
        self.assertEqual(measured[labels['trials']]['metric'], 'melee_attack_count')

    def test_scarlet_secrets_clears_the_oath_chain_before_every_argent_blade(self):
        scenario, [expectation] = trigger_scenario(CLASS_FILE, templar_trigger(SCARLET_SECRETS))
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), BASELINE_ATTEMPTS + SCHEDULED)
        for index in casts:
            self.assertIn({'action': 'set_aura', 'actor': 'caster', 'spell': OATH_CHAIN, 'stacks': 0},
                          steps[index - 2:index])
        self.assertEqual(expectation.model['observe_spell'], OATH_OF_RETRIBUTION)
        self.assertIn(f'aura {OATH_CHAIN} set to 0 stacks', expectation.rule)

    def test_attempt_auras_need_a_cast_trigger(self):
        entry = copy.deepcopy(templar_trigger(CHAKRA_OF_POWER))
        entry['attempt_auras'] = [{'spell': OATH_CHAIN, 'stacks': 0, 'source': 'test'}]
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_self_cast_trigger_has_no_target(self):
        scenario, _ = trigger_scenario(CLASS_FILE, templar_trigger(705274))
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertTrue(casts and all(step['spell'] == LIBRAM_OF_TENACITY and 'target' not in step for step in casts))
        resets = [step for step in scenario['steps'] if step['action'] == 'reset_cooldown']
        self.assertEqual(len(resets), BASELINE_ATTEMPTS + SCHEDULED)

    def test_unknown_aura_is_refused(self):
        with self.assertRaises(ValueError):
            trigger_entries(CLASS_FILE, [1])

    def test_status_entry_has_no_plan(self):
        entry = copy.deepcopy(templar_trigger(STAFFGUARD))
        entry.update(status='unmodelled', reason='the trigger cast fails')
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GenerateTriggerTest(unittest.TestCase):
    def test_generate_writes_every_part(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-triggers-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, triggers=[STAFFGUARD, CHAKRA_OF_POWER])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            self.assertEqual({entry['kind'] for entry in manifest['scenarios']}, {'trigger'})
            parts = len(trigger_plan(CLASS_FILE, templar_trigger(CHAKRA_OF_POWER)).part_attempts)
            self.assertEqual(len(manifest['scenarios']), 1 + parts)
            for entry in manifest['scenarios']:
                path = out / entry['file']
                text = path.read_text(encoding='utf-8')
                self.assertEqual(entry['sha256'], hashlib.sha256(text.encode('utf-8')).hexdigest())
                self.assertEqual(batch.exploratory_key(path, set()), entry['key'])
            self.assertIn('conformance-templar-trigger-705295-part-1',
                          {entry['key'] for entry in manifest['scenarios']})
        finally:
            shutil.rmtree(out)


if __name__ == '__main__':
    unittest.main()
