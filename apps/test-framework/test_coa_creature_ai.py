"""Synthetic regression tests for conservative creature SmartAI cloning."""

from copy import deepcopy
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))

from coa_creature_ai import prepare_ai_tables, transform_ai  # noqa: E402


DONOR = 100
TARGET = 200


def smart(owner=DONOR, source=0, row_id=0, **changes):
    row = {
        'entryorguid': owner, 'source_type': source, 'id': row_id, 'link': 0,
        'event_type': 0, 'event_phase_mask': 0, 'event_chance': 100, 'event_flags': 0,
        **{f'event_param{i}': 0 for i in range(1, 7)},
        'action_type': 11,
        **{f'action_param{i}': 0 for i in range(1, 7)},
        'target_type': 1,
        **{f'target_param{i}': 0 for i in range(1, 5)},
        'target_x': 0.0, 'target_y': 0.0, 'target_z': 0.0, 'target_o': 0.0,
        'comment': 'synthetic SmartAI row',
    }
    row.update(changes)
    return row


def condition(owner=DONOR, source=0, group=1, **changes):
    row = {
        'SourceTypeOrReferenceId': 22, 'SourceGroup': group,
        'SourceEntry': owner, 'SourceId': source, 'ElseGroup': 0,
        'ConditionTypeOrReference': 1, 'ConditionTarget': 0,
        'ConditionValue1': 0, 'ConditionValue2': 0, 'ConditionValue3': 0,
        'NegativeCondition': 0, 'ErrorType': 0, 'ErrorTextId': 0,
        'ScriptName': '', 'Comment': 'synthetic SmartAI condition',
    }
    row.update(changes)
    return row


def text(group=7):
    return {
        'CreatureID': DONOR, 'GroupID': group, 'ID': 0,
        'Text': 'Synthetic dialogue', 'Type': 12, 'Language': 0,
        'Probability': 100.0, 'Emote': 0, 'Duration': 0,
        'Sound': 0, 'SoundPlayType': 0, 'BroadcastTextId': 0,
        'TextRange': 0, 'Comment': 'synthetic creature_text',
    }


def tables(*rows, conditions=(), creature_text=()):
    return {
        'smart_scripts': list(rows),
        'conditions': list(conditions),
        'creature_text': list(creature_text),
    }


class CreatureSmartAI(unittest.TestCase):

    def test_dependency_closure_remaps_tal_dialogue_conditions_and_links(self):
        source = tables(
            smart(row_id=0, link=1, action_type=80, action_param1=500),
            smart(row_id=1, event_type=61, action_type=1, action_param1=7),
            smart(owner=500, source=9, row_id=0, action_type=1, action_param1=7),
            conditions=(
                condition(group=1),
                condition(group=2),
                condition(owner=500, source=9, group=1),
            ),
            creature_text=(text(),),
        )
        original = deepcopy(source)

        result = transform_ai(DONOR, TARGET, prepare_ai_tables(source), 900)

        self.assertEqual([], result['blocked'])
        self.assertEqual(901, result['next_tal_id'])
        output = result['tables']
        self.assertEqual(3, len(output['smart_scripts']))
        main = [r for r in output['smart_scripts'] if r['source_type'] == 0]
        timed = [r for r in output['smart_scripts'] if r['source_type'] == 9]
        self.assertEqual({TARGET}, {r['entryorguid'] for r in main})
        self.assertEqual({900}, {r['entryorguid'] for r in timed})
        self.assertEqual(900, next(r for r in main if r['action_type'] == 80)['action_param1'])
        self.assertEqual([(TARGET, 7, 0)], [
            (r['CreatureID'], r['GroupID'], r['ID']) for r in output['creature_text']
        ])
        self.assertEqual({(TARGET, 0, 1), (TARGET, 0, 2), (900, 9, 1)}, {
            (r['SourceEntry'], r['SourceId'], r['SourceGroup'])
            for r in output['conditions']
        })
        self.assertEqual(original, source, 'transform must not mutate exported input rows')

    def test_condition_source_group_is_smart_id_plus_one(self):
        source = tables(
            smart(row_id=4),
            conditions=(condition(group=4), condition(group=5)),
        )

        result = transform_ai(DONOR, TARGET, source, 900)

        self.assertEqual([], result['blocked'])
        self.assertEqual([(TARGET, 0, 5)], [
            (r['SourceEntry'], r['SourceId'], r['SourceGroup'])
            for r in result['tables']['conditions']
        ])

    def test_missing_template_smart_rows_is_blocking(self):
        result = transform_ai(DONOR, TARGET, tables(), 900)

        self.assertTrue(result['blocked'])
        self.assertEqual([], result['tables']['smart_scripts'])

    def test_quest_and_spawn_context_conditions_are_blocking(self):
        for condition_type in (9, 29):
            with self.subTest(condition_type=condition_type):
                source = tables(
                    smart(),
                    conditions=(condition(ConditionTypeOrReference=condition_type),),
                )

                result = transform_ai(DONOR, TARGET, source, 900)

                self.assertTrue(result['blocked'])
                self.assertEqual([], result['tables']['conditions'])

    def test_unsafe_row_withholds_complete_block(self):
        source = tables(
            smart(row_id=0),
            smart(row_id=1, target_type=10, target_param1=12345),
        )

        result = transform_ai(DONOR, TARGET, source, 900)

        self.assertIn('context_target', {item['code'] for item in result['blocked']})
        self.assertEqual({'smart_scripts': [], 'conditions': [], 'creature_text': []}, result['tables'])
        self.assertEqual(900, result['next_tal_id'])

    def test_broken_link_withholds_complete_block(self):
        result = transform_ai(DONOR, TARGET, tables(smart(link=77)), 900)

        self.assertIn('broken_smart_link', {item['code'] for item in result['blocked']})
        self.assertEqual([], result['tables']['smart_scripts'])

    def test_existing_target_and_allocated_tal_collisions_are_blocking(self):
        source = tables(
            smart(action_type=80, action_param1=500),
            smart(owner=500, source=9),
            smart(owner=TARGET),
            smart(owner=900, source=9),
        )

        result = transform_ai(DONOR, TARGET, source, 900)

        codes = {item['code'] for item in result['blocked']}
        self.assertIn('target_smart_collision', codes)
        self.assertIn('timed_action_list_collision', codes)
        self.assertEqual([], result['tables']['smart_scripts'])

    def test_npc_flag_actions_are_blocked_without_service_closure(self):
        for action_type in (81, 82, 83):
            with self.subTest(action_type=action_type):
                result = transform_ai(
                    DONOR, TARGET, tables(smart(action_type=action_type, action_param1=1)), 900,
                )

                self.assertIn('context_action', {item['code'] for item in result['blocked']})
                self.assertEqual([], result['tables']['smart_scripts'])

    def test_cross_cast_embedded_target_selector_is_blocked(self):
        source = tables(smart(
            action_type=86, action_param1=123, action_param2=10,
            action_param3=456, target_type=1,
        ))

        result = transform_ai(DONOR, TARGET, source, 900)

        self.assertIn('context_action', {item['code'] for item in result['blocked']})
        self.assertEqual([], result['tables']['smart_scripts'])

    def test_large_self_coordinates_do_not_bypass_position_filter(self):
        source = tables(smart(target_type=1, target_x=201.0))

        result = transform_ai(DONOR, TARGET, source, 900)

        self.assertIn('implicit_absolute_position', {item['code'] for item in result['blocked']})
        self.assertEqual([], result['tables']['smart_scripts'])


if __name__ == '__main__':
    unittest.main()
