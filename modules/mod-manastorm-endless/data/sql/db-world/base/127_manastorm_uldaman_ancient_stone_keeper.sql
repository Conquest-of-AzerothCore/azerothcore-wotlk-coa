-- Uldaman / Ancient Stone Keeper (NPC 7206, map 70).
--
-- One original recovered Ascension Manastorm route per difficulty:
--    97 = Normal,  dungeon encounter  551
--   380 = Endgame, dungeon encounter 2551
--
-- Original route variants that must remain catalogued but disabled:
--   98, 99   = Normal alternate routes
--   381, 382 = Endgame alternate routes
--
-- Exact player-authored arrival game_tele:
--   id 2164, X -88.4662, Y 294.124, Z -47.7379,
--   orientation 4.7218, map 70,
--   name 'Manastorm_Uldaman_AncientStoneKeeper'
--
-- Ancient Stone Keeper (7206) is the separate ordinary boss and NOT
-- the altar-activated Stone Keeper (4857) in instance_uldaman.cpp.
-- Preserve his native DB spawn and combat AI; no altar event bootstrap
-- or global Uldaman script changes are needed for this encounter.
--
-- Rerunnable. Change only the activation state of known native
-- alternate routes and the start teleport/StartingUnlocked/enabled
-- fields of the two selected routes. Never overwrite Chaotic Link
-- rosters, stacks, weight, depth, rewards or other flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2164, -88.4662, 294.124, -47.7379, 4.7218, 70,
     'Manastorm_Uldaman_AncientStoneKeeper');

-- Leave unused historical variants in the catalogue, but remove them
-- from ordinary weighted segment selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 70
  AND `objective_creature_entry` = 7206
  AND ((`difficulty` = 0
        AND `dungeon_encounter_id` = 551
        AND `segment_id` IN (98, 99))
    OR (`difficulty` = 2
        AND `dungeon_encounter_id` = 2551
        AND `segment_id` IN (381, 382)));

-- Enable only one original route per track. Preserve other flags by
-- OR-ing StartingUnlocked (bit 0x1), not replacing flags wholesale.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2164,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 97
     AND `map_id` = 70
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 551
     AND `objective_creature_entry` = 7206
     AND `start_game_tele_id` IN (0, 2164))
 OR (`segment_id` = 380
     AND `map_id` = 70
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2551
     AND `objective_creature_entry` = 7206
     AND `start_game_tele_id` IN (0, 2164));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 70 AND objective_creature_entry = 7206
-- ORDER BY difficulty, segment_id;
