-- Worldforged Decayed Sharpshot (#9200): the pickup (guid 6940332) was placed behind the Cain
-- Family Estate manor by the 2026-09-26 in-game audit, 4.5 yd from the Hound of House Cain's grave
-- (quest 1660042 "Defeat the Hound of House Cain behind the manor"). rev_20261016_90, an in-game
-- position-check pass, later moved it 27.6 yd away into the manor. Restore the audited spot, guarded
-- on the rev_20261016_90 coordinates.
UPDATE `gameobject` SET `position_x` = 1941.99, `position_y` = 1989.43, `position_z` = 156.585
WHERE `guid` = 6940332 AND `id` = 520047 AND `map` = 0
  AND `position_x` BETWEEN 1925.6 AND 1926.6 AND `position_y` BETWEEN 1966.4 AND 1967.4;
