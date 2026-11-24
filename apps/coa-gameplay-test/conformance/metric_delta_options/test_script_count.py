import unittest
from dataclasses import replace
from unittest import mock

from behaviours import behaviour_scenario, metric_delta_spec
from compare import judge_behaviour
from metric_delta_options import script_count
from procs import swing_interval
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict
from test_coverage import BUILD, claim, evidence_of

ANNIHILATION_TEXT = 'Lasts for $n attacks or $d.'
PIT_LORD_TEXT = 'Your Annihilation now affects $s1 additional attack'
COUNTED = {'noun': 'attack'}


def annihilation(**changes) -> dict:
    return {'spell': 803904, 'name': 'Annihilation (attacks)', 'kind': 'metric_delta', 'variant': 'charges',
            'label_suffix': 'charges', 'quote': ANNIHILATION_TEXT, 'trigger_spell': 803904, 'gate_spell': 803904,
            'target': 'caster', 'metric': 'aura_script_value', 'fields': {'spell': 803904, 'key': 803904},
            'cast_in_before': False, 'before_expected': 0, 'expected': 5, 'tolerance': 0, 'wait_ms': 500,
            'expire_ms': 500, 'script_count': COUNTED, **changes}


def pit_lord(**changes) -> dict:
    return {'spell': 802076, 'name': "Pit Lord's Strength (Annihilation attacks)", 'kind': 'metric_delta',
            'variant': 'charges', 'label_suffix': 'charges', 'quote': PIT_LORD_TEXT, 'trigger_spell': 803904,
            'gate_spell': 802076, 'target': 'caster', 'metric': 'aura_script_value',
            'fields': {'spell': 803904, 'key': 803904}, 'before_expected': 5, 'expected': 6, 'tolerance': 0,
            'wait_ms': 500, 'expire_ms': 500, 'script_count': COUNTED, **changes}


def without_option(entry: dict) -> dict:
    return {key: value for key, value in entry.items() if key != 'script_count'}


def generated(entry: dict):
    return behaviour_scenario(load_fixture_class_file(19), entry)


def judged_read(entry: dict, text: str, before: float, after: float):
    _, [expectation] = generated(entry)
    values = {expectation.model['before_label']: before, expectation.model['after_label']: after}
    verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
    evidence = evidence_of([claim(text, verdict.label, spell=entry['spell'])],
                           [replace(verdict, spell_id=entry['spell'], build=BUILD)])[0]
    return verdict, evidence


SPEC_MUTANTS = (
    ('stated_count', annihilation(quote='Gorge on fel energy')),
    ('counted_read', annihilation(evidence_metric='aura')),
    ('plain_layout', pit_lord(gate_timing='start')),
    ('contrast_arm', annihilation(cast_in_before=True)),
)
SCENARIO_MUTANTS = (
    ('named_aura', pit_lord(quote='affects $s1 additional attack')),
    ('no_setter', annihilation(phase_auras=[[800058, 1, 'caster', 'caster']])),
)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScriptCountTests(unittest.TestCase):
    def test_the_opted_read_stamps_the_count_metric_and_its_driver(self):
        for entry, driver in ((annihilation(), 'absent'), (pit_lord(), 'different')):
            with self.subTest(spell=entry['spell']):
                scenario, [expectation] = generated(entry)
                run.validate(scenario)
                self.assertEqual(expectation.model['metric'], 'aura_script_value')
                self.assertEqual(expectation.model['evidence_metric'], 'aura_script_count')
                self.assertEqual(expectation.model['script_count'],
                                 {'noun': 'attack', 'aura': 803904, 'driver': driver})
                self.assertIn(f'with the driving cast {driver}', scenario['contract'])

    def test_without_the_option_the_scenario_and_model_are_unchanged(self):
        for entry in (annihilation(), pit_lord()):
            with self.subTest(spell=entry['spell']):
                plain, [expectation] = generated(without_option(entry))
                opted, _ = generated(entry)
                self.assertEqual(plain['steps'], opted['steps'])
                self.assertNotIn('evidence_metric', expectation.model)
                self.assertNotIn('script_count', expectation.model)
                self.assertNotIn('aura_script_count', plain['contract'])

    def test_the_option_is_one_counted_noun(self):
        for raw in (True, {}, {'noun': 'hit'}, {'noun': 'attack', 'other': 1}, 'attack'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                generated(annihilation(script_count=raw))

    def test_the_count_metric_is_refused_without_the_option(self):
        with self.assertRaises(ValueError):
            generated(without_option(annihilation(evidence_metric='aura_script_count')))

    def test_each_spec_refusal_rule_refuses_its_case(self):
        extra = (('counted_read', annihilation(metric='aura')), ('counted_read', annihilation(after_at_least=5)),
                 ('contrast_arm', annihilation(tolerance=2.5)), ('contrast_arm', annihilation(expected=0)))
        for rule, entry in (*SPEC_MUTANTS, *extra):
            with self.subTest(rule=rule, entry=entry), self.assertRaisesRegex(ValueError, 'script_count'):
                generated(entry)

    def test_each_scenario_refusal_rule_refuses_its_case(self):
        for rule, entry in SCENARIO_MUTANTS:
            with self.subTest(rule=rule), self.assertRaisesRegex(ValueError, 'script_count'):
                generated(entry)

    def test_mutant_without_each_rule_lets_its_case_through(self):
        for rule, entry in (*SPEC_MUTANTS, *SCENARIO_MUTANTS):
            with self.subTest(rule=rule), mock.patch(f'metric_delta_options.script_count.{rule}',
                                                     lambda *args: None):
                scenario, _ = generated(entry)
                self.assertTrue(scenario['steps'])

    def seeded(self, entry: dict, edit) -> str | None:
        scenario, _ = generated(entry)
        return edit(metric_delta_spec(entry), list(scenario['steps']))

    def test_a_non_cast_step_on_the_read_aura_is_refused_and_caught_by_its_rule(self):
        def written(spec, steps):
            return script_count.no_setter(spec, [*steps, {'action': 'unlearn', 'actor': 'caster', 'spell': 803904}])
        self.assertIn('writes the read aura 803904', self.seeded(annihilation(), written))
        self.assertIsNone(self.seeded(annihilation(), script_count.no_setter))

    def test_the_real_cast_rule_refuses_a_missing_or_early_driving_cast(self):
        def uncast(spec, steps):
            return script_count.real_cast(spec, [step for step in steps if step.get('action') != 'cast'])

        def early(spec, steps):
            return script_count.real_cast(spec, [{'action': 'cast', 'actor': 'caster', 'spell': 803904,
                                                  'target': 'caster'}, *steps])
        self.assertIn('no real cast of 803904', self.seeded(annihilation(), uncast))
        self.assertIn('driving cast is not absent', self.seeded(annihilation(), early))
        self.assertIsNone(self.seeded(annihilation(), script_count.real_cast))
        self.assertIsNone(self.seeded(pit_lord(), early))
        records = mock.Mock(field=lambda *args: 'Annihilation')
        self.assertIn('no real cast', self.seeded(annihilation(), lambda spec, steps: script_count.scenario_refusal(
            spec, [step for step in steps if step.get('action') != 'cast'], records)))
        with mock.patch('metric_delta_options.script_count.real_cast', lambda *args: None):
            self.assertIsNone(self.seeded(annihilation(), lambda spec, steps: script_count.scenario_refusal(
                spec, [step for step in steps if step.get('action') != 'cast'], records)))

    def test_an_opted_count_read_is_behaviour_and_a_wrong_count_alerts(self):
        for entry, text, before, after in ((annihilation(), ANNIHILATION_TEXT, 0, 5),
                                           (pit_lord(), PIT_LORD_TEXT, 5, 6)):
            with self.subTest(spell=entry['spell']):
                verdict, evidence = judged_read(entry, text, before, after)
                self.assertEqual((verdict.status, verdict.detail['metric'], evidence),
                                 ('ok', 'aura_script_count', ['behaviour']))
                verdict, evidence = judged_read(entry, text, before, before)
                self.assertEqual((verdict.status, evidence), ('alert', ['unproven']))

    def test_the_count_read_without_its_count_word_stays_data(self):
        _, evidence = judged_read(annihilation(), 'Gorge on fel energy.', 0, 5)
        self.assertEqual(evidence, ['data'])

    def test_the_plain_script_value_read_stays_data(self):
        verdict, evidence = judged_read(without_option(annihilation()), ANNIHILATION_TEXT, 0, 5)
        self.assertEqual((verdict.status, verdict.detail['metric'], evidence), ('ok', 'aura_script_value', ['data']))
        verdict, evidence = judged_read(without_option(pit_lord()), PIT_LORD_TEXT, 5, 6)
        self.assertEqual((verdict.status, evidence), ('ok', ['data']))

    def test_mutant_with_the_count_row_on_the_plain_read_makes_it_behaviour(self):
        rows = {**script_count.STATE_PROMISES, 'aura_script_value': script_count.STATE_PROMISES['aura_script_count']}
        with mock.patch.dict('coverage.METRIC_EVIDENCE', {'aura_script_value': 'state'}), \
                mock.patch.object(script_count, 'STATE_PROMISES', rows), \
                mock.patch.object(script_count, 'METRIC_EVIDENCE', {'aura_script_count': 'state'}):
            _, evidence = judged_read(without_option(annihilation()), ANNIHILATION_TEXT, 0, 5)
            self.assertEqual(evidence, ['behaviour'])



SWUNG = {'noun': 'attack', 'swings': 2}


def swung_values(entry: dict, readings: dict) -> dict:
    _, [expectation] = generated(entry)
    values = {}
    for moment, (cast_count, count, cast_landed, landed) in readings.items():
        label = expectation.model[f'{moment}_label']
        values.update({label: count, script_count.cast_count_label(label): cast_count,
                       script_count.cast_landed_label(label): cast_landed, script_count.landed_label(label): landed})
    return values


def judged_swings(entry: dict, text: str, values: dict):
    _, [expectation] = generated(entry)
    verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
    evidence = evidence_of([claim(text, verdict.label, spell=entry['spell'])],
                           [replace(verdict, spell_id=entry['spell'], build=BUILD)])[0]
    return verdict, evidence


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScriptCountSwingTests(unittest.TestCase):
    def labels(self, scenario: dict) -> list:
        return [step.get('label') or step['action'] for step in scenario['steps']]

    def test_each_cast_arm_reads_the_count_and_landed_attacks_around_its_swings(self):
        scenario, [expectation] = generated(pit_lord(script_count=SWUNG, expire_ms=12500))
        run.validate(scenario)
        labels = self.labels(scenario)
        for moment in ('before', 'after'):
            label = expectation.model[f'{moment}_label']
            start = labels.index(script_count.cast_count_label(label))
            self.assertEqual(labels[start:start + 5], [script_count.cast_count_label(label),
                                                       script_count.cast_landed_label(label), 'attack',
                                                       script_count.SWING_WAIT_LABEL, 'stop_attack'])
            self.assertEqual(labels[labels.index(label) + 1], script_count.landed_label(label))
            self.assertEqual(scenario['steps'][labels.index(label) - 1]['ms'], 500)
            self.assertEqual(scenario['steps'][start - 1]['action'], 'cast')
        waits = [step['ms'] for step in scenario['steps'] if step.get('label') == script_count.SWING_WAIT_LABEL]
        self.assertEqual(waits, [2 * swing_interval(load_fixture_class_file(19))] * 2)
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['dummy'])
        self.assertEqual(expectation.model['script_count']['swings'],
                         {'count': 2, 'readings': [expectation.model['before_label'],
                                                   expectation.model['after_label']]})

    def test_an_uncast_before_arm_has_no_swings_and_stays_a_plain_count(self):
        scenario, [expectation] = generated(annihilation(script_count=SWUNG))
        labels = self.labels(scenario)
        before = expectation.model['before_label']
        self.assertNotIn(script_count.landed_label(before), labels)
        self.assertEqual(labels.count('attack'), 1)
        self.assertEqual(expectation.model['script_count']['swings']['readings'], [expectation.model['after_label']])

    def test_without_swings_the_scenario_and_model_are_unchanged(self):
        for entry in (annihilation(), pit_lord()):
            with self.subTest(spell=entry['spell']):
                plain, [expectation] = generated(entry)
                self.assertNotIn('swings', expectation.model['script_count'])
                self.assertNotIn('attack', self.labels(plain))
                self.assertNotIn('creatures', plain)

    def test_the_swing_count_is_a_positive_integer_for_attacks_inside_the_count(self):
        for raw in ({'noun': 'attack', 'swings': 0}, {'noun': 'attack', 'swings': 1.5},
                    {'noun': 'attack', 'swings': True}, {'noun': 'attack', 'swings': '2'}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                generated(annihilation(script_count=raw))
        for entry in (pit_lord(script_count={'noun': 'attack', 'swings': 4}),
                      annihilation(script_count={'noun': 'attack', 'swings': 4}),
                      annihilation(script_count={'noun': 'charge', 'swings': 1}, quote='Lasts for $n charges')):
            with self.subTest(entry=entry['script_count']), self.assertRaisesRegex(ValueError, 'swings'):
                generated(entry)
        with mock.patch('metric_delta_options.script_count.swing_window', lambda *args: None):
            scenario, _ = generated(pit_lord(script_count={'noun': 'attack', 'swings': 4}))
            self.assertTrue(scenario['steps'])

    def test_the_window_bound_counts_every_equipped_melee_hand(self):
        class_file = load_fixture_class_file(19)
        main, off = class_file['weapon'], class_file['off_hand_weapons'][0]
        one_hand = [{'action': 'equip', 'actor': 'caster', 'item': main['item'], 'slot': 15}]
        dual = one_hand + [{'action': 'equip', 'actor': 'caster', 'item': off['item'], 'slot': 16}]
        window = 2 * main['speed_ms']
        self.assertEqual(script_count.landed_bound(class_file, one_hand, window), 3)
        self.assertEqual(script_count.landed_bound(class_file, dual, window),
                         3 + window // off['speed_ms'] + 1)
        spec = metric_delta_spec(pit_lord(script_count=SWUNG))
        counted = script_count.Counted('attack', 2)
        self.assertIsNone(script_count.swing_window(spec, counted, script_count.landed_bound(class_file, one_hand,
                                                                                             window)))
        self.assertRegex(script_count.swing_window(spec, counted, script_count.landed_bound(class_file, dual, window)),
                         'equipped melee hands')
        with self.assertRaisesRegex(ValueError, 'speed of equipped item'):
            script_count.landed_bound(class_file, [{**one_hand[0], 'item': 1}], window)

    def test_mutant_counting_the_main_hand_only_lets_a_dual_wield_window_pass(self):
        class_file = load_fixture_class_file(19)
        dual = [{'action': 'equip', 'actor': 'caster', 'item': class_file['weapon']['item'], 'slot': 15},
                {'action': 'equip', 'actor': 'caster', 'item': class_file['off_hand_weapons'][0]['item'], 'slot': 16}]
        spec = metric_delta_spec(pit_lord(script_count=SWUNG))
        counted = script_count.Counted('attack', 2)
        window = 2 * class_file['weapon']['speed_ms']
        main_only = script_count.equipped_melee_speeds(class_file, dual)[:1]
        with mock.patch.object(script_count, 'equipped_melee_speeds', lambda *args: main_only):
            self.assertIsNone(script_count.swing_window(spec, counted,
                                                        script_count.landed_bound(class_file, dual, window)))
        self.assertIsNotNone(script_count.swing_window(spec, counted,
                                                       script_count.landed_bound(class_file, dual, window)))

    def test_the_count_plus_landed_attacks_is_judged_against_the_stated_count(self):
        entry = pit_lord(script_count=SWUNG, expire_ms=12500)
        values = swung_values(entry, {'before': (5, 3, 0, 2), 'after': (6, 3, 2, 5)})
        verdict, evidence = judged_swings(entry, PIT_LORD_TEXT, values)
        self.assertEqual((verdict.status, evidence), ('ok', ['behaviour']))
        verdict, _ = judged_swings(annihilation(script_count=SWUNG), ANNIHILATION_TEXT,
                                   {**swung_values(annihilation(script_count=SWUNG), {'after': (5, 2, 0, 3)}),
                                    generated(annihilation(script_count=SWUNG))[1][0].model['before_label']: 0})
        self.assertEqual(verdict.status, 'ok')

    def test_mutant_reads_without_consumption_alert(self):
        entry = pit_lord(script_count=SWUNG, expire_ms=12500)
        for name, after in (('no consumption', (6, 6, 2, 5)), ('no landed attack', (6, 6, 2, 2)),
                            ('two per attack', (6, 0, 2, 5)), ('wrong stored count', (7, 4, 2, 5))):
            with self.subTest(mutant=name):
                values = swung_values(entry, {'before': (5, 3, 0, 2), 'after': after})
                verdict, evidence = judged_swings(entry, PIT_LORD_TEXT, values)
                self.assertEqual((verdict.status, evidence), ('alert', ['unproven']))

    def test_mutant_without_the_landed_sum_lets_an_unconsumed_count_pass(self):
        entry = pit_lord(script_count=SWUNG, expire_ms=12500)
        values = swung_values(entry, {'before': (5, 5, 0, 2), 'after': (6, 6, 2, 5)})
        with mock.patch('metric_delta_options.script_count.counted_reading',
                        lambda values, label: values.get(label)):
            verdict, _ = judged_swings(entry, PIT_LORD_TEXT, values)
            self.assertEqual(verdict.status, 'ok')
        verdict, _ = judged_swings(entry, PIT_LORD_TEXT, values)
        self.assertEqual(verdict.status, 'alert')


DAGGER = {'item': 2208, 'speed_ms': 1300, 'skill_line': 173, 'proficiency': 1180}
DAGGER_SWUNG = {'noun': 'attack', 'swings': 2, 'main_hand': DAGGER}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ScriptCountMainHandTests(unittest.TestCase):
    def melee(self, steps: list) -> list:
        return [(step['action'], step.get('item'), step.get('slot')) for step in steps
                if step['action'] in ('add_item', 'equip')]

    def test_the_main_hand_replaces_every_melee_equip_step_before_the_casts(self):
        scenario, [expectation] = generated(pit_lord(script_count=DAGGER_SWUNG, expire_ms=12500))
        run.validate(scenario)
        steps = scenario['steps']
        self.assertEqual(self.melee(steps), [('add_item', 2208, None), ('equip', 2208, 15)])
        equip = next(index for index, step in enumerate(steps) if step['action'] == 'equip')
        self.assertEqual(steps[equip - 2], {'action': 'learn', 'actor': 'caster', 'spell': 1180})
        self.assertEqual(steps[equip + 1], {'action': 'set_skill', 'actor': 'caster', 'skill': 173, 'value': 300,
                                            'maximum': 300})
        first_cast = next(index for index, step in enumerate(steps) if step['action'] == 'cast')
        self.assertLess(equip, first_cast)
        waits = [step['ms'] for step in steps if step.get('label') == script_count.SWING_WAIT_LABEL]
        self.assertEqual(waits, [2 * swing_interval(load_fixture_class_file(19))] * 2)
        self.assertEqual(expectation.model['script_count']['swings']['main_hand'], 2208)
        self.assertIn('item 2208 (1300 ms', scenario['contract'])

    def test_the_bound_uses_the_main_hand_speed(self):
        class_file = load_fixture_class_file(19)
        steps = [{'action': 'equip', 'actor': 'caster', 'item': 2208, 'slot': 15}]
        main_hand = script_count.parse_main_hand(DAGGER)
        self.assertEqual(script_count.landed_bound(class_file, steps, 5000, main_hand), 4)
        with self.assertRaisesRegex(ValueError, 'speed of equipped item'):
            script_count.landed_bound(class_file, steps, 5000)

    def test_without_main_hand_the_class_weapons_stay(self):
        plain, _ = generated(pit_lord(script_count=SWUNG, expire_ms=12500))
        self.assertNotIn(('equip', 2208, 15), self.melee(plain['steps']))
        self.assertNotIn(1180, [step.get('spell') for step in plain['steps'] if step['action'] == 'learn'])

    def test_a_malformed_main_hand_is_refused(self):
        for raw in ({'noun': 'attack', 'main_hand': DAGGER},
                    {**DAGGER_SWUNG, 'main_hand': {**DAGGER, 'speed_ms': 0}},
                    {**DAGGER_SWUNG, 'main_hand': {**DAGGER, 'speed_ms': 1300.0}},
                    {**DAGGER_SWUNG, 'main_hand': {key: DAGGER[key] for key in ('item', 'speed_ms')}},
                    {**DAGGER_SWUNG, 'main_hand': {**DAGGER, 'proficiency': 803904}}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                generated(pit_lord(script_count=raw, expire_ms=12500))

    def dual_wield_swings(self) -> dict:
        class_file = load_fixture_class_file(19)
        main, off = class_file['weapon'], class_file['off_hand_weapons'][0]
        scenario = {'contract': '', 'steps': [
            {'action': 'add_item', 'actor': 'caster', 'item': main['item']},
            {'action': 'equip', 'actor': 'caster', 'item': main['item'], 'slot': 15},
            {'action': 'add_item', 'actor': 'caster', 'item': off['item']},
            {'action': 'equip', 'actor': 'caster', 'item': off['item'], 'slot': 16}]}
        spec = metric_delta_spec(pit_lord(script_count=DAGGER_SWUNG, expire_ms=12500))
        script_count.swing_fixtures(class_file, spec, script_count.parse(DAGGER_SWUNG), scenario)
        return scenario

    def test_a_dual_wield_fixture_becomes_one_main_hand_inside_the_bound(self):
        scenario = self.dual_wield_swings()
        self.assertEqual(self.melee(scenario['steps']), [('add_item', 2208, None), ('equip', 2208, 15)])

    def test_mutant_keeping_an_off_hand_beside_the_main_hand_is_refused_by_the_bound(self):
        original = script_count.melee_equip_indexes

        def main_only(steps):
            return {index for index in original(steps)
                    if 16 not in (steps[index].get('slot'), steps[min(index + 1, len(steps) - 1)].get('slot'))}

        for name, patched in (('one_main_hand', lambda class_file, main_hand, steps: steps),
                              ('melee_equip_indexes', main_only)):
            with self.subTest(mutant=name), mock.patch.object(script_count, name, patched), \
                    self.assertRaisesRegex(ValueError, 'equipped melee hands'):
                self.dual_wield_swings()

if __name__ == '__main__':
    unittest.main()
