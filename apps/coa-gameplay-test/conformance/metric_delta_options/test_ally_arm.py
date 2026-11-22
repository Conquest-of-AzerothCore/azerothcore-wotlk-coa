from dataclasses import replace
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import READBACK, UNPROVEN, metric_evidence
from metric_delta_options.ally_arm import parse
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict
from test_coverage import BUILD, claim, evidence_of

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
TWICE = {'spell': ALLY_SPELL, 'spell_go_per_cast': 2, 'source': 'a seeded script line that recasts it on the caster'}
COPY_ARM = {'actors': ['ally'], 'metric': 'health', 'before_expected': 5000, 'expected': 5750, 'tolerance': 1000,
            'source': 'a seeded copy heal'}
PRIMARY_ARM = {'actors': ['ally2'], 'metric': 'health', 'before_expected': 5000, 'expected': 6000, 'tolerance': 1000,
               'source': 'a seeded primary heal'}
REACH = 'a seeded Allies() filter by IsInRaidWith'
RATIO = {'numerator': 0, 'denominator': 1, 'expected': 0.75, 'tolerance': 0.01, 'source': 'a seeded 75% copy'}
ENERGIZE_ARM = {'actors': ['caster'], 'metric': 'spell_energize_total', 'count_metric': 'spell_energize_count',
                'fields': {'spell': SPELL}, 'source': 'a seeded 5% mana return per strike'}
DAMAGE_ARM = {'actors': ['caster'], 'metric': 'spell_damage_total', 'count_metric': 'spell_damage_count',
              'fields': {'spell': SPELL, 'target': 'dummy'}, 'source': 'a seeded strike'}
COUNT_ARM = {'actors': ['caster'], 'metric': 'spell_energize_count', 'fields': {'spell': SPELL}, 'before_expected': 0,
             'expected': 4, 'tolerance': 0, 'source': 'a seeded four strikes'}
FLOOR_RATIO = {'numerator': 0, 'denominator': 1, 'expected': 0.05, 'tolerance': 0.001, 'floor_count': 2,
               'source': 'a seeded floor(5% of each strike)'}


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


def ratio_entry(**ratio) -> dict:
    return steed_entry(ally_arm={'allies': 2, 'arms': [COPY_ARM, PRIMARY_ARM], 'ratios': [{**RATIO, **ratio}]})


STRIKE_ARM = {'actors': ['caster'], 'metric': 'spell_damage_total', 'count_metric': 'spell_damage_count',
              'fields': {'spell': ALLY_SPELL, 'target': 'dummy'}, 'source': 'a seeded second strike'}
SUMMED_RATIO = {'numerator': 0, 'denominator': [1, 2], 'expected': 0.05, 'tolerance': 0.001, 'floor_count': 0,
                'source': 'a seeded floor(5% of each of two strikes)'}


def summed_ratio_entry(**ratio) -> dict:
    return steed_entry(ally_arm={'allies': 0, 'arms': [ENERGIZE_ARM, DAMAGE_ARM, STRIKE_ARM],
                                 'ratios': [{**SUMMED_RATIO, **ratio}]})


def caster_ratio_entry(**ratio) -> dict:
    return steed_entry(ally_arm={'allies': 0, 'arms': [ENERGIZE_ARM, DAMAGE_ARM, COUNT_ARM],
                                 'ratios': [{**FLOOR_RATIO, **ratio}]})


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
        options = [True, {}, {'allies': 0}, {'allies': 8}, {'control_wait': False}, {'ally_health': [0, 10]},
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

    def test_seven_allies_are_grouped_players(self):
        scenario, [expectation] = self.scenario(steed_entry(
            ally_arm={'allies': 7, 'arms': [{**HEALTH_ARM, 'actors': ['ally6', 'ally7'], 'reach_source': REACH}]}))
        run.validate(scenario)
        allies = ['ally', 'ally2', 'ally3', 'ally4', 'ally5', 'ally6', 'ally7']
        self.assertEqual([player['id'] for player in scenario['players']], ['caster', *allies])
        self.assertEqual([step['target'] for step in scenario['steps'] if step['action'] == 'group'], allies)
        self.assertEqual(expectation.model['ally_arm']['allies'], allies)

    def test_a_read_in_raid_subgroup_two_without_its_reach_source_is_refused(self):
        heal = {'actors': ['caster'], 'metric': 'spell_heal_total', 'fields': {'spell': SPELL, 'target': 'ally5'},
                'before_expected': 0, 'expected': 0, 'tolerance': 0, 'source': 'a seeded cap of four allies'}
        refused = [steed_entry(ally_arm={'allies': 5, 'arms': [{**HEALTH_ARM, 'actors': ['ally', 'ally5']}]}),
                   steed_entry(ally_arm={'allies': 7, 'arms': [heal]}),
                   steed_entry(measure_actor='ally7', ally_arm={'allies': 7}),
                   steed_entry(fields={'target': 'ally6'}, ally_arm={'allies': 7}),
                   steed_entry(target='ally5', ally_arm={'allies': 5})]
        for entry in refused:
            with self.subTest(entry=entry), self.assertRaisesRegex(ValueError, 'raid subgroup 2, outside'):
                self.scenario(entry)
        for option in ({'allies': 4, 'reach_source': REACH}, {'arms': [{**HEALTH_ARM, 'reach_source': REACH}]},
                       {'allies': 5, 'reach_source': ' '},
                       {'allies': 5, 'arms': [{**HEALTH_ARM, 'actors': ['ally5'], 'reach_source': ''}]}):
            with self.subTest(option=option), self.assertRaisesRegex(ValueError, 'reach_source'):
                self.scenario(steed_entry(ally_arm=option))

    def test_a_read_in_raid_subgroup_two_with_its_reach_source_is_accepted(self):
        heal = {'actors': ['caster'], 'metric': 'spell_heal_total', 'fields': {'spell': SPELL, 'target': 'ally5'},
                'before_expected': 0, 'expected': 0, 'tolerance': 0, 'source': 'a seeded cap', 'reach_source': REACH}
        scenario, [expectation] = self.scenario(steed_entry(measure_actor='ally7', ally_arm={
            'allies': 7, 'reach_source': 'the main seeded reach', 'arms': [HEALTH_ARM, heal]}))
        run.validate(scenario)
        self.assertIn('The main reading reaches raid subgroup 2 (the main seeded reach).', scenario['contract'])
        self.assertIn(f'Arm 1 reaches raid subgroup 2 ({REACH}).', scenario['contract'])
        self.assertNotIn('Arm 0 reaches', scenario['contract'])
        self.assertNotIn('reach_source', expectation.model['ally_arm']['arms'][1])

    def test_mutant_a_party_scoped_zero_on_an_unstated_subgroup_two_ally_is_refused(self):
        zero = {'actors': ['ally4', 'ally5'], 'metric': 'aura', 'fields': {'spell': SPELL}, 'before_expected': 0,
                'expected': 0, 'tolerance': 0, 'source': 'a seeded "does not affect" clause'}
        scenario, _ = self.scenario(steed_entry(ally_arm={'allies': 5, 'arms': [{**zero, 'actors': ['ally4']}]}))
        run.validate(scenario)
        with self.assertRaisesRegex(ValueError, r"arm 0 reads \['ally5'\] in raid subgroup 2"):
            self.scenario(steed_entry(ally_arm={'allies': 5, 'arms': [zero]}))

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

    def test_a_stated_spell_go_count_per_cast_scales_the_landed_proof(self):
        scenario, _ = self.scenario({**ally_entry(ally_casts=[TWICE, TWICE]), 'learn': [ALLY_SPELL]})
        run.validate(scenario)
        steps = scenario['steps']
        proofs = [step['equals'] for step in steps if step['action'] == 'assert'
                  and step.get('metric') == 'spell_go_count' and step.get('spell') == ALLY_SPELL]
        self.assertEqual(proofs, [2, 4, 6, 8])
        self.assertIn(f'Each {ALLY_SPELL} cast at ally counts 2 SPELL_GO ({TWICE["source"]}).', scenario['contract'])
        run.check_report(ran_report(scenario), 'r', scenario, 0)

    def test_a_stated_spell_go_count_stays_with_its_own_spell(self):
        ally = parse({'ally_casts': [TWICE, SLOW_SPELL]})
        self.assertEqual((ally.spell_go_per_cast(ALLY_SPELL), ally.spell_go_per_cast(SLOW_SPELL)), (2, 1))

    def test_mutant_a_wrong_spell_go_count_fails_the_scenario(self):
        stated, _ = self.scenario({**ally_entry(ally_casts=[TWICE]), 'learn': [ALLY_SPELL]})
        plain, _ = self.scenario({**ally_entry(ally_casts=[ALLY_SPELL]), 'learn': [ALLY_SPELL]})
        for scenario, wrong in ((stated, lambda step: step['equals'] // 2), (plain, lambda step: step['equals'] * 2),
                                (stated, lambda step: 0)):
            failed = ran_report(scenario, lambda step: wrong(step) if step.get('metric') == 'spell_go_count'
                                else honest(step))
            with self.subTest(contract=scenario['contract'][-80:]), \
                    self.assertRaisesRegex(ValueError, 'Equality assertion failed'):
                run.check_report(failed, 'r', scenario, 0)

    def test_a_spell_go_count_without_its_stated_source_is_refused(self):
        casts = [[{**TWICE, 'spell_go_per_cast': count}] for count in (1, 0, -2, 2.0, '2', True)]
        casts += [[{**TWICE, 'source': source}] for source in ('', '  ', 7)]
        casts += [[{key: value for key, value in TWICE.items() if key != missing}] for missing in TWICE]
        casts += [[{**TWICE, 'surplus': 1}], [TWICE, ALLY_SPELL], [TWICE, {**TWICE, 'spell_go_per_cast': 3}],
                  [TWICE, {**TWICE, 'source': 'another line'}], [{**TWICE, 'spell': 0}]]
        for cast in casts:
            with self.subTest(cast=cast), self.assertRaisesRegex(ValueError, 'ally_arm'):
                self.scenario({**ally_entry(ally_casts=cast), 'learn': [ALLY_SPELL]})

    def test_a_ratio_names_two_arms_and_states_its_expectation(self):
        scenario, [expectation] = self.scenario(ratio_entry())
        run.validate(scenario)
        self.assertEqual(expectation.model['ally_arm']['ratios'], [{**RATIO, 'expected': 0.75, 'tolerance': 0.01}])
        self.assertIn('Ratio: arm 0 over arm 1', scenario['contract'])
        self.assertNotIn('ratios', self.scenario(ally_entry())[1][0].model['ally_arm'])
        refused = [{'numerator': 1}, {'numerator': 2}, {'denominator': -1}, {'denominator': True}, {'expected': 0},
                   {'expected': -0.75}, {'expected': float('inf')}, {'tolerance': -0.1}, {'tolerance': '0'},
                   {'source': ' '}, {'surplus': 1}]
        for change in refused:
            with self.subTest(change=change), self.assertRaisesRegex(ValueError, 'ally_arm'):
                self.scenario(ratio_entry(**change))
        for option in ({'arms': [COPY_ARM], 'ratios': [RATIO]}, {'arms': [COPY_ARM, PRIMARY_ARM], 'ratios': []},
                       {'arms': [COPY_ARM, PRIMARY_ARM], 'ratios': RATIO},
                       {'arms': [COPY_ARM, PRIMARY_ARM],
                        'ratios': [{key: value for key, value in RATIO.items() if key != 'source'}]}):
            with self.subTest(option=option), self.assertRaisesRegex(ValueError, 'ally_arm'):
                self.scenario(steed_entry(ally_arm={'allies': 2, **option}))

    def test_allies_zero_reads_caster_arms_with_no_ally_player_or_group_step(self):
        scenario, [expectation] = self.scenario(caster_ratio_entry())
        run.validate(scenario)
        self.assertEqual([player['id'] for player in scenario['players']], ['caster'])
        self.assertNotIn('group', [step['action'] for step in scenario['steps']])
        arms = expectation.model['ally_arm']['arms']
        self.assertEqual(arms[0]['count_after'], [f'{arms[0]["after"][0]} count'])
        self.assertNotIn('expected', arms[0])
        self.assertEqual(expectation.model['ally_arm']['ratios'][0]['floor_count'], 2)
        self.assertIn(arms[0]['count_after'][0], labels_of(scenario))
        self.assertIn('judged only through its ratio', scenario['contract'])
        self.assertIn('one unit per counted event', scenario['contract'])

    def test_allies_zero_without_caster_arms_and_a_bad_floor_count_are_refused(self):
        refused = [steed_entry(ally_arm={'allies': 0}),
                   steed_entry(ally_arm={'allies': 0, 'arms': [HEALTH_ARM], 'ally_health': [1, 2]}),
                   steed_entry(ally_arm={'allies': -1, 'arms': [HEALTH_ARM]}),
                   steed_entry(ally_arm={'allies': 0, 'arms': [ENERGIZE_ARM, DAMAGE_ARM]}),
                   steed_entry(ally_arm={'allies': 0, 'arms': [{**ENERGIZE_ARM, 'count_metric': 'no_such_metric'},
                                                               DAMAGE_ARM], 'ratios': [RATIO]}),
                   steed_entry(ally_arm={'allies': 0, 'arms': [{**ENERGIZE_ARM, 'expected': 1}, DAMAGE_ARM],
                                         'ratios': [RATIO]}),
                   caster_ratio_entry(floor_count=3), summed_ratio_entry(denominator=[1]),
                   summed_ratio_entry(denominator=[0, 1]), summed_ratio_entry(denominator=[1, 1]),
                   summed_ratio_entry(denominator=[1, 3]),
                   steed_entry(ally_arm={'allies': 0, 'arms': [ENERGIZE_ARM, DAMAGE_ARM, COUNT_ARM],
                                         'ratios': [{**SUMMED_RATIO, 'denominator': [1, 2]}]}),
                   steed_entry(ally_arm={'allies': 2, 'arms': [COPY_ARM, PRIMARY_ARM],
                                         'ratios': [{**RATIO, 'floor_count': 0, 'tolerance': 0.05}]}),
                   caster_ratio_entry(floor_count=True), caster_ratio_entry(tolerance=0.005)]
        for entry in refused:
            with self.subTest(entry=entry['ally_arm']), self.assertRaisesRegex(ValueError, 'ally_arm'):
                self.scenario(entry)

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

    def ratio_values(self, copy_after=5750, primary_after=6000) -> dict:
        return {(0, 'before'): 5000, (0, 'after'): copy_after, (1, 'before'): 5000, (1, 'after'): primary_after}

    def test_a_held_ratio_keeps_the_main_status(self):
        verdict = self.judged(ratio_entry(), self.ratio_values())
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('ally ratio arm 0 / arm 1: 750 / 1000 = 0.75 (expected 0.75 within 0.01): ok',
                      verdict.explanation)

    def test_a_held_ratio_keeps_a_failing_main_verdict(self):
        verdict = self.judged(ratio_entry(), self.ratio_values(), main=(1.0, 1.0))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('= 0.75 (expected 0.75 within 0.01): ok', verdict.explanation)

    def test_mutant_a_ratio_off_alerts_while_both_arms_hold(self):
        verdict = self.judged(ratio_entry(), self.ratio_values(copy_after=6000))
        self.assertEqual(verdict.status, 'alert')
        self.assertNotIn(': off (a seeded copy heal)', verdict.explanation)
        self.assertIn('= 1 (expected 0.75 within 0.01): off', verdict.explanation)

    def test_a_denominator_arm_that_did_not_move_is_off(self):
        verdict = self.judged(ratio_entry(), self.ratio_values(copy_after=5000, primary_after=5000))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('none, the denominator arm did not move', verdict.explanation)

    def floor_values(self, energize=200, damage=4000, strikes=4, landed=(4, 4)) -> dict:
        return {'values': {(0, 'before'): 0, (0, 'after'): energize, (1, 'before'): 0, (1, 'after'): damage,
                           (2, 'before'): 0, (2, 'after'): strikes},
                'counts': {0: landed[0], 1: landed[1]}}

    def judged_counted(self, entry: dict, readings: dict, main=(1.0, 2.0)):
        _, [expectation] = behaviour_scenario(templar(), entry)
        values = {expectation.model['before_label']: main[0], expectation.model['after_label']: main[1]}
        for index, arm in enumerate(expectation.model['ally_arm']['arms']):
            for moment in ('before', 'after'):
                for label in arm[moment]:
                    values[label] = readings['values'][(index, moment)]
            if 'count_metric' in arm:
                values[arm['count_before'][0]] = 0
                values[arm['count_after'][0]] = readings['counts'][index]
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_floor_count_widens_only_the_low_end_by_one_unit_per_event(self):
        exact = self.judged_counted(caster_ratio_entry(), self.floor_values())
        self.assertEqual(exact.status, 'ok')
        self.assertIn('0.048 to 0.051, the low end widened by 0.001', exact.explanation)
        truncated = self.judged_counted(caster_ratio_entry(), self.floor_values(energize=196))
        self.assertEqual(truncated.status, 'ok')
        self.assertEqual(self.judged_counted(caster_ratio_entry(), self.floor_values(energize=205)).status, 'alert')

    def test_mutant_a_ratio_ten_percent_low_or_high_still_alerts_with_the_widening(self):
        for energize in (180, 220):
            with self.subTest(energize=energize):
                verdict = self.judged_counted(caster_ratio_entry(), self.floor_values(energize=energize))
                self.assertEqual(verdict.status, 'alert')

    def test_a_widening_that_reaches_ten_percent_below_is_unmeasured(self):
        verdict = self.judged_counted(caster_ratio_entry(), self.floor_values(energize=20, damage=400, strikes=4))
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('no longer excluding 10% below 0.05', verdict.explanation)

    def test_a_ratio_only_arm_without_landed_events_is_unmeasured(self):
        for landed in ((0, 4), (4, 0)):
            with self.subTest(landed=landed):
                verdict = self.judged_counted(caster_ratio_entry(), self.floor_values(landed=landed))
                self.assertEqual(verdict.status, 'unmeasured')
                self.assertIn('no event of ratio-only arm(s)', verdict.explanation)
        unmoved = self.judged_counted(caster_ratio_entry(), self.floor_values(energize=0, damage=0))
        self.assertEqual(unmoved.status, 'unmeasured')

    def summed_values(self, energize=200, first=2000, second=2000, landed=(4, 2, 2)) -> dict:
        return {'values': {(0, 'before'): 0, (0, 'after'): energize, (1, 'before'): 0, (1, 'after'): first,
                           (2, 'before'): 0, (2, 'after'): second},
                'counts': dict(enumerate(landed))}

    def test_a_denominator_list_sums_its_arms_and_widens_by_the_numerator_count(self):
        verdict = self.judged_counted(summed_ratio_entry(), self.summed_values())
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('200 / 4000 = 0.05', verdict.explanation)
        self.assertIn('the low end widened by 0.001', verdict.explanation)
        self.assertEqual(self.judged_counted(summed_ratio_entry(), self.summed_values(energize=100)).status, 'alert')
        single = self.judged_counted(caster_ratio_entry(), self.floor_values())
        self.assertIn('200 / 4000 = 0.05', single.explanation)

    def test_a_denominator_list_with_an_arm_whose_events_did_not_land_is_unmeasured(self):
        for landed in ((4, 0, 2), (4, 2, 0)):
            with self.subTest(landed=landed):
                verdict = self.judged_counted(summed_ratio_entry(), self.summed_values(landed=landed))
                self.assertEqual(verdict.status, 'unmeasured')

    def test_an_unmeasured_ratio_never_counts_as_behaviour_in_coverage(self):
        ok = self.judged_counted(caster_ratio_entry(), self.floor_values())
        unmeasured = self.judged_counted(caster_ratio_entry(), self.floor_values(landed=(0, 4)))
        clauses = [claim('regenerate mana equal to 5% of the damage dealt', ok.label, spell=SPELL)]
        self.assertEqual((ok.status, unmeasured.status), ('ok', 'unmeasured'))
        self.assertNotEqual(evidence_of(clauses, [replace(ok, build=BUILD)])[0], [UNPROVEN])
        self.assertEqual(evidence_of(clauses, [replace(unmeasured, build=BUILD)])[0], [UNPROVEN])

    def test_without_arms_the_verdict_is_the_plain_one(self):
        plain = self.judged(steed_entry(), {})
        armless = self.judged(steed_entry(ally_arm={'allies': 1}), {})
        self.assertEqual((armless.status, armless.measured, armless.expected, armless.explanation),
                         (plain.status, plain.measured, plain.expected, plain.explanation))


if __name__ == '__main__':
    unittest.main()
