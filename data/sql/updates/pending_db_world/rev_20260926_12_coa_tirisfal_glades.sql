-- CoA Tirisfal Glades: Chapel of Final Grace, Balnir Farmstead, Edwin Coldwake, Ralden's lab, the Scarlet
-- Monastery grounds and Agamand Mills (quests 254053-254057, 254064); Lieutenant Sanders made hostile;
-- Rear Guard Patrol (356) top-up; stock re-floors and holiday turkeys of these places.
-- Creature guids 9010600-9010849, gameobject guids 7916220-7916399, gossip menus 932427-932438.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stand-in displays where the CoA model is missing from the client.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(991483, 'Father Alastor', NULL, 932429, 15, 15, 0, 68, 3, 1, 1.14286, 20, 0, 2000, 2000, 2, 0, 2048, 0, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(254936, 'Jorum Balnir', NULL, 0, 12, 12, 0, 21, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 2.2, 1, 1, 1, 1, 0, 0, ''),
(254937, 'Vara Balnir', NULL, 0, 12, 12, 0, 21, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 2.2, 1, 1, 1, 1, 0, 0, ''),
(254938, 'Jarim Balnir', NULL, 0, 12, 12, 0, 21, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 2.2, 1, 1, 1, 1, 0, 0, ''),
(254939, 'Duskdrinker', NULL, 0, 9, 9, 0, 16, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 24, 1, 1, 254939, '', 0, 2.45, 1, 1, 1, 1, 0, 0, ''),
(449250, 'Edwin Coldwake', NULL, 932427, 10, 10, 0, 68, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.1, 1, 1, 1, 1, 0, 0, ''),
(449251, 'Darkhound', 'Edwin''s Pet', 0, 10, 10, 0, 68, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1.1, 1, 1, 1, 1, 0, 0, ''),
(764553, 'Apothecary Grelthar', 'Royal Apothecary Society', 0, 12, 12, 0, 68, 128, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(764554, 'Apothecary Ralden', 'Royal Apothecary Society', 932428, 15, 15, 0, 68, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(764555, 'Warden Kaelthar Graveborn', 'Royal Apothecary Society', 932431, 15, 15, 0, 68, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(764556, 'Laboratory Guard', 'Royal Apothecary Society', 0, 15, 15, 0, 68, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(749136, 'Rod Toxicstrike', NULL, 932430, 10, 10, 0, 68, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 512, 2048, 0, 7, 128, 0, '', 0, 1.6268, 1, 1, 1, 1, 0, 0, ''),
(254584, 'Mallek the Tormented', NULL, 0, 9, 9, 0, 21, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 0, 6, 0, 0, 'SmartAI', 0, 1.47, 2, 1, 1, 1, 0, 0, ''),
(254956, 'Concoction Tested on Skeletons', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(254957, 'Concoction Tested on Zombies', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(254958, 'Concoction Tested on Banshees', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(254959, 'Unusual Subject Tested', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (254584, 254936, 254937, 254938, 254939, 254956, 254957, 254958, 254959, 449250, 449251, 749136, 764553, 764554, 764555, 764556, 991483);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(991483, 0, 1579, 1, 1),
(254936, 0, 16397, 1, 1),
(254937, 0, 16399, 1, 1),
(254938, 0, 16398, 1, 1),
(254939, 0, 11829, 1, 1),
(449250, 0, 10834, 1, 1),
(449251, 0, 9020, 1, 1),
(764553, 0, 4109, 1, 1),
(764554, 0, 4111, 1, 1),
(764555, 0, 13839, 1, 1),
(764556, 0, 13839, 1, 1),
(749136, 0, 23877, 1, 1),
(254584, 0, 1602, 1, 1),
(254956, 0, 11686, 1, 1),
(254957, 0, 11686, 1, 1),
(254958, 0, 11686, 1, 1),
(254959, 0, 11686, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (254584, 254936, 254937, 254938, 254939, 254956, 254957, 254958, 254959, 449250, 449251, 749136, 764553, 764554, 764555, 764556, 991483);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(764555, 1, 1897, 1957, 0),
(764556, 1, 1905, 0, 2551);

DELETE FROM `npc_vendor` WHERE `entry` = 764553;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
VALUES
(764553, 0, 734931, 0, 0, 0);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
-- Greetings are cached npc_text whose content names the speaker or his work.
DELETE FROM `npc_text` WHERE `ID` IN (56670, 58299, 58300, 115564, 115590);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(115590, 'Ah, a fresh face in these dreary lands! don''t mind the hound—he’s friendlier than he looks. found him sniffing around the old battlefields, poor thing. guess we’ve both been left behind in one way or another, eh?$B$BBut enough of that—what brings you through tirisfal? looking for trouble, or just trying to avoid it?', 'Ah, a fresh face in these dreary lands! don''t mind the hound—he’s friendlier than he looks. found him sniffing around the old battlefields, poor thing. guess we’ve both been left behind in one way or another, eh?$B$BBut enough of that—what brings you through tirisfal? looking for trouble, or just trying to avoid it?', 0, 0, 1),
(115564, 'You smell that? That’s the scent of progress. A few drops of this in a Scarlet’s rations, and they’ll be ours before the night is through.$B$BThe Scarlet Crusade won’t fall in battle—at least, not entirely. No, they’ll fall when they wake up one morning and realize they fight for the wrong side… or when they can’t tell if their own brothers are enemies or allies. This isn’t just war. This is justice.$B$BThey call us monsters, but tell me—who’s the real monster? The ones who cling to a dead kingdom? Or the ones who survived it? Hah. Doesn’t matter. Soon, the Scarlets will learn to serve the Forsaken… whether they want to or not.', 'You smell that? That’s the scent of progress. A few drops of this in a Scarlet’s rations, and they’ll be ours before the night is through.$B$BThe Scarlet Crusade won’t fall in battle—at least, not entirely. No, they’ll fall when they wake up one morning and realize they fight for the wrong side… or when they can’t tell if their own brothers are enemies or allies. This isn’t just war. This is justice.$B$BThey call us monsters, but tell me—who’s the real monster? The ones who cling to a dead kingdom? Or the ones who survived it? Hah. Doesn’t matter. Soon, the Scarlets will learn to serve the Forsaken… whether they want to or not.', 0, 0, 1),
(58299, 'I feel my body weakening every time I channel the light. But looking at all of these people, trapped in caskets in the ground, alive in undeath and buried for who knows how long...$B$BA little pain is worth soothing their minds.', 'I feel my body weakening every time I channel the light. But looking at all of these people, trapped in caskets in the ground, alive in undeath and buried for who knows how long...$B$BA little pain is worth soothing their minds.', 0, 0, 1),
(56670, 'Ah, another wanderer finds my humble camp.$B$B<The Forsaken gestures to bubbling vials.>$B$BStudying these Agamand undead - mindless puppets, unlike us free-willed Forsaken.$B$BWhat makes us different? Why were we freed from the Lich King''s control when they remain enslaved? That''s what I aim to discover.$B$BThe Dark Lady encourages our... research... but I prefer working away from prying eyes in the Undercity.', 'Ah, another wanderer finds my humble camp.$B$B<The Forsaken gestures to bubbling vials.>$B$BStudying these Agamand undead - mindless puppets, unlike us free-willed Forsaken.$B$BWhat makes us different? Why were we freed from the Lich King''s control when they remain enslaved? That''s what I aim to discover.$B$BThe Dark Lady encourages our... research... but I prefer working away from prying eyes in the Undercity.', 0, 0, 1),
(58300, 'We guard the lab so the Apothecaries can do their work. Simple enough.$B$BExcept it’s not.$B$BThe Crusade keeps testing our line, and every week it feels like they push a little harder. We’re holding, but I can feel the strain. Not sure how much longer I can juggle all this without something giving.', 'We guard the lab so the Apothecaries can do their work. Simple enough.$B$BExcept it’s not.$B$BThe Crusade keeps testing our line, and every week it feels like they push a little harder. We’re holding, but I can feel the strain. Not sure how much longer I can juggle all this without something giving.', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932427, 932428, 932429, 932430, 932431);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932427, 115590),
(932428, 115564),
(932429, 58299),
(932430, 56670),
(932431, 58300);

-- ---------------------------------------------------------------------------
-- 3. World objects and loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(254677, 10, 980926, 'Gravestone', '', 'Polishing', 1, '', 1689, 254053, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(254678, 10, 980926, 'Invincible''s Gravestone', '', 'Polishing', 1.5, '', 1689, 254053, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(254679, 10, 287, 'Scarlet Supplies', '', 'Infecting', 1, '', 1689, 254057, 0, 45000, 0, 1, 45000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(97485, 5, 1009364, 'Kobold Candle Hanger 1 RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(97486, 5, 673, 'General Church Pew RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(97487, 5, 1009365, 'Kobold Candle Rope RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(97488, 5, 1018301, 'Duskwood Grave Frame RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(97489, 5, 1039245, 'Garden Flower Clump Orange RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(97490, 5, 1009366, 'Garden Flower Clump Pink RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(97491, 5, 1057496, 'Garden Flower Clump Red RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(97492, 5, 1018304, 'Stormwind Gravestone Dirt RPG Prop', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(922365, 9, 3412, 'Dusty Plate', '', '', 1, '', 9560, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(922366, 9, 66377, 'Polished Plaque', '', '', 1, '', 9562, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3208962, 5, 1010679, 'Forsaken Tent 02', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3232091, 5, 1006900, 'Alchemist Table', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3239811, 5, 1025092, 'Rug', '', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3288426, 5, 1049058, 'Branch', '', '', 0.25, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(515424, 5, 1020695, 'Log', '', '', 1.89, '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(90095, 5, 36, 'Cargo Box', '', '', 1.1, '', 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `page_text` WHERE `ID` IN (9560, 9562);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(9560, 'Here rests Brandon Alastor$B$BA cherished preacher, devoted healer, and true friend.$B$BMay your soul find eternal peace.', 0),
(9562, 'Welcome to this hallowed ground,$BWhere peace and rest in silence are found.$BHonor those who came before,$BTheir legacy lives forevermore.$B$BIn the stillness, let your heart be light,$BFor here, the past and present unite.$BMay the spirits find their eternal grace,$BAnd may you feel their soft embrace.', 0);

-- Duskdrinker's meat and Sanders's head: 100 %, quest-only.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (13158, 254939);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(254939, 354652, 0, 100, 1, 1, 0, 1, 1, 'Duskdrinker - Tender Duskbat Meat'),
(13158, 354678, 0, 100, 1, 1, 0, 1, 1, 'Lieutenant Sanders - Lieutenant Sanders''s Head');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (13158, 254939);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(254939, 0, 354652),
(13158, 0, 354678);

-- Lieutenant Sanders (stock 13158): a hostile Scarlet like the friars of his camp, with loot.
UPDATE `creature_template` SET `faction` = 67, `lootid` = 13158 WHERE `entry` = 13158;

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- 254057 follows 254056.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(254053, 2, 11, 6, 85, 0, 0, 0, 0, 0, 0, 0, 5, 375, 202, 0, 0, 0, 0, 0, 0, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Humble Duty', 'Polish 6 gravestones at Father Alastor''s cemetary and Invincible''s grave at Balnir Farmstead.', 'If you’ll hear a simple request, these old bones do not carry the strength they once did. Faith in the Light... it was never meant for those like us. And this body doesn’t always answer when duty calls.$B$BThe graves in the cemetery have gone untended for far too long. Those poor souls likely have no one left in this world to remember them, but they deserve dignity all the same.$B$BIf you find the time, you might also tend to the grave of Arthas''s steed at the Balnir Farmstead. His master’s crimes are many, but the horse was loyal... and he died before the Lich King''s shadow ever fell across the land.$B$BHad he lived longer, perhaps the tale might have ended differently.', '', 'Return to Father Alastor in Tirisfal Glades.', -254677, -254678, 0, 0, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravestones Polished', 'Invincible''s Gravestone Polished', '', ''),
(254054, 2, 12, 6, 85, 1, 2, 0, 0, 0, 0, 0, 6, 375, 202, 0, 0, 0, 0, 0, 0, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Balnirs'' Rest', 'Put the spirits of the Balnir family, Jorum Balnir, Vara Balnir, and Jarim Balnir to rest.', 'The Balnir family once bred some of the finest steeds on all of Azeroth, favored by even the royalty. Even with such clients, they never let it get to their head, they were kind, humble folk, I believe their horses took after them, and that was why they were favored so.$B$B...But that is all in the past. The farmstead is in ruins now, and only the restless dead lives there. I am certain the Balnirs themselves must be amongst them, but though I may wield the light, it pains me now, I do not trust my power in a fight anymore.$B$BIf you would have it in your heart, could you put their poor souls to rest in my stead. There were three in total, Vara, Jorum, and their son Jarim.', '', 'Return to Father Alastor in Tirisfal Glades.', 254936, 254937, 254938, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254055, 2, 8, 4, 85, 0, 0, 0, 0, 0, 0, 0, 5, 675, 315, 0, 0, 0, 0, 0, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Darkhound''s Treat', 'Find a treat and give it to Edwin''s hound.', 'You still look a bit nervous, don''t worry, he won''t bite. Not unless I tell him to anyways.$B$BAlright, here, why don''t you do something to earn his trust a bit? He''s quite fond of those duskbats, took a while to train him not to just rush at them when they wander by the camp actually.$B$BI''ve been seeing a big one off to the east, been meaning to go hunt it for him, but since you''re here, why don''t you go find it and give him a piece?', '', 'Return to Edwin Coldwake.', 449251, 0, 0, 0, 1, 0, 0, 0, 354652, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Edwin''s Darkhound Fed', '', '', ''),
(254056, 2, 12, 7, 85, 0, 0, 0, 0, 0, 0, 0, 5, 475, 202, 0, 0, 0, 0, 0, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Brewing Disarray', 'Slay Lieutenant Sanders in Venomweb Vale and bring his head to Apothecary Ralden', 'Being stationed out here, we face constant attack from the Scarlet Crusade. We''ve held off their attacks thus far so the Apothecaries can do their work, and mostly they''ve stopped sending their people to their deaths.$B$BBut recently, some upstart Lieutenant got placed in charge of their camp in Venonweb Vale, and he''s been organizing more coordinated attacks against us. I''m not sure how much longer we can hold out, so I''d like to see Lieutenant Sanders dead.$B$BWithout him, we can only hope they''ll become disorganized enough to leave us alone for now. Apothecary Ralden has been asking constantly if we''ve taken off the Lieutenant''s head, so go bring it to him when you''re done so he''ll be off our backs.', '', 'Inform Apothecary Ralden of Lieutenant Sanders'' death', 0, 0, 0, 0, 0, 0, 0, 0, 354678, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(254057, 2, 12, 7, 85, 0, 0, 0, 0, 0, 0, 0, 6, 975, 202, 0, 0, 0, 0, 354654, 0, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'This Is Justice', 'Use Ralden''s Transformation Elixir to infiltrate the Scarlet Monastery''s courtyard and infect their supplies.', 'There. It''s done. With this, the Scarlet Crusade won''t even know they''ve lost until it''s too late.$B$BNow the last step is getting it to them without raising suspicion. That''s what the lieutenant''s head was for.$B$BI''ve whipped up an elixir that''ll make you look just like him. It should get you into the monastery without much trouble. Just don''t get too close to anyone if you can help it, and keep moving. This sort of thing isn''t foolproof, but as long as you don''t do anything idiotic, you''ll be fine.$B$BAnd don''t even think about picking a fight. The monastery guards aren''t like the ones at that camp. They can scatter your insides across the grass with one swing. If they figure out you aren''t their lieutenant, they won''t hesitate to prove it.', '', 'Return to Apothecary Ralden.', -254679, 0, 0, 0, 6, 0, 0, 0, 354654, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Scarlet Supplies Infected', '', '', ''),
(254064, 2, 8, 4, 85, 0, 0, 0, 0, 0, 0, 0, 5, 675, 315, 0, 0, 0, 0, 354655, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Nature of Freedom', 'Test Rod Toxicstrike''s concoction on 3 zombies, 3 skeletons, 3 banshees, and Mallek the Tormented', 'You know, since you''re going around these parts anyway, you could help me with something. I''m a scientist, not a fighter, you see. Unfortunately, those are two positions that intersect more often than I care to admit.$B$BWe Forsaken broke free of the Scourge, but many still serve it. Some are in far worse states of decay, like most of the ones around the Mills here, but others prove more difficult to explain. Our Dark Lady was once a banshee, yet I''ve spotted banshees in this region who remain bound to the Scourge.$B$BPerhaps it''s simply a matter of will. Even so, surely there must be a way to nudge at least some who retain a portion of themselves into severing their bond to the Lich King, no? That’s the basis of my theory. Alas, this concoction is as far as I can safely get.$B$BPerhaps you could give it a try? It should instate a temporary surge of power which, if my thesis is correct, might give them a chance to assert control. In practice, it does little on its own, but if someone like you were to weaken the forces binding them first, I''d expect it to prove far more potent.', '', 'Return to Rod Toxicstrike.', 254956, 254957, 254958, 254959, 3, 3, 3, 1, 354655, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Concoction Tested on Skeletons', 'Concoction Tested on Zombies', 'Concoction Tested on Banshees', 'Unusual Subject Tested')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (254053, 254054, 254055, 254056, 254057, 254064);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(254053, 0, 0, 0, 0, 0),
(254054, 0, 0, 0, 0, 0),
(254055, 0, 0, 0, 0, 0),
(254056, 0, 0, 0, 0, 0),
(254057, 0, 0, 254056, 1, 0),
(254064, 0, 0, 0, 1, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (254053, 254054, 254055, 254056, 254057, 254064);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(254053, 'I thank you for this. My love for this world and the people in it makes this pain bearable, but I am still wielding a power that now fights against my very being. There are days I can almost forget it, but sometimes I must remain here and conserve my strength.$B$B...Invincible''s grave has been opened?! By the light! Has Arthas not caused enough suffering already that he will not even let that poor horse rest in peace?$B$BI am sorry, thank you for bringing me the news at least, and for making this journey in my stead.'),
(254054, 'So they can finally rest. I am most grateful, you are truly kind, or perhaps you simply accept any job you are offered. The outcome is the same. It is a small difference amidst all the restless souls left behind by the Scourge, but still, I am glad.'),
(254055, 'There you go, see, he''ll love you forever now.$B$BI''ll take the rest of it off your hand, he can have it later.'),
(254056, 'He''s dead? Excellent news!$B$BWithout him, I doubt we''ll have much to worry about. Some low ranking fodder won''t be doing much more than holding down the camp against the local wildlife.$B$BNow, let''s see that face of his...$B$BNot bad, not bad at all, I can work with this.'),
(254057, 'It''s done? Good, good. We''ll keep an eye on them from here and see how well it spreads.$B$BScience always takes a few tries, but even if it doesn''t actually wipe out those Scarlet wretches here and now, it should at least trim down their ranks and soften them up for when we get a proper team together for an attack on the monastery.'),
(254064, 'This one wandered over here not too long ago, I take it he was the only one you had any luck with?$B$BGiven the nature of this research, I can count us fortunate even one of this lot was able to break free. For that matter, it is more fortunate for this one in particular, for he seems quite willing to aid in my research.$B$BAn expert on the necromantic arts...this might just be precisely what I need to achieve better results. Yes, this will do just fine.');

DELETE FROM `quest_request_items` WHERE `ID` IN (254053, 254054, 254055, 254056, 254057, 254064);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(254053, 'Invincible''s Grave is a much longer journey than the others, I do apologize for that.'),
(254054, 'That poor family deserves their rest. I hope we can at least grant them that much.'),
(254055, 'He loves any Duskbat meat, but I''m sure that big one is especially juicy.$B$BDon''t give him the whole thing at once though, he doesn''t need that much even if he''ll tell you otherwise! A piece should be plenty.'),
(254056, 'What is it now? I’m busy. Unless you’ve brought me something useful or dead, don’t waste my time.'),
(254057, 'What are you still doing here? I already gave you the elixir. Use it. Get moving. Or would you rather I test it on something slower?'),
(254064, 'Have you received any results thus far? I understand, such research takes much time, we can discuss it further once you''ve finished.');

DELETE FROM `creature_queststarter` WHERE `quest` IN (254053, 254054, 254055, 254056, 254057, 254064);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(991483, 254053),
(991483, 254054),
(449250, 254055),
(764555, 254056),
(764554, 254057),
(749136, 254064);

DELETE FROM `creature_questender` WHERE `quest` IN (254053, 254054, 254055, 254056, 254057, 254064);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(991483, 254053),
(991483, 254054),
(449250, 254055),
(764554, 254056),
(764554, 254057),
(749136, 254064);

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9010600, 9010601, 9010602, 9010603, 9010604, 9010605, 9010606, 9010607, 9010608, 9010609, 9010610, 9010611, 9010612, 9010613, 9010620, 9010621, 9010622, 9010623, 9010624, 9010625, 9010626, 9010627, 9010628, 9010629, 9010630, 9010631, 9010632, 9010633, 9010634, 9010635, 9010636, 9010637, 9010638, 9010639, 9010640, 9010641, 9010642, 9010643) OR `guid` BETWEEN 9010600 AND 9010849;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9010600, 991483, 0, 0, 0, 1, 1, 0, 1910.4, -152.63, 38.326, 5.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8611, at the foot of the chapel dais, facing the nave and door'),
(9010601, 254936, 0, 0, 0, 1, 1, 0, 2042.9, -460.3, 35.894, 3.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8614 on the barn floor, beside the water barrel'),
(9010602, 254937, 0, 0, 0, 1, 1, 0, 1965.86, -464.33, 34.62, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8615 in the burnt farmhouse garden'),
(9010603, 254938, 0, 0, 0, 1, 1, 0, 1998.77, -348.27, 35.452, 3.4, 300, 0, 0, 1, 0, 2, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: first Questie sighting, start of his ST8613 round'),
(9010604, 254939, 0, 0, 0, 1, 1, 0, 1647.39, -520.31, 46.609, 1.6, 300, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8554 centre, in the duskbat meadow'),
(9010605, 449250, 0, 0, 0, 1, 1, 0, 1665.06, -368.91, 44.998, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8610 at his tent, facing the duskbat meadow'),
(9010606, 449251, 0, 0, 0, 1, 1, 0, 1666.84, -463.91, 44.999, 1.59, 120, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8608, watching the meadow for duskbats'),
(9010607, 764555, 0, 0, 0, 1, 1, 1, 2479.64, -404.29, 77.27, 2.45, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: Questie point inside the lab door, facing it'),
(9010608, 764554, 0, 0, 0, 1, 1, 0, 2489.09, -392.8, 77.101, 3.61, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8589 at his workbench, facing the door'),
(9010609, 764553, 0, 0, 0, 1, 1, 0, 2481.15, -400.68, 77.101, 1.91, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: Exiles point by the book table'),
(9010610, 764556, 0, 0, 0, 1, 1, 1, 2470, -398.2, 76.299, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: west foot of the lab stair, facing out'),
(9010611, 764556, 0, 0, 0, 1, 1, 1, 2470.5, -405.5, 75.993, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: east foot of the lab stair, facing out'),
(9010612, 749136, 0, 0, 0, 1, 1, 0, 2655, 1046.1, 105.028, 2.24, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8620 (0.6 yd) in front of his log, facing the table'),
(9010613, 254584, 0, 0, 0, 1, 1, 0, 2773.54, 713.22, 160.791, 1.91, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: ST8576 on the ridge above the Mills'),
(9010620, 1529, 0, 0, 0, 1, 1, 0, 2072, -345, 37.223, 4.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: north field below the ridge'),
(9010621, 1529, 0, 0, 0, 1, 1, 0, 2068, -318, 41.076, 3.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: north-west corner by the copper ridge'),
(9010622, 1529, 0, 0, 0, 1, 1, 0, 2066, -392, 38.212, 2.1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: north field between the plough and the barn'),
(9010623, 1529, 0, 0, 0, 1, 1, 0, 2068, -485, 42.689, 3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: rise east of the barn under the canopy trees'),
(9010624, 1529, 0, 0, 0, 1, 1, 0, 2058, -495, 43.355, 1.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: behind the barn toward the open grave'),
(9010625, 1529, 0, 0, 0, 1, 1, 0, 1931, -340, 36.132, 0.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: west strip by the canopy trees'),
(9010626, 1529, 0, 0, 0, 1, 1, 0, 1942, -374, 35.452, 5.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: west field'),
(9010627, 1529, 0, 0, 0, 1, 1, 0, 1936, -462, 34.704, 0.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: south-west of the burnt farmhouse'),
(9010628, 1529, 0, 0, 0, 1, 1, 0, 1962, -500, 34.929, 1.8, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: south field past the planters'),
(9010629, 1529, 0, 0, 0, 1, 1, 0, 2006, -500, 39.243, 2.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: slope south of the silos'),
(9010630, 1529, 0, 0, 0, 1, 1, 0, 1966, -338, 35.452, 4.8, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: north-west of the yard'),
(9010631, 1529, 0, 0, 0, 1, 1, 0, 2026, -398, 35.452, 3.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: yard north of the hay wagon'),
(9010632, 1532, 0, 0, 0, 1, 1, 0, 2078, -395, 43.566, 3.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: foot of the north ridge'),
(9010633, 1532, 0, 0, 0, 1, 1, 0, 2084, -420, 43.201, 2.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: north-east field short of the canopy trees'),
(9010634, 1532, 0, 0, 0, 1, 1, 0, 2060, -330, 36.692, 5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: north-west field by the lone duskbat'),
(9010635, 1532, 0, 0, 0, 1, 1, 0, 2066, -512, 49.679, 0.7, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: grave rise north of the open grave'),
(9010636, 1532, 0, 0, 0, 1, 1, 0, 2030, -495, 41.166, 1.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: between the barn and the open grave'),
(9010637, 1532, 0, 0, 0, 1, 1, 0, 1950, -350, 35.452, 6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: west field'),
(9010638, 1532, 0, 0, 0, 1, 1, 0, 1932, -430, 35.522, 0.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: west edge of the farmhouse garden'),
(9010639, 1532, 0, 0, 0, 1, 1, 0, 1948, -485, 34.525, 2.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: south field'),
(9010640, 1532, 0, 0, 0, 1, 1, 0, 1985, -505, 35.91, 1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: south field toward the rise'),
(9010641, 1532, 0, 0, 0, 1, 1, 0, 1996, -475, 34.525, 3.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: by the broken wagon near the silos'),
(9010642, 1532, 0, 0, 0, 1, 1, 0, 1972, -420, 35.452, 4.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: west yard by the dead mule'),
(9010643, 1532, 0, 0, 0, 1, 1, 0, 2052, -395, 35.517, 2.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Balnir Farmstead: north yard between the plough and the shed');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9010600 AND 9010849;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES (9010603, 90106030, 0, 0, 1, 0, 0, NULL);

-- Jarim Balnir's round through both of his Questie sightings.
DELETE FROM `waypoint_data` WHERE `id` BETWEEN 90106000 AND 90108499;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`)
VALUES
(90106030, 1, 1998.77, -348.27, 35.452, NULL, 0, 3000, 0, 0, 0, 100, 0),
(90106030, 2, 1976.77, -341.95, 35.452, NULL, 0, 0, 0, 0, 0, 100, 0),
(90106030, 3, 1968, -370, 35.452, NULL, 0, 0, 0, 0, 0, 100, 0),
(90106030, 4, 1985, -400, 35.452, NULL, 0, 3000, 0, 0, 0, 100, 0),
(90106030, 5, 2012, -405, 35.452, NULL, 0, 0, 0, 0, 0, 100, 0),
(90106030, 6, 2022, -375, 35.452, NULL, 0, 0, 0, 0, 0, 100, 0);

DELETE FROM `gameobject` WHERE `guid` IN (7916220, 7916221, 7916222, 7916223, 7916224, 7916225, 7916226, 7916227, 7916228, 7916229, 7916230, 7916231, 7916232, 7916233, 7916234, 7916235, 7916236, 7916237, 7916240, 7916241, 7916242, 7916243, 7916244, 7916245, 7916246, 7916247, 7916248, 7916249, 7916250, 7916251, 7916252, 7916253, 7916254, 7916255, 7916256, 7916257, 7916270, 7916271, 7916272, 7916273, 7916274, 7916275, 7916276, 7916277, 7916278, 7916279, 7916280, 7916281, 7916282, 7916283, 7916284, 7916285, 7916286) OR `guid` BETWEEN 7916220 AND 7916399;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7916220, 254677, 0, 0, 0, 1, 1, 1909.34, -136.357, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone03 (atlas sighting)'),
(7916221, 254677, 0, 0, 0, 1, 1, 1910.1, -133.76, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone02'),
(7916222, 254677, 0, 0, 0, 1, 1, 1911.27, -131.27, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on 7FK_Forsaken_Grave03'),
(7916223, 254677, 0, 0, 0, 1, 1, 1912.68, -128.93, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone01'),
(7916224, 254677, 0, 0, 0, 1, 1, 1915.14, -123.84, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on 7FK_Forsaken_Grave04'),
(7916225, 254677, 0, 0, 0, 1, 1, 1916.17, -121.69, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone04'),
(7916226, 254677, 0, 0, 0, 1, 1, 1922.49, -125.37, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on 7FK_Forsaken_Grave04'),
(7916227, 254677, 0, 0, 0, 1, 1, 1920.47, -129.53, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone02'),
(7916228, 254677, 0, 0, 0, 1, 1, 1926.13, -129.61, 36.29, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on 7FK_Forsaken_Grave01'),
(7916229, 254677, 0, 0, 0, 1, 1, 1930.94, -129.6, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone02'),
(7916230, 254677, 0, 0, 0, 1, 1, 1936.21, -132.52, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone01'),
(7916231, 254677, 0, 0, 0, 1, 1, 1918.07, -134.3, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone04'),
(7916232, 254677, 0, 0, 0, 1, 1, 1915.46, -139.65, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on 7FK_Forsaken_Grave02'),
(7916233, 254677, 0, 0, 0, 1, 1, 1921.68, -139.57, 35.93, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Crypt03'),
(7916234, 254677, 0, 0, 0, 1, 1, 1920.13, -141.9, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on 7FK_Forsaken_Grave04'),
(7916235, 254677, 0, 0, 0, 1, 1, 1925.06, -144.7, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on 7FK_Forsaken_Grave03'),
(7916236, 254677, 0, 0, 0, 1, 1, 1929.44, -146.92, 36.41, 2.68, 0, 0, 0.973485, 0.228753, 60, 100, 1, '', 'CoA chapel yard: Gravestone on Worgen_Gravestone03'),
(7916237, 254678, 0, 0, 0, 1, 1, 2042.9, -520.3, 43.84, 3.05, 0, 0, 0.998952, 0.04578, 60, 100, 1, '', 'CoA Balnir: Invincible''s Gravestone, on the open grave before the monument (ST8556 0.96 yd)'),
(7916240, 254679, 0, 0, 0, 1, 1, 2838.56, -687.201, 139.904, 3.9, 0, 0, 0.92896, -0.370181, 60, 100, 1, '', 'CoA monastery grounds: atlas sighting on the bench under the gate arch'),
(7916241, 254679, 0, 0, 0, 1, 1, 2835.18, -683.96, 137.15, 0.8, 0, 0, 0.389418, 0.921061, 60, 100, 1, '', 'CoA monastery grounds: Questie sighting outside the gate arch'),
(7916242, 254679, 0, 0, 0, 1, 1, 2881.28, -642.84, 137.84, 1.6, 0, 0, 0.717356, 0.696707, 60, 100, 1, '', 'CoA monastery grounds: Questie sighting by the horse paddock'),
(7916243, 254679, 0, 0, 0, 1, 1, 2905.68, -755.34, 153.98, 5.1, 0, 0, 0.557684, -0.830054, 60, 100, 1, '', 'CoA monastery grounds: Questie sighting in the fountain garden'),
(7916244, 254679, 0, 0, 0, 1, 1, 2789.68, -842.99, 153.98, 0.1, 0, 0, 0.049979, 0.99875, 60, 100, 1, '', 'CoA monastery grounds: Questie sighting by the fence torch'),
(7916245, 254679, 0, 0, 0, 1, 1, 2794.8, -871.46, 154.05, 5.7, 0, 0, 0.287478, -0.957787, 60, 100, 1, '', 'CoA monastery grounds: Questie sighting before the field altar'),
(7916246, 254679, 0, 0, 0, 1, 1, 2819, -702, 137.11, 2.3, 0, 0, 0.912764, 0.408487, 60, 100, 1, '', 'CoA monastery grounds: under the Scarlet banner by the gate torch'),
(7916247, 254679, 0, 0, 0, 1, 1, 2786.5, -706.5, 129.63, 1.5, 0, 0, 0.681639, 0.731689, 60, 100, 1, '', 'CoA monastery grounds: between the two torches of the west path'),
(7916248, 254679, 0, 0, 0, 1, 1, 2779, -731, 130.06, 4, 0, 0, 0.909297, -0.416147, 60, 100, 1, '', 'CoA monastery grounds: at the west path bend by its torches'),
(7916249, 254679, 0, 0, 0, 1, 1, 2801.5, -756, 139.61, 1.9, 0, 0, 0.813416, 0.581683, 60, 100, 1, '', 'CoA monastery grounds: between the torches of the middle path'),
(7916250, 254679, 0, 0, 0, 1, 1, 2802, -786, 142.59, 1.4, 0, 0, 0.644218, 0.764842, 60, 100, 1, '', 'CoA monastery grounds: beside the torch pair of the upper path'),
(7916251, 254679, 0, 0, 0, 1, 1, 2811.5, -818, 153.24, 3.2, 0, 0, 0.999574, -0.0292, 60, 100, 1, '', 'CoA monastery grounds: at the torch where the path meets the upper field'),
(7916252, 254679, 0, 0, 0, 1, 1, 2791.5, -826, 154.62, 4.7, 0, 0, 0.711473, -0.702713, 60, 100, 1, '', 'CoA monastery grounds: inside the fence end by its torch'),
(7916253, 254679, 0, 0, 0, 1, 1, 2824, -876, 153.984, 2.6, 0, 0, 0.963558, 0.267499, 60, 100, 1, '', 'CoA monastery grounds: beside the field altar and its wall banner'),
(7916254, 254679, 0, 0, 0, 1, 1, 2885, -679, 137.17, 0.4, 0, 0, 0.198669, 0.980067, 60, 100, 1, '', 'CoA monastery grounds: against the paddock fence, north side'),
(7916255, 254679, 0, 0, 0, 1, 1, 2928, -745, 153.98, 3.5, 0, 0, 0.983986, -0.178246, 60, 100, 1, '', 'CoA monastery grounds: east of the fountain among the pines'),
(7916256, 254679, 0, 0, 0, 1, 1, 2850, -660, 137.6, 5.3, 0, 0, 0.472031, -0.881582, 60, 100, 1, '', 'CoA monastery grounds: on the lawn between the gate and the paddock'),
(7916257, 254679, 0, 0, 0, 1, 1, 2760, -770, 136.33, 0.6, 0, 0, 0.29552, 0.955336, 60, 100, 1, '', 'CoA monastery grounds: lower garden by the earthroot'),
(7916270, 97485, 0, 0, 0, 1, 1, 1913.83, -159.961, 38.344, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: chapel nave, candle stand'),
(7916271, 97486, 0, 0, 0, 1, 1, 1907.767, -156.561, 38.326, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: chapel pew before the dais'),
(7916272, 97487, 0, 0, 0, 1, 1, 1928.926, -159.641, 41.919, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: candle rope hung in the nave'),
(7916273, 97488, 0, 0, 0, 1, 1, 1919.19, -151.006, 38.329, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: grave frame in the nave'),
(7916274, 97489, 0, 0, 0, 1, 1, 1920.94, -152.082, 38.932, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: flowers on the grave'),
(7916275, 97490, 0, 0, 0, 1, 1, 1917.82, -150.311, 38.857, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: flowers on the grave'),
(7916276, 97491, 0, 0, 0, 1, 1, 1917.679, -149.855, 38.902, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: flowers on the grave'),
(7916277, 97492, 0, 0, 0, 1, 1, 1919.21, -151.201, 38.074, 2.66, 0, 0, 0.971148, 0.238476, 180, 100, 1, '', 'CoA Tirisfal: grave dirt in the frame'),
(7916278, 922365, 0, 0, 0, 1, 1, 1933.09, -150.787, 36.985, 1.1, 0, 0, 0.522687, 0.852525, 180, 100, 1, '', 'CoA Tirisfal: plate on Alastor''s own crypt'),
(7916279, 922366, 0, 0, 0, 1, 1, 1929.92, -137.859, 36.472, 5.71, 0, 0, 0.282686, -0.959213, 180, 100, 1, '', 'CoA Tirisfal: plaque on the yard crypt, facing the gate'),
(7916280, 3208962, 0, 0, 0, 1, 1, 1663.9, -364.729, 44.963, 4.98, 0, 0, 0.606454, -0.795119, 180, 100, 1, '', 'CoA Tirisfal: Edwin''s tent, opening toward him'),
(7916281, 3232091, 0, 0, 0, 1, 1, 2649.28, 1054.29, 104.521, 5.38, 0, 0, 0.436399, -0.899753, 180, 100, 1, '', 'CoA Tirisfal: Rod''s alchemy table'),
(7916282, 3239811, 0, 0, 0, 1, 1, 2648.15, 1051.85, 104.52, 5.38, 0, 0, 0.436399, -0.899753, 180, 100, 1, '', 'CoA Tirisfal: rug of Rod''s camp'),
(7916283, 3288426, 0, 0, 0, 1, 1, 2652.459, 1049.432, 105.64, 1, 0, 0, 0.479426, 0.877583, 180, 100, 1, '', 'CoA Tirisfal: root specimen at Rod''s camp'),
(7916284, 515424, 0, 0, 0, 1, 1, 2656.18, 1046.55, 105.551, 0.3, 0, 0, 0.149438, 0.988771, 180, 100, 1, '', 'CoA Tirisfal: log seat behind Rod'),
(7916285, 186658, 0, 0, 0, 1, 1, 2646.177, 1053.094, 104.375, 5.38, 0, 0, 0.436399, -0.899753, 180, 100, 1, '', 'CoA Tirisfal: Rod''s supply chest'),
(7916286, 90095, 0, 0, 0, 1, 1, 2945.158, 953.117, 121.992, 2, 0, 0, 0.841471, 0.540302, 180, 100, 1, '', 'CoA Tirisfal: cargo box at the north mill');

-- ---------------------------------------------------------------------------
-- 6. Scripts
-- ---------------------------------------------------------------------------
-- The darkhound credits its feeding; the concoction credits its test and the freed undead leave (ids
-- 100-109 on stock entries; their own rows stay).
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 1520;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (254584, 449251) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(254584, 0, 0, 1, 8, 0, 100, 0, 355193, 0, 5000, 5000, 0, 0, 33, 254959, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Mallek the Tormented - On Spellhit Rod''s Concoction - Quest Credit Unusual Subject Tested'),
(254584, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mallek the Tormented - Linked - Despawn In 2 Seconds'),
(449251, 0, 0, 1, 8, 0, 100, 0, 355164, 0, 5000, 5000, 0, 0, 33, 449251, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin''s Darkhound - On Spellhit Feed Duskhound - Quest Credit Edwin''s Darkhound Fed'),
(449251, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Edwin''s Darkhound - Linked - Play Emote Eat');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 1520 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1520, 0, 100, 101, 8, 0, 100, 0, 355193, 0, 5000, 5000, 0, 0, 33, 254956, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rattlecage Soldier - On Spellhit Rod''s Concoction - Quest Credit Concoction Tested on Skeletons'),
(1520, 0, 101, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rattlecage Soldier - Linked - Despawn In 2 Seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 1522 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1522, 0, 0, 0, 0, 0, 100, 0, 0, 0, 4000, 5000, 0, 0, 11, 13322, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Darkeye Bonecaster - In Combat CMC - Cast ''Frostbolt'''),
(1522, 0, 100, 101, 8, 0, 100, 0, 355193, 0, 5000, 5000, 0, 0, 33, 254956, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Darkeye Bonecaster - On Spellhit Rod''s Concoction - Quest Credit Concoction Tested on Skeletons'),
(1522, 0, 101, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Darkeye Bonecaster - Linked - Despawn In 2 Seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 1523 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1523, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 589, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Cracked Skull Soldier - On Aggro - Cast ''589'''),
(1523, 0, 100, 101, 8, 0, 100, 0, 355193, 0, 5000, 5000, 0, 0, 33, 254956, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Cracked Skull Soldier - On Spellhit Rod''s Concoction - Quest Credit Concoction Tested on Skeletons'),
(1523, 0, 101, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cracked Skull Soldier - Linked - Despawn In 2 Seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 1530 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1530, 0, 0, 0, 0, 0, 100, 0, 2700, 3400, 9800, 12100, 0, 0, 11, 3322, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Rotting Ancestor - In Combat - Cast ''3322'''),
(1530, 0, 100, 101, 8, 0, 100, 0, 355193, 0, 5000, 5000, 0, 0, 33, 254957, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rotting Ancestor - On Spellhit Rod''s Concoction - Quest Credit Concoction Tested on Zombies'),
(1530, 0, 101, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rotting Ancestor - Linked - Despawn In 2 Seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 1534 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1534, 0, 0, 0, 0, 0, 75, 0, 12000, 12000, 24000, 24000, 0, 0, 11, 7713, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wailing Ancestor - In Combat - Cast ''Wailing Dead'' (No Repeat)'),
(1534, 0, 100, 101, 8, 0, 100, 0, 355193, 0, 5000, 5000, 0, 0, 33, 254958, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wailing Ancestor - On Spellhit Rod''s Concoction - Quest Credit Concoction Tested on Banshees'),
(1534, 0, 101, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wailing Ancestor - Linked - Despawn In 2 Seconds');

-- ---------------------------------------------------------------------------
-- 7. Stock re-floors and holiday turkeys
-- ---------------------------------------------------------------------------
-- Decrepit Darkhound by the chapel yard, re-floor
UPDATE `creature` SET `position_x` = 1916.13, `position_y` = -111.6, `position_z` = 36.474 WHERE `guid` = 44493 AND `id` = 1547;
-- Greater Duskbat behind the chapel, re-floor
UPDATE `creature` SET `position_x` = 1915.09, `position_y` = -175.58, `position_z` = 36.408 WHERE `guid` = 44542 AND `id` = 1553;
-- Cursed Darkhound by the lab, re-floor
UPDATE `creature` SET `position_x` = 2470.7, `position_y` = -384.806, `position_z` = 75.658 WHERE `guid` = 44062 AND `id` = 1548;
-- Peacebloom below the lab, re-floor
UPDATE `gameobject` SET `position_x` = 2439.13, `position_y` = -409.188, `position_z` = 70.389 WHERE `guid` = 201557 AND `id` = 1618;
-- Copper Vein behind the lab, re-floor
UPDATE `gameobject` SET `position_x` = 2510.69, `position_y` = -376.824, `position_z` = 78.064 WHERE `guid` = 201698 AND `id` = 1731;
-- Pilgrim turkey in the chapel yard, re-floor
UPDATE `creature` SET `position_x` = 1930.87, `position_y` = -132, `position_z` = 36.429 WHERE `guid` = 242493 AND `id` = 32820;
-- Pilgrim turkey buried under the raised slope, re-floor
UPDATE `creature` SET `position_x` = 2434.33, `position_y` = -404, `position_z` = 70.721 WHERE `guid` = 243174 AND `id` = 32820;
-- Pilgrim turkey buried under the raised slope, re-floor
UPDATE `creature` SET `position_x` = 2439.32, `position_y` = -400, `position_z` = 71.008 WHERE `guid` = 243179 AND `id` = 32820;
-- Pilgrim turkey by the lab, re-floor
UPDATE `creature` SET `position_x` = 2469.93, `position_y` = -414, `position_z` = 75.108 WHERE `guid` = 243215 AND `id` = 32820;
-- Pilgrim turkey behind the chapel, re-floor
UPDATE `creature` SET `position_x` = 1917.24, `position_y` = -189, `position_z` = 35.539 WHERE `guid` = 242484 AND `id` = 32820;
-- Pilgrim turkey on the Balnir grave rise, re-floor
UPDATE `creature` SET `position_x` = 2017.34, `position_y` = -514, `position_z` = 42.08 WHERE `guid` = 242603 AND `id` = 32820;
-- Pilgrim turkey buried in the Balnir grave rise, re-floor
UPDATE `creature` SET `position_x` = 2036.43, `position_y` = -502, `position_z` = 42.757 WHERE `guid` = 242635 AND `id` = 32820;
-- Pilgrim turkey behind the Balnir barn, re-floor
UPDATE `creature` SET `position_x` = 2050.19, `position_y` = -487, `position_z` = 41.495 WHERE `guid` = 242661 AND `id` = 32820;
-- Pilgrim turkey on the Balnir grave rise, re-floor
UPDATE `creature` SET `position_x` = 2051.93, `position_y` = -507, `position_z` = 43.843 WHERE `guid` = 242664 AND `id` = 32820;
-- Pilgrim turkey on the ridge above Balnir, re-floor
UPDATE `creature` SET `position_x` = 2074.73, `position_y` = -519, `position_z` = 54.526 WHERE `guid` = 242704 AND `id` = 32820;
-- Pilgrim turkey at Agamand Mills, re-floor
UPDATE `creature` SET `position_x` = 2680.93, `position_y` = 812.035, `position_z` = 108.752 WHERE `guid` = 243405 AND `id` = 32820;
