-- CoA Brill (Tirisfal Glades): quests 1660050-1660054 with Flemer, Delcard and Alric Sading, Dark Priestess
-- Ashara, the spores of the ruined tower, the Brightwater rebels and the Rosewalk Scarlets; the other
-- Masons' Lodge members; Brill rebuild moves, camp clearance and Brill holiday rows.
-- Creature guids 9010350-9010599, gameobject guids 7916120-7916219, gossip menus 932415-932426.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stand-in displays where the CoA model is missing from the client.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(162842, 'Sporephase Guardian', NULL, 0, 8, 8, 0, 72, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 4, 0, 162842, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162843, 'Apothecary Flemer', NULL, 0, 11, 11, 0, 68, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(162844, 'Delcard Sading', 'Masons of Tirisfal', 0, 17, 17, 0, 68, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162845, 'Velyna Shadowveil', 'Masons of Tirisfal', 932416, 17, 17, 0, 68, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162846, 'Mordrek Blackbone', 'Masons of Tirisfal', 0, 17, 17, 0, 68, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162847, 'Dark Priestess Ashara', NULL, 932415, 29, 29, 0, 68, 3, 1, 1.14286, 20, 0, 2000, 2000, 2, 0, 2048, 0, 6, 0, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162853, 'Brightwater Rebel', NULL, 0, 8, 8, 0, 16, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 1, 12, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162854, 'Brightwater Rebel', NULL, 0, 8, 8, 0, 16, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 1, 12, '', 0, 0.96, 1, 1, 1, 1, 0, 162853, ''),
(162857, 'Alric Sading', NULL, 0, 8, 8, 0, 16, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 162857, 5, 20, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162859, 'Scarlet Soldier', NULL, 0, 8, 8, 0, 67, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 1, 12, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162860, 'Scarlet Mage', NULL, 0, 8, 8, 0, 67, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 0, 7, 0, 0, 1, 12, 'SmartAI', 0, 0.96, 1.5, 1, 1, 1, 0, 162859, ''),
(162861, 'Scarlet Battler', NULL, 0, 8, 8, 0, 67, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 1, 12, '', 0, 0.96, 1, 1, 1, 1, 0, 162859, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (162842, 162843, 162844, 162845, 162846, 162847, 162853, 162854, 162857, 162859, 162860, 162861);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162842, 0, 3033, 1, 1),
(162843, 0, 22113, 1, 1),
(162844, 0, 15176, 1, 1),
(162845, 0, 1592, 1, 1),
(162846, 0, 4006, 1, 1),
(162847, 0, 8782, 1, 1),
(162853, 0, 4127, 1, 1),
(162853, 1, 4128, 1, 1),
(162853, 2, 4132, 1, 1),
(162853, 3, 4131, 1, 1),
(162854, 0, 4134, 1, 1),
(162854, 1, 4133, 1, 1),
(162854, 2, 4136, 1, 1),
(162854, 3, 4135, 1, 1),
(162857, 0, 4152, 1, 1),
(162859, 0, 2516, 1, 1),
(162859, 1, 2517, 1, 1),
(162860, 0, 2512, 1, 1),
(162860, 1, 2513, 1, 1),
(162861, 0, 2514, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (162842, 162843, 162844, 162845, 162846, 162847, 162853, 162854, 162857, 162859, 162860, 162861);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(162844, 1, 1903, 0, 0),
(162853, 1, 5304, 0, 0),
(162854, 1, 14824, 0, 0),
(162857, 1, 2711, 0, 0),
(162859, 1, 1905, 0, 5259),
(162860, 1, 1907, 0, 0),
(162861, 1, 5305, 1895, 0);

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
-- Velyna's greeting and answer are the lodge's cached npc_text; her option label is inferred.
DELETE FROM `npc_text` WHERE `ID` IN (85157, 85206, 85207);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(85157, '<Her banshee gaze passes through you like a spear; flesh and spirit alike.>', '<Her banshee gaze passes through you like a spear; flesh and spirit alike.>', 0, 0, 1),
(85206, 'Welcome to the Masonic Lodge of Tirisfal, $C. <She sweeps her hand to encompass the towering Gothic building>. This marvel is the epicenter of the Forsaken’s architectural and cultural revolution. A beacon of hope… if that word still holds any meaning.', 'Welcome to the Masonic Lodge of Tirisfal, $C. <She sweeps her hand to encompass the towering Gothic building>. This marvel is the epicenter of the Forsaken’s architectural and cultural revolution. A beacon of hope… if that word still holds any meaning.', 0, 0, 1),
(85207, '<She replies with a sharp nod; the rag of her tongue swings like the pendulum of a clock.>$b$bBrill is the cradle of our vision. We began by restoring the town hall and the inn. A building here, another there… The Scourge, as you know, tore Lordaeron to shreds; most of the town was nothing but staggering ruins when we arrived. Yet where others saw tragic wreckage, we saw opportunity.$b$bThe Dark Lady seeks a divorce. We are not human, no longer. Clinging to the memory of what our lives once were is a trap, a way of delaying the pain of facing our true nature. The Brill of old was a village like any other. The Brill we are building now… is a sculpted work. A hymn to the Gothic and decrepit spirit of the Forsaken.$b$bWe want to restore dignity to our people. To do more with our freedom than crawl through the ruins of the past as if nothing had changed.$b$bBecause everything has changed.', '<She replies with a sharp nod; the rag of her tongue swings like the pendulum of a clock.>$b$bBrill is the cradle of our vision. We began by restoring the town hall and the inn. A building here, another there… The Scourge, as you know, tore Lordaeron to shreds; most of the town was nothing but staggering ruins when we arrived. Yet where others saw tragic wreckage, we saw opportunity.$b$bThe Dark Lady seeks a divorce. We are not human, no longer. Clinging to the memory of what our lives once were is a trap, a way of delaying the pain of facing our true nature. The Brill of old was a village like any other. The Brill we are building now… is a sculpted work. A hymn to the Gothic and decrepit spirit of the Forsaken.$b$bWe want to restore dignity to our people. To do more with our freedom than crawl through the ruins of the past as if nothing had changed.$b$bBecause everything has changed.', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932415, 932416, 932417);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932415, 85157),
(932416, 85206),
(932417, 85207);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932415, 932416);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932415, 0, 0, '<Stay a while and listen.>', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932416, 0, 0, 'What is your vision for Brill?', 0, 1, 1, 932417, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` = 932415 AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 932415, 0, 0, 0, 9, 0, 1660054, 0, 0, 0, 0, 0, '', 'Dark Priestess Ashara - the sermon only while Stay a While is taken');

-- ---------------------------------------------------------------------------
-- 3. World objects and loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300545, 10, 6911, 'Necrotic Spore', '', '', 1, 'SmartGameObjectAI', 0, 1660051, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `gameobject_template_addon` WHERE `entry` = 2300545;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`)
VALUES
(2300545, 0, 4);

DELETE FROM `creature_loot_template` WHERE `Entry` IN (162842, 162857);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(162842, 558954, 0, 100, 1, 1, 0, 1, 1, 'Sporephase Guardian - Clinging Necrotic Spores'),
(162857, 558955, 0, 100, 0, 1, 0, 1, 1, 'Alric Sading - Scarlet Letter');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` = 162842;
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(162842, 0, 558954);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- 1660050 follows 1660029 (Deathknell); 1660053 starts from the Scarlet Letter. The upsert leaves the POI
-- columns to the marker migration.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660050, 2, 8, 5, 85, 0, 0, 0, 0, 0, 0, 0, 4, 83, 114, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302016, 1, 2302021, 1, 2302026, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Apothecary Flemer', 'Speak with Apothecary Flemer in Brill.', 'You''ve done good work here.$b$bWhen you''re finished at Deathknell, pay a visit to Apothecary Flemer in Brill. He''s that “someone” I mentioned earlier.$b$bTell him that as soon as I''m able, I''ll send a shipment of the flesh he needs for his abomination.', '', 'Speak with Apothecary Flemer.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660051, 2, -1, 5, 85, 0, 0, 0, 0, 0, 0, 0, 5, 260, 337, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302031, 1, 2302036, 1, 2302041, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'More Than the Sum of its Parts', 'Collect Necrotic Spores from the fungus in the abandoned tower overlooking Brill. They come in two forms: clinging to creatures and encapsulated in mucous globules on the ground.', 'How to put this so a lay mind like yours might grasp it?$b$bAn abomination is more than the sum of its parts. For the Scourge, the secret ingredient was a dash of necromancy. We, of the Royal Apothecary Society, are obliged to find... more creative solutions.$b$bThe tower that looms over Brill shelters a fungal growth unlike any I''ve seen for miles. It fattened itself on death and necromancy, and its spores still pulse with that essence.$b$bBring me every spore you find, whether they''re clinging to the hides of its wardens, or trapped in mucous globules scattered across the floor.', '', 'Return to Apothecary Flemer.', 0, 0, 0, 0, 0, 0, 0, 0, 558953, 558954, 0, 0, 0, 0, 4, 6, 0, 0, 0, 0, '', '', '', ''),
(1660052, 2, 9, 5, 85, 0, 0, 0, 0, 0, 0, 0, 5, 350, 382, 0, 0, 0, 0, 0, 8, 0, 2302046, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Spotless Standing', 'Find the Forsaken Rebels entrenched along the shores of Brightwater Lake and put them down.', 'Chisels, hammers, squares, compasses... that''s what we have in abundance here, the Masons'' Lodge. Swords, bows, staves, axes? We wouldn''t even know which end to hold. You, on the other hand...$b$bEast of here, dug in along Brightwater Lake, a band of rebels has rejected the Dark Lady''s rule; simple-minded fools who think the living will greet them with open arms.$b$bMy brother is among them. If I wait for Magistrate Sevren to send his Deathstalkers, word will get out; my name stained, and with it my spotless standing as head of the lodge.$b$bPut the rebels down. Leave none alive. And above all, make certain my brother does not walk away.', '', 'Return to Delcard Sading.', 162857, 162853, 0, 0, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Alric Sading Slain', 'Brightwater Rebel Slain', '', ''),
(1660053, 2, 8, 5, 85, 0, 0, 0, 0, 0, 0, 0, 5, 240, 307, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302051, 1, 2302056, 1, 2302061, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Scarlet Correspondence', 'Find the Scarlet Crusade camp and put down their agents.', '<Correspondence exchanged between Alric Sading and a certain Belmont of the Scarlet Crusade.>$b$b<It seems the rebels had been in touch with the crusaders for some time, and were about to throw open the gates of their palisade as a token of goodwill.>$b$b<The humans'' camp is marked to the north. A brief visit is in order... to remind them who holds lordship over these lands.>', '', 'Return to Delcard Sading.', 162859, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Scarlet Zealot Slain', '', '', ''),
(1660054, 2, 8, 5, 85, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stay a While', 'Take a moment from the noise and haste and stay a while to listen to Dark Priestess Ashara.', '<Looks like you''re one of the rare curious souls ready to hear a banshee''s sermon.>$b$b<Perhaps she has something worth sharing.>', '', 'Say goodbye to Ashara.', 162921, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Listen to Dark Priestess Ashara', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660050, 1660051, 1660052, 1660053, 1660054);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660050, 0, 0, 1660029, 0, 0),
(1660051, 0, 0, 1660050, 0, 0),
(1660052, 0, 0, 0, 0, 0),
(1660053, 0, 0, 0, 0, 0),
(1660054, 0, 0, 0, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660050, 1660051, 1660052, 1660053, 1660054);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660050, '<The Forsaken hums a sinister tune in a voice like a cracked instrument, his focus pinned to the experiment in his hands.>$B$BAnd you are…?$B$BAh.$B$BVery well. I can wait, though never with idle hands. The flesh Eric promised me isn''t the only ingredient needed to bring an abomination to life.'),
(1660051, '<The Forsaken inspects the samples with a clinician''s eye; once they meet his standard, his gaze narrows, coldly patient, and a thin, condescending smile appears.>$B$BGood work, much to my surprise.$B$BThe spores radiate necrotic energy. A long curing awaits before their potential can be bent to the service of science…$B$BBut with this, and a few other pieces, you''ll see soon enough: the dead flesh of my construct, stitched and patchworked by these expert hands, will spasm into life!'),
(1660052, 'Is it done? Have you cleared out that traitorous rabble?$B$B<A flicker of a smile crosses Delcard Sading''s face as you confirm his brother''s death.>$B$BGood. Now no one will ever know the shame Alric nearly brought upon our family name.$B$BHe never accepted what he was—Forsaken. But when a problem has no solution, it ceases to be a problem and becomes something else: a reality to be faced.'),
(1660053, 'My brother and the rebels were in contact with the Scarlet Crusade… and they were going to invite them in?$B$B<Delcard lets out a hoarse cackle that knocks a tooth loose; it clacks off the wall.>$B$BWell. Seems I dragged you into this for nothing. They were going to die either way; by your hand, or at the crusaders'' mercy.$B$BHow naive. They were never a threat, after all.'),
(1660054, 'Curiosity is not one of the Three Virtues we keep in the Cult of the Forgotten Shadow.$B$BBut it is their antechamber.');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660050, 1660051, 1660052, 1660053, 1660054);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660050, ''),
(1660051, 'Did you bring the spores?'),
(1660052, 'Have you… you know… taken care of that matter?'),
(1660053, '<Delcard shakes his head slowly, as if to himself.>'),
(1660054, '');

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660050, 1660051, 1660052, 1660053, 1660054);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(161742, 1660050),
(162843, 1660051),
(162844, 1660052),
(162847, 1660054);

DELETE FROM `creature_questender` WHERE `quest` IN (1660050, 1660051, 1660052, 1660053, 1660054);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(162843, 1660050),
(162843, 1660051),
(162844, 1660052),
(162844, 1660053),
(162847, 1660054);

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9010350, 9010351, 9010352, 9010353, 9010354, 9010355, 9010360, 9010361, 9010362, 9010363, 9010364, 9010365, 9010366, 9010367, 9010368, 9010369, 9010370, 9010371, 9010372, 9010373, 9010374, 9010375, 9010376, 9010377, 9010380, 9010381, 9010382, 9010383, 9010384, 9010385, 9010386, 9010387, 9010388, 9010389, 9010390, 9010391, 9010392, 9010393, 9010394, 9010395, 9010396, 9010397, 9010398, 9010399, 9010400, 9010401, 9010402, 9010403, 9010404, 9010410, 9010411, 9010412, 9010413, 9010414, 9010415, 9010416, 9010417, 9010418, 9010419, 9010420, 9010421, 9010422, 9010423, 9010424, 9010425, 9010426, 9010427) OR `guid` BETWEEN 9010350 AND 9010599;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9010350, 162843, 0, 0, 0, 1, 1, 0, 2258.22, 407.96, 35.525, 2.48, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: ST8722, the 1660050/1660051 turn-in point in the ruined-building lab, working at the alchemy table'),
(9010351, 162844, 0, 0, 0, 1, 1, 1, 2247.63, 326.61, 35.188, 2.44, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: ST8723, the 1660052/1660053 turn-in point in the Masons'' Lodge, facing the door'),
(9010352, 162847, 0, 0, 0, 1, 1, 0, 2192.81, 333.04, 34.673, 4.46, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point behind the lectern of the Forsaken chapel, facing the pews'),
(9010353, 162857, 0, 0, 0, 1, 1, 1, 2283.18, 1.8, 35.838, 5.79, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: ST8724, the 1660052 objective point on the prison HQ upper floor, by his table'),
(9010354, 162845, 0, 0, 0, 1, 1, 0, 2252, 330.5, 35.188, 3.65, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Masons'' Lodge hall by the west bookshelf, greeting visitors from the door'),
(9010355, 162846, 0, 0, 0, 1, 1, 0, 2255, 322.5, 35.188, 2.63, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Masons'' Lodge hall by the east bookshelves, facing Delcard'),
(9010380, 162854, 0, 0, 0, 1, 1, 1, 2307.6, -3.55, 22.891, 1.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the dock head below the HQ'),
(9010381, 162853, 0, 0, 0, 1, 1, 1, 2300.37, -52.79, 22.891, 1.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the south dock under the tent pavilion'),
(9010382, 162853, 0, 0, 0, 1, 1, 1, 2295, -30, 22.891, 1.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: dock walk by the excavation tents'),
(9010383, 162854, 0, 0, 0, 1, 1, 1, 2306, -38, 24.604, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: raised dock end, watching the lake'),
(9010384, 162853, 0, 0, 0, 1, 1, 1, 2319.95, 5.49, 22.891, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the landing by the longhouse'),
(9010385, 162854, 0, 0, 0, 1, 1, 1, 2330.2, 0.97, 22.891, 3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point under the dock pavilion by the chair'),
(9010386, 162854, 0, 0, 0, 1, 1, 1, 2272.05, 3.23, 27.683, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point in the HQ north room'),
(9010387, 162853, 0, 0, 0, 1, 1, 1, 2285.5, -6, 25.02, 3.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: HQ hall beside the chairs'),
(9010388, 162854, 0, 0, 0, 1, 1, 1, 2276, -20, 24.672, 1.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: HQ south hall between the benches and the table'),
(9010389, 162853, 0, 0, 0, 1, 1, 1, 2266.5, -7, 26.599, 0.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: HQ west room (Questie point is on the cargo boxes)'),
(9010390, 162853, 0, 0, 0, 1, 1, 1, 2270, -5, 35.838, 0.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: HQ upper floor outside Alric''s quarters'),
(9010391, 162854, 0, 0, 0, 1, 1, 1, 2278, -8, 35.838, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: HQ upper floor landing'),
(9010392, 162854, 0, 0, 0, 1, 1, 1, 2325.38, 28.08, 24.374, 3.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the longhouse floor'),
(9010393, 162853, 0, 0, 0, 1, 1, 1, 2315, 20, 24.436, 0.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: longhouse, at the table'),
(9010394, 162854, 0, 0, 0, 1, 1, 1, 2310, 10, 24.695, 4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: longhouse south end'),
(9010395, 162853, 0, 0, 0, 1, 1, 1, 2302, 16, 24.656, 2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: longhouse beside the bunks'),
(9010396, 162854, 0, 0, 0, 1, 1, 1, 2344, 21, 24.075, 3.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: guard tower base'),
(9010397, 162853, 0, 0, 0, 1, 1, 1, 2335, 30, 24.953, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: north of the longhouse, watching the shore road'),
(9010398, 162854, 0, 0, 0, 1, 1, 1, 2296, 10, 23.51, 1.6, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill: yard between the HQ and the longhouse'),
(9010399, 162853, 0, 0, 0, 1, 1, 1, 2290, 20, 23.714, 1.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: north gate of the palisade, facing out'),
(9010400, 162854, 0, 0, 0, 1, 1, 1, 2258, -20, 24.304, 1.9, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill: west approach below the HQ'),
(9010401, 162853, 0, 0, 0, 1, 1, 1, 2260, 5, 26.484, 1.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: west side of the HQ, facing the Brill road'),
(9010402, 162854, 0, 0, 0, 1, 1, 1, 2285, -32, 22.891, 4.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: south dock by the cargo boxes'),
(9010403, 162853, 0, 0, 0, 1, 1, 1, 2299, -42, 22.891, 4.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: south dock walk, outside the tent'),
(9010404, 162854, 0, 0, 0, 1, 1, 1, 2266, -26, 24.126, 2.3, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill: south-west corner of the palisade'),
(9010410, 162859, 0, 0, 0, 1, 1, 1, 2450.42, 153.23, 27.947, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the garden terrace'),
(9010411, 162859, 0, 0, 0, 1, 1, 1, 2465.48, 153.23, 29.154, 3.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the north lawn by the torches'),
(9010412, 162859, 0, 0, 0, 1, 1, 1, 2429.33, 177.62, 29.481, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point between the camp tent and the arches'),
(9010413, 162859, 0, 0, 0, 1, 1, 1, 2419.68, 203.38, 29.33, 3.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point at the west gate under the banner'),
(9010414, 162859, 0, 0, 0, 1, 1, 1, 2407.63, 171.3, 29.477, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point under the south arch'),
(9010415, 162859, 0, 0, 0, 1, 1, 1, 2445, 190, 34.166, 4, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill: west terrace by the statue and the fountain'),
(9010416, 162860, 0, 0, 0, 1, 1, 1, 2427.22, 118.44, 22.326, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point in the lower garden by the arch posts'),
(9010417, 162860, 0, 0, 0, 1, 1, 1, 2436.26, 163.62, 29.69, 0.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point under the command pavilion, at the table'),
(9010418, 162860, 0, 0, 0, 1, 1, 1, 2479.34, 154.13, 29.068, 3.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point by the north tent'),
(9010419, 162860, 0, 0, 0, 1, 1, 1, 2413.96, 202.02, 29.333, 5.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point at the west gate, with the soldier'),
(9010420, 162860, 0, 0, 0, 1, 1, 1, 2397.09, 159.55, 29.554, 0.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the south lawn'),
(9010421, 162860, 0, 0, 0, 1, 1, 1, 2472, 140, 30.299, 3.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: north-east lawn toward the lake'),
(9010422, 162861, 0, 0, 0, 1, 1, 1, 2421.49, 96.3, 21.142, 1.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the lake shore by the tombstone'),
(9010423, 162861, 0, 0, 0, 1, 1, 1, 2432.34, 121.15, 22.498, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the lower garden path'),
(9010424, 162861, 0, 0, 0, 1, 1, 1, 2490.19, 164.07, 29.06, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point on the north edge by the banner'),
(9010425, 162861, 0, 0, 0, 1, 1, 1, 2459, 168, 29.369, 3.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: by the brazier and the supply crates (Questie point is in a crate)'),
(9010426, 162861, 0, 0, 0, 1, 1, 1, 2418.18, 172.65, 29.473, 0.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: Questie point by the south tent'),
(9010427, 162861, 0, 0, 0, 1, 1, 1, 2412, 188, 29.435, 1.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill: archery range by the targets and the bench'),
(9010360, 162842, 0, 0, 0, 1, 1, 0, 2188.89, 483.49, 59.774, 3.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point on the north slope below the ruined tower'),
(9010361, 162842, 0, 0, 0, 1, 1, 0, 2157.25, 470.39, 66.455, 5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point on the knoll top west of the tower'),
(9010362, 162842, 0, 0, 0, 1, 1, 0, 2147.01, 498.85, 55.106, 4.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point on the west slope'),
(9010363, 162842, 0, 0, 0, 1, 1, 0, 2097.6, 414.82, 59.274, 0.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point in the far south-west of the field'),
(9010364, 162842, 0, 0, 0, 1, 1, 0, 2167.5, 404.43, 56.195, 1.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point on the south slope'),
(9010365, 162842, 0, 0, 0, 1, 1, 0, 2192, 415, 61.848, 2.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: south-east slope beside the tower (Questie point is under its floor)'),
(9010366, 162842, 0, 0, 0, 1, 1, 0, 2176, 452, 67.629, 0.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: knoll top by the mushrooms (Questie point is on the tower floor)'),
(9010367, 162842, 0, 0, 0, 1, 1, 0, 2182.56, 481.69, 61.404, 3.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point on the north-west slope'),
(9010368, 162842, 0, 0, 0, 1, 1, 0, 2133.75, 486.66, 60.941, 5.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point in the west field'),
(9010369, 162842, 0, 0, 0, 1, 1, 0, 2120.19, 443.73, 62.86, 1.1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point in the west field'),
(9010370, 162842, 0, 0, 0, 1, 1, 0, 2128.93, 438.31, 64.093, 2.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point in the west field'),
(9010371, 162842, 0, 0, 0, 1, 1, 0, 2134.96, 419.34, 63.751, 0.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point in the south-west field'),
(9010372, 162842, 0, 0, 0, 1, 1, 0, 2141.28, 397.65, 56.37, 1.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point in the south field'),
(9010373, 162842, 0, 0, 0, 1, 1, 0, 2171.11, 428.82, 68.146, 0.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point on the knoll top'),
(9010374, 162842, 0, 0, 0, 1, 1, 0, 2151.23, 437.86, 66.739, 4.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: Questie point on the west edge of the knoll top'),
(9010375, 162842, 0, 0, 0, 1, 1, 0, 2104, 440, 59.562, 2.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: west field edge (replaces the Questie point on the tower floor)'),
(9010376, 162842, 0, 0, 0, 1, 1, 0, 2168, 466, 68.904, 5.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: knoll top among the puffballs (replaces the point under the tower)'),
(9010377, 162842, 0, 0, 0, 1, 1, 0, 2112, 470, 64.041, 4.8, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Brill plague field: north part of the west field');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9010350 AND 9010599;

DELETE FROM `gameobject` WHERE `guid` IN (7916120, 7916121, 7916122, 7916123, 7916124, 7916125, 7916126, 7916127, 7916128, 7916129, 7916130, 7916131, 7916132, 7916133, 7916134) OR `guid` BETWEEN 7916120 AND 7916219;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7916120, 2300545, 0, 0, 0, 1, 1, 2157.25, 435.15, 67.163, 0.5, 0, 0, 0.247404, 0.968912, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point on the knoll top'),
(7916121, 2300545, 0, 0, 0, 1, 1, 2157.55, 426.11, 68.004, 2.1, 0, 0, 0.867423, 0.497571, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point beside the plague mushroom'),
(7916122, 2300545, 0, 0, 0, 1, 1, 2164.78, 431.99, 67.964, 3.7, 0, 0, 0.961275, -0.27559, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point by the fallen tree'),
(7916123, 2300545, 0, 0, 0, 1, 1, 2170.81, 439.67, 67.269, 5.2, 0, 0, 0.515501, -0.856889, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point on the knoll top'),
(7916124, 2300545, 0, 0, 0, 1, 1, 2163, 442, 66.544, 1.4, 0, 0, 0.644218, 0.764842, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; open knoll top between the fallen tree and the mushrooms'),
(7916125, 2300545, 0, 0, 0, 1, 1, 2179.55, 421.14, 63.531, 4, 0, 0, 0.909297, -0.416147, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point on the south-east slope'),
(7916126, 2300545, 0, 0, 0, 1, 1, 2154, 452.5, 67.705, 0.9, 0, 0, 0.434966, 0.900447, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; beside the west mushroom (Questie point is inside it)'),
(7916127, 2300545, 0, 0, 0, 1, 1, 2164.48, 456.38, 68.825, 2.8, 0, 0, 0.98545, 0.169967, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point by the mushroom ring'),
(7916128, 2300545, 0, 0, 0, 1, 1, 2173, 466.5, 69.085, 4.6, 0, 0, 0.745705, -0.666276, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; among the puffballs (Questie point is on a mushroom cap)'),
(7916129, 2300545, 0, 0, 0, 1, 1, 2187.08, 470.39, 64.322, 6, 0, 0, 0.14112, -0.989992, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point below the tower wall'),
(7916130, 2300545, 0, 0, 0, 1, 1, 2196, 474, 63.045, 1.7, 0, 0, 0.75128, 0.659983, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; north foot of the tower (Questie point is against a mushroom)'),
(7916131, 2300545, 0, 0, 0, 1, 1, 2197.33, 427.02, 63.536, 3.3, 0, 0, 0.996865, -0.079121, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point in the hollow under the tower floor'),
(7916132, 2300545, 0, 0, 0, 1, 1, 2209.08, 428.37, 67.769, 5, 0, 0, 0.598472, -0.801144, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point on the tower floor'),
(7916133, 2300545, 0, 0, 0, 1, 1, 2219.92, 452.32, 67.769, 0.2, 0, 0, 0.099833, 0.995004, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; Questie point on the tower floor'),
(7916134, 2300545, 0, 0, 0, 1, 1, 2193, 446, 67.77, 2.4, 0, 0, 0.932039, 0.362358, 60, 100, 1, '', 'CoA Brill ruined tower: Necrotic Spore; middle of the tower floor');

-- ---------------------------------------------------------------------------
-- 6. Scripts
-- ---------------------------------------------------------------------------
-- Ashara credits the shared listen marker 162921; a spore gives its item only while 1660051 is taken.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (162847, 162860) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162847, 0, 0, 1, 62, 0, 100, 0, 932415, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara - On Gossip Option 0 Selected - Close Gossip'),
(162847, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara - Linked - Quest Credit Listen to Dark Priestess Ashara'),
(162860, 0, 0, 0, 0, 0, 100, 0, 0, 0, 3500, 5000, 0, 0, 11, 20793, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Scarlet Mage - In Combat - Cast ''Fireball''');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300545 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300545, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 56, 558953, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Necrotic Spore - On Use - Give the user Encapsulated Necrotic Spores'),
(2300545, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Necrotic Spore - Linked - Despawn until it respawns');

DELETE FROM `conditions` WHERE `SourceEntry` = 2300545 AND `SourceTypeOrReferenceId` = 22 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 2300545, 1, 0, 9, 0, 1660051, 0, 0, 0, 0, 0, '', 'Necrotic Spore - give the spores only while More Than the Sum of its Parts is taken');

-- ---------------------------------------------------------------------------
-- 7. Brill rebuild: stable, lab, square, outskirts, blacksmith and farm
-- ---------------------------------------------------------------------------
UPDATE `creature` SET `position_x` = 2291.23, `position_y` = 358.639, `position_z` = 34.273, `orientation` = 2.916 WHERE `guid` = 33711 AND `id` = 4773;
UPDATE `creature` SET `position_x` = 2300.92, `position_y` = 352.76, `position_z` = 34.221, `orientation` = 3.073 WHERE `guid` = 28472 AND `id` = 4731;
UPDATE `creature` SET `position_x` = 2283.65, `position_y` = 351.05, `position_z` = 34.113, `orientation` = 2.881 WHERE `guid` = 28478 AND `id` = 10055;
UPDATE `creature` SET `position_x` = 2296.6, `position_y` = 348, `position_z` = 34.234, `orientation` = 2.969 WHERE `guid` = 31906 AND `id` = 12342;
UPDATE `creature` SET `position_x` = 2304.71, `position_y` = 356.87, `position_z` = 34.173, `orientation` = 2.951 WHERE `guid` = 31907 AND `id` = 12341;
UPDATE `creature` SET `position_x` = 2297.88, `position_y` = 358.04, `position_z` = 34.199, `orientation` = 3.038 WHERE `guid` = 31909 AND `id` = 12343;
UPDATE `creature` SET `position_x` = 2303.53, `position_y` = 347.75, `position_z` = 34.269, `orientation` = 2.986 WHERE `guid` = 31910 AND `id` = 11156;
UPDATE `creature` SET `position_x` = 2304, `position_y` = 351, `position_z` = 34.225, `orientation` = 2.986 WHERE `guid` = 31911 AND `id` = 14558;
UPDATE `creature` SET `position_x` = 2304.59, `position_y` = 353.83, `position_z` = 34.244, `orientation` = 2.993 WHERE `guid` = 150154 AND `id` = 35169;
UPDATE `creature` SET `position_x` = 2299, `position_y` = 362.5, `position_z` = 34.126, `orientation` = 3.919 WHERE `guid` = 150155 AND `id` = 34238;
UPDATE `creature` SET `position_x` = 2245.69, `position_y` = 395.793, `position_z` = 35.518, `orientation` = 4.869 WHERE `guid` = 35231 AND `id` = 1518;
UPDATE `creature` SET `position_x` = 2258, `position_y` = 402, `position_z` = 35.522, `orientation` = 2.174 WHERE `guid` = 45191 AND `id` = 4075;
UPDATE `creature` SET `position_x` = 2257.38, `position_y` = 396.451, `position_z` = 35.516 WHERE `guid` = 44470 AND `id` = 4075;
UPDATE `creature` SET `position_x` = 2279.45, `position_y` = 298.072, `position_z` = 34.635, `orientation` = 1.937 WHERE `guid` = 29797 AND `id` = 1515;
UPDATE `creature` SET `position_x` = 2269.51, `position_y` = 279.453, `position_z` = 34.654, `orientation` = 2.705 WHERE `guid` = 29798 AND `id` = 1652;
UPDATE `creature` SET `position_x` = 2272.98, `position_y` = 290.231, `position_z` = 34.55 WHERE `guid` = 34112 AND `id` = 1746;
UPDATE `creature` SET `position_x` = 2255.06, `position_y` = 307.46, `position_z` = 34.324 WHERE `guid` = 31918 AND `id` = 2311;
UPDATE `creature` SET `position_x` = 2266.5, `position_y` = 327.3, `position_z` = 34.984, `orientation` = 6.248 WHERE `guid` = 28470 AND `id` = 2114;
UPDATE `creature` SET `position_x` = 2187.53, `position_y` = 274.695, `position_z` = 35.306 WHERE `guid` = 45153 AND `id` = 4075;
UPDATE `creature` SET `position_x` = 2216, `position_y` = 268, `position_z` = 35.066 WHERE `guid` = 45048 AND `id` = 4075;
UPDATE `creature` SET `position_x` = 2162.23, `position_y` = 273.459, `position_z` = 37.605 WHERE `guid` = 44912 AND `id` = 1547;
UPDATE `creature` SET `position_x` = 2258, `position_y` = 430, `position_z` = 36.719, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 45114 AND `id` = 1547;
UPDATE `creature` SET `position_x` = 2236.85, `position_y` = 312.21, `position_z` = 36.7 WHERE `guid` = 38288 AND `id` = 2135;
UPDATE `creature` SET `position_x` = 2227.93, `position_y` = 316.05, `position_z` = 36.722 WHERE `guid` = 38290 AND `id` = 2136;
UPDATE `creature` SET `position_x` = 2265.99, `position_y` = 349.78, `position_z` = 36.105, `orientation` = 4.765 WHERE `guid` = 33708 AND `id` = 2132;
UPDATE `gameobject` SET `position_x` = 2229.8, `position_y` = 313.66, `position_z` = 34.91 WHERE `guid` = 44871 AND `id` = 38491;
UPDATE `gameobject` SET `position_x` = 2229.7, `position_y` = 307.18, `position_z` = 36.72 WHERE `guid` = 44872 AND `id` = 38493;
UPDATE `gameobject` SET `position_x` = 2224.12, `position_y` = 319.44, `position_z` = 36.71 WHERE `guid` = 44873 AND `id` = 38494;
UPDATE `gameobject` SET `position_x` = 2229.92, `position_y` = 320.28, `position_z` = 36.72 WHERE `guid` = 44874 AND `id` = 38495;
UPDATE `gameobject` SET `position_x` = 2236.31, `position_y` = 314.76, `position_z` = 36.72 WHERE `guid` = 44875 AND `id` = 38492;
UPDATE `gameobject` SET `position_x` = 2257.45, `position_y` = 350.03, `position_z` = 36.04 WHERE `guid` = 44840 AND `id` = 3798;
UPDATE `gameobject` SET `position_x` = 2257.16, `position_y` = 349.19, `position_z` = 36.04 WHERE `guid` = 44841 AND `id` = 3797;
UPDATE `creature` SET `position_x` = 2451.51, `position_y` = 128.414, `position_z` = 27.689, `wander_distance` = 3, `MovementType` = 1 WHERE `guid` = 38368 AND `id` = 1553;
UPDATE `creature` SET `position_x` = 2393.22, `position_y` = 190.59, `position_z` = 32.381, `wander_distance` = 3, `MovementType` = 1 WHERE `guid` = 44576 AND `id` = 1547;
UPDATE `creature` SET `position_x` = 2321.37, `position_y` = 47.051, `position_z` = 26.741, `wander_distance` = 3, `MovementType` = 1 WHERE `guid` = 38371 AND `id` = 1547;
UPDATE `gameobject` SET `position_x` = 2314.25, `position_y` = 49.273, `position_z` = 28.067 WHERE `guid` = 201537 AND `id` = 1618;

-- Guard directions to the stable master and to fishing follow Morganus and Clyde Kellen.
UPDATE `points_of_interest` SET `PositionX` = 2283.65, `PositionY` = 351.05 WHERE `ID` = 432;
UPDATE `points_of_interest` SET `PositionX` = 2245, `PositionY` = -50 WHERE `ID` = 441;

-- ---------------------------------------------------------------------------
-- 8. Camp clearance: Queen Lianne's Rosewalk and Brightwater Docks
-- ---------------------------------------------------------------------------
UPDATE `creature` SET `position_x` = 2525, `position_y` = 150, `position_z` = 30.377, `orientation` = 3.4, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 44589 AND `id` = 1547;
UPDATE `creature` SET `position_x` = 2365, `position_y` = 172, `position_z` = 35.031, `orientation` = 4.7, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 37916 AND `id` = 1553;
UPDATE `creature` SET `position_x` = 2475, `position_y` = 225, `position_z` = 44.672, `orientation` = 0.9, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 41727 AND `id` = 1553;
UPDATE `creature` SET `position_x` = 2375, `position_y` = 228, `position_z` = 34.489, `orientation` = 4.1, `wander_distance` = 10, `MovementType` = 1 WHERE `guid` = 44495 AND `id` = 1553;
UPDATE `creature` SET `position_x` = 2500, `position_y` = 212, `position_z` = 37.864, `orientation` = 5.7, `wander_distance` = 10, `MovementType` = 1 WHERE `guid` = 45079 AND `id` = 1547;
UPDATE `gameobject` SET `position_x` = 2518, `position_y` = 190, `position_z` = 36.491, `orientation` = 4.6, `rotation2` = 0.745705, `rotation3` = -0.666276 WHERE `guid` = 201540 AND `id` = 1618;
UPDATE `creature` SET `position_x` = 2380, `position_y` = 252, `position_z` = 28.329, `orientation` = 4.9 WHERE `guid` = 243157 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2530, `position_y` = 175, `position_z` = 34.941, `orientation` = 3.3 WHERE `guid` = 243163 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2360, `position_y` = 140, `position_z` = 34.467, `orientation` = 2.7 WHERE `guid` = 243165 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2535, `position_y` = 125, `position_z` = 28.897, `orientation` = 2.8 WHERE `guid` = 243219 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2542, `position_y` = 152, `position_z` = 30.008, `orientation` = 2.9 WHERE `guid` = 243232 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2215, `position_y` = -20, `position_z` = 29.206, `orientation` = 0.1, `wander_distance` = 10, `MovementType` = 1 WHERE `guid` = 41988 AND `id` = 1547;
UPDATE `creature` SET `position_x` = 2225, `position_y` = 10, `position_z` = 31.844, `orientation` = 4.8, `wander_distance` = 10, `MovementType` = 1 WHERE `guid` = 37914 AND `id` = 1553;
UPDATE `creature` SET `position_x` = 2230, `position_y` = -45, `position_z` = 25.874, `orientation` = 0.7 WHERE `guid` = 242951 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2240, `position_y` = 40, `position_z` = 27.509, `orientation` = 3.7 WHERE `guid` = 242986 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2220, `position_y` = 25, `position_z` = 29.928, `orientation` = 5.3 WHERE `guid` = 243021 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2245, `position_y` = -50, `position_z` = 22.582, `orientation` = 4.712 WHERE `guid` = 33707 AND `id` = 5690;

-- ---------------------------------------------------------------------------
-- 9. Brill holiday rows
-- ---------------------------------------------------------------------------
-- Rows on moved buildings follow them; stranded, buried and floating rows go to the CoA ground.
-- Moves with the blacksmith.
UPDATE `gameobject` SET `position_x` = 2243.279, `position_y` = 308.892, `position_z` = 35.189, `orientation` = 1.8849 WHERE `guid` = 36327 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = 2237.949, `position_y` = 323.319, `position_z` = 47.532, `orientation` = 1.2566 WHERE `guid` = 36330 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = 2221.639, `position_y` = 303.936, `position_z` = 47.587, `orientation` = 1.309 WHERE `guid` = 36332 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = 2236.929, `position_y` = 300.87, `position_z` = 35.189, `orientation` = 1.1345 WHERE `guid` = 36762 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = 2218.729, `position_y` = 309.245, `position_z` = 41.2, `orientation` = 4.852 WHERE `guid` = 39155 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2240.889, `position_y` = 318.083, `position_z` = 41.169, `orientation` = 1.7453 WHERE `guid` = 39156 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2240.769, `position_y` = 304.389, `position_z` = 44, `orientation` = 0.7854 WHERE `guid` = 39157 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2227.339, `position_y` = 301.962, `position_z` = 41.151, `orientation` = 0 WHERE `guid` = 39158 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2232.269, `position_y` = 325.333, `position_z` = 41.255, `orientation` = 1.6057 WHERE `guid` = 39159 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2215.749, `position_y` = 314.102, `position_z` = 42.725, `orientation` = 3.5081 WHERE `guid` = 39561 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2244.659, `position_y` = 312.601, `position_z` = 42.705, `orientation` = 0.2618 WHERE `guid` = 39562 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2220.209, `position_y` = 321.72, `position_z` = 47.333, `orientation` = 2.5482 WHERE `guid` = 39564 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2233.419, `position_y` = 299.213, `position_z` = 42.691, `orientation` = 4.8869 WHERE `guid` = 39565 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2239.919, `position_y` = 305.104, `position_z` = 45.265, `orientation` = 5.6549 WHERE `guid` = 41383 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = 2218.019, `position_y` = 312.805, `position_z` = 42.384, `orientation` = 3.9444 WHERE `guid` = 41860 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2231.079, `position_y` = 301.75, `position_z` = 42.248, `orientation` = 0.8901 WHERE `guid` = 41861 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2241.719, `position_y` = 314.63, `position_z` = 42.218, `orientation` = 0.8727 WHERE `guid` = 41862 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2220.839, `position_y` = 321.208, `position_z` = 45.428, `orientation` = 2.5482 WHERE `guid` = 41863 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2219.269, `position_y` = 317.205, `position_z` = 40.378, `orientation` = 2.4784 WHERE `guid` = 78984 AND `id` = 181392;
UPDATE `gameobject` SET `position_x` = 2238.489, `position_y` = 306.392, `position_z` = 40.424, `orientation` = 5.6374 WHERE `guid` = 78985 AND `id` = 181392;
UPDATE `gameobject` SET `position_x` = 2233.869, `position_y` = 324.855, `position_z` = 36.523, `orientation` = 3.2996 WHERE `guid` = 151973 AND `id` = 113770;
UPDATE `gameobject` SET `position_x` = 2212.729, `position_y` = 331.797, `position_z` = 35.196, `orientation` = 1.5733 WHERE `guid` = 151976 AND `id` = 113768;
UPDATE `gameobject` SET `position_x` = 2219.959, `position_y` = 310.688, `position_z` = 36.728, `orientation` = 0.2107 WHERE `guid` = 151978 AND `id` = 113770;
UPDATE `gameobject` SET `position_x` = 2241.389, `position_y` = 303.904, `position_z` = 42.851, `orientation` = 5.585 WHERE `guid` = 21948 AND `id` = 181390;
UPDATE `creature` SET `position_x` = 2235.439, `position_y` = 302.029, `position_z` = 37.798, `orientation` = 2.6132 WHERE `guid` = 240110 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2236.839, `position_y` = 301.608, `position_z` = 45.289, `orientation` = 3.1473 WHERE `guid` = 240115 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2239.359, `position_y` = 307.138, `position_z` = 41.035, `orientation` = 2.3422 WHERE `guid` = 240116 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2242.419, `position_y` = 310.209, `position_z` = 42.544, `orientation` = 2.3422 WHERE `guid` = 240117 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2242.729, `position_y` = 310.58, `position_z` = 36.717, `orientation` = 2.2637 WHERE `guid` = 240118 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2237.019, `position_y` = 304.293, `position_z` = 40.964, `orientation` = 1.388 WHERE `guid` = 240119 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2233.399, `position_y` = 299.671, `position_z` = 38.161, `orientation` = 1.5882 WHERE `guid` = 240120 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2224.919, `position_y` = 304.186, `position_z` = 46.415, `orientation` = 3.002 WHERE `guid` = 240127 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2241.079, `position_y` = 308.935, `position_z` = 46.117, `orientation` = 2.7585 WHERE `guid` = 240128 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2243.899, `position_y` = 311.729, `position_z` = 45.447, `orientation` = 2.2283 WHERE `guid` = 240129 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2240.839, `position_y` = 306.576, `position_z` = 47.487, `orientation` = 1.4783 WHERE `guid` = 240130 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2235.789, `position_y` = 302.124, `position_z` = 45.502, `orientation` = 1.4783 WHERE `guid` = 240131 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2233.339, `position_y` = 300.002, `position_z` = 44.279, `orientation` = 1.4783 WHERE `guid` = 240132 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2228.819, `position_y` = 302.77, `position_z` = 43.964, `orientation` = 1.4783 WHERE `guid` = 240155 AND `id` = 23686;
UPDATE `creature` SET `position_x` = 2226.609, `position_y` = 317.561, `position_z` = 36.719, `orientation` = 5.185 WHERE `guid` = 242915 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2235.659, `position_y` = 312.108, `position_z` = 36.721, `orientation` = 3.412 WHERE `guid` = 242926 AND `id` = 32820;

-- Moves with the stable to the new Forsaken_Stable.
UPDATE `gameobject` SET `position_x` = 2295.093, `position_y` = 361.248, `position_z` = 35.802, `orientation` = 3.1606, `rotation2` = 0.999955, `rotation3` = -0.009504 WHERE `guid` = 21949 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = 2292.95, `position_y` = 345.785, `position_z` = 35.906, `orientation` = 3.0035, `rotation2` = 0.997617, `rotation3` = 0.068991 WHERE `guid` = 21950 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = 2286.179, `position_y` = 348.745, `position_z` = 34.007, `orientation` = 0.2285, `rotation2` = 0.114002, `rotation3` = 0.993481 WHERE `guid` = 36323 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = 2293.891, `position_y` = 353.616, `position_z` = 44.433, `orientation` = 5.0107, `rotation2` = 0.594177, `rotation3` = -0.804334 WHERE `guid` = 36760 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = 2287.917, `position_y` = 360.541, `position_z` = 34.168, `orientation` = 3.4573, `rotation2` = 0.987567, `rotation3` = -0.157199 WHERE `guid` = 37187 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = 2292.164, `position_y` = 343.68, `position_z` = 42.665, `orientation` = 5.2725, `rotation2` = 0.484107, `rotation3` = -0.875009 WHERE `guid` = 39154 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2294.976, `position_y` = 363.709, `position_z` = 42.633, `orientation` = 3.7889, `rotation2` = 0.94808, `rotation3` = -0.318033 WHERE `guid` = 39160 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2305.007, `position_y` = 342.018, `position_z` = 39.259, `orientation` = 4.6441, `rotation2` = 0.730834, `rotation3` = -0.682556 WHERE `guid` = 39556 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2293.733, `position_y` = 343.557, `position_z` = 39.233, `orientation` = 4.9059, `rotation2` = 0.63549, `rotation3` = -0.772109 WHERE `guid` = 39557 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2307.804, `position_y` = 361.975, `position_z` = 39.236, `orientation` = 1.6596, `rotation2` = 0.737796, `rotation3` = 0.675023 WHERE `guid` = 39559 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2296.61, `position_y` = 363.515, `position_z` = 39.234, `orientation` = 1.5724, `rotation2` = 0.707674, `rotation3` = 0.70654 WHERE `guid` = 39563 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2286.326, `position_y` = 352.878, `position_z` = 38.261, `orientation` = 3.0035, `rotation2` = 0.997617, `rotation3` = 0.068991 WHERE `guid` = 41390 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = 2286.973, `position_y` = 356.453, `position_z` = 38.334, `orientation` = 6.1626, `rotation2` = 0.060256, `rotation3` = -0.998183 WHERE `guid` = 41870 AND `id` = 178551;

-- Moves with the farm.
UPDATE `gameobject` SET `position_x` = 2260.703, `position_y` = 350.892, `position_z` = 36.105, `orientation` = 1.0825, `rotation2` = 0.515208, `rotation3` = 0.857065 WHERE `guid` = 36324 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = 2266.927, `position_y` = 342.044, `position_z` = 36.106, `orientation` = 3.9099, `rotation2` = 0.927116, `rotation3` = -0.374775 WHERE `guid` = 36761 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = 2272.64, `position_y` = 352.356, `position_z` = 35.266, `orientation` = 2.8801, `rotation2` = 0.991465, `rotation3` = 0.130374 WHERE `guid` = 37186 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = 2268.184, `position_y` = 350.62, `position_z` = 36.662, `orientation` = 4.5557, `rotation2` = 0.760279, `rotation3` = -0.649597 WHERE `guid` = 37432 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = 2265.883, `position_y` = 355.254, `position_z` = 42.166, `orientation` = 2.758, `rotation2` = 0.981663, `rotation3` = 0.190623 WHERE `guid` = 39153 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = 2261.674, `position_y` = 340.398, `position_z` = 39.575, `orientation` = 4.4335, `rotation2` = 0.798526, `rotation3` = -0.60196 WHERE `guid` = 39558 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2268.772, `position_y` = 345.453, `position_z` = 45.894, `orientation` = 0.0353, `rotation2` = 0.017649, `rotation3` = 0.999844 WHERE `guid` = 39560 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2265.31, `position_y` = 354.474, `position_z` = 43.391, `orientation` = 1.3443, `rotation2` = 0.62267, `rotation3` = 0.782485 WHERE `guid` = 41871 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2268.41, `position_y` = 345.493, `position_z` = 44.279, `orientation` = 6.0217, `rotation2` = 0.13037, `rotation3` = -0.991465 WHERE `guid` = 41873 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2271.032, `position_y` = 344.962, `position_z` = 40.235, `orientation` = 2.8801, `rotation2` = 0.991465, `rotation3` = 0.130374 WHERE `guid` = 41881 AND `id` = 178745;
UPDATE `gameobject` SET `position_x` = 2269.99, `position_y` = 343.162, `position_z` = 39.758, `orientation` = 6.0392, `rotation2` = 0.12169, `rotation3` = -0.992568 WHERE `guid` = 78989 AND `id` = 181392;
UPDATE `gameobject` SET `position_x` = 2270.19, `position_y` = 340.536, `position_z` = 35.254, `orientation` = 4.0251, `rotation2` = 0.904003, `rotation3` = -0.427525 WHERE `guid` = 151969 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = 2271.748, `position_y` = 348.438, `position_z` = 35.274, `orientation` = 4.3392, `rotation2` = 0.826011, `rotation3` = -0.563655 WHERE `guid` = 151970 AND `id` = 113772;
UPDATE `gameobject` SET `position_x` = 2262.334, `position_y` = 354.707, `position_z` = 35.274, `orientation` = 5.5448, `rotation2` = 0.360863, `rotation3` = -0.932619 WHERE `guid` = 151971 AND `id` = 113768;
UPDATE `gameobject` SET `position_x` = 2254.66, `position_y` = 346.991, `position_z` = 35.274, `orientation` = 0.0627, `rotation2` = 0.031345, `rotation3` = 0.999509 WHERE `guid` = 151972 AND `id` = 113769;
UPDATE `creature` SET `position_x` = 2260.228, `position_y` = 347.719, `position_z` = 36.103, `orientation` = 6.2309 WHERE `guid` = 242967 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2267.592, `position_y` = 348.167, `position_z` = 36.104, `orientation` = 4.9289 WHERE `guid` = 242978 AND `id` = 32820;
UPDATE `gameobject` SET `position_x` = 2265.855, `position_y` = 355.757, `position_z` = 40.712, `orientation` = 1.2221, `rotation2` = 0.573728, `rotation3` = 0.819046 WHERE `guid` = 21952 AND `id` = 181390;

-- Moves with the well.
UPDATE `gameobject` SET `position_x` = 2289.988, `position_y` = 336.01, `position_z` = 36.212, `orientation` = 1.4661 WHERE `guid` = 79417 AND `id` = 187572;
UPDATE `gameobject` SET `position_x` = 2291.368, `position_y` = 335.034, `position_z` = 36.227, `orientation` = 1.4486 WHERE `guid` = 79418 AND `id` = 187572;
UPDATE `gameobject` SET `position_x` = 2290.748, `position_y` = 334.742, `position_z` = 36.229, `orientation` = 4.7124 WHERE `guid` = 79877 AND `id` = 187573;

-- Pilgrim's Bounty feast moved as a group to the harvest field north of the town hall.
UPDATE `gameobject` SET `position_x` = 2346.97, `position_y` = 274.63, `position_z` = 35.044, `orientation` = 6.0737, `rotation2` = 0.104551, `rotation3` = -0.99452 WHERE `guid` = 43663 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2347.07, `position_y` = 274.65, `position_z` = 35.748, `orientation` = 3.3336, `rotation2` = 0.995395, `rotation3` = -0.095856 WHERE `guid` = 19074 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2347.23, `position_y` = 276.13, `position_z` = 35.06, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16336 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 2348.39, `position_y` = 277.5, `position_z` = 35.116, `orientation` = 5.6025, `rotation2` = 0.33381, `rotation3` = -0.94264 WHERE `guid` = 43669 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2348.4, `position_y` = 277.44, `position_z` = 35.812, `orientation` = 5.6025, `rotation2` = 0.33381, `rotation3` = -0.94264 WHERE `guid` = 19080 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2350.76, `position_y` = 267.58, `position_z` = 34.727, `orientation` = 0.9599, `rotation2` = 0.461735, `rotation3` = 0.887018 WHERE `guid` = 43658 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2350.81, `position_y` = 267.58, `position_z` = 35.423, `orientation` = 2.8623, `rotation2` = 0.990265, `rotation3` = 0.139193 WHERE `guid` = 19069 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2352.16, `position_y` = 266.98, `position_z` = 34.727, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16331 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 2353.56, `position_y` = 267.09, `position_z` = 35.506, `orientation` = 1.1345, `rotation2` = 0.537315, `rotation3` = 0.843382 WHERE `guid` = 19068 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2353.57, `position_y` = 266.98, `position_z` = 34.801, `orientation` = 1.9024, `rotation2` = 0.814113, `rotation3` = 0.580707 WHERE `guid` = 43657 AND `id` = 179968;
UPDATE `creature` SET `position_x` = 2353.65, `position_y` = 264.63, `position_z` = 34.552, `orientation` = 4.9218 WHERE `guid` = 52788 AND `id` = 34654;
UPDATE `gameobject` SET `position_x` = 2355.89, `position_y` = 274, `position_z` = 35.428, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 3347 AND `id` = 195664;
UPDATE `creature` SET `position_x` = 2355.97, `position_y` = 273.98, `position_z` = 35.511, `orientation` = 2.0944 WHERE `guid` = 52743 AND `id` = 32823;
UPDATE `gameobject` SET `position_x` = 2355.98, `position_y` = 282.01, `position_z` = 35.91, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 19081 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2356.04, `position_y` = 281.99, `position_z` = 35.221, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 43670 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2357.01, `position_y` = 282.46, `position_z` = 35.202, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16337 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 2358.23, `position_y` = 282.9, `position_z` = 35.873, `orientation` = 4.6251, `rotation2` = 0.737285, `rotation3` = -0.675582 WHERE `guid` = 19079 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2358.26, `position_y` = 282.99, `position_z` = 35.177, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 43668 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2362.46, `position_y` = 271.25, `position_z` = 36.108, `orientation` = 5.62, `rotation2` = 0.325549, `rotation3` = -0.945525 WHERE `guid` = 19067 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2362.52, `position_y` = 271.23, `position_z` = 35.416, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 43656 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2363.49, `position_y` = 271.7, `position_z` = 35.392, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16330 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 2364.72, `position_y` = 272.14, `position_z` = 36.088, `orientation` = 1.9897, `rotation2` = 0.838677, `rotation3` = 0.544629 WHERE `guid` = 19065 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2364.75, `position_y` = 272.23, `position_z` = 35.389, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 43655 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2367.79, `position_y` = 288.03, `position_z` = 35.795, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 19078 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2367.86, `position_y` = 288.01, `position_z` = 35.105, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 43667 AND `id` = 179968;
UPDATE `creature` SET `position_x` = 2368.45, `position_y` = 280.19, `position_z` = 35.57, `orientation` = 2.0944 WHERE `guid` = 52742 AND `id` = 32823;
UPDATE `gameobject` SET `position_x` = 2368.45, `position_y` = 280.19, `position_z` = 35.486, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 3346 AND `id` = 195664;
UPDATE `gameobject` SET `position_x` = 2368.82, `position_y` = 288.5, `position_z` = 35.095, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16335 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 2370.05, `position_y` = 288.93, `position_z` = 35.789, `orientation` = 2.8972, `rotation2` = 0.992543, `rotation3` = 0.121892 WHERE `guid` = 19077 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2370.08, `position_y` = 289.03, `position_z` = 35.093, `orientation` = 2.0071, `rotation2` = 0.843384, `rotation3` = 0.537312 WHERE `guid` = 43666 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2373.26, `position_y` = 276.48, `position_z` = 36.239, `orientation` = 3.7874, `rotation2` = 0.948318, `rotation3` = -0.317322 WHERE `guid` = 19063 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2373.29, `position_y` = 276.56, `position_z` = 35.541, `orientation` = 2.042, `rotation2` = 0.852631, `rotation3` = 0.522514 WHERE `guid` = 43653 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2374.09, `position_y` = 277.03, `position_z` = 35.514, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16329 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = 2374.97, `position_y` = 277.54, `position_z` = 36.175, `orientation` = 1.9199, `rotation2` = 0.819163, `rotation3` = 0.573561 WHERE `guid` = 19064 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2375.15, `position_y` = 277.47, `position_z` = 35.48, `orientation` = 1.9897, `rotation2` = 0.838677, `rotation3` = 0.544629 WHERE `guid` = 43652 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2378.19, `position_y` = 292.9, `position_z` = 35.369, `orientation` = 5.1836, `rotation2` = 0.52251, `rotation3` = -0.852633 WHERE `guid` = 43665 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2378.26, `position_y` = 292.84, `position_z` = 36.062, `orientation` = 2.9845, `rotation2` = 0.996917, `rotation3` = 0.078466 WHERE `guid` = 19076 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2379.55, `position_y` = 293.34, `position_z` = 35.506, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16334 AND `id` = 180353;
UPDATE `creature` SET `position_x` = 2379.62, `position_y` = 284.87, `position_z` = 35.295, `orientation` = 2.0944 WHERE `guid` = 52741 AND `id` = 32823;
UPDATE `gameobject` SET `position_x` = 2379.62, `position_y` = 284.87, `position_z` = 35.211, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 3345 AND `id` = 195664;
UPDATE `gameobject` SET `position_x` = 2380.82, `position_y` = 292.87, `position_z` = 35.544, `orientation` = 4.311, `rotation2` = 0.833876, `rotation3` = -0.551952 WHERE `guid` = 43660 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2381.01, `position_y` = 292.83, `position_z` = 36.24, `orientation` = 4.2935, `rotation2` = 0.838673, `rotation3` = -0.544635 WHERE `guid` = 19071 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2384.32, `position_y` = 281.49, `position_z` = 35.014, `orientation` = 2.234, `rotation2` = 0.898789, `rotation3` = 0.438381 WHERE `guid` = 43651 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2384.37, `position_y` = 281.49, `position_z` = 35.703, `orientation` = 1.7453, `rotation2` = 0.766035, `rotation3` = 0.642799 WHERE `guid` = 19062 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2385.34, `position_y` = 284.18, `position_z` = 35.709, `orientation` = 6.0214, `rotation2` = 0.130519, `rotation3` = -0.991446 WHERE `guid` = 19066 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = 2385.34, `position_y` = 284.08, `position_z` = 35.012, `orientation` = 3.2812, `rotation2` = 0.997565, `rotation3` = -0.069747 WHERE `guid` = 43654 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = 2385.41, `position_y` = 282.73, `position_z` = 34.96, `orientation` = 2.0944, `rotation2` = 0.866027, `rotation3` = 0.499998 WHERE `guid` = 16328 AND `id` = 180353;

-- The gypsy wagon it lay on is gone: on the ground.
UPDATE `gameobject` SET `position_x` = 2262.5, `position_y` = 276.512, `position_z` = 34.489, `orientation` = 2.6005 WHERE `guid` = 41381 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = 2261.46, `position_y` = 274.158, `position_z` = 34.565, `orientation` = 1.9199 WHERE `guid` = 41382 AND `id` = 178431;
UPDATE `gameobject` SET `position_x` = 2261.01, `position_y` = 273.208, `position_z` = 34.572, `orientation` = 5.3931 WHERE `guid` = 41384 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = 2262.02, `position_y` = 274.943, `position_z` = 34.568, `orientation` = 2.81 WHERE `guid` = 41627 AND `id` = 178429;
UPDATE `gameobject` SET `position_x` = 2262.65, `position_y` = 278.054, `position_z` = 34.398, `orientation` = 4.5902 WHERE `guid` = 68657 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = 2265.24, `position_y` = 273.786, `position_z` = 34.66, `orientation` = 3.0114 WHERE `guid` = 151948 AND `id` = 113770;

-- The gypsy wagon it hung on is gone: under the new gazebo eave.
UPDATE `gameobject` SET `position_x` = 2274.72, `position_y` = 272.12, `position_z` = 42.6, `orientation` = 1.5708, `rotation2` = 0.707108, `rotation3` = 0.707105 WHERE `guid` = 41865 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2268.72, `position_y` = 266.12, `position_z` = 42.6, `orientation` = 3.1416, `rotation2` = 1, `rotation3` = -0.000004 WHERE `guid` = 41864 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = 2271.19, `position_y` = 269.66, `position_z` = 41.4, `orientation` = 2.3562, `rotation2` = 0.923881, `rotation3` = 0.382681 WHERE `guid` = 8175 AND `id` = 180472;

-- Square lowered.
UPDATE `gameobject` SET `position_x` = 2257.57, `position_y` = 271.663, `position_z` = 34.407, `orientation` = 2.3736 WHERE `guid` = 78446 AND `id` = 181355;
UPDATE `creature` SET `position_x` = 2215.43, `position_y` = 237.536, `position_z` = 35.607, `orientation` = 1.693 WHERE `guid` = 78373 AND `id` = 15568;
UPDATE `gameobject` SET `position_x` = 2257.66, `position_y` = 267.047, `position_z` = 34.664, `orientation` = 3.002 WHERE `guid` = 151956 AND `id` = 113768;
UPDATE `creature` SET `position_x` = 2239.51, `position_y` = 282.798, `position_z` = 34.753, `orientation` = 5.2884 WHERE `guid` = 20425 AND `id` = 23973;
UPDATE `creature` SET `position_x` = 2240.93, `position_y` = 283.706, `position_z` = 34.74, `orientation` = 3.6303 WHERE `guid` = 20297 AND `id` = 23971;
UPDATE `creature` SET `position_x` = 2254.41, `position_y` = 297.984, `position_z` = 34.358, `orientation` = 5.776 WHERE `guid` = 242956 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2271.97, `position_y` = 289.642, `position_z` = 34.555, `orientation` = 2.905 WHERE `guid` = 242988 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2261.95, `position_y` = 280.004, `position_z` = 34.26, `orientation` = 2.427 WHERE `guid` = 244082 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2269.52, `position_y` = 280.954, `position_z` = 34.662, `orientation` = 2.893 WHERE `guid` = 242983 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2239.51, `position_y` = 282.798, `position_z` = 34.753, `orientation` = 5.2884 WHERE `guid` = 243872 AND `id` = 32820;

-- CoA ground.
UPDATE `creature` SET `position_x` = 2289.64, `position_y` = 428.394, `position_z` = 34.116, `orientation` = 1.0472 WHERE `guid` = 202761 AND `id` = 16781;
UPDATE `creature` SET `position_x` = 2291.1, `position_y` = 432.024, `position_z` = 34.203, `orientation` = 4.5902 WHERE `guid` = 202762 AND `id` = 16781;
UPDATE `gameobject` SET `position_x` = 2289.87, `position_y` = 434.362, `position_z` = 34.315, `orientation` = 4.66 WHERE `guid` = 151020 AND `id` = 181355;
UPDATE `gameobject` SET `position_x` = 2292.08, `position_y` = 424.978, `position_z` = 34.102, `orientation` = 3.3685 WHERE `guid` = 151013 AND `id` = 188020;
UPDATE `gameobject` SET `position_x` = 2208.33, `position_y` = 304.79, `position_z` = 34.714, `orientation` = 5.3943 WHERE `guid` = 151977 AND `id` = 113769;
UPDATE `creature` SET `position_x` = 2223.5, `position_y` = 399.235, `position_z` = 36.389, `orientation` = 0.504 WHERE `guid` = 242911 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2225.04, `position_y` = 382.953, `position_z` = 35.119, `orientation` = 5.981 WHERE `guid` = 242912 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2249.8, `position_y` = 416.225, `position_z` = 35.645, `orientation` = 3.341 WHERE `guid` = 242943 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2293.34, `position_y` = 423.774, `position_z` = 34.12, `orientation` = 5.638 WHERE `guid` = 243016 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2287.89, `position_y` = 440.899, `position_z` = 34.512, `orientation` = 3.1418 WHERE `guid` = 244299 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2322.2, `position_y` = 332.751, `position_z` = 37.165, `orientation` = 4.385 WHERE `guid` = 243047 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2330.09, `position_y` = 243.529, `position_z` = 28.173, `orientation` = 5.202 WHERE `guid` = 243056 AND `id` = 32820;

-- Beside the bonfire on open ground, clear of the tower rubble.
UPDATE `gameobject` SET `position_x` = 2275.5, `position_y` = 460.5, `position_z` = 33.856, `orientation` = 1.1868 WHERE `guid` = 151018 AND `id` = 181355;
UPDATE `gameobject` SET `position_x` = 2274, `position_y` = 454.5, `position_z` = 33.924, `orientation` = 0.3491 WHERE `guid` = 151012 AND `id` = 188020;

-- Out of the Masons' Lodge porch.
UPDATE `gameobject` SET `position_x` = 2262, `position_y` = 337, `position_z` = 35.079, `orientation` = 5.7421 WHERE `guid` = 78447 AND `id` = 181355;

-- Off the new grave.
UPDATE `gameobject` SET `position_x` = 2317, `position_y` = 316, `position_z` = 36.966, `orientation` = 4.9655 WHERE `guid` = 151965 AND `id` = 113772;

-- SuperTrack turn-in point.
UPDATE `creature` SET `position_x` = 2236.33, `position_y` = 247.33, `position_z` = 33.66, `orientation` = 0.86 WHERE `guid` = 244807 AND `id` = 32798;
UPDATE `creature` SET `position_x` = 2244.84, `position_y` = 262.27, `position_z` = 34.148, `orientation` = 0.84 WHERE `guid` = 244811 AND `id` = 32837;

-- On the belfry rubble.
UPDATE `creature` SET `position_x` = 2309.1, `position_y` = 282.281, `position_z` = 82.47, `orientation` = 6.0563 WHERE `guid` = 201200 AND `id` = 10716;
UPDATE `creature` SET `position_x` = 2311.46, `position_y` = 292.325, `position_z` = 81.725, `orientation` = 0.384 WHERE `guid` = 201202 AND `id` = 10716;

-- On the ruin foundation.
UPDATE `gameobject` SET `position_x` = 2232.44, `position_y` = 277.014, `position_z` = 35.153, `orientation` = 3.2638 WHERE `guid` = 43055 AND `id` = 186234;
UPDATE `gameobject` SET `position_x` = 2232.5, `position_y` = 275.318, `position_z` = 35.11, `orientation` = 2.7053 WHERE `guid` = 43060 AND `id` = 186614;
UPDATE `gameobject` SET `position_x` = 2234.31, `position_y` = 277.073, `position_z` = 35.071, `orientation` = 5.8468 WHERE `guid` = 43058 AND `id` = 186615;

-- Out of the gazebo post.
UPDATE `gameobject` SET `position_x` = 2277.55, `position_y` = 266.3, `position_z` = 35.108, `orientation` = 0.2269 WHERE `guid` = 41622 AND `id` = 178430;

-- Buried in the knoll: open ground below it.
UPDATE `creature` SET `position_x` = 2254, `position_y` = 445, `position_z` = 38.512, `orientation` = 2.968 WHERE `guid` = 242925 AND `id` = 32820;

-- Out of the new chapel.
UPDATE `creature` SET `position_x` = 2172, `position_y` = 350, `position_z` = 37.391, `orientation` = 5.015 WHERE `guid` = 242861 AND `id` = 32820;

-- Stranded in the Masons' Lodge (old stable site): open ground, short leash.
UPDATE `creature` SET `position_x` = 2266, `position_y` = 312, `position_z` = 34.124, `orientation` = 5.609, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 242935 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2273, `position_y` = 318, `position_z` = 34.113, `orientation` = 5.54353, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 243746 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2278.5, `position_y` = 304.5, `position_z` = 34.732, `orientation` = 5.605, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 242960 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2283, `position_y` = 320.5, `position_z` = 34.202, `orientation` = 6.128, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 242959 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2244.5, `position_y` = 354, `position_z` = 35.289, `orientation` = 5.591, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 242968 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2243.5, `position_y` = 367.5, `position_z` = 35.288, `orientation` = 5.554, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 242940 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 2249.5, `position_y` = 368, `position_z` = 35.27, `orientation` = 5.779, `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 242976 AND `id` = 32820;

-- Out of the town hall post: on its outer face under the eave.
UPDATE `gameobject` SET `position_x` = 2314.8, `position_y` = 303.48, `position_z` = 54.255, `orientation` = 1.51844 WHERE `guid` = 8177 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = 2304.21, `position_y` = 260.41, `position_z` = 54.239, `orientation` = 5.02655 WHERE `guid` = 39567 AND `id` = 180472;

-- On the CoA town hall roof.
UPDATE `gameobject` SET `position_x` = 2302.42, `position_y` = 295.455, `position_z` = 53.35, `orientation` = 1.32645 WHERE `guid` = 76528 AND `id` = 181389;

-- Sunk in a stump, rubble or the moved well: open ground beside it.
UPDATE `creature` SET `position_x` = 2286.5, `position_y` = 332.8, `position_z` = 34.53, `orientation` = 3.604 WHERE `guid` = 243003 AND `id` = 32820;
UPDATE `gameobject` SET `position_x` = 2291.53, `position_y` = 332.038, `position_z` = 35.054, `orientation` = 6.25743 WHERE `guid` = 151967 AND `id` = 113769;
UPDATE `creature` SET `position_x` = 2272, `position_y` = 450, `position_z` = 34.027, `orientation` = 3.4143 WHERE `guid` = 244296 AND `id` = 32820;
