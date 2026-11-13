import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun


def chain_period_entry() -> dict:
    return next(entry for entry in load_class_file(23)['behaviours']
                if entry['kind'] == 'hit_period' and entry['label_suffix'] == 'chain_period')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class HitPeriodTests(unittest.TestCase):
    def judged(self, period: float, first: float = 1330.0) -> Verdict:
        _, [expectation] = behaviour_scenario(load_class_file(23), chain_period_entry())
        model = expectation.model
        values = {model['control_label']: 0.0, model['start_label']: 0.0}
        for index, (time_label, hits_label) in enumerate(model['reads']):
            now = 1259.0 + index * 10.0
            values[time_label] = now
            values[hits_label] = float(sum(1 for hit in range(3) if first + hit * period <= now))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_fixtures_precede_the_cast_and_the_polls_follow_it(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(23), chain_period_entry())
        steps = run.validate(scenario)['steps']
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast')
        self.assertTrue(any(step['action'] == 'set_aura' and step['spell'] == 22856 for step in steps[:cast]))
        self.assertGreater(len(expectation.model['reads']), 100)

    def test_a_one_second_tick_passes_and_a_slower_one_alerts(self):
        self.assertEqual(self.judged(1000.0).status, 'ok')
        self.assertEqual(self.judged(1100.0).status, 'alert')
