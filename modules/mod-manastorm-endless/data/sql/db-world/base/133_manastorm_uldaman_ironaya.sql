-- Uldaman Ironaya NPC 7228 (map 70).
-- Exact original historical segments: Normal 694 / encounter 549;
-- Endgame 693 / encounter 2549. One route per difficulty.
-- User-authored teleport 2170. Name and location kept verbatim.
-- Native instance DATA_IRONAYA_DOORS progression and its original
-- door, keystone, and boss spawn are handled by ManastormMgr.cpp
-- only for these two private instance stages. No public dungeon changes.
-- Preserve preexisting chaotic link candidates/stacks/weights/rewards.

INSERT IGNORE INTO `game_tele`
  (`id`,`position_x`,`position_y`,`position_z`,`orientation`,`map`,`name`)
VALUES
  (2170,-228.171,235.858,-50.649,1.71925,70,'Manastorm_Uldaman_Ironaya');

UPDATE `manastorm_segment`
SET `start_game_tele_id`=2170,
    `flags`=(`flags` | 1),
    `enabled`=1
WHERE (`segment_id`=694 AND `map_id`=70 AND `difficulty`=0
       AND `dungeon_encounter_id`=549 AND `objective_creature_entry`=7228
       AND `start_game_tele_id` IN (0,2170))
   OR (`segment_id`=693 AND `map_id`=70 AND `difficulty`=2
       AND `dungeon_encounter_id`=2549 AND `objective_creature_entry`=7228
       AND `start_game_tele_id` IN (0,2170));

-- Read-only verification:
-- SELECT segment_id,difficulty,dungeon_encounter_id,
--        objective_creature_entry,start_game_tele_id,chaotic_link_stacks,enabled
-- FROM manastorm_segment WHERE segment_id IN (693,694);
