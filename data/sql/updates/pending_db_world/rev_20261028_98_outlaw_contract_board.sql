-- Outlaw's Contract Board: the neutral call board of the goblin towns (gameobject 1804480). Its template and the
-- High-Risk quest 982019 were missing, so the client's Outlaw board (CallBoardCore.lua outLawCallBoards) never
-- appeared, and the portable Outlaw board 422000 opened with every category empty.
-- Template: AscensionDB archive (hertigservices.github.io/ascension-data) revision d6494ceb3150, built 2026-09-12,
-- Client captures of 1804480 in seven modes, captured 2025-12-21 to 2026-09-10.
-- Spawns: the Ratchet position is the Bronzebeard GameObjects capture in the same archive's catalogue. The other four
-- towns come from the saved db.ascension.gg page of quest 1007385 (db.exil.es archive, 2026-10-04), which lists the
-- board as a giver at map points Barrens 62.4/37.9, Stranglethorn 28.1/75.3, Tanaris 51.7/28.7, Winterspring
-- 61.2/38.2 and Netherstorm 32.8/64.4; their positions are converted through WorldMapArea and are estimated, their
-- heights are the ground of the nearest spawns, and their facing is unknown.
-- Quests: on that page the board gives the profession call board quest 1007385 to both factions, like the
-- faction boards. Inferred from that: both Outlaw boards give and take back every quest that the Hero's Call
-- Board (402000) and the Warchief's Command Board (402001) both give. The High-Risk quest 982019 "For The Legion:
-- A Heap of..." (same archive, questcache Client captures) returns "to your masters", the Outlaw side, and is
-- given only here. The other fifteen For The Legion quests stay out: their objective items have no source in this
-- world.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data1`, `Data2`, `Data3`, `Data8`,
`ScriptName`)
VALUES
(1804480, 2, 3053, 'Outlaw''s Contract Board', 2, 7009, 1, 30148, 1, 'native_ascension_callboard')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
`size` = VALUES(`size`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`),
`Data8` = VALUES(`Data8`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `gameobject` WHERE `guid` BETWEEN 1804481 AND 1804485;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
  `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`,
  `state`, `ScriptName`, `VerifiedBuild`, `Comment`)
VALUES
(1804481, 1804480, 1, 17, 392, 1, 1, -945.684, -3701.34, 7.432, 0, 0, 0, 0, 1, 300, 0, 1, '', NULL,
  'Outlaw''s Contract Board, Ratchet'),
(1804482, 1804480, 0, 33, 35, 1, 1, -14371.26, 427.22, 7.46, 0, 0, 0, 0, 1, 300, 0, 1, '', NULL,
  'Outlaw''s Contract Board, Booty Bay (estimated)'),
(1804483, 1804480, 1, 440, 976, 1, 1, -7195.2, -3785.3, 8.8, 0, 0, 0, 0, 1, 300, 0, 1, '', NULL,
  'Outlaw''s Contract Board, Gadgetzan (estimated)'),
(1804484, 1804480, 1, 618, 2255, 1, 1, 6724.99, -4661.2, 720.9, 0, 0, 0, 0, 1, 300, 0, 1, '', NULL,
  'Outlaw''s Contract Board, Everlook (estimated)'),
(1804485, 1804480, 530, 3523, 3712, 1, 1, 3062.25, 3654.73, 142.9, 0, 0, 0, 0, 1, 300, 0, 1, '', NULL,
  'Outlaw''s Contract Board, Area 52 (estimated)');

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`,
  `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`,
  `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`,
  `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`,
  `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`,
  `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`,
  `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`,
  `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`,
  `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`,
  `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`,
  `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`,
  `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`,
  `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`,
  `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`,
  `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGo2`,
  `RequiredNpcOrGoCount2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`,
  `RequiredItemId1`, `RequiredItemCount1`, `RequiredItemId2`, `RequiredItemCount2`, `RequiredItemId3`,
  `RequiredItemCount3`, `RequiredItemId4`, `RequiredItemCount4`, `RequiredItemId5`, `RequiredItemCount5`,
  `RequiredItemId6`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`,
  `VerifiedBuild`)
VALUES
(982019, 2, 70, 70, 3523, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4096, 0, 375250, 900, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'For The Legion: A Heap of... (High-Risk)', 'Slay Zaxxis Raiders and obtain Ethereal Technology from The Heap.', 'My scouts report skirmishes between the Horde and Alliance. You have been commanded to prevent either faction from accomplishing their goals in the conflict area.  Slaughter the Zaxxis Raiders at The Heap and grab any tech you find.', '', 'Return to your masters.', 18875, 25, 0, 0, 0, 0, 0, 0, 28457, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 12340)
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`),
  `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`),
  `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`),
  `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`),
  `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`),
  `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`),
  `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`),
  `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`),
  `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`),
  `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`),
  `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`),
  `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`),
  `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`),
  `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`),
  `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`),
  `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`),
  `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`),
  `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`),
  `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`),
  `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`),
  `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`),
  `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`),
  `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`),
  `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`),
  `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`),
  `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`),
  `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`),
  `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`),
  `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`),
  `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`),
  `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`),
  `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`),
  `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`),
  `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`),
  `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`),
  `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`),
  `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`),
  `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`),
  `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`),
  `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`),
  `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`),
  `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`),
  `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`),
  `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`),
  `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`),
  `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`),
  `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemId2` = VALUES(`RequiredItemId2`),
  `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemId3` = VALUES(`RequiredItemId3`),
  `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemId4` = VALUES(`RequiredItemId4`),
  `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemId5` = VALUES(`RequiredItemId5`),
  `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemId6` = VALUES(`RequiredItemId6`),
  `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`),
  `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`),
  `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `quest_template_addon` WHERE `ID` = 982019;
INSERT INTO `quest_template_addon` (`ID`, `SpecialFlags`)
VALUES
(982019, 1);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 19 AND `SourceEntry` = 982019;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(19, 0, 982019, 0, 0, 1, 0, 1004019, 0, 0, 0, 0, 0, '', 'High-Risk quest requires the High-Risk ruleset');

DELETE FROM `gameobject_queststarter` WHERE `id` IN (1804480, 422000);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
SELECT `board`.`id`, `hero`.`quest`
FROM `gameobject_queststarter` AS `hero`
JOIN `gameobject_queststarter` AS `warchief` ON `warchief`.`quest` = `hero`.`quest` AND `warchief`.`id` = 402001
CROSS JOIN (SELECT 1804480 AS `id` UNION ALL SELECT 422000) AS `board`
WHERE `hero`.`id` = 402000
UNION ALL
SELECT 1804480, 982019
UNION ALL
SELECT 422000, 982019;

DELETE FROM `gameobject_questender` WHERE `id` IN (1804480, 422000);
INSERT INTO `gameobject_questender` (`id`, `quest`)
SELECT `board`.`id`, `hero`.`quest`
FROM `gameobject_questender` AS `hero`
JOIN `gameobject_questender` AS `warchief` ON `warchief`.`quest` = `hero`.`quest` AND `warchief`.`id` = 402001
CROSS JOIN (SELECT 1804480 AS `id` UNION ALL SELECT 422000) AS `board`
WHERE `hero`.`id` = 402000
UNION ALL
SELECT 1804480, 982019
UNION ALL
SELECT 422000, 982019;
