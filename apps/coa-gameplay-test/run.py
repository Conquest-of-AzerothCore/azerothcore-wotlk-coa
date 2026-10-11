#!/usr/bin/env python3
CLI_DESCRIPTION = """Run gameplay scenarios in a dedicated worldserver with disposable local databases."""

import argparse
import configparser
from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import secrets
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time

from world_cache import WorldCache, input_fingerprint

ROOT = Path(__file__).resolve().parents[2]
CREATE_FLAGS = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
IDENTIFIER = re.compile(r'[A-Za-z_][A-Za-z0-9_]*\Z')
ACTOR_ID = re.compile(r'[a-z][a-z0-9_]{0,31}\Z')
LOCAL_HOSTS = {'127.0.0.1', 'localhost', '::1'}
HOURS_PER_DAY = 24
MINUTES_PER_HOUR = 60
MINUTES_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR
METRICS = {
    'mana_regen', 'mana_regen_interrupted', 'resting',
    'sent_mana_regen', 'sent_mana_regen_interrupted',
    'moving', 'spline_remaining_ms', 'spline_speed', 'water_walk', 'in_water', 'terrain_in_water', 'ground_height',
    'forced_forward', 'distance_2d',
    'point_distance_2d', 'cast_remaining_ms', 'cast_pushback_ms',
    'melee_damage_count', 'melee_damage_total',
    'pet_power', 'pet_max_power', 'spell_energize_count', 'spell_energize_total',
    'xp', 'next_level_xp', 'skill_value', 'skill_maximum', 'lfg_dungeon_disabled', 'lfg_state', 'map_id',
    'map_difficulty', 'nearby_creature_template', 'nearby_creature_max_health', 'loot_gear_item_level',
    'position_x', 'position_y', 'position_z',
    'view_level', 'sent_level', 'sent_max_health', 'creature_query_rank', 'quest_level', 'quest_xp',
    'quest_log_sent_level', 'quest_log_sent_xp', 'quest_offer_sent_xp', 'quest_query_scaled', 'quest_query_reward_choice',
    'health', 'health_pct', 'max_health', 'creature_type', 'respawn_remaining', 'power', 'max_power', 'alive', 'combat', 'victim', 'casting', 'level',
    'aura', 'aura_stacks', 'aura_charges', 'aura_duration_ms', 'aura_amount', 'aura_positive', 'aura_visible',
    'knows_spell', 'spell_active', 'has_talent', 'talent_points', 'cooldown_ms', 'global_cooldown_ms', 'spell_charges',
    'action_button', 'action_button_packed', 'persisted_action_button', 'item_count', 'carried_item_count',
    'carried_pool_item_count', 'carried_variant_item_count', 'client_knows_spell', 'client_spellbook_copies',
    'pool_variant_count', 'pool_retired_item_count', 'pool_row_count', 'pool_item_present',
    'cache_token_count', 'cache_token_stage', 'cache_token_present',
    'free_inventory_slots', 'mail_count', 'mail_item_count', 'mail_has_item',
    'mail_pool_item_count', 'notifications', 'notification_contains',
    'bank_bag_slots', 'bank_shows',
    'system_messages',
    'system_message_contains', 'whispers_received', 'challenge_start_responses', 'challenge_start_code',
    'owned_creature_scale', 'owned_creature_visible', 'owned_creature_display', 'unit_scale', 'combat_reach',
    'token_count', 'item_sell_price', 'creature_model_scale', 'creature_model_display',
    'taxi_node', 'in_flight', 'taxi_destination', 'stabled_pet_count', 'stable_result', 'pet_rows', 'instance_binds_listed', 'pet_entry', 'pet_aura_stacks', 'pet_aura_duration_ms', 'pet_is_banker', 'pet_display',
    'pet_native_display', 'race', 'pet_scale', 'pet_knows_spell', 'pet_distance', 'pet_casting', 'pet_loading',
    'pet_spell_bar_count',
    'owned_creature_count', 'owned_creature_spacing', 'owned_creature_weapon_damage_min',
    'owned_creature_spell_hit_chance', 'owned_creature_attackable', 'owned_creature_victim',
    'charm_entry', 'charm_aura_stacks', 'controls_self', 'viewpoint_entry', 'seer_entry', 'private_instance',
    'dynamic_object', 'dynamic_object_duration_ms', 'gossip_options', 'gossip_option_text',
    'owned_gameobject_count', 'gameobject_remaining_ms', 'gameobject_display', 'gameobject_scale', 'at_homebind',
    'spellbook_rows', 'spellbook_offers_spell', 'spellbook_covers_spell', 'spellbook_learned_alerts',
    'spellbook_buy_succeeded', 'spellbook_buy_failed',
    'spellbook_buys_granted', 'spellbook_unannounced_buys', 'spellbook_misannounced_buys',
    'spellbook_notify_rows', 'spellbook_notified_spells', 'spellbook_unnotified_buys',
    'trainer_list_packets', 'trainer_window_rows', 'trainer_window_state', 'trainer_window_ability',
    'vendor_list_packets', 'vendor_items', 'vendor_price', 'vendor_price_sum', 'vendor_extended_cost',
    'spellbook_superseded_packets', 'spellbook_superseded_for', 'spellbook_loud_supersedes_for',
    'client_chat_lines_for', 'client_removals_keeping_buttons_for', 'client_placing_learns_for',
    'client_placing_supersedes_for', 'client_spell_rank_for',
    'client_spell_row_restored',
    'spellbook_client_notable',
    'spellbook_cues_in_last_buy', 'spellbook_last_buy_cued',
    'spellbook_silent_buys', 'spellbook_multi_announced_buys',
    'cast_speed_multiplier', 'spell_crit_chance', 'spell_power_cost', 'spell_damage_done', 'melee_damage_done',
    'who_count', 'who_class', 'player_name', 'name_lookup', 'loot_count', 'loot_entry', 'loot_received',
    'loot_gold', 'loot_bloodforged', 'loot_required_level', 'loot_item_level', 'loot_base_entry', 'loot_item_armor',
    'carried_item_level', 'carried_item_required_level', 'carried_item_armor', 'carried_item_scaling_level',
    'nearby_gameobject_count', 'nearby_gameobject_quest_active', 'nearby_gameobject_state', 'nearby_creature_count',
    'carried_money',
    'channel_object_entry',
    'quest_rewarded', 'has_achievement', 'has_title', 'spell_damage_taken', 'melee_damage_taken', 'spell_healing_taken',
    'spell_hit_bonus_taken', 'rooted', 'stunned', 'spell_cast_count', 'spell_go_count', 'cast_failure',
    'stealth_detection', 'can_detect',
    'quest_status', 'quest_takeable', 'quest_objective_count', 'dialog_status',
    'ball_offer_count', 'ball_offers_quest',
    'ball_carried_count', 'ball_carried_quest', 'ball_turn_in_count', 'ball_turn_in_quest',
    'gossip_text',
    'stat', 'attack_power', 'ranged_attack_power', 'armor', 'weapon_damage_min', 'resistance',
    'attack_time_ms', 'pet_attack_time_ms', 'run_speed_rate', 'display_id', 'mount_display_id',
    'aura_amplitude_ms', 'melee_crit_chance', 'dodge_chance', 'parry_chance', 'expertise', 'combat_rating',
    'spell_modifier', 'spell_cast_time_ms', 'client_cast_time_ms', 'client_attributes', 'spell_max_range', 'spell_max_stacks', 'spell_healing_done',
    'aura_crit_chance', 'aura_script_value', 'melee_hit_chance', 'spell_hit_chance', 'spell_power',
    'spell_done_crit_chance', 'spell_taken_crit_chance', 'spell_done_crit_chance_scripted', 'ranged_taken_crit_chance',
    'melee_spell_damage_done', 'script_melee_damage_taken',
    'script_spell_damage_taken', 'script_periodic_damage_taken', 'script_heal_received', 'spell_effect_value',
    'block_chance', 'block_value', 'critical_block_chance', 'spell_critical_damage', 'armor_reduced_damage',
    'aoe_damage_taken', 'reputation_gain', 'spell_immune', 'spell_effect_immune', 'melee_attack_count',
    'spell_damage_count', 'spell_damage_total', 'spell_uses_armor',
    'spell_heal_count', 'spell_heal_total', 'spell_effective_heal_total',
    'equipped_item',
    'pet_aura_amount', 'pet_aura_amplitude_ms', 'pet_max_health', 'pet_health', 'pet_attack_power',
    'pet_run_speed_rate',
    'distance', 'spell_proc_count', 'spell_proc_chance', 'aura_proc_rate', 'temporary_spell_replacement',
    'spell_family_flags',
    'creature_loot_quality_rate', 'equipped_gear_loot_rate',
    'quest_menu_items', 'quest_menu_has', 'player_setting', 'server_packets', 'server_packet_u8', 'server_packet_u32',
    'server_packet_float', 'server_packet_contains',
    'known_entry_rank',
    'pet_autocast_enabled', 'combo_points', 'game_mode_mask', 'owned_creature_spell_proc_count',
    'player_class', 'cached_class', 'at_login_flag', 'wildcard_starter_spells_known', 'action_bar_unknown_spells',
    'wildcard_spells_known', 'wildcard_cards_pending', 'wildcard_cards_collected', 'wildcard_roll_cards_set',
    'wildcard_roll_cards_used', 'wildcard_bonus_pack_progress',
}
PLAYER_STAT_METRICS = {
    'mana_regen', 'mana_regen_interrupted', 'resting',
    'sent_mana_regen', 'sent_mana_regen_interrupted',
    'spell_go_count',
    'global_cooldown_ms',
    'melee_damage_count',
    'melee_damage_total',
    'pet_power', 'pet_max_power', 'spell_energize_count', 'spell_energize_total',
    'melee_crit_chance', 'dodge_chance', 'parry_chance', 'expertise', 'combat_rating',
    'spell_modifier', 'spell_cast_time_ms', 'client_cast_time_ms', 'client_attributes', 'spell_max_range', 'spell_max_stacks', 'spell_healing_done',
    'spell_family_flags',
    'melee_hit_chance', 'spell_power', 'spell_done_crit_chance',
    'spell_taken_crit_chance', 'spell_done_crit_chance_scripted', 'melee_spell_damage_done',
    'script_melee_damage_taken', 'script_spell_damage_taken', 'script_periodic_damage_taken',
    'script_heal_received', 'spell_effect_value',
    'block_chance', 'block_value', 'critical_block_chance', 'spell_critical_damage', 'armor_reduced_damage',
    'aoe_damage_taken', 'reputation_gain', 'spell_immune', 'spell_effect_immune', 'melee_attack_count',
    'spell_damage_count', 'spell_damage_total', 'spell_uses_armor',
    'spell_heal_count', 'spell_heal_total', 'spell_effective_heal_total',
    'equipped_item',
    'pet_aura_amount', 'pet_aura_amplitude_ms', 'pet_aura_duration_ms', 'pet_max_health', 'pet_health',
    'pet_attack_power',
    'pet_run_speed_rate',
}
METRIC_FIELDS = {'actor', 'metric', 'spell', 'power', 'caster', 'effect', 'item', 'entry', 'button',
                 'relative_to', 'ratio_to', 'target', 'quest', 'id', 'stat', 'school', 'hand', 'rating', 'op',
                 'base', 'key', 'index', 'pet', 'critical', 'target_pet', 'periodic', 'name', 'text',
                 'min_distance', 'owner_display', 'ranged_weapon_subclass', 'skill', 'cache', 'table', 'exclude',
                 'dungeon', 'source', 'opcode', 'from', 'slot', 'achievement', 'title',
                 'type_mask', 'hit_mask', 'spell_type_mask',
                 'phase_mask', 'trigger_spell', 'trials', 'incoming', 'heal', 'quality',
                 'row', 'offset', 'skip_strings', 'from_end', 'x', 'y', 'min_required_level', 'max_required_level',
                 'flat_coefficient_modifier', 'dominant_stat', 'off_stat'}
ACTIONS = {
    'stop_attack': ({'actor'}, {'actor'}),
    'set_moving': ({'actor', 'enabled'}, {'actor', 'enabled'}),
    'level_scaling_packet': ({'actor', 'value'}, {'actor', 'value'}),
    'client_packet': ({'actor', 'opcode'},
                      {'actor', 'opcode', 'fields', 'consumed', 'early', 'cast_before', 'pet_loading_before'}),
    'discover_taxi_node': ({'actor', 'entry'}, {'actor', 'entry'}),
    'specialization': ({'actor', 'id'}, {'actor', 'id', 'refused'}),
    'advancement_rank': ({'actor', 'entry', 'rank'}, {'actor', 'entry', 'rank', 'refused'}),
    'apply_appearances': ({'actor', 'selection'}, {'actor', 'selection'}),
    'sell_item': ({'actor', 'entry', 'item'}, {'actor', 'entry', 'item', 'count'}),
    'dungeon_difficulty_packet': ({'actor', 'value'}, {'actor', 'value'}),
    'ascension_dungeon_difficulty_packet': ({'actor', 'value'}, {'actor', 'value'}),
    'console': ({'command'}, {'command'}),
    'command': ({'actor', 'command'}, {'actor', 'command'}),
    'whisper': ({'actor', 'to', 'text'}, {'actor', 'to', 'text', 'language'}),
    'wait': ({'ms'}, {'ms'}),
    'snapshot': ({'actor', 'metric', 'save_as'}, METRIC_FIELDS | {'save_as'}),
    'assert': ({'actor', 'metric'}, METRIC_FIELDS | {'equals', 'min', 'max', 'within_ms'}),
    'learn': ({'actor', 'spell'}, {'actor', 'spell'}),
    'set_action_button': ({'actor', 'button'}, {'actor', 'spell', 'button', 'wildcard_slot'}),
    'grant_resource': ({'actor', 'spell'}, {'actor', 'spell', 'amount'}),
    'unlearn': ({'actor', 'spell'}, {'actor', 'spell', 'all_specs'}),
    'money': ({'actor', 'copper'}, {'actor', 'copper'}),
    'set_aura': ({'actor', 'spell', 'stacks'}, {'actor', 'spell', 'stacks', 'pet', 'owned_entry'}),
    'cancel_aura': ({'actor', 'spell'}, {'actor', 'spell'}),
    'cancel_mount': ({'actor'}, {'actor'}),
    'cast': ({'actor', 'spell'}, {'actor', 'spell', 'target', 'destination', 'target_pet', 'target_item',
                                  'target_gameobject'}),
    'attack': ({'actor', 'target'}, {'actor', 'target', 'pet'}),
    'pvp': ({'actor', 'enabled'}, {'actor', 'enabled'}),
    'group': ({'actor', 'target'}, {'actor', 'target', 'loot_method'}),
    'lfg_dungeon': ({'actor', 'dungeon'}, {'actor', 'dungeon'}),
    'lfg_teleport': ({'actor'}, {'actor', 'out'}),
    'lfg_join': ({'actor', 'dungeons', 'roles'}, {'actor', 'dungeons', 'roles'}),
    'lfg_set_roles': ({'actor', 'roles'}, {'actor', 'roles'}),
    'lfg_accept': ({'actor'}, {'actor'}),
    'lfg_final_credit': ({'actor'}, {'actor'}),
    'encounter_credit': ({'actor', 'entry'}, {'actor', 'entry'}),
    'leave_group': ({'actor'}, {'actor'}),
    'die': ({'actor'}, {'actor', 'revived'}),
    'release_spirit': ({'actor'}, {'actor'}),
    'cast_charm': ({'actor', 'spell'}, {'actor', 'spell', 'target', 'pet', 'destination'}),
    'gossip_hello': ({'actor'}, {'actor', 'target'}),
    'banker_activate': ({'actor'}, {'actor', 'target', 'owner', 'entry'}),
    'personal_bank_open': ({'actor', 'entry'}, {'actor', 'entry'}),
    'personal_bank_swap': ({'actor', 'entry', 'direction'},
                           {'actor', 'entry', 'direction', 'item', 'slot', 'count', 'inventory_slot'}),
    'binder_activate': ({'actor', 'target'}, {'actor', 'target'}),
    'destroy_item': ({'actor', 'item'}, {'actor', 'item'}),
    'start_challenge': ({'actor', 'challenge', 'level'}, {'actor', 'challenge', 'level'}),
    'stop_challenge': ({'actor', 'challenge'}, {'actor', 'challenge'}),
    'area_trigger': ({'actor', 'id'}, {'actor', 'id'}),
    'trainer_buy': ({'actor', 'spell'}, {'actor', 'spell', 'target'}),
    'pet_autocast': ({'actor', 'spell', 'enabled'}, {'actor', 'spell', 'enabled'}),
    'gossip_select': ({'actor', 'option'}, {'actor', 'option', 'code', 'code_actor'}),
    'who': ({'actor'}, {'actor', 'target', 'race_mask', 'class_mask'}),
    'open_item': ({'actor', 'item'}, {'actor', 'item'}),
    'collect_loot': ({'actor'}, {'actor'}),
    'close_loot': ({'actor'}, {'actor'}),
    'set_money': ({'actor', 'value'}, {'actor', 'value'}),
    'set_phase': ({'actor'}, {'actor', 'value'}),
    'use_nearby_gameobject': ({'actor', 'entry'}, {'actor', 'entry'}),
    'attack_owned_creature': ({'actor', 'target', 'entry'}, {'actor', 'target', 'entry'}),
    'attack_nearby': ({'actor', 'entry'}, {'actor', 'entry', 'kill', 'damage_pct'}),
    'summon': ({'actor', 'as', 'entry'}, {'actor', 'as', 'entry', 'distance'}),
    'loot_nearby': ({'actor', 'entry'}, {'actor', 'entry'}),
    'loot_creature': ({'actor', 'target'}, {'actor', 'target'}),
    'loot_slot': ({'actor'}, {'actor', 'slot', 'item'}),
    'loot_money': ({'actor'}, {'actor'}),
    'prepare_quest': ({'actor', 'quest'}, {'actor', 'quest', 'complete'}),
    'reward_quest': ({'actor', 'quest'}, {'actor', 'quest', 'choice'}),
    'restore_quest_spells': ({'actor'}, {'actor'}),
    'login_hooks': ({'actor'}, {'actor'}),
    'relog': ({'actor'}, {'actor', 'race'}),
    'talent': ({'actor', 'talent', 'rank'}, {'actor', 'talent', 'rank', 'command'}),
    'reset_talents': ({'actor'}, {'actor'}),
    'add_item': ({'actor', 'item'}, {'actor', 'item', 'count'}),
    'fill_bags': ({'actor'}, {'actor', 'slots'}),
    'equip': ({'actor', 'item', 'slot'}, {'actor', 'item', 'slot', 'rejected'}),
    'use_item': ({'actor', 'item', 'spell'}, {'actor', 'item', 'spell', 'target', 'target_item', 'destination'}),
    'use_gameobject': ({'actor', 'entry'}, {'actor', 'entry'}),
    'summon_gameobject': ({'actor', 'entry'}, {'actor', 'entry', 'distance', 'duration_s'}),
    'loot_gameobject': ({'actor', 'entry'}, {'actor', 'entry'}),
    'mapless_loot_hook': ({'actor', 'store'}, {'actor', 'store'}),
    'set_skill': ({'actor', 'skill', 'value', 'maximum'}, {'actor', 'skill', 'value', 'maximum'}),
    'gather_skill': ({'actor', 'skill', 'required'}, {'actor', 'skill', 'required'}),
    'set_xp_enabled': ({'actor', 'enabled'}, {'actor', 'enabled'}),
    'set_level': ({'actor', 'value'}, {'actor', 'value'}),
    'set_health': ({'actor', 'value'}, {'actor', 'value', 'pet', 'maximum'}),
    'reset_cooldown': ({'actor', 'spell'}, {'actor', 'spell'}),
    'restore_charges': ({'actor', 'spell'}, {'actor', 'spell'}),
    'set_power': ({'actor', 'value'}, {'actor', 'value', 'power', 'pet'}),
    'teleport': ({'actor', 'map', 'x', 'y', 'z'}, {'actor', 'map', 'x', 'y', 'z', 'o'}),
    'teleport_to_spawn': ({'actor', 'guid'}, {'actor', 'guid'}),
    'quest_accept': ({'actor', 'quest'}, {'actor', 'quest', 'entry', 'gameobject'}),
    'quest_open': ({'actor', 'quest', 'entry'}, {'actor', 'quest', 'entry'}),
    'quest_click': ({'actor', 'quest', 'entry'}, {'actor', 'quest', 'entry'}),
    'quest_complete': ({'actor', 'quest'}, {'actor', 'quest'}),
    'quest_turn_in': ({'actor', 'quest'}, {'actor', 'quest', 'entry', 'gameobject', 'reward'}),
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def keys(value, required, allowed, where):
    require(isinstance(value, dict), f'{where}: expected an object')
    require(required <= value.keys(), f'{where}: missing {sorted(required - value.keys())}')
    require(value.keys() <= allowed, f'{where}: unknown fields {sorted(value.keys() - allowed)}')


def number(value, where, minimum=None, maximum=None, integer=False):
    require(type(value) in (int, float) and math.isfinite(value), f'{where}: expected a finite number')
    require(not integer or type(value) is int, f'{where}: expected an integer')
    require(minimum is None or value >= minimum, f'{where}: value is too small')
    require(maximum is None or value <= maximum, f'{where}: value is too large')


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f'Duplicate JSON key: {key}')
        result[key] = value
    return result


def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'), object_pairs_hook=unique_object)


def validate(scenario):
    keys(scenario, {'schema', 'name', 'players', 'steps'},
         {'schema', 'name', 'players', 'creatures', 'steps', 'timeout_ms', 'location', 'contract', 'hour',
          'creature_scaling'}, 'scenario')
    require(type(scenario['schema']) is int and scenario['schema'] == 1, 'Unsupported scenario schema')
    require(isinstance(scenario['name'], str) and scenario['name'].strip(), 'Scenario needs a name')
    number(scenario.get('timeout_ms', 90000), 'timeout_ms', 1, 600000, True)
    if 'hour' in scenario:
        number(scenario['hour'], 'hour', 0, HOURS_PER_DAY - 1, True)
    require(type(scenario.get('creature_scaling', False)) is bool, 'creature_scaling must be boolean')
    players = scenario['players']
    creatures = scenario.get('creatures', [])
    require(isinstance(players, list) and 1 <= len(players) <= 8, 'Expected 1..8 players')
    require(isinstance(creatures, list) and len(creatures) <= 8, 'Expected at most eight creatures')
    player_ids = set()
    actor_ids = set()
    for player in players:
        keys(player, {'id', 'race', 'class'},
             {'id', 'race', 'class', 'level', 'bot', 'spell_hit_rating', 'spell_crit_rating',
              'melee_crit_rating', 'ranged_crit_rating', 'ranged_hit_rating', 'melee_hit_rating',
              'expertise_rating', 'allow_regeneration', 'name', 'expansion', 'ascension_client', 'account_of'}, 'player')
        identity = player['id']
        require(isinstance(identity, str) and ACTOR_ID.fullmatch(identity), 'Invalid player id')
        require(identity not in actor_ids, 'Duplicate actor id')
        if 'account_of' in player:
            require(isinstance(player['account_of'], str) and player['account_of'] in player_ids,
                    'account_of must reference an earlier player')
        actor_ids.add(identity)
        player_ids.add(identity)
        if 'name' in player:
            require(isinstance(player['name'], str) and 1 <= len(player['name']) <= 25
                    and len(player['name'].encode('utf-8')) <= 47, 'Invalid fixture character name')
        for key in ('race', 'class'):
            number(player[key], key, 1, 255, True)
        number(player.get('level', 80), 'level', 1, 255, True)
        number(player.get('expansion', 2), 'expansion', 0, 2, True)
        require(type(player.get('bot', False)) is bool, 'bot must be boolean')
        require(type(player.get('ascension_client', False)) is bool, 'ascension_client must be boolean')
        number(player.get('spell_hit_rating', 0), 'spell_hit_rating', 0, 100000, True)
        number(player.get('spell_crit_rating', 0), 'spell_crit_rating', 0, 100000, True)
        number(player.get('melee_crit_rating', 0), 'melee_crit_rating', 0, 100000, True)
        number(player.get('ranged_crit_rating', 0), 'ranged_crit_rating', 0, 100000, True)
        number(player.get('ranged_hit_rating', 0), 'ranged_hit_rating', 0, 100000, True)
        number(player.get('melee_hit_rating', 0), 'melee_hit_rating', 0, 100000, True)
        number(player.get('expertise_rating', 0), 'expertise_rating', 0, 100000, True)
        require(type(player.get('allow_regeneration', True)) is bool, 'allow_regeneration must be boolean')
    for creature in creatures:
        keys(creature, {'id', 'owner', 'entry'},
             {'id', 'owner', 'entry', 'distance', 'faction', 'level', 'health', 'reaction', 'spell_hit_bonus',
              'stationary'},
             'creature')
        identity = creature['id']
        require(isinstance(identity, str) and ACTOR_ID.fullmatch(identity), 'Invalid creature id')
        require(identity not in actor_ids, 'Duplicate actor id')
        actor_ids.add(identity)
        require(creature['owner'] in player_ids, 'Creature owner must be a player')
        for key, default in (('entry', None), ('faction', 14), ('health', 100000)):
            number(creature.get(key, default), key, 1, 2**31 - 1, True)
        number(creature.get('level', 80), 'creature level', 1, 255, True)
        number(creature.get('distance', 3), 'distance', 0, 100)
        number(creature.get('reaction', 0), 'reaction', 0, 2, True)
        require(type(creature.get('stationary', False)) is bool, 'stationary must be boolean')
        number(creature.get('spell_hit_bonus', 0), 'creature spell hit bonus', 0, 100)
    if 'location' in scenario:
        location = scenario['location']
        keys(location, {'map', 'x', 'y', 'z'}, {'map', 'x', 'y', 'z', 'o', 'ignore_access'}, 'location')
        require(type(location.get('ignore_access', False)) is bool, 'ignore_access must be boolean')
        number(location['map'], 'map', 0, 2**32 - 1, True)
        for key in ('x', 'y', 'z'):
            number(location[key], key, -17000, 17000)
        number(location.get('o', 0), 'orientation', 0, 2 * math.pi)
    steps = scenario['steps']
    require(isinstance(steps, list) and 1 <= len(steps) <= 10000, 'Expected 1..10000 steps')
    snapshots = {}
    assertions = 0
    for index, step in enumerate(steps):
        where = f'step {index}'
        require(isinstance(step, dict) and step.get('action') in ACTIONS, f'{where}: unknown action')
        action = step['action']
        required, allowed = ACTIONS[action]
        keys(step, required | {'action'}, allowed | {'action', 'label'}, where)
        if action in {'console', 'command'}:
            require(isinstance(step['command'], str) and step['command'].strip()
                    and '\n' not in step['command'] and '\r' not in step['command'],
                    f'{where}: expected one command')
            if action == 'command':
                require(step['command'].startswith('.') and len(step['command']) > 1,
                        f'{where}: player command must start with a dot')
        if action == 'whisper':
            require(isinstance(step['to'], str) and step['to'].strip()
                    and isinstance(step['text'], str) and step['text'].strip(),
                    f'{where}: whisper needs a target and text')
            if 'language' in step:
                number(step['language'], f'{where}.language', 0, 2**32 - 1, True)
        if action == 'summon':
            require(isinstance(step['as'], str) and step['as'] not in actor_ids, f'{where}: duplicate summon id')
            actor_ids.add(step['as'])
        if 'actor' in step:
            require(step['actor'] in actor_ids, f'{where}: unknown actor')
            require(action in {'snapshot', 'assert', 'set_health', 'cast', 'attack_owned_creature'}
                    or step['actor'] in player_ids,
                    f'{where}: action needs a player')
            if action == 'cast' and step['actor'] not in player_ids:
                require('destination' not in step, f'{where}: creature cast has no destination')
            if action == 'cast' and 'target_item' in step:
                require(step['actor'] in player_ids and 'target' not in step and 'target_pet' not in step,
                        f'{where}: item targets cast from a player at an owned item')
            if action == 'cast' and 'target_pet' in step:
                require(type(step['target_pet']) is bool, f'{where}: target_pet must be boolean')
                require(step['actor'] in player_ids and 'target' not in step,
                        f'{where}: target_pet casts from a player at their current pet')
        for key in ('target', 'caster'):
            if key in step:
                require(step[key] in actor_ids, f'{where}: unknown {key}')
        if 'destination' in step:
            destination = step['destination']
            keys(destination, {'x', 'y', 'z'}, {'x', 'y', 'z'}, f'{where}.destination')
            for key in ('x', 'y', 'z'):
                number(destination[key], f'{where}.destination.{key}', -17000, 17000)
        if action in {'dungeon_difficulty_packet', 'ascension_dungeon_difficulty_packet'}:
            number(step['value'], f'{where}.value', 0, 2, True)
        if action == 'teleport_to_spawn':
            number(step['guid'], f'{where}.guid', 1, 2**32 - 1, True)
        if action == 'teleport':
            number(step['map'], f'{where}.map', 0, 2**31 - 1, True)
            for key in ('x', 'y', 'z', 'o'):
                if key in step:
                    number(step[key], f'{where}.{key}', -17000, 17000)
        for key in ('spell', 'item', 'talent', 'count', 'entry', 'quest', 'id', 'challenge', 'level',
                    'target_item', 'target_gameobject', 'achievement', 'title'):
            if key in step:
                number(step[key], f'{where}.{key}', 1, 2**31 - 1, True)
        for key, maximum in (('rank', 4), ('effect', 2), ('slot', 22),('power', 6), ('choice', 5),
                             ('reward', 5), ('option', 2**32 - 1)):
            if key in step:
                number(step[key], f'{where}.{key}', 0, maximum, True)
        if 'stacks' in step:
            number(step['stacks'], f'{where}.stacks', 0, 255, True)
        if action == 'set_action_button':
            require(('spell' in step) != ('wildcard_slot' in step), f'{where}: needs a spell or a wildcard_slot')
            if 'wildcard_slot' in step:
                number(step['wildcard_slot'], f'{where}.wildcard_slot', 0, 255, True)
        if action in ('set_aura', 'attack', 'set_health', 'set_power') and 'pet' in step:
            require(type(step['pet']) is bool, f'{where}: pet must be boolean')
            require(step['actor'] in player_ids, f'{where}: pet fixture needs a player')
        if action == 'pet_autocast':
            require(type(step['enabled']) is bool, f'{where}: enabled must be boolean')
        if action == 'set_aura' and 'owned_entry' in step:
            require(step['actor'] in player_ids, f'{where}: owned creature fixture needs a player')
            require(not step.get('pet', False), f'{where}: select either a pet or an owned creature')
            number(step['owned_entry'], f'{where}.owned_entry', 1, 2**32 - 1, True)
        if action in {'pvp', 'set_moving'}:
            require(type(step['enabled']) is bool, f'{where}: enabled must be boolean')
        if 'all_specs' in step:
            require(type(step['all_specs']) is bool, f'{where}: all_specs must be boolean')
        if action == 'talent' and 'command' in step:
            require(type(step['command']) is bool, f'{where}: command must be boolean')
        for key in ('race_mask', 'class_mask'):
            if key in step:
                number(step[key], f'{where}.{key}', 0, 2**32 - 1, True)
        if action == 'who' and 'target' in step:
            require(step['target'] in player_ids, f'{where}: Who name filter needs a player')
        if action == 'attack_owned_creature':
            require(step['actor'] not in player_ids and step['target'] in player_ids,
                    f'{where}: attack needs a creature and a player who owns the target')
        if action == 'group':
            require(step['target'] in player_ids and step['target'] != step['actor'],
                    f'{where}: group needs another player')
            if 'loot_method' in step:
                number(step['loot_method'], f'{where}.loot_method', 0, 4, True)
        if action == 'lfg_dungeon':
            number(step['dungeon'], f'{where}.dungeon', 1, 2**24 - 1, True)
        if action == 'encounter_credit':
            number(step['entry'], f'{where}.entry', 1, 2**32 - 1, True)
        if action == 'lfg_join':
            require(type(step['dungeons']) is list and 0 < len(step['dungeons']) <= 50,
                    f'{where}: dungeons must list 1-50 LFGDungeons ids')
            for index, dungeon in enumerate(step['dungeons']):
                number(dungeon, f'{where}.dungeons[{index}]', 1, 2**24 - 1, True)
        if action in {'lfg_join', 'lfg_set_roles'}:
            number(step['roles'], f'{where}.roles', 0, 15, True)
        if action == 'lfg_teleport' and 'out' in step:
            require(type(step['out']) is bool, f'{where}: out must be boolean')
        for key in ('ms', 'within_ms'):
            if key in step:
                number(step[key], f'{where}.{key}', 0, scenario.get('timeout_ms', 90000), True)
        if action in {'set_skill', 'gather_skill'}:
            number(step['skill'], f'{where}.skill', 1, 65535, True)
        if action == 'set_skill':
            number(step['maximum'], f'{where}.maximum', 1, 450, True)
            number(step['value'], f'{where}.value', 0, step['maximum'], True)
        if action == 'gather_skill':
            require(step['skill'] in {182, 186, 393, 633, 773, 755}, f'{where}: unsupported gathering skill')
            number(step['required'], f'{where}.required', 0, 450, True)
        if action == 'set_xp_enabled':
            require(type(step['enabled']) is bool, f'{where}: enabled must be boolean')
        if action == 'money':
            number(step['copper'], f'{where}.copper', 1, 2**31 - 1, True)
        if action == 'set_level':
            number(step['value'], f'{where}.value', 1, 80, True)
        if action == 'level_scaling_packet':
            number(step['value'], f'{where}.value', 0, 1, True)
        if action in {'quest_accept', 'quest_turn_in'}:
            require(('entry' in step) != ('gameobject' in step), f'{where}: quest giver needs an entry or a gameobject')
            if 'gameobject' in step:
                number(step['gameobject'], f'{where}.gameobject', 1, 2**31 - 1, True)
        if action == 'gossip_select':
            require(not ('code' in step and 'code_actor' in step), f'{where}: code and code_actor are exclusive')
            if 'code' in step:
                require(isinstance(step['code'], str) and 0 < len(step['code']) <= 255, f'{where}: invalid code')
            if 'code_actor' in step:
                require(step['code_actor'] in player_ids, f'{where}: code_actor must be a player')
        if action == 'die' and 'revived' in step:
            require(type(step['revived']) is bool, f'{where}: revived must be boolean')
        if action == 'relog':
            require(step['actor'] in player_ids, f'{where}: relog needs a player')
            if 'race' in step:
                number(step['race'], f'{where}.race', 1, 255, True)
        if action == 'specialization':
            require(step['actor'] in player_ids, f'{where}: specialization needs a player')
            number(step['id'], f'{where}.id', 1, 0xFFFF, True)
            require(type(step.get('refused', False)) is bool, f'{where}: refused must be boolean')
        if action == 'advancement_rank':
            require(step['actor'] in player_ids, f'{where}: advancement_rank needs a player')
            number(step['entry'], f'{where}.entry', 1, 2**32 - 1, True)
            number(step['rank'], f'{where}.rank', 0, 3, True)
            require(type(step.get('refused', False)) is bool, f'{where}: refused must be boolean')
        if action == 'apply_appearances':
            require(step['actor'] in player_ids, f'{where}: apply_appearances needs a player')
            selection = step['selection']
            require(isinstance(selection, dict), f'{where}: selection must map categories to appearances')
            for category, appearance in selection.items():
                require(category.isdigit() and 0 < int(category) < 256, f'{where}.selection: invalid category')
                number(appearance, f'{where}.selection.{category}', 0, 2**32 - 1, True)
        if action == 'mapless_loot_hook':
            require(step['actor'] in player_ids, f'{where}: mapless loot needs a player')
            require(step.get('store') in {'mail', 'gameobject'}, f'{where}: unsupported mapless loot store')
        if action == 'personal_bank_swap':
            require(step['direction'] in {'deposit', 'withdraw'}, f'{where}: invalid bank direction')
            number(step.get('slot', 0), f'{where}.slot', 0, 97, True)
            number(step.get('count', 0), f'{where}.count', 0, 2**31 - 1, True)
            if step['direction'] == 'deposit':
                number(step.get('item'), f'{where}.item', 1, 2**32 - 1, True)
            if 'inventory_slot' in step:
                require(step['direction'] == 'withdraw', f'{where}: inventory_slot needs withdrawal')
                number(step['inventory_slot'], f'{where}.inventory_slot', 23, 38, True)
        if action in {'summon_gameobject', 'loot_gameobject'}:
            require(step['actor'] in player_ids, f'{where}: {action} needs a player')
            number(step['entry'], f'{where}.entry', 1, 2**32 - 1, True)
            number(step.get('distance', 2), f'{where}.distance', 0, 20)
            number(step.get('duration_s', 300), f'{where}.duration_s', 1, 86400, True)
        if action == 'discover_taxi_node':
            number(step['entry'], f'{where}.entry', 1, 2**31 - 1, True)
        if action == 'client_packet':
            if 'cast_before' in step:
                number(step['cast_before'], f'{where}.cast_before', 1, 2**32 - 1, True)
            if 'pet_loading_before' in step:
                require(type(step['pet_loading_before']) is bool,
                        f'{where}: pet_loading_before must be boolean')
            number(step['opcode'], f'{where}.opcode', 1, 0xFFFF, True)
            if 'consumed' in step:
                require(type(step['consumed']) is bool, f'{where}: consumed must be boolean')
            if 'early' in step:
                require(type(step['early']) is bool, f'{where}: early must be boolean')
            fields = step.get('fields', [])
            require(isinstance(fields, list), f'{where}: fields must be a list')
            for index, field in enumerate(fields):
                require(isinstance(field, dict) and len(field) == 1, f'{where}.fields[{index}]: expected one typed value')
                (kind, value), = field.items()
                require(kind in {'u8', 'u32', 'u64', 'string', 'buyback_guid', 'actor_guid', 'packed_actor_guid',
                                 'pet_guid', 'stabled_pet', 'duel_arbiter',
                                 'wildcard_entry', 'wildcard_pending_cards', 'wildcard_lowest_card'},
                        f'{where}.fields[{index}]: unknown field type')
                if kind == 'string':
                    require(isinstance(value, str), f'{where}.fields[{index}]: expected a string')
                elif kind in {'actor_guid', 'packed_actor_guid'}:
                    require(value in actor_ids, f'{where}.fields[{index}]: expected a player or creature id')
                elif kind in {'pet_guid', 'duel_arbiter'}:
                    require(value in player_ids, f'{where}.fields[{index}]: expected a player id')
                else:
                    maximum = {'u8': 255, 'u32': 2**32 - 1, 'u64': 2**64 - 1, 'buyback_guid': 2**31 - 1,
                               'stabled_pet': 3, 'wildcard_entry': 255, 'wildcard_pending_cards': 1000,
                               'wildcard_lowest_card': 7}[kind]
                    number(value, f'{where}.fields[{index}]', 0, maximum, True)
        if 'value' in step:
            number(step['value'], f'{where}.value', 1 if action == 'set_health' else 0, 2**31 - 1, True)
        if action == 'set_health' and 'maximum' in step:
            require(step['actor'] in player_ids, f'{where}: maximum health fixture needs a player or their pet')
            number(step['maximum'], f'{where}.maximum', 1, 2**31 - 1, True)
            require(step['value'] <= step['maximum'], f'{where}: health exceeds fixture maximum')
        if action in {'snapshot', 'assert'}:
            metric = step['metric']
            if metric == 'equipped_item':
                require(step['actor'] in player_ids, f'{where}: equipment metric needs a player')
                number(step.get('slot'), f'{where}.slot', 0, 18, True)
            if metric in {'known_entry_rank', 'owned_creature_spell_proc_count'}:
                require(step['actor'] in player_ids, f'{where}: metric needs a player')
                number(step.get('entry'), f'{where}.entry', 1, 2**31 - 1, True)
            if metric in {'pet_autocast_enabled', 'owned_creature_spell_proc_count'}:
                number(step.get('spell'), f'{where}.spell', 1, 2**31 - 1, True)
            if metric == 'spell_damage_done' and 'base' in step:
                number(step['base'], f'{where}.base', 0, 2**32 - 1, True)
            if metric in {'combo_points', 'game_mode_mask', 'pet_autocast_enabled'}:
                require(step['actor'] in player_ids, f'{where}: metric needs a player')
            if metric == 'victim':
                require('target' in step, f'{where}: victim metric requires a target')
            if 'periodic' in step:
                require(metric in {'spell_damage_done', 'spell_healing_done', 'spell_healing_taken'}
                        and type(step['periodic']) is bool,
                        f'{where}: periodic requires a damage/healing calculation and a boolean')
            require(metric in METRICS, f'{where}: unknown metric')
            if metric in {'xp', 'next_level_xp', 'skill_value', 'skill_maximum'}:
                require(step['actor'] in player_ids, f'{where}: XP/skill metric needs a player')
                if metric in {'skill_value', 'skill_maximum'}:
                    number(step.get('skill'), f'{where}.skill', 1, 65535, True)
            if metric in {'player_name', 'name_lookup'}:
                require(step['actor'] in player_ids and isinstance(step.get('name'), str)
                        and bool(step['name']), f'{where}: name metric needs a player and name')
            elif 'name' in step:
                require(False, f'{where}: name only applies to name metrics')
            if metric in {'view_level', 'sent_level', 'sent_max_health'}:
                require(step['actor'] in player_ids and 'target' in step,
                        f'{where}: view metric needs a player and target')
            if metric == 'creature_query_rank':
                require(step['actor'] in player_ids, f'{where}: creature query metric needs a player')
                number(step.get('entry'), f'{where}.entry', 1, 2**31 - 1, True)
            if metric in {'map_id', 'map_difficulty', 'nearby_creature_template',
                          'nearby_creature_max_health', 'loot_gear_item_level'}:
                require(step['actor'] in player_ids, f'{where}: dungeon/loot metric needs a player')
            if metric in {'nearby_creature_template', 'nearby_creature_max_health'}:
                number(step.get('entry'), f'{where}.entry', 1, 2**32 - 1, True)
            if metric == 'lfg_state':
                require(step['actor'] in player_ids, f'{where}: LFG state metric needs a player')
            if metric == 'lfg_dungeon_disabled':
                number(step.get('dungeon'), f'{where}.dungeon', 1, 2**24 - 1, True)
            if metric in {'quest_level', 'quest_xp', 'quest_log_sent_level', 'quest_log_sent_xp',
                          'quest_offer_sent_xp', 'quest_query_scaled',
                          'quest_query_reward_choice'}:
                require(step['actor'] in player_ids and 'quest' in step,
                        f'{where}: quest metric needs a player and quest')
            if metric.startswith('aura') or metric in {
                    'knows_spell', 'cooldown_ms', 'global_cooldown_ms', 'spell_charges', 'cast_remaining_ms', 'has_talent',
                    'pet_knows_spell', 'client_knows_spell', 'client_spellbook_copies',
                    'pet_aura_stacks', 'pet_aura_duration_ms', 'charm_aura_stacks', 'spell_active',
                    'dynamic_object', 'dynamic_object_duration_ms', 'spell_power_cost',
                    'spell_damage_done', 'spell_damage_taken', 'spell_healing_taken', 'spell_hit_bonus_taken',
                    'spell_cast_count', 'spell_go_count', 'spell_modifier', 'spell_cast_time_ms',
                    'client_cast_time_ms', 'client_attributes',
                    'spell_max_range', 'spell_max_stacks', 'spell_healing_done', 'spell_done_crit_chance',
                    'spell_family_flags',
                    'spell_taken_crit_chance',
                    'spell_done_crit_chance_scripted',
                    'melee_spell_damage_done', 'script_spell_damage_taken', 'script_periodic_damage_taken',
                    'script_heal_received', 'spell_effect_value', 'spell_critical_damage', 'armor_reduced_damage',
                    'spell_immune', 'spell_effect_immune', 'spell_damage_count', 'spell_damage_total',
                    'spell_uses_armor', 'pet_aura_amount', 'pet_aura_amplitude_ms', 'spell_heal_count', 'spell_heal_total',
                    'spell_effective_heal_total', 'spell_energize_count', 'spell_energize_total',
                    'spell_proc_count', 'spell_proc_chance', 'aura_proc_rate', 'temporary_spell_replacement',
                    'cast_failure',
                    'trainer_window_state', 'trainer_window_ability', 'spellbook_superseded_for',
                    'spellbook_loud_supersedes_for', 'spellbook_client_notable', 'client_chat_lines_for',
                    'client_removals_keeping_buttons_for', 'client_placing_learns_for',
                    'client_placing_supersedes_for', 'client_spell_rank_for', 'client_spell_row_restored'}:
                require('spell' in step, f'{where}: metric needs spell')
            for key in ('pet', 'critical'):
                if key in step:
                    require(metric in {'spell_damage_count', 'spell_damage_total', 'spell_heal_count',
                                       'spell_heal_total', 'spell_effective_heal_total'}
                            or (key == 'pet' and metric in {'spell_go_count', 'spell_energize_count',
                                                           'spell_energize_total',
                                                           'armor_reduced_damage', 'spell_effect_value',
                                                           'spell_damage_done'}),
                            f'{where}: {key} only filters supported spell combat events')
                    require(type(step[key]) is bool, f'{where}: {key} must be boolean')
            if metric in {'spell_go_count', 'spell_damage_count', 'spell_damage_total'} and 'entry' in step:
                number(step['entry'], f'{where}.entry', 1, 2**32 - 1, True)
                require('pet' not in step, f'{where}: spell combat query selects either pet or entry')
            if 'target_pet' in step:
                require(metric in {'spell_heal_count', 'spell_heal_total', 'spell_effective_heal_total',
                                   'spell_energize_count', 'spell_energize_total'}
                        and step.get('target') in player_ids, f'{where}: target_pet needs a healing or energize target player')
                require(type(step['target_pet']) is bool, f'{where}: target_pet must be boolean')
            if metric in {'spell_damage_done', 'melee_damage_done', 'spell_damage_taken', 'melee_damage_taken',
                          'spell_healing_done', 'spell_healing_taken', 'spell_done_crit_chance',
                          'spell_taken_crit_chance', 'spell_done_crit_chance_scripted', 'melee_spell_damage_done',
                          'spell_critical_damage', 'armor_reduced_damage', 'spell_immune', 'spell_effect_immune',
                          'distance_2d', 'can_detect'} \
                    or metric.startswith('script_'):
                require('target' in step, f'{where}: damage metric needs target')
            if metric == 'aura_proc_rate':
                require('target' in step, f'{where}: {metric} metric needs target')
                number(step.get('type_mask'), f'{where}.type_mask', 1, 2**32 - 1, True)
                for key in ('trigger_spell', 'hit_mask', 'spell_type_mask', 'phase_mask'):
                    if key in step:
                        number(step[key], f'{where}.{key}', 0, 2**32 - 1, True)
                if 'trials' in step:
                    number(step['trials'], f'{where}.trials', 1, 1000000, True)
                for key in ('incoming', 'heal'):
                    if key in step:
                        require(type(step[key]) is bool, f'{where}: {key} must be boolean')
            if metric == 'distance':
                require('target' in step, f'{where}: {metric} metric needs target')
            if metric == 'point_distance_2d':
                for key in ('x', 'y'):
                    number(step.get(key), f'{where}.{key}', -17000, 17000)
            elif 'x' in step or 'y' in step:
                require(False, f'{where}: x and y only apply to point_distance_2d')
            if metric == 'stat':
                number(step.get('stat'), f'{where}.stat', 0, 4, True)
            if metric == 'aura_script_value':
                number(step.get('key'), f'{where}.key', 0, 2**32 - 1, True)
            if metric in {'resistance', 'spell_power'}:
                number(step.get('school'), f'{where}.school', 1, 6, True)
            if metric == 'combat_rating':
                number(step.get('rating'), f'{where}.rating', 0, 24, True)
            if metric == 'aoe_damage_taken':
                number(step.get('school'), f'{where}.school', 0, 6, True)
            if metric == 'reputation_gain':
                require('id' in step, f'{where}: reputation metric needs faction id')
            if metric == 'spell_modifier':
                number(step.get('op'), f'{where}.op', 0, 31, True)
                number(step.get('base'), f'{where}.base')
            if 'flat_coefficient_modifier' in step:
                require(metric == 'spell_effect_value' and not step.get('pet', False),
                        f'{where}: flat_coefficient_modifier needs a player spell effect query')
                number(step['flat_coefficient_modifier'], f'{where}.flat_coefficient_modifier',
                       -(2**31), 2**31 - 1, True)
            if metric == 'spell_family_flags':
                number(step.get('index', 0), f'{where}.index', 0, 2, True)
            if 'hand' in step:
                maximum = 1 if metric in {'melee_attack_count', 'melee_damage_count', 'melee_damage_total'} else 2
                number(step['hand'], f'{where}.hand', 0, maximum, True)
            if 'school' in step and metric == 'spell_crit_chance':
                number(step['school'], f'{where}.school', 0, 6, True)
            if metric in {'item_count', 'carried_item_level', 'carried_item_required_level', 'carried_item_armor',
                          'carried_item_scaling_level'}:
                require('item' in step, f'{where}: metric needs item')
            if metric == 'carried_pool_item_count':
                require('cache' in step, f'{where}: metric needs the cache item it checks against')
                for option in ('dominant_stat', 'off_stat'):
                    if option in step:
                        number(step[option], f'{where}.{option}', 3, 6, True)
            if metric == 'pool_variant_count':
                require('cache' in step, f'{where}: metric needs the cache item it checks against')
            if metric == 'pool_retired_item_count':
                require('cache' in step, f'{where}: metric needs the cache item it checks against')
            if metric == 'pool_row_count':
                require('cache' in step, f'{where}: metric needs the cache item it checks against')
            if metric == 'pool_item_present':
                require('cache' in step, f'{where}: metric needs the cache item it checks against')
                require('item' in step, f'{where}: metric needs the item to look for')
            if metric in ('cache_token_count', 'cache_token_stage', 'cache_token_present'):
                require('cache' in step, f'{where}: metric needs the cache item it checks against')
            if metric == 'cache_token_present':
                require('item' in step, f'{where}: metric needs the token to look for')
            if metric in ('mail_has_item',):
                require('item' in step, f'{where}: metric needs the item to look for')
            if metric == 'mail_pool_item_count':
                require('cache' in step, f'{where}: metric needs the cache item it checks against')
            if metric == 'notification_contains':
                require(isinstance(step.get('text'), str) and step['text'].strip(),
                        f'{where}: metric needs the text to look for')
            if metric == 'quest_rewarded':
                require('quest' in step, f'{where}: metric needs quest')
            if metric == 'has_achievement':
                require('achievement' in step, f'{where}: metric needs achievement')
            if metric == 'has_title':
                require('title' in step, f'{where}: metric needs title')
            if metric == 'who_class':
                require(step.get('target') in player_ids, f'{where}: Who class metric needs a target player')
            if metric == 'owned_creature_count':
                require('entry' in step, f'{where}: metric needs creature entry')
                require('caster' not in step or 'spell' in step, f'{where}: aura caster filter needs spell')
                if 'ranged_weapon_subclass' in step:
                    number(step['ranged_weapon_subclass'], f'{where}.ranged_weapon_subclass', 0, 20, True)
            if metric in {'owned_creature_scale', 'owned_creature_visible', 'owned_creature_display',
                          'owned_creature_spacing', 'owned_creature_weapon_damage_min',
                          'owned_creature_spell_hit_chance', 'owned_creature_attackable', 'owned_creature_victim'}:
                require('entry' in step, f'{where}: metric needs creature entry')
            if metric == 'owned_creature_attackable':
                require(step.get('target') in actor_ids, f'{where}: metric needs the attacking unit')
            if metric == 'owned_creature_victim':
                require(step.get('target') in actor_ids, f'{where}: metric needs the expected victim')
            if metric == 'system_message_contains':
                require(isinstance(step.get('text'), str) and step['text'].strip(),
                        f'{where}: metric needs the text to look for')
            if metric == 'whispers_received':
                require(step.get('from') in player_ids and isinstance(step.get('text'), str)
                        and step['text'].strip(), f'{where}: metric needs a sending player and text')
            if metric in {'spellbook_offers_spell', 'spellbook_learned_alerts',
                          'spellbook_buy_succeeded', 'spellbook_buy_failed', 'cast_failure'}:
                require('spell' in step, f'{where}: metric needs spell')
            if metric in {'owned_gameobject_count', 'gameobject_remaining_ms', 'gameobject_display', 'gameobject_scale'}:
                require('entry' in step, f'{where}: metric needs gameobject entry')
            if metric in {'quest_status', 'quest_takeable', 'quest_objective_count'}:
                require('quest' in step, f'{where}: metric needs quest')
            if metric == 'dialog_status':
                require('entry' in step, f'{where}: metric needs creature entry')
            if metric == 'taxi_node':
                number(step.get('entry'), f'{where}.entry', 1, 2**31 - 1, True)
            if metric == 'ball_offers_quest':
                require('quest' in step, f'{where}: metric needs quest')
            if metric in {'ball_carried_quest', 'ball_turn_in_quest'}:
                require('quest' in step, f'{where}: metric needs quest')
            if metric == 'gossip_text':
                require('id' in step, f'{where}: metric needs text id')
            if metric == 'gossip_option_text':
                require(isinstance(step.get('text'), str) and step['text'].strip(),
                        f'{where}: metric needs the option text')
                number(step.get('index'), f'{where}.index', 0, 255, True)
            if metric == 'quest_menu_has':
                require('quest' in step, f'{where}: metric needs quest')
            if metric == 'player_setting':
                require(isinstance(step.get('source'), str) and step['source'].strip() and 'index' in step,
                        f'{where}: metric needs a setting source and index')
                number(step['index'], f'{where}.index', 0, 2**16 - 1, True)
            if metric in {'server_packets', 'server_packet_u8', 'server_packet_u32',
                          'server_packet_float', 'server_packet_contains'}:
                number(step.get('opcode'), f'{where}.opcode', 1, 0xFFFF, True)
            if metric == 'action_button_packed':
                number(step.get('button'), f'{where}.button', 0, 143, True)
            if metric in {'server_packet_u8', 'server_packet_u32', 'server_packet_float'}:
                number(step.get('index', 0), f'{where}.index', 0, 2**16 - 1, True)
                number(step.get('offset', 0), f'{where}.offset', 0, 2**16 - 1, True)
                number(step.get('skip_strings', 0), f'{where}.skip_strings', 0, 32, True)
            if 'from_end' in step:
                require(metric == 'server_packet_float' and isinstance(step['from_end'], bool),
                        f'{where}: from_end is a boolean for server_packet_float')
                require(not step['from_end'] or (not step.get('offset', 0) and not step.get('skip_strings', 0)),
                        f'{where}: from_end cannot combine with offset or skip_strings')
            if 'row' in step:
                require(metric in {'server_packets', 'server_packet_u8', 'server_packet_u32', 'server_packet_float',
                                   'server_packet_contains'},
                        f'{where}: row applies only to captured packet counts, values or text')
                number(step['row'], f'{where}.row', 0, 2**32 - 1, True)
            if 'quality' in step:
                require(metric in {'loot_count', 'loot_entry', 'loot_required_level', 'loot_item_level'},
                        f'{where}: quality applies only to corpse/container loot items')
                number(step['quality'], f'{where}.quality', 0, 7, True)
            if metric == 'at_login_flag':
                number(step.get('id'), f'{where}.id', 1, 0xFFFF, True)
            if metric == 'server_packet_contains':
                require(isinstance(step.get('text'), str) and step['text'].strip(),
                        f'{where}: metric needs the text to look for')
            if metric in {'knows_spell', 'client_knows_spell', 'client_spellbook_copies', 'has_talent',
                          'talent_points', 'cooldown_ms',
                          'spell_charges',
                          'action_button', 'action_button_packed', 'persisted_action_button', 'item_count',
                          'carried_item_count', 'carried_pool_item_count', 'carried_variant_item_count',
                          'bank_bag_slots', 'taxi_node', 'in_flight', 'taxi_destination', 'stabled_pet_count',
                          'stable_result', 'pet_rows', 'instance_binds_listed', 'spell_active',
                          'cast_pushback_ms',
                          'bank_shows', 'system_messages', 'system_message_contains', 'whispers_received',
                          'challenge_start_responses', 'challenge_start_code', 'owned_creature_scale', 'cast_failure',
                          'owned_creature_weapon_damage_min', 'owned_creature_spell_hit_chance',
                          'owned_creature_attackable', 'owned_creature_victim',
                          'pet_entry', 'pet_aura_stacks', 'pet_is_banker', 'pet_display', 'pet_native_display', 'pet_scale',
                          'pet_knows_spell', 'pet_distance', 'pet_casting', 'pet_loading',
                          'owned_creature_count', 'owned_creature_spacing', 'charm_entry',
                          'charm_aura_stacks', 'controls_self', 'private_instance',
                          'dynamic_object', 'dynamic_object_duration_ms', 'gossip_options', 'gossip_option_text',
                          'owned_gameobject_count', 'gameobject_remaining_ms', 'gameobject_display', 'gameobject_scale',
                          'at_homebind',
                          'spellbook_rows', 'spellbook_offers_spell', 'spellbook_covers_spell',
                          'spellbook_learned_alerts', 'spellbook_buy_succeeded', 'spellbook_buy_failed',
                          'spellbook_buys_granted', 'spellbook_unannounced_buys',
                          'spellbook_misannounced_buys', 'spellbook_silent_buys',
                          'spellbook_multi_announced_buys',
                          'spellbook_notify_rows', 'spellbook_notified_spells',
                          'spellbook_unnotified_buys',
                          'trainer_list_packets', 'trainer_window_rows', 'trainer_window_state',
                          'trainer_window_ability', 'vendor_list_packets', 'vendor_items',
                          'vendor_price', 'vendor_price_sum', 'vendor_extended_cost',
                          'spellbook_superseded_packets',
                          'spellbook_superseded_for', 'spellbook_loud_supersedes_for', 'client_chat_lines_for',
                          'client_removals_keeping_buttons_for', 'client_placing_learns_for',
                          'client_placing_supersedes_for', 'client_spell_rank_for',
                          'client_spell_row_restored',
                          'spellbook_client_notable',
                          'spellbook_cues_in_last_buy', 'spellbook_last_buy_cued',
                          'cast_speed_multiplier', 'spell_crit_chance', 'spell_power_cost',
                          'spell_damage_done', 'melee_damage_done',
                          'who_count', 'who_class',
                          'loot_count', 'loot_entry', 'loot_required_level', 'loot_item_level', 'loot_received',
                          'quest_rewarded', 'has_achievement',
                          'loot_base_entry', 'loot_item_armor',
                          'carried_item_level', 'carried_item_required_level', 'carried_item_armor',
                          'carried_item_scaling_level',
                          'has_title',
                          'quest_status', 'quest_takeable', 'quest_objective_count', 'dialog_status',
                          'ball_offer_count', 'ball_offers_quest',
                          'ball_carried_count', 'ball_carried_quest',
                          'ball_turn_in_count', 'ball_turn_in_quest',
                          'temporary_spell_replacement', 'quest_menu_items', 'quest_menu_has',
                          'player_setting', 'server_packets', 'server_packet_u8', 'server_packet_u32', 'server_packet_float',
                          'server_packet_contains',
                          'quest_log_sent_level', 'quest_log_sent_xp', 'quest_offer_sent_xp',
                          'player_class', 'cached_class', 'at_login_flag',
                          'wildcard_starter_spells_known', 'action_bar_unknown_spells',
                          'wildcard_spells_known', 'wildcard_cards_pending',
                          'wildcard_cards_collected', 'wildcard_roll_cards_set',
                          'wildcard_roll_cards_used', 'wildcard_bonus_pack_progress'} | PLAYER_STAT_METRICS:
                require(step['actor'] in player_ids, f'{where}: metric needs a player')
            snapshot_metric = 'spell_event_count' if metric in {'spell_cast_count', 'spell_proc_count'} else metric
            shape = (snapshot_metric, step.get('exclude'))
            if 'relative_to' in step:
                require(snapshots.get(step['relative_to']) == shape, f'{where}: missing or incompatible snapshot')
            if 'ratio_to' in step:
                require(step['ratio_to'] in snapshots, f'{where}: missing ratio snapshot')
            if action == 'snapshot':
                name = step['save_as']
                require(isinstance(name, str) and ACTOR_ID.fullmatch(name), f'{where}: invalid snapshot name')
                require(name not in snapshots, f'{where}: duplicate snapshot')
                snapshots[name] = shape
            else:
                assertions += 1
                require(any(key in step for key in ('equals', 'min', 'max')), f'{where}: no expected value')
                for key in ('equals', 'min', 'max'):
                    if key in step:
                        number(step[key], f'{where}.{key}')
                require(step.get('min', -math.inf) <= step.get('max', math.inf), f'{where}: reversed range')
                if 'equals' in step:
                    require(step.get('min', -math.inf) <= step['equals'] <= step.get('max', math.inf),
                            f'{where}: contradictory assertion')
    require(assertions > 0, 'Scenario must contain assertions')
    return scenario


def read_config(path):
    values = {}
    for line in Path(path).read_text(encoding='utf-8-sig').splitlines():
        match = re.match(r'^\s*([A-Za-z0-9_.]+)\s*=\s*(.*)$', line)
        if not match:
            continue
        key, value = match.groups()
        if value.startswith('"'):
            require('"' in value[1:], f'Unterminated config value: {key}')
            value = value[1:value.index('"', 1)]
        else:
            value = value.split('#', 1)[0].strip()
        values[key] = value
    return values


def env_var_name(key):
    result = []
    for index, char in enumerate(key):
        if char in ' .-':
            result.append('_')
            continue
        if index + 1 < len(key):
            following = key[index + 1]
            if ((not char.isupper() and following.isupper())
                    or ('0' <= char <= '9') != ('0' <= following <= '9')):
                result.append(char.upper() + '_')
                continue
        result.append(char.upper())
    return 'AC_' + ''.join(result)


def utc_now():
    return datetime.now(timezone.utc)


def hour_timezone(hour, now=None):
    utc = (now or utc_now()).astimezone(timezone.utc)
    ahead = (hour - utc.hour) * MINUTES_PER_HOUR - utc.minute
    offset = (ahead + MINUTES_PER_DAY // 2) % MINUTES_PER_DAY - MINUTES_PER_DAY // 2
    hours, minutes = divmod(abs(offset), MINUTES_PER_HOUR)
    return f"UTC{'-' if offset > 0 else '+'}{hours:02d}:{minutes:02d}"


def scenario_timezone(scenario, now=None):
    return {'TZ': hour_timezone(scenario['hour'], now)} if 'hour' in scenario else {}


def server_environment(overrides, environment=None):
    blocked = {env_var_name(key) for key in overrides}
    source = os.environ if environment is None else environment
    return {name: value for name, value in source.items() if name not in blocked}


def source_setting(config, key, default=None, environment=None):
    source = os.environ if environment is None else environment
    value = source.get(env_var_name(key), config.get(key, default))
    require(value is not None, f'Missing source setting: {key}')
    return value


@dataclass(frozen=True)
class Connection:
    host: str
    port: int
    user: str
    password: str = field(repr=False)
    database: str

    @classmethod
    def parse(cls, value):
        parts = value.split(';')
        require(len(parts) == 5, 'Expected five database connection fields')
        host, port, user, password, database = parts
        require(host in LOCAL_HOSTS, 'Only local database sources are supported')
        require(IDENTIFIER.fullmatch(database), 'Invalid source database name')
        require(port.isdecimal() and 0 < int(port) <= 65535, 'Invalid database port')
        return cls(host, int(port), user, password, database)

    def with_database(self, name):
        return ';'.join((self.host, str(self.port), self.user, self.password, name))


def cnf_quote(value):
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r') + '"'


def database_credentials(connections, path):
    parser = configparser.ConfigParser(interpolation=None)
    try:
        parser.read_string(path.read_text(encoding='utf-8-sig'))
    except configparser.Error:
        raise ValueError('Invalid database client config') from None
    require('client' in parser, 'Database client config needs a [client] section')
    settings = parser['client']

    def value(key):
        require(key in settings, f'Database client config needs {key}')
        text = settings[key].strip()
        if text.startswith(('"', "'")):
            require(len(text) >= 2 and text[-1] == text[0], f'Invalid client config quoting for {key}')
            text = text[1:-1]
        escapes = {'b': '\b', 't': '\t', 'n': '\n', 'r': '\r', 's': ' ', '\\': '\\', '"': '"', "'": "'"}
        return re.sub(r'\\(.)', lambda match: escapes.get(match[1], match[0]), text)

    host, port, user, password = (value(key) for key in ('host', 'port', 'user', 'password'))
    require(host in LOCAL_HOSTS and port.isdecimal(), 'Client config must select a local MySQL endpoint')
    require(user and not any(char in user + password for char in ';\r\n"'),
            'Client credentials cannot be represented in a worldserver connection string')
    result = {}
    for role, source in connections.items():
        require(host == source.host and int(port) == source.port,
                'Client config endpoint must match every source database connection')
        result[role] = Connection(source.host, source.port, user, password, source.database)
    return result


class Databases:
    def __init__(self, mysql, dump, directory, connections, run_id):
        require(re.fullmatch(r'[0-9a-f]{12}', run_id), 'Invalid run id')
        self.mysql = str(mysql)
        self.dump = str(dump)
        self.directory = directory
        self.connections = connections
        self.names = {role: f'coa_test_{run_id}_{role}' for role in connections}
        self.created = []
        self.option_files = {}
        try:
            for role, connection in connections.items():
                require(self.names[role] != connection.database, 'Source and test database must differ')
                path = directory / f'{role}-client.cnf'
                self.option_files[role] = path
                content = '[client]\n' + '\n'.join(f'{key}={cnf_quote(str(value))}' for key, value in {
                    'host': connection.host, 'port': connection.port, 'user': connection.user,
                    'password': connection.password, 'protocol': 'TCP', 'default-character-set': 'utf8mb4',
                }.items()) + '\n'
                path.write_text(content, encoding='utf-8')
                path.chmod(0o600)
        except BaseException:
            self.remove_credentials()
            raise

    def redact(self, detail):
        for connection in self.connections.values():
            if connection.password:
                detail = detail.replace(connection.password, '[redacted]')
        return detail.strip()[-4000:]

    def sql(self, role, statement, timeout=60):
        result = subprocess.run([self.mysql, f'--defaults-extra-file={self.option_files[role]}',
                                 '--batch', '--skip-column-names'], input=statement, text=True,
                                capture_output=True, timeout=timeout, creationflags=CREATE_FLAGS)
        if result.returncode:
            detail = self.redact(result.stderr)
            raise ValueError(f'MySQL operation failed for {role}: {detail or result.returncode}')
        return result.stdout.strip()

    def copy(self, role, schema_only=False, tables=()):
        connection = self.connections[role]
        arguments = [self.dump, f'--defaults-extra-file={self.option_files[role]}',
                     '--single-transaction', '--skip-lock-tables', '--no-tablespaces', '--skip-add-locks',
                     '--set-gtid-purged=OFF', '--column-statistics=0', '--skip-triggers']
        if schema_only:
            arguments.append('--no-data')
        elif tables:
            arguments.append('--no-create-info')
        arguments.extend([connection.database, *tables])
        with tempfile.TemporaryFile() as errors:
            source = subprocess.Popen(arguments, stdout=subprocess.PIPE, stderr=errors, creationflags=CREATE_FLAGS)
            target = None
            try:
                target = subprocess.Popen([self.mysql, f'--defaults-extra-file={self.option_files[role]}',
                                           self.names[role]], stdin=source.stdout, stdout=subprocess.DEVNULL,
                                          stderr=errors, creationflags=CREATE_FLAGS)
                source.stdout.close()
                target.wait(timeout=1800)
                source.wait(timeout=60)
                if source.returncode or target.returncode:
                    errors.seek(0)
                    detail = self.redact(errors.read().decode('utf-8', errors='replace'))
                    raise ValueError(f'Database copy failed for {role}: {detail}')
            finally:
                for process in (target, source):
                    if process is not None and process.poll() is None:
                        process.kill()
                        process.wait()

    def prepare(self, roles=('auth', 'characters', 'world')):
        for role in roles:
            name = self.names[role]
            self.sql(role, f'CREATE DATABASE `{name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;')
            self.created.append(role)
            print(f'Preparing isolated {role} database...', flush=True)
            self.copy(role, schema_only=(role != 'world'))
            if role != 'world':
                tables = ['updates', 'updates_include']
                if role == 'auth':
                    tables += ['rbac_permissions', 'rbac_linked_permissions', 'rbac_default_permissions', 'realmlist']
                else:
                    tables += ['active_arena_season']
                self.copy(role, tables=tables)

    def cleanup(self):
        failures = []
        for role in reversed(self.created):
            try:
                self.sql(role, f'DROP DATABASE `{self.names[role]}`;')
            except (ValueError, subprocess.SubprocessError):
                failures.append(self.names[role])
        return failures

    def remove_credentials(self):
        for path in self.option_files.values():
            path.unlink(missing_ok=True)


def unused_port():
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        return listener.getsockname()[1]


DATABASE_SETTINGS = {'auth': 'LoginDatabaseInfo', 'characters': 'CharacterDatabaseInfo', 'world': 'WorldDatabaseInfo'}
RUN_SETTINGS = ('DataDir', 'SourceDirectory', 'LogsDir', 'TempDir', 'WorldServerPort', 'CoAGameplayTest.RunId',
                'CoAGameplayTest.WorldDatabaseId')
SERVER_SETTINGS = {
    'BindIP': '127.0.0.1', 'Console.Enable': 1, 'Ra.Enable': 0, 'SOAP.Enabled': 0, 'MapUpdate.Threads': 0,
    'Warden.Enabled': 0, 'Network.UseSocketActivation': 0,
    'LoginDatabase.WorkerThreads': 1, 'CharacterDatabase.WorkerThreads': 1,
    'LoginDatabase.TransactionIsolation': '', 'CharacterDatabase.TransactionIsolation': '',
    'WorldDatabase.TransactionIsolation': '',
    'Updates.EnableDatabases': 7, 'CoAGameplayTest.Enable': 1,
}
HARNESS_FILES = {'start': 'StartFile', 'scenario': 'ScenarioFile', 'ready': 'ReadyFile', 'result': 'ResultFile',
                 'cases': 'CaseDirectory'}
CLOCK_SETTINGS = {'Clock': 'real', 'Lanes': 1, 'StepMs': 3, 'ActiveWaitCapMs': 25, 'PollCapMs': 10, 'StartHour': 10}


def reserved_settings():
    return {*DATABASE_SETTINGS.values(), *RUN_SETTINGS, *SERVER_SETTINGS,
            *(f'CoAGameplayTest.{name}' for name in (*HARNESS_FILES.values(), *CLOCK_SETTINGS))}


def source_connections(config, client_config=None):
    connections = {role: Connection.parse(source_setting(config, key)) for role, key in DATABASE_SETTINGS.items()}
    if client_config:
        connections = database_credentials(connections, client_config)
    return connections


def data_directory(config, binary):
    data_dir = Path(source_setting(config, 'DataDir', '.'))
    if not data_dir.is_absolute():
        data_dir = binary.parent / data_dir
    return data_dir.resolve()


def harness_overrides(connections, names, data_dir, logs, private, run_id, world_id, files, clock=None):
    unknown = files.keys() - HARNESS_FILES.keys()
    require(not unknown, f'Unknown harness files: {sorted(unknown)}')
    clock = clock or {}
    unknown = clock.keys() - CLOCK_SETTINGS.keys()
    require(not unknown, f'Unknown clock settings: {sorted(unknown)}')
    overrides = {key: connections[role].with_database(names[role]) for role, key in DATABASE_SETTINGS.items()}
    overrides.update(zip(RUN_SETTINGS, (data_dir.as_posix(), ROOT.as_posix(), logs.as_posix(), private.as_posix(),
                                        unused_port(), run_id, world_id)))
    overrides.update(SERVER_SETTINGS)
    overrides.update({f'CoAGameplayTest.{name}': Path(files[key]).as_posix() if files.get(key) else ''
                      for key, name in HARNESS_FILES.items()})
    overrides.update({f'CoAGameplayTest.{name}': value for name, value in (CLOCK_SETTINGS | clock).items()})
    return overrides


def world_cache_info(cache):
    return cache.info if cache else {'mode': 'fresh', 'retained': False}


def prepare_databases(database, cache, refresh=False):
    if cache:
        cache.prepare(refresh=refresh)
    database.prepare(roles=('auth', 'characters') if cache else ('auth', 'characters', 'world'))


def release_databases(database, cache, server_still_running, summary):
    failures = list(database.names.values()) if server_still_running else database.cleanup()
    if cache:
        try:
            cache.finish(server_still_running=server_still_running)
        except (ValueError, OSError, subprocess.SubprocessError, KeyError) as error:
            summary['cache_cleanup_error'] = str(error)
            failures.append(database.names['world'])
    if failures:
        summary.update(status='failed', cleanup_failed=failures)
    return failures


def write_config(source, destination, overrides):
    lines = []
    for line in source.read_text(encoding='utf-8-sig').splitlines():
        match = re.match(r'^\s*([A-Za-z0-9_.]+)\s*=', line)
        if not match or match.group(1) not in overrides:
            lines.append(line)
    for key, value in overrides.items():
        require('"' not in str(value) and '\n' not in str(value) and '\r' not in str(value),
                f'Unsupported config characters in {key}')
        lines.append(f'{key} = "{value}"')
    destination.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    destination.chmod(0o600)


def check_no_reserved_overrides(path, reserved):
    settings = read_config(path)
    require(not settings.keys() & reserved
            and not any(key.startswith('CoAGameplayTest.') for key in settings),
            f'Module config overrides harness controls: {path.name}')


def stage_modules(source, destination, reserved):
    if destination.exists():
        for path in sorted(destination.glob('*.conf')):
            check_no_reserved_overrides(path, reserved)
            require((source / path.name).is_file(),
                    f'Unexpected server module config: {path.name}; use an empty module config directory')
    staged = []
    try:
        for path in sorted(source.glob('*.conf')):
            check_no_reserved_overrides(path, reserved)
            target = destination / path.name
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open('xb') as staged_file:
                staged.append(target)
                staged_file.write(path.read_bytes())
            target.chmod(0o600)
        return staged
    except BaseException:
        for path in staged:
            path.unlink(missing_ok=True)
        raise


class ServerStillRunning(RuntimeError):
    def __init__(self, pid):
        super().__init__(f'Test process {pid} could not be stopped; databases were retained')
        self.pid = pid


def check_report(report, run_id, scenario, returncode):
    require(int(report.get('schema', 0)) == 1, 'Unsupported result schema')
    require(report.get('run_id') == run_id, 'Result belongs to a different run')
    require(report.get('scenario') == scenario['name'], 'Result belongs to a different scenario')
    require(report.get('execution') == 'socketless-session-handlers', 'Unexpected execution mode')
    require(report.get('status') == 'passed', report.get('message', 'Scenario failed'))
    require(returncode == 0, f'Worldserver exited with code {returncode}')
    expected = sum(step['action'] == 'assert' for step in scenario['steps'])
    require(int(report.get('assertions', 0)) == expected, 'Not all assertions ran')
    require(int(report.get('completed_steps', 0)) == len(scenario['steps']), 'Scenario did not complete')
    records = report.get('steps', [])
    require(isinstance(records, list) and len(records) == len(scenario['steps']), 'Missing step evidence')
    for index, (record, step) in enumerate(zip(records, scenario['steps'])):
        require(int(record.get('index', -1)) == index and record.get('action') == step['action'],
                'Step evidence does not match the scenario')
        if step['action'] == 'assert':
            require(record.get('status') == 'passed', 'A recorded assertion failed')
            actual = float(record['actual'])
            require(math.isfinite(actual), 'Non-finite assertion result')
            require('equals' not in step or actual == step['equals'], 'Equality assertion failed')
            require('min' not in step or actual >= step['min'], 'Minimum assertion failed')
            require('max' not in step or actual <= step['max'], 'Maximum assertion failed')
        else:
            require(record.get('status') == 'completed', 'An action did not complete')


def read_ready(path, run_id):
    ready = read_json(path)
    require(ready.get('run_id') == run_id and ready.get('status') == 'ready', 'Invalid readiness record')
    return ready


def server_command(binary, config):
    return [str(binary), '-c', str(config)]


def start_server(command, directory, log, environment=None):
    return subprocess.Popen(command, cwd=directory, stdin=subprocess.PIPE, stdout=log, stderr=log,
                            env=environment, creationflags=CREATE_FLAGS)


def stop_process(process):
    if process.poll() is None:
        try:
            process.stdin.write(b'server shutdown 0\n')
            process.stdin.flush()
            process.wait(timeout=15)
        except (OSError, subprocess.TimeoutExpired):
            try:
                process.kill()
                process.wait(timeout=15)
            except (OSError, subprocess.TimeoutExpired) as error:
                if process.poll() is None:
                    raise ServerStillRunning(process.pid) from error
    process.stdin.close()


def run_process(command, directory, ready_path, result_path, run_id, startup_timeout, timeout,
                on_ready=None, environment=None, should_stop=None):
    with (directory / 'worldserver.log').open('wb') as log:
        if should_stop and should_stop():
            raise KeyboardInterrupt
        process = start_server(command, directory, log, environment)
        start = time.monotonic()
        ready_at = None
        try:
            while process.poll() is None:
                if should_stop and should_stop():
                    raise KeyboardInterrupt
                now = time.monotonic()
                if ready_at is None and ready_path.exists():
                    ready = read_ready(ready_path, run_id)
                    if on_ready:
                        on_ready(ready)
                    ready_at = time.monotonic()
                    print('Worldserver harness is ready; executing scenario...', flush=True)
                if ready_at is None:
                    require(now - start < startup_timeout, 'Worldserver/harness readiness timed out')
                else:
                    require(now - ready_at < timeout, 'Gameplay scenario/shutdown timed out')
                time.sleep(0.1)
            require(result_path.exists(), f'Worldserver exited with code {process.returncode} without a result; '
                    'check the build and server log')
            report = read_json(result_path)
            if report.get('status') == 'passed':
                require(on_ready is None or ready_at is not None, 'Startup barrier was not observed')
                require(ready_path.exists(), 'Successful result is missing harness readiness')
                read_ready(ready_path, run_id)
            return report, process.returncode
        finally:
            stop_process(process)


def sha256(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def execute(args, scenario):
    started = time.monotonic()
    binary = args.worldserver.resolve(strict=True)
    source_config = args.config.resolve(strict=True)
    mysql = args.mysql.resolve(strict=True)
    dump = args.mysqldump.resolve(strict=True)
    config = read_config(source_config)
    connections = source_connections(config, args.database_client_config)
    run_id = secrets.token_hex(6)
    output = (args.output or ROOT / '.cache' / 'coa-gameplay-tests' / run_id).resolve()
    output.mkdir(parents=True, exist_ok=False)
    args.result_directory = output
    result_path = output / 'result.json'
    ready_path = output / 'ready.json'
    scenario_path = output / 'scenario.json'
    scenario_path.write_text(json.dumps(scenario, indent=2) + '\n', encoding='utf-8')
    print(f'Run {run_id}: {output}', flush=True)
    credentials_dir = Path(tempfile.mkdtemp(prefix='coa-gameplay-test-'))
    generated_config = credentials_dir / 'worldserver.conf'
    module_configs = []
    cache = None
    retain_databases = False
    summary = {'schema': 1, 'run_id': run_id, 'scenario': scenario['name'], 'status': 'failed',
               'binary_sha256': sha256(binary), 'scenario_sha256': sha256(scenario_path),
               'binary': str(binary)}
    database = Databases(mysql, dump, credentials_dir, connections, run_id)
    summary['databases'] = database.names
    try:
        module_source = args.modules_config_dir or source_config.parent / 'modules'
        if not args.fresh_databases:
            cache = WorldCache(database, args.world_cache_dir.resolve(),
                               input_fingerprint(ROOT, source_config, module_source), result_directory=output)
        summary['world_cache'] = world_cache_info(cache)
        prepare_databases(database, cache, args.refresh_world)
        summary['database_prepare_seconds'] = round(time.monotonic() - started, 3)
        start_path = output / 'start.json' if cache else None
        overrides = harness_overrides(connections, database.names, data_directory(config, binary), output,
                                      credentials_dir, run_id, cache.metadata['world_id'] if cache else run_id,
                                      {'start': start_path, 'scenario': scenario_path, 'ready': ready_path,
                                       'result': result_path})
        staged_configs = getattr(args, 'staged_module_configs', None)
        if staged_configs is None:
            module_target = args.server_modules_dir or output / 'configs' / 'modules'
            module_configs = stage_modules(module_source, module_target, set(overrides))
            staged_configs = module_configs
        summary['module_config_sha256'] = {path.name: sha256(path) for path in staged_configs}
        write_config(source_config, generated_config, overrides)
        server_started = time.monotonic()
        on_ready = (lambda record: cache.ready(record, start_path, run_id)) if cache else None
        zone = scenario_timezone(scenario)
        if zone:
            summary['timezone'] = zone['TZ']
        report, returncode = run_process(server_command(binary, generated_config), output, ready_path,
                                         result_path, run_id, args.startup_timeout,
                                         scenario.get('timeout_ms', 90000) / 1000 + 30,
                                         on_ready=on_ready, environment=server_environment(overrides) | zone,
                                         should_stop=getattr(args, 'should_stop', None))
        summary['server_seconds'] = round(time.monotonic() - server_started, 3)
        if report.get('realm_local_start'):
            summary['realm_local_start'] = report['realm_local_start']
        check_report(report, run_id, scenario, returncode)
        summary.update(status='passed', assertions=int(report['assertions']))
    except ServerStillRunning as error:
        retain_databases = True
        summary.update(message=str(error), process_id=error.pid)
    except (ValueError, OSError, subprocess.SubprocessError, KeyError) as error:
        summary['message'] = str(error)
    finally:
        release_databases(database, cache, retain_databases, summary)
        generated_config.unlink(missing_ok=True)
        for path in module_configs:
            path.unlink(missing_ok=True)
        database.remove_credentials()
        shutil.rmtree(credentials_dir, ignore_errors=True)
        summary['total_seconds'] = round(time.monotonic() - started, 3)
        (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    stage = 'COMPLETE' if summary['status'] == 'passed' else 'FAILED'
    print(f"NATIVE STAGE {stage}: {scenario['name']}\nResults: {output}")
    if 'message' in summary:
        print(summary['message'])
    return 0 if summary['status'] == 'passed' else 1


def _raise_keyboard_interrupt(signum, frame):
    raise KeyboardInterrupt


def add_run_arguments(run):
    run.add_argument('--worldserver', type=Path, required=True)
    run.add_argument('--config', type=Path, required=True, help='Source worldserver config; never changed')
    run.add_argument('--mysql', type=Path, required=True)
    run.add_argument('--mysqldump', type=Path, required=True)
    run.add_argument('--database-client-config', type=Path,
                     help='Optional MySQL [client] file with credentials allowed to create/drop test schemas')
    run.add_argument('--modules-config-dir', type=Path, help='Defaults to the source config directory/modules')
    run.add_argument('--server-modules-dir', type=Path,
                     help='Directory the worldserver reads module configs from; required outside Windows')
    run.add_argument('--output', type=Path, help='New directory for logs and results')
    run.add_argument('--native-only', action='store_true',
                     help='Exploratory execution only; explicitly skip combined verification')
    run.add_argument('--startup-timeout', type=float, default=600)
    mode = run.add_mutually_exclusive_group()
    mode.add_argument('--fresh-databases', action='store_true', help='Use disposable copies without the world cache')
    mode.add_argument('--refresh-world', action='store_true', help='Replace the owned world cache before this run')
    run.add_argument('--world-cache-dir', type=Path, default=ROOT / '.cache/coa-gameplay-tests/world-cache',
                     help='Local cache metadata/lease directory; database ownership is verified separately')


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    subparsers = parser.add_subparsers(dest='command', required=True)
    check = subparsers.add_parser('validate', help='Validate a scenario without starting a server')
    check.add_argument('scenario', type=Path)
    run = subparsers.add_parser('run', help='Prepare isolated test DBs, run a scenario, and clean up')
    run.add_argument('scenario', type=Path)
    add_run_arguments(run)
    args = parser.parse_args(argv)
    previous_sigterm_handler = None
    sigterm_installed = False
    try:
        scenario = validate(read_json(args.scenario))
        if args.command == 'validate':
            print(f"Valid scenario: {scenario['name']} ({len(scenario['steps'])} steps)")
            return 0
        require(math.isfinite(args.startup_timeout) and args.startup_timeout > 0, 'Invalid startup timeout')
        require(args.server_modules_dir or os.name == 'nt',
                '--server-modules-dir is required outside Windows (the worldserver reads CONF_DIR/modules)')
        if hasattr(signal, 'SIGTERM'):
            previous_sigterm_handler = signal.signal(signal.SIGTERM, _raise_keyboard_interrupt)
            sigterm_installed = True
        from workflow import run_registered
        return run_registered(args, scenario, execute)
    except (ValueError, OSError, KeyError, TypeError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1
    finally:
        if sigterm_installed:
            signal.signal(signal.SIGTERM, previous_sigterm_handler)


if __name__ == '__main__':
    sys.exit(main())
