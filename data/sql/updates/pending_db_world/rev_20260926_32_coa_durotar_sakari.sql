-- CoA Durotar: Sakari's cure (quests 254008-254013) from the Den to Queen Erethina and Orgrimmar.
-- Creature guids 9012550-9012599, gameobject guids 7917200-7917279, gossip menu 932530.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(254011, 'Sakari', NULL, 0, 20, 20, 0, 29, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.25, 1, 1, 1, 1, 0, 0, ''),
(254013, 'Sakari', NULL, 0, 20, 20, 0, 126, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.25, 1, 1, 1, 1, 0, 0, ''),
(254012, 'Queen Erethina', NULL, 932530, 20, 20, 0, 35, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.25, 1, 1, 1, 1, 0, 0, ''),
(254015, 'Xaitoth', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 3, 0, 254015, '', 0, 2.0925, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (254011, 254012, 254013, 254015);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(254011, 0, 254003, 1, 1),
(254013, 0, 254003, 1, 1),
(254012, 0, 10873, 1, 1),
(254015, 0, 850, 1, 1);

-- Sakari's CoA display 254003 lacks model info; values of the stock orc female displays.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 254003;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(254003, 0.236, 1.5, 1, 0);

-- Erethina's greeting: cached npc_text 520009, attribution INFERRED (its text0_1 is a bookshelf line).
DELETE FROM `npc_text` WHERE `ID` = 520009;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(520009, 'Adventurers want fight and kill destroy and maim and crush and burn, yes, yes, yes!$B$BNot fight you, fight no fit for queen, queen watch and command and eat food sisters bring, you want fight, you fight sisters, yes, yes, yes!', 'Adventurers want fight and kill destroy and maim and crush and burn, yes, yes, yes!$B$BNot fight you, fight no fit for queen, queen watch and command and eat food sisters bring, you want fight, you fight sisters, yes, yes, yes!', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 932530;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932530, 520009);

-- ---------------------------------------------------------------------------
-- 2. Objects and loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(95649, 5, 1019810, 'Horde Skeleton RPG Prop', '', '', 0.8, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254001, 3, 3232, 'Strange Flower', '', '', 1, '', 43, 254001, 0, 1, 0, 0, 0, 0, 254008, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254003, 3, 6999, 'Metallic Debris', '', '', 0.3, '', 43, 254003, 0, 1, 0, 0, 0, 0, 254011, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254004, 2, 210, 'Crude Centaur Drawing', '', '', 1.79, '', 0, 93, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3224605, 5, 1014547, 'Bag of Herbs', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3241682, 5, 1026261, 'Dry Harpy Nest', 'questinteract', 'Burning', 1, '', 2160, 0, 0, 3000, 0, 0, 10000, 0, 0, 0, 0, 0, 0, 0, 30602, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3269050, 5, 1030316, 'Harpy Table', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3269051, 5, 1041765, 'Harpy Jar', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3350803, 1, 1030315, 'Harpy Totem', '', 'Burning', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 155781, 0, 0, 0, 0, 0, 1, 0, 0, 1)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (254001, 254003);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(254001, 254005, 0, 100, 1, 1, 0, 1, 1, 'Strange Flower - Strange Flower'),
(254003, 254007, 0, 100, 1, 1, 0, 1, 1, 'Metallic Debris - Metallic Debris');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (254001, 254003);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(254001, 0, 254005),
(254003, 0, 254007);

DELETE FROM `creature_loot_template` WHERE `Entry` = 254015;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(254015, 254006, 0, 100, 1, 1, 0, 1, 1, 'Xaitoth - Xaitoth''s Blood');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` = 254015;
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(254015, 0, 254006);

-- ---------------------------------------------------------------------------
-- 3. Quests
-- ---------------------------------------------------------------------------
-- Chain 254008 -> 254009 -> 254010 -> 254011 -> 254012 -> 254013; 254014 (Barrens) is not built. The upsert
-- leaves the POI columns to the markers file.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(254008, 2, 2, 1, 363, 0, 0, 0, 0, 0, 0, 254009, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 805, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'To Find a Cure', 'Find the strange flower.', 'Hmm. You mix the peacebloom and…no, that isn’t quite right.$B$BThe new recruit, right? Maybe you could help with something. Consider it part of your trials, maybe. Fighting was never my strength. I underwent these trials a few years back, a scorpid almost killed me. I only survived by making a salve with the local cacti and a rare flower.$B$BNot that it did much good. Do you think I’d be cheered on for coming back a failure? I’m a weakling who failed and a coward who couldn’t finish her fight.$B$BBut I’m back here anyways, not because I plan to repeat that but because I found my own path in life, and I’m trying to find a cure to something that’s afflicted us for a while. So if you do better in your trials than I did, I’m looking for another one of those flowers I found. Not for a healing salve this time. Something else. In my trials I found it in the north-west, growing under a tree.', '', 'Return to Sakari at Valley of Trials in Durotar.', 0, 0, 0, 0, 0, 0, 0, 0, 254005, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(254009, 2, 2, 1, 363, 0, 0, 0, 0, 0, 0, 254010, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 5571, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Dangerous Sample', 'Collect demon blood from a strong demon.', 'You have my gratitude. The truth is, this flower is the only lead I have. I’ve gathered plenty of cacti, there’s enough around I didn’t need to venture much off the main road, but the property I observed must have been in the flower. It’s more than most anyone else has found, but I have limited resources, and we don’t even know where the flower originated.$B$BWhat I need to understand is the properties of the demon blood. I’ve taken plenty of my own as samples, but I need something from the source. There’s demons in the cave at the north end of the valley, no? Find me the blood of one there, not any blood, the strongest you can find.$B$BIt will not compare to what the orcs drank of long ago, but perhaps it is at least a start.', '', 'Return to Sakari at Valley of Trials in Durotar.', 0, 0, 0, 0, 0, 0, 0, 0, 254006, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(254010, 2, 2, 1, 14, 0, 0, 0, 0, 0, 0, 254011, 4, 0, 67, 0, 0, 0, 0, 0, 8, 0, 375250, 95, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Knowledge of the Centaurs', 'Search the centaur camp for clues to the flower’s properties.', 'This isn’t enough…it’s a start, yes. But this task will require more. For a start, I need to understand this flower’s properties. I’ve yet to find anyone in the Horde who knows of it, they don’t seem to grow very frequently. But there is another group who may know of natural things.$B$BThe centaurs have lived in Durotar for many years, not that we can just ask them what they know. Still, it’s possible they have some record of this flower. See what you can learn from their camp. I’ll be in Orgrimmar when you’re done.$B$BBe safe. You are already a stronger and braver warrior than I, but with strength and bravery often come foolishness, as much as many orcs are loathe to admit it.', '', 'Search the centaur camp for clues to the flower’s properties', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254011, 2, 2, 1, 14, 0, 0, 0, 0, 0, 0, 254012, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Shinies!', 'Collect metallic debris.', 'You recognize the drawing as a creature you have heard threatens Durotar, a harpy. Perhaps some bits of shiny metal will appease one enough to talk with you.', '', 'Bring the metal to a harpy to the west of Razor Hill', 0, 0, 0, 0, 0, 0, 0, 0, 254007, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, '', '', '', ''),
(254012, 2, 7, 5, 14, 0, 0, 0, 0, 0, 0, 254013, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Queen''s Decree', 'Slay harpies for Queen Erethina.', 'Sisters plan rebellion, yes, yes, yes, ears listen, hear vile traitorous words! Want power, freedom, want to be queen, yes, yes, yes! Killed for this title fairly, sisters just jealous, yes yes yes, jealous traitors they are!$B$BShow sisters who true queen, yes, yes, yes, not all, many, enough! Stop rebellion, and will tell you story of Avianna’s Rose!', '', 'Return to Queen Erethina', 3115, 3116, 0, 0, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254013, 2, 10, 8, 14, 0, 0, 0, 0, 0, 0, 0, 2, 0, 67, 0, 0, 0, 0, 0, 8, 0, 5574, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Avianna''s Rose', 'Bring the information you learned to Sakari in Orgrimmar.', 'Have knowledge, yes, yes, yes! Make skin not green, but Avianna’s Rose rare, very rare, only ever one, no more, sometimes less! Harpy never removed curse, never used magic on Avianna’s Rose. Yet you already have one, yes, yes, yes!$B$BYou bring shinies, crush rebellion, help you, yes, yes, yes! Magic need other material, bright shiny stone, yellow, very shiny, very very very, at south place. Find, use flower, fix curse!', '', 'Bring the information to learned to Sakari in Orgrimmar', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (254008, 254009, 254010, 254011, 254012, 254013);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(254008, 0, 0, 0, 0, 0),
(254009, 0, 0, 254008, 0, 0),
(254010, 0, 0, 254009, 0, 0),
(254011, 0, 0, 254010, 0, 0),
(254012, 0, 0, 254011, 0, 0),
(254013, 0, 0, 254012, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (254008, 254009, 254010, 254011, 254012, 254013);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(254008, 'Growing here in this harsh landscape, in spite of everything against it.$B$BRather familiar, no?$B$BWhen I applied that salve, I noticed something odd. For a few moments, the green tint in my skin faded away on my chest, where I’d applied it. Like it was healing not just the scorpid’s sting, but the Legion’s influence as well.$B$BEven after all these years, the corruption of the fel blood the orcs drank long ago still remains. Green skin, but not just that. Our blood is forever tainted by demons, and it’s hard to say what influence that has. Subtle, perhaps, but it’s always there, within the orcs…and I’m going to find a cure. I might not have strength, or courage…and a lot of us would argue that means I lack honor as well. But I have a knowledge of herbs and alchemy. All I need is the help of someone willing to do what I cannot.$B$BWhat do you say? Will you aid a weakling and a coward?'),
(254009, 'I know the Horde values strength and courage, but as someone without either, I do not like asking you to face against a demon of such power for my sake. Still, I thank you. It is my hope now that this can lead us to a cure. Not right now, maybe, but I am young yet.$B$BGive me a moment, I’ll likely have more requests.'),
(254010, 'A crude drawing seems to depict the flower Sakari spoke of, next to a winged elf woman. Several more crude drawings next to it show the winged elf woman carrying various ores and gems. Perhaps whatever is being depicted knows more about the flower, and would value ores and gems.'),
(254011, 'You bring shinies, yes, yes, yes! Shinies! Shiny-bringer not food today, yes, yes, yes, tomorrow maybe, not today!$B$BShiny-bringer wants something in return, yes, yes, yes! Want harpies to leave, want help in fight, yes, yes, yes, I know your kinda well! Shiny buys day as not-food, no more. But more, yes, do more, do favor, and I tell all you wish, yes, yes, yes!'),
(254012, 'Sisters fear, sisters submit! True queen known, served, served by not-harpy even, yes, yes, yes! You will know of flower now!$B$BStory say harpy mother Avianna die, blood drop grow to single flower, spread long, many years, grow even here, yes, yes, yes! Not know if story is true, story not matter. Avianna’s Rose have great power, remove many curses, many!$B$BStory say harpy use magic with flower, remove curse, not wings, wings not curse, but others, harpy becomes greatest smartest queen, yes, yes, yes! Other curses too maybe, many curses, maybe demon curse too! Special magic, maybe other ways.'),
(254013, 'You talked to a harpy?!$B$BI believe you, of course, you have the honor not to deceive me, I’m sure. They’ve just not been receptive. Of course, we haven’t tried to talk much. Well, if you found out the flower’s properties, I can get started.');

DELETE FROM `quest_request_items` WHERE `ID` IN (254008, 254009, 254010, 254011, 254012, 254013);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(254008, 'I can only hope another flower has grown since that day.'),
(254009, 'You may have to search the cave for one strong enough for my purposes. Don''t do anything reckless.'),
(254010, 'I can only hope they keep some form of record.'),
(254011, 'You search for shinies? Yes, yes, yes, come back with shinies, maybe not eat you!'),
(254012, 'Crush, destroy, show true queen power! Make sisters never speak betrayal again, then tell you secrets of Avianna''s Rose, yes, yes, yes!'),
(254013, 'You still here? Eat you soon, yes, yes, yes, leave now or eat you soon, one day not eat you, no more!');

DELETE FROM `creature_queststarter` WHERE `quest` IN (254008, 254009, 254010, 254011, 254012, 254013);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(254011, 254008),
(254011, 254009),
(254011, 254010),
(254012, 254012),
(254012, 254013);

DELETE FROM `creature_questender` WHERE `quest` IN (254008, 254009, 254010, 254011, 254012, 254013);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(254011, 254008),
(254011, 254009),
(254012, 254011),
(254012, 254012),
(254013, 254013);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (254008, 254009, 254010, 254011, 254012, 254013);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
VALUES
(254004, 254011);

DELETE FROM `gameobject_questender` WHERE `quest` IN (254008, 254009, 254010, 254011, 254012, 254013);
INSERT INTO `gameobject_questender` (`id`, `quest`)
VALUES
(254004, 254010);

-- ---------------------------------------------------------------------------
-- 4. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9012550, 9012551, 9012552, 9012553, 9012554, 9012555, 9012556, 9012557, 9012558, 9012559, 9012560, 9012561, 9012562, 9012563, 9012564, 9012565, 9012566, 9012567, 9012568, 9012569) OR `guid` BETWEEN 9012550 AND 9012599;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9012550, 254011, 1, 0, 0, 1, 1, 0, -556.495, -4218.57, 41.832, 3.61, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sakari: atlas point under the orc tent at the Den front; faces the bubbling cauldron she mixes her salves at'),
(9012551, 254015, 1, 0, 0, 1, 1, 0, -179.73, -4360.58, 68.478, 2.15, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sakari: ST3456 on the raised floor of the Burning Blade Coven; faces back toward the coven mouth'),
(9012552, 254013, 1, 0, 0, 1, 1, 0, 1968.73, -4470.19, 25.92, 1.84, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sakari: ST243 in the Orgrimmar alchemy shop beside the jars; faces the table of vials'),
(9012553, 254012, 1, 0, 0, 1, 1, 0, 580.945, -4549.08, 41.198, 0.21, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sakari: atlas point on top of her Harpy Table (table top 1.14 yd); looks down Razorwind Canyon at her rebel sisters (ST3448)'),
(9012554, 3116, 1, 0, 0, 1, 1, 0, 726, -4450, 15.669, 5.45, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; canyon floor west of the egg ring, below the cliff nests'),
(9012555, 3116, 1, 0, 0, 1, 1, 0, 755, -4466, 15.669, 2.88, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; north of the egg ground by the kodo eggs'),
(9012556, 3116, 1, 0, 0, 1, 1, 0, 752, -4436, 18.542, 4.14, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; north-west rise beside the cactus clump'),
(9012557, 3116, 1, 0, 0, 1, 1, 0, 724, -4484, 15.61, 1.09, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; south-east corner of the egg ground under the Kalidar nest'),
(9012558, 3115, 1, 0, 0, 1, 1, 0, 648, -4533, 8.832, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; canyon floor at the ST3448 mark, below the Stonetalon nest'),
(9012559, 3115, 1, 0, 0, 1, 1, 0, 640, -4545, 8.685, 0.67, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; basin floor west of the Stolen Supply Sack (642, -4559)'),
(9012560, 3115, 1, 0, 0, 1, 1, 0, 628, -4530, 8.94, 6.17, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; middle of the basin, north of the queen''s hill'),
(9012561, 3115, 1, 0, 0, 1, 1, 0, 636, -4500, 11.946, 5.24, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; north-west end of the basin beside the Battered Chest (634, -4488)'),
(9012562, 3115, 1, 0, 0, 1, 1, 0, 616, -4512, 11.777, 5.79, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; west end of the basin, north-west of the Mageroyal (608, -4525)'),
(9012563, 3115, 1, 0, 0, 1, 1, 0, 622, -4556, 8.249, 0.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; east end of the basin below the Dry Harpy Nest cliff'),
(9012564, 3115, 1, 0, 0, 1, 1, 0, 610, -4538, 10.262, 0.11, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; foot of the queen''s hill north of the Copper Vein (598, -4544)'),
(9012565, 3115, 1, 0, 0, 1, 1, 0, 664, -4522, 8.953, 4.04, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Harpy; canyon north-west of the mark, under the Kalidar nest'),
(9012566, 3116, 1, 0, 0, 1, 1, 0, 770, -4400, 19.028, 4.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; north-west flats by the Silverleaf (777, -4406)'),
(9012567, 3116, 1, 0, 0, 1, 1, 0, 728, -4412, 18.443, 4.87, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; west flats where the egg ground opens toward the canyon exit'),
(9012568, 3116, 1, 0, 0, 1, 1, 0, 702, -4494, 14.739, 0.77, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; channel from the egg ground to the harpy canyon'),
(9012569, 3116, 1, 0, 0, 1, 1, 0, 758, -4410, 19.188, 4.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Razorwind Canyon: Dustwind Pillager; flat north-west corner of the egg ground');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9012550 AND 9012599;

DELETE FROM `gameobject` WHERE `guid` IN (7917200, 7917201, 7917202, 7917203, 7917204, 7917205, 7917206, 7917207, 7917210, 7917211, 7917212, 7917213, 7917214, 7917215, 7917216, 7917217, 7917218, 7917219, 7917220, 7917221, 7917222, 7917223, 7917224, 7917225, 7917226, 7917227) OR `guid` BETWEEN 7917200 AND 7917279;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7917200, 3224605, 1, 0, 0, 1, 1, -557.187, -4216.79, 41.859, 1.94, 0, 0, 0.824886, 0.5653, 120, 100, 1, '', 'CoA Sakari: atlas point, Sakari''s herb bag against the anvil stone'),
(7917201, 254001, 1, 0, 0, 1, 1, -320.429, -4121.06, 51.118, 4.1, 0, 0, 0.887362, -0.461073, 60, 100, 1, '', 'CoA Sakari: atlas point under the Durotartree03 at Zeb''Goro (ST3458 0.3 yd); the one rare flower the quest names'),
(7917202, 254004, 1, 0, 0, 1, 1, -967.398, -4423.86, 29.263, 2.8, 0, 0, 0.98545, 0.169967, 120, 100, 1, '', 'CoA Sakari: ST992 on the floor of the Kolkar Crag tent; laid out toward the bonfire at the tent mouth'),
(7917203, 3269050, 1, 0, 0, 1, 1, 580.914, -4549.03, 40.055, 0.21, 0, 0, 0.104807, 0.994493, 120, 100, 1, '', 'CoA Sakari: atlas point, Erethina''s table on the hilltop'),
(7917204, 3350803, 1, 0, 0, 1, 1, 578.896, -4549.03, 40.37, 0.21, 0, 0, 0.104807, 0.994493, 120, 100, 1, '', 'CoA Sakari: atlas point, the totem behind the queen'),
(7917205, 3241682, 1, 0, 0, 1, 1, 621.408, -4547.28, 28.772, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Sakari: atlas point, nest on the cliff face below the camp'),
(7917206, 3269051, 1, 0, 0, 1, 1, 649.859, -4560.36, 18.148, 2.4, 0, 0, 0.932039, 0.362358, 120, 100, 1, '', 'CoA Sakari: atlas point, jar at the foot of the rock'),
(7917207, 95649, 1, 0, 0, 1, 1, 646.633, -4556.69, 20.019, 0.8, 0, 0, 0.389418, 0.921061, 120, 100, 1, '', 'CoA Sakari: atlas point, skeleton sprawled on the rock ledge'),
(7917210, 254003, 1, 0, 0, 1, 1, -486.063, -4753.15, 34.979, 0.4, 0, 0, 0.198669, 0.980067, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; atlas point on the west verge by the boar ground'),
(7917211, 254003, 1, 0, 0, 1, 1, -476, -4752, 35.141, 2.1, 0, 0, 0.867423, 0.497571, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; west verge 10 yd north of the atlas piece, 7 yd off the road edge'),
(7917212, 254003, 1, 0, 0, 1, 1, -473.44, -4801.13, 36.644, 5.2, 0, 0, 0.515501, -0.856889, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; Questie point among the cactus clump east of the road'),
(7917213, 254003, 1, 0, 0, 1, 1, -485, -4806, 37.393, 1.3, 0, 0, 0.605186, 0.796084, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; open ground south-west of the cactus clump'),
(7917214, 254003, 1, 0, 0, 1, 1, -434.32, -4766.76, 35.666, 3, 0, 0, 0.997495, 0.070737, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; Questie point on the west verge above the bend'),
(7917215, 254003, 1, 0, 0, 1, 1, -422, -4772, 35.005, 0.9, 0, 0, 0.434966, 0.900447, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; west verge 13 yd further north, 7 yd off the road edge'),
(7917216, 254003, 1, 0, 0, 1, 1, -387.8, -4820.16, 36.746, 4.4, 0, 0, 0.808496, -0.588501, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; Questie point on the east side of the southern bend'),
(7917217, 254003, 1, 0, 0, 1, 1, -398, -4826, 36.941, 2.6, 0, 0, 0.963558, 0.267499, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; flat ground behind it, 22 yd off the road'),
(7917218, 254003, 1, 0, 0, 1, 1, -277.15, -4779.98, 31.461, 1.7, 0, 0, 0.75128, 0.659983, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; Questie point on the west bank of the road'),
(7917219, 254003, 1, 0, 0, 1, 1, -289, -4785, 32.561, 5.9, 0, 0, 0.190423, -0.981702, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; west bank 13 yd south, 10 yd off the road edge'),
(7917220, 254003, 1, 0, 0, 1, 1, -222.53, -4815.4, 24.857, 3.6, 0, 0, 0.973848, -0.227202, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; Questie point on the southern branch track at the junction'),
(7917221, 254003, 1, 0, 0, 1, 1, -230, -4808, 28.491, 0.2, 0, 0, 0.099833, 0.995004, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; rise west of the junction track'),
(7917222, 254003, 1, 0, 0, 1, 1, -144.65, -4746.66, 22.84, 4.9, 0, 0, 0.637765, -0.770231, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; Questie point on the west road edge'),
(7917223, 254003, 1, 0, 0, 1, 1, -133, -4738, 24.806, 2.3, 0, 0, 0.912764, 0.408487, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; slope above the west road edge'),
(7917224, 254003, 1, 0, 0, 1, 1, -78.75, -4754.59, 20.868, 1.1, 0, 0, 0.522687, 0.852525, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; Questie point on the east road edge'),
(7917225, 254003, 1, 0, 0, 1, 1, -90, -4760, 21.226, 3.8, 0, 0, 0.9463, -0.32329, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; flat east verge 12 yd off the road edge'),
(7917226, 254003, 1, 0, 0, 1, 1, -9.239, -4760.6, 24.967, 5.5, 0, 0, 0.381661, -0.924302, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; ST3447, the 254011 objective point (Questie piece 2.1 yd away)'),
(7917227, 254003, 1, 0, 0, 1, 1, 3, -4768, 25.749, 0.7, 0, 0, 0.342898, 0.939373, 60, 100, 1, '', 'CoA Durotar road: Metallic Debris; rise east of the road near Razor Hill');

DELETE FROM `gameobject_addon` WHERE `guid` BETWEEN 7917200 AND 7917279;
