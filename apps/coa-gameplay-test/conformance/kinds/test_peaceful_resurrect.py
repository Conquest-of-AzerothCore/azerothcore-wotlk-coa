import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict
from values import ALLY

ENTRY = {
    'spell': 803624, 'kind': 'peaceful_resurrect', 'variant': 'peaceful', 'name': 'Reclaim Soul',
    'quote': 'Brings a dead ally back to life with $s1 health', 'label_suffix': 'peaceful',
    'claims': [{'claim': 'health', 'quote': 'Brings a dead ally back to life with $s1 health'},
               {'claim': 'mana', 'quote': 'and $q1 mana.'},
               {'claim': 'refusal', 'quote': 'Cannot be cast when in combat.'}]}
SERVER = {'alive_unoffered': 0, 'combat_peaceful': 0, 'cast_failure_peaceful': 0, 'alive_peaceful': 1,
          'health_peaceful': 820, 'mana_peaceful': 1030, 'combat_fighting': 1, 'cast_failure_fighting': 1,
          'alive_fighting': 0}


def reading(name: str) -> str:
    return f'803624 peaceful_resurrect peaceful {name}'


def judged(expectation, **changes):
    values = {reading(name): float(value) for name, value in {**SERVER, **changes}.items()}
    return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PeacefulResurrectTests(unittest.TestCase):
    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(load_class_file(13), ENTRY)
        self.by_claim = {expectation.model['claim']: expectation for expectation in self.expectations}

    def test_the_out_of_combat_arm_runs_before_the_fight(self):
        run.validate(self.scenario)
        steps = self.scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        attack = next(index for index, step in enumerate(steps) if step['action'] == 'attack')
        self.assertEqual(len(casts), 2)
        self.assertLess(casts[0], attack)
        self.assertLess(attack, casts[1])
        self.assertEqual(steps[casts[0] + 1], {'action': 'wait', 'ms': 8500})
        self.assertEqual([step['actor'] for step in steps if step['action'] == 'die'], [ALLY, ALLY])
        self.assertEqual([player['id'] for player in self.scenario['players']], [CASTER, ALLY])
        self.assertEqual([expectation.label for expectation in self.expectations],
                         ['803624 behaviour_cast_combat peaceful health', '803624 behaviour_cast_combat peaceful mana',
                          '803624 behaviour_cast_combat peaceful refusal'])
        self.assertEqual([expectation.displayed for expectation in self.expectations], ['820', '1030', '1'])

    def test_the_server_shape_passes_every_claim(self):
        for claim, expectation in self.by_claim.items():
            with self.subTest(claim=claim):
                self.assertEqual(judged(expectation).status, 'ok')

    def test_a_cast_allowed_in_combat_or_refused_out_of_it_alerts(self):
        self.assertEqual(judged(self.by_claim['refusal'], cast_failure_fighting=0).status, 'alert')
        self.assertEqual(judged(self.by_claim['refusal'], cast_failure_peaceful=1, alive_peaceful=0).status, 'alert')

    def test_a_fighting_arm_that_never_reached_combat_is_unmeasured(self):
        self.assertEqual(judged(self.by_claim['refusal'], combat_fighting=0).status, 'unmeasured')

    def test_other_amounts_or_a_living_unoffered_ally_alert(self):
        self.assertEqual(judged(self.by_claim['health'], health_peaceful=819).status, 'alert')
        self.assertEqual(judged(self.by_claim['mana'], mana_peaceful=1029).status, 'alert')
        self.assertEqual(judged(self.by_claim['health'], alive_unoffered=1).status, 'alert')

    def test_a_missing_reading_keeps_the_alert_of_a_missing_measurement(self):
        values = {reading(name): float(value) for name, value in SERVER.items() if name != 'mana_peaceful'}
        verdict = judge_behaviour(base_verdict(self.by_claim['mana']), FakeRun(values), self.by_claim['mana'])
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('no measurement', verdict.explanation)

    def test_a_spell_usable_in_combat_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_class_file(13), {**ENTRY, 'spell': 801670,
                                                     'quote': 'Brew a potion and then throw it to an ally target',
                                                     'claims': [{'claim': 'health'}]})


if __name__ == '__main__':
    unittest.main()
