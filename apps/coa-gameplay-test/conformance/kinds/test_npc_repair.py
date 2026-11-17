import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import CASTER, DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict
from values import ALLY


class NpcRepairTests(unittest.TestCase):
    def entry(self, spell: int, kind: str, suffix: str | None = None) -> dict:
        return next(entry for entry in load_fixture_class_file(23)['behaviours']
                    if entry['spell'] == spell and entry['kind'] == kind
                    and (suffix is None or entry.get('label_suffix') == suffix))

    def judged(self, entry: dict, values_of) -> list[str]:
        scenario, expectations = behaviour_scenario(load_fixture_class_file(23), entry)
        return [judge_behaviour(base_verdict(expectation), FakeRun(values_of(expectation)), expectation).status
                for expectation in expectations]

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_the_repair_arms_and_their_expected_durability(self):
        scenario, expectations = behaviour_scenario(load_fixture_class_file(23), self.entry(804681, 'npc_repair'))
        run.validate(scenario)
        self.assertEqual({player['id'] for player in scenario['players']}, {CASTER, ALLY, 'enemy'})
        expected = {expectation.label.split(' npc_repair ')[1]: expectation.displayed for expectation in expectations}
        self.assertEqual(expected, {'caster without 50261 worn': '23', 'caster without 50261 after': '23',
                                    'caster with 50261 worn': '1', 'caster with 50261 after': '45',
                                    'ally with 50261 worn': '23', 'ally with 50261 after': '45',
                                    'enemy with 50261 worn': '23', 'enemy with 50261 after': '23'})
        repairs = [step for step in scenario['steps'] if step['action'] == 'repair_at']
        self.assertEqual([step['actor'] for step in repairs], [CASTER, CASTER, ALLY, 'enemy'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_repair_the_enemy_gets_alerts(self):
        statuses = self.judged(self.entry(804681, 'npc_repair'),
                               lambda expectation: {expectation.label: 45.0 if 'enemy' in expectation.label
                                                    and expectation.label.endswith('after')
                                                    else float(expectation.displayed)})
        self.assertEqual(statuses.count('alert'), 1)
