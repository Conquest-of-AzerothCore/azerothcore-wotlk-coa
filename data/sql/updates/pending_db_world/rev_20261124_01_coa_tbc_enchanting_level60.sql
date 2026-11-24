UPDATE `item_template`
SET `RequiredLevel` = 60
WHERE `entry` IN (22459, 22460) AND `RequiredLevel` > 60;
