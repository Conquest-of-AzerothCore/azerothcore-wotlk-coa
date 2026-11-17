import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

DAZED = {'aura': 1604, 'entry': 50073, 'source': 'Dazed, the striker melee from behind'}


def snare_entry(**changes) -> dict:
    entry = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry.get('spell') == 503740 and entry.get('variant') == 'snare_control')
    return {**entry, 'strike_landed': True, 'before_aura_absent': DAZED, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BeforeAuraAbsentTests(unittest.TestCase):
    def test_the_aura_is_read_right_before_the_before_reading(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        label = expectation.model['before_aura_absent']['read_label']
        read = scenario['steps'][labels.index(label)]
        self.assertEqual(labels.index(label) + 1, labels.index(expectation.model['before_label']))
        self.assertEqual((read['metric'], read['spell'], read['entry']),
                         ('owned_creature_aura_max_duration_ms', 1604, 50073))

    def test_without_the_option_nothing_is_read(self):
        entry = {key: value for key, value in snare_entry().items() if key != 'before_aura_absent'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('before_aura_absent', expectation.model)
        self.assertFalse(any(step.get('metric') == 'owned_creature_aura_max_duration_ms'
                             for step in scenario['steps']))

    def test_the_option_needs_an_aura_an_entry_and_a_source(self):
        for raw in (True, {'aura': 1604, 'entry': 50073}, {**DAZED, 'source': ''}, {**DAZED, 'aura': '1604'}):
            with self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), snare_entry(before_aura_absent=raw))

    def test_a_held_aura_is_unmeasured_and_an_absent_one_is_judged(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), snare_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        logs = expectation.model['strike_landed']['log_label']
        held = expectation.model['before_aura_absent']['read_label']

        def judged(before_value: float, duration: float | None) -> str:
            values = {before: before_value, after: 0.57143, logs: 4}
            if duration is not None:
                values[held] = duration
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(1.14286, 0), 'ok')
        self.assertEqual(judged(0.57143, 0), 'alert')
        self.assertEqual(judged(0.57143, 4000), 'unmeasured')
        self.assertEqual(judged(1.14286, None), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
