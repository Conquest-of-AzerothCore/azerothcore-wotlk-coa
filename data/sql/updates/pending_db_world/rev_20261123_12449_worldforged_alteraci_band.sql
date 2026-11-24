-- #12449, #12013: Worldforged Alteraci Band (6940035) stood inside a pillar after the float-height pass; restore
-- its first-pass realm row from 2026_09_16_00.
UPDATE `gameobject` SET `position_x` = 490.779, `position_y` = -168.578, `position_z` = 159.303
WHERE `guid` = 6940035 AND `id` = 97126;
