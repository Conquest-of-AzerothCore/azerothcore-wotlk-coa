from functools import cache
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.stat_arms import parse
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

PASSIVE_ARMS = {
    'mode': 'passive',
    'input': {'metric': 'combat_rating', 'fields': {'rating': 3}},
    'arms': [
        {'aura': 13665, 'stacks': 1, 'source': 'Increased Parry 20 (aura 189, misc 8)'},
        {'aura': 13667, 'stacks': 1, 'source': 'Increased Parry 40 (aura 189, misc 8)'},
    ],
    'unrelated': {
        'metric': 'combat_rating', 'fields': {'rating': 17}, 'aura': 10033, 'stacks': 1,
        'source': 'QA Test +100 Haste Rating (aura 189, misc 917504)',
    },
    'wait_ms': 1000,
}

ACTIVE_ARMS = {
    'mode': 'active_recast',
    'input': {'metric': 'stat', 'fields': {'stat': 2}},
    'arms': [
        {'aura': 706305, 'stacks': 1, 'source': 'QA Test +100 Stamina (aura 29, misc 2)'},
        {'aura': 706305, 'stacks': 2, 'source': 'QA Test +100 Stamina x2 (+200 Stamina)'},
    ],
    'unrelated': {
        'metric': 'stat', 'fields': {'stat': 4}, 'aura': 486, 'stacks': 1,
        'source': 'QA Test +1000 Spirit (aura 29, misc 4)',
    },
    'wait_ms': 100,
}


def passive_entry(**changes) -> dict:
    return {
        'spell': 680579, 'name': 'Dreadful (crit rating rises with parry rating)', 'kind': 'metric_delta',
        'label_suffix': 'crit_parry_arms',
        'quote': 'Increases your critical strike rating based on your parry and dodge rating.',
        'trigger_spell': 60235, 'gate_spell': 680579, 'target': 'caster',
        'metric': 'combat_rating', 'fields': {'rating': 8}, 'tolerance': 0.5,
        'wait_ms': 1000, 'expire_ms': 500, 'void_on_cast_failure': True,
        'stat_arms': PASSIVE_ARMS, **changes,
    }


def active_entry(**changes) -> dict:
    return {
        'spell': 572103, 'name': "Tentacle of N'Zoth (health rises with Stamina)", 'kind': 'metric_delta',
        'label_suffix': 'stamina_health_arms',
        'quote': 'The tentacle gains health based on your Stamina.',
        'trigger_spell': 572103, 'target': 'dummy', 'cast_in_before': False, 'cast_power': 2000,
        'metric': 'owned_creature_max_health', 'fields': {'entry': 501464}, 'tolerance': 0.5,
        'wait_ms': 1000, 'expire_ms': 8500, 'void_on_cast_failure': True,
        'stat_arms': ACTIVE_ARMS, **changes,
    }


@cache
def built_passive():
    return behaviour_scenario(load_class_file(25), passive_entry())


@cache
def built_active():
    return behaviour_scenario(load_class_file(25), active_entry())


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class StatArmsTests(unittest.TestCase):
    def test_generates_valid_scenarios_for_passive_and_active_recast_modes(self):
        p_scen, [p_exp] = built_passive()
        p_valid = run.validate(p_scen)
        self.assertEqual(p_exp.displayed, 'direction')
        self.assertIsNone(p_exp.model['expected'])
        self.assertIsNone(p_exp.model['before_expected'])
        self.assertIn('Stat arms (passive, D-38)', p_valid['contract'])

        a_scen, [a_exp] = built_active()
        a_valid = run.validate(a_scen)
        self.assertEqual(a_exp.displayed, 'direction')
        casts = [step for step in a_valid['steps'] if step['action'] == 'cast' and step.get('spell') == 572103]
        self.assertEqual(len(casts), 4)
        self.assertFalse(any(step.get('label') == a_exp.model['before_label'] for step in a_valid['steps']))
        self.assertIn('Stat arms (active_recast, D-38)', a_valid['contract'])

    def judge_passive(self, ctrl_out=(0.0, 0.0, 0.0, 0.0), lrn_out=(0.0, 20.0, 40.0, 0.0),
                      ctrl_in=(0.0, 20.0, 40.0, 0.0), lrn_in=(0.0, 20.0, 40.0, 0.0),
                      unrel=(0.0, 100.0, 0.0, 100.0), drop=None, cast_failures=None):
        _, [exp] = built_passive()
        rec = exp.model['stat_arms']
        found = {
            rec['before_label']: ctrl_out[0], rec['after_label']: lrn_out[0],
            rec['reads']['control'][0]: ctrl_out[1], rec['reads']['control'][1]: ctrl_out[2],
            rec['reads']['control_unrelated']: ctrl_out[3],
            rec['reads']['learned'][0]: lrn_out[1], rec['reads']['learned'][1]: lrn_out[2],
            rec['reads']['learned_unrelated']: lrn_out[3],
            rec['input']['control'][0]: ctrl_in[0], rec['input']['control'][1]: ctrl_in[1],
            rec['input']['control'][2]: ctrl_in[2], rec['input']['control_unrelated']: ctrl_in[3],
            rec['input']['learned'][0]: lrn_in[0], rec['input']['learned'][1]: lrn_in[1],
            rec['input']['learned'][2]: lrn_in[2], rec['input']['learned_unrelated']: lrn_in[3],
            rec['unrelated']['control_base']: unrel[0], rec['unrelated']['control_active']: unrel[1],
            rec['unrelated']['learned_base']: unrel[2], rec['unrelated']['learned_active']: unrel[3],
        }
        if drop:
            found.pop(drop(rec))
        fake = FakeRun(found)
        fake.cast_failures = cast_failures or {}
        return judge_behaviour(base_verdict(exp), fake, exp)

    def judge_active(self, out=(850.0, 1183.0, 1516.0, 850.0),
                     inputs=(104.0, 204.0, 304.0, 104.0), unrel=(75.0, 1075.0),
                     drop=None, cast_failures=None):
        _, [exp] = built_active()
        rec = exp.model['stat_arms']
        found = {
            rec['after_label']: out[0],
            rec['reads']['levels'][0]: out[1], rec['reads']['levels'][1]: out[2],
            rec['reads']['unrelated']: out[3],
            rec['input']['levels'][0]: inputs[0], rec['input']['levels'][1]: inputs[1],
            rec['input']['levels'][2]: inputs[2], rec['input']['unrelated']: inputs[3],
            rec['unrelated']['base']: unrel[0], rec['unrelated']['active']: unrel[1],
        }
        if drop:
            found.pop(drop(rec))
        fake = FakeRun(found)
        fake.cast_failures = cast_failures or {}
        return judge_behaviour(base_verdict(exp), fake, exp)

    def test_seeded_ok_in_both_modes(self):
        p_verdict = self.judge_passive()
        self.assertEqual(p_verdict.status, 'ok')
        self.assertIsNone(p_verdict.expected)
        self.assertEqual(p_verdict.detail['arm_gains'], [0.0, 20.0, 40.0])

        a_verdict = self.judge_active()
        self.assertEqual(a_verdict.status, 'ok')
        self.assertIsNone(a_verdict.expected)
        self.assertEqual(a_verdict.detail['arm_values'], [850.0, 1183.0, 1516.0])

    def test_mutants_and_non_monotonic_or_unrelated_movement_alert(self):
        self.assertEqual(self.judge_passive(lrn_out=(20.0, 20.0, 20.0, 20.0)).status, 'alert')
        self.assertEqual(self.judge_passive(lrn_out=(0.0, 20.0, 20.0, 0.0)).status, 'alert')
        self.assertEqual(self.judge_passive(lrn_out=(0.0, 40.0, 20.0, 0.0)).status, 'alert')
        self.assertEqual(self.judge_passive(lrn_out=(0.0, 20.0, 40.0, 15.0)).status, 'alert')

        self.assertEqual(self.judge_active(out=(850.0, 850.0, 850.0, 850.0)).status, 'alert')
        self.assertEqual(self.judge_active(out=(850.0, 1183.0, 1183.0, 850.0)).status, 'alert')
        self.assertEqual(self.judge_active(out=(850.0, 1183.0, 1000.0, 850.0)).status, 'alert')
        self.assertEqual(self.judge_active(out=(850.0, 1183.0, 1516.0, 950.0)).status, 'alert')

    def test_unmeasured_on_missing_reads_bad_fixtures_or_cast_failure(self):
        self.assertEqual(self.judge_passive(drop=lambda r: r['reads']['learned'][1]).status, 'unmeasured')
        self.assertEqual(self.judge_passive(ctrl_in=(0.0, 0.0, 40.0, 0.0)).status, 'unmeasured')
        self.assertEqual(self.judge_passive(lrn_in=(0.0, 25.0, 40.0, 0.0)).status, 'unmeasured')
        self.assertEqual(self.judge_passive(unrel=(0.0, 0.0, 0.0, 0.0)).status, 'unmeasured')
        self.assertEqual(self.judge_passive(ctrl_in=(0.0, 20.0, 40.0, 10.0)).status, 'unmeasured')

        self.assertEqual(self.judge_active(drop=lambda r: r['input']['levels'][2]).status, 'unmeasured')
        self.assertEqual(self.judge_active(inputs=(104.0, 104.0, 304.0, 104.0)).status, 'unmeasured')
        self.assertEqual(self.judge_active(unrel=(75.0, 75.0)).status, 'unmeasured')
        self.assertEqual(self.judge_active(inputs=(104.0, 204.0, 304.0, 120.0)).status, 'unmeasured')
        self.assertEqual(self.judge_active(cast_failures={572103: [55]}).status, 'unmeasured')

    def test_refuses_any_expected_figure_fewer_than_three_levels_or_invalid_config(self):
        for bad_raw in (
                {**PASSIVE_ARMS, 'arms': PASSIVE_ARMS['arms'][:1]},
                {**PASSIVE_ARMS, 'arms': [PASSIVE_ARMS['arms'][0], PASSIVE_ARMS['arms'][0]]},
                {**PASSIVE_ARMS, 'unrelated': {**PASSIVE_ARMS['unrelated'], 'fields': {'rating': 3}}},
                {**PASSIVE_ARMS, 'unrelated': {**PASSIVE_ARMS['unrelated'], 'aura': 13665}},
                {**PASSIVE_ARMS, 'expected': 1},
                {**PASSIVE_ARMS, 'slope': 1.0},
                {**PASSIVE_ARMS, 'ratio': 0.5},
                {**PASSIVE_ARMS, 'mode': 'unknown'},
                {**PASSIVE_ARMS, 'wait_ms': -1}):
            with self.subTest(bad_raw=bad_raw), self.assertRaises(ValueError):
                parse(bad_raw)

        for bad_entry in (
                passive_entry(expected=1),
                passive_entry(before_expected=0),
                passive_entry(expected=1, before_expected=0),
                passive_entry(expected_gain=10),
                passive_entry(expected_ratio=2.0),
                passive_entry(after_at_least=10),
                passive_entry(after_at_most=50),
                passive_entry(phase_power=[0, 0, 100]),
                passive_entry(cast_in_before=False),
                passive_entry(fields={'rating': 3}),
                passive_entry(fields={'rating': 17}),
                active_entry(expected=1000),
                active_entry(before_expected=0),
                active_entry(cast_in_before=True)):
            with self.subTest(bad_entry=bad_entry), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(25), bad_entry)


if __name__ == '__main__':
    unittest.main()
