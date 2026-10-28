-- CoA Coldridge Valley storyline: Groldha's search for her son through the Crash Site, the hidden path,
-- Runestone Forest and Radiance Town (quests 1660006-1660011 and 1660039), and the Radiant One Disguise.
-- Creature guids 9008000-9008399, gameobject guids 7914000-7914099, gossip menus 932200-932229.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stand-in displays where the CoA model is missing from the client. Never spawned: the kill-credit
-- markers 161721, 161722, 161902 and the disguise looks 161778-161781.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(161718, 'Groldha', NULL, 0, 8, 8, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(161719, 'Dead Crewman', NULL, 0, 9, 9, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(161720, 'Arathror', 'Anvilmar Mountaineer', 932200, 20, 20, 0, 35, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 161722, ''),
(161820, 'Redna', 'Radiance Town Exile', 932201, 8, 8, 0, 35, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(161839, 'Lahud', NULL, 0, 3, 3, 0, 1374, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 256, 2048, 7, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 2, 0, ''),
(161772, 'Radiant Fanatic', NULL, 0, 3, 3, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 161772, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161773, 'Radiant Guard', NULL, 0, 5, 6, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161786, 'Radiant Devotee', NULL, 0, 3, 3, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161775, 'His Radiant Majesty', NULL, 0, 7, 7, 0, 14, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 2.4, 1, 1, 1, 1, 0, 0, ''),
(161835, 'Right Hand of His Majesty', NULL, 0, 4, 4, 0, 14, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 9, 0, 0, 'SmartAI', 0, 2.79, 1, 1, 1, 1, 0, 0, ''),
(161776, 'Radiant Slime', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 4, 0, 0, 'SmartAI', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161721, '[KC] Hidden path tread', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161722, '[KC] Ask Arathror to help you put on the disguise', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161902, '[KC] Radiant Devotees doused', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161778, 'Radiant One', NULL, 0, 1, 1, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161779, 'Radiant One', NULL, 0, 1, 1, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161780, 'Radiant One', NULL, 0, 1, 1, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161781, 'Radiant One', NULL, 0, 1, 1, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161718, 161719, 161720, 161721, 161722, 161772, 161773, 161775, 161776, 161778, 161779, 161780, 161781, 161786, 161820, 161835, 161839, 161902);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(161718, 0, 1651, 1, 1),
(161719, 0, 7109, 1, 1),
(161720, 0, 1779, 1, 1),
(161820, 0, 3766, 1, 1),
(161839, 0, 141114, 1, 1),
(161772, 0, 3785, 1, 1),
(161772, 1, 3786, 1, 1),
(161772, 2, 6932, 1, 1),
(161772, 3, 6976, 1, 1),
(161773, 0, 1598, 1, 1),
(161773, 1, 1608, 1, 1),
(161773, 2, 6981, 1, 1),
(161773, 3, 6982, 1, 1),
(161786, 0, 3765, 1, 1),
(161786, 1, 3766, 1, 1),
(161786, 2, 6921, 1, 1),
(161786, 3, 6975, 1, 1),
(161775, 0, 6936, 1.25, 1),
(161835, 0, 6915, 1, 1),
(161776, 0, 33054, 1, 1),
(161721, 0, 11686, 1, 1),
(161722, 0, 11686, 1, 1),
(161902, 0, 11686, 1, 1),
(161778, 0, 3765, 1, 1),
(161779, 0, 3766, 1, 1),
(161780, 0, 6975, 1, 1),
(161781, 0, 6921, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (161718, 161719, 161720, 161721, 161722, 161772, 161773, 161775, 161776, 161778, 161779, 161780, 161781, 161786, 161820, 161835, 161839, 161902);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(161720, 1, 2023, 0, 2552);

-- The Dead Crewman lies dead (stand state 7) and still gives his quest.
DELETE FROM `creature_template_addon` WHERE `entry` = 161719;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(161719, 0, 0, 7, 0, 0, 0, NULL);

-- CoA displays 141114 (Lahud) and 33054 (Radiant Slime) lack model info; values of stock displays of the
-- same models.
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (33054, 141114);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(141114, 0.3519, 1.725, 0, 0),
(33054, 0.599, 1.25, 2, 0);

-- The cache lists each quest item in the creature query (questItem1).
DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (161772, 161776);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(161772, 0, 559142),
(161776, 0, 559162);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
-- Cached npc_text greetings; option texts INFERRED. Each of Arathror's three greetings is gated.
DELETE FROM `npc_text` WHERE `ID` IN (62611, 62615, 62618, 62701, 62708, 62709);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(62611, 'We’ve got everything we need for the disguise. Are things ready on your end?', 'We’ve got everything we need for the disguise. Are things ready on your end?', 0, 0, 1),
(62615, 'Everything is in place. Once you are ready, I will see to your disguise myself.', 'Everything is in place. Once you are ready, I will see to your disguise myself.', 0, 0, 1),
(62618, '<The mountaineer’s focus lingers down the sight of his rifle, unwavering. The rigid mask of seriousness, coupled with the measured calm of his movements, marks him as a true professional of his craft.>', '<The mountaineer’s focus lingers down the sight of his rifle, unwavering. The rigid mask of seriousness, coupled with the measured calm of his movements, marks him as a true professional of his craft.>', 0, 0, 1),
(62701, '<The dwarf breathes so heavily that the vapor from her mouth almost hides her entirely. A closer look reveals skin pocked with pustules and green blotches, her thinning hair marred by bald patches and raw, inflamed streaks.>$b$bWhat? Lost something up here?', '<The dwarf breathes so heavily that the vapor from her mouth almost hides her entirely. A closer look reveals skin pocked with pustules and green blotches, her thinning hair marred by bald patches and raw, inflamed streaks.>$b$bWhat? Lost something up here?', 0, 0, 1),
(62708, 'The same story as everywhere else. Nothing original about it.$b$bSome silver-tongued zealot gathers a crowd of the gullible and sells them an idea so mad it has to be true. Of course, there’s always a grain of truth in every lie. And the radiation… I don’t know how it works. I’m still trying to puzzle it out. But somehow, inexplicably, it brings change; physical change, mutations. It drives some to madness, yes, but others… it gives them a kind of fevered clarity. Brilliance, as they’d call it.', 'The same story as everywhere else. Nothing original about it.$b$bSome silver-tongued zealot gathers a crowd of the gullible and sells them an idea so mad it has to be true. Of course, there’s always a grain of truth in every lie. And the radiation… I don’t know how it works. I’m still trying to puzzle it out. But somehow, inexplicably, it brings change; physical change, mutations. It drives some to madness, yes, but others… it gives them a kind of fevered clarity. Brilliance, as they’d call it.', 0, 0, 1),
(62709, '<Redna looks away, fists tightening.>$b$bI came to Radiance Town with my son. He was just a boy.$b$b<Her voice falters, threatening to break.>$b$bBut cultists weren’t the only ones living in Radiance Town for long. Day by day, the number of radiant slimes grew. They were rarely hostile, but one of them… swallowed him whole. My son drowned in its gelatinous guts.$b$bI wept <as she weeps now, a stream of tears seeping past her green-lensed goggles>. I screamed <as she screams now, her voice torn and raw>. I stamped my feet and demanded justice. I looked for someone to blame. But no one seeks blame in Radiance Town. And least of all would they ever blame their leader.$b$bSo they cast me out.$b$b', '<Redna looks away, fists tightening.>$b$bI came to Radiance Town with my son. He was just a boy.$b$b<Her voice falters, threatening to break.>$b$bBut cultists weren’t the only ones living in Radiance Town for long. Day by day, the number of radiant slimes grew. They were rarely hostile, but one of them… swallowed him whole. My son drowned in its gelatinous guts.$b$bI wept <as she weeps now, a stream of tears seeping past her green-lensed goggles>. I screamed <as she screams now, her voice torn and raw>. I stamped my feet and demanded justice. I looked for someone to blame. But no one seeks blame in Radiance Town. And least of all would they ever blame their leader.$b$bSo they cast me out.$b$b', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932200, 932201, 932202, 932203);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932200, 62611),
(932200, 62615),
(932200, 62618),
(932201, 62701),
(932202, 62708),
(932203, 62709);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932200, 932201, 932202, 932203);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932200, 0, 0, 'I''m ready. Help me into the disguise.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932201, 0, 0, 'What happened in Radiance Town?', 0, 1, 1, 932202, 0, 0, 0, '', 0),
(932201, 1, 0, 'Why did you leave the town?', 0, 1, 1, 932203, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (932200, 932201, 932202, 932203) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 932200, 62618, 0, 0, 8, 0, 1660008, 0, 0, 1, 0, 0, '', 'Arathror greeting 62618 until A Fitting Disguise is rewarded'),
(14, 932200, 62611, 0, 0, 8, 0, 1660008, 0, 0, 0, 0, 0, '', 'Arathror greeting 62611 once A Fitting Disguise is rewarded'),
(14, 932200, 62615, 0, 0, 9, 0, 1660009, 0, 0, 0, 0, 0, '', 'Arathror greeting 62615 while His Radiant Majesty is taken'),
(15, 932200, 0, 0, 0, 8, 0, 1660008, 0, 0, 0, 0, 0, '', 'Disguise option: A Fitting Disguise rewarded'),
(15, 932200, 0, 0, 0, 1, 0, 256703, 0, 0, 1, 0, 0, '', 'Disguise option: not already wearing 256703'),
(15, 932200, 0, 0, 0, 1, 0, 256704, 0, 0, 1, 0, 0, '', 'Disguise option: not already wearing 256704'),
(15, 932200, 0, 0, 0, 1, 0, 256705, 0, 0, 1, 0, 0, '', 'Disguise option: not already wearing 256705'),
(15, 932200, 0, 0, 0, 1, 0, 256706, 0, 0, 1, 0, 0, '', 'Disguise option: not already wearing 256706'),
(15, 932200, 0, 0, 1, 9, 0, 1660009, 0, 0, 0, 0, 0, '', 'Disguise option: or His Radiant Majesty taken (its credit)');

-- ---------------------------------------------------------------------------
-- 3. World objects, pages and loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300506, 6, 300360, 'Proximity Bomb', '', 0.5, '', 0, 3, 2, 256480, 1, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300507, 10, 1010749, 'Plating', 'Investigating', 1, '', 93, 1660006, 0, 0, 0, 0, 0, 50014, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300508, 10, 1020313, 'Crate', 'Investigating', 1, '', 93, 1660006, 0, 0, 0, 0, 0, 50015, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300509, 10, 1024060, 'Crystal Shards', 'Investigating', 1, '', 93, 1660006, 0, 0, 0, 0, 0, 50016, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300510, 10, 7153, 'Banner', 'Investigating', 1, '', 93, 1660006, 0, 0, 0, 0, 0, 50017, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300525, 5, 7334, 'Baby', '', 1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300539, 7, 138, 'Short Wooden Seat', '', 1, '', 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

-- The notes on the wreck pieces (pagetextcache).
DELETE FROM `page_text` WHERE `ID` IN (50014, 50015, 50016, 50017);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(50014, '<Charred plating, still smoldering. A half-burned goblin note reads: “Turn left. We’ll land soft.”>', 0),
(50015, '<A crate, its contents scattered across the ground. Scribbled on the lid: “For the cult nutjobs. DO NOT drop.”>', 0),
(50016, '<Shards of bottles that once held some kind of liquid. Hanging from a strap is a note: “To our glorious new partners in crime!”>', 0),
(50017, '<A scorched banner meant as a gift to the cultists. Only two words remain legible: “Profit” and “Eternal.”>', 0);

-- Radiant Armor Piece from the fanatics: 75 % (INFERRED). The mutagen comes from the Extractor.
DELETE FROM `creature_loot_template` WHERE `Entry` = 161772;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(161772, 559142, 0, 75, 1, 1, 0, 1, 1, 'Radiant Fanatic - Radiant Armor Piece');

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- Chain 1660006 -> 1660007 -> 1660008 -> {1660009, 1660039, 1660010}; 1660011 stands alone.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660006, 2, 6, 3, 132, 0, 0, 0, 0, 0, 0, 1660007, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 5571, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Smoke on the Wind', 'Follow in the footsteps of Grelbin, son of Groldha, and investigate the source of the smoke.', 'Ah, a traveler! One look at your garb and I knew you’d come from afar.$b$bCome closer, look. This newborn of mine suffers from an illness no healer has managed to cure. He has little time left. But his older brother refuses to accept that.$b$bSomewhere along the way, he heard whispers of a “congregation” claiming to have a cure for all ailments. Grelbin clung to that hope like a drowning man to driftwood, and left to find them.$b$bThat was two weeks ago. He hasn’t returned yet, and worse, the wind now carries an ugly black smoke from the direction I last saw him go. I fear the worst.$b$bPlease… follow in his footsteps, and bring him back to me. The gods have already judged that I must give up one son. I won’t lose them both.', '', 'Inspect the corpse of the dead crewman.', -2300507, -2300508, -2300509, -2300510, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Plating examined', 'Crate examined', 'Crystal shards examined', 'Banner examined'),
(1660007, 2, -1, 3, 132, 0, 0, 0, 0, 0, 0, 1660008, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Promising Path', 'Follow the mountain path to uncover the location of the mysterious group.', '<Before looting the body, you reason that the goblin won’t be missing the papers in his pocket.>$b$b<Thumbing through them, you piece together that the goblin was part of a crew sent to locate a mysterious group of ascetics in the Coldridge Mountains; the very same group Grelbin, Groldha’s son, went searching for.>$b$b<Among the papers, you find a map marking a path up the mountain to the ascetics’ hidden domain.>', '', 'Speak with the mountaineer.', 161721, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Hidden path tread', '', '', ''),
(1660008, 2, -1, 3, 132, 0, 0, 0, 0, 0, 0, 1660009, 6, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Fitting Disguise', 'Slay Radiant fanatics and collect their armor pieces. Deliver them to Arathror so he can craft a disguise.', 'Up ahead are the gates to Radiance Town, a rat’s nest of that sect’s rabble. They call themselves “The Radiants.” I’ve been keeping watch on them for a month now.$b$bThey believe bathing in the same radiation that devastated Gnomeregan will grant them some kind of revelation, or Light knows what.$b$bThey’re dangerous; heretics as well as rebels. Their leader’s crowned himself king, if you can believe it. And I have orders to see him executed.$b$bNow that you’re here… a plan comes to mind.$b$bFollow the road, scout the forest ahead, and cut down a few of those zealots. Bring me back some pieces of their armor. I’ve got an idea… you’ll see!', '', 'Return to Arathror.', 0, 0, 0, 0, 0, 0, 0, 0, 559142, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, '', '', '', ''),
(1660009, 2, 6, 3, 132, 0, 2, 0, 0, 0, 0, 0, 7, 35, 0, 0, 0, 0, 0, 0, 8, 0, 559182, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'His Radiant Majesty', 'Tell Arathror when you’re ready to don the disguise. Then infiltrate Radiance Town and slay the cult leader, His Radiant Majesty.', 'I’ve had too many run-ins with the Radiant; they’d spot me in a heartbeat. You, though… you’re new. An unknown face.$b$bAye, I think this disguise will pass. Let me know when you’re ready and I’ll help you into it. No, not like that, don’t be daft.$b$bOnce you’re disguised, keep your head down. Cross the village to the far side without drawing attention, and find their so-called king. Most cults fall apart without a strong leader.$b$bIf this is one of them, you might just be in time to save Groldha’s son from losing his mind.', '', 'Return to Anvilmar and tell Groldha what you learned about her son and the sect.', 161722, 161775, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ask Arathror to help you put on the disguise', 'His Radiant Majesty slain', '', ''),
(1660039, 2, -1, 3, 132, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 559176, 1, 559177, 1, 559178, 1, 559185, 1, 559186, 1, 559181, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sever the Right Hand', 'Defeat Right Hand of His Majesty in Radiance Town.', 'Have you run into the exile, Redna?$bShe pitched her camp on the hill just above us.$b$bLast time I spoke with her, she said something I haven’t been able to shake off:$b“The only one who’ll defend a lie fiercer than the liar is the fool who believed it.”$b$bThe one they call “The Right Hand of His Majesty” is living proof of that. He’s no ordinary follower; Redna swears he’s crueler, more despotic, and more fanatical than his master.$b$bIf you’ve the steel for it, cut him down while you’re making your way through Radiance Town. Then, report to Redna. She and him had… unfinished business.', '', 'Return to Redna.', 161835, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660010, 2, 6, 3, 132, 0, 0, 0, 0, 0, 0, 0, 5, 25, 0, 0, 0, 0, 0, 559161, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Deciphering Radiation', 'Slay radioactive slimes in Radiance Town and use the Contamination Extractor on their corpses to harvest mutagen.', 'If you can sneak your way into Radiance Town… there’s something I could use your help with.$b$bI’ve been trying to understand how radiation works, looking for a way to counter its effects. For that purpose… I built this:$b$b<Redna shows you a contraption that only vaguely resembles a rifle.>$b$bKill a few radioactive slimes, then pull the trigger on this beauty. It’ll siphon the essence out of the slime and, with luck, let me isolate the mutagen.', '', 'Bring the harvested mutagens to Redna.', 0, 0, 0, 0, 0, 0, 0, 0, 559162, 559161, 0, 0, 0, 0, 5, 1, 0, 0, 0, 0, '', '', '', ''),
(1660011, 2, 6, 3, 132, 0, 0, 0, 0, 0, 0, 0, 4, 15, 0, 0, 0, 0, 0, 559163, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Soaking the Masses', 'Use the Radiation Sprayer to douse Radiaville’s townsfolk with radiation.', 'New around here?$b$bForgive me; might be I’ve run into you before, but my memory… it flickers, in and out, like a dying bulb.$b$bFriend or stranger, I could use your help. <Lahud stifles a guilty little giggle, clearly embarrassed.> Don’t think I’m trying to weasel out of my duty; I meant to do it, truly! But then I got woozy…$b$b<The gnome swallows back a burp and jerks upright, twitching as if he’d grabbed a live wire.>$b$bAll you need to do is spray a bit of blessed radiation on some of the townsfolk. You know, their weekly dose. Do this for me and I’ll be forever in your debt!', '', 'Speak with Lahud.', 161902, 0, 0, 0, 5, 0, 0, 0, 559163, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Radiant Devotees doused', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660006, 1660007, 1660008, 1660009, 1660010, 1660011, 1660039);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660006, 0, 0, 0, 0, 0),
(1660007, 0, 0, 1660006, 0, 0),
(1660008, 0, 0, 1660007, 0, 0),
(1660009, 0, 0, 1660008, 0, 0),
(1660039, 0, 0, 1660008, 0, 0),
(1660010, 0, 0, 1660008, 1, 0),
(1660011, 0, 0, 0, 1, 0);

-- Progress and completion texts from the AscensionES archive (pEN / cEN).
DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660006, 1660007, 1660008, 1660009, 1660010, 1660011, 1660039);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660006, '<The goblin had crawled from the wreckage of the rocket as far as he could before his strength gave out and his final, rattling breath escaped his scorched throat.>$B$B<Though the crash had reduced his legs to bloody pulp, a wad of papers still juts from the pocket of his scorched, threadbare trousers.>'),
(1660007, 'By my beard…! I nearly put a bullet through you. Nearly scared the life out of me.$B$BHere, have a seat. <The dwarf gestures warmly toward a stool, the only warmth you’ll find in this frozen wasteland.>$B$BLooking for Groldha’s boy, are you? Poor woman. He’s the latest recruit to join those lunatics’ ranks.'),
(1660008, 'Aye, this’ll do…$B$BNot quite your size, mind, but it’ll fit you better than me. My nose alone wouldn’t fit in a helmet that small.'),
(1660009, 'You’re back! I wanted to tell you, but didn’t know where to find you: Grelbin returned not long after you left. And you won’t believe it… he brought that “miracle cure” he’d heard about.$B$BI can’t yet say it’s improved the little one’s health, but the risk was worth it.$B$BIt’s a shame Grelbin isn’t here now; nothing would make me prouder than to introduce you. That son of mine… strong, brave, and stubborn as his father was.$B$BHe’s gone back to the congregation. Says he’s made great friends among those scholars. Perhaps, if you’re still in Anvilmar when he returns, you’ll meet him yourself…'),
(1660039, '<The dwarf listens closely, barely able to contain a toothless grin.>$B$BDid you kill that bastard?$B$B<Her leprous face lights up.>$B$BYou gave him what he had coming. In return, I’ll give you what you deserve: a reward worthy of the satisfaction you’ve given me.'),
(1660010, 'It worked. Interesting. To be honest, I wasn’t entirely sure it wouldn’t blow up in your hands.$B$B<Redna scratches at her scalp, patchy with bald spots, using fingers stripped of nails by radiation. Then she adjusts her emerald-green goggles, which give her the uncanny look of a chameleon.>$B$BIt’ll take me some time to analyze the samples with the crude tools I’ve got here. But I will get to the bottom of this. And when I do, I’ll take a pickaxe and dig even deeper.$B$BI’ll find a cure.'),
(1660011, '<The fits have grown worse. The gnome can barely keep one eye half open.>$B$BYou’re done? Splendid…$B$B<A string of bile hangs from his mouth. He’s been vomiting in your absence.>$B$BEver since I joined this lot… the sickness has only deepened. It doesn’t make any sense… does it?');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660006, 1660007, 1660008, 1660009, 1660010, 1660011, 1660039);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660006, '<The goblin is, beyond any doubt, irreversibly dead.>'),
(1660007, 'And just who in blazes are you?'),
(1660008, 'Warmed up yet? Nothing like a good brawl to survive the mountain cold!'),
(1660009, 'Back in Anvilmar? And without my son… I take it you didn’t find him. Oh, woe is me!'),
(1660039, 'Did you kill him? Is he still breathing? Make sure he suffers!'),
(1660010, 'With those mutagen samples, I’ll be one step closer to unraveling the mystery of radiation.'),
(1660011, 'You’re… done…?');

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660006, 1660007, 1660008, 1660009, 1660010, 1660011, 1660039);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(161718, 1660006),
(161719, 1660007),
(161720, 1660008),
(161720, 1660009),
(161820, 1660010),
(161839, 1660011),
(161720, 1660039);

DELETE FROM `creature_questender` WHERE `quest` IN (1660006, 1660007, 1660008, 1660009, 1660010, 1660011, 1660039);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(161719, 1660006),
(161720, 1660007),
(161720, 1660008),
(161718, 1660009),
(161820, 1660010),
(161839, 1660011),
(161820, 1660039);

-- ---------------------------------------------------------------------------
-- 5. The hidden path trigger
-- ---------------------------------------------------------------------------
-- AreaTrigger.dbc 6137 = SuperTrack 8662, the 1660007 objective at the top of the hidden path.
DELETE FROM `areatrigger` WHERE `entry` = 6137;
INSERT INTO `areatrigger` (`entry`, `map`, `x`, `y`, `z`, `radius`, `length`, `width`, `height`, `orientation`)
VALUES
(6137, 0, -6034.8, 698.825, 486.014, 0, 17, 5, 5, 0);

DELETE FROM `areatrigger_scripts` WHERE `entry` = 6137;
INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`)
VALUES
(6137, 'SmartTrigger');

-- ---------------------------------------------------------------------------
-- 6. The Radiant One Disguise
-- ---------------------------------------------------------------------------
-- Worn only in Runestone Forest and Radiance Town; leaving or death removes it (DESIGN).
DELETE FROM `spell_area` WHERE `spell` IN (256703, 256704, 256705, 256706);
INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_start_status`, `quest_end_status`, `quest_end`, `aura_spell`, `racemask`, `gender`, `autocast`)
VALUES
(256703, 10202, 0, 64, 11, 0, 0, 0, 2, 0),
(256703, 10203, 0, 64, 11, 0, 0, 0, 2, 0),
(256704, 10202, 0, 64, 11, 0, 0, 0, 2, 0),
(256704, 10203, 0, 64, 11, 0, 0, 0, 2, 0),
(256705, 10202, 0, 64, 11, 0, 0, 0, 2, 0),
(256705, 10203, 0, 64, 11, 0, 0, 0, 2, 0),
(256706, 10202, 0, 64, 11, 0, 0, 0, 2, 0),
(256706, 10203, 0, 64, 11, 0, 0, 0, 2, 0);

-- Arathror dresses the player: gnomes get the gnome look of their gender, others the dwarf look.
DELETE FROM `conditions` WHERE `SourceEntry` = 161720 AND `SourceTypeOrReferenceId` = 22 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 3, 161720, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, '', 'Arathror disguise row 2: men of every race but gnomes'),
(22, 3, 161720, 0, 0, 16, 0, 64, 0, 0, 1, 0, 0, '', 'Arathror disguise row 2: men of every race but gnomes'),
(22, 4, 161720, 0, 0, 20, 0, 1, 0, 0, 0, 0, 0, '', 'Arathror disguise row 3: women of every race but gnomes'),
(22, 4, 161720, 0, 0, 16, 0, 64, 0, 0, 1, 0, 0, '', 'Arathror disguise row 3: women of every race but gnomes'),
(22, 5, 161720, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, '', 'Arathror disguise row 4: gnome men'),
(22, 5, 161720, 0, 0, 16, 0, 64, 0, 0, 0, 0, 0, '', 'Arathror disguise row 4: gnome men'),
(22, 6, 161720, 0, 0, 20, 0, 1, 0, 0, 0, 0, 0, '', 'Arathror disguise row 5: gnome women'),
(22, 6, 161720, 0, 0, 16, 0, 64, 0, 0, 0, 0, 0, '', 'Arathror disguise row 5: gnome women');

-- ---------------------------------------------------------------------------
-- 7. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9008000, 9008001, 9008002, 9008003, 9008004, 9008005, 9008006, 9008010, 9008011, 9008012, 9008013, 9008014, 9008015, 9008016, 9008017, 9008020, 9008021, 9008022, 9008023, 9008024, 9008025, 9008026, 9008027, 9008028, 9008029, 9008030, 9008031, 9008032, 9008033, 9008034, 9008035, 9008036, 9008037, 9008038, 9008039, 9008040, 9008041, 9008042, 9008043, 9008060, 9008061, 9008062, 9008063, 9008064, 9008065, 9008066, 9008067, 9008068, 9008069, 9008070, 9008071, 9008072, 9008073, 9008074, 9008075, 9008076, 9008077, 9008078, 9008079, 9008100, 9008101, 9008102, 9008103, 9008104, 9008105, 9008106, 9008107, 9008108, 9008109, 9008110, 9008111, 9008112, 9008113, 9008114, 9008115, 9008116, 9008117, 9008118, 9008119, 9008120, 9008121, 9008122) OR `guid` BETWEEN 9008000 AND 9008399;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9008000, 161718, 0, 0, 0, 1, 1, 0, -6094.24, 405.02, 395.537, 4.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: SOURCED-CLIENT ST8665, the 1660006 start and 1660009 turn-in point in Anvilmar hall (Anvilmar.wmo floor 395.54), on Solm Hargrin''s retired post beside her baby; 5.2 yd from Freja Stormbelch; faces 4.02 into the hall, the way players come'),
(9008001, 161719, 0, 0, 0, 1, 1, 0, -6168.98, 771.89, 377.819, 3.94, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: SOURCED-CLIENT ST8661, the 1660006 turn-in point on the goblin Crash Site (area 10201) crater floor, 4 yd north of the rocket hull; lies dead, head toward the wreck he was thrown from'),
(9008002, 161720, 0, 0, 0, 1, 1, 1, -6010.67, 680.58, 484.997, 5.59, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: SOURCED-CLIENT ST8663, the turn-in point at Arathror''s post in Runestone Forest (area 10202) beside his gun tripod and seat; faces 5.59 north-east down the forest road toward the Radiance Town gate'),
(9008003, 161820, 0, 0, 0, 1, 1, 0, -5996.89, 752.26, 530.365, 4.52, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: SOURCED-CLIENT ST8697, the 1660010/1660039 turn-in point at her exile camp on the hill above Arathror (the ST z reads 530.41, the terrain 530.365); faces 4.52 down the hill path'),
(9008004, 161839, 0, 0, 0, 1, 1, 0, -5897.32, 498.61, 526.018, 2.05, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: SOURCED-CLIENT ST8698, the 1660011 turn-in point in Radiance Town (area 10203) by the Gnomehut table; faces 2.05 toward the devotees in the town below'),
(9008005, 161775, 0, 0, 0, 1, 1, 0, -5946.74, 440.96, 508.563, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: SOURCED-CLIENT ST8664, the 1660009 objective 2 point on the hall floor of the gear tower (Dwarven_Snowtower_Bronzebeard.wmo, 508.56) at the far end of town; faces 0.0 north toward the hall door'),
(9008006, 161835, 0, 0, 0, 1, 1, 0, -5930.44, 490.09, 508.128, 1.39, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: SOURCED-QUESTIE sighting of 161835 in the middle of Radiance Town on the path to the tower; faces 1.39 north-west toward the gate road'),
(9008010, 161773, 0, 0, 0, 1, 1, 0, -5905, 582, 496.186, 1.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; Radiance Town (area 10203): inside the gate by the gnome pipe, facing the gate'),
(9008011, 161773, 0, 0, 0, 1, 1, 0, -5914, 583.5, 495.725, 1.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; Radiance Town (area 10203): inside the gate on the other side of the road, facing the gate'),
(9008012, 161773, 0, 0, 0, 1, 1, 0, -5943.5, 445.5, 508.532, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; the gear tower hall (Dwarven_Snowtower_Bronzebeard.wmo, 508.56): at the king''s left under the lantern, facing the hall door'),
(9008013, 161773, 0, 0, 0, 1, 1, 0, -5940, 437.5, 508.563, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; the gear tower hall (Dwarven_Snowtower_Bronzebeard.wmo, 508.56): at the king''s right by the gnome machinery, facing the hall door'),
(9008014, 161773, 0, 0, 0, 1, 1, 0, -5951, 444.5, 508.554, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; the gear tower hall (Dwarven_Snowtower_Bronzebeard.wmo, 508.56): behind the king at the back of the hall, facing the door, clear of the dm-radiance-king album sightline'),
(9008015, 161773, 0, 0, 0, 1, 1, 0, -5909, 540, 501.758, 1.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; Radiance Town (area 10203): on the square by the hovel, facing the gate road'),
(9008016, 161773, 0, 0, 0, 1, 1, 0, -5938.95, 475.14, 508.601, 0.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; Radiance Town (area 10203): at the tower approach by the oil drum and steam-tank gear, on a Questie devotee sighting'),
(9008017, 161773, 0, 0, 0, 1, 1, 0, -5919, 505, 504.937, 1.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Guard; Radiance Town (area 10203): mid-town at the Kezan smokestack, 18.8 yd from the Right Hand, facing the square'),
(9008020, 161772, 0, 0, 0, 1, 1, 0, -5939.45, 644.63, 487.486, 1.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting on the road below the steel-plate barricade'),
(9008021, 161772, 0, 0, 0, 1, 1, 0, -5949.39, 654.77, 485.814, 0.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting where the road leaves the ridge from Arathror'),
(9008022, 161772, 0, 0, 0, 1, 1, 0, -5942.5, 662, 486.834, 0.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), by the snow mound and fallen branch, 13.1 yd from the Questie sighting (-5946.61, 674.4), which stands against a gun tripod'),
(9008023, 161772, 0, 0, 0, 1, 1, 0, -5933.06, 686.82, 486.015, 5.8, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting west of the tent camp'),
(9008024, 161772, 0, 0, 0, 1, 1, 0, -5926.5, 674, 487.115, 3.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), at the gun rack under the excavation pavilion of the tent camp, 8.2 yd from the Questie sighting (-5931.29, 667.31), which lies on the grain sacks'),
(9008025, 161772, 0, 0, 0, 1, 1, 0, -5915.88, 709.75, 486.192, 4.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting beside the snow-covered runestone'),
(9008026, 161772, 0, 0, 0, 1, 1, 0, -5891.5, 704, 483.565, 4.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), on the frozen shore beside the Anvilmar dock, 6.1 yd from the Questie sighting (-5896.93, 706.71), which is under the dock'),
(9008027, 161772, 0, 0, 0, 1, 1, 0, -5874.12, 703.79, 483.565, 3.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting on the shore by the powder kegs and the buried gyrocopter'),
(9008028, 161772, 0, 0, 0, 1, 1, 0, -5872.35, 711.78, 483.565, 3.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting by the frozen waterfall'),
(9008029, 161772, 0, 0, 0, 1, 1, 0, -5872.09, 663.64, 488.594, 2.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting at the gun tripod and gnome signpost, watching the road'),
(9008030, 161772, 0, 0, 0, 1, 1, 0, -5888.34, 671.74, 485.967, 1.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting among the tower rocks'),
(9008031, 161772, 0, 0, 0, 1, 1, 0, -5897, 657.5, 486.242, 2.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), by the oil drum and maintenance light, 4.1 yd from the Questie sighting (-5899.21, 660.98), which stands against the light'),
(9008032, 161772, 0, 0, 0, 1, 1, 0, -5902.74, 620.57, 490.504, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), Questie sighting at the rocket platform below the town gate, facing the gate'),
(9008033, 161772, 0, 0, 0, 1, 1, 0, -5926, 695, 486.248, 0.8, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), east side of the snow-covered runestone by the crate'),
(9008034, 161772, 0, 0, 0, 1, 1, 0, -5924, 655, 487.231, 1.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), on the road between the tent camp and the steel plates'),
(9008035, 161772, 0, 0, 0, 1, 1, 0, -5932.5, 681, 486.966, 5.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), at the powder kegs and barrels on the north side of the tent camp'),
(9008036, 161772, 0, 0, 0, 1, 1, 0, -5910, 640, 487.909, 1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), open road between the tent camp and the gate ramp'),
(9008037, 161772, 0, 0, 0, 1, 1, 0, -5895, 648, 487.481, 1.7, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), east edge of the road below the rocky rise'),
(9008038, 161772, 0, 0, 0, 1, 1, 0, -5862, 690, 483.729, 3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), north end of the forest on the frozen shore'),
(9008039, 161772, 0, 0, 0, 1, 1, 0, -5885, 718, 483.59, 3.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), shore below the frozen waterfall'),
(9008040, 161772, 0, 0, 0, 1, 1, 0, -5955, 668, 485.91, 0.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), head of the road where it climbs from Arathror''s camp, watching it'),
(9008041, 161772, 0, 0, 0, 1, 1, 0, -5906, 692, 485.689, 4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), under the snow trees in the middle of the forest'),
(9008042, 161772, 0, 0, 0, 1, 1, 0, -5920, 622, 489.166, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), at the foot of the gate ramp, facing the gate'),
(9008043, 161772, 0, 0, 0, 1, 1, 0, -5873, 685, 483.757, 3.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Fanatic; Runestone Forest road (area 10202), open shore between the gun tripod and the powder kegs'),
(9008060, 161776, 0, 0, 0, 1, 1, 0, -5895.67, 569.13, 502.387, 2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): north end by the elevator car under the excavation pavilion'),
(9008061, 161776, 0, 0, 0, 1, 1, 0, -5892.64, 564.32, 503.432, 5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): beside the parked spider tank'),
(9008062, 161776, 0, 0, 0, 1, 1, 0, -5920.09, 573.31, 501.389, 1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): by the robot arm of the two-storey house'),
(9008063, 161776, 0, 0, 0, 1, 1, 0, -5907.96, 556.47, 500.664, 3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): open ground below the two-storey house'),
(9008064, 161776, 0, 0, 0, 1, 1, 0, -5911.84, 549.12, 502.005, 4.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): between the two-storey house and the hovel'),
(9008065, 161776, 0, 0, 0, 1, 1, 0, -5916.72, 544.68, 503.216, 2.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): by the barrels of the two-storey gnome hut'),
(9008066, 161776, 0, 0, 0, 1, 1, 0, -5920, 528.72, 502.463, 0.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): among the gnome pipes at the excavation barrier'),
(9008067, 161776, 0, 0, 0, 1, 1, 0, -5927.41, 521.5, 504.87, 3.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): at the excavation barrier by the hovel'),
(9008068, 161776, 0, 0, 0, 1, 1, 0, -5916.64, 500.73, 505.983, 1.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): by the gnome screw and the Kezan smokestack'),
(9008069, 161776, 0, 0, 0, 1, 1, 0, -5931.2, 501.23, 507.771, 5.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): under the robot arm by the hovel'),
(9008070, 161776, 0, 0, 0, 1, 1, 0, -5943.41, 504.53, 512.401, 2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): on the slope below the fortress wall'),
(9008071, 161776, 0, 0, 0, 1, 1, 0, -5918.99, 467.54, 510.225, 4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): in front of the gear tower'),
(9008072, 161776, 0, 0, 0, 1, 1, 0, -5920.5, 456, 510.479, 0.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): beside the Kezan smokestack before the tower, 6.4 yd from the Questie sighting (-5917.23, 461.46) on the steep bank'),
(9008073, 161776, 0, 0, 0, 1, 1, 0, -5949, 494, 516.808, 3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): below the landing pad by the fallen tree, 9.1 yd from the Questie sighting (-5953.77, 501.74) inside the hovel eaves; stays put on the 34-degree bank'),
(9008074, 161776, 0, 0, 0, 1, 1, 0, -5972.04, 457.78, 509.893, 1, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): west of the gear tower by the snow trees'),
(9008075, 161776, 0, 0, 0, 1, 1, 0, -5971.62, 465.76, 510.569, 4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): west of the gear tower'),
(9008076, 161776, 0, 0, 0, 1, 1, 0, -5984.33, 460.57, 510.331, 2.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): by the rocks at the west end of the tower'),
(9008077, 161776, 0, 0, 0, 1, 1, 0, -5915.5, 440, 510.79, 5.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): east of the tower, 5.1 yd from the Questie sighting (-5918.57, 435.99) against the fallen tree'),
(9008078, 161776, 0, 0, 0, 1, 1, 0, -5921.27, 427.38, 506.832, 3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): by the gnome tubes at the south-east corner of the tower'),
(9008079, 161776, 0, 0, 0, 1, 1, 0, -5906.62, 424.21, 510.009, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Slime; Radiance Town (area 10203): on the bank at the far south-east of town; stays put on the 37-degree bank'),
(9008100, 161786, 0, 0, 0, 1, 1, 0, -5889.5, 553, 504.692, 4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): by the gnome tools, 2.9 yd from the Questie sighting (-5891.29, 555.33), which stands on a lunchbox'),
(9008101, 161786, 0, 0, 0, 1, 1, 0, -5913.69, 524.92, 502.122, 2, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): among the gnome pipes of the excavation'),
(9008102, 161786, 0, 0, 0, 1, 1, 0, -5913.5, 560.5, 500.346, 4.5, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): in front of the two-storey house by the barrels, 1.5 yd from the Questie sighting (-5914.95, 560.65) against its wall'),
(9008103, 161786, 0, 0, 0, 1, 1, 0, -5921.94, 565.59, 502.177, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the ground floor of the two-storey house (502.18)'),
(9008104, 161786, 0, 0, 0, 1, 1, 0, -5886, 566.5, 503.91, 3.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): beside the parked spider tank below the excavation pavilion, 7.1 yd from the Questie sighting (-5886.75, 573.57) on the elevator car'),
(9008105, 161786, 0, 0, 0, 1, 1, 0, -5896.26, 550.76, 503.463, 2.5, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): open ground by the hovel'),
(9008106, 161786, 0, 0, 0, 1, 1, 0, -5877.15, 557.23, 507.989, 3.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the east hovel floor (507.99) by the barrel at its door'),
(9008107, 161786, 0, 0, 0, 1, 1, 0, -5874.62, 552.03, 507.989, 2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): inside the east hovel on its floor (507.99); the Questie sighting'),
(9008108, 161786, 0, 0, 0, 1, 1, 0, -5893.48, 544.05, 504.116, 1.5, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): beside the hovel under the snow trees'),
(9008109, 161786, 0, 0, 0, 1, 1, 0, -5900.22, 535.18, 504.093, 0.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the floor of the hovel by the excavation (504.09)'),
(9008110, 161786, 0, 0, 0, 1, 1, 0, -5885.73, 516.56, 522.59, 4.2, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the upper terrace by the iron stump'),
(9008111, 161786, 0, 0, 0, 1, 1, 0, -5882.62, 526.19, 520.502, 3, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the upper terrace by the oil tank'),
(9008112, 161786, 0, 0, 0, 1, 1, 0, -5930.53, 510.86, 505.355, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the floor of the middle hovel (505.36)'),
(9008113, 161786, 0, 0, 0, 1, 1, 0, -5933.98, 495.15, 509.602, 5, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): open ground by the robot arm, beside the Right Hand'),
(9008114, 161786, 0, 0, 0, 1, 1, 0, -5955.2, 486.54, 522.927, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the landing pad by the bucket and barrel'),
(9008115, 161786, 0, 0, 0, 1, 1, 0, -5955, 479, 536.493, 1.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the Landingpad01 deck (536.49) under the excavation pavilion, headroom 3.6; 0.9 yd north of the Questie x/y, clear of the bucket'),
(9008116, 161786, 0, 0, 0, 1, 1, 0, -5936.17, 472.6, 508.578, 5.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): at the tower approach by the steam-tank gear and the barrel'),
(9008117, 161786, 0, 0, 0, 1, 1, 0, -5909, 519, 509.977, 0.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the Fortress02_04 deck (509.98) at the excavation barrier, 1 yd south of the parked spider tank''s box, facing the tank'),
(9008118, 161786, 0, 0, 0, 1, 1, 0, -5927, 533, 510.139, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): in the north doorway of the two-storey gnome hut on its ground floor (510.14), facing out onto the deck; the Questie sighting (-5930.7, 527.58) outside its wall has the wall and a barrel within 0.9 yd'),
(9008119, 161786, 0, 0, 0, 1, 1, 0, -5936, 540, 510.139, 0.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): at the gnome table with the tools and whistle on the ground floor of the two-storey gnome hut (510.14), facing it'),
(9008120, 161786, 0, 0, 0, 1, 1, 0, -5932.5, 537, 510.139, 5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): inside the two-storey gnome hut on its ground floor (510.14)'),
(9008121, 161786, 0, 0, 0, 1, 1, 0, -5886.24, 497.43, 529.088, 3, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the bank below Lahud'),
(9008122, 161786, 0, 0, 0, 1, 1, 0, -5887.67, 479.32, 534.506, 1.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Radiance: Radiant Devotee; Radiance Town (area 10203): on the floor of Lahud''s hut (534.51) at its gnome table');

DELETE FROM `gameobject` WHERE `guid` IN (7914000, 7914001, 7914002, 7914003, 7914004, 7914005, 7914006) OR `guid` BETWEEN 7914000 AND 7914099;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7914000, 2300525, 0, 0, 0, 1, 1, -6093.37, 404.29, 395.537, 4.02, 0, 0, 0.905091, -0.425219, 60, 100, 1, '', 'CoA Radiance: SOURCED-ATLAS sighting beside Groldha in Anvilmar hall (Anvilmar.wmo floor 395.54)'),
(7914001, 2300507, 0, 0, 0, 1, 1, -6214.3, 720.65, 386.585, 1.2, 0, 0, 0.564642, 0.825336, 30, 100, 1, '', 'CoA Radiance: SOURCED-CLIENT ST8657 objective 1 point on the goblin Crash Site (area 10201) crater floor, west rim'),
(7914002, 2300508, 0, 0, 0, 1, 1, -6197.39, 735.64, 380.246, 2.6, 0, 0, 0.963558, 0.267499, 30, 100, 1, '', 'CoA Radiance: SOURCED-CLIENT ST8658 objective 2 point on the goblin Crash Site (area 10201) crater floor; the ST z floats 0.79, so it stands on the floor below'),
(7914003, 2300509, 0, 0, 0, 1, 1, -6175.24, 744.28, 377.641, 0.4, 0, 0, 0.198669, 0.980067, 30, 100, 1, '', 'CoA Radiance: SOURCED-CLIENT ST8659 objective 3 point on the goblin Crash Site (area 10201) crater floor beside the rocket'),
(7914004, 2300510, 0, 0, 0, 1, 1, -6160.98, 753.42, 378.197, 5.1, 0, 0, 0.557684, -0.830054, 30, 100, 1, '', 'CoA Radiance: SOURCED-CLIENT ST8660 objective 4 point on the goblin Crash Site (area 10201) crater floor, east side'),
(7914005, 2300506, 0, 0, 0, 1, 1, -6207.21, 739.52, 381.196, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Radiance: SOURCED-ATLAS sighting on the goblin Crash Site (area 10201) crater floor between the plating and the crate; the atlas z sinks 0.33, so it stands on the floor'),
(7914006, 2300539, 0, 0, 0, 1, 1, -6010.39, 678.37, 484.794, 3.14, 0, 0, 1, 0.000796, 60, 100, 1, '', 'CoA Radiance: SOURCED-ATLAS sighting at Arathror''s post in Runestone Forest (area 10202), on the WestfallChair doodad of the CoA map, turned 3.14 like that doodad');

-- ---------------------------------------------------------------------------
-- 8. Scripts
-- ---------------------------------------------------------------------------
-- The Contamination Extractor (256717) works only on a dead Radiant Slime.
DELETE FROM `conditions` WHERE `SourceEntry` = 256717 AND `SourceTypeOrReferenceId` = 17;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(17, 0, 256717, 0, 0, 36, 1, 0, 0, 0, 1, 0, 0, '', 'Syphoning Mutagen: the target is dead'),
(17, 0, 256717, 0, 0, 31, 1, 3, 161776, 0, 0, 0, 0, '', 'Syphoning Mutagen: the target is a Radiant Slime');

-- "Call the cult" (DESIGN): the king and the Right Hand hand their attacker to nearby guards and
-- devotees, who take the king's faction until they evade. Areatrigger rows use source_type 2.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161720, 161773, 161775, 161776, 161786, 161835) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(161720, 0, 0, 1, 62, 0, 100, 0, 932200, 0, 0, 0, 0, 0, 33, 161722, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arathror - On Gossip Option 0 Selected - Quest Credit Ask Arathror to help you put on the disguise'),
(161720, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arathror - Linked - Close Gossip'),
(161720, 0, 2, 0, 62, 0, 100, 0, 932200, 0, 0, 0, 0, 0, 134, 256703, 34, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arathror - On Gossip Option 0 Selected - Invoker Casts Radiant One Disguise 256703'),
(161720, 0, 3, 0, 62, 0, 100, 0, 932200, 0, 0, 0, 0, 0, 134, 256704, 34, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arathror - On Gossip Option 0 Selected - Invoker Casts Radiant One Disguise 256704'),
(161720, 0, 4, 0, 62, 0, 100, 0, 932200, 0, 0, 0, 0, 0, 134, 256705, 34, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arathror - On Gossip Option 0 Selected - Invoker Casts Radiant One Disguise 256705'),
(161720, 0, 5, 0, 62, 0, 100, 0, 932200, 0, 0, 0, 0, 0, 134, 256706, 34, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arathror - On Gossip Option 0 Selected - Invoker Casts Radiant One Disguise 256706'),
(161773, 0, 0, 1, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Guard - On Data Set 1 1 - Take the king''s side'),
(161773, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Radiant Guard - Linked - Attack the king''s attacker'),
(161773, 0, 2, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Guard - On Evade - Restore the cult faction'),
(161773, 0, 3, 0, 1, 0, 100, 0, 5000, 5000, 5000, 5000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Guard - Out of Combat every 5 s - Restore the cult faction'),
(161775, 0, 0, 1, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'His Radiant Majesty - On Aggro - Store the attacker'),
(161775, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 9, 161773, 0, 40, 1, 0, 0, 0, 0, 'His Radiant Majesty - Linked - Send the attacker to the Radiant Guards within 40 yd'),
(161775, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 9, 161786, 0, 15, 1, 0, 0, 0, 0, 'His Radiant Majesty - Linked - Send the attacker to the Radiant Devotees within 15 yd'),
(161775, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 9, 161773, 0, 40, 1, 0, 0, 0, 0, 'His Radiant Majesty - Linked - Call the Radiant Guards within 40 yd'),
(161775, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 9, 161786, 0, 15, 1, 0, 0, 0, 0, 'His Radiant Majesty - Linked - Call the Radiant Devotees within 15 yd'),
(161776, 0, 0, 1, 8, 0, 100, 0, 256717, 0, 0, 0, 0, 0, 56, 559162, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Slime - On Spellhit Syphoning Mutagen - Add Radioactive Slime Mutagen to the invoker'),
(161776, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Slime - Linked - Despawn the drained corpse'),
(161786, 0, 0, 1, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Devotee - On Data Set 1 1 - Take the king''s side'),
(161786, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Radiant Devotee - Linked - Attack the king''s attacker'),
(161786, 0, 2, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Devotee - On Evade - Restore the cult faction'),
(161786, 0, 3, 0, 1, 0, 100, 0, 5000, 5000, 5000, 5000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Devotee - Out of Combat every 5 s - Restore the cult faction'),
(161786, 0, 4, 5, 8, 0, 100, 0, 256718, 0, 60000, 60000, 0, 0, 33, 161902, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Devotee - On Spellhit Dousing Radiation - Quest Credit Radiant Devotees doused'),
(161786, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Radiant Devotee - Linked - Cheer for the dose'),
(161835, 0, 0, 1, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Right Hand of His Majesty - On Aggro - Store the attacker'),
(161835, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 9, 161773, 0, 40, 1, 0, 0, 0, 0, 'Right Hand of His Majesty - Linked - Send the attacker to the Radiant Guards within 40 yd'),
(161835, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 9, 161786, 0, 15, 1, 0, 0, 0, 0, 'Right Hand of His Majesty - Linked - Send the attacker to the Radiant Devotees within 15 yd'),
(161835, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 9, 161773, 0, 40, 1, 0, 0, 0, 0, 'Right Hand of His Majesty - Linked - Call the Radiant Guards within 40 yd'),
(161835, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 9, 161786, 0, 15, 1, 0, 0, 0, 0, 'Right Hand of His Majesty - Linked - Call the Radiant Devotees within 15 yd');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 6137 AND `source_type` = 2;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(6137, 2, 0, 0, 46, 0, 100, 0, 6137, 0, 0, 0, 0, 0, 33, 161721, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Areatrigger 6137 - On Trigger - Quest Credit Hidden path tread');
