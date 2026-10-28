-- Dungeon fixes: rares on every difficulty, Deathstalker Adamant, Hamhock.

-- Lower Blackrock Spire: the rare bosses always spawn and stand on every difficulty (they were placed for
-- Mythic). The stock Burning Felguard spawn goes; the placed one stays, so there is one of him.
DELETE FROM `creature` WHERE `guid` IN (9950259, 9950260, 9950265, 9950273, 45808);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
(9950259, 9219, 229, 0, 0, 7, 1, 0, -37.1626, -428.256, 31.7916, 4.70417, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL),  -- Chop'gog the Butcher
(9950260, 9217, 229, 0, 0, 7, 1, 1, -37.6842, -379.083, 31.6183, 4.68916, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL),  -- Wizz'Magg the Magus
(9950265, 9218, 229, 0, 0, 7, 1, 0, -54.5744, -325.952, 43.0746, 5.20438, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL),  -- Razmorg the Decapitator
(9950273, 10263, 229, 0, 0, 7, 1, 1, -11.4631, -381.701, 49.1622, 6.27409, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL);  -- Burning Felguard

-- Ghok Bashguud (Lower Blackrock Spire) spawned in 15 % of instances, an ordinary add in the rest
-- (pool 9718). Rares always spawn: Ghok always, the add goes.
DELETE FROM `pool_creature` WHERE `pool_entry` = 9718;
DELETE FROM `pool_template` WHERE `entry` = 9718;
DELETE FROM `creature` WHERE `guid` = 45763;

-- Deathstalker Adamant (Shadowfang Keep) stays hostile to the Alliance but cannot be attacked by players
-- or creatures (Alliance bots killed him).
UPDATE `creature_template` SET `unit_flags` = `unit_flags` | 0x2 | 0x100 | 0x200 WHERE `entry` IN (3849, 103849, 203849);

-- Hamhock (Stockade): the stock Chain Lightning row ran next to the Ascension kit's, so he cast it twice as
-- often. The stock row is parked like the others; the kit's Chain Lightning has a 10 s cooldown and hits
-- twice as hard.
UPDATE `smart_scripts` SET `event_flags` = 16 WHERE `entryorguid` = 1717 AND `source_type` = 0 AND `id` = 0;
UPDATE `smart_scripts` SET `event_param3` = 10000, `event_param4` = 10000, `action_param3` = 1198
WHERE `entryorguid` = 1717 AND `source_type` = 0 AND `id` = 9010;
UPDATE `smart_scripts` SET `event_param3` = 10000, `event_param4` = 10000, `action_param3` = 1558
WHERE `entryorguid` = 1717 AND `source_type` = 0 AND `id` = 9011;
