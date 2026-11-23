import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

SHOTS = 15
BASE = 150.0
PLAIN, BLOCKED, LOST = 'plain', 'blocked', 'lost'


def ramp_entry(**changes) -> dict:
    return {'spell': 706240, 'name': 'Arbalest Mastery (per-shot ramp)', 'kind': 'shot_ramp',
            'label_suffix': 'witchbane_ramp',
            'quote': 'Each subsequent shot of a Witchbane cast deals $706241s1% more damage,',
            'cast_spell': 574320, 'shot_spell': 704342, 'stack_spell': 706241, 'shots_per_cast': 5,
            'dummy_distance': 17.5, 'caster_auras': [680486, 823764], 'target_auras': [33143], 'learn': [574320],
            **changes}


def ramped(per_stack: float = 0.15, cap: int = 10, base: float = BASE) -> list[float]:
    return [float(round(base * (1 + per_stack * min(shot, cap)))) for shot in range(SHOTS)]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ShotRampTests(unittest.TestCase):
    def expectations(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), ramp_entry(**changes))

    def judged(self, control: list, treatment: list[list], known=(0.0, 1.0), measure: int = 0,
               stacks=(0.0, 10.0)) -> Verdict:
        _, expectations = self.expectations()
        expectation = expectations[measure]
        model = expectation.model
        values = {model['known']['control']: known[0], model['known']['treatment']: known[1]}
        for arm, count in zip(('control', 'treatment'), stacks):
            values.update(dict.fromkeys(model['stacks'][arm], count))
        totals = [0.0, 0.0, 0.0]
        for arm, sequences in (('control', [control]), ('treatment', treatment)):
            for rows, shots in zip(model['reads'][arm], sequences):
                for labels, shot in zip(rows, [None, *shots]):
                    if shot is not None:
                        amount, outcome = shot if isinstance(shot, tuple) else (shot, PLAIN)
                        if outcome != LOST:
                            totals[2] += 1 if outcome != 'double' else 2
                        if outcome == PLAIN:
                            totals[0] += amount
                            totals[1] += 1
                    for label, value in zip(labels, totals):
                        values[label] = value
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_grid_reads_between_landings_and_the_talent_follows_the_control(self):
        scenario, expectations = self.expectations()
        run.validate(scenario)
        self.assertEqual([expectation.label for expectation in expectations],
                         ['706240 behaviour_metric_delta witchbane_ramp',
                          '706240 behaviour_metric_delta witchbane_ramp_max'])
        model = expectations[0].model
        self.assertEqual((model['per_stack'], model['cap']), (0.15, 10))
        self.assertEqual(len(model['reads']['treatment']), 4)
        self.assertEqual(len(model['reads']['control'][0]), SHOTS + 1)
        steps = scenario['steps']
        learned = [index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 706240]
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 3 * 5)
        self.assertEqual(len([index for index in casts if index < learned[0]]), 3)
        clock, cast_at, read_at = 0, [], []
        for step in steps[learned[0]:]:
            clock += step.get('ms', 0) if step['action'] == 'wait' else 0
            if step['action'] == 'cast':
                cast_at.append(clock)
            if step['action'] == 'assert' and step['label'].endswith('shot0 all'):
                read_at.append(clock)
        self.assertEqual([at - cast_at[0] for at in cast_at[:3]], [0, 3750, 7500])
        self.assertEqual(read_at[0] - cast_at[0], 389 + 375)
        self.assertTrue(all(step['critical'] is False and step['blocked'] is False for step in steps
                            if step['action'] == 'assert' and step['label'].endswith(' count')))

    def test_the_stated_ramp_passes_and_measures_both_parts(self):
        stated = [ramped() for _ in range(4)]
        per_stack = self.judged([BASE] * SHOTS, stated)
        self.assertEqual(per_stack.status, 'ok', per_stack.explanation)
        self.assertAlmostEqual(per_stack.measured, 0.15, places=3)
        maximum = self.judged([BASE] * SHOTS, stated, measure=1)
        self.assertEqual(maximum.status, 'ok', maximum.explanation)
        self.assertAlmostEqual(maximum.measured, 1.5, places=3)

    def test_a_ten_percent_mutant_and_an_uncapped_ramp_alert(self):
        mutant = self.judged([BASE] * SHOTS, [ramped(per_stack=0.10) for _ in range(4)])
        self.assertEqual(mutant.status, 'alert', mutant.explanation)
        uncapped = self.judged([BASE] * SHOTS, [ramped(cap=SHOTS) for _ in range(4)])
        self.assertEqual(uncapped.status, 'alert', uncapped.explanation)

    def test_stacks_read_short_of_the_cap_or_held_by_the_control_alert(self):
        stated = [ramped() for _ in range(4)]
        self.assertEqual(self.judged([BASE] * SHOTS, stated, stacks=(0.0, 9.0)).status, 'alert')
        self.assertEqual(self.judged([BASE] * SHOTS, stated, stacks=(1.0, 10.0)).status, 'alert')

    def test_a_ramping_control_or_a_changed_first_shot_alerts(self):
        self.assertEqual(self.judged(ramped(), [ramped() for _ in range(4)]).status, 'alert')
        self.assertEqual(self.judged([BASE] * SHOTS, [ramped(base=BASE * 1.15) for _ in range(4)]).status, 'alert')

    def test_excluded_shots_are_left_out_until_a_stack_count_is_uncovered(self):
        some = [ramped() for _ in range(4)]
        some[0] = [(amount, BLOCKED) if shot in (0, 3) else amount for shot, amount in enumerate(some[0])]
        self.assertEqual(self.judged([BASE] * SHOTS, some).status, 'ok')
        every = [[(amount, BLOCKED) if shot == 3 else amount for shot, amount in enumerate(ramped())]
                 for _ in range(4)]
        self.assertEqual(self.judged([BASE] * SHOTS, every).status, 'unmeasured')

    def test_a_lost_grid_or_an_unlearned_talent_is_unmeasured(self):
        lost = [ramped() for _ in range(4)]
        lost[1] = [(amount, LOST) if shot == 5 else amount for shot, amount in enumerate(lost[1])]
        self.assertEqual(self.judged([BASE] * SHOTS, lost).status, 'unmeasured')
        doubled = [ramped() for _ in range(4)]
        doubled[2] = [(amount, 'double') if shot == 7 else amount for shot, amount in enumerate(doubled[2])]
        self.assertEqual(self.judged([BASE] * SHOTS, doubled).status, 'unmeasured')
        self.assertEqual(self.judged([BASE] * SHOTS, [ramped() for _ in range(4)], known=(0.0, 0.0)).status,
                         'unmeasured')

    def test_too_few_shots_to_reach_the_plateau_are_refused(self):
        with self.assertRaises(ValueError):
            self.expectations(casts=2)
