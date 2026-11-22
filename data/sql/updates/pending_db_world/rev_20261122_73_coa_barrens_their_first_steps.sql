-- CoA Barrens: "Their First Steps" (500007) from Elder Thunderhoof (764578), escorting three Baby Thunderheads (764666)
-- home with the Leash (661322, Kodo Leash 993024). Quest values: CoA client capture 2026-09-03 (AscensionDB
-- d6494ceb3150), texts questcache-dawnrise-2026-09-01c. Templates and models: WDB captures 2026-09-04 and Descension
-- coa_creatures.sql (b18d7ee7). The elder stands on the client turn-in marker (SuperTrack 8632), the calves in the
-- client objective area (SuperTrack 8570, radius 40). Levels, factions, calf count, calf positions (z from the ground)
-- and the 661538 model info (taken from the Thunderhead display 1538) are estimated: the archives hold WDB defaults
-- only. A leashed calf follows the player and gives its credit beside the elder. Maintainer approved the archive
-- values (#13163).

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(764578, 'Elder Thunderhoof', NULL, 0, 25, 25, 0, 7, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(764666, 'Baby Thunderhead', NULL, 0, 20, 21, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 1, 0, 0, 'SmartAI', 1, 0.9486, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (764578, 764666);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(764578, 0, 9772, 1, 1),
(764666, 0, 661538, 1, 1);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 661538;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(661538, 1.2, 1.75, 2, 0);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 764666 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(764666, 0, 0, 0, 8, 0, 100, 0, 993024, 0, 0, 0, 0, 0, 29, 2, 0, 764578, 764666, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Baby Thunderhead - On Spellhit ''Kodo Leash'' - Follow Invoker to Elder Thunderhoof (Quest Credit ''Baby Thunderhead Escorted'')');

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `Flags`, `StartItem`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardFactionID1`, `RewardFactionValue1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `RequiredItemId1`, `RequiredItemCount1`, `ObjectiveText1`)
VALUES
(500007, 2, 24, 17, 17, 5, 4200, 900, 8, 661322, 375250, 150, 1397885, 1, 76, 5, 'Their First Steps', 'Three young Thunderheads have become separated from the herd. Guide them safely back to the Sanctuary of the Plains.', 'The kodo have walked these lands longer than any of us. Their steps carved the Barrens into what it is. I have followed them since I was a child, learning the ways of the herd and the stories passed through their line.  But something is wrong. The calves are few, their cries missing from the wind. I have seen the herds shift, restless and incomplete.  To the south, in the Field of Giants, the earth has been stirred by creatures that do not belong. Silithid tunnels, sharp and wrong, burrow too close to the grazing grounds. I fear the young have been taken or scattered.  If you find any calves alive, guide them home. If any have fallen, ensure they are not taken deeper. Bring balance to the herds again. The Barrens will feel their absence until you do.', '', 'Return to Elder Thunderhoof at the Sancuary of the Plains in The Barrens.', 764666, 3, 661322, 1, 'Baby Thunderhead Escorted')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `Flags` = VALUES(`Flags`), `StartItem` = VALUES(`StartItem`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `ObjectiveText1` = VALUES(`ObjectiveText1`);

DELETE FROM `quest_template_addon` WHERE `ID` = 500007;
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `NextQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(500007, 0, 0, 0, 0, 1, 0);

DELETE FROM `creature_queststarter` WHERE `quest` = 500007;
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(764578, 500007);

DELETE FROM `creature_questender` WHERE `quest` = 500007;
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(764578, 500007);

DELETE FROM `creature` WHERE `guid` BETWEEN 9012572 AND 9012578;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9012572, 764578, 1, 0, 0, 1, 1, 0, -2940.37, -2135.21, 91.673, 3.99, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Their First Steps: SuperTrack 8632, the 500007 giver and turn-in; faces the Field of Giants'),
(9012573, 764666, 1, 0, 0, 1, 1, 0, -3117.17, -2334.32, 93.52, 0.8, 60, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Their First Steps: lost calf at SuperTrack 8570'),
(9012574, 764666, 1, 0, 0, 1, 1, 0, -3127, -2346, 91.8, 1.6, 60, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Their First Steps: lost calf in the SuperTrack 8570 area'),
(9012575, 764666, 1, 0, 0, 1, 1, 0, -3104, -2324, 91.69, 3.9, 60, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Their First Steps: lost calf in the SuperTrack 8570 area'),
(9012576, 764666, 1, 0, 0, 1, 1, 0, -3132, -2321, 92.38, 5.5, 60, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Their First Steps: lost calf in the SuperTrack 8570 area'),
(9012577, 764666, 1, 0, 0, 1, 1, 0, -3106, -2349, 94.33, 2.4, 60, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Their First Steps: lost calf in the SuperTrack 8570 area'),
(9012578, 764666, 1, 0, 0, 1, 1, 0, -3094, -2337, 91.92, 3.1, 60, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Their First Steps: lost calf in the SuperTrack 8570 area');
