-- Zul'Farrak / Chief Ukorz Sandscalp (final selected native Manastorm boss).
--
-- Recovered Manastorm.dat original segment identities (map 209):
--   Normal:  696, dungeon encounter 600, NPC 7267
--   Endgame: 695, dungeon encounter 2600, NPC 7267
-- No additional historical route variants of this objective were recovered.
--
-- The native Zul'Farrak pyramid finale is gated by GO 146084.
-- ManastormZulFarrakCompat.cpp opens only that original door in
-- Chief Ukorz's two SCRIPTED PRIVATE Manastorm instances.
-- The pyramid event is NOT marked complete and ordinary dungeon
-- spawns, Chief Ukorz (7267), and Ruuzlu (7797) are preserved.
--
-- Exact user-authored start teleport (including name capitalization):
--   ID 2151; map 209; X 1781.65; Y 1079.82; Z 42.5112;
--   orientation 3.90579;
--   'Manastorm_Zulfarrak_ChiefUkorzSandscalpp'
--
-- Leave original weights, depths, reward scalars, Chaotic Link
-- candidates, and configured link stack requirements unchanged.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2151, 1781.65, 1079.82, 42.5112, 3.90579, 209,
     'Manastorm_Zulfarrak_ChiefUkorzSandscalpp');

-- Enable the exact recovered Normal/Endgame stage records only.
-- StartingUnlocked bit (0x1), matching other selected dungeon bosses.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2151,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 696
     AND `map_id` = 209
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 600
     AND `objective_creature_entry` = 7267
     AND `start_game_tele_id` IN (0, 2151))
 OR (`segment_id` = 695
     AND `map_id` = 209
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2600
     AND `objective_creature_entry` = 7267
     AND `start_game_tele_id` IN (0, 2151));

-- Verify the selected originals before starting tests:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 209 AND objective_creature_entry = 7267
-- ORDER BY difficulty, segment_id;
