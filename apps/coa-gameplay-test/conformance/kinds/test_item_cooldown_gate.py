import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.item_cooldown_gate import item_cooldown_gate_spec
from profile import CASTER, DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict, cycle_one_entry, first_index
from values import ALLY


class ItemCooldownGateTests(unittest.TestCase):
    def entry(self, spell: int) -> dict:
        return next(entry for entry in load_fixture_class_file(23)['behaviours']
                    if entry['spell'] == spell and entry['kind'] == 'item_cooldown_gate')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_an_ally_uses_the_item_before_and_after_its_cooldown(self):
        scenario, expectations = behaviour_scenario(load_fixture_class_file(23), self.entry(803771))
        run.validate(scenario)
        self.assertEqual({player['id'] for player in scenario['players']}, {CASTER, ALLY})
        uses = [step for step in scenario['steps'] if step['action'] == 'use_item']
        self.assertEqual([(step['actor'], step['item']) for step in uses],
                         [(ALLY, 11521), (ALLY, 11521), (ALLY, 11521), (ALLY, 555555)])
        expected = {expectation.label.split(' 11521 ')[1]: expectation.displayed for expectation in expectations}
        self.assertEqual(expected, {'first cast_failure': '0', 'first spell_go_count': '1',
                                    'early cast_failure': '67', 'early spell_go_count': '1',
                                    'ready cast_failure': '0', 'ready spell_go_count': '2',
                                    'shared cast_failure': '67'})
        first = next(index for index, step in enumerate(scenario['steps']) if step['action'] == 'use_item')
        waits = [step['ms'] for step in scenario['steps'][first:] if step['action'] == 'wait']
        self.assertEqual(sum(waits[:2]), 59500)
        self.assertEqual(sum(waits[:4]), 60500)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_an_early_use_that_goes_through_alerts(self):
        _, expectations = behaviour_scenario(load_fixture_class_file(23), self.entry(803777))
        early = next(expectation for expectation in expectations if expectation.label.endswith('early cast_failure'))
        self.assertEqual(judge_behaviour(base_verdict(early), FakeRun({early.label: 0.0}), early).status, 'alert')
        self.assertEqual(judge_behaviour(base_verdict(early), FakeRun({early.label: 67.0}), early).status, 'ok')

    def test_a_shared_item_needs_its_spell(self):
        with self.assertRaises(ValueError):
            item_cooldown_gate_spec({'spell': 1, 'name': 'n', 'quote': 'q', 'item': 2, 'item_spell': 3,
                                     'cooldown_ms': 60000, 'shared_item': 4})


class ItemCooldownGateCombatTests(unittest.TestCase):
    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_suffix_keeps_the_labels_of_one_item_apart(self):
        labels = set()
        for suffix in ('pool_healing_potion', 'pool_mana_potion'):
            _, expectations = behaviour_scenario(load_fixture_class_file(23), cycle_one_entry(803771, suffix))
            labels |= {expectation.label for expectation in expectations}
        _, plain = behaviour_scenario(load_fixture_class_file(23), next(
            entry for entry in load_fixture_class_file(23)['behaviours']
            if entry['spell'] == 803771 and entry['kind'] == 'item_cooldown_gate'))
        labels |= {expectation.label for expectation in plain}
        self.assertEqual(len(labels), 21)
        self.assertIn('803771 item_cooldown_gate 11521 first cast_failure', labels)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_combat_arm_holds_the_cooldown_until_the_combat_ends(self):
        scenario, expectations = behaviour_scenario(load_fixture_class_file(23), cycle_one_entry(803771, 'pool_combat'))
        steps = run.validate(scenario)['steps']
        expected = {expectation.label.split(' pool_combat ')[1]: expectation.displayed for expectation in expectations}
        self.assertEqual(expected, {'combat_start combat': '1', 'first cast_failure': '0',
                                    'first spell_go_count': '1', 'in_combat cast_failure': '67',
                                    'combat_end combat': '0', 'after_combat cast_failure': '67',
                                    'after_combat_early cast_failure': '67', 'after_combat_ready cast_failure': '0'})
        attack = first_index(steps, action='attack')
        kill = first_index(steps, action='cast', spell=501978)
        self.assertLess(attack, first_index(steps, action='use_item'))
        self.assertLess(first_index(steps, action='set_health'), kill)
        uses = [step['item'] for step in steps if step['action'] == 'use_item']
        self.assertEqual(uses, [11521, 555555, 555555, 555555, 555555])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_pooled_use_accepted_in_combat_alerts(self):
        _, expectations = behaviour_scenario(load_fixture_class_file(23), cycle_one_entry(803771, 'pool_combat'))
        held = next(expectation for expectation in expectations if expectation.label.endswith('in_combat cast_failure'))
        self.assertEqual(judge_behaviour(base_verdict(held), FakeRun({held.label: 0.0}), held).status, 'alert')
        self.assertEqual(judge_behaviour(base_verdict(held), FakeRun({held.label: 67.0}), held).status, 'ok')

    def test_the_combat_arm_needs_a_shared_item_and_a_suffix(self):
        with self.assertRaises(ValueError):
            item_cooldown_gate_spec({'spell': 1, 'name': 'n', 'quote': 'q', 'item': 2, 'item_spell': 3,
                                     'cooldown_ms': 60000, 'combat_kill_spell': 501978})
