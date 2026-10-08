-- Deadmines / Sneed's Shredder.
--
-- Enable exactly one Normal and one Endgame Manastorm stage for the recovered
-- shredder objective (642). Sneed (643) is a separate native creature.
--
-- Recovered native Manastorm identities:
--   113 = Normal,  map 36, encounter 162,  objective 642
--   213 = Endgame, map 36, encounter 2162, objective 642
--   Unused Normal variants: 114, 115, 116
--   Unused Endgame variants: 214, 215, 216
--
-- User-authorized starting position:
--   game_tele 2117, map 36
--   -218.188, -516.369, 51.8811, orientation 1.07996
--
-- The Heavy Door (gameobject entry 17153, DB spawn GUID 26183) is opened
-- only in this disposable private Manastorm stage by
-- ManastormDeadminesCompat.cpp. Do not modify its world DB spawn state.
--
-- Preserve manually authored Chaotic Link candidates, stacks, weights,
-- and all recovered encounter identities and other tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2117, -218.188, -516.369, 51.8811, 1.07996, 36,
     'Manastorm_Deadmines_SneedShredder');

-- Preserve the extra native variants but keep them unselectable.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 36
  AND `objective_creature_entry` = 642
  AND `segment_id` IN (114, 115, 116, 214, 215, 216);

-- Baseline dungeon content: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2117,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 113
     AND `map_id` = 36
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 162
     AND `objective_creature_entry` = 642
     AND `start_game_tele_id` IN (0, 2117))
 OR (`segment_id` = 213
     AND `map_id` = 36
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2162
     AND `objective_creature_entry` = 642
     AND `start_game_tele_id` IN (0, 2117));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 36 AND objective_creature_entry = 642
-- ORDER BY segment_id;
