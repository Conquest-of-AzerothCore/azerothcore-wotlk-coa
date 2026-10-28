-- Blackrock Depths / Golem Lord Argelmach (native NPC 8983, map 230).
--
-- Recovered original Ascension Manastorm segments:
--   423 = Normal  (difficulty 0), dungeon encounter  237
--   464 = Endgame (difficulty 2), dungeon encounter 2237
-- No alternate original Argelmach routes were recovered.
--
-- Exact player-authored arrival teleport (not a creature spawn):
--   2184, X 744.406, Y 21.7897, Z -53.8305,
--   orientation 6.26355, map 230,
--   'Manastorm_BlackrockDepths_GolemLordArgelmach'
--
-- Native instance_blackrock_depths.cpp already implements golem and
-- technician reinforcement handling through instance data 31/32,
-- including activation of constructs carrying Stoned (spell 10255).
-- Do not force activation during Manastorm PREPARING: preserve the
-- original creature AI and combat-triggered instance mechanics.
--
-- Rerunnable migration limited to two exact original segments.
-- Preserve Chaotic Link candidates/stacks, weights, depths, rewards,
-- and any pre-existing unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2184, 744.406, 21.7897, -53.8305, 6.26355, 230,
     'Manastorm_BlackrockDepths_GolemLordArgelmach');

-- One native original route per difficulty. OR StartingUnlocked
-- (0x1) without disturbing any existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2184,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 423
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 237
     AND `objective_creature_entry` = 8983
     AND `start_game_tele_id` IN (0, 2184))
 OR (`segment_id` = 464
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2237
     AND `objective_creature_entry` = 8983
     AND `start_game_tele_id` IN (0, 2184));

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 8983
-- ORDER BY difficulty, segment_id;
