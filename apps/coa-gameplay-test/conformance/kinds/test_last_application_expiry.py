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


FED = {**ENTRY, 'label_suffix': 'fed', 'gate_spell': 801899, 'expected_ms': 3000, 'window_ms': 4000, 'poll_ms': 25,
       'caster': True, 'feed': {'every_ms': 1700}}


MALICE = {'spell': 800214, 'name': "Malice of Gul'dan (Felstrike lasts $802678d)", 'kind': 'last_application_expiry',
          'label_suffix': 'felstrike_duration', 'quote': 'over $d', 'gate_spell': 800214, 'trigger_spell': 801312,
          'aura': 802678, 'expected_ms': 6000, 'control_window_ms': 500, 'window_ms': 8000, 'poll_ms': 50,
          'caster': False, 'force_crit': 'spell', 'feed': {'every_ms': 2000, 'stop_aura': 800239},
          'quote_spell': 802678}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FeedTests(unittest.TestCase):
    def judged(self, lasts_ms: float, stop: float = 1.0, control_applied: bool = False, before: float = 0.0,
               entry: dict = FED, remaining: float | None = None, age: float = 20.0, applies: float = 1.0,
               unstamped: tuple[str, ...] = (), timeline: tuple[dict, ...] | None = None) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        values = {}
        stamps = expectation.model['feed']['reads']['treatment']['stamps']
        values[stamps['start']] = 50000.0
        values[stamps['applies']] = applies
        values[stamps['first']] = 61000.0 - 50000.0 - age
        for name in unstamped:
            values[stamps[name]] = float('nan')
        for arm, rows in expectation.model['reads'].items():
            reads = expectation.model['feed']['reads'][arm]
            values[reads['stop']] = stop if arm == 'treatment' else 0.0
            values[reads['remaining']] = (lasts_ms - 20.0 if remaining is None else remaining) \
                if arm == 'treatment' else 0.0
            for index, (time, applied, aura) in enumerate(rows):
                now = 1000.0 if index == 0 else 61000.0 + (index - 1) * 34.0
                values[time] = now
                if arm == 'control':
                    values[applied] = 1.0 if control_applied and index else 0.0
                    values[aura] = 0.0
                    continue
                granted = index > 0
                values[applied] = 1.0 if granted else 0.0
                values[aura] = before if index == 0 else (1.0 if now < 61000.0 - 20.0 + lasts_ms else 0.0)
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        found = FakeRun(values)
        if timeline is not None:
            found.timeline = timeline
        return judge_behaviour(base, found, expectation)

    def test_the_loop_is_capped_by_the_proc_chance_and_both_arms_are_fed(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), FED)
        run.validate(scenario)
        loops = [step for step in scenario['steps'] if step['action'] == 'cast_until_aura']
        self.assertEqual([step['max_casts'] for step in loops], [47, 47])
        self.assertTrue(all(step['aura'] == 707010 and step['every_ms'] == 1700 and step['reset_cooldown']
                            for step in loops))
        self.assertEqual(expectation.model['feed']['max_casts'], 47)
        self.assertFalse([step for step in scenario['steps'] if step['action'] == 'cast'])

    def test_a_sixty_percent_roll_needs_nine_forced_crit_casts(self):
        entry = {**FED, 'gate_spell': 800214, 'force_crit': 'melee'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        self.assertEqual({step['max_casts'] for step in scenario['steps'] if step['action'] == 'cast_until_aura'}, {9})
        self.assertEqual((scenario['players'][0]['melee_crit_rating'], scenario['players'][0]['melee_hit_rating']),
                         (100000, 100000))

    def test_a_quote_is_taken_from_an_embedded_tooltip(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), MALICE)
        run.validate(scenario)
        self.assertEqual(expectation.model['quote'], 'over $d')
        self.assertEqual({step['max_casts'] for step in scenario['steps'] if step['action'] == 'cast_until_aura'}, {9})
        self.assertEqual((scenario['players'][0]['spell_crit_rating'], scenario['players'][0]['spell_hit_rating']),
                         (100000, 100000))
        self.assertNotIn('melee_crit_rating', scenario['players'][0])

    def test_a_quote_from_a_spell_the_tooltip_does_not_embed_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'does not embed'):
            behaviour_scenario(load_fixture_class_file(23), {**MALICE, 'quote_spell': 801902})

    def test_a_dummy_aura_stops_on_a_named_caster_aura(self):
        entry = {**FED, 'caster': False, 'feed': {'every_ms': 1700, 'stop_aura': 707010}}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        loop = next(step for step in scenario['steps'] if step['action'] == 'cast_until_aura')
        self.assertEqual(loop['aura'], 707010)
        reads = [step for step in scenario['steps'] if step.get('metric') == 'aura_duration_ms']
        self.assertTrue(reads and all(step['actor'] == 'dummy' for step in reads))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**entry, 'feed': {'every_ms': 1700}})

    def test_three_seconds_after_the_grant_passes(self):
        verdict = self.judged(3000.0)
        self.assertEqual(verdict.status, 'ok')
        self.assertLess(abs(verdict.measured - 3000.0), 200.0)

    def test_an_aura_older_than_the_stamp_at_the_first_read_is_unmeasured(self):
        self.assertEqual(self.judged(3000.0, age=120.0).status, 'unmeasured')
        self.assertEqual(self.judged(3000.0, age=100.0).status, 'ok')

    def test_a_stale_stamp_hiding_a_longer_aura_is_unmeasured(self):
        entry = {**MALICE, 'poll_ms': 25}
        verdict = self.judged(6020.0, entry=entry, remaining=6000.0, age=400.0)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('up to 400 ms old', verdict.explanation)
        self.assertEqual(self.judged(6020.0, entry=entry, remaining=6000.0, age=20.0).status, 'ok')

    def test_an_unstamped_or_refreshed_aura_is_unmeasured(self):
        self.assertEqual(self.judged(3000.0, remaining=0.0).status, 'unmeasured')
        for name in ('start', 'applies', 'first'):
            self.assertEqual(self.judged(3000.0, unstamped=(name,)).status, 'unmeasured')
        self.assertEqual(self.judged(3000.0, applies=2.0).status, 'unmeasured')
        self.assertEqual(self.judged(3000.0, applies=0.0).status, 'unmeasured')

    def test_only_the_fed_treatment_opens_a_timeline(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), MALICE)
        starts = [index for index, step in enumerate(scenario['steps']) if step['action'] == 'encounter_start']
        loops = [index for index, step in enumerate(scenario['steps']) if step['action'] == 'cast_until_aura']
        self.assertEqual(len(starts), 1)
        self.assertTrue(loops[0] < starts[0] < loops[1])
        self.assertNotIn('stamps', expectation.model['feed']['reads']['control'])
        stamped = [step for step in scenario['steps'] if step.get('event') == 'aura_applied']
        self.assertEqual({(step['spell'], tuple(step['target_actors'])) for step in stamped}, {(802678, ('dummy',))})
        self.assertIn('exclusive in a batch', scenario['contract'])

    def test_a_longer_or_shorter_aura_alerts(self):
        self.assertEqual(self.judged(3900.0).status, 'alert')
        self.assertEqual(self.judged(2100.0).status, 'alert')

    def test_a_loop_that_reached_its_cap_is_unmeasured(self):
        verdict = self.judged(3000.0, stop=0.0)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('cap of 47 casts', verdict.explanation)

    def test_an_aura_left_before_the_feed_is_unmeasured(self):
        self.assertEqual(self.judged(3000.0, before=1.0).status, 'unmeasured')

    def test_a_control_application_alerts(self):
        self.assertEqual(self.judged(3000.0, control_applied=True).status, 'alert')

    def test_the_feed_rules(self):
        for changes in ({'repeat': {'count': 2, 'every_ms': 500}}, {'no_refresh': True},
                        {'feed': {'every_ms': 1000}}, {'feed': {'every_ms': 1700, 'cap': 5}}, {'feed': {}},
                        {'gate_spell': 801902}, {'force_crit': 'fire'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**FED, **changes})

    def test_without_the_option_nothing_changes(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        self.assertNotIn('feed', expectation.model)
        self.assertNotIn('cast_until_aura', [step['action'] for step in scenario['steps']])
        self.assertNotIn('melee_crit_rating', scenario['players'][0])
        self.assertNotEqual(scenario['players'][0].get('melee_hit_rating'), 100000)

SAME_STAMP = {**FED, 'same_stamp_applies': True}


def applied(aura: int, at_ms: int, target: str = 'caster') -> dict:
    return {'at_ms': str(at_ms), 'event': 'aura_applied', 'source_entry': '0', 'spell': str(aura), 'target': target,
            'value': '1'}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SameStampAppliesTests(unittest.TestCase):
    judged = FeedTests.judged

    def aura(self) -> int:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), SAME_STAMP)
        return expectation.model['feed']['same_stamp']['aura']

    def test_the_option_reads_no_new_step_and_names_the_holder(self):
        plain, [bare] = behaviour_scenario(load_fixture_class_file(23), FED)
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), SAME_STAMP)
        run.validate(scenario)
        self.assertEqual(scenario['steps'], plain['steps'])
        self.assertNotIn('same_stamp', bare.model['feed'])
        self.assertEqual(expectation.model['feed']['same_stamp'], {'aura': FED['aura'], 'holder': 'caster'})

    def test_a_single_apply_is_judged_as_without_the_option(self):
        aura = self.aura()
        for timeline in ((), (applied(aura, 12),)):
            verdict = self.judged(3000.0, entry=SAME_STAMP, timeline=timeline)
            self.assertEqual(verdict.status, 'ok')
            self.assertEqual(verdict.measured, self.judged(3000.0).measured)

    def test_applies_at_one_recorded_game_time_are_judged_from_that_stamp(self):
        aura = self.aura()
        timeline = (applied(aura, 12), {**applied(aura, 12), 'event': 'cast', 'target': ''}, applied(aura, 12))
        verdict = self.judged(3000.0, entry=SAME_STAMP, applies=2.0, timeline=timeline)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('2 stamped applies at one game time (12 ms)', verdict.explanation)
        self.assertEqual(self.judged(3900.0, entry=SAME_STAMP, applies=2.0, timeline=timeline).status, 'alert')

    def test_applies_at_different_game_times_are_unmeasured(self):
        aura = self.aura()
        verdict = self.judged(3000.0, entry=SAME_STAMP, applies=2.0, timeline=(applied(aura, 12), applied(aura, 40)))
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('recorded at 12, 40 ms', verdict.explanation)

    def test_a_recorded_count_that_differs_from_the_stamped_one_is_unmeasured(self):
        aura = self.aura()
        for timeline in ((applied(aura, 12),), (applied(aura, 12), applied(aura, 12), applied(aura, 12)),
                         (applied(aura, 12), applied(aura, 12, 'dummy')), (applied(aura, 12), applied(aura + 1, 12))):
            with self.subTest(timeline=timeline):
                self.assertEqual(self.judged(3000.0, entry=SAME_STAMP, applies=2.0, timeline=timeline).status,
                                 'unmeasured')

    def test_an_empty_or_missing_timeline_is_unmeasured(self):
        self.assertEqual(self.judged(3000.0, entry=SAME_STAMP, applies=2.0, timeline=()).status, 'unmeasured')
        self.assertEqual(self.judged(3000.0, entry=SAME_STAMP, applies=2.0).status, 'unmeasured')

    def test_without_the_option_a_same_stamp_double_stays_unmeasured(self):
        aura = self.aura()
        verdict = self.judged(3000.0, applies=2.0, timeline=(applied(aura, 12), applied(aura, 12)))
        self.assertEqual(verdict.status, 'unmeasured')

    def test_the_option_needs_a_feed_and_a_boolean(self):
        for entry in ({**ENTRY, 'same_stamp_applies': True}, {**SAME_STAMP, 'same_stamp_applies': 1}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
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
