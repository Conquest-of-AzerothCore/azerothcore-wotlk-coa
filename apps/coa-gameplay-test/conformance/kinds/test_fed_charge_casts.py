import math
import unittest
from unittest import mock

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import BEHAVIOUR, UNPROVEN, verdict_evidence
from kinds import fed_charge_casts
from kinds.fed_charge_casts import INSIDE, OUTSIDE, STRADDLE, placed
from profile import DBC_DIR, load_fixture_class_file
from test_behaviours import FakeRun, base_verdict

FELFORGED = {'spell': 300490, 'name': 'Felforged (earned charges)', 'kind': 'fed_charge_casts',
             'label_suffix': 'felforged_fed', 'quote': 'Your next 3 Fel Fireballs have a $s1% reduced cast time',
             'quote_spell': 806104, 'feed_spell': 704368, 'aura': 806104, 'effect_spell': 801312, 'charges': 3,
             'every_ms': 3200, 'residual_target': 0.001, 'feed_power': 100, 'effect_power': 100, 'trials': 3,
             'min_judged': 2, 'poll_ms': 15}
STEP_MS = 3
READ_MS = 6
REDUCED = (1050, 1050, 1050, 1500)


FIRST_POLL_MS = {'cut': 955, 'full': 1300}
POLL_MS = 15


def timed_cast(values: dict, cast: dict, clock: float, count: float, cast_ms: float, aura: float) -> tuple:
    start, sent = clock, clock + STEP_MS
    values.update({cast['aura']: aura, cast['prior']: count, cast['start']: start, cast['sent']: sent})
    done = start + cast_ms
    for poll, names in enumerate(cast['polls']):
        before = sent + FIRST_POLL_MS[cast['band']] + poll * POLL_MS
        values.update({names['before']: before, names['count']: count + (1 if done <= before + STEP_MS else 0),
                       names['after']: before + READ_MS})
    return start + 2000, count + 1


def run_values(expectation, casts=REDUCED, control=1500, amount=-30.0, broken=None, fed_lag=0) -> dict:
    values, clock, count, grants = {}, 0.0, 0.0, 0.0
    for index, trial in enumerate(expectation.model['reads']):
        values.update({trial['haste control']: 1.0, trial['haste fed']: 1.0, trial['known start']: 1.0,
                       trial['grants start']: grants, trial['aura stop']: 1.0, trial['known stop']: 0.0,
                       trial['grants stop']: grants + 1, trial['amount']: amount, trial['used']: 0.0,
                       trial['grants end']: grants + 1})
        grants += 1
        clock, count = timed_cast(values, trial['control'], clock, count, control, 0.0)
        values[trial['fed at']] = clock - fed_lag
        for number, (cast, cast_ms) in enumerate(zip(trial['casts'], casts)):
            clock, count = timed_cast(values, cast, clock, count, cast_ms, 1.0 if number < 3 else 0.0)
        values[trial['went']] = count
        if broken and broken[0] == index:
            values[trial[broken[1]]] = broken[2]
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FedChargeCastsTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), {**FELFORGED, **changes})

    def judged(self, **kwargs):
        _, expectations = self.built()
        return {expectation.label.rsplit(' ', 1)[1]: judge_behaviour(
            base_verdict(expectation), FakeRun(run_values(expectation, **kwargs)), expectation)
            for expectation in expectations}

    def statuses(self, **kwargs):
        return {name: verdict.status for name, verdict in self.judged(**kwargs).items()}

    def test_the_aura_is_fed_for_real_and_the_talent_unlearned_at_the_stop(self):
        scenario, [charges, cut] = self.built()
        steps = scenario['steps']
        self.assertFalse([step for step in steps if step['action'] == 'set_aura' and step.get('spell') == 806104])
        stops = [index for index, step in enumerate(steps) if step['action'] == 'cast_until_aura']
        self.assertEqual(len(stops), 3)
        for stop in stops:
            self.assertEqual(steps[stop]['spell'], 704368)
            self.assertEqual(steps[stop]['max_casts'], 54)
            self.assertEqual(steps[stop + 1]['metric'], 'game_time_ms')
            self.assertEqual(steps[stop + 2], {'action': 'unlearn', 'actor': 'caster', 'spell': 300490})
            self.assertEqual((steps[stop + 3]['metric'], steps[stop + 3]['spell']), ('aura', 806104))
        casts = [step for step in steps if step['action'] == 'cast' and step['spell'] == 801312]
        self.assertEqual(len(casts), 15)
        self.assertTrue(all(step['ignore_gcd'] for step in casts))
        self.assertEqual(charges.model['bands'], {'cut': (1005.0, 1095.0), 'full': (1350.0, 1650.0)})
        self.assertEqual((charges.model['cast_ms'], cut.model['amount'], cut.model['expected']), (1500, -30.0, 30.0))
        hastes = [step for step in steps if step.get('metric') == 'cast_speed_multiplier']
        self.assertEqual(len(hastes), 6)

    def test_three_cut_casts_and_a_full_fourth_pass_both_labels(self):
        verdicts = self.judged()
        for name, verdict in verdicts.items():
            self.assertEqual(verdict.status, 'ok', f'{name}: {verdict.explanation}')

    def test_mutants_alert(self):
        self.assertEqual(self.statuses(casts=(1050,) * 4), {'charges': 'alert', 'cut': 'ok'})
        self.assertEqual(self.statuses(casts=(1050, 1050, 1500, 1500)), {'charges': 'alert', 'cut': 'alert'})
        self.assertEqual(self.statuses(casts=(1500,) * 4), {'charges': 'alert', 'cut': 'alert'})
        self.assertEqual(self.statuses(casts=(990, 990, 990, 1500)), {'charges': 'alert', 'cut': 'alert'})
        self.assertEqual(self.statuses(amount=-31.0), {'charges': 'ok', 'cut': 'alert'})

    def test_placement_is_inside_outside_or_straddling(self):
        band = (1005.0, 1095.0)
        self.assertEqual(placed((1040.0, 1070.0), band), INSIDE)
        self.assertEqual(placed((1005.0, 1095.0), band), INSIDE)
        self.assertEqual(placed((900.0, 1000.0), band), OUTSIDE)
        self.assertEqual(placed((1100.0, math.inf), band), OUTSIDE)
        self.assertEqual(placed((1080.0, 1110.0), band), STRADDLE)
        self.assertEqual(placed((0.0, 1010.0), band), STRADDLE)

    def test_a_straddling_bracket_is_unmeasured_not_ok(self):
        self.assertEqual(self.statuses(casts=(1090, 1050, 1050, 1500)), {'charges': 'unmeasured',
                                                                         'cut': 'unmeasured'})

    def test_void_conditions_leave_the_trial_unjudged(self):
        for broken in (('aura stop', 0.0), ('known stop', 1.0), ('grants end', 9.0), ('grants stop', 9.0),
                       ('haste fed', 1.05), ('haste control', 0.9), ('known start', 0.0), ('went', 0.0),
                       ('fed at', -10000.0)):
            with self.subTest(broken=broken[0]):
                verdicts = self.judged(broken=(1, *broken))
                self.assertEqual(verdicts['charges'].status, 'ok', verdicts['charges'].explanation)
                self.assertIn('trial 1:', verdicts['charges'].explanation.split('void:')[1])
        self.assertEqual(self.statuses(control=1050), {'charges': 'unmeasured', 'cut': 'unmeasured'})

    def test_a_last_cast_at_the_natural_expiry_is_void_not_proof_of_the_charge_count(self):
        _, [charges, _] = self.built()
        self.assertEqual(charges.model['duration'], 8000)
        self.assertEqual(self.statuses(fed_lag=1199), {'charges': 'ok', 'cut': 'ok'})
        late = self.judged(fed_lag=1200)
        self.assertEqual({name: verdict.status for name, verdict in late.items()},
                         {'charges': 'unmeasured', 'cut': 'unmeasured'})
        self.assertIn('last cast past 0.9 of the aura', late['charges'].explanation)

    def test_mutant_without_the_expiry_void_counts_a_full_cast_after_expiry(self):
        with mock.patch.object(fed_charge_casts, 'before_expiry', lambda *args: True):
            self.assertEqual(self.statuses(fed_lag=1200), {'charges': 'ok', 'cut': 'ok'})

    def test_too_few_judged_trials_is_unmeasured_but_an_outside_cast_still_alerts(self):
        _, [charges, _] = self.built()
        values = run_values(charges)
        for trial in charges.model['reads'][1:]:
            values[trial['aura stop']] = 0.0
        self.assertEqual(judge_behaviour(base_verdict(charges), FakeRun(values), charges).status, 'unmeasured')
        values = run_values(charges, casts=(1050,) * 4)
        for trial in charges.model['reads'][1:]:
            values[trial['aura stop']] = 0.0
        self.assertEqual(judge_behaviour(base_verdict(charges), FakeRun(values), charges).status, 'alert')

    def test_the_verdicts_are_behaviour_on_their_claims(self):
        verdicts = self.judged()
        self.assertEqual(verdicts['charges'].detail, {'metric': 'spell_cast_count'})
        self.assertEqual(verdict_evidence(verdicts['charges'], 'Your next 3 Fel Fireballs', {}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdicts['cut'], 'have a $s1% reduced cast time', {}), BEHAVIOUR)
        failed = self.judged(casts=(1500,) * 4)['cut']
        self.assertEqual(verdict_evidence(failed, 'have a $s1% reduced cast time', {}), UNPROVEN)

    def test_an_entry_off_the_tooltip_or_the_aura_effect_is_refused(self):
        for changes in ({'charges': 4}, {'quote_spell': 801312}, {'cut_effect': 1}, {'poll_ms': 0},
                        {'poll_ms': 101}, {'min_judged': 4}, {'residual_target': 1.0}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
