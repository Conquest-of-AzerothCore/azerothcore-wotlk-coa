import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import READBACK, metric_evidence
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

SPELL = 527023
ALLY_SPELL = 572769
ALLY_SPELL_POWER = 3
ALLY_SPELL_COST = 20
ALLY_SPELL_CASTER_AURA = 681170
SLOW_SPELL = 500688
HEALTH_ARM = {'actors': ['ally'], 'metric': 'health', 'before_expected': 5000, 'expected': 5000, 'tolerance': 0,
              'source': 'the ally fixture health, no heal in the scenario'}
AURA_ARM = {'actors': ['ally', 'ally2'], 'metric': 'aura', 'fields': {'spell': SPELL}, 'before_expected': 0,
            'expected': 0, 'tolerance': 0, 'source': 'Divine Charge is a self aura, so no ally holds it'}


def templar():
    return load_fixture_class_file(19)


def steed_entry(**changes) -> dict:
    entry = next(entry for entry in templar()['behaviours']
                 if entry.get('spell') == SPELL and entry.get('variant') == 'steed_speed')
    return {**entry, **changes}


def parry_entry() -> dict:
    return next(entry for entry in templar()['behaviours'] if entry.get('spell') == 804912
                and entry.get('attack_swings'))


def ally_entry(**option) -> dict:
    return steed_entry(ally_arm={'allies': 2, 'arms': [HEALTH_ARM, AURA_ARM], **option})


def labels_of(scenario: dict) -> list:
    return [step.get('label') for step in scenario['steps']]


def honest(step: dict) -> float:
    return next(step[key] for key in ('equals', 'min', 'max') if key in step)


def ran_report(scenario: dict, actual=honest) -> dict:
    steps = scenario['steps']
    return {'schema': 1, 'run_id': 'r', 'scenario': scenario['name'], 'execution': 'socketless-session-handlers',
            'status': 'passed', 'assertions': sum(step['action'] == 'assert' for step in steps),
            'completed_steps': len(steps),
            'steps': [{'index': index, 'action': step['action'],
                       **({'status': 'passed', 'actual': actual(step)} if step['action'] == 'assert'
                          else {'status': 'completed'})} for index, step in enumerate(steps)]}


def waited(steps: list) -> int:
    return sum(step['ms'] for step in steps if step['action'] == 'wait')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AllyArmScenarioTests(unittest.TestCase):
    def scenario(self, entry: dict):
        return behaviour_scenario(templar(), entry)

    def test_the_allies_are_grouped_players_and_the_arm_reads_follow_each_main_read(self):
        scenario, [expectation] = self.scenario(ally_entry())
        run.validate(scenario)
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', 'ally', 'ally2'])
        groups = [step['target'] for step in scenario['steps'] if step['action'] == 'group']
        self.assertEqual(groups, ['ally', 'ally2'])
        labels = labels_of(scenario)
        model = expectation.model['ally_arm']
        for moment in ('before', 'after'):
            read = labels.index(expectation.model[f'{moment}_label'])
            arm_labels = [label for arm in model['arms'] for label in arm[moment]]
            self.assertEqual(labels[read + 1:read + 1 + len(arm_labels)], arm_labels)
        reads = [step for step in scenario['steps'] if step.get('label') in model['arms'][1]['after']]
        self.assertEqual([(step['actor'], step['metric'], step['spell']) for step in reads],
                         [('ally', 'aura', SPELL), ('ally2', 'aura', SPELL)])

    def test_without_the_option_the_scenario_is_unchanged(self):
        scenario, [expectation] = self.scenario(steed_entry())
        plain, [plain_expectation] = self.scenario({**steed_entry(), 'ally_arm': None})
        self.assertEqual(scenario, plain)
        self.assertEqual(expectation, plain_expectation)
        self.assertNotIn('ally_arm', expectation.model)
        self.assertEqual([player['id'] for player in scenario['players']], ['caster'])

    def test_an_ally_becomes_a_measured_unit_and_a_cast_target(self):
        scenario, [expectation] = self.scenario(steed_entry(measure_actor='ally', ally_arm={'allies': 1}))
        run.validate(scenario)
        before = scenario['steps'][labels_of(scenario).index(expectation.model['before_label'])]
        self.assertEqual(before['actor'], 'ally')
        self.assertEqual(expectation.model['ally_arm'], {'allies': ['ally'], 'arms': []})

    def test_the_timed_control_waits_the_after_wait_before_the_uncast_read(self):
        entry = ally_entry(control_wait=True)
        scenario, [expectation] = self.scenario(entry)
        run.validate(scenario)
        labels = labels_of(scenario)
        timed = labels.index('timed no-cast control')
        self.assertEqual(labels.count('timed no-cast control'), 1)
        self.assertEqual(scenario['steps'][timed]['ms'], entry['wait_ms'])
        self.assertLess(timed, labels.index(expectation.model['before_label']))
        self.assertFalse(any(step['action'] == 'cast' and step['spell'] == SPELL
                             for step in scenario['steps'][:timed]))

    def test_the_ally_casts_and_health_come_in_both_phases_ahead_of_the_trigger(self):
        scenario, [expectation] = self.scenario({**ally_entry(ally_casts=[ALLY_SPELL], ally_health=[5000, 10000]),
                                                 'learn': [ALLY_SPELL]})
        run.validate(scenario)
        steps = scenario['steps']
        ally_casts = [index for index, step in enumerate(steps)
                      if step['action'] == 'cast' and step.get('target') == 'ally']
        healths = [index for index, step in enumerate(steps) if step['action'] == 'set_health'
                   and step['actor'] in ('ally', 'ally2') and (step['value'], step['maximum']) == (5000, 10000)]
        before = labels_of(scenario).index(expectation.model['before_label'])
        trigger = next(index for index, step in enumerate(steps)
                       if step['action'] == 'cast' and step.get('target') == 'caster' and step['spell'] == SPELL)
        self.assertEqual(len(ally_casts), 2)
        self.assertEqual(len(healths), 4)
        self.assertLess(ally_casts[0], before)
        self.assertLess(before, ally_casts[1])
        self.assertLess(ally_casts[1], trigger)
        self.assertLess(max(healths), trigger)

    def test_a_malformed_option_or_an_arm_without_its_stated_expectation_is_refused(self):
        readback = next(metric for metric, kind in metric_evidence().items() if kind == READBACK)
        options = [True, {}, {'allies': 0}, {'allies': 6}, {'control_wait': False}, {'ally_health': [0, 10]},
                   {'ally_health': [11, 10]}, {'ally_casts': ['x']}, {'surplus': 1}]
        options += [{'arms': [{key: value for key, value in HEALTH_ARM.items() if key != missing}]}
                    for missing in ('actors', 'metric', 'before_expected', 'expected', 'tolerance', 'source')]
        options += [{'arms': [{**HEALTH_ARM, **change}]} for change in (
            {'source': ' '}, {'tolerance': -1}, {'tolerance': float('inf')}, {'expected': float('nan')},
            {'expected': '5000'}, {'actors': []}, {'actors': ['ally', 'ally']},
            {'actors': ['ally3']}, {'actors': ['dummy']}, {'metric': readback}, {'metric': 'no_such_metric'})]
        for option in options:
            with self.subTest(option=option), self.assertRaises(ValueError):
                self.scenario(steed_entry(ally_arm=option))

    def test_the_timed_control_needs_an_uncast_before_phase(self):
        for changes in ({'cast_in_before': True}, {'gate_timing': 'start'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.scenario(steed_entry(ally_arm={'control_wait': True}, **changes))

    def test_an_ally_cast_is_prepared_and_asserted_landed_in_each_phase(self):
        entry = {**ally_entry(ally_casts=[ALLY_SPELL, ALLY_SPELL]), 'learn': [ALLY_SPELL]}
        scenario, _ = self.scenario(entry)
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps)
                 if step['action'] == 'cast' and step.get('target') == 'ally']
        self.assertEqual(len(casts), 4)
        for cast in casts:
            self.assertIn({'action': 'set_power', 'actor': 'caster', 'power': ALLY_SPELL_POWER,
                           'value': ALLY_SPELL_COST},
                          steps[cast - 4:cast])
            self.assertIn({'action': 'set_aura', 'actor': 'caster', 'spell': ALLY_SPELL_CASTER_AURA, 'stacks': 1},
                          steps[cast - 4:cast])
            proof = steps[cast + 2]
            self.assertEqual((proof['action'], proof['actor'], proof['metric'], proof['spell']),
                             ('assert', 'caster', 'spell_go_count', ALLY_SPELL))
        self.assertEqual([steps[cast + 2]['equals'] for cast in casts], [1, 2, 3, 4])
        self.assertIn('asserts the caster\'s spell_go_count', scenario['contract'])
        run.check_report(ran_report(scenario), 'r', scenario, 0)

    def test_mutant_an_ally_cast_that_did_not_go_off_fails_the_scenario(self):
        scenario, _ = self.scenario({**ally_entry(ally_casts=[ALLY_SPELL]), 'learn': [ALLY_SPELL]})
        failed = ran_report(scenario, lambda step: 0 if step['metric'] == 'spell_go_count' else honest(step))
        with self.assertRaisesRegex(ValueError, 'Equality assertion failed'):
            run.check_report(failed, 'r', scenario, 0)

    def test_an_ally_cast_the_scenario_cannot_prove_is_refused(self):
        entries = [ally_entry(ally_casts=[ALLY_SPELL]),
                   {**ally_entry(ally_casts=[SPELL]), 'learn': [SPELL]},
                   {**ally_entry(ally_casts=[ALLY_SPELL]), 'learn': [ALLY_SPELL], 'setup_casts': [ALLY_SPELL]},
                   {**ally_entry(ally_casts=[SLOW_SPELL]), 'learn': [SLOW_SPELL]},
                   {**parry_entry(), 'ally_arm': {'ally_casts': [ALLY_SPELL]}, 'learn': [ALLY_SPELL]}]
        for entry in entries:
            with self.subTest(entry=entry), self.assertRaisesRegex(ValueError, 'ally_arm'):
                self.scenario(entry)

    def test_a_caster_scoped_total_read_on_an_ally_is_refused(self):
        heal = {'actors': ['ally'], 'metric': 'spell_heal_total', 'fields': {'spell': SPELL}, 'before_expected': 0,
                'expected': 0, 'tolerance': 0, 'source': 'a heal the caster gives the ally'}
        refused = [steed_entry(ally_arm={'arms': [heal]}),
                   steed_entry(ally_arm={'arms': [{**heal, 'metric': 'spell_energize_total',
                                                   'fields': {'spell': SPELL, 'caster_entry': 1}}]}),
                   steed_entry(ally_arm={'allies': 2, 'arms': [
                       {**heal, 'actors': ['caster', 'ally2'], 'metric': 'spell_heal_count'}]}),
                   steed_entry(measure_actor='ally', metric='spell_effective_heal_total', fields={'spell': SPELL},
                               ally_arm={'allies': 1})]
        refused += [steed_entry(ally_arm={'arms': [{**heal, 'metric': metric}]})
                    for metric in ('spell_damage_total', 'spell_log_count', 'spell_go_count', 'spell_proc_count')]
        for entry in refused:
            with self.subTest(entry=entry), self.assertRaisesRegex(ValueError, 'never the caster'):
                self.scenario(entry)
        for arm in ({**heal, 'actors': ['caster'], 'fields': {'spell': SPELL, 'target': 'ally'}},
                    {**heal, 'fields': {'spell': SPELL, 'caster_entry': 1}}):
            with self.subTest(arm=arm):
                scenario, _ = self.scenario(steed_entry(ally_arm={'arms': [arm]}))
                run.validate(scenario)

    def test_the_timed_control_reads_at_the_treatment_interval(self):
        scenario, [expectation] = self.scenario({**ally_entry(control_wait=True, ally_casts=[ALLY_SPELL]),
                                                 'learn': [ALLY_SPELL]})
        steps = scenario['steps']
        labels = labels_of(scenario)
        before = labels.index(expectation.model['before_label'])
        after = labels.index(expectation.model['after_label'])
        trigger = next(index for index in range(before, after)
                       if steps[index]['action'] == 'cast' and steps[index]['spell'] == SPELL)
        ally_end = max(index for index in range(before, trigger) if steps[index]['action'] == 'assert')
        self.assertEqual(waited(steps[labels.index('timed no-cast control'):before]), waited(steps[ally_end:after]))

    def test_the_timed_control_refuses_every_after_phase_only_wait(self):
        refused = [{'setup_casts': [300514], 'setup_wait_ms': 1000},
                   {'target': 'dummy', 'target_casts': [300514]},
                   {'enemy_player_race': 2, 'fields': {'target': 'enemy'}, 'enemy_casts': [300514]},
                   {'enemy_player_race': 2, 'fields': {'target': 'enemy'}, 'helper_casts': [300514]},
                   {'relocate_during_wait': {'every_ms': 200, 'count': 2, 'dy': 1}}]
        for changes in refused:
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, 'control_wait reads the uncast'):
                self.scenario(steed_entry(ally_arm={'control_wait': True}, **changes))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AllyArmVerdictTests(unittest.TestCase):
    def judged(self, entry: dict, arm_values: dict, main=(1.0, 2.0)):
        _, [expectation] = behaviour_scenario(templar(), entry)
        values = {expectation.model['before_label']: main[0], expectation.model['after_label']: main[1]}
        for index, arm in enumerate(expectation.model.get('ally_arm', {}).get('arms', [])):
            for moment in ('before', 'after'):
                for label in arm[moment]:
                    if (index, moment) in arm_values:
                        values[label] = arm_values[(index, moment)] / len(arm[moment])
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def held(self) -> dict:
        return {(0, 'before'): 5000, (0, 'after'): 5000, (1, 'before'): 0, (1, 'after'): 0}

    def test_arms_held_keep_the_main_status(self):
        self.assertEqual(self.judged(ally_entry(), self.held()).status, 'ok')
        self.assertEqual(self.judged(ally_entry(), self.held(), main=(1.0, 1.0)).status, 'alert')

    def test_mutant_an_ally_read_off_its_expectation_alerts(self):
        mutant = {**self.held(), (1, 'after'): 1}
        verdict = self.judged(ally_entry(), mutant)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('ally arm 1 aura: 0 before (expected 0) and 1 after (expected 0), within 0: off',
                      verdict.explanation)

    def test_a_missing_arm_read_leaves_the_verdict_unmeasured(self):
        values = {key: value for key, value in self.held().items() if key != (0, 'after')}
        self.assertEqual(self.judged(ally_entry(), values).status, 'unmeasured')
        self.assertEqual(self.judged(ally_entry(), values, main=(1.0, 1.0)).status, 'alert')

    def test_without_arms_the_verdict_is_the_plain_one(self):
        plain = self.judged(steed_entry(), {})
        armless = self.judged(steed_entry(ally_arm={'allies': 1}), {})
        self.assertEqual((armless.status, armless.measured, armless.expected, armless.explanation),
                         (plain.status, plain.measured, plain.expected, plain.explanation))


if __name__ == '__main__':
    unittest.main()
