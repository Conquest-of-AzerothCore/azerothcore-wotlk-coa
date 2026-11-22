from pathlib import Path
import sys
import unittest

from behaviours import COST_GATE_RESOURCES, NO_CAST_FAILURE, THREAT_SLOPE_WAIT_MS, behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_class_file
from test_behaviours import FakeRun, base_verdict

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

CLASS_FILE = load_class_file(27)
REFUSED = COST_GATE_RESOURCES['cooldown']


def entry_of(spell: int, variant: str) -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == spell and entry.get('variant') == variant)


def cd_gate_all_arms() -> dict:
    entry = entry_of(707528, 'cd_gate_without')
    return {**{key: value for key, value in entry.items() if key not in ('only_arm', 'priming_reads')},
            'variant': 'cd_gate', 'label_suffix': 'cd_gate'}


def results(expectations) -> dict:
    return {expectation.label.rsplit(' ', 1)[1]: expectation.displayed for expectation in expectations}


def judged(expectation, values: dict) -> str:
    return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation).status


def assert_labels(scenario) -> list[str]:
    return [step['label'] for step in scenario['steps'] if step['action'] == 'assert']


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RefusedWithTests(unittest.TestCase):
    def test_a_reset_expects_the_recast_accepted_by_default(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, entry_of(301266, 'reset_horusath'))
        self.assertEqual(results(expectations), {'without': str(REFUSED), 'with': str(NO_CAST_FAILURE)})
        self.assertFalse([label for label in assert_labels(scenario) if label.endswith('after_cast')])

    def test_refused_with_expects_the_with_arm_refused_and_the_after_cast_landed(self):
        entry = {**entry_of(301266, 'reset_horusath'), 'refused_with': True}
        _, expectations = behaviour_scenario(CLASS_FILE, entry)
        self.assertEqual(results(expectations),
                         {'without': str(REFUSED), 'with': str(REFUSED), 'after_cast': str(NO_CAST_FAILURE)})

    def test_the_after_cast_is_read_on_the_reset_spell_just_before_the_with_attempt(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, entry_of(301266, 'reset_horusath_sunset'))
        run.validate(scenario)
        steps = scenario['steps']
        read = next(index for index, step in enumerate(steps)
                    if step.get('label') == '301266 cost_gate 500154 reset_horusath_sunset with after_cast')
        self.assertEqual((steps[read]['metric'], steps[read]['spell']), ('cast_failure', 301266))
        concord = max(index for index, step in enumerate(steps[:read])
                      if step['action'] == 'cast' and step['spell'] == 301266)
        attempt = next(index for index, step in enumerate(steps[read:], read)
                       if step['action'] == 'cast' and step['spell'] == 500154)
        self.assertLess(concord, read)
        self.assertFalse([step for step in steps[read:attempt] if step['action'] == 'cast'])

    def test_seeded_refused_concord_alerts_the_after_cast_while_the_with_arm_reads_refused(self):
        _, expectations = behaviour_scenario(CLASS_FILE, entry_of(301266, 'reset_horusath_sunset'))
        by_arm = {expectation.label.rsplit(' ', 1)[1]: expectation for expectation in expectations}
        with_label, after_label = by_arm['with'].label, by_arm['after_cast'].label
        self.assertEqual(judged(by_arm['with'], {with_label: float(REFUSED)}), 'ok')
        self.assertEqual(judged(by_arm['after_cast'], {after_label: float(REFUSED)}), 'alert')
        self.assertEqual(judged(by_arm['after_cast'], {after_label: 172.0}), 'alert')
        self.assertEqual(judged(by_arm['after_cast'], {after_label: float(NO_CAST_FAILURE)}), 'ok')

    def test_refused_with_needs_a_reset(self):
        entry = {**entry_of(301266, 'reset_horusath'), 'refused_with': True, 'resets': False, 'after_casts': [],
                 'reduction': 2000}
        with self.assertRaisesRegex(ValueError, 'needs resets'):
            behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ExtraReadsTests(unittest.TestCase):
    READS = [{'metric': 'cooldown_ms', 'spell': 500154}, {'metric': 'global_cooldown_ms', 'spell': 500154},
             {'metric': 'knows_spell', 'spell': 502380}, {'metric': 'aura', 'spell': 500149}, {'metric': 'power'}]

    def scenario(self, **changes):
        return behaviour_scenario(CLASS_FILE, {**entry_of(301266, 'reset_horusath'), **changes})

    def extra_steps(self, scenario) -> list[dict]:
        return [step for step in scenario['steps'] if ' extra ' in step.get('label', '')]

    def test_off_by_default_the_scenario_has_no_extra_read(self):
        scenario, _ = self.scenario()
        self.assertEqual(self.extra_steps(scenario), [])

    def test_reads_follow_the_attempt_of_the_without_and_with_arms_only(self):
        scenario, expectations = self.scenario(extra_reads=self.READS)
        steps = scenario['steps']
        extras = self.extra_steps(scenario)
        self.assertEqual(len(extras), 2 * len(self.READS))
        self.assertEqual({step['label'].rsplit(' ', 1)[0].split(' ')[-1] for step in extras if step['metric'] == 'power'},
                         {'extra'})
        for step in extras:
            attempt = max(index for index, other in enumerate(steps[:steps.index(step)])
                          if other['action'] == 'assert' and other['metric'] == 'cast_failure')
            self.assertFalse([other for other in steps[attempt + 1:steps.index(step)]
                              if other['action'] in ('cast', 'wait')])
        self.assertEqual([step['metric'] for step in extras[:len(self.READS)]],
                         [read['metric'] for read in self.READS])
        self.assertEqual(next(step for step in extras if step['metric'] == 'power')['power'], 0)

    def test_the_reads_are_never_an_expectation_and_leave_the_judged_labels_unchanged(self):
        _, plain = self.scenario()
        _, extended = self.scenario(extra_reads=self.READS)
        self.assertEqual([(e.label, e.displayed) for e in plain], [(e.label, e.displayed) for e in extended])
        self.assertFalse([e for e in extended if ' extra ' in e.label])

    def test_a_read_placed_around_an_after_cast_brackets_that_cast_in_the_without_and_with_arms(self):
        reads = [{'metric': 'cooldown_ms', 'spell': 500154, 'at': 'before_cast', 'cast': 500143},
                 {'metric': 'cooldown_ms', 'spell': 500154, 'at': 'after_cast', 'cast': 500143}]
        scenario, _ = self.scenario(extra_reads=reads, after_casts=[[500143, 'caster']], after_wait_ms=1600,
                                    after_cast_gap_ms=2200)
        steps = scenario['steps']
        for arm in ('without', 'with'):
            before = next(i for i, step in enumerate(steps) if step.get('label', '').endswith(f'{arm} extra cooldown_ms 500154 before_cast 500143'))
            after = next(i for i, step in enumerate(steps) if step.get('label', '').endswith(f'{arm} extra cooldown_ms 500154 after_cast 500143'))
            casts = [i for i in range(before, after) if steps[i]['action'] == 'cast']
            self.assertEqual([steps[i]['spell'] for i in casts], [500143])
            self.assertEqual(steps[after - 1]['ms'], 2200)
        self.assertFalse([step for step in steps if step.get('label', '').startswith('301266 cost_gate 500154 reset_horusath beyond extra')])

    def test_a_placed_read_needs_a_cast_among_the_after_casts(self):
        read = {'metric': 'cooldown_ms', 'spell': 500154, 'at': 'after_cast', 'cast': 1}
        with self.assertRaisesRegex(ValueError, 'extra_reads'):
            self.scenario(extra_reads=[read])

    def test_an_unknown_metric_or_a_power_with_a_spell_is_refused(self):
        for read in ({'metric': 'cast_failure', 'spell': 500154}, {'metric': 'power', 'spell': 1},
                     {'metric': 'cooldown_ms'}):
            with self.assertRaisesRegex(ValueError, 'extra_reads'):
                self.scenario(extra_reads=[read])


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class OnlyArmTests(unittest.TestCase):
    def scenario(self, **changes):
        return behaviour_scenario(CLASS_FILE, {**cd_gate_all_arms(), **changes})

    def test_off_by_default_every_arm_shares_one_scenario(self):
        _, expectations = self.scenario()
        self.assertEqual([e.label.rsplit(' ', 1)[1] for e in expectations], ['without', 'with', 'beyond'])

    def test_one_arm_alone_has_its_own_scenario_name_and_label(self):
        plain, _ = self.scenario()
        for arm, result in (('without', 67), ('with', 0), ('beyond', 67), ('unfulfilled', 67)):
            scenario, expectations = self.scenario(only_arm=arm)
            self.assertEqual([e.label.rsplit(' ', 1)[1] for e in expectations], [arm])
            self.assertEqual([e.displayed for e in expectations], [str(result)])
            self.assertTrue(scenario['name'].endswith(f' {arm}'))
            self.assertNotEqual(scenario['name'], plain['name'])
            self.assertEqual(len([s for s in scenario['steps'] if s.get('metric') == 'cast_failure']), 1)

    def test_the_talent_is_learned_only_in_the_arms_that_have_it(self):
        learned = lambda arm: [s['spell'] for s in self.scenario(only_arm=arm)[0]['steps']
                               if s['action'] == 'learn' and s['spell'] == 707528]
        self.assertEqual(learned('without'), [])
        for arm in ('with', 'beyond', 'unfulfilled'):
            self.assertEqual(learned(arm), [707528])

    def test_the_beyond_attempt_is_earlier_than_the_with_attempt(self):
        waits = lambda arm: [s['ms'] for s in self.scenario(only_arm=arm)[0]['steps']
                             if s['action'] == 'wait' and s.get('label', '').endswith('cooldown wait')]
        self.assertGreater(waits('with')[0], waits('beyond')[0])

    def test_priming_reads_precede_the_priming_cast_and_are_judged_per_scenario(self):
        reads = [{'spell': 807440, 'expected': 1}, {'spell': 803719, 'expected': 1}]
        scenario, expectations = self.scenario(only_arm='with', priming_reads=reads)
        steps = scenario['steps']
        priming = [i for i, s in enumerate(steps) if ' priming ' in s.get('label', '')]
        self.assertEqual([steps[i]['spell'] for i in priming], [807440, 803719])
        cast = next(i for i in range(priming[-1], len(steps)) if steps[i]['action'] == 'cast')
        self.assertEqual(steps[cast]['spell'], 500154)
        self.assertEqual([e.displayed for e in expectations if ' priming ' in e.label], ['1', '1'])
        void = next(e for e in expectations if e.label.endswith('priming 807440'))
        self.assertEqual(judged(void, {void.label: 0.0}), 'alert')
        self.assertEqual(judged(void, {void.label: 1.0}), 'ok')

    def test_priming_reads_are_off_by_default(self):
        scenario, expectations = self.scenario(only_arm='with')
        self.assertFalse([s for s in scenario['steps'] if ' priming ' in s.get('label', '')])
        self.assertFalse([e for e in expectations if ' priming ' in e.label])

    def test_only_arm_refuses_an_unknown_arm_and_an_incompatible_gate(self):
        for changes in ({'only_arm': 'next'}, {'only_arm': 'with', 'next_arm': True},
                        {'only_arm': 'with', 'unset_arm': True}, {'only_arm': 'with', 'talent_aura': 123456}):
            with self.assertRaisesRegex(ValueError, 'only_arm'):
                self.scenario(**changes)

    def test_priming_reads_refuse_a_state_other_than_0_or_1(self):
        with self.assertRaisesRegex(ValueError, 'priming_reads'):
            self.scenario(only_arm='with', priming_reads=[{'spell': 807440, 'expected': 2}])


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PrimingArmExpectedTests(unittest.TestCase):
    def scenario(self, **changes):
        entry = entry_of(560861, 'dawnfall_gate')
        return behaviour_scenario(CLASS_FILE, {**entry, **changes})

    def priming(self, expectations) -> dict:
        return {e.model['arm']: e for e in expectations if ' priming ' in e.label}

    def test_the_unset_arm_expects_dawn_absent_and_the_others_present(self):
        _, expectations = self.scenario()
        arms = self.priming(expectations)
        self.assertEqual({arm: e.displayed for arm, e in arms.items()},
                         {'without': '1', 'with': '1', 'unset': '0', 'beyond': '1'})

    def arm_readings(self, expectations, arm: str) -> list:
        return [e for e in expectations if e.model.get('arm') == arm and 'priming_void' in e.model]

    def test_a_mutant_with_dawn_up_in_the_unset_arm_voids_every_reading_of_the_arm(self):
        _, expectations = self.scenario()
        unset = self.priming(expectations)['unset']
        self.assertEqual(judged(unset, {unset.label: 0.0}), 'ok')
        self.assertEqual(judged(unset, {unset.label: 1.0}), 'unmeasured')
        readings = [e for e in self.arm_readings(expectations, 'unset') if ' priming ' not in e.label]
        self.assertTrue(readings)
        for reading in readings:
            values = {unset.label: 1.0, reading.label: float(reading.displayed)}
            self.assertEqual(judged(reading, values), 'unmeasured', reading.label)
        with_arm = self.priming(expectations)['with']
        self.assertEqual(judged(with_arm, {with_arm.label: 1.0}), 'ok')
        self.assertEqual(judged(with_arm, {with_arm.label: 0.0}), 'unmeasured')

    def test_a_held_priming_state_leaves_the_gate_reading_judged(self):
        _, expectations = self.scenario()
        unset = self.priming(expectations)['unset']
        gate = next(e for e in self.arm_readings(expectations, 'unset') if ' priming ' not in e.label)
        self.assertEqual(judged(gate, {unset.label: 0.0, gate.label: float(gate.displayed)}), 'ok')
        self.assertEqual(judged(gate, {unset.label: 0.0, gate.label: float(gate.displayed) + 1}), 'alert')

    def test_without_arm_expected_every_arm_keeps_one_state(self):
        reads = [{'spell': 807440, 'expected': 1}]
        _, expectations = self.scenario(priming_reads=reads)
        self.assertEqual({e.displayed for e in self.priming(expectations).values()}, {'1'})
        self.assertFalse(any('priming_void' in e.model for e in expectations))

    def test_arm_expected_refuses_an_unknown_arm_or_a_state_other_than_0_or_1(self):
        for bad in ({'nowhere': 0}, {'unset': 2}, {'unset': True}, [0]):
            with self.assertRaisesRegex(ValueError, 'arm_expected'):
                self.scenario(priming_reads=[{'spell': 807440, 'expected': 1, 'arm_expected': bad}])


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ThreatSlopeFieldTests(unittest.TestCase):
    def sunflare(self, **changes) -> dict:
        entry = {**entry_of(504734, 'threat_slope_sunflare'), **changes}
        return {key: value for key, value in entry.items() if value is not None}

    def readings(self, model: dict, threat: float, lost: float, extra: dict | None = None) -> dict:
        return {model['cast_label']: float(NO_CAST_FAILURE), model['health_before_label']: 10000.0,
                model['health_after_label']: 10000.0 - lost, model['threat_label']: threat, **(extra or {})}

    def test_flat_adds_to_the_dbc_flat_of_the_model(self):
        _, (stated,) = behaviour_scenario(CLASS_FILE, self.sunflare())
        _, (bare,) = behaviour_scenario(CLASS_FILE, self.sunflare(flat=None))
        self.assertEqual(stated.model['flat'] - bare.model['flat'], 1.0)

    def test_seeded_flat_judges_the_slope_and_a_missing_cut_alerts(self):
        _, (expectation,) = behaviour_scenario(CLASS_FILE, self.sunflare())
        flat = expectation.model['flat']
        self.assertEqual(judged(expectation, self.readings(expectation.model, 0.8 * 26 + flat, 26)), 'ok')
        self.assertEqual(judged(expectation, self.readings(expectation.model, 1.0 * 26 + flat, 26)), 'alert')

    def test_learn_steps_follow_the_hit_spell_and_are_absent_without_learn(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, self.sunflare())
        learned = [step['spell'] for step in scenario['steps'] if step['action'] == 'learn']
        self.assertEqual(learned[-2:], [800231, 504734])
        scenario, _ = behaviour_scenario(CLASS_FILE, self.sunflare(learn=None))
        self.assertNotIn(504734, [step['spell'] for step in scenario['steps'] if step['action'] == 'learn'])

    def test_label_suffix_names_every_reading_and_the_expectation(self):
        scenario, (expectation,) = behaviour_scenario(CLASS_FILE, self.sunflare())
        self.assertEqual(expectation.label, '504734 behaviour_threat_slope 800231 talent')
        self.assertTrue(all(label.startswith('504734 threat_slope 800231 talent ')
                            for label in assert_labels(scenario) if 'threat_slope' in label))
        _, (plain,) = behaviour_scenario(CLASS_FILE, self.sunflare(label_suffix=None))
        self.assertEqual(plain.label, '504734 behaviour_threat_slope 800231')

    def test_settle_ms_lengthens_the_read_wait_and_defaults_to_none(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, entry_of(504734, 'threat_slope_sundown'))
        run.validate(scenario)
        waits = [step['ms'] for step in scenario['steps'] if step['action'] == 'wait' and 'label' not in step]
        self.assertEqual(waits[-1], 2000 + THREAT_SLOPE_WAIT_MS + 2500)
        scenario, _ = behaviour_scenario(CLASS_FILE, self.sunflare())
        waits = [step['ms'] for step in scenario['steps'] if step['action'] == 'wait' and 'label' not in step]
        self.assertEqual(waits[-1], 2000 + THREAT_SLOPE_WAIT_MS)

    def test_seeded_unlanded_flare_voids_the_trial(self):
        _, (expectation,) = behaviour_scenario(CLASS_FILE, entry_of(504734, 'threat_slope_sundown'))
        model = expectation.model
        (flare,) = model['unlanded_labels']
        self.assertEqual(flare, '504734 threat_slope 572752 talent 807175_damage_count after')
        right = 0.8 * 2000 + model['flat']
        self.assertEqual(judged(expectation, self.readings(model, right, 2000, {flare: 0.0})), 'ok')
        self.assertEqual(judged(expectation, self.readings(model, 2000 + model['flat'], 2000, {flare: 0.0})),
                         'alert')
        self.assertEqual(judged(expectation, self.readings(model, right, 2000, {flare: 1.0})), 'unmeasured')

    def test_unlanded_needs_a_settle_wait(self):
        entry = {**entry_of(504734, 'threat_slope_sundown')}
        del entry['settle_ms']
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)

    def test_the_sun_down_flat_is_the_three_spell_levels(self):
        for variant, expected in (('threat_slope_sundown', 0.8), ('threat_slope_sundown_control', 1.0)):
            _, (expectation,) = behaviour_scenario(CLASS_FILE, entry_of(504734, variant))
            self.assertEqual((expectation.model['flat'], expectation.model['expected']), (178.0, expected))


if __name__ == '__main__':
    unittest.main()
