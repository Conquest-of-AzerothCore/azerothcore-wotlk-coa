-- Shadowfang Keep / Baron Silverlaine.
--
-- Restore exactly one Normal and one Endgame Manastorm segment, using the
-- user's start anchor. All other Silverlaine route variants remain disabled.
--
-- Recovered native Manastorm identities:
--   24  = Normal,  map 33, encounter 466,  objective 3887
--   325 = Endgame, map 33, encounter 2466, objective 3887
--
-- User-authored physical start:
--   game_tele 2110; map 33
--   -175.758, 2232.39, 76.2413, orientation 2.48816
--
-- Preserve any existing Chaotic Links, counts, creature links, weights, and
-- native encounter fields. Do not insert new Manastorm catalogue rows.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2110, -175.758, 2232.39, 76.2413, 2.48816, 33,
     'Manastorm_SFK_BaronSilverlaine');

-- Enforce the one-route-per-boss decision, leaving other row data intact.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 33
  AND `objective_creature_entry` = 3887
  AND `segment_id` IN
      (25, 26, 27, 28, 29, 30, 31,
       326, 327, 328, 329, 330, 331, 332);

-- The Silverlaine pair is ordinary baseline dungeon content:
-- StartingUnlocked (bit 1) is intentionally enabled.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2110,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 24
     AND `map_id` = 33
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 466
     AND `objective_creature_entry` = 3887
     AND `start_game_tele_id` IN (0, 2110))
 OR (`segment_id` = 325
     AND `map_id` = 33
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2466
     AND `objective_creature_entry` = 3887
     AND `start_game_tele_id` IN (0, 2110));

-- Confirm precisely these two rows were enabled:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 33 AND objective_creature_entry = 3887
-- ORDER BY segment_id;
