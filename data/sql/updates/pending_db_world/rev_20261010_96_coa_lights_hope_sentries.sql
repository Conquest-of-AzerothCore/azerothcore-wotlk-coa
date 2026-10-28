-- Patch-WB1 built an inn and a smithy at Light's Hope Chapel and reshaped the ground around them.
-- Argent Sentries standing inside the new walls move to the nearest open ground; the others follow the new ground.
UPDATE `creature` SET `position_x` = 2214.0, `position_y` = -5327.0, `position_z` = 86.67
WHERE `guid` = 53869 AND `id` = 16378;
UPDATE `creature` SET `position_x` = 2227.99, `position_y` = -5284.8, `position_z` = 80.33
WHERE `guid` = 54756 AND `id` = 16378;
UPDATE `creature` SET `position_x` = 2318.5, `position_y` = -5328.0, `position_z` = 82.0
WHERE `guid` = 54757 AND `id` = 16378;
UPDATE `creature` SET `position_z` = 87.13 WHERE `guid` = 54758 AND `id` = 16378;
UPDATE `creature` SET `position_z` = 92.59 WHERE `guid` = 54751 AND `id` = 16378;
