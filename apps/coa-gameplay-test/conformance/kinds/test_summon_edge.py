import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

ENTRY = {'spell': 500961, 'kind': 'summon_edge', 'label_suffix': 'ally_edge',
         'name': 'Spirit Idol (a grouped ally inside the 30 yd edge is energized, one beyond is not)',
         'quote': 'Allies within $500958A1 yds', 'summon_spell': 500961, 'summon_entry': 50106, 'radius': 30,
         'role': 'ally', 'metric': 'spell_energize_count', 'fields': {'spell': 805282, 'caster_entry': 50106},
         'inside_yd': -0.5, 'beyond_yd': 0.5, 'wait_ms': 6500, 'witness': True}
ENEMY_ENTRY = {**ENTRY, 'spell': 505339, 'label_suffix': 'enemy_edge', 'quote': 'Enemies within $504761a1 yds',
               'summon_spell': 505339, 'summon_entry': 50119, 'role': 'enemy', 'metric': 'aura',
               'fields': {'spell': 504761}, 'witness': False, 'wait_ms': 4500}
OWNER_ENTRY = {**ENTRY, 'spell': 802719, 'label_suffix': 'field_owner_beyond', 'quote': 'While within $802718a1 yds,',
               'summon_spell': 802719, 'summon_entry': 310659, 'radius': 15, 'role': 'owner',
               'owner_side': 'beyond', 'cell_search': False, 'metric': 'aura', 'fields': {'spell': 802718},
               'witness': False, 'wait_ms': 3000}
CENTRE = (-8900.0, -120.0, 82.0)
REACH = {'centre': 0.5, 'inside': 1.5, 'beyond': 1.5}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SummonEdgeTests(unittest.TestCase):
    def judged(self, entry: dict, inside: float, beyond: float, witness: float = 2.0,
               offsets: tuple[float, float] = (-0.5, 0.5), dz: float = 0.0, centre: tuple = CENTRE) -> Verdict:
        _, [expectation] = behaviour_scenario(load_fixture_class_file(23), entry)
        model = expectation.model
        values = {}
        for moment, reads in model['reads'].items():
            gained = moment == 'end'
            for side, value in (('inside', inside), ('beyond', beyond)):
                if side in reads:
                    values[reads[side]] = value if gained else 0.0
            if 'witness' in reads:
                values[reads['witness']] = witness if gained else 0.0
        for moment, units in model['geometry'].items():
            for unit, reads in units.items():
                along = 0.0 if unit == 'centre' else (model['radius'] + REACH['centre'] + REACH[unit]
                                                      + offsets[unit == 'beyond'])
                values[reads['x']] = centre[0] + along
                values[reads['y']] = centre[1]
                values[reads['z']] = centre[2] + (dz if unit != 'centre' else 0.0)
                values[reads['reach']] = REACH[unit]
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                       expectation.rank_id, expectation.check)
        return judge_behaviour(base, FakeRun(values), expectation)

    def test_the_units_are_placed_around_the_summon(self):
        for entry in (ENTRY, ENEMY_ENTRY):
            scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
            run.validate(scenario)
            moves = [step for step in scenario['steps'] if step['action'] == 'relocate']
            self.assertEqual([step['edge_offset'] for step in moves], [-0.5, 0.5])
            self.assertTrue(all(step['around_entry'] == entry['summon_entry'] for step in moves))
        enemy, _ = behaviour_scenario(load_fixture_class_file(23), ENEMY_ENTRY)
        self.assertIn('location', enemy)

    def test_inside_reached_and_beyond_spared_passes(self):
        self.assertEqual(self.judged(ENTRY, 2, 0).status, 'ok')
        self.assertEqual(self.judged(ENEMY_ENTRY, 1, 0).status, 'ok')

    def test_a_reached_beyond_or_a_missed_inside_alerts(self):
        self.assertEqual(self.judged(ENTRY, 2, 2).status, 'alert')
        self.assertEqual(self.judged(ENTRY, 0, 0).status, 'alert')
        self.assertEqual(self.judged(ENEMY_ENTRY, 1, 1).status, 'alert')

    def test_the_owner_stands_on_one_side_without_a_grid_check(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), OWNER_ENTRY)
        run.validate(scenario)
        self.assertEqual([player['id'] for player in scenario['players']], ['caster'])
        moves = [step for step in scenario['steps'] if step['action'] == 'relocate']
        self.assertEqual([(step['actor'], step['edge_offset']) for step in moves], [('caster', 0.5)])
        cell = 533.3333 / 8
        on_edge = (-56 * cell - 15.75, CENTRE[1], CENTRE[2])
        self.assertEqual(self.judged(OWNER_ENTRY, 0, 0, centre=on_edge).status, 'ok')
        self.assertEqual(self.judged(OWNER_ENTRY, 0, 1).status, 'alert')
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), {**OWNER_ENTRY, 'owner_side': None})

    def test_a_silent_summon_is_unmeasured(self):
        self.assertEqual(self.judged(ENTRY, 0, 0, witness=0).status, 'unmeasured')

    def test_a_layout_off_the_edge_is_unmeasured(self):
        self.assertEqual(self.judged(ENTRY, 2, 0, offsets=(-0.1, 0.5)).status, 'unmeasured')
        self.assertEqual(self.judged(ENTRY, 2, 0, dz=10.0).status, 'unmeasured')

    def test_a_unit_in_an_unvisited_cell_is_unmeasured(self):
        cell = 533.3333 / 8
        on_edge = (-56 * cell - 30.75, CENTRE[1], CENTRE[2])
        self.assertEqual(self.judged(ENTRY, 2, 0, centre=on_edge).status, 'unmeasured')

    def test_refused_inputs(self):
        for changes in ({'role': 'friend'}, {'metric': 'health'}, {'inside_yd': -0.1}, {'beyond_yd': 3.0},
                        {'witness': True, 'metric': 'aura', 'fields': {'spell': 504761}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})


if __name__ == '__main__':
    unittest.main()
