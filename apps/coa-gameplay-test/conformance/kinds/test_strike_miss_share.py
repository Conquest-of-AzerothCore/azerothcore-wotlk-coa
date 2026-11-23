import unittest

from behaviours import STRIKER, behaviour_scenario
from compare import judge_behaviour
from kinds.strike_miss_share import strike_miss_share_spec
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

QUOTE = ('You cannot attack or cast spells, but chance to be hit by ranged attacks and spells is reduced by '
         '$806295s1% for the duration.')
ENTRY = {
    'spell': 500947, 'kind': 'strike_miss_share', 'variant': 'miss', 'label_suffix': 'miss', 'name': 'Slither',
    'quote': QUOTE, 'trigger_spell': 500947, 'trigger_aura': 806295, 'strike_spell': 41394, 'strikes': 4,
    'strike_wait_ms': 300, 'trigger_wait_ms': 200, 'burst_ms': 5400, 'control_bursts': 2, 'treatment_bursts': 3,
    'control_minimum_share': 0.5, 'refused': {'spell': 573026, 'result': 104, 'attack_ms': 3000}}


def scenario_of(entry: dict = ENTRY):
    return behaviour_scenario(load_class_file(13), entry)


def burst_values(model: dict, arm: str, sent: list[int], landed: list[int], aura: list[float]) -> dict:
    values = {}
    for burst, go, logs, held in zip(model['bursts'][arm], sent, landed, aura):
        values.update({burst['before']['go']: 10.0, burst['after']['go']: 10.0 + go,
                       burst['before']['logs']: 5.0, burst['after']['logs']: 5.0 + logs, burst['aura']: held})
    return values


def refused_values(model: dict, arm: str, go: int, failure: int, swings: int, aura: float) -> dict:
    reads = model['arms'][arm]
    return {reads['go'][0]: 1.0, reads['go'][1]: 1.0 + go, reads['failure']: float(failure),
            reads['swings'][0]: 2.0, reads['swings'][1]: 2.0 + swings, reads['aura']: aura}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class StrikeMissShareTests(unittest.TestCase):
    def judged(self, expectation, values):
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def share(self, treatment_landed, control_landed=(4, 3), sent=4, aura=(1.0, 1.0, 1.0)):
        _, expectations = scenario_of()
        share = expectations[0]
        values = {**burst_values(share.model, 'control', [4, 4], list(control_landed), [0.0, 0.0]),
                  **burst_values(share.model, 'treatment', [sent] * 3, list(treatment_landed), list(aura))}
        return self.judged(share, values)

    def test_the_treatment_bursts_follow_a_real_trigger_cast_and_the_striker_has_no_hit_bonus(self):
        scenario, expectations = scenario_of()
        steps = run.validate(scenario)['steps']
        striker = next(creature for creature in scenario['creatures'] if creature['id'] == STRIKER)
        self.assertNotIn('spell_hit_bonus', striker)
        self.assertEqual(striker['reaction'], 0)
        triggers = [step for step in steps if step['action'] == 'cast' and step['spell'] == 500947]
        self.assertEqual(len(triggers), 1 + 3)
        strikes = [step for step in steps if step['action'] == 'cast' and step['actor'] == STRIKER]
        self.assertEqual(len(strikes), 4 * (2 + 3))
        self.assertEqual([expectation.label for expectation in expectations],
                         ['500947 behaviour_metric_delta miss', '500947 behaviour_metric_delta miss_cast',
                          '500947 behaviour_metric_delta miss_attack'])
        self.assertEqual([expectation.model['metric'] for expectation in expectations],
                         ['spell_log_count', 'cast_failure', 'melee_attack_count'])

    def test_no_landed_strike_passes_and_one_landed_strike_alerts(self):
        self.assertEqual(self.share([0, 0, 0]).status, 'ok')
        self.assertEqual(self.share([0, 1, 0]).status, 'alert')

    def test_a_weak_control_a_short_burst_or_a_lapsed_aura_is_unmeasured(self):
        self.assertEqual(self.share([0, 0, 0], control_landed=(1, 0)).status, 'unmeasured')
        self.assertEqual(self.share([0, 0, 0], sent=3).status, 'unmeasured')
        self.assertEqual(self.share([0, 0, 0], aura=(1.0, 0.0, 1.0)).status, 'unmeasured')

    def test_the_refused_cast_and_attack_are_judged_against_the_control(self):
        _, [_, cast, attack] = scenario_of()
        allowed = refused_values(cast.model, 'control', 1, 0, 2, 0.0)
        self.assertEqual(self.judged(cast, {**allowed, **refused_values(cast.model, 'treatment', 0, 104, 0, 1.0)})
                         .status, 'ok')
        self.assertEqual(self.judged(cast, {**allowed, **refused_values(cast.model, 'treatment', 1, 0, 0, 1.0)})
                         .status, 'alert')
        self.assertEqual(self.judged(attack, {**allowed, **refused_values(cast.model, 'treatment', 0, 104, 0, 1.0)})
                         .status, 'ok')
        self.assertEqual(self.judged(attack, {**allowed, **refused_values(cast.model, 'treatment', 0, 104, 1, 1.0)})
                         .status, 'alert')
        blocked = refused_values(cast.model, 'control', 0, 104, 0, 0.0)
        self.assertEqual(self.judged(cast, {**blocked, **refused_values(cast.model, 'treatment', 0, 104, 0, 1.0)})
                         .status, 'unmeasured')

    def test_strikes_that_outlast_the_burst_are_refused(self):
        with self.assertRaises(ValueError):
            strike_miss_share_spec({**ENTRY, 'strikes': 20})
        self.assertEqual(strike_miss_share_spec({k: v for k, v in ENTRY.items() if k != 'refused'}).refused, None)


if __name__ == '__main__':
    unittest.main()
