import unittest

from behaviours import behaviour_scenario
from kinds.flat_chance_rate import POOLED_JUDGE, flat_chance_verdict
from kinds.stack_chance_rate import arm_trials_needed
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
    return FakeRun(values)


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

    def test_events_per_proc_divide_the_events(self):
        verdict = self.pooled({**HEAL, 'events_per_proc': 2}, {'unlearned': (10, 0), 'treatment': (1000, 160)},
                              spread=4)
        self.assertEqual(verdict.status, 'ok')


if __name__ == '__main__':
    unittest.main()
