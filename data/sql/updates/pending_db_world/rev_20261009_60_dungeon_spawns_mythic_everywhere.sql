-- Every enemy that stands on Mythic stands on every difficulty, at its Mythic position.

-- Bosses with one spawn per difficulty (Normal often elsewhere) keep the Mythic one: Lorgus Jett,
-- Ragglesnout, Plaguemaw the Rotting, Jergosh the Invoker. Fallen Champion and The Unforgiven were Mythic only.
DELETE FROM `creature` WHERE `guid` IN (26173, 9780128, 247108, 9780122, 9780124, 48740, 9780132);
UPDATE `creature` SET `spawnMask` = 7 WHERE `guid` IN (9780127, 9780116, 9780119, 9780131, 9780160, 9950080);

-- Lower Blackrock Spire: the Spirestone packs next to the rare bosses, on every difficulty.
DELETE FROM `creature` WHERE `guid` IN (9950261, 9950262, 9950263, 9950264, 9950266,
    9950292, 9950293, 9950294, 9950295, 9950297);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
(9950261, 9216, 229, 0, 0, 7, 1, 1, -31.6589, -375.797, 31.6183, 4.67345, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL),  -- Spirestone Warlord
(9950262, 9216, 229, 0, 0, 7, 1, 1, -43.1022, -375.351, 31.6183, 4.67345, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL),  -- Spirestone Warlord
(9950263, 9201, 229, 0, 0, 7, 1, 1, -14.0319, -355.053, 31.6183, 3.11836, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL),  -- Spirestone Ogre Magus
(9950264, 9200, 229, 0, 0, 7, 1, 1, -19.7114, -348.077, 31.604, 3.98623, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL),  -- Spirestone Reaver
(9950266, 9198, 229, 0, 0, 7, 1, 1, -49.0848, -322.638, 43.047, 5.0473, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL);  -- Spirestone Mystic
