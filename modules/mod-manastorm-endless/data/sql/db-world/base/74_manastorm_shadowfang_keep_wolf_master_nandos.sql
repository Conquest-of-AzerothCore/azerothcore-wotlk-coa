-- Shadowfang Keep / Wolf Master Nandos.
--
-- Restore exactly one Normal and one Endgame Manastorm route for this boss.
-- Preserve recovered duplicate rows, but keep them disabled.
--
-- Current Manastorm catalogue:
--   45  = Normal,  map 33, encounter 470,  objective 3927
--   348 = Endgame, map 33, encounter 2470, objective 3927
--   46  = duplicate Normal route (disabled)
--   349 = duplicate Endgame route (disabled)
--
-- User-selected start / Manastorm safety bubble:
--   game_tele 2114, map 33
--   -172.762, 2182.75, 151.907, orientation 5.88188
--
-- Preserve native identities, existing Chaotic Links/stack counts, and
-- other tuning on the selected segments.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2114, -172.762, 2182.75, 151.907, 5.88188, 33,
     'Manastorm_SFK_WolfMasterNandos');

-- Unused route variants, preserved for recovery but not selectable.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 33
  AND `objective_creature_entry` = 3927
  AND `segment_id` IN (46, 349);

-- Ordinary Vanilla dungeon baseline content: StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2114,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 45
     AND `map_id` = 33
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 470
     AND `objective_creature_entry` = 3927
     AND `start_game_tele_id` IN (0, 2114))
 OR (`segment_id` = 348
     AND `map_id` = 33
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2470
     AND `objective_creature_entry` = 3927
     AND `start_game_tele_id` IN (0, 2114));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 33 AND objective_creature_entry = 3927
-- ORDER BY segment_id;
