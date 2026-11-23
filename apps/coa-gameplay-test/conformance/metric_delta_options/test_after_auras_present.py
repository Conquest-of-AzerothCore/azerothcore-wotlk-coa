import unittest

from behaviours import behaviour_scenario
from compare import PASSIVE_METRIC, judge_behaviour
from coverage import READBACK, metric_evidence
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

CLASS_FILE = {'class_id': 13, 'name': 'Witch Doctor', 'race': 1, 'level': 60, 'skill_lines': [],
              'reference_stats': {}}
SILENCE = 24259
FISH_BUFF = 803269
GUARDS = [{'aura': SILENCE, 'source': 'Spell Lock from the striker'},
          {'aura': FISH_BUFF, 'source': 'the Fish Oil Cauldron buff'}]
SILENCED = {'spell': 801664, 'kind': 'metric_delta', 'name': 'Ingredient: Bloodthistle (Cauldron buff while silenced)',
            'variant': 'cauldron_silenced', 'label_suffix': 'cauldron_silenced',
            'quote': 'Cauldron: Allies within $802771a1 yds receive $802771s1% increased healing.',
            'trigger_spell': 801664, 'target': 'caster', 'cast_in_before': False, 'measure_actor': 'caster',
            'metric': 'aura', 'fields': {'spell': 802771}, 'evidence_metric': 'aura_amount', 'before_expected': 0,
            'expected': 1, 'cast_power': 1000, 'learn': [561069], 'setup_casts': [801662], 'setup_wait_ms': 1600,
            'strike': {'spell': SILENCE, 'health': 10000, 'max_health': 10000, 'after_trigger_ms': 1700, 'count': 1,
                       'wait_ms': 2500, 'reaction': 0},
            'after_auras_present': GUARDS, 'wait_ms': 100, 'expire_ms': 14000}


def entry(**changes) -> dict:
    return {**SILENCED, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AfterAurasPresentTests(unittest.TestCase):
    def test_the_auras_are_read_on_the_caster_right_before_the_after_reading(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        reads = expectation.model['after_auras_present']['reads']
        after = labels.index(expectation.model['after_label'])
        self.assertEqual([labels.index(label) for _, label, _ in reads], [after - 2, after - 1])
        for aura, label, _ in reads:
            read = scenario['steps'][labels.index(label)]
            self.assertEqual((read['actor'], read['metric'], read['spell']), ('caster', 'aura', aura))
        self.assertIn('the caster must hold 24259 (Spell Lock from the striker)', scenario['contract'])

    def test_without_the_option_nothing_is_read(self):
        scenario, [expectation] = behaviour_scenario(
            CLASS_FILE, {key: value for key, value in entry().items() if key != 'after_auras_present'})
        self.assertNotIn('after_auras_present', expectation.model)
        self.assertFalse(any(step.get('spell') in (SILENCE, FISH_BUFF) and step.get('action') == 'assert'
                             for step in scenario['steps']))

    def test_the_option_needs_distinct_auras_each_with_a_source(self):
        for raw in ([], True, [{'aura': SILENCE}], [{'aura': SILENCE, 'source': ''}],
                    [{'aura': '24259', 'source': 'x'}], [{'aura': True, 'source': 'x'}], GUARDS[:1] * 2):
            with self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, entry(after_auras_present=raw))

    def test_an_absent_guard_is_unmeasured_and_present_guards_keep_the_plain_verdict(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        silence, fish = (label for _, label, _ in expectation.model['after_auras_present']['reads'])

        def judged(after_value: float, guards: dict) -> str:
            values = {before: 0.0, after: after_value, **guards}
            return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status

        self.assertEqual(judged(1.0, {silence: 1.0, fish: 1.0}), 'ok')
        self.assertEqual(judged(0.0, {silence: 1.0, fish: 1.0}), 'alert')
        self.assertEqual(judged(1.0, {silence: 0.0, fish: 1.0}), 'unmeasured')
        self.assertEqual(judged(0.0, {silence: 1.0, fish: 0.0}), 'unmeasured')
        self.assertEqual(judged(0.0, {fish: 1.0}), 'unmeasured')

    def test_the_aura_read_of_a_healing_claim_is_stamped_as_a_readback(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry())
        before, after = expectation.model['before_label'], expectation.model['after_label']
        values = {before: 0.0, after: 1.0, **{label: 1.0 for _, label, _ in
                                               expectation.model['after_auras_present']['reads']}}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(metric_evidence()[verdict.detail[PASSIVE_METRIC]], READBACK)


if __name__ == '__main__':
    unittest.main()
