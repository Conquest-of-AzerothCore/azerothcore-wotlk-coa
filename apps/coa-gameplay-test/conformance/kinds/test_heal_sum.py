import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

SHROOMS, PULSE, FROG_BONES, BOOMS, BREWER = 801660, 802703, 801663, 705859, 92085
SPLASH, BREW, ECHO = 567736, 501205, 899906

BOOMS_ENTRY = {
    'spell': BOOMS, 'kind': 'heal_sum', 'variant': 'booms_targets', 'name': 'Jungle Booms',
    'quote': 'but heals $s2 less targets.', 'gate_spell': BOOMS, 'learn': [BREWER],
    'allies': [{'id': f'a{index}', 'dx': 3 * index, 'dy': 0} for index in range(1, 8)],
    'casts': [{'spell': FROG_BONES, 'target': CASTER, 'watch_ms': 1600, 'poll_ms': 400},
              {'spell': SHROOMS, 'target': CASTER, 'watch_ms': 6500, 'poll_ms': 500}],
    'checks': [{'name': 'booms_targets', 'judge': 'cap', 'spell': PULSE, 'expected': 5, 'control_expected': 8,
                'witness': 'control'}]}

SPLASH_ENTRY = {
    'spell': SPLASH, 'kind': 'heal_sum', 'variant': 'splash_cap', 'name': 'Splash Potion',
    'quote': 'healing up to $i allies', 'learn': [BREWER],
    'creatures': [{'id': f'c{index}', 'entry': 631, 'distance': index + 1} for index in range(1, 9)],
    'casts': [{'spell': FROG_BONES, 'target': CASTER, 'watch_ms': 1600, 'poll_ms': 400}] +
             [{'spell': SPLASH, 'target': CASTER, 'watch_ms': 1600, 'poll_ms': 400}] * 2,
    'checks': [{'name': 'splash_cap', 'judge': 'cap', 'spell': SPLASH, 'expected': 16, 'witness': 'treatment'}]}

ECHO_ENTRY = {
    'spell': BREW, 'kind': 'heal_sum', 'variant': 'echo_half', 'name': "Loa's Brew echo",
    'quote': "Healing a different target with Loa's Brew also heals your previous Loa's Brew target",
    'allies': [{'id': 'first', 'dx': 10, 'dy': 0, 'health': 2000, 'maximum': 20000},
               {'id': 'second', 'dx': 15, 'dy': 0, 'health': 2000, 'maximum': 20000}],
    'casts': [{'spell': BREW, 'target': 'first', 'watch_ms': 4000, 'poll_ms': 500},
              {'spell': BREW, 'target': 'second', 'watch_ms': 4000, 'poll_ms': 500}],
    'checks': [{'name': 'echo_half', 'judge': 'pair', 'spell': ECHO, 'on': 'first', 'source': BREW,
                'source_on': 'second', 'expected': 0.5, 'band': [-0.5, 0.0], 'band_reason': 'uint32 halving'}]}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(13), entry)


def values_of(expectation, heals: dict) -> dict:
    values = {}
    for phase, units in expectation.model['reads'].items():
        for unit, spells in units.items():
            for spell, fields in spells.items():
                read = heals.get(phase, {}).get(unit, {}).get(int(spell), (0, 0, 0))
                for (field, (start, end)), value in zip(fields.items(), read):
                    values[start] = 100.0
                    values[end] = 100.0 + value
    return values


def judged(expectation, heals: dict):
    return judge_behaviour(base_verdict(expectation), FakeRun(values_of(expectation, heals)), expectation)


def counts(phase_counts: dict, spell: int) -> dict:
    return {phase: {unit: {spell: (count, count * 90, count * 90)} for unit, count in units.items()}
            for phase, units in phase_counts.items()}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class HealSumTests(unittest.TestCase):
    def test_scenarios_are_valid_and_read_every_unit(self):
        for entry in (BOOMS_ENTRY, SPLASH_ENTRY, ECHO_ENTRY):
            with self.subTest(entry=entry['variant']):
                scenario, [expectation] = scenario_of(entry)
                run.validate(scenario)
                self.assertEqual(expectation.label, f'{entry["spell"]} behaviour_metric_delta {entry["variant"]}')
                self.assertEqual(expectation.model['units'][0], CASTER)
        scenario, [expectation] = scenario_of(SPLASH_ENTRY)
        self.assertEqual([creature['entry'] for creature in scenario['creatures']], [631] * 8)
        self.assertEqual(len(expectation.model['units']), 9)

    def test_cap_judges_the_sum_and_the_control(self):
        _, [expectation] = scenario_of(BOOMS_ENTRY)
        units = expectation.model['units']
        control = {unit: 1 for unit in units}
        treatment = {unit: (1 if index < 5 else 0) for index, unit in enumerate(units)}
        self.assertEqual(judged(expectation, counts({'control': control, 'treatment': treatment}, PULSE)).status,
                         'ok')
        self.assertEqual(judged(expectation, counts({'control': control, 'treatment': control}, PULSE)).status,
                         'alert')
        four = {unit: (1 if index < 4 else 0) for index, unit in enumerate(units)}
        self.assertEqual(judged(expectation, counts({'control': control, 'treatment': four}, PULSE)).status,
                         'alert')
        short = {**control, units[-1]: 0}
        self.assertEqual(judged(expectation, counts({'control': short, 'treatment': treatment}, PULSE)).status,
                         'unmeasured')

    def test_cap_without_gate_needs_every_unit_in_the_treatment_window(self):
        _, [expectation] = scenario_of(SPLASH_ENTRY)
        units = expectation.model['units']
        right = {unit: (2 if index < 7 else 1) for index, unit in enumerate(units)}
        self.assertEqual(judged(expectation, counts({'treatment': right}, SPLASH)).status, 'ok')
        uncapped = {unit: 2 for unit in units}
        self.assertEqual(judged(expectation, counts({'treatment': uncapped}, SPLASH)).status, 'alert')
        hidden = {**uncapped, units[-1]: 0}
        self.assertEqual(judged(expectation, counts({'treatment': hidden}, SPLASH)).status, 'unmeasured')

    def test_pair_judges_the_share_of_one_heal(self):
        _, [expectation] = scenario_of(ECHO_ENTRY)

        def heals(echo, brew=(1, 1501, 1501)) -> dict:
            return {'treatment': {'first': {ECHO: (1, echo, echo), BREW: (1, 1400, 1400)}, 'second': {BREW: brew}}}

        self.assertEqual(judged(expectation, heals(750)).status, 'ok')
        self.assertEqual(judged(expectation, heals(0)).status, 'alert')
        self.assertEqual(judged(expectation, heals(1450)).status, 'alert')
        self.assertEqual(judged(expectation, heals(750, (1, 1501, 1200))).status, 'unmeasured')
        self.assertEqual(judged(expectation, heals(750, (0, 0, 0))).status, 'unmeasured')

    def test_refused_inputs(self):
        bad = [
            {**BOOMS_ENTRY, 'allies': []},
            {**BOOMS_ENTRY, 'allies': [{'id': CASTER, 'dx': 1, 'dy': 0}]},
            {**BOOMS_ENTRY, 'checks': [{**BOOMS_ENTRY['checks'][0], 'control_expected': None}]},
            {**SPLASH_ENTRY, 'checks': [{**SPLASH_ENTRY['checks'][0], 'witness': 'control'}]},
            {**SPLASH_ENTRY, 'creatures': [{'id': 'c1', 'entry': 631, 'distance': 40}]},
            {**ECHO_ENTRY, 'checks': [{**ECHO_ENTRY['checks'][0], 'band_reason': ''}]},
            {**ECHO_ENTRY, 'checks': [{**ECHO_ENTRY['checks'][0], 'on': 'nobody'}]},
            {**ECHO_ENTRY, 'casts': [{'spell': BREW, 'target': 'nobody', 'watch_ms': 4000}]}]
        for entry in bad:
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                scenario_of(entry)


if __name__ == '__main__':
    unittest.main()
