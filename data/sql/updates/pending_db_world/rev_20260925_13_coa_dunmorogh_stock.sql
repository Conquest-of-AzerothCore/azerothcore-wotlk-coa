-- CoA Dun Morogh and Coldridge Valley: stock rows CoA's rebuild stranded (hop field, Crash Site, single
-- rows, airfield tower), Kharanos graveyard 101, Runestone Forest graveyard 6076, graveyard links for the
-- caves and CoA's edge zones, and The Boar Hunter's count. Creature guids 9008800-9008849.

-- ---------------------------------------------------------------------------
-- 1. Kharanos south plateau and the hop field
-- ---------------------------------------------------------------------------
-- The fence ring of CoA's fenced hop field (1660077) runs x -5766..-5695, y -602..-531; the meadow south of it,
-- where stock rabbits, boars and leopards already graze, takes the rows.
-- Large Crag Boar (3645): off the buried Kharanos plateau; meadow west of the snow trees at (-5774, -600).
UPDATE `creature` SET `position_x` = -5790, `position_y` = -612, `position_z` = 398.367 WHERE `guid` = 3645 AND `id` = 1126;
-- Crag Boar (1719): off the buried Kharanos plateau; meadow, with the stock boars by Crag Boar 3639.
UPDATE `creature` SET `position_x` = -5810, `position_y` = -622, `position_z` = 399.608 WHERE `guid` = 1719 AND `id` = 1125;
-- Rabbit (3644): off the buried Kharanos plateau; west slope of the meadow.
UPDATE `creature` SET `position_x` = -5815, `position_y` = -535, `position_z` = 406.492 WHERE `guid` = 3644 AND `id` = 721;
-- Ice Claw Bear (4102): off the buried Kharanos plateau; far end of the meadow by a snow tree.
UPDATE `creature` SET `position_x` = -5838, `position_y` = -598, `position_z` = 397.044 WHERE `guid` = 4102 AND `id` = 1196;
-- Winter Wolf (4103): off the buried Kharanos plateau; middle of the meadow below a snow tree.
UPDATE `creature` SET `position_x` = -5800, `position_y` = -560, `position_z` = 399.887 WHERE `guid` = 4103 AND `id` = 1131;
-- Snow Leopard (3643): out of the hop field; meadow south of the field's south corner.
UPDATE `creature` SET `position_x` = -5792, `position_y` = -576, `position_z` = 398.598 WHERE `guid` = 3643 AND `id` = 1201;
-- Large Crag Boar (230): out of the hop field; east edge of the meadow.
UPDATE `creature` SET `position_x` = -5822, `position_y` = -640, `position_z` = 399.032 WHERE `guid` = 230 AND `id` = 1126;
-- Large Crag Boar (3642): out of the hop field; north-east corner of the meadow, clear of the Kharanos tunnel.
UPDATE `creature` SET `position_x` = -5780, `position_y` = -635, `position_z` = 398.353 WHERE `guid` = 3642 AND `id` = 1126;
-- Rabbit (1717): away from the hop field fence; the meadow's west rise.
UPDATE `creature` SET `position_x` = -5835, `position_y` = -525, `position_z` = 408.734 WHERE `guid` = 1717 AND `id` = 721;

-- Earthroot (205203): pool 20339, off the buried Kharanos plateau; meadow by the snow trees.
UPDATE `gameobject` SET `position_x` = -5782, `position_y` = -590, `position_z` = 397.591 WHERE `guid` = 205203 AND `id` = 1619;
-- Peacebloom (205130): pool 20338, off the buried Kharanos plateau; south end of the meadow.
UPDATE `gameobject` SET `position_x` = -5845, `position_y` = -615, `position_z` = 397.044 WHERE `guid` = 205130 AND `id` = 1618;
-- Earthroot (205197): pool 20339, off the buried Kharanos plateau; the meadow's west rise.
UPDATE `gameobject` SET `position_x` = -5822, `position_y` = -510, `position_z` = 404.808 WHERE `guid` = 205197 AND `id` = 1619;
-- Peacebloom (205135): pool 20338, out of the hop field; meadow slope.
UPDATE `gameobject` SET `position_x` = -5815, `position_y` = -548, `position_z` = 404.88 WHERE `guid` = 205135 AND `id` = 1618;

-- ---------------------------------------------------------------------------
-- 2. Kharanos graveyard 101
-- ---------------------------------------------------------------------------
UPDATE `game_graveyard` SET `x` = -5598.31, `y` = -596.246, `z` = 452.261 WHERE `ID` = 101;
-- Spirit Healer (87045): out of the stable to the hilltop cemetery, facing WorldSafeLocs 101.
UPDATE `creature` SET `position_x` = -5602, `position_y` = -600, `position_z` = 452.259, `orientation` = 0.79 WHERE `guid` = 87045 AND `id` = 6491;

-- ---------------------------------------------------------------------------
-- 3. Coldridge Valley Crash Site
-- ---------------------------------------------------------------------------
-- Rows floating over CoA's lowered crater or stuck in its new rocks, clear of the 1660006 points.
-- Small Crag Boar (509): meadow below the rim, south-west of ST47.
UPDATE `creature` SET `position_x` = -6236, `position_y` = 745, `position_z` = 387.682 WHERE `guid` = 509 AND `id` = 708;
-- Small Crag Boar (506): east rim, north of Talin Keeneye.
UPDATE `creature` SET `position_x` = -6175, `position_y` = 700, `position_z` = 386.952 WHERE `guid` = 506 AND `id` = 708;
-- Small Crag Boar (601): east meadow, north of Talin Keeneye's campfire.
UPDATE `creature` SET `position_x` = -6200, `position_y` = 690, `position_z` = 386.874 WHERE `guid` = 601 AND `id` = 708;
-- Small Crag Boar (507): south-west meadow, west of ST47.
UPDATE `creature` SET `position_x` = -6232, `position_y` = 775, `position_z` = 389.401 WHERE `guid` = 507 AND `id` = 708;
-- Burly Rockjaw Trogg (491): south meadow among the Burly Rockjaw Troggs.
UPDATE `creature` SET `position_x` = -6262, `position_y` = 760, `position_z` = 386.188 WHERE `guid` = 491 AND `id` = 724;
-- Small Crag Boar (475): open east rim beside the new rock.
UPDATE `creature` SET `position_x` = -6166, `position_y` = 695, `position_z` = 386.99 WHERE `guid` = 475 AND `id` = 708;
-- Small Crag Boar (490): north-east hill above the new rock.
UPDATE `creature` SET `position_x` = -6140, `position_y` = 800, `position_z` = 398.785 WHERE `guid` = 490 AND `id` = 708;
-- Small Crag Boar (600): north-east rim, off the new rock.
UPDATE `creature` SET `position_x` = -6136, `position_y` = 792, `position_z` = 402.852 WHERE `guid` = 600 AND `id` = 708;
-- Small Crag Boar (595): south meadow, south of ST47.
UPDATE `creature` SET `position_x` = -6244, `position_y` = 732, `position_z` = 389.277 WHERE `guid` = 595 AND `id` = 708;
-- Small Crag Boar (485): south-west meadow, off the new rock.
UPDATE `creature` SET `position_x` = -6258, `position_y` = 790, `position_z` = 388.11 WHERE `guid` = 485 AND `id` = 708;
-- Small Crag Boar (701): rim meadow south-east of ST47, off the wreck.
UPDATE `creature` SET `position_x` = -6234, `position_y` = 720, `position_z` = 389.58 WHERE `guid` = 701 AND `id` = 708;

-- Burly Rockjaw Trogg (483): onto the crater rim; same x and y.
UPDATE `creature` SET `position_z` = 387.451 WHERE `guid` = 483 AND `id` = 724;

-- ---------------------------------------------------------------------------
-- 4. Single rows
-- ---------------------------------------------------------------------------
-- Rockjaw Trogg (1549): buried at the Coldridge Pass west mouth; trogg flat by Rockjaw Trogg 1546.
UPDATE `creature` SET `position_x` = -6340, `position_y` = 178, `position_z` = 396.348 WHERE `guid` = 1549 AND `id` = 707;
-- Crag Boar (3628): under a new Snow_2Story house; open ground east of it.
UPDATE `creature` SET `position_x` = -5880, `position_y` = -540, `position_z` = 399.139 WHERE `guid` = 3628 AND `id` = 1125;
-- Large Crag Boar (4129): in a new Tundrid Hills fence; 7 yd north-east of it.
UPDATE `creature` SET `position_x` = -5600, `position_y` = -1000, `position_z` = 393.512 WHERE `guid` = 4129 AND `id` = 1126;
-- Bjarn (134473): rare (pool 1064); out of CoA's Coldhewn Camp to the open snowfield south of it.
UPDATE `creature` SET `position_x` = -5850, `position_y` = -1255, `position_z` = 390.641 WHERE `guid` = 134473 AND `id` = 1130;

-- Earthroot (205220): pool 20339, in the same Snow_2Story house; open ground east of it.
UPDATE `gameobject` SET `position_x` = -5890, `position_y` = -545, `position_z` = 398.932 WHERE `guid` = 205220 AND `id` = 1619;

-- Crag Boar (264): floated 5.41 where CoA cut the Winding Road; same x and y.
UPDATE `creature` SET `position_z` = 439.767 WHERE `guid` = 264 AND `id` = 1125;
-- Crag Boar (3612): floated 0.87 at the Winding Road head camp; same x and y.
UPDATE `creature` SET `position_z` = 417.752 WHERE `guid` = 3612 AND `id` = 1125;
-- Grif Wildheart (222): hunter trainer kept by 13, floated 0.61; same x and y.
UPDATE `creature` SET `position_z` = 407.236 WHERE `guid` = 222 AND `id` = 1231;

-- ---------------------------------------------------------------------------
-- 5. Ironforge airfield tower
-- ---------------------------------------------------------------------------
-- CoA set the Ironforge airfield Dwarven_Snowtower.wmo 1.987 yd lower; the rows inside follow (z - 1.987).
UPDATE `creature` SET `position_z` = 501.597 WHERE `guid` = 161018 AND `id` = 727;
UPDATE `creature` SET `position_z` = 501.794 WHERE `guid` = 161028 AND `id` = 727;
UPDATE `gameobject` SET `position_z` = 508.36 WHERE `guid` = 55863 AND `id` = 147043;
UPDATE `gameobject` SET `position_z` = 508.36 WHERE `guid` = 55864 AND `id` = 147044;
UPDATE `gameobject` SET `position_z` = 508.36 WHERE `guid` = 55865 AND `id` = 147045;
UPDATE `gameobject` SET `position_z` = 508.36 WHERE `guid` = 55890 AND `id` = 34034;
UPDATE `gameobject` SET `position_z` = 508.36 WHERE `guid` = 55891 AND `id` = 34035;
UPDATE `gameobject` SET `position_z` = 508.36 WHERE `guid` = 55892 AND `id` = 34037;
UPDATE `gameobject` SET `position_z` = 508.36 WHERE `guid` = 55893 AND `id` = 34038;
UPDATE `gameobject` SET `position_z` = 501.496 WHERE `guid` = 81604 AND `id` = 29743;
UPDATE `gameobject` SET `position_z` = 501.496 WHERE `guid` = 81605 AND `id` = 29745;
UPDATE `gameobject` SET `position_z` = 508.366 WHERE `guid` = 81606 AND `id` = 29746;
UPDATE `gameobject` SET `position_z` = 501.496 WHERE `guid` = 100082 AND `id` = 29741;
UPDATE `gameobject` SET `position_z` = 508.366 WHERE `guid` = 100083 AND `id` = 29742;
UPDATE `gameobject` SET `position_z` = 508.366 WHERE `guid` = 100084 AND `id` = 29744;
UPDATE `gameobject` SET `position_z` = 501.496 WHERE `guid` = 100085 AND `id` = 29747;

-- ---------------------------------------------------------------------------
-- 6. Runestone Forest graveyard 6076
-- ---------------------------------------------------------------------------
DELETE FROM `game_graveyard` WHERE `ID` = 6076;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`)
VALUES
(6076, 0, -5969.45, 768.374, 525.359, 'Coldridge Valley, Runestone forest Graveyard');

DELETE FROM `creature` WHERE `guid` = 9008800 OR `guid` BETWEEN 9008800 AND 9008849;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9008800, 6491, 0, 0, 0, 1, 4294967295, 0, -5973.5, 766, 525.015, 0.53, 60, 0, 0, 4120, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Runestone Forest graveyard 6076: on the open snow 4.7 yd south-east of the WorldSafeLocs point, facing it, clear of the signpost and the fallen tree');

-- ---------------------------------------------------------------------------
-- 7. Graveyard links
-- ---------------------------------------------------------------------------
-- 10120 Coldridge Pass: the tunnel (AnvilmarPass.wmo) maps to this parent-0 area.
-- 10119 Gol'Bolar Quarry: the quarry mine WMO maps to this parent-0 area.
-- 10121 The Grizzled Den: the den WMO maps to this parent-0 area.
-- 10302 Pale Reach: CoA zone on Dun Morogh's west edge (Winding Road, Ealdfrost Range).
-- 10292 Druk'Thar: CoA zone on Dun Morogh's north edge (Fan'dor Hills, Dun Argan).
-- 10306 Dun Kazad: the Pale Reach cave WMO maps to this parent-0 area.
-- 10202 Runestone Forest and 10203 Radiance Town: area links to 6076, faction 0.
DELETE FROM `graveyard_zone` WHERE (`ID`, `GhostZone`) IN ((7, 10119), (100, 10119), (101, 10119), (852, 10119), (1471, 10119), (1472, 10119), (7, 10120), (100, 10120), (101, 10120), (852, 10120), (1471, 10120), (1472, 10120), (7, 10121), (100, 10121), (101, 10121), (852, 10121), (1471, 10121), (1472, 10121), (6076, 10202), (6076, 10203), (100, 10292), (101, 10292), (852, 10292), (1471, 10292), (1472, 10292), (100, 10302), (101, 10302), (852, 10302), (1471, 10302), (1472, 10302), (100, 10306), (101, 10306), (852, 10306), (1471, 10306), (1472, 10306));
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES
(7, 10119, 67, 'Gol''Bolar Quarry - Wetlands, Crossroads'),
(100, 10119, 469, 'Gol''Bolar Quarry - Dun Morogh, Anvilmar'),
(101, 10119, 469, 'Gol''Bolar Quarry - Dun Morogh, Kharanos'),
(852, 10119, 469, 'Gol''Bolar Quarry - Dun Morogh, Gates of Ironforge'),
(1471, 10119, 0, 'Gol''Bolar Quarry - Dun Morogh, Iceflow Lake'),
(1472, 10119, 0, 'Gol''Bolar Quarry - Dun Morogh, East Road'),
(7, 10120, 67, 'Coldridge Pass - Wetlands, Crossroads'),
(100, 10120, 469, 'Coldridge Pass - Dun Morogh, Anvilmar'),
(101, 10120, 469, 'Coldridge Pass - Dun Morogh, Kharanos'),
(852, 10120, 469, 'Coldridge Pass - Dun Morogh, Gates of Ironforge'),
(1471, 10120, 0, 'Coldridge Pass - Dun Morogh, Iceflow Lake'),
(1472, 10120, 0, 'Coldridge Pass - Dun Morogh, East Road'),
(7, 10121, 67, 'The Grizzled Den - Wetlands, Crossroads'),
(100, 10121, 469, 'The Grizzled Den - Dun Morogh, Anvilmar'),
(101, 10121, 469, 'The Grizzled Den - Dun Morogh, Kharanos'),
(852, 10121, 469, 'The Grizzled Den - Dun Morogh, Gates of Ironforge'),
(1471, 10121, 0, 'The Grizzled Den - Dun Morogh, Iceflow Lake'),
(1472, 10121, 0, 'The Grizzled Den - Dun Morogh, East Road'),
(6076, 10202, 0, 'Runestone Forest - Runestone forest Graveyard'),
(6076, 10203, 0, 'Radiance Town - Runestone forest Graveyard'),
(100, 10292, 469, 'Druk''Thar - Dun Morogh, Anvilmar'),
(101, 10292, 469, 'Druk''Thar - Dun Morogh, Kharanos'),
(852, 10292, 469, 'Druk''Thar - Dun Morogh, Gates of Ironforge'),
(1471, 10292, 0, 'Druk''Thar - Dun Morogh, Iceflow Lake'),
(1472, 10292, 0, 'Druk''Thar - Dun Morogh, East Road'),
(100, 10302, 469, 'Pale Reach - Dun Morogh, Anvilmar'),
(101, 10302, 469, 'Pale Reach - Dun Morogh, Kharanos'),
(852, 10302, 469, 'Pale Reach - Dun Morogh, Gates of Ironforge'),
(1471, 10302, 0, 'Pale Reach - Dun Morogh, Iceflow Lake'),
(1472, 10302, 0, 'Pale Reach - Dun Morogh, East Road'),
(100, 10306, 469, 'Dun Kazad - Dun Morogh, Anvilmar'),
(101, 10306, 469, 'Dun Kazad - Dun Morogh, Kharanos'),
(852, 10306, 469, 'Dun Kazad - Dun Morogh, Gates of Ironforge'),
(1471, 10306, 0, 'Dun Kazad - Dun Morogh, Iceflow Lake'),
(1472, 10306, 0, 'Dun Kazad - Dun Morogh, East Road');

-- ---------------------------------------------------------------------------
-- 8. The Boar Hunter
-- ---------------------------------------------------------------------------
-- 183: CoA asks for 8 Small Crag Boars (questcache); 57 are spawned in Coldridge.
UPDATE `quest_template` SET `RequiredNpcOrGoCount1` = 8, `LogDescription` = 'Talin Keeneye would like you to kill 8 Small Crag Boars.' WHERE `ID` = 183;
