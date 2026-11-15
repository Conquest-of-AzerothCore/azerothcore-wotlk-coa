import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

ECLIPSE = 811117
ECLIPSE_HIT = 802717
LEECH = 803287
POTION = 801661
INGREDIENT = 801664
HEX = 801693
CLASS_FILE = {'class_id': 13, 'name': 'Witch Doctor', 'race': 1, 'level': 60, 'skill_lines': [],
              'reference_stats': {}}
ENTRY = {'spell': INGREDIENT, 'name': 'Ingredient: Bloodthistle (Potion leech once every 0.5 sec)',
         'kind': 'proc_gate_interval', 'label_suffix': 'gate', 'quote': 'Can only occur once every 0.5 sec.',
         'gate_ms': 500, 'learn': [92085, INGREDIENT, POTION],
         'setup_casts': [[INGREDIENT, 'caster'], [POTION, 'caster']], 'trigger_casts': [[ECLIPSE, 'dummy']],
         'cast_auras': [[561136, 5]], 'cast_power': 2000, 'cast_wait_ms': 1600, 'control_ms': 1400, 'windows': 4,
         'window_ms': 1400, 'since_spell': ECLIPSE,
         'trigger': {'stream': 'spell_damage', 'spell': ECLIPSE_HIT, 'target': 'dummy'},
         'output': {'stream': 'spell_heal', 'spell': LEECH, 'target': 'caster'}, 'amount_pct': 5,
         'cause_auras': [[802975, POTION]], 'fixture': {'spell_power': 2000, 'ranged_hit_rating': 10000}}
WARDS = {'spell': 807450, 'name': 'Hexfire Mass (Serpent Ward once every 3 sec)', 'kind': 'proc_gate_interval',
         'label_suffix': 'gate', 'quote': 'Can only occur once every 3 sec.', 'gate_ms': 3000, 'learn': [HEX],
         'talent': 807450, 'forced_talent': 807450,
         'trigger_casts': [[HEX, 'dummy'], [HEX, 'dummy2'], [HEX, 'dummy3'], [HEX, 'dummy4']], 'cast_power': 2000,
         'cast_wait_ms': 2250, 'control_ms': 1000, 'windows': 1, 'window_casts': False, 'window_ms': 12500,
         'since_spell': HEX, 'trigger': {'stream': 'spell_damage', 'spell': HEX},
         'output': {'event': 'spawn', 'source_entry': 50587}, 'dummies': 4}
FAIR = (5, 3, 250.0, 500.0, 500.0)
EDGE = (5, 2, 250.0, 750.0, 750.0)


def gate_values(expectation, windows, control=(5, 0), amount=75.0, released=None) -> dict:
    model = expectation.model
    values, triggers, outputs = {}, 0.0, 0.0

    def edge(labels: dict, side: str):
        values[labels[f'{side} triggers']], values[labels[f'{side} outputs']] = triggers, outputs
        if f'{side} amount' in labels:
            values[labels[f'{side} amount']] = triggers * amount

    edge(model['control'], 'start')
    triggers, outputs = triggers + control[0], outputs + control[1]
    edge(model['control'], 'end')
    for labels, (fired, answered, trigger_gap, shortest, longest) in zip(model['windows'], windows):
        edge(labels, 'start')
        triggers, outputs = triggers + fired, outputs + answered
        edge(labels, 'end')
        values[labels['trigger gap max']] = trigger_gap
        values[labels['output gap min']], values[labels['output gap max']] = shortest, longest
    if model['released']:
        values[model['released']] = 0.0 if released is None else released
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ProcGateIntervalTests(unittest.TestCase):
    def judged(self, windows=(FAIR,) * 4, entry=ENTRY, **values):
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        return judge_behaviour(base_verdict(expectation), FakeRun(gate_values(expectation, windows, **values)),
                               expectation)

    def test_the_control_round_comes_before_the_potion_and_the_windows_after(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, ENTRY)
        run.validate(scenario, run.SIMULATED_CLOCK)
        casts = [step['spell'] for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [ECLIPSE, INGREDIENT, POTION] + [ECLIPSE] * 4)
        self.assertEqual(scenario['players'][0]['spell_power'], 2000)

    def test_a_gate_pinned_by_an_accepted_and_a_refused_edge_hit_passes(self):
        verdict = self.judged(windows=(FAIR, EDGE, FAIR, EDGE))
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('a trigger 500 ms after an output was refused and an output followed the previous one after '
                      '500 ms, so the edge trigger was refused once and accepted once: the gate sits on the edge at '
                      '500 ms, inside 475 to 525 ms', verdict.explanation)
        self.assertNotIn('excluding', verdict.explanation)

    def test_a_bracket_inside_the_band_passes_with_the_excluded_gates_stated(self):
        verdict = self.judged(windows=(FAIR, (5, 2, 250.0, 730.0, 730.0), FAIR, FAIR))
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('the gate lies above 480 ms (a trigger that late was refused) and at most 500 ms (the shortest '
                      'output interval): the bracket 480 to 500 ms lies inside 475 to 525 ms, excluding a gate at or '
                      'below 480 ms and one above 500 ms', verdict.explanation)

    def test_a_bracket_wider_than_the_band_is_unmeasured_with_the_bracket_stated(self):
        accepted = self.judged()
        self.assertEqual(accepted.status, 'unmeasured')
        self.assertIn('250 to 500 ms reaches outside 475 to 525 ms', accepted.explanation)
        refused = self.judged(windows=(EDGE,) * 4)
        self.assertEqual(refused.status, 'unmeasured')
        self.assertIn('500 to 750 ms reaches outside', refused.explanation)

    def test_near_mutants_at_three_fifths_and_seven_fifths_of_the_gate_do_not_pass(self):
        self.assertNotEqual(self.judged(windows=(FAIR,) * 4).status, 'ok')
        self.assertNotEqual(self.judged(windows=(EDGE,) * 4).status, 'ok')

    def test_the_mutant_without_a_gate_alerts(self):
        verdict = self.judged(windows=((5, 5, 250.0, 250.0, 250.0),) * 4)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 250.0)

    def test_the_mutant_with_a_doubled_gate_alerts(self):
        self.assertEqual(self.judged(windows=((5, 2, 250.0, 1000.0, 1000.0),) * 4).status, 'alert')

    def test_an_output_in_the_control_alerts(self):
        self.assertEqual(self.judged(control=(5, 1)).status, 'alert')

    def test_a_missing_release_read_is_a_missing_measurement(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, WARDS)
        values = gate_values(expectation, ((20, 5, 750.0, 3000.0, 3750.0),), control=(9, 0))
        del values[expectation.model['released']]
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertIn('no measurement', verdict.explanation)
        self.assertIn('released', verdict.explanation)

    def test_a_leech_that_rounds_to_nothing_is_unmeasured(self):
        self.assertEqual(self.judged(amount=15.0).status, 'unmeasured')

    def test_triggers_wider_than_the_window_are_unmeasured(self):
        self.assertEqual(self.judged(windows=((3, 2, 500.0, 500.0, 500.0),) * 4).status, 'unmeasured')

    def test_a_single_output_per_window_is_unmeasured(self):
        self.assertEqual(self.judged(windows=((5, 1, 250.0, float('nan'), float('nan')),) * 4).status,
                         'unmeasured')

    def test_a_cause_aura_that_lapses_before_the_last_window_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**ENTRY, 'windows': 5})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {key: value for key, value in ENTRY.items() if key != 'cause_auras'})

    def test_the_eclipse_hits_cannot_miss(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, ENTRY)
        self.assertEqual(scenario['players'][0]['ranged_hit_rating'], 10000)

    def test_a_wait_shorter_than_the_global_cooldown_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**ENTRY, 'cast_wait_ms': 1000})

    def test_the_ward_timeline_starts_before_the_hexes_and_the_talent_follows_them(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, WARDS)
        run.validate(scenario, run.SIMULATED_CLOCK)
        actions = [(step['action'], step.get('spell')) for step in scenario['steps']]
        self.assertLess(actions.index(('encounter_start', None)), actions.index(('cast', HEX)))
        self.assertLess(actions.index(('spell_mod_mutant', 807450)), actions.index(('cast', HEX)))
        self.assertGreater(actions.index(('learn', 807450)), max(index for index, action in enumerate(actions)
                                                                 if action == ('cast', HEX)))
        self.assertEqual(len(scenario['creatures']), 4)

    def test_ward_spawns_three_to_four_ticks_apart_pass_and_a_kept_mutant_alerts(self):
        windows = ((20, 5, 750.0, 3000.0, 3750.0),)
        self.assertEqual(self.judged(windows=windows, entry=WARDS, control=(9, 0)).status, 'ok')
        self.assertEqual(self.judged(windows=windows, entry=WARDS, control=(9, 0), released=1.0).status, 'alert')
        self.assertEqual(self.judged(windows=((20, 20, 750.0, 750.0, 750.0),), entry=WARDS,
                                     control=(9, 0)).status, 'alert')

    def test_ward_gates_three_fifths_and_seven_fifths_of_the_stated_one_alert(self):
        self.assertEqual(self.judged(windows=((17, 6, 750.0, 2250.0, 2250.0),), entry=WARDS,
                                     control=(9, 0)).status, 'alert')
        self.assertEqual(self.judged(windows=((17, 3, 750.0, 4500.0, 4500.0),), entry=WARDS,
                                     control=(9, 0)).status, 'alert')

    def test_ward_gates_off_the_tick_edge_are_unmeasured(self):
        self.assertEqual(self.judged(windows=((17, 5, 750.0, 3000.0, 3000.0),), entry=WARDS,
                                     control=(9, 0)).status, 'unmeasured')
        self.assertEqual(self.judged(windows=((17, 4, 750.0, 3750.0, 3750.0),), entry=WARDS,
                                     control=(9, 0)).status, 'unmeasured')

    def test_a_window_past_the_hex_duration_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**WARDS, 'window_ms': 20000})
