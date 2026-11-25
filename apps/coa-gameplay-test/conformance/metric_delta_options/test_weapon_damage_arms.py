from functools import cache
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.weapon_damage_arms import parse
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

WEAPON_ARMS = {
    'weapons': [
        {'item': 2534, 'source': 'Dreadnought Rondel (28.46-45.46)'},
        {'item': 2535, 'source': 'Heretic War Staff (84.53-119.41)'},
        {'item': 2531, 'source': 'Godblade Great Axe (90.86-127.3)'},
    ],
    'unrelated': {
        'metric': 'combat_rating', 'fields': {'rating': 17}, 'aura': 10033, 'stacks': 1,
        'source': 'QA Test +100 Haste Rating (aura 189, misc 917504)',
    },
    'wait_ms': 1000,
}


def void_power_entry(**changes) -> dict:
    return {
        'spell': 574147, 'name': 'Void Power (healing power rises with main-hand weapon damage)',
        'kind': 'metric_delta', 'label_suffix': 'healing_weapon_arms',
        'quote': 'Your healing power is increased based on your main-hand weapon damage.',
        'trigger_spell': 60235, 'gate_spell': 574147, 'target': 'caster',
        'metric': 'healing_power', 'fields': {'school': 5}, 'tolerance': 0.5,
        'wait_ms': 1000, 'expire_ms': 500, 'void_on_cast_failure': True,
        'weapon_damage_arms': WEAPON_ARMS, **changes,
    }


@cache
def built_entry():
    return behaviour_scenario(load_class_file(25), void_power_entry())


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class WeaponDamageArmsTests(unittest.TestCase):
    def test_generates_valid_scenario_and_reads_weapon_damage_and_equal_ap(self):
        scenario, [exp] = built_entry()
        valid = run.validate(scenario)
        self.assertEqual(exp.displayed, 'direction')
        self.assertIsNone(exp.model['expected'])
        self.assertIsNone(exp.model['before_expected'])
        self.assertIn('Weapon damage arms (D-38)', valid['contract'])
        equips = [step['item'] for step in valid['steps'] if step['action'] == 'equip' and step['slot'] == 15]
        self.assertEqual(equips, [2531, 2534, 2535, 2531, 2534, 2534, 2535, 2531, 2534])
        added = {step['item'] for step in valid['steps'] if step['action'] == 'add_item'}
        self.assertTrue({2531, 2534, 2535} <= added)
        skills = {step['skill'] for step in valid['steps'] if step['action'] == 'set_skill'}
        self.assertTrue({172, 173, 136} <= skills)

    def judge(self, ctrl_out=(0.0, 0.0, 0.0, 0.0), lrn_out=(79.0, 190.0, 205.0, 79.0),
              ctrl_eq=(2534, 2535, 2531, 2534), lrn_eq=(2534, 2535, 2531, 2534),
              ctrl_dmg=(71.4, 173.2, 187.6, 71.4), lrn_dmg=(71.4, 173.2, 187.6, 71.4),
              ctrl_ap=(376.0, 376.0, 376.0, 376.0), lrn_ap=(376.0, 376.0, 376.0, 376.0),
              unrel=(0.0, 100.0, 0.0, 100.0), drop=None, cast_failures=None):
        _, [exp] = built_entry()
        rec = exp.model['weapon_damage_arms']
        found = {
            rec['before_label']: 0.0, rec['after_label']: 205.0,
            **{label: val for label, val in zip(rec['reads']['control'], ctrl_out[:3])},
            rec['reads']['control_unrelated']: ctrl_out[3],
            **{label: val for label, val in zip(rec['reads']['learned'], lrn_out[:3])},
            rec['reads']['learned_unrelated']: lrn_out[3],
            **{label: val for label, val in zip(rec['equipped']['control'], ctrl_eq[:3])},
            rec['equipped']['control_unrelated']: ctrl_eq[3],
            **{label: val for label, val in zip(rec['equipped']['learned'], lrn_eq[:3])},
            rec['equipped']['learned_unrelated']: lrn_eq[3],
            **{label: val for label, val in zip(rec['damage']['control'], ctrl_dmg[:3])},
            rec['damage']['control_unrelated']: ctrl_dmg[3],
            **{label: val for label, val in zip(rec['damage']['learned'], lrn_dmg[:3])},
            rec['damage']['learned_unrelated']: lrn_dmg[3],
            **{label: val for label, val in zip(rec['ap']['control'], ctrl_ap[:3])},
            rec['ap']['control_unrelated']: ctrl_ap[3],
            **{label: val for label, val in zip(rec['ap']['learned'], lrn_ap[:3])},
            rec['ap']['learned_unrelated']: lrn_ap[3],
            rec['unrelated']['control_base']: unrel[0], rec['unrelated']['control_active']: unrel[1],
            rec['unrelated']['learned_base']: unrel[2], rec['unrelated']['learned_active']: unrel[3],
        }
        if drop:
            found.pop(drop(rec))
        fake = FakeRun(found)
        fake.cast_failures = cast_failures or {}
        return judge_behaviour(base_verdict(exp), fake, exp)

    def test_seeded_ok_and_evidence_promise(self):
        from coverage import STATE, metric_evidence, promised_state
        verdict = self.judge()
        self.assertEqual(verdict.status, 'ok')
        self.assertIsNone(verdict.expected)
        self.assertEqual(verdict.detail['arm_gains'], [79.0, 190.0, 205.0])
        self.assertEqual(verdict.detail['attack_power'], 376.0)
        self.assertEqual(metric_evidence()['healing_power'], STATE)
        self.assertTrue(promised_state(verdict, void_power_entry()['quote']))

    def test_mutants_alert_on_flat_plateau_falling_or_unrelated_movement(self):
        self.assertEqual(self.judge(lrn_out=(100.0, 100.0, 100.0, 100.0)).status, 'alert')
        self.assertEqual(self.judge(lrn_out=(79.0, 190.0, 190.0, 79.0)).status, 'alert')
        self.assertEqual(self.judge(lrn_out=(79.0, 205.0, 190.0, 79.0)).status, 'alert')
        self.assertEqual(self.judge(lrn_out=(79.0, 190.0, 205.0, 95.0)).status, 'alert')

    def test_unmeasured_on_missing_reads_ap_confound_or_bad_fixtures(self):
        self.assertEqual(self.judge(drop=lambda r: r['ap']['learned'][1]).status, 'unmeasured')
        self.assertEqual(self.judge(drop=lambda r: r['reads']['learned'][2]).status, 'unmeasured')
        self.assertEqual(self.judge(lrn_ap=(376.0, 420.0, 376.0, 376.0)).status, 'unmeasured')
        self.assertEqual(self.judge(ctrl_ap=(376.0, 376.0, 376.0, 390.0)).status, 'unmeasured')
        self.assertEqual(self.judge(ctrl_dmg=(71.4, 71.4, 187.6, 71.4)).status, 'unmeasured')
        self.assertEqual(self.judge(lrn_dmg=(71.4, 180.0, 187.6, 71.4)).status, 'unmeasured')
        self.assertEqual(self.judge(ctrl_eq=(2534, 2534, 2531, 2534)).status, 'unmeasured')
        self.assertEqual(self.judge(unrel=(0.0, 0.0, 0.0, 0.0)).status, 'unmeasured')
        self.assertEqual(self.judge(ctrl_dmg=(71.4, 173.2, 187.6, 80.0)).status, 'unmeasured')
        self.assertEqual(self.judge(cast_failures={60235: [55]}).status, 'unmeasured')

    def test_refuses_expected_figures_too_few_weapons_or_undeclared_items(self):
        for bad_raw in (
                {**WEAPON_ARMS, 'weapons': WEAPON_ARMS['weapons'][:2]},
                {**WEAPON_ARMS, 'weapons': [WEAPON_ARMS['weapons'][0], WEAPON_ARMS['weapons'][0],
                                            WEAPON_ARMS['weapons'][1]]},
                {**WEAPON_ARMS, 'unrelated': {**WEAPON_ARMS['unrelated'], 'metric': 'attack_power', 'fields': {}}},
                {**WEAPON_ARMS, 'unrelated': {**WEAPON_ARMS['unrelated'], 'metric': 'weapon_damage_min', 'fields': {}}},
                {**WEAPON_ARMS, 'expected': 100},
                {**WEAPON_ARMS, 'slope': 1.0},
                {**WEAPON_ARMS, 'wait_ms': -1}):
            with self.subTest(bad_raw=bad_raw), self.assertRaises(ValueError):
                parse(bad_raw)

        for bad_entry in (
                void_power_entry(expected=200),
                void_power_entry(before_expected=0),
                void_power_entry(expected_gain=10),
                void_power_entry(expected_ratio=2.0),
                void_power_entry(after_at_least=10),
                void_power_entry(after_at_most=300),
                void_power_entry(phase_power=[0, 0, 100]),
                void_power_entry(cast_in_before=False),
                void_power_entry(metric='attack_power', fields={}),
                void_power_entry(metric='weapon_damage_min', fields={}),
                void_power_entry(metric='combat_rating', fields={'rating': 17}),
                void_power_entry(weapon_damage_arms={**WEAPON_ARMS, 'weapons': [
                    WEAPON_ARMS['weapons'][0], WEAPON_ARMS['weapons'][1], {'item': 999999, 'source': 'undeclared'}]})):
            with self.subTest(bad_entry=bad_entry), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(25), bad_entry)


if __name__ == '__main__':
    unittest.main()
