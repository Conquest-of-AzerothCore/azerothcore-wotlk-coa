import json
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from pathlib import Path

from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

SOURCE = 'Spell.cpp:1277-1279 default 60 degrees replaced by spell_cone 800654 ConeDegrees 90'
ORIGIN_X, ORIGIN_Y = -8949.95, -132.49


def class_file() -> dict:
    return json.load(open(Path(__file__).resolve().parents[1] / 'classes' / 'sun_cleric.json'))


def cone_entry(**changes) -> dict:
    base = next(entry for entry in class_file()['behaviours']
                if entry['spell'] == 504580 and entry.get('label_suffix') == 'damage')
    entry = {key: value for key, value in base.items() if key not in ('after_at_least', 'after_at_most')}
    entry.update({'variant': 'cone', 'label_suffix': 'cone', 'metric': 'spell_damage_count', 'expected': 1,
                  'fields': {'spell': 504580, 'target': 'dummy'},
                  'area_dummies': {'cone': {'angle': 90, 'radius': 12, 'source': SOURCE}}})
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AreaDummiesConeTests(unittest.TestCase):
    def build(self, **changes):
        return behaviour_scenario(class_file(), cone_entry(**changes))

    def test_dummies_stand_at_planned_bearings_and_the_caster_is_relocated_before_the_cast(self):
        scenario, [expectation] = self.build()
        steps = run.validate(scenario)['steps']
        plan = expectation.model['area_dummies']['cone']['plan']
        distances = {creature['id']: creature['distance'] for creature in scenario['creatures']}
        self.assertAlmostEqual(distances['dummy'], plan['x']['inside'])
        self.assertAlmostEqual(distances['area1'], plan['x']['outside'])
        self.assertAlmostEqual(distances['area2'], plan['x']['behind'])
        self.assertEqual(plan['bearing'], {'inside': 40.5, 'outside': 49.5, 'behind': 135.0})
        relocate = next(index for index, step in enumerate(steps) if step['action'] == 'relocate')
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 504580)
        self.assertLess(relocate, cast)
        self.assertEqual((steps[relocate]['dx'], steps[relocate]['dy']), (plan['start'], -plan['offset']))
        labels = [step.get('label') for step in steps]
        self.assertLess(labels.index('504580 cone caster o'), cast + len(steps))
        self.assertTrue(all(label in labels for triple in expectation.model['area_dummies']['labels']['positions'].values()
                            for label in triple))

    def test_the_list_form_and_entries_without_the_option_are_unchanged(self):
        scenario, [expectation] = self.build(area_dummies=[4.0, 5.0])
        self.assertNotIn('area_dummies', expectation.model)
        self.assertFalse(any(step.get('action') == 'relocate' for step in scenario['steps']))

    def test_malformed_cones_are_refused(self):
        good = {'angle': 90, 'radius': 12, 'source': SOURCE}
        for cone in ({**good, 'source': 'first read'}, {**good, 'angle': 170}, {**good, 'radius': 6},
                     {key: value for key, value in good.items() if key != 'source'}, {**good, 'behind': 90},
                     {**good, 'margin_pct': 0}, {**good, 'offset': 1}):
            with self.subTest(cone=cone), self.assertRaises(ValueError):
                self.build(area_dummies={'cone': cone})
        with self.assertRaises(ValueError):
            self.build(area_dummies={'cone': good, 'extra': 1})
        with self.assertRaises(ValueError):
            self.build(metric='spell_damage_total')

    def values(self, expectation, inside=1.0, outside=0.0, behind=0.0, orientation=0.0, skew=0.0):
        model = expectation.model['area_dummies']
        plan, labels = model['cone']['plan'], model['labels']
        values = {expectation.model['before_label']: 0.0, expectation.model['after_label']: inside}
        values[labels['caster'][0]] = ORIGIN_X + plan['start']
        values[labels['caster'][1]] = ORIGIN_Y - plan['offset']
        values[labels['caster'][2]] = orientation
        values[labels['caster_z']] = 83.5
        for unit, arm in zip(('dummy', 'area1', 'area2'), ('inside', 'outside', 'behind')):
            x, y, z = labels['positions'][unit]
            values[x] = ORIGIN_X + plan['x'][arm]
            values[y] = ORIGIN_Y + (skew if unit == 'area1' else 0.0)
            values[z] = 83.5
        values[labels['hits']['outside']] = outside
        values[labels['hits']['behind']] = behind
        return values

    def judged(self, **changes):
        _, [expectation] = self.build()
        values = self.values(expectation, **changes)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_inside_struck_outside_and_behind_spared_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('bearings from the read positions', verdict.explanation)

    def test_seeded_mutants_alert_or_void(self):
        self.assertEqual(self.judged(outside=1.0).status, 'alert')
        self.assertEqual(self.judged(behind=1.0).status, 'alert')
        self.assertNotEqual(self.judged(inside=0.0).status, 'ok')
        self.assertEqual(self.judged(orientation=0.3).status, 'unmeasured')
        self.assertEqual(self.judged(skew=2.0).status, 'unmeasured')

    def test_a_missing_read_alerts(self):
        _, [expectation] = self.build()
        values = self.values(expectation)
        del values[expectation.model['area_dummies']['labels']['caster'][2]]
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'alert')


if __name__ == '__main__':
    unittest.main()
