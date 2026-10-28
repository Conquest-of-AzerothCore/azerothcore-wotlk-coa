-- CoA Mulgore: the Iris Sanctuary and the Bloodhoof fire (quests 1660066-1660070) and
-- Stonefather's Circle (500004), with new Windfury harpies for its Ritual Totems.
-- Creature guids 9011400-9011599, gameobject guids 7916700-7916799, gossip menus 932470-932484.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stand-in displays where the CoA model is missing from the client. 162949 is the same row that
-- rev_20260926_31 writes.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(162902, 'Handros', NULL, 0, 8, 8, 0, 104, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162903, 'Ammus Grey-Eye', NULL, 932470, 16, 16, 0, 104, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162904, 'Arkan Fairwind', NULL, 932473, 9, 9, 0, 104, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 0.98, 1, 1, 1, 1, 0, 162950, ''),
(162905, 'Ardunno', NULL, 0, 8, 8, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162906, 'Sage Muudren', NULL, 0, 20, 20, 0, 104, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162908, 'Ancestress Emnil', NULL, 0, 35, 35, 0, 104, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(991485, 'Tharok Windhoof', NULL, 0, 20, 20, 0, 104, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162907, 'Devouring Fire', NULL, 0, 6, 6, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 4, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162909, 'Thick Kodo', NULL, 0, 6, 6, 0, 15, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 1, 0, 162909, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162949, '[TG] Water Tauren', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 130, 0, ''),
(162950, 'Parachute', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (162902, 162903, 162904, 162905, 162906, 162907, 162908, 162909, 162949, 162950, 991485);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162902, 0, 2103, 1, 1),
(162903, 0, 4375, 1, 1),
(162904, 0, 15314, 1, 1),
(162905, 0, 15817, 1, 1),
(162906, 0, 2578, 1, 1),
(162908, 0, 15647, 1, 1),
(991485, 0, 2082, 1, 1),
(162907, 0, 5488, 1, 1),
(162909, 0, 1454, 1, 1),
(162949, 0, 11686, 1, 1),
(162950, 0, 11686, 1, 1);

-- Shared listen-credit marker, the same row as rev_20260923_00 (Goldshire).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `rank`, `unit_class`, `unit_flags`, `type`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `gossip_menu_id`)
VALUES
(162921, '[KC] Listen to Aliscar Lend', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `rank` = VALUES(`rank`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `gossip_menu_id` = VALUES(`gossip_menu_id`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 162921;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162921, 0, 11686, 1, 1);

-- Ardunno lies dead in his hut; the fires carry the Fire Shield the blessing strips.
DELETE FROM `creature_template_addon` WHERE `entry` IN (162902, 162903, 162904, 162905, 162906, 162907, 162908, 162909, 162949, 162950, 991485);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(162905, 0, 0, 7, 0, 0, 0, NULL),
(162907, 0, 0, 0, 0, 0, 0, '267029');

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
-- Greetings and stories are cached npc_text; the option texts are INFERRED.
DELETE FROM `npc_text` WHERE `ID` IN (62713, 62714, 85188, 85203);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(85188, '<The elder’s gaze rests on the horizon; the grasslands of Mulgore roll on for leagues, broken only in the far distance by the abrupt profile of Thunder Bluff.>', '<The elder’s gaze rests on the horizon; the grasslands of Mulgore roll on for leagues, broken only in the far distance by the abrupt profile of Thunder Bluff.>', 0, 0, 1),
(62713, 'As many as memory has allowed me to keep… though my memory is not what it once was.$b$bI could tell you of the Earthmother, whose gentle eyes are the sun and the moon. Whose blush is the passion of all living things; the blood that flows and spills, the call of new mysteries in the dark, the promise to spread and conquer new lands.$b$bI could tell you of the Old Ones, who walked the world before the Earthmother, and whom she buried beneath her flesh. Of how their shadow seeped up from the depths and poisoned all the good she had nurtured.$b$bOr… I could speak of the Grimtotem. Other tauren believe that Shadow twisted Life, made it violent, cruel, merciless. But we, the Grimtotem, see it differently. Life and its laws never changed. The Shadow’s true triumph was to blind us, convincing us that the world was once better than it is today. Shadow torments us with false hopes and pretty lies. It lures us to despise the world we’ve been given, to turn our backs on reality.$b$bWe Grimtotem choose instead to walk in step with the world as it is, without blindfolds, without comforts.', 'As many as memory has allowed me to keep… though my memory is not what it once was.$b$bI could tell you of the Earthmother, whose gentle eyes are the sun and the moon. Whose blush is the passion of all living things; the blood that flows and spills, the call of new mysteries in the dark, the promise to spread and conquer new lands.$b$bI could tell you of the Old Ones, who walked the world before the Earthmother, and whom she buried beneath her flesh. Of how their shadow seeped up from the depths and poisoned all the good she had nurtured.$b$bOr… I could speak of the Grimtotem. Other tauren believe that Shadow twisted Life, made it violent, cruel, merciless. But we, the Grimtotem, see it differently. Life and its laws never changed. The Shadow’s true triumph was to blind us, convincing us that the world was once better than it is today. Shadow torments us with false hopes and pretty lies. It lures us to despise the world we’ve been given, to turn our backs on reality.$b$bWe Grimtotem choose instead to walk in step with the world as it is, without blindfolds, without comforts.', 0, 0, 1),
(62714, 'Once, long ago, before we realized our mistake.$b$bThe spirit of the Hyena is cunning, and there is wisdom in that. But its hunger is a lust, a ravening passion that corrodes the mind as surely as teeth grind carrion bone. Those who sought its favor rarely lived long.$b$bFor this, and other evils, its worship was cast aside. And rightly so. Legend says that in the days after the sacrifice of the Earth Mother, those who followed the Hyena and caught its laughter became what we now know as gnolls.$b$bAnd there is no creature more wretched than a gnoll.', 'Once, long ago, before we realized our mistake.$b$bThe spirit of the Hyena is cunning, and there is wisdom in that. But its hunger is a lust, a ravening passion that corrodes the mind as surely as teeth grind carrion bone. Those who sought its favor rarely lived long.$b$bFor this, and other evils, its worship was cast aside. And rightly so. Legend says that in the days after the sacrifice of the Earth Mother, those who followed the Hyena and caught its laughter became what we now know as gnolls.$b$bAnd there is no creature more wretched than a gnoll.', 0, 0, 1),
(85203, '<The hulking tauren scans the horizon with the same faraway, introspective look as the Sanctuary Matron.>', '<The hulking tauren scans the horizon with the same faraway, introspective look as the Sanctuary Matron.>', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932470, 932471, 932472, 932473);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932470, 85188),
(932471, 62713),
(932472, 62714),
(932473, 85203);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932470, 932471, 932472, 932473);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932470, 0, 0, 'What stories do you keep, elder?', 0, 1, 1, 932471, 0, 0, 0, '', 0),
(932470, 1, 0, 'Did your people ever follow the spirit of the Hyena?', 0, 1, 1, 932472, 0, 0, 0, '', 0),
(932471, 0, 0, '<Stay a while at the cliff''s edge, in silence.>', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932472, 0, 0, '<Stay a while at the cliff''s edge, in silence.>', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932473, 0, 0, 'I need a parachute to get down from here.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (932470, 932471, 932472, 932473) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 932471, 0, 0, 0, 9, 0, 1660070, 0, 0, 0, 0, 0, '', 'show only while quest 1660070 is taken'),
(15, 932472, 0, 0, 0, 9, 0, 1660070, 0, 0, 0, 0, 0, '', 'show only while quest 1660070 is taken'),
(15, 932473, 0, 0, 0, 9, 0, 1660067, 0, 0, 0, 0, 0, '', 'show only while quest 1660067 is taken'),
(15, 932473, 0, 0, 1, 28, 0, 1660067, 0, 0, 0, 0, 0, '', 'or once quest 1660067 is complete (a new parachute)');

-- ---------------------------------------------------------------------------
-- 3. Prairie Sap and loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300552, 3, 88677, 'Prairie Sap', '', '', 1, '', 1689, 2300552, 0, 1, 0, 0, 0, 0, 1660069, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

-- Flags 4 (GO_FLAG_INTERACT_COND): usable only while the quest needs it.
DELETE FROM `gameobject_template_addon` WHERE `entry` = 2300552;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`)
VALUES
(2300552, 0, 4);

DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300552;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300552, 558968, 0, 100, 1, 1, 0, 1, 1, 'Prairie Sap - Prairie Sap');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` = 2300552;
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(2300552, 0, 558968);

-- Quest drops, quest-only: Kodo Tallow from the kodos, Ritual Totems from the Windfury.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (2972, 2973, 2974, 162909) AND `Item` = 558969;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(162909, 558969, 0, 50, 1, 1, 0, 1, 1, 'Thick Kodo - Kodo Tallow'),
(2972, 558969, 0, 50, 1, 1, 0, 1, 1, 'Kodo Calf - Kodo Tallow'),
(2973, 558969, 0, 50, 1, 1, 0, 1, 1, 'Kodo Bull - Kodo Tallow'),
(2974, 558969, 0, 50, 1, 1, 0, 1, 1, 'Kodo Matriarch - Kodo Tallow');

DELETE FROM `creature_loot_template` WHERE `Entry` IN (2964, 2965) AND `Item` = 662335;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2964, 662335, 0, 60, 1, 1, 0, 1, 1, 'Windfury Sorceress - Ritual Totem'),
(2965, 662335, 0, 60, 1, 1, 0, 1, 1, 'Windfury Matriarch - Ritual Totem');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (2972, 2973, 2974, 162909) AND `Idx` = 0;
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(162909, 0, 558969),
(2972, 0, 558969),
(2973, 0, 558969),
(2974, 0, 558969);

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (2964, 2965) AND `Idx` = 1;
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(2964, 1, 662335),
(2965, 1, 662335);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- Chain 1660030 -> 1660066 -> {1660067 -> {1660068, 1660069}, 1660070}; 500004 stands alone. The upsert
-- leaves the POI columns to the markers file.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660066, 2, 8, 5, 215, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Smoke on the Horizon', 'Speak with Ammus Grey-Eye at the summit of the Iris Sanctuary.', 'Headed to Bloodhoof Village, beyond these walls?$b$bI''ve been watching the horizon that way, and I''d swear the wind was carrying smoke; a scorched tang to it.$b$bIt wouldn''t be strange; even here in Mulgore, the tauren are not without enemies.$b$bPay a visit to Ammus Grey-Eye, up on the mesa. She''s the wisest among us and tends the sanctuary at the summit alone.$b$bWe usually go to her for the water she blesses for our rites. If Bloodhoof Village faces a crisis, they''ll need those blessings more than ever.', '', 'Speak with Ammus Grey-Eye.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660067, 2, 8, 5, 215, 0, 0, 0, 0, 0, 0, 0, 4, 260, 337, 0, 0, 0, 0, 558971, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302003, 1, 2302004, 1, 2302005, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Amphora of Sacred Water', 'Fill the amphora with the blessed water of the Iris Sanctuary, and bring it to Sage Muudren in Bloodhoof Village.', 'This sanctuary was raised in honor of the Earthmother and the Sky-Father. When it rains, the hollowed stone at its heart gathers the water the clouds so generously bestow.$b$bThen, with all due ceremony, I bless it.$b$bFill an amphora with the water that washes the totem''s feet, and carry it to Sage Muudren in Bloodhoof Village. With it, he can soothe the roused elements and restore the village''s spiritual harmony.$b$bI do not know if it will mend Ardunno''s rashness, but it will help to soften its effects.', '', 'Find Muudren and deliver the amphora of blessed water.', 0, 162950, 0, 0, 0, 1, 0, 0, 558972, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'Parachute Used', '', ''),
(1660068, 2, 8, 5, 215, 0, 0, 0, 0, 0, 0, 0, 5, 156, 213, 0, 0, 0, 0, 558967, 8, 0, 2302006, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Exile of Embers', 'Channel the blessing to weaken the fire elementals prowling around Ardunno''s hut and banish them back to their elemental plane.', 'Ardunno was the shaman who set the blaze. He died of his own foolishness, and, luck for us, the flames did not spread beyond his hut.$b$bEven so, the elementals he summoned moments before his death still wander among the charred remains. You know the kind I mean: wrathful spirits whose very flesh is fire.$b$bOf the four elements, the most volatile.$b$bI will lay the blessing of these waters upon you. Use it to weaken the fire elementals you find and banish them from this village, from this world, back to their prison-plane.', '', 'Return to Muudren.', 162907, 0, 0, 0, 5, 0, 0, 0, 558967, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(1660069, 2, 8, 5, 215, 0, 0, 0, 0, 0, 0, 0, 5, 83, 114, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302007, 1, 2302008, 1, 2302009, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Smoke that Remembers', 'Obtain incense for Ancestor Emnil''s altar. You will need Prairie Sage and Kodo Tallow.', 'Young $R, my name is Emnil, ancestress of the Bloodhoof.$b$bI crossed the veil centuries ago, long before the children of my children laid claim to these lands. Then they brought my ashes and scattered them in this place; and they raised behind me the great totem you behold.$b$bArdunno, fiery of spirit, reckless, ever enamored of the flame, kept the ritual incense; but with his death the sacred smoke grows thin, and with it my bond to the realm of the living.$b$bWill you, out of honor, rekindle the fragrance and replenish the sacred incense?', '', 'Return to Ancestor Emnil.', 0, 0, 0, 0, 0, 0, 0, 0, 558968, 558969, 0, 0, 0, 0, 6, 2, 0, 0, 0, 0, '', '', '', ''),
(1660070, 2, 8, 5, 215, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stay a While', 'Take a moment from the noise and haste and stay a while to listen to Ammus Grey-Eye.', '<The elder Tauren fits the description of the sanctuary leader, reputed to be among the wisest of her kind.>$b$b<Perhaps she has something worth sharing with you.>', '', 'Say goodbye to Ammus, Grey-Eye.', 162921, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Listen to Ammus Grey-Eye', '', '', ''),
(500004, 2, 10, 4, 215, 0, 0, 0, 0, 0, 0, 0, 5, 175, 315, 0, 0, 0, 0, 0, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Circle’s Rite', 'Collect 8 Ritual Totems and bring them to Maur Tharok Windhoof at Stonefather''s Circle.', 'My disciples were on the road from Thunder Bluff when the Windfury harpies swept down from the cliffs to the north.$B$BDrawn to anything carved or painted, they tore through the packs and snatched the sacred totems meant for our next rite. The disciples escaped with their lives, but the harpies now flaunt those totems as ornaments in their claws and feathers. Without them, the rite cannot begin.$B$BFind the Windfury to the north, $N, and take back what they stole. Return the totems to me so the winds may carry our voices once more.', '', 'Return to Maur Tharok Windhoof at Stonefather''s Circle', 0, 0, 0, 0, 0, 0, 0, 0, 662335, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (500004, 1660066, 1660067, 1660068, 1660069, 1660070);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660066, 0, 0, 1660030, 0, 0),
(1660067, 0, 0, 1660066, 1, 0),
(1660068, 0, 0, 1660067, 1, 0),
(1660069, 0, 0, 1660067, 0, 0),
(1660070, 0, 0, 1660066, 0, 0),
(500004, 0, 0, 0, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (500004, 1660066, 1660067, 1660068, 1660069, 1660070);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660066, 'Oh, a new face.$B$B<The elder cups your cheeks with hands furred in grey and smiles, tenderly.>$B$BYou’re here about the fire in Bloodhoof Village, aren’t you? I warned the village shaman of the dangers tucked inside his fondness for flame.$B$BHe did not listen.'),
(1660067, 'This is…$B$B<The tauren’s gaze warms with gratitude as he regards the amphora of water blessed by Ammus Grey-Eye.>$B$BCan you feel the power these waters give off? Few can, fully. It’s like a caress to the spirit; a hush after a long, noisy day.$B$BThese waters will help me restore the elemental balance Ardunno disturbed. Even so, I will still need your help.'),
(1660068, 'The water’s blessing fades, but it has done its work.$B$BYou return unharmed.$B$BFew can say they’ve faced spirits of fire and lived to tell it.$B$BYou have done Bloodhoof Village a great service, $C.'),
(1660069, 'The incense burns with renewed vigor. By this act, my dignity is restored.$B$BThe children of my children shall yet receive my blessing; in hope, and in words of heartening when the days grow dark.'),
(1660070, 'Rest here a while, on the very edge of the cliff. In silence; at times, words do no more than paw at the truth.$B$BFeel this moment. Keep it, for as long as it lasts.$B$BTaste Life as it is: a force that outstrips flesh and speech alike.'),
(500004, 'These are the ones. The cedar still hums with the songs we carved into it. You’ve saved us the trouble of crafting them all over again, and for that, I’m grateful. The rite will go on when the time is right.');

DELETE FROM `quest_request_items` WHERE `ID` IN (500004, 1660066, 1660067, 1660068, 1660069, 1660070);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660067, 'Another young tauren. This village teems with promising warriors.'),
(1660068, 'Have you quenched the flames?'),
(1660069, 'The curling smoke grows faint. The incense is nearly spent…'),
(500004, 'Have you taken the totems back from the harpies? The rite cannot move forward without them.');

DELETE FROM `creature_queststarter` WHERE `quest` IN (500004, 1660066, 1660067, 1660068, 1660069, 1660070);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(991485, 500004),
(162902, 1660066),
(162903, 1660067),
(162906, 1660068),
(162908, 1660069),
(162903, 1660070);

DELETE FROM `creature_questender` WHERE `quest` IN (500004, 1660066, 1660067, 1660068, 1660069, 1660070);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(991485, 500004),
(162903, 1660066),
(162906, 1660067),
(162906, 1660068),
(162908, 1660069),
(162903, 1660070);

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9011400, 9011401, 9011402, 9011403, 9011404, 9011405, 9011406, 9011407, 9011410, 9011411, 9011412, 9011413, 9011414, 9011415, 9011416, 9011417, 9011418, 9011419, 9011420, 9011421, 9011422, 9011423, 9011424, 9011425, 9011426, 9011427, 9011428, 9011429, 9011440, 9011441, 9011442, 9011443, 9011444, 9011445, 9011446, 9011447, 9011448, 9011449, 9011450, 9011451, 9011452, 9011453, 9011454, 9011455, 9011456, 9011457, 9011460, 9011461, 9011462, 9011463, 9011464, 9011465, 9011466, 9011467, 9011468, 9011469, 9011470, 9011471, 9011472, 9011473) OR `guid` BETWEEN 9011400 AND 9011599;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9011400, 162902, 1, 0, 0, 1, 1, 0, -2960.59, -252.91, 51.688, 6.24, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: Questie point at the west edge of Camp Narache by the great totem; faces north toward Bloodhoof, where he saw the smoke'),
(9011401, 162903, 1, 0, 0, 1, 1, 0, -2913.48, 7.072, 188.885, 0.07, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: ST8745, the 1660066 turn-in at the cliff edge of the Iris Sanctuary summit; her gaze rests on Thunder Bluff'),
(9011402, 162904, 1, 0, 0, 1, 1, 0, -2920.88, 2.869, 189.222, 5.84, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: ST8844, the 1660067 parachute point (Questie 0.9 yd); faces Bloodhoof, where the parachute takes you'),
(9011403, 162949, 1, 0, 0, 1, 1, 0, -2983.53, 9.11, 189.961, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: ST8747, the centre of the 1660067 basin circle (r 10) at the foot of the totem, on the pool bed; invisible, so the Collect Water reach matches the SuperTrack circle'),
(9011404, 162906, 1, 0, 0, 1, 1, 0, -2295.9, -223.629, 3.796, 6.19, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: ST8746, the 1660067/1660068 turn-in at the door of the new tall hut; faces out toward the burnt hut'),
(9011405, 162908, 1, 0, 0, 1, 1, 0, -2354.45, -3.256, 8.317, 5.21, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: ST8749, the 1660069 turn-in below the incense burner; faces away from her totem, toward visitors'),
(9011406, 991485, 1, 0, 0, 1, 1, 0, -1964.83, -354.372, -1.743, 0.29, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: ST8564, the 500004 turn-in inside Stonefather''s Circle; faces the pond at the centre of the stone posts'),
(9011407, 162905, 1, 0, 0, 1, 1, 0, -2295.5, -74.5, 3.768, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Mulgore: on the floor of his burnt hut (Taurenhutbig_Destroyed), where he died (INFERRED; no source places him)'),
(9011410, 162907, 1, 0, 0, 1, 1, 0, -2289.27, -100.74, 2.995, 1.67, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; ST8748, the 1660068 objective point in the signpost ring east of the hut'),
(9011411, 162907, 1, 0, 0, 1, 1, 0, -2308.85, -101.39, 3.331, 1.05, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting beside the broken totem south-east of the hut'),
(9011412, 162907, 1, 0, 0, 1, 1, 0, -2287.61, -75.71, 3.768, 2.44, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting on the charred hut floor'),
(9011413, 162907, 1, 0, 0, 1, 1, 0, -2258.84, -83.93, 3.351, 2.8, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting at the north end of the hut'),
(9011414, 162907, 1, 0, 0, 1, 1, 0, -2310.9, -58.25, 2.843, 5.65, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting by the damaged windbreaks west of the hut'),
(9011415, 162907, 1, 0, 0, 1, 1, 0, -2281.45, -29.48, 5.141, 4.47, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting on the open ground north-west of the windbreaks'),
(9011416, 162907, 1, 0, 0, 1, 1, 0, -2259.87, -0.21, 14.335, 4.29, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting on the rise north-west, where the fire crept uphill'),
(9011417, 162907, 1, 0, 0, 1, 1, 0, -2238.64, -44.38, 5.29, 3.62, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting north of the hut'),
(9011418, 162907, 1, 0, 0, 1, 1, 0, -2342.76, -96.25, -12.637, 0.45, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting on the low ground south, by the fallen tree'),
(9011419, 162907, 1, 0, 0, 1, 1, 0, -2321.18, -139.91, -12.611, 1.16, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting at the foot of the plateau south-east'),
(9011420, 162907, 1, 0, 0, 1, 1, 0, -2349.61, -136.83, -14.15, 0.84, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting on the low ground far south-east'),
(9011421, 162907, 1, 0, 0, 1, 1, 0, -2287.27, -131.18, 1.699, 1.65, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; Questie sighting at the hut end of the bridge to Bloodhoof; stays put'),
(9011422, 162907, 1, 0, 0, 1, 1, 0, -2303, -70, 3.768, 6.1, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; south half of the hut floor, among the looms'),
(9011423, 162907, 1, 0, 0, 1, 1, 0, -2276, -82, 2.904, 2.58, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; north half of the hut, by the wall hanging'),
(9011424, 162907, 1, 0, 0, 1, 1, 0, -2280, -58, 2.898, 4, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; between the hut and the west windbreak'),
(9011425, 162907, 1, 0, 0, 1, 1, 0, -2262, -98, 1.716, 2.43, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; north arc of the signpost ring'),
(9011426, 162907, 1, 0, 0, 1, 1, 0, -2322, -38, 3.699, 5.44, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; south-west plateau past the damaged windbreaks'),
(9011427, 162907, 1, 0, 0, 1, 1, 0, -2330, -112, -13.211, 0.81, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; low ground between the two southern sightings'),
(9011428, 162907, 1, 0, 0, 1, 1, 0, -2300, -35, 2.444, 4.93, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; west of the windbreak line'),
(9011429, 162907, 1, 0, 0, 1, 1, 0, -2252, -66, 2.744, 3.29, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Ardunno''s hut: Devouring Fire; north of the hut, facing its doorway'),
(9011440, 162909, 1, 0, 0, 1, 1, 0, -2442.1, 72.6, 32.196, 5.57, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; Questie sighting (-2443.79, 82.48) moved 10 yd down the south-west slope, clear of the Plainstrider there'),
(9011441, 162909, 1, 0, 0, 1, 1, 0, -2416.74, -72.11, -7.172, 0.84, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; Questie sighting on the low plain'),
(9011442, 162909, 1, 0, 0, 1, 1, 0, -2429.07, -93.17, -4.301, 0.88, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; Questie sighting on the low plain, east end'),
(9011443, 162909, 1, 0, 0, 1, 1, 0, -2434.89, -64.92, -7.373, 0.65, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; Questie sighting on the low plain'),
(9011444, 162909, 1, 0, 0, 1, 1, 0, -2422.56, -4.83, 2.449, 0.02, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; Questie sighting at the foot of the hill below Emnil'),
(9011445, 162909, 1, 0, 0, 1, 1, 0, -2440, -40, -7.227, 0.41, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; open plain between the sightings'),
(9011446, 162909, 1, 0, 0, 1, 1, 0, -2455, -20, 0.27, 0.17, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; gentle rise of the plain west of the low ground'),
(9011447, 162909, 1, 0, 0, 1, 1, 0, -2430, 15, 13.598, 6.05, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; foot of the hill''s south face'),
(9011448, 162909, 1, 0, 0, 1, 1, 0, -2462, 20, 13.623, 6.07, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; grass below the south slope'),
(9011449, 162909, 1, 0, 0, 1, 1, 0, -2440, 45, 25.224, 5.77, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; south slope, clear of the Ambercorn'),
(9011450, 162909, 1, 0, 0, 1, 1, 0, -2470, -54, -3.691, 0.41, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; plain south of the low ground, 4 yd clear of the fallen tree trunk'),
(9011451, 162909, 1, 0, 0, 1, 1, 0, -2452, -85, -3.011, 0.7, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; east end of the plain'),
(9011452, 162909, 1, 0, 0, 1, 1, 0, -2482, 82, 28.769, 5.69, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; west end of the plain below the ridge'),
(9011453, 162909, 1, 0, 0, 1, 1, 0, -2485, -10, 2.746, 0.05, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; middle of the plain''s south half'),
(9011454, 162909, 1, 0, 0, 1, 1, 0, -2465, 58, 24.262, 5.78, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; south slope between the two western sightings'),
(9011455, 162909, 1, 0, 0, 1, 1, 0, -2476, -28, -2.748, 0.2, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; plain between the southern kodos'),
(9011456, 162909, 1, 0, 0, 1, 1, 0, -2456, -68.3, -3.879, 0.57, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; east end of the plain, clear of the Ambercorn and the wolf'),
(9011457, 162909, 1, 0, 0, 1, 1, 0, -2408, -53, -8.552, 0.75, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Emnil''s plain: Thick Kodo; low ground at the foot of the fire plateau, 50 yd south of it'),
(9011460, 2964, 1, 0, 0, 1, 1, 0, -595, 40, 12.342, 2.07, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8562: below the harpy nest in the twin trees'),
(9011461, 2965, 1, 0, 0, 1, 1, 0, -630, 95, 14.092, 5.33, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8562: under the nest in the stone tree grove'),
(9011462, 2964, 1, 0, 0, 1, 1, 0, -555, 95, 42.446, 3.67, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8562: ridge top beside the high nests'),
(9011463, 2965, 1, 0, 0, 1, 1, 0, -610, 20, 1.941, 1.53, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8562: the valley floor south of the grove'),
(9011464, 2964, 1, 0, 0, 1, 1, 0, -640, 60, 6.653, 0.13, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8562: west slope toward the fallen tree'),
(9011465, 2965, 1, 0, 0, 1, 1, 0, -575, 100, 36.09, 3.96, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8562: ridge slope between the nests'),
(9011466, 2964, 1, 0, 0, 1, 1, 0, -620, 70, 16.059, 5.84, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8562: slope below the grove nest'),
(9011467, 2965, 1, 0, 0, 1, 1, 0, -615, -718, 27.763, 4.13, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8563: at the foot of the stone tree with the nest'),
(9011468, 2964, 1, 0, 0, 1, 1, 0, -655, -760, 27.745, 0.67, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8563: slope between the lower and upper harpies'),
(9011469, 2965, 1, 0, 0, 1, 1, 0, -600, -760, 53.544, 2.54, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8563: upper terrace east of the copper vein'),
(9011470, 2964, 1, 0, 0, 1, 1, 0, -635, -700, 12.848, 4.85, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8563: north foot of the ridge'),
(9011471, 2965, 1, 0, 0, 1, 1, 0, -660, -730, 14.655, 5.98, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8563: west slope below the nests'),
(9011472, 2964, 1, 0, 0, 1, 1, 0, -622, -790, 49.583, 1.72, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8563: south terrace by the broad tree'),
(9011473, 2965, 1, 0, 0, 1, 1, 0, -640, -775, 38.66, 1.28, 375, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Windfury Ridge ST8563: slope under the nest trees');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9011400 AND 9011599;

DELETE FROM `gameobject` WHERE `guid` IN (7916700, 7916701, 7916702, 7916703, 7916704, 7916705, 7916706, 7916707, 7916708, 7916709, 7916710, 7916711, 7916712, 7916713, 7916714, 7916715, 7916716, 7916717, 7916718, 7916719, 7916720) OR `guid` BETWEEN 7916700 AND 7916799;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7916700, 2300552, 1, 0, 0, 1, 1, -2377.35, 0.82, 6.825, 1.62, 0, 0, 0.724287, 0.689498, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting at the foot of the big rock by the shrine'),
(7916701, 2300552, 1, 0, 0, 1, 1, -2334.88, 22.39, 20.91, 2.45, 0, 0, 0.940806, 0.338946, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the north face above Emnil'),
(7916702, 2300552, 1, 0, 0, 1, 1, -2317.41, 50.12, 32.892, 2.99, 0, 0, 0.997129, 0.075724, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the north face'),
(7916703, 2300552, 1, 0, 0, 1, 1, -2303.71, 55.26, 31.972, 3.08, 0, 0, 0.999526, 0.030791, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the north shoulder'),
(7916704, 2300552, 1, 0, 0, 1, 1, -2325.63, 66.04, 45.007, 3.25, 0, 0, 0.998531, -0.054177, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting high on the north face'),
(7916705, 2300552, 1, 0, 0, 1, 1, -2312.61, 132.81, 51.455, 3.97, 0, 0, 0.915437, -0.402461, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the far north-west shoulder'),
(7916706, 2300552, 1, 0, 0, 1, 1, -2355.43, 92.24, 66.105, 4.06, 0, 0, 0.896406, -0.443234, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting near the summit'),
(7916707, 2300552, 1, 0, 0, 1, 1, -2374.61, 113.3, 56.354, 4.61, 0, 0, 0.742365, -0.669996, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting west of the summit'),
(7916708, 2300552, 1, 0, 0, 1, 1, -2400.98, 84.53, 48.15, 5.42, 0, 0, 0.418318, -0.908301, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the south shoulder'),
(7916709, 2300552, 1, 0, 0, 1, 1, -2403.38, 65.02, 56.279, 6.07, 0, 0, 0.106391, -0.994324, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the south shoulder'),
(7916710, 2300552, 1, 0, 0, 1, 1, -2408.5, 29.5, 15.231, 0.82, 0, 0, 0.398609, 0.917121, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting (-2406.46, 33.17) moved 4 yd off the tree trunk'),
(7916711, 2300552, 1, 0, 0, 1, 1, -2451.33, 46.53, 23.1, 0.19, 0, 0, 0.094857, 0.995491, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the south slope'),
(7916712, 2300552, 1, 0, 0, 1, 1, -2459.89, 69.64, 28.485, 6.16, 0, 0, 0.061554, -0.998104, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting on the south slope'),
(7916713, 2300552, 1, 0, 0, 1, 1, -2471.88, 63.48, 25.23, 6.25, 0, 0, 0.016592, -0.999862, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; Questie sighting at the west foot of the slope'),
(7916714, 2300552, 1, 0, 0, 1, 1, -2430, 60, 29.727, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; south slope between the sightings'),
(7916715, 2300552, 1, 0, 0, 1, 1, -2340, 110, 58.771, 4.04, 0, 0, 0.900793, -0.434248, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; flat ground on the north-west shoulder'),
(7916716, 2300552, 1, 0, 0, 1, 1, -2420, 95, 39.187, 5.56, 0, 0, 0.353764, -0.935335, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; south-west shoulder'),
(7916717, 2300552, 1, 0, 0, 1, 1, -2295, 85, 40.224, 3.43, 0, 0, 0.989621, -0.143704, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; north shoulder beyond the Questie pair'),
(7916718, 2300552, 1, 0, 0, 1, 1, -2445, 30, 19.197, 0.43, 0, 0, 0.213347, 0.976976, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; lower south slope'),
(7916719, 2300552, 1, 0, 0, 1, 1, -2360, 125, 56.576, 4.41, 0, 0, 0.805544, -0.592536, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; west shoulder below the summit'),
(7916720, 2300552, 1, 0, 0, 1, 1, -2330, 95, 55.33, 3.75, 0, 0, 0.954086, -0.299534, 120, 100, 1, '', 'CoA Emnil''s hill: Prairie Sap; north face, upper terrace');

-- ---------------------------------------------------------------------------
-- 6. Scripts
-- ---------------------------------------------------------------------------
-- Collect Water fills the amphora only within 10 yd of the basin trigger. Arkan lends the stock Parachute
-- and credits it; Ammus credits the shared listen marker; the blessing strips a fire's shield.
DELETE FROM `spell_scripts` WHERE `id` = 256898;
INSERT INTO `spell_scripts` (`id`, `effIndex`, `delay`, `command`, `datalong`, `datalong2`, `dataint`, `x`, `y`, `z`, `o`)
VALUES
(256898, 0, 0, 17, 558972, 1, 0, 0, 0, 0, 0);

DELETE FROM `conditions` WHERE `SourceEntry` = 256898 AND `SourceTypeOrReferenceId` = 17;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(17, 0, 256898, 0, 0, 29, 0, 162949, 10, 0, 0, 60, 0, '', 'Collect Water - only at the Iris Sanctuary basin');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (162903, 162904, 162907) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162903, 0, 0, 1, 62, 0, 100, 0, 932471, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ammus Grey-Eye - On Gossip Option Selected - Close Gossip'),
(162903, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ammus Grey-Eye - Linked - Quest Credit Listen to Ammus Grey-Eye'),
(162903, 0, 2, 3, 62, 0, 100, 0, 932472, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ammus Grey-Eye - On Gossip Option Selected - Close Gossip'),
(162903, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ammus Grey-Eye - Linked - Quest Credit Listen to Ammus Grey-Eye'),
(162904, 0, 0, 1, 62, 0, 100, 0, 932473, 0, 0, 0, 0, 0, 11, 45472, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arkan Fairwind - On Gossip Option Selected - Cast ''Parachute'' on Invoker'),
(162904, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162950, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arkan Fairwind - Linked - Quest Credit Parachute Used'),
(162904, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arkan Fairwind - Linked - Close Gossip'),
(162907, 0, 0, 0, 8, 0, 100, 0, 267028, 0, 0, 0, 0, 0, 28, 267029, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Devouring Fire - On Spellhit ''Extinguish Fire Elementals'' - Remove ''Fire Shield''');
