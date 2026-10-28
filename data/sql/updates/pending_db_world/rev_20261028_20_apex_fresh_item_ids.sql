-- Fresh item ids: the client keeps item info keyed by id for the life of the
-- install, so an id that was ever sent as legendary keeps that colour. New ids
-- force a clean query.
UPDATE `item_template` SET `entry` = 1009200 WHERE `entry` = 1009100;
UPDATE `item_template` SET `entry` = 1009201 WHERE `entry` = 1009101;
UPDATE `item_template` SET `entry` = 1009202 WHERE `entry` = 1009102;
UPDATE `item_template` SET `entry` = 1009203 WHERE `entry` = 1009103;

UPDATE `item_dbc` SET `ID` = 1009200 WHERE `ID` = 1009100;
UPDATE `item_dbc` SET `ID` = 1009201 WHERE `ID` = 1009101;
UPDATE `item_dbc` SET `ID` = 1009202 WHERE `ID` = 1009102;
UPDATE `item_dbc` SET `ID` = 1009203 WHERE `ID` = 1009103;

UPDATE `creature_loot_template` SET `Item` = 1009203 WHERE `Item` = 1009103;
UPDATE `creature_loot_template` SET `Item` = 1009201 WHERE `Item` = 1009101;
UPDATE `creature_loot_template` SET `Item` = 1009202 WHERE `Item` = 1009102;

UPDATE `quest_template`
SET `RequiredItemId1` = 1009203, `RequiredItemId2` = 1009201, `RequiredItemId3` = 1009202,
    `RewardItem1` = 1009200
WHERE `ID` IN (9916201, 9916211);
