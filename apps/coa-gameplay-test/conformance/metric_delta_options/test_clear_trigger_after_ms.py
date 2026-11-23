import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.clear_trigger_after_ms import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

HEX = 801693
WARD = 500960
OPTION = {'ms': 3200, 'quiet_ms': 2950, 'spell': HEX, 'target': 'dummy'}


def duration_entry(**changes) -> dict:
    return {'spell': 705925, 'name': 'Example ward haste (duration)', 'kind': 'metric_delta',
            'variant': 'ward_haste_lasts', 'label_suffix': 'ward_haste_lasts', 'quote': 'for $705926d',
            'trigger_spell': HEX, 'target': 'dummy', 'setup_casts': [WARD], 'setup_target': 'caster',
            'setup_wait_ms': 1600, 'measure_actor': 'caster', 'cast_power': 1400,
            'metric': 'owned_creature_cast_speed', 'fields': {'entry': 50105}, 'before_expected': 1.0,
            'expected': 100 / 103, 'tolerance': 0.0001, 'after_expiry_expected': 1.0, 'forced_roll': 705925,
            'gate_timing': 'start', 'trigger_only_after': True, 'wait_ms': 14400, 'expire_ms': 500,
            'expiry_wait_ms': 1000, 'game_time': {'after': [17500, 17750], 'expired': [18450, 18700]},
            'clear_trigger_after_ms': dict(OPTION), **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ClearTriggerAfterMsTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), duration_entry(**changes))

    def test_the_trigger_aura_is_cleared_after_the_treatment_cast_only(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        hexes = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == HEX]
        wards = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == WARD]
        self.assertEqual(len(hexes), 1)
        self.assertEqual(len(wards), 2)
        before = next(index for index, step in enumerate(steps)
                      if step.get('label') == expectation.model['before_label'])
        self.assertLess(wards[0], before)
        self.assertEqual([step['action'] for step in steps[hexes[0] + 1:hexes[0] + 8]],
                         ['assert', 'wait', 'assert', 'wait', 'assert', 'assert', 'set_aura'])
        self.assertEqual([steps[hexes[0] + 2]['ms'], steps[hexes[0] + 4]['ms']], [2950, 250])
        cleared = steps[hexes[0] + 7]
        self.assertEqual((cleared['spell'], cleared['stacks'], cleared['target']), (HEX, 0, 'dummy'))
        self.assertTrue(steps[hexes[0] + 1]['periodic'])
        recorded = expectation.model['clear_trigger_after_ms']
        labels = [step.get('label') for step in steps]
        for moment, read in (('after', expectation.model['after_label']),
                             ('expired', expectation.model['expired_label'])):
            self.assertEqual(labels[labels.index(read) - 1], recorded[moment])
        self.assertIn('exactly one tick', scenario['contract'])

    def test_an_entry_without_the_option_clears_nothing(self):
        scenario, [expectation] = self.built(clear_trigger_after_ms=None)
        self.assertNotIn('clear_trigger_after_ms', expectation.model)
        self.assertFalse(any(step['action'] == 'set_aura' and step.get('spell') == HEX for step in scenario['steps']))

    def values(self, after=100 / 103, expired=1.0, ticks=(0, 0, 1, 1, 1), cleared=3200.0, missing=None):
        _, [expectation] = self.built()
        model = expectation.model
        recorded = model['clear_trigger_after_ms']
        stamps = model['game_time']
        found = {model['before_label']: 1.0, model['after_label']: after, model['expired_label']: expired,
                 stamps['cast_label']: 100000.0, stamps['after_label']: 117600.0, stamps['expired_label']: 118600.0,
                 recorded['cleared at']: 100000.0 + cleared, model['forced_roll']['released_label']: 0.0}
        for moment, count in zip(('cast', 'quiet', 'cleared', 'after', 'expired'), ticks):
            found[recorded[moment]] = float(count)
        if missing:
            found.pop(recorded[missing])
        return expectation, found

    def judged(self, **reads):
        expectation, found = self.values(**reads)
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def test_the_stated_duration_is_ok_with_one_tick(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('1 when cleared at 3200 ms', verdict.explanation)

    def test_a_short_or_long_aura_alerts(self):
        self.assertEqual(self.judged(after=1.0).status, 'alert')
        self.assertEqual(self.judged(expired=100 / 103).status, 'alert')

    def test_a_clear_that_did_not_hold_one_tick_is_unmeasured(self):
        for reads in ({'ticks': (0, 1, 1, 1, 1)}, {'ticks': (0, 0, 0, 0, 0)}, {'ticks': (0, 0, 2, 2, 2)},
                      {'ticks': (0, 0, 1, 2, 2)}, {'ticks': (0, 0, 1, 1, 2)}, {'cleared': 3300.0},
                      {'missing': 'quiet'}, {'missing': 'cleared at'}):
            with self.subTest(reads=reads):
                self.assertEqual(self.judged(**reads).status, 'unmeasured')

    def test_the_duration_words_of_the_claim_make_the_cleared_trigger_behaviour(self):
        from coverage import BEHAVIOUR, DATA, METRIC_EVIDENCE, STATE, STATE_PROMISES, metric_evidence, \
            verdict_evidence
        verdict = self.judged()
        self.assertEqual(verdict.detail['metric'], 'cleared_trigger_state')
        self.assertNotIn('cleared_trigger_state', METRIC_EVIDENCE)
        self.assertNotIn('cleared_trigger_state', STATE_PROMISES)
        self.assertEqual(metric_evidence()['cleared_trigger_state'], STATE)
        self.assertEqual(verdict_evidence(verdict, 'for $705926d', {}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdict, 'to increase the haste of your Serpent Wards by $705926s1%', {}),
                         DATA)
        self.assertNotEqual(verdict_evidence(self.judged(after=1.0), 'for $705926d', {}), BEHAVIOUR)

    def test_refused_inputs(self):
        for raw in ({'ms': 3200, 'quiet_ms': 2950, 'spell': HEX}, {**OPTION, 'quiet_ms': 3200},
                    {**OPTION, 'quiet_ms': 0}, {**OPTION, 'ms': 10001}, {**OPTION, 'ms': True},
                    {**OPTION, 'spell': 0}, {**OPTION, 'target': 7}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'trigger_only_after': False}, {'expiry_wait_ms': None, 'after_expiry_expected': None},
                        {'game_time': {'after': [17500, 17750]}, 'expiry_wait_ms': None,
                         'after_expiry_expected': None},
                        {'clear_trigger_after_ms': {**OPTION, 'spell': 1}},
                        {'clear_trigger_after_ms': {**OPTION, 'target': 'caster'}},
                        {'clear_trigger_after_ms': {**OPTION, 'ms': 9000, 'quiet_ms': 8000},
                         'game_time': {'after': [8000, 9500], 'expired': [18450, 18700]}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
