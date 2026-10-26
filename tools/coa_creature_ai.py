"""Conservative SmartAI cloning for reconstructed creature templates.

The transformer copies a complete template-level SmartAI block or nothing. It
supports local combat behavior, own dialogue, SourceType 22 conditions, and
self-targeted timed action lists. World-, spawn-, path-, instance-, quest-,
gossip-, equipment-, and GUID-bound behavior is rejected for manual review.
"""

from collections import defaultdict
from copy import deepcopy
import math


SMART_COLUMNS = (
    'entryorguid', 'source_type', 'id', 'link', 'event_type',
    'event_phase_mask', 'event_chance', 'event_flags',
    *(f'event_param{i}' for i in range(1, 7)), 'action_type',
    *(f'action_param{i}' for i in range(1, 7)), 'target_type',
    *(f'target_param{i}' for i in range(1, 5)),
    'target_x', 'target_y', 'target_z', 'target_o', 'comment',
)
SMART_INTEGER_COLUMNS = SMART_COLUMNS[:26]
CONDITION_KEY = (
    'SourceTypeOrReferenceId', 'SourceGroup', 'SourceEntry', 'SourceId',
    'ElseGroup', 'ConditionTypeOrReference', 'ConditionTarget',
    'ConditionValue1', 'ConditionValue2', 'ConditionValue3',
)
CONDITION_COLUMNS = CONDITION_KEY + (
    'NegativeCondition', 'ErrorType', 'ErrorTextId', 'ScriptName', 'Comment',
)
TEXT_KEY = ('CreatureID', 'GroupID', 'ID')

# Events whose meaning is local to the creature, its combat, or its own
# summons. Context-bearing events are withheld until the creature has a home.
SAFE_EVENTS = (
    set(range(0, 11)) | set(range(12, 19)) |
    {21, 22, 23, 24, 25, 26, 29, 30, 31, 32, 33, 35, 36, 37,
     38, 52, 53, 54, 59, 60, 61, 63, 66, 67, 74, 77, 82, 101,
     102, 105, 106, 107, 110}
)

# This is deliberately an allowlist. Missing actions are coupled to quests,
# world state, paths, spawns, gossip, equipment, or unsupported core behavior.
SAFE_ACTIONS = {
    1, 2, 3, 4, 5, 8, 10, 11, 12, 13, 14, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 27, 28, 30, 31, 37, 39, 40, 42, 43, 44, 45,
    46, 47, 48, 49, 51, 58, 59, 60, 61, 63, 64, 66, 67, 72, 73,
    74, 75, 79, 80, 84, 85, 89, 90, 91, 92, 94,
    95, 96, 100, 101, 102, 103, 108, 109, 110, 114, 115, 116,
    121, 122, 123, 125, 134, 136, 142, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 216, 217, 218, 219, 220, 223,
    224, 225, 227, 228, 238, 239, 242,
}
SAFE_TARGETS = {
    0, 1, 2, 3, 4, 5, 6, 7, 12, 16, 17, 18, 21, 22, 23, 24,
    25, 26, 28, 201, 202, 203, 204,
}
PLAYER_TARGETS = {16, 17, 18, 21, 201, 203}
SUMMON_ACTIONS = {12, 219, 228}
SELF_TEMPLATE_ACTIONS = {3, 36, 43}
SUMMON_EVENTS = {17, 35, 82, 107}


def _is_int(value):
    return type(value) is int


def _notice(collection, code, message, row=None):
    notice = {'code': code, 'message': message}
    if row is not None:
        notice['row'] = {
            key: row.get(key) for key in
            ('entryorguid', 'source_type', 'id', 'link', 'event_type',
             'action_type', 'target_type')
        }
    collection.append(notice)


def prepare_ai_tables(tables):
    """Build reusable indexes for repeated ``transform_ai`` calls."""
    if not isinstance(tables, dict):
        raise ValueError('tables must be a dictionary of exported row lists')
    required = ('smart_scripts', 'conditions', 'creature_text')
    for name in required:
        if name not in tables or not isinstance(tables[name], list):
            raise ValueError(f'tables[{name!r}] must be an exported row list')

    smart = defaultdict(list)
    conditions = defaultdict(list)
    text = defaultdict(list)
    errors = []
    for row in tables['smart_scripts']:
        if not isinstance(row, dict) or not _is_int(row.get('entryorguid')) or not _is_int(row.get('source_type')):
            errors.append('smart_scripts contains a row with an invalid key')
            continue
        smart[(row['entryorguid'], row['source_type'])].append(row)
    for row in tables['conditions']:
        if not isinstance(row, dict):
            errors.append('conditions contains a non-object row')
            continue
        if row.get('SourceTypeOrReferenceId') != 22:
            continue
        key = (row.get('SourceEntry'), row.get('SourceId'), row.get('SourceGroup'))
        if not all(_is_int(value) for value in key):
            errors.append('conditions contains a SourceType 22 row with an invalid key')
            continue
        conditions[key].append(row)
    for row in tables['creature_text']:
        if not isinstance(row, dict):
            errors.append('creature_text contains a non-object row')
            continue
        key = (row.get('CreatureID'), row.get('GroupID'))
        if not all(_is_int(value) for value in key):
            errors.append('creature_text contains a row with an invalid key')
            continue
        text[key].append(row)
    return {
        '_coa_ai_prepared': True,
        'rows': tables,
        'smart': smart,
        'conditions': conditions,
        'text': text,
        'errors': errors,
    }


def _validate_smart(row, blocked):
    missing = [column for column in SMART_COLUMNS if column not in row]
    if missing:
        _notice(blocked, 'malformed_smart_row',
                'SmartAI row is missing columns: ' + ', '.join(missing), row)
        return False
    bad_ints = [column for column in SMART_INTEGER_COLUMNS if not _is_int(row[column])]
    if bad_ints:
        _notice(blocked, 'malformed_smart_row',
                'SmartAI integer columns have invalid types: ' + ', '.join(bad_ints), row)
        return False
    unsigned = SMART_INTEGER_COLUMNS[2:]
    if any(row[column] < 0 or row[column] > 4294967295 for column in unsigned):
        _notice(blocked, 'malformed_smart_row',
                'SmartAI identifiers or parameters are outside unsigned integer range', row)
        return False
    if row['entryorguid'] == 0 or not -2147483648 <= row['entryorguid'] <= 2147483647:
        _notice(blocked, 'malformed_smart_row', 'SmartAI entryorguid is outside signed integer range', row)
        return False
    if row['id'] > 65535 or row['link'] > 65535 or not 0 <= row['event_chance'] <= 100:
        _notice(blocked, 'malformed_smart_row',
                'SmartAI id, link, or event chance is outside its schema range', row)
        return False
    for column in ('target_x', 'target_y', 'target_z', 'target_o'):
        value = row[column]
        if type(value) not in (int, float) or not math.isfinite(value):
            _notice(blocked, 'malformed_smart_row',
                    f'SmartAI coordinate {column} is not finite', row)
            return False
    if not isinstance(row['comment'], str):
        _notice(blocked, 'malformed_smart_row', 'SmartAI comment is not text', row)
        return False
    return True


def _validate_condition(row, donor, blocked):
    missing = [column for column in CONDITION_COLUMNS if column not in row]
    if missing:
        _notice(blocked, 'malformed_condition',
                'SmartAI condition is missing columns: ' + ', '.join(missing))
        return False
    numeric = CONDITION_COLUMNS[:13]
    if any(not _is_int(row[column]) for column in numeric):
        _notice(blocked, 'malformed_condition', 'SmartAI condition has a non-integer numeric field')
        return False
    if row['SourceTypeOrReferenceId'] != 22:
        _notice(blocked, 'malformed_condition', 'SmartAI condition does not use source type 22')
        return False
    if row['ScriptName']:
        _notice(blocked, 'condition_script_dependency',
                'SmartAI condition has a condition ScriptName requiring manual review')
        return False
    if row['ConditionTypeOrReference'] not in (1, 21):
        _notice(blocked, 'context_condition',
                'Condition depends on unreviewed quest, spawn, reference, or world context')
        return False
    values = (row['ConditionValue1'], row['ConditionValue2'], row['ConditionValue3'])
    if donor in values:
        _notice(blocked, 'ambiguous_condition_self_reference',
                'SmartAI condition embeds the donor entry in a semantic value')
        return False
    return True


def _is_own_talker(row, simple=False):
    target = row['target_type']
    if simple:
        return target == 1 or target in PLAYER_TARGETS
    return target in (0, 1) or target in PLAYER_TARGETS or row['action_param3'] == 1


def _review_and_clone(row, donor, target, is_tal, blocked, warnings,
                      text_groups, requested_tals):
    if not _validate_smart(row, blocked):
        return None
    if row['source_type'] != (9 if is_tal else 0):
        _notice(blocked, 'wrong_smart_source', 'SmartAI row has an unexpected source type', row)
        return None
    if not is_tal:
        event = row['event_type']
        if event == 11:
            if any(row[f'event_param{i}'] for i in range(1, 4)):
                _notice(blocked, 'world_respawn_event',
                        'Respawn event is restricted to a map or area', row)
        elif event not in SAFE_EVENTS:
            _notice(blocked, 'context_event',
                    'Event depends on quest, gossip, path, transport, instance, GUID, or world context', row)
    action = row['action_type']
    if action not in SAFE_ACTIONS:
        _notice(blocked, 'context_action',
                'Action is outside the conservative portable-action allowlist', row)
    if row['target_type'] not in SAFE_TARGETS:
        _notice(blocked, 'context_target',
                'Target uses an entry, GUID, position, gameobject, instance, or formation selector', row)
    if row['target_type'] == 1 and any(abs(row[k]) > 200 for k in ('target_x', 'target_y', 'target_z')):
        _notice(blocked, 'implicit_absolute_position',
                'Core converts this self target to an absolute world position', row)
    if row['target_type'] == 202 and row['target_param3'] != 1:
        _notice(blocked, 'absolute_random_point',
                'Random-point target uses stored world coordinates instead of the script owner', row)

    clone = deepcopy(row)
    if not is_tal:
        clone['entryorguid'] = target

    if action in SUMMON_ACTIONS:
        if row['action_param1'] == donor:
            clone['action_param1'] = target
        else:
            _notice(warnings, 'preserved_external_summon',
                    f'Action preserves external summoned creature {row["action_param1"]}', row)
    if action in SELF_TEMPLATE_ACTIONS and row['action_param1'] == donor:
        if row['target_type'] not in (0, 1):
            _notice(blocked, 'ambiguous_template_self_reference',
                    'Template/model action names the donor but does not target self', row)
        else:
            clone['action_param1'] = target
    elif action in SELF_TEMPLATE_ACTIONS and row['action_param1']:
        _notice(warnings, 'preserved_external_template',
                f'Action preserves external creature template {row["action_param1"]}', row)

    if not is_tal and row['event_type'] in SUMMON_EVENTS and row['event_param1'] == donor:
        clone['event_param1'] = target
    if not is_tal and row['event_type'] == 5 and row['event_param4'] == donor:
        _notice(blocked, 'ambiguous_kill_self_reference',
                'Kill event embeds the donor entry as the killed-creature filter', row)
    if not is_tal and row['event_type'] == 52:
        speaker = row['event_param2']
        if speaker == donor:
            clone['event_param2'] = target
            text_groups.add(row['event_param1'])
        else:
            _notice(blocked, 'external_text_over',
                    f'Text-over event depends on external speaker {speaker}', row)

    if row['target_type'] == 204 and row['target_param1'] == donor:
        clone['target_param1'] = target

    if action in (1, 84):
        if not _is_own_talker(row, simple=action == 84):
            _notice(blocked, 'external_talker',
                    'Dialogue target may make another creature use the donor text group', row)
        else:
            text_groups.add(row['action_param1'])

    if action == 58 and row['action_param1'] > 3:
        _notice(blocked, 'context_ai_template',
                'Caged SmartAI templates embed creature/gameobject encounter dependencies', row)
    if action == 80:
        if is_tal:
            _notice(blocked, 'nested_timed_action_list',
                    'Timed action lists cannot safely call another timed action list', row)
        elif row['target_type'] != 1:
            _notice(blocked, 'external_timed_action_list_target',
                    'Timed action list call is not explicitly self-targeted', row)
        elif row['action_param1'] <= 0:
            _notice(blocked, 'missing_timed_action_list',
                    'Timed action list id is not positive', row)
        else:
            requested_tals.add(row['action_param1'])
    return clone


def _copy_conditions(prepared, old_owner, new_owner, source_type, rows,
                     donor, blocked):
    copied = []
    seen = set()
    for smart in rows:
        if not _is_int(smart.get('id')):
            continue
        key = (old_owner, source_type, smart['id'] + 1)
        for condition in prepared['conditions'].get(key, ()):  # SourceGroup is event id + 1.
            if not _validate_condition(condition, donor, blocked):
                continue
            clone = deepcopy(condition)
            clone['SourceEntry'] = new_owner
            condition_key = tuple(clone[column] for column in CONDITION_KEY)
            if condition_key not in seen:
                seen.add(condition_key)
                copied.append(clone)
    return copied


def _validate_links(rows, blocked):
    valid_links = {row.get('id') for row in rows if row.get('event_type') == 61}
    for row in rows:
        link = row.get('link')
        if _is_int(link) and link and link not in valid_links:
            _notice(blocked, 'broken_smart_link',
                    f'SmartAI link {link} has no LINK event in the same block', row)


def transform_ai(donor, target, tables, tal_start):
    """Clone one donor's portable SmartAI dependency closure or withhold it.

    ``tables`` may be raw exported tables or the result of ``prepare_ai_tables``.
    Structured blockers always cause all returned row lists to be empty.
    """
    for label, value in (('donor', donor), ('target', target), ('tal_start', tal_start)):
        if not _is_int(value) or value <= 0:
            raise ValueError(f'{label} must be a positive integer')
    if donor == target:
        raise ValueError('donor and target must differ')
    prepared = tables if isinstance(tables, dict) and tables.get('_coa_ai_prepared') else prepare_ai_tables(tables)
    blocked = []
    warnings = []
    output = {'smart_scripts': [], 'conditions': [], 'creature_text': []}
    for message in prepared['errors']:
        _notice(blocked, 'malformed_export', message)

    donor_rows = list(prepared['smart'].get((donor, 0), ()))
    if not donor_rows:
        _notice(blocked, 'no_template_smart_scripts',
                f'Donor {donor} has no positive template-level SmartAI rows')
        return {'tables': output, 'warnings': warnings, 'blocked': blocked,
                'next_tal_id': tal_start}
    if prepared['smart'].get((target, 0)):
        _notice(blocked, 'target_smart_collision',
                f'Target {target} already has template-level SmartAI rows')
    if any(key[0] == target and key[1] == 0 for key in prepared['conditions']):
        _notice(blocked, 'target_condition_collision',
                f'Target {target} already has SourceType 22 condition rows')

    _validate_links(donor_rows, blocked)
    text_groups = set()
    requested_tals = set()
    main_clones = []
    for row in donor_rows:
        clone = _review_and_clone(row, donor, target, False, blocked, warnings,
                                  text_groups, requested_tals)
        if clone is not None:
            main_clones.append(clone)

    tal_map = {old: tal_start + offset for offset, old in enumerate(sorted(requested_tals))}
    existing_tals = {owner for owner, source in prepared['smart'] if source == 9}
    for old, new in tal_map.items():
        if not prepared['smart'].get((old, 9)):
            _notice(blocked, 'missing_timed_action_list',
                    f'Timed action list {old} has no source_type 9 rows')
        if new in existing_tals:
            _notice(blocked, 'timed_action_list_collision',
                    f'Allocated timed action list id {new} already exists')
    for clone in main_clones:
        if clone['action_type'] == 80 and clone['action_param1'] in tal_map:
            clone['action_param1'] = tal_map[clone['action_param1']]

    tal_clones = []
    tal_conditions = []
    for old, new in sorted(tal_map.items()):
        old_rows = list(prepared['smart'].get((old, 9), ()))
        _validate_links(old_rows, blocked)
        for row in old_rows:
            clone = _review_and_clone(row, donor, target, True, blocked, warnings,
                                      text_groups, set())
            if clone is not None:
                clone['entryorguid'] = new
                tal_clones.append(clone)
        tal_conditions.extend(_copy_conditions(
            prepared, old, new, 9, old_rows, donor, blocked))

    main_conditions = _copy_conditions(
        prepared, donor, target, 0, donor_rows, donor, blocked)
    text_rows = []
    for group in sorted(text_groups):
        source_rows = prepared['text'].get((donor, group), ())
        if not source_rows:
            _notice(blocked, 'missing_creature_text',
                    f'Donor {donor} has no creature_text group {group}')
            continue
        if prepared['text'].get((target, group)):
            _notice(blocked, 'target_text_collision',
                    f'Target {target} already has creature_text group {group}')
            continue
        for row in source_rows:
            if any(column not in row for column in TEXT_KEY):
                _notice(blocked, 'malformed_creature_text',
                        f'Donor {donor} has a malformed creature_text row in group {group}')
                continue
            clone = deepcopy(row)
            clone['CreatureID'] = target
            text_rows.append(clone)

    smart_output = main_clones + tal_clones
    smart_keys = [(row['entryorguid'], row['source_type'], row['id'], row['link'])
                  for row in smart_output]
    if len(smart_keys) != len(set(smart_keys)):
        _notice(blocked, 'duplicate_output_smart_key',
                'Transformed SmartAI rows collide on their primary key')
    condition_keys = [tuple(row[column] for column in CONDITION_KEY)
                      for row in main_conditions + tal_conditions]
    if len(condition_keys) != len(set(condition_keys)):
        _notice(blocked, 'duplicate_output_condition_key',
                'Transformed condition rows collide on their primary key')

    if blocked:
        return {'tables': output, 'warnings': warnings, 'blocked': blocked,
                'next_tal_id': tal_start}
    output['smart_scripts'] = smart_output
    output['conditions'] = main_conditions + tal_conditions
    output['creature_text'] = text_rows
    return {'tables': output, 'warnings': warnings, 'blocked': [],
            'next_tal_id': tal_start + len(tal_map)}
