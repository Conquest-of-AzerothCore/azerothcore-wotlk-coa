-- Nests and Feathers (175065): the three Nests on the ground floor inside the Gryphon Breeding Bastion go (two under
-- the stairs, one by the south-west wall). The gryphon that sat on one of them moves to an outdoor nest that had
-- none, and the other two bare outdoor nests get a Daumor Gryphon each, 0.8 yd above the nest and facing as it does,
-- like the rest.
DELETE FROM `gameobject` WHERE `guid` IN (9983005, 9983006, 9983008) AND `id` = 2300669;

UPDATE `creature` SET `position_x` = -7254, `position_y` = 422.5, `position_z` = 478.59, `orientation` = 4.1763 WHERE `guid` = 9960382 AND `id` = 164188;

DELETE FROM `creature` WHERE `guid` IN (9993200, 9993201);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9993200, 164188, 0, 0, 0, 1, 1, 0, -7255.4, 437.5, 470.97, 0.3987, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Daumor Gryphon on the west snowfield nest'),
(9993201, 164188, 0, 0, 0, 1, 1, 0, -7288.4, 462.8, 465.68, 0.3987, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Daumor Gryphon on the far south-west slope nest');

-- A cleaned Nest kept sparkling and could be cleaned again at once. The Nest (2300669) is now consumed when cleaned and
-- comes back when its gryphon respawns on it (rev_20261108_9980), or after its own respawn time where no gryphon
-- left. So that the nest itself never vanishes, each has a plain copy of the model (2399013, size 0.99) under it.
UPDATE `gameobject_template` SET `Data5` = 1 WHERE `entry` = 2300669;

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data8`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(2399013, 5, 7395, 'Nest', '', '', '', 0.99, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`);

DELETE FROM `gameobject` WHERE `guid` BETWEEN 9993110 AND 9993120;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9993110, 2399013, 0, 0, 0, 1, 1, -7242, 417.7, 477.74, 4.9929, 0, 0, 0.601312, -0.799014, 120, 255, 1, '', 0, 'Plain nest under Nest 9983001'),
(9993111, 2399013, 0, 0, 0, 1, 1, -7259, 410.8, 481.99, 1.9004, 0, 0, 0.813532, 0.58152, 120, 255, 1, '', 0, 'Plain nest under Nest 9983002'),
(9993112, 2399013, 0, 0, 0, 1, 1, -7254, 422.5, 477.79, 4.1763, 0, 0, 0.869131, -0.494582, 120, 255, 1, '', 0, 'Plain nest under Nest 9983003'),
(9993113, 2399013, 0, 0, 0, 1, 1, -7252.1, 395.1, 493.59, 4.4263, 0, 0, 0.800688, -0.599082, 120, 255, 1, '', 0, 'Plain nest under Nest 9983004'),
(9993114, 2399013, 0, 0, 0, 1, 1, -7269, 398.7, 481.88, 2.722, 0, 0, 0.978073, 0.208261, 120, 255, 1, '', 0, 'Plain nest under Nest 9983007'),
(9993115, 2399013, 0, 0, 0, 1, 1, -7243.3, 381.9, 482.07, 0.9772, 0, 0, 0.46939, 0.882991, 120, 255, 1, '', 0, 'Plain nest under Nest 9983009'),
(9993116, 2399013, 0, 0, 0, 1, 1, -7255.4, 437.5, 470.17, 0.3987, 0, 0, 0.198032, 0.980196, 120, 255, 1, '', 0, 'Plain nest under Nest 9983010'),
(9993117, 2399013, 0, 0, 0, 1, 1, -7262.7, 382.3, 482.21, 1.3936, 0, 0, 0.641767, 0.7669, 120, 255, 1, '', 0, 'Plain nest under Nest 9983011'),
(9993118, 2399013, 0, 0, 0, 1, 1, -7217.4, 430.5, 467.96, 5.854, 0, 0, 0.212949, -0.977063, 120, 255, 1, '', 0, 'Plain nest under Nest 9983012'),
(9993119, 2399013, 0, 0, 0, 1, 1, -7225.3, 468.5, 460.04, 0.3987, 0, 0, 0.198032, 0.980196, 120, 255, 1, '', 0, 'Plain nest under Nest 9983013'),
(9993120, 2399013, 0, 0, 0, 1, 1, -7288.4, 462.8, 464.88, 0.3987, 0, 0, 0.198032, 0.980196, 120, 255, 1, '', 0, 'Plain nest under Nest 9983014');
