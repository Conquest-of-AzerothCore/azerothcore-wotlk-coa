from dataclasses import dataclass
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options import area_sum
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def base_entry() -> dict:
    return next(entry for entry in load_fixture_class_file(23)['behaviours']
                if entry['spell'] == 707562 and entry.get('label_suffix') == 'one_stack_damage')


def summed_entry(**changes) -> dict:
    entry = {**base_entry(), 'variant': 'area_count', 'label_suffix': 'area_count', 'area_dummies': [4.0, 5.0],
             'area_sum': True, 'fields': {**base_entry()['fields'], 'target': 'dummy'}}
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AreaSumTests(unittest.TestCase):
    def test_each_judged_reading_is_followed_by_one_read_per_area_dummy(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), summed_entry())
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        for moment in ('before', 'after'):
            label = expectation.model[f'{moment}_label']
            read = scenario['steps'][labels.index(label)]
            parts = scenario['steps'][labels.index(label) + 1:labels.index(label) + 3]
            self.assertEqual([part['label'] for part in parts], [f'{label} area1', f'{label} area2'])
            self.assertEqual([part['target'] for part in parts], ['area1', 'area2'])
            for part in parts:
                self.assertEqual({**part, 'target': 'dummy', 'label': label}, read)
        self.assertIn('with area1, area2', scenario['contract'])

    def test_a_reading_on_the_dummy_as_actor_sums_over_the_area_dummies_as_actors(self):
        entry = summed_entry(metric='aura', fields={'spell': 707592}, measure_actor='dummy',
                             expected=2, before_expected=0)
        entry = {key: value for key, value in entry.items() if key not in ('expected_gain', 'tolerance')}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        labels = [step.get('label') for step in scenario['steps']]
        label = expectation.model['after_label']
        parts = scenario['steps'][labels.index(label) + 1:labels.index(label) + 3]
        self.assertEqual([(part['actor'], part['metric']) for part in parts], [('area1', 'aura'), ('area2', 'aura')])
        self.assertNotIn('target', parts[0])

    def test_without_the_option_no_area_read_is_made(self):
        entry = {key: value for key, value in summed_entry().items() if key != 'area_sum'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('area_sum', expectation.model)
        self.assertFalse(any(str(step.get('label', '')).endswith((' area1', ' area2')) for step in scenario['steps']))

    def test_refused_inputs(self):
        without_areas = {key: value for key, value in summed_entry().items() if key != 'area_dummies'}
        for entry in (summed_entry(area_sum=False), summed_entry(area_sum=1), without_areas,
                      summed_entry(fields={**base_entry()['fields'], 'target': 'area1'}),
                      summed_entry(measure_actor='dummy'),
                      summed_entry(fields_sum={'spell': 1, 'target': 'dummy'})):
            with self.subTest(entry={key: entry.get(key) for key in ('area_sum', 'area_dummies', 'fields')}):
                with self.assertRaises(ValueError):
                    behaviour_scenario(load_fixture_class_file(23), entry)

    def test_the_judge_reads_the_sum_and_one_more_struck_dummy_alerts(self):
        entry = {key: value for key, value in summed_entry(expected=2, before_expected=0).items()
                 if key not in ('expected_gain', 'tolerance')}
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        before, after = expectation.model['before_label'], expectation.model['after_label']

        def judged(before_reads, after_reads) -> str:
            reads = {}
            for label, values in ((before, before_reads), (after, after_reads)):
                for name, value in zip(('', ' area1', ' area2'), values):
                    if value is not None:
                        reads[f'{label}{name}'] = value
            return judge_behaviour(base_verdict(expectation), FakeRun(reads), expectation).status

        self.assertEqual(judged((0, 0, 0), (1, 1, 0)), 'ok')
        self.assertEqual(judged((0, 0, 0), (0, 1, 1)), 'ok')
        self.assertEqual(judged((0, 0, 0), (1, 1, 1)), 'alert')
        self.assertEqual(judged((0, 0, 0), (1, 0, 0)), 'alert')
        self.assertEqual(judged((0, 1, 0), (1, 1, 0)), 'alert')
        self.assertEqual(judged((0, 0, 0), (1, 1, None)), 'alert')


@dataclass(frozen=True)
class AreaVerdict:
    status: str = 'ok'
    explanation: str = ''


class AreaSingleHitTests(unittest.TestCase):
    def test_secondary_hits_must_land_on_three_distinct_recipients(self):
        areas = ['area1', 'area2', 'area3', 'area4']
        model = {'additional_single_hits': 3, 'areas': areas, 'before': 'before', 'after': 'after'}
        values = {f'before {area}': 0 for area in areas}

        def status(distribution, primary_status='ok'):
            after = {f'after {area}': count for area, count in zip(areas, distribution) if count is not None}
            return area_sum.verdict(AreaVerdict(primary_status), FakeRun(values | after), model).status

        self.assertEqual(status([1, 1, 1, 0]), 'ok')
        self.assertEqual(status([0, 1, 1, 1]), 'ok')
        self.assertEqual(status([2, 1, 0, 0]), 'alert')
        self.assertEqual(status([1, 1, 1, 1]), 'alert')
        self.assertEqual(status([1, 1, 1, None]), 'unmeasured')
        self.assertEqual(status([1, 1, 1, 0], primary_status='alert'), 'alert')
        values['before area1'] = 1
        self.assertEqual(status([1, 1, 1, 0]), 'alert')


if __name__ == '__main__':
    unittest.main()
