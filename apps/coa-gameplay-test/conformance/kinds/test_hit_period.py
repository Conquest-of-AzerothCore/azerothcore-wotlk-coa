import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import CASTER, DBC_DIR, load_class_file, load_fixture_class_file
import run
from test_behaviours import FakeRun


ECLIPSE_PERIOD = {
    'spell': 811117, 'kind': 'hit_period', 'variant': 'eclipse_period', 'label_suffix': 'eclipse_period',
    'name': 'Spirit Eclipse', 'quote': 'every $t1 sec', 'trigger_spell': 811117, 'hit_spell': 802717,
    'expected_ms': 250, 'window': [50, 2000],
    'setup_casts': [{'actor': 'caster', 'spell': 501136, 'target': 'caster', 'wait_ms': 1700},
                    {'actor': 'dummy', 'spell': 132, 'target': 'dummy', 'wait_ms': 300}]}


def chain_period_entry() -> dict:
    return next(entry for entry in load_fixture_class_file(23)['behaviours']
                if entry['kind'] == 'hit_period' and entry['label_suffix'] == 'chain_period')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class HitPeriodTests(unittest.TestCase):
    def judged(self, period: float, first: float = 1330.0) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), chain_period_entry())
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
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), chain_period_entry())
        steps = run.validate(scenario)['steps']
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast')
        self.assertTrue(any(step['action'] == 'set_aura' and step['spell'] == 22856 for step in steps[:cast]))
        self.assertGreater(len(expectation.model['reads']), 100)

    def test_a_one_second_tick_passes_and_a_slower_one_alerts(self):
        self.assertEqual(self.judged(1000.0).status, 'ok')
        self.assertEqual(self.judged(1100.0).status, 'alert')

    def test_setup_casts_follow_the_control_read_and_precede_the_trigger(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(13), ECLIPSE_PERIOD)
        steps = run.validate(scenario)['steps']
        casts = [(step['actor'], step['spell']) for step in steps if step['action'] == 'cast']
        self.assertEqual(casts, [(CASTER, 501136), ('dummy', 132), (CASTER, 811117)])
        control = next(index for index, step in enumerate(steps) if step.get('label') == expectation.model[
            'control_label'])
        mirage = next(index for index, step in enumerate(steps) if step.get('spell') == 501136
                      and step['action'] == 'cast')
        self.assertLess(control, mirage)
        self.assertTrue(any(step['action'] == 'learn' and step['spell'] == 501136 for step in steps[:control]))
        self.assertIn('real setup casts', scenario['contract'])

    def test_no_setup_casts_leaves_the_scenario_unchanged(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), chain_period_entry())
        self.assertNotIn('setup', scenario['contract'])
        self.assertEqual(sum(step['action'] == 'learn' for step in scenario['steps']), 1)

    def test_a_setup_cast_by_another_actor_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_class_file(13), {**ECLIPSE_PERIOD, 'setup_casts': [
                {'actor': 'ally', 'spell': 132, 'target': 'dummy', 'wait_ms': 300}]})

    def test_learn_adds_learned_spells_before_the_control_read(self):
        entry = {**ECLIPSE_PERIOD, 'setup_casts': [], 'learn': [560545]}
        scenario, _ = behaviour_scenario(load_class_file(13), entry)
        learned = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learned, [811117, 560545])
        self.assertIn('[560545] learned at the start', scenario['contract'])
