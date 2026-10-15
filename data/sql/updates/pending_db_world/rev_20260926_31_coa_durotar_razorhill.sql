-- CoA Durotar, Razor Hill: Karagar, Rilly, Dirgran and Bagamul (quests 1660061-1660065) with Rivenruin Cave
-- and the mine peons; the Razor Hill rows CoA moved, its townsfolk and kennel wolves, and its holiday rows.
-- Creature guids 9012300-9012549, gameobject guids 7917100-7917199, gossip menus 932515-932529.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stock looks stand in where the CoA display is missing from the client. 162949 is the same row that
-- rev_20260926_21 writes.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(162839, 'Karagar', NULL, 0, 22, 22, 0, 29, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162840, 'Rilly', NULL, 0, 13, 13, 0, 29, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162838, 'Foreman Dirgran', NULL, 0, 10, 10, 0, 29, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(162836, 'Thirsty Peon', NULL, 932515, 8, 8, 0, 29, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 0.93, 1, 1, 1, 1, 0, 162949, ''),
(162949, '[TG] Water Tauren', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 130, 0, ''),
(162841, 'Bagamul Skyfang', NULL, 932516, 41, 41, 0, 29, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162834, 'Rivenruin Myrmidon', NULL, 0, 6, 7, 0, 74, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162835, 'Rivenruin Sorceress', NULL, 0, 6, 7, 0, 74, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 0.96, 1.5, 1, 1, 1, 0, 0, ''),
(162916, 'Rivenruin Brute', NULL, 0, 8, 8, 0, 74, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 5, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162830, 'Thol''gark', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162831, 'Shagara', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162832, 'Zagrah', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162833, 'Kor''gar', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162956, 'Druzzak', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162957, 'Ragrath', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162958, 'Zann''jaro', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162959, 'Yaz''mora', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162966, 'Drogra', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162967, 'Krashna', NULL, 0, 10, 10, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162928, 'Orphan Child', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(162929, 'Grunt Zargul', NULL, 0, 30, 30, 0, 85, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (162830, 162831, 162832, 162833, 162834, 162835, 162836, 162838, 162839, 162840, 162841, 162916, 162928, 162929, 162949, 162956, 162957, 162958, 162959, 162966, 162967);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162839, 0, 11894, 1, 1),
(162840, 0, 7216, 1, 1),
(162838, 0, 16973, 1, 1),
(162836, 0, 23037, 1, 1),
(162836, 1, 23038, 1, 1),
(162949, 0, 11686, 1, 1),
(162841, 0, 18909, 1, 1),
(162834, 0, 4923, 1, 1),
(162835, 0, 11260, 1, 1),
(162916, 0, 67527, 1, 1),
(162830, 0, 1370, 1, 1),
(162831, 0, 31416, 1, 1),
(162832, 0, 11858, 1, 1),
(162833, 0, 11860, 1, 1),
(162956, 0, 19182, 1, 1),
(162957, 0, 11859, 1, 1),
(162958, 0, 19186, 1, 1),
(162959, 0, 19185, 1, 1),
(162966, 0, 11857, 1, 1),
(162967, 0, 19181, 1, 1),
(162928, 0, 14589, 1, 1),
(162929, 0, 9799, 1, 1);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 67527;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(67527, 1.3, 1.95, 0, 0);

-- Shared listen-credit marker, the same row as rev_20260923_00 (Goldshire).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `rank`, `unit_class`, `unit_flags`, `type`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `gossip_menu_id`)
VALUES
(162921, '[KC] Listen to Aliscar Lend', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `rank` = VALUES(`rank`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `gossip_menu_id` = VALUES(`gossip_menu_id`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 162921;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162921, 0, 11686, 1, 1);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
-- Greetings are cached npc_text; option texts are INFERRED. 932516 was an earlier Bagamul greeting.
DELETE FROM `npc_text` WHERE `ID` IN (85189, 85204, 932516);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(85204, '<The orc’s clumsy movements betray his meager strength. He’s sweating from every pore, but the heat inside the mine is so furnace-hot the sweat vanishes before it ever puddles.>', '<The orc’s clumsy movements betray his meager strength. He’s sweating from every pore, but the heat inside the mine is so furnace-hot the sweat vanishes before it ever puddles.>', 0, 0, 1),
(85189, '<The gray-haired orc sits with his legs dangling. Razor Hill sprawls beneath you like a miniature Orgrimmar.>', '<The gray-haired orc sits with his legs dangling. Razor Hill sprawls beneath you like a miniature Orgrimmar.>', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932515, 932516);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932515, 85204),
(932516, 85189);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932515, 932516);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932515, 0, 0, 'Here, have a drink of cool water.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932516, 0, 0, '<Stay a while and listen.>', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (932515, 932516) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 932515, 0, 0, 0, 9, 0, 1660064, 0, 0, 0, 0, 0, '', 'show only while quest 1660064 taken'),
(15, 932515, 0, 0, 0, 2, 0, 558974, 1, 0, 0, 0, 0, '', 'show only while item 558974 held'),
(15, 932516, 0, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken');

-- ---------------------------------------------------------------------------
-- 3. Elven Relics of Old
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300551, 3, 87038, 'Elven Relic of Old', '', '', 1, '', 1689, 2300551, 0, 1, 0, 0, 0, 0, 1660063, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300553, 3, 87036, 'Elven Relic of Old', '', '', 1, '', 1689, 2300551, 0, 1, 0, 0, 0, 0, 1660063, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300554, 3, 87035, 'Elven Relic of Old', '', '', 1, '', 1689, 2300551, 0, 1, 0, 0, 0, 0, 1660063, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300555, 3, 87034, 'Elven Relic of Old', '', '', 1, '', 1689, 2300551, 0, 1, 0, 0, 0, 0, 1660063, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300556, 3, 87032, 'Elven Relic of Old', '', '', 1, '', 1689, 2300551, 0, 1, 0, 0, 0, 0, 1660063, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300557, 3, 87031, 'Elven Relic of Old', '', '', 1, '', 1689, 2300551, 0, 1, 0, 0, 0, 0, 1660063, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300558, 3, 87029, 'Elven Relic of Old', '', '', 1, '', 1689, 2300551, 0, 1, 0, 0, 0, 0, 1660063, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300551;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300551, 558966, 0, 100, 1, 1, 0, 1, 1, 'Elven Relic of Old - Elven Relic of Old');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (2300551, 2300553, 2300554, 2300555, 2300556, 2300557, 2300558);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(2300551, 0, 558966),
(2300553, 0, 558966),
(2300554, 0, 558966),
(2300555, 0, 558966),
(2300556, 0, 558966),
(2300557, 0, 558966),
(2300558, 0, 558966);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- 1660022 -> 1660061 -> {1660062, 1660063}; 1660064 and 1660065 stand alone. The upsert leaves the POI
-- columns to the markers file.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660061, 2, 8, 5, 14, 0, 0, 0, 0, 0, 0, 1660062, 4, 83, 114, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302014, 1, 2302019, 1, 2302024, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Esgramor''s Master', 'Speak with Karagar in Razor Hill.', 'The Valley of Trials lived up to its name with you, friend.$b$bMy place is here, but the road''s calling you. And I think I''ve a fair guess where you''ll head next.$b$bI know a sage in Razor Hill who could use your help. His name is Karagar. Find him, and while you''re at it, tell him everything about Hirsutta, the ritual, and your heroic intervention to foil her plans.', '', 'Speak with Karagar.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660062, 2, 8, 5, 14, 0, 0, 0, 0, 0, 0, 0, 5, 350, 382, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302029, 1, 2302034, 1, 2302039, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Echoes of Hirsutta', 'Defeat naga in Rivenruin Cave on the Durotar coast.', 'The powers Hirsutta loosed drew the eye of the ever-hungry naga that prowl Durotar''s shores.$b$bEver crossed paths with one? Elf-and-serpent hybrids. They''ve slithered out of the sea and holed up in the ruins of a coastal cave, east of here.$b$bI doubt they know exactly what sparked the surge they sensed, but they''re here to probe its nature. Sooner or later, they''ll be a problem.$b$bUnless you see to them first.', '', 'Return to Karagar.', 162834, 162835, 162916, 0, 10, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660063, 2, 8, 5, 14, 0, 0, 0, 0, 0, 0, 0, 5, 350, 382, 0, 0, 0, 0, 0, 8, 0, 2302044, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Auction the Past', 'Recover Elven Relics of Old from the ruins in Rivenruin Cave, Durotar.', 'You here about the naga?$b$bPerfect!$b$bSee, I was poking around the cave ruins, scooping up elven relics to flip at auction (you''d be amazed what those antiques fetch) when the first naga showed up.$b$bI had to hightail it! And, as you can imagine, I barely grabbed a thing.$b$bSince you''re heading into the cave anyway, mind picking up a few relics for me? I''ll cut you in for a percentage of whatever I pull at the Auction House!', '', 'Return to Rilly.', 0, 0, 0, 0, 0, 0, 0, 0, 558966, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, '', '', '', ''),
(1660064, 2, 8, 5, 14, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 558973, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302049, 1, 2302054, 1, 2302059, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Durotar''s Dire Drought', 'Fill the pitcher with water from one of the pools outside Razor Hill, then give the mine peons a drink.', 'New to Razor Hill?$b$bName''s Dirgran; foreman over the peons working this mine.$b$bWant to earn a little coin?$b$bI need someone to fill this pitcher and head into the mine to slake my peons'' thirst.$b$bYou''ve noticed, I''m sure, doesn''t take a keen eye, that water''s scarce in Durotar. But there are a few pools just outside town, by the road, still fit to drink.', '', 'Speak with Dirgran.', 162949, 0, 0, 0, 5, 0, 0, 0, 558974, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Thirsty peons served', '', '', ''),
(1660065, 2, 8, 5, 14, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stay a While', 'Take a moment from the noise and haste and stay a while to listen to Bagamul Skyfang.', 'Sit down, don''t worry. There''s room for both of us.$b$b<The old orc gestures in welcome, murmuring as if to himself.>$b$b<Perhaps he has something worth sharing.>', '', 'Say goodbye to Bagamul Skyfang.', 162921, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Listen to Bagamul Skyfang', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660061, 1660062, 1660063, 1660064, 1660065);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660061, 0, 0, 1660022, 0, 0),
(1660062, 0, 0, 1660061, 0, 0),
(1660063, 0, 0, 1660061, 0, 0),
(1660064, 0, 0, 0, 1, 0),
(1660065, 0, 0, 0, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660061, 1660062, 1660063, 1660064, 1660065);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660061, '<The old orc listens to your account of the Valley of Trials with a half-lidded stare.>$B$BI never liked that Hirsutta. And I never trusted her voodoo. Shame time proved me right.$B$BIt''s a blessing you managed to bring her down. But I fear the echo of her ambition won''t die quickly. The consequences of her ritual are reverberating even here, in Razor Hill.'),
(1660062, '<Though the old orc''s eyes remain shut, he senses your presence all the same.>$B$BThe naga are dead.$B$BI felt it in the earth; it whispered every step you took into my ear. The water told me too, reddened by their blood.$B$BYou have my thanks, $C.'),
(1660063, '<The goblin''s eyes light up like a kid handed candy when he sees you hauling in the elven relics.>$B$BSplendid! Wonderful! Phenomenal!$B$BI''m gonna make a killing on this. At least… <he cuts himself off before naming a number. He puckers up and pretends to take a closer look.>$B$BMaybe I got a little carried away. Look at this, the condition''s awful! No one''s paying top coin for something this beat-up…$B$BAnyway. Can''t say I don''t keep my promises. Here''s a little payment for the effort… symbolic, of course.'),
(1660064, 'Don''t ask me how, but I''d swear it''s hotter in there than out here.$B$BHardly a day goes by without a peon keeling over.$B$BThey''ll be grateful for the cool water you brought them.'),
(1660065, 'Thank you for the company, $C.$B$BFew bother to listen to this old orc.');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660061, 1660062, 1660063, 1660064, 1660065);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660062, '<The elder closes his eyes, a gesture of deep focus and endless patience.>'),
(1660063, 'Just imagine the money we can make!'),
(1660064, 'I wouldn''t mind a swig of cold water myself…');

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660061, 1660062, 1660063, 1660064, 1660065);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(161732, 1660061),
(162839, 1660062),
(162840, 1660063),
(162838, 1660064),
(162841, 1660065);

DELETE FROM `creature_questender` WHERE `quest` IN (1660061, 1660062, 1660063, 1660064, 1660065);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(162839, 1660061),
(162839, 1660062),
(162840, 1660063),
(162838, 1660064),
(162841, 1660065);

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9012300, 9012301, 9012302, 9012303, 9012304, 9012305, 9012306, 9012310, 9012311, 9012312, 9012313, 9012314, 9012315, 9012316, 9012317, 9012318, 9012319, 9012320, 9012321, 9012322, 9012323, 9012324, 9012325, 9012330, 9012331, 9012332, 9012333, 9012334, 9012335, 9012336, 9012337, 9012338, 9012339, 9012340, 9012341, 9012342, 9012343, 9012344, 9012345, 9012346, 9012347, 9012348, 9012349, 9012350, 9012351, 9012352, 9012353, 9012354, 9012355, 9012356, 9012357, 9012358, 9012359, 9012360, 9012361, 9012362, 9012363, 9012370, 9012371, 9012372, 9012373, 9012374, 9012375, 9012376, 9012377, 9012378, 9012379, 9012380, 9012381, 9012382, 9012383, 9012384, 9012385, 9012400, 9012401, 9012402, 9012403, 9012404, 9012405, 9012406, 9012407, 9012408, 9012409, 9012410, 9012411, 9012420, 9012421, 9012422, 9012423) OR `guid` BETWEEN 9012300 AND 9012549;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9012300, 162839, 1, 0, 0, 1, 1, 0, 366.935, -4764.07, 30.122, 2.3877, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: ST8740 on the cliff rock under his tent (atlas 0.8 yd); looks out over the town'),
(9012301, 162840, 1, 0, 0, 1, 1, 0, 331, -4987.4, 20.726, 5.0147, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: ST8744 (1.9 yd) under the tree outside Rivenruin Cave, clear of the dry bush; eyes the cave mouth he fled'),
(9012302, 162838, 1, 0, 0, 1, 1, 0, 375.735, -4664.36, 16.134, 3.9261, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: ST8845 at the mine mouth (atlas); faces the town road'),
(9012303, 162841, 1, 0, 0, 1, 1, 0, 244.59, -4699.78, 38.53, 4.712, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: atlas point on the Pvp_Orctower top floor (Questie 0.3 yd); looks east over the land toward the sea'),
(9012304, 162949, 1, 0, 0, 1, 1, 0, 207.812, -4695.65, 11.462, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: ST8846, the pool west of town (water 12.78); invisible, Collect Water reaches 6 yd, the SuperTrack radius'),
(9012305, 162949, 1, 0, 0, 1, 1, 0, 149.062, -4777.27, 11.793, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: atlas sighting at the Watertroughlarge01 by the kennel; invisible'),
(9012306, 162916, 1, 0, 0, 1, 1, 0, 416.939, -5103.85, -30.111, 1.389, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: ST8742 (atlas) at the far end of the deep south hall'),
(9012310, 162836, 1, 0, 0, 1, 1, 0, 401.92, -4648.3, 16.685, 3.6918, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point at the foot of the mine tunnel'),
(9012311, 162836, 1, 0, 0, 1, 1, 0, 402.49, -4638.02, 18.551, 3.9192, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; atlas sighting in the first chamber'),
(9012312, 162836, 1, 0, 0, 1, 1, 0, 412.3, -4637.19, 18.579, 3.7806, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; ST8847, the objective point in the first chamber'),
(9012313, 162836, 1, 0, 0, 1, 1, 0, 419.54, -4643.02, 18.384, 3.5949, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point at the chamber exit'),
(9012314, 162836, 1, 0, 0, 1, 1, 0, 423.07, -4637.73, 18.247, 3.654, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point in the low corridor'),
(9012315, 162836, 1, 0, 0, 1, 1, 0, 430.12, -4643.02, 16.454, 3.5155, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point on the corridor floor'),
(9012316, 162836, 1, 0, 0, 1, 1, 0, 433.64, -4632.44, 17.717, 3.6454, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point at the corridor bend'),
(9012317, 162836, 1, 0, 0, 1, 1, 0, 444, -4630, 18.841, 3.6079, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; the junction floor; Questie (444.21, -4627.15) has no floor under it'),
(9012318, 162836, 1, 0, 0, 1, 1, 0, 447.74, -4632.44, 19.268, 3.5589, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point at the junction'),
(9012319, 162836, 1, 0, 0, 1, 1, 0, 447.74, -4621.86, 20.139, 3.6748, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point on the junction ramp'),
(9012320, 162836, 1, 0, 0, 1, 1, 0, 458.31, -4627.15, 18.993, 3.565, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point in the east chamber'),
(9012321, 162836, 1, 0, 0, 1, 1, 0, 465.36, -4621.86, 18.52, 3.5844, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point at the east chamber end'),
(9012322, 162836, 1, 0, 0, 1, 1, 0, 465.36, -4616.58, 17.937, 3.6314, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point in the east chamber corner'),
(9012323, 162836, 1, 0, 0, 1, 1, 0, 450, -4606, 19.284, 3.8076, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; north branch; Questie (451.26, -4606.0) has no floor under it'),
(9012324, 162836, 1, 0, 0, 1, 1, 0, 447, -4603, 18.556, 3.8524, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; north branch end; Questie (447.74, -4600.71) is outside the room'),
(9012325, 162836, 1, 0, 0, 1, 1, 0, 444.21, -4611.29, 19.39, 3.8009, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dirgran''s mine: Thirsty Peon; Questie point in the north branch'),
(9012330, 162834, 1, 0, 0, 1, 1, 0, 357.5, -5036.98, 17.573, 2.6503, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; atlas sighting just inside the west mouth'),
(9012331, 162834, 1, 0, 0, 1, 1, 0, 364.57, -5023.75, 18.491, 3.435, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the north side of the entrance tunnel'),
(9012332, 162834, 1, 0, 0, 1, 1, 0, 378, -5025, 17.272, 3.2855, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the tunnel bend'),
(9012333, 162834, 1, 0, 0, 1, 1, 0, 393, -5022, 12.578, 3.302, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the tunnel slope down'),
(9012334, 162834, 1, 0, 0, 1, 1, 0, 405, -5025, 8.04, 3.2219, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the foot of the tunnel slope'),
(9012335, 162834, 1, 0, 0, 1, 1, 0, 416.02, -5032.74, 6.605, 1.0958, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the landing ledge'),
(9012336, 162834, 1, 0, 0, 1, 1, 0, 427.3, -5042.79, 4.63, 1.9602, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the balcony over the south hall'),
(9012337, 162834, 1, 0, 0, 1, 1, 0, 427.6, -5010.6, 1.985, 4.2268, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; north end of the balcony, out of the tall grass'),
(9012338, 162834, 1, 0, 0, 1, 1, 0, 438.57, -5038.56, 2.065, 2.5109, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the balcony'),
(9012339, 162834, 1, 0, 0, 1, 1, 0, 419.3, -5013.8, 3.439, 4.7748, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the balcony head, out of the tall grass'),
(9012340, 162834, 1, 0, 0, 1, 1, 0, 427.3, -5028, -30.424, 4.6406, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the south hall floor under the balcony, south of the grass'),
(9012341, 162834, 1, 0, 0, 1, 1, 0, 422.5, -5045, -31.377, 4.8775, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the lowest floor of the south hall, north of the grass'),
(9012342, 162834, 1, 0, 0, 1, 1, 0, 432, -5064, -28.687, 2.6224, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the south hall east side'),
(9012343, 162834, 1, 0, 0, 1, 1, 0, 417, -5088, -28.799, 1.2925, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the approach to the Brute'),
(9012344, 162834, 1, 0, 0, 1, 1, 0, 452.32, -4951.84, -25.344, 2.542, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point in the west hall'),
(9012345, 162834, 1, 0, 0, 1, 1, 0, 411, -4914, -24.062, 5.4578, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the west hall south corner'),
(9012346, 162834, 1, 0, 0, 1, 1, 0, 435, -4935, -25.682, 4.7124, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the west hall centre'),
(9012347, 162834, 1, 0, 0, 1, 1, 0, 461, -4929.5, -25.541, 3.5254, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the west hall north side, off the coral'),
(9012348, 162834, 1, 0, 0, 1, 1, 0, 426, -4968, -22.709, 1.2598, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the west hall east rise'),
(9012349, 162834, 1, 0, 0, 1, 1, 0, 444, -4977, -22.142, 1.8094, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the foot of the ramp up to the middle gallery'),
(9012350, 162834, 1, 0, 0, 1, 1, 0, 441.75, -4999.43, -0.053, 5.6931, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point at the middle gallery entrance'),
(9012351, 162834, 1, 0, 0, 1, 1, 0, 452.32, -4999.96, -1.97, 5.4129, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point in the middle gallery'),
(9012352, 162834, 1, 0, 0, 1, 1, 0, 455.84, -5016.88, 1.965, 0.2024, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point beside the atlas relic'),
(9012353, 162834, 1, 0, 0, 1, 1, 0, 474.17, -5028.51, 5.924, 2.1671, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the gallery rise'),
(9012354, 162834, 1, 0, 0, 1, 1, 0, 474.52, -5011.06, 5.038, 3.534, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the gallery rise'),
(9012355, 162834, 1, 0, 0, 1, 1, 0, 483.33, -4995.73, -5.756, 5.723, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the way down to the north hall'),
(9012356, 162834, 1, 0, 0, 1, 1, 0, 498.2, -5036.5, -14.866, 0.347, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the north hall mouth, off the ruin ring'),
(9012357, 162834, 1, 0, 0, 1, 1, 0, 511.17, -5024.81, -12.29, 6.2731, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point in the north hall'),
(9012358, 162834, 1, 0, 0, 1, 1, 0, 507.29, -5045.43, -14.486, 0.7326, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; Questie point on the north hall east side'),
(9012359, 162834, 1, 0, 0, 1, 1, 0, 540, -5031, -13.334, 2.6012, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the north hall middle'),
(9012360, 162834, 1, 0, 0, 1, 1, 0, 561, -5037, -13.672, 2.7723, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the far north hall'),
(9012361, 162834, 1, 0, 0, 1, 1, 0, 525, -5001, -12.414, 4.9178, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the north hall west bay'),
(9012362, 162834, 1, 0, 0, 1, 1, 0, 467, -5069.5, -23.347, 5.2117, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the east hall floor, north of the grass'),
(9012363, 162834, 1, 0, 0, 1, 1, 0, 486, -5064, -18.907, 3.7439, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Myrmidon; the east hall rise toward the north hall'),
(9012370, 162835, 1, 0, 0, 1, 1, 0, 365.39, -5045.45, 21.699, 2.5071, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; atlas sighting in the side bay of the west mouth'),
(9012371, 162835, 1, 0, 0, 1, 1, 0, 399, -5028, 10.927, 3.1761, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; the tunnel slope, behind the myrmidons'),
(9012372, 162835, 1, 0, 0, 1, 1, 0, 441.04, -5014.23, -13.778, 6.2511, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point on the ramp between the halls'),
(9012373, 162835, 1, 0, 0, 1, 1, 0, 490.38, -5009.47, 3.567, 3.3561, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point at the gallery east end'),
(9012374, 162835, 1, 0, 0, 1, 1, 0, 425.53, -4987.26, -21.93, 1.373, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point in the west hall south bay'),
(9012375, 162835, 1, 0, 0, 1, 1, 0, 409.68, -4940.2, -23.68, 0.0079, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point by the west hall wall'),
(9012376, 162835, 1, 0, 0, 1, 1, 0, 429.41, -4900.54, -24.783, 4.8531, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point at the far west end'),
(9012377, 162835, 1, 0, 0, 1, 1, 0, 531.96, -5044.9, -10.237, 1.669, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point on the north hall ledge'),
(9012378, 162835, 1, 0, 0, 1, 1, 0, 530.55, -5024.28, -13.51, 4.0601, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point in the north hall'),
(9012379, 162835, 1, 0, 0, 1, 1, 0, 547.82, -5025.87, -13.737, 3.0928, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; Questie point in the north hall'),
(9012380, 162835, 1, 0, 0, 1, 1, 0, 552, -5022, -13.626, 3.2771, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; beside Questie (555.92, -5020.58), which stands against the wall'),
(9012381, 162835, 1, 0, 0, 1, 1, 0, 424.5, -5063, -28.962, 1.4056, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; the south hall west side, out of the grass'),
(9012382, 162835, 1, 0, 0, 1, 1, 0, 426, -5088, -27.973, 1.6065, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; the south hall end, before the Brute'),
(9012383, 162835, 1, 0, 0, 1, 1, 0, 474, -5076, -21.504, 2.8966, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; the east hall'),
(9012384, 162835, 1, 0, 0, 1, 1, 0, 459, -4962, -22.711, 2.3996, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; the west hall north-east bay'),
(9012385, 162835, 1, 0, 0, 1, 1, 0, 564, -5022, -13.685, 3.2296, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Rivenruin Cave: Rivenruin Sorceress; the far north hall'),
(9012400, 162830, 1, 0, 0, 1, 1, 0, 297.28, -4665.07, 27.548, 5.1046, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting on the great-hall hill'),
(9012401, 162831, 1, 0, 0, 1, 1, 0, 369.65, -4681.56, 16.465, 3.3017, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting on the mine road; faces the inn'),
(9012402, 162832, 1, 0, 0, 1, 1, 0, 330.43, -4760.99, 12.601, 2.6481, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting; faces the lower square'),
(9012403, 162833, 1, 0, 0, 1, 1, 0, 243.52, -4758.05, 12.119, 5.9367, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting; faces the feast ground'),
(9012404, 162956, 1, 0, 0, 1, 1, 0, 299.6, -4629.03, 36.268, 4.718, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting on the great hall upper floor'),
(9012405, 162957, 1, 0, 0, 1, 1, 0, 303.53, -4744.87, 9.627, 5.6978, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting; talks with Yaz''mora'),
(9012406, 162959, 1, 0, 0, 1, 1, 0, 305.28, -4746.03, 9.559, 2.5562, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting; talks with Ragrath'),
(9012407, 162958, 1, 0, 0, 1, 1, 0, 308.39, -4757.21, 9.399, 1.8979, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting; faces the talking pair'),
(9012408, 162966, 1, 0, 0, 1, 1, 0, 359.32, -4795.48, 26.659, 2.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting on the Orchut upper floor; faces the town'),
(9012409, 162967, 1, 0, 0, 1, 1, 0, 322.19, -4701.92, 15.93, 0.5898, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting; faces the inn'),
(9012410, 162928, 1, 0, 0, 1, 1, 0, 321.37, -4748.02, 9.56, 5.3221, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting in the lower square'),
(9012411, 162929, 1, 0, 0, 1, 1, 0, 250.85, -4854.32, 54.454, 4.23, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill townsfolk: atlas sighting on the Orctower top; faces the south-west approach'),
(9012420, 356, 1, 0, 0, 1, 1, 0, 165.73, -4782.02, 12.01, 2.864, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill kennel: display wolf; atlas sighting in the kennel'),
(9012421, 12351, 1, 0, 0, 1, 1, 0, 163.44, -4776.34, 11.829, 3.2062, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill kennel: display wolf; atlas sighting in the kennel'),
(9012422, 14539, 1, 0, 0, 1, 1, 0, 155.07, -4793.24, 11.993, 0.39, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill kennel: display wolf; atlas sighting in the kennel; faces out of its pen'),
(9012423, 14540, 1, 0, 0, 1, 1, 0, 167.96, -4787.28, 12.197, 3.53, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill kennel: display wolf; atlas sighting in the kennel; faces out of its pen');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9012300 AND 9012549;

DELETE FROM `gameobject` WHERE `guid` IN (7917100, 7917101, 7917102, 7917103, 7917104, 7917105, 7917106, 7917107, 7917108, 7917109, 7917110, 7917111, 7917112, 7917113, 7917114, 7917115, 7917116, 7917117, 7917118, 7917119, 7917120, 7917121, 7917122, 7917123, 7917124, 7917125, 7917126) OR `guid` BETWEEN 7917100 AND 7917199;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7917100, 2300551, 1, 0, 0, 1, 1, 429.06, -5006.95, 1.136, 6.0628, 0, 0, 0.10997, -0.993935, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; atlas sighting on the balcony'),
(7917101, 2300553, 1, 0, 0, 1, 1, 405.61, -4945.03, -22.536, 5.4162, 0, 0, 0.420043, -0.907504, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; atlas sighting against the west hall wall'),
(7917102, 2300554, 1, 0, 0, 1, 1, 451.08, -5071.5, -26.235, 2.7263, 0, 0, 0.978519, 0.206157, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; atlas sighting in the east hall'),
(7917103, 2300555, 1, 0, 0, 1, 1, 386.1, -5016.67, 15.05, 0.0212, 0, 0, 0.0106, 0.999944, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; atlas sighting in the tunnel side niche'),
(7917104, 2300556, 1, 0, 0, 1, 1, 455.93, -5018.11, 2.313, 0.3303, 0, 0, 0.1644, 0.986394, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; atlas sighting in the middle gallery'),
(7917105, 2300557, 1, 0, 0, 1, 1, 431.8, -4960.72, -24.877, 5.2613, 0, 0, 0.489, -0.872284, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; atlas sighting in the west hall'),
(7917106, 2300558, 1, 0, 0, 1, 1, 450.56, -5032.39, 3.779, 0.8778, 0, 0, 0.424944, 0.90522, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; atlas sighting on the gallery'),
(7917107, 2300553, 1, 0, 0, 1, 1, 488.97, -5004.72, 3.468, 3.5467, 0, 0, 0.979556, -0.201171, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point at the gallery east end'),
(7917108, 2300554, 1, 0, 0, 1, 1, 498.5, -5040, -15.197, 2.5005, 0, 0, 0.949063, 0.315085, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie (496.72, -5037.5) 3 yd off, clear of the myrmidon there'),
(7917109, 2300555, 1, 0, 0, 1, 1, 418.13, -5084.04, -28.079, 1.2924, 0, 0, 0.602157, 0.798378, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point near the Brute'),
(7917110, 2300555, 1, 0, 0, 1, 1, 530.9, -5028.51, -13.172, 2.9394, 0, 0, 0.994894, 0.100924, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point in the north hall'),
(7917111, 2300556, 1, 0, 0, 1, 1, 556.5, -5016, -13.491, 3.1307, 0, 0, 0.999985, 0.005446, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie (555.92, -5020.58) 4.6 yd off the wall'),
(7917112, 2300557, 1, 0, 0, 1, 1, 440.34, -5020.05, -13.1, 0.202, 0, 0, 0.100828, 0.994904, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point on the ramp'),
(7917113, 2300557, 1, 0, 0, 1, 1, 555.92, -5036.44, -13.733, 2.91, 0, 0, 0.993303, 0.115538, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point in the far north hall'),
(7917114, 2300558, 1, 0, 0, 1, 1, 417.08, -5116.29, -28.414, 1.431, 0, 0, 0.655995, 0.754765, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point behind the Brute'),
(7917115, 2300558, 1, 0, 0, 1, 1, 463.24, -5071.87, -24.02, 2.8406, 0, 0, 0.988697, 0.149929, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point in the east hall'),
(7917116, 2300551, 1, 0, 0, 1, 1, 427.3, -5042.79, -31.229, 4.5795, 0, 0, 0.752495, -0.658598, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; Questie point on the south hall floor under the balcony'),
(7917117, 2300556, 1, 0, 0, 1, 1, 468, -4945, -25.619, 4.6696, 0, 0, 0.722072, -0.691818, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the west hall north corner'),
(7917118, 2300553, 1, 0, 0, 1, 1, 441, -4905, -25.53, 4.9272, 0, 0, 0.627231, -0.778833, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the west hall far corner'),
(7917119, 2300554, 1, 0, 0, 1, 1, 414, -4914, -24.213, 5.18, 0, 0, 0.524044, -0.851691, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the west hall south corner, 3 yd off the myrmidon'),
(7917120, 2300551, 1, 0, 0, 1, 1, 419.02, -5032.74, 5.405, 0.3682, 0, 0, 0.183062, 0.983101, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the landing ledge, 3 yd off the myrmidon'),
(7917121, 2300554, 1, 0, 0, 1, 1, 528, -5003, -12.018, 3.3298, 0, 0, 0.995576, -0.093965, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the north hall west bay'),
(7917122, 2300555, 1, 0, 0, 1, 1, 428.53, -4987.26, -22.02, 5.6329, 0, 0, 0.319444, -0.947605, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the west hall south bay, 3 yd off the sorceress'),
(7917123, 2300551, 1, 0, 0, 1, 1, 489, -5064, -18.324, 3.0792, 0, 0, 0.999513, 0.031191, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the east hall rise'),
(7917124, 2300556, 1, 0, 0, 1, 1, 367.57, -5023.75, 18.401, 0.0896, 0, 0, 0.044785, 0.998997, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the entrance tunnel, 3 yd off the myrmidon'),
(7917125, 2300557, 1, 0, 0, 1, 1, 435, -5064, -28.251, 2.7611, 0, 0, 0.981958, 0.189101, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the south hall east side'),
(7917126, 2300553, 1, 0, 0, 1, 1, 514.17, -5024.81, -12.69, 2.9447, 0, 0, 0.995158, 0.098287, 120, 100, 1, '', 'CoA Rivenruin Cave: Elven Relic of Old; the north hall, 3 yd off the myrmidon');

-- ---------------------------------------------------------------------------
-- 6. Scripts
-- ---------------------------------------------------------------------------
-- Collect Water fills the pitcher only within 6 yd of a water trigger. A peon drinks, credits the served
-- count and leaves for a minute; Bagamul credits the shared listen marker.
DELETE FROM `spell_scripts` WHERE `id` = 267033;
INSERT INTO `spell_scripts` (`id`, `effIndex`, `delay`, `command`, `datalong`, `datalong2`, `dataint`, `x`, `y`, `z`, `o`)
VALUES
(267033, 0, 0, 17, 558974, 1, 0, 0, 0, 0, 0);

DELETE FROM `conditions` WHERE `SourceEntry` = 267033 AND `SourceTypeOrReferenceId` = 17;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(17, 0, 267033, 0, 0, 29, 0, 162949, 6, 0, 0, 60, 0, '', 'Collect Water - only at the Razor Hill pool or trough');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (162835, 162836, 162841) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162835, 0, 0, 0, 0, 0, 100, 0, 0, 0, 3400, 4700, 0, 0, 11, 9532, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Rivenruin Sorceress - In Combat CMC - Cast ''Lightning Bolt'''),
(162835, 0, 1, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Rivenruin Sorceress - Between 0-15% Health - Flee For Assist (No Repeat)'),
(162836, 0, 0, 1, 62, 0, 100, 0, 932515, 0, 0, 0, 0, 0, 33, 162949, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thirsty Peon - On Gossip Option 0 Selected - Quest Credit Thirsty peon served'),
(162836, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thirsty Peon - Linked - Close Gossip'),
(162836, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Thirsty Peon - Linked - Play Emote Drink'),
(162836, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Thirsty Peon - Linked - Remove Npc Flag Gossip'),
(162836, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 3000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Thirsty Peon - Linked - Despawn In 3 s'),
(162841, 0, 0, 1, 62, 0, 100, 0, 932516, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - On Gossip Option 0 Selected - Close Gossip'),
(162841, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - Linked - Quest Credit Listen to Bagamul Skyfang');

-- ---------------------------------------------------------------------------
-- 7. Razor Hill stock rows
-- ---------------------------------------------------------------------------
-- Gar'Thok (4692): ST1107 (784/825/830/837), moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `creature` SET `position_x` = 275.38, `position_y` = -4713.18, `position_z` = 17.489, `orientation` = 0.566 WHERE `guid` = 4692 AND `id` = 3139;
-- Orgnil Soulscar (3396): ST699 (806/823).
UPDATE `creature` SET `position_x` = 288.04, `position_y` = -4720.88, `position_z` = 13.389 WHERE `guid` = 3396 AND `id` = 3142;
-- Magga (3416): ST1717 (5843) in the Razor Hill inn (atlas x6, Exiles); faces Innkeeper Grosk.
UPDATE `creature` SET `position_x` = 327.7, `position_y` = -4683, `position_z` = 16.458, `orientation` = 6.0289 WHERE `guid` = 3416 AND `id` = 11943;
-- Harruk (7673): atlas sighting in the burrow, moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `creature` SET `position_x` = 277, `position_y` = -4716.89, `position_z` = 11.626, `orientation` = 2.451 WHERE `guid` = 7673 AND `id` = 3620;
-- Krunn (7674): atlas sighting in the moved smithy.
UPDATE `creature` SET `position_x` = 361.01, `position_y` = -4711.99, `position_z` = 15.165 WHERE `guid` = 7674 AND `id` = 3175;
-- Dwukk (10280): atlas sighting in the moved smithy.
UPDATE `creature` SET `position_x` = 363.69, `position_y` = -4703.79, `position_z` = 15.488 WHERE `guid` = 10280 AND `id` = 3174;
-- Uhgar (10272): atlas sighting beside the moved smithy.
UPDATE `creature` SET `position_x` = 382.09, `position_y` = -4709.95, `position_z` = 13.67 WHERE `guid` = 10272 AND `id` = 3163;
-- Mukdrak (7666): atlas sighting; sunk under the moved smithy.
UPDATE `creature` SET `position_x` = 368.32, `position_y` = -4722.72, `position_z` = 13.154 WHERE `guid` = 7666 AND `id` = 11025;
-- Ghrawt (7667): atlas sighting at the wagon stall by the inn; buried 16 yd under the east hill; faces the lane.
UPDATE `creature` SET `position_x` = 314.3, `position_y` = -4681.69, `position_z` = 16.01, `orientation` = 3.1416 WHERE `guid` = 7667 AND `id` = 3165;
-- Cutac (7672): atlas sighting in the new Orchut; buried.
UPDATE `creature` SET `position_x` = 387.98, `position_y` = -4758.34, `position_z` = 12.245, `orientation` = 2.7452 WHERE `guid` = 7672 AND `id` = 3166;
-- Kitha (7295): atlas sighting on the raised ground south of the barracks; faces her moved anvil stone.
UPDATE `creature` SET `position_x` = 300.47, `position_y` = -4857.39, `position_z` = 21.179, `orientation` = 0.3249 WHERE `guid` = 7295 AND `id` = 6027;
-- Ophek (449): atlas sighting beside Kitha; buried 21 yd.
UPDATE `creature` SET `position_x` = 307.57, `position_y` = -4866.03, `position_z` = 21.53, `orientation` = 1.8889 WHERE `guid` = 449 AND `id` = 3294;
-- Grunt Kor'ja (3431): atlas sighting by the new kennel; floated.
UPDATE `creature` SET `position_x` = 171.98, `position_y` = -4767.34, `position_z` = 14.263 WHERE `guid` = 3431 AND `id` = 12430;
-- Flakk (6381): atlas sighting by the feast ground.
UPDATE `creature` SET `position_x` = 282.71, `position_y` = -4764.43, `position_z` = 11.904 WHERE `guid` = 6381 AND `id` = 3168;
-- Takrin Pathseeker (516): atlas sighting under the orc tent (the great hall covers his stock spot); faces out of the tent.
UPDATE `creature` SET `position_x` = 239.52, `position_y` = -4664.73, `position_z` = 16.126, `orientation` = 0.424 WHERE `guid` = 516 AND `id` = 3336;
-- Grimtak (10425): atlas sighting (the great hall covers his stock spot); faces the kitchen.
UPDATE `creature` SET `position_x` = 281.47, `position_y` = -4694.72, `position_z` = 12.966, `orientation` = 3.177 WHERE `guid` = 10425 AND `id` = 3881;
-- Cook Torka (6460): atlas sighting x9 with her kitchen (the great hall covers her stock kitchen); faces her cooking table.
UPDATE `creature` SET `position_x` = 268.98, `position_y` = -4694.89, `position_z` = 14.056, `orientation` = 6.2457 WHERE `guid` = 6460 AND `id` = 3191;
-- Razor Hill Grunt (7294): the atlas grunt post north-west of town (inside the great-hall wall before); faces away from the town.
UPDATE `creature` SET `position_x` = 174.73, `position_y` = -4675.37, `position_z` = 20.62, `orientation` = 2.8435 WHERE `guid` = 7294 AND `id` = 5953;
-- Razor Hill Grunt (8417): buried 15 yd; south-west tower foot, off the bush.
UPDATE `creature` SET `position_x` = 242.8, `position_y` = -4838, `position_z` = 30.105 WHERE `guid` = 8417 AND `id` = 5953;
-- Razor Hill Grunt (8421): buried 21 yd; foot of the new south-west tower.
UPDATE `creature` SET `position_x` = 257.5, `position_y` = -4830, `position_z` = 31.783 WHERE `guid` = 8421 AND `id` = 5953;
-- Razor Hill Grunt (6385): buried 14 yd; on the raised east hill, town side.
UPDATE `creature` SET `position_x` = 357.65, `position_y` = -4788.13, `position_z` = 26.424 WHERE `guid` = 6385 AND `id` = 5953;
-- Razor Hill Grunt (8416): buried 19 yd; on the raised east hill.
UPDATE `creature` SET `position_x` = 365.533, `position_y` = -4827.24, `position_z` = 30.502 WHERE `guid` = 8416 AND `id` = 5953;
-- Razor Hill Grunt (10277): buried 17 yd; on the raised east hill.
UPDATE `creature` SET `position_x` = 369.885, `position_y` = -4818.79, `position_z` = 28.859 WHERE `guid` = 10277 AND `id` = 5953;
-- Razor Hill Grunt (8423): sunk on a steep bank; open ground clear of the bush.
UPDATE `creature` SET `position_x` = 380.5, `position_y` = -4756, `position_z` = 9.679 WHERE `guid` = 8423 AND `id` = 5953;
-- Razor Hill Grunt (7668): sunk 1.9 yd; open ground beside it.
UPDATE `creature` SET `position_x` = 388, `position_y` = -4855, `position_z` = 14.257 WHERE `guid` = 7668 AND `id` = 5953;
-- Razor Hill Grunt (7296): against a new cactus; 1 yd clear.
UPDATE `creature` SET `position_x` = 401.5, `position_y` = -4739, `position_z` = 10.219 WHERE `guid` = 7296 AND `id` = 5953;
-- Razor Hill Grunt (10271): sunk under the new mine-room floor.
UPDATE `creature` SET `position_x` = 379.145, `position_y` = -4665.41, `position_z` = 16.553 WHERE `guid` = 10271 AND `id` = 5953;
-- Clattering Scorpid (7951): floated inside the Rivenruin mouth; outside it.
UPDATE `creature` SET `position_x` = 330, `position_y` = -5020, `position_z` = 16.292 WHERE `guid` = 7951 AND `id` = 3125;
-- Anvil (12083): moved with the smithy (-4.590, -2.055, -0.826).
UPDATE `gameobject` SET `position_x` = 364.474, `position_y` = -4704.505, `position_z` = 15.504 WHERE `guid` = 12083 AND `id` = 51703;
-- Anvil (12067): moved with the smithy (-4.590, -2.055, -0.826).
UPDATE `gameobject` SET `position_x` = 375.301, `position_y` = -4712.735, `position_z` = 15.235 WHERE `guid` = 12067 AND `id` = 51702;
-- Heated Forge (12079): moved with the smithy (-4.590, -2.055, -0.826).
UPDATE `gameobject` SET `position_x` = 369.619, `position_y` = -4710.415, `position_z` = 13.33 WHERE `guid` = 12079 AND `id` = 50983;
-- Water Barrel (44541): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `gameobject` SET `position_x` = 266.483, `position_y` = -4715.118, `position_z` = 11.629, `orientation` = 2.57326, `rotation2` = 0.959896, `rotation3` = 0.280357 WHERE `guid` = 44541 AND `id` = 3658;
-- Food Crate (44542): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `gameobject` SET `position_x` = 266.483, `position_y` = -4715.118, `position_z` = 11.629, `orientation` = 2.57326, `rotation2` = 0.959896, `rotation3` = 0.280357 WHERE `guid` = 44542 AND `id` = 3719;
-- Tall Brazier (1591): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)); outside the shell it stands on the ground by the entrance.
UPDATE `gameobject` SET `position_x` = 293.549, `position_y` = -4722.014, `position_z` = 12.562, `orientation` = 4.31859, `rotation2` = 0.831775, `rotation3` = -0.555113 WHERE `guid` = 1591 AND `id` = 55250;
-- Cooking Table (399): atlas point of Cook Torka's kitchen.
UPDATE `gameobject` SET `position_x` = 272.71, `position_y` = -4695.03, `position_z` = 13.517, `orientation` = 3.14159, `rotation0` = 0, `rotation1` = 0, `rotation2` = 1, `rotation3` = 0.000001 WHERE `guid` = 399 AND `id` = 18075;
-- Bubbling Cauldron (1733): atlas point of Cook Torka's kitchen.
UPDATE `gameobject` SET `position_x` = 266.92, `position_y` = -4697.05, `position_z` = 14.129, `orientation` = 3.17656, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.999847, `rotation3` = -0.017483 WHERE `guid` = 1733 AND `id` = 18079;
-- Smoking Rack (1365): atlas point of Cook Torka's kitchen.
UPDATE `gameobject` SET `position_x` = 283.99, `position_y` = -4695.86, `position_z` = 12.816, `orientation` = 3.14159, `rotation0` = 0, `rotation1` = 0, `rotation2` = 1, `rotation3` = 0.000001 WHERE `guid` = 1365 AND `id` = 31574;
-- Medium Brazier (1718): atlas point; sunk by the smithy.
UPDATE `gameobject` SET `position_x` = 366.09, `position_y` = -4722.64, `position_z` = 13.219, `orientation` = 3.11539, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.999914, `rotation3` = 0.013101 WHERE `guid` = 1718 AND `id` = 31572;
-- Medium Brazier (1382): atlas point; sunk.
UPDATE `gameobject` SET `position_x` = 331.22, `position_y` = -4763.77, `position_z` = 13.153, `orientation` = 3.14309, `rotation0` = 0, `rotation1` = 0, `rotation2` = 1, `rotation3` = -0.000749 WHERE `guid` = 1382 AND `id` = 31576;
-- Bubbling Cauldron (1425): buried 22 yd; beside Kitha's moved anvil stone.
UPDATE `gameobject` SET `position_x` = 304.6, `position_y` = -4862, `position_z` = 21.189 WHERE `guid` = 1425 AND `id` = 31580;
-- Water Barrel (44551): buried under the great-hall hill; its foot.
UPDATE `gameobject` SET `position_x` = 296, `position_y` = -4668.5, `position_z` = 16.245 WHERE `guid` = 44551 AND `id` = 3658;
-- Food Crate (44552): buried under the great-hall hill; its foot.
UPDATE `gameobject` SET `position_x` = 296, `position_y` = -4668.5, `position_z` = 16.245 WHERE `guid` = 44552 AND `id` = 3719;
-- Water Barrel (44549): sunk into the burrow mound; same x and y.
UPDATE `gameobject` SET `position_x` = 290.396, `position_y` = -4706.11, `position_z` = 13.906 WHERE `guid` = 44549 AND `id` = 3658;
-- Food Crate (44550): sunk into the burrow mound; same x and y.
UPDATE `gameobject` SET `position_x` = 290.396, `position_y` = -4706.11, `position_z` = 13.906 WHERE `guid` = 44550 AND `id` = 3719;
-- Tall Brazier (1222): sunk into the burrow mound; same x and y.
UPDATE `gameobject` SET `position_x` = 292.934, `position_y` = -4709.42, `position_z` = 13.726 WHERE `guid` = 1222 AND `id` = 31578;
-- Silverleaf (55808): against the naga pagoda; open ground below.
UPDATE `gameobject` SET `position_x` = 340, `position_y` = -5068, `position_z` = 14.907 WHERE `guid` = 55808 AND `id` = 1617;

-- Patrol nodes that CoA's new west-road footbridge covers, onto its deck.
UPDATE `waypoint_data` SET `position_x` = 223.59, `position_y` = -4740.63, `position_z` = 11.081 WHERE `id` = 84200 AND `point` = 6;
UPDATE `waypoint_data` SET `position_x` = 223.963, `position_y` = -4743.59, `position_z` = 11.09 WHERE `id` = 84200 AND `point` = 7;
UPDATE `waypoints` SET `position_x` = 224.22, `position_y` = -4741.74, `position_z` = 11.044 WHERE `entry` = 1067602 AND `pointid` = 25;
UPDATE `waypoints` SET `position_x` = 211.733, `position_y` = -4744.54, `position_z` = 11.221 WHERE `entry` = 1067602 AND `pointid` = 34;
-- Razor Hill Grunt directions to the smiths who moved with the smithy.
UPDATE `points_of_interest` SET `PositionX` = 363.69, `PositionY` = -4703.79 WHERE `ID` = 413;
UPDATE `points_of_interest` SET `PositionX` = 368.32, `PositionY` = -4722.72 WHERE `ID` = 414;
UPDATE `points_of_interest` SET `PositionX` = 361.01, `PositionY` = -4711.99 WHERE `ID` = 418;

-- ---------------------------------------------------------------------------
-- 8. Razor Hill holiday rows
-- ---------------------------------------------------------------------------
-- 244806 (event 9): ST13479 turn-in (npc-divergence).
UPDATE `creature` SET `position_x` = 323.94, `position_y` = -4703.51, `position_z` = 15.889 WHERE `guid` = 244806 AND `id` = 32798;
-- 244810 (event 9): atlas sighting.
UPDATE `creature` SET `position_x` = 333.09, `position_y` = -4707.97, `position_z` = 15.665 WHERE `guid` = 244810 AND `id` = 32837;
-- 240090 (event 12): invisible fire at the barracks wall; re-seated.
UPDATE `creature` SET `position_x` = 298.649, `position_y` = -4773.64, `position_z` = 10.591 WHERE `guid` = 240090 AND `id` = 23686;
-- 208995 (event 61): buried in the tower mound; its foot, 4 yd off.
UPDATE `creature` SET `position_x` = 251.42, `position_y` = -4675.27, `position_z` = 15.678 WHERE `guid` = 208995 AND `id` = 40256;
-- 208996 (event 61): buried in the tower mound; its foot, 3 yd off.
UPDATE `creature` SET `position_x` = 251, `position_y` = -4672.84, `position_z` = 15.639 WHERE `guid` = 208996 AND `id` = 40256;
-- 208998 (event 61): floated 0.8 yd; re-seated.
UPDATE `creature` SET `position_x` = 273.356, `position_y` = -4774.6, `position_z` = 11.388 WHERE `guid` = 208998 AND `id` = 40256;
-- 209000 (event 61): buried under the east hill; on it, 1 yd off.
UPDATE `creature` SET `position_x` = 344.74, `position_y` = -4791.72, `position_z` = 26.043 WHERE `guid` = 209000 AND `id` = 40256;
-- 209003 (event 61): floated against a new fence; 1 yd clear, re-seated.
UPDATE `creature` SET `position_x` = 374.95, `position_y` = -4775.08, `position_z` = 10.452 WHERE `guid` = 209003 AND `id` = 40256;
-- 209008 (event 61): buried under the south-west hill; on it.
UPDATE `creature` SET `position_x` = 266.075, `position_y` = -4829.9, `position_z` = 25.969 WHERE `guid` = 209008 AND `id` = 40257;
-- 209010 (event 61): buried 2.5 yd; open ground 3 yd off.
UPDATE `creature` SET `position_x` = 293.94, `position_y` = -4801.09, `position_z` = 12.139 WHERE `guid` = 209010 AND `id` = 40257;
-- 209013 (event 61): buried at the barracks; the low ground 7 yd west.
UPDATE `creature` SET `position_x` = 336.23, `position_y` = -4828.82, `position_z` = 10.448 WHERE `guid` = 209013 AND `id` = 40257;
-- 209014 (event 61): buried under the east hill; on it.
UPDATE `creature` SET `position_x` = 343.365, `position_y` = -4789.49, `position_z` = 26 WHERE `guid` = 209014 AND `id` = 40257;
-- 209015 (event 61): buried at the barracks; the low ground 10 yd west.
UPDATE `creature` SET `position_x` = 335.4, `position_y` = -4834.95, `position_z` = 9.971 WHERE `guid` = 209015 AND `id` = 40257;
-- 209017 (event 61): floated 2.2 yd; re-seated.
UPDATE `creature` SET `position_x` = 375.766, `position_y` = -4777.95, `position_z` = 10.318 WHERE `guid` = 209017 AND `id` = 40257;
-- 36746 (event 12): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `gameobject` SET `position_x` = 283.422, `position_y` = -4713.443, `position_z` = 15.026, `orientation` = 2.6433, `rotation2` = 0.969123, `rotation3` = 0.246577 WHERE `guid` = 36746 AND `id` = 180406;
-- 37172 (event 12): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `gameobject` SET `position_x` = 278.452, `position_y` = -4706.197, `position_z` = 15.026, `orientation` = 2.50345, `rotation2` = 0.949527, `rotation3` = 0.313685 WHERE `guid` = 37172 AND `id` = 180407;
-- 152058 (event 9): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `gameobject` SET `position_x` = 258.71, `position_y` = -4713.054, `position_z` = 15.027, `orientation` = 0.26, `rotation2` = 0.129634, `rotation3` = 0.991562 WHERE `guid` = 152058 AND `id` = 113770;
-- 152059 (event 9): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)).
UPDATE `gameobject` SET `position_x` = 279.682, `position_y` = -4723.594, `position_z` = 15.027, `orientation` = 2.03069, `rotation2` = 0.849663, `rotation3` = 0.527327 WHERE `guid` = 152059 AND `id` = 113771;
-- 152060 (event 9): moved with the troll burrow (+67.437 deg about (270.30, -4706.22) to (270.89, -4716.24)); at the brazier by the entrance.
UPDATE `gameobject` SET `position_x` = 293.758, `position_y` = -4721.849, `position_z` = 12.56, `orientation` = 3.73107, `rotation2` = 0.956878, `rotation3` = -0.29049 WHERE `guid` = 152060 AND `id` = 113772;
-- 37175 (event 12): moved with the smithy (-4.590, -2.055, -0.826).
UPDATE `gameobject` SET `position_x` = 383.333, `position_y` = -4714.095, `position_z` = 15.634, `orientation` = 1.83259, `rotation2` = 0.793352, `rotation3` = 0.608764 WHERE `guid` = 37175 AND `id` = 180407;
-- 66920 (event 12): atlas sighting at CoA's Hallow's End fire site.
UPDATE `gameobject` SET `position_x` = 241.15, `position_y` = -4563.96, `position_z` = 14.256 WHERE `guid` = 66920 AND `id` = 186615;
-- 150723 (event 1): buried in the great-hall hill; its foot, 4 yd off.
UPDATE `gameobject` SET `position_x` = 273.8, `position_y` = -4641.52, `position_z` = 16.593 WHERE `guid` = 150723 AND `id` = 181355;
-- 150727 (event 1): buried in the east hill; open ground 4 yd off.
UPDATE `gameobject` SET `position_x` = 333.97, `position_y` = -4756.6, `position_z` = 12.583 WHERE `guid` = 150727 AND `id` = 181355;
-- 150728 (event 1): floated 0.4 yd; re-seated.
UPDATE `gameobject` SET `position_x` = 246.39, `position_y` = -4751.75, `position_z` = 12.033 WHERE `guid` = 150728 AND `id` = 181355;
-- 36309 (event 12): its watchtower is gone; on the ground where it stood.
UPDATE `gameobject` SET `position_x` = 242.533, `position_y` = -4747.68, `position_z` = 12.383 WHERE `guid` = 36309 AND `id` = 180405;
-- 37171 (event 12): its watchtower is gone; on the ground where it stood.
UPDATE `gameobject` SET `position_x` = 241.731, `position_y` = -4724.49, `position_z` = 14.26 WHERE `guid` = 37171 AND `id` = 180407;
-- 36313 (event 12): its watchtower is gone; on the ground where it stood.
UPDATE `gameobject` SET `position_x` = 376.122, `position_y` = -4761.78, `position_z` = 9.864 WHERE `guid` = 36313 AND `id` = 180405;
-- 37176 (event 12): its watchtower is gone; on the east hill rock above.
UPDATE `gameobject` SET `position_x` = 370.259, `position_y` = -4831.36, `position_z` = 31.169 WHERE `guid` = 37176 AND `id` = 180407;
-- 36310 (event 12): its watchtower is gone; on the south-west hill.
UPDATE `gameobject` SET `position_x` = 263.72, `position_y` = -4826.96, `position_z` = 24.618 WHERE `guid` = 36310 AND `id` = 180405;
-- 36747 (event 12): its watchtower is gone; on the south-west hill.
UPDATE `gameobject` SET `position_x` = 260.71, `position_y` = -4819.83, `position_z` = 22.147 WHERE `guid` = 36747 AND `id` = 180406;
-- 68058 (event 12): buried 22 yd; on the hill above, 2 yd off.
UPDATE `gameobject` SET `position_x` = 343.79, `position_y` = -4848.28, `position_z` = 33.168 WHERE `guid` = 68058 AND `id` = 180405;
-- 36748 (event 12): buried 16 yd; on the east hill rock above.
UPDATE `gameobject` SET `position_x` = 361.788, `position_y` = -4772.05, `position_z` = 29.333 WHERE `guid` = 36748 AND `id` = 180406;
-- 36750 (event 12): sunk into the moved smithy floor; re-seated.
UPDATE `gameobject` SET `position_x` = 359.142, `position_y` = -4712.21, `position_z` = 15.63 WHERE `guid` = 36750 AND `id` = 180406;
-- 152057 (event 9): buried in the great-hall hill; on it.
UPDATE `gameobject` SET `position_x` = 297.2, `position_y` = -4657.1, `position_z` = 28.086 WHERE `guid` = 152057 AND `id` = 113769;
-- 152062 (event 9): sunk under a rock; 1 yd off.
UPDATE `gameobject` SET `position_x` = 297.47, `position_y` = -4796.06, `position_z` = 11.869 WHERE `guid` = 152062 AND `id` = 113769;
-- 152064 (event 9): buried in the south hill; 3 yd off on it.
UPDATE `gameobject` SET `position_x` = 290.96, `position_y` = -4842.74, `position_z` = 19.896 WHERE `guid` = 152064 AND `id` = 113771;
-- 152066 (event 9): buried; the low ground 6 yd off.
UPDATE `gameobject` SET `position_x` = 310.25, `position_y` = -4844.63, `position_z` = 10.524 WHERE `guid` = 152066 AND `id` = 113768;
-- 152067 (event 9): buried 11 yd; on the hill above.
UPDATE `gameobject` SET `position_x` = 312.713, `position_y` = -4860.69, `position_z` = 21.752 WHERE `guid` = 152067 AND `id` = 113769;
-- 152069 (event 9): buried 22 yd; on the hill above, 3 yd off.
UPDATE `gameobject` SET `position_x` = 346.23, `position_y` = -4849.86, `position_z` = 32.458 WHERE `guid` = 152069 AND `id` = 113771;
-- 152070 (event 9): buried 20 yd; on the hill above, 1 yd off.
UPDATE `gameobject` SET `position_x` = 337.62, `position_y` = -4857.31, `position_z` = 30.541 WHERE `guid` = 152070 AND `id` = 113772;
-- 152071 (event 9): buried; the low ground 2 yd off.
UPDATE `gameobject` SET `position_x` = 336.55, `position_y` = -4832.75, `position_z` = 10.435 WHERE `guid` = 152071 AND `id` = 113768;
-- 152072 (event 9): buried 22 yd; on the hill above.
UPDATE `gameobject` SET `position_x` = 359.585, `position_y` = -4836.23, `position_z` = 33.392 WHERE `guid` = 152072 AND `id` = 113769;
-- 152073 (event 9): buried; the low ground 3 yd off.
UPDATE `gameobject` SET `position_x` = 341.23, `position_y` = -4806.26, `position_z` = 10.948 WHERE `guid` = 152073 AND `id` = 113770;
-- 152075 (event 9): buried; the bank 2 yd off.
UPDATE `gameobject` SET `position_x` = 333.17, `position_y` = -4768.66, `position_z` = 14.569 WHERE `guid` = 152075 AND `id` = 113772;
-- 152077 (event 9): sunk into the moved smithy floor; re-seated.
UPDATE `gameobject` SET `position_x` = 367.509, `position_y` = -4719.81, `position_z` = 15.035 WHERE `guid` = 152077 AND `id` = 113769;
-- 36751 (event 12): its watchtower is gone; on the east hill rock above.
UPDATE `gameobject` SET `position_x` = 375.951, `position_y` = -4819.75, `position_z` = 28.72 WHERE `guid` = 36751 AND `id` = 180406;
-- 152081 (event 9): buried under the new inn mound; 4 yd south on open ground.
UPDATE `gameobject` SET `position_x` = 344.32, `position_y` = -4664.5, `position_z` = 16.369 WHERE `guid` = 152081 AND `id` = 113768;
-- 41409 (event 2): clear of CoA's new hut; 1 yd west along the barracks eave.
UPDATE `gameobject` SET `position_x` = 347.33, `position_y` = -4807.82, `position_z` = 31.748 WHERE `guid` = 41409 AND `id` = 178645;
-- Pilgrim's Bounty feast re-seated on CoA's reshaped ground (event 26); pumpkins keep their height over their haystack.
UPDATE `creature` SET `position_x` = 260.519, `position_y` = -4763.93, `position_z` = 11.913 WHERE `guid` = 52758 AND `id` = 32823;
UPDATE `creature` SET `position_x` = 272.727, `position_y` = -4764.28, `position_z` = 9.972 WHERE `guid` = 52759 AND `id` = 32823;
-- 52799: off the new fence.
UPDATE `creature` SET `position_x` = 251, `position_y` = -4756.5, `position_z` = 11.987 WHERE `guid` = 52799 AND `id` = 34654;
UPDATE `gameobject` SET `position_x` = 260.519, `position_y` = -4763.93, `position_z` = 12.015 WHERE `guid` = 3370 AND `id` = 195664;
UPDATE `gameobject` SET `position_x` = 272.727, `position_y` = -4764.28, `position_z` = 10.129 WHERE `guid` = 3371 AND `id` = 195664;
UPDATE `gameobject` SET `position_x` = 251.918, `position_y` = -4765.78, `position_z` = 12.181 WHERE `guid` = 16402 AND `id` = 180353;
-- 16403: off the rickshaw.
UPDATE `gameobject` SET `position_x` = 251.5, `position_y` = -4757.9, `position_z` = 11.977 WHERE `guid` = 16403 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 255.877, `position_y` = -4772.35, `position_z` = 12.027 WHERE `guid` = 16404 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 267.087, `position_y` = -4759.07, `position_z` = 9.892 WHERE `guid` = 16405 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 267.488, `position_y` = -4772, `position_z` = 11.763 WHERE `guid` = 16406 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 278.477, `position_y` = -4757.81, `position_z` = 11.823 WHERE `guid` = 16410 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 279.002, `position_y` = -4770.9, `position_z` = 11.181 WHERE `guid` = 16411 AND `id` = 180353;
-- 16412: off Flakk's spot.
UPDATE `gameobject` SET `position_x` = 280.86, `position_y` = -4764.25, `position_z` = 11.892 WHERE `guid` = 16412 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 251.818, `position_y` = -4764.55, `position_z` = 12.835 WHERE `guid` = 19191 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 252.139, `position_y` = -4766.9, `position_z` = 12.82 WHERE `guid` = 19192 AND `id` = 195164;
-- 19193: with its haystack.
UPDATE `gameobject` SET `position_x` = 250.861, `position_y` = -4759.44, `position_z` = 12.71 WHERE `guid` = 19193 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 255.012, `position_y` = -4758, `position_z` = 12.53 WHERE `guid` = 19194 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 255.036, `position_y` = -4771.42, `position_z` = 12.725 WHERE `guid` = 19195 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 257, `position_y` = -4772.53, `position_z` = 12.643 WHERE `guid` = 19196 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 265.844, `position_y` = -4759.26, `position_z` = 10.914 WHERE `guid` = 19197 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 266.406, `position_y` = -4771.91, `position_z` = 12.52 WHERE `guid` = 19198 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 267.903, `position_y` = -4759.03, `position_z` = 10.504 WHERE `guid` = 19199 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 268.639, `position_y` = -4771.9, `position_z` = 12.184 WHERE `guid` = 19200 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 277.2, `position_y` = -4757.66, `position_z` = 12.054 WHERE `guid` = 19206 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 278.179, `position_y` = -4771.42, `position_z` = 11.791 WHERE `guid` = 19207 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 279.943, `position_y` = -4770.41, `position_z` = 11.995 WHERE `guid` = 19209 AND `id` = 195164;
-- 19210: with its haystack.
UPDATE `gameobject` SET `position_x` = 280.542, `position_y` = -4763.12, `position_z` = 12.614 WHERE `guid` = 19210 AND `id` = 195164;
-- 19211: with its haystack.
UPDATE `gameobject` SET `position_x` = 280.928, `position_y` = -4765.33, `position_z` = 12.527 WHERE `guid` = 19211 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 251.842, `position_y` = -4764.5, `position_z` = 12.18 WHERE `guid` = 43779 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 252.042, `position_y` = -4766.85, `position_z` = 12.175 WHERE `guid` = 43780 AND `id` = 179968;
-- 43781: off the rickshaw.
UPDATE `gameobject` SET `position_x` = 251, `position_y` = -4759.3, `position_z` = 12.04 WHERE `guid` = 43781 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 254.988, `position_y` = -4771.46, `position_z` = 12.067 WHERE `guid` = 43782 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 255.106, `position_y` = -4757.97, `position_z` = 11.865 WHERE `guid` = 43783 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 257.069, `position_y` = -4772.6, `position_z` = 11.985 WHERE `guid` = 43784 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 265.983, `position_y` = -4759.11, `position_z` = 10.248 WHERE `guid` = 43785 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 266.431, `position_y` = -4771.87, `position_z` = 11.867 WHERE `guid` = 43786 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 267.997, `position_y` = -4759, `position_z` = 9.853 WHERE `guid` = 43787 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 268.542, `position_y` = -4771.85, `position_z` = 11.526 WHERE `guid` = 43788 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 277.241, `position_y` = -4757.57, `position_z` = 11.377 WHERE `guid` = 43793 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 278.227, `position_y` = -4771.49, `position_z` = 11.131 WHERE `guid` = 43794 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 279.804, `position_y` = -4770.53, `position_z` = 11.345 WHERE `guid` = 43796 AND `id` = 179968;
-- 43797: off Flakk's spot.
UPDATE `gameobject` SET `position_x` = 280.58, `position_y` = -4763.03, `position_z` = 11.952 WHERE `guid` = 43797 AND `id` = 179968;
-- 43798: off Flakk's spot.
UPDATE `gameobject` SET `position_x` = 280.99, `position_y` = -4765.35, `position_z` = 11.866 WHERE `guid` = 43798 AND `id` = 179968;
