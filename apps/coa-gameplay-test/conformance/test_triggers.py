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

from compare import STATUSES, compare
from hits import MAX_SCENARIO_MS
from passives import cleaned_tooltip
from procs import ATTACK, CAST
from profile import DBC_DIR
from test_compare import CLASS_FILE, Workspace, assert_step, constant_reader
from tooltip import Records
from triggers import (BASELINE_ATTEMPTS, COOLDOWN_CHECK, COOLDOWN_DELTA_KIND, DURATION_CHECK, DURATION_DELTA_KIND,
                      GATE_ABSENCE_CHECK, GATE_ABSENCE_KIND, MAGNITUDE_CHECK, MAGNITUDE_RATIO_KIND, MAIN_HAND,
                      PERIODIC, SELF_TRIGGER_CHECK,
                      SELF_TRIGGER_KIND, TAKEN_HIT, TRIGGER_CHECK,
                      TRIGGER_TRIALS, attempt_interval,
                      attempt_steps, checked_cooldown_entry, checked_duration_entry, checked_entry,
                      checked_gate_absence_entry, checked_magnitude_entry, checked_self_trigger_entry,
                      checked_trigger_set,
                      cooldown_label, cooldown_trial_label, cooldown_trial_steps, cooldown_trigger_rule,
                      cooldown_trigger_scenario, count_step, counts, duration_label, duration_trial_label,
                      duration_trial_steps, duration_trigger_rule, duration_trigger_scenario,
                      gate_absence_label, gate_absence_rule, gate_absence_scenario,
                      magnitude_label, magnitude_measurement_labels, magnitude_ratio_scenario,
                      magnitude_trigger_rule,
                      self_trigger_label, self_trigger_rule, self_trigger_scenario,
                      shares_cooldown_aura, shares_cooldown_effect, shares_trigger_aura, trigger_entries,
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
                    804912, 573452, 707391, 801466, 500678, 573324, 706325, 572741}
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
HOLY_CLEAVE = 801445
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
DUAL_WIELD = 674
LIBRAM_OF_ZEAL = 801466
RIGHTEOUS_UPHEAVAL_501562 = 501562
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
RETRIBUTION = 707391
HOLY_SCHOOL_MASK = 2
RETRIBUTION_EXTRA_STRIKE = 525028
TESTAMENT_OF_FORTITUDE = 500678
SACRED_RESTRAINT = 102208
KEY = 'conformance-templar-trigger-520812-part-1'
SECOND_KEY = 'conformance-templar-trigger-520812-part-2'
LABELS = trigger_measurements(SCARLET_SECRETS)


def templar_trigger(aura):
    return next(entry for entry in CLASS_FILE['triggers'] if entry['aura'] == aura)


def first_index(steps: list[dict], **match) -> int:
    return next(index for index, step in enumerate(steps) if all(step.get(k) == v for k, v in match.items()))


def templar_gate_trigger(aura):
    return next(entry for entry in CLASS_FILE['triggers']
               if entry['aura'] == aura and entry.get('kind') == GATE_ABSENCE_KIND)


def templar_magnitude_trigger(aura):
    return next(entry for entry in CLASS_FILE['triggers']
               if entry['aura'] == aura and entry.get('kind') == MAGNITUDE_RATIO_KIND)


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


MAGNITUDE_LABELS = magnitude_measurement_labels(DELIVERANCE)
MAGNITUDE_KEY = f'conformance-templar-trigger-{DELIVERANCE}-1-part-1'


def magnitude_model(part=0, parts=1, attempts=SCHEDULED, expected_ratio=0.5, observe_metric='spell_damage_total'):
    return {'part': part, 'parts': parts, 'scheduled_attempts': SCHEDULED, 'part_attempts': attempts,
            'minimum_trials': TRIGGER_TRIALS, 'trigger': {'action': 'cast', 'spell': VINDICATION_MAX_RANK,
            'target': 'dummy'}, 'trigger_metric': 'spell_damage_total', 'observe_spell': DELIVERANCE_COPY,
            'observe_metric': observe_metric, 'expected_ratio': expected_ratio, 'force_crit': 'melee',
            'measurements': MAGNITUDE_LABELS}


def magnitude_expectation(**model):
    return Expectation(magnitude_label(DELIVERANCE), MAGNITUDE_CHECK, DELIVERANCE, DELIVERANCE, None,
                       'Critically striking with Vindication or Righteous Lunge', 'magnitude rule',
                       magnitude_model(**model))


def magnitude_steps(trigger_total, observe_total, trigger_count=SCHEDULED, observe_count=None, aura=1):
    observe_count = trigger_count if observe_count is None else observe_count
    return [assert_step(MAGNITUDE_LABELS['trigger_total'], str(trigger_total)),
            assert_step(MAGNITUDE_LABELS['trigger_count'], str(trigger_count)),
            assert_step(MAGNITUDE_LABELS['observe_total'], str(observe_total)),
            assert_step(MAGNITUDE_LABELS['observe_count'], str(observe_count)),
            assert_step(MAGNITUDE_LABELS['aura'], str(aura))]


RETRIBUTION_LABELS = magnitude_measurement_labels(RETRIBUTION)
RETRIBUTION_KEY = f'conformance-templar-trigger-{RETRIBUTION}-1-part-1'


def retribution_magnitude_model(part=0, parts=1, attempts=SCHEDULED, expected_ratio=0.3):
    return {'part': part, 'parts': parts, 'scheduled_attempts': SCHEDULED, 'part_attempts': attempts,
            'minimum_trials': TRIGGER_TRIALS, 'trigger': {'action': 'attack', 'spell': 0},
            'trigger_metric': 'melee_damage_total', 'observe_spell': RETRIBUTION_EXTRA_STRIKE,
            'observe_metric': 'spell_damage_total', 'expected_ratio': expected_ratio, 'force_crit': None,
            'measurements': RETRIBUTION_LABELS}


def retribution_magnitude_expectation(**model):
    return Expectation(magnitude_label(RETRIBUTION), MAGNITUDE_CHECK, RETRIBUTION, RETRIBUTION, None,
                       'Melee damage dealt', 'magnitude rule', retribution_magnitude_model(**model))


def retribution_magnitude_steps(trigger_total, observe_total, trigger_count, observe_count, aura=1):
    return [assert_step(RETRIBUTION_LABELS['trigger_total'], str(trigger_total)),
            assert_step(RETRIBUTION_LABELS['trigger_count'], str(trigger_count)),
            assert_step(RETRIBUTION_LABELS['observe_total'], str(observe_total)),
            assert_step(RETRIBUTION_LABELS['observe_count'], str(observe_count)),
            assert_step(RETRIBUTION_LABELS['aura'], str(aura))]


RETRIBUTION_TARGET_LABELS = {'armor': 'target armor', 'view_level': 'target view_level',
                             'resistance 1': 'target resistance 1'}


def resisted_retribution_magnitude_expectation():
    model = {**retribution_magnitude_model(), 'resisted_school_mask': HOLY_SCHOOL_MASK, 'caster_level': 60,
             'target_measurements': RETRIBUTION_TARGET_LABELS}
    return Expectation(magnitude_label(RETRIBUTION), MAGNITUDE_CHECK, RETRIBUTION, RETRIBUTION, None,
                       'Melee damage dealt', 'magnitude rule', model)


def resisted_retribution_magnitude_steps(observe_total, view_level=60, holy_resistance=0):
    return retribution_magnitude_steps(trigger_total=10000, trigger_count=200, observe_total=observe_total,
                                       observe_count=200) + [
        assert_step(RETRIBUTION_TARGET_LABELS['armor'], '528'),
        assert_step(RETRIBUTION_TARGET_LABELS['view_level'], str(view_level)),
        assert_step(RETRIBUTION_TARGET_LABELS['resistance 1'], str(holy_resistance))]


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

    def two_entries_same_effect(self, aura=ONE_WITH_THE_LIGHT):
        base = {'aura': aura, 'kind': COOLDOWN_DELTA_KIND, 'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL,
                                                                       'target': 'dummy'},
               'observe_metric': 'cooldown_ms', 'expected_delta_ms': 1000}
        return {'triggers': [{**base, 'effect': 0, 'observe_spell': 1}, {**base, 'effect': 0, 'observe_spell': 2}]}

    def test_shares_cooldown_effect_true_for_two_entries_of_the_same_aura_and_effect(self):
        class_file = self.two_entries_same_effect()
        self.assertTrue(shares_cooldown_effect(class_file, class_file['triggers'][0]))
        self.assertTrue(shares_cooldown_effect(class_file, class_file['triggers'][1]))

    def test_shares_cooldown_effect_false_for_two_entries_of_the_same_aura_but_different_effect(self):
        class_file = self.two_entries()
        self.assertFalse(shares_cooldown_effect(class_file, class_file['triggers'][0]))
        self.assertFalse(shares_cooldown_effect(class_file, class_file['triggers'][1]))

    def test_shares_cooldown_effect_false_for_a_sole_entry(self):
        self.assertFalse(shares_cooldown_effect(CLASS_FILE, self.cooldown_entry()))

    def test_cooldown_label_with_observe_spell_is_distinct_per_entry(self):
        self.assertNotEqual(cooldown_label(ONE_WITH_THE_LIGHT, 1), cooldown_label(ONE_WITH_THE_LIGHT, 2))
        self.assertEqual(cooldown_label(ONE_WITH_THE_LIGHT), '504807 trigger_cooldown_delta')
        self.assertEqual(cooldown_label(ONE_WITH_THE_LIGHT, 801461), '504807 trigger_cooldown_delta 801461')


FERVENT_CASTIGATION = 707606
BLESSING_OF_EONAR = 705290
BLADE_OF_FAITH = 803880
SILVERHAND_INCANTATION = 801465


class TriggerCountLabelDisambiguationTest(unittest.TestCase):
    def two_entries(self, aura=FERVENT_CASTIGATION):
        base = {'aura': aura, 'trial_metric': 'spell_cast_count', 'observe_spell': 1, 'observe_metric': 'spell_cast_count',
               'per_trigger': 1, 'per_trigger_text': ''}
        first = {**base, 'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL, 'target': 'dummy'}}
        second = {**base, 'trigger': {'action': 'cast', 'spell': BLADE_OF_FAITH, 'target': 'dummy'}}
        return {'triggers': [first, second]}

    def test_shares_trigger_aura_true_for_two_default_kind_entries_of_the_same_aura(self):
        class_file = self.two_entries()
        self.assertTrue(shares_trigger_aura(class_file, class_file['triggers'][0]))
        self.assertTrue(shares_trigger_aura(class_file, class_file['triggers'][1]))

    def test_shares_trigger_aura_false_for_a_sole_entry(self):
        self.assertFalse(shares_trigger_aura(CLASS_FILE, templar_trigger(SCARLET_SECRETS)))

    def test_shares_trigger_aura_ignores_entries_of_another_kind(self):
        class_file = self.two_entries(aura=ONE_WITH_THE_LIGHT)
        cooldown_entry = {'aura': ONE_WITH_THE_LIGHT, 'kind': COOLDOWN_DELTA_KIND,
                          'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL, 'target': 'dummy'},
                          'observe_metric': 'cooldown_ms', 'expected_delta_ms': 1000, 'observe_spell': 2}
        class_file['triggers'] = class_file['triggers'][:1] + [cooldown_entry]
        self.assertFalse(shares_trigger_aura(class_file, class_file['triggers'][0]))

    def test_trigger_label_with_trigger_spell_is_distinct_per_entry(self):
        self.assertNotEqual(trigger_label(FERVENT_CASTIGATION, RIGHTEOUS_UPHEAVAL),
                            trigger_label(FERVENT_CASTIGATION, BLADE_OF_FAITH))
        self.assertEqual(trigger_label(FERVENT_CASTIGATION), '707606 trigger_count')
        self.assertEqual(trigger_label(FERVENT_CASTIGATION, BLADE_OF_FAITH), '707606 trigger_count 803880')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_trigger_scenario_disambiguates_the_expectation_label_when_the_aura_is_shared(self):
        entries = [entry for entry in CLASS_FILE['triggers'] if entry['aura'] == FERVENT_CASTIGATION]
        self.assertEqual(len(entries), 2)
        first, second = entries
        _, [first_expectation] = trigger_scenario(CLASS_FILE, first)
        _, [second_expectation] = trigger_scenario(CLASS_FILE, second)
        self.assertNotEqual(first_expectation.label, second_expectation.label)
        self.assertEqual({first_expectation.label, second_expectation.label},
                         {trigger_label(FERVENT_CASTIGATION, RIGHTEOUS_UPHEAVAL),
                          trigger_label(FERVENT_CASTIGATION, BLADE_OF_FAITH)})

    def test_checked_trigger_set_rejects_two_entries_triggered_by_the_same_spell(self):
        base = {'aura': FERVENT_CASTIGATION, 'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL,
                                                         'target': 'dummy'}}
        with self.assertRaises(ValueError):
            checked_trigger_set([dict(base), dict(base)])

    def test_checked_trigger_set_accepts_two_entries_triggered_by_different_spells(self):
        entries = self.two_entries()['triggers']
        self.assertIs(checked_trigger_set(entries), entries)

    def test_checked_trigger_set_ignores_a_status_entry_sharing_the_trigger_spell(self):
        base = {'aura': FERVENT_CASTIGATION, 'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL,
                                                         'target': 'dummy'}}
        status = {'aura': FERVENT_CASTIGATION, 'status': 'unmodelled', 'reason': 'x',
                  'trigger': {'action': 'cast', 'spell': RIGHTEOUS_UPHEAVAL, 'target': 'dummy'}}
        entries = checked_trigger_set([dict(base), status])
        self.assertEqual(len(entries), 2)


FORCE_OF_GOLGANNETH = 500694
DIVINE_FORCE = 806153
TESTAMENT_OF_WILL = 801455


class OneWithTheLightCooldownEntryTest(unittest.TestCase):
    def cooldown_entries(self):
        return [entry for entry in CLASS_FILE['triggers'] if entry['aura'] == ONE_WITH_THE_LIGHT
               and entry.get('kind') == COOLDOWN_DELTA_KIND]

    def effect_0_entries(self):
        return [entry for entry in self.cooldown_entries() if entry['effect'] == 0]

    def entry_for(self, observe_spell):
        return next(entry for entry in self.cooldown_entries() if entry['observe_spell'] == observe_spell)

    def test_one_cooldown_delta_entry_covers_effect_2(self):
        entries = [entry for entry in self.cooldown_entries() if entry['effect'] == 2]
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]['observe_spell'], LIBRAM_OF_TENACITY)

    def test_three_new_cooldown_delta_entries_cover_effect_0_one_per_named_spell(self):
        entries = self.effect_0_entries()
        self.assertEqual(len(entries), 3)
        self.assertEqual({entry['observe_spell'] for entry in entries},
                         {FORCE_OF_GOLGANNETH, DIVINE_FORCE, TESTAMENT_OF_WILL})
        self.assertTrue(all(entry['expected_delta_ms'] == 1000 for entry in entries))

    def test_effect_0_is_no_longer_in_unmodelled_effects(self):
        self.assertFalse(any(entry['spell'] == ONE_WITH_THE_LIGHT and entry['effect'] == 0
                             for entry in CLASS_FILE['unmodelled_effects']))

    def test_force_of_golganneth_entry_self_casts_with_no_observe_target(self):
        entry = self.entry_for(FORCE_OF_GOLGANNETH)
        self.assertIsNone(entry.get('observe_target'))

    def test_divine_force_entry_casts_at_the_hostile_dummy(self):
        entry = self.entry_for(DIVINE_FORCE)
        self.assertEqual(entry['observe_target'], 'dummy')

    def test_testament_of_will_entry_casts_at_a_grouped_ally(self):
        entry = self.entry_for(TESTAMENT_OF_WILL)
        self.assertEqual(entry['observe_target'], 'ally')

    def test_checked_entry_accepts_every_new_cooldown_entry(self):
        for entry in self.effect_0_entries():
            self.assertIs(checked_entry(entry), entry)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trigger_scenario_groups_an_ally_for_an_observe_target_ally_entry(self):
        entry = self.entry_for(TESTAMENT_OF_WILL)
        scenario, _ = cooldown_trigger_scenario(CLASS_FILE, entry, 0)
        self.assertTrue(any(step.get('action') == 'group' for step in scenario['steps']))
        self.assertEqual(len(scenario['players']), 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_cooldown_trigger_scenario_adds_a_creature_for_an_observe_target_dummy_entry(self):
        entry = self.entry_for(DIVINE_FORCE)
        scenario, _ = cooldown_trigger_scenario(CLASS_FILE, entry, 0)
        self.assertIn('creatures', scenario)


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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scarlet_champion_scenario_forces_melee_crit_rating(self):
        scenario, _ = trigger_scenario(CLASS_FILE, templar_trigger(SCARLET_CHAMPION))
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)

    def test_legacy_of_the_silver_hand_is_a_plain_cast_trigger(self):
        entry = templar_trigger(LEGACY_OF_THE_SILVER_HAND)
        self.assertNotIn('force_crit', entry)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': ARGENT_BLADE_RANK, 'target': 'dummy'})
        self.assertEqual(entry['trial_metric'], 'spell_cast_count')
        self.assertEqual(entry['observe_spell'], LEGACY_OF_THE_SILVER_HAND_CHARGES)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
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


class MagnitudeTriggerCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self):
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=constant_reader())
                    if verdict.check == MAGNITUDE_CHECK]
        self.assertEqual(len(verdicts), 1)
        self.assertIn(verdicts[0].status, STATUSES)
        return verdicts[0]

    def test_ratio_at_the_expected_fraction_is_ok(self):
        self.workspace.scenario(MAGNITUDE_KEY, 'trigger', [magnitude_expectation()],
                                steps=magnitude_steps(trigger_total=100000, observe_total=50000))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.5)
        self.assertEqual(verdict.expected, 0.5)

    def test_ratio_far_from_the_expected_fraction_alerts(self):
        self.workspace.scenario(MAGNITUDE_KEY, 'trigger', [magnitude_expectation()],
                                steps=magnitude_steps(trigger_total=100000, observe_total=1000))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 0.01)

    def test_absent_passive_aura_is_unmeasured(self):
        self.workspace.scenario(MAGNITUDE_KEY, 'trigger', [magnitude_expectation()],
                                steps=magnitude_steps(trigger_total=100000, observe_total=50000, aura=0))
        self.assertEqual(self.verdict().status, 'unmeasured')

    def test_too_few_trigger_hits_is_insufficient(self):
        self.workspace.scenario(MAGNITUDE_KEY, 'trigger', [magnitude_expectation(attempts=TRIGGER_TRIALS - 1)],
                                steps=magnitude_steps(trigger_total=1000, observe_total=500,
                                                      trigger_count=TRIGGER_TRIALS - 1))
        self.assertEqual(self.verdict().status, 'insufficient_trials')

    def test_heal_ratio_metric_is_read_the_same_way(self):
        self.workspace.scenario(MAGNITUDE_KEY, 'trigger',
                                [magnitude_expectation(expected_ratio=0.75, observe_metric='spell_heal_total')],
                                steps=magnitude_steps(trigger_total=400000, observe_total=300000))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.75)

    def test_parts_are_summed_before_the_ratio_is_taken(self):
        second_key = f'conformance-templar-trigger-{DELIVERANCE}-1-part-2'
        self.workspace.scenario(MAGNITUDE_KEY, 'trigger', [magnitude_expectation(parts=2, attempts=150)],
                                steps=magnitude_steps(trigger_total=60000, observe_total=30000,
                                                      trigger_count=150))
        self.workspace.scenario(second_key, 'trigger',
                                [magnitude_expectation(part=1, parts=2, attempts=SCHEDULED - 150)],
                                steps=magnitude_steps(trigger_total=40000, observe_total=20000,
                                                      trigger_count=SCHEDULED - 150))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.5)

    def test_attack_trigger_ratio_at_the_expected_fraction_is_ok(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger', [retribution_magnitude_expectation()],
                                steps=retribution_magnitude_steps(trigger_total=10000, trigger_count=200,
                                                                  observe_total=3000, observe_count=200))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.3)
        self.assertEqual(verdict.expected, 0.3)
        self.assertNotIn(' of 0 ', verdict.explanation)
        self.assertIn('main-hand melee attacks', verdict.explanation)

    def test_attack_trigger_ratio_normalises_by_each_sides_own_event_count_not_the_raw_sums(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger', [retribution_magnitude_expectation()],
                                steps=retribution_magnitude_steps(trigger_total=100000, trigger_count=2000,
                                                                  observe_total=3000, observe_count=200))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.3)

    def test_attack_trigger_ratio_far_from_the_expected_fraction_alerts(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger', [retribution_magnitude_expectation()],
                                steps=retribution_magnitude_steps(trigger_total=10000, trigger_count=200,
                                                                  observe_total=500, observe_count=200))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 0.05)

    def test_attack_trigger_insufficient_trials_is_judged_on_observe_count_not_trigger_count(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger',
                                [retribution_magnitude_expectation(attempts=TRIGGER_TRIALS - 1)],
                                steps=retribution_magnitude_steps(trigger_total=1000000, trigger_count=1000000,
                                                                  observe_total=TRIGGER_TRIALS - 1,
                                                                  observe_count=TRIGGER_TRIALS - 1))
        self.assertEqual(self.verdict().status, 'insufficient_trials')

    def test_holy_strike_ratio_is_judged_after_the_level_sixty_dummys_average_resist(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger', [resisted_retribution_magnitude_expectation()],
                                steps=resisted_retribution_magnitude_steps(observe_total=2664))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.expected, 0.264)
        self.assertIn('0.8800 kept', verdict.explanation)

    def test_holy_strike_ratio_at_the_unresisted_tooltip_fraction_alerts_against_a_resisting_dummy(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger', [resisted_retribution_magnitude_expectation()],
                                steps=resisted_retribution_magnitude_steps(observe_total=3000))
        self.assertEqual(self.verdict().status, 'alert')

    def test_holy_strike_ratio_adds_the_dummys_own_holy_resistance(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger', [resisted_retribution_magnitude_expectation()],
                                steps=resisted_retribution_magnitude_steps(observe_total=2280, holy_resistance=60))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.expected, 0.3 * 0.76)

    def test_holy_strike_ratio_without_the_target_readings_is_not_judged(self):
        self.workspace.scenario(RETRIBUTION_KEY, 'trigger', [resisted_retribution_magnitude_expectation()],
                                steps=retribution_magnitude_steps(trigger_total=10000, trigger_count=200,
                                                                  observe_total=2664, observe_count=200))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('no magnitude measurements', verdict.explanation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class MagnitudeScenarioResistanceTest(unittest.TestCase):
    def test_holy_copy_on_the_dummy_measures_the_dummys_level_and_holy_resistance(self):
        scenario, [expectation] = magnitude_ratio_scenario(CLASS_FILE, templar_magnitude_trigger(RETRIBUTION))
        self.assertEqual(expectation.model['resisted_school_mask'], HOLY_SCHOOL_MASK)
        self.assertEqual(expectation.model['caster_level'], CLASS_FILE['level'])
        measured = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        target = expectation.model['target_measurements']
        self.assertEqual(measured[target['view_level']]['metric'], 'view_level')
        self.assertEqual(measured[target['resistance 1']]['metric'], 'resistance')
        self.assertEqual(measured[target['resistance 1']]['school'], 1)

    def test_physical_copy_measures_no_target_resistance(self):
        scenario, [expectation] = magnitude_ratio_scenario(CLASS_FILE, templar_magnitude_trigger(DELIVERANCE))
        self.assertEqual(expectation.model['resisted_school_mask'], 0)
        self.assertEqual(expectation.model['target_measurements'], {})
        self.assertNotIn('resistance', [step.get('metric') for step in scenario['steps']])

    def test_self_heal_copy_measures_no_target_resistance(self):
        _, [expectation] = magnitude_ratio_scenario(CLASS_FILE, templar_magnitude_trigger(UTHERS_LEGACY))
        self.assertEqual(expectation.model['resisted_school_mask'], 0)


class CheckedMagnitudeEntryTest(unittest.TestCase):
    def cast_entry(self):
        return copy.deepcopy(templar_magnitude_trigger(DELIVERANCE))

    def attack_entry(self):
        return copy.deepcopy(templar_magnitude_trigger(RETRIBUTION))

    def test_accepts_a_cast_trigger_entry(self):
        entry = self.cast_entry()
        self.assertIs(checked_magnitude_entry(entry), entry)

    def test_accepts_an_attack_trigger_entry(self):
        entry = self.attack_entry()
        self.assertIs(checked_magnitude_entry(entry), entry)

    def test_rejects_an_unknown_trigger_action(self):
        entry = self.attack_entry()
        entry['trigger'] = {'action': PERIODIC, 'amplitude_ms': 1000}
        with self.assertRaises(ValueError):
            checked_magnitude_entry(entry)

    def test_rejects_an_attack_trigger_naming_a_spell(self):
        entry = self.attack_entry()
        entry['trigger'] = {'action': ATTACK, 'spell': VINDICATION_MAX_RANK}
        with self.assertRaises(ValueError):
            checked_magnitude_entry(entry)

    def test_rejects_an_attack_trigger_with_a_spell_damage_metric(self):
        entry = self.attack_entry()
        entry['trigger_metric'] = 'spell_damage_total'
        with self.assertRaises(ValueError):
            checked_magnitude_entry(entry)

    def test_rejects_a_cast_trigger_with_a_melee_damage_metric(self):
        entry = self.cast_entry()
        entry['trigger_metric'] = 'melee_damage_total'
        with self.assertRaises(ValueError):
            checked_magnitude_entry(entry)

    def test_rejects_a_cast_trigger_at_an_unknown_target(self):
        entry = self.cast_entry()
        entry['trigger'] = {'action': CAST, 'spell': VINDICATION_MAX_RANK, 'target': 'nowhere'}
        with self.assertRaises(ValueError):
            checked_magnitude_entry(entry)


SELF_TRIGGER_LABELS = trigger_measurements(TESTAMENT_OF_FORTITUDE)
SELF_TRIGGER_KEY = f'conformance-templar-trigger-{TESTAMENT_OF_FORTITUDE}-1-part-1'


def self_trigger_model(part=0, parts=1, attempts=SCHEDULED, per_trigger=1):
    return {'part': part, 'parts': parts, 'scheduled_attempts': SCHEDULED, 'part_attempts': attempts,
            'minimum_trials': TRIGGER_TRIALS, 'per_trigger': per_trigger,
            'trigger': {'action': 'cast', 'spell': TESTAMENT_OF_FORTITUDE, 'target': 'self'},
            'observe_spell': SACRED_RESTRAINT, 'observe_metric': 'aura_apply_count',
            'trial_metric': 'spell_cast_count', 'measurements': SELF_TRIGGER_LABELS}


def self_trigger_expectation(**model):
    return Expectation(self_trigger_label(TESTAMENT_OF_FORTITUDE), SELF_TRIGGER_CHECK, TESTAMENT_OF_FORTITUDE,
                       TESTAMENT_OF_FORTITUDE, None, 'Applies Sacred Restraint', 'self-trigger rule',
                       self_trigger_model(**model))


def self_trigger_steps(trials, events):
    return [assert_step(SELF_TRIGGER_LABELS['trials'], str(trials)),
           assert_step(SELF_TRIGGER_LABELS['events'], str(events))]


class SelfTriggerCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self):
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=constant_reader())
                    if verdict.check == SELF_TRIGGER_CHECK]
        self.assertEqual(len(verdicts), 1)
        self.assertIn(verdicts[0].status, STATUSES)
        return verdicts[0]

    def test_every_cast_applies_the_aura_is_ok(self):
        self.workspace.scenario(SELF_TRIGGER_KEY, 'trigger', [self_trigger_expectation()],
                                steps=self_trigger_steps(SCHEDULED, SCHEDULED))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (SCHEDULED, SCHEDULED))

    def test_missing_events_is_a_seeded_wrong_value_alert(self):
        self.workspace.scenario(SELF_TRIGGER_KEY, 'trigger', [self_trigger_expectation()],
                                steps=self_trigger_steps(SCHEDULED, SCHEDULED - 50))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, SCHEDULED - 50)

    def test_too_few_trials_is_insufficient(self):
        self.workspace.scenario(SELF_TRIGGER_KEY, 'trigger', [self_trigger_expectation(attempts=TRIGGER_TRIALS - 1)],
                                steps=self_trigger_steps(TRIGGER_TRIALS - 1, TRIGGER_TRIALS - 1))
        self.assertEqual(self.verdict().status, 'insufficient_trials')

    def test_missing_measurement_is_an_alert(self):
        self.workspace.scenario(SELF_TRIGGER_KEY, 'trigger', [self_trigger_expectation()],
                                steps=[assert_step(SELF_TRIGGER_LABELS['trials'], str(SCHEDULED))])
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('no trigger measurements', verdict.explanation)

    def test_parts_are_summed_with_no_baseline_phase_at_all(self):
        second_key = f'conformance-templar-trigger-{TESTAMENT_OF_FORTITUDE}-1-part-2'
        self.workspace.scenario(SELF_TRIGGER_KEY, 'trigger', [self_trigger_expectation(parts=2, attempts=150)],
                                steps=self_trigger_steps(150, 150))
        self.workspace.scenario(second_key, 'trigger',
                                [self_trigger_expectation(part=1, parts=2, attempts=SCHEDULED - 150)],
                                steps=self_trigger_steps(SCHEDULED - 150, SCHEDULED - 150))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (SCHEDULED, SCHEDULED))
        self.assertIn('2 of 2 parts', verdict.explanation)
        self.assertNotIn('baseline_attempts', self_trigger_model())


class CheckedSelfTriggerEntryTest(unittest.TestCase):
    def entry(self):
        return copy.deepcopy(templar_trigger(TESTAMENT_OF_FORTITUDE))

    def test_accepts_a_self_trigger_entry(self):
        entry = self.entry()
        self.assertIs(checked_self_trigger_entry(entry), entry)

    def test_rejects_a_trigger_spell_different_from_the_aura(self):
        entry = self.entry()
        entry['trigger'] = {'action': CAST, 'spell': VINDICATION_MAX_RANK, 'target': 'self'}
        with self.assertRaises(ValueError):
            checked_self_trigger_entry(entry)

    def test_rejects_a_non_cast_trigger(self):
        entry = self.entry()
        entry['trigger'] = {'action': PERIODIC, 'amplitude_ms': 1000}
        with self.assertRaises(ValueError):
            checked_self_trigger_entry(entry)

    def test_rejects_an_unknown_target(self):
        entry = self.entry()
        entry['trigger'] = {'action': CAST, 'spell': TESTAMENT_OF_FORTITUDE, 'target': 'nowhere'}
        with self.assertRaises(ValueError):
            checked_self_trigger_entry(entry)

    def test_rejects_an_unknown_observe_metric(self):
        entry = self.entry()
        entry['observe_metric'] = 'hit_mean'
        with self.assertRaises(ValueError):
            checked_self_trigger_entry(entry)

    def test_checked_entry_dispatches_to_self_trigger(self):
        entry = self.entry()
        self.assertIs(checked_entry(entry), entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class SelfTriggerScenarioShapeTest(unittest.TestCase):
    def test_self_trigger_scenario_learns_only_the_aura_with_no_baseline_at_all(self):
        entry = templar_trigger(TESTAMENT_OF_FORTITUDE)
        scenario, [expectation] = self_trigger_scenario(CLASS_FILE, entry, part=0)
        run.validate(scenario)
        steps = scenario['steps']
        self.assertEqual(casts_of(steps, TESTAMENT_OF_FORTITUDE), expectation.model['part_attempts'])
        self.assertFalse(any('baseline' in step.get('label', '') for step in steps))
        self.assertEqual((expectation.label, expectation.check),
                         (self_trigger_label(TESTAMENT_OF_FORTITUDE), SELF_TRIGGER_CHECK))
        self.assertEqual(expectation.model['trigger']['spell'], TESTAMENT_OF_FORTITUDE)
        self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)

    def test_self_trigger_scenario_casts_at_the_dummy_when_a_target_trigger(self):
        entry = templar_trigger(VINDICATION_MAX_RANK)
        scenario, [expectation] = self_trigger_scenario(CLASS_FILE, entry, part=0)
        run.validate(scenario)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')
        self.assertEqual(expectation.model['observe_spell'], ZEALOTRY_HIT)

    def test_self_trigger_rule_names_no_baseline(self):
        entry = templar_trigger(TESTAMENT_OF_FORTITUDE)
        self.assertIn('no separate passive', self_trigger_rule(entry))


GATE_ABSENCE_LABELS = trigger_measurements(FAITH_GUARD)
GATE_ABSENCE_KEY = f'conformance-templar-trigger-{FAITH_GUARD}-gate-part-1'


def gate_absence_model(part=0, parts=1, attempts=SCHEDULED):
    return {'part': part, 'parts': parts, 'scheduled_attempts': SCHEDULED, 'part_attempts': attempts,
            'minimum_trials': TRIGGER_TRIALS, 'trigger': {'action': 'cast', 'spell': CHASTISE, 'target': 'dummy'},
            'observe_spell': 706466, 'observe_metric': 'spell_cast_count', 'trial_metric': 'spell_cast_count',
            'gate_text': 'While a Libram is active', 'measurements': GATE_ABSENCE_LABELS}


def gate_absence_expectation(**model):
    return Expectation(gate_absence_label(FAITH_GUARD), GATE_ABSENCE_CHECK, FAITH_GUARD, FAITH_GUARD, None,
                       'will now unleash', 'gate-absence rule', gate_absence_model(**model))


def gate_absence_steps(trials, events):
    return [assert_step(GATE_ABSENCE_LABELS['trials'], str(trials)),
           assert_step(GATE_ABSENCE_LABELS['events'], str(events))]


class GateAbsenceCompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self):
        manifest, results = self.workspace.manifest()
        verdicts = [verdict for verdict in compare(manifest, results, tooltips=constant_reader())
                    if verdict.check == GATE_ABSENCE_CHECK]
        self.assertEqual(len(verdicts), 1)
        self.assertIn(verdicts[0].status, STATUSES)
        return verdicts[0]

    def test_no_events_with_the_condition_withheld_is_ok(self):
        self.workspace.scenario(GATE_ABSENCE_KEY, 'trigger', [gate_absence_expectation()],
                                steps=gate_absence_steps(SCHEDULED, 0))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (0.0, 0.0))

    def test_any_event_with_the_condition_withheld_is_a_seeded_wrong_value_alert(self):
        self.workspace.scenario(GATE_ABSENCE_KEY, 'trigger', [gate_absence_expectation()],
                                steps=gate_absence_steps(SCHEDULED, 5))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.measured, 5)

    def test_too_few_trials_is_insufficient(self):
        self.workspace.scenario(GATE_ABSENCE_KEY, 'trigger',
                                [gate_absence_expectation(attempts=TRIGGER_TRIALS - 1)],
                                steps=gate_absence_steps(TRIGGER_TRIALS - 1, 0))
        self.assertEqual(self.verdict().status, 'insufficient_trials')

    def away_expectation(self):
        expectation = gate_absence_expectation()
        return replace(expectation, model={**expectation.model, 'away_control': 'control'})

    def test_an_absence_away_is_ok_only_when_the_observed_spell_casts_there(self):
        self.workspace.scenario(GATE_ABSENCE_KEY, 'trigger', [self.away_expectation()],
                                steps=gate_absence_steps(SCHEDULED, 0) + [assert_step('control', '0')])
        self.assertEqual(self.verdict().status, 'ok')

    def test_seeded_absence_out_of_the_observed_spells_range_is_unmeasured(self):
        self.workspace.scenario(GATE_ABSENCE_KEY, 'trigger', [self.away_expectation()],
                                steps=gate_absence_steps(SCHEDULED, 0) + [assert_step('control', '97')])
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('could not be cast at the away position', verdict.explanation)

    def test_missing_measurement_is_an_alert(self):
        self.workspace.scenario(GATE_ABSENCE_KEY, 'trigger', [gate_absence_expectation()],
                                steps=[assert_step(GATE_ABSENCE_LABELS['trials'], str(SCHEDULED))])
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('no trigger measurements', verdict.explanation)

    def test_parts_are_summed_with_no_baseline_phase_at_all(self):
        second_key = f'conformance-templar-trigger-{FAITH_GUARD}-gate-part-2'
        self.workspace.scenario(GATE_ABSENCE_KEY, 'trigger', [gate_absence_expectation(parts=2, attempts=150)],
                                steps=gate_absence_steps(150, 0))
        self.workspace.scenario(second_key, 'trigger',
                                [gate_absence_expectation(part=1, parts=2, attempts=SCHEDULED - 150)],
                                steps=gate_absence_steps(SCHEDULED - 150, 0))
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (0.0, 0.0))
        self.assertIn('2 of 2 parts', verdict.explanation)


class CheckedGateAbsenceEntryTest(unittest.TestCase):
    def entry(self):
        return copy.deepcopy(templar_gate_trigger(FAITH_GUARD))

    def test_accepts_a_gate_absence_entry(self):
        entry = self.entry()
        self.assertIs(checked_gate_absence_entry(entry), entry)

    def test_rejects_a_non_cast_trigger(self):
        entry = self.entry()
        entry['trigger'] = {'action': PERIODIC, 'amplitude_ms': 1000}
        with self.assertRaises(ValueError):
            checked_gate_absence_entry(entry)

    def test_rejects_an_unknown_target(self):
        entry = self.entry()
        entry['trigger'] = {'action': CAST, 'spell': CHASTISE, 'target': 'nowhere'}
        with self.assertRaises(ValueError):
            checked_gate_absence_entry(entry)

    def test_rejects_an_unknown_observe_metric(self):
        entry = self.entry()
        entry['observe_metric'] = 'hit_mean'
        with self.assertRaises(ValueError):
            checked_gate_absence_entry(entry)

    def test_rejects_attempt_auras(self):
        entry = self.entry()
        entry['attempt_auras'] = [{'spell': LIBRAM_OF_CONSECRATION, 'stacks': 1, 'source': 'test'}]
        with self.assertRaises(ValueError):
            checked_gate_absence_entry(entry)

    def test_rejects_a_missing_gate_text(self):
        entry = self.entry()
        del entry['gate_text']
        with self.assertRaises(ValueError):
            checked_gate_absence_entry(entry)

    def test_checked_entry_dispatches_to_gate_absence(self):
        entry = self.entry()
        self.assertIs(checked_entry(entry), entry)

    def test_rejects_an_away_step_beyond_one_relocation(self):
        entry = {**self.entry(), 'away_yd': 25.0}
        with self.assertRaises(ValueError):
            checked_gate_absence_entry(entry)

    def test_rejects_an_away_step_without_a_dummy_target(self):
        entry = {**self.entry(), 'away_yd': 15.0}
        entry['trigger'] = {**entry['trigger'], 'target': 'ally'}
        with self.assertRaises(ValueError):
            checked_gate_absence_entry(entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GateAbsenceScenarioShapeTest(unittest.TestCase):
    def test_gate_absence_scenario_learns_the_trigger_and_the_aura_with_no_baseline_at_all(self):
        entry = templar_gate_trigger(FAITH_GUARD)
        scenario, [expectation] = gate_absence_scenario(CLASS_FILE, entry, part=0)
        run.validate(scenario)
        steps = scenario['steps']
        self.assertEqual(casts_of(steps, CHASTISE), expectation.model['part_attempts'])
        self.assertFalse(any('baseline' in step.get('label', '') for step in steps))
        learns = {step['spell'] for step in steps if step['action'] == 'learn'}
        self.assertEqual(learns, {CHASTISE, FAITH_GUARD})
        self.assertEqual((expectation.label, expectation.check),
                         (gate_absence_label(FAITH_GUARD), GATE_ABSENCE_CHECK))
        self.assertLessEqual(scenario['timeout_ms'], MAX_SCENARIO_MS)

    def test_gate_absence_scenario_never_sets_the_libram_aura(self):
        entry = templar_gate_trigger(FAITH_GUARD)
        scenario, _ = gate_absence_scenario(CLASS_FILE, entry, part=0)
        self.assertFalse(any(step.get('action') == 'set_aura' and step.get('spell') == LIBRAM_OF_CONSECRATION
                             for step in scenario['steps']))

    def test_gate_absence_rule_names_the_withheld_condition(self):
        entry = templar_gate_trigger(FAITH_GUARD)
        self.assertIn('While a Libram is active', gate_absence_rule(entry))

    def test_an_away_step_ends_with_a_cast_of_the_observed_spell_away(self):
        entry = {**templar_gate_trigger(FAITH_GUARD), 'away_yd': 15.0}
        scenario, [expectation] = gate_absence_scenario(CLASS_FILE, entry, part=0)
        steps = run.validate(scenario)['steps']
        self.assertEqual(steps[-1]['label'], expectation.model['away_control'])
        self.assertEqual(steps[-1]['metric'], 'cast_failure')
        last_cast = max(index for index, step in enumerate(steps) if step['action'] == 'cast')
        self.assertEqual(steps[last_cast]['spell'], 706466)

    def test_an_away_step_casts_in_place_and_waits_away(self):
        entry = {**templar_gate_trigger(FAITH_GUARD), 'away_yd': 15.0}
        scenario, _ = gate_absence_scenario(CLASS_FILE, entry, part=0)
        steps = run.validate(scenario)['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == CHASTISE]
        moves = [step['dx'] for step in steps if step['action'] == 'relocate']
        self.assertEqual(moves, [-15.0] + [15.0, -15.0] * len(casts))
        for index in casts:
            self.assertEqual(steps[index + 1], {'action': 'relocate', 'actor': 'caster', 'dx': -15.0})
            self.assertEqual(steps[index - 1]['dx'], 15.0)


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
                if entry.get('kind') == GATE_ABSENCE_KIND:
                    self.assertIn(entry['gate_text'], cleaned)
                else:
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
                elif entry['observe_source'].startswith('tooltip token'):
                    token = re.match(rf'tooltip token (\${observed}\w+) of {entry["aura"]}$', entry['observe_source'])
                    self.assertTrue(token)
                    self.assertIn(token.group(1), description)
                    self.assertNotIn(observed, triggered)
                    self.assertTrue(entry['observe_note'])
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
                if trigger['action'] == 'attack' and entry.get('kind') == MAGNITUDE_RATIO_KIND:
                    self.assertEqual(entry['trigger_metric'], 'melee_damage_total')
                    self.assertIn(entry['observe_metric'], ('spell_damage_total', 'spell_heal_total'))
                    continue
                if trigger['action'] == 'attack':
                    self.assertIn(entry['trial_metric'], ('melee_attack_count', 'melee_damage_count'))
                    continue
                if trigger['action'] == PERIODIC:
                    self.assertGreater(trigger['amplitude_ms'], 0)
                    self.assertEqual(entry['trial_metric'], 'spell_cast_count')
                    continue
                if trigger['action'] == TAKEN_HIT:
                    metric = entry['trigger_metric'] if entry.get('kind') == MAGNITUDE_RATIO_KIND \
                        else entry['trial_metric']
                    self.assertEqual(metric, 'spell_damage_total' if entry.get('kind') == MAGNITUDE_RATIO_KIND
                                     else 'spell_damage_count')
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
                if entry.get('kind') == MAGNITUDE_RATIO_KIND:
                    self.assertIn(entry['observe_metric'], ('spell_damage_total', 'spell_heal_total'))
                    continue
                self.assertIn(entry['trial_metric'], ('spell_cast_count', 'spell_damage_count'))

    def test_every_second_cast_is_the_only_half_rate(self):
        for entry in trigger_entries(CLASS_FILE):
            with self.subTest(aura=entry['aura']):
                if entry.get('kind') in (COOLDOWN_DELTA_KIND, DURATION_DELTA_KIND, MAGNITUDE_RATIO_KIND,
                                         GATE_ABSENCE_KIND):
                    continue
                if entry['per_trigger_text'].startswith('Every 2nd'):
                    expected = 0.5
                elif entry['per_trigger_text'].startswith('10 times'):
                    expected = 0.1
                elif entry['aura'] == DISCIPLINED_MIND_681483:
                    expected = 2
                else:
                    expected = 1
                self.assertEqual(entry['per_trigger'], expected)

    def test_divine_fury_is_unmodelled_and_iron_penance_keeps_its_vindication_driver(self):
        divine_fury, iron_penance = templar_trigger(DIVINE_FURY), templar_trigger(IRON_PENANCE)
        self.assertEqual(divine_fury.get('status'), 'unmodelled')
        self.assertNotIn('trigger', divine_fury)
        self.assertEqual(iron_penance['trigger']['spell'], VINDICATION_MAX_RANK)

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

    def test_one_with_the_light_zealotry_effect_casts_a_hostile_targeted_breaker(self):
        entry = templar_trigger(ONE_WITH_THE_LIGHT)
        self.assertNotIn('status', entry)
        self.assertEqual(entry['trigger']['spell'], OATH_BREAKER_CAST)
        self.assertEqual(entry['trigger']['target'], 'dummy')
        self.assertEqual(entry['observe_spell'], 801450)
        self.assertEqual(entry['observe_source'], f'EffectTriggerSpell[1] of {ONE_WITH_THE_LIGHT}')
        plan = trigger_plan(CLASS_FILE, entry)
        self.assertEqual(sum(plan.part_attempts), SCHEDULED)

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
                              DURATION_DELTA_KIND: duration_trigger_scenario,
                              MAGNITUDE_RATIO_KIND: magnitude_ratio_scenario,
                              GATE_ABSENCE_KIND: gate_absence_scenario}.get(entry.get('kind'), trigger_scenario)
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

    def test_a_trigger_may_cast_a_whole_number_of_events_but_not_a_fraction_above_one(self):
        entry = copy.deepcopy(templar_trigger(DISCIPLINED_MIND_681483))
        self.assertEqual(trigger_scenario(CLASS_FILE, entry)[1][0].model['per_trigger'], 2)
        entry['per_trigger'] = 1.5
        with self.assertRaisesRegex(ValueError, 'events per trigger'):
            trigger_scenario(CLASS_FILE, entry)

    def test_disciplined_mind_681483_entry_casts_at_an_ally(self):
        entry = templar_trigger(DISCIPLINED_MIND_681483)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': BENEDICTION_RANK_60, 'target': 'ally'})
        self.assertEqual(entry['observe_spell'], DISPEL_FOR_BENEDICTION)
        self.assertEqual(entry['observe_metric'], 'spell_cast_count')
        self.assertEqual((entry['per_trigger'], templar_trigger(680399)['per_trigger']), (2, 1))
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

    def test_keeping_the_oath_stays_unmodelled(self):
        entry = templar_trigger(KEEPING_THE_OATH)
        self.assertEqual(entry['status'], 'unmodelled')
        self.assertNotIn('trigger', entry)
        with self.assertRaises(ValueError):
            trigger_plan(CLASS_FILE, entry)

    def test_keeping_the_oath_is_reachable_through_its_own_spell_proc_row(self):
        entry = templar_trigger(KEEPING_THE_OATH)
        self.assertIn('rev_20261001_04_templar_keeping_the_oath_avoid.sql', entry['reason'])
        self.assertIn('PROC_HIT_DODGE|PROC_HIT_PARRY', entry['reason'])
        self.assertIn('no action in run.py', entry['reason'])

    def test_zealotry_dual_wields_a_one_hand_pair_before_the_baseline_and_counts_off_hand_swings(self):
        entry = templar_trigger(ZEALOTRY)
        scenario, [expectation] = trigger_scenario(CLASS_FILE, entry, 0)
        steps = scenario['steps']
        main = first_index(steps, action='equip', slot=15)
        known = first_index(steps, metric='knows_spell', spell=entry['dual_wield']['known_spell'])
        off_hand = first_index(steps, action='equip', item=entry['dual_wield']['off_hand_item'], slot=16)
        baseline = first_index(steps, action='attack')
        passive = first_index(steps, action='learn', spell=ZEALOTRY)
        self.assertNotIn(DUAL_WIELD, [step.get('spell') for step in steps if step['action'] == 'learn'])
        self.assertEqual(steps[known]['label'], f'{ZEALOTRY} dual_wield knows {DUAL_WIELD}')
        self.assertIn(f'is read knowing {DUAL_WIELD}, not granted,', expectation.rule)
        self.assertLess(main, known)
        self.assertLess(known, off_hand)
        self.assertLess(off_hand, baseline)
        self.assertLess(baseline, passive)
        self.assertNotEqual(steps[main]['item'], CLASS_FILE['weapon']['item'])
        trials = [step for step in steps if step.get('metric') == 'melee_damage_count']
        self.assertEqual({step['hand'] for step in trials}, {1})
        self.assertIn('trials: melee_damage_count off hand', expectation.rule)
        self.assertEqual(expectation.model['dual_wield'], entry['dual_wield'])
        run.validate(scenario)
        self.assertNotIn('dual_wield', trigger_scenario(CLASS_FILE, templar_trigger(PARRY_DANCE), 0)[1][0].model)

    def test_dual_wield_needs_an_attack_trigger_and_its_three_fields(self):
        entry = copy.deepcopy(templar_trigger(ZEALOTRY))
        source = entry['dual_wield']['source']
        for broken in ({**entry, 'trigger': {'action': 'cast', 'spell': 573324, 'target': 'dummy'},
                        'trial_metric': 'spell_cast_count', 'trial_metric_fields': {}},
                       {**entry, 'dual_wield': {'spell': 674, 'off_hand_item': 2492}},
                       {**entry, 'dual_wield': {'known_spell': '674', 'off_hand_item': 2492, 'source': source}},
                       {**entry, 'dual_wield': {**entry['dual_wield'], 'spell': 674}}):
            with self.subTest(broken=broken['dual_wield']), self.assertRaises(ValueError):
                checked_entry(broken)

    def test_a_granted_dual_wield_learns_its_spell_before_the_off_hand_equip(self):
        entry = copy.deepcopy(templar_trigger(ZEALOTRY))
        entry['dual_wield'] = {'spell': DUAL_WIELD, 'off_hand_item': 2492, 'source': entry['dual_wield']['source']}
        scenario, [expectation] = trigger_scenario(CLASS_FILE, checked_entry(entry), 0)
        steps = scenario['steps']
        learned = first_index(steps, action='learn', spell=DUAL_WIELD)
        self.assertLess(learned, first_index(steps, action='equip', item=2492, slot=16))
        self.assertFalse(any(step.get('metric') == 'knows_spell' for step in steps))
        self.assertIn(f'the caster learns {DUAL_WIELD} and equips', expectation.rule)

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
        return {
            'aura': SACRED_DEFENSE, 'name': 'Sacred Defense',
            'tooltip': 'When you take Physical damage you now strike back at enemies for $s1% of the damage '
                       'dealt as Holy damage. Can only occur once per sec.',
            'trigger': {'action': 'taken_hit', 'spell': 16827, 'striker_entry': 36},
            'trigger_text': 'When you take Physical damage', 'trigger_spell_text': '',
            'trial_metric': 'spell_damage_count', 'observe_spell': 707720, 'observe_source': 'synthetic fixture',
            'observe_metric': 'spell_cast_count', 'per_trigger': 1, 'per_trigger_text': 'now strike back at enemies',
            'internal_cooldown_ms': 1000}

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

    def test_every_strike_refills_the_caster_first(self):
        entry = self.entry()
        plan = trigger_plan(CLASS_FILE, entry)
        steps = attempt_steps(CLASS_FILE, entry, plan, 3, '')
        for index, step in enumerate(steps):
            if step.get('action') == 'cast':
                self.assertEqual(steps[index - 1]['action'], 'set_health')
                self.assertEqual(steps[index - 1]['actor'], 'caster')

    def magnitude_entry(self):
        return {'aura': SACRED_DEFENSE, 'kind': MAGNITUDE_RATIO_KIND, 'name': 'Sacred Defense',
                'tooltip': self.entry()['tooltip'],
                'trigger': {'action': 'taken_hit', 'spell': 32247, 'striker_entry': 36},
                'trigger_text': 'When you take Physical damage', 'trigger_metric': 'spell_damage_total',
                'observe_spell': 707720, 'observe_source': 'synthetic fixture',
                'observe_metric': 'spell_damage_total', 'per_trigger_text': 'for $s1% of the damage dealt',
                'internal_cooldown_ms': 1000, 'expected_ratio': 0.15}

    def test_a_magnitude_ratio_reads_the_strikers_hits_and_the_strike_back_at_the_striker(self):
        scenario, [expectation] = magnitude_ratio_scenario(CLASS_FILE, self.magnitude_entry(), 0)
        run.validate(scenario)
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['striker'])
        labels = expectation.model['measurements']
        steps = {step.get('label'): step for step in scenario['steps']}
        for key in ('trigger_total', 'trigger_count'):
            self.assertEqual((steps[labels[key]]['caster'], steps[labels[key]]['target'], steps[labels[key]]['spell']),
                             ('striker', 'caster', 32247))
        self.assertEqual(steps[labels['observe_total']]['spell'], 707720)
        self.assertEqual(expectation.model['resisted_school_mask'], 2)
        self.assertEqual(steps[expectation.model['target_measurements']['resistance 1']]['actor'], 'striker')
        casts = [step for step in scenario['steps'] if step.get('action') == 'cast']
        self.assertTrue(casts and all(step['actor'] == 'striker' for step in casts))

    def test_a_magnitude_ratio_taken_hit_needs_a_striker_and_a_spell(self):
        for trigger in ({'action': 'taken_hit', 'spell': 32247}, {'action': 'taken_hit', 'striker_entry': 36}):
            with self.subTest(trigger=trigger), self.assertRaises(ValueError):
                checked_entry({**self.magnitude_entry(), 'trigger': trigger})

    def gate_entry(self):
        return {'aura': SACRED_DEFENSE, 'kind': GATE_ABSENCE_KIND, 'name': 'Sacred Defense',
                'tooltip': self.entry()['tooltip'],
                'trigger': {'action': 'taken_hit', 'spell': 32247, 'striker_entry': 31146},
                'trigger_text': 'When you take Physical damage', 'trial_metric': 'spell_damage_count',
                'observe_spell': 707720, 'observe_source': 'synthetic fixture', 'observe_metric': 'spell_cast_count',
                'internal_cooldown_ms': 1000, 'gate_text': 'the striker is a boss'}

    def test_a_gate_absence_on_a_taken_hit_strikes_from_the_withheld_striker(self):
        scenario, [expectation] = gate_absence_scenario(CLASS_FILE, self.gate_entry(), 0)
        run.validate(scenario)
        self.assertEqual(scenario['creatures'][0]['entry'], 31146)
        self.assertFalse(any(step.get('action') == 'learn' and step.get('spell') == 32247
                             for step in scenario['steps']))
        self.assertEqual(expectation.check, GATE_ABSENCE_CHECK)

    def test_a_gate_absence_suffix_names_its_label(self):
        _, [plain] = gate_absence_scenario(CLASS_FILE, self.gate_entry(), 0)
        _, [named] = gate_absence_scenario(CLASS_FILE, {**self.gate_entry(), 'label_suffix': 'dungeon_boss'}, 0)
        self.assertEqual(plain.label, f'{SACRED_DEFENSE} gate_absence_count')
        self.assertEqual(named.label, f'{SACRED_DEFENSE} gate_absence_count dungeon_boss')

    def test_a_gate_absence_on_a_taken_hit_needs_a_striker(self):
        entry = self.gate_entry()
        with self.assertRaises(ValueError):
            checked_entry({**entry, 'trigger': {'action': 'taken_hit', 'spell': 32247}})

    def test_absent_passive_gives_zero_baseline_events(self):
        scenario, [expectation] = trigger_scenario(CLASS_FILE, self.entry(), 0)
        labels = expectation.model['measurements']
        learn_index = next(index for index, step in enumerate(scenario['steps'])
                           if step.get('action') == 'learn' and step.get('spell') == SACRED_DEFENSE)
        baseline_events_index = next(index for index, step in enumerate(scenario['steps'])
                                    if step.get('label') == labels['without'])
        self.assertLess(baseline_events_index, learn_index)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TakenHitMutantTests(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()
        self.entries = TakenHitTriggerTests()

    def tearDown(self):
        self.workspace.close()

    def judged(self, check, key, expectation, values):
        self.workspace.close()
        self.workspace = Workspace()
        self.workspace.scenario(key, 'trigger', [expectation],
                                steps=[assert_step(label, str(value)) for label, value in values.items()])
        manifest, results = self.workspace.manifest()
        [verdict] = [verdict for verdict in compare(manifest, results, tooltips=constant_reader())
                     if verdict.check == check]
        return verdict

    def magnitude(self, observe_total):
        _, [expectation] = magnitude_ratio_scenario(CLASS_FILE, self.entries.magnitude_entry(), 0)
        labels, target = expectation.model['measurements'], expectation.model['target_measurements']
        values = {labels['trigger_total']: 949 * 273, labels['trigger_count']: 273,
                  labels['observe_total']: observe_total, labels['observe_count']: 273, labels['aura']: 1,
                  target['armor']: 0, target['view_level']: 60, target['resistance 1']: 0}
        return self.judged(MAGNITUDE_CHECK, f'conformance-templar-trigger-{SACRED_DEFENSE}-part-1', expectation,
                           values)

    def test_a_strike_back_at_half_the_share_alerts(self):
        self.assertEqual(self.magnitude(round(949 * 0.15 * 0.88) * 273).status, 'ok')
        self.assertEqual(self.magnitude(round(949 * 0.075 * 0.88) * 273).status, 'alert')

    def gate(self, entry, events):
        _, [expectation] = gate_absence_scenario(CLASS_FILE, entry, 0)
        labels = expectation.model['measurements']
        key = 'conformance-templar-trigger-705306-gate' + (f'-{entry["label_suffix"]}' if entry.get('label_suffix')
                                                            else '') + '-part-1'
        return self.judged(GATE_ABSENCE_CHECK, key, expectation, {labels['trials']: 273, labels['events']: events})

    def test_a_strike_back_from_a_boss_striker_alerts(self):
        self.assertEqual(self.gate(self.entries.gate_entry(), 0).status, 'ok')
        self.assertEqual(self.gate(self.entries.gate_entry(), 1).status, 'alert')

    def test_a_strike_back_from_the_suffixed_dungeon_boss_arm_alerts_under_its_own_label(self):
        entry = {**self.entries.gate_entry(), 'label_suffix': 'dungeon_boss',
                 'trigger': {'action': 'taken_hit', 'spell': 32247, 'striker_entry': 643}}
        verdict = self.gate(entry, 2)
        self.assertEqual((verdict.label, verdict.status),
                         (f'{SACRED_DEFENSE} gate_absence_count dungeon_boss', 'alert'))


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

    def test_fervent_castigation_scenario_keys_do_not_collide(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-fervent-castigation-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, triggers=[FERVENT_CASTIGATION])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            keys = [entry['key'] for entry in manifest['scenarios']]
            self.assertEqual(len(keys), len(set(keys)))
            self.assertTrue(any(str(RIGHTEOUS_UPHEAVAL) in key for key in keys))
            self.assertTrue(any(str(BLADE_OF_FAITH) in key for key in keys))
        finally:
            shutil.rmtree(out)

    def test_blessing_of_eonar_scenario_keys_do_not_collide(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-blessing-of-eonar-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, triggers=[BLESSING_OF_EONAR])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            keys = [entry['key'] for entry in manifest['scenarios']]
            self.assertEqual(len(keys), len(set(keys)))
            self.assertTrue(any('801461' in key for key in keys))
            self.assertTrue(any(str(SILVERHAND_INCANTATION) in key for key in keys))
        finally:
            shutil.rmtree(out)

    def test_one_with_the_light_cooldown_scenario_keys_do_not_collide_across_three_shared_effect_entries(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-one-with-the-light-cooldown-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, triggers=[ONE_WITH_THE_LIGHT])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            keys = [entry['key'] for entry in manifest['scenarios']]
            self.assertEqual(len(keys), len(set(keys)))
            self.assertTrue(any(str(FORCE_OF_GOLGANNETH) in key for key in keys))
            self.assertTrue(any(str(DIVINE_FORCE) in key for key in keys))
            self.assertTrue(any(str(TESTAMENT_OF_WILL) in key for key in keys))
        finally:
            shutil.rmtree(out)


class FerventCastigationAndBlessingOfEonarEntriesTest(unittest.TestCase):
    def entries(self, aura):
        return [entry for entry in CLASS_FILE['triggers'] if entry['aura'] == aura]

    def test_fervent_castigation_has_one_entry_per_named_trigger_spell(self):
        entries = self.entries(FERVENT_CASTIGATION)
        self.assertEqual(len(entries), 2)
        self.assertEqual({entry['trigger']['spell'] for entry in entries}, {RIGHTEOUS_UPHEAVAL, BLADE_OF_FAITH})
        self.assertEqual({entry['observe_spell'] for entry in entries}, {OATH_OF_RETRIBUTION})
        for entry in entries:
            with self.subTest(trigger=entry['trigger']):
                self.assertTrue(shares_trigger_aura(CLASS_FILE, entry))
                self.assertIs(checked_entry(entry), entry)

    def test_blessing_of_eonar_has_one_entry_per_named_trigger_spell(self):
        entries = self.entries(BLESSING_OF_EONAR)
        self.assertEqual(len(entries), 2)
        self.assertEqual({entry['trigger']['spell'] for entry in entries}, {801461, SILVERHAND_INCANTATION})
        silverhand = next(entry for entry in entries if entry['trigger']['spell'] == SILVERHAND_INCANTATION)
        self.assertEqual(silverhand['co_learn'], [92111])
        self.assertIs(checked_entry(silverhand), silverhand)


class LibramOfZealCooldownEntryTest(unittest.TestCase):
    def entry(self):
        return templar_trigger(LIBRAM_OF_ZEAL)

    def test_entry_is_a_cooldown_delta_on_righteous_upheaval(self):
        entry = self.entry()
        self.assertEqual(entry['kind'], COOLDOWN_DELTA_KIND)
        self.assertEqual(entry['trigger'], {'action': 'cast', 'spell': HOLY_CLEAVE, 'target': 'dummy'})
        self.assertEqual(entry['observe_spell'], RIGHTEOUS_UPHEAVAL)
        self.assertEqual(entry['observe_target'], 'dummy')
        self.assertEqual(entry['force_crit'], 'melee')
        self.assertEqual(entry['observe_metric'], 'cooldown_ms')
        self.assertEqual(entry['expected_delta_ms'], 2000)
        self.assertEqual(entry['setup_casts'], [LIBRAM_OF_ZEAL])

    def test_checked_cooldown_entry_accepts_the_entry(self):
        self.assertIs(checked_cooldown_entry(self.entry()), self.entry())

    def test_checked_cooldown_entry_rejects_a_seeded_non_positive_expected_delta(self):
        broken = {**self.entry(), 'expected_delta_ms': 0}
        with self.assertRaises(ValueError):
            checked_cooldown_entry(broken)

    def test_checked_cooldown_entry_rejects_a_seeded_non_integer_setup_cast(self):
        broken = {**self.entry(), 'setup_casts': ['not-a-spell-id']}
        with self.assertRaises(ValueError):
            checked_cooldown_entry(broken)

    def test_checked_cooldown_entry_rejects_a_seeded_unknown_observe_target(self):
        broken = {**self.entry(), 'observe_target': 'not-a-target'}
        with self.assertRaises(ValueError):
            checked_cooldown_entry(broken)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CooldownDeltaObserveTargetTest(unittest.TestCase):
    def test_cooldown_trial_steps_casts_the_observed_rank_at_the_named_target(self):
        entry = templar_trigger(LIBRAM_OF_ZEAL)
        steps = cooldown_trial_steps(CLASS_FILE, entry, 1, 'measured')
        observe_casts = [step for step in steps if step.get('action') == 'cast'
                        and step.get('spell') == entry['observe_spell']]
        self.assertEqual(len(observe_casts), 1)
        self.assertEqual(observe_casts[0].get('target'), 'dummy')

    def test_cooldown_trial_steps_waits_after_the_observed_cast_to_clear_its_gcd(self):
        entry = templar_trigger(LIBRAM_OF_ZEAL)
        steps = cooldown_trial_steps(CLASS_FILE, entry, 1, 'measured')
        before_index = next(index for index, step in enumerate(steps)
                            if step.get('label', '').endswith('0 before'))
        self.assertEqual(steps[before_index + 1]['action'], 'wait')
        self.assertGreater(steps[before_index + 1]['ms'], 0)

    def test_cooldown_trial_steps_casts_the_observed_rank_at_self_without_observe_target(self):
        one_with_the_light = next(entry for entry in CLASS_FILE['triggers']
                                  if entry['aura'] == ONE_WITH_THE_LIGHT and entry.get('kind') == COOLDOWN_DELTA_KIND
                                  and entry.get('observe_spell') == 801461)
        entry = {**one_with_the_light, 'observe_target': None}
        steps = cooldown_trial_steps(CLASS_FILE, entry, 1, 'measured')
        observe_casts = [step for step in steps if step.get('action') == 'cast'
                        and step.get('spell') == entry['observe_spell']]
        self.assertEqual(len(observe_casts), 1)
        self.assertNotIn('target', observe_casts[0])

    def test_cooldown_trial_steps_waits_after_a_self_cast_observed_rank_with_its_own_gcd_too(self):
        one_with_the_light = next(entry for entry in CLASS_FILE['triggers']
                                  if entry['aura'] == ONE_WITH_THE_LIGHT and entry.get('kind') == COOLDOWN_DELTA_KIND
                                  and entry.get('observe_spell') == 500694)
        steps = cooldown_trial_steps(CLASS_FILE, one_with_the_light, 1, 'measured')
        before_index = next(index for index, step in enumerate(steps)
                            if step.get('label', '').endswith('0 before'))
        self.assertEqual(steps[before_index + 1]['action'], 'wait')
        self.assertGreater(steps[before_index + 1]['ms'], 0)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CooldownDeltaForceCritTest(unittest.TestCase):
    def test_cooldown_trigger_scenario_forces_the_trigger_cast_to_crit(self):
        entry = templar_trigger(LIBRAM_OF_ZEAL)
        scenario, _ = cooldown_trigger_scenario(CLASS_FILE, entry, 0)
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)

    def test_cooldown_trigger_scenario_leaves_crit_rating_unset_without_force_crit(self):
        one_with_the_light = next(entry for entry in CLASS_FILE['triggers']
                                  if entry['aura'] == ONE_WITH_THE_LIGHT and entry.get('kind') == COOLDOWN_DELTA_KIND)
        scenario, _ = cooldown_trigger_scenario(CLASS_FILE, one_with_the_light, 0)
        self.assertNotIn('melee_crit_rating', scenario['players'][0])
        self.assertNotIn('spell_crit_rating', scenario['players'][0])


if __name__ == '__main__':
    unittest.main()
