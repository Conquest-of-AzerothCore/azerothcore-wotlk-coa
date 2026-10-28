-- CoA Red Cloud Mesa storyline: Morriga Hollowhoof's revenge on Three Totems (quests 1660030-1660035 and
-- 1660043) and the Grimtotem Disguise.
-- Creature guids 9011000-9011399, gameobject guids 7916500-7916699, gossip menu 932450.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Never spawned: the kill-credit markers 161822, 161823, 161849, the disguise looks 161829/161830 and the totem spirits (summoned).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(161817, 'Redhorn', NULL, 0, 10, 10, 0, 104, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1.029, 1, 1, 1, 1, 0, 0, ''),
(161818, 'Morriga Hollowhoof', NULL, 0, 15, 15, 0, 104, 2, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1.05, 1, 1, 1, 1, 0, 0, ''),
(161819, 'Sage Nauchol', NULL, 932450, 13, 13, 0, 35, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 1.05, 1, 1, 1, 1, 0, 161823, ''),
(161840, 'Hyena Spirit', NULL, 0, 10, 10, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(161838, 'Belduna', NULL, 0, 5, 5, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(161816, 'Malgorm Hollowhoof', NULL, 0, 7, 7, 0, 16, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 4.032, 1, 1, 1, 1, 0, 0, ''),
(161834, 'Cruel Carrion Spirit', NULL, 0, 4, 4, 0, 73, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 1, 0, 0, '', 0, 2.79, 1, 1, 1, 1, 0, 0, ''),
(161809, 'Grimtotem Marauder', NULL, 0, 3, 3, 0, 16, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 161809, '', 0, 0.9765, 1, 1, 1, 1, 0, 0, ''),
(161810, 'Grimtotem Patrol', NULL, 0, 3, 3, 0, 16, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 161810, '', 0, 0.9765, 1, 1, 1, 1, 0, 0, ''),
(161811, 'Tallstrider', NULL, 0, 3, 3, 0, 189, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 161811, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161812, 'Battlefield Scavenger', NULL, 0, 4, 4, 0, 73, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161813, 'Funeral Guard', NULL, 0, 5, 5, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161814, 'Grimtotem Warrior', NULL, 0, 6, 6, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161815, 'Grimtotem Villager', NULL, 0, 5, 5, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161837, 'Grimtotem Guard', NULL, 0, 6, 6, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(161850, 'Aquiline Totem', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161851, 'Owlish Totem', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161852, 'Taurine Totem', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161822, '[KC] Hard Basin discovered', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161823, '[KC] Ask Nauchol to dress you in the disguise', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161849, '[KC] Corrupting Totem', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161829, 'Grimtotem Disguise', NULL, 0, 1, 1, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161830, 'Grimtotem Disguise', NULL, 0, 1, 1, 0, 1374, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161809, 161810, 161811, 161812, 161813, 161814, 161815, 161816, 161817, 161818, 161819, 161822, 161823, 161829, 161830, 161834, 161837, 161838, 161840, 161849, 161850, 161851, 161852);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(161817, 0, 141781, 1, 1),
(161818, 0, 141782, 1, 1),
(161819, 0, 141783, 1, 1),
(161840, 0, 2712, 1, 1),
(161838, 0, 141794, 1, 1),
(161816, 0, 141784, 1, 1),
(161834, 0, 1192, 1, 1),
(161809, 0, 141785, 1, 1),
(161809, 1, 141786, 1, 1),
(161809, 2, 141787, 1, 1),
(161809, 3, 141788, 1, 1),
(161810, 0, 141789, 1, 1),
(161810, 1, 141790, 1, 1),
(161810, 2, 141791, 1, 1),
(161810, 3, 141792, 1, 1),
(161811, 0, 178, 1, 1),
(161812, 0, 137311, 1, 1),
(161813, 0, 141793, 1, 1),
(161813, 1, 141794, 1, 1),
(161814, 0, 141795, 1, 1),
(161814, 1, 141796, 1, 1),
(161814, 2, 141797, 1, 1),
(161814, 3, 141798, 1, 1),
(161815, 0, 141799, 1, 1),
(161815, 1, 141800, 1, 1),
(161815, 2, 141801, 1, 1),
(161815, 3, 141802, 1, 1),
(161837, 0, 141797, 1, 1),
(161837, 1, 141796, 1, 1),
(161850, 0, 22633, 1, 1),
(161851, 0, 141730, 1, 1),
(161852, 0, 141804, 1, 1),
(161822, 0, 11686, 1, 1),
(161823, 0, 11686, 1, 1),
(161849, 0, 11686, 1, 1),
(161829, 0, 141795, 1, 1),
(161830, 0, 141797, 1, 1);

-- The Hyena Spirit is a ghost; the Cruel Carrion Spirit flies.
DELETE FROM `creature_template_addon` WHERE `entry` = 161840;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(161840, 0, 0, 0, 1, 0, 0, '22650');

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 161834;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`)
VALUES
(161834, 1, 0, 1, 0, 0, 0, NULL);

-- The Grimtotem tauren displays, the dream owl and the muskox lack model info; values of stock displays of
-- the same or a similar model. The vulture 137311 repeats the Teldrassil row.
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (137311, 141730, 141781, 141782, 141783, 141784, 141785, 141786, 141787, 141788, 141789, 141790, 141791, 141792, 141793, 141794, 141795, 141796, 141797, 141798, 141799, 141800, 141801, 141802, 141804);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(137311, 0.1, 1.25, 2, 0),
(141730, 0.28, 1.2, 2, 0),
(141781, 0.9747, 4.05, 0, 0),
(141782, 0.8725, 3.75, 1, 0),
(141783, 0.9747, 4.05, 0, 0),
(141784, 0.9747, 4.05, 0, 0),
(141785, 0.9747, 4.05, 0, 0),
(141786, 0.9747, 4.05, 0, 0),
(141787, 0.8725, 3.75, 1, 0),
(141788, 0.8725, 3.75, 1, 0),
(141789, 0.9747, 4.05, 0, 0),
(141790, 0.9747, 4.05, 0, 0),
(141791, 0.8725, 3.75, 1, 0),
(141792, 0.8725, 3.75, 1, 0),
(141793, 0.9747, 4.05, 0, 0),
(141794, 0.8725, 3.75, 1, 0),
(141795, 0.9747, 4.05, 0, 0),
(141796, 0.9747, 4.05, 0, 0),
(141797, 0.8725, 3.75, 1, 0),
(141798, 0.8725, 3.75, 1, 0),
(141799, 0.9747, 4.05, 0, 0),
(141800, 0.9747, 4.05, 0, 0),
(141801, 0.8725, 3.75, 1, 0),
(141802, 0.8725, 3.75, 1, 0),
(141804, 0.6111, 2.031, 2, 0);

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (161809, 161810, 161811);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(161809, 0, 559156),
(161810, 0, 559168),
(161811, 0, 559168);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
-- Cached npc_text greetings: 62611/62615 shared with Arathror (identical rows); 62619, the only
-- tauren greeting of the 62611-62619 batch, as his default (attribution INFERRED). Option text INFERRED.
DELETE FROM `npc_text` WHERE `ID` IN (62611, 62615, 62619);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(62611, 'We’ve got everything we need for the disguise. Are things ready on your end?', 'We’ve got everything we need for the disguise. Are things ready on your end?', 0, 0, 1),
(62615, 'Everything is in place. Once you are ready, I will see to your disguise myself.', 'Everything is in place. Once you are ready, I will see to your disguise myself.', 0, 0, 1),
(62619, '<The elder tauren has his back to you. His massive arms work diligently, rolling up a curtain of white cloth. His fingers, surprisingly deft for their size, drum against it like the legs of a spider.>', '<The elder tauren has his back to you. His massive arms work diligently, rolling up a curtain of white cloth. His fingers, surprisingly deft for their size, drum against it like the legs of a spider.>', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 932450;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932450, 62611),
(932450, 62615),
(932450, 62619);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932450;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932450, 0, 0, 'I am ready. Dress me in the disguise.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` = 932450 AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 932450, 62611, 0, 0, 8, 0, 1660032, 0, 0, 0, 0, 0, '', 'Nauchol greeting 62611 once Death and Dishonor is rewarded'),
(14, 932450, 62611, 0, 0, 8, 0, 1660033, 0, 0, 1, 0, 0, '', 'Nauchol greeting 62611 until Death and Justice is rewarded'),
(14, 932450, 62615, 0, 0, 9, 0, 1660033, 0, 0, 0, 0, 0, '', 'Nauchol greeting 62615 while Death and Justice is taken'),
(14, 932450, 62619, 0, 0, 8, 0, 1660032, 0, 0, 1, 0, 0, '', 'Nauchol greeting 62619 until Death and Dishonor is rewarded'),
(14, 932450, 62619, 0, 1, 8, 0, 1660033, 0, 0, 0, 0, 0, '', 'Nauchol greeting 62619 or once Death and Justice is rewarded'),
(15, 932450, 0, 0, 0, 8, 0, 1660032, 0, 0, 0, 0, 0, '', 'Disguise option: Death and Dishonor rewarded'),
(15, 932450, 0, 0, 0, 1, 0, 256709, 0, 0, 1, 0, 0, '', 'Disguise option: not already wearing 256709'),
(15, 932450, 0, 0, 0, 1, 0, 256710, 0, 0, 1, 0, 0, '', 'Disguise option: not already wearing 256710'),
(15, 932450, 0, 0, 1, 9, 0, 1660033, 0, 0, 0, 0, 0, '', 'Disguise option: or Death and Justice taken (its credit)');

-- ---------------------------------------------------------------------------
-- 3. World objects and loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300514, 3, 7640, 'Dead Rebel Warrior', '', 1.35, '', 1689, 2300514, 0, 1, 0, 0, 0, 0, 1660032, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300515, 3, 1045031, 'Exalted Pendant', '', 0.5, '', 1689, 2300515, 0, 0, 0, 0, 0, 0, 1660032, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300532, 3, 758, 'Offering Bone', '', 4.5, '', 1689, 2300532, 0, 1, 0, 0, 0, 0, 1660035, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300527, 10, 69712, 'Aquiline Totem', '', 0.3, 'SmartGameObjectAI', 0, 1660034, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300533, 10, 85947, 'Owlish Totem', '', 0.3, 'SmartGameObjectAI', 0, 1660034, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300534, 10, 85946, 'Taurine Totem', '', 0.3, 'SmartGameObjectAI', 0, 1660034, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

-- Manes 70 %, bones from Patrols and Tallstriders 40 % (INFERRED); every chest pays 100 % (DESIGN).
DELETE FROM `creature_loot_template` WHERE `Entry` IN (161809, 161810, 161811);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(161809, 559156, 0, 70, 1, 1, 0, 1, 1, 'Grimtotem Marauder - Grimtotem Marauder Mane'),
(161810, 559168, 0, 40, 1, 1, 0, 1, 1, 'Grimtotem Patrol - Offering Bone'),
(161811, 559168, 0, 40, 1, 1, 0, 1, 1, 'Tallstrider - Offering Bone');

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (2300514, 2300515, 2300532);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300514, 559151, 0, 100, 1, 1, 0, 1, 1, 'Dead Rebel Warrior - Grimtotem Armor Piece'),
(2300515, 559152, 0, 100, 1, 1, 0, 1, 1, 'Exalted Pendant - Exalted Pendant'),
(2300532, 559168, 0, 100, 1, 1, 0, 1, 1, 'Offering Bone - Offering Bone');

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- Chain 1660030 -> 1660031 -> 1660032 -> {1660033, 1660034}; 1660030 -> 1660035 -> 1660043.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660030, 2, 6, 3, 220, 0, 0, 0, 0, 0, 0, 0, 5, 25, 0, 0, 0, 0, 0, 0, 8, 0, 5571, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death and Tribute', 'Slay seven Grimtotem Marauders in Red Cloud Mesa, take their manes as proof, and deliver them to Lady Redhorn’s mistress.', '<The tauren sizes you up with a measured, judging gaze.>$b$bStrong. Well-built. Brave.$b$b<After a moment’s pause, he nods, convinced.>$b$bYes. You might prove useful.$b$bAcross this plain stands a lone cabin, the place of exile for my noble lady.$b$bShe is… a harsh judge. But generous. Slay seven Grimtotem Marauders and bring her their manes as proof. She will reward you well. And if she deems you worthy…$b$bShe will entrust you with the noblest of purposes.', '', 'Present yourself before Morriga.', 0, 0, 0, 0, 0, 0, 0, 0, 559156, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, '', '', '', ''),
(1660031, 2, 6, 3, 220, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 559157, 8, 0, 805, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death and Exile', 'Follow the Grimtotem Mountain Path to Hard Basin and show Morriga Hollowhoof’s ring to Sage Nauchol.', 'I am Morriga Hollowhoof, daughter of the tyrant Malgorm Hollowhoof, lord of Three Totems.$b$bI have not always lived here. Once, I sought to free Three Totems from my father’s tyranny. I failed. My mate paid for that failure with his life, as did all who followed me in rebellion.$b$bI, however… my father lacked the courage to execute. Instead, he cast me out here.$b$bBut what he does not know is that I still have allies; both within the village, and beyond it. And you, stranger, will be my way of reaching them.$b$bFollow the path winding up the mountain, and seek out Sage Nauchol. Take him this ring. You’ll need say no more.', '', 'Speak with Sage Nauchol.', 161822, 0, 0, 0, 1, 0, 0, 0, 559157, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Hard Basin discovered', '', '', ''),
(1660032, 2, 6, 3, 220, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death and Dishonor', 'Gather pieces of armor and the identifying pendant of Three Totems warriors to complete your disguise.', 'If you have faced fifteen of Malgorm’s warriors and lived, perhaps you have a chance against the tyrant himself. But not against an entire village.$b$bWe’ll need a disguise; to dress you as one of our own.$b$bAfter Morriga’s rebellion, her fallen warriors were denied the honor of funeral rites. Their bodies still lie scattered in the grass and muck, left to carrion. Their belongings won’t be missed, and the vultures will thank you for stripping them bare.$b$bOnly those who died loyal to Malgorm were given the rites. From their corpses you won’t find armor, but something far more valuable: the pendant that marks them as the tyrant’s chosen.', '', 'Return to Sage Nauchol', 0, 0, 0, 0, 0, 0, 0, 0, 559151, 559152, 0, 0, 0, 0, 5, 1, 0, 0, 0, 0, '', '', '', ''),
(1660033, 2, 6, 3, 220, 0, 2, 0, 0, 0, 0, 0, 7, 50, 0, 0, 0, 0, 0, 0, 8, 0, 559183, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death and Justice', 'Speak with Nauchol when you are ready for the disguise, then infiltrate Three Totems and slay Malgorm Hollowhoof.', 'You’ll find Malgorm Hollowhoof at the far end of the village, atop the hill, in the largest cabin of them all.$b$bAs you walk to him, keep your head high. Do not meet any gaze. Be confident. Proud. Arrogant, even. That is how his warriors behave. That is how he is.', '', 'Report to Morriga with news of her father’s death.', 161823, 161816, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ask Nauchol to dress you in the disguise', 'Malgorm Hollowhoof slain', '', ''),
(1660034, 2, 6, 3, 220, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death by Laughter', 'Channel the Great Hyena’s blessing into the village totems and defeat the guardian spirits that protect them.', 'Don’t I stir a bit of pity in you? <The hyena scrunches its muzzle into something that almost resembles a pout.> So… alone. Out of place. Just like Morriga.$b$bShe’s lucky to have you. But what about me?$b$b<The pout stretches into a grin, rows of jagged teeth glinting.>$b$bLet’s play a game. Go into the village and channel my blessing through their totems. The spirits guarding them will be furious, but you and I will have ourselves a laugh at their expense.$b$bDo this for me… and perhaps fortune will bare its teeth for you as well.', '', 'Return to the Hyena Spirit.', 161849, 161850, 161851, 161852, 3, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Totems altered', 'Aquiline Spirit defeated', 'Owlish Spirit defeated', 'Taurine Spirit defeated'),
(1660035, 2, 6, 3, 220, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'To Whom I Devote', 'Gather bones along the mountain path and offer them at the Great Hyena’s altar in Hard Basin.', 'Numerous are the spirits who guide the Shu’halo. Some are more popular, well-known, and revered by all the tribes. Others…$b$bAt the end of the mountain path, in a corner of Hard Basin, stands a solitary totem honoring the spirit of the Great Hyena. My patroness.$b$bI owe her much, even in exile. Her wisdom has guided me through these long years.$b$bTake her an offering in my name. Bones; the bones of my enemies, and of the great beasts whose remains line the path.$b$bWe will need her blessing if we are to bring down my father, the tyrant.', '', 'Present the Offering Bones at the altar of the Great Hyena.', 0, 0, 0, 0, 0, 0, 0, 0, 559168, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, '', '', '', ''),
(1660043, 2, 6, 3, 220, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 559176, 1, 559177, 1, 559178, 1, 559179, 1, 559186, 1, 559181, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Fighting Over Carrion', 'Defeat the Cruel Carrion Spirit in Hard Basin.', 'Perhaps you noticed that wretched presence… the bird circling over Hard Basin, lording over the carrion scattered across the battlefield.$b$bHe’s nothing but an echo of an echo, but with me stuck down here and him flying free above… it makes my teeth itch.$b$bKill him, will you? If not for me, then for the reward.$b$b<The hyena spirit flashes a sly grin full of sharp teeth.>$b$bOh yes… the reward will be worth it. More than worth it.', '', 'Return to the Spirit of the Hyena.', 161834, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660030, 1660031, 1660032, 1660033, 1660034, 1660035, 1660043);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660030, 0, 0, 0, 0, 0),
(1660031, 0, 0, 1660030, 1, 0),
(1660032, 0, 0, 1660031, 0, 0),
(1660033, 0, 0, 1660032, 0, 0),
(1660034, 0, 0, 1660032, 0, 0),
(1660035, 0, 0, 1660030, 0, 0),
(1660043, 0, 0, 1660035, 0, 0);

-- Progress and completion texts from the AscensionES archive (pEN / cEN).
DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660030, 1660031, 1660032, 1660033, 1660034, 1660035, 1660043);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660030, 'This isn’t just any gift... Seven manes, from seven warriors. A feat worth respect.$B$BI take it you were sent by my loyal Redhorn. If that is so, then it will be my honor to accept your service.'),
(1660031, 'This ring…$B$B<The tauren falls silent for a long while. His gaze flickers restlessly, like a grasshopper in the brush.>$B$BDo you know what this means? Morriga has chosen you as her champion. I wonder what she saw in you… that I cannot.$B$BHm. No matter. We have work to do.'),
(1660032, 'Do you bring all we need for the disguise?'),
(1660033, 'My father… is dead?$B$B<Morriga’s eyes grow wet. Her look might be sorrow… or relief. Likely, a tear of both.>$B$BThat means I can return to Three Totems.$B$BAnd set things right.$B$B<Morriga’s tears vanish into the dimples of her smile. Suddenly, she no longer seems so gentle.>$B$BSet them right—my way.'),
(1660034, '<The hyena howls and laughs and weeps all at once, as though the task it set you was the greatest jest ever told.>$B$BWell done… oh, very well done!$B$BThe village spirits are in an uproar. They earned it; the humiliation they dealt me, the exile…$B$BMy smile is the smile of fortune. Now… enjoy it.'),
(1660035, '<The spirit of the hyena bares its teeth as you approach. You cannot tell if it is warning, or laughter.>$B$BMorriga, is it?$B$B<A jagged, manic laugh rakes through your skull.>$B$BI am pleased. That tauren always finds a way to amuse me. She never tires of serving.$B$BVery well. I’ll take her scraps.'),
(1660043, 'At last!$B$BThe scavenger turned to carrion. Delicious. His father will rage when he learns I conspired to kill one of his countless bastards.$B$BAnother grievance to add to our long, bloody tally.$B$B<A final, triumphant cackle ends the spirit’s rant.>$B$BWell then, a promise is a promise. Choose your reward wisely.');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660030, 1660031, 1660032, 1660033, 1660034, 1660035, 1660043);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660030, 'Did I summon you here? Begone from my sight!'),
(1660031, 'Yes?'),
(1660032, 'Still haven’t brought what we need for the disguise?$B$BYou may have bested fifteen warriors already, but you will not survive an entire village united against you.'),
(1660033, 'You again… an ill omen. Did you find Nauchol? Were you discovered?'),
(1660034, '<Before the altar looms a creature of hazy outline, barely visible, as though it does not belong fully to the world of flesh.>'),
(1660035, '<Before the altar looms a creature of hazy outline, barely visible, as though it does not belong fully to the world of flesh.>'),
(1660043, '<The hyena sniffs the air, then fixes its gaze on the sky.>$B$BThe vulture… have you finished him?');

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660030, 1660031, 1660032, 1660033, 1660034, 1660035, 1660043);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(161817, 1660030),
(161818, 1660031),
(161819, 1660032),
(161819, 1660033),
(161840, 1660034),
(161818, 1660035),
(161840, 1660043);

DELETE FROM `creature_questender` WHERE `quest` IN (1660030, 1660031, 1660032, 1660033, 1660034, 1660035, 1660043);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(161818, 1660030),
(161819, 1660031),
(161819, 1660032),
(161818, 1660033),
(161840, 1660034),
(161840, 1660035),
(161840, 1660043);

-- ---------------------------------------------------------------------------
-- 5. The Hard Basin trigger
-- ---------------------------------------------------------------------------
-- AreaTrigger.dbc 6140 at the Grimtotem bridge approach, the 1660031 objective.
DELETE FROM `areatrigger` WHERE `entry` = 6140;
INSERT INTO `areatrigger` (`entry`, `map`, `x`, `y`, `z`, `radius`, `length`, `width`, `height`, `orientation`)
VALUES
(6140, 1, -3581.09, -931.454, 191.712, 0, 13, 4, 5, 0);

DELETE FROM `areatrigger_scripts` WHERE `entry` = 6140;
INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`)
VALUES
(6140, 'SmartTrigger');

-- ---------------------------------------------------------------------------
-- 6. The Grimtotem Disguise
-- ---------------------------------------------------------------------------
-- Worn only in Hard Basin and Three Totem Village; leaving or death removes it (DESIGN).
DELETE FROM `spell_area` WHERE `spell` IN (256709, 256710);
INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_start_status`, `quest_end_status`, `quest_end`, `aura_spell`, `racemask`, `gender`, `autocast`)
VALUES
(256709, 10210, 0, 64, 11, 0, 0, 0, 2, 0),
(256709, 10211, 0, 64, 11, 0, 0, 0, 2, 0),
(256710, 10210, 0, 64, 11, 0, 0, 0, 2, 0),
(256710, 10211, 0, 64, 11, 0, 0, 0, 2, 0);

-- 256710 as in Spell.dbc except AttributesEx3, which drops ALLOW_AURA_WHILE_DEAD so death ends it.
DELETE FROM `spell_dbc` WHERE `ID` = 256710;
INSERT INTO `spell_dbc` (`ID`, `Category`, `DispelType`, `Mechanic`, `Attributes`, `AttributesEx`, `AttributesEx2`, `AttributesEx3`, `AttributesEx4`, `AttributesEx5`, `AttributesEx6`, `AttributesEx7`, `ShapeshiftMask`, `unk_320_2`, `ShapeshiftExclude`, `unk_320_3`, `Targets`, `TargetCreatureType`, `RequiresSpellFocus`, `FacingCasterFlags`, `CasterAuraState`, `TargetAuraState`, `ExcludeCasterAuraState`, `ExcludeTargetAuraState`, `CasterAuraSpell`, `TargetAuraSpell`, `ExcludeCasterAuraSpell`, `ExcludeTargetAuraSpell`, `CastingTimeIndex`, `RecoveryTime`, `CategoryRecoveryTime`, `InterruptFlags`, `AuraInterruptFlags`, `ChannelInterruptFlags`, `ProcTypeMask`, `ProcChance`, `ProcCharges`, `MaxLevel`, `BaseLevel`, `SpellLevel`, `DurationIndex`, `PowerType`, `ManaCost`, `ManaCostPerLevel`, `ManaPerSecond`, `ManaPerSecondPerLevel`, `RangeIndex`, `Speed`, `ModalNextSpell`, `CumulativeAura`, `Totem_1`, `Totem_2`, `Reagent_1`, `Reagent_2`, `Reagent_3`, `Reagent_4`, `Reagent_5`, `Reagent_6`, `Reagent_7`, `Reagent_8`, `ReagentCount_1`, `ReagentCount_2`, `ReagentCount_3`, `ReagentCount_4`, `ReagentCount_5`, `ReagentCount_6`, `ReagentCount_7`, `ReagentCount_8`, `EquippedItemClass`, `EquippedItemSubclass`, `EquippedItemInvTypes`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`, `EffectRealPointsPerLevel_1`, `EffectRealPointsPerLevel_2`, `EffectRealPointsPerLevel_3`, `EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `EffectMechanic_1`, `EffectMechanic_2`, `EffectMechanic_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`, `ImplicitTargetA_3`, `ImplicitTargetB_1`, `ImplicitTargetB_2`, `ImplicitTargetB_3`, `EffectRadiusIndex_1`, `EffectRadiusIndex_2`, `EffectRadiusIndex_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`, `EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `EffectAuraPeriod_3`, `EffectMultipleValue_1`, `EffectMultipleValue_2`, `EffectMultipleValue_3`, `EffectChainTargets_1`, `EffectChainTargets_2`, `EffectChainTargets_3`, `EffectItemType_1`, `EffectItemType_2`, `EffectItemType_3`, `EffectMiscValue_1`, `EffectMiscValue_2`, `EffectMiscValue_3`, `EffectMiscValueB_1`, `EffectMiscValueB_2`, `EffectMiscValueB_3`, `EffectTriggerSpell_1`, `EffectTriggerSpell_2`, `EffectTriggerSpell_3`, `EffectPointsPerCombo_1`, `EffectPointsPerCombo_2`, `EffectPointsPerCombo_3`, `EffectSpellClassMaskA_1`, `EffectSpellClassMaskA_2`, `EffectSpellClassMaskA_3`, `EffectSpellClassMaskB_1`, `EffectSpellClassMaskB_2`, `EffectSpellClassMaskB_3`, `EffectSpellClassMaskC_1`, `EffectSpellClassMaskC_2`, `EffectSpellClassMaskC_3`, `SpellVisualID_1`, `SpellVisualID_2`, `SpellIconID`, `ActiveIconID`, `SpellPriority`, `Name_Lang_enUS`, `Name_Lang_enGB`, `Name_Lang_koKR`, `Name_Lang_frFR`, `Name_Lang_deDE`, `Name_Lang_enCN`, `Name_Lang_zhCN`, `Name_Lang_enTW`, `Name_Lang_zhTW`, `Name_Lang_esES`, `Name_Lang_esMX`, `Name_Lang_ruRU`, `Name_Lang_ptPT`, `Name_Lang_ptBR`, `Name_Lang_itIT`, `Name_Lang_Unk`, `Name_Lang_Mask`, `NameSubtext_Lang_enUS`, `NameSubtext_Lang_enGB`, `NameSubtext_Lang_koKR`, `NameSubtext_Lang_frFR`, `NameSubtext_Lang_deDE`, `NameSubtext_Lang_enCN`, `NameSubtext_Lang_zhCN`, `NameSubtext_Lang_enTW`, `NameSubtext_Lang_zhTW`, `NameSubtext_Lang_esES`, `NameSubtext_Lang_esMX`, `NameSubtext_Lang_ruRU`, `NameSubtext_Lang_ptPT`, `NameSubtext_Lang_ptBR`, `NameSubtext_Lang_itIT`, `NameSubtext_Lang_Unk`, `NameSubtext_Lang_Mask`, `Description_Lang_enUS`, `Description_Lang_enGB`, `Description_Lang_koKR`, `Description_Lang_frFR`, `Description_Lang_deDE`, `Description_Lang_enCN`, `Description_Lang_zhCN`, `Description_Lang_enTW`, `Description_Lang_zhTW`, `Description_Lang_esES`, `Description_Lang_esMX`, `Description_Lang_ruRU`, `Description_Lang_ptPT`, `Description_Lang_ptBR`, `Description_Lang_itIT`, `Description_Lang_Unk`, `Description_Lang_Mask`, `AuraDescription_Lang_enUS`, `AuraDescription_Lang_enGB`, `AuraDescription_Lang_koKR`, `AuraDescription_Lang_frFR`, `AuraDescription_Lang_deDE`, `AuraDescription_Lang_enCN`, `AuraDescription_Lang_zhCN`, `AuraDescription_Lang_enTW`, `AuraDescription_Lang_zhTW`, `AuraDescription_Lang_esES`, `AuraDescription_Lang_esMX`, `AuraDescription_Lang_ruRU`, `AuraDescription_Lang_ptPT`, `AuraDescription_Lang_ptBR`, `AuraDescription_Lang_itIT`, `AuraDescription_Lang_Unk`, `AuraDescription_Lang_Mask`, `ManaCostPct`, `StartRecoveryCategory`, `StartRecoveryTime`, `MaxTargetLevel`, `SpellClassSet`, `SpellClassMask_1`, `SpellClassMask_2`, `SpellClassMask_3`, `MaxTargets`, `DefenseType`, `PreventionType`, `StanceBarOrder`, `EffectChainAmplitude_1`, `EffectChainAmplitude_2`, `EffectChainAmplitude_3`, `MinFactionID`, `MinReputation`, `RequiredAuraVision`, `RequiredTotemCategoryID_1`, `RequiredTotemCategoryID_2`, `RequiredAreasID`, `SchoolMask`, `RuneCostID`, `SpellMissileID`, `PowerDisplayID`, `EffectBonusMultiplier_1`, `EffectBonusMultiplier_2`, `EffectBonusMultiplier_3`, `SpellDescriptionVariableID`, `SpellDifficultyID`)
VALUES
(256710, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 101, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 6, 6, 6, 0, 1, 1, 0, 0, 0, 0, 0, 3, 0, 0, 0, 25, 25, 1, 0, 0, 0, 0, 0, 0, 56, 226, 139, 0, 500, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 161830, 0, 829, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 278464, 0, 1615, 0, 0, 'Grimtotem Disguise', '', '', '', '', '', '', '', '', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 16712190, '', '', '', '', '', '', '', '', '', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 16712190, 'Signature guise of the savage Grimtotem warriors of Three Totems. Allows you to slip into Three Totem village unnoticed.', '', '', '', '', '', '', '', '', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 16712190, 'Signature guise of the savage Grimtotem warriors of Three Totems. Allows you to slip into Three Totem village unnoticed.', '', '', '', '', '', '', '', '', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 16712190, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0);

-- Nauchol dresses men as a Grimtotem warrior and women as a Grimtotem guard.
DELETE FROM `conditions` WHERE `SourceEntry` = 161819 AND `SourceTypeOrReferenceId` = 22 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 3, 161819, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, '', 'Nauchol disguise row 2: men'),
(22, 4, 161819, 0, 0, 20, 0, 1, 0, 0, 0, 0, 0, '', 'Nauchol disguise row 3: women');

-- ---------------------------------------------------------------------------
-- 7. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9011000, 9011001, 9011002, 9011003, 9011004, 9011005, 9011006, 9011010, 9011011, 9011012, 9011013, 9011014, 9011015, 9011016, 9011017, 9011018, 9011019, 9011020, 9011021, 9011022, 9011023, 9011024, 9011025, 9011026, 9011027, 9011028, 9011029, 9011030, 9011031, 9011032, 9011033, 9011034, 9011035, 9011036, 9011037, 9011038, 9011039, 9011040, 9011041, 9011042, 9011043, 9011044, 9011045, 9011046, 9011047, 9011048, 9011049, 9011050, 9011051, 9011052, 9011060, 9011061, 9011062, 9011063, 9011064, 9011065, 9011066, 9011067, 9011068, 9011069, 9011070, 9011071, 9011080, 9011081, 9011082, 9011083, 9011084, 9011085, 9011086, 9011087, 9011090, 9011091, 9011092, 9011093, 9011100, 9011101, 9011102, 9011103, 9011110, 9011111, 9011112, 9011113, 9011114, 9011115, 9011120, 9011121, 9011122, 9011123, 9011124, 9011125, 9011130, 9011131, 9011132) OR `guid` BETWEEN 9011000 AND 9011399;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9011000, 161817, 1, 0, 0, 1, 1, 0, -2909, -289, 53.951, 1.69, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Camp Narache, 4.0 yd south-west of Go''hro 9003910 who stands on his Questie point (user Q11), by the excavation stakes; faces 1.69 toward the camp heart and Grull Hawkwind'),
(9011001, 161818, 1, 0, 0, 1, 1, 0, -3360.89, -901.79, 70.84, 0.93, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: SOURCED-CLIENT ST8688, the 1660030/1660033 turn-in point in front of Morriga''s exile cabin (TaurenHutD.wmo); faces 0.93 across the plain toward Camp Narache, the way players come'),
(9011002, 161819, 1, 0, 0, 1, 1, 0, -3628.05, -1035.92, 203.14, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: SOURCED-CLIENT ST8690, the 1660031/1660032 turn-in point at his tent in Hard Basin (area 10210); faces 1.0 toward the bench ring and the bridge path'),
(9011003, 161840, 1, 0, 0, 1, 1, 0, -3644.44, -969.58, 204.644, 5.55, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: SOURCED-CLIENT ST8705, the 1660034/1660035/1660043 turn-in point at the Great Hyena altar in the windbreak corner of Hard Basin (area 10210); faces 5.55 out over the basin'),
(9011004, 161816, 1, 0, 0, 1, 1, 0, -3462.84, -1157.95, 214.871, 2.79, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: SOURCED-CLIENT ST8692, the 1660033 objective point on the floor of Malgorm''s hut (TaurenHutBig.wmo); faces 2.79 toward the door'),
(9011005, 161834, 1, 0, 0, 1, 1, 0, -3509, -1105, 221, 2.03, 120, 0, 0, 1, 0, 2, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: first node of its flight circle over the lake south of the Hard Basin battlefield, 21+ yd from every corpse, looter post and graveyard (verifier nodes)'),
(9011006, 161838, 1, 0, 0, 1, 1, 0, -3587.5, -1110, 205.312, 3.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Three Totem Village (area 10211): at the bowls by the north-west trough, facing them'),
(9011010, 161809, 1, 0, 0, 1, 1, 0, -3204.56, -573.82, 27.397, 0.77, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the northern flats toward Camp Narache, facing Camp Narache'),
(9011011, 161809, 1, 0, 0, 1, 1, 0, -3196.64, -588.76, 29.471, 0.8, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the northern flats toward Camp Narache, facing Camp Narache'),
(9011012, 161809, 1, 0, 0, 1, 1, 0, -3250.4, -595.6, 29.43, 0.73, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the northern flats toward Camp Narache, facing Camp Narache'),
(9011013, 161809, 1, 0, 0, 1, 1, 0, -3242.6, -629.8, 29.282, 0.79, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the northern flats toward Camp Narache, facing Camp Narache'),
(9011014, 161809, 1, 0, 0, 1, 1, 0, -3286.52, -625.3, 35.908, 0.73, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Camp Narache'),
(9011015, 161809, 1, 0, 0, 1, 1, 0, -3305.24, -631.24, 41.22, 4.51, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Morriga''s cabin'),
(9011016, 161809, 1, 0, 0, 1, 1, 0, -3311.96, -680.92, 42.967, 4.49, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Morriga''s cabin'),
(9011017, 161809, 1, 0, 0, 1, 1, 0, -3295.64, -676.06, 40.335, 0.78, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Camp Narache'),
(9011018, 161809, 1, 0, 0, 1, 1, 0, -3254.6, -677.86, 32.785, 0.84, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the northern flats toward Camp Narache, facing Camp Narache'),
(9011019, 161809, 1, 0, 0, 1, 1, 0, -3220.76, -712.23, 36.183, 0.93, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the northern flats toward Camp Narache, facing Camp Narache'),
(9011020, 161809, 1, 0, 0, 1, 1, 0, -3272.6, -728.79, 40.053, 0.88, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Camp Narache'),
(9011021, 161809, 1, 0, 0, 1, 1, 0, -3282.56, -714.21, 41.799, 0.85, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Camp Narache'),
(9011022, 161809, 1, 0, 0, 1, 1, 0, -3344.25, -648.52, 54.947, 4.65, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Morriga''s cabin'),
(9011023, 161809, 1, 0, 0, 1, 1, 0, -3344.97, -682, 53.624, 4.64, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Morriga''s cabin'),
(9011024, 161809, 1, 0, 0, 1, 1, 0, -3342.81, -707.74, 56.672, 4.62, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Morriga''s cabin'),
(9011025, 161809, 1, 0, 0, 1, 1, 0, -3363.33, -730.59, 63.23, 4.73, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the open mid plain, facing Morriga''s cabin'),
(9011026, 161809, 1, 0, 0, 1, 1, 0, -3337, -757.5, 52.924, 4.56, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; 1.3 yd off the Questie sighting (-3338.25, -757.77) among the tree stands, clear of the tree trunk; faces the cabin'),
(9011027, 161809, 1, 0, 0, 1, 1, 0, -3313.04, -759.21, 47.333, 4.39, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting among the tree stands of the mid plain, facing Morriga''s cabin'),
(9011028, 161809, 1, 0, 0, 1, 1, 0, -3283.76, -763.17, 40.867, 0.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting among the tree stands of the mid plain, facing Camp Narache'),
(9011029, 161809, 1, 0, 0, 1, 1, 0, -3259.28, -790.35, 36.218, 0.96, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the northern flats toward Camp Narache, facing Camp Narache'),
(9011030, 161809, 1, 0, 0, 1, 1, 0, -3283.28, -832.47, 47.33, 0.97, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting among the tree stands of the mid plain, facing Camp Narache'),
(9011031, 161809, 1, 0, 0, 1, 1, 0, -3326.97, -803.67, 47.311, 4.38, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting among the tree stands of the mid plain, facing Morriga''s cabin'),
(9011032, 161809, 1, 0, 0, 1, 1, 0, -3404.49, -774.51, 68.502, 5.04, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the southern slope under the mountain path, facing Morriga''s cabin'),
(9011033, 161809, 1, 0, 0, 1, 1, 0, -3401.85, -806.19, 66.635, 5.12, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the southern slope under the mountain path, facing Morriga''s cabin'),
(9011034, 161809, 1, 0, 0, 1, 1, 0, -3417.33, -828.69, 63.973, 5.37, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the southern slope under the mountain path, facing Morriga''s cabin'),
(9011035, 161809, 1, 0, 0, 1, 1, 0, -3431.01, -855.33, 63.7, 5.7, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the southern slope under the mountain path, facing Morriga''s cabin'),
(9011036, 161809, 1, 0, 0, 1, 1, 0, -3444.33, -814.11, 78.27, 5.47, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the southern slope under the mountain path, facing Morriga''s cabin; stays put on the 36-degree slope'),
(9011037, 161809, 1, 0, 0, 1, 1, 0, -3464.25, -840.57, 76.665, 5.75, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; Questie sighting on the southern slope under the mountain path, facing Morriga''s cabin'),
(9011038, 161809, 1, 0, 0, 1, 1, 0, -3190, -596, 30.574, 2.31, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3196.64, -588.76), facing it'),
(9011039, 161809, 1, 0, 0, 1, 1, 0, -3249, -636, 30.078, 0.77, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3242.6, -629.8), facing it'),
(9011040, 161809, 1, 0, 0, 1, 1, 0, -3298, -637, 39.434, 2.47, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3305.24, -631.24), facing it'),
(9011041, 161809, 1, 0, 0, 1, 1, 0, -3318, -674, 44.351, 5.43, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3311.96, -680.92), facing it'),
(9011042, 161809, 1, 0, 0, 1, 1, 0, -3261, -684, 34.557, 0.76, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3254.6, -677.86), facing it'),
(9011043, 161809, 1, 0, 0, 1, 1, 0, -3266, -735, 38.45, 2.39, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3272.6, -728.79), facing it'),
(9011044, 161809, 1, 0, 0, 1, 1, 0, -3336, -714, 54.734, 2.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3342.81, -707.74), facing it'),
(9011045, 161809, 1, 0, 0, 1, 1, 0, -3290, -769, 42.065, 0.75, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3283.76, -763.17), facing it'),
(9011046, 161809, 1, 0, 0, 1, 1, 0, -3394, -812, 62.975, 2.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3401.85, -806.19), facing it'),
(9011047, 161809, 1, 0, 0, 1, 1, 0, -3423, -849, 61.277, 3.81, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; raiding pair with the Questie sighting (-3431.01, -855.33), facing it'),
(9011048, 161809, 1, 0, 0, 1, 1, 0, -3280, -692, 39.392, 4.34, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; by the tree stump (-3282.7, -684.5) in the tree pair, facing the cabin'),
(9011049, 161809, 1, 0, 0, 1, 1, 0, -3322, -770, 49.18, 4.43, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; between the stump (-3324.7, -760.6) and the tree stand, facing the cabin'),
(9011050, 161809, 1, 0, 0, 1, 1, 0, -3355, -825, 51.111, 4.64, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; by the big stump (-3361.6, -821.9) on the approach to the cabin, facing it'),
(9011051, 161809, 1, 0, 0, 1, 1, 0, -3338, -845, 51.48, 4.33, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; at the tauren signpost (-3344.3, -840.7) on the cabin trail, facing the cabin'),
(9011052, 161809, 1, 0, 0, 1, 1, 0, -3305, -838, 47.903, 3.99, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Marauder; beside the fallen tree (-3297.0, -849.1), facing the cabin'),
(9011060, 161810, 1, 0, 0, 1, 1, 0, -3402.7, -842.7, 58.343, 4.36, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; where the Grimtotem Mountain Path leaves the plain, facing up it; 14 yd from the Questie sighting (-3388.53, -846.51), which is 6 yd from stock cougar 94870'),
(9011061, 161810, 1, 0, 0, 1, 1, 0, -3461.97, -857.13, 71.516, 4.13, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting on the lower climb of the Grimtotem Mountain Path, facing up the path'),
(9011062, 161810, 1, 0, 0, 1, 1, 0, -3479.73, -898.34, 107.554, 5.89, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting by the stone benches, facing along the path to the totems'),
(9011063, 161810, 1, 0, 0, 1, 1, 0, -3453.33, -833.19, 112.999, 1.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting on the plank bridge; stays put on its planks, facing north'),
(9011064, 161810, 1, 0, 0, 1, 1, 0, -3511.17, -771.27, 138.329, 3.17, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting on the upper path, facing the kodo skeleton'),
(9011065, 161810, 1, 0, 0, 1, 1, 0, -3529.89, -777.57, 143.675, 4.48, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting at the kodo skeleton, facing up the path'),
(9011066, 161810, 1, 0, 0, 1, 1, 0, -3540.21, -806.55, 153.356, 4.37, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting on the upper climb, facing up the path'),
(9011067, 161810, 1, 0, 0, 1, 1, 0, -3567.57, -850.11, 167.105, 4.48, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting by the stone benches, facing up the path'),
(9011068, 161810, 1, 0, 0, 1, 1, 0, -3582.93, -923.18, 188.397, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting at the bridge approach; stays put on the 32-degree slope, facing down the path'),
(9011069, 161810, 1, 0, 0, 1, 1, 0, -3597.09, -997.7, 203.586, 5.21, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting at the mouth of Hard Basin (area 10210), facing the bench ring'),
(9011070, 161810, 1, 0, 0, 1, 1, 0, -3582.57, -928.22, 190.697, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; Questie sighting at the bridge approach beside the other, facing down the path'),
(9011071, 161810, 1, 0, 0, 1, 1, 0, -3556, -842, 164.02, 1.15, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Patrol; on the upper climb between two sightings; replaces the sighting (-3626.3, -1026.3) 10 yd from Nauchol''s tent; stays put on the 37-degree slope'),
(9011080, 161811, 1, 0, 0, 1, 1, 0, -3405, -856, 60.823, 1.2, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; grazing on the meadow below the Grimtotem Mountain Path'),
(9011081, 161811, 1, 0, 0, 1, 1, 0, -3435, -838, 65.055, 2.8, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; grazing on the meadow slope below the Grimtotem Mountain Path, 16 yd from the nearest Marauder'),
(9011082, 161811, 1, 0, 0, 1, 1, 0, -3398, -830, 59.776, 4.4, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; on the meadow at the foot of the Grimtotem Mountain Path'),
(9011083, 161811, 1, 0, 0, 1, 1, 0, -3437, -866, 68.69, 0.6, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; at the foot of the climb of the Grimtotem Mountain Path'),
(9011084, 161811, 1, 0, 0, 1, 1, 0, -3505, -763, 138.944, 3.3, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; on the grass plateau of the upper the Grimtotem Mountain Path'),
(9011085, 161811, 1, 0, 0, 1, 1, 0, -3490, -770, 131.776, 5.5, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; by the stone benches of the upper the Grimtotem Mountain Path'),
(9011086, 161811, 1, 0, 0, 1, 1, 0, -3547, -812, 156.378, 2, 300, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; on the shoulder of the upper climb of the Grimtotem Mountain Path'),
(9011087, 161811, 1, 0, 0, 1, 1, 0, -3552, -835, 163.821, 4, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Tallstrider; on the 33-degree upper climb of the Grimtotem Mountain Path, short wander'),
(9011090, 161812, 1, 0, 0, 1, 1, 0, -3530, -1055, 205.093, 1, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Battlefield Scavenger; the Hard Basin battlefield: among the spears and skeletons in the middle'),
(9011091, 161812, 1, 0, 0, 1, 1, 0, -3514, -1066, 205.11, 3.4, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Battlefield Scavenger; the Hard Basin battlefield: over the meat heaps to the east'),
(9011092, 161812, 1, 0, 0, 1, 1, 0, -3550, -1062, 204.857, 5.2, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Battlefield Scavenger; the Hard Basin battlefield: west end by the meat piles'),
(9011093, 161812, 1, 0, 0, 1, 1, 0, -3506, -1048, 206.839, 2.3, 300, 6, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Battlefield Scavenger; the Hard Basin battlefield: north-east corner by the meat pile'),
(9011100, 161837, 1, 0, 0, 1, 1, 0, -3577, -1107.5, 204.756, 2.19, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Guard; Three Totem Village (area 10211): west entrance by the windbreak line, facing Hard Basin'),
(9011101, 161837, 1, 0, 0, 1, 1, 0, -3565, -1106.5, 204.86, 2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Guard; Three Totem Village (area 10211): west entrance on the other side of the windbreak (-3571.6, -1102.7), facing Hard Basin'),
(9011102, 161837, 1, 0, 0, 1, 1, 0, -3474.9, -1147, 215.07, 2.79, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Guard; Malgorm''s hut (TaurenHutBig.wmo): north flank of the door on the porch floor, facing out'),
(9011103, 161837, 1, 0, 0, 1, 1, 0, -3479.5, -1159, 214.112, 2.79, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Guard; Malgorm''s hut (TaurenHutBig.wmo): south flank of the door, facing out'),
(9011110, 161814, 1, 0, 0, 1, 1, 0, -3486, -1163.5, 214.139, 2.22, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Warrior; Three Totem Village (area 10211): at the weapon rack (-3488.2, -1160.6) before the hut, facing it'),
(9011111, 161814, 1, 0, 0, 1, 1, 0, -3481.5, -1163, 214.108, 1.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Warrior; Three Totem Village (area 10211): at the second weapon rack (-3482.1, -1160.2), facing it'),
(9011112, 161814, 1, 0, 0, 1, 1, 0, -3487.5, -1184, 213.473, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Warrior; Three Totem Village (area 10211): at the stone benches of the hill plaza, facing the drums'),
(9011113, 161814, 1, 0, 0, 1, 1, 0, -3465, -1180, 214.112, 5.45, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Warrior; Three Totem Village (area 10211): at the drum circle (-3459.5, -1184.5), facing it, clear of the ball-hoop stand'),
(9011114, 161814, 1, 0, 0, 1, 1, 0, -3490, -1200, 213.302, 4.24, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Warrior; Three Totem Village (area 10211): at the chicken hut weapon rack (-3492.0, -1204.0), facing it'),
(9011115, 161814, 1, 0, 0, 1, 1, 0, -3560.5, -1204.5, 206.04, 1.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Warrior; Three Totem Village (area 10211): before the tall hut (-3568.2, -1211.0), facing the lake path'),
(9011120, 161815, 1, 0, 0, 1, 1, 0, -3568.8, -1134.5, 205.276, 5.52, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Villager; Three Totem Village (area 10211): drawing water at the trough (-3566.1, -1137.1), facing it'),
(9011121, 161815, 1, 0, 0, 1, 1, 0, -3560.5, -1143, 205.486, 2.41, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Villager; Three Totem Village (area 10211): at the tool rack (-3563.4, -1140.5), facing it'),
(9011122, 161815, 1, 0, 0, 1, 1, 0, -3582.5, -1128, 205.433, 2.43, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Villager; Three Totem Village (area 10211): tending the jars by the Owlish Totem, facing them'),
(9011123, 161815, 1, 0, 0, 1, 1, 0, -3596.5, -1154.5, 205.821, 5.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Villager; Three Totem Village (area 10211): inside hut A (TaurenHutA.wmo) by the rug, facing the door'),
(9011124, 161815, 1, 0, 0, 1, 1, 0, -3577.5, -1193, 205.669, 2.45, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Villager; Three Totem Village (area 10211): at the travois of hut C (-3580.5, -1190.5), facing it'),
(9011125, 161815, 1, 0, 0, 1, 1, 0, -3592.8, -1171.4, 206.536, 3.07, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Grimtotem Villager; Three Totem Village (area 10211): at the jar and rug of the chicken hut, facing them, clear of the loom'),
(9011130, 161813, 1, 0, 0, 1, 1, 0, -3476.5, -1093.5, 205.628, 5.67, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Funeral Guard; the funeral biers (TaurenMummy on FuneralPyre01): west of the first bier, facing it'),
(9011131, 161813, 1, 0, 0, 1, 1, 0, -3463.5, -1095.5, 206.453, 2.51, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Funeral Guard; the funeral biers (TaurenMummy on FuneralPyre01): east of the second bier, facing it'),
(9011132, 161813, 1, 0, 0, 1, 1, 0, -3477.5, -1083, 205.991, 5.46, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Three Totems: Funeral Guard; the funeral biers (TaurenMummy on FuneralPyre01): north-west of the third bier, facing it');

DELETE FROM `gameobject` WHERE `guid` IN (7916500, 7916501, 7916502, 7916503, 7916504, 7916505, 7916506, 7916507, 7916508, 7916509, 7916510, 7916511, 7916512, 7916513, 7916514, 7916520, 7916521, 7916522, 7916525, 7916526, 7916527, 7916530, 7916531, 7916532, 7916533, 7916534, 7916535, 7916536, 7916537, 7916538, 7916539, 7916540, 7916541, 7916542, 7916543, 7916544, 7916545) OR `guid` BETWEEN 7916500 AND 7916699;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7916500, 2300514, 1, 0, 0, 1, 1, -3538.8, -1052.1, 205.102, 0.8, 0, 0, 0.389418, 0.921061, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; SOURCED-ATLAS sighting between the two skeletons and the spears'),
(7916501, 2300514, 1, 0, 0, 1, 1, -3546, -1040, 206.101, 2.2, 0, 0, 0.891207, 0.453596, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; beside the female skeleton and the harness totem (-3548.2, -1042.5)'),
(7916502, 2300514, 1, 0, 0, 1, 1, -3552, -1051, 204.812, 4, 0, 0, 0.909297, -0.416147, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the two bloody meat piles (-3550.6, -1054.0)'),
(7916503, 2300514, 1, 0, 0, 1, 1, -3531.5, -1046, 206.501, 1.4, 0, 0, 0.644218, 0.764842, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the male skeleton and spear (-3530.4, -1043.7)'),
(7916504, 2300514, 1, 0, 0, 1, 1, -3525, -1049.5, 206.057, 5.3, 0, 0, 0.472031, -0.881582, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the meat pile (-3524.8, -1052.7)'),
(7916505, 2300514, 1, 0, 0, 1, 1, -3516.5, -1043.5, 207.706, 3, 0, 0, 0.997495, 0.070737, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the skeleton pair and hatchet (-3519.5, -1046.0)'),
(7916506, 2300514, 1, 0, 0, 1, 1, -3525, -1059.5, 205.452, 0.3, 0, 0, 0.149438, 0.988771, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the heap of meat and the spear (-3522.0, -1062.5)'),
(7916507, 2300514, 1, 0, 0, 1, 1, -3511.5, -1052.5, 205.851, 4.6, 0, 0, 0.745705, -0.666276, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the meat pile (-3510.5, -1055.6)'),
(7916508, 2300514, 1, 0, 0, 1, 1, -3518.5, -1079, 205.269, 2.6, 0, 0, 0.963558, 0.267499, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the male skeleton and spear (-3520.4, -1077.2)'),
(7916509, 2300514, 1, 0, 0, 1, 1, -3503.5, -1057.5, 206.09, 1.1, 0, 0, 0.522687, 0.852525, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the female skeleton and spear (-3502.6, -1060.5)'),
(7916510, 2300514, 1, 0, 0, 1, 1, -3510.5, -1083, 205.065, 4.2, 0, 0, 0.863209, -0.504846, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the dropped hatchet (-3512.9, -1086.7); turned 4.2 clear of the tree trunk'),
(7916511, 2300514, 1, 0, 0, 1, 1, -3537, -1066, 205.253, 3.6, 0, 0, 0.973848, -0.227202, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; open grass between the skeleton clusters'),
(7916512, 2300514, 1, 0, 0, 1, 1, -3560, -1062, 204.614, 0.5, 0, 0, 0.247404, 0.968912, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; by the southern Grimtotem totems (-3572.9, -1060.5)'),
(7916513, 2300514, 1, 0, 0, 1, 1, -3545, -1075, 204.899, 2, 0, 0, 0.841471, 0.540302, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; south edge of the battlefield toward the lake'),
(7916514, 2300514, 1, 0, 0, 1, 1, -3496, -1066, 205.526, 4.9, 0, 0, 0.637765, -0.770231, 120, 100, 1, '', 'CoA Three Totems: Dead Rebel Warrior; east edge of the battlefield below the biers'),
(7916520, 2300515, 1, 0, 0, 1, 1, -3471.52, -1096.94, 209.432, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Three Totems: Exalted Pendant; SOURCED-CLIENT ST8691 on the first mummy bier (surface of TaurenMummy.m2)'),
(7916521, 2300515, 1, 0, 0, 1, 1, -3466.83, -1092.99, 209.478, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Three Totems: Exalted Pendant; the same spot on the second mummy bier (-3467.0, -1092.9)'),
(7916522, 2300515, 1, 0, 0, 1, 1, -3473.21, -1087.51, 209.46, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Three Totems: Exalted Pendant; the same spot on the third mummy bier (-3473.4, -1087.4)'),
(7916525, 2300527, 1, 0, 0, 1, 1, -3550.64, -1211.03, 205.737, 4.7, 0, 0, 0.711473, -0.702713, 60, 100, 1, '', 'CoA Three Totems: SOURCED-CLIENT ST8706 among the bowls and torch before the tall hut (Questie object and spirit 161850 there)'),
(7916526, 2300533, 1, 0, 0, 1, 1, -3585.93, -1123.78, 205.292, 5.5, 0, 0, 0.381661, -0.924302, 60, 100, 1, '', 'CoA Three Totems: SOURCED-CLIENT ST8707 among the jars and torches by the west windbreaks (Questie object and spirit 161851)'),
(7916527, 2300534, 1, 0, 0, 1, 1, -3497.02, -1207.18, 213.125, 1.6, 0, 0, 0.717356, 0.696707, 60, 100, 1, '', 'CoA Three Totems: SOURCED-CLIENT ST8708 by the chicken hut travois (SOURCED-ATLAS 0.0 yd; Questie spirit 161852 there)'),
(7916530, 2300532, 1, 0, 0, 1, 1, -3532.4, -777.5, 144.29, 1.2, 0, 0, 0.564642, 0.825336, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; SOURCED-ATLAS sighting by the kodo skeleton (-3533.8, -772.0) on the Grimtotem Mountain Path'),
(7916531, 2300532, 1, 0, 0, 1, 1, -3483, -838, 84.701, 2, 0, 0, 0.841471, 0.540302, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; in the ravine under the plank bridge by the second kodo skeleton (-3485.5, -836.7)'),
(7916532, 2300532, 1, 0, 0, 1, 1, -3487.5, -897, 105.032, 0.4, 0, 0, 0.198669, 0.980067, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; by the stone benches (-3490.3, -897.8) on the lower climb of the Grimtotem Mountain Path'),
(7916533, 2300532, 1, 0, 0, 1, 1, -3466.5, -909, 110.735, 5.1, 0, 0, 0.557684, -0.830054, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; by the path totem (-3464.7, -913.9) on the Grimtotem Mountain Path'),
(7916534, 2300532, 1, 0, 0, 1, 1, -3446, -907.5, 113.326, 3.3, 0, 0, 0.996865, -0.079121, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; south landing of the plank bridge beside the totem (-3448.7, -901.6)'),
(7916535, 2300532, 1, 0, 0, 1, 1, -3466, -771.5, 125.745, 0.9, 0, 0, 0.434966, 0.900447, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; north landing of the plank bridge'),
(7916536, 2300532, 1, 0, 0, 1, 1, -3478, -776.5, 128.993, 2.7, 0, 0, 0.975723, 0.219007, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; by the stone benches (-3479.8, -773.1) on the Grimtotem Mountain Path'),
(7916537, 2300532, 1, 0, 0, 1, 1, -3500, -780, 135.353, 4.2, 0, 0, 0.863209, -0.504846, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; at the bend of the Grimtotem Mountain Path below the kodo skeleton'),
(7916538, 2300532, 1, 0, 0, 1, 1, -3515, -768.5, 139.376, 1.9, 0, 0, 0.813416, 0.581683, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; on the grass shoulder of the Grimtotem Mountain Path'),
(7916539, 2300532, 1, 0, 0, 1, 1, -3536.5, -794.5, 151.823, 5.6, 0, 0, 0.334988, -0.942222, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; by the stone bench (-3534.1, -790.1) on the Grimtotem Mountain Path'),
(7916540, 2300532, 1, 0, 0, 1, 1, -3540.5, -822, 158.222, 0.7, 0, 0, 0.342898, 0.939373, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; on the upper climb of the Grimtotem Mountain Path'),
(7916541, 2300532, 1, 0, 0, 1, 1, -3569, -856, 168.648, 3.9, 0, 0, 0.92896, -0.370181, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; by the stone benches (-3572.2, -859.8) on the Grimtotem Mountain Path'),
(7916542, 2300532, 1, 0, 0, 1, 1, -3576, -889, 177.537, 2.4, 0, 0, 0.932039, 0.362358, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; at the upper switchback of the Grimtotem Mountain Path'),
(7916543, 2300532, 1, 0, 0, 1, 1, -3572.5, -909, 181.169, 4.4, 0, 0, 0.808496, -0.588501, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; by the path totem (-3571.6, -906.1) below the bridge'),
(7916544, 2300532, 1, 0, 0, 1, 1, -3431, -864, 66.876, 0.2, 0, 0, 0.099833, 0.995004, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; at the foot of the Grimtotem Mountain Path where it leaves the plain'),
(7916545, 2300532, 1, 0, 0, 1, 1, -3456, -869, 73.554, 3.1, 0, 0, 0.999784, 0.020795, 120, 100, 1, '', 'CoA Three Totems: Offering Bone; on the lower climb of the Grimtotem Mountain Path');

-- The Cruel Carrion Spirit circles over the lake by the battlefield.
DELETE FROM `creature_addon` WHERE `guid` = 9011005;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(9011005, 90110050, 0, 0, 1, 0, 0, NULL);

DELETE FROM `waypoint_data` WHERE `id` = 90110050;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`)
VALUES
(90110050, 1, -3509, -1105, 221, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 2, -3512, -1099, 221, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 3, -3520, -1098, 221, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 4, -3527, -1103, 221, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 5, -3527, -1111, 221, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 6, -3521, -1116, 221, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 7, -3513, -1115, 221, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 8, -3484, -1122, 206.5, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 9, -3509, -1111, 221, NULL, 0, 0, 0, 0, 0, 100, 0);

-- ---------------------------------------------------------------------------
-- 8. Scripts
-- ---------------------------------------------------------------------------
-- Malgorm hands his attacker to the nearby guards and warriors, who take his faction until they evade.
-- Each totem credits its use and releases its spirit. Areatrigger rows use source_type 2.
DELETE FROM `conditions` WHERE `SourceEntry` IN (2300527, 2300533, 2300534) AND `SourceTypeOrReferenceId` = 22 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 2300527, 1, 0, 9, 0, 1660034, 0, 0, 0, 0, 0, '', 'Aquiline Totem: Death by Laughter taken'),
(22, 1, 2300533, 1, 0, 9, 0, 1660034, 0, 0, 0, 0, 0, '', 'Owlish Totem: Death by Laughter taken'),
(22, 1, 2300534, 1, 0, 9, 0, 1660034, 0, 0, 0, 0, 0, '', 'Taurine Totem: Death by Laughter taken');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161814, 161816, 161819, 161837) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(161814, 0, 0, 1, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 2, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Warrior - On Data Set 1 1 - Take Malgorm''s side'),
(161814, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Warrior - Linked - Attack Malgorm''s attacker'),
(161814, 0, 2, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Warrior - On Evade - Restore the village faction'),
(161814, 0, 3, 0, 1, 0, 100, 0, 5000, 5000, 5000, 5000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Warrior - Out of Combat every 5 s - Restore the village faction'),
(161816, 0, 0, 1, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Malgorm Hollowhoof - On Aggro - Store the attacker'),
(161816, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 9, 161837, 0, 40, 1, 0, 0, 0, 0, 'Malgorm Hollowhoof - Linked - Send the attacker to the Grimtotem Guards within 40 yd'),
(161816, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 9, 161814, 0, 30, 1, 0, 0, 0, 0, 'Malgorm Hollowhoof - Linked - Send the attacker to the Grimtotem Warriors within 30 yd'),
(161816, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 9, 161837, 0, 40, 1, 0, 0, 0, 0, 'Malgorm Hollowhoof - Linked - Call the Grimtotem Guards within 40 yd'),
(161816, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 9, 161814, 0, 30, 1, 0, 0, 0, 0, 'Malgorm Hollowhoof - Linked - Call the Grimtotem Warriors within 30 yd'),
(161819, 0, 0, 1, 62, 0, 100, 0, 932450, 0, 0, 0, 0, 0, 33, 161823, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sage Nauchol - On Gossip Option 0 Selected - Quest Credit Ask Nauchol to dress you in the disguise'),
(161819, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sage Nauchol - Linked - Close Gossip'),
(161819, 0, 2, 0, 62, 0, 100, 0, 932450, 0, 0, 0, 0, 0, 134, 256709, 34, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sage Nauchol - On Gossip Option 0 Selected - Invoker Casts Grimtotem Disguise 256709'),
(161819, 0, 3, 0, 62, 0, 100, 0, 932450, 0, 0, 0, 0, 0, 134, 256710, 34, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sage Nauchol - On Gossip Option 0 Selected - Invoker Casts Grimtotem Disguise 256710'),
(161837, 0, 0, 1, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 2, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Guard - On Data Set 1 1 - Take Malgorm''s side'),
(161837, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Guard - Linked - Attack Malgorm''s attacker'),
(161837, 0, 2, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Guard - On Evade - Restore the village faction'),
(161837, 0, 3, 0, 1, 0, 100, 0, 5000, 5000, 5000, 5000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Guard - Out of Combat every 5 s - Restore the village faction');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300527, 2300533, 2300534) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300527, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 161849, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aquiline Totem - On Gossip Hello - Quest Credit Totems altered'),
(2300527, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161850, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, -3547.5, -1207, 205.527, 4, 'Aquiline Totem - Linked - Summon its guardian spirit to attack the invoker'),
(2300527, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aquiline Totem - Linked - Fade for 60 seconds'),
(2300533, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 161849, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Owlish Totem - On Gossip Hello - Quest Credit Totems altered'),
(2300533, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161851, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, -3582.5, -1121, 205.775, 3.8, 'Owlish Totem - Linked - Summon its guardian spirit to attack the invoker'),
(2300533, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Owlish Totem - Linked - Fade for 60 seconds'),
(2300534, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 161849, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Taurine Totem - On Gossip Hello - Quest Credit Totems altered'),
(2300534, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161852, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, -3500.5, -1204, 212.906, 5.5, 'Taurine Totem - Linked - Summon its guardian spirit to attack the invoker'),
(2300534, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Taurine Totem - Linked - Fade for 60 seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 6140 AND `source_type` = 2;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(6140, 2, 0, 0, 46, 0, 100, 0, 6140, 0, 0, 0, 0, 0, 33, 161822, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Areatrigger 6140 - On Trigger - Quest Credit Hard Basin discovered');
