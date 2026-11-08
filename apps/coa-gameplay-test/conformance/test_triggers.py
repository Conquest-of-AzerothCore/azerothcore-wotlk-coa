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
from triggers import (BASELINE_ATTEMPTS, TRIGGER_CHECK, TRIGGER_TRIALS, attempt_interval, trigger_entries,
                      trigger_label, trigger_measurements, trigger_plan, trigger_rule, trigger_scenario,
                      trigger_status_expectation)
from values import Expectation, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import batch
import run

TEMPLAR_TRIGGERS = {520812, 705274, 705290, 705295, 712677, 707606, 806273, 804932, 806516, 803158, 805420, 680891,
                    803844, 803159, 301065, 801457, 301254, 705256, 705259, 705286, 705298, 705255,
                    680397, 524765, 560096, 707364, 504107, 706385, 523712, 520534}
GUARDIAN_OF_THE_LIGHT = 707364
DIVINE_FURY = 504107
UTHERS_LEGACY = 706385
IRON_PENANCE = 523712
VINDICATION_MAX_RANK = 573324
CONDEMN = 804906
IMPROVED_SCARLET_HAMMER = 301254
SCARLET_HAMMER = 807035
DETERMINED = 705256
TEMPLE_GUARDIAN = 803792
FAITH_GUARD = 705259
CHASTISE = 503141
LIBRAM_OF_CONSECRATION = 801441
DUTY_CALLS = 705286
RIGHTEOUS_LUNGE = 570233
UNTAINTED = 705298
DIVINE_STRIKES = 705255
SCOURGEBANE = 801832
DISCIPLINED_BLOWS = 680397
LIGHTS_GUIDANCE = 524765
DEVOTION_OF_KHAZGOROTH = 560096
SCARLET_SECRETS = 520812
STAFFGUARD = 705295
CHAKRA_OF_POWER = 803158
CHAKRA_OF_LIGHT_R1 = 803844
CHAKRA_OF_LIGHT_R2 = 803159
SCARLET_TRAINING = 301065
BINDING_SCRIPTURE = 801457
OATH_BREAKER_CAST = 572027
RIGHTEOUS_UPHEAVAL_HEAL = 803160
WARRIOR_OF_DAWN = 561156
SCARLET_CRUSADER = 301172
ARGENT_BLADE_RANK = 807268
TESTAMENT_OF_FAITH = 801478
DAMAGE_REDIRECT = 705309
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
    def test_attempt_interval_respects_internal_cooldown(self):
        entry = copy.deepcopy(templar_trigger(STAFFGUARD))
        without_cooldown = attempt_interval(CLASS_FILE, entry)
        entry['internal_cooldown_ms'] = without_cooldown + 5000
        self.assertEqual(attempt_interval(CLASS_FILE, entry), entry['internal_cooldown_ms'] + 500)

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
                self.assertEqual(self.spell(entry['aura'], 'ProcFlags'), entry.get('native_proc_flags', 0))

    def test_attempt_auras_quote_the_tooltip_that_sets_them(self):
        for entry in trigger_entries(CLASS_FILE):
            for aura in entry.get('attempt_auras', []):
                with self.subTest(aura=entry['aura'], fixture=aura['spell']):
                    name, quote = aura['source'].split(f' {aura["spell"]}: ', 1)
                    self.assertEqual(name, self.spell(aura['spell'], 'SpellName[enUS]'))
                    fixture_description = self.spell(aura['spell'], 'Description[enUS]')
                    source_tooltip = cleaned_tooltip(fixture_description) if fixture_description \
                        else cleaned_tooltip(entry['tooltip'])
                    self.assertIn(quote, source_tooltip)

    def test_cast_triggers_name_the_words_that_make_the_spell_a_trigger(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                trigger = entry['trigger']
                if trigger['action'] == 'attack':
                    self.assertIn(entry['trial_metric'], ('melee_attack_count', 'melee_damage_count'))
                    continue
                self.assertEqual(trigger['action'], 'cast')
                self.assertIn(trigger['target'], ('self', 'dummy', 'ally'))
                spell = trigger['spell']
                own_text = self.spell(spell, 'SpellName[enUS]') + ' ' + cleaned_tooltip(
                    self.spell(spell, 'Description[enUS]'))
                self.assertIn(entry['trigger_spell_text'], own_text)
                self.assertIn(entry['trial_metric'], ('spell_cast_count', 'spell_damage_count'))

    def test_every_second_cast_is_the_only_half_rate(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                if entry['per_trigger_text'].startswith('Every 2nd'):
                    expected = 0.5
                elif entry['per_trigger_text'].startswith('10 times'):
                    expected = 0.1
                else:
                    expected = 1
                self.assertEqual(entry['per_trigger'], expected)

    def test_divine_fury_and_iron_penance_share_the_vindication_driver(self):
        divine_fury, iron_penance = templar_trigger(DIVINE_FURY), templar_trigger(IRON_PENANCE)
        self.assertEqual(divine_fury['trigger']['spell'], VINDICATION_MAX_RANK)
        self.assertEqual(iron_penance['trigger']['spell'], VINDICATION_MAX_RANK)
        self.assertEqual(divine_fury['trigger'], iron_penance['trigger'])

    def test_uthers_legacy_waits_for_condemns_full_tick_spacing(self):
        entry = templar_trigger(UTHERS_LEGACY)
        self.assertEqual(entry['trigger']['spell'], CONDEMN)
        interval = attempt_interval(CLASS_FILE, entry)
        self.assertGreaterEqual(interval, 2 * 3000)
        plan = trigger_plan(CLASS_FILE, entry)
        self.assertEqual(plan.attempt_ms, interval)

    def test_every_entry_has_a_scenario_or_a_status(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                if entry.get('status'):
                    self.assertTrue(trigger_status_expectation(entry).rule.startswith(entry['status']))
                    continue
                plan = trigger_plan(CLASS_FILE, entry)
                self.assertEqual(sum(plan.part_attempts), SCHEDULED * entry.get('trial_attempts_factor', 1))
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

    def test_a_cast_trigger_equips_a_weapon_fitting_the_trigger_spell(self):
        entry = {'aura': STAFFGUARD, 'name': 'test', 'trigger': {'action': 'cast', 'spell': VINDICATION_MAX_RANK,
                                                                   'target': 'dummy'},
                 'trigger_text': 'test', 'trial_metric': 'spell_cast_count', 'observe_spell': ARGENT_BLADE,
                 'observe_source': 'test', 'observe_metric': 'spell_cast_count', 'per_trigger': 1,
                 'per_trigger_text': 'test'}
        scenario, _ = trigger_scenario(CLASS_FILE, entry)
        equips = [step for step in scenario['steps'] if step['action'] == 'equip']
        self.assertEqual(len(equips), 1)
        self.assertNotEqual(equips[0]['item'], CLASS_FILE['weapon']['item'])
        self.assertEqual(equips[0]['item'], CLASS_FILE['alternate_weapons'][0]['item'])

    def test_unknown_aura_is_refused(self):
        with self.assertRaises(ValueError):
            trigger_entries(CLASS_FILE, [1])

    def test_chakra_of_light_ranks_share_the_breaker_trigger_with_mending_ward(self):
        mending_ward = templar_trigger(806273)
        for aura in (CHAKRA_OF_LIGHT_R1, CHAKRA_OF_LIGHT_R2):
            with self.subTest(aura=aura):
                entry = templar_trigger(aura)
                self.assertEqual(entry['trigger'], mending_ward['trigger'])
                self.assertEqual(entry['trigger']['spell'], OATH_BREAKER_CAST)
                self.assertEqual(entry['observe_spell'], RIGHTEOUS_UPHEAVAL_HEAL)

    def test_scarlet_training_forces_warrior_of_dawn(self):
        entry = templar_trigger(SCARLET_TRAINING)
        [aura] = entry['attempt_auras']
        self.assertEqual(aura['spell'], WARRIOR_OF_DAWN)
        stack_amount = self.spell(WARRIOR_OF_DAWN, 'StackAmount')
        self.assertLessEqual(aura['stacks'], max(stack_amount, 1))
        self.assertEqual(entry['observe_spell'], SCARLET_CRUSADER)
        self.assertEqual(entry['trigger']['spell'], ARGENT_BLADE_RANK)

    def test_scarlet_training_doubles_its_scheduled_attempts(self):
        entry = templar_trigger(SCARLET_TRAINING)
        self.assertEqual(entry['trial_attempts_factor'], 2)
        self.assertTrue(entry['trial_attempts_reason'])
        plain = templar_trigger(STAFFGUARD)
        plan = trigger_plan(CLASS_FILE, entry)
        plain_plan = trigger_plan(CLASS_FILE, plain)
        self.assertEqual(plan.scheduled, plain_plan.scheduled * 2)
        self.assertIn(f'scheduled attempts x2 ({entry["trial_attempts_reason"]})', trigger_rule(entry))

    def test_trial_attempts_factor_below_one_is_refused(self):
        entry = copy.deepcopy(templar_trigger(STAFFGUARD))
        entry['trial_attempts_factor'] = 0.5
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_trial_attempts_factor_needs_a_reason(self):
        entry = copy.deepcopy(templar_trigger(STAFFGUARD))
        entry['trial_attempts_factor'] = 2
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_binding_scripture_groups_the_ally_once_and_lowers_her_health_before_every_heal(self):
        entry = templar_trigger(BINDING_SCRIPTURE)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': TESTAMENT_OF_FAITH, 'target': 'ally'})
        self.assertEqual(entry['observe_spell'], DAMAGE_REDIRECT)
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        steps = scenario['steps']
        groups = [step for step in steps if step['action'] == 'group']
        self.assertEqual(groups, [{'action': 'group', 'actor': 'caster', 'target': 'ally'}])
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally'])
        self.assertNotIn('creatures', scenario)
        casts = [index for index, step in enumerate(steps)
                if step['action'] == 'cast' and step['spell'] == TESTAMENT_OF_FAITH]
        self.assertTrue(casts)
        for index in casts:
            self.assertIn({'action': 'set_health', 'actor': 'ally', 'value': 5000, 'maximum': 10000},
                          steps[index - 2:index])
            self.assertEqual(steps[index]['target'], 'ally')
        self.assertIn('before each attempt the ally health set to 50% of max', expectation.rule)

    def test_ally_target_requires_a_cast_trigger(self):
        entry = copy.deepcopy(templar_trigger(BINDING_SCRIPTURE))
        entry['trigger'] = {'action': 'attack', 'spell': 0}
        entry['trial_metric'] = 'melee_attack_count'
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_ally_trigger_baseline_runs_before_the_learn_without_the_passive(self):
        entry = templar_trigger(BINDING_SCRIPTURE)
        scenario, _ = trigger_scenario(CLASS_FILE, entry)
        steps = scenario['steps']
        learn_aura = steps.index({'action': 'learn', 'actor': 'caster', 'spell': BINDING_SCRIPTURE})
        casts_before = [step for step in steps[:learn_aura]
                        if step['action'] == 'cast' and step['spell'] == TESTAMENT_OF_FAITH]
        self.assertEqual(len(casts_before), BASELINE_ATTEMPTS)
        labels = trigger_measurements(BINDING_SCRIPTURE)
        baseline_step = next(step for step in steps if step.get('label') == labels['without'])
        self.assertLess(steps.index(baseline_step), learn_aura)

    def test_improved_scarlet_hammer_observes_its_own_trigger_spell(self):
        entry = templar_trigger(IMPROVED_SCARLET_HAMMER)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': SCARLET_HAMMER, 'target': 'dummy'})
        self.assertEqual(entry['observe_spell'], 521240)
        self.assertEqual(self.spell(IMPROVED_SCARLET_HAMMER, 'EffectTriggerSpell[0]'), entry['observe_spell'])

    def test_determined_triggers_on_a_temple_guardian_charge_at_an_ally(self):
        entry = templar_trigger(DETERMINED)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': TEMPLE_GUARDIAN, 'target': 'ally'})
        self.assertEqual(entry['observe_spell'], 681136)
        self.assertTrue(entry['restore_charges'])
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        self.assertIn('ally', [player['id'] for player in scenario['players']])
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps)
                if step['action'] == 'cast' and step['spell'] == TEMPLE_GUARDIAN]
        self.assertTrue(casts)
        for index in casts:
            before = steps[index - 3:index]
            self.assertIn({'action': 'relocate', 'actor': 'caster', 'dx': 10}, before)
            self.assertIn({'action': 'restore_charges', 'actor': 'caster', 'spell': TEMPLE_GUARDIAN}, before)
        self.assertIn(f'the charges of {TEMPLE_GUARDIAN} are restored', expectation.rule)

    def test_binding_scripture_does_not_relocate_the_caster(self):
        entry = templar_trigger(BINDING_SCRIPTURE)
        scenario, _ = trigger_scenario(CLASS_FILE, entry)
        steps = scenario['steps']
        self.assertNotIn({'action': 'relocate', 'actor': 'caster', 'dx': 10}, steps)

    def test_restore_charges_needs_a_cast_trigger(self):
        entry = copy.deepcopy(templar_trigger(DETERMINED))
        entry['trigger'] = {'action': 'attack', 'spell': 0}
        entry['trial_metric'] = 'melee_attack_count'
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_faith_guard_sets_a_libram_attempt_aura(self):
        entry = templar_trigger(FAITH_GUARD)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': CHASTISE, 'target': 'dummy'})
        librams = {801441, 803890, 803891, 803892, 803893, 801461, 801463, 801466, 805423}
        [aura] = entry['attempt_auras']
        self.assertIn(aura['spell'], librams)
        self.assertEqual(aura['spell'], LIBRAM_OF_CONSECRATION)
        self.assertEqual(entry['observe_spell'], 706466)

    def test_duty_calls_trigger_spell_matches_family_mask(self):
        entry = templar_trigger(DUTY_CALLS)
        self.assertEqual(entry['trigger']['spell'], RIGHTEOUS_LUNGE)
        self.assertEqual(self.spell(RIGHTEOUS_LUNGE, 'SpellFamilyName'), 25)
        self.assertTrue(self.spell(RIGHTEOUS_LUNGE, 'SpellFamilyFlags[2]') & 1)
        self.assertEqual(entry['observe_spell'], 560834)

    def test_untainted_entry_has_a_matching_internal_cooldown(self):
        entry = templar_trigger(UNTAINTED)
        self.assertEqual(entry['internal_cooldown_ms'], 15000)
        self.assertIn('every 15 sec', entry['tooltip'].lower())
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': TEMPLE_GUARDIAN, 'target': 'ally'})
        self.assertTrue(entry['restore_charges'])
        self.assertEqual(entry['caster_health_pct'], 50)
        plan = trigger_plan(CLASS_FILE, entry)
        self.assertGreaterEqual(plan.attempt_ms, 15000)
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        self.assertIn('attempts spaced at least 15000 ms apart', expectation.rule)
        self.assertIn('the caster health set to 50% of max', expectation.rule)
        self.assertEqual(expectation.model['internal_cooldown_ms'], 15000)
        self.assertEqual(expectation.model['caster_health_pct'], 50)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps)
                if step['action'] == 'cast' and step['spell'] == TEMPLE_GUARDIAN]
        self.assertTrue(casts)
        for index in casts:
            self.assertIn({'action': 'set_health', 'actor': 'caster', 'value': 5000, 'maximum': 10000},
                          steps[index - 4:index])

    def test_divine_strikes_entry_uses_an_aura_apply_observe(self):
        entry = templar_trigger(DIVINE_STRIKES)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': CHASTISE, 'target': 'dummy'})
        self.assertEqual(entry['observe_metric'], 'aura_apply_count')
        self.assertEqual(entry['observe_actor'], 'target')
        self.assertEqual(entry['observe_spell'], 803372)
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        labels = trigger_measurements(DIVINE_STRIKES)
        measured = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertEqual(measured[labels['events']]['actor'], 'dummy')
        self.assertEqual(measured[labels['events']]['metric'], 'aura_apply_count')
        self.assertIn('on the target', expectation.rule)
        self.assertEqual(expectation.model['observe_actor'], 'target')

    def test_unknown_observe_actor_is_refused(self):
        entry = copy.deepcopy(templar_trigger(DIVINE_STRIKES))
        entry['observe_actor'] = 'ally'
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_lights_guidance_resets_health_before_every_benediction(self):
        entry = templar_trigger(LIGHTS_GUIDANCE)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': 578276, 'target': 'self'})
        self.assertEqual(entry['caster_health_pct'], 50)
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps)
                if step['action'] == 'cast' and step['spell'] == 578276]
        self.assertTrue(casts)
        for index in casts:
            self.assertIn({'action': 'set_health', 'actor': 'caster', 'value': 5000, 'maximum': 10000},
                         steps[index - 2:index])
        self.assertIn('the caster health set to 50% of max', expectation.rule)

    def test_disciplined_blows_stays_unmodelled_on_the_measured_double_count(self):
        entry = templar_trigger(DISCIPLINED_BLOWS)
        self.assertEqual(entry['status'], 'unmodelled')
        self.assertIn('546 casts of 680398 for 273 Benediction casts', entry['reason'])
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_devotion_of_khazgoroth_cites_its_native_proc_flags(self):
        entry = templar_trigger(DEVOTION_OF_KHAZGOROTH)
        self.assertEqual(entry['trigger'], {'action': 'attack', 'spell': 0})
        self.assertEqual(entry['trial_metric'], 'melee_attack_count')
        self.assertEqual(entry['native_proc_flags'], 4)
        self.assertEqual(entry['observe_spell'], 560097)
        records = Records(dataset(DBC_DIR))
        self.assertEqual(records.field('Spell', DEVOTION_OF_KHAZGOROTH, 'ProcFlags'), entry['native_proc_flags'])

    def test_native_proc_flags_defaults_to_the_dummied_zero(self):
        entry = copy.deepcopy(templar_trigger(CHAKRA_OF_POWER))
        self.assertNotIn('native_proc_flags', entry)
        records = Records(dataset(DBC_DIR))
        self.assertEqual(records.field('Spell', CHAKRA_OF_POWER, 'ProcFlags'), entry.get('native_proc_flags', 0))

    def test_caster_health_pct_needs_a_cast_trigger(self):
        entry = copy.deepcopy(templar_trigger(UNTAINTED))
        entry['trigger'] = {'action': 'attack', 'spell': 0}
        entry['trial_metric'] = 'melee_attack_count'
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

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
