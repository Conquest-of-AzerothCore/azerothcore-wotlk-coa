import json
import unittest
from pathlib import Path

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import BEHAVIOUR, DATA, METRIC_EVIDENCE, STATE, STATE_PROMISES, metric_evidence, promised_state, \
    state_promises, verdict_evidence
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

ORIGIN = (-8949.95, -132.49, 83.5)
PLACED = [
    {'dx': -5.0, 'dy': 0.0, 'before_expected': 1, 'expected': 0},
    {'dx': 0.0, 'dy': 5.0, 'before_expected': 1, 'expected': 0},
    {'dx': 0.0, 'dy': -10.5, 'before_expected': 1, 'expected': 0},
    {'dx': 14.0, 'dy': 0.0, 'before_expected': 1, 'expected': 1},
]


def class_file() -> dict:
    return json.load(open(Path(__file__).resolve().parents[1] / 'classes' / 'cultist.json'))


def placed_entry(**changes) -> dict:
    base = next(entry for entry in class_file()['behaviours']
                if entry['spell'] == 804056 and entry.get('label_suffix') == 'interrupt_stops_cast')
    entry = {**base, 'variant': 'interrupt_around', 'label_suffix': 'interrupt_around',
             'area_dummies': {'placed': PLACED, 'casts_before': [12051]}}
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AreaDummiesPlacedTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(class_file(), placed_entry(**changes))

    def values(self, expectation, primary=(1.0, 0.0), area_before=(1.0, 1.0, 1.0, 1.0),
               area_after=(0.0, 0.0, 0.0, 1.0), skew=(0.0, 0.0, 0.0)):
        model = expectation.model['area_dummies']
        placed, labels = model['placed'], model['labels']
        x, y, z = ORIGIN
        values = {expectation.model['before_label']: primary[0], expectation.model['after_label']: primary[1]}
        for axis, coord in zip(labels['positions']['caster'], (x, y, z)):
            values[axis] = coord
        for axis, coord in zip(labels['positions']['dummy'], (x + placed['primary_dx'], y, z)):
            values[axis] = coord
        for index, (name, item) in enumerate(zip(placed['names'], placed['dummies'])):
            sx, sy, sz = skew if index == 0 else (0.0, 0.0, 0.0)
            for axis, coord in zip(labels['positions'][name], (x + item['dx'] + sx, y + item['dy'] + sy, z + sz)):
                values[axis] = coord
            values[labels['before'][name]] = area_before[index]
            values[labels['after'][name]] = area_after[index]
        return values

    def judged(self, entry_changes=None, **value_changes):
        _, [expectation] = self.build(**(entry_changes or {}))
        values = self.values(expectation, **value_changes)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_placed_creatures_geometry_casts_and_per_dummy_reads_validate(self):
        scenario, [expectation] = self.build()
        steps = run.validate(scenario)['steps']
        by_id = {creature['id']: creature for creature in scenario['creatures']}
        self.assertEqual(by_id['dummy']['distance'], 3)
        for index, item in enumerate(PLACED, start=1):
            creature = by_id[f'area{index}']
            self.assertNotIn('distance', creature)
            self.assertEqual((creature['dx'], creature['dy']), (item['dx'], item['dy']))
        self.assertEqual(expectation.model['evidence_metric'], 'area_casting')
        labels = [step.get('label') for step in steps]
        before_idx = labels.index(expectation.model['before_label'])
        after_idx = labels.index(expectation.model['after_label'])
        trigger_idx = next(i for i, step in enumerate(steps)
                           if step.get('action') == 'cast' and step.get('spell') == 804056)
        area_casts = [i for i, step in enumerate(steps)
                      if step.get('action') == 'cast' and step.get('actor') == 'area1' and step.get('spell') == 12051]
        self.assertEqual(len(area_casts), 2)
        self.assertLess(area_casts[0], before_idx)
        self.assertLess(before_idx, area_casts[1])
        self.assertLess(area_casts[1], trigger_idx)
        self.assertLess(labels.index('804056 placed area4 z'), trigger_idx)
        self.assertGreater(labels.index('804056 placed area4 before'), before_idx)
        self.assertGreater(labels.index('804056 placed area4 after'), after_idx)
        self.assertIn('Placed area dummies:', scenario['contract'])

    def test_all_around_interrupted_and_outside_spared_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('placed dummies matched', verdict.explanation)

    def test_seeded_mutants_alert(self):
        self.assertEqual(self.judged(area_after=(1.0, 0.0, 0.0, 1.0)).status, 'alert')
        self.assertEqual(self.judged(area_after=(0.0, 0.0, 0.0, 0.0)).status, 'alert')
        self.assertEqual(self.judged(area_before=(1.0, 0.0, 1.0, 1.0)).status, 'alert')
        self.assertEqual(self.judged(primary=(1.0, 1.0)).status, 'alert')

    def test_misplaced_dummies_or_height_off_void_as_unmeasured(self):
        self.assertEqual(self.judged(skew=(0.5, 0.0, 0.0)).status, 'unmeasured')
        self.assertEqual(self.judged(skew=(0.0, 0.0, 1.5)).status, 'unmeasured')

    def test_missing_read_alerts(self):
        _, [expectation] = self.build()
        values = self.values(expectation)
        del values[expectation.model['area_dummies']['labels']['after']['area1']]
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')

    def test_area_casting_evidence_and_state_promise(self):
        self.assertNotIn('area_casting', METRIC_EVIDENCE)
        self.assertNotIn('area_casting', STATE_PROMISES)
        self.assertEqual(metric_evidence()['area_casting'], STATE)
        self.assertIn('area_casting', state_promises())
        verdict = self.judged()
        self.assertTrue(promised_state(verdict, 'of all enemies around you'))
        self.assertTrue(promised_state(verdict, 'interrupting nearby enemies'))
        self.assertFalse(promised_state(verdict, 'Increases your haste by 3%.'))
        self.assertEqual(verdict_evidence(verdict, 'of all enemies around you', {verdict.label: verdict}), BEHAVIOUR)
        self.assertEqual(verdict_evidence(verdict, 'Increases your haste by 3%.', {verdict.label: verdict}), DATA)

    def test_non_casting_metric_keeps_its_own_evidence_metric(self):
        _, [expectation] = self.build(
            metric='spell_damage_count', fields={'spell': 804056, 'target': 'dummy'},
            measure_actor='caster', before_expected=0, expected=1, target_casts_before=[],
            area_dummies={'placed': [{'dx': -5.0, 'dy': 0.0, 'before_expected': 0, 'expected': 1}]})
        self.assertNotIn('evidence_metric', expectation.model)

    def test_malformed_and_conflicting_placed_entries_are_refused(self):
        one = {'dx': -5.0, 'dy': 0.0, 'before_expected': 1, 'expected': 0}
        for bad in (
                {'placed': []},
                {'placed': [{**one, 'dx': -float(i)} for i in range(1, 13)]},
                {'placed': [one], 'extra': 1},
                {'placed': [one], 'casts_before': []},
                {'placed': [one], 'casts_before': [0]},
                {'placed': [one], 'casts_before': [True]},
                {'placed': [{**one, 'dx': 0.0, 'dy': 0.0}]},
                {'placed': [{**one, 'dx': 80.0, 'dy': 80.0}]},
                {'placed': [{**one, 'dx': True}]},
                {'placed': [{**one, 'tolerance': -0.1}]},
                {'placed': [{key: value for key, value in one.items() if key != 'before_expected'}]},
                {'placed': [one, dict(one)]},
                {'placed': [{**one, 'dx': 3.0, 'dy': 0.0}]},
                {'placed': [{**one, 'expected': 1}]}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                self.build(area_dummies=bad)
        for changes in (
                {'area_sum': True},
                {'relocate_before_trigger': {'dx': 1}},
                {'attack_swings': 3},
                {'measure_actor': 'caster', 'fields': {}},
                {'evidence_metric': 'casting'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.build(**changes)


if __name__ == '__main__':
    unittest.main()
