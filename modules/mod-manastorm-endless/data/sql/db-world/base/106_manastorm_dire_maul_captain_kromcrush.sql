-- Dire Maul North / Captain Kromcrush.
--
-- Recovered original Manastorm identities (map 429, objective 14325):
--   147 = Normal
--   278 = Endgame
--
-- The optional Gordok tribute/disguise route can affect this boss
-- during ordinary dungeon gameplay. Do not change that native encounter.
-- No scripted summon, forced despawn, patrol change or quest override.
--
-- Exact user-authored starting teleport (preserve capitalization):
--   2145, map 429, X 499.579, Y 482.431, Z 29.4627,
--   orientation 6.26, name Manastorm_Diremaul_CaptainKromCrush
--
-- Keep recovered dungeon_encounter_id values unchanged because
-- the original Manastorm IDs for these North-wing records have not
-- been independently verified. Also preserve Chaotic Link candidates,
-- stack counts, weights, depths, rewards and all manual settings.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2145, 499.579, 482.431, 29.4627, 6.26, 429,
     'Manastorm_Diremaul_CaptainKromCrush');

-- Retain historical alternative routes as disabled records.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 429
  AND `objective_creature_entry` = 14325
  AND `difficulty` IN (0, 2)
  AND `segment_id` NOT IN (147, 278);

-- Enable the one original Normal and one original Endgame route.
-- StartingUnlocked (bit 0x1), matching the other Dire Maul stages.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2145,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 147
     AND `map_id` = 429
     AND `difficulty` = 0
     AND `objective_creature_entry` = 14325
     AND `start_game_tele_id` IN (0, 2145))
 OR (`segment_id` = 278
     AND `map_id` = 429
     AND `difficulty` = 2
     AND `objective_creature_entry` = 14325
     AND `start_game_tele_id` IN (0, 2145));

-- Verify the selected original segments and any disabled alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 429 AND objective_creature_entry = 14325
-- ORDER BY difficulty, segment_id;
