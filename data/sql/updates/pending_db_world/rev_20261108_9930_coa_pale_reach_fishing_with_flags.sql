-- Fishing With Flags (175165) had no source for Kazadmere Fish 559944 (#9424, #9714, #10402, #10533, #11042, #11094).
-- The quest never reached players on the realm, so its mechanics are a new design built on the realm quest text: two
-- flags stand in the open water of each of the three holes in Lake Kazadmere, and pulling one during the quest lands
-- either a dead fish at the player's feet (2 in 3) or a Berserk Kazadmere Fish that attacks (1 in 3), with the
-- bobber's hooked sound. A pulled flag is used up for 20 s and a plain copy stands in, so it stops sparkling.
-- Thirty small fish per hole hop constantly on the ice as in V10AMkhYl6c 1:27:56-1:28:12; they cannot be targeted.
UPDATE `creature_template` SET `minlevel` = 1, `maxlevel` = 1, `faction` = 35, `npcflag` = 0, `unit_flags` = 33554434,
`gossip_menu_id` = 0, `AIName` = 'SmartAI', `lootid` = 0, `MovementType` = 0 WHERE `entry` = 165511;
UPDATE `creature_template_model` SET `DisplayScale` = 0.05 WHERE `CreatureID` = 165511;

DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (165511, 165634);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES
(165511, 1, 1, 0, 0, 0, 0, 0),
(165634, 0, 1, 0, 0, 0, 0, 0);

DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 165511;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` = 165511;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 165511;
DELETE FROM `creature_loot_template` WHERE `Entry` = 165511;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 165511 AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (16551100, 16551101) AND `source_type` = 9;

INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`,
`unit_class`, `unit_flags`, `type`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`) VALUES
(165634, 'Berserk Kazadmere Fish', 22, 24, 14, 0, 0.8, 0.8, 1, 0, 1, 165634, 'SmartAI', 0, 0.8, 0.8)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`),
`unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `lootid` = VALUES(`lootid`),
`AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`),
`DamageModifier` = VALUES(`DamageModifier`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 165634;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(165634, 0, 39732, 0.5, 1, 0);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 39732;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`) VALUES
(39732, 1, 8, 2, 0, 0);

DELETE FROM `creature_loot_template` WHERE `Entry` = 165634;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(165634, 559944, 0, 100, 1, 1, 0, 1, 1, 'Berserk Kazadmere Fish - Kazadmere Fish');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 165634 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `target_type`, `comment`) VALUES
(165634, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 11, 8599, 0, 0, 0, 1, 'Berserk Kazadmere Fish - On Aggro - Cast Enrage'),
(165634, 0, 1, 0, 0, 0, 100, 0, 2000, 4000, 7000, 10000, 11, 3391, 0, 0, 0, 2, 'Berserk Kazadmere Fish - In Combat - Cast Thrash');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 165634 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `comment`) VALUES
(165634, 0, 2, 0, 54, 0, 100, 0, 0, 0, 0, 0, 49, 0, 0, 0, 21, 20, 0, 0, 0, 0, 0, 'Berserk Kazadmere Fish - On Summoned - Attack the closest player');

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data8`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(2399006, 10, 300355, 'Fishing Flag', 'Interact', '', '', 1, 0, 175165, 0, 1, 0, 1, 0, 'SmartGameObjectAI', '', 0),
(2399007, 3, 242, 'Kazadmere Fish', 'LootAll', '', '', 1, 57, 2399007, 0, 1, 0, 0, 175165, '', '', 0),
(2399008, 5, 300355, 'Fishing Flag', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`),
`size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data3` = VALUES(`Data3`), `Data5` = VALUES(`Data5`), `Data8` = VALUES(`Data8`),
`AIName` = VALUES(`AIName`);

DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2399007;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2399007, 559944, 0, 100, 1, 1, 0, 1, 1, 'Kazadmere Fish');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-9993010, -9993011, -9993012, 2399006) AND `source_type` = 1;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (239900600, 239900601) AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `target_type`, `comment`) VALUES
(2399006, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 4, 3355, 0, 0, 0, 7, 'Fishing Flag - On Use - Play Fishing Hooked'),
(2399006, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 50, 2399008, 21, 0, 0, 1, 'Fishing Flag - Linked - Stand a plain flag in its place while it rests'),
(2399006, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 87, 239900600, 239900600, 239900601, 0, 1, 'Fishing Flag - Linked - Land a dead fish (2/3) or a berserk one (1/3)'),
(239900600, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 50, 2399007, 60, 0, 0, 7, 'Fishing Flag - Dead fish - Leave the catch at the invoker for 60 s');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 239900601 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `comment`) VALUES
(239900601, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 12, 165634, 4, 60000, 1, 0, 0, 0, 0, 0, -1, 'Fishing Flag - Berserk fish - Summon it in the water below the flag');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` IN (-9993010, -9993011, -9993012, 2399006);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 2399006, 1, 0, 47, 0, 175165, 8, 0, 0, 0, 0, '', 'Fishing Flag: works only while Fishing With Flags is in progress');

-- Replaces the unpublished playtest fish and flags (creature 9998350-9998358, gameobject 9999304-9999306).
DELETE FROM `creature` WHERE `guid` BETWEEN 9998350 AND 9998358 AND `id` = 165511;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-9999304, -9999305, -9999306) AND `source_type` = 1;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` IN (-9999304, -9999305, -9999306) AND `SourceId` = 1;
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9999304 AND 9999306 AND `id` = 2399006;

DELETE FROM `creature` WHERE `guid` BETWEEN 9993000 AND 9993099 AND `id` = 165511;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(9993000, 165511, 0, 0, 0, 1, 1, 0, -6146.56, -533.58, 505.22, 2.84, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993001, 165511, 0, 0, 0, 1, 1, 0, -6137.94, -524.88, 505.11, 3.52, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993002, 165511, 0, 0, 0, 1, 1, 0, -6150.93, -530.28, 505.07, 5.80, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993003, 165511, 0, 0, 0, 1, 1, 0, -6142.27, -534.61, 505.06, 2.92, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993004, 165511, 0, 0, 0, 1, 1, 0, -6141.20, -543.26, 504.98, 3.19, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993005, 165511, 0, 0, 0, 1, 1, 0, -6134.69, -525.95, 505.09, 3.69, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993006, 165511, 0, 0, 0, 1, 1, 0, -6144.39, -524.99, 505.32, 1.16, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993007, 165511, 0, 0, 0, 1, 1, 0, -6135.77, -532.45, 505.09, 3.21, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993008, 165511, 0, 0, 0, 1, 1, 0, -6139.02, -528.11, 505.07, 3.96, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993009, 165511, 0, 0, 0, 1, 1, 0, -6137.92, -544.40, 505.37, 4.98, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993010, 165511, 0, 0, 0, 1, 1, 0, -6148.72, -533.58, 505.22, 0.59, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993011, 165511, 0, 0, 0, 1, 1, 0, -6141.19, -535.69, 505.06, 1.91, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993012, 165511, 0, 0, 0, 1, 1, 0, -6143.30, -545.47, 505.33, 0.57, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993013, 165511, 0, 0, 0, 1, 1, 0, -6136.85, -541.14, 505.22, 5.08, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993014, 165511, 0, 0, 0, 1, 1, 0, -6141.19, -527.04, 505.09, 4.35, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993015, 165511, 0, 0, 0, 1, 1, 0, -6144.43, -540.02, 505.05, 0.26, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993016, 165511, 0, 0, 0, 1, 1, 0, -6135.76, -546.55, 505.41, 6.17, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993017, 165511, 0, 0, 0, 1, 1, 0, -6149.70, -530.49, 505.59, 6.06, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993018, 165511, 0, 0, 0, 1, 1, 0, -6131.45, -540.05, 505.19, 4.11, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993019, 165511, 0, 0, 0, 1, 1, 0, -6152.00, -527.05, 505.11, 3.87, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993020, 165511, 0, 0, 0, 1, 1, 0, -6142.27, -537.86, 505.06, 0.99, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993021, 165511, 0, 0, 0, 1, 1, 0, -6142.27, -529.20, 505.07, 0.09, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993022, 165511, 0, 0, 0, 1, 1, 0, -6147.57, -530.46, 505.53, 3.32, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993023, 165511, 0, 0, 0, 1, 1, 0, -6148.62, -543.36, 505.59, 0.37, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993024, 165511, 0, 0, 0, 1, 1, 0, -6144.44, -528.11, 505.07, 1.19, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993025, 165511, 0, 0, 0, 1, 1, 0, -6148.67, -545.48, 505.38, 1.52, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993026, 165511, 0, 0, 0, 1, 1, 0, -6132.53, -541.14, 505.20, 0.19, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993027, 165511, 0, 0, 0, 1, 1, 0, -6134.69, -536.75, 504.95, 2.91, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993028, 165511, 0, 0, 0, 1, 1, 0, -6146.47, -543.36, 505.62, 2.77, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993029, 165511, 0, 0, 0, 1, 1, 0, -6152.00, -529.22, 505.12, 5.29, 30, 0, 0, 'Fish: Lake Kazadmere north hole'),
(9993030, 165511, 0, 0, 0, 1, 1, 0, -6120.13, -556.35, 505.46, 3.26, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993031, 165511, 0, 0, 0, 1, 1, 0, -6122.23, -557.44, 505.23, 4.02, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993032, 165511, 0, 0, 0, 1, 1, 0, -6112.50, -553.13, 505.18, 3.14, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993033, 165511, 0, 0, 0, 1, 1, 0, -6116.92, -562.78, 505.48, 4.16, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993034, 165511, 0, 0, 0, 1, 1, 0, -6114.78, -556.34, 505.51, 2.87, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993035, 165511, 0, 0, 0, 1, 1, 0, -6112.51, -565.00, 505.19, 1.75, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993036, 165511, 0, 0, 0, 1, 1, 0, -6115.75, -558.52, 505.20, 6.27, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993037, 165511, 0, 0, 0, 1, 1, 0, -6111.35, -560.71, 505.01, 6.25, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993038, 165511, 0, 0, 0, 1, 1, 0, -6123.35, -566.02, 505.42, 5.28, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993039, 165511, 0, 0, 0, 1, 1, 0, -6121.17, -555.28, 505.31, 4.45, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993040, 165511, 0, 0, 0, 1, 1, 0, -6119.11, -554.19, 505.67, 1.98, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993041, 165511, 0, 0, 0, 1, 1, 0, -6113.63, -557.44, 505.30, 1.44, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993042, 165511, 0, 0, 0, 1, 1, 0, -6124.40, -558.51, 505.30, 1.82, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993043, 165511, 0, 0, 0, 1, 1, 0, -6124.39, -556.36, 505.27, 0.44, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993044, 165511, 0, 0, 0, 1, 1, 0, -6120.05, -559.61, 505.16, 4.81, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993045, 165511, 0, 0, 0, 1, 1, 0, -6123.31, -555.28, 505.26, 2.51, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993046, 165511, 0, 0, 0, 1, 1, 0, -6124.39, -554.21, 505.26, 5.32, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993047, 165511, 0, 0, 0, 1, 1, 0, -6114.70, -553.13, 505.29, 2.43, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993048, 165511, 0, 0, 0, 1, 1, 0, -6113.61, -566.06, 505.23, 6.02, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993049, 165511, 0, 0, 0, 1, 1, 0, -6123.38, -559.55, 505.59, 5.32, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993050, 165511, 0, 0, 0, 1, 1, 0, -6121.20, -564.94, 505.42, 0.00, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993051, 165511, 0, 0, 0, 1, 1, 0, -6116.83, -553.13, 505.21, 1.32, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993052, 165511, 0, 0, 0, 1, 1, 0, -6121.13, -560.69, 505.16, 5.72, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993053, 165511, 0, 0, 0, 1, 1, 0, -6116.83, -560.68, 505.20, 2.95, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993054, 165511, 0, 0, 0, 1, 1, 0, -6115.88, -563.83, 505.59, 6.16, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993055, 165511, 0, 0, 0, 1, 1, 0, -6111.44, -558.52, 505.21, 2.50, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993056, 165511, 0, 0, 0, 1, 1, 0, -6112.50, -559.61, 505.18, 0.46, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993057, 165511, 0, 0, 0, 1, 1, 0, -6120.17, -562.76, 505.61, 3.95, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993058, 165511, 0, 0, 0, 1, 1, 0, -6115.82, -555.27, 505.41, 4.89, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993059, 165511, 0, 0, 0, 1, 1, 0, -6116.96, -557.40, 505.64, 1.69, 30, 0, 0, 'Fish: Lake Kazadmere east hole'),
(9993060, 165511, 0, 0, 0, 1, 1, 0, -6153.70, -558.74, 505.35, 0.55, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993061, 165511, 0, 0, 0, 1, 1, 0, -6139.71, -559.82, 505.33, 2.09, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993062, 165511, 0, 0, 0, 1, 1, 0, -6151.55, -557.67, 505.34, 6.05, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993063, 165511, 0, 0, 0, 1, 1, 0, -6150.48, -556.59, 505.33, 4.76, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993064, 165511, 0, 0, 0, 1, 1, 0, -6141.82, -560.86, 505.60, 0.74, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993065, 165511, 0, 0, 0, 1, 1, 0, -6153.68, -566.26, 505.39, 1.55, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993066, 165511, 0, 0, 0, 1, 1, 0, -6140.78, -566.27, 505.35, 0.63, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993067, 165511, 0, 0, 0, 1, 1, 0, -6150.42, -564.09, 505.51, 0.38, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993068, 165511, 0, 0, 0, 1, 1, 0, -6141.87, -555.52, 505.31, 5.01, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993069, 165511, 0, 0, 0, 1, 1, 0, -6153.69, -561.97, 505.37, 1.12, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993070, 165511, 0, 0, 0, 1, 1, 0, -6151.50, -568.39, 505.47, 3.51, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993071, 165511, 0, 0, 0, 1, 1, 0, -6145.01, -565.10, 505.75, 2.81, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993072, 165511, 0, 0, 0, 1, 1, 0, -6141.84, -563.02, 505.49, 1.20, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993073, 165511, 0, 0, 0, 1, 1, 0, -6152.45, -560.82, 505.85, 4.60, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993074, 165511, 0, 0, 0, 1, 1, 0, -6147.20, -564.09, 505.49, 0.82, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993075, 165511, 0, 0, 0, 1, 1, 0, -6152.60, -565.19, 505.39, 4.04, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993076, 165511, 0, 0, 0, 1, 1, 0, -6141.86, -557.67, 505.35, 0.73, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993077, 165511, 0, 0, 0, 1, 1, 0, -6152.63, -555.52, 505.33, 2.64, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993078, 165511, 0, 0, 0, 1, 1, 0, -6149.35, -567.31, 505.48, 1.34, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993079, 165511, 0, 0, 0, 1, 1, 0, -6139.71, -565.20, 505.34, 1.69, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993080, 165511, 0, 0, 0, 1, 1, 0, -6147.25, -555.52, 505.32, 6.10, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993081, 165511, 0, 0, 0, 1, 1, 0, -6152.42, -562.93, 505.93, 5.05, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993082, 165511, 0, 0, 0, 1, 1, 0, -6144.01, -558.74, 505.39, 1.91, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993083, 165511, 0, 0, 0, 1, 1, 0, -6146.20, -560.92, 505.19, 5.56, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993084, 165511, 0, 0, 0, 1, 1, 0, -6144.03, -563.07, 505.22, 1.32, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993085, 165511, 0, 0, 0, 1, 1, 0, -6149.24, -562.94, 505.88, 2.48, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993086, 165511, 0, 0, 0, 1, 1, 0, -6139.71, -567.35, 505.35, 5.37, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993087, 165511, 0, 0, 0, 1, 1, 0, -6140.78, -558.74, 505.40, 4.03, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993088, 165511, 0, 0, 0, 1, 1, 0, -6146.08, -568.32, 505.71, 0.63, 30, 0, 0, 'Fish: Lake Kazadmere south hole'),
(9993089, 165511, 0, 0, 0, 1, 1, 0, -6140.79, -556.60, 505.31, 6.21, 30, 0, 0, 'Fish: Lake Kazadmere south hole');

DELETE FROM `smart_scripts` WHERE `entryorguid` BETWEEN -9993099 AND -9993000 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `comment`) VALUES
(-9993000, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6146.56, -533.58, 505.22, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993001, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6137.94, -524.88, 505.11, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993002, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6150.93, -530.28, 505.07, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993003, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6142.27, -534.61, 505.06, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993004, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6141.20, -543.26, 504.98, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993005, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6134.69, -525.95, 505.09, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993006, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6144.39, -524.99, 505.32, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993007, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6135.77, -532.45, 505.09, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993008, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6139.02, -528.11, 505.07, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993009, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6137.92, -544.40, 505.37, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993010, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6148.72, -533.58, 505.22, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993011, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6141.19, -535.69, 505.06, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993012, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6143.30, -545.47, 505.33, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993013, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6136.85, -541.14, 505.22, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993014, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6141.19, -527.04, 505.09, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993015, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6144.43, -540.02, 505.05, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993016, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6135.76, -546.55, 505.41, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993017, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6149.70, -530.49, 505.59, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993018, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6131.45, -540.05, 505.19, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993019, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6152.00, -527.05, 505.11, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993020, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6142.27, -537.86, 505.06, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993021, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6142.27, -529.20, 505.07, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993022, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6147.57, -530.46, 505.53, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993023, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6148.62, -543.36, 505.59, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993024, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6144.44, -528.11, 505.07, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993025, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6148.67, -545.48, 505.38, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993026, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6132.53, -541.14, 505.20, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993027, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6134.69, -536.75, 504.95, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993028, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6146.47, -543.36, 505.62, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993029, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6152.00, -529.22, 505.12, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993030, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6120.13, -556.35, 505.46, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993031, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6122.23, -557.44, 505.23, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993032, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6112.50, -553.13, 505.18, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993033, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6116.92, -562.78, 505.48, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993034, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6114.78, -556.34, 505.51, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993035, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6112.51, -565.00, 505.19, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993036, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6115.75, -558.52, 505.20, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993037, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6111.35, -560.71, 505.01, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993038, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6123.35, -566.02, 505.42, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993039, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6121.17, -555.28, 505.31, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993040, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6119.11, -554.19, 505.67, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993041, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6113.63, -557.44, 505.30, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993042, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6124.40, -558.51, 505.30, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993043, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6124.39, -556.36, 505.27, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993044, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6120.05, -559.61, 505.16, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993045, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6123.31, -555.28, 505.26, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993046, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6124.39, -554.21, 505.26, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993047, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6114.70, -553.13, 505.29, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993048, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6113.61, -566.06, 505.23, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993049, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6123.38, -559.55, 505.59, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993050, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6121.20, -564.94, 505.42, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993051, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6116.83, -553.13, 505.21, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993052, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6121.13, -560.69, 505.16, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993053, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6116.83, -560.68, 505.20, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993054, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6115.88, -563.83, 505.59, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993055, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6111.44, -558.52, 505.21, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993056, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6112.50, -559.61, 505.18, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993057, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6120.17, -562.76, 505.61, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993058, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6115.82, -555.27, 505.41, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993059, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6116.96, -557.40, 505.64, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993060, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6153.70, -558.74, 505.35, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993061, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6139.71, -559.82, 505.33, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993062, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6151.55, -557.67, 505.34, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993063, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6150.48, -556.59, 505.33, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993064, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6141.82, -560.86, 505.60, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993065, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6153.68, -566.26, 505.39, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993066, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6140.78, -566.27, 505.35, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993067, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6150.42, -564.09, 505.51, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993068, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6141.87, -555.52, 505.31, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993069, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6153.69, -561.97, 505.37, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993070, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6151.50, -568.39, 505.47, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993071, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6145.01, -565.10, 505.75, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993072, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6141.84, -563.02, 505.49, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993073, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6152.45, -560.82, 505.85, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993074, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6147.20, -564.09, 505.49, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993075, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6152.60, -565.19, 505.39, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993076, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6141.86, -557.67, 505.35, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993077, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6152.63, -555.52, 505.33, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993078, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6149.35, -567.31, 505.48, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993079, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6139.71, -565.20, 505.34, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993080, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6147.25, -555.52, 505.32, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993081, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6152.42, -562.93, 505.93, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993082, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6144.01, -558.74, 505.39, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993083, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6146.20, -560.92, 505.19, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993084, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6144.03, -563.07, 505.22, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993085, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6149.24, -562.94, 505.88, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993086, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6139.71, -567.35, 505.35, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993087, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6140.78, -558.74, 505.40, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993088, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6146.08, -568.32, 505.71, 'Fish - Out of Combat - Hop to a random spot near home'),
(-9993089, 0, 0, 0, 1, 0, 100, 0, 0, 1200, 400, 1200, 97, 6, 6, 0, 202, 2, 1, 0, -6140.79, -556.60, 505.31, 'Fish - Out of Combat - Hop to a random spot near home');

DELETE FROM `gameobject` WHERE `guid` BETWEEN 9993010 AND 9993015;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9993010, 2399006, 0, 0, 0, 1, 1, -6145.60, -533.00, 504.81, 2.07, 0, 0, 0.859862, 0.510526, 20, 0, 1, 'Pale Reach: Lake Kazadmere fishing flag, north hole'),
(9993011, 2399006, 0, 0, 0, 1, 1, -6117.85, -561.23, 504.92, 5.80, 0, 0, 0.239249, -0.970958, 20, 0, 1, 'Pale Reach: Lake Kazadmere fishing flag, east hole'),
(9993012, 2399006, 0, 0, 0, 1, 1, -6146.30, -561.80, 505.08, 4.03, 0, 0, 0.902953, -0.429739, 20, 0, 1, 'Pale Reach: Lake Kazadmere fishing flag, south hole'),
(9993013, 2399006, 0, 0, 0, 1, 1, -6139.53, -537.61, 504.81, 2.07, 0, 0, 0.859862, 0.510526, 20, 0, 1, 'Pale Reach: Lake Kazadmere fishing flag, north hole'),
(9993014, 2399006, 0, 0, 0, 1, 1, -6116.90, -558.97, 504.92, 5.80, 0, 0, 0.239249, -0.970958, 20, 0, 1, 'Pale Reach: Lake Kazadmere fishing flag, east hole'),
(9993015, 2399006, 0, 0, 0, 1, 1, -6147.61, -557.83, 505.08, 4.03, 0, 0, 0.902953, -0.429739, 20, 0, 1, 'Pale Reach: Lake Kazadmere fishing flag, south hole');

-- Lofar 164464 greets players; the line is new (the quest is unreleased and no realm greeting exists).
DELETE FROM `npc_text` WHERE `ID` = 9920304;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(9920304, '<Lofar doesn''t look up from the line he''s untangling.>$B$BCareful where you step. The ice near the holes is thinner than it looks.', '<Lofar doesn''t look up from the line he''s untangling.>$B$BCareful where you step. The ice near the holes is thinner than it looks.', 1);
DELETE FROM `gossip_menu` WHERE `MenuID` = 9920304;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9920304, 9920304);
UPDATE `creature_template` SET `npcflag` = `npcflag` | 1, `gossip_menu_id` = 9920304 WHERE `entry` = 164464;
