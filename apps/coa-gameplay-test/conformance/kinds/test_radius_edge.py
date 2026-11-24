import unittest
from unittest import mock

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun
import kinds.radius_edge as radius_edge

ENTRY = {'spell': 500331, 'name': 'Raise: Skeletal Mage (Command radius edge)', 'kind': 'radius_edge',
         'label_suffix': 'command_radius_edge', 'quote': 'within $801513a1 yds,', 'gate_spell': 500331,
         'cast_spell': 504868, 'hit_spell': 801513, 'caster_entry': 50075, 'setup_casts': [500331], 'radius': 6,
         'dummy_reach': 1.275, 'reach_source': 'test', 'repeats': 3, 'settle_ms': 1500}
LEEWAY_ENTRY = {'spell': 807870, 'name': 'Glare (stun radius)', 'kind': 'radius_edge',
                'label_suffix': 'radius_edge_stun', 'quote': 'and stuns enemies within $a1 yds', 'gate_spell': 807870,
                'cast_spell': 807870, 'cast_at': 'caster', 'hit_spell': 807870, 'hit_metric': 'aura', 'power': 1360,
                'radius': 8, 'dummy_reach': 1.275, 'primary_yd': 0.1, 'repeats': 1, 'settle_ms': 2500,
                'reach_source': 'test', 'leeway': True}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RadiusEdgeTests(unittest.TestCase):
    def built(self, entry=None):
        return behaviour_scenario(load_fixture_class_file(23), entry or ENTRY)

    def judged(self, treatment: dict, control: dict | None = None, reach: float = 1.275,
               inside: float = 6.775, outside: float = 7.775) -> Verdict:
        _, [expectation] = self.built()
        model = expectation.model
        values = {label: reach for label in model['reach'].values()}
        values.update({label: 83.5 for label in model['height'].values()})
        values.update({model['distance']['inside']: inside, model['distance']['outside']: outside})
        for arm, counts in (('control', control or {}), ('treatment', treatment)):
            for dummy, label in model['arms'][arm].items():
                values[label] = float(counts.get(dummy, 0))
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_dummies_bracket_the_edge_on_one_line(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        self.assertEqual([creature['distance'] for creature in scenario['creatures']], [3.0, 9.775, 10.775])
        learns = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learns[-1], 500331)
        self.assertEqual(expectation.label, '500331 behaviour_metric_delta command_radius_edge')

    def test_inside_struck_and_outside_spared_passes(self):
        self.assertEqual(self.judged({'primary': 3, 'inside': 3}).status, 'ok')

    def test_a_wider_radius_alerts(self):
        self.assertEqual(self.judged({'primary': 3, 'inside': 3, 'outside': 3}).status, 'alert')
        self.assertEqual(self.judged({'primary': 3}).status, 'alert')

    def test_a_struck_control_alerts(self):
        self.assertEqual(self.judged({'primary': 3, 'inside': 3}, control={'inside': 1}).status, 'alert')

    def test_a_layout_off_the_edge_is_unmeasured(self):
        self.assertEqual(self.judged({'primary': 3, 'inside': 3}, reach=0.2).status, 'unmeasured')
        self.assertEqual(self.judged({'inside': 3}).status, 'unmeasured')

    def test_a_corpse_center_adds_its_own_size(self):
        entry = {**ENTRY, 'spell': 533239, 'label_suffix': 'corpse_radius_edge',
                 'quote': 'to all enemies within $533240A1 yds.', 'gate_spell': 533239, 'cast_spell': 533239,
                 'cast_at': 'caster', 'hit_spell': 533240, 'radius': 10, 'repeats': 1,
                 'corpse': {'entry': 6, 'health': 100, 'kill_spell': 92559, 'reach': 0.875}}
        entry.pop('caster_entry')
        entry.pop('setup_casts')
        scenario, [expectation] = self.built(entry)
        run.validate(scenario)
        self.assertEqual([creature['distance'] for creature in scenario['creatures']], [3.0, 14.65, 15.65])
        self.assertEqual(scenario['creatures'][0]['entry'], 6)
        learns = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual((learns.count(533239), learns[-1]), (1, 533239))
        model = expectation.model
        values = {model['reach']['primary']: 0.875, model['reach']['inside']: 1.275, model['reach']['outside']: 1.275}
        values.update({label: 83.5 for label in model['height'].values()})
        values.update({model['distance']['inside']: 11.65, model['distance']['outside']: 12.65})
        for arm, struck in (('control', 0.0), ('treatment', 1.0)):
            values.update({model['arms'][arm]['primary']: 0.0, model['arms'][arm]['inside']: struck,
                           model['arms'][arm]['outside']: 0.0})
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        self.assertEqual(judge_behaviour(base, FakeRun(values), expectation).status, 'ok')
        values[model['arms']['treatment']['outside']] = 1.0
        self.assertEqual(judge_behaviour(base, FakeRun(values), expectation).status, 'alert')
        values[model['reach']['primary']] = 0.0
        self.assertEqual(judge_behaviour(base, FakeRun(values), expectation).status, 'unmeasured')

    def test_the_gate_cannot_be_learned_in_both_arms(self):
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'learn': [500331]})

    def test_a_living_center_and_an_aura_read_move_the_layout(self):
        entry = {**ENTRY, 'spell': 680238, 'label_suffix': 'radius_edge_stun', 'quote': 'within $681179a1 yds,',
                 'gate_spell': 680238, 'cast_spell': 680238, 'cast_at': 'caster', 'hit_spell': 681179, 'radius': 3,
                 'primary_yd': 4.0, 'center_reach': 1.275, 'hit_metric': 'aura', 'repeats': 1}
        entry.pop('caster_entry')
        entry.pop('setup_casts')
        scenario, [expectation] = self.built(entry)
        run.validate(scenario)
        self.assertEqual([creature['distance'] for creature in scenario['creatures']], [4.0, 9.05, 10.05])
        reads = [step for step in scenario['steps'] if step.get('metric') == 'aura']
        self.assertEqual({(step['actor'], step['spell']) for step in reads},
                         {('primary', 681179), ('inside', 681179), ('outside', 681179)})
        model = expectation.model
        self.assertEqual((model['metric'], model['center_size'], model['center_struck']), ('aura', True, True))
        values = {model['reach'][name]: 1.275 for name in model['reach']}
        values.update({label: 83.5 for label in model['height'].values()})
        values.update({model['distance']['inside']: 5.05, model['distance']['outside']: 6.05})
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)

        def judged(control: dict, treatment: dict) -> str:
            for arm, counts in (('control', control), ('treatment', treatment)):
                for dummy, label in model['arms'][arm].items():
                    values[label] = float(counts.get(dummy, 0))
            return judge_behaviour(base, FakeRun(values), expectation).status

        self.assertEqual(judged({}, {'primary': 1, 'inside': 1}), 'ok')
        self.assertEqual(judged({}, {'primary': 1, 'inside': 1, 'outside': 1}), 'alert')
        self.assertEqual(judged({}, {'inside': 1}), 'unmeasured')
        self.assertEqual(judged({'inside': 1}, {'primary': 1, 'inside': 1}), 'alert')

    def leeway_values(self, expectation, rate: float, treatment: dict) -> dict:
        model = expectation.model
        values = {label: 1.275 for label in model['reach'].values()}
        values.update({label: 83.5 for label in model['height'].values()})
        values.update({model['distance']['inside']: 11.435, model['distance']['outside']: 12.435,
                       model['leeway']: rate})
        for arm, counts in (('control', {}), ('treatment', treatment)):
            for dummy, label in model['arms'][arm].items():
                values[label] = float(counts.get(dummy, 0))
        return values

    def leeway_judged(self, expectation, rate: float, treatment: dict) -> Verdict:
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(self.leeway_values(expectation, rate, treatment)), expectation)

    def test_the_player_caster_leeway_moves_the_edge_to_the_engine_rule(self):
        scenario, [expectation] = self.built(LEEWAY_ENTRY)
        run.validate(scenario)
        self.assertEqual([creature['distance'] for creature in scenario['creatures']], [0.1, 11.535, 12.535])
        reads = [step for step in scenario['steps'] if step.get('metric') == 'run_speed_rate']
        self.assertEqual([(step['actor'], step['label']) for step in reads],
                         [('caster', '807870 radius_edge_stun caster run_speed_rate')])
        self.assertFalse([step for step in scenario['steps'] if step['action'] == 'set_moving'])
        self.assertIn('leeway 2.66 yd', scenario['contract'])
        self.assertEqual(expectation.model['leeway'], '807870 radius_edge_stun caster run_speed_rate')
        verdict = self.leeway_judged(expectation, 1.0, {'primary': 1, 'inside': 1})
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('+ leeway 2.66', verdict.explanation)
        self.assertIn('run mode required by construction', verdict.explanation)
        self.assertEqual(self.leeway_judged(expectation, 1.0, {'primary': 1, 'inside': 1, 'outside': 1}).status,
                         'alert')
        self.assertEqual(self.leeway_judged(expectation, 1.0, {'primary': 1}).status, 'alert')

    def test_a_speed_under_the_threshold_drops_the_leeway(self):
        _, [expectation] = self.built(LEEWAY_ENTRY)
        self.assertEqual(self.leeway_judged(expectation, 0.7, {'primary': 1, 'inside': 1}).status, 'unmeasured')
        self.assertEqual(self.leeway_judged(expectation, 0.72, {'primary': 1, 'inside': 1}).status, 'ok')

    def test_a_wrong_leeway_does_not_pass(self):
        _, [expectation] = self.built(LEEWAY_ENTRY)
        for wrong in (1.5, 4.0):
            with self.subTest(leeway=wrong), mock.patch.object(radius_edge, 'LEEWAY_BONUS_RANGE_YD', wrong):
                self.assertNotEqual(self.leeway_judged(expectation, 1.0, {'primary': 1, 'inside': 1}).status, 'ok')

    def test_the_leeway_needs_a_player_caster_and_a_leeway_area(self):
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'leeway': True})
        no_area = {**ENTRY, 'leeway': True}
        no_area.pop('caster_entry')
        with self.assertRaises(ValueError):
            self.built(no_area)
        with self.assertRaises(ValueError):
            self.built({**LEEWAY_ENTRY, 'leeway': 'yes'})
