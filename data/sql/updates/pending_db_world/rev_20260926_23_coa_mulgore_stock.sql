-- CoA Mulgore and Red Cloud Mesa: stock rows CoA's terrain stranded (the fire-ground hill, the Grimtotem hut
-- camp, Palemane Rock, Stonefather's Circle, the raised ridges), buried pooled nodes, Hard Basin graveyard
-- 6077 and graveyard links for the caves and the Grimtotem areas. Creature guids 9011650-9011699.

-- ---------------------------------------------------------------------------
-- 1. The hill north-west of Bloodhoof and the 1660068 fire ground
-- ---------------------------------------------------------------------------
-- Fire ground: x -2350..-2239, y -140..0 plus 15 yd; the wanderers leave it by more than their radius.
-- Prairie Wolf (25420): buried on the hill flank; middle of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2190, `position_y` = -40, `position_z` = 0.808 WHERE `guid` = 25420 AND `id` = 2958;
-- Prairie Wolf (25462): in the fire ground; the plain north of the hill, by the Mullgoretree grove.
UPDATE `creature` SET `position_x` = -2175, `position_y` = -95, `position_z` = -5.507 WHERE `guid` = 25462 AND `id` = 2958;
-- Prairie Wolf (25373): in the fire ground; north end of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2140, `position_y` = -62, `position_z` = -2.759 WHERE `guid` = 25373 AND `id` = 2958;
-- Prairie Wolf (25423): in the fire ground; west rise of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2200, `position_y` = 5, `position_z` = 18.012 WHERE `guid` = 25423 AND `id` = 2958;
-- Prairie Wolf (25383): in the fire ground; low ground of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2165, `position_y` = -68, `position_z` = -6.008 WHERE `guid` = 25383 AND `id` = 2958;
-- Adult Plainstrider (25234): buried on the hill; south end of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2200, `position_y` = -75, `position_z` = -8.067 WHERE `guid` = 25234 AND `id` = 2956;
-- Adult Plainstrider (25238): buried on the hill flank; west slope of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2160, `position_y` = -40, `position_z` = 7.052 WHERE `guid` = 25238 AND `id` = 2956;
-- Wiry Swoop (26069): buried by the burnt hut; south edge of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2200, `position_y` = -25, `position_z` = 5.02 WHERE `guid` = 26069 AND `id` = 2969;
-- Adult Plainstrider (25204): wandered into the fire ground; north-east rise of the plain north of the hill.
UPDATE `creature` SET `position_x` = -2150, `position_y` = 5, `position_z` = 22.15 WHERE `guid` = 25204 AND `id` = 2956;
-- Prairie Wolf (25398): buried on the new hill; open slope west of it.
UPDATE `creature` SET `position_x` = -2425, `position_y` = 100, `position_z` = 40.856 WHERE `guid` = 25398 AND `id` = 2958;
-- Adult Plainstrider (25162): buried on the hilltop; plain north of the hill.
UPDATE `creature` SET `position_x` = -2300, `position_y` = 100, `position_z` = 46.063 WHERE `guid` = 25162 AND `id` = 2956;
-- Adult Plainstrider (25211): on a 41-degree face against Mullgorerock03; flat plain south of the hill, off the
-- kodo ground.
UPDATE `creature` SET `position_x` = -2400, `position_y` = -100, `position_z` = -3.581 WHERE `guid` = 25211 AND `id` = 2956;

-- Adult Plainstrider (25199): floated 1.15; same x and y.
UPDATE `creature` SET `position_z` = -3.215 WHERE `guid` = 25199 AND `id` = 2956;
-- Adult Plainstrider (25206): sunk 1.66; same x and y.
UPDATE `creature` SET `position_z` = 34.433 WHERE `guid` = 25206 AND `id` = 2956;
-- Prairie Wolf (25401): sunk 0.56; same x and y.
UPDATE `creature` SET `position_z` = -7.132 WHERE `guid` = 25401 AND `id` = 2958;
-- Prairie Wolf (25419): sunk 1.02; same x and y.
UPDATE `creature` SET `position_z` = 46.821 WHERE `guid` = 25419 AND `id` = 2958;
-- Wiry Swoop (26059): sunk 1.34; same x and y.
UPDATE `creature` SET `position_z` = 44.316 WHERE `guid` = 26059 AND `id` = 2969;
-- Adult Plainstrider (25228): buried 2.64 on the Narache road hill; same x and y.
UPDATE `creature` SET `position_z` = 83.897 WHERE `guid` = 25228 AND `id` = 2956;

-- Ambercorn (20317): sunk 1.28; same x and y.
UPDATE `gameobject` SET `position_z` = 34.949 WHERE `guid` = 20317 AND `id` = 2912;
-- Peacebloom (214093): pool 21342, sunk 0.44; same x and y.
UPDATE `gameobject` SET `position_z` = -7.213 WHERE `guid` = 214093 AND `id` = 1618;

-- ---------------------------------------------------------------------------
-- 2. Morriga's cabin (Grimtotem hut camp)
-- ---------------------------------------------------------------------------
-- Mountain Cougar (94862): floated 12.7 over the lowered hut camp; open meadow north of it.
UPDATE `creature` SET `position_x` = -3312, `position_y` = -898, `position_z` = 65.09 WHERE `guid` = 94862 AND `id` = 2961;
-- Battleboar (72747): floated 7.0 over the lowered hut camp; open ground north-east of the hut.
UPDATE `creature` SET `position_x` = -3322, `position_y` = -940, `position_z` = 68.898 WHERE `guid` = 72747 AND `id` = 2966;

-- Mountain Cougar (94870): floated 1.39; same x and y.
UPDATE `creature` SET `position_z` = 55.849 WHERE `guid` = 94870 AND `id` = 2961;
-- Battleboar (72741): floated 1.58; same x and y.
UPDATE `creature` SET `position_z` = 67.943 WHERE `guid` = 72741 AND `id` = 2966;
-- Battleboar (72745): floated 0.98; same x and y.
UPDATE `creature` SET `position_z` = 75.241 WHERE `guid` = 72745 AND `id` = 2966;

-- Battleboar (72741): 20 yd from Morriga; wander 5 so it stays off her spot.
UPDATE `creature` SET `wander_distance` = 5 WHERE `guid` = 72741 AND `id` = 2966;

-- ---------------------------------------------------------------------------
-- 3. Palemane Rock and Stonefather's Circle
-- ---------------------------------------------------------------------------
-- Palemane Tanner (24824): floated on the foot of a new ridge; 6 yd west onto the camp floor.
UPDATE `creature` SET `position_x` = -2746, `position_y` = -480, `position_z` = 3.024 WHERE `guid` = 24824 AND `id` = 2949;

-- Palemane Tanner (24822): floated 2.14; same x and y.
UPDATE `creature` SET `position_z` = -1.68 WHERE `guid` = 24822 AND `id` = 2949;
-- Palemane Skinner (24829): floated 2.03; same x and y.
UPDATE `creature` SET `position_z` = 12.076 WHERE `guid` = 24829 AND `id` = 2950;

-- Hostile wanderers keep 30 yd plus their wander radius from Tharok and the teepees.
-- Prairie Stalker (25587): inside the circle; plain to the north.
UPDATE `creature` SET `position_x` = -1900, `position_y` = -300, `position_z` = -7.805 WHERE `guid` = 25587 AND `id` = 2959;
-- Prairie Stalker (25563): 16 yd from the north teepee; plain beyond it.
UPDATE `creature` SET `position_x` = -1870, `position_y` = -330, `position_z` = -7.664 WHERE `guid` = 25563 AND `id` = 2959;
-- Prairie Stalker (25585): sunk, 42 yd from the north teepee; plain north-east.
UPDATE `creature` SET `position_x` = -1865, `position_y` = -385, `position_z` = -8.651 WHERE `guid` = 25585 AND `id` = 2959;
-- Prairie Stalker (25601): sunk, by the east teepee; plain to the south-east.
UPDATE `creature` SET `position_x` = -2020, `position_y` = -410, `position_z` = -5.068 WHERE `guid` = 25601 AND `id` = 2959;
-- Swoop (26094): floated, by the west teepee; plain to the south-west.
UPDATE `creature` SET `position_x` = -2000, `position_y` = -290, `position_z` = -9.3 WHERE `guid` = 26094 AND `id` = 2970;

-- ---------------------------------------------------------------------------
-- 4. Herb and ore nodes on the raised ridges
-- ---------------------------------------------------------------------------
-- Copper Vein (214238): pool 21344, buried 18.5 in a raised ridge; same x and y.
UPDATE `gameobject` SET `position_z` = 40.805 WHERE `guid` = 214238 AND `id` = 1731;
-- Earthroot (214138): pool 21343, buried 23.3 in a raised ridge; same x and y.
UPDATE `gameobject` SET `position_z` = 36.333 WHERE `guid` = 214138 AND `id` = 1619;
-- Earthroot (214152): pool 21343, buried 11.4 in a raised ridge; same x and y.
UPDATE `gameobject` SET `position_z` = 39.138 WHERE `guid` = 214152 AND `id` = 1619;
-- Copper Vein (214214): pool 21344, floated 2.6 on a lowered face; same x and y.
UPDATE `gameobject` SET `position_z` = 34.005 WHERE `guid` = 214214 AND `id` = 1731;

-- Copper Vein (214242): pool 21344, buried 13.5 in a raised ridge; onto the ridge top, clear of the
-- Mullgoretree02 trunk.
UPDATE `gameobject` SET `position_x` = -2820.6, `position_y` = -434.5, `position_z` = 37.313 WHERE `guid` = 214242 AND `id` = 1731;

-- Pooled nodes CoA buried; each pool keeps more than twice its max_limit.
-- 214209 (pool 21344): Copper Vein 60 yd under a new cliff.
-- 214212 (pool 21344): Copper Vein inside a vertical face.
-- 214215 (pool 21344): Copper Vein inside a vertical face.
-- 214153 (pool 21343): Earthroot inside a vertical face.
-- 214139 (pool 21343): Earthroot sunk on a 62-degree face.
-- 214084 (pool 21338): Peacebloom under water in the new Stonefather stream.
-- 213975 (pool 21333): Silverleaf inside a new tree trunk.
DELETE FROM `pool_gameobject` WHERE `guid` IN (213975, 214084, 214139, 214153, 214209, 214212, 214215);
DELETE FROM `gameobject` WHERE `guid` IN (213975, 214084, 214139, 214153, 214209, 214212, 214215);

-- ---------------------------------------------------------------------------
-- 5. Hard Basin graveyard 6077
-- ---------------------------------------------------------------------------
DELETE FROM `game_graveyard` WHERE `ID` = 6077;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`)
VALUES
(6077, 1, -3627.28, -1007.71, 204.562, 'Red Cloud Mesa, Hard Basin Graveyard');

-- Spirit Healer (9011650): open basin floor 4.4 yd north-east of the WorldSafeLocs point, facing it, clear of
-- the fallen trees and the rock outcrop.
DELETE FROM `creature` WHERE `guid` = 9011650 OR `guid` BETWEEN 9011650 AND 9011699;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9011650, 6491, 1, 0, 0, 1, 4294967295, 0, -3623.5, -1010, 203.972, 2.597, 60, 0, 0, 4120, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Red Cloud Mesa: Hard Basin graveyard 6077');

-- ---------------------------------------------------------------------------
-- 6. Graveyard links
-- ---------------------------------------------------------------------------
-- 10128 Palemane Rock: the cave WMO maps to this parent-0 area; Mulgore's graveyards with Mulgore's factions.
-- 10129 The Venture Co. Mine: the mine WMO maps to this parent-0 area; Mulgore's graveyards with Mulgore's factions.
-- 10209-10211: area links to 6077, faction 0.
DELETE FROM `graveyard_zone` WHERE (`ID`, `GhostZone`) IN ((34, 10128), (89, 10128), (249, 10128), (851, 10128), (1435, 10128), (1436, 10128), (34, 10129), (89, 10129), (249, 10129), (851, 10129), (1435, 10129), (1436, 10129), (6077, 10209), (6077, 10210), (6077, 10211));
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES
(34, 10128, 67, 'Palemane Rock - Mulgore, Red Cloud Mesa'),
(89, 10128, 67, 'Palemane Rock - Mulgore, Bloodhoof Village'),
(249, 10128, 469, 'Palemane Rock - The Barrens, Ratchet'),
(851, 10128, 67, 'Palemane Rock - Mulgore, Thunder Bluff'),
(1435, 10128, 0, 'Palemane Rock - Mulgore, Southeast GY'),
(1436, 10128, 0, 'Palemane Rock - Mulgore, Red Rocks'),
(34, 10129, 67, 'The Venture Co. Mine - Mulgore, Red Cloud Mesa'),
(89, 10129, 67, 'The Venture Co. Mine - Mulgore, Bloodhoof Village'),
(249, 10129, 469, 'The Venture Co. Mine - The Barrens, Ratchet'),
(851, 10129, 67, 'The Venture Co. Mine - Mulgore, Thunder Bluff'),
(1435, 10129, 0, 'The Venture Co. Mine - Mulgore, Southeast GY'),
(1436, 10129, 0, 'The Venture Co. Mine - Mulgore, Red Rocks'),
(6077, 10209, 0, 'Grimtotem Mountain Path - Hard Basin Graveyard'),
(6077, 10210, 0, 'Hard Basin - Hard Basin Graveyard'),
(6077, 10211, 0, 'Three Totem Village - Hard Basin Graveyard');
