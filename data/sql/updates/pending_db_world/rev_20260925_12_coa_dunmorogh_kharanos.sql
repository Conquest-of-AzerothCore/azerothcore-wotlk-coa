-- CoA Kharanos and its hills: the Thunderbrews' hops, Ikoras's automata, Gornarn's range, Gravedigger
-- Nonuid, Mirsinth and Jun'Kon, and Coldhewn Camp (quests 254003, 254004, 1660076-1660080, 500005 and
-- 500006); Yori Crackhelm to the Thunderbrew inn, his 5841 turn-in point (DESIGN).
-- Creature guids 9008480-9008799, gameobject guids 7914120-7914299, gossip menus 932240-932269.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stand-in displays where the CoA model is missing from the client.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(254003, 'Mirsinth the Exile', NULL, 932240, 10, 10, 0, 35, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1.96, 1, 1, 1, 1, 0, 0, ''),
(254006, 'Jun''Kon', NULL, 0, 8, 8, 0, 37, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 254006, '', 0, 2, 1, 1, 1, 1, 0, 0, ''),
(162882, 'Norhi Thunderbrew', NULL, 0, 13, 13, 0, 55, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162883, 'Eyma Thunderbrew', NULL, 0, 15, 15, 0, 55, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162884, 'Ikoras', NULL, 0, 9, 9, 0, 875, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(162891, 'Gornarn', NULL, 932243, 10, 10, 0, 55, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(162901, 'Gravedigger Nonuid', NULL, 932241, 18, 18, 0, 55, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(765556, 'Brunna Ironhew', 'Woodcutting Trainer', 0, 11, 11, 0, 55, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(764536, 'Old Kargan Stouthew', NULL, 932244, 10, 10, 0, 55, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(76555, 'Icehide', NULL, 0, 14, 14, 0, 66, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 2, 1, 0, 0, '', 0, 2.88, 1, 1, 1, 1, 0, 0, ''),
(162888, 'Out-of-Control Automaton v1.1', NULL, 0, 6, 6, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 9, 0, 162888, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162889, 'Out-of-Control Automaton v1.2', NULL, 0, 6, 6, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 9, 0, 162889, '', 0, 0.96, 1, 1, 1, 1, 0, 162888, ''),
(162890, 'Out-of-Control Automaton v1.3', NULL, 0, 7, 7, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 9, 0, 162890, '', 0, 0.96, 1, 1, 1, 1, 0, 162888, ''),
(162917, 'Target', NULL, 0, 5, 5, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (76555, 162882, 162883, 162884, 162888, 162889, 162890, 162891, 162901, 162917, 254003, 254006, 764536, 765556);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(254003, 0, 254002, 1, 1),
(254006, 0, 27490, 1, 1),
(162882, 0, 2284, 1, 1),
(162883, 0, 2286, 1, 1),
(162884, 0, 4285, 1, 1),
(162891, 0, 1847, 1, 1),
(162901, 0, 3085, 1, 1),
(765556, 0, 1839, 1, 1),
(764536, 0, 3306, 1, 1),
(76555, 0, 333954, 1, 1),
(162888, 0, 6888, 1, 1),
(162889, 0, 8369, 1, 1),
(162890, 0, 6889, 1, 1),
(162917, 0, 29075, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (76555, 162882, 162883, 162884, 162888, 162889, 162890, 162891, 162901, 162917, 254003, 254006, 764536, 765556);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(162891, 1, 0, 0, 2508),
(162901, 1, 3334, 0, 0),
(764536, 1, 0, 0, 2508),
(765556, 1, 768, 0, 0);

-- Old Kargan sits on the bearskin rug of his post (ST8560 is on the rug, 379.77)
DELETE FROM `creature_template_addon` WHERE `entry` IN (76555, 162882, 162883, 162884, 162888, 162889, 162890, 162891, 162901, 162917, 254003, 254006, 764536, 765556);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(764536, 0, 0, 1, 1, 0, 0, NULL);

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 162917;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`)
VALUES
(162917, 1, 1, 0, 1, 0, 0, NULL);

-- CoA displays 254002 (Mirsinth) and 333954 (Icehide) lack model info; values of stock displays of the
-- same build.
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (254002, 333954);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(254002, 0.306, 1.5, 1, 0),
(333954, 1.0335, 1.95, 2, 0);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
-- Greetings and answers are the cached npc_text of each NPC; the option texts are INFERRED from them.
-- Mirsinth's second text 52003 speaks of a lake and green grass: her Loch Modan quest 254005, not built.
DELETE FROM `npc_text` WHERE `ID` IN (52002, 85161, 85191, 85205, 115558);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(52002, 'Old Mirsinth will not harm you. Cast out of her tribe, yes, no loyalty to those with no loyalty to her. Old Mirsinth has lost passion for petty feuds and bloodshed long ago anyways, she only wants to see lands beyond this one before the Loa take her.', 'Old Mirsinth will not harm you. Cast out of her tribe, yes, no loyalty to those with no loyalty to her. Old Mirsinth has lost passion for petty feuds and bloodshed long ago anyways, she only wants to see lands beyond this one before the Loa take her.', 0, 0, 1),
(85191, '<The gravedigger’s weary look tells of a long day at the shovel. The pit impresses you not so much by its depth as by the clean, polished finish of its earthen walls.>', '<The gravedigger’s weary look tells of a long day at the shovel. The pit impresses you not so much by its depth as by the clean, polished finish of its earthen walls.>', 0, 0, 1),
(85161, 'Sorry, didn’t notice I had company.$b$b<The dwarf wipes the sweat from his brow with the back of his hand, then dries it off in his abundant grey beard.>$b$bDid you know the deceased?', 'Sorry, didn’t notice I had company.$b$b<The dwarf wipes the sweat from his brow with the back of his hand, then dries it off in his abundant grey beard.>$b$bDid you know the deceased?', 0, 0, 1),
(85205, '<You figure that the solitary dwarf leaning against the wheel of the small wagon must be the owner of the stall. Around him stretches a chaotic carpet of opened ammo boxes, shells scattered across the snow, crumpled papers, overturned barrels, and broken baskets, all lying in utter disarray.>', '<You figure that the solitary dwarf leaning against the wheel of the small wagon must be the owner of the stall. Around him stretches a chaotic carpet of opened ammo boxes, shells scattered across the snow, crumpled papers, overturned barrels, and broken baskets, all lying in utter disarray.>', 0, 0, 1),
(115558, 'Ahh, a fresh face! Welcome to Coldhewn Camp. We skin what we hunt, and we cut what we burn—keeps the coin flowin’ and the ale cold.$B$BPlenty o’ wolves and hares in these hills, and their pelts fetch a fine price in Ironforge. But keep yer eyes open—there’s been new tracks in the snow. Big ones. Clawed and deep.$B$BSome say it’s a rogue yeti, others swear it’s a frost elemental gone feral. But a trapper came down from the ridge, white as bone, swearing he saw a great sabercat—pale as the drifts, eyes like cold fire.$B$BThey call it Icehide, though no one''s been fool enough to get close. If ye go wanderin’, $N, keep a sharp blade… and sharper senses.', 'Ahh, a fresh face! Welcome to Coldhewn Camp. We skin what we hunt, and we cut what we burn—keeps the coin flowin’ and the ale cold.$B$BPlenty o’ wolves and hares in these hills, and their pelts fetch a fine price in Ironforge. But keep yer eyes open—there’s been new tracks in the snow. Big ones. Clawed and deep.$B$BSome say it’s a rogue yeti, others swear it’s a frost elemental gone feral. But a trapper came down from the ridge, white as bone, swearing he saw a great sabercat—pale as the drifts, eyes like cold fire.$B$BThey call it Icehide, though no one''s been fool enough to get close. If ye go wanderin’, $N, keep a sharp blade… and sharper senses.', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932240, 932241, 932242, 932243, 932244);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932240, 52002),
(932241, 85191),
(932242, 85161),
(932243, 85205),
(932244, 115558);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932240, 932241, 932242, 932243, 932244);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932241, 0, 0, '<Clear your throat.>', 0, 1, 1, 932242, 0, 0, 0, '', 0),
(932242, 0, 0, 'No, I didn''t know them. Tell me about them.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (932240, 932241, 932242, 932243, 932244) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 932242, 0, 0, 0, 9, 0, 1660080, 0, 0, 0, 0, 0, '', 'Gravedigger Nonuid - listen only while quest 1660080 is taken');

-- ---------------------------------------------------------------------------
-- 3. World objects and loot
-- ---------------------------------------------------------------------------
-- The Coldhewn quest tree is its own entry 2300580 with the Dun Morogh Tree look: 244620 is main's Woodcutting
-- node (lock 1876, Forestwood logs), so reusing it would turn those nodes into quest trees. It takes the
-- plain lock 1689.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300550, 10, 7702, 'Thunderbrew Hop', '', '', 0.4, 'SmartGameObjectAI', 0, 1660077, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300580, 3, 170005, 'Dun Morogh Tree', 'AxeCursor', 'Collecting', 1, '', 1689, 2300580, 0, 1, 1, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

-- Flags 4 (GO_FLAG_INTERACT_COND): usable only while the quest needs them.
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (2300550, 2300580);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`)
VALUES
(2300550, 0, 4),
(2300580, 0, 4);

-- Jun'Kon's totem, the automata parts and the Frostpine log: 100 %, quest-only.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (162888, 162889, 162890, 254006);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(254006, 254002, 0, 100, 1, 1, 0, 1, 1, 'Jun''Kon - Mirsinth''s Totem'),
(162888, 558965, 0, 100, 1, 1, 0, 1, 1, 'Out-of-Control Automaton v1.1 - Reusable Mechanical Parts'),
(162889, 558965, 0, 100, 1, 1, 0, 1, 1, 'Out-of-Control Automaton v1.2 - Reusable Mechanical Parts'),
(162890, 558965, 0, 100, 1, 1, 0, 1, 1, 'Out-of-Control Automaton v1.3 - Reusable Mechanical Parts');

DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300580;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300580, 662336, 0, 100, 1, 1, 0, 1, 1, 'Dun Morogh Tree - Frostpine Log');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (162888, 162889, 162890, 254006);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(254006, 0, 254002),
(162888, 0, 558965),
(162889, 0, 558965),
(162890, 0, 558965);

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` = 2300580;
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(2300580, 0, 662336);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- Chains 254002 -> 254003 -> 254004 and 1660009 -> 1660076 -> 1660077. 254004's RewardNextQuest stays
-- 0 until 254005 (Loch Modan) exists. The upsert leaves the POI columns to migration 60.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(254003, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 254004, 2, 0, 67, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 3, 0, 54, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Mirsinth', 'Find the exiled Frostmane troll.', 'I saw a troll wanderin’ in the hills up between Brewnall and Kharanos, looked to be avodin’ the other trolls. Went near the cave of that yeti we’ve taken to callin’ Old Icebeard. Why? Well, he’s been there for a while, and his beard has ice in it.$B$BAnyways, your troll exile’s probably dead by now, Old Icebeard’s taken out some good dwarves in my time. I wouldn’t go near him personally, but if you’ve really gotta find that troll, just keep an eye out and stay clear of him. Got it? Rather not have your death on my conscience.', '', 'Find the exiled Frostmane troll', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254004, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Brother''s Betrayal', 'Get Mirsinth the Exile’s totem from Jun’Kon at Frostmane Hold.', 'You wish to talk things Old Mirsinth has seen? A being of metal wages war upon my people and maybe yours as well? Yes, yes, Old Mirsinth has seen many things, but maybe your being of metal as well. You wish it stopped for the threat it poses to your people, though it attacks mine?$B$BYou have better foresight than Old Mirsinth’s people, perhaps. You have put aside old feuds, so Old Mirsinth will as well. Old Mirsinth’s people are no longer Old Mirsinth’s anyways, cast out, yes, “exiled” as you say? Why is that? And why does your metal being not do as told? For the same reasons Old Mirsinth does not, or perhaps the opposite.$B$BIf you want answers, you will do something Old Mirsinth cannot. Old Mirsinth hides here because yeti keeps our peoples away. Yeti easier to hide from than our peoples, see. Old Mirsinth can hide, avoid, wander, but Brother Jun’Kon took Old Mirsinth’s totem when cast her out, see. No family of Old Mirsinth if she is no family of his. Brother Jun’Kon is coward, hides deep, deep in cave. Bring totem back, we will talk about metal being, history, many things, yes?', '', 'Return to Mirsinth the Exile', 0, 0, 0, 0, 0, 0, 0, 0, 254002, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(1660076, 2, 8, 5, 1, 0, 0, 0, 0, 0, 0, 1660077, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302013, 1, 2302018, 1, 2302023, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Growing Business', 'Speak with Eyma Thunderbrew at the Thunderbrew Distillery in Kharanos.', '<The dwarf waves from afar to catch your eye; big sweeping arms at first, then he starts hopping in place.>$b$bWell met! <pants> I saw how you handled Groldha. I''m guessing you won''t be lingering in Anvilmar much longer...$b$bIf that''s the case and your feet carry you to Kharanos, I''ve a message that needs delivering.$b$bFind Eyma at the inn and tell her the talks in Anvilmar bore fruit. They want a shipment of our best ale; if it wins them over, we''ve got ourselves regular buyers. The ancestors smile on us, $C!', '', 'Speak with Eyma Thunderbrew.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660077, 2, 8, 5, 1, 0, 0, 0, 0, 0, 0, 0, 5, 260, 337, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302028, 1, 2302033, 1, 2302038, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Thunderbrew''s Hop', 'Harvest seven Thunderbrew Hops from the Thunderbrew Distillery grounds in Kharanos.', 'Nori must''ve seen something in you, to trust you with that message.$b$bSince you''re here, maybe you can lend a hand.$b$bStep out of the inn and look left; you''ll see the distillery''s hop yard. Special strain of hops, for the finest brew in all Dun Morogh.$b$bWe''re swamped today with customers. Would you mind picking hops and bringing them back to me? Hardly hero''s work, I know. But it pays, and it pays well.', '', 'Return to Eyma Thunderbrew.', 0, 0, 0, 0, 0, 0, 0, 0, 558964, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, '', '', '', ''),
(1660078, 2, 8, 5, 1, 0, 0, 0, 0, 0, 0, 0, 5, 350, 382, 0, 0, 0, 0, 0, 8, 0, 2302043, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Bots on Strike', 'Defeat Out-of-Control Automata clogging the Kharanos tunnel and recover Reusable Mechanical Parts from their remains.', 'Careful! The tunnel''s been impassable for a few days now.$b$bMy inventions, the automata I built with these very hands <he shakes them in your face, more comic than tragic>, have betrayed me. They''ve turned on me!$b$bNow they attack anything that wanders close. They''ve already claimed a life and, worse yet, they''ve wrecked my reputation!$b$bDon''t go into that tunnel unless... <the gnome''s eyes take on an opportunistic glint>.$b$bYou''re not like the others, now that I look at you. You might just survive them. Destroy them... That''s it! Go in there, take them apart, and bring me their parts.', '', 'Return to Ikoras.', 162888, 0, 0, 0, 7, 0, 0, 0, 558965, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 'Out-of-Control Automaton destroyed', '', '', ''),
(1660079, 2, 8, 5, 1, 0, 0, 0, 0, 0, 0, 0, 5, 83, 114, 0, 0, 0, 0, 558950, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302048, 1, 2302053, 1, 2302058, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Live-Fire Demo', 'Test Gornarn''s Blunderbuss and ammo on the practice targets up on the ridge above Kharanos.', '<The dwarf braces a blunderbuss between his knees and runs a rod down the barrel; push, twist, pull, until the grime comes loose and spatters out.>$b$bSorry, didn''t notice I had an audience.$b$bFancy putting a few rounds downrange? Targets are always hungry for lead; with luck, we''ll catch a buyer''s eye.$b$bAll this ammunition isn''t going to sell itself.', '', 'Speak with Gornarn.', 162917, 0, 0, 0, 3, 0, 0, 0, 558950, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Target hit', '', '', ''),
(1660080, 2, 8, 5, 1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stay a While', 'Take a moment from the noise and haste and stay a while to listen to Gravedigger Nonuid.', '<The gravedigger''s weary look tells of a long day at the shovel. The pit impresses you not so much by its depth as by the clean, polished finish of its earthen walls.>$b$b<Perhaps he has something worth sharing.>', '', 'Say goodbye to Nonuid.', 162921, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Listen to Gravedigger Nonuid', '', '', ''),
(500005, 2, 7, 5, 1, 0, 0, 0, 0, 0, 0, 0, 5, 175, 292, 0, 0, 0, 0, 0, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 500660, 1, 500659, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Timber for the Coldhewn', 'Chop down Dun Morogh trees near Coldhewn Camp and return with 12 Frostpine Logs.', 'Did they send you? If you are another one of those scumbag contract managers, turn around and walk back the way you came. I am up to my neck in bad orders and worse paperwork.$B$BJust got an extra order from Ironforge. Big one. Sudden. And instead of giving us more hands, they swapped out the whole logging team. No time to train, no time to plan, just get it done.$B$BI am behind, and I hate being behind. If you are handy with an axe and do not mind the cold, I could use the help. We need Frostpine logs, twelve of them. You will find them in the woods nearby.$B$BIt is not charity work. I will make sure it is worth your while.', '', 'Return to Brunna Ironhew at Coldhewn Camp in Dun Morogh.', 0, 0, 0, 0, 0, 0, 0, 0, 662336, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, '', '', '', ''),
(500006, 2, 11, 6, 1, 1, 3, 0, 0, 0, 0, 0, 6, 375, 292, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 500661, 1, 500662, 1, 500663, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Icehide the Unbroken', 'You’ve been asked to track and slay Icehide, the elite Frostsaber haunting Coldhewn Ridge above the camp.', 'You see that rise above the camp? That is where it took the last hunter. We found the blood trail. Nothing else.$B$BThey call it Icehide. Ice leopard. Big, silent, and too smart for our traps. It strikes fast, leaves nothing but red in the snow, and then it is gone again.$B$BToo many have died chasing it. This is not about pride or sport anymore. We cannot work those hills while it still prowls. And I will not send another one of ours to vanish into the cold.$B$BIf you are willing to take the risk, do it. But be sure of your shot. Icehide will not give you a second.', '', 'Return to Old Kargan Stouthew at Coldhewn Camp in Dun Morogh.', 76555, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (254003, 254004, 500005, 500006, 1660076, 1660077, 1660078, 1660079, 1660080);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(254003, 0, 0, 254002, 0, 0),
(254004, 0, 0, 254003, 0, 0),
(1660076, 0, 0, 1660009, 0, 0),
(1660077, 0, 0, 1660076, 0, 0),
(1660078, 0, 0, 0, 0, 0),
(1660079, 0, 0, 0, 1, 0),
(1660080, 0, 0, 0, 0, 0),
(500005, 0, 0, 0, 0, 0),
(500006, 0, 0, 0, 0, 0);

-- Progress and completion texts and paragraph breaks from the AscensionES archive (pEN / cEN).
DELETE FROM `quest_offer_reward` WHERE `ID` IN (254003, 254004, 500005, 500006, 1660076, 1660077, 1660078, 1660079, 1660080);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(254003, 'You here to kill me?$B$BYes, I can speak your language, the loa show Old Mirsinth many things. The speech of your people be but one of many, though your kind care little for it, as do mine. The snow covers with blood, the troggs show, my people rejoice, care little when Old Mirsinth says they will kill both our kinds with half a chance.$B$BNo, no, old feuds and vengeance, these things mean more, yes? Old Misinth cares little for them.'),
(254004, 'Old Mirsinth and Brother Jun’Kon friends once, long, long ago…not children anymore, Old Mirsinth wiser now, Brother Jun’Kon less wise…but Old Mirsinth cannot help remember those days…$B$BGive Old Mirsinth a moment…patience is valuable you know…isn’t that right Brother Jun’Kon?'),
(1660076, '<The dwarf woman’s inquisitive brow softens when you mention Norhi and the message he asked you to deliver.>$B$BThat’s good news, <she says, without much enthusiasm.>$B$BI’ll see to it the shipment’s ready as soon as possible.'),
(1660077, 'Hm… <Eyma inhales the aroma of the hops you gathered; her eyes flutter shut.>$B$BIntoxicating.$B$BI hope the wildlife didn’t give you too much grief. At this rate I’ll have to hire someone to patrol the grounds.'),
(1660078, 'You survived!$B$BAnd you salvaged no small number of parts.$B$B<Ikoras coughs and bats away the thin plume of smoke puffing from the cave mouth, fidgeting as he does.>$B$BWith these, and a couple of stiff drinks at the distillery, I think I’ll recover the inspiration (and the nerve) to plunge into my next project: a second generation of automata, stronger and more obedient than the first batch.$B$BThanks!'),
(1660079, 'By my mother’s beard! Now that was a show!$B$BYou saw it with your own eyes, eh? I sell only the finest kit.$B$BDo me a favor and spread the word, will you? In this line of work, nothing beats word of mouth.'),
(1660080, 'Choose your enemies with care, $C.$B$BPlenty of dwarves pass through Kharanos eager to forge a legend… only to end up dropped into one of these niches.'),
(500005, 'This will do. Not perfect, but better than nothing. You just saved me from a lecture and a frozen sleep outside the barracks.$B$BHere, take this. You earned more than thanks.'),
(500006, 'That is it. No mistaking that pelt.$B$BYou did what no one else could. We will honor the fallen, and the hills will be safer for it.$B$BYou earned this. And our respect.');

DELETE FROM `quest_request_items` WHERE `ID` IN (254003, 254004, 500005, 500006, 1660076, 1660077, 1660078, 1660079, 1660080);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(254003, 'Watch out for that yeti, ye hear?'),
(254004, 'Brother Jun''Kon cast Old Mirsinth out, said Old Mirsinth traitor for questioning old feuds and vengeance.$B$BBut Old Mirsinth cannot help wish her brother did not need die...make it quick for Old Mirsinth.'),
(1660076, ''),
(1660077, 'Got the hops?'),
(1660078, 'How are things in there?'),
(1660079, 'Don''t worry about the target. Blast ''em good!'),
(1660080, ''),
(500005, 'You have the logs? Or at least some progress to show? I am running out of ways to stall the foreman.'),
(500006, 'Still breathing? Or did Icehide just let you crawl back to tell the tale?');

DELETE FROM `creature_queststarter` WHERE `quest` IN (254003, 254004, 500005, 500006, 1660076, 1660077, 1660078, 1660079, 1660080);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(254002, 254003),
(254003, 254004),
(765556, 500005),
(764536, 500006),
(162882, 1660076),
(162883, 1660077),
(162884, 1660078),
(162891, 1660079),
(162901, 1660080);

DELETE FROM `creature_questender` WHERE `quest` IN (254003, 254004, 500005, 500006, 1660076, 1660077, 1660078, 1660079, 1660080);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(254003, 254003),
(254003, 254004),
(765556, 500005),
(764536, 500006),
(162883, 1660076),
(162883, 1660077),
(162884, 1660078),
(162891, 1660079),
(162901, 1660080);

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9008480, 9008481, 9008482, 9008483, 9008484, 9008485, 9008486, 9008487, 9008488, 9008489, 9008490, 9008491, 9008492, 9008500, 9008501, 9008502, 9008503, 9008504, 9008505, 9008506, 9008507, 9008508, 9008509, 9008510, 9008511, 9008512, 9008513, 9008514, 9008515, 9008516, 9008517, 9008518, 9008519, 9008520, 9008521, 9008522, 9008523, 9008524, 9008525, 9008526, 9008527, 9008528) OR `guid` BETWEEN 9008480 AND 9008799;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9008480, 254003, 0, 0, 0, 1, 1, 0, -5584.3, -8.088, 427.445, 4.03, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST242, the 254003/254004 turn-in point on the Chill Breeze ridge above Old Icebeard''s cave (Questie 2.0 yd); she faces the yeti''s cave, which keeps her people away'),
(9008481, 254006, 0, 0, 0, 1, 1, 0, -5569.75, 740.475, 392.368, 4.44, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST95, the 254004 objective point on the Md_Icecave02 floor deep in Frostmane Hold (Questie 2.8 yd); faces the way in from the hold; the rare Great Father Arctikus can share the chamber (pool, 7.8 yd)'),
(9008482, 162882, 0, 0, 0, 1, 1, 0, -6105.4, 401.4, 395.542, 0.31, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-QUESTIE sighting in the Anvilmar hall (no SuperTrack point), on the 395.54 floor beside the ale kegs; faces Groldha''s post across the hall ("I saw how you handled Groldha"); 7.2 yd from Freja'),
(9008483, 162883, 0, 0, 0, 1, 1, 0, -5606.57, -529.594, 399.657, 2.13, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST8734, the 1660076/1660077 turn-in point on the Thunderbrew inn upper floor (Snow_Inn.wmo), the post of the retired Granis Swiftaxe; faces the room like Innkeeper Belm beside her'),
(9008484, 162884, 0, 0, 0, 1, 1, 0, -5710.8, -603, 422.97, 4.76, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST8736 (the 1660078 turn-in point) sits on a stack of cargo boxes; he stands on the terrace ground beside them, 1.56 yd from the point, facing the tunnel mouth his automata hold'),
(9008485, 162891, 0, 0, 0, 1, 1, 1, -5641.15, -621.904, 448.922, 1.52, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST8738, the 1660079 turn-in point at the ammunition stall on the ridge, against the wagon wheel; faces his targets downrange'),
(9008486, 162917, 0, 0, 0, 1, 1, 0, -5640.53, -609.348, 448.433, 4.66, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST8739, the 1660079 objective point downrange of the stall, beside the mining lamp; faces the stall'),
(9008487, 162917, 0, 0, 0, 1, 1, 0, -5643.5, -606.5, 448.226, 4.86, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: second target 4.1 yd from the first, west of the small snow pine on the open snow, facing the stall (INFERRED: three targets for three hits)'),
(9008488, 162917, 0, 0, 0, 1, 1, 0, -5639.5, -605, 447.886, 4.62, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: third target 4.5 yd further downrange of the first, by the chair of the range, facing the stall (INFERRED)'),
(9008489, 162901, 0, 0, 0, 1, 1, 1, -5602.6, -604.8, 452.239, 2.93, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-QUESTIE sighting (-5605.5, -604.4) is on the fresh dirt mound of the new hilltop cemetery; he stands at its north edge, 2.9 yd away, facing the pit and the wheelbarrow; 5.6 yd from Zipak, 4.8 from the healer'),
(9008490, 765556, 0, 0, 0, 1, 1, 1, -5764.65, -1275.34, 379.641, 0.85, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST8559, the 500005 turn-in point by the log stacks of Coldhewn Camp; faces the woods she sends players to'),
(9008491, 764536, 0, 0, 0, 1, 1, 1, -5772.58, -1246.25, 379.771, 0.06, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST8560, the 500006 turn-in point on the bearskin rug of Coldhewn Camp; faces the brazier'),
(9008492, 76555, 0, 0, 0, 1, 1, 0, -5794.58, -1391.9, 441.429, 1.42, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos: SOURCED-CLIENT ST8557, the 500006 objective point on the ledge by the campfire on Coldhewn Ridge; faces down toward the camp'),
(9008500, 162888, 0, 0, 0, 1, 1, 0, -5705.96, -652.12, 424.716, 1.69, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; tunnel mouth by the rifle and chair (Questie v1.1 sighting), facing out toward Ikoras''s terrace'),
(9008501, 162888, 0, 0, 0, 1, 1, 0, -5710, -672, 425.362, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; west side of the mouth passage where it starts to drop toward the brazier, facing the entrance'),
(9008502, 162889, 0, 0, 0, 1, 1, 0, -5716.46, -679.7, 423.274, 1.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; west side of the brazier landing inside the mouth (Questie v1.2 sighting)'),
(9008503, 162890, 0, 0, 0, 1, 1, 0, -5702.68, -680.19, 423.681, 1.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; beside the first brazier inside the mouth (Questie v1.3 sighting)'),
(9008504, 162889, 0, 0, 0, 1, 1, 0, -5690.53, -682.16, 422.798, 2.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; where the passage turns north toward the upper chamber (Questie v1.2 sighting)'),
(9008505, 162890, 0, 0, 0, 1, 1, 0, -5680, -690, 418.955, 2.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; on the ramp up into the north chamber, facing down the passage'),
(9008506, 162889, 0, 0, 0, 1, 1, 0, -5665.25, -695.45, 416.42, 2.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; by the brazier at the north end of the chamber (Questie v1.2 sighting)'),
(9008507, 162889, 0, 0, 0, 1, 1, 0, -5672, -704, 415.551, 2.9, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; open floor in the middle of the north chamber'),
(9008508, 162888, 0, 0, 0, 1, 1, 0, -5675.43, -710.72, 414.871, 2.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; south end of the north chamber (Questie v1.1 sighting)'),
(9008509, 162888, 0, 0, 0, 1, 1, 0, -5668.5, -722, 415.523, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; beside the excavation tent and its crates in the east end of the chamber'),
(9008510, 162890, 0, 0, 0, 1, 1, 0, -5678, -724, 415.691, 2.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; between the excavation tent and the brazier'),
(9008511, 162889, 0, 0, 0, 1, 1, 0, -5690, -722, 412.871, 1.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; by the brazier at the top of the slope down into the main corridor'),
(9008512, 162890, 0, 0, 0, 1, 1, 0, -5710.56, -727.46, 408.861, 0.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; by the corridor brazier where the slope meets the main corridor (Questie v1.3 sighting)'),
(9008513, 162889, 0, 0, 0, 1, 1, 0, -5725, -730.41, 406.883, 0.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; main corridor, west wall (Questie v1.2 sighting)'),
(9008514, 162889, 0, 0, 0, 1, 1, 0, -5732, -742, 407.188, 0.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; before the ruined excavation tent, its barrels and brazier at the south end of the corridor'),
(9008515, 162888, 0, 0, 0, 1, 1, 0, -5728.94, -751.59, 410.215, 1.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; between the ruined tent and the standing excavation tent (Questie v1.1 sighting)'),
(9008516, 162888, 0, 0, 0, 1, 1, 0, -5712, -750, 409.48, 1.8, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; open floor of the corridor bend toward the east hall'),
(9008517, 162890, 0, 0, 0, 1, 1, 0, -5702, -756, 410.314, 2.2, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; level floor between the corridor bend and the brazier'),
(9008518, 162889, 0, 0, 0, 1, 1, 0, -5692.83, -763.4, 410.294, 2.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; by the brazier of the east passage (Questie v1.2 sighting)'),
(9008519, 162889, 0, 0, 0, 1, 1, 0, -5700, -772, 409.113, 1.4, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; east passage floor, heading for the east hall'),
(9008520, 162890, 0, 0, 0, 1, 1, 0, -5711.21, -784.08, 407.714, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; north end of the east hall (Questie v1.3 sighting)'),
(9008521, 162889, 0, 0, 0, 1, 1, 0, -5720.08, -787.53, 405.931, 0.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; by the second ruined camp (tent, barrels, crate, chairs) in the east hall, a pair with the next one (Questie v1.2 sighting)'),
(9008522, 162888, 0, 0, 0, 1, 1, 0, -5724.02, -789.5, 404.825, 0.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; at the crate of the second ruined camp, the other half of the pair (Questie v1.1 sighting)'),
(9008523, 162890, 0, 0, 0, 1, 1, 0, -5716, -800, 406.577, 1.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; east hall, beside the brazier south of the ruined camp'),
(9008524, 162889, 0, 0, 0, 1, 1, 0, -5704, -800, 406.321, 1.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; east hall, north-east side'),
(9008525, 162888, 0, 0, 0, 1, 1, 0, -5708, -820, 403.094, 1.6, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; the low east end of the hall, before the exit ramp'),
(9008526, 162890, 0, 0, 0, 1, 1, 0, -5698, -848, 416.002, 1.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; on the exit ramp below the snowy rock; the Questie v1.3 sighting (-5698.08, -841.7) has no navmesh under it'),
(9008527, 162888, 0, 0, 0, 1, 1, 0, -5704, -852, 418.299, 1.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; top of the exit ramp; the Questie v1.1 sighting (-5704.97, -839.73) has no navmesh under it'),
(9008528, 162888, 0, 0, 0, 1, 1, 0, -5707.13, -680.53, 423.773, 1.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Kharanos tunnel: Out-of-Control Automaton; SOURCED-CLIENT ST8737, the 1660078 objective point in the mouth passage, between the two Questie bots at the brazier');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9008480 AND 9008799;

DELETE FROM `gameobject` WHERE `guid` IN (7914120, 7914121, 7914122, 7914123, 7914124, 7914125, 7914126, 7914127, 7914128, 7914129, 7914130, 7914131, 7914132, 7914133, 7914134, 7914135, 7914136, 7914137, 7914138, 7914139, 7914140, 7914141, 7914150, 7914151, 7914152, 7914153, 7914154, 7914155, 7914156, 7914157, 7914158, 7914159, 7914160, 7914161, 7914162, 7914163, 7914164, 7914165, 7914166, 7914167, 7914168, 7914169, 7914170, 7914171, 7914172, 7914173, 7914174, 7914175, 7914176, 7914177, 7914178, 7914179) OR `guid` BETWEEN 7914120 AND 7914299;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7914120, 2300550, 0, 0, 0, 1, 1, -5717.78, -551.67, 398.539, 0.4, 0, 0, 0.198669, 0.980067, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; Questie sighting, north rows'),
(7914121, 2300550, 0, 0, 0, 1, 1, -5701.69, -555.12, 398.542, 2.2, 0, 0, 0.891207, 0.453596, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; Questie sighting, the north tip of the field'),
(7914122, 2300550, 0, 0, 0, 1, 1, -5715.15, -563.98, 398.542, 1.1, 0, 0, 0.522687, 0.852525, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; Questie sighting, north-east rows'),
(7914123, 2300550, 0, 0, 0, 1, 1, -5725.99, -557.09, 398.552, 5.3, 0, 0, 0.472031, -0.881582, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; Questie sighting, middle rows'),
(7914124, 2300550, 0, 0, 0, 1, 1, -5734.19, -554.63, 398.538, 3, 0, 0, 0.997495, 0.070737, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; Questie sighting, west rows by the fence'),
(7914125, 2300550, 0, 0, 0, 1, 1, -5737.15, -568.91, 398.602, 4.2, 0, 0, 0.863209, -0.504846, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; Questie sighting, middle rows'),
(7914126, 2300550, 0, 0, 0, 1, 1, -5736.82, -579.74, 398.625, 0.9, 0, 0, 0.434966, 0.900447, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; Questie sighting, south-east rows'),
(7914127, 2300550, 0, 0, 0, 1, 1, -5728.18, -565.22, 398.562, 2.6, 0, 0, 0.963558, 0.267499, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; SuperTrack ST8735, the 1660077 objective point, between two bushes'),
(7914128, 2300550, 0, 0, 0, 1, 1, -5753.8, -578.5, 398.66, 1.7, 0, 0, 0.75128, 0.659983, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; south corner, among the four southernmost bushes'),
(7914129, 2300550, 0, 0, 0, 1, 1, -5749.3, -574.6, 398.656, 5.9, 0, 0, 0.190423, -0.981702, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; south rows, between the bush pairs'),
(7914130, 2300550, 0, 0, 0, 1, 1, -5748.9, -584, 398.637, 3.6, 0, 0, 0.973848, -0.227202, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; south-east rows, between two bushes'),
(7914131, 2300550, 0, 0, 0, 1, 1, -5745.2, -565.8, 398.615, 0.2, 0, 0, 0.099833, 0.995004, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; south-west rows, between three bushes'),
(7914132, 2300550, 0, 0, 0, 1, 1, -5739.5, -589, 398.601, 4.8, 0, 0, 0.675463, -0.737394, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; east corner rows'),
(7914133, 2300550, 0, 0, 0, 1, 1, -5732, -584, 398.607, 2.9, 0, 0, 0.992713, 0.120503, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; east rows, in the gap of three bushes'),
(7914134, 2300550, 0, 0, 0, 1, 1, -5731, -573.3, 398.568, 1.4, 0, 0, 0.644218, 0.764842, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; middle rows, between two bushes'),
(7914135, 2300550, 0, 0, 0, 1, 1, -5724.6, -575.2, 398.56, 5, 0, 0, 0.598472, -0.801144, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; north-east rows, in the gap of three bushes'),
(7914136, 2300550, 0, 0, 0, 1, 1, -5722.8, -546.9, 398.53, 2.4, 0, 0, 0.932039, 0.362358, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; west rows toward the west corner'),
(7914137, 2300550, 0, 0, 0, 1, 1, -5716, -540.2, 398.55, 3.9, 0, 0, 0.92896, -0.370181, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; west corner, between three bushes'),
(7914138, 2300550, 0, 0, 0, 1, 1, -5710.4, -551.3, 398.534, 0.7, 0, 0, 0.342898, 0.939373, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; north rows, between two bushes'),
(7914139, 2300550, 0, 0, 0, 1, 1, -5720.9, -569.8, 398.554, 4.4, 0, 0, 0.808496, -0.588501, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; north-east rows, between three bushes'),
(7914140, 2300550, 0, 0, 0, 1, 1, -5738.5, -560, 398.552, 1.9, 0, 0, 0.813416, 0.581683, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; west rows, between two bushes'),
(7914141, 2300550, 0, 0, 0, 1, 1, -5720.5, -559.8, 398.545, 5.6, 0, 0, 0.334988, -0.942222, 60, 100, 1, '', 'CoA Kharanos hop field: Thunderbrew Hop; middle rows, between two bushes'),
(7914150, 2300580, 0, 0, 0, 1, 1, -5734.5, -1188.5, 379.316, 0.3, 0, 0, 0.149438, 0.988771, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, beside the small snow pines of the Questie sighting'),
(7914151, 2300580, 0, 0, 0, 1, 1, -5725.5, -1186, 380.563, 2, 0, 0, 0.841471, 0.540302, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, beside the axe-cut stump'),
(7914152, 2300580, 0, 0, 0, 1, 1, -5721, -1196.5, 382.071, 4.1, 0, 0, 0.887362, -0.461073, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, south of the stump and the old snow tree'),
(7914153, 2300580, 0, 0, 0, 1, 1, -5736, -1201, 382.593, 5.5, 0, 0, 0.381661, -0.924302, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, on the slope below the big snow pine'),
(7914154, 2300580, 0, 0, 0, 1, 1, -5681, -1206, 387.234, 1.2, 0, 0, 0.564642, 0.825336, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-east grove of the cut stumps, its edge inside the circle'),
(7914155, 2300580, 0, 0, 0, 1, 1, -5700.5, -1246, 389.695, 3.3, 0, 0, 0.996865, -0.079121, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; east grove, beside the small snow pines of the Questie sighting'),
(7914156, 2300580, 0, 0, 0, 1, 1, -5700, -1264, 389.949, 0.8, 0, 0, 0.389418, 0.921061, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; east grove, south of the old broadleaf'),
(7914157, 2300580, 0, 0, 0, 1, 1, -5689, -1248, 389.211, 2.7, 0, 0, 0.975723, 0.219007, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; east grove, among its tall snow trees'),
(7914158, 2300580, 0, 0, 0, 1, 1, -5705, -1256, 390.25, 4.6, 0, 0, 0.745705, -0.666276, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; west edge of the east grove'),
(7914159, 2300580, 0, 0, 0, 1, 1, -5671, -1252, 389.657, 1.9, 0, 0, 0.813416, 0.581683, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south-east grove, beside the mid snow tree'),
(7914160, 2300580, 0, 0, 0, 1, 1, -5674, -1268, 389.984, 5.1, 0, 0, 0.557684, -0.830054, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south-east grove, by the snow pine'),
(7914161, 2300580, 0, 0, 0, 1, 1, -5677, -1258, 389.609, 0.5, 0, 0, 0.247404, 0.968912, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south-east grove, between its snow trees'),
(7914162, 2300580, 0, 0, 0, 1, 1, -5752, -1212, 388.42, 3.7, 0, 0, 0.961275, -0.27559, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; the rise north of the camp, above the copper vein'),
(7914163, 2300580, 0, 0, 0, 1, 1, -5737, -1227, 383.141, 2.2, 0, 0, 0.891207, 0.453596, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north of the camp, beside the big mid snow tree'),
(7914164, 2300580, 0, 0, 0, 1, 1, -5765, -1230, 378.86, 6, 0, 0, 0.14112, -0.989992, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north of the camp, by the small snow pines'),
(7914165, 2300580, 0, 0, 0, 1, 1, -5795, -1193, 377.073, 1, 0, 0, 0.479426, 0.877583, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, by the small snow pines of the Questie sighting'),
(7914166, 2300580, 0, 0, 0, 1, 1, -5786.5, -1198.5, 375.915, 3.9, 0, 0, 0.92896, -0.370181, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, between its tall snow trees'),
(7914167, 2300580, 0, 0, 0, 1, 1, -5779.5, -1188, 378.227, 2.5, 0, 0, 0.948985, 0.315322, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, east edge'),
(7914168, 2300580, 0, 0, 0, 1, 1, -5796, -1212.5, 376.729, 4.9, 0, 0, 0.637765, -0.770231, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, south edge by the snow pine'),
(7914169, 2300580, 0, 0, 0, 1, 1, -5757, -1178.5, 376.563, 0.6, 0, 0, 0.29552, 0.955336, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north grove, by the old broadleaf'),
(7914170, 2300580, 0, 0, 0, 1, 1, -5767, -1190, 380.102, 3.1, 0, 0, 0.999784, 0.020795, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north grove, on the slope between its trees'),
(7914171, 2300580, 0, 0, 0, 1, 1, -5748, -1187, 380.44, 5.8, 0, 0, 0.239249, -0.970958, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north grove, by the snow pine'),
(7914172, 2300580, 0, 0, 0, 1, 1, -5745, -1294, 387.64, 1.6, 0, 0, 0.717356, 0.696707, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south of the camp, by the small snow pine of the Questie sighting'),
(7914173, 2300580, 0, 0, 0, 1, 1, -5755, -1300, 388.499, 4.3, 0, 0, 0.836899, -0.547358, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south of the camp, beyond the snow pines'),
(7914174, 2300580, 0, 0, 0, 1, 1, -5745, -1321, 391.261, 2.8, 0, 0, 0.98545, 0.169967, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south grove, beside the small snow pines of the Questie sighting'),
(7914175, 2300580, 0, 0, 0, 1, 1, -5758, -1318, 389.826, 0.1, 0, 0, 0.049979, 0.99875, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south grove, between the snow pine and the broadleaf'),
(7914176, 2300580, 0, 0, 0, 1, 1, -5767, -1314, 388.54, 5.3, 0, 0, 0.472031, -0.881582, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south grove, west edge toward the two-storey house'),
(7914177, 2300580, 0, 0, 0, 1, 1, -5716, -1226, 387.893, 3.5, 0, 0, 0.983986, -0.178246, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; a lone young tree on the open slope between the camp and the east grove'),
(7914178, 2300580, 0, 0, 0, 1, 1, -5712, -1276, 390.218, 1.3, 0, 0, 0.605186, 0.796084, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; a lone young tree on the open slope south-east of the camp'),
(7914179, 2300580, 0, 0, 0, 1, 1, -5728, -1312, 392.011, 4, 0, 0, 0.909297, -0.416147, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; a young tree on the slope east of the south grove');

-- ---------------------------------------------------------------------------
-- 6. Scripts
-- ---------------------------------------------------------------------------
-- The hop gives its item only while 1660077 is taken. Nonuid credits the shared marker 162921; the Target
-- credits itself on each Blunderbuss hit.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (162901, 162917) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162901, 0, 0, 1, 62, 0, 100, 0, 932242, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - On Gossip Option 0 Selected - Close Gossip'),
(162901, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Quest Credit Listen to Gravedigger Nonuid'),
(162917, 0, 0, 0, 8, 0, 100, 0, 267024, 0, 0, 0, 0, 0, 33, 162917, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Target - On Spellhit Shoot target - Quest Credit Target hit');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300550 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300550, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 56, 558964, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thunderbrew Hop - On Use - Give the user a Thunderbrew Hop'),
(2300550, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Thunderbrew Hop - Linked - Despawn until it respawns');

DELETE FROM `conditions` WHERE `SourceEntry` = 2300550 AND `SourceTypeOrReferenceId` = 22 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 2300550, 1, 0, 9, 0, 1660077, 0, 0, 0, 0, 0, '', 'Thunderbrew Hop - give the hop only while Thunderbrew''s Hop is taken');

-- ---------------------------------------------------------------------------
-- 7. Yori Crackhelm (stock 348) to the Thunderbrew inn
-- ---------------------------------------------------------------------------
-- To the 5841 turn-in point ST1715 on the inn's upper floor (DESIGN); facing kept.
UPDATE `creature` SET `position_x` = -5592.95, `position_y` = -529.919, `position_z` = 399.652, `orientation` = 0.925025 WHERE `guid` = 348 AND `id` = 11941;
