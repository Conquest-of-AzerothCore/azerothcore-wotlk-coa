import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import CASTER, DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

BEAM = 501117
WAVE = 712453

BRANCH_ENTRY = {
    'spell': BEAM, 'kind': 'ally_heal_reach', 'variant': 'branches', 'name': 'Mojo Beam branches',
    'quote': 'Each time Mojo Beam heals a target it will grow a new branch.',
    'allies': [{'id': 'a', 'dx': 22, 'dy': 0}, {'id': 'b', 'dx': 22, 'dy': 12}, {'id': 'c', 'dx': 22, 'dy': 24},
               {'id': 'far', 'dx': -10, 'dy': 30}, {'id': 'loose', 'dx': 22, 'dy': -10, 'grouped': False}],
    'casts': [{'spell': BEAM, 'target': 'a', 'watch_ms': 3000, 'poll_ms': 250, 'refill_power': 1497}],
    'checks': [{'name': 'branch_grow', 'judge': 'reach', 'spell': BEAM, 'reference': 'a', 'minimum': 2,
                'healed': ['b', 'c'], 'unhealed': ['far', 'loose']},
               {'name': 'branch_heals', 'judge': 'offsets', 'spell': BEAM, 'reference': 'a', 'minimum': 2,
                'quote': 'Each new branch immediately heals and continues healing.',
                'offsets': {'b': 0, 'c': -1}}]}

WAVE_ENTRY = {
    'spell': 707617, 'kind': 'ally_heal_reach', 'variant': 'wave', 'name': 'Mojo Wave',
    'quote': 'Healing with Mojo Beam now heals up to $712453i of the lowest health nearby allies',
    'gate_spell': 707617,
    'allies': [{'id': 'a', 'dx': 22, 'dy': 0, 'health': 10000, 'maximum': 100000},
               {'id': 'b', 'dx': 22, 'dy': 6, 'health': 20000, 'maximum': 100000},
               {'id': 'c', 'dx': 22, 'dy': -6, 'health': 30000, 'maximum': 100000},
               {'id': 'd', 'dx': 28, 'dy': 0, 'health': 90000, 'maximum': 100000}],
    'casts': [{'spell': BEAM, 'target': 'a', 'watch_ms': 3000, 'poll_ms': 250, 'refill_power': 1497,
               'end_ms': 5500}],
    'checks': [{'name': 'wave_lowest', 'judge': 'reach', 'spell': WAVE, 'reference': 'a', 'witness_spell': BEAM,
                'minimum': 2, 'healed': ['a', 'b', 'c'], 'unhealed': ['d']},
               {'name': 'wave_cap', 'judge': 'per_source', 'spell': WAVE, 'source': BEAM, 'per_event': 2,
                'minimum': 2},
               {'name': 'wave_share', 'judge': 'share', 'spell': WAVE, 'quote': 'for $s1% of the healing done',
                'source': BEAM, 'expected': 0.5, 'minimum': 2, 'band': [0.0, 1.0], 'band_reason': 'rounding'}]}

FROG_BONES, POTION_TOSS, BOTTLE, INGREDIENT_MARKER, UNSTABLE_HEAL = 801663, 801661, 801696, 801702, 802489
UNSTABLE_ENTRY = {
    'spell': 802487, 'kind': 'ally_heal_reach', 'variant': 'unstable_radius', 'name': 'Unstable Concoction',
    'quote': 'healing nearby allies within $802489a1 yds', 'gate_spell': 802487, 'learn': [92085],
    'allies': [{'id': 'near', 'dx': 3, 'dy': 0}, {'id': 'inside', 'dx': 22.5, 'dy': 0},
               {'id': 'outside', 'dx': 23.5, 'dy': 0}],
    'casts': [{'spell': FROG_BONES, 'target': CASTER, 'watch_ms': 1600, 'poll_ms': 400},
              {'spell': POTION_TOSS, 'target': CASTER, 'watch_ms': 1600, 'poll_ms': 400},
              {'spell': BOTTLE, 'target': CASTER, 'watch_ms': 2500, 'poll_ms': 500}],
    'checks': [{'name': 'unstable_radius', 'judge': 'reach', 'spell': UNSTABLE_HEAL, 'reference': 'near',
                'minimum': 1, 'healed': ['near', 'inside'], 'unhealed': ['outside']}]}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(13), entry)


def values_of(expectation, heals: dict) -> dict:
    values = {}
    for phase, allies in expectation.model['reads'].items():
        for ally, spells in allies.items():
            for spell, fields in spells.items():
                read = heals.get(phase, {}).get(ally, {}).get(int(spell), (0, 0, 0))
                for (field, (start, end)), value in zip(fields.items(), read):
                    values[start] = 100.0
                    values[end] = 100.0 + value
    return values


def judged(expectation, heals: dict):
    return judge_behaviour(base_verdict(expectation), FakeRun(values_of(expectation, heals)), expectation)


def branch_heals(a=6, b=6, c=5, far=0, loose=0) -> dict:
    return {'treatment': {ally: {BEAM: (count, count * 277, count * 277)}
                          for ally, count in {'a': a, 'b': b, 'c': c, 'far': far, 'loose': loose}.items()}}


def wave_heals(waves=None, beams=None, control_waves=None, beam_amount=277, wave_amount=139, overheal=0) -> dict:
    waves = {'a': 16, 'b': 16, 'c': 16, 'd': 0} if waves is None else waves
    beams = {'a': 6, 'b': 6, 'c': 6, 'd': 6} if beams is None else beams
    control_waves = {} if control_waves is None else control_waves

    def phase(wave_counts: dict) -> dict:
        return {ally: {BEAM: (beams[ally], beams[ally] * beam_amount, beams[ally] * beam_amount - overheal),
                       WAVE: (wave_counts.get(ally, 0), wave_counts.get(ally, 0) * wave_amount,
                              wave_counts.get(ally, 0) * wave_amount)}
                for ally in beams}
    return {'control': phase(control_waves), 'treatment': phase(waves)}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AllyHealReachScenarioTests(unittest.TestCase):
    def test_the_allies_are_placed_grouped_and_read_around_each_window(self):
        scenario, expectations = scenario_of(BRANCH_ENTRY)
        run.validate(scenario)
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER, 'a', 'b', 'c', 'far', 'loose'])
        steps = scenario['steps']
        grouped = [step['target'] for step in steps if step['action'] == 'group']
        self.assertEqual(grouped, ['a', 'b', 'c', 'far'])
        moved = {}
        for step in steps:
            if step['action'] == 'relocate':
                x, y = moved.get(step['actor'], (0.0, 0.0))
                moved[step['actor']] = (x + step['dx'], y + step['dy'])
        self.assertEqual(moved['c'], (22.0, 24.0))
        self.assertEqual(moved['far'], (-10.0, 30.0))
        self.assertTrue(all(abs(step['dx']) <= 20 and abs(step['dy']) <= 20 for step in steps
                            if step['action'] == 'relocate'))
        cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast')
        labels = [step.get('label', '') for step in steps]
        start = next(index for index, label in enumerate(labels) if ' treatment start ' in label)
        end = next(index for index, label in enumerate(labels) if ' treatment end ' in label)
        self.assertLess(start, cast)
        self.assertLess(cast, end)
        self.assertEqual(sum(step['ms'] for step in steps[cast:end] if step['action'] == 'wait'), 3000)
        self.assertEqual(len([step for step in steps[cast:end] if step['action'] == 'set_power']), 12)
        self.assertEqual([expectation.label for expectation in expectations],
                         ['501117 behaviour_metric_delta branch_grow', '501117 behaviour_metric_delta branch_heals'])
        self.assertEqual({expectation.model['metric'] for expectation in expectations}, {'spell_heal_count'})

    def test_a_gate_spell_is_learned_between_the_control_and_the_treatment_phase(self):
        scenario, expectations = scenario_of(WAVE_ENTRY)
        run.validate(scenario)
        steps = scenario['steps']
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 707617)
        labels = [step.get('label', '') for step in steps]
        control_end = max(index for index, label in enumerate(labels) if ' control end ' in label)
        treatment_start = min(index for index, label in enumerate(labels) if ' treatment start ' in label)
        self.assertLess(control_end, learn)
        self.assertLess(learn, treatment_start)
        learned = [step['spell'] for step in steps[:learn] if step['action'] == 'learn']
        self.assertEqual(learned, [BEAM])
        health = [step for step in steps if step['action'] == 'set_health']
        self.assertEqual(len(health), 8)
        self.assertTrue(all(step['maximum'] == 100000 for step in health))
        self.assertEqual(expectations[2].model['metric'], 'spell_heal_total')

    def test_an_entry_without_a_reference_an_unknown_ally_or_a_share_without_a_gate_is_refused(self):
        broken = {**BRANCH_ENTRY, 'checks': [{**BRANCH_ENTRY['checks'][0], 'reference': None}]}
        with self.assertRaises(ValueError):
            scenario_of(broken)
        broken = {**BRANCH_ENTRY, 'checks': [{**BRANCH_ENTRY['checks'][0], 'healed': ['ghost']}]}
        with self.assertRaises(ValueError):
            scenario_of(broken)
        broken = {**WAVE_ENTRY, 'gate_spell': None}
        with self.assertRaises(ValueError):
            scenario_of(broken)
        with self.assertRaises(ValueError):
            scenario_of({**WAVE_ENTRY, 'learn': [707617]})
        broken = {**WAVE_ENTRY, 'allies': [{**WAVE_ENTRY['allies'][0], 'maximum': None}] + WAVE_ENTRY['allies'][1:]}
        with self.assertRaises(ValueError):
            scenario_of(broken)

    def test_a_cast_at_the_caster_gets_its_caster_aura_first_and_the_contract_names_it(self):
        scenario, _ = scenario_of(UNSTABLE_ENTRY)
        run.validate(scenario)
        steps = scenario['steps']
        casts = [step for step in steps if step['action'] == 'cast']
        self.assertEqual([step['spell'] for step in casts], [FROG_BONES, POTION_TOSS, BOTTLE] * 2)
        self.assertTrue(all(step['target'] == CASTER for step in casts))
        auras = [index for index, step in enumerate(steps) if step['action'] == 'set_aura']
        self.assertEqual([steps[index]['spell'] for index in auras], [INGREDIENT_MARKER, INGREDIENT_MARKER])
        self.assertTrue(all(steps[index + 1]['action'] == 'cast' and steps[index + 1]['spell'] == POTION_TOSS
                            for index in auras))
        self.assertIn(f'{INGREDIENT_MARKER} before each {POTION_TOSS}', scenario['contract'])
        self.assertIn('Precondition fixtures', scenario['contract'])
        branch, _ = scenario_of(BRANCH_ENTRY)
        self.assertNotIn('Precondition fixtures', branch['contract'])
        self.assertFalse(any(step['action'] == 'set_aura' for step in branch['steps']))

    def test_end_ms_is_waited_after_the_end_reads_of_each_phase(self):
        scenario, _ = scenario_of(WAVE_ENTRY)
        steps = scenario['steps']
        labels = [step.get('label', '') for step in steps]
        waits = [index for index, step in enumerate(steps)
                 if step['action'] == 'wait' and step.get('label') == 'ally_heal_reach end']
        self.assertEqual([steps[index]['ms'] for index in waits], [5500, 5500])
        control_end = max(index for index, label in enumerate(labels) if ' control end ' in label)
        treatment_end = max(index for index, label in enumerate(labels) if ' treatment end ' in label)
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 707617)
        self.assertEqual(waits[0], control_end + 1)
        self.assertLess(waits[0], learn)
        self.assertEqual(waits[1], treatment_end + 1)
        branch, _ = scenario_of(BRANCH_ENTRY)
        self.assertFalse(any(step.get('label') == 'ally_heal_reach end' for step in branch['steps']))

    def test_seven_allies_keep_schema_one_and_allies_past_a_party_are_named(self):
        extra = [{'id': 'e', 'dx': -5, 'dy': 0}, {'id': 'f', 'dx': -5, 'dy': 5}]
        seven = {**BRANCH_ENTRY, 'allies': BRANCH_ENTRY['allies'] + extra}
        scenario, _ = scenario_of(seven)
        run.validate(scenario)
        self.assertEqual((scenario['schema'], len(scenario['players'])), (1, 8))
        self.assertIn('6 grouped allies exceed a party', scenario['contract'])
        self.assertIn("before it adds e", scenario['contract'])
        self.assertIn("['e', 'f']", scenario['contract'])
        branch, _ = scenario_of(BRANCH_ENTRY)
        self.assertNotIn('exceed a party', branch['contract'])

    def test_more_than_seven_allies_use_schema_two_up_to_twenty_four(self):
        allies = [{'id': f'a{index}', 'dx': 4 + index % 6, 'dy': index // 6} for index in range(24)]
        entry = {**BRANCH_ENTRY, 'allies': allies, 'casts': [{**BRANCH_ENTRY['casts'][0], 'target': 'a0'}],
                 'checks': [{**BRANCH_ENTRY['checks'][0], 'reference': 'a0', 'healed': ['a1'], 'unhealed': []}]}
        scenario, _ = scenario_of(entry)
        run.validate(scenario)
        self.assertEqual((scenario['schema'], len(scenario['players'])), (2, 25))
        with self.assertRaises(ValueError):
            scenario_of({**entry, 'allies': allies + [{'id': 'a24', 'dx': -5, 'dy': 10}]})


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AllyHealReachJudgeTests(unittest.TestCase):
    def setUp(self):
        _, self.branch = scenario_of(BRANCH_ENTRY)
        _, self.wave = scenario_of(WAVE_ENTRY)

    def test_branches_grown_and_healed_every_tick_pass(self):
        self.assertEqual(judged(self.branch[0], branch_heals()).status, 'ok')
        self.assertEqual(judged(self.branch[1], branch_heals()).status, 'ok')

    def test_a_server_without_branches_alerts_on_both_checks(self):
        self.assertEqual(judged(self.branch[0], branch_heals(b=0, c=0)).status, 'alert')
        self.assertEqual(judged(self.branch[1], branch_heals(b=0, c=0)).status, 'alert')

    def test_a_branch_that_waits_a_tick_alerts_and_a_heal_beyond_the_reach_alerts(self):
        self.assertEqual(judged(self.branch[1], branch_heals(b=5, c=4)).status, 'alert')
        self.assertEqual(judged(self.branch[0], branch_heals(far=3)).status, 'alert')
        self.assertEqual(judged(self.branch[0], branch_heals(loose=1)).status, 'alert')

    def test_a_beam_that_did_not_run_is_unmeasured(self):
        self.assertEqual(judged(self.branch[0], branch_heals(a=1, b=1, c=0)).status, 'unmeasured')
        self.assertEqual(judged(self.branch[1], branch_heals(a=1, b=1, c=0)).status, 'unmeasured')

    def test_waves_on_the_lowest_two_at_half_the_heal_pass(self):
        for expectation in self.wave:
            with self.subTest(label=expectation.label):
                self.assertEqual(judged(expectation, wave_heals()).status, 'ok')

    def test_a_wave_on_the_highest_ally_or_without_the_talent_alerts(self):
        self.assertEqual(judged(self.wave[0], wave_heals(waves={'a': 16, 'b': 14, 'c': 16, 'd': 2})).status, 'alert')
        for expectation in self.wave:
            with self.subTest(label=expectation.label):
                self.assertEqual(judged(expectation, wave_heals(control_waves={'b': 1})).status, 'alert')

    def test_a_server_without_waves_alerts_on_the_pick_and_the_cap_and_leaves_the_share_unmeasured(self):
        none = wave_heals(waves={'a': 0, 'b': 0, 'c': 0, 'd': 0})
        self.assertEqual(judged(self.wave[0], none).status, 'alert')
        self.assertEqual(judged(self.wave[1], none).status, 'alert')
        self.assertEqual(judged(self.wave[2], none).status, 'unmeasured')

    def test_a_reach_without_a_witness_names_its_unwitnessed_allies(self):
        self.assertIn('no witness spell', judged(self.branch[0], branch_heals()).explanation)
        self.assertNotIn('no witness spell', judged(self.wave[0], wave_heals()).explanation)

    def test_a_third_wave_per_heal_or_another_share_alerts(self):
        self.assertEqual(judged(self.wave[1], wave_heals(waves={'a': 24, 'b': 24, 'c': 24, 'd': 0})).status, 'alert')
        self.assertEqual(judged(self.wave[2], wave_heals(wave_amount=142)).status, 'alert')
        self.assertEqual(judged(self.wave[2], wave_heals(wave_amount=138)).status, 'alert')

    def test_a_highest_ally_out_of_reach_or_an_overheal_is_unmeasured(self):
        beams = {'a': 6, 'b': 6, 'c': 6, 'd': 0}
        self.assertEqual(judged(self.wave[0], wave_heals(beams=beams)).status, 'unmeasured')
        self.assertEqual(judged(self.wave[1], wave_heals(overheal=50)).status, 'unmeasured')


HEXBREAK, CURSE = 806240, 702
DISPEL_ENTRY = {
    'spell': 300660, 'kind': 'ally_heal_reach', 'variant': 'hex_jump', 'name': 'Hexbreak jump',
    'quote': 'now affects an additional nearby ally', 'gate_spell': 300660,
    'allies': [{'id': 'p', 'dx': 22, 'dy': 0, 'auras': [[CURSE, 1]]},
               {'id': 'n', 'dx': 22, 'dy': -6, 'auras': [[CURSE, 1]]},
               {'id': 'f', 'dx': 22, 'dy': -24, 'auras': [[CURSE, 1]]}],
    'casts': [{'spell': HEXBREAK, 'target': 'p', 'watch_ms': 1000}],
    'checks': [{'name': 'hex_jump', 'judge': 'aura_reach', 'spell': HEXBREAK, 'aura': CURSE, 'reference': 'p',
                'removed': ['n'], 'kept': ['f']}]}
DRAIN_ENTRY = {
    'spell': BEAM, 'kind': 'ally_heal_reach', 'variant': 'drain', 'name': 'Mojo Beam drain',
    'quote': 'For every sprouted the branch, you consume more and more mana.',
    'allies': [{'id': 'lone', 'dx': -10, 'dy': -30}, {'id': 'a', 'dx': 22, 'dy': 0},
               {'id': 'b', 'dx': 22, 'dy': -12}],
    'casts': [{'spell': BEAM, 'target': 'lone', 'watch_ms': 1250, 'power_reads': True, 'gap_ms': 500},
              {'spell': BEAM, 'target': 'a', 'watch_ms': 1250, 'power_reads': True}],
    'checks': [{'name': 'drain', 'judge': 'drain', 'spell': BEAM, 'low_cast': 0, 'high_cast': 1}]}


def aura_values(expectation, present: dict) -> dict:
    return {label: float(present.get((phase, moment, unit), 1))
            for phase, moments in expectation.model['aura_reads'].items()
            for moment, units in moments.items() for unit, label in units.items()}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AllyEffectJudgeTests(unittest.TestCase):
    def test_a_dispel_jump_is_read_on_the_ally_auras(self):
        scenario, [expectation] = scenario_of(DISPEL_ENTRY)
        run.validate(scenario)
        fixtures = [step for step in scenario['steps'] if step['action'] == 'set_aura']
        self.assertEqual(len(fixtures), 6)
        jumped = {('control', 'end', 'p'): 0, ('treatment', 'end', 'p'): 0, ('treatment', 'end', 'n'): 0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(aura_values(expectation, jumped)),
                                  expectation)
        self.assertEqual(verdict.status, 'ok')
        stayed = {('control', 'end', 'p'): 0, ('treatment', 'end', 'p'): 0}
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(aura_values(expectation, stayed)),
                                  expectation)
        self.assertEqual(verdict.status, 'alert')

    def test_a_drain_compares_the_power_spent_by_two_casts(self):
        scenario, [expectation] = scenario_of(DRAIN_ENTRY)
        run.validate(scenario)
        (low_start, low_end), (high_start, high_end) = expectation.model['power_reads']['treatment'].values()
        values = {low_start: 1497, low_end: 941, high_start: 1497, high_end: 767}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'ok')
        values[high_end] = 941
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')

    def test_an_equal_drain_holds_the_two_casts_within_the_tolerance(self):
        [check] = DRAIN_ENTRY['checks']
        entry = {**DRAIN_ENTRY, 'checks': [{**check, 'relation': 'equal', 'tolerance': 1}]}
        scenario, [expectation] = scenario_of(entry)
        run.validate(scenario)
        (low_start, low_end), (high_start, high_end) = expectation.model['power_reads']['treatment'].values()
        values = {low_start: 1497, low_end: 942, high_start: 1497, high_end: 941}
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'ok')
        values[high_end] = 767
        self.assertEqual(judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status, 'alert')

    def test_a_more_drain_keeps_its_model(self):
        _, [expectation] = scenario_of(DRAIN_ENTRY)
        self.assertNotIn('relation', expectation.model)

    def test_refused_layouts(self):
        for check in ({'judge': 'aura_reach', 'aura': 1, 'reference': 'p', 'removed': ['n']},
                      {'judge': 'drain', 'low_cast': 0, 'high_cast': 0},
                      {'judge': 'drain', 'low_cast': 0, 'high_cast': 1, 'relation': 'less'},
                      {'judge': 'count', 'reference': 'p'}):
            entry = {**DISPEL_ENTRY, 'checks': [{'name': 'x', 'spell': HEXBREAK, **check}]}
            with self.subTest(check=check), self.assertRaises(ValueError):
                scenario_of(entry)


if __name__ == '__main__':
    unittest.main()
