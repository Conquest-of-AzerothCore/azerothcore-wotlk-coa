import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 500331, 'name': 'Raise: Skeletal Mage (Command radius edge)', 'kind': 'radius_edge',
         'label_suffix': 'command_radius_edge', 'quote': 'within $801513a1 yds,', 'gate_spell': 500331,
         'cast_spell': 504868, 'hit_spell': 801513, 'caster_entry': 50075, 'setup_casts': [500331], 'radius': 6,
         'dummy_reach': 1.275, 'reach_source': 'test', 'repeats': 3, 'settle_ms': 1500}


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

    def test_the_gate_cannot_be_learned_in_both_arms(self):
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'learn': [500331]})
