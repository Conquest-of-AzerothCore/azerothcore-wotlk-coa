import unittest

from behaviours import behaviour_scenario
from compare import banded_rate, judge_behaviour
from kinds.stack_chance_rate import POOLED_JUDGE, stack_chance_verdict
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

SPIRIT = 561136
ARROW = 801674
RECLAMATION = 806288
BOW = {'item': 2000265, 'slot': 17, 'subclass': 2, 'inventory_type': 15, 'skill_line': 45}
CLASS_FILE = {'class_id': 13, 'name': 'Witch Doctor', 'race': 1, 'level': 60, 'skill_lines': [],
              'reference_stats': {}, 'alternate_weapons': [BOW]}
HUNTING_QUOTE = ('Each active Spirit gives you a 15% chance when you cast Malefic Arrow to generate an additional '
                 'Spirit.')
ECHO_QUOTE = ('For each active Spirit on you, you have a $561361s1% chance for your Reclamation to cast an additional '
              'time.')
ENTRY = {'spell': 707504, 'name': 'Spirit Hunting (extra Spirit per Malefic Arrow)', 'kind': 'stack_chance_rate',
         'label_suffix': 'spirit_chance', 'quote': HUNTING_QUOTE, 'talent': 707504, 'stack_aura': SPIRIT,
         'trigger_spell': ARROW, 'learn': [ARROW, 707854], 'event_spell': SPIRIT, 'chance_pct': 15,
         'arms': [{'stacks': 5, 'trials': 590}, {'stacks': 4, 'trials': 1180}], 'control_trials': 10,
         'unlearned_trials': 10, 'cast_wait_ms': 1600, 'cast_power': 1000, 'parts': 6, 'dummy_distance': 15}
ECHO = {'spell': 705843, 'name': 'Loa Spirits (Reclamation recast)', 'kind': 'stack_chance_rate',
        'label_suffix': 'spirit_chance', 'quote': ECHO_QUOTE, 'stack_aura': SPIRIT, 'trigger_spell': RECLAMATION,
        'trial_spell': SPIRIT, 'event_spell': RECLAMATION, 'event_offset': 1, 'chance_pct': 5,
        'arms': [{'stacks': 1, 'trials': 451}, {'stacks': 2, 'trials': 854}], 'control_trials': 10,
        'unlearned_trials': 8, 'cast_wait_ms': 2500, 'cast_power': 1000, 'parts': 7, 'dummy_distance': 15}
FAIR = {'unlearned': (10, 0), 'control': (10, 0), 'stacks 5': (590, 442), 'stacks 4': (1180, 708)}
ECHO_FAIR = {'unlearned': (8, 0), 'control': (10, 0), 'stacks 1': (451, 22), 'stacks 2': (854, 85)}
TEN_PARTS = {'parts': 10, 'arms': [{'stacks': 5, 'trials': 570}, {'stacks': 4, 'trials': 1150}]}
PILOT = {'pilot': True, 'parts': 1, 'arms': [{'stacks': 5, 'trials': 300}, {'stacks': 4, 'trials': 300}],
         'control_trials': 50, 'unlearned_trials': 50}


def counted_run(expectation, counts: dict, offset: int = 0) -> FakeRun:
    values, trials_total, events_total = {}, 0.0, 0.0
    for arm in expectation.model['arms']:
        trials, extra = counts[arm['name']]
        reads = arm['reads']
        values[reads['start trials']], values[reads['start events']] = trials_total, events_total
        trials_total += trials
        events_total += extra + offset * trials
        values[reads['end trials']], values[reads['end events']] = trials_total, events_total
    return FakeRun(values)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class StackChanceRateTests(unittest.TestCase):
    def built(self, entry=None, **changes):
        return behaviour_scenario(CLASS_FILE, {**(entry or ENTRY), **changes})

    def pooled(self, counts: dict, entry=None, offset: int = 0):
        entry = entry or ENTRY
        _, [expectation] = self.built(entry)
        part = counted_run(expectation, counts, offset)
        return POOLED_JUDGE(base_verdict(expectation), [part] * entry['parts'], expectation.model)

    def test_every_cast_sets_its_stacks_and_the_talent_is_learned_after_the_unlearned_arm(self):
        scenario, [expectation] = self.built()
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        stacks = [step['stacks'] for step in steps if step['action'] == 'set_aura' and step['spell'] == SPIRIT]
        casts = [step for step in steps if step['action'] == 'cast' and step['spell'] == ARROW]
        self.assertEqual(stacks, [5] * 10 + [0] * 10 + [5] * 590 + [4] * 1180)
        self.assertEqual(len(casts), len(stacks))
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 707504)
        labels = [step.get('label') for step in steps]
        arms = {arm['name']: arm for arm in expectation.model['arms']}
        self.assertLess(labels.index(arms['unlearned']['reads']['end events']), learn)
        self.assertLess(learn, labels.index(arms['control']['reads']['start trials']))
        self.assertIn({'action': 'equip', 'actor': 'caster', 'item': 2000265, 'slot': 17}, steps)
        self.assertEqual(expectation.model['metric'], 'spell_cast_count')
        self.assertEqual((round(arms['stacks 5']['expected'], 4), arms['stacks 5']['minimum']), (0.75, 3540))
        self.assertEqual((round(arms['stacks 4']['expected'], 4), arms['stacks 4']['minimum']), (0.6, 7079))

    def test_each_arm_total_inside_its_band_passes_with_its_controls(self):
        found = self.pooled(FAIR)
        self.assertEqual(found.status, 'ok')
        self.assertEqual(found.detail['contrast'], 'learned')
        self.assertEqual(found.detail['parts'], 6)
        self.assertIn('set_aura', found.explanation)
        bands = {item['arm']: round(item['band'], 4) for item in found.detail['arms'] if 'band' in item}
        self.assertEqual(bands, {'stacks 5': 0.0375, 'stacks 4': 0.03})

    def test_a_total_outside_its_band_alerts_although_the_per_stack_reading_would_pass(self):
        found = self.pooled({**FAIR, 'stacks 5': (590, 472)})
        self.assertEqual(found.status, 'alert')
        self.assertAlmostEqual(found.expected, 0.75)
        self.assertGreater(found.low, 0.75)
        per_stack, *_ = banded_rate('alert', found.low / 5, found.high / 5, 0.15, '')
        self.assertEqual(per_stack, 'ok')

    def test_a_flat_chance_that_ignores_the_stacks_alerts(self):
        self.assertEqual(self.pooled({**FAIR, 'stacks 4': (1180, 885)}).status, 'alert')

    def test_an_event_in_either_control_alerts(self):
        self.assertEqual(self.pooled({**FAIR, 'control': (10, 1)}).status, 'alert')
        found = self.pooled({**FAIR, 'unlearned': (10, 2)})
        self.assertEqual(found.status, 'alert')
        self.assertNotIn('contrast', found.detail)

    def test_the_event_offset_discounts_the_trigger_own_cast(self):
        self.assertEqual(self.pooled(ECHO_FAIR, ECHO, offset=1).status, 'ok')
        self.assertEqual(self.pooled({**ECHO_FAIR, 'stacks 2': (854, -20)}, ECHO, offset=1).status, 'alert')

    def test_a_roll_on_the_stacks_after_reclamation_grants_its_spirit_alerts_at_one_stack(self):
        self.assertEqual(self.pooled({**ECHO_FAIR, 'stacks 1': (451, 45)}, ECHO, offset=1).status, 'alert')

    def test_ten_parts_take_the_between_part_interval_and_overdispersed_parts_are_measured(self):
        _, [expectation] = self.built(**TEN_PARTS)
        arms = {arm['name']: arm['minimum'] for arm in expectation.model['arms']}
        self.assertGreater(arms['stacks 5'], 3540)
        self.assertLessEqual(arms['stacks 5'], 5700)

        def parts(spread: int) -> list[FakeRun]:
            return [counted_run(expectation, {'unlearned': (10, 0), 'control': (10, 0),
                                              'stacks 5': (570, 428 + (spread if index % 2 else -spread)),
                                              'stacks 4': (1150, 690)})
                    for index in range(10)]

        steady = POOLED_JUDGE(base_verdict(expectation), parts(0), expectation.model)
        self.assertEqual(steady.status, 'ok')
        self.assertIn('between-part', steady.explanation)
        spread = POOLED_JUDGE(base_verdict(expectation), parts(40), expectation.model)
        self.assertEqual(spread.status, 'measured')

    def test_parts_are_pooled_and_one_part_alone_is_too_small(self):
        _, [expectation] = self.built()
        part = counted_run(expectation, FAIR)
        self.assertEqual(stack_chance_verdict(base_verdict(expectation), part, expectation.model).status,
                         'insufficient_trials')

    def test_a_pilot_holding_the_chance_but_not_the_band_is_measured(self):
        _, [expectation] = self.built(**PILOT)
        counts = {'unlearned': (50, 0), 'control': (50, 0), 'stacks 5': (300, 225), 'stacks 4': (300, 180)}
        found = judge_behaviour(base_verdict(expectation), counted_run(expectation, counts), expectation)
        self.assertEqual(found.status, 'measured')

    def test_entries_the_band_or_the_fixture_cannot_measure_are_refused(self):
        for changes in ({'arms': [{'stacks': 5, 'trials': 100}]},
                        {'parts': 2, 'arms': [{'stacks': 5, 'trials': 280}, {'stacks': 3, 'trials': 1000}]},
                        {'parts': 10, 'arms': [{'stacks': 5, 'trials': 354}, {'stacks': 4, 'trials': 708}]},
                        {'arms': [{'stacks': 6, 'trials': 600}]},
                        {'chance_pct': 25, 'arms': [{'stacks': 4, 'trials': 600}]}, {'cast_wait_ms': 1000},
                        {'cast_power': None}, {'learn': [ARROW, 707854, 707504]}, {'control_trials': 8},
                        {'dummy_distance': None}, {'dummy_distance': 0}, {'dummy_distance': 101}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)

    def test_a_ranged_trigger_casts_at_the_stated_distance(self):
        for entry in (ENTRY, ECHO):
            with self.subTest(spell=entry['spell']):
                scenario, _ = self.built(entry)
                self.assertEqual(scenario['creatures'][0]['distance'], 15)
                self.assertIn('The dummy stands 15 yd from the caster.', scenario['contract'])
