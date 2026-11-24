from functools import cache
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.apply_stamp import parse
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

STALWART = 300355
IMMUNITY = 301342
CLOCK = 800722


WINDOWS = {'immunity_held': (1, 3630, [3620, 3750], [3620, 3990]),
           'immunity_gone': (0, 4030, [4010, 4130], [4010, 4380])}


def class_entry(suffix: str) -> dict:
    expected, wait, after, window = WINDOWS[suffix]
    return {'spell': STALWART, 'kind': 'metric_delta', 'quote': 'prevent you from being critically struck again',
            'gate_spell': STALWART, 'trigger_spell': CLOCK, 'target': 'caster',
            'phase_auras': [[213, 1, 'caster', 'caster']],
            'strike': {'spell': 11976, 'health': 100000, 'max_health': 100000, 'count': 4, 'wait_ms': 20},
            'metric': 'aura', 'fields': {'spell': IMMUNITY}, 'measure_actor': 'caster', 'before_expected': 0,
            'expected': expected, 'wait_ms': wait, 'expire_ms': 500, 'name': f'apply stamp test {suffix}',
            'variant': suffix, 'label_suffix': suffix, 'game_time': {'after': after},
            'caster_avoidance': {'dodge': 0, 'parry': 0},
            'apply_stamp': {'aura': IMMUNITY, 'window': window, 'source': 'test duration 4000 ms'}}


@cache
def stamped(suffix: str, option: bool):
    _, [expectation] = behaviour_scenario(load_class_file(27),
                                          {**class_entry(suffix), **({} if option else {'apply_stamp': None})})
    return expectation


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ApplyStampTests(unittest.TestCase):
    def built(self, suffix: str = 'immunity_gone', **changes):
        return behaviour_scenario(load_class_file(27), {**class_entry(suffix), **changes})

    def test_the_timeline_opens_before_the_after_strikes_and_the_stamps_follow_the_reads(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        actions = [step['action'] for step in steps]
        self.assertEqual(actions.count('encounter_start'), 1)
        opened = actions.index('encounter_start')
        learn = max(index for index, step in enumerate(steps)
                    if step['action'] == 'learn' and step.get('spell') == STALWART)
        strikes = [index for index, step in enumerate(steps) if step.get('actor') == 'striker']
        self.assertTrue(learn < opened < min(index for index in strikes if index > learn))
        self.assertEqual(steps[opened]['boss_entry'], 36)
        labels = [step.get('label') for step in steps]
        clock = max(index for index, step in enumerate(steps)
                    if step['action'] == 'cast' and step.get('spell') == CLOCK)
        self.assertEqual(labels[clock + 1:clock + 3],
                         [f'{STALWART} apply_stamp cast_count', f'{STALWART} apply_stamp cast_upper'])
        after = labels.index(expectation.model['after_label'])
        self.assertEqual(labels[after + 1:after + 5],
                         [f'{STALWART} apply_stamp {stamp}' for stamp in ('read_upper', 'count', 'clock', 'first')])
        self.assertEqual(steps[after + 3]['event'], 'cast')
        self.assertEqual(steps[after + 4]['spell'], IMMUNITY)
        self.assertIn('Apply stamp', scenario['contract'])

    def test_an_entry_without_the_option_is_unchanged(self):
        scenario, [expectation] = self.built(apply_stamp=None)
        self.assertNotIn('apply_stamp', expectation.model)
        self.assertFalse(any(step['action'] == 'encounter_start' for step in scenario['steps']))
        self.assertFalse(any('apply_stamp' in str(step.get('label')) for step in scenario['steps']))

    def judged(self, suffix='immunity_gone', aura=0.0, wait=4040, offset=90.0, count=4, cast_count=4, drop=None,
               option=True):
        expectation = stamped(suffix, option)
        model = expectation.model
        found = {model['before_label']: 0.0, model['after_label']: aura,
                 model['game_time']['cast_label']: 10000.0, model['game_time']['after_label']: 10000.0 + wait}
        if option:
            stamps = model['apply_stamp']['stamps']
            found.update({stamps['cast_count']: cast_count, stamps['cast_upper']: 10004.0,
                          stamps['read_upper']: 10003.0 + wait, stamps['count']: count,
                          stamps['clock']: 500.0, stamps['first']: 500.0 - offset})
            if drop:
                found.pop(stamps[drop])
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def test_a_gone_reading_bracketed_inside_its_window_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['apply_bracket'], [4036.0, 4133.0])

    def test_a_held_reading_bracketed_inside_its_window_is_ok(self):
        verdict = self.judged('immunity_held', aura=1.0, wait=3640)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['apply_bracket'], [3636.0, 3733.0])

    def test_a_long_duration_hidden_by_a_late_apply_alerts_only_with_the_stamp(self):
        self.assertEqual(self.judged(offset=400.0, option=False).status, 'ok')
        verdict = self.judged(offset=400.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.detail['apply_bracket'], [4036.0, 4443.0])

    def test_a_held_reading_from_an_early_apply_alerts(self):
        self.assertEqual(self.judged('immunity_held', aura=1.0, wait=3640, offset=400.0).status, 'alert')

    def test_a_reading_that_cannot_bound_the_apply_is_unmeasured(self):
        for reads in ({'drop': 'first'}, {'drop': 'clock'}, {'drop': 'cast_upper'}, {'count': 0, 'cast_count': 0},
                      {'count': 5}):
            with self.subTest(reads=reads):
                self.assertEqual(self.judged(**reads).status, 'unmeasured')

    def test_refused_inputs(self):
        good = {'aura': IMMUNITY, 'window': [4010, 4380], 'source': 'duration'}
        for raw in ({**good, 'source': ' '}, {**good, 'aura': True}, {**good, 'window': [4380, 4010]},
                    {**good, 'window': [0, 10]}, {**good, 'window': [4010.5, 4380]}, {**good, 'extra': 1},
                    {key: good[key] for key in good if key != 'source'}, IMMUNITY):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'game_time': None}, {'strike': {**class_entry('immunity_gone')['strike'],
                                                         'after_trigger_ms': 100}}):
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, 'apply_stamp'):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
