-- Wounded Dryads (164322) for Amber for the Dryads (175098) lie on their side in the death pose at a fraction of
-- their health (RIEMlZSgbQw 00:22:29-00:22:30, 00:22:36, 00:22:58; i5vATMYui0I 00:23:43). When Amber Healing Touch
-- (365044) lands they get up and run off and are gone about two seconds later (RIEMlZSgbQw 00:22:30-00:22:33,
-- 00:23:00-00:23:02; i5vATMYui0I 00:23:46). Locally they stood at full health.
UPDATE `creature_template` SET `RegenHealth` = 0 WHERE `entry` = 164322;

DELETE FROM `creature_template_addon` WHERE `entry` = 164322;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
`visibilityDistanceType`, `auras`) VALUES
(164322, 0, 0, 7, 1, 0, 0, NULL);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164322 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
`event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
`event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
`action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
`target_y`, `target_z`, `target_o`, `comment`) VALUES
(164322, 0, 0, 1, 8, 0, 100, 0, 365044, 0, 3000, 3000, 0, 0, 33, 164322, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
'Wounded Dryad - On Spellhit Amber Healing Touch - Quest Credit'),
(164322, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 91, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Wounded Dryad - Linked - Stand Up'),
(164322, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Wounded Dryad - Linked - Set Health 100%'),
(164322, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 59, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Wounded Dryad - Linked - Set Run'),
(164322, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 46, 12, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Wounded Dryad - Linked - Run Forward 12 Yards'),
(164322, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Wounded Dryad - Linked - Despawn In 2 s'),
(164322, 0, 6, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 20, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Wounded Dryad - On Respawn - Set Health 20%');
