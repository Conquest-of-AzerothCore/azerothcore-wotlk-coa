from dataclasses import replace
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from compare import VERDICTS_FILE, Verdict, delta_margin, read_verdicts, write_verdicts
from conformance import DIFF_EXIT, main
from diff import ADDED, IMPACT_FILE, REMOVED, diff
from procs import PROC_CHECK
from stack import MEASURED, STACK_DPS, STACK_SOURCE

ARGENT_BLADE = 807268
RETRIBUTION_STRIKE = 525028
SCARLET_HAMMER = 807035
HIT = 'hit_mean'
CLASS = {'class_id': 19, 'class_name': 'Templar', 'level': 60}


def hit(label, spell, measured, half, expected=543.2, status='ok'):
    return Verdict(label, status, measured, expected, expected - half, expected + half, '', 's', spell, spell,
                   HIT)


def passes(label, check, spell, mean, half, status=MEASURED):
    return Verdict(label, status, mean, None, mean - half, mean + half, '', 's', spell, spell, check)


def proc(label, rate, low, high, status='ok'):
    return Verdict(label, status, rate, 0.1, low, high, '', 's', 92111, 92111, PROC_CHECK)


def value(label, spell, measured, expected, status='ok'):
    margin = max(1.0, 0.005 * abs(expected))
    return Verdict(label, status, measured, expected, expected - margin, expected + margin, '', 's', spell,
                   spell, 'effect_value')


def cooldown(label, spell, measured, expected, window):
    return Verdict(label, 'ok', measured, expected, expected - window, expected, '', 's', spell, spell,
                   'cooldown_ms')


def passive(label, measured, expected, metric):
    margin = delta_margin(metric, expected)
    return Verdict(label, 'ok', measured, expected, expected - margin, expected + margin, '', 's', 561346, 561346,
                   'passive_delta', {'metric': metric})


def only(changes):
    assert len(changes) == 1, changes
    return changes[0]


class DiffTests(unittest.TestCase):
    def test_identical_verdicts_have_no_change(self):
        verdicts = [hit('a hit_mean', ARGENT_BLADE, 543.0, 3.0), value('b', 1, 50.0, 50.0)]
        self.assertEqual(diff(verdicts, list(verdicts), set()), [])

    def test_move_inside_both_intervals_is_not_significant(self):
        change = only(diff([hit('a', ARGENT_BLADE, 543.0, 3.2)], [hit('a', ARGENT_BLADE, 545.0, 3.2)],
                           {ARGENT_BLADE}))
        self.assertFalse(change.significant)
        self.assertFalse(change.listed)
        self.assertEqual((change.before, change.after), (543.0, 545.0))
        self.assertAlmostEqual(change.delta_pct, 2 / 543 * 100)

    def test_hit_means_without_spread_use_the_deterministic_tolerance(self):
        change = only(diff([hit('a', 807805, 400.0, 0.0, expected=400.0)],
                           [hit('a', 807805, 402.0, 0.0, expected=402.0)], set()))
        self.assertFalse(change.significant)
        self.assertIn('no width', change.rule)
        moved = only(diff([hit('a', 807805, 400.0, 0.0, expected=400.0)],
                          [hit('a', 807805, 410.0, 0.0, expected=410.0)], set()))
        self.assertTrue(moved.significant)

    def test_intervals_that_overlap_can_still_differ(self):
        before, after = passes('s', STACK_DPS, 0, 100.0, 3.0), passes('s', STACK_DPS, 0, 105.0, 3.0)
        self.assertTrue(only(diff([before], [after], set())).significant)
        close = passes('s', STACK_DPS, 0, 104.0, 3.0)
        self.assertFalse(only(diff([before], [close], set())).significant)

    def test_retribution_drop_with_only_argent_blade_intended_is_unintended(self):
        before = [passes('source 525028', STACK_SOURCE, RETRIBUTION_STRIKE, 100.0, 2.0),
                  hit('807268 hit_mean', ARGENT_BLADE, 543.0, 3.0)]
        after = [passes('source 525028', STACK_SOURCE, RETRIBUTION_STRIKE, 80.0, 2.0),
                 hit('807268 hit_mean', ARGENT_BLADE, 560.0, 3.0, status='alert')]
        changes = {change.label: change for change in diff(before, after, {ARGENT_BLADE})}
        retribution = changes['source 525028']
        self.assertTrue(retribution.significant)
        self.assertFalse(retribution.intended)
        self.assertAlmostEqual(retribution.delta_pct, -20.0)
        argent = changes['807268 hit_mean']
        self.assertTrue(argent.significant)
        self.assertTrue(argent.intended)

    def test_rank_id_of_an_intended_spell_counts(self):
        verdict = Verdict('r', 'ok', 1.0, 1.0, 0.0, 2.0, '', 's', 111, 222, 'effect_value')
        moved = Verdict('r', 'ok', 40.0, 1.0, 0.0, 2.0, '', 's', 111, 222, 'effect_value')
        self.assertTrue(only(diff([verdict], [moved], {222})).intended)
        self.assertFalse(only(diff([verdict], [moved], {333})).intended)

    def test_total_dps_without_a_spell_is_never_intended(self):
        change = only(diff([passes('dps', STACK_DPS, 0, 100.0, 1.0)], [passes('dps', STACK_DPS, 0, 90.0, 1.0)], {0}))
        self.assertFalse(change.intended)

    def test_asymmetric_wilson_intervals_use_the_facing_sides(self):
        before = proc('p', 0.10, 0.05, 0.20)
        wide_above = proc('p', 0.20, 0.15, 0.30)
        self.assertFalse(only(diff([before], [wide_above], set())).significant)
        far_above = proc('p', 0.40, 0.35, 0.45)
        self.assertTrue(only(diff([before], [far_above], set())).significant)
        far_below = proc('p', 0.06, 0.04, 0.08)
        self.assertFalse(only(diff([before], [far_below], set())).significant)
        lower = proc('p', 0.0105, 0.01, 0.0115)
        self.assertTrue(only(diff([proc('p', 0.10, 0.09, 0.30)], [lower], set())).significant)

    def test_deterministic_values_move_beyond_the_tolerance(self):
        self.assertFalse(only(diff([value('v', 1, 50.0, 50.0)], [value('v', 1, 50.9, 50.0)], set())).significant)
        self.assertTrue(only(diff([value('v', 1, 50.0, 50.0)], [value('v', 1, 51.5, 50.0)], set())).significant)
        self.assertFalse(only(diff([value('v', 1, 1000.0, 1000.0)], [value('v', 1, 1004.0, 1000.0)],
                                   set())).significant)
        self.assertTrue(only(diff([value('v', 1, 1000.0, 1000.0)], [value('v', 1, 1006.0, 1000.0)],
                                  set())).significant)

    def test_rolled_values_move_within_the_spread_of_their_roll(self):
        def rolled(measured):
            return replace(value('v', 1, measured, 960.0), detail={'roll_spread': 223})

        self.assertFalse(only(diff([rolled(997.0)], [rolled(924.0)], set())).significant)
        self.assertTrue(only(diff([rolled(997.0)], [rolled(1230.0)], set())).significant)
        self.assertIn('roll spread 223', only(diff([rolled(997.0)], [rolled(924.0)], set())).rule)

    def test_percent_point_passive_change_of_half_a_point_is_significant(self):
        label = '561346 e0 spell_crit_chance 1'
        change = only(diff([passive(label, 6.0, 6.0, 'spell_crit_chance')],
                           [passive(label, 5.5, 6.0, 'spell_crit_chance')], set()))
        self.assertTrue(change.significant)

    def test_integer_passive_change_inside_the_one_point_floor_is_noise(self):
        label = '561346 e1 expertise'
        change = only(diff([passive(label, 10.0, 10.0, 'expertise')], [passive(label, 10.5, 10.0, 'expertise')],
                           set()))
        self.assertFalse(change.significant)

    def test_cooldown_moves_inside_the_timing_window_are_noise(self):
        before = cooldown('c', 1, 7940.0, 8000.0, 120.0)
        self.assertFalse(only(diff([before], [cooldown('c', 1, 7900.0, 8000.0, 120.0)], set())).significant)
        self.assertTrue(only(diff([before], [cooldown('c', 1, 6000.0, 8000.0, 120.0)], set())).significant)

    def test_status_change_is_listed_even_when_the_move_is_small(self):
        before = value('v', 1, 50.0, 50.0)
        after = value('v', 1, 50.4, 50.0, status='alert')
        change = only(diff([before], [after], set()))
        self.assertFalse(change.significant)
        self.assertTrue(change.listed)
        self.assertEqual((change.status_before, change.status_after), ('ok', 'alert'))

    def test_status_change_without_a_measurement_is_listed_and_not_significant(self):
        before = hit('h', 1, 540.0, 3.0)
        after = Verdict('h', 'insufficient_trials', None, None, None, None, '', 's', 1, 1, HIT)
        change = only(diff([before], [after], set()))
        self.assertFalse(change.significant)
        self.assertTrue(change.listed)
        self.assertIsNone(change.delta_pct)

    def test_move_without_an_interval_is_not_judged_and_listed(self):
        before = hit('h', 1, 540.0, 3.0)
        after = Verdict('h', 'ok', 900.0, 543.2, None, None, '', 's', 1, 1, HIT)
        change = only(diff([before], [after], set()))
        self.assertFalse(change.significant)
        self.assertFalse(change.judged)
        self.assertTrue(change.listed)
        self.assertIn('not judged', change.rule)

    def test_same_value_without_an_interval_is_judged(self):
        before = Verdict('h', 'ok', 900.0, 543.2, None, None, '', 's', 1, 1, HIT)
        after = Verdict('h', 'alert', 900.0, 543.2, None, None, '', 's', 1, 1, HIT)
        change = only(diff([before], [after], set()))
        self.assertTrue(change.judged)

    def test_deterministic_moves_are_always_judged(self):
        change = only(diff([value('v', 1, 50.0, 50.0)], [value('v', 1, 50.5, 50.0)], set()))
        self.assertTrue(change.judged)

    def test_labels_on_one_side_are_added_and_removed(self):
        before = [value('gone', 1, 5.0, 5.0), value('both', 2, 5.0, 5.0)]
        after = [value('both', 2, 5.0, 5.0), value('new', 3, 7.0, 7.0)]
        changes = {change.label: change for change in diff(before, after, {3})}
        self.assertEqual(set(changes), {'gone', 'new'})
        self.assertEqual(changes['gone'].kind, REMOVED)
        self.assertEqual((changes['gone'].before, changes['gone'].after), (5.0, None))
        self.assertEqual(changes['new'].kind, ADDED)
        self.assertEqual((changes['new'].before, changes['new'].after), (None, 7.0))
        self.assertTrue(changes['new'].intended)
        self.assertFalse(changes['gone'].intended)
        self.assertTrue(all(change.listed for change in changes.values()))

    def test_duplicate_verdicts_in_one_scenario_are_an_error(self):
        twice = [value('v', 1, 5.0, 5.0), value('v', 1, 6.0, 5.0)]
        with self.assertRaises(ValueError):
            diff(twice, [], set())

    def test_the_same_label_in_two_scenarios_is_two_verdicts(self):
        def known(scenario, measured):
            return Verdict('known_aura 887007', 'ok', measured, 1.0, 1.0, 1.0, '', scenario, 887007, 887007,
                           'known_aura')

        before = [known('first', 1.0), known('second', 1.0)]
        after = [known('first', 1.0), known('second', 5.0)]
        change = only(diff(before, after, set()))
        self.assertEqual(change.scenario, 'second')
        self.assertTrue(change.significant)


class CommandTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix='conformance-diff-'))

    def tearDown(self):
        shutil.rmtree(self.root)

    def compare_output(self, name, verdicts, header=CLASS):
        out = self.root / name
        out.mkdir()
        write_verdicts(header, out / 'manifest.json', self.root / 'stamp', verdicts, out)
        return out

    def test_verdicts_survive_the_round_trip(self):
        verdicts = [hit('h', 1, 540.0, 3.0), passes('s', STACK_DPS, 0, 100.0, 2.0),
                    Verdict('d', MEASURED, 1.0, None, None, None, 'x', 's', 0, 0, 'talent_delta',
                            {'config': 'c1', 'passes': 5})]
        out = self.compare_output('before', verdicts)
        header, stored = read_verdicts(out)
        self.assertEqual(stored, verdicts)
        self.assertEqual((header['class_id'], header['class_name'], header['level']), (19, 'Templar', 60))
        self.assertEqual(json.loads((out / VERDICTS_FILE).read_text(encoding='utf-8'))['schema'], 1)

    def test_diff_command_lists_unintended_changes_first(self):
        before = self.compare_output('before', [
            passes('source 525028', STACK_SOURCE, RETRIBUTION_STRIKE, 100.0, 2.0),
            hit('807268 hit_mean', ARGENT_BLADE, 543.0, 3.0), value('quiet', 5, 10.0, 10.0)])
        after = self.compare_output('after', [
            passes('source 525028', STACK_SOURCE, RETRIBUTION_STRIKE, 80.0, 2.0),
            hit('807268 hit_mean', ARGENT_BLADE, 600.0, 3.0, status='alert'), value('quiet', 5, 10.3, 10.0)])
        self.assertEqual(main(['diff', '--before', str(before), '--after', str(after), '--intended', '807268']), 0)
        text = (after / IMPACT_FILE).read_text(encoding='utf-8')
        unintended, intended, quiet = (text.index(f'## {name}') for name in
                                       ('Unintended changes', 'Intended changes', 'Moved inside the intervals'))
        self.assertLess(unintended, intended)
        self.assertLess(intended, quiet)
        self.assertLess(unintended, text.index('source 525028'))
        self.assertLess(text.index('source 525028'), intended)
        self.assertLess(intended, text.index('807268 hit_mean'))
        self.assertLess(text.index('807268 hit_mean'), quiet)
        self.assertGreater(text.index('| quiet |'), quiet)

    def test_unjudged_move_is_listed_outside_the_quiet_section(self):
        before = self.compare_output('before', [hit('807268 hit_mean', ARGENT_BLADE, 540.0, 3.0),
                                                hit('other hit_mean', 5, 540.0, 3.0), value('quiet', 7, 10.0, 10.0)])
        after = self.compare_output('after', [
            Verdict('807268 hit_mean', 'ok', 900.0, 543.2, None, None, '', 's', ARGENT_BLADE, ARGENT_BLADE, HIT),
            Verdict('other hit_mean', 'ok', 900.0, 543.2, None, None, '', 's', 5, 5, HIT),
            value('quiet', 7, 10.3, 10.0)])
        self.assertEqual(main(['diff', '--before', str(before), '--after', str(after), '--intended', '807268']), 0)
        text = (after / IMPACT_FILE).read_text(encoding='utf-8')
        unintended, intended, quiet = (text.index(f'## {name}') for name in
                                       ('Unintended changes', 'Intended changes', 'Moved inside the intervals'))
        self.assertTrue(unintended < text.index('| other hit_mean |') < intended)
        self.assertTrue(intended < text.index('| 807268 hit_mean |') < quiet)
        self.assertGreater(text.index('| quiet |'), quiet)
        self.assertNotIn('inside intervals | ', text[:quiet])
        self.assertIn('| not judged |', text)
        self.assertIn('| of which not judged (no interval) | 2 |', text)

    def test_most_keys_unmatched_opens_with_a_warning(self):
        before = self.compare_output('before', [value('a', 1, 5.0, 5.0), value('b', 1, 5.0, 5.0),
                                                value('c', 1, 5.0, 5.0)])
        after = self.compare_output('after', [value('a', 1, 5.0, 5.0), value('x', 1, 5.0, 5.0),
                                              value('y', 1, 5.0, 5.0)])
        self.assertEqual(main(['diff', '--before', str(before), '--after', str(after)]), 0)
        text = (after / IMPACT_FILE).read_text(encoding='utf-8')
        self.assertIn('Warning: 2 of 3 verdicts before and 2 of 3 after have no counterpart', text)
        self.assertLess(text.index('Warning'), text.index('- Before:'))

    def test_few_unmatched_keys_give_no_warning(self):
        before = self.compare_output('before', [value('a', 1, 5.0, 5.0), value('b', 1, 5.0, 5.0)])
        after = self.compare_output('after', [value('a', 1, 5.0, 5.0), value('b', 1, 5.0, 5.0),
                                              value('c', 1, 5.0, 5.0)])
        self.assertEqual(main(['diff', '--before', str(before), '--after', str(after)]), 0)
        self.assertNotIn('Warning', (after / IMPACT_FILE).read_text(encoding='utf-8'))

    def test_diff_command_writes_to_the_requested_directory(self):
        before = self.compare_output('before', [value('v', 1, 5.0, 5.0)])
        after = self.compare_output('after', [value('v', 1, 9.0, 5.0)])
        out = self.root / 'impact'
        self.assertEqual(main(['diff', '--before', str(before), '--after', str(after), '--out', str(out)]), 0)
        self.assertIn('| v |', (out / IMPACT_FILE).read_text(encoding='utf-8'))
        self.assertFalse((after / IMPACT_FILE).exists())

    def test_diff_command_refuses_other_classes(self):
        before = self.compare_output('before', [value('v', 1, 5.0, 5.0)])
        after = self.compare_output('after', [value('v', 1, 5.0, 5.0)], {**CLASS, 'class_id': 20})
        self.assertEqual(main(['diff', '--before', str(before), '--after', str(after)]), DIFF_EXIT)
        self.assertFalse((after / IMPACT_FILE).exists())

    def test_diff_command_needs_the_verdicts_file(self):
        before = self.compare_output('before', [value('v', 1, 5.0, 5.0)])
        empty = self.root / 'old'
        empty.mkdir()
        self.assertEqual(main(['diff', '--before', str(before), '--after', str(empty)]), DIFF_EXIT)


if __name__ == '__main__':
    unittest.main()
