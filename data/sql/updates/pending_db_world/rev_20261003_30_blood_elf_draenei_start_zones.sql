-- Blood Elves start at the Undead start in Deathknell, Draenei at the Night Elf start in Shadowglen.
-- Death Knights keep their Ebon Hold start.
UPDATE `playercreateinfo` SET `map` = 0, `zone` = 85, `position_x` = 1676.71, `position_y` = 1678.31,
    `position_z` = 121.67, `orientation` = 2.70526 WHERE `race` = 10 AND `class` <> 6;
UPDATE `playercreateinfo` SET `map` = 1, `zone` = 141, `position_x` = 10311.3, `position_y` = 832.463,
    `position_z` = 1326.41, `orientation` = 5.69632 WHERE `race` = 11 AND `class` <> 6;
