import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

INNER_DEMON = [804216, 1, 'caster', 'caster']


def folly(**changes) -> dict:
    return {'spell': 805236, 'name': "Grommash's Folly (critical auto attacks heal)", 'kind': 'metric_delta',
            'variant': 'crit_swing_heal', 'label_suffix': 'crit_swing_heal',
            'quote': 'and you now heal equal to $807426s1% of all damage dealt by critical strikes with auto attacks.',
            'trigger_spell': 805236, 'gate_spell': 805236, 'target': 'dummy', 'attack_swings': 4,
            'force_crit': 'melee', 'measure_actor': 'caster', 'metric': 'spell_heal_total',
            'fields': {'spell': 560839, 'target': 'caster'},
            'ratio_to_metric': {'metric': 'melee_damage_total', 'fields': {'critical': True}, 'increments': True},
            'phase_auras': [INNER_DEMON], 'before_expected': 0, 'expected': 0.5, 'tolerance': 0.02,
            'wait_ms': 500, 'expire_ms': 500, **changes}


def generated(entry: dict):
    return behaviour_scenario(load_fixture_class_file(19), entry)


def judged(entry: dict, heal_before: float, heal_after: float, crit_before: float, crit_after: float) -> str:
    _, [expectation] = generated(entry)
    before, after = expectation.model['before_label'], expectation.model['after_label']
    values = {before: heal_before, after: heal_after, f'{before} ratio base': crit_before,
              f'{after} ratio base': crit_after}
    return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AttackSwingPhaseAuraTests(unittest.TestCase):
    def test_each_phase_sets_its_aura_right_before_it_attacks(self):
        scenario, [expectation] = generated(folly())
        run.validate(scenario)
        steps = scenario['steps']
        attacks = [index for index, step in enumerate(steps) if step['action'] == 'attack']
        self.assertEqual(len(attacks), 2)
        for index in attacks:
            self.assertEqual(steps[index - 2:index], [
                {'action': 'set_aura', 'actor': 'caster', 'spell': 804216, 'stacks': 1},
                {'action': 'wait', 'label': 'let the phase auras settle', 'ms': 500}])
        labels = [step.get('label') for step in steps]
        gate = steps.index({'action': 'learn', 'actor': 'caster', 'spell': 805236})
        self.assertLess(labels.index(expectation.model['before_label']), gate)
        self.assertLess(gate, attacks[1])
        self.assertIn("sets the auras [[804216, 1, 'caster', 'caster']] (spell, stacks, on, by) and waits 500 ms",
                      scenario['contract'])

    def test_without_phase_auras_the_swing_scenario_is_unchanged(self):
        plain, _ = generated(folly(phase_auras=[]))
        unset, _ = generated({key: value for key, value in folly().items() if key != 'phase_auras'})
        self.assertEqual(plain, unset)
        self.assertNotIn('set_aura', [step['action'] for step in plain['steps']])
        self.assertNotIn('sets the auras', plain['contract'])

    def test_after_auras_stay_refused_on_attack_swings(self):
        with self.assertRaisesRegex(ValueError, 'attacks the dummy as its trigger'):
            generated(folly(after_auras=[INNER_DEMON]))

    def test_the_heal_share_of_critical_swing_damage_is_judged(self):
        self.assertEqual(judged(folly(), 0, 2000, 4000, 8000), 'ok')
        self.assertEqual(judged(folly(expected=0), 0, 0, 4000, 8000), 'ok')

    def test_mutant_heal_without_the_condition_or_at_another_share_alerts(self):
        for heal_after in (0, 4000, 2000 * 1.1):
            with self.subTest(heal_after=heal_after):
                self.assertEqual(judged(folly(), 0, heal_after, 4000, 8000), 'alert')
        self.assertEqual(judged(folly(expected=0), 0, 2000, 4000, 8000), 'alert')


if __name__ == '__main__':
    unittest.main()
