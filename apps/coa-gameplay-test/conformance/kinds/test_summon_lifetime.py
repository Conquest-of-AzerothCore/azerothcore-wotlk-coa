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
