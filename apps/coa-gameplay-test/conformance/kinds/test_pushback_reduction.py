from dataclasses import replace
import unittest

from behaviours import STRIKER, behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict, cast_indices, cycle_one_entry


class PushbackReductionTests(unittest.TestCase):
    def built(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours'] if entry['kind'] == 'pushback_reduction')
        single = {**entry, 'repeats': 1, 'windows': [[2440, 2560], [2930, 3050], [2680, 2800]]}
        return behaviour_scenario(load_fixture_class_file(23), single)

    def values(self, ends: dict, strikes: dict | None = None, step_ms: float = 1.0) -> dict:
        _, [expectation] = self.built()
        found = {}
        for index, (name, phase) in enumerate(expectation.model['phases'].items()):
            start = 10000.0 * (index + 1)
            found[phase['start']] = start
            low = {'unhit': 2440, 'hit': 2930, 'reduced': 2680}[name]
            for poll, (time_label, casting_label) in enumerate(phase['polls']):
                at = start + low + poll * step_ms
                found[time_label], found[casting_label] = at, 1.0 if at - start < ends[name] else 0.0
            if 'strike' in phase:
                offset = (strikes or {}).get(name, 1000.0)
                found[phase['strike']], found[phase['struck']] = start + offset, start + offset
                found[phase['strikes'][0]], found[phase['strikes'][1]] = 0.0, 1.0
        return found

    def judged(self, ends: dict, strikes: dict | None = None) -> str:
        _, [expectation] = self.built()
        return judge_behaviour(base_verdict(expectation), FakeRun(self.values(ends, strikes)), expectation).status

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_poll_and_strike_is_stamped_in_game_time(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        strikes = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['actor'] == STRIKER]
        self.assertEqual(len(strikes), 2)
        for index in strikes:
            self.assertEqual((steps[index - 1]['metric'], steps[index + 1]['metric']), ('game_time_ms', 'game_time_ms'))
        reducer = cast_indices(steps, 807813)
        self.assertEqual(len(reducer), 1)
        self.assertLess(strikes[0], reducer[0])
        self.assertLess(reducer[0], strikes[1])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_halved_pushback_is_ok_and_a_full_one_alerts(self):
        self.assertEqual(self.judged({'unhit': 2495, 'hit': 2983, 'reduced': 2739}), 'ok')
        self.assertEqual(self.judged({'unhit': 2495, 'hit': 2983, 'reduced': 2790}), 'alert')
        self.assertEqual(self.judged({'unhit': 2495, 'hit': 2983, 'reduced': 2760}), 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_strikes_at_different_offsets_are_invalid(self):
        self.assertEqual(self.judged({'unhit': 2495, 'hit': 2983, 'reduced': 2739},
                                     {'hit': 1000.0, 'reduced': 1012.0}), 'unmeasured')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_reducer_stamps_its_own_cast_or_its_learn_as_the_contrast(self):
        own = cycle_one_entry(807813, 'pushback_game_time')
        learned = cycle_one_entry(802988, 'pushback_game_time')
        contrast = lambda entry: behaviour_scenario(load_fixture_class_file(23), entry)[1][0].model['contrast']
        self.assertEqual(contrast(own), 'own_cast')
        self.assertEqual(contrast(learned), 'learned')
        self.assertEqual(contrast({**own, 'reducer_spell': 802988}), 'condition')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_an_own_cast_reduction_is_a_promised_state_and_a_condition_one_is_not(self):
        from compare import observed
        from coverage import promised_state
        clause = 'and reduces the pushback suffered from damaging attacks while casting by 50%'
        _, [expectation] = self.built()
        found = judge_behaviour(base_verdict(expectation),
                                FakeRun(self.values({'unhit': 2495, 'hit': 2983, 'reduced': 2739})), expectation)
        stamped = replace(found, detail={**found.detail, **observed(expectation)})
        self.assertEqual(stamped.status, 'ok')
        self.assertTrue(promised_state(stamped, clause))
        self.assertFalse(promised_state(replace(stamped, detail={**stamped.detail, 'contrast': 'condition'}), clause))
        self.assertFalse(promised_state(stamped, 'Summon an Icebound Champion'))


class PushbackLearnedReducerTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_learned_reducer_adds_its_own_unhit_cast_after_the_learn(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry['kind'] == 'pushback_reduction' and entry.get('reducer_learn'))
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        steps = scenario['steps']
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == entry['reducer_spell'])
        casts = cast_indices(steps, entry['cast_spell'])
        repeats = entry.get('repeats', 1)
        self.assertEqual(len(casts), 4 * repeats)
        self.assertLess(casts[2 * repeats - 1], learn)
        self.assertLess(learn, casts[2 * repeats])
        self.assertEqual(list(expectation.model['samples']), ['unhit', 'hit', 'reduced_unhit', 'reduced'])
        self.assertNotIn('strike', expectation.model['samples']['reduced_unhit'][0])


class PushbackSampledTests(unittest.TestCase):
    def built(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry['kind'] == 'pushback_reduction' and entry.get('repeats', 1) > 1
                     and entry.get('reducer_learn'))
        return entry, behaviour_scenario(load_fixture_class_file(23), entry)

    def judged(self, ends: dict) -> str:
        entry, (_, [expectation]) = self.built()
        lows = dict(zip(('unhit', 'hit', 'reduced_unhit', 'reduced'), (low for low, _ in entry['windows'])))
        values = {}
        for kind, samples in expectation.model['samples'].items():
            for index, phase in enumerate(samples):
                start = 100000.0 * (len(values) + 1)
                values[phase['start']] = start
                end = ends[kind] + (index % 3) * 3.0
                for poll, (at, casting) in enumerate(phase['polls']):
                    offset = lows[kind] + poll * 9.0
                    values[at], values[casting] = start + offset, 1.0 if offset < end else 0.0
                if 'strike' in phase:
                    values[phase['strike']], values[phase['struck']] = start + 1012.0, start + 1016.0
                    values[phase['strikes'][0]], values[phase['strikes'][1]] = 0.0, 1.0
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_mean_of_repeated_casts_is_judged_with_its_interval(self):
        entry, (scenario, [expectation]) = self.built()
        run.validate(scenario)
        self.assertEqual(len(expectation.model['samples']['hit']), entry['repeats'])
        self.assertEqual(self.judged({'unhit': 2505, 'hit': 3005, 'reduced_unhit': 2125, 'reduced': 2375}), 'ok')
        self.assertEqual(self.judged({'unhit': 2505, 'hit': 3005, 'reduced_unhit': 2125, 'reduced': 2475}), 'alert')
