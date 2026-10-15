-- CoA Durotar: the Warborn Grounds arena (254059-254063), Fighter Fuel (254084), the camp's vendors and
-- crowd, and the stock wildlife CoA's camp built over, moved into the Fighter Fuel circle.
-- Creature guids 9012600-9012749, gameobject guids 7917280-7917319, gossip menu 932534.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stand-in displays where the CoA model is missing from the client. Shadowblood, her totem and the ring
-- trigger have no cache entry (CoA entries 9303635-9303637).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(991518, 'Vince McOrc', NULL, 932534, 10, 10, 0, 29, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(255101, 'Gurgthock', 'Ambitious Assistant', 0, 10, 10, 0, 29, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(99003, 'Shinga', 'Nurse', 0, 8, 8, 0, 29, 2, 1, 1.14286, 20, 0, 2000, 2000, 2, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(254941, 'Lowfang', NULL, 0, 7, 7, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 2.4, 1, 1, 1, 1, 0, 0, ''),
(254945, 'Deathscreech', NULL, 0, 8, 8, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 3.5, 1, 1, 1, 1, 0, 0, ''),
(254947, 'The Masher', NULL, 0, 8, 8, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 3, 1, 1, 1, 1, 0, 0, ''),
(9303635, 'Shadowblood', NULL, 0, 9, 9, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 2, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 3, 1, 1, 1, 1, 0, 0, ''),
(9303636, 'Healing Totem', NULL, 0, 9, 9, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 11, 0, 0, 'SmartAI', 0, 0.2, 1, 1, 1, 1, 0, 0, ''),
(9303637, 'Orcamania Ring', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(764600, 'Kadr', 'Meat Vendor', 0, 30, 30, 0, 29, 128, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764603, 'Zathekkus', 'Drinks', 0, 35, 35, 0, 29, 128, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.136, 1, 1, 1, 1, 0, 0, ''),
(764604, 'Wallace', 'Cheese Vendor', 0, 35, 35, 0, 29, 128, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.136, 1, 1, 1, 1, 0, 0, ''),
(764596, 'Orc Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764597, 'Orc Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764598, 'Troll Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764601, 'Orc Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764602, 'Troll Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764605, 'Orc Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764606, 'Troll Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764607, 'Troll Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764611, 'Troll Spectator', NULL, 0, 1, 1, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764609, 'Pit Fighter', NULL, 0, 8, 8, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.072, 1, 1, 1, 1, 0, 0, ''),
(764610, 'Pit Fighter', NULL, 0, 8, 8, 0, 29, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.072, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (99003, 254941, 254945, 254947, 255101, 764596, 764597, 764598, 764600, 764601, 764602, 764603, 764604, 764605, 764606, 764607, 764609, 764610, 764611, 991518, 9303635, 9303636, 9303637);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(991518, 0, 16438, 1, 1),
(255101, 0, 17836, 1, 1),
(99003, 0, 1897, 1, 1),
(254941, 0, 6042, 1, 1),
(254945, 0, 10873, 1, 1),
(254947, 0, 11548, 1, 1),
(9303635, 0, 15841, 1, 1),
(9303636, 0, 4587, 1, 1),
(9303637, 0, 11686, 1, 1),
(764600, 0, 1390, 1, 1),
(764603, 0, 4082, 1, 1),
(764604, 0, 7180, 1, 1),
(764596, 0, 15891, 1, 1),
(764597, 0, 15892, 1, 1),
(764598, 0, 15893, 1, 1),
(764601, 0, 29659, 1, 1),
(764602, 0, 15894, 1, 1),
(764605, 0, 4966, 1, 1),
(764606, 0, 16446, 1, 1),
(764607, 0, 16445, 1, 1),
(764611, 0, 15893, 1, 1),
(764609, 0, 6044, 1, 1),
(764610, 0, 6042, 1, 1);

DELETE FROM `npc_vendor` WHERE `entry` IN (764600, 764603, 764604);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`)
VALUES
(764600, 0, 772061),
(764600, 1, 772062),
(764600, 2, 772068),
(764600, 3, 772071),
(764603, 0, 772061),
(764603, 1, 772062),
(764603, 2, 772063),
(764603, 3, 772064),
(764603, 4, 772065),
(764603, 5, 772066),
(764603, 6, 772067),
(764603, 7, 772068),
(764603, 8, 772069),
(764603, 9, 772070),
(764604, 0, 772070);

-- ---------------------------------------------------------------------------
-- 2. Vince's gossip
-- ---------------------------------------------------------------------------
-- The greeting and option texts are INFERRED from the quest texts.
DELETE FROM `npc_text` WHERE `ID` = 932534;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(932534, 'Step right up, $c! The crowd came for blood and glory, and you look like you can give them both. Say the word and I''ll send your opponent into the ring.', 'Step right up, $c! The crowd came for blood and glory, and you look like you can give them both. Say the word and I''ll send your opponent into the ring.', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 932534;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932534, 932534);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932534;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932534, 0, 0, 'Send out Lowfang. I''m ready.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932534, 1, 0, 'Send out Deathscreech. I''m ready.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932534, 2, 0, 'Send out The Masher. I''m ready.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932534, 3, 0, 'Send out Shadowblood. I''m ready.', 0, 1, 1, 0, 0, 0, 0, '', 0);

-- ---------------------------------------------------------------------------
-- 3. Infirmary props and Fighter Fuel loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(97451, 5, 1020108, 'Orc Cot 1 RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(99011, 5, 1018218, 'Orc Table RPG PROP', '', 'Inspecting', 1.2, '', 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(99012, 3, 6891, 'Book of Healing', '', 'Inspecting', 1, '', 1689, 99011, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(99013, 5, 1047312, 'Troll Mortar RPG PROP', '', 'Inspecting', 0.4, '', 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(99014, 5, 1010409, 'Grass Mortar RPG PROP', '', 'Inspecting', 0.4, '', 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `gameobject_loot_template` WHERE `Entry` = 99011;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(99011, 705590, 0, 100, 0, 1, 0, 1, 1, 'Book of Healing - Book of Healing');

-- Quest drops, quest-only.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (3126, 3127) AND `Item` = 354316;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(3126, 354316, 0, 75, 1, 1, 0, 1, 1, 'Armored Scorpid - Scorpid Venom'),
(3127, 354316, 0, 75, 1, 1, 0, 1, 1, 'Venomtail Scorpid - Scorpid Venom');

DELETE FROM `creature_loot_template` WHERE `Entry` IN (3099, 3100, 3225) AND `Item` = 354317;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(3099, 354317, 0, 75, 1, 1, 0, 1, 1, 'Dire Mottled Boar - Mottled Boar Tusk'),
(3100, 354317, 0, 75, 1, 1, 0, 1, 1, 'Elder Mottled Boar - Mottled Boar Tusk'),
(3225, 354317, 0, 75, 1, 1, 0, 1, 1, 'Corrupted Mottled Boar - Mottled Boar Tusk');

DELETE FROM `creature_loot_template` WHERE `Entry` IN (3122, 3123) AND `Item` = 354318;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(3122, 354318, 0, 75, 1, 1, 0, 1, 1, 'Bloodtalon Taillasher - Raptor Blood'),
(3123, 354318, 0, 75, 1, 1, 0, 1, 1, 'Bloodtalon Scythemaw - Raptor Blood');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (3099, 3100, 3122, 3123, 3126, 3225) AND `Idx` = 0;
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(3126, 0, 354316),
(3099, 0, 354317),
(3100, 0, 354317),
(3225, 0, 354317),
(3122, 0, 354318),
(3123, 0, 354318);

DELETE FROM `creature_questitem` WHERE `CreatureEntry` = 3127 AND `Idx` = 1;
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(3127, 1, 354316);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- Arena chain 254059 -> 254060 -> 254061 -> 254062 -> 254063; each round completes by event, so SpecialFlags
-- 2. The upsert leaves the POI columns to the markers file.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(254059, 2, 8, 6, 14, 1, 2, 0, 0, 0, 0, 254060, 5, 525, 292, 0, 0, 0, 0, 0, 7, 0, 375250, 75, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warborn Grounds: "Lowfang"', 'Defeat the first challenger: "Lowfang"', 'You! You aren''t just here to spectate, are you? You''re the type who likes a good fight, I can see it in your eyes.    Why don''t you give a round in the ring a go? There''s wealth and glory in it if you win, and a good death if you lose. We''ve got another newbie all lined up, if you win I''ll get some more experienced opponents for you.', 'Defeat "Lowfang"', 'Speak with Vince''s assistant, Gurgthok', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254060, 2, 8, 6, 14, 1, 2, 0, 0, 0, 0, 254061, 6, 525, 292, 0, 0, 0, 0, 0, 7, 0, 375250, 75, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warborn Grounds: "Deathscreech"', 'Defeat the second challenger: "Deathscreech"', 'Don''t get cocky now, Lowfang had no experience in the ring, he''s just a warm-up.    Next in line is a harpy all the way from the Dustwind tribe. Don''t act like that''s so odd, I''ll take anyone willing to fight, doesn''t matter what feuds are happening outside the ring. I didn''t understand her real name, doesn''t matter though, she talked in this horrible screech, so her name in the ring''s Deathscreech.', 'Defeat "Deathscreech"', 'Speak with Vince''s assistant, Gurgthok', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254061, 2, 8, 6, 14, 1, 2, 0, 0, 0, 0, 254062, 6, 525, 292, 0, 0, 0, 0, 0, 7, 0, 375250, 75, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255037, 1, 255038, 1, 255039, 1, 255040, 1, 255041, 1, 255042, 1, 0, 0, 0, 0, 0, 0, 0, 76, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warborn Grounds: "The Masher"', 'Defeat the third challenger: "The Masher"', 'Word is spreading fast about you, $C. The crowd is already calling you the Mysterious Stranger, and some are saying you might go all the way. You have not just surprised the fans. You have made believers out of them.  But this is it. The final round.  Your last opponent is a walking disaster zone. The Masher. Ogre, massive, mean, and completely unhinged. He does not fight clean. He does not hold back. You beat him and the ring is yours.  Go in strong. Walk out a champion.', 'Defeat "The Masher"', 'Speak with Vince''s assistant, Gurgthok', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254062, 2, 9, 7, 14, 1, 2, 0, 0, 0, 0, 254063, 6, 1050, 585, 0, 0, 0, 0, 0, 7, 0, 375250, 125, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warborn Grounds: "Shadowblood"', 'Defeat the fourth challenger: "Shadowblood"', 'More and more bets are pouring in on you, only one other fighter''s stood up to the Masher''s hammer before. A Shadow Hunter from the Darkspear tribe who took up fighting in the arena, she''s the toughest active fighter of the ring right now.    We call her Shadowblood. She''s got a penchant for not dying, maybe there''s a trick up her sleeve, but that''s on you to figure out. The actual champion hasn''t fought in years, so beat her and you''ll be the toughest we''ve got.', 'Shadowblood Defeated', 'Speak with Vince''s assistant, Gurgthok', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254063, 2, 9, 7, 14, 1, 2, 0, 0, 0, 0, 0, 7, 1575, 877, 0, 0, 0, 0, 0, 7, 0, 375250, 200, 1397885, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warborn Grounds: One Last Battle', 'Be crowned champion of Orcamania', 'Looks like the ones who bet on you will be getting paid out well. You beat the best we''ve got, so only one thing''s left now.    Step out into the ring and you''ll be crowned the latest champion of Orcamania!', 'Become the Champion', 'Speak with Vince''s assistant, Gurgthok', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254084, 2, 8, 6, 14, 0, 0, 0, 0, 0, 0, 0, 5, 325, 292, 0, 0, 0, 0, 0, 8, 0, 1397884, 1, 856, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 5, 0, 530, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Fighter Fuel', 'Shinga the nurse wants you to collect 4 Vials of Scorpid Venom, 4 Vials of Raptor Blood, and 4 Boar Tusks.', 'At the rate these fighters are getting themselves hurt, I''m going to run out of healing herbs.    I know another remedy that''d help them recover just as well, but it''s rather dangerous to get, and I''m no fighter.    If you end up going out there, maybe you could bring the ingredients back? I need scorpid venom, raptor blood, and boar tusks. Don''t worry, the venom isn''t harmful if it''s treated the right way.', '', 'Return to Shinga at the Warborn Grounds in Durotar', 0, 0, 0, 0, 0, 0, 0, 0, 354316, 354317, 354318, 0, 0, 0, 4, 4, 4, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (254059, 254060, 254061, 254062, 254063, 254084);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(254059, 0, 0, 0, 0, 2),
(254060, 0, 0, 254059, 0, 2),
(254061, 0, 0, 254060, 0, 2),
(254062, 0, 0, 254061, 0, 2),
(254063, 0, 0, 254062, 0, 2),
(254084, 0, 0, 0, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (254059, 254060, 254061, 254062, 254063, 254084);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(254059, 'Hah! I knew you had it in you to be a real fighter. Don''t worry, Lowfang''s only the beginning, we''ve got plenty of more seasoned competitors lined up.'),
(254060, 'You finally got rid of that harpy! Anyone can fight who''s willing, but she''d gotten most of the crowd cheering against her. Not that I mind, builds investment if people care how the fight goes.$B$BWonder who that Queen Erethina she always yells about is, but that sounds more like a problem for you than me.'),
(254061, 'Thought for sure you were gonna splatter when that club came down on you. Guess you are tougher than you look. The crowd loves an underdog, so this works out just fine.$B$BYou gave them a show. More importantly, you gave them a winner.$B$BHey, if I go start up my own ring, you should sign up. I''ll give you a better challenge, promise.'),
(254062, 'So it was the totems letting her heal herself up, was it?$B$BOf course I knew that! Anyone with half a brain could figure up something was up with those, but not my place to ruin the surprise. It''s more exciting if the fighters have to figure it out on their own, you''d be surprised how many don''t.$B$BGuess you''ve got brains and not just brawn.'),
(254063, 'Now that was a fight! Things haven''t been the same around here since the champion retired, don''t blame him though, no one wanted to fight when they knew they''d lose. But this, this will make things interesting again, and they''re fighting for more than active champion.$B$BSuppose you''re not sticking around though, are you? A shame, but I know how you adventurer lot are, not like I''ve got anything left to throw at you.'),
(254084, 'Yes, yes, that is perfect. You will not believe how quickly this concoction brings them back on their feet. One sip and they are practically ready to tear through a wall.$B$BThank you. With these, we might just get through the next round of injuries without losing anyone. Just… never drink it yourself unless you enjoy waking up days later not knowing where you are.');

DELETE FROM `quest_request_items` WHERE `ID` IN (254059, 254060, 254061, 254062, 254063, 254084);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(254059, 'What are you talking to me for? Get out and fight!'),
(254060, 'What are you talking to me for? Get out and fight!'),
(254061, 'What are you talking to me for? Get out and fight!'),
(254062, 'What are you talking to me for? Get out and fight!'),
(254063, 'What are you talking to me for? Get out and fight!'),
(254084, 'Ah, you are back. Do you have those bizarre ingredients? I know it sounds more like something you would feed to a wild beast than a wounded fighter. Scorpid venom, raptor blood, and boar tusks… what a combination. Still, I swear it works. If it does not cure them, it will at least kick their heart into gear hard enough that they forget they were ever hurt.');

DELETE FROM `creature_queststarter` WHERE `quest` IN (254059, 254060, 254061, 254062, 254063, 254084);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(991518, 254059),
(991518, 254060),
(991518, 254061),
(991518, 254062),
(991518, 254063),
(99003, 254084);

DELETE FROM `creature_questender` WHERE `quest` IN (254059, 254060, 254061, 254062, 254063, 254084);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(255101, 254059),
(255101, 254060),
(255101, 254061),
(255101, 254062),
(255101, 254063),
(99003, 254084);

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9012600, 9012601, 9012602, 9012603, 9012604, 9012605, 9012606, 9012610, 9012611, 9012612, 9012613, 9012614, 9012615, 9012616, 9012617, 9012618, 9012619, 9012620, 9012621, 9012630, 9012631, 9012632, 9012633, 9012634, 9012635, 9012636, 9012637, 9012638, 9012639, 9012640, 9012641, 9012642, 9012643, 9012644, 9012645, 9012646, 9012647, 9012648, 9012649, 9012650, 9012651, 9012652, 9012653, 9012654, 9012655, 9012656, 9012657, 9012658, 9012659, 9012660, 9012661, 9012662, 9012663, 9012664) OR `guid` BETWEEN 9012600 AND 9012749;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9012600, 255101, 1, 0, 0, 1, 1, 0, 178.518, -3966.25, 48.489, 0.08, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: ST8593, the 254059-254061 turn-in on the Orcrefugetower2 balcony; faces the ring'),
(9012601, 991518, 1, 0, 0, 1, 1, 0, 178.3, -3969.2, 48.489, 0.12, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: beside his assistant on the tower balcony, 3 yd from Gurgthock and clear of the brazier; faces the ring'),
(9012602, 99003, 1, 0, 0, 1, 1, 0, 196.9, -4042.9, 49.606, 1.64, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: ST8584 (0.7 yd), the 254084 turn-in in the great hall, a step in front of her table; faces the hall'),
(9012603, 9303637, 1, 0, 0, 1, 1, 0, 213.03, -3963.63, 37.104, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: ST8592, the ring centre; the 254063 walk-in reach'),
(9012604, 764600, 1, 0, 0, 1, 1, 0, 224.8, -3916.5, 39.377, 3.72, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: Exiles zone point 3.6 yd off; under the food stall roof at the north end of its counter'),
(9012605, 764603, 1, 0, 0, 1, 1, 0, 236.4, -3926.4, 39.202, 2.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: Exiles zone point 2.3 yd off; under the drinks stall roof beside his bottle tables'),
(9012606, 764604, 1, 0, 0, 1, 1, 0, 239, -3938.5, 38.943, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: Exiles zone point 4.5 yd off; in front of the cheese tables, facing the passers-by'),
(9012610, 764596, 1, 0, 0, 1, 1, 0, 187, -3942.5, 47.033, 5.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: west bleachers, top bench'),
(9012611, 764598, 1, 0, 0, 1, 1, 0, 189, -3940.5, 46.777, 5.52, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: west bleachers, top bench by the banners'),
(9012612, 764602, 1, 0, 0, 1, 1, 0, 185.5, -3946, 46.693, 5.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: west bleachers, top bench by the gate post'),
(9012613, 764597, 1, 0, 0, 1, 1, 0, 190, -3947.5, 44.525, 5.67, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: west bleachers, front bench'),
(9012614, 764606, 1, 0, 0, 1, 1, 0, 192, -3943, 44.96, 5.51, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: west bleachers, front bench at the ringside end'),
(9012615, 764601, 1, 0, 0, 1, 1, 0, 191, -3984, 44.564, 0.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: east bleachers, on the platform at their foot'),
(9012616, 764607, 1, 0, 0, 1, 1, 0, 192, -3988.5, 45.896, 0.87, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: east bleachers, front bench'),
(9012617, 764605, 1, 0, 0, 1, 1, 0, 189.5, -3991, 47.54, 0.86, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: east bleachers, top bench'),
(9012618, 764611, 1, 0, 0, 1, 1, 0, 186.5, -3983, 45.803, 0.63, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: east bleachers, middle bench by the gate post'),
(9012619, 764596, 1, 0, 0, 1, 1, 0, 184.5, -3985.5, 47.356, 0.65, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: east bleachers, top bench under the banners'),
(9012620, 764609, 1, 0, 0, 1, 1, 0, 234, -3957.5, 35.78, 3.43, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: west post of the fighters'' lane into the ring'),
(9012621, 764610, 1, 0, 0, 1, 1, 0, 232, -3966, 35.806, 3.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Warborn Grounds: east post of the fighters'' lane into the ring'),
(9012630, 3126, 1, 0, 0, 1, 1, 0, 257.5, -4111.5, 36.504, 3.1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north flats, halfway to the road'),
(9012631, 3122, 1, 0, 0, 1, 1, 0, 255, -4126, 36.992, 2.76, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north flats above the road dip'),
(9012632, 3122, 1, 0, 0, 1, 1, 0, 249.5, -4083, 38.206, 3.78, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north-west, where the plain meets the camp approach'),
(9012633, 3126, 1, 0, 0, 1, 1, 0, 246, -4097.5, 38.093, 3.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north side, between the approach and the flats'),
(9012634, 3127, 1, 0, 0, 1, 1, 0, 246.5, -4130.5, 38.305, 2.57, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north side, above the road dip'),
(9012635, 3099, 1, 0, 0, 1, 1, 0, 244, -4144, 37.85, 2.29, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north-east rim, near the road bend'),
(9012636, 3099, 1, 0, 0, 1, 1, 0, 236.5, -4091.5, 39.877, 3.82, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north-west of the centre, open slope'),
(9012637, 3122, 1, 0, 0, 1, 1, 0, 239.5, -4105, 39.068, 3.32, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north of the centre, open slope'),
(9012638, 3126, 1, 0, 0, 1, 1, 0, 235, -4119, 40.056, 2.72, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north-east of the centre'),
(9012639, 3126, 1, 0, 0, 1, 1, 0, 233.5, -4150, 39.416, 2.02, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: eastern rim, above the low ground'),
(9012640, 3122, 1, 0, 0, 1, 1, 0, 226, -4085, 42.23, 4.26, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: west side, 23 yd out from the camp'),
(9012641, 3126, 1, 0, 0, 1, 1, 0, 224.5, -4094.5, 41.669, 4.1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: west of the centre'),
(9012642, 3123, 1, 0, 0, 1, 1, 0, 225, -4148.5, 40.964, 1.85, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: eastern rim'),
(9012643, 3122, 1, 0, 0, 1, 1, 0, 216.5, -4093, 43.164, 4.56, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: west of the centre, below the camp'),
(9012644, 3126, 1, 0, 0, 1, 1, 0, 213, -4106.5, 42.781, 5.01, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: the circle''s centre'),
(9012645, 3122, 1, 0, 0, 1, 1, 0, 216, -4121, 42.684, 1.75, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: east of the centre'),
(9012646, 3126, 1, 0, 0, 1, 1, 0, 212, -4134, 43.362, 1.49, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: east of the centre, on the slope'),
(9012647, 3127, 1, 0, 0, 1, 1, 0, 201, -4096, 45.302, 5.48, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south-west quarter, below the hall'),
(9012648, 3122, 1, 0, 0, 1, 1, 0, 204.5, -4112.5, 43.894, 0.31, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south of the centre'),
(9012649, 3099, 1, 0, 0, 1, 1, 0, 200, -4126, 44.727, 0.87, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south-east of the centre'),
(9012650, 3126, 1, 0, 0, 1, 1, 0, 203, -4140.5, 44.426, 1.23, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south-east quarter'),
(9012651, 3122, 1, 0, 0, 1, 1, 0, 201.5, -4154, 43.94, 1.3, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south-east rim'),
(9012652, 3099, 1, 0, 0, 1, 1, 0, 193.5, -4100, 45.966, 5.85, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south side, open rise'),
(9012653, 3126, 1, 0, 0, 1, 1, 0, 188.5, -4115, 45.916, 0.21, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south side, on the rise'),
(9012654, 3122, 1, 0, 0, 1, 1, 0, 192.5, -4130, 45.631, 0.76, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south-east of the rise'),
(9012655, 3099, 1, 0, 0, 1, 1, 0, 189, -4145.5, 45.91, 0.96, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south-east rim'),
(9012656, 3126, 1, 0, 0, 1, 1, 0, 181, -4092, 48.414, 5.79, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: high south-west ground by the hall'),
(9012657, 3127, 1, 0, 0, 1, 1, 0, 182.5, -4121.5, 46.696, 0.36, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: high south ground'),
(9012658, 3123, 1, 0, 0, 1, 1, 0, 178, -4136, 47.27, 0.64, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: high south-east ground'),
(9012659, 3099, 1, 0, 0, 1, 1, 0, 170, -4118, 48.611, 0.19, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: southern rim, top of the rise'),
(9012660, 3126, 1, 0, 0, 1, 1, 0, 170.5, -4130, 48.226, 0.44, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: southern rim, top of the rise'),
(9012661, 3099, 1, 0, 0, 1, 1, 0, 262, -4103, 35.584, 3.28, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: northern rim, on the low flats'),
(9012662, 3122, 1, 0, 0, 1, 1, 0, 252.5, -4138, 36.745, 2.51, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: north-east rim, above the road dip'),
(9012663, 3122, 1, 0, 0, 1, 1, 0, 181.5, -4084.5, 48.606, 5.63, 300, 7, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: south-west corner, 22 yd out from the hall'),
(9012664, 3099, 1, 0, 0, 1, 1, 0, 220, -4157.5, 41.137, 1.7, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Fighter Fuel circle: eastern rim');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9012600 AND 9012749;

DELETE FROM `gameobject` WHERE `guid` IN (7917280, 7917281, 7917282, 7917283, 7917284) OR `guid` BETWEEN 7917280 AND 7917319;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7917280, 97451, 1, 0, 0, 1, 1, 189.75, -4047.86, 49.606, 1.82, 0, 0, 0.789504, 0.613746, 300, 100, 1, '', 'CoA Warborn infirmary: atlas point in the great hall, a sickbed beside the nurse'),
(7917281, 99011, 1, 0, 0, 1, 1, 196.83, -4044.88, 49.606, 1.82, 0, 0, 0.789504, 0.613746, 300, 100, 1, '', 'CoA Warborn infirmary: atlas point behind Shinga'),
(7917282, 99012, 1, 0, 0, 1, 1, 196.43, -4044.73, 50.573, 1.82, 0, 0, 0.789504, 0.613746, 300, 100, 1, '', 'CoA Warborn infirmary: atlas point on the table'),
(7917283, 99013, 1, 0, 0, 1, 1, 196.71, -4044.36, 50.557, 1.82, 0, 0, 0.789504, 0.613746, 300, 100, 1, '', 'CoA Warborn infirmary: atlas point on the table'),
(7917284, 99014, 1, 0, 0, 1, 1, 196.65, -4044.38, 50.758, 1.82, 0, 0, 0.789504, 0.613746, 300, 100, 1, '', 'CoA Warborn infirmary: atlas point on the table');

-- ---------------------------------------------------------------------------
-- 6. Stock rows moved out of the camp
-- ---------------------------------------------------------------------------
-- Boars, raptors and a scorpid into the Fighter Fuel circle; the hare, adder and Earthroot north of the camp.
UPDATE `creature` SET `position_x` = 259, `position_y` = -4094, `position_z` = 35.997, `orientation` = 3.47, `wander_distance` = 6 WHERE `guid` = 7992 AND `id` = 3100;
UPDATE `creature` SET `position_x` = 249, `position_y` = -4115.5, `position_z` = 37.884, `orientation` = 2.97, `wander_distance` = 6 WHERE `guid` = 4712 AND `id` = 3100;
UPDATE `creature` SET `position_x` = 228.5, `position_y` = -4106, `position_z` = 40.656, `orientation` = 3.38, `wander_distance` = 6 WHERE `guid` = 11871 AND `id` = 3099;
UPDATE `creature` SET `position_x` = 215.5, `position_y` = -4149, `position_z` = 42.378, `orientation` = 1.61, `wander_distance` = 6 WHERE `guid` = 6647 AND `id` = 3100;
UPDATE `creature` SET `position_x` = 204.5, `position_y` = -4084.5, `position_z` = 45.76, `orientation` = 5.07, `wander_distance` = 6 WHERE `guid` = 11879 AND `id` = 3100;
UPDATE `creature` SET `position_x` = 178.5, `position_y` = -4107.5, `position_z` = 47.543, `orientation` = 6.23, `wander_distance` = 6 WHERE `guid` = 10505 AND `id` = 3099;
UPDATE `creature` SET `position_x` = 191, `position_y` = -4084, `position_z` = 47.589, `orientation` = 5.44, `wander_distance` = 7 WHERE `guid` = 7265 AND `id` = 3122;
UPDATE `creature` SET `position_x` = 238.5, `position_y` = -4134.5, `position_z` = 39.539, `orientation` = 2.35, `wander_distance` = 7 WHERE `guid` = 4747 AND `id` = 3123;
UPDATE `creature` SET `position_x` = 240, `position_y` = -4081.5, `position_z` = 39.986, `orientation` = 3.96, `wander_distance` = 5 WHERE `guid` = 6665 AND `id` = 3126;
UPDATE `creature` SET `position_x` = 268, `position_y` = -3895, `position_z` = 34.339, `orientation` = 4.17 WHERE `guid` = 7922 AND `id` = 5951;
UPDATE `creature` SET `position_x` = 266, `position_y` = -3918, `position_z` = 36.571, `orientation` = 1.87 WHERE `guid` = 12152 AND `id` = 3300;
UPDATE `gameobject` SET `position_x` = 274.5, `position_y` = -3926.5, `position_z` = 36.983 WHERE `guid` = 21899 AND `id` = 1619;

-- ---------------------------------------------------------------------------
-- 7. Scripts
-- ---------------------------------------------------------------------------
-- Vince sends each round's opponent into the ring while that round is open and the ring is empty; the
-- opponent's death credits the party. Shadowblood's totems heal her until they are destroyed. Walking into
-- the ring centre on One Last Battle crowns the champion.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (254941, 254945, 254947, 764596, 764597, 764598, 764601, 764602, 764605, 764606, 764607, 764611, 991518, 9303635, 9303636, 9303637) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(254941, 0, 0, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 26, 254059, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Lowfang - On Death - Group Quest Credit 254059'),
(254941, 0, 1, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lowfang - On Evade - Despawn'),
(254945, 0, 0, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 26, 254060, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Deathscreech - On Death - Group Quest Credit 254060'),
(254945, 0, 1, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Deathscreech - On Evade - Despawn'),
(254947, 0, 0, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 26, 254061, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'The Masher - On Death - Group Quest Credit 254061'),
(254947, 0, 1, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'The Masher - On Evade - Despawn'),
(764596, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764597, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764598, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764601, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764602, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764605, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764606, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764607, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(764611, 0, 0, 0, 1, 0, 100, 0, 5000, 20000, 15000, 40000, 0, 0, 10, 4, 15, 21, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectator - Out of Combat - Play Random Emote'),
(991518, 0, 0, 1, 62, 0, 100, 0, 932534, 0, 0, 0, 0, 0, 12, 254941, 4, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 213.03, -3963.63, 37.104, 3.22, 'Vince McOrc - On Gossip Option 0 Selected - Summon ''Lowfang'' In The Ring'),
(991518, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Vince McOrc - Linked - Close Gossip'),
(991518, 0, 2, 3, 62, 0, 100, 0, 932534, 1, 0, 0, 0, 0, 12, 254945, 4, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 213.03, -3963.63, 37.104, 3.22, 'Vince McOrc - On Gossip Option 1 Selected - Summon ''Deathscreech'' In The Ring'),
(991518, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Vince McOrc - Linked - Close Gossip'),
(991518, 0, 4, 5, 62, 0, 100, 0, 932534, 2, 0, 0, 0, 0, 12, 254947, 4, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 213.03, -3963.63, 37.104, 3.22, 'Vince McOrc - On Gossip Option 2 Selected - Summon ''The Masher'' In The Ring'),
(991518, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Vince McOrc - Linked - Close Gossip'),
(991518, 0, 6, 7, 62, 0, 100, 0, 932534, 3, 0, 0, 0, 0, 12, 9303635, 4, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 213.03, -3963.63, 37.104, 3.22, 'Vince McOrc - On Gossip Option 3 Selected - Summon ''Shadowblood'' In The Ring'),
(991518, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Vince McOrc - Linked - Close Gossip'),
(9303635, 0, 0, 1, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9303636, 1, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 213, -3957.5, 37.158, 0, 'Shadowblood - On Aggro - Summon ''Healing Totem'' West'),
(9303635, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9303636, 1, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 213, -3969.7, 37.117, 0, 'Shadowblood - Linked - Summon ''Healing Totem'' East'),
(9303635, 0, 2, 3, 2, 0, 100, 1, 0, 50, 0, 0, 0, 0, 12, 9303636, 1, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 207, -3963.6, 37.166, 0, 'Shadowblood - Between 0-50% Health - Summon ''Healing Totem'' South'),
(9303635, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9303636, 1, 180000, 0, 0, 0, 8, 0, 0, 0, 0, 219, -3963.6, 36.941, 0, 'Shadowblood - Linked - Summon ''Healing Totem'' North'),
(9303635, 0, 4, 0, 0, 0, 100, 0, 3000, 5000, 8000, 11000, 0, 0, 11, 20807, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadowblood - In Combat - Cast ''Shadow Bolt'''),
(9303635, 0, 5, 6, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 26, 254062, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadowblood - On Death - Group Quest Credit 254062'),
(9303635, 0, 6, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 9303636, 80, 0, 0, 0, 0, 0, 0, 'Shadowblood - Linked - Despawn ''Healing Totem'''),
(9303635, 0, 7, 8, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 9303636, 80, 0, 0, 0, 0, 0, 0, 'Shadowblood - On Evade - Despawn ''Healing Totem'''),
(9303635, 0, 8, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadowblood - Linked - Despawn'),
(9303636, 0, 0, 1, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Healing Totem - On Just Summoned - Set Reactstate Passive'),
(9303636, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 103, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Healing Totem - Linked - Root'),
(9303636, 0, 2, 0, 60, 0, 100, 0, 2000, 2000, 4000, 4000, 0, 0, 11, 547, 2, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0, 'Healing Totem - On Update - Cast ''Healing Wave'' On Summoner'),
(9303637, 0, 0, 0, 10, 0, 100, 0, 1, 5, 1000, 1000, 1, 0, 26, 254063, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Orcamania Ring - Within 5 yd - Group Quest Credit 254063');

DELETE FROM `conditions` WHERE `SourceGroup` = 932534 AND `SourceTypeOrReferenceId` = 15;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 932534, 0, 0, 0, 47, 0, 254059, 8, 0, 0, 0, 0, '', 'send out Lowfang only while quest 254059 is incomplete'),
(15, 932534, 0, 0, 0, 29, 1, 254941, 80, 0, 1, 0, 0, '', 'and no living Lowfang is in the ring'),
(15, 932534, 0, 0, 0, 29, 1, 254945, 80, 0, 1, 0, 0, '', 'and no living Deathscreech is in the ring'),
(15, 932534, 0, 0, 0, 29, 1, 254947, 80, 0, 1, 0, 0, '', 'and no living The Masher is in the ring'),
(15, 932534, 0, 0, 0, 29, 1, 9303635, 80, 0, 1, 0, 0, '', 'and no living Shadowblood is in the ring'),
(15, 932534, 1, 0, 0, 47, 0, 254060, 8, 0, 0, 0, 0, '', 'send out Deathscreech only while quest 254060 is incomplete'),
(15, 932534, 1, 0, 0, 29, 1, 254941, 80, 0, 1, 0, 0, '', 'and no living Lowfang is in the ring'),
(15, 932534, 1, 0, 0, 29, 1, 254945, 80, 0, 1, 0, 0, '', 'and no living Deathscreech is in the ring'),
(15, 932534, 1, 0, 0, 29, 1, 254947, 80, 0, 1, 0, 0, '', 'and no living The Masher is in the ring'),
(15, 932534, 1, 0, 0, 29, 1, 9303635, 80, 0, 1, 0, 0, '', 'and no living Shadowblood is in the ring'),
(15, 932534, 2, 0, 0, 47, 0, 254061, 8, 0, 0, 0, 0, '', 'send out The Masher only while quest 254061 is incomplete'),
(15, 932534, 2, 0, 0, 29, 1, 254941, 80, 0, 1, 0, 0, '', 'and no living Lowfang is in the ring'),
(15, 932534, 2, 0, 0, 29, 1, 254945, 80, 0, 1, 0, 0, '', 'and no living Deathscreech is in the ring'),
(15, 932534, 2, 0, 0, 29, 1, 254947, 80, 0, 1, 0, 0, '', 'and no living The Masher is in the ring'),
(15, 932534, 2, 0, 0, 29, 1, 9303635, 80, 0, 1, 0, 0, '', 'and no living Shadowblood is in the ring'),
(15, 932534, 3, 0, 0, 47, 0, 254062, 8, 0, 0, 0, 0, '', 'send out Shadowblood only while quest 254062 is incomplete'),
(15, 932534, 3, 0, 0, 29, 1, 254941, 80, 0, 1, 0, 0, '', 'and no living Lowfang is in the ring'),
(15, 932534, 3, 0, 0, 29, 1, 254945, 80, 0, 1, 0, 0, '', 'and no living Deathscreech is in the ring'),
(15, 932534, 3, 0, 0, 29, 1, 254947, 80, 0, 1, 0, 0, '', 'and no living The Masher is in the ring'),
(15, 932534, 3, 0, 0, 29, 1, 9303635, 80, 0, 1, 0, 0, '', 'and no living Shadowblood is in the ring');

DELETE FROM `conditions` WHERE `SourceEntry` = 9303637 AND `SourceTypeOrReferenceId` = 22;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 9303637, 0, 0, 9, 0, 254063, 0, 0, 0, 0, 0, '', 'crown only players on One Last Battle');
