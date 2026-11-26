import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.equip_grant import equip_grant_spec
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

GRANT = 707072
PAIRS = [{'main_hand': 2524, 'off_hand': 30754, 'skill_line': 54, 'source': 'a seeded one-hand pair'},
         {'main_hand': 2529, 'off_hand': 2529, 'skill_line': 55, 'source': 'a seeded two-hand sword pair'}]


def entry(**changes) -> dict:
    return {'spell': GRANT, 'name': 'Seeded grant', 'kind': 'equip_grant', 'quote': 'Allows you to dual wield',
            'pairs': PAIRS, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class EquipGrantTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(19), entry(**changes))

    def test_the_off_hand_is_refused_unlearned_and_accepted_after_the_learn(self):
        scenario, [expectation] = self.built()
        steps = run.validate(scenario)['steps']
        actions = [(step['action'], step.get('spell') or step.get('item'), step.get('slot'), step.get('rejected'))
                   for step in steps if step['action'] in ('learn', 'unlearn', 'equip')
                   and (step.get('spell') == GRANT or step.get('item') in (2524, 30754, 2529))]
        unlearn = actions.index(('unlearn', GRANT, None, None))
        learn = actions.index(('learn', GRANT, None, None))
        self.assertLess(unlearn, learn)
        refused = [action for action in actions[unlearn:learn] if action[3]]
        self.assertEqual(refused, [('equip', 30754, 16, True), ('equip', 2529, 16, True)])
        self.assertFalse(any(action[3] for action in actions[learn:]))
        learned = steps[next(index for index, step in enumerate(steps)
                             if step['action'] == 'learn' and step.get('spell') == GRANT):]
        self.assertNotIn('add_item', [step['action'] for step in learned])
        self.assertEqual(expectation.label, f'{GRANT} behaviour_metric_delta equip')
        self.assertEqual(len(expectation.model['pairs']), 2)

    def values(self, expectation, learned_off=None, unlearned_off=None) -> dict:
        values = {}
        for pair in expectation.model['pairs']:
            values[pair['reads']['unlearned'][0]] = pair['main_hand']
            values[pair['reads']['unlearned'][1]] = 2129 if unlearned_off is None else unlearned_off
            values[pair['reads']['learned'][0]] = pair['main_hand']
            values[pair['reads']['learned'][1]] = pair['off_hand'] if learned_off is None else learned_off
        return values

    def test_refused_then_held_is_ok(self):
        _, [expectation] = self.built()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(expectation)), expectation)
        self.assertEqual((verdict.status, verdict.measured), ('ok', 2.0))

    def test_mutant_a_grant_that_never_lands_or_no_refusal_alerts(self):
        _, [expectation] = self.built()
        for values in (self.values(expectation, learned_off=0),
                       {**self.values(expectation), expectation.model['pairs'][1]['reads']['unlearned'][1]: 2529}):
            with self.subTest(values=sorted(values.items())[:1]):
                verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
                self.assertEqual(verdict.status, 'alert')

    def test_a_missing_read_is_not_ok_and_bad_pairs_are_refused(self):
        _, [expectation] = self.built()
        values = self.values(expectation)
        values.pop(expectation.model['pairs'][0]['reads']['learned'][1])
        self.assertNotEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'ok')
        for pairs in ([], [{**PAIRS[0], 'skill_line': 0}], [{**PAIRS[0], 'source': ' '}], [{**PAIRS[0], 'extra': 1}]):
            with self.subTest(pairs=pairs), self.assertRaisesRegex(ValueError, 'equip_grant'):
                equip_grant_spec(entry(pairs=pairs))


if __name__ == '__main__':
    unittest.main()
