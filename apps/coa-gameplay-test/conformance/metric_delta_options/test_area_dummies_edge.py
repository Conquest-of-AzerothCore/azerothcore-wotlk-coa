import json
import unittest
from pathlib import Path

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

ORIGIN = (-8949.95, -132.49, 83.5)


def class_file() -> dict:
    return json.load(open(Path(__file__).resolve().parents[1] / 'classes' / 'sun_cleric.json'))


def edge_entry(**changes) -> dict:
    entry = next(entry for entry in class_file()['behaviours']
                 if entry['spell'] == 680637 and entry.get('label_suffix') == 'split_radius')
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AreaDummiesEdgeTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(class_file(), edge_entry(**changes))

    def test_area1_and_area2_stand_ten_percent_either_side_of_radius_reach_and_leeway(self):
        scenario, [expectation] = self.build()
        steps = run.validate(scenario)['steps']
        plan = expectation.model['area_dummies']['edge']['plan']
        self.assertAlmostEqual(plan['edge'], 8 + 1.275 + 2.66)
        distances = {creature['id']: creature['distance'] for creature in scenario['creatures']}
        self.assertAlmostEqual(distances['area1'], plan['edge'] * 0.9)
        self.assertAlmostEqual(distances['area2'], plan['edge'] * 1.1)
        labels = [step.get('label') for step in steps]
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 500143]
        self.assertLess(labels.index('680637 edge caster run_speed_rate'), casts[-1])
        self.assertGreater(labels.index('680637 edge caster run_speed_rate'), casts[0])
        self.assertGreater(labels.index('680637 edge area2 hits'), labels.index(expectation.model['after_label']))
        self.assertIn('Spell.cpp:9437-9442', scenario['contract'])
        self.assertIn('Spell.cpp:1388-1394', scenario['contract'])

    def test_the_list_form_keeps_no_edge_model(self):
        _, [expectation] = self.build(area_dummies=[6.0, 20.0])
        self.assertNotIn('area_dummies', expectation.model)

    def test_malformed_edges_are_refused(self):
        good = edge_entry()['area_dummies']['edge']
        for edge in ({**good, 'source': 'read'}, {**good, 'reach_source': 'a run'}, {**good, 'radius': 0},
                     {**good, 'reach': -1}, {**good, 'margin_pct': 0}, {**good, 'leeway': 1},
                     {key: value for key, value in good.items() if key != 'reach'}, {**good, 'other': 1}):
            with self.subTest(edge=edge), self.assertRaises(ValueError):
                self.build(area_dummies={'edge': edge})
        with self.assertRaises(ValueError):
            self.build(relocate_before_trigger={'dx': 1})

    def values(self, expectation, after=(32.0, 32.0, 0.0), hits=(1.0, 0.0), reach=1.275, rate=1.0, area2_x=None):
        model = expectation.model['area_dummies']
        plan, labels = model['edge']['plan'], model['labels']
        values = {}
        for label, reads in ((expectation.model['before_label'], (0.0, 0.0, 0.0)),
                             (expectation.model['after_label'], after)):
            for name, value in zip(('', ' area1', ' area2'), reads):
                values[f'{label}{name}'] = value
        x, y, z = ORIGIN
        offsets = {'caster': 0.0, 'area1': plan['area1'], 'area2': plan['area2'] if area2_x is None else area2_x}
        for unit, offset in offsets.items():
            for axis, value in zip(labels['positions'][unit], (x + offset, y, z)):
                values[axis] = value
        values[labels['reach']['caster']] = 1.5
        values[labels['reach']['area1']] = reach
        values[labels['reach']['area2']] = reach
        values[labels['run_speed_rate']] = rate
        values[labels['hits']['area1']], values[labels['hits']['area2']] = hits
        return values

    def judged(self, **changes):
        _, [expectation] = self.build()
        values = self.values(expectation, **changes)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_area1_struck_and_area2_spared_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('area1 inside the edge struck', verdict.explanation)

    def test_seeded_mutants_alert(self):
        self.assertEqual(self.judged(after=(24.0, 24.0, 24.0), hits=(1.0, 1.0)).status, 'alert')
        self.assertEqual(self.judged(after=(48.0, 0.0, 0.0), hits=(0.0, 0.0)).status, 'alert')
        self.assertEqual(self.judged(hits=(1.0, 1.0)).status, 'alert')

    def test_a_layout_off_the_stated_edge_is_void(self):
        self.assertEqual(self.judged(reach=1.5).status, 'unmeasured')
        self.assertEqual(self.judged(rate=0.5).status, 'unmeasured')
        self.assertEqual(self.judged(area2_x=11.5).status, 'unmeasured')
        self.assertEqual(self.judged(after=(24.0, 24.0, 24.0), hits=(1.0, 1.0), area2_x=11.5).status, 'unmeasured')

    def test_a_missing_read_alerts(self):
        _, [expectation] = self.build()
        values = self.values(expectation)
        del values[expectation.model['area_dummies']['labels']['run_speed_rate']]
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')


if __name__ == '__main__':
    unittest.main()
