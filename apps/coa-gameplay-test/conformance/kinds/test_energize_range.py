import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


class EnergizeRangeTests(unittest.TestCase):
    def built(self):
        entry = next(entry for entry in load_fixture_class_file(23)['behaviours'] if entry['kind'] == 'energize_range')
        return behaviour_scenario(load_fixture_class_file(23), entry)

    def judged(self, amounts: list[int]) -> str:
        _, [expectation] = self.built()
        marks = expectation.model['marks']
        values, total, count = {}, 0.0, 0.0
        for index, (total_label, count_label) in enumerate(marks):
            if 0 < index <= len(amounts):
                total, count = total + amounts[index - 1], count + 1
            values[total_label], values[count_label] = total, count
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_every_poll_reads_the_energize_total_and_count(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        self.assertEqual(len(expectation.model['marks']), 1 + 160 * 13)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_both_ends_inside_the_roll_are_ok_and_a_missing_end_or_an_outlier_alerts(self):
        full = [30 + index % 51 for index in range(400)]
        self.assertEqual(self.judged(full), 'ok')
        self.assertEqual(self.judged([amount if amount != 80 else 79 for amount in full]), 'alert')
        self.assertEqual(self.judged(full[:-1] + [81]), 'alert')
        self.assertEqual(self.judged(full[:100]), 'unmeasured')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_learned_talent_is_learned_after_the_cast_spell_and_its_shifted_roll_is_judged(self):
        base = next(entry for entry in load_fixture_class_file(23)['behaviours'] if entry['kind'] == 'energize_range')
        entry = {**base, 'learn': [704528], 'low': 50, 'high': 100}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        learned = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learned[-2:], [801724, 704528])
        marks = expectation.model['marks']

        def judged(amounts: list[int]) -> str:
            values, total, count = {}, 0.0, 0.0
            for index, (total_label, count_label) in enumerate(marks):
                if 0 < index <= len(amounts):
                    total, count = total + amounts[index - 1], count + 1
                values[total_label], values[count_label] = total, count
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged([50 + index % 51 for index in range(400)]), 'ok')
        self.assertEqual(judged([30 + index % 51 for index in range(400)]), 'alert')
        without = {key: value for key, value in base.items() if key != 'learn'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), without)
        self.assertNotIn(704528, [step.get('spell') for step in scenario['steps'] if step['action'] == 'learn'])
