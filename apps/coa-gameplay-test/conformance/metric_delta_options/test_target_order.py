import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict


def order_entry(**changes) -> dict:
    return {'spell': 300235, 'name': 'Death Commander (less damage per further target)', 'kind': 'metric_delta',
            'label_suffix': 'order', 'quote': "to increase your and your Undead minion's haste", 'expected': 1,
            'before_expected': 0, 'trigger_spell': 500237, 'target': 'dummy', 'metric': 'spell_damage_count',
            'fields': {'spell': 500237, 'target': 'dummy'}, 'area_dummies': [4.0, 5.0],
            'target_order': {'spell': 500237, 'events': 1, 'centre': 'dummy', 'casts': 2}, **changes}


def expectation_of(entry: dict):
    return behaviour_scenario(load_fixture_class_file(23), entry)[1][0]


def run_values(order: dict, damages: list[list[float]], positions: list[float] | None = None,
               plain: list[list[int]] | None = None, struck: list[list[int]] | None = None) -> dict:
    positions = positions or [0.0, 1.0, 2.0]
    values = {label: 0 for creature in order['base'].values() for label in creature.values()}
    for cast, reads in enumerate(order['casts_reads']):
        for index, creature in enumerate(order['targets']):
            labels = reads[creature]
            values[labels['total']] = sum(row[index] for row in damages[:cast + 1])
            values[labels['plain']] = sum((plain or [[1] * 3] * len(damages))[row][index] for row in range(cast + 1))
            values[labels['struck']] = sum((struck or [[1] * 3] * len(damages))[row][index] for row in range(cast + 1))
        for index, creature in enumerate(order['targets']):
            x, y, z = order['positions'][cast][creature]
            values.update({x: 10.0 + positions[index], y: 20.0, z: 5.0})
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TargetOrderTests(unittest.TestCase):
    def judged(self, values: dict, expectation) -> str:
        return judge_behaviour(base_verdict(expectation), FakeRun({**values, **self.plain(expectation)}),
                               expectation).status

    def plain(self, expectation) -> dict:
        return {expectation.model['before_label']: 0, expectation.model['after_label']: 1}

    def test_each_cast_reads_every_target_and_the_treatment_is_repeated(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), order_entry())
        run.validate(scenario)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] == 500237]
        self.assertEqual(len(casts), 3)
        labels = [step.get('label', '') for step in scenario['steps']]
        order = expectation.model['target_order']
        self.assertEqual(order['targets'], ['dummy', 'area1', 'area2'])
        self.assertLess(labels.index(order['base']['dummy']['total']), labels.index(expectation.model['after_label']))
        self.assertLess(labels.index(expectation.model['after_label']),
                        labels.index(order['casts_reads'][0]['area2']['struck']))
        reads = {step['label']: step for step in scenario['steps'] if step.get('label') in
                 {order['casts_reads'][1]['area1']['total'], order['positions'][1]['area2'][0]}}
        total = reads[order['casts_reads'][1]['area1']['total']]
        self.assertEqual((total['critical'], total['resisted'], total['blocked'], total['target']),
                         (False, False, False, 'area1'))
        self.assertEqual(reads[order['positions'][1]['area2'][0]]['actor'], 'area2')
        waited = sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait')
        self.assertGreater(scenario.get('timeout_ms', 0), waited)

    def test_without_the_option_the_scenario_has_no_order_read(self):
        entry = {key: value for key, value in order_entry().items() if key != 'target_order'}
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertNotIn('target_order', expectation.model)
        self.assertFalse(any(' order ' in str(step.get('label', '')) for step in scenario['steps']))

    def test_malformed_options_are_refused(self):
        for changes in ({'target_order': {'spell': 500237, 'events': 1, 'centre': 'area1', 'casts': 2}},
                        {'target_order': {'spell': 500237, 'events': 0, 'centre': 'dummy', 'casts': 2}},
                        {'target_order': {'spell': 500237, 'events': 1, 'centre': 'dummy'}},
                        {'area_dummies': [4.0]},
                        {'area_dummies': None}):
            entry = {key: value for key, value in order_entry(**changes).items() if value is not None}
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), entry)

    def test_damage_falling_along_the_measured_distance_is_ok(self):
        expectation = expectation_of(order_entry())
        order = expectation.model['target_order']
        self.assertEqual(self.judged(run_values(order, [[100, 90, 80], [101, 91, 79]]), expectation), 'ok')

    def test_the_order_follows_the_measured_distances_not_the_names(self):
        expectation = expectation_of(order_entry())
        order = expectation.model['target_order']
        values = run_values(order, [[100, 80, 90], [100, 80, 90]], positions=[0.0, 2.0, 1.0])
        self.assertEqual(self.judged(values, expectation), 'ok')

    def test_a_reversed_or_flat_falloff_alerts(self):
        expectation = expectation_of(order_entry())
        order = expectation.model['target_order']
        for damages in ([[80, 90, 100], [80, 90, 100]], [[90, 90, 80], [90, 90, 80]], [[100, 90, 95], [100, 90, 95]]):
            with self.subTest(damages=damages):
                self.assertEqual(self.judged(run_values(order, damages), expectation), 'alert')

    def test_a_critical_hit_leaves_that_target_out_of_its_rank_mean(self):
        expectation = expectation_of(order_entry())
        order = expectation.model['target_order']
        values = run_values(order, [[100, 180, 80], [100, 90, 80]], plain=[[1, 0, 1], [1, 1, 1]])
        self.assertEqual(self.judged(values, expectation), 'ok')
        values = run_values(order, [[100, 180, 80], [100, 180, 80]], plain=[[1, 0, 1], [1, 0, 1]])
        self.assertEqual(self.judged(values, expectation), 'unmeasured')

    def test_close_distances_void_the_cast_and_a_wrong_hit_count_alerts(self):
        expectation = expectation_of(order_entry())
        order = expectation.model['target_order']
        values = run_values(order, [[100, 90, 80], [100, 90, 80]], positions=[0.0, 1.0, 1.005])
        self.assertEqual(self.judged(values, expectation), 'unmeasured')
        values = run_values(order, [[100, 90, 80], [100, 90, 80]], struck=[[1, 1, 1], [1, 1, 0]])
        self.assertEqual(self.judged(values, expectation), 'alert')

    def test_a_missing_read_alerts(self):
        expectation = expectation_of(order_entry())
        order = expectation.model['target_order']
        values = run_values(order, [[100, 90, 80], [100, 90, 80]])
        del values[order['casts_reads'][1]['area2']['total']]
        self.assertEqual(self.judged(values, expectation), 'alert')
