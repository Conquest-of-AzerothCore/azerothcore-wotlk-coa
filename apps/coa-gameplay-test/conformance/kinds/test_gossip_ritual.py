import unittest

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_scenario
from compare import judge_behaviour
from coverage import BEHAVIOUR, EVENT, UNPROVEN, clause_coverage, metric_evidence
from kinds.gossip_ritual import METRIC, gossip_ritual_spec
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

ELDRITCH_RITUAL = 804777
RITUAL_STONE = 50298
RITUAL_BEAM = 800965
FACELESS_DESTROYER = 50263
SHADOWGEM = 1210

ENTRY = {
    'spell': ELDRITCH_RITUAL, 'name': 'Eldritch Ritual (gossip ritual)', 'kind': 'gossip_ritual',
    'variant': 'gossip_ritual', 'label_suffix': 'gossip_ritual',
    'quote': 'When 10 allies are channeling, the stone will be destroyed to bring forth a hostile Faceless Destroyer',
    'stone_entry': RITUAL_STONE, 'channel_aura': RITUAL_BEAM, 'summon_entry': FACELESS_DESTROYER,
    'channelers': 10, 'reagent_item': SHADOWGEM}


def seeded_values(model: dict, drop=(), **overrides) -> dict:
    reads = model['reads']
    values = {
        reads['pre_stone']: 0.0, reads['pre_summon']: 0.0, reads['pre_aura']: 0.0, reads['pre_hp']: 2500.0,
        reads['cast_failure']: 0.0, reads['stone_created']: 1.0,
        reads['caster_channeling']: 1.0, reads['hp_after_drain']: 2450.0, reads['summon_before_full']: 0.0,
        reads['stone_after_complete']: 0.0, reads['summon_created']: 1.0,
    }
    for key, val in overrides.items():
        values[reads[key]] = val
    for key in drop:
        values.pop(reads[key], None)
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class GossipRitualTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scenario, [cls.expectation] = behaviour_scenario(load_class_file(25), ENTRY)

    def judged(self, drop=(), **overrides):
        return judge_behaviour(base_verdict(self.expectation),
                               FakeRun(seeded_values(self.expectation.model, drop, **overrides)), self.expectation)

    def test_scenario_validates_with_ten_grouped_players_reagent_dest_cast_and_gossip_steps(self):
        run.validate(self.scenario)
        self.assertEqual(self.scenario['schema'], 2)
        self.assertEqual(self.expectation.label, '804777 behaviour_metric_delta gossip_ritual')
        self.assertEqual(self.expectation.model['metric'], METRIC)
        expected_ids = [CASTER, *(f'ally{index}' for index in range(1, 10))]
        self.assertEqual([player['id'] for player in self.scenario['players']], expected_ids)
        self.assertTrue(all(player['class'] == 25 and player['allow_regeneration'] is False
                            for player in self.scenario['players']))
        add_items = [step for step in self.scenario['steps']
                     if step['action'] == 'add_item' and step['item'] == SHADOWGEM]
        self.assertEqual(add_items, [{'action': 'add_item', 'actor': CASTER, 'item': SHADOWGEM, 'count': 1}])
        casts = [step for step in self.scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [{'action': 'cast', 'actor': CASTER, 'spell': ELDRITCH_RITUAL,
                                  'destination_unit': CASTER}])
        gossips = [(step['actor'], step['entry']) for step in self.scenario['steps']
                   if step['action'] == 'gossip_hello']
        self.assertEqual(gossips, [(actor, RITUAL_STONE) for actor in expected_ids])
        channel_reads = [step for step in self.scenario['steps']
                         if step.get('action') == 'assert' and step.get('spell') == RITUAL_BEAM]
        self.assertEqual([(step['metric'], step['entry'], step['caster']) for step in channel_reads],
                         [('owned_creature_count', RITUAL_STONE, CASTER)] * 2)
        summon_reads = [step for step in self.scenario['steps']
                        if step.get('action') == 'assert' and step.get('entry') == FACELESS_DESTROYER]
        self.assertEqual([step['metric'] for step in summon_reads], [METRIC] * 3)

    def test_small_channeler_count_uses_schema_one_and_optional_cast_power(self):
        small = {**ENTRY, 'channelers': 4, 'reagent_item': None, 'cast_power': 3000}
        scenario, _ = behaviour_scenario(load_class_file(25), small)
        run.validate(scenario)
        self.assertEqual(scenario['schema'], 1)
        self.assertEqual(len(scenario['players']), 4)
        self.assertEqual([step for step in scenario['steps']
                          if step['action'] == 'add_item' and step['item'] == SHADOWGEM], [])
        self.assertEqual([step for step in scenario['steps'] if step['action'] == 'set_power'],
                         [{'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': 3000}])

    def test_complete_gossip_ritual_passes_and_counts_as_behaviour_evidence(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(metric_evidence()[METRIC], EVENT)
        build = 'c' * 64
        stamped = verdict.__class__(**{**verdict.__dict__, 'build': build})
        clauses = [{'spell': ELDRITCH_RITUAL, 'clause': ENTRY['quote'], 'kind': 'claim',
                    'labels': [self.expectation.label]}]
        self.assertEqual([status for _, status in clause_coverage(clauses, [stamped], build).evidence], [BEHAVIOUR])
        alerted = self.judged(summon_created=0.0)
        stamped_alert = alerted.__class__(**{**alerted.__dict__, 'build': build})
        self.assertEqual([status for _, status in clause_coverage(clauses, [stamped_alert], build).evidence],
                         [UNPROVEN])

    def test_mutants_alert_at_each_broken_stage_even_when_later_steps_abort(self):
        for case, drop, overrides in (
            ('cast_failed', ('caster_channeling', 'hp_after_drain', 'summon_before_full',
                             'stone_after_complete', 'summon_created'), {'cast_failure': 1.0, 'stone_created': 0.0}),
            ('no_stone', ('caster_channeling', 'hp_after_drain', 'summon_before_full',
                          'stone_after_complete', 'summon_created'), {'stone_created': 0.0}),
            ('not_channeling', ('stone_after_complete', 'summon_created'), {'caster_channeling': 0.0}),
            ('no_hp_drain', (), {'hp_after_drain': 2500.0}),
            ('premature_summon', (), {'summon_before_full': 1.0}),
            ('stone_not_destroyed', (), {'stone_after_complete': 1.0}),
            ('no_summon_created', (), {'summon_created': 0.0}),
            ('two_summons_created', (), {'summon_created': 2.0}),
        ):
            with self.subTest(case=case):
                self.assertEqual(self.judged(drop=drop, **overrides).status, 'alert')

    def test_dirty_baseline_or_missing_measurement_is_unmeasured(self):
        for bad_pre in ({'pre_stone': 1.0}, {'pre_summon': 1.0}, {'pre_aura': 1.0}, {'pre_hp': 0.0}):
            with self.subTest(bad_pre=bad_pre):
                self.assertEqual(self.judged(**bad_pre).status, 'unmeasured')
        for dropped in (('stone_created',), ('caster_channeling',), ('summon_created',)):
            with self.subTest(dropped=dropped):
                self.assertEqual(self.judged(drop=dropped).status, 'unmeasured')
        self.assertEqual(judge_behaviour(base_verdict(self.expectation), FakeRun({}), self.expectation).status,
                         'unmeasured')

    def test_invalid_spec_fields_are_refused(self):
        for bad in ({'unknown': 1}, {'stone_entry': FACELESS_DESTROYER}, {'channelers': 1}, {'channelers': 26},
                    {'channelers': True}, {'reagent_item': 0}, {'reagent_count': 0},
                    {'reagent_item': None, 'reagent_count': 2}, {'cast_power': -1},
                    {'spawn_wait_ms': 50}, {'drain_wait_ms': 50}, {'complete_wait_ms': 50}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                gossip_ritual_spec({**ENTRY, **bad})


if __name__ == '__main__':
    unittest.main()
