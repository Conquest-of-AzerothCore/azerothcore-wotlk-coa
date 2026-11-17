import math
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def leap_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (displacement)', 'kind': 'metric_delta',
            'label_suffix': 'leap', 'quote': "to increase your and your Undead minion's haste",
            'expected': 18, 'before_expected': 15, 'expected_gain': 3, 'tolerance': 0.3, 'trigger_spell': 500237,
            'target': 'caster', 'metric': 'position_x', 'fields': {}, 'displacement': {}, 'wait_ms': 1500,
            'expire_ms': 1600, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class DisplacementTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), leap_entry(**changes))

    def test_the_position_is_read_before_each_trigger_cast_and_before_each_judged_reading(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 500237]
        shift = expectation.model['displacement']
        for cast, moment in zip(casts, ('before', 'after')):
            names = shift[moment]
            self.assertEqual([labels.index(names[f'start {axis}']) for axis in 'xyo'],
                             [cast - 3, cast - 2, cast - 1])
            read = labels.index(expectation.model[f'{moment}_label'])
            self.assertEqual([labels.index(names[f'end {axis}']) for axis in 'xy'], [read - 2, read - 1])
            self.assertEqual(steps[cast - 1]['metric'], 'position_o')
        self.assertEqual(expectation.model['evidence_metric'], 'displacement_2d')

    def test_an_uncast_phase_reads_its_start_right_before_its_reading(self):
        scenario, [expectation] = self.built(cast_in_before=False, expected_gain=None, expected=18,
                                             before_expected=0, after_at_least=17.7, after_at_most=18.3)
        labels = [step.get('label') for step in scenario['steps']]
        names = expectation.model['displacement']['before']
        read = labels.index(expectation.model['before_label'])
        self.assertEqual(labels[read - 5:read], [names['start x'], names['start y'], names['start o'],
                                                 names['end x'], names['end y']])

    def judged(self, before_yd, after_yd, missing=None):
        _, [expectation] = self.built()
        shift = expectation.model['displacement']
        values = {expectation.model['before_label']: -1.0, expectation.model['after_label']: -1.0}
        for moment, length in (('before', before_yd), ('after', after_yd)):
            names = shift[moment]
            values.update({names['start x']: 100.0, names['start y']: 50.0, names['start o']: 0.0,
                           names['end x']: 100.0 + length * math.cos(0.3), names['end y']: 50.0 + length * math.sin(0.3)})
        if missing:
            values.pop(shift['after'][missing])
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_gain_is_judged_on_the_displacements_not_on_the_raw_reads(self):
        self.assertEqual(self.judged(15.0, 18.0).status, 'ok')
        self.assertEqual(self.judged(15.0, 15.0).status, 'alert')
        self.assertEqual(self.judged(15.0, 19.0).status, 'alert')
        self.assertEqual(self.judged(12.0, 15.0).status, 'alert')
        self.assertNotEqual(self.judged(15.0, 18.0, missing='end y').status, 'ok')

    def test_a_displacement_state_is_promised_by_range_words(self):
        from coverage import STATE, metric_evidence, promised_state, state_promises
        found = self.judged(15.0, 18.0)
        self.assertEqual(found.detail['metric'], 'displacement_2d')
        self.assertEqual(metric_evidence()['displacement_2d'], STATE)
        self.assertEqual(metric_evidence()['position_x'], STATE)
        self.assertTrue(promised_state(found, 'Increases the base range of Vault by 3 yds.'))
        self.assertFalse(promised_state(found, 'Increases your haste by 3%.'))
        self.assertIn('displacement_2d', state_promises())

    def bearing_judged(self, angle_deg, length=15.0, facing=1.0, bearing=90):
        _, [expectation] = self.built(cast_in_before=False, expected_gain=None, expected=15, before_expected=0,
                                      tolerance=0.3, displacement={'bearing': bearing})
        shift = expectation.model['displacement']
        values = {}
        for moment, moved_yd in (('before', 0.0), ('after', length)):
            names = shift[moment]
            heading = facing + math.radians(angle_deg)
            values.update({names['start x']: 10.0, names['start y']: 20.0, names['start o']: facing,
                           names['end x']: 10.0 + moved_yd * math.cos(heading),
                           names['end y']: 20.0 + moved_yd * math.sin(heading)})
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_stated_bearing_is_judged_from_the_start_facing(self):
        self.assertEqual(self.bearing_judged(90).status, 'ok')
        self.assertEqual(self.bearing_judged(100).status, 'ok')
        self.assertEqual(self.bearing_judged(110).status, 'alert')
        self.assertEqual(self.bearing_judged(0).status, 'alert')
        self.assertEqual(self.bearing_judged(-90).status, 'alert')
        self.assertEqual(self.bearing_judged(180, bearing=180).status, 'ok')
        self.assertEqual(self.bearing_judged(-175, bearing=180).status, 'ok')
        self.assertIn('degrees from the start facing', self.bearing_judged(90).explanation)

    def test_mutant_a_bearing_judged_without_the_start_facing_alerts(self):
        self.assertEqual(self.bearing_judged(90, facing=0.0).status, 'ok')
        self.assertEqual(self.bearing_judged(0, facing=math.pi / 2).status, 'alert')

    def test_a_displacement_entry_reads_the_caster_position_x_only(self):
        for changes in ({'metric': 'aura', 'fields': {'spell': 1}}, {'measure_actor': 'dummy', 'target': 'dummy'},
                        {'displacement': {'bearing': 270}}, {'displacement': {'bearing_tolerance': 10}},
                        {'displacement': {'bearing': 90, 'bearing_tolerance': 90}}, {'displacement': True}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)


if __name__ == '__main__':
    unittest.main()
