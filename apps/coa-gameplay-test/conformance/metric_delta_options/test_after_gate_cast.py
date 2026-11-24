from functools import cache
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.after_gate_cast import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

DIVINE_STRIKES = 705255
CAP = 10
GATED = {'after_gate_cast': True, 'after_start_reads': [{'spell': DIVINE_STRIKES, 'expected': 1}],
         'void_on_cast_failure': True}


@cache
def templar() -> dict:
    return load_fixture_class_file(19)


def plain_entry() -> dict:
    return next(behaviour for behaviour in templar()['behaviours']
                if behaviour.get('spell') == DIVINE_STRIKES and behaviour.get('variant') == 'stack_cap')


def gated_entry(**changes) -> dict:
    return {**plain_entry(), **GATED, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterGateCastTests(unittest.TestCase):
    def test_the_gate_is_cast_once_at_the_start_of_the_after_phase(self):
        scenario, [expectation] = behaviour_scenario(templar(), gated_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        casts = [index for index, step in enumerate(steps)
                 if step['action'] == 'cast' and step['spell'] == DIVINE_STRIKES]
        self.assertEqual(len(casts), 1)
        [cast] = casts
        self.assertEqual(steps[cast]['target'], 'caster')
        self.assertEqual(steps[cast - 1], {'action': 'reset_cooldown', 'actor': 'caster', 'spell': DIVINE_STRIKES})
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == DIVINE_STRIKES)
        read = labels.index(expectation.model['after_start_reads'][0]['read_label'])
        self.assertLess(labels.index(expectation.model['before_label']), learn)
        self.assertLess(learn, cast)
        self.assertLess(cast, read)
        first_feed = next(index for index, step in enumerate(steps)
                          if index > cast and step['action'] == 'cast')
        self.assertLess(read, first_feed)
        self.assertIn(f'a real cast of {DIVINE_STRIKES}', scenario['contract'])

    def test_an_entry_without_the_option_is_unchanged(self):
        with_reads = {key: value for key, value in gated_entry().items() if key != 'after_gate_cast'}
        scenario, [expectation] = behaviour_scenario(templar(), with_reads)
        self.assertFalse(any(step['action'] == 'cast' and step['spell'] == DIVINE_STRIKES
                             for step in scenario['steps']))
        self.assertNotIn('real cast', scenario['contract'])
        self.assertNotIn('after_gate_cast', expectation.model)
        self.assertEqual(behaviour_scenario(templar(), gated_entry(after_gate_cast=None))[0], scenario)

    def judged(self, stacks: float | None, failures: dict | None = None) -> str:
        _, [expectation] = behaviour_scenario(templar(), gated_entry())
        model = expectation.model
        values = {model['before_label']: 0.0, model['after_label']: float(CAP)}
        if stacks is not None:
            values[model['after_start_reads'][0]['read_label']] = stacks
        fake = FakeRun(values)
        fake.cast_failures = failures or {}
        return judge_behaviour(base_verdict(expectation), fake, expectation).status

    def test_a_landed_cast_is_judged_and_a_cast_that_did_not_land_is_unmeasured(self):
        self.assertEqual(self.judged(1.0), 'ok')
        self.assertEqual(self.judged(0.0), 'unmeasured')
        self.assertEqual(self.judged(None), 'unmeasured')
        self.assertEqual(self.judged(1.0, {DIVINE_STRIKES: [105]}), 'unmeasured')

    def test_refused_inputs(self):
        for raw in (False, 1, {'spell': DIVINE_STRIKES}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'after_start_reads': None}, {'after_start_reads': [{'spell': DIVINE_STRIKES, 'expected': 0}]},
                        {'void_on_cast_failure': None}, {'after_auras': [[DIVINE_STRIKES, 1, 'caster', 'caster']]},
                        {'gate_timing': 'start'}):
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, 'after_gate_cast'):
                behaviour_scenario(templar(), gated_entry(**changes))


if __name__ == '__main__':
    unittest.main()
