from pathlib import Path
import sys
import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from periodic_dispel_party import party_pulse_spec, period_bracket
from profile import DBC_DIR, load_fixture_class_file

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run
from values import Expectation

WITCHING_IDOL = 804051
FEAR, SLEEP, CHARM = 65931, 9159, 6358
STEP_MS = 3
FIRST_PULSE_MS = 3
EDGE_PULSE = {'radius_spell': 853203, 'pulses': 2, 'near_distance': 18.0, 'far_margin': 2.0}


class SeededRun:
    def __init__(self, values):
        self.values = values
        self.key = 'seeded'
        self.status = 'completed'
        self.message = ''
        self.steps = []
        self.max_step_ms = None
        self.cast_failures = {}


def base_verdict(expectation: Expectation) -> Verdict:
    return Verdict(expectation.label, 'alert', None, None, None, None, '', 'seeded-key', expectation.spell_id,
                   expectation.rank_id, expectation.check)


def idol_entry(**changes) -> dict:
    return {'spell': WITCHING_IDOL, 'name': 'Witching Idol (party pulse dispel)', 'kind': 'periodic_dispel',
            'quote': 'periodically dispels fear, sleep, and charm effects every $806696T1 sec from party members '
                     'within $853203a1 yds.',
            'debuffs': [FEAR, SLEEP, CHARM], 'period_ms': 2500, 'margin_ms': 100,
            'party_pulse': {'radius_spell': 853203, 'pulses': 2}, **changes}


def simulated(steps: list[dict], period_ms: int, removed_per_pulse: int | None = None, reaches_far: bool = False,
              radius_yd: float | None = None) -> SeededRun:
    auras = {'ally': [], 'ally_far': []}
    placed = {ally: sum(step['dx'] for step in steps if step['action'] == 'relocate' and step['actor'] == ally)
              for ally in auras}
    reached = (tuple(ally for ally in auras if placed[ally] <= radius_yd) if radius_yd is not None
               else ('ally', 'ally_far') if reaches_far else ('ally',))
    values, clock, cast_at, next_pulse = {}, 0, None, None

    def pulse_until(moment: int):
        nonlocal next_pulse
        while next_pulse is not None and next_pulse <= moment:
            for ally in reached:
                keep = 0 if removed_per_pulse is None else max(len(auras[ally]) - removed_per_pulse, 0)
                auras[ally] = auras[ally][len(auras[ally]) - keep:]
            next_pulse += period_ms

    for step in steps:
        clock += step['ms'] if step['action'] == 'wait' else STEP_MS
        pulse_until(clock)
        if step['action'] == 'cast' and step.get('spell') == WITCHING_IDOL:
            cast_at = clock
            next_pulse = cast_at + FIRST_PULSE_MS
        elif step['action'] == 'set_aura' and step['actor'] in auras:
            held = [spell for spell in auras[step['actor']] if spell != step['spell']]
            auras[step['actor']] = held + ([step['spell']] if step['stacks'] else [])
        elif step['action'] == 'assert' and step.get('metric') == 'aura' and step['actor'] in auras:
            values[step['label']] = 1.0 if step['spell'] in auras[step['actor']] else 0.0
    return SeededRun(values)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PartyPulseTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(19), idol_entry(**changes))

    def statuses(self, run_values: SeededRun, expectations) -> dict[str, str]:
        return {expectation.label: judge_behaviour(base_verdict(expectation), run_values, expectation).status
                for expectation in expectations}

    def test_reads_control_every_pulse_and_the_far_member(self):
        scenario, expectations = self.built()
        run.validate(scenario)
        self.assertEqual([(e.label.removeprefix(f'{WITCHING_IDOL} periodic_dispel '), e.displayed)
                          for e in expectations],
                         [('control', '3'), ('far_control', '3'), ('after_0', '0'), ('before_1', '3'),
                          ('after_1', '0'), ('before_2', '3'), ('after_2', '0'), ('far_after_2', '3')])
        waits = [step['ms'] for step in scenario['steps'] if step.get('label', '').endswith(' wait')]
        self.assertEqual(waits, [5100, 100, 2300, 200, 2300, 200])
        self.assertEqual(period_bracket(party_pulse_spec(idol_entry())), (2300, 2600))
        groups = [step['target'] for step in scenario['steps'] if step['action'] == 'group']
        self.assertEqual(groups, ['ally', 'ally_far'])
        far = sum(step['dx'] for step in scenario['steps'] if step['action'] == 'relocate'
                  and step['actor'] == 'ally_far')
        self.assertEqual(far, 35.0)

    def test_seeded_all_removed_each_pulse_is_ok(self):
        scenario, expectations = self.built()
        self.assertEqual(set(self.statuses(simulated(scenario['steps'], 2500), expectations).values()), {'ok'})

    def test_mutant_one_removal_per_pulse_alerts(self):
        scenario, expectations = self.built()
        statuses = self.statuses(simulated(scenario['steps'], 2500, removed_per_pulse=1), expectations)
        self.assertEqual(statuses[f'{WITCHING_IDOL} periodic_dispel after_0'], 'alert')

    def test_mutant_reaching_the_far_member_alerts(self):
        scenario, expectations = self.built()
        statuses = self.statuses(simulated(scenario['steps'], 2500, reaches_far=True), expectations)
        self.assertEqual(statuses[f'{WITCHING_IDOL} periodic_dispel far_after_2'], 'alert')

    def test_mutant_periods_ten_percent_off_alert(self):
        scenario, expectations = self.built()
        for period in (2250, 2750):
            with self.subTest(period=period):
                statuses = self.statuses(simulated(scenario['steps'], period), expectations)
                self.assertIn('alert', statuses.values())

    def test_mutant_no_dispel_alerts(self):
        scenario, expectations = self.built()
        statuses = self.statuses(simulated(scenario['steps'], 10 ** 9), expectations)
        self.assertEqual(statuses[f'{WITCHING_IDOL} periodic_dispel after_1'], 'alert')

    def test_refuses_a_wide_margin_an_uncovered_mechanic_or_a_short_window(self):
        for changes in ({'margin_ms': 200}, {'debuffs': [FEAR, SLEEP]}, {'debuffs': [FEAR, SLEEP, CHARM, 55095]},
                        {'party_pulse': {'radius_spell': 806696, 'pulses': 2}},
                        {'party_pulse': {'radius_spell': 853203, 'pulses': 1}},
                        {'party_pulse': {'radius_spell': 853203, 'pulses': 4}},
                        {'party_pulse': {'radius_spell': 853203, 'pulse': 2}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)

    def test_far_margin_and_near_distance_bracket_the_radius(self):
        scenario, _ = self.built(party_pulse=EDGE_PULSE)
        run.validate(scenario)
        placed = {ally: sum(step['dx'] for step in scenario['steps']
                            if step['action'] == 'relocate' and step['actor'] == ally) for ally in ('ally', 'ally_far')}
        self.assertEqual(placed, {'ally': 18.0, 'ally_far': 22.0})
        self.assertIn('A party member 18 yd away and a party member 22 yd away', scenario['contract'])

    def test_seeded_radius_of_twenty_is_ok_at_the_edges(self):
        scenario, expectations = self.built(party_pulse=EDGE_PULSE)
        statuses = self.statuses(simulated(scenario['steps'], 2500, radius_yd=20.0), expectations)
        self.assertEqual(set(statuses.values()), {'ok'})

    def test_mutant_radius_of_thirty_or_fifteen_alerts(self):
        scenario, expectations = self.built(party_pulse=EDGE_PULSE)
        wide = self.statuses(simulated(scenario['steps'], 2500, radius_yd=30.0), expectations)
        self.assertEqual(wide[f'{WITCHING_IDOL} periodic_dispel far_after_2'], 'alert')
        narrow = self.statuses(simulated(scenario['steps'], 2500, radius_yd=15.0), expectations)
        self.assertEqual(narrow[f'{WITCHING_IDOL} periodic_dispel after_0'], 'alert')

    def test_default_placement_is_unchanged_without_the_fields(self):
        default, _ = self.built()
        explicit, _ = self.built(party_pulse={'radius_spell': 853203, 'pulses': 2, 'near_distance': 3.0,
                                              'far_margin': 15.0})
        self.assertEqual(default, explicit)

    def test_refuses_a_near_member_outside_the_radius_or_no_far_margin(self):
        for changes in ({'near_distance': 20.0}, {'near_distance': 0.0}, {'far_margin': 0.0}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(party_pulse={**EDGE_PULSE, **changes})

    def test_near_limit_places_the_near_member_beyond_the_radius_and_inside_the_limit(self):
        pulse = {**EDGE_PULSE, 'near_distance': 21.0, 'far_margin': 4.0, 'near_limit': 22.5, 'note': 'Ruling O-47.'}
        scenario, expectations = self.built(party_pulse=pulse)
        run.validate(scenario)
        placed = {ally: sum(step['dx'] for step in scenario['steps']
                            if step['action'] == 'relocate' and step['actor'] == ally) for ally in ('ally', 'ally_far')}
        self.assertEqual(placed, {'ally': 21.0, 'ally_far': 24.0})
        self.assertTrue(scenario['contract'].endswith('Ruling O-47.'))
        reach = self.statuses(simulated(scenario['steps'], 2500, radius_yd=22.5), expectations)
        self.assertEqual(set(reach.values()), {'ok'})
        for radius in (20.0, 25.0):
            wrong = self.statuses(simulated(scenario['steps'], 2500, radius_yd=radius), expectations)
            self.assertIn('alert', wrong.values())

    def test_near_limit_refuses_an_unordered_bracket_and_stays_inert_unset(self):
        for changes in ({'near_limit': 19.0}, {'near_distance': 21.0, 'near_limit': 20.5},
                        {'near_distance': 21.0, 'far_margin': 1.0, 'near_limit': 22.5}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(party_pulse={**EDGE_PULSE, **changes})
        unset, _ = self.built(party_pulse=EDGE_PULSE)
        none, _ = self.built(party_pulse={**EDGE_PULSE, 'near_limit': None})
        self.assertEqual(unset, none)

    def test_without_party_pulse_the_entry_keeps_the_one_per_period_model(self):
        entry = idol_entry()
        del entry['party_pulse']
        _, expectations = behaviour_scenario(load_fixture_class_file(19), entry)
        self.assertEqual([e.displayed for e in expectations], ['3', '3', '2', '1', '0'])


if __name__ == '__main__':
    unittest.main()
