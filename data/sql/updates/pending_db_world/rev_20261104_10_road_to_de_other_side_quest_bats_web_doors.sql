-- Road to De Other Side (map 937): bats for "A Sinister Family", and web doors for Drak'math's arena.

-- Lifedrinkers counted as Bats of the Other Side (kill credit 163814) since #8715; on Ascension they did not (db.exil.es
-- lists only their own credit 162980), and the quest text asks for bats (#10705).
UPDATE `creature_template` SET `KillCredit2` = 0 WHERE `entry` IN (162979, 162980, 162981, 262979, 262980, 262981, 362979, 362980, 362981);

-- The hostile bats are quest targets but carried CREATURE_TYPE_FLAG_NO_NAME_PLATE (as in Ascension's data), so they
-- showed no health bar.
UPDATE `creature_template` SET `type_flags` = `type_flags` & ~1048576 WHERE `entry` IN (162766, 162767, 262766, 262767, 362766, 362767);

-- A fifth hostile bat, placed in game: the quest needs five and only four were spawned.
DELETE FROM `creature` WHERE `guid` IN (9999808, 9370619);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9370619,162767,937,0,0,1,1,0,185.941,-291.183,206.894,3.73689,300,3,0,0,0,1,0,0,0,'',0,0,'Bat of the Other Side');

-- Drak'math's arena: Ascension's own web doors (SinisterLair Dungeon Web Door, display 300461, in db.exil.es without
-- positions) on the west entrance and the east exit. They stand open and close 3 s after the pull (#10777). The
-- positions are a proposal to be checked in game.
DELETE FROM `gameobject_template` WHERE `entry` IN (2300575, 2300583);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300575,0,300461,'SinisterLair Dungeon Web Door','','','',1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'','',12340),
(2300583,0,300461,'SinisterLair Dungeon Web Door','','','',1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'','',12340);
DELETE FROM `gameobject` WHERE `guid` IN (9370008, 9370009);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9370008,2300575,937,10219,10219,7,1,270.5,151.0,248.5,0,0,0,0,1,86400,100,0,'',NULL,'Drak''math arena, west entrance'),
(9370009,2300583,937,10219,10219,7,1,309.5,152.0,248.5,3.14159,0,0,1,0,86400,100,0,'',NULL,'Drak''math arena, east exit');
