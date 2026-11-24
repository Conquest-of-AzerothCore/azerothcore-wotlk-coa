import json
import unittest
from pathlib import Path

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

SOURCE = ('504580 EquippedItemClass 4 with EquippedItemSubClassMask 64 (shield), refused through Spell::CheckItems '
          'HasItemFitToSpellRequirements, Spell.cpp:7539-7541, as SPELL_FAILED_EQUIPPED_ITEM_CLASS 29')


def class_file() -> dict:
    return json.load(open(Path(__file__).resolve().parents[1] / 'classes' / 'sun_cleric.json'))


def entry(**changes) -> dict:
    base = next(item for item in class_file()['behaviours']
                if item['spell'] == 504580 and item.get('label_suffix') == 'damage')
    kept = {key: value for key, value in base.items()
            if key not in ('after_at_least', 'after_at_most', 'phase_auras', 'fields', 'expected', 'wait_ms',
                           'expire_ms')}
    kept.update({'variant': 'no_shield', 'label_suffix': 'no_shield', 'learn': [504580], 'cast_in_before': True,
                 'metric': 'cast_failure', 'fields': {'spell': 504580}, 'before_expected': 0, 'expected': 29,
                 'wait_ms': 2000, 'expire_ms': 500, 'without_item': {'item': 2129, 'source': SOURCE}})
    return {**kept, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class WithoutItemTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(class_file(), entry(**changes))

    def test_the_item_is_destroyed_only_before_the_second_cast(self):
        scenario, _ = self.build()
        steps = run.validate(scenario)['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 504580]
        destroyed = [index for index, step in enumerate(steps) if step['action'] == 'destroy_item']
        equipped = [index for index, step in enumerate(steps) if step['action'] == 'equip' and step['item'] == 2129]
        self.assertEqual(len(casts), 2)
        self.assertEqual(destroyed, [casts[1] - 1])
        self.assertEqual(steps[casts[1] - 2]['action'], 'reset_cooldown')
        self.assertEqual(steps[casts[1] - 2]['spell'], 504580)
        self.assertTrue(equipped and equipped[0] < casts[0])

    def test_without_the_option_nothing_is_destroyed(self):
        entry_without = {key: value for key, value in entry().items() if key != 'without_item'}
        scenario, _ = behaviour_scenario(class_file(), entry_without)
        self.assertFalse(any(step['action'] == 'destroy_item' for step in scenario['steps']))

    def test_malformed_options_are_refused(self):
        for option in ({'item': 2129}, {'item': 0, 'source': SOURCE}, {'item': 2129, 'source': 'short'},
                       {'item': True, 'source': SOURCE}, 'item'):
            with self.subTest(option=option), self.assertRaises(ValueError):
                self.build(without_item=option)
        for changes in ({'metric': 'spell_damage_count', 'fields': {'spell': 504580, 'target': 'dummy'}},
                        {'cast_in_before': False}, {'without_item': {'item': 99999, 'source': SOURCE}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.build(**changes)

    def judged(self, before, after):
        _, [expectation] = self.build()
        values = {expectation.model['before_label']: before, expectation.model['after_label']: after}
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_refused_with_the_class_failure_only_without_the_shield(self):
        self.assertEqual(self.judged(0.0, 29.0).status, 'ok')

    def test_seeded_mutants_alert(self):
        self.assertEqual(self.judged(0.0, 0.0).status, 'alert')
        self.assertEqual(self.judged(29.0, 29.0).status, 'alert')
        self.assertEqual(self.judged(0.0, 31.0).status, 'alert')


if __name__ == '__main__':
    unittest.main()
