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
