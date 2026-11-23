-- #13346: Worldforged Malgin's Barback (6941944) floated 0.90 yd off the bar in Bael'dun Keep; restore its first-pass realm x/y from 2026_09_16_00 on the bar (ground gap 0.03).
UPDATE `gameobject` SET `position_x` = -4084.457, `position_y` = -2401.604, `position_z` = 126.197
WHERE `guid` = 6941944 AND `id` = 97117;
