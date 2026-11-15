-- Darsok Swiftdagger (guid 14415) kept his old tower orientation after moving onto the patch-WB1 tower and faces
-- the wall; turn him half a circle, orientation 5.74213 -> 2.60054 (#11736).
UPDATE `creature` SET `orientation` = 2.60054
WHERE `guid` = 14415 AND `id` = 3449 AND `map` = 1
  AND `position_x` BETWEEN -516.889 AND -516.887 AND `position_y` BETWEEN -2597.391 AND -2597.389
  AND `orientation` BETWEEN 5.74212 AND 5.74214;
