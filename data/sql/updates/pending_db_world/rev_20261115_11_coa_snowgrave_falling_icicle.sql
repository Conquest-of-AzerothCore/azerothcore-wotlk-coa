-- The icicle Snowgrave brings down falls from the ceiling tip first, as the icicle Hodir drops in Ulduar.
DELETE FROM `creature_template` WHERE `entry` = 978100;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`,
    `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `ScriptName`, `VerifiedBuild`)
SELECT 978100, 'Falling Icicle', '', 60, 60, 0, 35, 0, 1, 1, 0, 1, 33554434, 10, '', '', 12340;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978100;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(978100, 0, 28470, 1, 1, 12340);
