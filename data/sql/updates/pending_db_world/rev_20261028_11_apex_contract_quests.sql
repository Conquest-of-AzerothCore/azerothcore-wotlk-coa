-- Apex contract questline: two faction huntmasters, one contract each, then the
-- three-hide hunt that pays out the Skin-Peeler diploma and the Apex Hunter title.

DELETE FROM `creature_queststarter` WHERE `quest` BETWEEN 9916200 AND 9916211;
DELETE FROM `creature_questender` WHERE `quest` BETWEEN 9916200 AND 9916211;
DELETE FROM `quest_template` WHERE `ID` BETWEEN 9916200 AND 9916211;
DELETE FROM `gossip_menu` WHERE `MenuID` IN (9916113, 9916114);
DELETE FROM `npc_text` WHERE `ID` IN (900001, 900002);
DELETE FROM `creature_loot_template` WHERE `Entry` IN (9916212, 9916213, 9916214);

-- ---- gossip: each huntmaster speaks in his own voice -----------------------
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES
(900001, 'Mind the pelts on the rack, they''re curing. ...You''ve the look of someone who''s killed things that fought back. Good. Sit down.'),
(900002, 'Ya smell like de road, not de city. Good. Zul''khar don''t waste words on city hunters.');

INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9916113, 900001),
(9916114, 900002);

UPDATE `creature_template` SET `gossip_menu_id` = 9916113 WHERE `entry` = 9916113;
UPDATE `creature_template` SET `gossip_menu_id` = 9916114 WHERE `entry` = 9916114;

-- ---- the contract: a breadcrumb that opens the hunt ------------------------
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `LogTitle`, `LogDescription`, `QuestDescription`,
 `QuestCompletionLog`, `QuestSortID`, `QuestInfoID`, `Flags`, `RewardNextQuest`) VALUES
(9916200, 0, 58, 58, 'The Apex Contract',
 'Read the bounty board and take up the hunt.',
 'Three contracts are nailed to the board behind me, older ones under them, all of them failures. Read them, then decide whether you still like the idea.',
 'Return to Torvald Greyfeather in the Dwarven District of Stormwind.', 0, 0, 0, 9916201),
(9916210, 0, 58, 58, 'The Apex Contract',
 'Read the bounty board and take up de hunt.',
 'Three contracts nailed to de board behind me, old ones under dem, all of dem failures. Read dem, den decide if ya still like de idea.',
 'Return to Zul''khar in de Valley of Honor of Orgrimmar.', 0, 0, 0, 9916211);

-- ---- the hunt: the three hides, then the diploma ---------------------------
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `LogTitle`, `LogDescription`, `QuestDescription`,
 `QuestCompletionLog`, `QuestSortID`, `QuestInfoID`, `Flags`,
 `RequiredItemId1`, `RequiredItemCount1`, `RequiredItemId2`, `RequiredItemCount2`,
 `RequiredItemId3`, `RequiredItemCount3`,
 `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`,
 `RewardItem1`, `RewardAmount1`, `RewardTitle`) VALUES
(9916201, 0, 60, 58, 'The Three Apex Hunts',
 'Bring the hides of Nytharos, Stormfang and Vaelthara to Torvald Greyfeather.',
 'I''ve chased three beasts across this continent and lost every time. Not to their teeth. To their patience. Nytharos sits in the drowned ruins and lets the sea do his work for him. Stormfang runs the Hinterlands ridge and never stands still long enough to be struck. Vaelthara has been hunted by ogres for twenty years, and she learned to hunt back. Bring me their hides, and skin them yourself. I''ll know if you didn''t.',
 'Return to Torvald Greyfeather in the Dwarven District of Stormwind.', 0, 0, 0,
 1009103, 1, 1009101, 1, 1009102, 1,
 'Tide-Warped Hide', 'Stormfang Pelt', 'Scarred Owlcat Pelt',
 1009100, 1, 231),
(9916211, 0, 60, 58, 'The Three Apex Hunts',
 'Bring de hides of Nytharos, Stormfang and Vaelthara to Zul''khar.',
 'Three beasts out dere wearing de best hides on Azeroth. Nytharos, de drowned one. He don''t chase ya, he wait, and de water does de killing. Stormfang, de storm-worg. He move like lightning and hit like it too. Vaelthara, de scarred matriarch. Ogres hunt her twenty years, now she hunt everything. Kill dem. Skin dem yourself. A hide bought from a hunter is just leather.',
 'Return to Zul''khar in de Valley of Honor of Orgrimmar.', 0, 0, 0,
 1009103, 1, 1009101, 1, 1009102, 1,
 'Tide-Warped Hide', 'Stormfang Pelt', 'Scarred Owlcat Pelt',
 1009100, 1, 231);

-- ---- who offers and who takes them ----------------------------------------
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(9916113, 9916200), (9916113, 9916201),
(9916114, 9916210), (9916114, 9916211);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(9916113, 9916200), (9916113, 9916201),
(9916114, 9916210), (9916114, 9916211);

-- ---- the hides drop only for someone on the hunt ---------------------------
INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(9916214, 1009103, 0, 100, 1, 1, 0, 1, 1, 'Tide-Warped Hide, quest only'),
(9916212, 1009101, 0, 100, 1, 1, 0, 1, 1, 'Stormfang Pelt, quest only'),
(9916213, 1009102, 0, 100, 1, 1, 0, 1, 1, 'Scarred Owlcat Pelt, quest only');
