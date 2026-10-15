-- ----------------------------------------------------------------------------
-- Worldforged pickups: the Westfall revision of 2026-09-25
-- ----------------------------------------------------------------------------
-- The zone walked in the map editor and then reviewed on the zone's sheet of
-- worldforged-items.xlsx.  Two things came out of that:
--
--   * 33 rows of the module were re-placed by hand in the editor (Noggit, in the
--     client's own data): 41 changesets in the pro2 project, read in the order they were
--     written, the last write to a row winning.  Position and rotation quaternion are what
--     the editor emitted, down to the digit; `orientation` is the yaw that quaternion
--     represents, which is what the model is drawn with.
--   * 48 rows were taken out of the zone in the review: printed on the sheet and marked
--     red by hand.  Every one of them is deleted below.  Of the 41 rows the review kept, 35
--     authored in the editor in this same walk and 5 already stand where they did; one of
--     them - the Deadman's Signet - was moved out of the zone into Raven Hill Cemetery in
--     Duskwood, so 40 rows stand in Westfall's areas when this file has run.
--
-- The review is a statement about the zone, not about the realm: the objects it takes out
-- stand in other zones as well, and the other zones are left exactly as they are.  This
-- file deletes the zone's own placements, and nothing else.
--
-- Heavy Bone (95819, guid 6940607) is resized: it draws the Desolace giant's femur
-- (world\expansion07\doodads\desertzone\8des_bones_femur01.m2), whose own bounding box
-- in the client's GameObjectDisplayInfo.dbc is 26.1 yd long, 8.1 wide and 5.8 tall at size
-- 1 - a landmark lying in the grass rather than a bone you pick up.  Its size becomes 0.01,
-- a femur 26 cm long.  That entry backs this one placement and nothing else in the world.
--
-- Idempotent: every statement is an UPDATE keyed on guid, a DELETE keyed on guid, or a
-- REPLACE on a guid this file allocates.  Apply to acore_world, then let the worldserver
-- load the rows.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- The size the review asked for: 26.1 yd of femur at size 1 becomes 26 cm.
UPDATE `gameobject_template` SET `size` = 0.01 WHERE `entry` = 95819;

-- Charred Strongbox (95783): Westfall - Worldforged Blessed Mail Wraps | realm map Westfall
--   authored in game (spawns_20260925_182439.sql): moved 0.00 yd, height +0.43 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10408.300781, `position_y` = 953.700195, `position_z` = 38.507305,
  `orientation` = 1.704529, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.752773000, `rotation3` = 0.658280000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940135;

-- Defias Handshake (95811): The Dead Acre - Worldforged Defias Handshake | realm map Westfall
--   authored in game (spawns_20260925_181231.sql): moved 2.78 yd, height -0.18 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10758.470703, `position_y` = 888.199219, `position_z` = 36.911957,
  `orientation` = 5.158619, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.533119000, `rotation3` = -0.846040000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940338;

-- Defias Mage Stash (90252): Moonbrook - Worldforged Defias Mage Stash | realm map Westfall
--   authored in game (spawns_20260925_180528.sql): moved 2.31 yd, height -0.80 yd, turned 0.461 rad (26.4 deg)
UPDATE `gameobject` SET
  `position_x` = -11097.482422, `position_y` = 1517.019531, `position_z` = 42.983147,
  `orientation` = 4.690856, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.714678852, `rotation3` = -0.699452742,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940340;

-- Defias Remains (90251): Moonbrook - Worldforged Defias Honorcode Memento | realm map Westfall
--   authored in game (spawns_20260925_180415.sql): moved 2.74 yd, height -0.24 yd, turned 0.408 rad (23.4 deg)
UPDATE `gameobject` SET
  `position_x` = -10988.439453, `position_y` = 1614.571289, `position_z` = 44.861526,
  `orientation` = 5.298881, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.472523494, `rotation3` = -0.881318074,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940339;

-- Defias Rusty Gun Rack (90253): Moonbrook - Worldforged Old Defias Gun | realm map Westfall
--   authored in game (spawns_20260925_180500.sql): moved 10.31 yd, height -0.11 yd, turned 2.326 rad (133.3 deg)
UPDATE `gameobject` SET
  `position_x` = -10949.214844, `position_y` = 1568.400391, `position_z` = 46.866566,
  `orientation` = 3.108559, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.999863598, `rotation3` = 0.016516221,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940829;

-- Defias Throwing Knife (95782): Westfall - Worldforged Defias Throwing Knife | realm map Westfall
--   authored in game (spawns_20260925_190316.sql): moved 3.06 yd, height +0.80 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10337.128906, `position_y` = 1219.344727, `position_z` = 41.402954,
  `orientation` = 3.130751, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.999985000, `rotation3` = 0.005421000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940349;

-- Dirt Covered Sword (95820): The Dust Plains - Worldforged Burial Blade | realm map Westfall
--   authored in game (spawns_20260925_181433.sql): moved 12.15 yd, height -0.95 yd, turned 0.946 rad (54.2 deg)
UPDATE `gameobject` SET
  `position_x` = -11278.445312, `position_y` = 1020.040039, `position_z` = 94.373466,
  `orientation` = 1.981366, `rotation0` = -0.493580749, `rotation1` = -0.388371684,
  `rotation2` = -0.650860185, `rotation3` = -0.426528426,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940202;

-- Fisherman's Last Wish (90243): Longshore - Worldforged Fisherman's Last Wish | realm map Westfall
--   authored in game (spawns_20260925_175657.sql): moved 33.19 yd, height -2.11 yd, turned 1.495 rad (85.7 deg)
UPDATE `gameobject` SET
  `position_x` = -9790.015625, `position_y` = 2104.459961, `position_z` = 13.301194,
  `orientation` = 3.502176, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.983791452, `rotation3` = -0.179316424,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940479;

-- Forgotten Shipment (95807): Westfall - Worldforged Forgotten Shipment | realm map Elwynn Forest
--   authored in game (spawns_20260925_182357.sql): moved 9.38 yd, height -0.96 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9892.925781, `position_y` = 808.529297, `position_z` = 22.373011,
  `orientation` = 2.013231, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.845027000, `rotation3` = 0.534724000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940500;

-- Gnoll Cleaver (95780): Longshore - Worldforged Gnoll Cleaver | realm map Westfall
--   authored in game (spawns_20260925_180220.sql): moved 0.07 yd, height +0.33 yd, turned 1.618 rad (92.7 deg)
UPDATE `gameobject` SET
  `position_x` = -9708.171875, `position_y` = 1436.838867, `position_z` = 47.828510,
  `orientation` = 0.123681, `rotation0` = 0.697316186, `rotation1` = -0.043177362,
  `rotation2` = 0.044216256, `rotation3` = 0.714094374,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940554;

-- Harvest Scythe  (95786): The Molsen Farm - Worldforged Harvest Scythe | realm map Westfall
--   authored in game (spawns_20260925_181755.sql): moved 6.88 yd, height +3.57 yd, turned 0.940 rad (53.8 deg)
UPDATE `gameobject` SET
  `position_x` = -10222.539062, `position_y` = 1444.791992, `position_z` = 44.185085,
  `orientation` = 5.042623, `rotation0` = 0.180055129, `rotation1` = 0.544362224,
  `rotation2` = 0.476228607, `rotation3` = -0.666675509,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940595;

-- Harvester?s Aegis (95781): Jangolode Mine - Worldforged Harvester?s Aegis | realm map Westfall
--   authored in game (spawns_20260925_174743.sql): moved 1.17 yd, height +0.33 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10022.794922, `position_y` = 1422.366211, `position_z` = 41.566124,
  `orientation` = 2.274140, `rotation0` = 0.648444976, `rotation1` = 0.300320081,
  `rotation2` = 0.634747850, `rotation3` = 0.293976409,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940596;

-- Heavy Bone (95819): Westfall - Worldforged Heavy Bone | realm map Westfall
--   authored in game (spawns_20260925_190130.sql): moved 13.87 yd, height -1.08 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10081.019531, `position_y` = 1559.546875, `position_z` = 40.055119,
  `orientation` = 0.900070, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.434997000, `rotation3` = 0.900432000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940607;

-- Klaven's Wardrobe (95784): Westfall - Worldforged Defias Apothecary Pants | realm map Westfall
--   authored in game (spawns_20260925_182310.sql): moved 2.32 yd, height +0.34 yd, turned 2.911 rad (166.8 deg)
UPDATE `gameobject` SET
  `position_x` = -11151.513672, `position_y` = 565.304688, `position_z` = 70.870033,
  `orientation` = 5.053698, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.576749320, `rotation3` = -0.816921185,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940334;

-- Liquid Arcane (95808): The Jansen Stead - Worldforged Liquid Arcane | realm map Westfall
--   authored in game (spawns_20260925_181606.sql): moved 3.92 yd, height +0.00 yd, turned 0.439 rad (25.1 deg)
UPDATE `gameobject` SET
  `position_x` = -9845.578125, `position_y` = 1041.665039, `position_z` = 34.809902,
  `orientation` = 1.735543, `rotation0` = 0.464156146, `rotation1` = -0.359323866,
  `rotation2` = 0.617632737, `rotation3` = 0.523426436,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940706;

-- Madness Cursed Notes (90249): Westfall - Worldforged Madness Cursed Notes | realm map Duskwood
--   authored in game (spawns_20260925_182159.sql): moved 2.40 yd, height +1.01 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11123.980469, `position_y` = 515.496094, `position_z` = 32.848824,
  `orientation` = 1.366250, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.631220000, `rotation3` = 0.775604000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940731;

-- Mrlrgrl Pitchfork (1345094): Longshore - Worldforged Mrlrgrl Pitchfork | realm map Westfall
--   authored in game (spawns_20260925_175829.sql): moved 13.15 yd, height -1.35 yd, turned 0.288 rad (16.5 deg)
UPDATE `gameobject` SET
  `position_x` = -10636.316406, `position_y` = 2123.422852, `position_z` = 1.904321,
  `orientation` = 0.288306, `rotation0` = -0.144497718, `rotation1` = -0.604175789,
  `rotation2` = 0.112573363, `rotation3` = 0.775512258,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940774;

-- Peculiar Gold Nugget (90244): Alexston Farmstead - Worldforged Peculiar Gold Nugget | realm map Westfall
--   authored in game (spawns_20260925_174132.sql): moved 5.78 yd, height +7.22 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10556.396484, `position_y` = 1999.857422, `position_z` = -6.881282,
  `orientation` = 2.952160, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.995518000, `rotation3` = 0.094575000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940876;

-- People's Militia Armaments (90247): The Dagger Hills - Worldforged People's Militia Crossbow | realm map Westfall
--   authored in game (spawns_20260925_180754.sql): moved 10.29 yd, height -0.06 yd, turned 0.863 rad (49.4 deg)
UPDATE `gameobject` SET
  `position_x` = -11464.783203, `position_y` = 1515.622070, `position_z` = 50.879410,
  `orientation` = 0.667213, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.327452849, `rotation3` = 0.944867521,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940882;

-- People's Militia Stolen Badge (90250): Jangolode Mine - Worldforged People's Militia Badge | realm map Jangolode Mine
--   authored in game (spawns_20260925_175129.sql): moved 7.89 yd, height -0.97 yd, turned 0.926 rad (53.1 deg)
UPDATE `gameobject` SET
  `position_x` = -9849.759766, `position_y` = 1411.028320, `position_z` = 39.366085,
  `orientation` = 4.567752, `rotation0` = 0.061237960, `rotation1` = -0.052964599,
  `rotation2` = 0.753867567, `rotation3` = -0.652018677,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940879;

-- Quarry Sledge (95785): Gold Coast Quarry - Worldforged Quarry Sledge | realm map Westfall
--   authored in game (spawns_20260925_174846.sql): moved 2.56 yd, height -0.35 yd, turned 0.380 rad (21.8 deg)
UPDATE `gameobject` SET
  `position_x` = -10429.277344, `position_y` = 1926.838867, `position_z` = 9.039962,
  `orientation` = 1.830768, `rotation0` = -0.579714138, `rotation1` = 0.175050057,
  `rotation2` = -0.630903194, `rotation3` = -0.485025933,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940916;

-- Quel'Thalas Sunken Treasure Chest (90240): Longshore - Worldforged Corroded Quel'thalas Ring  | realm map Westfall
--   authored in game (spawns_20260925_180317.sql): moved 39.40 yd, height +6.15 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9590.583984, `position_y` = 1270.700195, `position_z` = -3.569255,
  `orientation` = 4.654330, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.727333000, `rotation3` = -0.686285000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940269;

-- Quel'Thalas Sunken Treasure Chest (90246): Longshore - Worldforged Murky Quel'thalas Drape | realm map Westfall
--   authored in game (spawns_20260925_180050.sql): moved 0.62 yd, height -0.73 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11424.033203, `position_y` = 1827.651367, `position_z` = -4.702791,
  `orientation` = 5.770230, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.253675000, `rotation3` = -0.967290000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940783;

-- Quel'Thalas Sunken Treasure Chest (90242): Longshore - Worldforged Old Quel'thalas Brooch | realm map Westfall
--   authored in game (spawns_20260925_180026.sql): moved 0.00 yd, height +0.32 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10029.900391, `position_y` = 2001.299805, `position_z` = -7.349064,
  `orientation` = 4.060160, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.896370000, `rotation3` = -0.443306000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940838;

-- Quel'Thalas Sunken Treasure Chest (90245): Longshore - Worldforged Rusty Quel'thalas Circlet | realm map Westfall
--   authored in game (spawns_20260925_175909.sql): moved 5.70 yd, height -1.93 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11122.179688, `position_y` = 2110.124023, `position_z` = -7.548529,
  `orientation` = 5.818779, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.230122000, `rotation3` = -0.973162000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940990;

-- Rower's Footlocker (95787): Longshore - Worldforged Rower's Footlocker | realm map Stranglethorn Vale
--   authored in game (spawns_20260925_180141.sql): moved 3.55 yd, height +0.25 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11507.494141, `position_y` = 1765.972656, `position_z` = 0.561586,
  `orientation` = 3.426661, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.989859000, `rotation3` = -0.142052000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940980;

-- Sack of Defias Gear (90254): Moonbrook - Worldforged Sack of Defias Gear | realm map Westfall
--   authored in game (spawns_20260925_180610.sql): moved 5.02 yd, height -0.04 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10946.804688, `position_y` = 1485.422852, `position_z` = 36.657322,
  `orientation` = 1.525300, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.690840000, `rotation3` = 0.723008000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940993;

-- Sentinel's Blade (95810): Sentinel Hill - Worldforged Sentinel's Blade | realm map Westfall
--   authored in game (spawns_20260925_180849.sql): moved 9.25 yd, height -1.17 yd, turned 0.295 rad (16.9 deg)
UPDATE `gameobject` SET
  `position_x` = -10510.189453, `position_y` = 1028.875977, `position_z` = 95.761467,
  `orientation` = 3.659157, `rotation0` = 0.072842866, `rotation1` = 0.588311089,
  `rotation2` = 0.778530923, `rotation3` = -0.206091198,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941048;

-- Sharpened Chopper (95818): The Molsen Farm - Worldforged Sharpened Chopper | realm map Westfall
--   authored in game (spawns_20260925_181942.sql): moved 1.17 yd, height -0.48 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10304.902344, `position_y` = 1408.207031, `position_z` = 40.500175,
  `orientation` = 1.191711, `rotation0` = 0.650423275, `rotation1` = -0.441032102,
  `rotation2` = 0.347066348, `rotation3` = 0.511844896,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941063;

-- Stashed Goods (95814): Westfall - Worldforged Wizard Wraps | realm map Westfall
--   authored in game (spawns_20260925_190013.sql): moved 29.81 yd, height +0.05 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10517.779297, `position_y` = 1577.265625, `position_z` = 46.941963,
  `orientation` = 1.347569, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.623948000, `rotation3` = 0.781466000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941350;

-- Storage Crate (95779): Furlbrow's Pumpkin Farm - Worldforged Pumpkin Smashers | realm map Westfall
--   authored in game (spawns_20260925_174559.sql): moved 3.04 yd, height -0.07 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9870.789062, `position_y` = 1319.565430, `position_z` = 42.967804,
  `orientation` = 3.737951, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.955873000, `rotation3` = -0.293780000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940912;

-- Terrible Defias Mixture (1345147): Westfall - Worldforged Terrible Defias Mixture | realm map Westfall
--   authored in game (spawns_20260925_182232.sql): moved 14.96 yd, height +0.17 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11114.091797, `position_y` = 523.203125, `position_z` = 31.981808,
  `orientation` = 0.518073, `rotation0` = -0.218038450, `rotation1` = -0.822818100,
  `rotation2` = 0.134430591, `rotation3` = 0.507304667,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941205;

-- Westfall Supply Cache (518321): Westfall - Worldforged Leyline Channeling Rod | realm map Westfall
--   authored in game (spawns_20260925_182020.sql): moved 7.56 yd, height -0.08 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10247.205078, `position_y` = 1758.354492, `position_z` = 73.818138,
  `orientation` = 5.106750, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.554879000, `rotation3` = -0.831931000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940698;

-- Abandoned Moonshine (515530) at (-11103.1, 524.7, 31.3) in Westfall, holding Abandoned Moonshine: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940007;

-- Atal'ai Fisher's Boots (254381) at (-10544.8, 770.0, 49.5) in Westfall, holding Atal'ai Angler Boots: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940091;

-- Biggs's Spare Equipment (254380) at (-10795.4, 2072.3, 8.8) in Longshore, holding Biggs's Spare Legguards: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940118;

-- Broken Crate (518344) at (-10754.1, 1961.4, 36.7) in Alexston Farmstead, holding Planned Strike Cord: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940899;

-- Caravaner's Chest (515518) at (-9983.2, 2211.2, -34.1) in Longshore, holding Caravaner's Bracers: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940217;

-- Cartographer's Supplies (254390) at (-10543.2, 1266.5, 66.7) in Sentinel Hill, holding Cartographer's Cape: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940220;

-- Cloud Serpent Feather (515520) at (-10546.4, 1056.6, 47.9) in Sentinel Hill, holding Cloud Serpent Feather: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940258;

-- Cursed Scepter (515514) at (-10006.6, 1651.4, 38.4) in Westfall, holding Cursed Elemental Scepter: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940287;

-- Deadman's Signet (515510) at (-10704.4, 1706.3, 43.8) in Alexston Farmstead: emptied in game (20260925_174354), and the object placed again elsewhere in the zone on guid 6960036 below - this spot goes
DELETE FROM `gameobject` WHERE `guid` = 6940322;

-- Defias Mage Stash (90252) at (-11367.7, 2664.0, -43.7) in Longshore: emptied in game (20260925_175455), and the object placed again elsewhere in the zone on guid 6960037 below - this spot goes
DELETE FROM `gameobject` WHERE `guid` = 6940347;

-- Defias Magus Staff (95816) at (-10748.5, 1658.0, 46.2) in Alexston Farmstead: marked red in the review of 2026-09-25, and taken out of the zone.  The editor also nudged this row in the same walk (spawns_20260925_174517.sql); a removal is the last thing said about a row, so the nudge is not written
DELETE FROM `gameobject` WHERE `guid` = 6940341;

-- Draenic Axe (254561) at (-10078.4, 1301.5, 41.4) in Westfall, holding Axe of the Lost: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940097;

-- Drowned Diver's Signet (515511) at (-10193.2, 1546.4, 41.7) in The Molsen Farm, holding Drowned Diver's Ring: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940382;

-- Exile's Amulet (254391) at (-10101.8, 2137.4, -18.5) in Longshore, holding Exile's Amulet: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940449;

-- Fallow Basket (254364) at (-9938.9, 879.5, 33.5) in Westfall, holding Fallow Tunic: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940461;

-- Floodworn Shoulderguards (95894) at (-10783.0, 1563.6, 48.9) in Westfall, holding Floodworn Shoulderguards: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940489;

-- Forgotten Pauldron (515503) at (-10543.2, 712.6, 32.8) in Westfall, holding Forgotten Pauldron: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940499;

-- Frayed Cord (515508) at (-10356.5, 2386.2, -101.4) in Longshore, holding Highperch Necklace: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940628;

-- Gnawed Kodo Bone (515515) at (-10286.5, 2281.2, -44.4) in Longshore, holding Slightly Magical Kodo Bone: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941100;

-- Gnomish Shotgun (254563) at (-10263.2, 2491.2, -326.0) in The Great Sea, holding Khazno's Shotgun: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940680;

-- Grimtotem Blade (515504) at (-10379.9, 1651.4, 38.2) in Westfall, holding Grimtotem Darkblade: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940581;

-- Harpy Feather (515571) at (-10706.5, 2071.3, 7.8) in Longshore, holding The Tickler: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941221;

-- Harvest Golem Scythe (1345068) at (-10239.9, 1441.5, 40.8) in The Molsen Farm: emptied in game (20260925_181848), and the object placed again elsewhere in the zone on guid 6960038 below - this spot goes
DELETE FROM `gameobject` WHERE `guid` = 6940594;

-- Heavy Boots (95885) at (-10456.1, 1972.2, 9.3) in Gold Coast Quarry, holding Anchorfoot Greaves: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940041;

-- Heavy Boots (95885) at (-10776.5, 1406.5, 23.0) in Stendel's Pond, holding Anchorfoot Greaves: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940608;

-- Highlands Chest (515517) at (-10379.9, 1126.5, 38.0) in Westfall, holding Highlands Vest: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940626;

-- Highvale Scouting Supplies (254572) at (-10599.9, 1385.5, 41.3) in Westfall, holding Sash of Contemplation: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941004;

-- Infused Staff (254560) at (-10473.2, 1931.3, 8.8) in Gold Coast Quarry, holding Staff of the Wind Sisters: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941141;

-- Leftover Kodo War Drum (515533) at (-10908.8, 636.7, 30.0) in The Dust Plains, holding Kodo War Drum: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940683;

-- Needlewind Crossbow (97136) at (-10683.1, 1196.5, 46.8) in Sentinel Hill, holding Needlewind Crossbow: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940798;

-- Offering Pendant (1345101) at (-10164.1, 858.9, 31.7) in Westfall, holding Offering Pendant: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940815;

-- Plains Bolter (95875) at (-10122.1, 1511.4, 42.0) in Westfall, holding Plains Bolter: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940895;

-- Reinforced Helmet (517263) at (-10022.2, 1290.6, 43.3) in Furlbrow's Pumpkin Farm, holding Ironwood Cap: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940659;

-- Reverent of Earth (254559) at (-10272.3, 840.0, 42.3) in Westfall, holding Earth Reverent's Sash: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940408;

-- Ritual Hideskinner (95889) at (-10748.0, 1910.0, 47.6) in Alexston Farmstead, holding Hide Piercer: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940622;

-- Ruby Giant's Eye (254400) at (-10634.4, 812.3, 50.9) in Westfall, holding Giant Ruby Eye: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940539;

-- Rusted Shield (254395) at (-10375.2, 1933.8, 20.3) in Gold Coast Quarry, holding Rusted Shield: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940988;

-- Rusty Hatchet (515505) at (-10169.9, 1476.4, 40.8) in The Molsen Farm, holding Centaur Mining Axe: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940227;

-- Scuba Slayer's Blade (515524) at (-10169.9, 1546.4, 43.0) in The Molsen Farm, holding Scuba Slayer's Blade: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941037;

-- Sha-Bane Staff (254377) at (-10531.0, 2248.3, -24.9) in Longshore, holding Sha-Bane Staff: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941050;

-- Silithid Wall Creeper (515534) at (-11429.7, 776.6, 103.6) in Westfall, holding Silithid Bug Blaster: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941079;

-- Small Emerald (517204) at (-11298.8, 1225.2, 151.5) in The Dagger Hills, holding Emerald Circle Charm: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940428;

-- Stolen Supplies (518322) at (-10963.1, 1025.1, 37.9) in Westfall, holding Rehomed Belt: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940947;

-- Strange Trinket (515509) at (-10216.5, 1756.4, 36.0) in Westfall, holding Darkcloud Braid: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940308;

-- Travel Sack (68403) at (-10644.4, 1170.3, 33.3) in Sentinel Hill, holding Break-time Gloves: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941272;

-- Witherbark Chest (95892) at (-10958.9, 1891.4, 44.3) in Westfall, holding Brood Caller's Raiment: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6940191;

-- Wyvern Trapper Spear (1345182) at (-10309.9, 2613.6, -393.6) in The Great Sea: removed in game (20260925_175347) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6941358;

-- Zun'watha Cleaver (95882) at (-10768.5, 2209.1, -17.0) in Longshore, holding Zun'watha Cleaver: marked red in the review of 2026-09-25 - taken out of the zone
DELETE FROM `gameobject` WHERE `guid` = 6941374;

-- Deadman's Signet (515510): a placement the realm authored by hand (20260925_174354), guid 6960036 allocated here - the spot the editor emptied is deleted above
--   it stands in Raven Hill Cemetery and keeps the loot row its object already carried (Deadman's Signet)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960036, 515510, 0, 0, 0, 1, 1, -10280.898438, 74.771484, 39.107048, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Deadman''s Signet | in-game placement 2026-09-25 (spawns_20260925_174354.sql)');

-- Defias Mage Stash (90252): a placement the realm authored by hand (20260925_175455), guid 6960037 allocated here - the spot the editor emptied is deleted above
--   it stands in Moonbrook and keeps the loot row its object already carried (Defias Sprig)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960037, 90252, 0, 0, 0, 1, 1, -11044.369141, 1427.211914, 44.171074, 5.712904, 0.000000000, 0.000000000, -0.281292487, 0.959622080, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Defias Sprig | in-game placement 2026-09-25 (spawns_20260925_175455.sql)');

-- Harvest Golem Scythe (1345068): a placement the realm authored by hand (20260925_181848), guid 6960038 allocated here - the spot the editor emptied is deleted above
--   it stands in The Dead Acre and keeps the loot row its object already carried (Harvest Golem Scythe)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960038, 1345068, 0, 0, 0, 1, 1, -10810.443359, 828.189453, 37.313030, 4.961185, -0.403773719, -0.314018245, -0.527516605, 0.678296069, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Harvest Golem Scythe | in-game placement 2026-09-25 (spawns_20260925_181848.sql)');

COMMIT;
