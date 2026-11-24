import unittest

from behaviours import STRIKER, behaviour_scenario
from kinds.debuff_resist_rate import (CASTER_HEALTH, boosted, debuff_resist_rate_spec, debuff_resist_rate_verdict,
                                      read_label)
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

QUOTE = 'While at full health, your chance to resist the next Curse or Magic effect on you is increased by 100%.'
RATE_ENTRY = {
    'spell': 804613, 'kind': 'debuff_resist_rate', 'variant': 'curse', 'label_suffix': 'resist_curse',
    'name': 'Doomstride', 'quote': QUOTE, 'strike_spell': 702, 'base_chance_pct': 4, 'clear_auras': [706818],
    'low_health_pct': 90, 'parts': 10}
LOCKOUT_ENTRY = {
    'spell': 804613, 'kind': 'debuff_resist_rate', 'variant': 'lockout', 'label_suffix': 'resist_lockout',
    'name': 'Doomstride', 'quote': 'Can only occur once every 10 sec.', 'mode': 'lockout', 'strike_spell': 702,
    'base_chance_pct': 34, 'striker_level': 54, 'clear_auras': [706818], 'lockout_aura': 706818,
    'lockout_ms': 10000, 'locked_gap_ms': 300, 'locked_trials': 388, 'expiry_trials': 12,
    'expiry_margin_ms': 500, 'parts': 4}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(14), entry)


def applied_reads(prefix: str, arm: str, trials: int, resisted: int) -> dict:
    return {read_label(prefix, arm, trial, 'applied'): 0.0 if trial <= resisted else 1.0
            for trial in range(1, trials + 1)}


def rate_runs(model: dict, rates: dict) -> list[FakeRun]:
    runs = []
    for _ in range(10):
        values = {}
        for arm, rate in rates.items():
            trials = model['trials'][arm]
            values.update(applied_reads(model['prefix'], arm, trials, round(rate * trials)))
        runs.append(FakeRun(values))
    return runs


def locked_runs(model: dict, primed_rate: float, unprimed_rate: float, parts: int = 4) -> list[FakeRun]:
    runs = []
    trials = model['trials']['locked']
    primed = round(trials * 0.2244)
    for _ in range(parts):
        values = {}
        for trial in range(1, trials + 1):
            is_primed = trial <= primed
            index = trial if is_primed else trial - primed
            rate, count = (primed_rate, primed) if is_primed else (unprimed_rate, trials - primed)
            values[read_label(model['prefix'], 'locked', trial, 'primed')] = 1.0 if is_primed else 0.0
            values[read_label(model['prefix'], 'locked', trial, 'applied')] = (
                0.0 if index <= round(rate * count) else 1.0)
        runs.append(FakeRun(values))
    return runs


def expiry_runs(model: dict, held: float, ended: float) -> list[FakeRun]:
    values = {}
    for trial in range(1, model['trials']['expiry'] + 1):
        primed = trial % 3 == 0
        values[read_label(model['prefix'], 'expiry', trial, 'primed')] = 1.0 if primed else 0.0
        values[read_label(model['prefix'], 'expiry', trial, 'held')] = held if primed else 0.0
        values[read_label(model['prefix'], 'expiry', trial, 'ended')] = ended if primed else 0.0
    return [FakeRun(values)]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class DebuffResistRateTests(unittest.TestCase):
    def rate(self, rates: dict, low_health: bool = False):
        _, expectations = scenario_of(RATE_ENTRY)
        expectation = expectations[1 if low_health else 0]
        model = expectation.model
        return debuff_resist_rate_verdict(base_verdict(expectation), rate_runs(model, rates), model)

    def test_the_control_strikes_before_the_real_learn_and_the_striker_has_no_hit_bonus(self):
        scenario, expectations = scenario_of(RATE_ENTRY)
        steps = run.validate(scenario)['steps']
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == STRIKER)
        self.assertNotIn('spell_hit_bonus', striker)
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step.get('spell') == 804613)
        trials = expectations[0].model['trials']
        strikes = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['actor'] == STRIKER]
        self.assertEqual(len(strikes), sum(trials.values()))
        self.assertEqual(sum(index < learn for index in strikes), trials['control'])
        self.assertFalse(any(step['action'] == 'set_aura' and step.get('spell') == 804613 for step in steps))
        healths = {step['value'] for step in steps if step['action'] == 'set_health' and step['actor'] == CASTER}
        self.assertEqual(healths, {CASTER_HEALTH, CASTER_HEALTH * 90 // 100})
        self.assertEqual([expectation.label for expectation in expectations],
                         ['804613 behaviour_metric_delta resist_curse',
                          '804613 behaviour_metric_delta resist_curse_low_health'])
        self.assertEqual({expectation.model['metric'] for expectation in expectations}, {'aura'})

    def test_the_trials_are_sized_for_the_stated_residual(self):
        _, expectations = scenario_of(RATE_ENTRY)
        model = expectations[0].model
        self.assertEqual(model['minimum'], {'control': 3310, 'treatment': 6220, 'low_health': 3310})

    def test_the_second_stock_roll_passes_and_the_mutants_alert(self):
        conformant = {'control': 0.04, 'treatment': boosted(0.04), 'low_health': 0.04}
        self.assertEqual(self.rate(conformant).status, 'ok')
        self.assertEqual(self.rate({**conformant, 'treatment': 0.04}).status, 'alert')
        self.assertEqual(self.rate({**conformant, 'treatment': 1.0}).status, 'alert')
        self.assertEqual(self.rate({**conformant, 'control': 0.0}).status, 'alert')

    def test_the_low_health_arm_resists_at_the_stock_chance(self):
        conformant = {'control': 0.04, 'treatment': boosted(0.04), 'low_health': 0.04}
        self.assertEqual(self.rate(conformant, low_health=True).status, 'ok')
        self.assertEqual(self.rate({**conformant, 'low_health': boosted(0.04)}, low_health=True).status, 'alert')

    def test_a_missing_read_is_unmeasured(self):
        _, expectations = scenario_of(RATE_ENTRY)
        expectation = expectations[0]
        verdict = debuff_resist_rate_verdict(base_verdict(expectation), [FakeRun({})], expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_the_lockout_blocks_the_second_roll_on_primed_trials(self):
        scenario, expectations = scenario_of(LOCKOUT_ENTRY)
        run.validate(scenario)
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == STRIKER)
        self.assertEqual(striker['level'], 54)
        locked = expectations[0]
        model = locked.model

        def status(primed, unprimed):
            return debuff_resist_rate_verdict(base_verdict(locked), locked_runs(model, primed, unprimed),
                                              model).status
        self.assertEqual(status(0.34, boosted(0.34)), 'ok')
        self.assertEqual(status(boosted(0.34), boosted(0.34)), 'alert')
        self.assertEqual(status(0.34, 0.34), 'alert')

    def test_the_lockout_aura_holds_inside_and_ends_after(self):
        _, expectations = scenario_of(LOCKOUT_ENTRY)
        expiry = expectations[1]
        model = expiry.model
        self.assertEqual(expiry.label, '804613 behaviour_metric_delta resist_lockout_expiry')
        for held, ended, expected in ((1.0, 0.0, 'ok'), (0.0, 0.0, 'alert'), (1.0, 1.0, 'alert')):
            verdict = debuff_resist_rate_verdict(base_verdict(expiry), expiry_runs(model, held, ended), model)
            self.assertEqual(verdict.status, expected)

    def test_an_incomplete_entry_is_refused(self):
        with self.assertRaises(ValueError):
            debuff_resist_rate_spec({**RATE_ENTRY, 'low_health_pct': 100})
        with self.assertRaises(ValueError):
            debuff_resist_rate_spec({**LOCKOUT_ENTRY, 'expiry_margin_ms': 10000})
        with self.assertRaises(ValueError):
            debuff_resist_rate_spec({**RATE_ENTRY, 'mode': 'other'})


if __name__ == '__main__':
    unittest.main()
