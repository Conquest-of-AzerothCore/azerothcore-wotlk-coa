import unittest

from behaviours import behaviour_scenario
from kinds.flat_chance_rate import POOLED_JUDGE, flat_chance_verdict
from kinds.stack_chance_rate import STREAM_LOCATION, arm_trials_needed
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

HEX = 801693
SPIRIT = 561136
BREW = 801670
WARD = 500960
WARD_ENTRY = 50105
ATTACK = 573055
VOODOO = 500473
CLASS_FILE = {'class_id': 13, 'name': 'Witch Doctor', 'race': 1, 'level': 60, 'skill_lines': [],
              'reference_stats': {}}
RESIST = {'spell': 823764, 'stacks': 1, 'source': 'no tick fully resisted'}
TICK = {'spell': 503707, 'name': 'Darkspear Traditionalist (tick rate)', 'kind': 'flat_chance_rate',
        'variant': 'hex_spirit_rate', 'label_suffix': 'hex_spirit_rate',
        'quote': 'Periodic damage dealt by Hex of Malice now has a $h% chance to collect a Spirit.',
        'chance_pct': 20, 'trigger_spell': HEX, 'cast_power': 1400, 'attempt_auras': [RESIST],
        'stop_trigger_aura': True, 'cast_wait_ms': 3500,
        'trial': {'metric': 'spell_damage_count', 'spell': HEX, 'target': 'dummy', 'periodic': True},
        'event': {'metric': 'spell_cast_count', 'spell': SPIRIT},
        'cycles': 900, 'unlearned_cycles': 10, 'trials_per_cycle': 1, 'parts': 21}
HEAL = {'spell': 804620, 'name': 'Loa Spirits rank one (heal rate)', 'kind': 'flat_chance_rate',
        'variant': 'heal_rate', 'label_suffix': 'heal_rate',
        'quote': 'Damage dealt and healing done now has a $h% chance to collect a Spirit.', 'chance_pct': 8,
        'trigger_spell': BREW, 'trigger_target': 'caster', 'cast_power': 1400, 'caster_health_pct': 30,
        'cast_wait_ms': 2400, 'trial': {'metric': 'spell_heal_count', 'spell': BREW, 'target': 'caster'},
        'event': {'metric': 'spell_cast_count', 'spell': SPIRIT},
        'cycles': 1000, 'unlearned_cycles': 10, 'trials_per_cycle': 1, 'parts': 10}
CREATURE = {'spell': 802262, 'name': 'Voodoo Fire (ward rate)', 'kind': 'flat_chance_rate', 'variant': 'voodoo_rate',
            'label_suffix': 'voodoo_rate',
            'quote': "Your Serpent Ward's attacks now have a $h% chance to shoot Voodoo Fire,", 'chance_pct': 20,
            'learn': [WARD], 'trigger_spell': HEX, 'cast_power': 1400,
            'setup': {'spell': WARD, 'target': 'caster', 'power': 1400, 'every': 1},
            'layout': [{'do': 'trigger', 'wait_ms': 1600}, {'do': 'setup', 'wait_ms': 100}, {'do': 'start'},
                       {'do': 'wait', 'ms': 18300}, {'do': 'trigger', 'wait_ms': 19000},
                       {'do': 'trigger', 'wait_ms': 18700}, {'do': 'end'}, {'do': 'wait', 'ms': 4000}],
            'trial': {'metric': 'owned_creature_spell_cast_count', 'spell': ATTACK, 'entry': WARD_ENTRY},
            'event': {'metric': 'owned_creature_spell_cast_count', 'spell': VOODOO, 'entry': WARD_ENTRY},
            'cycles': 52, 'unlearned_cycles': 1, 'trials_per_cycle': 27, 'parts': 14}
SINGLE_TARGET = {'reach_yd': 0, 'source': 'single-target trigger at the own dummy, caster auras only'}
SERPENT = {'entries': [WARD_ENTRY], 'within_yd': 3.5, 'reach_yd': 30, 'combat_reach_yd': 4,
           'spells': [ATTACK, VOODOO]}
TICK_STREAMS = {**TICK, 'streams': 8, 'cycles': 113, 'unlearned_cycles': 2, 'isolation': SINGLE_TARGET}
HEAL_STREAMS = {**HEAL, 'streams': 8, 'cycles': 125, 'unlearned_cycles': 2, 'isolation': SINGLE_TARGET}
CREATURE_STREAMS = {**CREATURE, 'streams': 4, 'cycles': 13, 'dummy_distance': 25,
                    'isolation': {'reach_yd': 10, 'source': 'Voodoo Fire 10 yd from the own dummy; ward 30 yd',
                                  'wards': [SERPENT]}}


def counted_run(expectation, counts: dict) -> FakeRun:
    values, trials_total, events_total = {}, 0.0, 0.0
    for arm in expectation.model['arms']:
        trials, events = counts[arm['name']]
        segments = arm['segments']
        for index, segment in enumerate(segments):
            share_trials = trials / len(segments)
            share_events = events / len(segments)
            values[segment['start trials']], values[segment['start events']] = trials_total, events_total
            trials_total += share_trials
            events_total += share_events
            values[segment['end trials']], values[segment['end events']] = trials_total, events_total
    for item in expectation.model.get('isolation', []):
        values[item['label']] = (item['min'] + item['max']) / 2
    return FakeRun(values)


def own_dummy(actor: str) -> str:
    return actor.replace('caster', 'dummy')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FlatChanceRateTests(unittest.TestCase):
    def built(self, entry, **changes):
        return behaviour_scenario(CLASS_FILE, {**entry, **changes})

    def pooled(self, entry, counts: dict, spread: int = 0):
        _, [expectation] = self.built(entry)
        runs = []
        for index in range(entry['parts']):
            sign = 1 if index % 2 else -1
            runs.append(counted_run(expectation, {name: (trials, events + (sign * spread if name == 'treatment' else 0))
                                                  for name, (trials, events) in counts.items()}))
        return POOLED_JUDGE(base_verdict(expectation), runs, expectation.model)

    def test_a_tick_cycle_casts_waits_and_removes_the_hex_and_the_talent_follows_the_unlearned_arm(self):
        scenario, [expectation] = self.built(TICK)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual(len(casts), 910)
        removals = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == HEX]
        self.assertEqual({(step['stacks'], step['target']) for step in removals}, {(0, 'dummy')})
        self.assertEqual(len(removals), 910)
        learns = [index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 503707]
        self.assertEqual(len(learns), 1)
        self.assertEqual(sum(1 for index in casts if index < learns[0]), 10)
        reads = [step for step in steps if step.get('metric') == 'spell_damage_count']
        self.assertTrue(all(step['periodic'] is True and step['target'] == 'dummy' for step in reads))
        self.assertEqual(expectation.model['metric'], 'flat_chance_rate')

    def test_a_heal_cycle_holds_the_caster_health_before_every_self_cast(self):
        scenario, _ = self.built(HEAL)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertTrue(all(steps[index]['target'] == 'caster' for index in casts))
        self.assertTrue(all(steps[index - 2]['action'] == 'set_health' for index in casts))
        self.assertEqual(steps[casts[0] - 2]['value'], 3000)

    def test_a_creature_cycle_reads_each_ward_once_at_its_start_and_end(self):
        scenario, [expectation] = self.built(CREATURE)
        run.validate(scenario, run.SIMULATED_CLOCK)
        treatment = expectation.model['arms'][1]
        self.assertEqual(len(treatment['segments']), 52)
        self.assertEqual(len(expectation.model['arms'][0]['segments']), 1)
        reads = [step for step in scenario['steps'] if step.get('metric') == 'owned_creature_spell_cast_count']
        self.assertEqual(len(reads), 4 * 53)
        self.assertTrue(all(step['entry'] == WARD_ENTRY for step in reads))

    def test_an_unlearned_override_reads_its_own_creature(self):
        viper = {**CREATURE, 'spell': 707329, 'talents': [707329], 'learn': [712373, WARD], 'chance_pct': 50,
                 'quote': 'Transforms Call of Sseratus into Viper Ward.@s:712373:0@',
                 'setup': {'spell': 712373, 'target': 'dummy', 'power': 1400, 'every': 1},
                 'unlearned': {'setup': {'spell': WARD, 'target': 'caster', 'power': 1400, 'every': 1},
                               'entry': WARD_ENTRY},
                 'trial': {'metric': 'owned_creature_spell_cast_count', 'spell': ATTACK, 'entry': 51105},
                 'event': {'metric': 'owned_creature_spell_cast_count', 'spell': 712415, 'entry': 51105},
                 'cycles': 100, 'trials_per_cycle': 17, 'parts': 12,
                 'layout': [{'do': 'trigger', 'wait_ms': 1600}, {'do': 'setup', 'wait_ms': 100}, {'do': 'start'},
                            {'do': 'wait', 'ms': 18900}, {'do': 'end'}, {'do': 'wait', 'ms': 1500}]}
        scenario, _ = self.built(viper)
        reads = [step for step in scenario['steps'] if step.get('metric') == 'owned_creature_spell_cast_count']
        self.assertEqual({step['entry'] for step in reads[:4]}, {WARD_ENTRY})
        self.assertEqual({step['entry'] for step in reads[4:]}, {51105})
        setups = [step['spell'] for step in scenario['steps'] if step['action'] == 'cast' and step['spell'] != HEX]
        self.assertEqual(setups[0], WARD)
        self.assertEqual(set(setups[1:]), {712373})

    def test_fewer_trials_than_the_flip_proof_size_are_refused(self):
        needed = arm_trials_needed(0.2, 1, 21)
        with self.assertRaisesRegex(ValueError, f'{needed} flip-proof trials'):
            self.built(TICK, cycles=needed // 21 - 1)

    def test_a_cast_inside_the_global_cooldown_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'cast and global cooldown'):
            self.built(TICK, cast_wait_ms=1000)

    def test_the_talent_cannot_be_learned_up_front(self):
        with self.assertRaisesRegex(ValueError, 'between the unlearned and treatment arms'):
            self.built(TICK, learn=[503707])

    def test_the_stated_rate_passes_inside_the_band(self):
        verdict = self.pooled(TICK, {'unlearned': (10, 0), 'treatment': (900, 180)}, spread=6)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['contrast'], 'learned')

    def test_a_rate_three_points_off_alerts(self):
        verdict = self.pooled(TICK, {'unlearned': (10, 0), 'treatment': (900, 207)}, spread=6)
        self.assertEqual(verdict.status, 'alert')

    def test_an_event_without_the_talent_alerts(self):
        verdict = self.pooled(TICK, {'unlearned': (10, 1), 'treatment': (900, 180)}, spread=6)
        self.assertEqual(verdict.status, 'alert')
        self.assertNotIn('contrast', verdict.detail)

    def test_a_missing_read_is_unmeasured(self):
        _, [expectation] = self.built(TICK)
        verdict = flat_chance_verdict(base_verdict(expectation), FakeRun({}), expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')

    def test_fewer_measured_trials_than_the_size_are_insufficient(self):
        verdict = self.pooled(TICK, {'unlearned': (10, 0), 'treatment': (500, 100)}, spread=4)
        self.assertEqual(verdict.status, 'insufficient_trials')

    def test_streams_cast_each_caster_at_its_own_dummy_on_flat_ground(self):
        scenario, [expectation] = self.built(TICK_STREAMS)
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(scenario['location'], STREAM_LOCATION)
        self.assertEqual([player['id'] for player in scenario['players']],
                         ['caster'] + [f'caster{index}' for index in range(1, 8)])
        self.assertEqual([(creature['id'], creature['owner'], creature['distance'])
                          for creature in scenario['creatures']][:2],
                         [('dummy', 'caster', 0.0), ('dummy1', 'caster1', 14.286)])
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(len(casts), 8 * 115)
        self.assertTrue(all(step['target'] == own_dummy(step['actor']) for step in casts))
        reads = [step for step in scenario['steps']
                 if step.get('metric') == 'spell_damage_count' and step.get('periodic')]
        self.assertTrue(all(step['target'] == own_dummy(step['actor']) for step in reads))
        self.assertEqual([len(arm['segments']) for arm in expectation.model['arms']], [8, 8])

    def test_streams_place_every_caster_and_assert_ground_and_distances(self):
        scenario, _ = self.built(TICK_STREAMS)
        steps = scenario['steps']
        moves = [step for step in steps if step['action'] == 'relocate' and step['actor'] == 'caster7']
        self.assertEqual(round(sum(step.get('dx', 0) for step in moves), 3), 100.0)
        self.assertEqual(sum(step.get('dy', 0) for step in moves), -3)
        self.assertTrue(all(abs(step.get('dx', step.get('dy'))) <= 20 for step in moves))
        grounds = [step for step in steps if step.get('metric') == 'ground_height']
        self.assertEqual(len(grounds), 16)
        self.assertTrue(all(step['min'] == STREAM_LOCATION['z'] - 0.5 for step in grounds))
        distances = {step['label'].split(' isolation ')[1]: step for step in steps
                     if step.get('metric') == 'distance'}
        self.assertEqual(len(distances), 64)
        self.assertEqual((distances['s0 to s0 distance']['min'], distances['s0 to s0 distance']['max']), (2.5, 3.5))
        self.assertEqual(distances['s7 to s0 distance']['min'], 99.545)

    def test_streams_assert_no_damage_or_healing_across_streams(self):
        scenario, [expectation] = self.built(TICK_STREAMS)
        crossing = [step for step in scenario['steps'] if ' dummy 801693 from ' in step.get('label', '')]
        self.assertEqual(len(crossing), 56)
        self.assertTrue(all(step['min'] == step['max'] == 0 and step['caster'] != step['actor']
                            for step in crossing))
        self.assertTrue(all(step['target'] == own_dummy(step['actor']) for step in crossing))
        self.assertIn({'label': crossing[0]['label'], 'min': 0, 'max': 0, 'status': 'alert'},
                      expectation.model['isolation'])
        heal, _ = self.built(HEAL_STREAMS)
        healing = [step for step in heal['steps'] if step.get('metric') == 'spell_heal_count'
                   and step.get('max') == 0]
        self.assertEqual(len(healing), 56)
        self.assertTrue(all(step['target'] != step['actor'] for step in healing))

    def test_stream_wards_read_their_hits_and_placement_while_they_live(self):
        scenario, _ = self.built(CREATURE_STREAMS)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        hits = [step for step in steps if ' ward 50105 573055 on ' in step.get('label', '')]
        self.assertEqual(len(hits), 12 * 14)
        self.assertTrue(all(step['entry'] == WARD_ENTRY and step['max'] == 0 for step in hits))
        placements = [index for index, step in enumerate(steps) if step.get('label', '').endswith(' placement')]
        self.assertEqual(len(placements), 4 * 14)
        self.assertTrue(all(steps[index]['min_distance'] == 3.5 for index in placements))
        for index in placements:
            previous = next(step for step in reversed(steps[:index]) if step['action'] != 'assert')
            self.assertNotEqual(previous.get('label'), 'cycle')

    def test_streams_keep_the_flip_proof_size(self):
        needed = arm_trials_needed(0.2, 1, 21)
        with self.assertRaisesRegex(ValueError, f'{needed} flip-proof trials'):
            self.built(TICK_STREAMS, cycles=needed // (21 * 8) - 1)

    def test_streams_need_a_settled_isolation(self):
        with self.assertRaisesRegex(ValueError, 'settle their isolation'):
            self.built({key: value for key, value in TICK_STREAMS.items() if key != 'isolation'})

    def test_streams_closer_than_a_reach_are_refused(self):
        with self.assertRaisesRegex(ValueError, 'not beyond the 12 yd reach'):
            self.built(TICK_STREAMS, isolation={**SINGLE_TARGET, 'reach_yd': 12})

    def test_a_ward_within_its_reach_of_another_dummy_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'from another dummy'):
            self.built(CREATURE_STREAMS, streams=5, cycles=11)

    def test_stream_reads_are_summed_per_part(self):
        verdict = self.pooled(TICK_STREAMS, {'unlearned': (16, 0), 'treatment': (904, 181)}, spread=6)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['arms'][1]['trials'], 904 * 21)

    def test_a_hit_across_streams_alerts(self):
        _, [expectation] = self.built(CREATURE_STREAMS)
        part = counted_run(expectation, {'unlearned': (27 * 4, 0), 'treatment': (27 * 52, 281)})
        label = next(item['label'] for item in expectation.model['isolation'] if ' 500473 on s2 ' in item['label'])
        part.values[label] = 1
        verdict = POOLED_JUDGE(base_verdict(expectation), [part], expectation.model)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('stream isolation', verdict.explanation)

    def test_a_stream_off_its_ground_or_place_is_unmeasured(self):
        _, [expectation] = self.built(TICK_STREAMS)
        part = counted_run(expectation, {'unlearned': (16, 0), 'treatment': (904, 181)})
        label = next(item['label'] for item in expectation.model['isolation']
                     if item['label'].endswith('s5 to s5 distance'))
        part.values[label] = 9
        verdict = flat_chance_verdict(base_verdict(expectation), part, expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('stream isolation', verdict.explanation)

    def test_a_missing_isolation_read_is_unmeasured(self):
        _, [expectation] = self.built(TICK_STREAMS)
        part = counted_run(expectation, {'unlearned': (16, 0), 'treatment': (904, 181)})
        del part.values[expectation.model['isolation'][-1]['label']]
        verdict = flat_chance_verdict(base_verdict(expectation), part, expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')
    def test_a_rating_fixture_sets_the_caster_and_reads_its_bonus_once(self):
        rated = {**TICK, 'player_ratings': {'ranged_crit_rating': 280},
                 'rating_bonus': {'rating': 9, 'expected_pct': 20.0, 'tolerance': 0.01}}
        scenario, [expectation] = self.built(rated)
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(scenario['players'][0]['ranged_crit_rating'], 280)
        reads = [step for step in scenario['steps'] if step.get('metric') == 'combat_rating_bonus']
        self.assertEqual([(read['rating'], read['label']) for read in reads],
                         [(9, expectation.model['rating_bonus']['label'])])
        _, [plain] = self.built(TICK)
        self.assertNotIn('rating_bonus', plain.model)

    def test_a_rating_bonus_off_its_statement_is_unmeasured(self):
        rated = {**TICK, 'player_ratings': {'ranged_crit_rating': 280},
                 'rating_bonus': {'rating': 9, 'expected_pct': 20.0, 'tolerance': 0.01}}
        _, [expectation] = self.built(rated)
        label = expectation.model['rating_bonus']['label']

        def judged(bonus):
            runs = []
            for index in range(rated['parts']):
                fake = counted_run(expectation, {'unlearned': (10, 0), 'treatment': (900, 180 + (6 if index % 2
                                                                                                else -6))})
                fake.values[label] = bonus
                runs.append(fake)
            return POOLED_JUDGE(base_verdict(expectation), runs, expectation.model).status

        self.assertEqual(judged(20.000002), 'ok')
        self.assertEqual(judged(10.0), 'unmeasured')

    def test_refused_rating_inputs(self):
        for changes in ({'player_ratings': {'haste_rating': 10}}, {'player_ratings': {'ranged_crit_rating': -1}},
                        {'rating_bonus': {'rating': 9, 'expected_pct': 20.0, 'tolerance': 0.01}},
                        {'player_ratings': {'ranged_crit_rating': 280},
                         'rating_bonus': {'rating': 25, 'expected_pct': 20.0, 'tolerance': 0.01}},
                        {'player_ratings': {'ranged_crit_rating': 280},
                         'rating_bonus': {'rating': 9, 'expected_pct': 20.0}}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(TICK, **changes)

    def test_events_per_proc_divide_the_events(self):
        verdict = self.pooled({**HEAL, 'events_per_proc': 2}, {'unlearned': (10, 0), 'treatment': (1000, 160)},
                              spread=4)
        self.assertEqual(verdict.status, 'ok')


if __name__ == '__main__':
    unittest.main()
