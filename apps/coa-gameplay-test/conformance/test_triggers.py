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
from procs import ATTACK
from profile import DBC_DIR
from test_compare import CLASS_FILE, Workspace, assert_step, constant_reader
from tooltip import Records
from triggers import (BASELINE_ATTEMPTS, COOLDOWN_CHECK, COOLDOWN_DELTA_KIND, DURATION_CHECK, DURATION_DELTA_KIND,
                      MAIN_HAND, PERIODIC, TAKEN_HIT, TRIGGER_CHECK, TRIGGER_TRIALS, attempt_interval,
                      attempt_steps, checked_cooldown_entry, checked_duration_entry, checked_entry,
                      cooldown_label, cooldown_trial_label, cooldown_trial_steps, cooldown_trigger_rule,
                      cooldown_trigger_scenario, count_step, counts, duration_label, duration_trial_label,
                      duration_trial_steps, duration_trigger_rule, duration_trigger_scenario,
                      shares_cooldown_aura, trigger_entries,
                      trigger_label, trigger_measurements, trigger_plan, trigger_rule, trigger_scenario,
                      trigger_status_expectation)
from values import ALLY, FORCED_CRIT_RATING, Expectation, dataset

sys.path.append(str(Path(__file__).resolve().parents[1]))
import batch
import run

TEMPLAR_TRIGGERS = {520812, 705274, 705290, 705295, 712677, 707606, 806273, 804932, 806516, 803158, 805420, 680891,
                    803844, 803159, 301065, 801457, 301254, 705256, 705259, 705286, 705298, 705255,
                    680397, 524765, 560096, 707364, 504107, 706385, 523712, 520534, 504561, 504807, 500011,
                    92108, 92109, 300504, 300529, 301310, 680399, 681483, 704116, 804927, 805415, 806522, 705306,
                    804912, 573452}
ETERNALLY_DEVOTED = 573452
ETERNAL_BLESSING = 705300
LORESCRIBE = 804927
LORESCRIBE_DEAD_TRIGGER = 806089
LORESCRIBE_REDUCTION_SOURCE = 806106
SCARLET_CHAMPION = 805415
SCARLET_CHAMPION_STACK = 805416
LEGACY_OF_THE_SILVER_HAND = 806522
LEGACY_OF_THE_SILVER_HAND_CHARGES = 806523
RIGHTEOUS_UPHEAVAL = 572027
GUARDIAN_OF_THE_LIGHT = 707364
DIVINE_FURY = 504107
UTHERS_LEGACY = 706385
IRON_PENANCE = 523712
PRIEST_TRAINING = 504561
ONE_WITH_THE_LIGHT = 504807
VINDICATION_MAX_RANK = 573324
ZEALOTRY_HIT = 801450
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
PARRY_DANCE = 804912
SACRED_DEFENSE = 705306
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
KEEPING_THE_OATH = 92109
ZEALOTRY = 92108
WHIRLING_TEMPEST = 300504
LIGHTS_WARD = 300529
LIGHTS_CHOSEN = 301310
RIGHTEOUS_TEMPEST_CHANNEL = 805409
DISCIPLINED_MIND_681483 = 681483
BENEDICTION_RANK_60 = 578276
DISPEL_FOR_BENEDICTION = 525052
DELIVERANCE = 704116
DELIVERANCE_COPY = 801456
RIGHTEOUSNESS = 680891
KEY = 'conformance-templar-trigger-520812-part-1'
SECOND_KEY = 'conformance-templar-trigger-520812-part-2'
LABELS = trigger_measurements(SCARLET_SECRETS)


def templar_trigger(aura):
    return next(entry for entry in CLASS_FILE['triggers'] if entry['aura'] == aura)


def lorescribe_entries():
    entries = [entry for entry in CLASS_FILE['triggers'] if entry['aura'] == LORESCRIBE]
    return {entry['effect']: entry for entry in entries}


def eternally_devoted_entry():
    return templar_trigger(ETERNALLY_DEVOTED)


COOLDOWN_LABELS = {'aura': f'{LORESCRIBE} trigger cooldown aura'}
COOLDOWN_KEY = 'conformance-templar-trigger-804927-1-part-1'


def cooldown_model(part=0, parts=1, baseline=BASELINE_ATTEMPTS, attempts=SCHEDULED):
    return {'part': part, 'parts': parts, 'scheduled_attempts': SCHEDULED, 'part_attempts': attempts,
            'baseline_attempts': baseline, 'minimum_trials': TRIGGER_TRIALS,
            'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL, 'target': 'dummy'},
            'observe_spell': LIBRAM_OF_TENACITY, 'observe_metric': 'cooldown_ms', 'expected_delta_ms': 4000,
            'measurements': COOLDOWN_LABELS}


def cooldown_expectation(**model):
    return Expectation(cooldown_label(LORESCRIBE), COOLDOWN_CHECK, LORESCRIBE, LORESCRIBE, None,
                       'Casting Oath Breaker abilities', 'cooldown delta rule', cooldown_model(**model))


def cooldown_steps(baseline_deltas=(), measured_deltas=(), aura=1):
    full_cooldown = 180000.0
    steps = []
    for phase, deltas in (('baseline', baseline_deltas), ('measured', measured_deltas)):
        for index, delta in enumerate(deltas):
            steps.append(assert_step(cooldown_trial_label(LORESCRIBE, phase, index, 'before'), str(full_cooldown)))
            steps.append(assert_step(cooldown_trial_label(LORESCRIBE, phase, index, 'after'),
                                     str(full_cooldown - delta)))
    steps.append(assert_step(COOLDOWN_LABELS['aura'], str(aura)))
    return steps


def trigger_model(per_trigger=0.5, part=0, parts=1, baseline=BASELINE_ATTEMPTS, attempts=SCHEDULED):
    return {'part': part, 'parts': parts, 'scheduled_attempts': SCHEDULED, 'part_attempts': attempts,
            'baseline_attempts': baseline, 'minimum_trials': TRIGGER_TRIALS, 'per_trigger': per_trigger,
            'trigger': {'action': 'cast', 'spell': ARGENT_BLADE, 'target': 'dummy'},
            'observe_spell': OATH_OF_RETRIBUTION, 'observe_metric': 'spell_cast_count',
            'trial_metric': 'spell_cast_count', 'measurements': LABELS}


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


def generic_trigger_steps(aura, trials, events, without=0, baseline_trials=BASELINE_ATTEMPTS, learned=1):
    labels = trigger_measurements(aura)
    before = baseline_trials or 0
    steps = [assert_step(labels['aura'], str(learned)), assert_step(labels['trials'], str(trials + before)),
             assert_step(labels['events'], str(events + without))]
    if baseline_trials is not None:
        steps = [assert_step(labels['baseline_trials'], str(baseline_trials)),
                 assert_step(labels['without'], str(without))] + steps
    return steps


class TrialsTest(unittest.TestCase):
    def test_trial_count(self):
        self.assertEqual(TRIGGER_TRIALS, math.ceil(math.log(0.01) / math.log(0.975)))
        self.assertEqual(TRIGGER_TRIALS, 182)
        self.assertEqual(BASELINE_ATTEMPTS, 20)

    def test_count_step_defaults_to_main_hand_with_no_trial_metric_fields(self):
        step = count_step('label', 'melee_damage_count', 0)
        self.assertEqual(step, {'action': 'assert', 'label': 'label', 'actor': 'caster',
                                'metric': 'melee_damage_count', 'hand': MAIN_HAND,
                                'min': -1000000000, 'max': 1000000000})

    def test_count_step_merges_trial_metric_fields_without_dropping_hand(self):
        step = count_step('label', 'melee_damage_count', 0, trial_metric_fields={'critical': True})
        self.assertEqual(step['hand'], MAIN_HAND)
        self.assertTrue(step['critical'])

    def test_count_step_trial_metric_fields_can_override_hand(self):
        step = count_step('label', 'melee_damage_count', 0, trial_metric_fields={'hand': 1})
        self.assertEqual(step['hand'], 1)

    def test_count_step_ignores_trial_metric_fields_on_a_non_melee_metric(self):
        step = count_step('label', 'spell_cast_count', 42, trial_metric_fields={'critical': True})
        self.assertNotIn('critical', step)

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


class CooldownDeltaEntryTest(unittest.TestCase):
    def cooldown_entry(self):
        return lorescribe_entries()[1]

    def dead_entry(self):
        return lorescribe_entries()[0]

    def test_lorescribe_has_exactly_two_entries_for_its_two_effects(self):
        entries = lorescribe_entries()
        self.assertEqual(set(entries), {0, 1})
        self.assertEqual(entries[0]['aura'], LORESCRIBE)
        self.assertEqual(entries[1]['aura'], LORESCRIBE)

    def test_lorescribe_e0_is_a_dead_effect_with_no_trigger_field(self):
        entry = self.dead_entry()
        self.assertEqual(entry['status'], 'unmodelled')
        self.assertNotIn('trigger', entry)
        self.assertEqual(entry['observe_spell'], LORESCRIBE_DEAD_TRIGGER)
        self.assertEqual(entry['observe_source'], f'EffectTriggerSpell[0] of {LORESCRIBE}')
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_lorescribe_cooldown_entry_has_the_cooldown_delta_kind(self):
        entry = self.cooldown_entry()
        self.assertEqual(entry['kind'], COOLDOWN_DELTA_KIND)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL, 'target': 'dummy'})
        self.assertEqual(entry['observe_spell'], LIBRAM_OF_TENACITY)
        self.assertEqual(entry['observe_metric'], 'cooldown_ms')
        self.assertEqual(entry['expected_delta_ms'], 4000)

    def test_checked_cooldown_entry_rejects_a_count_based_observe_metric(self):
        entry = copy.deepcopy(self.cooldown_entry())
        entry['observe_metric'] = 'spell_cast_count'
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_checked_cooldown_entry_rejects_a_non_cast_trigger(self):
        entry = copy.deepcopy(self.cooldown_entry())
        entry['trigger'] = {'action': ATTACK}
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_checked_cooldown_entry_rejects_a_non_positive_expected_delta(self):
        entry = copy.deepcopy(self.cooldown_entry())
        entry['expected_delta_ms'] = 0
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_checked_cooldown_entry_accepts_the_lorescribe_entry(self):
        self.assertIs(checked_cooldown_entry(self.cooldown_entry()), self.cooldown_entry())

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trial_steps_reset_cast_measure_cast_measure_per_attempt(self):
        entry = self.cooldown_entry()
        steps = cooldown_trial_steps(CLASS_FILE, entry, 2, 'measured')
        actions = [step['action'] for step in steps]
        self.assertEqual(actions.count('cast'), 4)
        self.assertEqual(actions.count('reset_cooldown'), 4)
        first_cast = actions.index('cast')
        self.assertEqual(steps[first_cast]['spell'], LIBRAM_OF_TENACITY)
        before_label = cooldown_trial_label(LORESCRIBE, 'measured', 0, 'before')
        after_label = cooldown_trial_label(LORESCRIBE, 'measured', 0, 'after')
        before_index = next(i for i, step in enumerate(steps) if step.get('label') == before_label)
        after_index = next(i for i, step in enumerate(steps) if step.get('label') == after_label)
        self.assertLess(before_index, after_index)
        second_cast = actions.index('cast', first_cast + 1)
        self.assertEqual(steps[second_cast]['spell'], RIGHTEOUS_UPHEAVAL)
        self.assertEqual(steps[second_cast]['target'], 'dummy')
        self.assertLess(before_index, second_cast)
        self.assertLess(second_cast, after_index)

    def test_cooldown_trial_steps_empty_for_zero_attempts(self):
        self.assertEqual(cooldown_trial_steps(CLASS_FILE, self.cooldown_entry(), 0, 'baseline'), [])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trigger_scenario_schedules_the_baseline_before_the_learn(self):
        entry = self.cooldown_entry()
        scenario, [expectation] = cooldown_trigger_scenario(CLASS_FILE, entry, part=0)
        run.validate(scenario)
        steps = scenario['steps']
        learn_aura = steps.index({'action': 'learn', 'actor': 'caster', 'spell': LORESCRIBE})
        before_baseline = [step for step in steps[:learn_aura]
                           if step.get('metric') == 'cooldown_ms' and step['label'].startswith(f'{LORESCRIBE} '
                                                                                                f'trigger cooldown '
                                                                                                f'baseline')]
        before_measured = [step for step in steps[learn_aura:]
                           if step.get('metric') == 'cooldown_ms' and step['label'].startswith(f'{LORESCRIBE} '
                                                                                                f'trigger cooldown '
                                                                                                f'measured')]
        self.assertEqual(len(before_baseline), BASELINE_ATTEMPTS * 2)
        self.assertEqual(len(before_measured), expectation.model['part_attempts'] * 2)
        self.assertEqual((expectation.label, expectation.check), (cooldown_label(LORESCRIBE), COOLDOWN_CHECK))
        self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trigger_scenario_part_without_baseline_has_no_baseline_labels(self):
        entry = self.cooldown_entry()
        scenario, [expectation] = cooldown_trigger_scenario(CLASS_FILE, entry, part=1)
        steps = scenario['steps']
        self.assertFalse(any(step.get('label', '').startswith(f'{LORESCRIBE} trigger cooldown baseline')
                             for step in steps))
        self.assertEqual(expectation.model['baseline_attempts'], 0)


class CooldownDeltaSetupCastsTest(unittest.TestCase):
    def entry(self):
        return eternally_devoted_entry()

    def test_eternally_devoted_entry_sets_up_a_cast_of_eternal_blessing(self):
        entry = self.entry()
        self.assertEqual(entry['kind'], COOLDOWN_DELTA_KIND)
        self.assertEqual(entry['setup_casts'], [ETERNAL_BLESSING])

    def test_checked_cooldown_entry_rejects_a_non_integer_setup_cast_spell(self):
        entry = copy.deepcopy(self.entry())
        entry['setup_casts'] = ['705300']
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_checked_cooldown_entry_accepts_the_eternally_devoted_entry(self):
        self.assertIs(checked_cooldown_entry(self.entry()), self.entry())

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trigger_scenario_learns_setup_casts_once_up_front(self):
        entry = self.entry()
        scenario, _ = cooldown_trigger_scenario(CLASS_FILE, entry, part=0)
        steps = scenario['steps']
        learn_aura = steps.index({'action': 'learn', 'actor': 'caster', 'spell': ETERNALLY_DEVOTED})
        learn_setup = steps.index({'action': 'learn', 'actor': 'caster', 'spell': ETERNAL_BLESSING})
        self.assertLess(learn_setup, learn_aura)
        run.validate(scenario)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trial_steps_cast_the_setup_spell_before_the_observed_and_trigger_casts(self):
        entry = self.entry()
        steps = cooldown_trial_steps(CLASS_FILE, entry, 2, 'measured')
        casts = [step['spell'] for step in steps if step['action'] == 'cast']
        self.assertEqual(casts, [ETERNAL_BLESSING, LIBRAM_OF_TENACITY, RIGHTEOUS_UPHEAVAL] * 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trial_steps_cast_the_setup_spell_in_the_baseline_too(self):
        entry = self.entry()
        steps = cooldown_trial_steps(CLASS_FILE, entry, 1, 'baseline')
        casts = [step['spell'] for step in steps if step['action'] == 'cast']
        self.assertEqual(casts, [ETERNAL_BLESSING, LIBRAM_OF_TENACITY, RIGHTEOUS_UPHEAVAL])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trial_steps_spend_the_setup_wait_only_once(self):
        entry = self.entry()
        steps = cooldown_trial_steps(CLASS_FILE, entry, 1, 'measured')
        self.assertEqual(sum(step.get('ms', 0) for step in steps if step['action'] == 'wait'),
                         attempt_interval(CLASS_FILE, entry))

    def test_cooldown_trigger_rule_names_the_setup_cast_spell(self):
        self.assertIn(f'{ETERNAL_BLESSING} is reset and cast at self', cooldown_trigger_rule(self.entry()))


HOLY_COMBATANT = 500011
ARGENT_BLADE_AT_60 = 807268
INTERDICT = 560116
ONE_WITH_THE_LIGHT = 504807


class CooldownDeltaLabelDisambiguationTest(unittest.TestCase):
    def two_entries(self, aura=ONE_WITH_THE_LIGHT):
        base = {'aura': aura, 'kind': COOLDOWN_DELTA_KIND, 'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL,
                                                                       'target': 'dummy'},
               'observe_metric': 'cooldown_ms', 'expected_delta_ms': 1000}
        return {'triggers': [{**base, 'effect': 0, 'observe_spell': 1}, {**base, 'effect': 1, 'observe_spell': 2}]}

    def test_shares_cooldown_aura_true_for_two_entries_of_the_same_aura(self):
        class_file = self.two_entries()
        self.assertTrue(shares_cooldown_aura(class_file, class_file['triggers'][0]))
        self.assertTrue(shares_cooldown_aura(class_file, class_file['triggers'][1]))

    def test_shares_cooldown_aura_false_for_a_sole_entry(self):
        entry = self.cooldown_entry()
        self.assertFalse(shares_cooldown_aura(CLASS_FILE, entry))

    def cooldown_entry(self):
        return templar_trigger(LORESCRIBE)

    def test_cooldown_label_with_observe_spell_is_distinct_per_entry(self):
        self.assertNotEqual(cooldown_label(ONE_WITH_THE_LIGHT, 1), cooldown_label(ONE_WITH_THE_LIGHT, 2))
        self.assertEqual(cooldown_label(ONE_WITH_THE_LIGHT), '504807 trigger_cooldown_delta')
        self.assertEqual(cooldown_label(ONE_WITH_THE_LIGHT, 801461), '504807 trigger_cooldown_delta 801461')


class OneWithTheLightCooldownEntryTest(unittest.TestCase):
    def entry(self):
        return templar_trigger(ONE_WITH_THE_LIGHT)

    def cooldown_entries(self):
        return [entry for entry in CLASS_FILE['triggers'] if entry['aura'] == ONE_WITH_THE_LIGHT
               and entry.get('kind') == COOLDOWN_DELTA_KIND]

    def test_exactly_one_new_cooldown_delta_entry_covers_effect_2(self):
        entries = self.cooldown_entries()
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]['effect'], 2)
        self.assertEqual(entries[0]['observe_spell'], LIBRAM_OF_TENACITY)

    def test_effect_0_has_no_new_entry_and_is_closed_via_unmodelled_effects(self):
        self.assertFalse(any(entry.get('effect') == 0 and entry.get('kind') == COOLDOWN_DELTA_KIND
                             for entry in CLASS_FILE['triggers'] if entry['aura'] == ONE_WITH_THE_LIGHT))
        override = next(entry for entry in CLASS_FILE['unmodelled_effects']
                        if entry['spell'] == ONE_WITH_THE_LIGHT and entry['effect'] == 0)
        self.assertIn('SPELL_FAILED_NOT_READY', override['reason'])

    def test_checked_entry_accepts_the_new_cooldown_entry(self):
        entry = self.cooldown_entries()[0]
        self.assertIs(checked_entry(entry), entry)


class HolyCombatantDurationEntryTest(unittest.TestCase):
    def entry(self):
        return templar_trigger(HOLY_COMBATANT)

    def test_entry_has_the_duration_delta_kind(self):
        entry = self.entry()
        self.assertEqual(entry['kind'], DURATION_DELTA_KIND)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': ARGENT_BLADE_AT_60, 'target': 'dummy'})
        self.assertEqual(entry['observe_spell'], INTERDICT)
        self.assertEqual(entry['observe_metric'], 'aura_duration_ms')
        self.assertEqual(entry['expected_delta_ms'], 1000)
        self.assertGreater(entry['decay_wait_ms'], entry['expected_delta_ms'])

    def test_checked_duration_entry_accepts_the_entry(self):
        self.assertIs(checked_duration_entry(self.entry()), self.entry())

    def test_checked_duration_entry_rejects_a_non_cast_trigger(self):
        entry = copy.deepcopy(self.entry())
        entry['trigger'] = {'action': ATTACK}
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_checked_duration_entry_rejects_a_non_duration_observe_metric(self):
        entry = copy.deepcopy(self.entry())
        entry['observe_metric'] = 'cooldown_ms'
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_checked_duration_entry_rejects_a_non_positive_expected_delta(self):
        entry = copy.deepcopy(self.entry())
        entry['expected_delta_ms'] = 0
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_checked_duration_entry_rejects_a_decay_wait_not_exceeding_the_expected_delta(self):
        entry = copy.deepcopy(self.entry())
        entry['decay_wait_ms'] = entry['expected_delta_ms']
        with self.assertRaises(ValueError):
            checked_entry(entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_duration_trial_steps_cast_observe_wait_decay_then_cast_trigger(self):
        entry = self.entry()
        steps = duration_trial_steps(CLASS_FILE, entry, 1, 'measured')
        actions = [step['action'] for step in steps]
        self.assertEqual(actions.count('cast'), 2)
        first_cast = actions.index('cast')
        self.assertEqual(steps[first_cast]['spell'], INTERDICT)
        decay_wait = next(step for step in steps if step.get('label') == 'measureddecay')
        self.assertEqual(decay_wait['ms'], entry['decay_wait_ms'])
        before_label = duration_trial_label(HOLY_COMBATANT, 'measured', 0, 'before')
        after_label = duration_trial_label(HOLY_COMBATANT, 'measured', 0, 'after')
        before_index = next(i for i, step in enumerate(steps) if step.get('label') == before_label)
        after_index = next(i for i, step in enumerate(steps) if step.get('label') == after_label)
        second_cast = actions.index('cast', first_cast + 1)
        self.assertEqual(steps[second_cast]['spell'], ARGENT_BLADE_AT_60)
        self.assertLess(before_index, second_cast)
        self.assertLess(second_cast, after_index)

    def test_duration_trial_steps_empty_for_zero_attempts(self):
        self.assertEqual(duration_trial_steps(CLASS_FILE, self.entry(), 0, 'baseline'), [])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_duration_trigger_scenario_schedules_the_baseline_before_the_learn(self):
        entry = self.entry()
        scenario, [expectation] = duration_trigger_scenario(CLASS_FILE, entry, part=0)
        run.validate(scenario)
        steps = scenario['steps']
        learn_aura = steps.index({'action': 'learn', 'actor': 'caster', 'spell': HOLY_COMBATANT})
        before_baseline = [step for step in steps[:learn_aura]
                           if step.get('metric') == 'aura_duration_ms'
                           and step['label'].startswith(f'{HOLY_COMBATANT} trigger duration baseline')]
        before_measured = [step for step in steps[learn_aura:]
                           if step.get('metric') == 'aura_duration_ms'
                           and step['label'].startswith(f'{HOLY_COMBATANT} trigger duration measured')]
        self.assertEqual(len(before_baseline), BASELINE_ATTEMPTS * 2)
        self.assertEqual(len(before_measured), expectation.model['part_attempts'] * 2)
        self.assertEqual((expectation.label, expectation.check), (duration_label(HOLY_COMBATANT), DURATION_CHECK))
        self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_duration_trigger_scenario_part_without_baseline_has_no_baseline_labels(self):
        entry = self.entry()
        scenario, [expectation] = duration_trigger_scenario(CLASS_FILE, entry, part=1)
        steps = scenario['steps']
        self.assertFalse(any(step.get('label', '').startswith(f'{HOLY_COMBATANT} trigger duration baseline')
                             for step in steps))
        self.assertEqual(expectation.model['baseline_attempts'], 0)


class ScarletChampionLegacyEntriesTest(unittest.TestCase):
    def test_scarlet_champion_forces_a_melee_crit_on_the_trigger_cast(self):
        entry = templar_trigger(SCARLET_CHAMPION)
        self.assertEqual(entry['force_crit'], 'melee')
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': ARGENT_BLADE_RANK, 'target': 'dummy'})
        self.assertEqual(entry['trial_metric'], 'spell_damage_count')
        self.assertEqual(entry['internal_cooldown_ms'], 1000)
        self.assertEqual(entry['observe_spell'], SCARLET_CHAMPION_STACK)

    def test_scarlet_champion_scenario_forces_melee_crit_rating(self):
        scenario, _ = trigger_scenario(CLASS_FILE, templar_trigger(SCARLET_CHAMPION))
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)

    def test_legacy_of_the_silver_hand_is_a_plain_cast_trigger(self):
        entry = templar_trigger(LEGACY_OF_THE_SILVER_HAND)
        self.assertNotIn('force_crit', entry)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': ARGENT_BLADE_RANK, 'target': 'dummy'})
        self.assertEqual(entry['trial_metric'], 'spell_cast_count')
        self.assertEqual(entry['observe_spell'], LEGACY_OF_THE_SILVER_HAND_CHARGES)

    def test_legacy_of_the_silver_hand_scenario_builds_and_validates(self):
        scenario, [expectation] = trigger_scenario(CLASS_FILE, templar_trigger(LEGACY_OF_THE_SILVER_HAND))
        run.validate(scenario)
        self.assertEqual((expectation.label, expectation.check),
                         (trigger_label(LEGACY_OF_THE_SILVER_HAND), TRIGGER_CHECK))


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

    def periodic_entry(self, initial_tick):
        return {'aura': LIGHTS_WARD, 'name': "Light's Ward", 'tooltip': '', 'trigger_text': '',
                'trigger_spell_text': '', 'trigger': {'action': PERIODIC, 'amplitude_ms': 2000},
                'trial_metric': 'spell_cast_count', 'observe_spell': 301283, 'observe_source': 'none',
                'observe_metric': 'spell_cast_count', 'per_trigger': 1, 'per_trigger_text': '',
                'periodic_initial_tick': initial_tick}

    def test_periodic_trigger_judges_events_against_the_known_attempt_count(self):
        entry = self.periodic_entry(initial_tick=False)
        plan = trigger_plan(CLASS_FILE, entry)
        first_attempts, second_attempts = plan.part_attempts
        labels = trigger_measurements(LIGHTS_WARD)
        first, [first_exp] = trigger_scenario(CLASS_FILE, entry, 0)
        second, [second_exp] = trigger_scenario(CLASS_FILE, entry, 1)
        self.workspace.scenario('conformance-templar-trigger-300529-part-1', 'trigger', [first_exp], steps=[
            assert_step(labels['baseline_trials'], str(BASELINE_ATTEMPTS)), assert_step(labels['without'], '0'),
            assert_step(labels['events'], str(first_attempts)), assert_step(labels['aura'], '1')])
        self.workspace.scenario('conformance-templar-trigger-300529-part-2', 'trigger', [second_exp], steps=[
            assert_step(labels['events'], str(second_attempts)), assert_step(labels['aura'], '1')])
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (plan.scheduled, plan.scheduled))

    def test_periodic_initial_tick_adds_one_event_per_counted_part(self):
        entry = self.periodic_entry(initial_tick=True)
        plan = trigger_plan(CLASS_FILE, entry)
        first_attempts, second_attempts = plan.part_attempts
        labels = trigger_measurements(LIGHTS_WARD)
        first, [first_exp] = trigger_scenario(CLASS_FILE, entry, 0)
        second, [second_exp] = trigger_scenario(CLASS_FILE, entry, 1)
        self.workspace.scenario('conformance-templar-trigger-300529-part-1', 'trigger', [first_exp], steps=[
            assert_step(labels['baseline_trials'], str(BASELINE_ATTEMPTS)), assert_step(labels['without'], '0'),
            assert_step(labels['events'], str(first_attempts + 1)), assert_step(labels['aura'], '1')])
        self.workspace.scenario('conformance-templar-trigger-300529-part-2', 'trigger', [second_exp], steps=[
            assert_step(labels['events'], str(second_attempts + 1)), assert_step(labels['aura'], '1')])
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.expected, plan.scheduled + 2)

    def test_periodic_initial_tick_without_the_extra_event_is_an_alert(self):
        entry = self.periodic_entry(initial_tick=True)
        plan = trigger_plan(CLASS_FILE, entry)
        first_attempts, second_attempts = plan.part_attempts
        labels = trigger_measurements(LIGHTS_WARD)
        first, [first_exp] = trigger_scenario(CLASS_FILE, entry, 0)
        second, [second_exp] = trigger_scenario(CLASS_FILE, entry, 1)
        self.workspace.scenario('conformance-templar-trigger-300529-part-1', 'trigger', [first_exp], steps=[
            assert_step(labels['baseline_trials'], str(BASELINE_ATTEMPTS)), assert_step(labels['without'], '0'),
            assert_step(labels['events'], str(first_attempts)), assert_step(labels['aura'], '1')])
        self.workspace.scenario('conformance-templar-trigger-300529-part-2', 'trigger', [second_exp], steps=[
            assert_step(labels['events'], str(second_attempts)), assert_step(labels['aura'], '1')])
        self.assertEqual(self.verdict().status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_disciplined_mind_681483_absent_dispel_cast_alerts(self):
        entry = copy.deepcopy(templar_trigger(DISCIPLINED_MIND_681483))
        entry['observe_spell'] = 1
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        key = f'conformance-templar-trigger-{DISCIPLINED_MIND_681483}-part-1'
        self.workspace.scenario(key, 'trigger', [expectation],
                                steps=generic_trigger_steps(DISCIPLINED_MIND_681483, SCHEDULED, 0))
        self.assertEqual(self.verdict().status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_deliverance_absent_crit_copy_alerts(self):
        entry = copy.deepcopy(templar_trigger(DELIVERANCE))
        entry['observe_spell'] = 1
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        key = f'conformance-templar-trigger-{DELIVERANCE}-part-1'
        self.workspace.scenario(key, 'trigger', [expectation],
                                steps=generic_trigger_steps(DELIVERANCE, SCHEDULED, 0))
        self.assertEqual(self.verdict().status, 'alert')


class CooldownTriggerCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self):
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=constant_reader())
                    if verdict.check == COOLDOWN_CHECK]
        self.assertEqual(len(verdicts), 1)
        self.assertIn(verdicts[0].status, STATUSES)
        return verdicts[0]

    def test_mean_delta_within_tolerance_is_ok(self):
        self.workspace.scenario(COOLDOWN_KEY, 'trigger', [cooldown_expectation()],
                                steps=cooldown_steps(baseline_deltas=[0] * BASELINE_ATTEMPTS,
                                                     measured_deltas=[4000] * SCHEDULED))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (4000, 4000))

    def test_absent_effect_measured_delta_zero_is_an_alert(self):
        self.workspace.scenario(COOLDOWN_KEY, 'trigger', [cooldown_expectation()],
                                steps=cooldown_steps(baseline_deltas=[0] * BASELINE_ATTEMPTS,
                                                     measured_deltas=[0] * SCHEDULED))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('outside', verdict.explanation)

    def test_nonzero_baseline_delta_is_an_alert(self):
        self.workspace.scenario(COOLDOWN_KEY, 'trigger', [cooldown_expectation()],
                                steps=cooldown_steps(baseline_deltas=[4000] + [0] * (BASELINE_ATTEMPTS - 1),
                                                     measured_deltas=[4000] * SCHEDULED))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('baseline trial without the passive', verdict.explanation)

    def test_too_few_measured_trials_is_insufficient(self):
        self.workspace.scenario(COOLDOWN_KEY, 'trigger',
                                [cooldown_expectation(attempts=TRIGGER_TRIALS - 1)],
                                steps=cooldown_steps(baseline_deltas=[0] * BASELINE_ATTEMPTS,
                                                     measured_deltas=[4000] * (TRIGGER_TRIALS - 1)))
        self.assertEqual(self.verdict().status, 'insufficient_trials')

    def test_absent_passive_aura_is_unmeasured(self):
        self.workspace.scenario(COOLDOWN_KEY, 'trigger', [cooldown_expectation()],
                                steps=cooldown_steps(baseline_deltas=[0] * BASELINE_ATTEMPTS, aura=0))
        self.assertEqual(self.verdict().status, 'unmeasured')

    def test_baseline_without_trials_is_never_ok(self):
        self.workspace.scenario(COOLDOWN_KEY, 'trigger', [cooldown_expectation(baseline=0)],
                                steps=cooldown_steps(measured_deltas=[4000] * SCHEDULED))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('baseline', verdict.explanation)

    def test_parts_are_summed_and_only_the_first_holds_the_baseline(self):
        second_key = 'conformance-templar-trigger-804927-1-part-2'
        self.workspace.scenario(COOLDOWN_KEY, 'trigger', [cooldown_expectation(parts=2, attempts=150)],
                                steps=cooldown_steps(baseline_deltas=[0] * BASELINE_ATTEMPTS,
                                                     measured_deltas=[4000] * 150))
        self.workspace.scenario(second_key, 'trigger',
                                [cooldown_expectation(part=1, parts=2, baseline=0, attempts=SCHEDULED - 150)],
                                steps=cooldown_steps(measured_deltas=[4000] * (SCHEDULED - 150)))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('2 parts', verdict.explanation)


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
                if entry.get('kind') in (COOLDOWN_DELTA_KIND, DURATION_DELTA_KIND):
                    self.assertTrue(entry['observe_source'])
                    self.assertNotIn(observed, triggered)
                elif entry['observe_source'].startswith('EffectTriggerSpell'):
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
                if 'trigger' not in entry:
                    self.assertTrue(entry.get('status'))
                    continue
                trigger = entry['trigger']
                if trigger['action'] == 'attack':
                    self.assertIn(entry['trial_metric'], ('melee_attack_count', 'melee_damage_count'))
                    continue
                if trigger['action'] == PERIODIC:
                    self.assertGreater(trigger['amplitude_ms'], 0)
                    self.assertEqual(entry['trial_metric'], 'spell_cast_count')
                    continue
                if trigger['action'] == TAKEN_HIT:
                    self.assertEqual(entry['trial_metric'], 'spell_damage_count')
                    self.assertGreater(trigger['striker_entry'], 0)
                    continue
                self.assertEqual(trigger['action'], 'cast')
                self.assertIn(trigger['target'], ('self', 'dummy', 'ally'))
                spell = trigger['spell']
                own_text = self.spell(spell, 'SpellName[enUS]') + ' ' + cleaned_tooltip(
                    self.spell(spell, 'Description[enUS]'))
                self.assertIn(entry['trigger_spell_text'], own_text)
                if entry.get('kind') == COOLDOWN_DELTA_KIND:
                    self.assertEqual(entry['observe_metric'], 'cooldown_ms')
                    continue
                if entry.get('kind') == DURATION_DELTA_KIND:
                    self.assertEqual(entry['observe_metric'], 'aura_duration_ms')
                    continue
                self.assertIn(entry['trial_metric'], ('spell_cast_count', 'spell_damage_count'))

    def test_every_second_cast_is_the_only_half_rate(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                if entry.get('kind') in (COOLDOWN_DELTA_KIND, DURATION_DELTA_KIND):
                    continue
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

    def test_priest_training_reads_zealotry_hits_instead_of_the_vindication_ratio(self):
        entry = templar_trigger(PRIEST_TRAINING)
        self.assertNotIn('status', entry)
        self.assertEqual(entry['trigger']['spell'], VINDICATION_MAX_RANK)
        self.assertEqual(entry['trial_metric'], 'spell_damage_count')
        self.assertEqual(entry['trial_spell'], ZEALOTRY_HIT)
        plan = trigger_plan(CLASS_FILE, entry)
        self.assertEqual(sum(plan.part_attempts), SCHEDULED)

    def test_iron_penance_reads_zealotry_hits_instead_of_the_vindication_ratio(self):
        entry = templar_trigger(IRON_PENANCE)
        self.assertNotIn('status', entry)
        self.assertEqual(entry['trigger']['spell'], VINDICATION_MAX_RANK)
        self.assertEqual(entry['trial_metric'], 'spell_damage_count')
        self.assertEqual(entry['trial_spell'], ZEALOTRY_HIT)
        plan = trigger_plan(CLASS_FILE, entry)
        self.assertEqual(sum(plan.part_attempts), SCHEDULED)

    def test_one_with_the_light_zealotry_effect_stays_unmodelled(self):
        entry = templar_trigger(ONE_WITH_THE_LIGHT)
        self.assertEqual(entry['status'], 'unmodelled')
        self.assertEqual(entry['observe_spell'], 801450)
        self.assertEqual(entry['observe_source'], f'EffectTriggerSpell[1] of {ONE_WITH_THE_LIGHT}')
        self.assertIn('0 casts of 801450', entry['reason'])
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

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
                scenario_fn = {COOLDOWN_DELTA_KIND: cooldown_trigger_scenario,
                              DURATION_DELTA_KIND: duration_trigger_scenario}.get(entry.get('kind'),
                                                                                  trigger_scenario)
                for part in range(len(plan.part_attempts)):
                    scenario, _ = scenario_fn(CLASS_FILE, entry, part)
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

    def test_parry_dance_crit_leg_trial_counts_only_critical_melee_damage(self):
        entry = templar_trigger(PARRY_DANCE)
        self.assertEqual(entry['trial_metric'], 'melee_damage_count')
        self.assertEqual(entry['trial_metric_fields'], {'critical': True})
        self.assertEqual(entry['force_crit'], 'melee')
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry, 0)
        run.validate(scenario)
        labels = trigger_measurements(PARRY_DANCE)
        measured = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertEqual(measured[labels['trials']]['metric'], 'melee_damage_count')
        self.assertTrue(measured[labels['trials']]['critical'])
        self.assertEqual(measured[labels['trials']]['hand'], MAIN_HAND)
        self.assertEqual((measured[labels['events']]['metric'], measured[labels['events']]['spell']),
                         ('spell_cast_count', 560651))
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)

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

    def test_trial_metric_fields_need_a_melee_trial_metric(self):
        entry = copy.deepcopy(templar_trigger(STAFFGUARD))
        entry['trial_metric_fields'] = {'critical': True}
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_trial_spell_needs_a_cast_or_taken_hit_action(self):
        entry = copy.deepcopy(templar_trigger(LIGHTS_WARD))
        entry['trial_spell'] = 801450
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_trial_spell_needs_a_spell_damage_count_trial_metric(self):
        entry = copy.deepcopy(templar_trigger(IRON_PENANCE))
        entry['status'], entry['reason'] = None, None
        entry['trial_metric'] = 'spell_cast_count'
        entry['trial_spell'] = 801450
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_trial_spell_must_be_an_integer(self):
        entry = copy.deepcopy(templar_trigger(IRON_PENANCE))
        entry['status'], entry['reason'] = None, None
        entry['trial_metric'] = 'spell_damage_count'
        entry['trial_spell'] = '801450'
        with self.assertRaises(ValueError):
            checked_entry(entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_trial_spell_overrides_the_trigger_spell_in_the_trial_count_and_rule(self):
        entry = copy.deepcopy(templar_trigger(IRON_PENANCE))
        entry['status'], entry['reason'] = None, None
        entry['trial_metric'] = 'spell_damage_count'
        entry['trial_spell'] = 801450
        checked_entry(entry)
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        labels = trigger_measurements(IRON_PENANCE)
        measured = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertEqual((measured[labels['trials']]['metric'], measured[labels['trials']]['spell']),
                         ('spell_damage_count', 801450))
        casts = {step['spell'] for step in scenario['steps'] if step['action'] == 'cast'}
        self.assertIn(VINDICATION_MAX_RANK, casts)
        self.assertNotIn(801450, casts)
        self.assertIn('spell_damage_count of 801450', expectation.rule)

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
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': ARGENT_BLADE_RANK, 'target': 'dummy'})
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

    def test_divine_strikes_co_learns_righteousness_before_the_first_cast(self):
        entry = templar_trigger(DIVINE_STRIKES)
        self.assertEqual(entry['co_learn'], [RIGHTEOUSNESS])
        scenario, expectations = trigger_scenario(CLASS_FILE, entry)
        steps = scenario['steps']
        learn_aura = steps.index({'action': 'learn', 'actor': 'caster', 'spell': DIVINE_STRIKES})
        co_learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': RIGHTEOUSNESS})
        trigger_cast_after_learn = steps[learn_aura:].index(
            {'action': 'cast', 'actor': 'caster', 'spell': ARGENT_BLADE_RANK, 'target': 'dummy'}) + learn_aura
        self.assertLess(learn_aura, co_learn)
        self.assertLess(co_learn, trigger_cast_after_learn)
        self.assertIn(f'; {DIVINE_STRIKES} also learns {RIGHTEOUSNESS}', expectations[0].rule)

    def test_without_co_learn_the_scenario_omits_righteousness(self):
        entry = copy.deepcopy(templar_trigger(DIVINE_STRIKES))
        del entry['co_learn']
        scenario, expectations = trigger_scenario(CLASS_FILE, entry)
        self.assertNotIn({'action': 'learn', 'actor': 'caster', 'spell': RIGHTEOUSNESS}, scenario['steps'])
        self.assertNotIn('also learns', expectations[0].rule)

    def test_disciplined_mind_681483_entry_casts_at_an_ally(self):
        entry = templar_trigger(DISCIPLINED_MIND_681483)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': BENEDICTION_RANK_60, 'target': 'ally'})
        self.assertEqual(entry['observe_spell'], DISPEL_FOR_BENEDICTION)
        self.assertEqual(entry['observe_metric'], 'spell_cast_count')
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry)
        steps = scenario['steps']
        self.assertIn({'action': 'group', 'actor': 'caster', 'target': ALLY}, steps)
        casts = [index for index, step in enumerate(steps)
                if step['action'] == 'cast' and step['spell'] == BENEDICTION_RANK_60]
        self.assertTrue(casts)
        for index in casts:
            self.assertEqual(steps[index]['target'], ALLY)
        self.assertEqual(expectation.model['observe_spell'], DISPEL_FOR_BENEDICTION)

    def test_deliverance_force_crit_is_melee(self):
        entry = templar_trigger(DELIVERANCE)
        self.assertEqual(entry['force_crit'], 'melee')
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': VINDICATION_MAX_RANK, 'target': 'dummy'})
        self.assertEqual(entry['observe_spell'], DELIVERANCE_COPY)

    def test_deliverance_force_crit_rating_overrides_melee_crit_rating_without_touching_the_class_file(self):
        entry = templar_trigger(DELIVERANCE)
        scenario, _ = trigger_scenario(CLASS_FILE, entry)
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)
        self.assertNotIn('melee_crit_rating', CLASS_FILE.get('ratings', {}))

    def test_force_crit_outside_the_known_kinds_is_refused(self):
        entry = copy.deepcopy(templar_trigger(DELIVERANCE))
        entry['force_crit'] = 'ranged'
        with self.assertRaises(ValueError):
            checked_entry(entry)

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

    def test_disciplined_blows_is_checked_after_the_round5_type_mask_fix(self):
        entry = templar_trigger(DISCIPLINED_BLOWS)
        self.assertNotIn('status', entry)
        self.assertNotIn('reason', entry)
        self.assertEqual(entry['per_trigger'], 1)
        self.assertIn('546 casts of 680398 for 273', entry['fix_note'])
        self.assertIn('DONE_HIT_PROC_FLAG_MASK', entry['fix_note'])
        plan = trigger_plan(CLASS_FILE, entry)
        self.assertGreater(plan.scheduled, 0)

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

    def test_keeping_the_oath_and_zealotry_stay_unmodelled(self):
        for aura in (KEEPING_THE_OATH, ZEALOTRY):
            with self.subTest(aura=aura):
                entry = templar_trigger(aura)
                self.assertEqual(entry['status'], 'unmodelled')
                self.assertNotIn('trigger', entry)
                with self.assertRaises(ValueError):
                    trigger_plan(CLASS_FILE, entry)

    def test_keeping_the_oath_is_reachable_through_its_own_spell_proc_row(self):
        entry = templar_trigger(KEEPING_THE_OATH)
        self.assertIn('rev_20261001_04_templar_keeping_the_oath_avoid.sql', entry['reason'])
        self.assertIn('PROC_HIT_DODGE|PROC_HIT_PARRY', entry['reason'])
        self.assertIn('no action in run.py', entry['reason'])

    def test_zealotry_is_reachable_but_the_harness_cannot_produce_an_off_hand_swing(self):
        entry = templar_trigger(ZEALOTRY)
        self.assertIn('rev_20260909_04_templar_completion.sql', entry['reason'])
        self.assertIn('OFF_ATTACK', entry['reason'])
        self.assertIn('CanDualWield', entry['reason'])
        self.assertIn('no path granting CanDualWield to Templar', entry['reason'])

    def test_periodic_trigger_interval_is_its_own_amplitude(self):
        for aura, amplitude in ((LIGHTS_WARD, 2000), (LIGHTS_CHOSEN, 5000)):
            with self.subTest(aura=aura):
                entry = templar_trigger(aura)
                self.assertEqual(entry['trigger'], {'action': PERIODIC, 'amplitude_ms': amplitude})
                self.assertEqual(attempt_interval(CLASS_FILE, entry), amplitude)

    def test_periodic_attempt_steps_only_wait(self):
        entry = templar_trigger(LIGHTS_WARD)
        plan = trigger_plan(CLASS_FILE, entry)
        steps = attempt_steps(CLASS_FILE, entry, plan, 5, '')
        self.assertEqual(steps, [{'action': 'wait', 'label': 'ticks', 'ms': 5 * plan.attempt_ms}])

    def test_periodic_trigger_has_no_trial_count_step_but_has_an_events_step(self):
        entry = templar_trigger(LIGHTS_CHOSEN)
        labels = trigger_measurements(entry['aura'])
        steps = counts(entry, labels['trials'], labels['events'])
        self.assertEqual(len(steps), 1)
        self.assertEqual(steps[0]['label'], labels['events'])

    def test_periodic_trigger_amplitude_must_be_positive(self):
        entry = copy.deepcopy(templar_trigger(LIGHTS_WARD))
        entry['trigger'] = {'action': PERIODIC, 'amplitude_ms': 0}
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_periodic_initial_tick_matches_the_dbc_attribute(self):
        extra_initial_period = 0x200
        for aura, initial_tick in ((LIGHTS_WARD, True), (LIGHTS_CHOSEN, False)):
            with self.subTest(aura=aura):
                entry = templar_trigger(aura)
                self.assertEqual(entry.get('periodic_initial_tick', False), initial_tick)
                attributes_ex5 = self.spell(aura, 'AttributesEx5')
                self.assertEqual(bool(attributes_ex5 & extra_initial_period), initial_tick)

    def test_whirling_tempest_observes_an_aura_apply_of_its_own_dbc_trigger(self):
        entry = templar_trigger(WHIRLING_TEMPEST)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': RIGHTEOUS_TEMPEST_CHANNEL, 'target': 'self'})
        self.assertEqual(entry['observe_metric'], 'aura_apply_count')
        self.assertEqual(entry['observe_spell'], 301340)

    def test_periodic_entry_builds_a_valid_scenario(self):
        for aura in (LIGHTS_WARD, LIGHTS_CHOSEN):
            with self.subTest(aura=aura):
                entry = templar_trigger(aura)
                scenario, [expectation] = trigger_scenario(CLASS_FILE, entry, 0)
                run.validate(scenario)
                self.assertNotIn('creatures', scenario)
                self.assertEqual(expectation.model['trigger']['action'], PERIODIC)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TakenHitTriggerTests(unittest.TestCase):
    def entry(self):
        return templar_trigger(SACRED_DEFENSE)

    def test_attempt_interval_folds_the_strikers_own_cast_time(self):
        entry = self.entry()
        interval = attempt_interval(CLASS_FILE, entry)
        self.assertGreater(interval, entry['internal_cooldown_ms'])

    def test_attempt_steps_build_a_striker_cast_loop_not_a_caster_loop(self):
        entry = self.entry()
        plan = trigger_plan(CLASS_FILE, entry)
        steps = attempt_steps(CLASS_FILE, entry, plan, 3, '')
        casts = [step for step in steps if step.get('action') == 'cast']
        self.assertEqual(len(casts), 3)
        for cast in casts:
            self.assertEqual(cast['actor'], 'striker')
            self.assertEqual(cast['target'], 'caster')
            self.assertEqual(cast['spell'], entry['trigger']['spell'])
        self.assertFalse(any(step.get('action') in ('attack', 'stop_attack') for step in steps))

    def test_counts_reads_the_strikers_spell_damage_on_the_caster(self):
        entry = self.entry()
        steps = counts(entry, 'trials', 'events')
        trial_step = steps[0]
        self.assertEqual(trial_step['actor'], 'caster')
        self.assertEqual(trial_step['caster'], 'striker')
        self.assertEqual(trial_step['target'], 'caster')
        self.assertEqual(trial_step['spell'], entry['trigger']['spell'])

    def test_scenario_adds_a_striker_creature_and_validates(self):
        scenario, [expectation] = trigger_scenario(CLASS_FILE, self.entry(), 0)
        run.validate(scenario)
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == 'striker')
        self.assertEqual(striker['entry'], self.entry()['trigger']['striker_entry'])
        self.assertEqual(expectation.check, TRIGGER_CHECK)

    def test_striker_entry_is_required(self):
        entry = copy.deepcopy(self.entry())
        entry['trigger'] = dict(entry['trigger'])
        del entry['trigger']['striker_entry']
        with self.assertRaises(ValueError):
            checked_entry(entry)

    def test_absent_passive_gives_zero_baseline_events(self):
        scenario, [expectation] = trigger_scenario(CLASS_FILE, self.entry(), 0)
        labels = expectation.model['measurements']
        learn_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('action') == 'learn' and step.get('spell') == SACRED_DEFENSE)
        baseline_events_index = next(index for index, step in enumerate(scenario['steps'])
                                    if step.get('label') == labels['without'])
        self.assertLess(baseline_events_index, learn_index)


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
