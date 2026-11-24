from pathlib import Path
import sys
import unittest

from behaviours import behaviour_scenario
import compare as compare_module
from profile import DBC_DIR
from test_behaviours import CLASS_FILE, FakeRun, base_verdict

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

NEEDS_DBC = unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
FELBANE_QUOTE = 'Curse an enemy, causing the next spell they cast within $d to be reflected onto them.'
RESOLVE_END_QUOTE = ('When this ends, you unleash a Felfire Blast that leeches health from nearby enemies based on how '
                     'many times you took damage with the effect active.')


def reflect_entry(**changes) -> dict:
    return {'spell': 525001, 'name': 'seeded reflect', 'kind': 'taken_hit', 'variant': 'reflect',
            'label_suffix': 'reflect', 'judge': 'counts', 'quote': FELBANE_QUOTE, 'strike_spell': 41394,
            'trials': 4, 'striker_spell_hit': True, 'striker_untriggered': True,
            'count_reads': {'landed': {'metric': 'spell_damage_count', 'spell': 41394, 'caster': 'striker',
                                       'target': 'caster'},
                            'reflected': {'metric': 'spell_damage_count', 'spell': 41394, 'caster': 'striker',
                                          'target': 'striker'}},
            'count_total': ['landed', 'reflected'],
            'arms': [{'name': 'control', 'strikes': 2, 'counts': {'landed': 2, 'reflected': 0}},
                     {'name': 'treatment', 'casts': [[525001, 'striker']], 'strikes': 2,
                      'counts': {'landed': 1, 'reflected': 1}}], **changes}


def leech_entry(**changes) -> dict:
    return {'spell': 804823, 'name': 'seeded end leech', 'kind': 'taken_hit', 'variant': 'end_leech',
            'label_suffix': 'end_leech', 'judge': 'counts', 'quote': RESOLVE_END_QUOTE, 'strike_spell': 41394,
            'trials': 2, 'caster_health_pct': 100, 'caster_max_health': 20000, 'settle_ms': 31000,
            'count_reads': {'hits': {'metric': 'spell_log_count', 'spell': 41394, 'caster': 'striker',
                                     'target': 'caster'},
                            'blast': {'metric': 'spell_damage_total', 'spell': 807347, 'caster': 'caster',
                                      'target': 'striker'},
                            'leech': {'metric': 'spell_heal_total', 'spell': 807347, 'target': 'caster'},
                            'pain': {'metric': 'aura', 'actor': 'striker', 'spell': 704397, 'state': True}},
            'count_total': ['hits'], 'rising': ['blast'], 'equal': [['blast', 'leech']],
            'arms': [{'name': 'one', 'casts': [[804823, 'caster']], 'strikes': 1, 'counts': {'pain': 0}},
                     {'name': 'three', 'casts': [[804823, 'caster']], 'strikes': 3, 'counts': {'pain': 0},
                      'require': {'pain': 0}}], **changes}


def icd_entry(**changes) -> dict:
    return {'spell': 804613, 'name': 'seeded resist icd', 'kind': 'taken_hit', 'variant': 'resist_icd',
            'label_suffix': 'resist_icd', 'judge': 'resist_rate', 'expected_points': 100,
            'quote': 'Can only occur once every 10 sec.', 'strike_spell': 702, 'trials': 4, 'learn': [804613],
            'striker_spell_hit': True,
            'arms': [{'name': 'control', 'auras': [[706818, 0]], 'prime_gap_ms': 9000},
                     {'name': 'treatment', 'auras': [[706818, 0]], 'prime_gap_ms': 11000}], **changes}


def capped_entry(**changes) -> dict:
    return {'spell': 804823, 'name': 'seeded capped', 'kind': 'taken_hit', 'variant': 'capped',
            'label_suffix': 'capped', 'judge': 'absorb', 'quote': 'up to 100% of your maximum health.',
            'strike_spell': 41394, 'trials': 6, 'caster_health_pct': 100, 'caster_max_health': 2000,
            'arms': [{'name': 'control', 'absorb': 'none'},
                     {'name': 'resolve', 'opening_casts': [[804823, 'caster']], 'absorb': 'capped_share',
                      'share_pct': 50, 'cap_pct': 100}], **changes}


def counts_run(model: dict, trials: dict[str, list[dict[str, float]]]) -> FakeRun:
    values = {}
    for arm in model['arms']:
        totals = dict.fromkeys(arm['marks']['start'], 0.0)
        for name, label in arm['marks']['start'].items():
            values[label] = 0.0
        for trial, delta in enumerate(trials[arm['name']], start=1):
            for name, label in arm['marks'][str(trial)].items():
                if name in model['states']:
                    values[label] = delta.get(name, 0.0)
                else:
                    totals[name] += delta.get(name, 0.0)
                    values[label] = totals[name]
    return FakeRun(values)


def counts_verdict(expectation, trials):
    return compare_module.behaviour_taken_hit_verdict(base_verdict(expectation),
                                                      counts_run(expectation.model, trials), expectation.model)


class StrikerFixtureTests(unittest.TestCase):
    @NEEDS_DBC
    def test_untriggered_strikes_and_the_spell_hit_bonus_are_stated_fixtures(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, reflect_entry())
        steps = run.validate(scenario)['steps']
        strikes = [step for step in steps if step['action'] == 'cast' and step['actor'] == 'striker']
        self.assertEqual(len(strikes), 2 * 2 * 4)
        self.assertTrue(all(step['triggered'] is False for step in strikes))
        self.assertEqual(scenario['creatures'][0]['spell_hit_bonus'], 100)
        self.assertIn('untriggered', scenario['contract'])

    @NEEDS_DBC
    def test_without_the_options_the_strike_and_striker_carry_neither(self):
        entry = reflect_entry(striker_spell_hit=False, striker_untriggered=False)
        scenario, _ = behaviour_scenario(CLASS_FILE, entry)
        strikes = [step for step in scenario['steps'] if step['action'] == 'cast' and step['actor'] == 'striker']
        self.assertFalse(any('triggered' in step for step in strikes))
        self.assertNotIn('spell_hit_bonus', scenario['creatures'][0])

    @NEEDS_DBC
    def test_striker_fixtures_of_a_player_striker_are_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, reflect_entry(striker_race=2))


class PrimedResistTests(unittest.TestCase):
    @NEEDS_DBC
    def test_each_trial_primes_waits_its_gap_and_clears_before_the_judged_strike(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, icd_entry())
        steps = run.validate(scenario)['steps']
        gaps = [step['ms'] for step in steps if step.get('label', '').split(' ')[1:2] == ['prime']]
        self.assertEqual(gaps, [9000] * 4 + [11000] * 4)
        index = next(n for n, step in enumerate(steps) if step.get('label') == 'control prime 1')
        self.assertEqual([steps[index - 1]['action'], steps[index + 1]['action'], steps[index + 2]['action']],
                         ['cast', 'set_aura', 'cast'])
        self.assertEqual(expectation.model['kind'], 'taken_rate')

    @NEEDS_DBC
    def test_seeded_cooldown_passes_and_a_mutant_without_one_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, icd_entry())
        model = expectation.model

        def verdict(control_resisted: bool):
            values = {label: (0.0 if control_resisted else 1.0) for label in model['reads']['control']}
            values.update({label: 0.0 for label in model['reads']['treatment']})
            return compare_module.behaviour_taken_rate_verdict(base_verdict(expectation), FakeRun(values), model)

        self.assertEqual(verdict(False).status, 'ok')
        self.assertEqual(verdict(True).status, 'alert')

    @NEEDS_DBC
    def test_a_prime_outside_a_resist_rate_or_without_a_gap_is_refused(self):
        for broken in (icd_entry(arms=[{'name': 'control', 'prime_gap_ms': 0}, {'name': 'treatment'}]),
                       capped_entry(arms=[{'name': 'control', 'prime_gap_ms': 9000},
                                          {'name': 'resolve', 'opening_casts': [[804823, 'caster']]}])):
            with self.subTest(judge=broken['judge']), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, broken)


class CappedShareTests(unittest.TestCase):
    def verdict(self, expectation, absorbs: list[float], strike: float = 1100.0):
        values = {}
        for arm in expectation.model['arms']:
            totals = {'damage': 0.0, 'count': 0.0, 'absorb': 0.0, 'logs': 0.0}
            for mark, labels in arm['marks'].items():
                if mark != 'start':
                    absorbed = absorbs[int(mark) - 1] if arm['absorb'] == 'capped_share' else 0.0
                    totals = {'damage': totals['damage'] + strike - absorbed, 'count': totals['count'] + 1,
                              'absorb': totals['absorb'] + absorbed, 'logs': totals['logs'] + 1}
                for key, label in labels.items():
                    values[label] = totals[key]
        return compare_module.behaviour_taken_hit_verdict(base_verdict(expectation), FakeRun(values),
                                                          expectation.model)

    @NEEDS_DBC
    def test_seeded_cap_passes_and_an_uncapped_mutant_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, capped_entry())
        self.assertEqual(expectation.model['arms'][1]['cap'], 2000)
        self.assertEqual(self.verdict(expectation, [550, 550, 550, 350, 0, 0]).status, 'ok')
        self.assertEqual(self.verdict(expectation, [550] * 6).status, 'alert')
        self.assertEqual(self.verdict(expectation, [550, 550, 550, 550, 0, 0]).status, 'alert')

    @NEEDS_DBC
    def test_a_run_that_never_reaches_the_cap_or_starts_on_it_is_unmeasured(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, capped_entry(trials=3))
        self.assertEqual(self.verdict(expectation, [550, 550, 550]).status, 'unmeasured')
        arms = capped_entry()['arms']
        _, [expectation] = behaviour_scenario(CLASS_FILE, capped_entry(arms=[arms[0], {**arms[1], 'cap_pct': 10}],
                                                                       trials=3))
        self.assertEqual(self.verdict(expectation, [200, 0, 0]).status, 'unmeasured')
        self.assertEqual(self.verdict(expectation, [550, 0, 0]).status, 'alert')

    @NEEDS_DBC
    def test_a_cap_without_its_percent_or_with_two_strikes_is_refused(self):
        arms = capped_entry()['arms']
        for broken in ([arms[0], {**arms[1], 'cap_pct': 0}], [arms[0], {**arms[1], 'strikes': 2}],
                       [arms[0], {**arms[1], 'absorb': 'share'}]):
            with self.subTest(arm=broken[1]), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, capped_entry(arms=broken))


class CountsJudgeTests(unittest.TestCase):
    @NEEDS_DBC
    def test_seeded_reflection_passes_and_a_mutant_that_does_not_reflect_alerts(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, reflect_entry())
        self.assertEqual(expectation.model['kind'], 'taken_counts')
        good = {'control': [{'landed': 2}] * 4, 'treatment': [{'landed': 1, 'reflected': 1}] * 4}
        self.assertEqual(counts_verdict(expectation, good).status, 'ok')
        mutant = {'control': [{'landed': 2}] * 4, 'treatment': [{'landed': 2}] * 4}
        self.assertEqual(counts_verdict(expectation, mutant).status, 'alert')
        both = {'control': [{'landed': 2}] * 4, 'treatment': [{'reflected': 2}] * 4}
        self.assertEqual(counts_verdict(expectation, both).status, 'alert')

    @NEEDS_DBC
    def test_skipped_trials_below_the_threshold_are_unmeasured_never_ok(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, reflect_entry())
        self.assertEqual(expectation.model['minimum_trials'], 2)
        missed = {'control': [{'landed': 2}] * 4, 'treatment': [{'landed': 1, 'reflected': 1}] + [{}] * 3}
        verdict = counts_verdict(expectation, missed)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('below the 2 required', verdict.explanation)
        enough = {'control': [{'landed': 2}] * 4, 'treatment': [{'landed': 1, 'reflected': 1}] * 2 + [{}] * 2}
        self.assertEqual(counts_verdict(expectation, enough).status, 'ok')

    @NEEDS_DBC
    def test_rise_and_equality_are_strict(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, leech_entry())
        good = {'one': [{'hits': 1, 'blast': 200, 'leech': 200}] * 2,
                'three': [{'hits': 3, 'blast': 600, 'leech': 600}] * 2}
        self.assertEqual(counts_verdict(expectation, good).status, 'ok')
        flat = {'one': good['one'], 'three': [{'hits': 3, 'blast': 200, 'leech': 200}] * 2}
        self.assertEqual(counts_verdict(expectation, flat).status, 'alert')
        unequal = {'one': [{'hits': 1, 'blast': 200, 'leech': 199}] * 2, 'three': good['three']}
        self.assertEqual(counts_verdict(expectation, unequal).status, 'alert')

    @NEEDS_DBC
    def test_a_state_off_its_requirement_voids_the_trial(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, leech_entry())
        self.assertEqual(expectation.model['states'], ['pain'])
        voided = {'one': [{'hits': 1, 'blast': 200, 'leech': 200}] * 2,
                  'three': [{'hits': 3, 'blast': 600, 'leech': 600, 'pain': 1}] * 2}
        self.assertEqual(counts_verdict(expectation, voided).status, 'unmeasured')

    @NEEDS_DBC
    def test_state_reads_use_their_actor_and_stay_out_of_the_step_fields(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, leech_entry())
        pains = [step for step in run.validate(scenario)['steps'] if step.get('label', '').endswith(' pain')]
        self.assertTrue(pains and all(step['actor'] == 'striker' and 'state' not in step for step in pains))

    @NEEDS_DBC
    def test_a_band_holds_each_judged_trial_and_a_strikeless_arm_is_judged(self):
        arms = [{'name': 'zero', 'casts': [[804823, 'caster']], 'strikes': 0, 'counts': {'pain': 0},
                 'bands': {'blast': [61, 62]}},
                {'name': 'one', 'casts': [[804823, 'caster']], 'strikes': 1, 'counts': {'pain': 0},
                 'bands': {'blast': [62, 63]}}]
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, leech_entry(arms=arms, rising=[]))
        self.assertEqual(expectation.model['arms'][0]['bands'], {'blast': [61.0, 62.0]})
        self.assertEqual(expectation.model['arms'][0]['strikes'], 0)
        strikes = [step for step in scenario['steps'] if step.get('label', '').startswith('zero strike')]
        self.assertEqual(strikes, [])
        good = {'zero': [{'blast': 62, 'leech': 62}] * 2, 'one': [{'hits': 1, 'blast': 62, 'leech': 62}] * 2}
        self.assertEqual(counts_verdict(expectation, good).status, 'ok')
        outside = {'zero': good['zero'], 'one': [{'hits': 1, 'blast': 200, 'leech': 200}] * 2}
        verdict = counts_verdict(expectation, outside)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('must be 62 to 63', verdict.explanation)

    @NEEDS_DBC
    def test_a_band_without_the_counts_judge_reversed_or_on_an_exact_count_is_refused(self):
        for bands in ({'blast': [63, 62]}, {'pain': [0, 1]}, {'missing': [0, 1]}):
            arms = [{'name': 'one', 'casts': [[804823, 'caster']], 'strikes': 1, 'counts': {'pain': 0},
                     'bands': bands}]
            with self.subTest(bands=bands), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, leech_entry(arms=arms, rising=[]))
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, capped_entry(arms=[{'name': 'control', 'absorb': 'none', 'strikes': 0}]))

    @NEEDS_DBC
    def test_counts_without_reads_or_naming_an_unknown_read_is_refused(self):
        for broken in (reflect_entry(count_reads={}), reflect_entry(count_total=['missing']),
                       reflect_entry(rising=['missing']), reflect_entry(judge='absorb'),
                       leech_entry(count_total=['hits', 'pain'])):
            with self.subTest(broken=broken.get('count_total')), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, broken)


if __name__ == '__main__':
    unittest.main()
