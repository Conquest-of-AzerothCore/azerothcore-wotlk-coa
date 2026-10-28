-- Blackfathom Deeps / Lorgus Jett.
--
-- Original recovered Manastorm identities (map 48, objective NPC 12902):
--   73 = Normal,  encounter  222
--  240 = Endgame, encounter 2222
-- Unselected native route variants retained but disabled:
--   74 (Normal), 241 (Endgame).
--
-- Player-authored start teleport preserved exactly:
-- 2155, X -494.416, Y -41.5218, Z -40.6442, facing 3.184, map 48
-- 'Manastorm_BlackfathomDeep_LorgusJett'
--
-- Native behavior note:
-- Lorgus Jett is not a scripted gate boss in BFD's instance script,
-- but has historically had multiple native spawn points. Upstream
-- AzerothCore PR #6289 removed an erroneous SmartAI random-despawn.
-- Keep original NPC spawn and movement AI, no duplicate summon or
-- world spawn changes. Verify the objective's position in each
-- Manastorm private run; this teleport alone cannot guarantee proximity.
--
-- This patch changes no authored Chaotic Link candidates or required
-- stacks; weights, depths, reward scaling and existing flag bits remain.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2155, -494.416, -41.5218, -40.6442, 3.184, 48,
     'Manastorm_BlackfathomDeep_LorgusJett');

-- Disable only alternate variants for the same native boss objective.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 48
  AND `objective_creature_entry` = 12902
  AND (
      (`segment_id` = 74
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 222)
   OR (`segment_id` = 241
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2222)
  );

-- Keep one original segment per track. Add StartingUnlocked bit 0x1
-- without overriding other flag bits or existing progression fields.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2155,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 73
     AND `map_id` = 48
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 222
     AND `objective_creature_entry` = 12902
     AND `start_game_tele_id` IN (0, 2155))
 OR (`segment_id` = 240
     AND `map_id` = 48
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2222
     AND `objective_creature_entry` = 12902
     AND `start_game_tele_id` IN (0, 2155));

-- Read-only verification after applying:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id, weight,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 48 AND objective_creature_entry = 12902
-- ORDER BY difficulty, segment_id;
