import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict
from values import GCD_WAIT_MS

COOLDOWN = {'spell': 300349, 'name': 'Hope (once per sec)', 'kind': 'timer_spacing_arms', 'variant': 'cooldown_cut',
            'label_suffix': 'icd_spacing', 'quote': 'Can occur only once per sec.', 'timer_ms': 1000,
            'gaps': [940, 1050], 'hit_spell': 503624, 'cooldown_spell': 800764, 'cut_spell': 804512,
            'cut_effect': 0, 'caster_health_pct': 30, 'force_crit': 'spell', 'cast_power': 1360}
CHAIN = {'spell': 300371, 'name': 'Censure (once per sec)', 'kind': 'timer_spacing_arms', 'variant': 'chain_copy',
         'label_suffix': 'icd_spacing', 'quote': 'Can only occur once per sec.', 'timer_ms': 1000,
         'gaps': [940, 1050], 'hit_spell': 572801, 'seed_spell': 801524, 'aura_spell': 806697, 'spares': 6,
         'radius': 10.0, 'cast_power': 1360}
STEP_MS = 3.0


class TimedRun(FakeRun):
    def __init__(self, values, steps):
        super().__init__(values, STEP_MS)
        self.steps = steps


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TimerSpacingArmsTests(unittest.TestCase):
    def generated(self, entry):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, expectation

    def cooldown_run(self, cuts, spacings=(950.0, 1060.0), crits=(2, 2), opened=2.0):
        scenario, expectation = self.generated(COOLDOWN)
        reads, values, steps = expectation.model['reads'], {}, []
        planned = dict(zip(('blocked', 'allowed'), zip(cuts, spacings, crits)))
        elapsed = 0.0
        for step in scenario['steps']:
            label = step.get('label')
            record = {'label': label, 'action': step['action'], 'elapsed_ms': float(step.get('ms', 0))}
            steps.append(record)
            elapsed += record['elapsed_ms']
            for name, (cut, spacing, crit) in planned.items():
                if label == reads[name]['cooldown_start']:
                    elapsed = 0.0
                if label == reads[name]['cooldown']:
                    values[label] = 30000 - elapsed - 1000 * cut
                if label == reads[name]['spacing']:
                    values[label] = spacing
                if label == reads[name]['opened']:
                    values[label] = 1.0 if name == 'blocked' else opened
                if label in reads[name]['start']:
                    values[label] = 0.0
                if label in reads[name]['end']:
                    values[label] = float(crit)
        return judge_behaviour(base_verdict(expectation), TimedRun(values, steps), expectation)

    def chain_run(self, copies, spacings=(950.0, 1060.0)):
        _, expectation = self.generated(CHAIN)
        reads, values = expectation.model['reads'], {}
        held = 0
        for name, gained, spacing in zip(('blocked', 'allowed'), copies, spacings):
            for index, label in enumerate(reads[name]['start']):
                values[label] = 1.0 if index < held else 0.0
            for index, label in enumerate(reads[name]['end']):
                values[label] = 1.0 if index < held + gained else 0.0
            values[reads[name]['spacing']] = spacing
            values[reads[name]['opened']] = 1.0 if name == 'blocked' else 2.0
            held += gained
        return judge_behaviour(base_verdict(expectation), FakeRun(values, STEP_MS), expectation)

    def test_both_scenarios_validate_and_cast_the_second_hit_with_ignore_gcd(self):
        for entry in (COOLDOWN, CHAIN):
            with self.subTest(variant=entry['variant']):
                scenario, _ = self.generated(entry)
                run.validate(scenario)
                hits = [step for step in scenario['steps']
                        if step['action'] == 'cast' and step['spell'] == entry['hit_spell']]
                self.assertEqual([bool(step.get('ignore_gcd')) for step in hits], [False, True, False, True])
                gaps = [step['ms'] for step in scenario['steps'] if step['action'] == 'wait'
                        and step.get('label', '').endswith(' gap')]
                self.assertEqual(gaps, entry['gaps'])

    def test_one_cut_blocked_and_two_allowed_is_ok(self):
        self.assertEqual(self.cooldown_run((1, 2)).status, 'ok')

    def test_mutant_without_the_timer_alerts(self):
        self.assertEqual(self.cooldown_run((2, 2)).status, 'alert')

    def test_mutant_with_a_longer_timer_alerts(self):
        self.assertEqual(self.cooldown_run((1, 1)).status, 'alert')

    def test_a_spacing_outside_its_band_is_unmeasured(self):
        self.assertEqual(self.cooldown_run((1, 2), spacings=(1001.0, 1060.0)).status, 'unmeasured')
        self.assertEqual(self.cooldown_run((1, 2), spacings=(950.0, 1101.0)).status, 'unmeasured')

    def test_a_refused_opening_cast_is_unmeasured(self):
        self.assertEqual(self.cooldown_run((1, 2), opened=1.0).status, 'unmeasured')

    def test_the_next_arm_opens_after_the_global_cooldown_of_the_second_hit(self):
        for entry in (COOLDOWN, CHAIN):
            with self.subTest(variant=entry['variant']):
                scenario, _ = self.generated(entry)
                waits = [step['ms'] for step in scenario['steps']
                         if step['action'] == 'wait' and step.get('label', '').endswith(' hits')]
                self.assertTrue(waits and all(wait >= GCD_WAIT_MS for wait in waits))

    def test_a_non_critical_heal_is_unmeasured(self):
        self.assertEqual(self.cooldown_run((1, 2), crits=(1, 2)).status, 'unmeasured')

    def test_chain_copies_follow_the_timer(self):
        self.assertEqual(self.chain_run((1, 2)).status, 'ok')
        self.assertEqual(self.chain_run((2, 2)).status, 'alert')
        self.assertEqual(self.chain_run((1, 1)).status, 'alert')
        self.assertEqual(self.chain_run((1, 2), spacings=(899.0, 1060.0)).status, 'unmeasured')

    def test_a_missing_read_is_unmeasured(self):
        _, expectation = self.generated(CHAIN)
        verdict = judge_behaviour(base_verdict(expectation), FakeRun({}, STEP_MS), expectation)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_gaps_must_bracket_the_timer(self):
        for gaps in ([1000, 1050], [940, 1000], [899, 1050], [940, 1101], [940]):
            with self.subTest(gaps=gaps), self.assertRaises(ValueError):
                self.generated({**COOLDOWN, 'gaps': gaps})


    def control_run(self, control_copies, copies=(1, 2), control_spacing=1060.0, control_opened=1.0):
        _, expectation = self.generated({**CHAIN, 'variant': 'chain_control', 'label_suffix': 'chain_control'})
        model = expectation.model
        control, reads, values = model['control'], model['reads'], {}
        for index, label in enumerate(control['start']):
            values[label] = 0.0
        for index, label in enumerate(control['end']):
            values[label] = 1.0 if index < control_copies else 0.0
        values[control['spacing']], values[control['opened']] = control_spacing, control_opened
        held = control_copies
        for count, (name, gained) in enumerate(zip(('blocked', 'allowed'), copies), 2):
            for index, label in enumerate(reads[name]['start']):
                values[label] = 1.0 if index < held else 0.0
            for index, label in enumerate(reads[name]['end']):
                values[label] = 1.0 if index < held + gained else 0.0
            values[reads[name]['spacing']] = 950.0 if name == 'blocked' else 1060.0
            values[reads[name]['opened']] = float(count)
            held += gained
        return judge_behaviour(base_verdict(expectation), FakeRun(values, STEP_MS), expectation)

    def test_the_control_arm_runs_before_the_learn(self):
        scenario, expectation = self.generated({**CHAIN, 'variant': 'chain_control', 'label_suffix': 'chain_control'})
        run.validate(scenario)
        steps, labels = scenario['steps'], [step.get('label') for step in scenario['steps']]
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == CHAIN['spell'])
        self.assertLess(labels.index(expectation.model['control']['opened']), learn)
        hits = [step for step in steps if step['action'] == 'cast' and step['spell'] == CHAIN['hit_spell']]
        self.assertEqual(len(hits), 6)
        self.assertEqual(expectation.label, '300371 behaviour_metric_delta chain_control')

    def test_no_copy_before_the_learn_and_the_timer_arms_is_ok(self):
        self.assertEqual(self.control_run(0).status, 'ok')

    def test_a_mutant_that_chains_without_the_passive_alerts(self):
        verdict = self.control_run(1)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('control arm without 300371', verdict.explanation)

    def test_a_mutant_that_never_chains_alerts(self):
        self.assertEqual(self.control_run(0, copies=(0, 0)).status, 'alert')

    def test_a_control_arm_outside_its_band_or_not_opened_is_unmeasured(self):
        self.assertEqual(self.control_run(0, control_spacing=1000.0).status, 'unmeasured')
        self.assertEqual(self.control_run(0, control_opened=0.0).status, 'unmeasured')

    def test_the_chain_copy_variant_has_no_control_arm(self):
        _, expectation = self.generated(CHAIN)
        self.assertNotIn('control', expectation.model)


if __name__ == '__main__':
    unittest.main()
