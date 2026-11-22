import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 707007, 'name': 'March of the Dead (slow lasts 3 sec after the last explosion)',
         'kind': 'last_application_expiry', 'label_suffix': 'slow_expiry', 'quote': 'for $707010d.',
         'gate_spell': 707007, 'trigger_spell': 707007, 'aura': 707010, 'expected_ms': 3000,
         'control_window_ms': 500, 'window_ms': 5000, 'poll_ms': 25}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class LastApplicationExpiryTests(unittest.TestCase):
    def judged(self, lasts_ms: float, applications=(300.0, 400.0, 900.0), control_applied: bool = False) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        values = {}
        for arm, rows in expectation.model['reads'].items():
            for index, (time, applied, aura) in enumerate(rows):
                now = 1000.0 + index * 34.0
                values[time] = now
                if arm == 'control':
                    values[applied] = 1.0 if control_applied and index else 0.0
                    values[aura] = 0.0
                    continue
                done = [moment for moment in applications if 1000.0 + moment <= now]
                values[applied] = float(len(done))
                values[aura] = 1.0 if done and now < 1000.0 + done[-1] + lasts_ms else 0.0
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_polls_are_valid(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        self.assertEqual(len(expectation.model['reads']['treatment'][0]), 3)

    def test_three_seconds_after_the_last_application_passes(self):
        verdict = self.judged(3000.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertLess(abs(verdict.measured - 3000.0), 60.0)

    def test_a_longer_or_shorter_aura_alerts(self):
        self.assertEqual(self.judged(3600.0).status, 'alert')
        self.assertEqual(self.judged(2400.0).status, 'alert')

    def test_timing_from_the_first_application_would_not_pass(self):
        self.assertEqual(self.judged(2400.0, applications=(300.0, 900.0)).status, 'alert')

    def test_a_control_application_alerts(self):
        self.assertEqual(self.judged(3000.0, control_applied=True).status, 'alert')

    def test_an_aura_never_applied_is_unmeasured(self):
        self.assertEqual(self.judged(3000.0, applications=()).status, 'unmeasured')


NO_REFRESH = {**ENTRY, 'label_suffix': 'no_refresh', 'expected_ms': 3000, 'window_ms': 4000, 'poll_ms': 25,
              'caster': True, 'repeat': {'count': 3, 'every_ms': 500}, 'no_refresh': True}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class NoRefreshTests(unittest.TestCase):
    def judged(self, lasts_ms: float, applications=(10.0,), stacks_at=(10.0, 510.0, 1010.0)) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), NO_REFRESH)
        values = {}
        for arm, rows in expectation.model['reads'].items():
            for index, (time, applied, aura, stacks) in enumerate(rows):
                now = index * 34.0
                values[time] = 1000.0 + now
                if arm == 'control':
                    values[applied] = values[aura] = values[stacks] = 0.0
                    continue
                done = [moment for moment in applications if moment <= now]
                on = bool(done) and now < done[-1] + lasts_ms
                values[applied] = float(len(done))
                values[aura] = 1.0 if on else 0.0
                values[stacks] = float(sum(moment <= now for moment in stacks_at)) if on else 0.0
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_caster_holds_the_reads_and_the_trigger_repeats(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), NO_REFRESH)
        run.validate(scenario)
        reads = [step for step in scenario['steps'] if step.get('metric') in ('aura', 'aura_stacks', 'aura_apply_count')
                 and step.get('spell') == 707010]
        self.assertTrue(reads and all(step['actor'] == 'caster' for step in reads))
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(len(casts), 1 + 3)
        self.assertEqual(len(expectation.model['reads']['treatment'][0]), 4)
        self.assertTrue(expectation.model['no_refresh'])
        first_cast = next(index for index, step in enumerate(scenario['steps']) if step['action'] == 'cast')
        first_read = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('label') == expectation.model['reads']['control'][0][1])
        self.assertLess(first_read, first_cast)

    def test_without_the_options_nothing_changes(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertNotIn('no_refresh', expectation.model)
        self.assertFalse(any(step.get('metric') == 'aura_stacks' for step in scenario['steps']))
        self.assertTrue(all(step['actor'] == 'dummy' for step in scenario['steps']
                            if step.get('metric') == 'aura' and step.get('spell') == 707010))

    def test_a_trigger_target_of_the_caster_is_cast_at_the_caster(self):
        entry = {**ENTRY, 'trigger_target': 'caster'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        targets = {step['target'] for step in scenario['steps']
                   if step['action'] == 'cast' and step['spell'] == 707007}
        self.assertEqual(targets, {'caster'})
        default, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertEqual({step['target'] for step in default['steps']
                          if step['action'] == 'cast' and step['spell'] == 707007}, {'dummy'})
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**ENTRY, 'trigger_target': 'ally'})

    def test_one_application_with_rising_stacks_timed_from_it_passes(self):
        self.assertEqual(self.judged(3000.0).status, 'ok')

    def test_a_refreshing_mutant_alerts(self):
        self.assertEqual(self.judged(3000.0, applications=(10.0, 510.0, 1010.0)).status, 'alert')

    def test_stacks_that_never_rise_are_unmeasured(self):
        self.assertEqual(self.judged(3000.0, stacks_at=(10.0,)).status, 'unmeasured')

    def test_no_refresh_needs_repeated_casts_inside_the_duration(self):
        for changes in ({'repeat': None}, {'repeat': {'count': 7, 'every_ms': 500}}, {'repeat': {'count': 2}},
                        {'caster': 'yes'}):
            entry = {key: value for key, value in {**NO_REFRESH, **changes}.items() if value is not None}
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), entry)


FORCED = {**ENTRY, 'label_suffix': 'forced', 'expected_ms': 3000, 'window_ms': 6000, 'poll_ms': 25, 'caster': True,
          'repeat': {'count': 3, 'every_ms': 500}, 'forced_roll': 707007}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ForcedRollTests(unittest.TestCase):
    def judged(self, lasts_ms: float, released: float = 0.0) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), FORCED)
        values = {expectation.model['forced_roll']['released_label']: released}
        for arm, rows in expectation.model['reads'].items():
            for index, (time, applied, aura) in enumerate(rows):
                now = index * 34.0
                values[time] = 1000.0 + now
                done = [moment for moment in (300.0, 800.0) if moment <= now] if arm == 'treatment' else []
                values[applied] = float(len(done))
                values[aura] = 1.0 if done and now < done[-1] + lasts_ms else 0.0
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_roll_is_forced_and_the_power_refilled_before_each_recast(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), FORCED)
        run.validate(scenario)
        kinds = [step['action'] for step in scenario['steps']]
        self.assertEqual(kinds.count('spell_mod_mutant'), 1)
        casts = [index for index, step in enumerate(scenario['steps'])
                 if step['action'] == 'cast' and step['spell'] == 707007]
        self.assertEqual(len(casts), 1 + 3)
        self.assertTrue(all(scenario['steps'][index - 1]['action'] == 'set_power' for index in casts[2:]))

    def test_without_the_option_nothing_changes(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertNotIn('forced_roll', expectation.model)
        self.assertNotIn('spell_mod_mutant', [step['action'] for step in scenario['steps']])

    def test_three_seconds_after_the_last_application_passes(self):
        self.assertEqual(self.judged(3000.0).status, 'ok')

    def test_a_longer_or_shorter_aura_alerts(self):
        self.assertEqual(self.judged(3600.0).status, 'alert')
        self.assertEqual(self.judged(2400.0).status, 'alert')

    def test_a_modifier_left_active_alerts(self):
        self.assertEqual(self.judged(3000.0, released=1.0).status, 'alert')

    def test_forcing_needs_repeated_casts(self):
        entry = {key: value for key, value in FORCED.items() if key != 'repeat'}
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), entry)


PRE_POLL = {**ENTRY, 'label_suffix': 'pre_poll', 'caster': True, 'trigger_target': 'caster', 'poll_before_cast': True}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PollBeforeCastTests(unittest.TestCase):
    def judged(self, entry: dict, lasts_ms: float) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        values = {}
        for arm, rows in expectation.model['reads'].items():
            for index, (time, applied, aura) in enumerate(rows):
                now = index * 34.0
                values[time] = 1000.0 + now
                on = arm == 'treatment' and (index > 0 if entry.get('poll_before_cast') else True)
                values[applied] = 1.0 if on else 0.0
                values[aura] = 1.0 if on and now < lasts_ms + 34.0 else 0.0
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_one_poll_precedes_the_cast_in_both_arms(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), PRE_POLL)
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        for arm, cast in zip(('control', 'treatment'), casts):
            first_read = next(index for index, step in enumerate(steps)
                              if step.get('label') == expectation.model['reads'][arm][0][1])
            self.assertLess(first_read, cast)
        self.assertIn('One poll precedes the cast', scenario['contract'])

    def test_an_application_at_the_cast_is_timed_from_the_read_before_it(self):
        self.assertEqual(self.judged(PRE_POLL, 3000.0).status, 'ok')
        self.assertEqual(self.judged(PRE_POLL, 3600.0).status, 'alert')

    def test_without_the_poll_an_application_at_the_cast_is_unmeasured(self):
        entry = {key: value for key, value in PRE_POLL.items() if key != 'poll_before_cast'}
        self.assertEqual(self.judged(entry, 3000.0).status, 'unmeasured')

    def test_the_option_is_a_boolean(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**PRE_POLL, 'poll_before_cast': 'yes'})
