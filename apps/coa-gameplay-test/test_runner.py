import copy
from datetime import datetime, timedelta, timezone
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import run


class RunnerTests(unittest.TestCase):
    def test_player_account_sharing_requires_an_earlier_player(self):
        self.scenario['players'].append({'id': 'alt', 'race': 1, 'class': 1, 'account_of': 'caster'})
        self.assertIs(run.validate(self.scenario), self.scenario)
        for owner in ('alt', 'missing', 'target', '', 1, None):
            self.scenario['players'][-1]['account_of'] = owner
            with self.subTest(owner=owner), self.assertRaisesRegex(ValueError, 'earlier player'):
                run.validate(self.scenario)

    def test_duel_arbiter_packet_field_requires_a_player(self):
        step = {'action': 'client_packet', 'actor': 'caster', 'opcode': 364,
                'fields': [{'duel_arbiter': 'caster'}], 'consumed': False}
        self.scenario['steps'].append(step)
        self.assertIs(run.validate(self.scenario), self.scenario)
        for actor in ('target', 'missing', 1):
            step['fields'] = [{'duel_arbiter': actor}]
            with self.subTest(actor=actor), self.assertRaisesRegex(ValueError, 'expected a player id'):
                run.validate(self.scenario)

    def test_spell_cast_and_proc_counts_can_share_relative_snapshots(self):
        for measured, captured in (('spell_cast_count', 'spell_proc_count'),
                                   ('spell_proc_count', 'spell_cast_count')):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].extend([
                {'action': 'snapshot', 'actor': 'caster', 'metric': captured,
                 'spell': 653267, 'save_as': 'native_procs'},
                {'action': 'assert', 'actor': 'caster', 'metric': measured,
                 'spell': 653263, 'relative_to': 'native_procs', 'equals': 0},
            ])
            with self.subTest(measured=measured, captured=captured):
                self.assertIs(run.validate(scenario), scenario)

    def test_spell_event_relative_snapshots_reject_missing_or_incompatible_metrics(self):
        for captured, reference in (('health', 'baseline'), ('spell_proc_count', 'missing')):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].extend([
                {'action': 'snapshot', 'actor': 'caster', 'metric': captured,
                 **({'spell': 653267} if captured == 'spell_proc_count' else {}),
                 'save_as': 'baseline'},
                {'action': 'assert', 'actor': 'caster', 'metric': 'spell_cast_count',
                 'spell': 653263, 'relative_to': reference, 'equals': 0},
            ])
            with self.subTest(captured=captured, reference=reference), \
                    self.assertRaisesRegex(ValueError, 'missing or incompatible snapshot'):
                run.validate(scenario)

    def test_spell_family_flags_require_a_spell_and_valid_word(self):
        for word in (0, 1, 2):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].append({'action': 'assert', 'actor': 'caster',
                                     'metric': 'spell_family_flags', 'spell': 116, 'index': word, 'equals': 0})
            self.assertIs(run.validate(scenario), scenario)
        for extra in ({}, {'spell': 116, 'index': -1}, {'spell': 116, 'index': 3},
                      {'spell': 116, 'index': True}, {'spell': 116, 'index': 0.5}):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].append({'action': 'assert', 'actor': 'caster',
                                     'metric': 'spell_family_flags', 'equals': 0, **extra})
            with self.subTest(extra=extra), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_creature_spell_hit_bonus_and_native_metric(self):
        for bonus in (0, 4, 100):
            scenario = copy.deepcopy(self.scenario)
            scenario['creatures'][0]['spell_hit_bonus'] = bonus
            scenario['steps'].append({'action': 'assert', 'actor': 'target',
                                     'metric': 'spell_hit_chance', 'equals': bonus})
            self.assertIs(run.validate(scenario), scenario)
        for bonus in (-1, 100.1, True, float('nan'), float('inf'), '100'):
            scenario = copy.deepcopy(self.scenario)
            scenario['creatures'][0]['spell_hit_bonus'] = bonus
            with self.subTest(bonus=bonus), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_creature_reaction_and_victim_target_validation(self):
        for reaction in (0, 1, 2):
            scenario = copy.deepcopy(self.scenario)
            scenario['creatures'][0]['reaction'] = reaction
            scenario['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'victim',
                                     'target': 'caster', 'equals': 0})
            self.assertIs(run.validate(scenario), scenario)
        for reaction in (-1, 3, True, 1.5, '1'):
            scenario = copy.deepcopy(self.scenario)
            scenario['creatures'][0]['reaction'] = reaction
            with self.subTest(reaction=reaction), self.assertRaises(ValueError):
                run.validate(scenario)
        for target in (None, 'absent'):
            scenario = copy.deepcopy(self.scenario)
            step = {'action': 'assert', 'actor': 'target', 'metric': 'victim', 'equals': 0}
            if target is not None:
                step['target'] = target
            scenario['steps'].append(step)
            with self.subTest(target=target), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_profession_fixture_validation(self):
        scenario = run.read_json(Path(__file__).parent / 'scenarios' / 'profession-xp.json')
        self.assertIs(run.validate(scenario), scenario)
        for step in (
            {'action': 'set_skill', 'actor': 'gatherer', 'skill': 186, 'value': 76, 'maximum': 75},
            {'action': 'gather_skill', 'actor': 'gatherer', 'skill': 171, 'required': 1},
            {'action': 'gather_skill', 'actor': 'gatherer', 'skill': 186, 'required': -1},
            {'action': 'set_xp_enabled', 'actor': 'gatherer', 'enabled': 1},
            {'action': 'assert', 'actor': 'gatherer', 'metric': 'skill_value', 'equals': 0},
            {'action': 'assert', 'actor': 'gatherer', 'metric': 'health', 'ratio_to': 'level_xp', 'equals': 1},
        ):
            invalid = copy.deepcopy(scenario)
            invalid['steps'].append(step)
            with self.subTest(step=step), self.assertRaises(ValueError):
                run.validate(invalid)

    def test_optional_character_names(self):
        scenario = run.read_json(Path(__file__).parent / 'scenarios' / 'optional-character-names.json')
        self.assertIs(run.validate(scenario), scenario)
        for invalid in ('x' * 26, '\u0410' * 24):
            candidate = copy.deepcopy(scenario)
            candidate['players'][0]['name'] = invalid
            with self.assertRaises(ValueError):
                run.validate(candidate)
        for field, value in [('name', None), ('actor', 'absent')]:
            candidate = copy.deepcopy(scenario)
            candidate['steps'][0][field] = value
            with self.assertRaises(ValueError):
                run.validate(candidate)

    def test_personal_bank_split_packets(self):
        for direction in ('deposit', 'withdraw'):
            scenario = copy.deepcopy(self.scenario)
            step = {'action': 'personal_bank_swap', 'actor': 'caster', 'entry': 475001,
                    'direction': direction, 'count': 5}
            if direction == 'deposit':
                step['item'] = 2589
            else:
                step['inventory_slot'] = 38
            scenario['steps'].append(step)
            self.assertIs(run.validate(scenario), scenario)
            for key, value in (('count', -1), ('count', 2**31), ('count', True), ('slot', 98),
                               ('inventory_slot', 39), ('direction', 'invalid')):
                invalid = copy.deepcopy(scenario)
                invalid['steps'][-1][key] = value
                with self.subTest(direction=direction, key=key, value=value):
                    with self.assertRaises(ValueError):
                        run.validate(invalid)

    def setUp(self):
        self.scenario = run.read_json(Path(__file__).parent / 'scenarios' / 'frostbolt.json')

    def report(self):
        records = []
        for index, step in enumerate(self.scenario['steps']):
            record = {'index': str(index), 'action': step['action'], 'status': 'completed'}
            if step['action'] == 'assert':
                record.update(status='passed', actual=str(step.get('equals', step.get('max', step.get('min')))))
            records.append(record)
        return {
            'schema': '1', 'run_id': '012345abcdef', 'scenario': self.scenario['name'],
            'execution': 'socketless-session-handlers', 'status': 'passed',
            'assertions': str(sum(step['action'] == 'assert' for step in self.scenario['steps'])),
            'completed_steps': str(len(records)), 'steps': records,
        }

    def test_example_is_valid(self):
        for path in (Path(__file__).parent / 'scenarios').glob('*.json'):
            scenario = run.read_json(path)
            with self.subTest(path=path):
                self.assertIs(run.validate(scenario), scenario)

    def test_hour_is_an_optional_realm_local_hour(self):
        for hour in (0, 12, 23):
            scenario = copy.deepcopy(self.scenario)
            scenario['hour'] = hour
            self.assertIs(run.validate(scenario), scenario)
        for hour in (-1, 24, 1.5, True, '12', None):
            scenario = copy.deepcopy(self.scenario)
            scenario['hour'] = hour
            with self.subTest(hour=hour), self.assertRaisesRegex(ValueError, '^hour: '):
                run.validate(scenario)

    def test_creature_scaling_is_an_optional_boolean(self):
        for value in (True, False):
            scenario = copy.deepcopy(self.scenario)
            scenario['creature_scaling'] = value
            self.assertIs(run.validate(scenario), scenario)
        for value in (1, 'true', None):
            scenario = copy.deepcopy(self.scenario)
            scenario['creature_scaling'] = value
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, 'creature_scaling must be boolean'):
                run.validate(scenario)

    def test_hour_timezone_is_a_posix_offset_placing_local_time_at_the_start_of_that_hour(self):
        for utc_hour, hour, expected in ((10, 12, 'UTC-01:01'), (23, 0, 'UTC-00:01'), (1, 23, 'UTC+02:59'),
                                         (12, 0, 'UTC-11:01'), (12, 23, 'UTC-10:01'), (5, 5, 'UTC+00:59'),
                                         (0, 12, 'UTC-11:01'), (22, 12, 'UTC+10:59'), (18, 6, 'UTC-11:01')):
            now = datetime(2026, 9, 24, utc_hour, 59, 30, tzinfo=timezone.utc)
            with self.subTest(utc_hour=utc_hour, hour=hour):
                zone = run.hour_timezone(hour, now)
                self.assertEqual(zone, expected)
                west = (1 if zone[3] == '+' else -1) * (int(zone[4:6]) * 60 + int(zone[7:9]))
                self.assertEqual((utc_hour * 60 + 59 - west) % (24 * 60), hour * 60)
        moscow = datetime(2026, 9, 25, 1, 0, tzinfo=timezone(timedelta(hours=3)))
        self.assertEqual(run.hour_timezone(12, moscow), 'UTC+10:00')
        with patch.object(run, 'utc_now', return_value=datetime(2026, 9, 24, 3, 0, tzinfo=timezone.utc)):
            self.assertEqual(run.scenario_timezone({**self.scenario, 'hour': 0}), {'TZ': 'UTC+03:00'})
        self.assertEqual(run.scenario_timezone(self.scenario), {})

    @unittest.skipIf(os.name == 'nt', 'POSIX TZ strings are checked through the C library of a child process')
    def test_hour_timezone_starts_that_local_hour_in_a_child_process(self):
        for utc_hour, minute, hour in ((10, 30, 12), (22, 59, 12), (23, 59, 0), (1, 0, 23), (12, 1, 0), (6, 45, 18)):
            now = datetime(2026, 9, 24, utc_hour, minute, 30, tzinfo=timezone.utc)
            with self.subTest(utc_hour=utc_hour, minute=minute, hour=hour):
                local = subprocess.run(
                    [sys.executable, '-c', f'import time; print(time.localtime({int(now.timestamp())})[3:5])'],
                    env={**os.environ, 'TZ': run.hour_timezone(hour, now)}, capture_output=True, text=True,
                    check=True)
                self.assertEqual(local.stdout.strip(), f'({hour}, 0)')

    def test_spell_damage_observation_filters(self):
        step = {'action': 'assert', 'actor': 'caster', 'metric': 'spell_damage_count',
                'spell': 116, 'target': 'target', 'pet': True, 'critical': False, 'equals': 0}
        self.scenario['steps'].append(step)
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'pet': 1}, {'critical': 'false'}, {'actor': 'target'}, {'spell': None},
                       {'metric': 'health'}):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'][-1].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_ratio_can_compare_different_numeric_metrics(self):
        self.scenario['steps'].extend([
            {'action': 'snapshot', 'actor': 'caster', 'metric': 'spell_damage_total', 'spell': 116,
             'target': 'target', 'save_as': 'damage'},
            {'action': 'assert', 'actor': 'caster', 'metric': 'spell_heal_total', 'spell': 116,
             'target': 'caster', 'ratio_to': 'damage', 'equals': 1},
        ])
        self.assertIs(run.validate(self.scenario), self.scenario)

    def test_completed_cast_and_packet_count_metrics(self):
        for metric, actor, extra in [('spell_cast_count', 'caster', {}),
                                     ('spell_cast_count', 'target', {}),
                                     ('spell_go_count', 'caster', {}),
                                     ('spell_go_count', 'caster', {'pet': True}),
                                     ('spell_go_count', 'caster', {'entry': 50587})]:
            with self.subTest(metric=metric, actor=actor, extra=extra):
                scenario = copy.deepcopy(self.scenario)
                scenario['steps'].append({'action': 'assert', 'actor': actor, 'metric': metric,
                                          'spell': 116, 'equals': 0, **extra})
                self.assertIs(run.validate(scenario), scenario)
                del scenario['steps'][-1]['spell']
                with self.assertRaises(ValueError):
                    run.validate(scenario)
        for metric, actor, extra in [('spell_go_count', 'target', {}),
                                     ('spell_cast_count', 'caster', {'pet': True}),
                                     ('spell_go_count', 'caster', {'pet': 1}),
                                     ('spell_go_count', 'caster', {'entry': 0}),
                                     ('spell_go_count', 'caster', {'entry': 50587, 'pet': True})]:
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].append({'action': 'assert', 'actor': actor, 'metric': metric,
                                      'spell': 116, 'equals': 0, **extra})
            with self.subTest(metric=metric, actor=actor, extra=extra), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_native_relog_and_slot_observations(self):
        for step in [
            {'action': 'relog', 'actor': 'caster'},
            {'action': 'relog', 'actor': 'caster', 'race': 11},
            {'action': 'assert', 'actor': 'caster', 'metric': 'race', 'equals': 11},
            {'action': 'assert', 'actor': 'caster', 'metric': 'pet_native_display', 'equals': 173031},
            {'action': 'assert', 'actor': 'caster', 'metric': 'action_button_packed', 'button': 143, 'equals': 0},
            {'action': 'assert', 'actor': 'caster', 'metric': 'server_packet_u32', 'opcode': 1829, 'index': 1,
             'equals': 20},
        ]:
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].append(step)
            self.assertIs(run.validate(scenario), scenario)
        for step in [
            {'action': 'relog', 'actor': 'target'},
            {'action': 'assert', 'actor': 'caster', 'metric': 'action_button_packed', 'equals': 0},
            {'action': 'assert', 'actor': 'caster', 'metric': 'server_packet_u32', 'opcode': 1829, 'index': -1,
             'equals': 0},
        ]:
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].append(step)
            with self.assertRaises(ValueError):
                run.validate(scenario)

    def test_packet_float_observation_fields(self):
        valid = {'action': 'assert', 'actor': 'caster', 'metric': 'server_packet_float',
                 'opcode': 239, 'from_end': True, 'index': 0, 'equals': -8.6}
        scenario = copy.deepcopy(self.scenario)
        scenario['steps'].append(valid)
        self.assertIs(run.validate(scenario), scenario)
        for changes in [{'opcode': 0}, {'index': -1}, {'from_end': 1}, {'offset': 4}, {'skip_strings': 1}]:
            with self.subTest(changes=changes):
                scenario = copy.deepcopy(self.scenario)
                scenario['steps'].append({**valid, **changes})
                with self.assertRaises(ValueError):
                    run.validate(scenario)
        scenario = copy.deepcopy(self.scenario)
        scenario['steps'].append({**valid, 'from_end': False, 'offset': 4})
        self.assertIs(run.validate(scenario), scenario)

    def test_pet_aura_fixture(self):
        self.scenario['steps'].append({'action': 'set_aura', 'actor': 'caster',
                                       'spell': 82888, 'stacks': 1, 'pet': True})
        self.assertIs(run.validate(self.scenario), self.scenario)
        self.scenario['steps'][-1]['pet'] = 'true'
        with self.assertRaises(ValueError):
            run.validate(self.scenario)

    def test_cancel_aura_requires_player_and_spell(self):
        self.scenario['steps'].append({'action': 'cancel_aura', 'actor': 'caster', 'spell': 802229})
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'actor': 'target'}, {'actor': 'absent'}, {'spell': 0}, {'spell': -802229},
                       {'spell': True}, {'spell': 802229.5}, {'pet': True}, {'target': 'caster'}, {'stacks': 0}):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][-1].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                run.validate(invalid)
        for field in ('actor', 'spell'):
            invalid = copy.deepcopy(self.scenario)
            del invalid['steps'][-1][field]
            with self.subTest(missing=field), self.assertRaises(ValueError):
                run.validate(invalid)

    def test_cancel_mount_requires_player(self):
        self.scenario['steps'].append({'action': 'cancel_mount', 'actor': 'caster'})
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'actor': 'target'}, {'actor': 'absent'}, {'spell': 801384}):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][-1].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                run.validate(invalid)

    def test_stunned_observation_accepts_units(self):
        for actor in ('caster', 'target'):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].append({'action': 'assert', 'actor': actor, 'metric': 'stunned', 'equals': 0})
            with self.subTest(actor=actor):
                self.assertIs(run.validate(scenario), scenario)

    def test_pet_spell_calculations(self):
        for metric in ('spell_effect_value', 'spell_damage_done'):
            with self.subTest(metric=metric):
                scenario = copy.deepcopy(self.scenario)
                scenario['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': metric,
                                          'spell': 116, 'target': 'target', 'pet': True, 'min': 0})
                self.assertIs(run.validate(scenario), scenario)
                for change in ({'pet': 1}, {'actor': 'target'}, {'critical': True}):
                    invalid = copy.deepcopy(scenario)
                    invalid['steps'][-1].update(change)
                    with self.assertRaises(ValueError):
                        run.validate(invalid)

    def test_flat_coefficient_modifier_query(self):
        self.scenario['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'spell_effect_value',
                                      'spell': 630874, 'flat_coefficient_modifier': 20, 'min': 0})
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'metric': 'spell_modifier', 'op': 24, 'base': 100}, {'pet': True},
                       {'actor': 'target'}, {'flat_coefficient_modifier': True},
                       {'flat_coefficient_modifier': 0.5}, {'flat_coefficient_modifier': 2**31}):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][-1].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                run.validate(invalid)

    def test_unlearn_all_specs_fixture(self):
        self.scenario['steps'].append({'action': 'unlearn', 'actor': 'caster',
                                       'spell': 116, 'all_specs': True})
        self.assertIs(run.validate(self.scenario), self.scenario)
        self.scenario['steps'][-1]['all_specs'] = 1
        with self.assertRaises(ValueError):
            run.validate(self.scenario)

    def test_healing_observation_targets(self):
        self.scenario['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'spell_heal_total',
                                       'spell': 997800, 'target': 'caster', 'target_pet': True, 'equals': 0})
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'target_pet': 1}, {'target': 'target'}, {'metric': 'health'}, {'actor': 'target'}):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'][-1].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_cast_at_current_pet(self):
        self.scenario['steps'].append({'action': 'cast', 'actor': 'caster', 'spell': 801707, 'target_pet': True})
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'target_pet': 1}, {'target': 'target'}, {'actor': 'target'}):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'][-1].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_pet_aura_amount_needs_spell(self):
        self.scenario['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'pet_aura_amount',
                                       'spell': 500939, 'effect': 1, 'equals': 5})
        self.assertIs(run.validate(self.scenario), self.scenario)
        del self.scenario['steps'][-1]['spell']
        with self.assertRaises(ValueError):
            run.validate(self.scenario)

    def test_pet_health_and_native_pvp(self):
        self.scenario['steps'].extend([
            {'action': 'set_health', 'actor': 'caster', 'value': 100, 'pet': True},
            {'action': 'pvp', 'actor': 'caster', 'enabled': True},
        ])
        self.assertIs(run.validate(self.scenario), self.scenario)
        self.scenario['steps'][-1]['enabled'] = 1
        with self.assertRaises(ValueError):
            run.validate(self.scenario)

    def test_explicit_health_maximum_and_spell_cooldown_fixtures(self):
        self.scenario['steps'].extend([
            {'action': 'set_health', 'actor': 'caster', 'value': 3500, 'maximum': 10000},
            {'action': 'reset_cooldown', 'actor': 'caster', 'spell': 116},
        ])
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'value': 10001}, {'maximum': 0}, {'maximum': True}, {'actor': 'target'}):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'][-2].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                run.validate(scenario)
        del self.scenario['steps'][-1]['spell']
        with self.assertRaises(ValueError):
            run.validate(self.scenario)

    def test_native_pet_attack(self):
        self.scenario['steps'].append({'action': 'attack', 'actor': 'caster',
                                       'target': 'target', 'pet': True})
        self.assertIs(run.validate(self.scenario), self.scenario)
        self.scenario['steps'][-1]['pet'] = 1
        with self.assertRaises(ValueError):
            run.validate(self.scenario)

    def test_pet_power_fixture_and_observation(self):
        self.scenario['steps'].extend([
            {'action': 'set_power', 'actor': 'caster', 'value': 0, 'power': 2, 'pet': True},
            {'action': 'assert', 'actor': 'caster', 'metric': 'pet_power', 'power': 2, 'equals': 0},
        ])
        self.assertIs(run.validate(self.scenario), self.scenario)
        for index, key, value in ((-2, 'pet', 1), (-1, 'actor', 'target'), (-1, 'power', 7)):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][index][key] = value
            with self.assertRaises(ValueError):
                run.validate(invalid)

    def test_energize_observation_filters(self):
        self.scenario['steps'].append({
            'action': 'assert', 'actor': 'caster', 'metric': 'spell_energize_total',
            'spell': 803348, 'power': 2, 'target': 'caster', 'target_pet': True, 'equals': 10,
        })
        self.assertIs(run.validate(self.scenario), self.scenario)
        for change in ({'critical': True}, {'pet': 1}, {'target_pet': 1}, {'spell': None},
                       {'target': 'target'}, {'actor': 'target'}, {'power': 7}):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][-1].update(change)
            with self.assertRaises(ValueError):
                run.validate(invalid)

    def test_periodic_calculation_queries(self):
        for metric in ('spell_damage_done', 'spell_healing_done'):
            scenario = copy.deepcopy(self.scenario)
            scenario['steps'].append({'action': 'snapshot', 'actor': 'caster', 'metric': metric,
                                      'spell': 116, 'target': 'target', 'periodic': True, 'save_as': 'tick'})
            self.assertIs(run.validate(scenario), scenario)
            for change in ({'periodic': 1}, {'metric': 'spell_damage_total'}):
                invalid = copy.deepcopy(scenario)
                invalid['steps'][-1].update(change)
                with self.assertRaises(ValueError):
                    run.validate(invalid)

    def test_movement_and_cast_observations(self):
        self.scenario['steps'].extend([
            {'action': 'set_moving', 'actor': 'caster', 'enabled': True},
            {'action': 'assert', 'actor': 'caster', 'metric': 'moving', 'equals': 1},
            {'action': 'assert', 'actor': 'target', 'metric': 'distance_2d', 'target': 'caster', 'min': 0},
            {'action': 'assert', 'actor': 'caster', 'metric': 'cast_remaining_ms', 'spell': 116, 'min': 0},
        ])
        self.assertIs(run.validate(self.scenario), self.scenario)
        for index, key, value in ((-4, 'enabled', 1), (-4, 'actor', 'target'),
                                   (-2, 'target', 'missing'), (-1, 'spell', None)):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][index][key] = value
            with self.assertRaises(ValueError):
                run.validate(invalid)

    def test_native_client_upload_actions(self):
        self.scenario['steps'].extend([
            {'action': 'specialization', 'actor': 'caster', 'id': 60},
            {'action': 'advancement_rank', 'actor': 'caster', 'entry': 34422, 'rank': 1, 'refused': True},
            {'action': 'apply_appearances', 'actor': 'caster', 'selection': {'56': 1451, '57': 0}},
        ])
        self.assertIs(run.validate(self.scenario), self.scenario)
        for index, key, value in ((-3, 'actor', 'target'), (-3, 'id', 0), (-2, 'rank', 4), (-2, 'actor', 'target'),
                                   (-2, 'refused', 1), (-1, 'selection', {'x': 1}), (-1, 'selection', {'0': 1}),
                                   (-1, 'selection', [1451]), (-1, 'actor', 'target')):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][index][key] = value
            with self.assertRaises(ValueError):
                run.validate(invalid)

    def test_cast_pushback_observation_requires_player(self):
        self.scenario['steps'].append(
            {'action': 'assert', 'actor': 'caster', 'metric': 'cast_pushback_ms', 'equals': 0})
        self.assertIs(run.validate(self.scenario), self.scenario)
        self.scenario['steps'][-1]['actor'] = 'target'
        with self.assertRaises(ValueError):
            run.validate(self.scenario)

    def test_pet_armor_and_melee_hand_observations(self):
        self.scenario['steps'].extend([
            {'action': 'stop_attack', 'actor': 'caster'},
            {'action': 'assert', 'actor': 'caster', 'metric': 'armor_reduced_damage',
             'pet': True, 'spell': 116, 'target': 'target', 'min': 0},
            {'action': 'assert', 'actor': 'caster', 'metric': 'melee_attack_count', 'hand': 0, 'min': 0},
            {'action': 'assert', 'actor': 'caster', 'metric': 'melee_damage_count', 'hand': 1, 'min': 0},
            {'action': 'assert', 'actor': 'caster', 'metric': 'forced_forward', 'equals': 0},
        ])
        self.assertIs(run.validate(self.scenario), self.scenario)
        for index, key, value in ((-5, 'actor', 'target'), (-4, 'pet', 1), (-3, 'hand', 2),
                                   (-2, 'hand', 2), (-2, 'actor', 'target')):
            invalid = copy.deepcopy(self.scenario)
            invalid['steps'][index][key] = value
            with self.assertRaises(ValueError):
                run.validate(invalid)

    def test_malformed_scenarios_fail_before_starting_processes(self):
        for change in (
            lambda s: s['steps'].append({'action': 'level_scaling_packet', 'actor': 'caster', 'value': 2}),
            lambda s: s['steps'].append({'action': 'level_scaling_packet', 'actor': 'target', 'value': 1}),
            lambda s: s['steps'].append({'action': 'client_packet', 'actor': 'caster', 'opcode': 618, 'early': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'sent_level', 'equals': 57}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target',
                                         'target': 'caster', 'metric': 'view_level', 'equals': 57}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'quest_xp', 'equals': 1}),
            lambda s: s.update(schema=True),
            lambda s: s['steps'].append({'action': 'use_gameobject', 'actor': 'caster'}),
            lambda s: s['steps'].append({'action': 'use_gameobject', 'actor': 'target', 'entry': 1903510}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'owned_gameobject_count', 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'gameobject_remaining_ms', 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target',
                                         'metric': 'owned_gameobject_count', 'entry': 1903510, 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target',
                                         'metric': 'at_homebind', 'equals': 0}),
            lambda s: s['steps'].append({'action': 'group', 'actor': 'caster', 'target': 'caster'}),
            lambda s: s['steps'].append({'action': 'group', 'actor': 'caster', 'target': 'target'}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'spell_immune', 'spell': 116, 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'spell_effect_immune', 'target': 'target', 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'aoe_damage_taken', 'school': 7, 'equals': 1000}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'reputation_gain', 'equals': 1000}),
            lambda s: s.update(timeout_ms=float('inf')),
            lambda s: s['players'][0].update(level=True),
            lambda s: s['steps'].append({'action': 'set_level', 'actor': 'caster', 'value': 0}),
            lambda s: s['steps'].append({'action': 'set_level', 'actor': 'caster', 'value': 81}),
            lambda s: s['steps'].append({'action': 'relog', 'actor': 'caster', 'race': 0}),
            lambda s: s['steps'].append({'action': 'relog', 'actor': 'caster', 'race': 256}),
            lambda s: s['steps'].append({'action': 'relog', 'actor': 'caster', 'race': True}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'spell_damage_done', 'spell': 686, 'equals': 1000}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'spell_damage_done', 'target': 'target', 'equals': 1000}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'melee_damage_done', 'target': 'missing', 'equals': 1000}),
            lambda s: s['players'][0].update(race=0),
            lambda s: s['players'][0].update(ranged_hit_rating=-1),
            lambda s: s['players'][0].update(melee_hit_rating=-1),
            lambda s: s['players'][0].update(melee_crit_rating=-1),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'spell_cast_count', 'equals': 1}),
            lambda s: s['players'][0].update(expertise_rating=True),
            lambda s: s['players'][0].update(allow_regeneration=0),
            lambda s: s['players'][0].update(spell_crit_rating=-1),
            lambda s: s['players'][0].update(ranged_crit_rating=-1),
            lambda s: s['steps'].append({'action': 'who', 'actor': 'caster', 'class_mask': 2**32}),
            lambda s: s['steps'].append({'action': 'who', 'actor': 'caster', 'target': 'target'}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'who_class', 'equals': 1}),
            lambda s: s['steps'].append({'action': 'open_item', 'actor': 'caster'}),
            lambda s: s['steps'].append({'action': 'prepare_quest', 'actor': 'caster', 'quest': 0}),
            lambda s: s['steps'].append({'action': 'reward_quest', 'actor': 'caster', 'quest': 1518, 'choice': 6}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'quest_rewarded', 'equals': 1}),
            lambda s: s['steps'].append({'action': 'login_hooks', 'actor': 'target'}),
            lambda s: s['steps'].append({'action': 'collect_loot', 'actor': 'target'}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'loot_count', 'equals': 1}),
            lambda s: s['creatures'][0].update(id='caster'),
            lambda s: s['steps'].append({'action': 'cast', 'actor': 'caster', 'spell': 116, 'target': 'missing'}),
            lambda s: s.update(location={'map': 33, 'x': 0, 'y': 0, 'z': 0, 'ignore_access': 1}),
            lambda s: s['steps'].append({'action': 'cast', 'actor': 'caster', 'spell': 502329,
                                         'destination': {'x': 0, 'y': 0}}),
            lambda s: s['steps'].append({'action': 'cast', 'actor': 'caster', 'spell': 502329,
                                         'destination': {'x': float('nan'), 'y': 0, 'z': 0}}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'dynamic_object',
                                         'spell': 502329, 'equals': 1}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'dynamic_object',
                                         'equals': 1}),
            lambda s: s['steps'].append({'action': 'cast', 'actor': 'target', 'spell': 10308, 'target': 'caster',
                                         'destination': {'x': 0, 'y': 0, 'z': 0}}),
            lambda s: s['steps'].append({'action': 'cast_charm', 'actor': 'target', 'spell': 802176}),
            lambda s: s['steps'].append({'action': 'gossip_hello', 'actor': 'caster', 'target': 'missing'}),
            lambda s: s['steps'].append({'action': 'attack', 'actor': 'caster'}),
            lambda s: s['steps'].append({'action': 'attack', 'actor': 'caster', 'target': 'missing'}),
            lambda s: s['steps'].append({'action': 'gossip_select', 'actor': 'caster', 'option': -1}),
            lambda s: s['steps'].append({'action': 'set_aura', 'actor': 'caster', 'spell': 803102, 'stacks': 256}),
            lambda s: s['steps'].append({'action': 'set_aura', 'actor': 'target', 'spell': 803102, 'stacks': 1}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'spell_power_cost',
                                         'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'health',
                                         'ratio_to': 'missing', 'equals': 1}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'gossip_options',
                                         'equals': 1}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'health', 'equlas': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'health',
                                         'equals': float('nan')}),
            lambda s: s['steps'].append({'action': 'set_power', 'actor': 'caster', 'value': 1, 'power': 7}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'pet_entry', 'equals': 0}),
            lambda s: s['steps'].append({'action': 'command', 'actor': 'target', 'command': '.manastorm enter 1'}),
            lambda s: s['steps'].append({'action': 'command', 'actor': 'caster', 'command': 'manastorm enter 1'}),
            lambda s: s['steps'].append({'action': 'command', 'actor': 'caster', 'command': '.a\n.b'}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'charm_entry', 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'charm_aura_stacks',
                                         'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'pet_aura_stacks',
                                         'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'owned_creature_count',
                                         'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'target', 'metric': 'owned_creature_count',
                                         'entry': 36, 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster', 'metric': 'owned_creature_count',
                                         'entry': 36, 'caster': 'caster', 'equals': 0}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'owned_creature_weapon_damage_min', 'min': 1}),
            lambda s: s['steps'].append({'action': 'assert', 'actor': 'caster',
                                         'metric': 'owned_creature_spacing', 'min': 1}),
            lambda s: s.update(steps=[{'action': 'wait', 'ms': 1}]),
            lambda s: s['steps'].insert(0, {'action': 'assert', 'actor': 'target', 'metric': 'health',
                                           'relative_to': 'missing', 'equals': 0}),
        ):
            scenario = copy.deepcopy(self.scenario)
            change(scenario)
            with self.subTest(scenario=scenario), self.assertRaises(ValueError):
                run.validate(scenario)

    def test_duplicate_json_keys_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            json.loads('{"schema": 1, "schema": 2}', object_pairs_hook=run.unique_object)

    def test_result_is_rechecked_against_expected_values(self):
        report = self.report()
        assertion = next(i for i, step in enumerate(self.scenario['steps']) if step['action'] == 'assert')
        run.check_report(report, report['run_id'], self.scenario, 0)
        mutations = [
            lambda r: r.update(schema='2'),
            lambda r: r.update(run_id='different'),
            lambda r: r.update(assertions='0'),
            lambda r: r.update(completed_steps='1'),
            lambda r: r['steps'].pop(),
            lambda r: r['steps'][assertion].update(actual='1'),
            lambda r: r['steps'][assertion].update(actual='nan'),
            lambda r: r['steps'][assertion].update(status='failed'),
            lambda r: r['steps'][assertion].update(index='99'),
            lambda r: r['steps'][0].update(status='failed'),
        ]
        for mutate in mutations:
            candidate = copy.deepcopy(report)
            mutate(candidate)
            with self.subTest(report=candidate), self.assertRaises(ValueError):
                run.check_report(candidate, report['run_id'], self.scenario, 0)
        with self.assertRaises(ValueError):
            run.check_report(report, report['run_id'], self.scenario, 1)

    def test_only_local_valid_database_names_are_accepted(self):
        connection = run.Connection.parse('127.0.0.1;3306;user;secret;acore_world')
        self.assertEqual(connection.database, 'acore_world')
        for text in ('external.example;3306;u;p;world', 'localhost;3306;u;p;world`; DROP DATABASE auth;',
                     'localhost;0;u;p;world', 'localhost;3306;u;p;world-name'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                run.Connection.parse(text)

    def database(self, directory):
        connections = {role: run.Connection('127.0.0.1', 3306, 'user', 'secret', f'source_{role}')
                       for role in ('auth', 'characters', 'world')}
        return run.Databases('mysql', 'mysqldump', directory, connections, '012345abcdef')

    def test_admin_credentials_preserve_source_endpoint_and_schema(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'admin.ini'
            original = '[client]\nhost=127.0.0.1\nport=3306\nuser=root\npassword="literal%secret\\svalue"\n'
            path.write_text(original)
            sources = {'world': run.Connection('127.0.0.1', 3306, 'user', 'old', 'acore_world')}
            result = run.database_credentials(sources, path)['world']
            self.assertEqual(result.database, 'acore_world')
            self.assertEqual(result.host, '127.0.0.1')
            self.assertEqual(result.user, 'root')
            self.assertEqual(result.password, 'literal%secret value')
            self.assertEqual(path.read_text(), original)
            self.assertEqual(sources['world'].user, 'user')
            path.write_text(original.replace('3306', '3307'))
            with self.assertRaisesRegex(ValueError, 'endpoint must match'):
                run.database_credentials(sources, path)
            path.write_text('[client]\npassword=secret\nnot-valid secret\n')
            with self.assertRaisesRegex(ValueError, '^Invalid database client config$'):
                run.database_credentials(sources, path)

    def test_partial_clone_only_drops_databases_created_by_this_run(self):
        with tempfile.TemporaryDirectory() as temporary:
            database = self.database(Path(temporary))
            statements = []
            with patch.object(database, 'sql', side_effect=lambda role, sql: statements.append(sql)), \
                    patch.object(database, 'copy', side_effect=ValueError('copy failed')):
                with self.assertRaisesRegex(ValueError, 'copy failed'):
                    database.prepare()
                self.assertEqual(database.cleanup(), [])
            self.assertEqual(database.created, ['auth'])
            self.assertEqual(len(statements), 2)
            self.assertEqual(statements[-1], 'DROP DATABASE `coa_test_012345abcdef_auth`;')
            self.assertNotIn('source_', '\n'.join(statements))
            database.remove_credentials()
            self.assertFalse(any(Path(temporary).glob('*.cnf')))

    def test_existing_database_is_never_adopted_or_dropped(self):
        with tempfile.TemporaryDirectory() as temporary:
            database = self.database(Path(temporary))
            with patch.object(database, 'sql', side_effect=ValueError('exists')) as execute:
                with self.assertRaises(ValueError):
                    database.prepare()
                self.assertEqual(database.cleanup(), [])
                self.assertEqual(execute.call_count, 1)
            self.assertEqual(database.created, [])

    def test_database_diagnostics_do_not_expose_credentials(self):
        with tempfile.TemporaryDirectory() as temporary:
            database = self.database(Path(temporary))
            result = SimpleNamespace(returncode=1, stderr='ERROR 1045 password=secret', stdout='')
            with patch.object(run.subprocess, 'run', return_value=result), self.assertRaises(ValueError) as raised:
                database.sql('auth', 'SELECT 1;')
            self.assertIn('1045', str(raised.exception))
            self.assertNotIn('secret', str(raised.exception))
            self.assertNotIn('secret', repr(database.connections['auth']))

    def test_configuration_override_removes_old_values_without_editing_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / 'source.conf'
            output = Path(temporary) / 'test.conf'
            original = '[worldserver]\nBindIP = "0.0.0.0"\nBindIP = "::"\nDataDir = "C:/data"\n'
            source.write_text(original)
            run.write_config(source, output, {'BindIP': '127.0.0.1'})
            self.assertEqual(source.read_text(), original)
            self.assertEqual(output.read_text().count('BindIP'), 1)
            self.assertEqual(run.read_config(output)['BindIP'], '127.0.0.1')

    def test_module_settings_are_copied_and_cannot_override_isolation(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = directory / 'modules'
            source.mkdir()
            config = source / 'module.conf'
            config.write_text('CoA.Enable = 1\n')
            staged = run.stage_modules(source, directory / 'run' / 'configs' / 'modules', {'BindIP'})
            self.assertEqual(staged[0].read_bytes(), config.read_bytes())
            config.write_text('BindIP = "0.0.0.0"\n')
            with self.assertRaisesRegex(ValueError, 'overrides harness'):
                run.stage_modules(source, directory / 'other-run' / 'configs' / 'modules', {'BindIP'})
            self.assertFalse((directory / 'other-run').exists())

    def fake_process(self, code, startup_timeout=3, environment=None):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            script = directory / 'fake_server.py'
            script.write_text('from pathlib import Path\nimport json, sys, time\n' + code, encoding='utf-8')
            return run.run_process([sys.executable, str(script)], directory, directory / 'ready.json',
                                   directory / 'result.json', '012345abcdef', startup_timeout, 3,
                                   environment=environment)

    def test_zero_exit_without_result_is_a_failure(self):
        with self.assertRaisesRegex(ValueError, 'without a result'):
            self.fake_process('sys.exit(0)\n')

    def test_readiness_timeout_stops_owned_child(self):
        with self.assertRaisesRegex(ValueError, 'readiness timed out'):
            self.fake_process('sys.stdin.readline()\n', startup_timeout=0.15)

    def test_wrong_run_readiness_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Invalid readiness'):
            self.fake_process('Path("ready.json").write_text(json.dumps({"status":"ready","run_id":"other"}))\n'
                              'sys.stdin.readline()\n')

    def test_matching_completed_process_returns_its_report(self):
        report = self.report()
        result, returncode = self.fake_process(
            'Path("ready.json").write_text(json.dumps({"status":"ready","run_id":"012345abcdef"}))\n'
            f'Path("result.json").write_text({json.dumps(json.dumps(report))})\n')
        run.check_report(result, '012345abcdef', self.scenario, returncode)

    def test_success_without_readiness_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'missing harness readiness'):
            self.fake_process(f'Path("result.json").write_text({json.dumps(json.dumps(self.report()))})\n')

    def test_environment_names_follow_server_conversion(self):
        for key, name in {
                'SomeConfig': 'AC_SOME_CONFIG', 'myNestedConfig.opt1': 'AC_MY_NESTED_CONFIG_OPT_1',
                'LogDB.Opt.ClearTime': 'AC_LOG_DB_OPT_CLEAR_TIME', 'DataDir': 'AC_DATA_DIR',
                'LoginDatabaseInfo': 'AC_LOGIN_DATABASE_INFO',
                'Updates.EnableDatabases': 'AC_UPDATES_ENABLE_DATABASES'}.items():
            self.assertEqual(run.env_var_name(key), name)

    def test_generated_values_are_not_replaced_by_inherited_environment(self):
        inherited = {'AC_UPDATES_ENABLE_DATABASES': '0', 'AC_LOGS_DIR': '/live/logs',
                     'AC_ASCENSION_MANASTORM_ENABLE': '1', 'PATH': '/usr/bin'}
        environment = run.server_environment({'Updates.EnableDatabases': 7, 'LogsDir': '/run'}, inherited)
        self.assertEqual(environment, {'AC_ASCENSION_MANASTORM_ENABLE': '1', 'PATH': '/usr/bin'})

    def test_source_settings_follow_server_environment_precedence(self):
        config = {'DataDir': '.'}
        self.assertEqual(run.source_setting(config, 'DataDir', '.', {'AC_DATA_DIR': '/data'}), '/data')
        self.assertEqual(run.source_setting(config, 'DataDir', None, {}), '.')
        self.assertEqual(run.source_setting({}, 'DataDir', '.', {}), '.')
        with self.assertRaisesRegex(ValueError, 'Missing source setting'):
            run.source_setting({}, 'LoginDatabaseInfo', None, {})

    def test_server_process_uses_supplied_environment(self):
        report = self.report()
        with patch.dict(run.os.environ, {'AC_UPDATES_ENABLE_DATABASES': '0'}):
            result, returncode = self.fake_process(
                'import os\n'
                'if "AC_UPDATES_ENABLE_DATABASES" not in os.environ:\n'
                '    Path("ready.json").write_text(json.dumps({"status":"ready","run_id":"012345abcdef"}))\n'
                f'    Path("result.json").write_text({json.dumps(json.dumps(report))})\n',
                environment=run.server_environment({'Updates.EnableDatabases': 7}))
        run.check_report(result, '012345abcdef', self.scenario, returncode)

    def test_module_configs_never_replace_server_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = directory / 'source'
            target = directory / 'server-modules'
            source.mkdir()
            target.mkdir()
            (source / 'a.conf').write_text('A.Enable = 1\n')
            (source / 'b.conf').write_text('B.Enable = 1\n')
            (target / 'b.conf').write_text('B.Enable = 0\n')
            with self.assertRaises(FileExistsError):
                run.stage_modules(source, target, {'BindIP'})
            self.assertFalse((target / 'a.conf').exists())
            self.assertEqual((target / 'b.conf').read_text(), 'B.Enable = 0\n')

    def test_existing_destination_configs_cannot_override_isolation(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = directory / 'modules'
            source.mkdir()
            (source / 'module.conf').write_text('CoA.Enable = 1\n')
            destination = directory / 'server-modules'
            destination.mkdir()
            (destination / 'other.conf').write_text('WorldDatabaseInfo = "0;0;u;p;d"\n')
            with self.assertRaisesRegex(ValueError, 'overrides harness controls: other.conf'):
                run.stage_modules(source, destination, {'WorldDatabaseInfo'})
            self.assertFalse((destination / 'module.conf').exists())

    def test_untracked_destination_configs_cannot_change_gameplay(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = directory / 'modules'
            source.mkdir()
            destination = directory / 'server-modules'
            destination.mkdir()
            existing = destination / 'extra.conf'
            existing.write_text('Rate.XP.Kill = 5\n')
            with self.assertRaisesRegex(ValueError, 'Unexpected server module config: extra.conf'):
                run.stage_modules(source, destination, {'WorldDatabaseInfo'})
            self.assertEqual(existing.read_text(), 'Rate.XP.Kill = 5\n')

    @unittest.skipIf(run.os.name == 'nt', 'Windows reads module configs relative to the working directory')
    def test_server_module_directory_is_required_outside_windows(self):
        scenario = str(Path(__file__).parent / 'scenarios' / 'frostbolt.json')
        arguments = ['run', scenario, '--worldserver', 'w', '--config', 'c', '--mysql', 'm', '--mysqldump', 'd']
        with patch('sys.stderr', new_callable=io.StringIO) as errors, patch.object(run, 'execute') as execute:
            code = run.main(arguments)
        self.assertEqual(code, 1)
        self.assertIn('--server-modules-dir', errors.getvalue())
        execute.assert_not_called()

    def test_execute_keeps_credentials_out_of_the_result_directory(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            worldserver = directory / 'worldserver'
            worldserver.write_bytes(b'binary')
            config = directory / 'worldserver.conf'
            config.write_text(
                'LoginDatabaseInfo = "127.0.0.1;3306;user;secret-password;source_auth"\n'
                'CharacterDatabaseInfo = "127.0.0.1;3306;user;secret-password;source_characters"\n'
                'WorldDatabaseInfo = "127.0.0.1;3306;user;secret-password;source_world"\n'
                'CharacterDatabase.WorkerThreads = 4\nCharacterDatabase.TransactionIsolation = "READ-COMMITTED"\n'
                'LoginDatabase.TransactionIsolation = "SERIALIZABLE"\n'
                'WorldDatabase.TransactionIsolation = "READ-UNCOMMITTED"\n')
            mysql = directory / 'mysql'
            mysql.write_bytes(b'')
            mysqldump = directory / 'mysqldump'
            mysqldump.write_bytes(b'')
            (directory / 'modules').mkdir()
            output = directory / 'output'
            args = SimpleNamespace(
                worldserver=worldserver, config=config, mysql=mysql, mysqldump=mysqldump,
                database_client_config=None, modules_config_dir=None,
                server_modules_dir=directory / 'server-modules', output=output, startup_timeout=3,
                fresh_databases=True, refresh_world=False, world_cache_dir=directory / 'cache')
            report = self.report()
            credential_dirs = []
            server_settings = []
            real_mkdtemp = tempfile.mkdtemp

            def recording_mkdtemp(*a, **kw):
                path = real_mkdtemp(*a, **kw)
                credential_dirs.append(Path(path))
                return path

            def recording_process(command, *a, **kw):
                server_settings.append(run.read_config(Path(command[-1])))
                return report, 0

            with patch.object(run.tempfile, 'mkdtemp', side_effect=recording_mkdtemp), \
                    patch.object(run.secrets, 'token_hex', return_value='012345abcdef'), \
                    patch.object(run.Databases, 'prepare', lambda self, **kw: None), \
                    patch.object(run.Databases, 'cleanup', lambda self: []), \
                    patch.object(run, 'run_process', side_effect=recording_process):
                code = run.execute(args, self.scenario)
            self.assertEqual(code, 0)
            self.assertEqual(len(credential_dirs), 1)
            self.assertEqual(server_settings[0]['TempDir'], credential_dirs[0].as_posix())
            self.assertEqual({name: server_settings[0][f'CoAGameplayTest.{name}'] for name in run.CLOCK_SETTINGS},
                             {'Clock': 'real', 'Lanes': '1', 'StepMs': '3', 'ActiveWaitCapMs': '25',
                              'PollCapMs': '10', 'StartHour': '10'})
            self.assertEqual(server_settings[0]['CoAGameplayTest.CaseDirectory'], '')
            self.assertEqual({key: server_settings[0][key] for key in (
                'LoginDatabase.WorkerThreads', 'CharacterDatabase.WorkerThreads', 'LoginDatabase.TransactionIsolation',
                'CharacterDatabase.TransactionIsolation', 'WorldDatabase.TransactionIsolation')}, {
                'LoginDatabase.WorkerThreads': '1', 'CharacterDatabase.WorkerThreads': '1',
                'LoginDatabase.TransactionIsolation': '', 'CharacterDatabase.TransactionIsolation': '',
                'WorldDatabase.TransactionIsolation': ''})
            self.assertFalse(credential_dirs[0].exists())
            self.assertFalse((output / 'worldserver.conf').exists())
            self.assertFalse(any(output.glob('*-client.cnf')))
            for path in output.rglob('*'):
                if path.is_file():
                    self.assertNotIn('secret-password', path.read_text(encoding='utf-8', errors='replace'))

    def test_execute_gives_only_an_hour_scenario_a_fixed_offset(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / 'worldserver').write_bytes(b'binary')
            config = directory / 'worldserver.conf'
            config.write_text(''.join(f'{key} = "127.0.0.1;3306;user;secret;source_{role}"\n'
                                      for role, key in run.DATABASE_SETTINGS.items()))
            for tool in ('mysql', 'mysqldump'):
                (directory / tool).write_bytes(b'')
            (directory / 'modules').mkdir()
            observed = []

            def recording_process(command, *a, **kw):
                observed.append(kw['environment'])
                return {**self.report(), 'realm_local_start': '2026-09-25 12:34:56'}, 0

            with patch.object(run.Databases, 'prepare', lambda self, **kw: None), \
                    patch.object(run.Databases, 'cleanup', lambda self: []), \
                    patch.object(run, 'run_process', side_effect=recording_process), \
                    patch.object(run.secrets, 'token_hex', return_value='012345abcdef'), \
                    patch.object(run, 'utc_now', return_value=datetime(2026, 9, 24, 22, 40, tzinfo=timezone.utc)), \
                    patch.dict(run.os.environ, {'TZ': 'Europe/Moscow'}):
                for name, scenario in (('noon', {**self.scenario, 'hour': 12}), ('plain', self.scenario)):
                    args = SimpleNamespace(
                        worldserver=directory / 'worldserver', config=config, mysql=directory / 'mysql',
                        mysqldump=directory / 'mysqldump', database_client_config=None, modules_config_dir=None,
                        server_modules_dir=directory / name / 'modules', output=directory / name,
                        startup_timeout=3, fresh_databases=True, refresh_world=False,
                        world_cache_dir=directory / 'cache')
                    self.assertEqual(run.execute(args, scenario), 0)
            self.assertEqual([environment['TZ'] for environment in observed], ['UTC+10:40', 'Europe/Moscow'])
            summaries = [run.read_json(directory / name / 'summary.json') for name in ('noon', 'plain')]
            self.assertEqual([summary.get('timezone') for summary in summaries], ['UTC+10:40', None])
            self.assertEqual({summary['realm_local_start'] for summary in summaries}, {'2026-09-25 12:34:56'})

    @unittest.skipUnless(hasattr(run.signal, 'SIGTERM'), 'SIGTERM is not available on this platform')
    def test_sigterm_handler_raises_and_previous_handler_is_restored(self):
        scenario = str(Path(__file__).parent / 'scenarios' / 'frostbolt.json')
        arguments = ['run', scenario, '--worldserver', 'w', '--config', 'c', '--mysql', 'm', '--mysqldump', 'd',
                     '--server-modules-dir', 'sm']
        previous_handler = run.signal.getsignal(run.signal.SIGTERM)
        installed_handlers = []

        def fake_execute(args, scenario):
            installed_handlers.append(run.signal.getsignal(run.signal.SIGTERM))
            return 0

        with patch.object(run, 'execute', side_effect=fake_execute), \
                patch('workflow.run_registered', side_effect=lambda args, scenario, execute: execute(args, scenario)):
            code = run.main(arguments)
        self.assertEqual(code, 0)
        self.assertEqual(len(installed_handlers), 1)
        self.assertIsNot(installed_handlers[0], previous_handler)
        with self.assertRaises(KeyboardInterrupt):
            installed_handlers[0](run.signal.SIGTERM, None)
        self.assertEqual(run.signal.getsignal(run.signal.SIGTERM), previous_handler)

    def test_ready_callback_releases_waiting_child_before_scenario(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            script = directory / 'fake_server.py'
            script.write_text(
                'from pathlib import Path\nimport os, time\n'
                'assert "AC_UPDATES_ENABLE_DATABASES" not in os.environ\n'
                'Path("ready.json").write_text(\'{"status":"ready","run_id":"012345abcdef"}\')\n'
                'while not Path("start.json").exists():\n    time.sleep(0.01)\n'
                f'Path("result.json").write_text({json.dumps(json.dumps(self.report()))})\n', encoding='utf-8')
            observed = []

            def release(record):
                self.assertFalse((directory / 'result.json').exists())
                observed.append(record['run_id'])
                (directory / 'start.json').write_text('{}')

            with patch.dict(run.os.environ, {'AC_UPDATES_ENABLE_DATABASES': '0'}):
                report, returncode = run.run_process(
                    [sys.executable, str(script)], directory, directory / 'ready.json', directory / 'result.json',
                    '012345abcdef', 3, 3, on_ready=release,
                    environment=run.server_environment({'Updates.EnableDatabases': 7}))
            run.check_report(report, '012345abcdef', self.scenario, returncode)
            self.assertEqual(observed, ['012345abcdef'])


if __name__ == '__main__':
    unittest.main()
