import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour, pooled_parts
from kinds import kind_pooled_judge
from kinds.cast_period import cast_period_spec
from profile import DBC_DIR, load_class_file, load_fixture_class_file
from values import FORCE_CRIT_RATINGS, FORCED_CRIT_RATING
import run
from test_behaviours import FakeRun


def bone_toss_entry() -> dict:
    return next(entry for entry in load_fixture_class_file(23)['behaviours']
                if entry['kind'] == 'cast_period' and entry['label_suffix'] == 'bone_toss_period')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CastPeriodTests(unittest.TestCase):
    def expectation(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), bone_toss_entry())
        return scenario, expectation

    def judged(self, period: float, control: float = 0.0, offset: float = 430.0, step: float = 112.0) -> Verdict:
        _, expectation = self.expectation()
        model = expectation.model
        values = {model['control_label']: control, model['start_label']: 10000.0}
        for index, (time_label, casts_label) in enumerate(model['reads']):
            now = 10000.0 + index * step
            values[time_label] = now
            values[casts_label] = float(sum(1 for cast in range(100) if offset + cast * period <= now - 10000.0))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_command_follows_an_uncommanded_control_and_the_polls_follow_the_command(self):
        scenario, expectation = self.expectation()
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        command = next(index for index, step in enumerate(steps)
                       if step['action'] == 'cast' and step['spell'] == 504868)
        self.assertLess(labels.index(expectation.model['control_label']), command)
        self.assertLess(command, labels.index(expectation.model['reads'][0][0]))
        self.assertEqual(len(expectation.model['reads']), 9500 // 100 + 1)
        self.assertEqual(expectation.model['metric'], 'owned_creature_spell_cast_count')

    def test_a_one_second_period_passes(self):
        verdict = self.judged(1000.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertLess(verdict.low, verdict.measured)

    def test_the_live_period_and_a_slow_pulse_alert(self):
        self.assertEqual(self.judged(1240.0).status, 'alert')
        self.assertEqual(self.judged(3000.0).status, 'alert')
        self.assertEqual(self.judged(900.0).status, 'alert')

    def test_a_cast_without_a_command_alerts(self):
        self.assertEqual(self.judged(1000.0, control=1.0).status, 'alert')

    def test_force_crit_and_learn_shape_the_player_and_the_start(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), {**bone_toss_entry(), 'force_crit': 'spell',
                                                                       'learn': [801722]})
        steps = run.validate(scenario)['steps']
        self.assertEqual(scenario['players'][0]['spell_crit_rating'], FORCED_CRIT_RATING)
        learned = [index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 801722]
        first_cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast')
        self.assertEqual(len(learned), 1)
        self.assertLess(learned[0], first_cast)
        self.assertIn('spell_crit_rating', scenario['contract'])

    def test_without_the_options_the_player_holds_no_forced_rating(self):
        scenario, _ = self.expectation()
        self.assertFalse(set(FORCE_CRIT_RATINGS.values()) & set(scenario['players'][0]))

    def test_mutant_an_unknown_force_crit_or_learn_is_refused(self):
        for changes in ({'force_crit': 'holy'}, {'force_crit': True}, {'learn': ['801722']}, {'learn': [0]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                cast_period_spec({**bone_toss_entry(), **changes})

    def test_too_few_casts_are_unmeasured(self):
        self.assertEqual(self.judged(20000.0).status, 'unmeasured')

    def test_polls_wider_than_half_the_period_are_refused(self):
        with self.assertRaises(ValueError):
            cast_period_spec({**bone_toss_entry(), 'poll_ms': 600})
        with self.assertRaises(ValueError):
            cast_period_spec({**bone_toss_entry(), 'control_ms': 1000})


def gaps_entry(**changes) -> dict:
    return {**bone_toss_entry(), 'expected_ms': 4000, 'control_ms': 8000, 'window_ms': 12500,
            'gaps_ms': [4000, 2000, 4000], 'casts_per_event': 2, 'minion_auras': [[704706, 50385, 1500]], **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CastGapsTests(unittest.TestCase):
    def judged(self, events: list[float], per_event: int = 2, step: float = 100.0) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), gaps_entry())
        model = expectation.model
        values = {model['control_label']: 0.0, model['start_label']: 10000.0}
        for index, (time_label, casts_label) in enumerate(model['reads']):
            now = 10000.0 + index * step
            values[time_label] = now
            values[casts_label] = float(per_event * sum(1 for event in events if event <= now - 10000.0))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_minion_aura_is_set_in_the_window_and_the_plain_entry_has_none(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), gaps_entry())
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        aura = next(index for index, step in enumerate(steps) if step['action'] == 'set_aura'
                    and step.get('owned_entry') == 50385)
        self.assertEqual(steps[aura]['spell'], 704706)
        self.assertEqual(labels.index(expectation.model['reads'][15][0]), aura + 1)
        self.assertEqual(expectation.model['gaps']['expected_ms'], [4000, 2000, 4000])
        _, [plain] = behaviour_scenario(load_fixture_class_file(23), bone_toss_entry())
        self.assertNotIn('gaps', plain.model)

    def test_events_at_the_stated_gaps_pass_and_an_unshortened_gap_alerts(self):
        self.assertEqual(self.judged([450.0, 4450.0, 6450.0, 10450.0]).status, 'ok')
        self.assertEqual(self.judged([450.0, 4450.0, 8450.0, 12450.0]).status, 'alert')
        self.assertEqual(self.judged([450.0, 4450.0, 6450.0, 8450.0]).status, 'alert')

    def test_mutant_single_casts_counted_as_events_alert_and_too_few_events_are_unmeasured(self):
        self.assertEqual(self.judged([450.0, 4450.0, 6450.0, 10450.0], per_event=1).status, 'alert')
        self.assertEqual(self.judged([450.0, 4450.0]).status, 'unmeasured')

    def test_a_pet_attack_command_follows_the_trigger_only_when_asked(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), gaps_entry(pet_attack=True))
        steps = run.validate(scenario)['steps']
        command = next(index for index, step in enumerate(steps)
                       if step['action'] == 'cast' and step['spell'] == 504868)
        self.assertEqual(steps[command + 1], {'action': 'attack', 'actor': 'caster', 'target': 'dummy', 'pet': True})
        plain, _ = behaviour_scenario(load_fixture_class_file(23), gaps_entry())
        self.assertFalse(any(step['action'] == 'attack' for step in plain['steps']))

    def test_auras_without_gaps_or_gaps_beyond_the_window_are_refused(self):
        for changes in ({'gaps_ms': []}, {'gaps_ms': [6000, 6500]}, {'casts_per_event': 0},
                        {'minion_auras': [[704706, 50385]]}, {'pet_attack': 'yes'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), gaps_entry(**changes))


def arm_entry(side: str, **changes) -> dict:
    return {**next(entry for entry in load_class_file(15)['behaviours']
                   if entry['kind'] == 'cast_period' and entry.get('arm') == side), **changes}


def arm_expectations(arm: str = 'treatment', **changes):
    scenario, expectations = behaviour_scenario(load_class_file(15), arm_entry(arm, **changes))
    return scenario, {expectation.model['judge']: expectation for expectation in expectations}


def arm_values(model: dict, arm: str, events: list[float], crits: int, noncrits: int, aura: int,
               step: float = 100.0) -> dict:
    labels = model['arms'][arm]
    values = {labels['control']: 0.0, labels['start']: 10000.0, labels['crits']: float(crits),
              labels['noncrits']: float(noncrits), labels['aura']: float(aura)}
    for index, (time_label, casts_label) in enumerate(labels['reads']):
        now = 10000.0 + index * step
        values[time_label] = now
        values[casts_label] = float(2 * sum(1 for event in events if event <= now - 10000.0))
    return values


TREATMENT_EVENTS = [1450.0, 11450.0, 31450.0]
CONTROL_EVENTS = [1450.0, 21450.0, 41450.0]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CastArmsTests(unittest.TestCase):
    def judged(self, judge: str, treatment: dict | None = None, control: dict | None = None,
               drop: str | None = None) -> Verdict:
        _, expectations = arm_expectations()
        expectation = expectations[judge]
        model = expectation.model
        arms = {'treatment': {'events': TREATMENT_EVENTS, 'crits': 1, 'noncrits': 0, 'aura': 1, **(treatment or {})},
                'control': {'events': CONTROL_EVENTS, 'crits': 0, 'noncrits': 1, 'aura': 0, **(control or {})}}
        runs = [FakeRun(arm_values(model, arm, **{key: value for key, value in read.items() if key != 'ran'}))
                for arm, read in arms.items() if read.get('ran', True)]
        if drop is not None:
            runs[0].values.pop(model['arms']['treatment'][drop])
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return kind_pooled_judge('cast_period')(base, runs, model)

    def test_both_arms_share_their_labels_and_pool_as_two_parts(self):
        _, treatment = arm_expectations('treatment')
        _, control = arm_expectations('control')
        for judge in ('leap_arms', 'owned_aura'):
            self.assertEqual(treatment[judge].label, control[judge].label)
            self.assertEqual(treatment[judge].model, control[judge].model)
            self.assertTrue(pooled_parts(treatment[judge].check, treatment[judge].model))

    def test_the_control_holds_the_named_fixture_and_no_forced_rating(self):
        treatment, _ = arm_expectations('treatment')
        control, _ = arm_expectations('control')
        steps = run.validate(control)['steps']
        trigger = next(index for index, step in enumerate(steps)
                       if step['action'] == 'cast' and step['spell'] == 802024)
        fixture = next(index for index, step in enumerate(steps) if step['action'] == 'set_aura'
                       and step['spell'] == 64481)
        self.assertLess(fixture, trigger)
        self.assertEqual(steps[fixture]['label'], 'precondition fixture 64481')
        self.assertEqual(treatment['players'][0]['melee_crit_rating'], FORCED_CRIT_RATING)
        self.assertFalse(set(FORCE_CRIT_RATINGS.values()) & set(control['players'][0]))
        self.assertFalse(any(step['action'] == 'set_aura' for step in run.validate(treatment)['steps']))

    def test_the_owned_aura_is_read_after_the_trigger_and_before_the_pet_attack(self):
        scenario, expectations = arm_expectations()
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        trigger = next(index for index, step in enumerate(steps)
                       if step['action'] == 'cast' and step['spell'] == 802024)
        attack = next(index for index, step in enumerate(steps) if step['action'] == 'attack')
        aura = labels.index(expectations['owned_aura'].model['arms']['treatment']['aura'])
        self.assertLess(trigger, aura)
        self.assertLess(aura, attack)
        self.assertEqual(steps[aura]['spell'], 800528)

    def test_a_ten_second_cut_and_an_unchanged_second_gap_pass(self):
        self.assertEqual(self.judged('leap_arms').status, 'ok')
        self.assertEqual(self.judged('owned_aura').status, 'ok')

    def test_mutant_a_nine_or_eleven_second_reduction_alerts(self):
        for first in (12450.0, 10450.0):
            with self.subTest(first=first):
                events = [1450.0, first, first + 20000.0]
                self.assertEqual(self.judged('leap_arms', treatment={'events': events}).status, 'alert')

    def test_mutant_a_second_shortened_gap_alerts(self):
        self.assertEqual(self.judged('leap_arms', treatment={'events': [1450.0, 11450.0, 21450.0]}).status, 'alert')

    def test_mutant_the_aura_in_the_control_or_missing_in_the_treatment_alerts(self):
        self.assertEqual(self.judged('owned_aura', control={'aura': 1}).status, 'alert')
        self.assertEqual(self.judged('owned_aura', treatment={'aura': 0}).status, 'alert')

    def test_mutant_a_crit_in_the_control_alerts_and_an_uncritical_treatment_holds(self):
        for judge in ('leap_arms', 'owned_aura'):
            with self.subTest(judge=judge):
                self.assertEqual(self.judged(judge, control={'crits': 1, 'noncrits': 0}).status, 'alert')
                self.assertEqual(self.judged(judge, treatment={'crits': 0, 'noncrits': 1}).status, 'unmeasured')
                self.assertEqual(self.judged(judge, control={'noncrits': 0}).status, 'unmeasured')

    def test_a_missing_arm_or_read_is_never_a_pass(self):
        for judge in ('leap_arms', 'owned_aura'):
            with self.subTest(judge=judge):
                self.assertEqual(self.judged(judge, control={'ran': False}).status, 'unmeasured')
                self.assertEqual(self.judged(judge, drop='crits').status, 'unmeasured')
        self.assertEqual(self.judged('owned_aura', drop='aura').status, 'unmeasured')

    def test_the_arm_fields_are_refused_out_of_shape(self):
        for changes in ({'arm': 'both'}, {'owned_aura': [800528, 50124]}, {'pet_attack': False},
                        {'caster_auras': [[64481]]}, {'gaps_ms': [10000, 20000]}, {'aura_quote': None},
                        {'gap_reduction_ms': 20000}, {'gap_reduction_ms': None, 'owned_aura': None,
                                                      'aura_quote': None}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                cast_period_spec(arm_entry('treatment', **changes))
        with self.assertRaises(ValueError):
            cast_period_spec({**bone_toss_entry(), 'gap_reduction_ms': 1000})


def expiry_entry(side: str, **changes) -> dict:
    return {**next(entry for entry in load_class_file(15)['behaviours']
                   if entry['kind'] == 'cast_period' and entry.get('variant') == f'scent_duration_{side}'), **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AuraExpiryArmTests(unittest.TestCase):
    def judged(self, present_age=14400.0, gone_age=15700.0, gone: int = 0, control_gone: int = 0,
               treatment_aura: int = 1, control_aura: int = 0, drop: str | None = None) -> Verdict:
        scenario, [expectation] = behaviour_scenario(load_class_file(15), expiry_entry('treatment'))
        model = expectation.model
        runs = []
        for arm, aura, after in (('treatment', treatment_aura, gone), ('control', control_aura, control_gone)):
            labels = model['arms'][arm]
            values = {labels['control']: 0.0, labels['start']: 10000.0, labels['trigger_done']: 10050.0,
                      labels['crits']: 1.0 if arm == 'treatment' else 0.0,
                      labels['noncrits']: 0.0 if arm == 'treatment' else 1.0, labels['aura']: float(aura),
                      labels['aura_time']: 10050.0 + present_age, labels['aura_gone_time']: 10050.0 + gone_age,
                      labels['aura_gone']: float(after)}
            runs.append(FakeRun(values))
        if drop is not None:
            runs[0].values.pop(model['arms']['treatment'][drop])
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return kind_pooled_judge('cast_period')(base, runs, model)

    def test_present_before_and_gone_after_the_stated_duration_passes(self):
        self.assertEqual(self.judged().status, 'ok')

    def test_the_option_is_inert_for_an_arm_entry_without_it(self):
        _, expectations = arm_expectations()
        model = expectations['owned_aura'].model
        self.assertNotIn('expiry', model)
        self.assertNotIn('trigger_done', model['arms']['treatment'])

    def test_the_reads_are_stamped_around_the_trigger_and_both_aura_reads(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), expiry_entry('treatment'))
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        arms = expectation.model['arms']['treatment']
        order = [labels.index(arms[key]) for key in ('start', 'trigger_done', 'aura_time', 'aura', 'aura_gone_time',
                                                     'aura_gone')]
        self.assertEqual(order, sorted(order))
        self.assertLess(order[-1], next(index for index, step in enumerate(steps) if step['action'] == 'attack'))

    def test_mutant_an_aura_gone_ten_percent_early_or_late_alerts_or_holds(self):
        self.assertEqual(self.judged(present_age=13500.0, gone=0).status, 'unmeasured')
        self.assertEqual(self.judged(gone_age=16500.0, gone=0).status, 'unmeasured')
        self.assertEqual(self.judged(gone_age=16500.0, gone=1).status, 'alert')
        self.assertEqual(self.judged(treatment_aura=0).status, 'alert')

    def test_mutant_the_control_holding_the_aura_alerts(self):
        self.assertEqual(self.judged(control_gone=1).status, 'alert')
        self.assertEqual(self.judged(control_aura=1).status, 'alert')

    def test_a_missing_stamp_is_never_a_pass(self):
        for key in ('trigger_done', 'aura_time', 'aura_gone_time', 'aura_gone'):
            with self.subTest(key=key):
                self.assertEqual(self.judged(drop=key).status, 'unmeasured')

    def test_the_expiry_is_refused_out_of_shape(self):
        for changes in ({'owned_aura': None, 'aura_quote': None}, {'aura_expiry': {'expected_ms': 15000}},
                        {'aura_expiry': {'expected_ms': 14000, 'gone_after_ms': 500}},
                        {'aura_expiry': {'expected_ms': 15000, 'gone_after_ms': 0}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                cast_period_spec(expiry_entry('treatment', **changes))
