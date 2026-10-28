-- Dire Maul West / Lord Hel'nurath, original Dreadsteed ritual objective.
--
-- Recovered Manastorm identity (map 429, creature 14506):
--   687 = Normal,  encounter 156
--   688 = Endgame, encounter 2156
--
-- Boss 14506 is ritual-summoned rather than a persistent DB spawn.
-- Private Manastorm bootstrap summons him in the native ritual arena,
-- suppresses Immol'thar (11496) in that stage only, and preserves
-- normal Dire Maul / Warlock quest behavior.
--
-- Keep existing Chaotic Link routes/stacks and all manual tuning unchanged.
-- Exact starting position and teleport name supplied by the user.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2141, -46.2375, 751.226, -28.8181, 1.45615, 429,
     'Manastorm_DireMaul_LordHel\'nurath');

-- StartingUnlocked (bit 0x1), same baseline as preceding Dire Maul stages.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2141,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 687
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 156
     AND `objective_creature_entry` = 14506
     AND `start_game_tele_id` IN (0, 2141))
 OR (`segment_id` = 688
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2156
     AND `objective_creature_entry` = 14506
     AND `start_game_tele_id` IN (0, 2141));

-- Verify after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 14506
-- ORDER BY segment_id;
