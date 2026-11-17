import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

PROOF = '801343 before_absent_recipient count'
PRESENT = '801343 before_absent_recipient present'


def share_entry(**changes) -> dict:
    entry = next(entry for entry in load_class_file(15)['behaviours']
                 if entry.get('spell') == 801343 and entry.get('variant') == 'hound_heal_share')
    return {**entry, **changes}


def without_option(**changes) -> dict:
    return {key: value for key, value in share_entry(**changes).items() if key != 'before_absent_recipient'}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class BeforeAbsentRecipientTests(unittest.TestCase):
    def scenario(self, entry: dict):
        return behaviour_scenario(load_class_file(15), entry)

    def test_the_before_read_becomes_a_recipient_count_and_the_after_read_needs_the_hound(self):
        scenario, [expectation] = self.scenario(share_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        before, after = expectation.model['before_label'], expectation.model['after_label']
        self.assertNotIn(before, labels)
        proof = steps[labels.index(PROOF)]
        self.assertEqual((proof['action'], proof['metric'], proof['entry']),
                         ('assert', 'owned_creature_count', 50124))
        present = steps[labels.index(PRESENT)]
        self.assertEqual((present['action'], present['metric'], present['entry'], present['equals']),
                         ('assert', 'owned_creature_count', 50124, 1))
        self.assertEqual(labels.index(PRESENT) + 1, labels.index(after))
        read = steps[labels.index(after)]
        self.assertEqual((read['metric'], read['spell'], read['target'], read['target_pet']),
                         ('spell_heal_total', 574335, 'caster', True))

    def test_without_the_option_the_before_read_stays(self):
        entry = without_option(fields={'spell': 574335})
        scenario, [expectation] = self.scenario(entry)
        labels = [step.get('label') for step in scenario['steps']]
        self.assertNotIn('before_absent_recipient', expectation.model)
        self.assertIn(expectation.model['before_label'], labels)
        self.assertFalse({PROOF, PRESENT} & set(labels))

    def test_the_option_is_true_and_only_on_a_target_pet_total_with_the_summon_withheld_before(self):
        fields = {'spell': 574335, 'target': 'caster', 'target_pet': True}
        for changes in ({'before_absent_recipient': 1}, {'before_absent_recipient': {'entry': 50124}},
                        {'fields': {'spell': 574335}}, {'fields': {**fields, 'target_pet': False}},
                        {'fields': {'spell': 574335, 'target_pet': True}},
                        {'metric': 'spell_heal_count'}, {'setup_only_after': False},
                        {'setup_casts': [681220]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.scenario(share_entry(**changes))

    def test_the_proof_read_gates_the_zero_before_value(self):
        _, [expectation] = self.scenario(share_entry())
        after = expectation.model['after_label']

        def judged(after_value: float, count: float | None) -> str:
            values = {after: after_value}
            if count is not None:
                values[PROOF] = count
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(500, 0), 'ok')
        self.assertEqual(judged(250, 0), 'alert')
        self.assertEqual(judged(500, 1), 'alert')
        self.assertEqual(judged(500, None), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
