import unittest

from behaviours import behaviour_scenario
from metric_delta_options import channel_lengths
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def lengths_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (end damage by channel length)', 'kind': 'metric_delta',
            'label_suffix': 'lengths', 'quote': "to increase your and your Undead minion's haste",
            'expected': 2, 'before_expected': 0, 'trigger_spell': 500237, 'target': 'dummy',
            'metric': 'spell_damage_count', 'fields': {'spell': 500237, 'target': 'dummy'}, 'wait_ms': 3000,
            'channel_lengths': {'spell': 500237, 'events': 2, 'cancel_ms': [600, 1500], 'repeats': 2}, **changes}


def judged_entry(repeats: int = 4) -> dict:
    return lengths_entry(channel_lengths={'spell': 500237, 'events': 2, 'cancel_ms': [600, 1500], 'repeats': repeats})


def expectation_of(entry: dict):
    return behaviour_scenario(load_fixture_class_file(23), entry)[1][0]


def run_values(expectation, damages: dict, plain: dict | None = None, struck: dict | None = None,
               still_up: dict | None = None) -> dict:
    lengths = expectation.model['channel_lengths']
    values = {expectation.model['before_label']: 0, expectation.model['after_label']: 2,
              **dict.fromkeys(lengths['base'].values(), 0)}
    for arm in lengths['cancel_ms']:
        flags = (still_up or {}).get(arm, [0] * lengths['repeats'])
        values.update(zip(lengths['channel'][str(arm)], flags))
    totals = {'total': 0, 'plain': 0, 'struck': 0}
    for arm in [lengths['arms'][-1], *lengths['arms'][:-1]]:
        for repeat, row in enumerate(lengths['reads'][str(arm)]):
            totals['total'] += damages[arm][repeat]
            totals['plain'] += (plain or {}).get(arm, [2] * len(damages[arm]))[repeat]
            totals['struck'] += (struck or {}).get(arm, [2] * len(damages[arm]))[repeat]
            values.update({row[read]: totals[read] for read in totals})
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ChannelLengthsTests(unittest.TestCase):
    def judged(self, values: dict, expectation) -> str:
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    def test_each_length_is_cast_with_its_cancel_and_read(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), lengths_entry())
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 500237]
        self.assertEqual(len(casts), 1 + 2 + 2 * 2)
        cancels = [index for index, step in enumerate(steps) if step['action'] == 'cancel_aura']
        self.assertEqual(len(cancels), 4)
        self.assertEqual([steps[index - 1]['ms'] for index in cancels], [600, 600, 1500, 1500])
        self.assertEqual([steps[index + 2]['ms'] for index in cancels], [2400, 2400, 1500, 1500])
        self.assertTrue(all(steps[index]['spell'] == 500237 for index in cancels))
        self.assertEqual(expectation.model['channel_lengths']['arms'], [600, 1500, 'full'])
        reads = [steps[index + 1] for index in cancels]
        self.assertTrue(all((read['action'], read['metric'], read['actor'], read['spell'])
                            == ('assert', 'aura', 'caster', 500237) for read in reads))
        self.assertEqual([read['label'] for read in reads],
                         [label for arm in (600, 1500)
                          for label in expectation.model['channel_lengths']['channel'][str(arm)]])

    def test_without_the_option_the_scenario_has_no_cancel(self):
        entry = {key: value for key, value in lengths_entry().items() if key != 'channel_lengths'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('channel_lengths', expectation.model)
        self.assertFalse(any(step['action'] == 'cancel_aura' for step in scenario['steps']))

    def test_malformed_options_are_refused(self):
        for lengths in ({'spell': 500237, 'events': 2, 'cancel_ms': [1500, 600], 'repeats': 2},
                        {'spell': 500237, 'events': 2, 'cancel_ms': [600], 'repeats': 2},
                        {'spell': 500237, 'events': 2, 'cancel_ms': [600, 3000], 'repeats': 2},
                        {'spell': 500237, 'events': 2, 'cancel_ms': [600, 1500], 'repeats': 0},
                        {'spell': 500237, 'events': 2, 'cancel_ms': [600, 1500]}):
            with self.subTest(lengths=lengths), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), lengths_entry(channel_lengths=lengths))

    def test_three_lengths_need_three_kept_casts_each(self):
        self.assertEqual([channel_lengths.minimum_kept(count) for count in (2, 3, 4)], [7, 4, 2])

    def test_damage_rising_with_the_channel_length_is_ok(self):
        expectation = expectation_of(judged_entry())
        damages = {600: [80, 84, 82, 81], 1500: [170, 175, 172, 171], 'full': [330, 320, 325, 322]}
        self.assertEqual(self.judged(run_values(expectation, damages), expectation), 'ok')

    def test_flat_or_falling_damage_alerts(self):
        expectation = expectation_of(judged_entry())
        for damages in ({600: [330, 320, 325, 322], 1500: [170, 175, 172, 171], 'full': [80, 84, 82, 81]},
                        {600: [200] * 4, 1500: [200] * 4, 'full': [200] * 4},
                        {600: [80, 84, 82, 81], 1500: [340] * 4, 'full': [330, 320, 325, 322]}):
            with self.subTest(damages=damages):
                self.assertEqual(self.judged(run_values(expectation, damages), expectation), 'alert')

    def test_critical_repeats_leave_the_mean_and_a_wholly_critical_length_is_unmeasured(self):
        expectation = expectation_of(judged_entry(5))
        damages = {600: [80, 400, 82, 81, 83], 1500: [170, 175, 172, 171, 173], 'full': [330, 320, 325, 322, 327]}
        self.assertEqual(self.judged(run_values(expectation, damages, plain={600: [2, 1, 2, 2, 2]}), expectation),
                         'ok')
        self.assertEqual(self.judged(run_values(expectation, damages, plain={600: [1] * 5}), expectation),
                         'unmeasured')

    def test_a_missing_end_strike_alerts(self):
        expectation = expectation_of(judged_entry())
        damages = {600: [80, 84, 82, 81], 1500: [170, 175, 172, 171], 'full': [330, 320, 325, 322]}
        values = run_values(expectation, damages, struck={1500: [2, 1, 2, 2]}, plain={1500: [2, 1, 2, 2]})
        self.assertEqual(self.judged(values, expectation), 'alert')

    def test_a_cancel_that_leaves_the_channel_up_voids_its_cast(self):
        expectation = expectation_of(judged_entry(5))
        damages = {600: [80, 900, 82, 81, 83], 1500: [170, 175, 172, 171, 173], 'full': [330, 320, 325, 322, 327]}
        values = run_values(expectation, damages, still_up={600: [0, 1, 0, 0, 0]})
        self.assertEqual(self.judged(values, expectation), 'ok')

    def test_failed_cancels_never_pass_on_full_channels_read_in_rising_order(self):
        expectation = expectation_of(judged_entry())
        damages = {600: [300, 310, 305, 306], 1500: [320, 325, 322, 321], 'full': [330, 335, 332, 331]}
        values = run_values(expectation, damages, still_up={600: [1] * 4, 1500: [1] * 4})
        self.assertEqual(self.judged(values, expectation), 'unmeasured')

    def test_a_missing_channel_read_alerts(self):
        expectation = expectation_of(judged_entry())
        damages = {600: [80, 84, 82, 81], 1500: [170, 175, 172, 171], 'full': [330, 320, 325, 322]}
        values = run_values(expectation, damages)
        del values[expectation.model['channel_lengths']['channel']['1500'][0]]
        self.assertEqual(self.judged(values, expectation), 'alert')

    def test_length_independent_damage_with_rising_means_never_passes(self):
        expectation = expectation_of(judged_entry())
        for damages in ({600: [300, 330, 301, 329], 1500: [310, 335, 311, 334], 'full': [320, 340, 321, 339]},
                        {600: [80, 175, 81, 174], 1500: [170, 330, 171, 329], 'full': [320, 335, 321, 334]}):
            with self.subTest(damages=damages):
                self.assertEqual(self.judged(run_values(expectation, damages), expectation), 'alert')

    def test_two_kept_casts_per_length_read_unmeasured_even_in_ordered_blocks(self):
        expectation = expectation_of(judged_entry())
        damages = {600: [200, 900, 201, 950], 1500: [202, 960, 203, 970], 'full': [204, 205, 980, 990]}
        values = run_values(expectation, damages, still_up={600: [0, 1, 0, 1], 1500: [0, 1, 0, 1]},
                            plain={'full': [2, 2, 1, 1]})
        self.assertEqual(self.judged(values, expectation), 'unmeasured')
