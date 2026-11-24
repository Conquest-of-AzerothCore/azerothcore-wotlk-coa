import unittest
from unittest import mock

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import BEHAVIOUR, verdict_evidence
import kinds.attacker_miss_share as share
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 572752, 'name': 'Sun Down (attackers swing inside the scorched earth)', 'kind': 'attacker_miss_share',
         'quote': "reduces the target's chance to hit by", 'quote_spell': 807175, 'cast_spell': 572752,
         'aura': 807175, 'expected': 3,
         'arm_ms': 64000, 'cycle_ms': 8000, 'settle_ms': 7500}
HERALD = {'spell': 804630, 'name': 'Herald of Dawn (attacker swings under the Solar Flare)',
          'kind': 'attacker_miss_share', 'quote': "reduces the target's chance to hit by", 'quote_spell': 807175,
          'cast_spell': 500146,
          'pre_cast': [806477], 'learn': [804630, 806477], 'aura': 807175, 'expected': 3, 'attackers': 1,
          'arm_ms': 64000, 'cycle_ms': 8000, 'settle_ms': 7500, 'label_suffix': 'herald_miss'}
BASE_MANA = {'power': 0, 'value': 1363, 'source': 'seeded test value'}


def class_file() -> dict:
    return {**load_fixture_class_file(23), 'base_mana': BASE_MANA}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AttackerMissShareTests(unittest.TestCase):
    def built(self, entry=None, parts: int = 1):
        scenario, [expectation] = behaviour_scenario(class_file(), entry or ENTRY)
        if parts > 1:
            expectation.model['parts'] = parts
        return scenario, expectation

    def test_pre_cast_casts_the_sequence_before_the_cast_spell_in_every_treatment_cycle(self):
        scenario, expectation = self.built(HERALD)
        run.validate(scenario, run.SIMULATED_CLOCK)
        casts = [step['spell'] for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [806477, 500146] * 9)
        self.assertEqual(expectation.model['auras']['treatment'][0].count('herald_miss'), 1)

    def test_pre_cast_needs_a_settle_and_a_cycle_over_the_whole_sequence(self):
        with self.assertRaises(ValueError):
            self.built({**HERALD, 'settle_ms': 4000})
        with self.assertRaises(ValueError):
            self.built({**HERALD, 'cycle_ms': 5000, 'arm_ms': 60000})

    def values(self, expectation, control: tuple[int, int], treated: tuple[int, int], held: dict | None = None):
        model = expectation.model
        values = {}
        for arm, (misses, swings) in (('control', control), ('treatment', treated)):
            reads = model['reads'][arm]
            values[reads['start swings']], values[reads['start misses']] = 50.0, 5.0
            values[reads['end swings']], values[reads['end misses']] = 50.0 + swings, 5.0 + misses
            for label in model['auras'][arm]:
                values[label] = 1.0 if arm == 'treatment' else 0.0
        values.update(held or {})
        return values

    def pooled(self, control, treated, parts: int = 2, held: dict | None = None, ran: int | None = None):
        _, expectation = self.built(parts=parts)
        runs = []
        for index in range(parts if ran is None else ran):
            part = FakeRun(self.values(expectation, control, treated, held if index == 1 else None))
            part.key = f'part-{index + 1}'
            runs.append(part)
        return share.POOLED_JUDGE(base_verdict(expectation), runs, expectation.model)

    def test_the_treatment_casts_the_spell_and_never_sets_the_aura(self):
        scenario, expectation = self.built()
        run.validate(scenario)
        actions = [step['action'] for step in scenario['steps']]
        self.assertNotIn('set_aura', actions)
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(len(casts), 1 + ENTRY['arm_ms'] // ENTRY['cycle_ms'])
        self.assertTrue(all(step['spell'] == 572752 and step['target'] == 'attacker1' for step in casts))
        self.assertEqual(actions.count('reset_cooldown'), len(casts))
        powers = [step for step in scenario['steps'] if step['action'] == 'set_power']
        self.assertEqual(len(powers), len(casts))
        self.assertTrue(all(step['value'] == BASE_MANA['value'] for step in powers))
        self.assertEqual(expectation.model['expected'], 3.0)
        self.assertEqual(len(scenario['creatures']), 8)

    def test_relocate_dx_moves_the_caster_once_before_the_first_read(self):
        plain, _ = self.built()
        moved, expectation = self.built({**ENTRY, 'relocate_dx': -1.0})
        run.validate(moved, run.SIMULATED_CLOCK)
        relocations = [index for index, step in enumerate(moved['steps']) if step['action'] == 'relocate']
        self.assertEqual(len(relocations), 1)
        step = moved['steps'][relocations[0]]
        self.assertEqual((step['actor'], step['dx']), ('caster', -1.0))
        labels = [step.get('label') for step in moved['steps']]
        self.assertLess(relocations[0], labels.index(expectation.model['reads']['control']['start swings']))
        self.assertGreater(relocations[0], labels.index('engage'))
        self.assertEqual([step for index, step in enumerate(moved['steps']) if index != relocations[0]],
                         plain['steps'])
        self.assertNotIn('relocate', [step['action'] for step in plain['steps']])

    def test_relocate_dx_is_a_nonzero_distance_under_the_attackers_distance(self):
        for raw in (0, 3.0, -3.0, 40, float('nan'), 'x'):
            with self.assertRaises(ValueError):
                self.built({**ENTRY, 'relocate_dx': raw})

    def test_no_cast_lies_inside_the_control_arm(self):
        scenario, expectation = self.built()
        labels = [step.get('label') for step in scenario['steps']]
        steps = scenario['steps']
        control_end = labels.index(expectation.model['reads']['control']['end misses'])
        self.assertFalse([step for step in steps[:control_end] if step['action'] == 'cast'])

    def test_counting_starts_after_the_settle_and_the_aura_read_on_every_attacker(self):
        scenario, expectation = self.built()
        labels = [step.get('label') for step in scenario['steps']]
        start = labels.index(expectation.model['reads']['treatment']['start swings'])
        ready = [label for label in expectation.model['auras']['treatment'] if ' ready ' in label]
        self.assertEqual(len(ready), 8)
        self.assertTrue(all(labels.index(label) < start for label in ready))
        self.assertEqual(labels.index('treatment settle'), start - len(ready) - 1)
        reads = [step for step in scenario['steps'] if step.get('label') in ready]
        self.assertTrue(all(step['metric'] == 'aura' and step['spell'] == 807175 and step['caster'] == 'caster'
                            for step in reads))
        misses = [step for step in scenario['steps'] if step.get('label', '').endswith(' misses')]
        self.assertTrue(misses and all(step['victim_state'] == 0 for step in misses))

    def test_the_stated_change_passes_over_two_parts(self):
        verdict = self.pooled((400, 8000), (640, 8000))
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertAlmostEqual(verdict.measured, 3.0)
        self.assertIn('2 parts pooled', verdict.explanation)
        self.assertIn('reset_cooldown 572752', verdict.explanation)

    def test_an_unresolved_change_is_not_judged_and_a_missing_or_reversed_one_alerts(self):
        self.assertEqual(self.pooled((40, 800), (40, 800)).status, 'insufficient_trials')
        self.assertEqual(self.pooled((300, 6000), (336, 6000)).status, 'insufficient_trials')
        self.assertEqual(self.pooled((400, 8000), (400, 8000)).status, 'alert')
        self.assertEqual(self.pooled((400, 8000), (160, 8000)).status, 'alert')

    def test_a_lapsed_aura_a_clamped_control_or_a_missing_part_is_unmeasured(self):
        _, expectation = self.built(parts=2)
        lapsed = {expectation.model['auras']['treatment'][-1]: 0.0}
        verdict = self.pooled((400, 8000), (640, 8000), held=lapsed)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertTrue(verdict.explanation.startswith('part-2: '))
        contaminated = {expectation.model['auras']['control'][0]: 1.0}
        self.assertEqual(self.pooled((400, 8000), (640, 8000), held=contaminated).status, 'unmeasured')
        self.assertEqual(self.pooled((160, 8000), (400, 8000)).status, 'unmeasured')
        self.assertEqual(self.pooled((400, 8000), (640, 8000), ran=1).status, 'unmeasured')

    def test_refused_treatment_casts_are_named_as_an_invalid_setup(self):
        _, expectation = self.built()
        ready = {expectation.model['auras']['treatment'][0]: 0.0}
        refused = FakeRun(self.values(expectation, (400, 8000), (640, 8000), ready))
        refused.cast_failures = {572752: [134, 134, 0]}
        verdict = share.POOLED_JUDGE(base_verdict(expectation), [refused], expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('; invalid setup: 2 casts of 572752 refused, ', verdict.explanation)
        self.assertIn('(134)', verdict.explanation)
        plain = FakeRun(self.values(expectation, (400, 8000), (640, 8000), ready))
        verdict = share.POOLED_JUDGE(base_verdict(expectation), [plain], expectation.model)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertNotIn('invalid setup', verdict.explanation)

    def test_a_treatment_read_of_hits_instead_of_misses_alerts(self):
        with mock.patch.object(share, 'MISS_VICTIM_STATE', 1):
            scenario, expectation = self.built(parts=2)
        reads = [step for step in scenario['steps'] if step.get('label') == expectation.model['reads']['treatment']
                 ['end misses']]
        self.assertEqual(reads[0]['victim_state'], 1)
        hits_read_as_misses = self.pooled((400, 8000), (7200, 8000))
        self.assertEqual(hits_read_as_misses.status, 'alert')

    def test_the_single_part_judge_runs_through_compare(self):
        _, expectation = self.built()
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(self.values(expectation, (800, 16000),
                                                                                 (1280, 16000))), expectation)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertEqual(verdict_evidence(verdict, ENTRY['quote'], {}), BEHAVIOUR)

    def test_entries_the_kind_cannot_measure_are_refused(self):
        refused = [{**ENTRY, 'attackers': 9}, {**ENTRY, 'cycle_ms': 10000, 'arm_ms': 60000},
                   {**ENTRY, 'arm_ms': 60000}, {**ENTRY, 'expected': -3}, {**ENTRY, 'settle_ms': 1000},
                   {**ENTRY, 'aura': 572754}, {**ENTRY, 'cycle_ms': 1000, 'arm_ms': 1_000_000},
                   {**ENTRY, 'cycle_ms': 9000, 'arm_ms': 3_600_000}, {**ENTRY, 'quote_spell': 572754},
                   {key: value for key, value in ENTRY.items() if key != 'quote_spell'}]
        for entry in refused:
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                self.built(entry)
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), ENTRY)


SPELL_CLAMP = {'spell': 300348, 'name': 'Sun Shield (attacker spell hit clamp)', 'kind': 'attacker_miss_share',
               'variant': 'spell_clamp', 'label_suffix': 'spell_hit_taken',
               'quote': 'Reduces your chance to be hit by spells by', 'attacker_spell': 585, 'expected': 3}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class SpellClampTests(unittest.TestCase):
    def built(self, **changes):
        return behaviour_scenario(load_fixture_class_file(23), {**SPELL_CLAMP, **changes})

    def test_four_attackers_cast_at_the_clamp_and_one_point_under_it_around_the_learn(self):
        scenario, [expectation] = self.built()
        bonuses = [creature['spell_hit_bonus'] for creature in scenario['creatures']]
        self.assertEqual(bonuses, [4, 3, 7, 6])
        casts = share.spell_clamp_casts()
        self.assertLessEqual(4 * 0.99 ** casts, share.SPELL_RESIDUAL)
        self.assertGreater(4 * 0.99 ** (casts - 1), share.SPELL_RESIDUAL)
        steps = scenario['steps']
        per_attacker = {creature['id']: len([step for step in steps if step['action'] == 'cast'
                                             and step['actor'] == creature['id'] and step['spell'] == 585])
                        for creature in scenario['creatures']}
        self.assertEqual(set(per_attacker.values()), {casts})
        learn = next(index for index, step in enumerate(steps) if step['action'] == 'learn'
                     and step['spell'] == 300348)
        first_treatment = next(index for index, step in enumerate(steps) if step.get('actor') == 'attacker3')
        last_control = max(index for index, step in enumerate(steps) if step.get('actor') == 'attacker2')
        self.assertTrue(last_control < learn < first_treatment)
        self.assertEqual(expectation.model['expected'], 3.0)
        self.assertEqual(share.label(SPELL_CLAMP), [expectation.label])

    def test_a_wrong_figure_a_non_magic_spell_or_another_aura_is_refused(self):
        for changes in ({'expected': 4}, {'expected': 0}, {'attacker_spell': 6603},
                        {'spell': 572752, 'quote': "reduces the target's chance to hit by"}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.built(**changes)

    def judged(self, misses: dict, casts=None, auras=(0.0, 1.0), size=None):
        _, [expectation] = self.built() if size is None else self.built(casts=size)
        clamp = expectation.model['spell_clamp']
        values = {clamp['auras']['control']: auras[0], clamp['auras']['treatment']: auras[1]}
        for arm, reads in clamp['reads'].items():
            count = clamp['casts'] if casts is None else casts
            values.update({reads['start casts']: 0.0, reads['start landed']: 0.0, reads['end casts']: float(count),
                           reads['end landed']: float(count - misses.get(arm, 0))})
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_three_point_reduction_passes_and_two_or_four_point_mutants_alert(self):
        correct = {'control edge': 8, 'treatment edge': 9}
        self.assertEqual(self.judged(correct).status, 'ok', self.judged(correct).explanation)
        self.assertEqual(self.judged({**correct, 'treatment clamp': 7}).status, 'alert')
        self.assertEqual(self.judged({'control edge': 8}).status, 'alert')

    def test_a_control_off_the_base_or_a_short_arm_or_an_unread_aura_is_unmeasured(self):
        correct = {'control edge': 8, 'treatment edge': 9}
        for name, verdict in (('control clamp miss', self.judged({**correct, 'control clamp': 1})),
                              ('missless control edge', self.judged({'treatment edge': 9})),
                              ('short arms', self.judged(correct, casts=800)),
                              ('treatment aura absent', self.judged(correct, auras=(0.0, 0.0))),
                              ('control aura present', self.judged(correct, auras=(1.0, 1.0)))):
            with self.subTest(name=name):
                self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)

    def test_a_casts_option_sizes_every_arm_and_the_judge_and_absent_keeps_the_default(self):
        default, _ = self.built()
        self.assertEqual(self.built(casts=share.spell_clamp_casts())[0], default)
        scenario, [expectation] = self.built(casts=1100)
        per_attacker = [len([step for step in scenario['steps'] if step['action'] == 'cast'
                             and step['actor'] == creature['id'] and step['spell'] == 585])
                        for creature in scenario['creatures']]
        self.assertEqual(per_attacker, [1100] * 4)
        self.assertEqual(expectation.model['spell_clamp']['casts'], 1100)
        self.assertIn('cast 585 at the caster 1100 times', scenario['contract'])
        self.assertIn(f'{4 * 0.99 ** 1100:.2e} per pair', scenario['contract'])

    def test_a_casts_option_under_the_default_or_not_a_whole_count_is_refused(self):
        for casts in (share.spell_clamp_casts() - 1, 0, 1100.0, '1100', True):
            with self.subTest(casts=casts), self.assertRaises(ValueError):
                self.built(casts=casts)

    def test_a_sized_entry_passes_alerts_on_mutants_and_is_unmeasured_on_the_default_count(self):
        correct = {'control edge': 11, 'treatment edge': 10}
        self.assertEqual(self.judged(correct, size=1100).status, 'ok')
        self.assertEqual(self.judged({**correct, 'treatment clamp': 1}, size=1100).status, 'alert')
        self.assertEqual(self.judged({'control edge': 11}, size=1100).status, 'alert')
        short = self.judged(correct, casts=share.spell_clamp_casts(), size=1100)
        self.assertEqual(short.status, 'unmeasured', short.explanation)

    def test_the_spell_variant_is_classed_behaviour_by_its_damage_log_metric(self):
        verdict = self.judged({'control edge': 8, 'treatment edge': 9})
        self.assertEqual(verdict_evidence(verdict, SPELL_CLAMP['quote'], {}), BEHAVIOUR)


if __name__ == '__main__':
    unittest.main()
