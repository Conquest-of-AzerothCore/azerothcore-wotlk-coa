import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.caster_aura_gate import MOMENTS, gate_label
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

QUICKDRAW_R7 = 806851
QUICKDRAW_R1 = 804193
QUICKDRAW_AURA = 680244
DARKSLAYER = 804179


def entry(**changes) -> dict:
    return {'spell': QUICKDRAW_R7, 'name': 'Quickdraw r7', 'kind': 'caster_aura_gate',
            'quote': 'Only usable after critically striking with an ability.', 'crit_ability': DARKSLAYER,
            'force_crit': 'ranged', 'earned_learn': [QUICKDRAW_R1], 'known_probes': [QUICKDRAW_R1], **changes}


def cast_index(steps: list[dict], moment: str) -> int:
    read = next(index for index, step in enumerate(steps) if step.get('label') == gate_label(QUICKDRAW_R7, moment))
    return max(index for index, step in enumerate(steps[:read])
               if step['action'] == 'cast' and step['spell'] == QUICKDRAW_R7)


def aura_sets(steps: list[dict], start: int, end: int, stacks: int) -> list[int]:
    return [index for index in range(start, end) if steps[index]['action'] == 'set_aura'
            and steps[index]['spell'] == QUICKDRAW_AURA and steps[index]['stacks'] == stacks]


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class CasterAuraGateTests(unittest.TestCase):
    def setUp(self):
        self.scenario, self.expectations = behaviour_scenario(load_fixture_class_file(19), entry())
        self.steps = run.validate(self.scenario)['steps']

    def test_the_blocked_attempt_has_no_gate_aura_and_the_allowed_one_has_exactly_one(self):
        blocked, allowed = cast_index(self.steps, MOMENTS[0]), cast_index(self.steps, MOMENTS[1])
        removed = max(aura_sets(self.steps, 0, blocked, 0))
        self.assertEqual(aura_sets(self.steps, removed, blocked, 1), [])
        self.assertEqual(len(aura_sets(self.steps, blocked, allowed, 1)), 1)

    def test_the_earned_attempt_follows_a_forced_crit_with_no_gate_fixture(self):
        earned = cast_index(self.steps, MOMENTS[3])
        removed = max(aura_sets(self.steps, 0, earned, 0))
        self.assertEqual(aura_sets(self.steps, removed, earned, 1), [])
        crit = [index for index in range(removed, earned)
                if self.steps[index]['action'] == 'cast' and self.steps[index]['spell'] == DARKSLAYER]
        self.assertEqual(len(crit), 1)
        learned = [index for index, step in enumerate(self.steps)
                   if step == {'action': 'learn', 'actor': 'caster', 'spell': QUICKDRAW_R1}]
        self.assertEqual(len(learned), 1)
        self.assertGreater(learned[0], cast_index(self.steps, MOMENTS[1]))
        self.assertLess(learned[0], removed)
        self.assertEqual(self.scenario['players'][0]['ranged_crit_rating'], 100000)

    def test_the_rank_alone_is_probed_before_the_first_rank_is_learned(self):
        labels = [step.get('label') for step in self.steps]
        learned = self.steps.index({'action': 'learn', 'actor': 'caster', 'spell': QUICKDRAW_R1})
        for read in (f'probe knows {QUICKDRAW_R1} rank_only', f'probe aura {QUICKDRAW_AURA} rank_only'):
            self.assertLess(labels.index(f'{QUICKDRAW_R7} behaviour_cast_gate {read}'), learned)
        self.assertGreater(labels.index(f'{QUICKDRAW_R7} behaviour_cast_gate probe knows {QUICKDRAW_R1} earned'),
                           learned)

    def test_the_expected_codes_and_their_judgement(self):
        self.assertEqual([(expectation.label, expectation.displayed) for expectation in self.expectations],
                         [(gate_label(QUICKDRAW_R7, moment), value)
                          for moment, value in zip(MOMENTS, ('22', '0', '1', '0'))])
        blocked = self.expectations[0]
        self.assertEqual(judge_behaviour(base_verdict(blocked), FakeRun({blocked.label: 22.0}), blocked).status, 'ok')
        self.assertEqual(judge_behaviour(base_verdict(blocked), FakeRun({blocked.label: 0.0}), blocked).status,
                         'alert')

    def test_without_a_crit_ability_only_the_fixture_arms_are_judged(self):
        plain = {key: value for key, value in entry().items()
                 if key not in ('crit_ability', 'force_crit', 'earned_learn', 'known_probes')}
        _, expectations = behaviour_scenario(load_fixture_class_file(19), plain)
        self.assertEqual([expectation.label for expectation in expectations],
                         [gate_label(QUICKDRAW_R7, moment) for moment in MOMENTS[:2]])

    def test_bad_entries_are_refused(self):
        for changes in ({'force_crit': None}, {'force_crit': 'wand'}, {'crit_ability': QUICKDRAW_R7}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), entry(**changes))
