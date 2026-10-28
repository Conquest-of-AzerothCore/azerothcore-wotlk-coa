-- Zul'Farrak / Witch Doctor Zum'rah.
--
-- Recovered native Manastorm identities (map 209, objective 7271):
--   197 = Normal,  encounter 597
--   400 = Endgame, encounter 2597
--   No historical route alternatives identified for this encounter.
--
-- Zum'rah starts friendly/neutral and should turn hostile when players
-- approach his sanctum. His graveyard zombie/ward adds are native combat
-- mechanics. Preserve the boss's normal spawn, AI and graveyard objects.
-- A private-only proximity-activation fix may be needed if the original
-- database behavior fails during stage tests; do not globally modify him.
--
-- Exact user-authored start teleport (preserve unusual capitalization
-- and spelling in the supplied name):
--   2148, map 209, X 1860.45, Y 974.479, Z 8.88194,
--   orientation 0.882824, name Manastorm_ZulFarrrak_WItchDoctorZumrah
--
-- Do not rewrite native encounter IDs, Chaotic Link candidates or
-- stacks, weights, depth settings, rewards, or other authored fields.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2148, 1860.45, 974.479, 8.88194, 0.882824, 209,
     'Manastorm_ZulFarrrak_WItchDoctorZumrah');

-- StartingUnlocked (0x1), one recovered Normal and Endgame route.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2148,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 197
     AND `map_id` = 209
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 597
     AND `objective_creature_entry` = 7271
     AND `start_game_tele_id` IN (0, 2148))
 OR (`segment_id` = 400
     AND `map_id` = 209
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2597
     AND `objective_creature_entry` = 7271
     AND `start_game_tele_id` IN (0, 2148));

-- Verify the recovered segments before runtime tests:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 209 AND objective_creature_entry = 7271
-- ORDER BY difficulty, segment_id;
