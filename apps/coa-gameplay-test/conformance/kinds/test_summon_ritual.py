from types import SimpleNamespace
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.summon_ritual import direct_summon_scenario, summon_ritual_spec
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

BLOOD_COVENANT = 1200012
SUMMONING_OBELISK = 1200011

ENTRY = {
    'spell': BLOOD_COVENANT, 'name': 'Blood Covenant (summoning ritual)', 'kind': 'summon_ritual',
    'variant': 'summon_ritual', 'label_suffix': 'summon_ritual',
    'quote': 'Once allies are inside, they may help summon party and raid members to your current location.',
    'ritual_entry': 194111, 'stone_entry': 194114, 'portal_entry': 179944}

DIRECT_ENTRY = {
    'spell': SUMMONING_OBELISK, 'name': 'Summoning Obelisk (direct summon)', 'kind': 'summon_ritual',
    'variant': 'summon_ritual', 'label_suffix': 'summon_ritual',
    'quote': 'allowing you and another ally to summon party and raid members to your current location.',
    'ritual_entry': 194110}


def seeded_values(model: dict, drop=(), **overrides) -> dict:
    reads = model['reads']
    values = {
        reads['pre_ritual']: 0.0, reads['pre_stone']: 0.0, reads['pre_portal']: 0.0, reads['pre_summon']: 0.0,
        reads['cast_failure']: 0.0, reads['ritual_created']: 1.0,
        reads['stone_created']: 1.0, reads['summon_after_stone']: 0.0,
        reads['portal_created']: 1.0, reads['summon_after_portal']: 0.0,
        reads['summon_final']: 1.0,
    }
    for key, val in overrides.items():
        values[reads[key]] = val
    for key in drop:
        values.pop(reads[key], None)
    return values


def seeded_direct_values(model: dict, drop=(), **overrides) -> dict:
    reads = model['reads']
    values = {
        reads['pre_ritual']: 0.0, reads['pre_summon']: 0.0,
        reads['cast_failure']: 0.0, reads['ritual_created']: 1.0,
        reads['summon_before_click']: 0.0, reads['summon_final']: 1.0,
    }
    for key, val in overrides.items():
        values[reads[key]] = val
    for key in drop:
        values.pop(reads[key], None)
    return values


class DirectRitualLocationTest(unittest.TestCase):
    def test_direct_ritual_uses_the_configured_origin(self):
        origin = {'map': 1, 'x': 500.0, 'y': 600.0, 'z': 80.0}
        distant = {**origin, 'x': 1000.0}
        spec = summon_ritual_spec({**DIRECT_ENTRY, 'location': origin, 'faraway_location': distant})
        scenario, _ = direct_summon_scenario(
            {'name': 'Cultist', 'class_id': 25, 'race': 1, 'level': 60}, spec,
            SimpleNamespace(quote=DIRECT_ENTRY['quote']), SimpleNamespace())
        run.validate(scenario)
        self.assertEqual(scenario['location'], origin)
        self.assertIn({'action': 'teleport', 'actor': 'faraway', **distant}, scenario['steps'])


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SummonRitualTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scenario, [cls.expectation] = behaviour_scenario(load_class_file(20), ENTRY)

    def judged(self, drop=(), **overrides):
        return judge_behaviour(base_verdict(self.expectation),
                               FakeRun(seeded_values(self.expectation.model, drop, **overrides)), self.expectation)

    def test_scenario_validates_with_four_grouped_players_and_full_gameobject_chain(self):
        run.validate(self.scenario)
        self.assertEqual(self.expectation.label, '1200012 behaviour_metric_delta summon_ritual')
        self.assertEqual(self.expectation.model['metric'], 'summon_pending')
        self.assertEqual([player['id'] for player in self.scenario['players']], [CASTER, 'first', 'second', 'faraway'])
        self.assertTrue(all(player['class'] == 20 for player in self.scenario['players']))
        uses = [(step['actor'], step['entry'], step['owner']) for step in self.scenario['steps']
                if step['action'] == 'use_nearby_gameobject']
        self.assertEqual(uses, [('first', 194111, CASTER), ('second', 194111, CASTER),
                                ('first', 194114, CASTER), ('second', 179944, 'first')])

    def test_complete_ritual_passes(self):
        self.assertEqual(self.judged().status, 'ok')

    def test_mutants_alert_at_each_broken_stage_even_when_later_steps_abort(self):
        for case, drop, overrides in (
            ('cast_failed', ('stone_created', 'summon_after_stone', 'portal_created', 'summon_after_portal',
                             'summon_final'), {'cast_failure': 1.0, 'ritual_created': 0.0}),
            ('no_ritual', ('stone_created', 'summon_after_stone', 'portal_created', 'summon_after_portal',
                           'summon_final'), {'ritual_created': 0.0}),
            ('no_stone', ('portal_created', 'summon_after_portal', 'summon_final'), {'stone_created': 0.0}),
            ('premature_summon_after_stone', (), {'summon_after_stone': 1.0}),
            ('no_portal', ('summon_final',), {'portal_created': 0.0}),
            ('premature_summon_after_portal', (), {'summon_after_portal': 1.0}),
            ('no_final_summon', (), {'summon_final': 0.0}),
        ):
            with self.subTest(case=case):
                self.assertEqual(self.judged(drop=drop, **overrides).status, 'alert')

    def test_dirty_baseline_or_missing_measurement_is_unmeasured(self):
        self.assertEqual(self.judged(pre_summon=1.0).status, 'unmeasured')
        self.assertEqual(self.judged(drop=('summon_final',)).status, 'unmeasured')
        self.assertEqual(judge_behaviour(base_verdict(self.expectation), FakeRun({}), self.expectation).status,
                         'unmeasured')

    def test_invalid_spec_fields_are_refused(self):
        for bad in ({'unknown': 1}, {'stone_entry': 194111}, {'ritual_wait_ms': 50},
                    {'faraway_location': {'map': 1, 'x': -9100.0, 'y': 400.0, 'z': 93.0}},
                    {'faraway_location': {'map': 0, 'x': -9458.0, 'y': 45.0, 'z': 55.5}}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                summon_ritual_spec({**ENTRY, **bad})
        for partial in ({**DIRECT_ENTRY, 'stone_entry': 194114}, {**DIRECT_ENTRY, 'portal_entry': 179944},
                        {**DIRECT_ENTRY, 'stone_entry': 194114, 'portal_entry': None},
                        {**DIRECT_ENTRY, 'stone_entry': None, 'portal_entry': 179944}):
            with self.subTest(partial=partial), self.assertRaises(ValueError):
                summon_ritual_spec(partial)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class DirectSummonRitualTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scenario, [cls.expectation] = behaviour_scenario(load_class_file(25), DIRECT_ENTRY)

    def judged(self, drop=(), **overrides):
        return judge_behaviour(base_verdict(self.expectation),
                               FakeRun(seeded_direct_values(self.expectation.model, drop, **overrides)),
                               self.expectation)

    def test_direct_scenario_validates_with_three_grouped_players_and_single_click(self):
        run.validate(self.scenario)
        self.assertEqual(self.expectation.label, '1200011 behaviour_metric_delta summon_ritual')
        self.assertEqual(self.expectation.model['metric'], 'summon_pending')
        self.assertNotIn('stone_entry', self.expectation.model)
        self.assertNotIn('portal_entry', self.expectation.model)
        self.assertEqual([player['id'] for player in self.scenario['players']], [CASTER, 'first', 'faraway'])
        self.assertTrue(all(player['class'] == 25 for player in self.scenario['players']))
        selects = [(step['actor'], step['target']) for step in self.scenario['steps'] if step['action'] == 'select']
        self.assertEqual(selects, [(CASTER, 'faraway')])
        uses = [(step['actor'], step['entry'], step['owner']) for step in self.scenario['steps']
                if step['action'] == 'use_nearby_gameobject']
        self.assertEqual(uses, [('first', 194110, CASTER)])

    def test_direct_ritual_with_cast_power_and_explicit_none_entries_validates(self):
        scenario, _ = behaviour_scenario(load_class_file(25),
                                         {**DIRECT_ENTRY, 'stone_entry': None, 'portal_entry': None,
                                          'cast_power': 5000})
        run.validate(scenario)
        power_steps = [step for step in scenario['steps'] if step['action'] == 'set_power']
        self.assertEqual(power_steps, [{'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': 5000}])

    def test_complete_direct_ritual_passes(self):
        self.assertEqual(self.judged().status, 'ok')

    def test_direct_mutants_alert_at_each_broken_stage(self):
        for case, drop, overrides in (
            ('cast_failed', ('summon_before_click', 'summon_final'), {'cast_failure': 1.0, 'ritual_created': 0.0}),
            ('no_ritual', ('summon_before_click', 'summon_final'), {'ritual_created': 0.0}),
            ('premature_summon', (), {'summon_before_click': 1.0}),
            ('no_final_summon', (), {'summon_final': 0.0}),
        ):
            with self.subTest(case=case):
                self.assertEqual(self.judged(drop=drop, **overrides).status, 'alert')

    def test_direct_dirty_baseline_or_missing_measurement_is_unmeasured(self):
        self.assertEqual(self.judged(pre_ritual=1.0).status, 'unmeasured')
        self.assertEqual(self.judged(pre_summon=1.0).status, 'unmeasured')
        self.assertEqual(self.judged(drop=('summon_before_click',)).status, 'unmeasured')
        self.assertEqual(self.judged(drop=('summon_final',)).status, 'unmeasured')
        self.assertEqual(judge_behaviour(base_verdict(self.expectation), FakeRun({}), self.expectation).status,
                         'unmeasured')


if __name__ == '__main__':
    unittest.main()
