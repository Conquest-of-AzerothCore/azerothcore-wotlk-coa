-- Amphora From The Spring (175084). On the realm the player swims into the Tilted Cliffs spring and uses the Amphora
-- (Fill Amphora 257542); when the cast ends an Arcane Elemental (164240) rises on them and attacks, and the Filled
-- Amphora objective completes only after it dies, with no loot taken (6QNRME4U5pY 00:03:27-00:03:41, RIEMlZSgbQw
-- 04:35:07-04:35:30). Locally the spring bunny swapped the items as soon as a player came near it, so no spirit rose.
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9990037 AND `source_type` = 0;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = -9990037
AND `SourceId` = 0;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 17 AND `SourceGroup` = 0 AND `SourceEntry` = 257542;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
`ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
`NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(17, 0, 257542, 0, 0, 22, 0, 0, 0, 0, 0, 60, 0, '', 'Fill Amphora - only in Eastern Kingdoms'),
(17, 0, 257542, 0, 0, 29, 0, 23837, 15, 0, 0, 60, 0, '', 'Fill Amphora - only at the Tilted Cliffs spring bunny'),
(17, 0, 257542, 0, 0, 40, 0, 0, 0, 0, 0, 96, 0, '', 'Fill Amphora - only while in the water'),
(17, 0, 257542, 0, 0, 29, 0, 164240, 40, 0, 1, 173, 0, '', 'Fill Amphora - not while the spring spirit is up');

DELETE FROM `spell_scripts` WHERE `id` = 257542;
INSERT INTO `spell_scripts` (`id`, `effIndex`, `delay`, `command`, `datalong`, `datalong2`, `dataint`, `x`, `y`, `z`,
`o`) VALUES
(257542, 0, 0, 10, 164240, 60000, 0, -7432, -88, 292.265, 2.36);

-- The realm's spirit is a hostile Arcane Elemental with a mana bar (realm creature cache display 21247, ManaFiend,
-- already its model row), at the level of the Tilted Cliffs yaks.
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23, `faction` = 14, `unit_class` = 8,
`AIName` = 'SmartAI' WHERE `entry` = 164240;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164240 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
`event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
`event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
`action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
`target_y`, `target_z`, `target_o`, `comment`) VALUES
(164240, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
'Arcane Elemental - On Just Summoned - Attack Summoner'),
(164240, 0, 1, 2, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 57, 559898, 1, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0,
'Arcane Elemental - On Death - Take Amphora From Summoner'),
(164240, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 56, 559925, 1, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0,
'Arcane Elemental - Linked - Give Filled Amphora To Summoner');

-- A healed Injured Andraste Soldier (164153, 164263) is restored to full health, cannot be healed again while
-- whole, and is hurt again a minute later. The realm frames show the soldiers standing or lying as before through
-- the heal (RIEMlZSgbQw 04:36:14, hxdp8nA91RA 02:39:00), so their pose is unchanged.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 17 AND `SourceGroup` = 0 AND `SourceEntry` = 257543
AND `ConditionTypeOrReference` = 38;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
`ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
`NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(17, 0, 257543, 0, 0, 38, 1, 100, 2, 0, 0, 2, 0, '', 'Heal Injured only on a soldier below full health'),
(17, 0, 257543, 0, 1, 38, 1, 100, 2, 0, 0, 2, 0, '', 'Heal Injured only on a soldier below full health');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164153, 164263) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
`event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
`event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
`action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
`target_y`, `target_z`, `target_o`, `comment`) VALUES
(164153, 0, 0, 1, 8, 0, 100, 0, 257543, 0, 60000, 60000, 0, 0, 33, 164263, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - On Heal Injured hit - Quest Credit'),
(164153, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - Linked - Set Health 100%'),
(164153, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - Linked - Hurt Again In 60 s'),
(164153, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - On Timed Event - Set Health 10%'),
(164153, 0, 4, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - On Respawn - Set Health 10%'),
(164263, 0, 0, 1, 8, 0, 100, 0, 257543, 0, 60000, 60000, 0, 0, 33, 164263, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - On Heal Injured hit - Quest Credit'),
(164263, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - Linked - Set Health 100%'),
(164263, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - Linked - Hurt Again In 60 s'),
(164263, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - On Timed Event - Set Health 10%'),
(164263, 0, 4, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Injured Andraste Soldier - On Respawn - Set Health 10%');
