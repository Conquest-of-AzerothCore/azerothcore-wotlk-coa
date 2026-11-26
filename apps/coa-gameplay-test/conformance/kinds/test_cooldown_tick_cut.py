import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from coverage import metric_evidence
from kinds.cooldown_tick_cut import TICK_CUT_METRIC, interval_bracket, period_bracket
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 300361, 'name': 'Day Cycles (Horusath Blast cut in Sunrise)', 'kind': 'cooldown_tick_cut',
         'label_suffix': 'tick_cut_sunrise',
         'quote': 'While in Sunrise, the remaining cooldown of Horusath Blast is reduced by $301176s2% every $t1 sec.',
         'cooled_spell': 500154, 'phase_aura': 500477, 'expected_pct': 10}


def remaining_after(first: float, cut_pct: float, offset_ms: float, elapsed_ms: float = 1000.0) -> float:
    return (1.0 - cut_pct / 100.0) * (first - offset_ms) - (elapsed_ms - offset_ms)


def series(cut_pct: float, phase_ms: float, reads: int = 61, step_ms: float = 100.0, period_ms: float = 1000.0,
           start: float = 24800.0) -> list[tuple[float, float]]:
    rows, remaining, now = [], start, 0.0
    next_tick = phase_ms
    for index in range(reads):
        rows.append((5000.0 + now, remaining))
        end = now + step_ms
        while next_tick <= end:
            remaining -= next_tick - now
            now = next_tick
            remaining *= 1.0 - cut_pct / 100.0
            next_tick += period_ms
        remaining -= end - now
        now = end
    return rows


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownTickCutTests(unittest.TestCase):
    def judged(self, cut_pct: float, offset_ms: float = 400.0, step_ms: float = 100.0, period_ms: float = 1000.0,
               entry: dict = ENTRY, rows: list[tuple[float, float]] | None = None) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        model = expectation.model
        values = {}
        for (time_label, cooldown_label), (time, remaining) in zip(
                model['reads'], rows or series(cut_pct, offset_ms, len(model['reads']), step_ms, period_ms)):
            values[time_label], values[cooldown_label] = time, remaining
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_cooled_spell_is_cast_in_the_phase_and_read_inside_each_amplitude(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        steps = scenario['steps']
        phase = next(index for index, step in enumerate(steps) if step['action'] == 'set_aura'
                     and step['spell'] == 500477)
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 500154)
        self.assertLess(phase, cast)
        self.assertEqual(steps[cast]['target'], 'dummy')
        reads = [step for step in steps if step['action'] == 'assert' and step['metric'] == 'cooldown_ms']
        self.assertEqual(len(reads), 61)
        self.assertEqual({step['ms'] for step in steps if str(step.get('label', '')).startswith('read interval')},
                         {100})
        self.assertEqual(expectation.model['amplitude_ms'], 1000)
        self.assertEqual(expectation.label, '300361 behaviour_metric_delta tick_cut_sunrise')

    def test_a_ten_percent_cut_is_ok_wherever_the_tick_falls(self):
        for offset in (1.0, 125.0, 400.0, 999.0, 1000.0):
            with self.subTest(offset=offset):
                self.assertEqual(self.judged(10.0, offset).status, 'ok')

    def test_a_server_that_cuts_nothing_alerts(self):
        verdict = self.judged(0.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('against 10', verdict.explanation)

    def test_a_cut_twice_as_large_alerts(self):
        self.assertEqual(self.judged(20.0).status, 'alert')

    def test_the_control_phase_expects_no_cut(self):
        control = {**ENTRY, 'label_suffix': 'tick_cut_sunrise_control', 'phase_aura': 500511, 'expected_pct': 0}
        self.assertEqual(self.judged(0.0, entry=control).status, 'ok')
        self.assertEqual(self.judged(10.0, entry=control).status, 'alert')

    def test_an_interval_as_long_as_the_amplitude_is_unmeasured(self):
        self.assertEqual(self.judged(10.0, step_ms=1000.0).status, 'unmeasured')

    def test_a_tick_every_two_seconds_alerts_on_its_count(self):
        verdict = self.judged(10.0, period_ms=2000.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('allowed 6 to 6', verdict.explanation)

    def test_a_period_ten_percent_short_alerts_wherever_the_tick_falls(self):
        for offset in (1.0, 50.0, 400.0, 899.0):
            with self.subTest(offset=offset):
                verdict = self.judged(10.0, offset, period_ms=900.0)
                self.assertEqual(verdict.status, 'alert')
                self.assertIn('against 950 to 1050', verdict.explanation)

    def test_a_period_ten_percent_long_alerts_wherever_the_tick_falls(self):
        for offset in (1.0, 50.0, 400.0, 1099.0):
            with self.subTest(offset=offset):
                verdict = self.judged(10.0, offset, period_ms=1100.0)
                self.assertEqual(verdict.status, 'alert')
                self.assertIn('against 950 to 1050', verdict.explanation)

    def test_unevenly_spaced_ticks_alert(self):
        early, late = series(10.0, 400.0, reads=30), series(10.0, 700.0, reads=31, start=14000.0)
        offset = early[-1][0] + 100.0 - late[0][0]
        verdict = self.judged(10.0, rows=early + [(time + offset, remaining) for time, remaining in late])
        self.assertEqual(verdict.status, 'alert')

    def test_the_period_bracket_holds_the_true_period(self):
        ticks = [(5000.0 + 1000.0 * index + 350.0, 5000.0 + 1000.0 * index + 450.0) for index in range(6)]
        low, high = period_bracket(ticks)
        self.assertLessEqual(low, 1000.0)
        self.assertGreaterEqual(high, 1000.0)
        self.assertLess(high - low, 50.0)

    def test_slow_reads_still_find_every_tick(self):
        self.assertEqual(self.judged(10.0, step_ms=150.0, entry={**ENTRY, 'reads': 55, 'read_step_ms': 150}).status,
                         'ok')

    def test_the_bracket_holds_the_true_cut(self):
        for offset in (0.0, 250.0, 1000.0):
            low, high = interval_bracket(24800.0, remaining_after(24800.0, 10.0, offset), 1000.0)
            self.assertLessEqual(low, 10.0 + 1e-9)
            self.assertGreaterEqual(high, 10.0 - 1e-9)

    def test_the_derived_metric_is_an_event(self):
        self.assertEqual(metric_evidence()[TICK_CUT_METRIC], 'event')

    def test_reads_and_cut_are_bounded(self):
        for changes in ({'reads': 2}, {'reads': 81}, {'expected_pct': 100}, {'amplitude_effect': 1},
                        {'read_step_ms': 50}, {'read_step_ms': 1000}, {'reads': 5}, {'reads': 13, 'read_step_ms': 250},
                        {'reads': 40}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})


if __name__ == '__main__':
    unittest.main()
