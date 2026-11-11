import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from behaviours import NotModelled, behaviour_entries
from compare import Run, Verdict, evaluate, judge_behaviour
from coverage import BEHAVIOUR, EVIDENCE
from expiry import (BEHAVIOUR_EXPIRIES, BEHAVIOUR_EXPIRY, CLOCK_STEP_MS, LOCKOUT_METRIC, SCHOOL_LOCKOUT,
                    act_margins_of, behaviour_expiry, expiry_arm, lands_within_its_cast_step, margins_of, pair_steps,
                    school_lockout_scenario, shift_of, trigger_expiry)
from hits import MAX_ACCELERATED_SCENARIO_MS
from profile import DBC_DIR, load_class_file
from tooltip import Records
from values import dataset

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import run

CLASS_FILE = load_class_file(19)
TESTAMENT_OF_STRENGTH = 300514
BLESSING_OF_AGGRAMAR = 300502
FINESSE_RANK_2 = 707851
COURAGE_RANK_1 = 707754
SACRED_OATH = 712346
HOLY_COMBATANT = 500011
RIGHTEOUS_CUSTODIAN = 572808
OATH_FLOW = 705283
DEEP_SECRETS = 705263
SACRED_RESTRAINT = 102208
BECKON = 804914
FROSTBOLT = 116
TITANSTRIKE = 806521
CONDEMN = 804906
DIVINE_FORCE = 806153
EVOCATION = 12051
EXPIRY_ENTRIES = (TESTAMENT_OF_STRENGTH, BLESSING_OF_AGGRAMAR, 705271, FINESSE_RANK_2, COURAGE_RANK_1, 712466,
                  SACRED_OATH, BECKON)


def behaviour(spell: int) -> dict:
    return next(entry for entry in behaviour_entries(CLASS_FILE, [spell]) if entry['kind'] in BEHAVIOUR_EXPIRIES)


def trigger(aura: int) -> dict:
    return next(entry for entry in CLASS_FILE['triggers'] if entry['aura'] == aura)


def built(spell: int):
    found = trigger_expiry(CLASS_FILE, trigger(spell)) if spell == HOLY_COMBATANT \
        else behaviour_expiry(CLASS_FILE, behaviour(spell))
    scenario, expectations = found
    return scenario, expectations[0]


def simulated(scenario: dict, expectation, ends: dict[str, float], gap_ms: float = CLOCK_STEP_MS,
              overshoot_ms: float = 0.0, values: dict[str, float] | None = None, max_step: float | None = 25.0):
    arms = expectation.model['arms']
    by_applied = {arm['applied_label'] or arm['act_label']: arm for arm in arms}
    readings = {arm['before_label']: arm for arm in arms} | {arm['after_label']: arm for arm in arms}
    clock, applied, steps, found = 0.0, {}, [], dict(values or {})
    for index, step in enumerate(scenario['steps']):
        clock += gap_ms if index else 0.0
        elapsed = step['ms'] + overshoot_ms if step['action'] == 'wait' else 0.0
        clock += elapsed
        label = step.get('label', step['action'])
        steps.append({'index': str(index), 'action': step['action'], 'label': label, 'elapsed_ms': str(elapsed)})
        if label in by_applied:
            applied[by_applied[label]['name']] = clock
        if label in readings:
            arm = readings[label]
            start = applied[arm['name']]
            found[label] = 1.0 if clock - start < ends[arm['name']] else 0.0
    for requirement, value in (expectation.model['arms'][0]['requires'] + expectation.model['arms'][-1]['requires']):
        found.setdefault(requirement, value)
    return Run('expiry-run', 'passed', '', found, steps, max_step)


def judged(spell: int, ends: dict[str, float] | None = None, **options) -> Verdict:
    scenario, expectation = built(spell)
    stated = {arm['name']: arm['expected_ms'] for arm in expectation.model['arms']}
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'expiry-run', expectation.spell_id,
                   expectation.rank_id, expectation.check)
    return judge_behaviour(base, simulated(scenario, expectation, stated | (ends or {}), **options), expectation)


def stated_ends(spell: int) -> dict[str, float]:
    return {arm['name']: arm['expected_ms'] for arm in built(spell)[1].model['arms']}


class MarginTest(unittest.TestCase):
    def test_margins_leave_room_for_the_step_slack_on_both_sides(self):
        self.assertEqual(margins_of(4200, []), (105, 34))
        self.assertEqual(margins_of(60000, []), (1500, 1500))

    def test_steps_after_the_act_widen_the_before_margin(self):
        tail = [{'action': 'wait', 'ms': 500}, {'action': 'cast'}]
        before, after = margins_of(7000, tail)
        self.assertEqual(before, (3 + 4) * CLOCK_STEP_MS + 1)
        self.assertLess(after + (3 + 7) * CLOCK_STEP_MS, shift_of(7000))

    def test_a_short_end_has_no_judgeable_pair(self):
        with self.assertRaises(NotModelled):
            margins_of(3000, [])

    def test_a_short_end_timed_from_the_act_itself_has_a_pair(self):
        self.assertEqual(act_margins_of(3000), (124, 26))
        before, after = act_margins_of(2600)
        self.assertGreater(before, 2 * CLOCK_STEP_MS)
        self.assertLess(after, shift_of(2600) - 4 * CLOCK_STEP_MS)
        with self.assertRaises(NotModelled):
            act_margins_of(2500)

    def test_pair_reads_before_and_after_the_stated_end(self):
        arm = expiry_arm('1 2', 'with', 5100)
        steps = pair_steps(arm, 'caster', 2)
        self.assertEqual([step['action'] for step in steps], ['wait', 'assert', 'wait', 'assert'])
        self.assertEqual(steps[0]['ms'], 5100 - arm.before_margin_ms)
        self.assertEqual(steps[2]['ms'], arm.before_margin_ms + arm.after_margin_ms)
        self.assertEqual({steps[1]['metric'], steps[3]['metric']}, {'aura'})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TemplarExpiryScenarioTest(unittest.TestCase):
    def test_every_duration_entry_gets_a_valid_expiry_scenario(self):
        for spell in (*EXPIRY_ENTRIES, HOLY_COMBATANT):
            with self.subTest(spell=spell):
                scenario, expectation = built(spell)
                run.validate(scenario)
                self.assertEqual(expectation.check, BEHAVIOUR_EXPIRY)
                self.assertEqual(EVIDENCE[expectation.check], BEHAVIOUR)

    def test_a_half_hour_end_fits_only_an_accelerated_scenario(self):
        self.assertEqual(MAX_ACCELERATED_SCENARIO_MS, run.MAX_SIMULATED_TIMEOUT_MS[1])
        scenario, expectation = built(RIGHTEOUS_CUSTODIAN)
        self.assertEqual(stated_ends(RIGHTEOUS_CUSTODIAN), {'cast': 1800000.0})
        self.assertGreater(scenario['timeout_ms'], run.MAX_TIMEOUT_MS[1])
        self.assertIs(run.validate(scenario, run.SIMULATED_CLOCK), scenario)
        with self.assertRaisesRegex(ValueError, 'too large'):
            run.validate(scenario)
        arm = expectation.model['arms'][0]
        self.assertEqual((arm['before_margin_ms'], arm['after_margin_ms'], arm['requires']),
                         (45000, 45000, [['572808 572808 before cast', 0.0]]))

    def test_stated_ends_come_from_the_dbc_and_the_tooltip(self):
        self.assertEqual(stated_ends(TESTAMENT_OF_STRENGTH), {'cast': 60000.0})
        self.assertEqual(stated_ends(FINESSE_RANK_2), {'without': 6000.0, 'with': 4200.0})
        self.assertEqual(stated_ends(COURAGE_RANK_1), {'without': 15000.0, 'with': 13500.0})
        self.assertEqual(stated_ends(BLESSING_OF_AGGRAMAR), {'without': 30000.0, 'with': 30000.0})
        self.assertEqual(stated_ends(SACRED_OATH), {'without': 8000.0, 'with': 7000.0})
        self.assertEqual(stated_ends(HOLY_COMBATANT), {'without': 6000.0, 'with': 7000.0})

    def test_a_three_second_taunt_is_timed_from_its_cast_and_read_on_the_dummy(self):
        scenario, expectation = built(BECKON)
        self.assertEqual(stated_ends(BECKON), {'cast': 3000.0})
        arm = expectation.model['arms'][0]
        self.assertIsNone(arm['applied_label'])
        self.assertEqual((arm['before_margin_ms'], arm['after_margin_ms'], arm['requires']),
                         (124, 26, [[f'{BECKON} {BECKON} before cast', 0.0]]))
        act = next(index for index, step in enumerate(scenario['steps']) if step.get('label') == arm['act_label'])
        tail = scenario['steps'][act + 1:]
        self.assertEqual([step['action'] for step in tail], ['wait', 'assert', 'wait', 'assert'])
        self.assertEqual([tail[0]['ms'], tail[2]['ms']], [3000 - 124, 124 + 26])
        self.assertEqual({tail[1]['actor'], tail[3]['actor']}, {'dummy'})
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['dummy'])

    def test_only_an_instant_spell_without_travel_lands_its_own_aura_within_its_cast_step(self):
        records = Records(dataset(DBC_DIR))
        self.assertTrue(lands_within_its_cast_step(records, BECKON, BECKON))
        self.assertFalse(lands_within_its_cast_step(records, BECKON, SACRED_RESTRAINT))
        self.assertFalse(lands_within_its_cast_step(records, FROSTBOLT, FROSTBOLT))

    def test_a_control_arm_casts_before_the_passive_is_learned_and_ends_at_the_unmodified_duration(self):
        scenario, expectation = built(OATH_FLOW)
        self.assertEqual(stated_ends(OATH_FLOW), {'without': 15000.0, 'with': 18000.0})
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        without, with_arm = expectation.model['arms']
        learned = next(index for index, step in enumerate(steps)
                       if step['action'] == 'learn' and step['spell'] == OATH_FLOW)
        reset = next(index for index, step in enumerate(steps) if step['action'] == 'reset_cooldown')
        self.assertLess(labels.index(without['after_label']), reset)
        self.assertLess(reset, learned)
        self.assertLess(learned, labels.index(with_arm['act_label']))
        self.assertEqual(without['requires'], with_arm['requires'])

    def test_a_control_arm_clears_the_auras_it_names_before_the_second_cast(self):
        entry = next(entry for entry in behaviour_entries(CLASS_FILE, [DEEP_SECRETS])
                     if entry.get('label_suffix') == 'testament')
        scenario, (expectation,) = behaviour_expiry(CLASS_FILE, entry)
        steps = scenario['steps']
        cleared = next(index for index, step in enumerate(steps)
                       if step['action'] == 'set_aura' and step['spell'] == SACRED_RESTRAINT)
        labels = [step.get('label') for step in steps]
        without, with_arm = expectation.model['arms']
        self.assertEqual(steps[cleared]['stacks'], 0)
        self.assertLess(labels.index(without['after_label']), cleared)
        self.assertLess(cleared, labels.index(with_arm['act_label']))
        self.assertEqual(expectation.label, f'{DEEP_SECRETS} {BEHAVIOUR_EXPIRY} testament')

    def test_seeded_passive_that_leaves_the_duration_unchanged_alerts(self):
        self.assertEqual(judged(OATH_FLOW).status, 'ok')
        self.assertEqual(judged(OATH_FLOW, {'with': 15000.0}).status, 'alert')
        self.assertEqual(judged(DEEP_SECRETS).status, 'ok')
        self.assertEqual(judged(DEEP_SECRETS, {'with': 20000.0}).status, 'alert')
        self.assertEqual(judged(DEEP_SECRETS, {'without': 30000.0}).status, 'alert')

    def test_an_extra_cast_arm_learns_the_spell_before_both_casts_and_casts_it_inside_the_with_arm(self):
        scenario, expectation = built(TITANSTRIKE)
        self.assertEqual(stated_ends(TITANSTRIKE), {'without': 15000.0, 'with': 18000.0})
        steps = run.validate(scenario)['steps']
        labels = [step.get('label') for step in steps]
        without, with_arm = expectation.model['arms']
        learned = next(index for index, step in enumerate(steps)
                       if step['action'] == 'learn' and step['spell'] == TITANSTRIKE)
        extra = next(index for index, step in enumerate(steps)
                     if step['action'] == 'cast' and step['spell'] == TITANSTRIKE)
        self.assertLess(learned, labels.index(without['act_label']))
        self.assertEqual(steps[labels.index(without['act_label'])]['spell'], CONDEMN)
        self.assertLess(labels.index(with_arm['applied_label']), extra)
        self.assertLess(extra, labels.index(with_arm['before_label']))
        self.assertEqual([step['spell'] for step in steps if step['action'] == 'cast'], [CONDEMN, CONDEMN, TITANSTRIKE])

    def test_seeded_extra_cast_that_leaves_the_duration_unchanged_alerts(self):
        self.assertEqual(judged(TITANSTRIKE).status, 'ok')
        self.assertEqual(judged(TITANSTRIKE, {'with': 15000.0}).status, 'alert')

    def test_seeded_extra_cast_that_refreshes_the_aura_to_its_maximum_alerts(self):
        extra = behaviour(TITANSTRIKE)['control']['extra_cast']
        self.assertNotEqual(extra['after_ms'], 3000)
        self.assertEqual(judged(TITANSTRIKE, {'with': extra['after_ms'] + 15000.0}).status, 'alert')
        learns = [step for step in built(TITANSTRIKE)[0]['steps']
                  if step['action'] == 'learn' and step['spell'] == TITANSTRIKE]
        self.assertEqual(len(learns), 1)

    def test_an_extra_cast_names_its_spell_target_and_delay(self):
        entry = behaviour(TITANSTRIKE)
        broken = {**entry, 'control': {**entry['control'], 'extra_cast': {'spell': TITANSTRIKE}}}
        with self.assertRaises(ValueError):
            behaviour_expiry(CLASS_FILE, broken)

    def test_a_control_arm_needs_a_separate_cast_spell(self):
        entry = {key: value for key, value in behaviour(OATH_FLOW).items() if key not in ('cast_spell', 'cast_target')}
        with self.assertRaises(ValueError):
            behaviour_expiry(CLASS_FILE, entry)

    def test_the_refresh_arm_times_its_end_from_the_breaker_cast(self):
        scenario, expectation = built(BLESSING_OF_AGGRAMAR)
        arm = expectation.model['arms'][1]
        act = next(step for step in scenario['steps'] if step.get('label') == arm['act_label'])
        self.assertEqual(act['spell'], behaviour(BLESSING_OF_AGGRAMAR)['breaker_spell'])
        self.assertIsNone(arm['applied_label'])

    def test_the_ratio_arms_are_one_landed_cast_each_past_the_diminishing_returns_window(self):
        scenario, _ = built(FINESSE_RANK_2)
        casts = [index for index, step in enumerate(scenario['steps']) if step['action'] == 'cast']
        self.assertEqual(len(casts), 2)
        between = scenario['steps'][casts[0]:casts[1]]
        self.assertGreaterEqual(sum(step.get('ms', 0) for step in between if step['action'] == 'wait'),
                                6000 + 15000)

    def test_a_conformant_server_is_ok_with_the_widest_step_slack_and_without_it(self):
        for spell in (*EXPIRY_ENTRIES, HOLY_COMBATANT):
            for gap in (0.0, CLOCK_STEP_MS):
                with self.subTest(spell=spell, gap=gap):
                    self.assertEqual(judged(spell, gap_ms=gap).status, 'ok')

    def test_a_server_off_by_the_shift_alerts(self):
        for spell in (*EXPIRY_ENTRIES, HOLY_COMBATANT):
            for sign in (1, -1):
                with self.subTest(spell=spell, sign=sign):
                    ends = {name: end + sign * shift_of(end) for name, end in stated_ends(spell).items()}
                    self.assertEqual(judged(spell, ends).status, 'alert')

    def test_seeded_wrong_ratio_alerts(self):
        self.assertEqual(judged(FINESSE_RANK_2, {'with': 0.75 * 6000}).status, 'alert')
        self.assertEqual(judged(COURAGE_RANK_1, {'with': 15000.0}).status, 'alert')

    def test_seeded_missing_delta_or_refresh_alerts(self):
        self.assertEqual(judged(SACRED_OATH, {'with': 8000.0}).status, 'alert')
        self.assertEqual(judged(HOLY_COMBATANT, {'with': 6000.0}).status, 'alert')
        self.assertEqual(judged(BLESSING_OF_AGGRAMAR, {'with': 26000.0}).status, 'alert')
        self.assertEqual(judged(BLESSING_OF_AGGRAMAR, {'without': 34000.0}).status, 'alert')

    def test_an_ok_verdict_states_the_end_interval_it_excludes(self):
        verdict = judged(FINESSE_RANK_2)
        low, high = verdict.detail['expiry'][1]['end_ms']
        self.assertGreater(low, 4200 - shift_of(4200))
        self.assertLess(high, 4200 + shift_of(4200))
        self.assertIn('is excluded', verdict.explanation)

    def test_late_readings_are_unmeasured_not_ok(self):
        self.assertEqual(judged(FINESSE_RANK_2, gap_ms=CLOCK_STEP_MS, overshoot_ms=150.0).status, 'unmeasured')

    def test_missing_step_timing_is_unmeasured(self):
        self.assertEqual(judged(TESTAMENT_OF_STRENGTH, max_step=None).status, 'unmeasured')

    def test_a_failed_precondition_is_unmeasured(self):
        scenario, expectation = built(SACRED_OATH)
        crit = expectation.model['arms'][1]['requires'][0][0]
        values = {crit: 1.0}
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'expiry-run', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        found = simulated(scenario, expectation, stated_ends(SACRED_OATH), values=values)
        self.assertEqual(judge_behaviour(base, found, expectation).status, 'unmeasured')

    def test_a_missing_reading_alerts(self):
        scenario, expectation = built(TESTAMENT_OF_STRENGTH)
        found = simulated(scenario, expectation, stated_ends(TESTAMENT_OF_STRENGTH))
        values = {label: value for label, value in found.values.items() if 'after_expiry' not in label}
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'expiry-run', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        missing = Run(found.key, found.status, found.message, values, found.steps, found.max_step_ms)
        self.assertEqual(judge_behaviour(base, missing, expectation).status, 'alert')


def lockout_entry() -> dict:
    entry = next((entry for entry in CLASS_FILE['behaviours']
                  if entry['spell'] == DIVINE_FORCE and entry['kind'] == SCHOOL_LOCKOUT), None)
    if entry is None:
        raise unittest.SkipTest("the other side's Divine Force school lockout entry is not in this branch's class file")
    return entry


def lockout_judged(ends: dict[str, float] | None = None, **options) -> Verdict:
    scenario, expectations = school_lockout_scenario(CLASS_FILE, lockout_entry())
    expectation = expectations[0]
    stated = {arm['name']: arm['expected_ms'] for arm in expectation.model['arms']}
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'expiry-run', expectation.spell_id,
                   expectation.rank_id, expectation.check)
    return judge_behaviour(base, simulated(scenario, expectation, stated | (ends or {}), **options), expectation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SchoolLockoutTest(unittest.TestCase):
    def test_the_lockout_is_read_on_a_channelling_dummy_and_timed_from_the_interrupting_cast(self):
        scenario, expectations = school_lockout_scenario(CLASS_FILE, lockout_entry())
        run.validate(scenario)
        expectation = expectations[0]
        self.assertEqual((expectation.label, expectation.check, expectation.model['observe_metric']),
                         (f'{DIVINE_FORCE} {BEHAVIOUR_EXPIRY} lockout', BEHAVIOUR_EXPIRY, LOCKOUT_METRIC))
        arm = expectation.model['arms'][0]
        self.assertEqual((arm['expected_ms'], arm['applied_label'], arm['before_margin_ms'], arm['after_margin_ms']),
                         (3000.0, None, 124, 26))
        self.assertEqual([label.split()[-3:] for label, _ in arm['requires']],
                         [['lockout', 'before', 'cast'], ['channel', 'before', 'cast']])
        steps = scenario['steps']
        channel = next(index for index, step in enumerate(steps) if step.get('spell') == EVOCATION)
        act = next(index for index, step in enumerate(steps) if step.get('label') == arm['act_label'])
        self.assertLess(channel, act)
        self.assertEqual((steps[channel]['actor'], steps[act]['spell'], steps[act]['target']),
                         ('dummy', 807805, 'dummy'))
        reads = [step for step in steps[act + 1:] if step['action'] == 'assert']
        self.assertEqual({(step['actor'], step['metric'], step['school_mask']) for step in reads},
                         {('dummy', LOCKOUT_METRIC, 64)})
        self.assertEqual([step['ms'] for step in steps[act + 1:] if step['action'] == 'wait'], [2876, 150])

    def test_a_conformant_lockout_is_ok(self):
        for gap in (0.0, CLOCK_STEP_MS):
            with self.subTest(gap=gap):
                self.assertEqual(lockout_judged(gap_ms=gap).status, 'ok')

    def test_seeded_lockout_held_by_the_stun_or_shortened_alerts(self):
        self.assertEqual(lockout_judged({'cast': 6000.0}).status, 'alert')
        self.assertEqual(lockout_judged({'cast': 3000.0 - shift_of(3000.0)}).status, 'alert')
        self.assertEqual(lockout_judged({'cast': 0.0}).status, 'alert')

    def test_a_dummy_that_was_not_channelling_is_unmeasured(self):
        scenario, expectations = school_lockout_scenario(CLASS_FILE, lockout_entry())
        expectation = expectations[0]
        channel = expectation.model['arms'][0]['requires'][1][0]
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'expiry-run', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        found = simulated(scenario, expectation, {'cast': 3000.0}, values={channel: 0.0})
        self.assertEqual(judge_behaviour(base, found, expectation).status, 'unmeasured')

    def test_a_spell_an_interrupt_cannot_stop_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'not a channel an interrupt stops'):
            school_lockout_scenario(CLASS_FILE, {**lockout_entry(), 'channel_spell': FROSTBOLT})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class GenerateExpiryTest(unittest.TestCase):
    def setUp(self):
        self.out = Path(tempfile.mkdtemp(prefix='conformance-expiry-'))

    def tearDown(self):
        shutil.rmtree(self.out)

    def test_generate_adds_one_expiry_scenario_beside_the_readback(self):
        from conformance import generate
        manifest = json.loads(generate(19, self.out, behaviours=[FINESSE_RANK_2],
                                       triggers=[HOLY_COMBATANT]).read_text(encoding='utf-8'))
        kinds = sorted(entry['kind'] for entry in manifest['scenarios'])
        self.assertEqual(kinds.count('expiry'), 2)
        self.assertIn('behaviour', kinds)
        self.assertIn('trigger', kinds)
        labels = {data['label'] for entry in manifest['scenarios'] if entry['kind'] == 'expiry'
                  for data in entry['expectations']}
        self.assertEqual(labels, {f'{FINESSE_RANK_2} {BEHAVIOUR_EXPIRY}', f'{HOLY_COMBATANT} {BEHAVIOUR_EXPIRY}'})

    def test_compare_judges_the_expiry_expectation(self):
        from conformance import generate
        manifest_path = generate(19, self.out, behaviours=[TESTAMENT_OF_STRENGTH])
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
        entry = next(entry for entry in manifest['scenarios'] if entry['kind'] == 'expiry')
        scenario = json.loads((self.out / entry['file']).read_text(encoding='utf-8'))
        _, expectation = built(TESTAMENT_OF_STRENGTH)
        found = simulated(scenario, expectation, stated_ends(TESTAMENT_OF_STRENGTH))
        results = self.out / 'results' / 'gameplay' / 'exploratory' / entry['key']
        results.mkdir(parents=True)
        (results / 'summary.json').write_text(json.dumps({'scenario_sha256': entry['sha256'],
                                                          'binary_sha256': 'f' * 64}), encoding='utf-8')
        (results / 'result.json').write_text(json.dumps(
            {'status': 'passed', 'message': 'All assertions passed', 'max_step_ms': '25',
             'server_version': 'AzerothCore rev. 0123456789ab 2026-11-11 03:00:00 +0100 (test branch)',
             'steps': [{**step, 'actual': str(found.values[step['label']])}
                       if step['label'] in found.values else step for step in found.steps]}), encoding='utf-8')
        verdicts = [verdict for verdict in evaluate(manifest_path, self.out / 'results').verdicts
                    if verdict.check == BEHAVIOUR_EXPIRY]
        self.assertEqual([verdict.status for verdict in verdicts], ['ok'])


if __name__ == '__main__':
    unittest.main()
