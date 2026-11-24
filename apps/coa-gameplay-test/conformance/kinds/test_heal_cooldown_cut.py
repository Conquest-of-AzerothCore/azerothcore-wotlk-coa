import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

TALENT = 802219
POTION = 801661
BEAM = 500950
CLASS_FILE = {'class_id': 13, 'name': 'Witch Doctor', 'race': 1, 'level': 60, 'skill_lines': [],
              'reference_stats': {}}
QUOTE = 'Effective healing done by Mojo Beam now reduces the cooldown of Potion Toss and Splash Potion by 1 sec.'
ENTRY = {'spell': TALENT, 'name': "Splash On 'Em (Mojo Beam heals cut the Potion Toss cooldown)",
         'kind': 'heal_cooldown_cut', 'label_suffix': 'beam_potion', 'quote': QUOTE, 'talent': TALENT,
         'gated_spell': POTION, 'cooldown_ms': 15000, 'heal_spell': BEAM, 'heal_ms': 3000, 'expected_cut_ms': 1000,
         'learn': [92085, 801664], 'setup_casts': [[801664, 'caster']], 'cast_power': 2000, 'health_pct': 1,
         'first_attempt_ms': 6500, 'last_attempt_ms': 12000, 'attempt_step_ms': 100}


def arm_values(arm: dict, cut_ms: float, heals: int, overheal: float = 0.0, offset_ms: float = 10.0,
               step_ms: float = 100.0, refusal: float = 67.0) -> dict:
    values = {arm['primed']['result']: 0.0, arm['primed']['time']: 1000.0, arm['primed']['heals']: 0.0,
              arm['primed']['healed']: 0.0, arm['primed']['effective']: 0.0,
              arm['stopped']['heals']: float(heals), arm['stopped']['healed']: 150.0 * heals,
              arm['stopped']['effective']: 150.0 * heals - overheal}
    cast = False
    for index, (result, time, counted) in enumerate(arm['attempts']):
        elapsed = 6500.0 + step_ms * index + offset_ms
        ready = not cast and elapsed + cut_ms * heals >= 15000.0
        values[result] = 0.0 if ready else refusal
        cast = cast or ready
        values[time] = 1000.0 + elapsed
        values[counted] = float(heals)
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class HealCooldownCutTests(unittest.TestCase):
    def judged(self, cut_ms=1000.0, control_cut_ms=0.0, heals=6, overheal=0.0, entry=ENTRY,
               ineffective_cut_ms=0.0, ineffective_overheal=None, control_refusal=67.0):
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        arms = expectation.model['arms']
        values = {**arm_values(arms['control'], control_cut_ms, heals, refusal=control_refusal),
                  **arm_values(arms['treatment'], cut_ms, heals, overheal)}
        if 'ineffective' in arms:
            values.update(arm_values(arms['ineffective'], ineffective_cut_ms, heals,
                                     150.0 * heals if ineffective_overheal is None else ineffective_overheal,
                                     step_ms=500.0))
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_talent_is_learned_between_the_arms_and_the_beam_is_cancelled_before_the_attempts(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, ENTRY)
        run.validate(scenario, run.SIMULATED_CLOCK)
        actions = [(step['action'], step.get('spell')) for step in scenario['steps']]
        beams = [index for index, action in enumerate(actions) if action == ('cast', BEAM)]
        cancels = [index for index, action in enumerate(actions) if action == ('cancel_aura', BEAM)]
        learn = actions.index(('learn', TALENT))
        self.assertEqual(len(beams), 3)
        self.assertLess(beams[0], learn)
        self.assertLess(learn, beams[1])
        self.assertTrue(all(beam < cancel for beam, cancel in zip(beams, cancels)))
        health = [step['value'] for step in scenario['steps'] if step['action'] == 'set_health']
        self.assertEqual(health, [100, 100, 10000])

    def test_a_second_per_heal_passes(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 1000.0, delta=20.0)

    def test_the_mutant_with_half_a_second_per_heal_alerts(self):
        self.assertEqual(self.judged(cut_ms=500.0).status, 'alert')

    def test_the_mutant_without_a_cut_alerts(self):
        self.assertEqual(self.judged(cut_ms=0.0).status, 'alert')

    def test_a_cut_without_the_talent_alerts(self):
        self.assertEqual(self.judged(control_cut_ms=1000.0).status, 'alert')

    def test_the_mutant_that_cuts_on_overhealing_heals_alerts(self):
        verdict = self.judged(ineffective_cut_ms=1000.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('overhealing', verdict.explanation)

    def test_an_ineffective_arm_that_healed_effectively_is_unmeasured(self):
        self.assertEqual(self.judged(ineffective_overheal=0.0).status, 'unmeasured')

    def test_a_control_refusal_other_than_not_ready_is_unmeasured(self):
        verdict = self.judged(control_refusal=173.0)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('not 67', verdict.explanation)

    def test_without_effective_only_there_is_no_ineffective_arm(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, {**ENTRY, 'effective_only': False})
        self.assertNotIn('ineffective', expectation.model['arms'])
        self.assertEqual(self.judged(entry={**ENTRY, 'effective_only': False}).status, 'ok')

    def test_an_overhealed_arm_is_unmeasured(self):
        self.assertEqual(self.judged(overheal=40.0).status, 'unmeasured')

    def test_a_cooldown_already_cleared_at_the_first_attempt_is_unmeasured(self):
        self.assertEqual(self.judged(heals=16, cut_ms=1000.0).status, 'unmeasured')

    def test_a_stated_cooldown_other_than_the_dbc_recovery_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**ENTRY, 'cooldown_ms': 14000})

    def test_attempts_that_miss_the_expected_recast_are_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**ENTRY, 'first_attempt_ms': 9500})
