import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

FIXTURE = [92123, 1, 'caster', 'caster']
AMOUNT = [92123, 2, 4]


def capacity_entry(**changes) -> dict:
    armor = next(entry for entry in load_fixture_class_file(23)['behaviours']
                 if entry['spell'] == 301207 and entry.get('label_suffix') == 'armor')
    entry = {**armor, 'variant': 'capacity_fixture', 'label_suffix': 'capacity_fixture', 'expected': 6,
             'before_expected': 3, 'trigger_spell': 500981, 'metric': 'aura_stacks', 'fields': {'spell': 805011},
             'after_auras': [FIXTURE], 'phase_aura_amounts': [AMOUNT]}
    for key in ('expected_ratio', 'tolerance'):
        entry.pop(key)
    return {**entry, **changes}


def amount_steps(scenario: dict) -> list[int]:
    return [index for index, step in enumerate(scenario['steps'])
            if step['action'] == 'set_aura' and 'amount' in step]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PhaseAuraAmountTests(unittest.TestCase):
    def test_an_after_aura_amount_follows_its_aura_in_the_after_phase_only(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), capacity_entry())
        run.validate(scenario)
        [index] = amount_steps(scenario)
        step = scenario['steps'][index]
        self.assertEqual((step['spell'], step['stacks'], step['effect'], step['amount']), (92123, 1, 2, 4))
        previous = scenario['steps'][index - 1]
        self.assertEqual((previous['action'], previous['spell']), ('set_aura', 92123))
        self.assertNotIn('amount', previous)

    def test_a_phase_aura_amount_is_set_in_both_phases(self):
        entry = capacity_entry(after_auras=[], phase_auras=[FIXTURE])
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(len(amount_steps(scenario)), 2)

    def test_without_the_option_no_amount_is_set(self):
        entry = {key: value for key, value in capacity_entry().items() if key != 'phase_aura_amounts'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(amount_steps(scenario), [])

    def test_an_amount_needs_an_aura_of_the_entry_and_an_effect_0_to_2(self):
        for amounts in ([[92124, 2, 4]], [[92123, 3, 4]]):
            with self.subTest(amounts=amounts), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), capacity_entry(phase_aura_amounts=amounts))

    def test_the_fixture_capacity_passes_and_a_mutant_without_it_alerts(self):
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), capacity_entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        held = judge_behaviour(base_verdict(expectation), FakeRun({before: 3.0, after: 6.0}), expectation)
        self.assertEqual(held.status, 'ok', held.explanation)
        mutant = judge_behaviour(base_verdict(expectation), FakeRun({before: 3.0, after: 3.0}), expectation)
        self.assertEqual(mutant.status, 'alert', mutant.explanation)
