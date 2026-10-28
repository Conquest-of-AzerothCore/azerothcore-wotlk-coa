-- Razorfen Downs / Ragglesnout (native rare).
--
-- Original Ascension Manastorm segment identities from recovered data:
--   692 = Normal,  map 129, encounter 9999, NPC 7354
--   690 = Endgame, map 129, encounter 2619, NPC 7354
--
-- Encounter ID 9999 is unusual, but it is the RECOVERED historical
-- Normal value and matches the original Manastorm row. Do not replace
-- it with a fabricated dungeon encounter or new stage identity.
--
-- Exact user-authored start teleport:
--   2163, X 2413.95, Y 897.604, Z 30.7454, orientation 3.01908,
--   map 129, 'Manastorm_RazorfenDowns_Ragglesnout'
--
-- Ragglesnout is a rare optional native dungeon spawn. When either
-- Manastorm stage is selected, private-only C++ bootstrap resolves a
-- native entry-7354 spawn GUID and coordinates from the world DB and
-- loads that original DB creature in the disposable instance if the
-- rare was not already present. No permanent creature is inserted,
-- no public rare chance or AI is changed.
--
-- Idempotent; preserves all author-managed Chaotic Link candidates,
-- stack counts, route weights, depth policies and rewards.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2163, 2413.95, 897.604, 30.7454, 3.01908, 129,
     'Manastorm_RazorfenDowns_Ragglesnout');

UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2163,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 692
     AND `map_id` = 129
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 9999
     AND `objective_creature_entry` = 7354
     AND `start_game_tele_id` IN (0, 2163))
 OR (`segment_id` = 690
     AND `map_id` = 129
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2619
     AND `objective_creature_entry` = 7354
     AND `start_game_tele_id` IN (0, 2163));

-- Read-only audit after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 129 AND objective_creature_entry = 7354
-- ORDER BY difficulty, segment_id;
--
-- Native rare-spawn audit (requires local world DB):
-- SELECT guid, id, map, position_x, position_y, position_z,
--        orientation, spawntimesecs
-- FROM creature
-- WHERE map = 129 AND id = 7354
-- ORDER BY guid;
