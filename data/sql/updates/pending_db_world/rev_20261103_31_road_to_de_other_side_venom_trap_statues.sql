-- Road to De Other Side (map 937): the snake head statues on the three flights of stairs up to the Chimeric Embryo spit
-- Venom Trap (256923) again (#10285): first flight, second, third, then from the start. Trap (162975) is in every log
-- (Venom Trap cast 294 times in the 2026-08-24 Normal run, hits 205 median) but had no spawns. One trap per statue
-- (sinisterlair_snakeheadstatue_01 in vt_sinisterlair_dungeon.wmo), 2 yards in front of it, 2 yards above its base
-- and facing the statue across the stairs (inside the statue it had no line of sight); a flight fires every 6 s,
-- 2 s after the one below, at a character in its 24 degree cone (npc_coa_other_side_venom_trap).
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` BETWEEN -9370618 AND -9370601;
DELETE FROM `creature` WHERE `guid` BETWEEN 9370601 AND 9370618;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9370601,162975,937,0,0,7,1,0,418.87,52.89,275.15,5.8469,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370602,162975,937,0,0,7,1,0,428.57,48.38,275.15,2.7053,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370603,162975,937,0,0,7,1,0,415.02,43.95,280.58,5.8470,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370604,162975,937,0,0,7,1,0,424.23,39.65,280.58,2.7054,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370605,162975,937,0,0,7,1,0,410.5,34.28,287.91,5.8467,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370606,162975,937,0,0,7,1,0,419.7,30.0,287.91,2.7051,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370607,162975,937,0,0,7,1,0,370.58,-52.29,300.65,5.8464,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370608,162975,937,0,0,7,1,0,379.04,-56.23,300.65,2.7048,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370609,162975,937,0,0,7,1,0,366.81,-60.03,305.31,5.8471,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370610,162975,937,0,0,7,1,0,375.53,-64.1,305.31,2.7055,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370611,162975,937,0,0,7,1,0,362.69,-68.1,310.22,5.8462,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370612,162975,937,0,0,7,1,0,372.0,-72.44,310.22,2.7046,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370613,162975,937,0,0,7,1,0,322.25,-153.75,335.47,5.8470,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370614,162975,937,0,0,7,1,0,332.38,-158.48,335.47,2.7054,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370615,162975,937,0,0,7,1,0,317.64,-162.7,342.24,5.8470,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370616,162975,937,0,0,7,1,0,328.48,-167.76,342.24,2.7054,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370617,162975,937,0,0,7,1,0,312.68,-171.91,349.22,5.8469,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370618,162975,937,0,0,7,1,0,324.63,-177.47,349.22,2.7053,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs');
UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_coa_other_side_venom_trap' WHERE `entry` = 162975;
