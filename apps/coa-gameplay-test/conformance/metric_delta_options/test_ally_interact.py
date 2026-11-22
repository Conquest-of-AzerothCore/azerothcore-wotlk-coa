import math
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options import ally_interact
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

ARM_SOURCE = 'the interaction makes the ally cast 802145 on itself once, which applies its aura'
BLINK = {
    'spell': 802161, 'name': 'Sun Gate (ally blink)', 'kind': 'metric_delta', 'variant': 'ally_blink',
    'label_suffix': 'ally_blink',
    'quote': 'This leaves behind a Sun Gate for $d that allies can interact with to blink themselves the same '
             'distance forward.',
    'trigger_spell': 802161, 'target': 'caster', 'cast_in_before': False, 'cast_power': 1363,
    'measure_actor': 'ally', 'metric': 'position_x', 'fields': {}, 'before_expected': 0, 'expected': 25,
    'tolerance': 1.0, 'wait_ms': 1500, 'expire_ms': 500,
    'ally_arm': {'allies': 1, 'arms': [{'actors': ['ally'], 'metric': 'aura_apply_count', 'fields': {'spell': 802145},
                                        'before_expected': 0, 'expected': 1, 'tolerance': 0, 'source': ARM_SOURCE}]},
    'ally_offsets': {'ally': 3}, 'ally_interact': {'entry': 50331, 'bearing': 0}}
LOCKOUT = {
    **BLINK, 'variant': 'ally_lockout', 'label_suffix': 'ally_lockout', 'name': 'Sun Gate (ally lockout)',
    'quote': 'Allies can only use Sun Gate every $802148d.', 'cast_in_before': True, 'metric': 'aura_apply_count',
    'fields': {'spell': 802148}, 'before_expected': 1, 'expected': 2, 'tolerance': 0, 'wait_ms': 500,
    'expire_ms': 14500,
    'ally_arm': {'allies': 1, 'arms': [{'actors': ['ally'], 'metric': 'aura_apply_count', 'fields': {'spell': 802145},
                                        'before_expected': 1, 'expected': 2, 'tolerance': 0, 'source': ARM_SOURCE}]},
    'ally_interact': {'entry': 50331, 'lockout_aura': 802148, 'return_yd': 25}}


def changed(entry: dict, **changes) -> dict:
    return {key: value for key, value in {**entry, **changes}.items() if value is not None}


def game_times(scenario: dict) -> dict:
    elapsed, times = 0, {}
    for step in scenario['steps']:
        elapsed += step['ms'] if step['action'] == 'wait' else 0
        if step['action'] == 'gossip_hello':
            times[step['label']] = elapsed
    return times


class ParseTests(unittest.TestCase):
    def test_the_blink_and_lockout_forms_parse(self):
        self.assertEqual(ally_interact.parse({'entry': 50331}), ally_interact.AllyInteract(50331))
        lockout = ally_interact.parse({'entry': 50331, 'lockout_aura': 802148, 'return_yd': 25})
        self.assertEqual((lockout.lockout_aura, lockout.return_yd), (802148, 25.0))
        self.assertEqual(ally_interact.parse({'entry': 1, 'bearing': 0}).bearing_tolerance, 15.0)

    def test_bad_forms_are_refused(self):
        for raw in ({}, {'entry': True}, {'entry': 0}, {'entry': 1, 'other': 1}, {'entry': 1, 'lockout_aura': 2},
                    {'entry': 1, 'return_yd': 5}, {'entry': 1, 'lockout_aura': 2, 'return_yd': 0},
                    {'entry': 1, 'lockout_aura': 2, 'return_yd': 41}, {'entry': 1, 'bearing_tolerance': 5},
                    {'entry': 1, 'bearing': 200}, {'entry': 1, 'lockout_aura': 2, 'return_yd': 5, 'bearing': 0}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                ally_interact.parse(raw)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BlinkTests(unittest.TestCase):
    def test_the_ally_interacts_once_after_the_gate_and_its_position_frames_the_interaction(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(27), BLINK)
        run.validate(scenario)
        steps = scenario['steps']
        interact = next(index for index, step in enumerate(steps) if step['action'] == 'gossip_hello')
        self.assertEqual(len([step for step in steps if step['action'] == 'gossip_hello']), 1)
        names = expectation.model['ally_interact']['after']
        self.assertEqual([step.get('label') for step in steps[interact - 3:interact]],
                         [names['start x'], names['start y'], names['start o']])
        self.assertEqual(steps[interact]['entry'], 50331)
        self.assertEqual(expectation.model['evidence_metric'], 'displacement_2d')

    def judged(self, after_yd, angle_deg=0.0, arm_after=1.0):
        _, [expectation] = behaviour_scenario(load_class_file(27), BLINK)
        shift = expectation.model['ally_interact']
        values = {'802161 position_x before ally_arm 0 ally': 0.0, '802161 position_x after ally_arm 0 ally': arm_after}
        for moment, length in (('before', 0.0), ('after', after_yd)):
            names = shift[moment]
            heading = 0.5 + math.radians(angle_deg)
            values.update({names['start x']: 10.0, names['start y']: 20.0, names['start o']: 0.5,
                           names['end x']: 10.0 + length * math.cos(heading),
                           names['end y']: 20.0 + length * math.sin(heading)})
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_25_yd_forward_blink_passes_and_short_backward_or_missing_blinks_alert(self):
        self.assertEqual(self.judged(25.0).status, 'ok', self.judged(25.0).explanation)
        for after_yd, angle_deg, arm_after in ((20.0, 0.0, 1.0), (25.0, 180.0, 1.0), (0.0, 0.0, 0.0),
                                               (25.0, 0.0, 0.0)):
            with self.subTest(after_yd=after_yd, angle_deg=angle_deg, arm_after=arm_after):
                self.assertEqual(self.judged(after_yd, angle_deg, arm_after).status, 'alert')

    def test_the_blink_needs_an_uncast_before_phase_on_the_grouped_ally(self):
        for change in ({'cast_in_before': True}, {'ally_arm': None}, {'measure_actor': 'caster'},
                       {'metric': 'aura'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(27), changed(BLINK, **change))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class LockoutTests(unittest.TestCase):
    def test_the_tries_fall_at_nine_and_eleven_tenths_of_the_dbc_lockout(self):
        scenario, _ = behaviour_scenario(load_class_file(27), LOCKOUT)
        run.validate(scenario)
        times = game_times(scenario)
        first = times[ally_interact.FIRST_LABEL]
        self.assertEqual(times[ally_interact.REFUSED_LABEL] - first, 81000)
        self.assertEqual(times[ally_interact.ACCEPTED_LABEL] - first, 99000)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 802161]
        self.assertEqual(len(casts), 3)

    def test_a_wrong_expire_wait_names_the_one_that_fits(self):
        with self.assertRaisesRegex(ValueError, 'set expire_ms 14500'):
            behaviour_scenario(load_class_file(27), changed(LOCKOUT, expire_ms=10000))

    def test_the_lockout_needs_both_phase_casts_cast_power_and_the_lockout_aura_count(self):
        for change in ({'cast_in_before': False}, {'cast_power': None}, {'fields': {'spell': 802145}},
                       {'metric': 'aura'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(27), changed(LOCKOUT, **change))

    def test_a_ninety_second_lockout_passes_and_shorter_or_longer_mutants_alert(self):
        _, [expectation] = behaviour_scenario(load_class_file(27), LOCKOUT)
        before, after = expectation.model['before_label'], expectation.model['after_label']
        arms = {'802161 aura_apply_count before ally_arm 0 ally': 1.0,
                '802161 aura_apply_count after ally_arm 0 ally': 2.0}
        for counts, status in (((1.0, 2.0), 'ok'), ((2.0, 3.0), 'alert'), ((1.0, 1.0), 'alert')):
            values = {**arms, before: counts[0], after: counts[1]}
            verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
            with self.subTest(counts=counts):
                self.assertEqual(verdict.status, status, verdict.explanation)


JUDGED = changed(LOCKOUT, fields={'spell': 802145},
                 ally_interact={'entry': 50331, 'lockout_aura': 802148, 'return_yd': 25, 'judged_spell': 802145})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class JudgedSpellTests(unittest.TestCase):
    def test_judged_spell_needs_a_lockout_and_another_spell(self):
        for raw in ({'entry': 1, 'judged_spell': 2}, {'entry': 1, 'lockout_aura': 2, 'return_yd': 5, 'judged_spell': 2},
                    {'entry': 1, 'lockout_aura': 2, 'return_yd': 5, 'judged_spell': True}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                ally_interact.parse(raw)

    def test_the_judged_spell_keeps_the_lockout_timing_and_records_the_lockout_aura(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(27), JUDGED)
        run.validate(scenario)
        times = game_times(scenario)
        first = times[ally_interact.FIRST_LABEL]
        self.assertEqual((times[ally_interact.REFUSED_LABEL] - first, times[ally_interact.ACCEPTED_LABEL] - first),
                         (81000, 99000))
        recorded = expectation.model['ally_interact']['recorded']
        reads = [step for step in scenario['steps'] if step.get('label') in recorded.values()]
        self.assertEqual([(step['metric'], step['spell']) for step in reads], [('aura_apply_count', 802148)] * 2)
        self.assertEqual(expectation.model['ally_interact']['judged_spell'], 802145)

    def test_the_judged_spell_reading_must_match_its_fields(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_class_file(27), changed(JUDGED, fields={'spell': 802148}))

    def test_a_doubled_lockout_record_does_not_alert_but_a_wrong_judged_count_does(self):
        _, [expectation] = behaviour_scenario(load_class_file(27), JUDGED)
        before, after = expectation.model['before_label'], expectation.model['after_label']
        recorded = expectation.model['ally_interact']['recorded']
        arms = {'802161 aura_apply_count before ally_arm 0 ally': 1.0,
                '802161 aura_apply_count after ally_arm 0 ally': 2.0}
        for counts, status in (((1.0, 2.0), 'ok'), ((1.0, 1.0), 'alert'), ((2.0, 3.0), 'alert')):
            values = {**arms, before: counts[0], after: counts[1], recorded['before']: 2.0, recorded['after']: 4.0}
            verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
            with self.subTest(counts=counts):
                self.assertEqual(verdict.status, status, verdict.explanation)

    def test_without_judged_spell_the_lockout_model_is_unchanged(self):
        _, [expectation] = behaviour_scenario(load_class_file(27), LOCKOUT)
        self.assertEqual(expectation.model['ally_interact'], {'lockout_aura': 802148})


if __name__ == '__main__':
    unittest.main()
