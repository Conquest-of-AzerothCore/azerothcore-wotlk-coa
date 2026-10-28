-- Collapse every trophy item onto its final id, whichever intermediate id it is on.
-- Rev 20 and rev 21 both renumbered these rows, so a clean database hit a duplicate
-- primary key. Each target is cleared only when a source row still has to move onto it.
DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` IN (1009100, 1009200) AND t.`entry` = 1009300;
DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` IN (1009101, 1009201) AND t.`entry` = 1009302;
DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` IN (1009102, 1009202) AND t.`entry` = 1009303;
DELETE t FROM `item_template` t JOIN `item_template` s ON s.`entry` IN (1009103, 1009203) AND t.`entry` = 1009304;
UPDATE `item_template` SET `entry` = 1009300 WHERE `entry` IN (1009100, 1009200);
UPDATE `item_template` SET `entry` = 1009302 WHERE `entry` IN (1009101, 1009201);
UPDATE `item_template` SET `entry` = 1009303 WHERE `entry` IN (1009102, 1009202);
UPDATE `item_template` SET `entry` = 1009304 WHERE `entry` IN (1009103, 1009203);

DELETE d FROM `item_dbc` d JOIN `item_dbc` s ON s.`ID` IN (1009100, 1009200) AND d.`ID` = 1009300;
DELETE d FROM `item_dbc` d JOIN `item_dbc` s ON s.`ID` IN (1009101, 1009201) AND d.`ID` = 1009302;
DELETE d FROM `item_dbc` d JOIN `item_dbc` s ON s.`ID` IN (1009102, 1009202) AND d.`ID` = 1009303;
DELETE d FROM `item_dbc` d JOIN `item_dbc` s ON s.`ID` IN (1009103, 1009203) AND d.`ID` = 1009304;
UPDATE `item_dbc` SET `ID` = 1009300 WHERE `ID` IN (1009100, 1009200);
UPDATE `item_dbc` SET `ID` = 1009302 WHERE `ID` IN (1009101, 1009201);
UPDATE `item_dbc` SET `ID` = 1009303 WHERE `ID` IN (1009102, 1009202);
UPDATE `item_dbc` SET `ID` = 1009304 WHERE `ID` IN (1009103, 1009203);

UPDATE `creature_loot_template` SET `Item` = 1009302 WHERE `Item` IN (1009101, 1009201);
UPDATE `creature_loot_template` SET `Item` = 1009303 WHERE `Item` IN (1009102, 1009202);
UPDATE `creature_loot_template` SET `Item` = 1009304 WHERE `Item` IN (1009103, 1009203);

UPDATE `quest_template` SET `RequiredItemId1` = 1009304 WHERE `RequiredItemId1` IN (1009103, 1009203);
UPDATE `quest_template` SET `RequiredItemId2` = 1009302 WHERE `RequiredItemId2` IN (1009101, 1009201);
UPDATE `quest_template` SET `RequiredItemId3` = 1009303 WHERE `RequiredItemId3` IN (1009102, 1009202);
UPDATE `quest_template` SET `RewardItem1` = 190191 WHERE `RewardItem1` IN (1009100, 1009200, 1009300);
