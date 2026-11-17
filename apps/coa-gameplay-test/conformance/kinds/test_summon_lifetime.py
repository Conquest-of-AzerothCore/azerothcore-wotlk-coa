from dataclasses import replace
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict, cast_indices


class SummonLifetimeTests(unittest.TestCase):
    def built(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry['kind'] == 'summon_lifetime' and entry['spell'] == 705747)
        return behaviour_scenario(load_fixture_class_file(23), entry)

    def judged(self, spawn_ms: float, end_ms: float, control: float = 0.0) -> str:
        _, [expectation] = self.built()
        model = expectation.model
        values = {model['control']: control, model['released']: 0.0, model['starts']['control']: 0.0,
                  model['starts']['treatment']: 100000.0}
        for window, low in (('spawn', 2500), ('end', 16500)):
            for index, (at, count) in enumerate(model['polls'][window]):
                offset = low + index * 25.0
                values[at], values[count] = 100000.0 + offset, 1.0 if spawn_ms <= offset < end_ms else 0.0
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_talent_is_forced_and_learned_after_the_control_cast(self):
        scenario, _ = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        mutant = next(index for index, step in enumerate(steps) if step['action'] == 'spell_mod_mutant')
        learn = next(index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 705747)
        casts = cast_indices(steps, 500968)
        self.assertEqual(len(casts), 2)
        self.assertLess(mutant, casts[0])
        self.assertLess(casts[0], learn)
        self.assertLess(learn, casts[1])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_stated_lifetime_is_ok_and_a_short_or_control_summon_alerts(self):
        self.assertEqual(self.judged(3010.0, 18010.0), 'ok')
        self.assertEqual(self.judged(3010.0, 16010.0), 'unmeasured')
        self.assertEqual(self.judged(3010.0, 17010.0), 'alert')
        self.assertEqual(self.judged(3010.0, 18010.0, control=1.0), 'alert')


class SummonLifetimePooledTests(unittest.TestCase):
    def expectation(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry['kind'] == 'summon_lifetime' and entry['spell'] == 807700)
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return replace(expectation, model={**expectation.model, 'parts': entry['parts']})

    def values(self, model: dict, end_ms: float | None) -> dict:
        found = {model['control']: 0.0, model['released']: 0.0, model['starts']['control']: 0.0,
                 model['starts']['treatment']: 100000.0}
        for window, low in (('spawn', 2500), ('end', 11500)):
            for index, (at, count) in enumerate(model['polls'][window]):
                offset = low + index * 25.0
                present = end_ms is not None and 3010.0 <= offset < end_ms
                found[at], found[count] = 100000.0 + offset, 1.0 if present else 0.0
        return found

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_parts_without_a_summon_are_left_out_and_a_summoned_part_is_judged(self):
        from kinds.summon_lifetime import behaviour_summon_lifetime_pooled_verdict
        expectation = self.expectation()
        model = expectation.model
        judged = lambda ends: behaviour_summon_lifetime_pooled_verdict(
            base_verdict(expectation), [FakeRun(self.values(model, end)) for end in ends], model).status
        self.assertEqual(judged([None, 13010.0, None]), 'ok')
        self.assertEqual(judged([None, None]), 'unmeasured')
        self.assertEqual(judged([13010.0, 12010.0]), 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_pooled_entry_writes_one_scenario_per_part(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry['kind'] == 'summon_lifetime' and entry['spell'] == 807700)
        self.assertGreaterEqual(entry['parts'], 40)


class SummonLifetimeBaselineTests(unittest.TestCase):
    BASELINE = {'baseline_count': 2, 'baseline_ms': 20000, 'roll_source': 'Example.cpp:1-2 (roll_chance_i)'}

    def entry(self, **changes) -> dict:
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                     if entry['kind'] == 'summon_lifetime' and entry['spell'] == 807700)
        return {**entry, **self.BASELINE, **changes}

    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), self.entry(**changes))

    def values(self, model: dict, end_ms: float | None, control: float = 2.0, expired: float = 0.0,
               pre: float = 0.0, stray: float | None = None) -> dict:
        found = {model['control']: control, model['released']: 0.0, model['starts']['control']: 0.0,
                 model['starts']['treatment']: 100000.0, model['baseline']['expired']: expired}
        pre_time, pre_count = model['polls']['spawn'][0]
        self.assertEqual(pre_time, model['starts']['treatment'])
        found[pre_count] = pre
        for window, low, marks in (('spawn', 2500, model['polls']['spawn'][1:]), ('end', 11500, model['polls']['end'])):
            for index, (at, count) in enumerate(marks):
                offset = low + index * 25.0
                present = end_ms is not None and 3010.0 <= offset < end_ms
                found[at], found[count] = 100000.0 + offset, 3.0 if present else 2.0
        if stray is not None:
            found[model['polls']['end'][-1][1]] = stray
        return found

    def status(self, end_ms: float | None, **reads) -> str:
        _, [expectation] = self.built()
        return judge_behaviour(base_verdict(expectation), FakeRun(self.values(expectation.model, end_ms, **reads)),
                               expectation).status

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_baseline_expires_before_the_talent_and_the_treatment_starts_empty(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        model = expectation.model
        learn = next(index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 807700)
        casts = cast_indices(steps, 500968)
        self.assertLess(labels.index(model['control']), labels.index(model['baseline']['expired']))
        self.assertLess(labels.index(model['baseline']['expired']), learn)
        self.assertLess(learn, labels.index(model['polls']['spawn'][0][1]))
        self.assertLess(labels.index(model['polls']['spawn'][0][1]), casts[1])
        wait = steps[labels.index('let the control baseline expire')]['ms']
        self.assertEqual(wait, 20000 - 3500 - 1600 + 1000)
        self.assertIn('Example.cpp:1-2', scenario['contract'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_extra_creature_is_judged_above_the_baseline(self):
        self.assertEqual(self.status(13010.0), 'ok')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_lifetime_past_or_before_the_end_window_alerts(self):
        self.assertEqual(self.status(30000.0), 'alert')
        self.assertEqual(self.status(11000.0), 'alert')
        self.assertEqual(self.status(12010.0), 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_control_with_the_extra_creature_alerts_and_broken_baselines_are_unmeasured(self):
        self.assertEqual(self.status(13010.0, control=3.0), 'alert')
        self.assertEqual(self.status(13010.0, expired=1.0), 'unmeasured')
        self.assertEqual(self.status(13010.0, pre=2.0), 'unmeasured')
        self.assertEqual(self.status(13010.0, stray=1.0), 'unmeasured')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_pooled_parts_at_the_baseline_are_left_out(self):
        from kinds.summon_lifetime import behaviour_summon_lifetime_pooled_verdict
        _, [expectation] = self.built()
        model = {**expectation.model, 'parts': 3}
        judged = lambda ends: behaviour_summon_lifetime_pooled_verdict(
            base_verdict(expectation), [FakeRun(self.values(model, end)) for end in ends], model).status
        self.assertEqual(judged([None, 13010.0, None]), 'ok')
        self.assertEqual(judged([None, None]), 'unmeasured')
        self.assertEqual(judged([13010.0, 30000.0]), 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_baseline_fields_are_refused_alone_or_inside_the_end_window(self):
        for changes in ({'baseline_ms': None}, {'baseline_count': 0}, {'baseline_ms': 15000}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)
        entry = {key: value for key, value in self.entry().items() if key not in self.BASELINE}
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**entry, 'roll_source': 'Example.cpp:1'})
        _, [plain] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('baseline', plain.model)
