-- The diploma is gone. The Skin-Peeler becomes the only reward.
UPDATE `quest_template`
SET `RewardItem1` = 190191, `RewardAmount1` = 1,
    `RewardItem2` = 0, `RewardAmount2` = 0
WHERE `ID` IN (17839, 17844);

DELETE FROM `item_dbc` WHERE `ID` = 1009300;
DELETE FROM `item_template` WHERE `entry` = 1009300;
