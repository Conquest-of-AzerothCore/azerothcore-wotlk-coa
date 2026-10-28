UPDATE `creature_template`
SET `name` = 'Stormfang',
    `subname` = 'the Crackling Fury',
    `rank` = 1
WHERE `entry` = 9916212;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 9916212 AND `id` = 100;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
 `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
 `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`,
 `action_param2`, `action_param3`, `action_param4`, `action_param5`,
 `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
 `target_param4`, `comment`)
VALUES
(9916212, 0, 100, 0, 11, 0,
 100, 0, 0, 0, 0,
 0, 0, 0, 8, 1,
 0, 0, 0, 0,
 0, 1, 0, 0, 0,
 0, 'Stormfang - defensive on spawn');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 9916212 AND `id` IN (10, 11);

DELETE FROM `creature_text` WHERE `CreatureID` = 9916212 AND `GroupID` IN (1, 2);
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`,
 `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(9916212, 1, 0, 'You cannot outrun the thunder.', 14, 0, 100, 0, 0, 0, 0, 0, 'Stormfang phase 2'),
(9916212, 2, 0, 'Overcharge! The hunt ends here.', 14, 0, 100, 0, 0, 0, 0, 0, 'Stormfang phase 3');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 9916212 AND `id` IN (20, 40);
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
 `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
 `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`,
 `action_param2`, `action_param3`, `action_param4`, `action_param5`,
 `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
 `target_param4`, `comment`)
VALUES
(9916212, 0, 20, 0, 2, 0, 100, 0, 0, 65, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 'Stormfang - phase 2 yell'),
(9916212, 0, 40, 0, 2, 0, 100, 0, 0, 30, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 'Stormfang - phase 3 yell');

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9916211;
DELETE FROM `creature_template` WHERE `entry` = 9916211;

INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
 `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `rank`,
 `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `unit_flags`,
 `unit_flags2`, `type`, `type_flags`, `family`, `HealthModifier`,
 `ArmorModifier`, `RegenHealth`, `AIName`, `MovementType`, `ScriptName`,
 `flags_extra`)
VALUES
(9916211, 'Stormfang Spirit Wolf', '', 60, 60, 16, 0,
 1, 1.14286, 1, 1, 0,
 1, 1500, 2000, 0,
 0, 1, 0, 1, 1,
 1, 1, '', 0, '',
 0);

INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 9916211, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`
FROM `creature_template_model`
WHERE `CreatureID` = 29264 AND `Idx` = 0;
