import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

BEFORE = '681453 shield before'
AFTER = '681453 shield after'
SHIELD = 1200


def shield_entry(**changes) -> dict:
    entry = next(entry for entry in load_class_file(15)['behaviours']
                 if entry.get('spell') == 681453 and entry.get('variant') == 'learn_shield')
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ShieldAfterLearnTests(unittest.TestCase):
    def scenario(self, entry: dict):
        return behaviour_scenario(load_class_file(15), entry)

    def test_the_equip_is_refused_before_the_learn_and_accepted_after_it_with_no_shield_skill_step(self):
        scenario, _ = self.scenario(shield_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        equips = [(index, step) for index, step in enumerate(steps) if step['action'] == 'equip' and step['item'] == SHIELD]
        self.assertEqual([step.get('rejected', False) for _, step in equips], [True, False])
        learn = next(index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 681453)
        self.assertLess(equips[0][0], learn)
        self.assertLess(learn, equips[1][0])
        self.assertEqual(labels.index(BEFORE), equips[0][0] + 1)
        self.assertEqual(labels.index(AFTER), equips[1][0] + 1)
        self.assertEqual(steps[labels.index(AFTER)]['slot'], 16)
        self.assertFalse([step for step in steps if step['action'] == 'set_skill' and step['skill'] == 433])

    def test_a_shield_held_from_the_start_equips_once_before_the_cast(self):
        scenario, _ = self.scenario(shield_entry(shield_after_learn={'item': SHIELD, 'slot': 16,
                                                                     'rejected_before': False}))
        equips = [step for step in scenario['steps'] if step['action'] == 'equip' and step['item'] == SHIELD]
        self.assertEqual([step.get('rejected', False) for step in equips], [False])

    def test_without_the_option_no_shield_step_is_written(self):
        entry = {key: value for key, value in shield_entry().items() if key != 'shield_after_learn'}
        scenario, [expectation] = self.scenario(entry)
        self.assertNotIn('shield_after_learn', expectation.model)
        self.assertFalse([step for step in scenario['steps'] if step.get('item') == SHIELD])

    def test_the_option_names_item_slot_and_a_boolean(self):
        for value in (True, {'item': SHIELD}, {'item': SHIELD, 'slot': 16, 'rejected_before': 1},
                      {'item': '1200', 'slot': 16, 'rejected_before': True}):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.scenario(shield_entry(shield_after_learn=value))

    def test_the_slot_reads_gate_the_judgement(self):
        _, [expectation] = self.scenario(shield_entry())
        after = expectation.model['after_label']

        def judged(before, shield_after) -> str:
            values = {after: 1.0, expectation.model['before_label']: 0.0}
            for label, value in ((BEFORE, before), (AFTER, shield_after)):
                if value is not None:
                    values[label] = value
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(2027, SHIELD), 'ok')
        self.assertEqual(judged(SHIELD, SHIELD), 'alert')
        self.assertEqual(judged(2027, 2027), 'alert')
        self.assertEqual(judged(2027, None), 'unmeasured')


if __name__ == '__main__':
    unittest.main()
