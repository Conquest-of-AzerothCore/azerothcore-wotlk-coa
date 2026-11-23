import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 704721, 'name': 'Study of Death (0.5 sec per minion damage event)', 'kind': 'cooldown_clear_time',
         'label_suffix': 'clear_time',
         'quote': 'Frost and Physical damage dealt by your Undead minions now reduces the cooldown of Unholy Frenzy by '
                  '$/1000;302597S1 sec.',
         'raise_spell': 500971, 'minion_entry': 50073, 'observe_spell': 805029, 'observe_power': 1373,
         'cooldown_ms': 180000, 'expected_cut_ms': 500, 'first_attempt_ms': 100000, 'last_attempt_ms': 175000,
         'attempt_step_ms': 1000}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CooldownClearTimeTests(unittest.TestCase):
    def judged(self, cut_ms: float, hits_per_second: float = 0.5) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        model = expectation.model
        values = {model['primed']: 0.0, model['start'][0]: 1000.0, model['start'][1]: 0.0}
        cleared = False
        for index, (result, time, events) in enumerate(model['attempts']):
            elapsed = 100000.0 + 1000.0 * index + 10.0
            hits = int(elapsed / 1000.0 * hits_per_second)
            ready = not cleared and elapsed + cut_ms * hits >= 180000.0
            values[result] = 0.0 if ready else 67.0
            cleared = cleared or ready
            values[time] = 1000.0 + elapsed
            values[events] = float(hits)
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_talent_is_learned_after_the_priming_cast(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), ENTRY)
        run.validate(scenario)
        actions = [(step['action'], step.get('spell')) for step in scenario['steps']]
        self.assertLess(actions.index(('cast', 805029)), actions.index(('learn', 704721)))

    def test_half_a_second_per_event_passes(self):
        self.assertEqual(self.judged(500.0).status, 'ok')

    def test_a_full_second_per_event_alerts(self):
        self.assertEqual(self.judged(1000.0).status, 'alert')

    def test_a_cooldown_cleared_before_the_attempts_is_unmeasured(self):
        self.assertEqual(self.judged(3000.0).status, 'unmeasured')
