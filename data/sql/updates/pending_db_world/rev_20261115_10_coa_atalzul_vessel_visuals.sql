-- Atal'zul's Soul Vessels wear swirling soul and shadow effects, so they read as dangerous at a glance.
DELETE FROM `creature_template_addon` WHERE `entry` = 67536;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
    `visibilityDistanceType`, `auras`) VALUES
(67536, 0, 0, 0, 0, 0, 3, '72523 69105');
