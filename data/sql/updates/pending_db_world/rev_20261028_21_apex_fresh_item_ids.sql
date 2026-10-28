-- The client resolves an icon live from Item.dbc + ItemDisplayInfo, but it keeps
-- the item's quality from the query response it cached the first time that id was
-- seen. These four ids were first seen as legendary, so they keep that colour.
-- Fresh ids force a clean query.
UPDATE `item_template` SET `entry` = 1009300 WHERE `entry` = 1009100;
UPDATE `item_template` SET `entry` = 1009302 WHERE `entry` = 1009101;
UPDATE `item_template` SET `entry` = 1009303 WHERE `entry` = 1009102;
UPDATE `item_template` SET `entry` = 1009304 WHERE `entry` = 1009103;

UPDATE `item_dbc` SET `ID` = 1009300 WHERE `ID` = 1009100;
UPDATE `item_dbc` SET `ID` = 1009302 WHERE `ID` = 1009101;
UPDATE `item_dbc` SET `ID` = 1009303 WHERE `ID` = 1009102;
UPDATE `item_dbc` SET `ID` = 1009304 WHERE `ID` = 1009103;

UPDATE `creature_loot_template` SET `Item` = 1009304 WHERE `Item` = 1009103;
UPDATE `creature_loot_template` SET `Item` = 1009302 WHERE `Item` = 1009101;
UPDATE `creature_loot_template` SET `Item` = 1009303 WHERE `Item` = 1009102;

UPDATE `quest_template`
SET `RequiredItemId1` = 1009304, `RequiredItemId2` = 1009302, `RequiredItemId3` = 1009303,
    `RewardItem1` = 1009300
WHERE `ID` IN (9916201, 9916211);
