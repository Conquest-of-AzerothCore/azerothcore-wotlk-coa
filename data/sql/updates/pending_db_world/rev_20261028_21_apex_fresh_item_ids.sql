-- The trophy items move from their authored ids straight to the final ones. No 10092xx id is
-- touched: those belong to real items (Combat Tome: Back Stab IX among them).
START TRANSACTION;

DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` = 1009100 AND t.`entry` = 1009300;
DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` = 1009101 AND t.`entry` = 1009302;
DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` = 1009102 AND t.`entry` = 1009303;
DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` = 1009103 AND t.`entry` = 1009304;
UPDATE `item_template` SET `entry` = 1009300 WHERE `entry` = 1009100;
UPDATE `item_template` SET `entry` = 1009302 WHERE `entry` = 1009101;
UPDATE `item_template` SET `entry` = 1009303 WHERE `entry` = 1009102;
UPDATE `item_template` SET `entry` = 1009304 WHERE `entry` = 1009103;

UPDATE `item_dbc` SET `ID` = 1009300 WHERE `ID` = 1009100;
UPDATE `item_dbc` SET `ID` = 1009302 WHERE `ID` = 1009101;
UPDATE `item_dbc` SET `ID` = 1009303 WHERE `ID` = 1009102;
UPDATE `item_dbc` SET `ID` = 1009304 WHERE `ID` = 1009103;

UPDATE `creature_loot_template` SET `Item` = 1009302 WHERE `Item` = 1009101;
UPDATE `creature_loot_template` SET `Item` = 1009303 WHERE `Item` = 1009102;
UPDATE `creature_loot_template` SET `Item` = 1009304 WHERE `Item` = 1009103;

UPDATE `quest_template` SET `RequiredItemId1` = 1009304 WHERE `RequiredItemId1` = 1009103;
UPDATE `quest_template` SET `RequiredItemId2` = 1009302 WHERE `RequiredItemId2` = 1009101;
UPDATE `quest_template` SET `RequiredItemId3` = 1009303 WHERE `RequiredItemId3` = 1009102;
UPDATE `quest_template` SET `RewardItem1` = 190191 WHERE `RewardItem1` IN (1009100, 1009300);

COMMIT;
