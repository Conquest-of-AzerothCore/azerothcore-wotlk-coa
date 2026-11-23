import math
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.cooldown_cut_series import METRIC
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

GLAIVE = 562719
AVATAR = 705943
BLESSING = 706577
CLASS_FILE = {'class_id': 13, 'name': 'Witch Doctor', 'race': 1, 'level': 60, 'skill_lines': [],
              'reference_stats': {}}
ENTRY = {'spell': BLESSING, 'kind': 'cooldown_cut_series', 'name': "Vol'jin's Blessing (series)",
         'label_suffix': 'glaive_cut',
         'quote': 'the cooldown of Spirit Glaive is now reduced by $706803s1% every 1 sec.',
         'learn': [AVATAR], 'gated_spell': GLAIVE,
         'casts': [{'spell': GLAIVE, 'target': 'dummy', 'wait_ms': 2700},
                   {'spell': AVATAR, 'target': 'caster', 'wait_ms': 200}],
         'series': {'reads': 110, 'step_ms': 50}, 'expected_pct': 20, 'pct_source': [706803, 0],
         'expected_period_ms': 1000, 'clear_auras': [AVATAR], 'min_ticks': 4, 'cast_power': 1400,
         'dummy_distance': 15}


def series_values(reads: list, share: float, period: float, first_tick: float = 1000.0,
                  start: float = 19100.0, step: float = 50.0) -> dict:
    values, remaining, now, tick = {}, start, 0.0, first_tick
    for cooldown_label, time_label in reads:
        values[cooldown_label] = float(max(0, round(remaining)))
        values[time_label] = 50000.0 + now
        target = now + step
        while share and tick <= target:
            remaining -= tick - now
            now = tick
            remaining -= math.floor(remaining * share / 100)
            tick += period
        remaining -= target - now
        now = target
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownCutSeriesTests(unittest.TestCase):
    def judged(self, share=20.0, period=1000.0, control_share=0.0, entry=ENTRY, drop=None):
        _, expectations = behaviour_scenario(CLASS_FILE, entry)
        verdicts = []
        for expectation in expectations:
            arms = expectation.model['arms']
            values = {**series_values(arms['control'], control_share, period),
                      **series_values(arms['treatment'], share, period)}
            if drop is not None:
                values.pop(arms['treatment'][drop][0])
            verdicts.append(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation))
        return verdicts

    def test_the_arms_cast_for_real_and_the_talent_is_learned_between_them(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, ENTRY)
        run.validate(scenario)
        actions = [(step['action'], step.get('spell')) for step in scenario['steps']]
        learn = actions.index(('learn', BLESSING))
        avatars = [index for index, action in enumerate(actions) if action == ('cast', AVATAR)]
        glaives = [index for index, action in enumerate(actions) if action == ('cast', GLAIVE)]
        cancels = [index for index, action in enumerate(actions) if action == ('cancel_aura', AVATAR)]
        self.assertEqual(len(avatars), 2)
        self.assertTrue(glaives[0] < avatars[0] < cancels[0] < learn < glaives[1] < avatars[1] < cancels[1])
        reads = [step for step in scenario['steps'] if step.get('metric') == 'cooldown_ms']
        self.assertEqual(len(reads), 2 * ENTRY['series']['reads'])
        self.assertEqual({step['spell'] for step in reads}, {GLAIVE})
        self.assertEqual([expectation.label for expectation in expectations],
                         [f'{BLESSING} behaviour_metric_delta glaive_cut',
                          f'{BLESSING} behaviour_metric_delta glaive_cut_period'])
        self.assertEqual({expectation.model['metric'] for expectation in expectations}, {METRIC})

    def test_a_fifth_a_second_passes_both_judges(self):
        amount, period = self.judged()
        self.assertEqual((amount.status, period.status), ('ok', 'ok'), (amount.explanation, period.explanation))
        self.assertAlmostEqual(amount.measured, 20.0, delta=0.5)
        self.assertAlmostEqual(period.measured, 1000.0, delta=15.0)

    def test_a_quarter_a_tick_alerts_the_amount(self):
        amount, _ = self.judged(share=25.0)
        self.assertEqual(amount.status, 'alert')

    def test_a_slower_tick_alerts_the_period(self):
        _, period = self.judged(period=1200.0)
        self.assertEqual(period.status, 'alert')

    def test_no_cut_alerts(self):
        amount, period = self.judged(share=0.0)
        self.assertEqual((amount.status, period.status), ('alert', 'alert'))

    def test_a_cut_without_the_talent_alerts(self):
        amount, _ = self.judged(control_share=20.0)
        self.assertEqual(amount.status, 'alert')

    def test_a_missing_read_is_unmeasured(self):
        amount, _ = self.judged(drop=10)
        self.assertEqual(amount.status, 'unmeasured')

    def test_bad_entries_are_refused(self):
        for change in ({'learn': [AVATAR, BLESSING]}, {'gated_spell': 806289},
                       {'series': {'reads': 110, 'step_ms': 600}}, {'series': {'reads': 20, 'step_ms': 50}},
                       {'expected_pct': 25}, {'casts': [{'spell': GLAIVE, 'target': 'ally', 'wait_ms': 0}]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, {**ENTRY, **change})
