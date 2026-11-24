from functools import cache
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.stack_feed import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

DIVINE_STRIKES = 705255
STACKED = 803372
CAP = 10
WINDOW = 6000
TRIALS = 3
FEED = {'aura': STACKED, 'cap': CAP, 'window_ms': WINDOW, 'trials': TRIALS,
        'source': 'test StackAmount 10, 6000 ms'}


@cache
def templar() -> dict:
    return load_fixture_class_file(19)


def class_entry(**changes) -> dict:
    entry = next(behaviour for behaviour in templar()['behaviours']
                 if behaviour.get('spell') == DIVINE_STRIKES and behaviour.get('variant') == 'stack_cap')
    return {**entry, 'stack_feed': FEED, **changes}


@cache
def fed_expectation():
    _, [expectation] = behaviour_scenario(templar(), class_entry())
    return expectation


def trial_reads(labels: list[dict], counts: list[int], stacks: list[int], spacing: int = 300,
                start: float = 1000.0) -> dict:
    found = {}
    for index, poll in enumerate(labels):
        found[poll['count']] = float(counts[index])
        found[poll['stacks']] = float(stacks[index])
        found[poll['clock']] = start + index * spacing
    return found


def rising(polls: int, per_poll: int = 1) -> tuple[list[int], list[int]]:
    counts = [per_poll * index for index in range(polls)]
    return counts, [min(count, CAP) for count in counts]


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class StackFeedTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(templar(), class_entry(**changes))

    def test_each_trial_polls_its_start_every_feed_cast_and_its_end(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        polls = len(class_entry()['setup_casts']) + 2
        for trial in range(1, TRIALS + 1):
            for poll in range(polls):
                for read in ('count', 'stacks', 'clock'):
                    self.assertEqual(labels.count(f'{DIVINE_STRIKES} stack_feed t{trial} p{poll} {read}'), 1)
        self.assertEqual(sum(1 for step in scenario['steps']
                             if step['action'] == 'wait' and step.get('ms') == WINDOW + 1000), TRIALS - 1)
        after = labels.index(expectation.model['after_label'])
        self.assertEqual(labels[after + 1], f'{DIVINE_STRIKES} stack_feed t1 p{polls - 1} count')
        self.assertIn('Stack feed', scenario['contract'])

    def test_an_entry_without_the_option_is_unchanged(self):
        plain, [expectation] = self.built(stack_feed=None)
        self.assertNotIn('stack_feed', expectation.model)
        self.assertFalse(any('stack_feed' in str(step.get('label')) for step in plain['steps']))
        entry = class_entry()
        entry.pop('stack_feed')
        self.assertEqual(behaviour_scenario(templar(), entry)[0], plain)

    def test_refeed_auras_are_set_after_every_treatment_feed_cast(self):
        scenario, _ = self.built(stack_feed={**FEED, 'refeed_auras': [[704576, 2]]})
        refeeds = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == 704576]
        self.assertEqual(len(refeeds), TRIALS * len(class_entry()['setup_casts']))

    def judged(self, trials: list[tuple[list[int], list[int]]], control: float = 0.0, spacing: int = 300,
               dropped: tuple[str, ...] = ()):
        expectation = fed_expectation()
        model = expectation.model
        found = {model['before_label']: control, model['after_label']: float(CAP)}
        for labels, (counts, stacks) in zip(model['stack_feed']['labels'], trials):
            found.update(trial_reads(labels, counts, stacks, spacing))
        for label in dropped:
            found.pop(label)
        return judge_behaviour(base_verdict(expectation), FakeRun(found), expectation)

    def polls(self) -> int:
        return len(fed_expectation().model['stack_feed']['labels'][0])

    def test_valid_trials_at_the_cap_pass(self):
        verdict = self.judged([rising(self.polls())] * TRIALS)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, CAP)
        self.assertEqual(verdict.detail['stack_feed'], {'voided': 0, 'trials': TRIALS, 'residual': 0.0})

    def test_a_read_above_the_cap_alerts(self):
        counts, stacks = rising(self.polls())
        stacks[-1] = CAP + 1
        verdict = self.judged([(counts, stacks)] + [rising(self.polls())] * (TRIALS - 1))
        self.assertEqual(verdict.status, 'alert')

    def test_a_read_above_the_cap_in_an_otherwise_void_trial_alerts(self):
        polls = self.polls()
        valid = [rising(polls)] * (TRIALS - 1)
        few = [0] * (polls - 2) + [1, 2]
        over = few[:-1] + [CAP + 1]
        self.assertEqual(self.judged([(few, over)] + valid).status, 'alert')
        counts, stacks = rising(polls)
        stacks[1] = CAP + 1
        first = fed_expectation().model['stack_feed']['labels'][0]
        verdict = self.judged([(counts, stacks)] + valid, dropped=(first[-1]['count'],))
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.detail['stack_feed']['voided'], 0)
        self.assertIn('above the cap', verdict.explanation)
        counts, stacks = rising(polls)
        stacks[0] = CAP + 1
        self.assertEqual(self.judged([(counts, stacks)] + valid).status, 'alert')
        counts, stacks = rising(polls)
        stacks[-1] = CAP + 1
        self.assertEqual(self.judged([(counts, stacks)] + valid, spacing=WINDOW).status, 'alert')

    def test_a_cap_below_the_tooltip_alerts(self):
        counts, _ = rising(self.polls())
        stacks = [min(count, CAP - 1) for count in counts]
        self.assertEqual(self.judged([(counts, stacks)] * TRIALS).status, 'alert')

    def test_a_control_application_alerts(self):
        self.assertEqual(self.judged([rising(self.polls())] * TRIALS, control=1.0).status, 'alert')

    def test_too_few_applications_void_the_trial(self):
        short = ([0] * (self.polls() - CAP) + list(range(1, CAP + 1)), None)
        short = (short[0], [min(count, CAP) for count in short[0]])
        verdict = self.judged([short] + [rising(self.polls())] * (TRIALS - 1))
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['stack_feed']['voided'], 1)
        self.assertAlmostEqual(verdict.detail['stack_feed']['residual'], (1 / TRIALS) ** TRIALS)

    def test_a_gap_past_the_window_voids_the_trial(self):
        verdict = self.judged([rising(self.polls())] * TRIALS, spacing=WINDOW)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertEqual(verdict.detail['stack_feed']['voided'], TRIALS)

    def test_a_trial_that_starts_with_stacks_or_misses_a_read_is_void(self):
        counts, stacks = rising(self.polls())
        stacks[0] = 1
        verdict = self.judged([(counts, stacks)] + [rising(self.polls())] * (TRIALS - 1))
        self.assertEqual(verdict.detail['stack_feed']['voided'], 1)
        self.assertEqual(self.judged([]).status, 'unmeasured')

    def test_an_aura_gone_at_the_end_is_void_not_a_pass(self):
        counts, stacks = rising(self.polls())
        stacks[-1] = 0
        self.assertEqual(self.judged([(counts, stacks)] * TRIALS).status, 'unmeasured')

    def test_refused_inputs(self):
        for raw in ({**FEED, 'cap': 0}, {**FEED, 'trials': True}, {**FEED, 'source': ' '}, {**FEED, 'extra': 1},
                    {**FEED, 'refeed_auras': [[1]]}, {key: FEED[key] for key in FEED if key != 'window_ms'}, 5):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse(raw)
        for changes in ({'expected': CAP - 1}, {'stack_feed': {**FEED, 'aura': 1}}, {'setup_casts': []},
                        {'setup_wait_ms': WINDOW}):
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, 'stack_feed'):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
