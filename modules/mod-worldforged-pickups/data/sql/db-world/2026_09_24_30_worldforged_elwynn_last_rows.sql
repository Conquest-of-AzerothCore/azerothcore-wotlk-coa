-- ----------------------------------------------------------------------------
-- Worldforged pickups: the last two rows the editor moved after their pass
-- ----------------------------------------------------------------------------
-- Both rows belong to the Elwynn Forest and Northshire Valley pass, and both were
-- moved again in the map editor after that pass was written, so the file that
-- carries the pass no longer holds what the world holds.  The values below are the
-- world's own, read back from the database: position_x/y/z and the rotation
-- quaternion down to the digit.
--
--   Ziz's Alchemy Goggles (254229, guid 6941368, Jasperlode Mine): 0.2 yd higher
--   Northshire's Cherry Pie prop (90635, guid 6960002): moved back to the spot the
--   pass before the last one wrote, 0.35 yd from where the pass left it
--
-- Idempotent: both statements are UPDATEs keyed on guid, and neither touches
-- anything but the position, the rotation and the comment.  Apply to acore_world,
-- then let the worldserver load the rows.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Ziz's Alchemy Goggles (254229): Jasperlode Mine - Worldforged Ziz's Alchemy Goggles | realm map Elwynn Forest
--   authored in game: moved back to the placement the world runs now, 0.2 yd higher than the previous pass left it
UPDATE `gameobject` SET
  `position_x` = -9474.809570, `position_y` = -19.015600, `position_z` = 64.870598,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941368;

-- Cherry Pie prop (90635): Northshire Valley - Cherry Pie prop - the visible pie every other starter-zone pie stands next to
--   authored in game: back on the placement the world runs now, 0.35 yd from where the previous pass left it
UPDATE `gameobject` SET
  `position_x` = -8912.210938, `position_y` = -103.546875, `position_z` = 82.917717,
  `orientation` = 0.108748, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.054347418, `rotation3` = 0.998522103,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6960002;

COMMIT;
