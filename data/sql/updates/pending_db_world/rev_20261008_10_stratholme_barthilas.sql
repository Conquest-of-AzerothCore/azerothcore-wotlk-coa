-- Stratholme: Magistrate Barthilas stands at the Service Entrance gate, on every difficulty.
--
-- His SmartAI teleported him to the inner square (4068.74, -3535.97) on every respawn and ran him
-- there on a trigger (path 104350, instance data TYPE_BARTHILAS_RUN), so after a reset or respawn
-- he was found in the wrong place. Those rows go; his fight and gate actions stay.
-- The one spawn left is the hand-placed one at the gate, and it now spawns on Normal, Heroic and
-- Mythic (it was Mythic only, so Normal and Heroic had no Barthilas at all).

DELETE FROM `smart_scripts` WHERE `entryorguid` = 10435 AND `source_type` = 0 AND `id` BETWEEN 12 AND 18;

DELETE FROM `creature` WHERE `id` IN (10435, 110435, 210435) AND `guid` <> 9950286;
DELETE FROM `creature` WHERE `guid` = 9950286;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
(9950286, 10435, 329, 0, 0, 7, 1, 0, 3662.42, -3616.07, 137.481, 2.06036, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL);
