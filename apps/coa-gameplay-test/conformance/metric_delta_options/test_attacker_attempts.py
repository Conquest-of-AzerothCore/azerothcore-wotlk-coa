import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from metric_delta_options.attacker_attempts import (ATTACKERS, DAMAGE_SHIELD_OPCODE, AttackerAttempts, arm_rounds,
                                                    attacker_ids, fixture_label, prefix, read_label, running_label,
                                                    shield_label, struck_attacker)
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

AURA = 681220
SPELL = 25307
TRIALS = 64
FIXTURES = (6590, 803393)
SMALL = {'spell': SPELL, 'trials': 8, 'wait_ms': 2800}


def entry(**changes) -> dict:
    base = {'spell': AURA, 'kind': 'metric_delta', 'trigger_spell': AURA, 'name': 'attacker attempts test',
            'variant': 'attempts_test', 'label_suffix': 'attempts_test',
            'quote': 'Each target struck is guaranteed to miss their next instance of damage',
            'before_expected': 0, 'expected': 0, 'metric': 'spell_log_count',
            'fields': {'spell': SPELL, 'caster': 'attacker1', 'target': 'caster'},
            'attacker_attempts': {'spell': SPELL, 'trials': TRIALS, 'wait_ms': 2800}}
    return {**base, **changes}


def readings(first_landed: int = 0, kept: int = 0, second_misses: int = 0, control_misses: int = 0,
             skip: str | None = None, silent: int = 0, pre_missing: bool = False,
             fixture_amounts: dict | None = None) -> dict:
    attempts = AttackerAttempts(SPELL, TRIALS, 2800, tuple(fixture_amounts or ()))
    head = prefix(AURA, attempts)
    values = {fixture_label(head, aura, attacker): amount for aura, amount in (fixture_amounts or {}).items()
              for attacker in attacker_ids()}
    budget = {'first': first_landed, 'kept': kept, 'second': second_misses, 'control': control_misses,
              'silent': silent}

    def spend(name: str) -> bool:
        if budget[name] > 0:
            budget[name] -= 1
            return True
        return False

    for arm, rounds in arm_rounds(attempts).items():
        for attacker in attacker_ids():
            logs = go = 0
            values[read_label(head, arm, 'r0', 'logs', attacker)] = logs
            values[read_label(head, arm, 'r0', 'go', attacker)] = go
            for index in range(1, rounds + 1):
                values[read_label(head, arm, f'r{index}', 'pre', attacker)] = 1 if arm == 'aura' else 0
                for attempt in ('a', 'b'):
                    go += 0 if spend('silent') else 1
                    if arm == 'aura' and attempt == 'a':
                        landed, aura = spend('first'), 1 if spend('kept') else 0
                    elif arm == 'aura':
                        landed, aura = not spend('second'), 0
                    else:
                        landed, aura = not spend('control'), 0
                    logs += int(landed)
                    moment = f'r{index}{attempt}'
                    values[read_label(head, arm, moment, 'logs', attacker)] = logs
                    values[read_label(head, arm, moment, 'go', attacker)] = go
                    values[read_label(head, arm, moment, 'aura', attacker)] = aura
    if pre_missing:
        values[read_label(head, 'aura', 'r1', 'pre', 'attacker1')] = 0
    if skip is not None:
        values.pop(skip)
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AttackerAttemptsTests(unittest.TestCase):
    def judged(self, values: dict):
        _, [expectation] = behaviour_scenario(load_class_file(15), entry())
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_scenario_has_eight_passive_attackers_and_three_arms_of_two_attempts(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), entry())
        run.validate(scenario, run.SIMULATED_CLOCK)
        attackers = [creature for creature in scenario['creatures'] if creature['id'].startswith('attacker')]
        self.assertEqual(len(attackers), ATTACKERS)
        self.assertEqual({creature['reaction'] for creature in attackers}, {0})
        casts = [step for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(len(casts), ATTACKERS * 2 * sum(arm_rounds(AttackerAttempts(SPELL, TRIALS, 2800)).values()))
        self.assertEqual({(step['spell'], step['target']) for step in casts}, {(SPELL, 'caster')})
        auras = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['stacks'] == 1]
        self.assertEqual(len(auras), ATTACKERS * TRIALS)
        self.assertEqual(expectation.model['attacker_attempts'],
                         {'spell': SPELL, 'trials': TRIALS, 'wait_ms': 2800, 'aura': AURA})
        self.assertEqual(expectation.model['metric'], 'spell_log_count')

    def test_without_the_option_the_entry_keeps_the_plain_metric_delta(self):
        plain = {key: value for key, value in entry().items() if key != 'attacker_attempts'}
        scenario, [expectation] = behaviour_scenario(load_class_file(15), plain)
        self.assertNotIn('attacker_attempts', expectation.model)
        self.assertFalse(any(step['action'] == 'cast' and step['actor'].startswith('attacker')
                             for step in scenario['steps']))

    def test_a_consumed_aura_with_second_attempts_at_the_control_rate_passes(self):
        verdict = self.judged(readings(second_misses=15, control_misses=15))
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_a_landed_first_attempt_alerts(self):
        verdict = self.judged(readings(first_landed=1))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_an_aura_left_after_a_first_attempt_alerts(self):
        verdict = self.judged(readings(kept=1))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_second_attempts_far_from_the_control_alert(self):
        verdict = self.judged(readings(second_misses=ATTACKERS * TRIALS - 1))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_a_missing_read_a_silent_attempt_or_a_missing_pre_aura_is_unmeasured(self):
        head = prefix(AURA, AttackerAttempts(SPELL, TRIALS, 2800))
        for values in (readings(skip=read_label(head, 'aura', 'r3a', 'aura', 'attacker4')),
                       readings(skip=read_label(head, 'control2', 'r2b', 'logs', 'attacker8')),
                       readings(silent=1), readings(pre_missing=True)):
            with self.subTest(keys=len(values)):
                self.assertEqual(self.judged(values).status, 'unmeasured')

    def test_attacker_auras_are_set_once_per_attacker_read_back_and_recorded(self):
        with_fixture = entry(attacker_attempts={'spell': SPELL, 'trials': TRIALS, 'wait_ms': 2800,
                                                'attacker_auras': list(FIXTURES)})
        scenario, [expectation] = behaviour_scenario(load_class_file(15), with_fixture)
        run.validate(scenario, run.SIMULATED_CLOCK)
        fixture = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] in FIXTURES]
        self.assertEqual(len(fixture), ATTACKERS * len(FIXTURES))
        self.assertEqual({step['caster'] for step in fixture}, set(attacker_ids()))
        self.assertEqual(expectation.model['attacker_attempts']['attacker_auras'], list(FIXTURES))
        self.assertIn(str(list(FIXTURES)), scenario['contract'])

    def test_a_fixture_read_at_zero_or_missing_is_unmeasured_and_a_carried_one_judges(self):
        with_fixture = entry(attacker_attempts={'spell': SPELL, 'trials': TRIALS, 'wait_ms': 2800,
                                                'attacker_auras': list(FIXTURES)})
        _, [expectation] = behaviour_scenario(load_class_file(15), with_fixture)
        head = prefix(AURA, AttackerAttempts(SPELL, TRIALS, 2800, FIXTURES))
        carried = {aura: 1 for aura in FIXTURES}
        ok = judge_behaviour(base_verdict(expectation),
                             FakeRun(readings(second_misses=15, control_misses=15, fixture_amounts=carried)),
                             expectation)
        self.assertEqual(ok.status, 'ok', ok.explanation)
        zero = readings(fixture_amounts={FIXTURES[0]: 1, FIXTURES[1]: 0})
        missing = readings(fixture_amounts=carried, skip=fixture_label(head, FIXTURES[0], 'attacker3'))
        for values in (zero, missing):
            verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
            self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)

    def test_the_option_refuses_a_bad_value_or_another_metric(self):
        for change in ({'attacker_attempts': {'spell': SPELL, 'trials': 0, 'wait_ms': 2800}},
                       {'attacker_attempts': {'spell': SPELL, 'trials': 8}},
                       {'attacker_attempts': {'spell': SPELL, 'trials': 8, 'wait_ms': 20000}},
                       {'attacker_attempts': {'spell': SPELL, 'trials': 128, 'wait_ms': 2800}},
                       {'attacker_attempts': {**SMALL, 'attacker_auras': [6590, 6590]}},
                       {'attacker_attempts': {**SMALL, 'attacker_auras': [0]}},
                       {'attacker_attempts': {**SMALL, 'attacker_auras': 6590}},
                       {'attacker_attempts': {**SMALL, 'other': 1}},
                       {'metric': 'spell_damage_total'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(15), entry(**change))


DOT = 10894
RUNNING_TRIALS = 36
LANDED_TRIALS = 60
RUNNING = {'spell': SPELL, 'trials': RUNNING_TRIALS, 'wait_ms': 2800, 'running': {'spell': DOT, 'wait_ms': 3500}}
TICK = 128


def running_readings(trials: int = RUNNING_TRIALS, dropped: int = 0, zeroed: int = 0, weak: int = 0, silent: int = 0,
                     no_dot: bool = False) -> dict:
    attempts = AttackerAttempts(SPELL, trials, 2800, (), (DOT, 3500))
    head = prefix(AURA, attempts)
    values = {}
    budget = {'dropped': dropped, 'zeroed': zeroed, 'weak': weak, 'silent': silent}

    def spend(name: str) -> bool:
        if budget[name] > 0:
            budget[name] -= 1
            return True
        return False

    for arm, rounds in arm_rounds(attempts).items():
        ticks = {attacker: 0 for attacker in attacker_ids()}
        damage = {attacker: 0 for attacker in attacker_ids()}
        for attacker in attacker_ids():
            values[read_label(head, arm, 'r0', 'logs', attacker)] = 0
            values[read_label(head, arm, 'r0', 'go', attacker)] = 0
            values[running_label(head, arm, 0, 'ticks', attacker)] = 0
            values[running_label(head, arm, 0, 'damage', attacker)] = 0
        logs = {attacker: 0 for attacker in attacker_ids()}
        go = {attacker: 0 for attacker in attacker_ids()}
        for index in range(1, rounds + 1):
            lost = 0
            for attacker in attacker_ids():
                values[running_label(head, arm, index, 'dot', attacker)] = 0 if no_dot else 1
                values[read_label(head, arm, f'r{index}', 'pre', attacker)] = 1 if arm == 'aura' else 0
                tick = 0 if spend('silent') else 1
                amount = TICK // 2 if arm == 'aura' and spend('weak') else TICK
                ticks[attacker] += tick
                damage[attacker] += tick * amount
                lost += 0 if arm == 'aura' and spend('zeroed') else tick * amount
                values[running_label(head, arm, index, 'ticks', attacker)] = ticks[attacker]
                values[running_label(head, arm, index, 'damage', attacker)] = damage[attacker]
                values[running_label(head, arm, index, 'held', attacker)] = (
                    0 if arm != 'aura' or spend('dropped') else 1)
                for attempt in ('a', 'b'):
                    go[attacker] += 1
                    landed = not (arm == 'aura' and attempt == 'a')
                    logs[attacker] += int(landed)
                    moment = f'r{index}{attempt}'
                    values[read_label(head, arm, moment, 'logs', attacker)] = logs[attacker]
                    values[read_label(head, arm, moment, 'go', attacker)] = go[attacker]
                    values[read_label(head, arm, moment, 'aura', attacker)] = 0
            values[running_label(head, arm, index, 'health_before', 'caster')] = 1_000_000
            values[running_label(head, arm, index, 'health_after', 'caster')] = 1_000_000 - lost
    return values


def landed_readings(trials: int = LANDED_TRIALS, first_landed: int = 0) -> dict:
    attempts = AttackerAttempts(DOT, trials, 500, (), None, 'aura')
    head = prefix(AURA, attempts)
    values = {}
    budget = {'first': first_landed}
    for arm, rounds in arm_rounds(attempts).items():
        for attacker in attacker_ids():
            go = 0
            values[read_label(head, arm, 'r0', 'landed', attacker)] = 0
            values[read_label(head, arm, 'r0', 'go', attacker)] = 0
            for index in range(1, rounds + 1):
                values[read_label(head, arm, f'r{index}', 'pre', attacker)] = 1 if arm == 'aura' else 0
                for attempt in ('a', 'b'):
                    go += 1
                    landed = 1
                    if arm == 'aura' and attempt == 'a':
                        landed = 1 if budget['first'] > 0 else 0
                        budget['first'] -= landed
                    moment = f'r{index}{attempt}'
                    values[read_label(head, arm, moment, 'landed', attacker)] = landed
                    values[read_label(head, arm, moment, 'go', attacker)] = go
                    values[read_label(head, arm, moment, 'aura', attacker)] = 0
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RunningAndLandedTests(unittest.TestCase):
    def judged(self, option: dict, values: dict):
        _, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=option))
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_running_casts_the_effect_before_the_aura_and_reads_a_window_per_trial(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=RUNNING))
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        trials = sum(arm_rounds(AttackerAttempts(SPELL, RUNNING_TRIALS, 2800)).values())
        dots = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == DOT]
        self.assertEqual(len(dots), ATTACKERS * trials)
        first_aura = next(index for index, step in enumerate(steps)
                          if step['action'] == 'set_aura' and step['spell'] == AURA and step['stacks'] == 1)
        self.assertLess(dots[0], first_aura)
        removals = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == DOT]
        self.assertEqual({(step['target'], step['stacks']) for step in removals}, {('caster', 0)})
        self.assertEqual(len(removals), ATTACKERS * trials)
        self.assertEqual(expectation.model['attacker_attempts']['running'], {'spell': DOT, 'wait_ms': 3500})
        self.assertIn(f'casts {DOT}', scenario['contract'])

    def test_running_ticks_that_keep_the_aura_at_full_damage_pass(self):
        verdict = self.judged(RUNNING, running_readings())
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_a_tick_that_removes_the_aura_alerts(self):
        verdict = self.judged(RUNNING, running_readings(dropped=1))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_ticks_zeroed_under_the_aura_alert(self):
        verdict = self.judged(RUNNING, running_readings(zeroed=ATTACKERS * RUNNING_TRIALS))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_weaker_ticks_under_the_aura_alert(self):
        verdict = self.judged(RUNNING, running_readings(weak=ATTACKERS * RUNNING_TRIALS))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_a_window_without_a_tick_or_without_the_effect_is_unmeasured(self):
        for values in (running_readings(silent=1), running_readings(no_dot=True)):
            with self.subTest(keys=len(values)):
                self.assertEqual(self.judged(RUNNING, values).status, 'unmeasured')

    def test_landed_aura_reads_the_effect_on_the_caster_and_removes_it_after_each_attempt(self):
        option = {'spell': DOT, 'trials': LANDED_TRIALS, 'wait_ms': 500, 'landed': 'aura'}
        scenario, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=option))
        run.validate(scenario, run.SIMULATED_CLOCK)
        landed = [step for step in scenario['steps'] if step['action'] == 'assert' and step['label'].endswith(
            tuple(f' landed {attacker}' for attacker in attacker_ids()))]
        self.assertTrue(landed)
        self.assertEqual({(step['actor'], step['metric'], step['spell']) for step in landed}, {('caster', 'aura', DOT)})
        removals = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == DOT]
        trials = sum(arm_rounds(AttackerAttempts(DOT, LANDED_TRIALS, 500)).values())
        self.assertEqual(len(removals), ATTACKERS * 2 * trials)
        self.assertEqual(expectation.model['attacker_attempts']['landed'], 'aura')
        self.assertEqual(self.judged(option, landed_readings()).status, 'ok')
        self.assertEqual(self.judged(option, landed_readings(first_landed=1)).status, 'alert')

    def test_the_new_fields_refuse_bad_values(self):
        for option in ({**SMALL, 'running': {'spell': DOT}}, {**SMALL, 'running': {'spell': DOT, 'wait_ms': 0}},
                       {**SMALL, 'running': {'spell': DOT, 'wait_ms': 20000}}, {**SMALL, 'running': DOT},
                       {**SMALL, 'landed': 'health'}):
            with self.subTest(option=option), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(15), entry(attacker_attempts=option))


SHIELD = 43420
SHIELD_FIXTURE = 823764
SHIELD_TRIALS = 16
SHIELD_DAMAGE = 200
SHIELDED = {'spell': SPELL, 'trials': SHIELD_TRIALS, 'wait_ms': 2800,
            'shield': {'spell': SHIELD, 'wait_ms': 2400, 'caster_auras': [SHIELD_FIXTURE]}}


def shield_readings(dropped: int = 0, zeroed: int = 0, silent: int = 0, control_held: bool = False,
                    no_fixture: bool = False) -> dict:
    attempts = AttackerAttempts(SPELL, SHIELD_TRIALS, 2800, (), None, 'logs', (SHIELD, 2400, (SHIELD_FIXTURE,)))
    head = prefix(AURA, attempts)
    values = {fixture_label(head, SHIELD_FIXTURE, 'caster'): 0 if no_fixture else 1}
    budget = {'dropped': dropped, 'zeroed': zeroed, 'silent': silent}

    def spend(name: str) -> bool:
        if budget[name] > 0:
            budget[name] -= 1
            return True
        return False

    packets = 0
    health = 1_000_000
    for arm, rounds in arm_rounds(attempts).items():
        logs = {attacker: 0 for attacker in attacker_ids()}
        go = {attacker: 0 for attacker in attacker_ids()}
        for attacker in attacker_ids():
            values[read_label(head, arm, 'r0', 'logs', attacker)] = 0
            values[read_label(head, arm, 'r0', 'go', attacker)] = 0
        for index in range(1, rounds + 1):
            health = 1_000_000
            for attacker in attacker_ids():
                values[read_label(head, arm, f'r{index}', 'pre', attacker)] = 1 if arm == 'aura' else 0
            values[shield_label(head, arm, index, 'on')] = 1
            values[shield_label(head, arm, index, 'packets_before')] = packets
            values[shield_label(head, arm, index, 'health_before')] = health
            hits = 0 if spend('silent') else 1
            packets += hits
            health -= 0 if arm == 'aura' and spend('zeroed') else hits * SHIELD_DAMAGE
            values[shield_label(head, arm, index, 'packets_after')] = packets
            values[shield_label(head, arm, index, 'damage')] = SHIELD_DAMAGE if packets else -1
            values[shield_label(head, arm, index, 'health_after')] = health
            values[shield_label(head, arm, index, 'held')] = (
                int(control_held) if arm != 'aura' else 0 if spend('dropped') else 1)
            for attacker in attacker_ids():
                for attempt in ('a', 'b'):
                    go[attacker] += 1
                    logs[attacker] += int(not (arm == 'aura' and attempt == 'a'))
                    moment = f'r{index}{attempt}'
                    values[read_label(head, arm, moment, 'logs', attacker)] = logs[attacker]
                    values[read_label(head, arm, moment, 'go', attacker)] = go[attacker]
                    values[read_label(head, arm, moment, 'aura', attacker)] = 0
    return values


TRIGGER = 2150082
TRIGGERED_TICK = 2150083
AREA = 892288
TICKED = {'spell': SPELL, 'trials': RUNNING_TRIALS, 'wait_ms': 2800,
          'running': {'spell': TRIGGER, 'wait_ms': 1500, 'tick': TRIGGERED_TICK}}
PERIODIC_LANDED = {'spell': AREA, 'trials': LANDED_TRIALS, 'wait_ms': 2500, 'landed': 'periodic'}


def periodic_readings(first_landed: int = 0) -> dict:
    attempts = AttackerAttempts(AREA, LANDED_TRIALS, 2500, (), None, 'periodic')
    head = prefix(AURA, attempts)
    values = {}
    budget = {'first': first_landed}
    for arm, rounds in arm_rounds(attempts).items():
        for attacker in attacker_ids():
            go = ticks = 0
            values[read_label(head, arm, 'r0', 'ticks', attacker)] = 0
            values[read_label(head, arm, 'r0', 'go', attacker)] = 0
            for index in range(1, rounds + 1):
                values[read_label(head, arm, f'r{index}', 'pre', attacker)] = 1 if arm == 'aura' else 0
                for attempt in ('a', 'b'):
                    go += 1
                    landed = True
                    if arm == 'aura' and attempt == 'a':
                        landed = budget['first'] > 0
                        budget['first'] -= int(landed)
                    ticks += 2 if landed else 0
                    moment = f'r{index}{attempt}'
                    values[read_label(head, arm, moment, 'ticks', attacker)] = ticks
                    values[read_label(head, arm, moment, 'go', attacker)] = go
                    values[read_label(head, arm, moment, 'aura', attacker)] = 0
    return values


TICK_LANDED = {'spell': TRIGGER, 'trials': RUNNING_TRIALS, 'wait_ms': 1500, 'landed_tick': TRIGGERED_TICK}


def tick_landed_readings(first_landed: int = 0, kept: int = 0) -> dict:
    attempts = AttackerAttempts(TRIGGER, RUNNING_TRIALS, 1500, (), None, 'logs', None, TRIGGERED_TICK)
    head = prefix(AURA, attempts)
    values = {}
    budget = {'first': first_landed, 'kept': kept}
    for arm, rounds in arm_rounds(attempts).items():
        for attacker in attacker_ids():
            go = logs = 0
            values[read_label(head, arm, 'r0', 'logs', attacker)] = 0
            values[read_label(head, arm, 'r0', 'go', attacker)] = 0
            for index in range(1, rounds + 1):
                values[read_label(head, arm, f'r{index}', 'pre', attacker)] = 1 if arm == 'aura' else 0
                for attempt in ('a', 'b'):
                    go += 1
                    landed, aura = True, 0
                    if arm == 'aura' and attempt == 'a':
                        landed = budget['first'] > 0
                        budget['first'] -= int(landed)
                        aura = int(budget['kept'] > 0)
                        budget['kept'] -= aura
                    logs += 1 if landed else 0
                    moment = f'r{index}{attempt}'
                    values[read_label(head, arm, moment, 'logs', attacker)] = logs
                    values[read_label(head, arm, moment, 'go', attacker)] = go
                    values[read_label(head, arm, moment, 'aura', attacker)] = aura
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ShieldTickAndPeriodicTests(unittest.TestCase):
    def judged(self, option: dict, values: dict):
        _, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=option))
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_shield_strikes_one_attacker_per_trial_and_reads_the_shield_packets(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=SHIELDED))
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        trials = sum(arm_rounds(AttackerAttempts(SPELL, SHIELD_TRIALS, 2800)).values())
        attacks = [step for step in steps if step['action'] == 'attack']
        self.assertEqual(len(attacks), trials)
        self.assertEqual({step['target'] for step in attacks}, set(attacker_ids()))
        self.assertEqual(attacks[0]['target'], struck_attacker(1))
        self.assertEqual(sum(step['action'] == 'stop_attack' for step in steps), trials)
        shields = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == SHIELD]
        self.assertEqual(sorted({step['stacks'] for step in shields}), [0, 1])
        self.assertEqual(len(shields), 2 * trials)
        packets = [step for step in steps if step['action'] == 'assert' and step.get('opcode') == DAMAGE_SHIELD_OPCODE]
        self.assertEqual(len(packets), 3 * trials)
        fixture = [step for step in steps if step['action'] == 'set_aura' and step['spell'] == SHIELD_FIXTURE]
        self.assertEqual([(step['target'], step['stacks']) for step in fixture], [('caster', 1)])
        first_attack = steps.index(attacks[0])
        first_attempt = next(index for index, step in enumerate(steps)
                             if step['action'] == 'cast' and step['spell'] == SPELL)
        self.assertLess(first_attack, first_attempt)
        self.assertEqual(expectation.model['attacker_attempts']['shield'],
                         {'spell': SHIELD, 'wait_ms': 2400, 'caster_auras': [SHIELD_FIXTURE]})
        self.assertIn('SMSG_SPELLDAMAGESHIELD', scenario['contract'])

    def test_a_landed_shield_that_keeps_the_aura_at_full_damage_passes(self):
        verdict = self.judged(SHIELDED, shield_readings())
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_a_shield_that_removes_the_aura_alerts(self):
        verdict = self.judged(SHIELDED, shield_readings(dropped=1))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_shields_zeroed_under_the_aura_alert(self):
        verdict = self.judged(SHIELDED, shield_readings(zeroed=SHIELD_TRIALS))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_a_window_without_a_packet_is_left_out_and_an_arm_without_any_is_unmeasured(self):
        self.assertEqual(self.judged(SHIELDED, shield_readings(silent=1)).status, 'ok')
        self.assertEqual(self.judged(SHIELDED, shield_readings(silent=4 + SHIELD_TRIALS)).status, 'unmeasured')

    def test_an_aura_in_the_control_or_a_missing_caster_fixture_is_unmeasured(self):
        for values in (shield_readings(control_held=True), shield_readings(no_fixture=True)):
            with self.subTest(keys=len(values)):
                self.assertEqual(self.judged(SHIELDED, values).status, 'unmeasured')

    def test_a_running_tick_spell_is_read_without_the_periodic_filter(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=TICKED))
        run.validate(scenario, run.SIMULATED_CLOCK)
        ticks = [step for step in scenario['steps'] if step['action'] == 'assert' and ' running ticks ' in step['label']]
        self.assertTrue(ticks)
        self.assertEqual({(step['spell'], step.get('periodic')) for step in ticks}, {(TRIGGERED_TICK, None)})
        self.assertEqual(expectation.model['attacker_attempts']['running'],
                         {'spell': TRIGGER, 'wait_ms': 1500, 'tick': TRIGGERED_TICK})
        self.assertIn(f'triggered tick spell {TRIGGERED_TICK}', scenario['contract'])

    def test_a_periodic_landed_read_counts_ticks_over_the_attempt(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=PERIODIC_LANDED))
        run.validate(scenario, run.SIMULATED_CLOCK)
        landed = [step for step in scenario['steps'] if step['action'] == 'assert' and step['label'].endswith(
            tuple(f' ticks {attacker}' for attacker in attacker_ids()))]
        self.assertTrue(landed)
        self.assertEqual({(step['metric'], step['spell'], step['periodic']) for step in landed},
                         {('spell_damage_count', AREA, True)})
        self.assertFalse([step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == AREA])
        self.assertEqual(expectation.model['attacker_attempts']['landed'], 'periodic')
        self.assertEqual(self.judged(PERIODIC_LANDED, periodic_readings()).status, 'ok')
        self.assertEqual(self.judged(PERIODIC_LANDED, periodic_readings(first_landed=1)).status, 'alert')

    def test_a_landed_tick_read_counts_the_tick_spell_logs_and_removes_the_attempt_spell(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), entry(attacker_attempts=TICK_LANDED))
        run.validate(scenario, run.SIMULATED_CLOCK)
        landed = [step for step in scenario['steps'] if step['action'] == 'assert' and step['label'].endswith(
            tuple(f' logs {attacker}' for attacker in attacker_ids()))]
        self.assertTrue(landed)
        self.assertEqual({(step['metric'], step['spell']) for step in landed}, {('spell_log_count', TRIGGERED_TICK)})
        removals = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == TRIGGER]
        trials = sum(arm_rounds(AttackerAttempts(TRIGGER, RUNNING_TRIALS, 1500)).values())
        self.assertEqual(len(removals), 2 * 2 * ATTACKERS * trials)
        self.assertEqual({(step['target'] == 'caster', step['stacks']) for step in removals}, {(True, 0), (False, 0)})
        self.assertEqual(expectation.model['attacker_attempts']['landed_tick'], TRIGGERED_TICK)
        self.assertIn(f'triggered tick spell {TRIGGERED_TICK}', scenario['contract'])
        self.assertEqual(self.judged(TICK_LANDED, tick_landed_readings()).status, 'ok')
        self.assertEqual(self.judged(TICK_LANDED, tick_landed_readings(first_landed=1)).status, 'alert')
        self.assertEqual(self.judged(TICK_LANDED, tick_landed_readings(kept=1)).status, 'alert')

    def test_without_landed_tick_the_logs_read_keeps_the_attempt_spell(self):
        scenario, _ = behaviour_scenario(load_class_file(15), entry(attacker_attempts=SMALL))
        landed = [step for step in scenario['steps'] if step['action'] == 'assert' and step['label'].endswith(
            tuple(f' logs {attacker}' for attacker in attacker_ids()))]
        self.assertEqual({step['spell'] for step in landed}, {SPELL})
        self.assertFalse([step for step in scenario['steps']
                          if step['action'] == 'set_aura' and step['spell'] == SPELL])

    def test_the_shield_and_tick_fields_refuse_bad_values(self):
        for option in ({**SMALL, 'shield': {'spell': SHIELD}}, {**SMALL, 'shield': {'spell': SHIELD, 'wait_ms': 0}},
                       {**SMALL, 'shield': {'spell': SHIELD, 'wait_ms': 20000}},
                       {**SMALL, 'shield': {'spell': SHIELD, 'wait_ms': 2400, 'caster_auras': [1, 1]}},
                       {**SMALL, 'shield': {'spell': SHIELD, 'wait_ms': 2400, 'other': 1}},
                       {**SMALL, 'running': {'spell': DOT, 'wait_ms': 3500, 'tick': 0}},
                       {**SMALL, 'landed_tick': 0}, {**SMALL, 'landed_tick': True},
                       {**SMALL, 'landed_tick': TRIGGERED_TICK, 'landed': 'aura'},
                       {**SMALL, 'running': {'spell': DOT, 'wait_ms': 3500},
                        'shield': {'spell': SHIELD, 'wait_ms': 2400}}):
            with self.subTest(option=option), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(15), entry(attacker_attempts=option))


if __name__ == '__main__':
    unittest.main()
