-- Road to De Other Side (map 937): the snake head statues on the three flights of stairs up to the Chimeric Embryo spit
-- Venom Trap (256923) again (#10285): first flight, second, third, then from the start. Trap (162975) is in every log
-- (Venom Trap cast 294 times in the 2026-08-24 Normal run, hits 205 median) but had no spawns. One trap per statue
-- (sinisterlair_snakeheadstatue_01 in vt_sinisterlair_dungeon.wmo), 1.5 yards above its base and facing the statue
-- across the stairs; a flight fires every 6 s, 2 s after the one below.
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` BETWEEN -9370618 AND -9370601;
DELETE FROM `creature` WHERE `guid` BETWEEN 9370601 AND 9370618;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9370601,162975,937,0,0,7,1,0,417.06,53.74,274.65,5.8469,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370602,162975,937,0,0,7,1,0,430.38,47.53,274.65,2.7053,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370603,162975,937,0,0,7,1,0,413.21,44.79,280.08,5.8470,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370604,162975,937,0,0,7,1,0,426.04,38.81,280.08,2.7054,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370605,162975,937,0,0,7,1,0,408.69,35.13,287.41,5.8467,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370606,162975,937,0,0,7,1,0,421.51,29.15,287.41,2.7051,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, first stairs'),
(9370607,162975,937,0,0,7,1,0,368.77,-51.44,300.15,5.8464,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370608,162975,937,0,0,7,1,0,380.85,-57.08,300.15,2.7048,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370609,162975,937,0,0,7,1,0,365.0,-59.19,304.81,5.8471,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370610,162975,937,0,0,7,1,0,377.34,-64.94,304.81,2.7055,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370611,162975,937,0,0,7,1,0,360.88,-67.25,309.72,5.8462,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370612,162975,937,0,0,7,1,0,373.81,-73.29,309.72,2.7046,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, second stairs'),
(9370613,162975,937,0,0,7,1,0,320.44,-152.91,334.97,5.8470,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370614,162975,937,0,0,7,1,0,334.19,-159.32,334.97,2.7054,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370615,162975,937,0,0,7,1,0,315.83,-161.86,341.74,5.8470,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370616,162975,937,0,0,7,1,0,330.29,-168.6,341.74,2.7054,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370617,162975,937,0,0,7,1,0,310.87,-171.06,348.72,5.8469,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs'),
(9370618,162975,937,0,0,7,1,0,326.44,-178.32,348.72,2.7053,300,0,0,0,0,0,0,0,0,'',0,0,'Venom Trap statue, third stairs');
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 162975;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9370601,0,0,0,1,0,100,0,0,0,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (first stairs)'),
(-9370602,0,0,0,1,0,100,0,0,0,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (first stairs)'),
(-9370603,0,0,0,1,0,100,0,0,0,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (first stairs)'),
(-9370604,0,0,0,1,0,100,0,0,0,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (first stairs)'),
(-9370605,0,0,0,1,0,100,0,0,0,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (first stairs)'),
(-9370606,0,0,0,1,0,100,0,0,0,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (first stairs)'),
(-9370607,0,0,0,1,0,100,0,2000,2000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (second stairs)'),
(-9370608,0,0,0,1,0,100,0,2000,2000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (second stairs)'),
(-9370609,0,0,0,1,0,100,0,2000,2000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (second stairs)'),
(-9370610,0,0,0,1,0,100,0,2000,2000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (second stairs)'),
(-9370611,0,0,0,1,0,100,0,2000,2000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (second stairs)'),
(-9370612,0,0,0,1,0,100,0,2000,2000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (second stairs)'),
(-9370613,0,0,0,1,0,100,0,4000,4000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (third stairs)'),
(-9370614,0,0,0,1,0,100,0,4000,4000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (third stairs)'),
(-9370615,0,0,0,1,0,100,0,4000,4000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (third stairs)'),
(-9370616,0,0,0,1,0,100,0,4000,4000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (third stairs)'),
(-9370617,0,0,0,1,0,100,0,4000,4000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (third stairs)'),
(-9370618,0,0,0,1,0,100,0,4000,4000,6000,6000,0,0,11,256923,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Trap - Out of Combat - Cast Venom Trap (third stairs)');
