-- ----------------------------------------------------------------------------
-- Worldforged pickups: their height on the ground, and their recorded places.
-- ----------------------------------------------------------------------------
-- Four blocks, each read out of collected data rather than chosen here:
--
--   a  the height a GameObject dump observed. A dump holds the position its collector
--      stood at with the object in front of them, so where one is within 40 yd of our
--      spawn and disagrees with the height the earlier migrations leave by more than
--      10 yd, the observation replaces it.
--
--   d  the height of a placement standing on nothing: no prop or creature the realm already
--      has within 80 yd stands within 60 yd of it, so nothing local supports that height.
--      The floor those neighbours share replaces it.
--
--   b  a placement an earlier pass wrote straight into the database from collected data and
--      never wrote a migration for - the place the Exiles database documents behind an item,
--      and a recorded loot position the CoA-only pass dropped. Stated here from the rows
--      themselves, so the module owns them and a fresh database has them.
--
--   e  the facing of a placement that carries none, copied from another placement of the
--      same object - a value Ascension gave that object, kept consistent with its quaternion.
--
--   c  a position the community recorded looting an item at, where the restoration has
--      no placement of that object on the map at all, or none within 150 yd. A pin is
--      where the looter stood, so a pin a few yards from an existing spawn says nothing
--      and is left out.
--
-- A new spawn needs no loot row: gameobject_loot_template is keyed by the object entry,
-- so a second placement of an object already in the world carries that entry's loot.
--
-- A pin carries no height, so each added row takes it from what a player meets there, in
-- order: the floor the realm's own occupants share (the median height of the creatures and
-- objects already spawned within 80 yd, then within 200 yd), then the terrain surface the
-- worldserver itself reads, then a realm dump of that same object nearby. A row no witness
-- can place is not added.
-- ----------------------------------------------------------------------------


-- a: the height a dump observed
UPDATE `gameobject` SET `position_z` = CASE `guid`
  WHEN 6903164 THEN 12.164
  WHEN 6903319 THEN 389.198
  ELSE `position_z` END
WHERE `guid` IN (6903164, 6903319);

-- d: a height nothing local supports
UPDATE `gameobject` SET `position_z` = CASE `guid`
  WHEN 6900007 THEN 30.62
  WHEN 6900322 THEN 161.341
  WHEN 6900726 THEN 56.766
  WHEN 6900782 THEN 18.179
  WHEN 6900808 THEN -271.79
  WHEN 6900876 THEN 105.612
  WHEN 6901352 THEN 42.783
  WHEN 6903001 THEN 17.593
  WHEN 6903047 THEN 84.981
  WHEN 6903053 THEN 102.249
  WHEN 6903074 THEN 43.962
  WHEN 6903127 THEN 84.981
  WHEN 6903144 THEN 87.494
  WHEN 6903160 THEN 87.743
  WHEN 6903168 THEN 88.53
  WHEN 6903169 THEN 88.349
  WHEN 6903170 THEN 87.494
  WHEN 6903171 THEN 87.807
  WHEN 6903173 THEN 172.428
  WHEN 6903233 THEN 26.505
  WHEN 6903245 THEN 131.976
  WHEN 6903325 THEN 23.002
  WHEN 6903336 THEN 136.034
  WHEN 6903381 THEN 266.69
  WHEN 6903387 THEN 102.643
  WHEN 6903408 THEN 16.345
  WHEN 6903446 THEN 260.681
  WHEN 6903463 THEN 85.433
  WHEN 6903550 THEN 85.284
  WHEN 6903621 THEN 6.599
  WHEN 6903635 THEN 148.319
  WHEN 6903647 THEN 111.143
  WHEN 6903662 THEN 122.403
  WHEN 6903692 THEN 85.526
  WHEN 6903700 THEN 12.547
  WHEN 6903723 THEN 285.44
  WHEN 6903793 THEN 13.146
  WHEN 6903799 THEN 7.752
  WHEN 6903816 THEN 266.817
  WHEN 6903834 THEN 267.629
  WHEN 6903846 THEN 7.761
  WHEN 6903850 THEN 211.551
  WHEN 6903869 THEN 27.978
  WHEN 6903895 THEN 177.294
  WHEN 6903920 THEN 168.541
  WHEN 6903923 THEN 50.96
  WHEN 6903938 THEN 354.353
  WHEN 6903951 THEN 180.995
  WHEN 6903993 THEN 161.341
  WHEN 6904000 THEN 13.146
  WHEN 6904052 THEN 356.39
  WHEN 6904127 THEN 84.981
  WHEN 6904180 THEN 99.657
  WHEN 6904288 THEN 1290.9
  WHEN 6904400 THEN 123.402
  WHEN 6904442 THEN 434.671
  WHEN 6904443 THEN 435.571
  WHEN 6904446 THEN 1326.53
  WHEN 6904449 THEN 1323.75
  WHEN 6904514 THEN 64.929
  WHEN 6904521 THEN -0.474
  WHEN 6904648 THEN 1326.03
  WHEN 6904652 THEN 1326.09
  WHEN 6904705 THEN 1329.36
  WHEN 6904738 THEN 16.791
  WHEN 6904764 THEN 6.193
  WHEN 6904832 THEN 6.308
  WHEN 6904833 THEN 1301.77
  WHEN 6904849 THEN 1331.51
  WHEN 6904873 THEN 1326.33
  WHEN 6904881 THEN 1325.87
  WHEN 6904882 THEN 1330.07
  WHEN 6904914 THEN 1324.12
  WHEN 6904918 THEN 1323.75
  WHEN 6904947 THEN 58.532
  WHEN 6904975 THEN 34.708
  WHEN 6904994 THEN 66.919
  WHEN 6904995 THEN 1336.0
  WHEN 6905276 THEN -99.928
  WHEN 6905281 THEN -136.772
  WHEN 6910020 THEN 416.775
  WHEN 6910029 THEN 85.743
  WHEN 6910033 THEN 100.575
  WHEN 6910116 THEN 230.967
  WHEN 6910146 THEN 268.285
  WHEN 6910239 THEN 1327.63
  WHEN 6910248 THEN 30.62
  WHEN 6910253 THEN 122.992
  WHEN 6910267 THEN -84.732
  WHEN 6920020 THEN 1301.77
  ELSE `position_z` END
WHERE `guid` IN (6900007, 6900322, 6900726, 6900782, 6900808, 6900876, 6901352, 6903001, 6903047, 6903053, 6903074, 6903127, 6903144, 6903160, 6903168, 6903169, 6903170, 6903171, 6903173, 6903233, 6903245, 6903325, 6903336, 6903381, 6903387, 6903408, 6903446, 6903463, 6903550, 6903621, 6903635, 6903647, 6903662, 6903692, 6903700, 6903723, 6903793, 6903799, 6903816, 6903834, 6903846, 6903850, 6903869, 6903895, 6903920, 6903923, 6903938, 6903951, 6903993, 6904000, 6904052, 6904127, 6904180, 6904288, 6904400, 6904442, 6904443, 6904446, 6904449, 6904514, 6904521, 6904648, 6904652, 6904705, 6904738, 6904764, 6904832, 6904833, 6904849, 6904873, 6904881, 6904882, 6904914, 6904918, 6904947, 6904975, 6904994, 6904995, 6905276, 6905281, 6910020, 6910029, 6910033, 6910116, 6910146, 6910239, 6910248, 6910253, 6910267, 6920020);

-- b: a placement an earlier pass wrote straight into the database
DELETE FROM `gameobject` WHERE `guid` BETWEEN 6930001 AND 6930142;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
  `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`,
  `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6930001,68394,0,0,0,1,1,-6962.46,-1237.12,242.125,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Jewelled Ring | AtlasLoot Searing Gorge | Z from the realm dump''s own height there'),
(6930002,68410,0,0,0,1,1,-6709.67,-1147.84,185.571,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Dirt Mound | AtlasLoot Searing Gorge | Z from the realm dump''s own height there'),
(6930003,68428,0,0,0,1,1,-6456.88,-1415.68,129.727,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Pile of Bones | AtlasLoot Searing Gorge | Z from the realm dump''s own height there'),
(6930004,90215,0,0,0,1,1,-9042.29,-248.44,72.742,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Old Grave  | AtlasLoot Northshire Valley | Z from the terrain the worldserver reads'),
(6930005,90253,0,0,0,1,1,-11009.8,1476.44,46.978,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Defias Rusty Gun Rack | AtlasLoot Westfall | Z from the realm dump''s own height there'),
(6930006,90255,0,0,0,1,1,-8777.58,-1982.49,133.027,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Dirtpaw Trousers | AtlasLoot Redridge Mountains | Z from the realm dump''s own height there'),
(6930007,90259,0,0,0,1,1,-8676.29,-2308.14,158.167,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Blackrock Armor Supplies | AtlasLoot Redridge Mountains | Z from the realm dump''s own height there'),
(6930008,90260,0,0,0,1,1,-9370.85,-3089.7,78.795,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Shadowhide Treasure | AtlasLoot Redridge Mountains | Z from the realm dump''s own height there'),
(6930009,90263,0,0,0,1,1,-9703.66,-2633.79,63.793,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Chocked Fish Corpse | AtlasLoot Redridge Mountains | Z from the terrain the worldserver reads'),
(6930010,90269,0,0,0,1,1,-10310,-3.69,43.195,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Eliza''s Pendant | AtlasLoot Duskwood | Z from the realm dump''s own height there'),
(6930011,90272,0,0,0,1,1,-11048,-1326.2,52.73,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Darkshire Grave | AtlasLoot Duskwood | Z from the realm dump''s own height there'),
(6930012,90274,0,0,0,1,1,-11138,-435.53,34.595,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Defias Night Blade | AtlasLoot Duskwood | Z from the realm dump''s own height there'),
(6930013,90280,0,0,0,1,1,-9095.92,-2525.24,131.138,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Burning Scales of the Black Dragonflight Matriarch | AtlasLoot Redridge Mountains | Z from the realm dump''s own height there'),
(6930014,90283,0,0,0,1,1,-10328,401.16,12.164,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Alchemy Visceral Juice | AtlasLoot Duskwood | Z from the realm dump''s own height there'),
(6930015,90285,0,0,0,1,1,-10292,158.25,1.809,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Sharp Bone Necklace | AtlasLoot Duskwood | Z from the realm dump''s own height there'),
(6930016,90349,0,0,0,1,1,1246.15,1938,20.901,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Meat Wagon Small Claw | AtlasLoot Silverpine Forest | Z from the realm dump''s own height there'),
(6930017,90478,0,0,0,1,1,2010.56,-3778.47,120.051,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Fallen Sentry Armor | AtlasLoot Eastern Plaguelands | Z from the realm dump''s own height there'),
(6930018,90501,0,0,0,1,1,2763.2,-4624.98,91.017,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Cauterizing Needle | AtlasLoot Eastern Plaguelands | Z from the terrain the worldserver reads'),
(6930019,90623,0,0,0,1,1,3209.95,-3324.98,147.486,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Golden Circlet | AtlasLoot Eastern Plaguelands | Z from the realm dump''s own height there'),
(6930020,95510,0,0,0,1,1,-5387.18,-1300.12,447.858,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged A Really Pointy Bone | AtlasLoot Dun Morogh | Z from the realm dump''s own height there'),
(6930021,95513,0,0,0,1,1,-5518.57,-194.72,346.859,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Snow Pile | AtlasLoot The Grizzled Den | Z from the realm dump''s own height there'),
(6930022,95525,0,0,0,1,1,-5719.8,-3979.48,332.619,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Galgosh''s Other Bone | AtlasLoot Loch Modan | Z from the realm dump''s own height there'),
(6930023,95534,0,0,0,1,1,734.94,-448.56,193.434,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Runed Quill Plume | AtlasLoot Alterac Mountains | Z from the terrain the worldserver reads'),
(6930024,95605,0,0,0,1,1,-6917.85,-835.36,262.491,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Fire Poker | AtlasLoot Searing Gorge | Z from the terrain the worldserver reads'),
(6930025,95743,0,0,0,1,1,-11550.9,-587.2,31.098,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Heavy Jungle Chopper | AtlasLoot Stranglethorn Vale | Z from the realm dump''s own height there'),
(6930026,95765,0,0,0,1,1,-12784.5,-268.2,40.396,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Clawed Up Bag | AtlasLoot Stranglethorn Vale | Z from the realm dump''s own height there'),
(6930027,95847,0,0,0,1,1,-853,-2054,37.68,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Clothing Crate | AtlasLoot Arathi Highlands | Z from the realm dump''s own height there'),
(6930028,95848,0,0,0,1,1,-901,-2054,37.107,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Handheld Persuasion Device | AtlasLoot Arathi Highlands | Z from the realm dump''s own height there'),
(6930029,95872,0,0,0,1,1,-1357,-1910,44.943,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Abandoned Supplies | AtlasLoot Arathi Highlands | Z from the realm dump''s own height there'),
(6930030,95882,0,0,0,1,1,-10776.5,2211.23,-16.981,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Zun''watha Cleaver | AtlasLoot Westfall | Z from the terrain the worldserver reads'),
(6930031,96196,0,0,0,1,1,-12827.1,-1289,210.328,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Rusted Shoulderplate | AtlasLoot Stranglethorn Vale | Z from the terrain the worldserver reads'),
(6930032,96199,0,0,0,1,1,-12699.4,-1097.6,150.69,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Kum''isha''s Supply Chest | AtlasLoot Stranglethorn Vale | Z from the terrain the worldserver reads'),
(6930033,96206,0,0,0,1,1,-12442.6,-3016.5,127.673,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Empowered Scythe | AtlasLoot Blasted Lands | Z from the terrain the worldserver reads'),
(6930034,96208,0,0,0,1,1,-12442.6,-2916,88.125,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Skewered Doll | AtlasLoot Blasted Lands | Z from the terrain the worldserver reads'),
(6930035,96210,0,0,0,1,1,-12464.9,-2949.5,120.896,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Smoldering Boots | AtlasLoot Blasted Lands | Z from the terrain the worldserver reads'),
(6930036,96233,0,0,0,1,1,3215.05,-4644.33,117.439,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Spare Hammer | AtlasLoot Eastern Plaguelands | Z from the terrain the worldserver reads'),
(6930037,158300,0,0,0,1,1,-6665.06,-1192.48,209.407,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Elder''s Pipe | AtlasLoot Searing Gorge | Z from the realm dump''s own height there'),
(6930038,158305,0,0,0,1,1,-6635.32,-1304.08,210.953,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Wrench | AtlasLoot Searing Gorge | Z from the realm dump''s own height there'),
(6930039,254166,0,0,0,1,1,3083.75,1632.42,-37.885,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Quivering Web | AtlasLoot Tirisfal Glades | Z from the terrain the worldserver reads'),
(6930040,254318,0,0,0,1,1,753.6,-392.58,139.626,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Embrace of the Fifth | AtlasLoot Alterac Mountains | Z from the terrain the worldserver reads'),
(6930041,254338,0,0,0,1,1,287.1,-392.58,172.982,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Icy Grave | AtlasLoot Alterac Mountains | Z from the realm dump''s own height there'),
(6930042,254342,0,0,0,1,1,660.3,-336.6,155.711,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Snow Buried Shipment | AtlasLoot Alterac Mountains | Z from the realm dump''s own height there'),
(6930043,254375,0,0,0,1,1,-8646.94,-177.66,102.082,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Kazkaz''s Ceremonial Mask | AtlasLoot Echo Ridge Mine | Z from the terrain the worldserver reads'),
(6930044,254376,0,0,0,1,1,-10271.7,-3828.6,-109.893,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Atal''ai Alchemy Supplies | AtlasLoot Azeroth | Z from the realm dump''s own height there'),
(6930045,254383,0,0,0,1,1,-10828.7,-3460.76,103.023,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Idol to Hakkar | AtlasLoot Swamp of Sorrows | Z from the terrain the worldserver reads'),
(6930046,254400,0,0,0,1,1,-10844,-3460.76,81.921,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Ruby Giant''s Eye | AtlasLoot Swamp of Sorrows | Z from the terrain the worldserver reads'),
(6930047,254497,0,0,0,1,1,-10476.8,-3460.76,21.662,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Ogrish Handaxe | AtlasLoot Swamp of Sorrows | Z from the terrain the worldserver reads'),
(6930048,254540,0,0,0,1,1,-9110.39,-2394.98,129.786,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Gnollish Headwear | AtlasLoot Redridge Mountains | Z from the realm dump''s own height there'),
(6930049,254541,0,0,0,1,1,-9139.33,-2677.21,90.106,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Web-Covered Belt | AtlasLoot Redridge Mountains | Z from the realm dump''s own height there'),
(6930050,254649,0,0,0,1,1,-8397.4,-1730.5,232.704,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Blackened Object | AtlasLoot Burning Steppes | Z from the terrain the worldserver reads'),
(6930051,254664,0,0,0,1,1,-8397.4,-1613.34,232.738,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Thar''zul''s Staff | AtlasLoot Burning Steppes | Z from the terrain the worldserver reads'),
(6930052,340127,0,0,0,1,1,2850.12,-1475.56,148.69,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Burning Judgement | AtlasLoot Western Plaguelands | Z from the realm dump''s own height there'),
(6930053,387875,0,0,0,1,1,-2753.54,-1547.08,10.524,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Swiftgear Sniper | AtlasLoot Wetlands | Z from the dump catalogue''s example height there'),
(6930054,515384,0,0,0,1,1,-901.13,-853.4,31.29,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Crude Effigy | AtlasLoot Hillsbrad Foothills | Z from the realm dump''s own height there'),
(6930055,515386,0,0,0,1,1,-730.49,-1461.21,65.296,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Eroded Pit Fighter Knuckles | AtlasLoot Hillsbrad Foothills | Z from the terrain the worldserver reads'),
(6930056,515403,0,0,0,1,1,-858.47,74.31,10.947,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Foreman''s Lightcap | AtlasLoot Hillsbrad Foothills | Z from the realm dump''s own height there'),
(6930057,517322,0,0,0,1,1,-751.82,-373.55,17.979,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Alder''s Axe | AtlasLoot Hillsbrad Foothills | Z from the realm dump''s own height there'),
(6930058,518346,0,0,0,1,1,-6950.12,-2402.31,247.669,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Dusty Sack | AtlasLoot Badlands | Z from the realm dump''s own height there'),
(6930060,520051,0,0,0,1,1,2023.62,1712.08,136.819,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Sturdy Arrow | AtlasLoot Deathknell | Z from the realm dump''s own height there'),
(6930061,520073,0,0,0,1,1,-6255.12,642.61,387.051,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Radiant Rifle | AtlasLoot Coldridge Valley | Z from the terrain the worldserver reads'),
(6930062,1345004,0,0,0,1,1,2631.8,1045.08,101.101,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Apothecary''s Lantern | AtlasLoot Tirisfal Glades | Z from the terrain the worldserver reads'),
(6930063,1345005,0,0,0,1,1,2631.8,1045.08,101.101,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Apothecary''s Lantern | AtlasLoot Tirisfal Glades | Z from the terrain the worldserver reads'),
(6930064,1345006,0,0,0,1,1,2631.8,1045.08,101.101,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Apothecary''s Lantern | AtlasLoot Tirisfal Glades | Z from the terrain the worldserver reads'),
(6930065,1345020,0,0,0,1,1,-10752.2,-3208.42,24.744,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Celsalia''s Luxorious Robes | AtlasLoot Swamp of Sorrows | Z from the terrain the worldserver reads'),
(6930066,1345067,0,0,0,1,1,-5204.6,-3813.94,323.15,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Haren''s Tankard | AtlasLoot Loch Modan | Z from the terrain the worldserver reads'),
(6930067,1345112,0,0,0,1,1,2905.13,-2614.72,89.344,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Red Metal Pauldrons | AtlasLoot Eastern Plaguelands | Z from the terrain the worldserver reads'),
(6930068,1345124,0,0,0,1,1,-10461.5,-3277.24,21.334,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Sentinel Wrap | AtlasLoot Swamp of Sorrows | Z from the terrain the worldserver reads'),
(6930069,1345129,0,0,0,1,1,-1285,-2738,53.951,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Silken Travel Gloves | AtlasLoot Arathi Highlands | Z from the terrain the worldserver reads'),
(6930070,1345154,0,0,0,1,1,399.06,-1512.18,47.922,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Totem of the Flowing River | AtlasLoot Alterac Mountains | Z from the terrain the worldserver reads'),
(6930071,90296,1,0,0,1,1,-495,-4424.67,62.209,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Non-work Approved Bedroll | AtlasLoot Valley of Trials | Z from the terrain the worldserver reads'),
(6930072,90338,1,0,0,1,1,-2327,-418.28,-8.065,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Venture Co. Unique Concoction | AtlasLoot Mulgore | Z from the terrain the worldserver reads'),
(6930074,90606,1,0,0,1,1,-165.44,-5081.92,19.538,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Shabby Knife | AtlasLoot Durotar | Z from the terrain the worldserver reads'),
(6930075,90626,1,0,0,1,1,10936.6,853.67,1333.99,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Mossy Bag | AtlasLoot Shadowglen | Z from the terrain the worldserver reads'),
(6930077,95635,1,0,0,1,1,5341,-3277,1650.5,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Assassin''s Crossbow | AtlasLoot Azshara | Z from the terrain the worldserver reads'),
(6930078,95652,1,0,0,1,1,-59.72,-4976.16,17.213,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Loot Basket | AtlasLoot Durotar | Z from the terrain the worldserver reads'),
(6930079,95668,1,0,0,1,1,116.48,-5134.8,1.271,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Spare Boots | AtlasLoot Durotar | Z from the terrain the worldserver reads'),
(6930080,95920,1,0,0,1,1,-7914.93,-1168.54,-328.145,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Crystal Resonator Coffer | AtlasLoot Un''Goro Crater | Z from the realm dump''s own height there'),
(6930081,95921,1,0,0,1,1,-1865.78,-1151.45,151.795,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Hive Queen''s Antenna | AtlasLoot The Venture Co. Mine | Z from the terrain the worldserver reads'),
(6930082,95927,1,0,0,1,1,-8146.75,-1171.17,-331.459,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Fallen Axe | AtlasLoot The Slithering Scar | Z from the realm dump''s own height there'),
(6930083,95933,1,0,0,1,1,-7988.94,-1316.5,-312.482,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Volcano Heated Crown | AtlasLoot Un''Goro Crater | Z from the realm''s occupants there'),
(6930084,95934,1,0,0,1,1,-423,-4303.17,44.332,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Precious Ring | AtlasLoot Valley of Trials | Z from the terrain the worldserver reads'),
(6930085,96104,1,0,0,1,1,-3756.2,229.25,114.325,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Large Bone | AtlasLoot Feralas | Z from the realm dump''s own height there'),
(6930086,96159,1,0,0,1,1,6021.43,-1118.52,392.28,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Fel Axe | AtlasLoot Felwood | Z from the terrain the worldserver reads'),
(6930087,96167,1,0,0,1,1,-765,-4573.17,64.53,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Shareholder''s Coffer | AtlasLoot Valley of Trials | Z from the terrain the worldserver reads'),
(6930088,96168,1,0,0,1,1,-756,-4586.67,49.081,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Polished Rifle | AtlasLoot Valley of Trials | Z from the terrain the worldserver reads'),
(6930089,96173,1,0,0,1,1,-6360.72,-2019.31,-261.251,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Jane''s Hat | AtlasLoot Un''Goro Crater | Z from the realm dump''s own height there'),
(6930090,96174,1,0,0,1,1,-8038.28,-1242.52,-270.572,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Kodo Riding Harness | AtlasLoot Un''Goro Crater | Z from the terrain the worldserver reads'),
(6930091,96180,1,0,0,1,1,-7964.27,-1205.53,-274.672,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Spear of a Slain Hunter | AtlasLoot Un''Goro Crater | Z from the terrain the worldserver reads'),
(6930092,96216,1,0,0,1,1,-7988.94,-1390.48,-268.379,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Sharpened Hatchet | AtlasLoot Un''Goro Crater | Z from the terrain the worldserver reads'),
(6930093,96218,1,0,0,1,1,-8087.62,-1316.5,-207.499,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Steel Helmet | AtlasLoot Un''Goro Crater | Z from the realm dump''s own height there'),
(6930094,96220,1,0,0,1,1,-675,-4235.67,67.239,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Ritual Chest | AtlasLoot Valley of Trials | Z from the terrain the worldserver reads'),
(6930095,159984,1,0,0,1,1,-7839.63,1109.38,3.159,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Crystal Axe | AtlasLoot Silithus | Z from the terrain the worldserver reads'),
(6930096,254311,1,0,0,1,1,-6977.47,-1797.37,-259.455,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Hidden Stash | AtlasLoot Un''Goro Crater | Z from the terrain the worldserver reads'),
(6930097,254402,1,0,0,1,1,-2424.33,405,64.929,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Everdark Shard | AtlasLoot Palemane Rock | Z from the terrain the worldserver reads'),
(6930098,254405,1,0,0,1,1,-4378,-3914.56,54.595,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Cylla''s Endless Potion | AtlasLoot Dustwallow Marsh | Z from the terrain the worldserver reads'),
(6930099,254415,1,0,0,1,1,4225.27,-6369.7,-20.83,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Ursolan Totem | AtlasLoot Azshara | Z from the terrain the worldserver reads'),
(6930100,254443,1,0,0,1,1,4022.41,-6521.8,-11.961,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Fel Hunter''s Spike | AtlasLoot Azshara | Z from the terrain the worldserver reads'),
(6930101,254457,1,0,0,1,1,4022.41,-6369.7,-9.394,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Glowing Shard | AtlasLoot Azshara | Z from the terrain the worldserver reads'),
(6930102,254468,1,0,0,1,1,3954.79,-6623.2,-18.196,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Duke''s Staff | AtlasLoot Azshara | Z from the terrain the worldserver reads'),
(6930103,254484,1,0,0,1,1,-8707.08,-4425.8,27.419,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Hexed Staff | AtlasLoot Caverns of Time | Z from the terrain the worldserver reads'),
(6930104,254581,1,0,0,1,1,-4448,-3914.56,31.377,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Runic Belt | AtlasLoot Dustwallow Marsh | Z from the terrain the worldserver reads'),
(6930105,254633,1,0,0,1,1,46,-5081.92,7.718,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Shiny Hammer | AtlasLoot Durotar | Z from the terrain the worldserver reads'),
(6930106,357440,1,0,0,1,1,6687.13,-4505,722.396,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Maddening Satchel | AtlasLoot Winterspring | Z from the terrain the worldserver reads'),
(6930107,375005,1,0,0,1,1,7065.77,-4505,653.915,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged The Leaping Arc | AtlasLoot Winterspring | Z from the terrain the worldserver reads'),
(6930108,515436,1,0,0,1,1,11254,1573.96,9.307,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Heirloom of the Whisperwind | AtlasLoot Teldrassil | Z from the terrain the worldserver reads'),
(6930109,515517,1,0,0,1,1,-6107.82,-2809,40.872,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Highlands Chest | AtlasLoot Thousand Needles | Z from the terrain the worldserver reads'),
(6930110,515764,1,0,0,1,1,-9923,-3806,116.073,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Tender''s Hat | AtlasLoot Tanaris | Z from the terrain the worldserver reads'),
(6930111,515769,1,0,0,1,1,-6427,-4082,-63.555,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Qiraji-Touched Tool | AtlasLoot Tanaris | Z from the terrain the worldserver reads'),
(6930112,515866,1,0,0,1,1,-5470.78,2661.4,-281.117,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Gregan Tanning Rack | AtlasLoot Feralas | Z from the terrain the worldserver reads'),
(6930113,515952,1,0,0,1,1,838.81,-4772.14,65.768,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Durn''s Loot Bag | AtlasLoot Dustwind Cave | Z from the terrain the worldserver reads'),
(6930114,517234,1,0,0,1,1,5944.77,-1118.52,424.643,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Silverhand Spaulder | AtlasLoot Felwood | Z from the terrain the worldserver reads'),
(6930115,517277,1,0,0,1,1,-3061.1,2452.93,105.156,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Rotwood Rapier | AtlasLoot Feralas | Z from the terrain the worldserver reads'),
(6930116,518171,1,0,0,1,1,-7769.94,935.28,-0.739,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Twilight Infusion | AtlasLoot Silithus | Z from the terrain the worldserver reads'),
(6930117,518461,1,0,0,1,1,-7793.17,1039.74,-1.767,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Twilight Stave | AtlasLoot Silithus | Z from the terrain the worldserver reads'),
(6930118,518464,1,0,0,1,1,-260.3,-4298.1,55.12,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Scorpion Corpse | AtlasLoot Sinister Lair | Z from the terrain the worldserver reads'),
(6930119,518565,1,0,0,1,1,7302.42,-4434,648.114,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Suffering Soul | AtlasLoot Winterspring | Z from the terrain the worldserver reads'),
(6930120,518586,1,0,0,1,1,7207.76,-4363,650.293,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Icy Blade | AtlasLoot Winterspring | Z from the terrain the worldserver reads'),
(6930121,686871,1,0,0,1,1,-51.32,-4413.67,121.825,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Infested Pauldrons | AtlasLoot Sinister Lair | Z from the terrain the worldserver reads'),
(6930122,686935,1,0,0,1,1,7397.08,-4292,677.648,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Excavator''s Buckler | AtlasLoot Winterspring | Z from the terrain the worldserver reads'),
(6930124,1344803,1,0,0,1,1,10936.6,853.67,1333.99,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Eye-Catching Item Rack | AtlasLoot Shadowglen | Z from the terrain the worldserver reads'),
(6930125,1345017,1,0,0,1,1,-143.7,169.34,58.181,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Boulder Greaves | AtlasLoot Stonetalon Mountains | Z from the terrain the worldserver reads'),
(6930126,1345075,1,0,0,1,1,5319.77,-1250.36,1323.98,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Idol of the Brooding Shadow | AtlasLoot Darkshore | Z from the terrain the worldserver reads'),
(6930127,1345087,1,0,0,1,1,1409.35,-3457.2,93.541,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Loded Ring | AtlasLoot The Barrens | Z from the terrain the worldserver reads'),
(6930128,1345098,1,0,0,1,1,-2663,-3546.99,34.066,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Northpoint Helmet | AtlasLoot Dustwallow Marsh | Z from the terrain the worldserver reads'),
(6930129,1345105,1,0,0,1,1,7633.73,-4931,696.232,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Owlbeast Talon | AtlasLoot Winterspring | Z from the terrain the worldserver reads'),
(6930130,1345134,1,0,0,1,1,-7862.86,970.1,2.904,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Southwind Defender | AtlasLoot Silithus | Z from the terrain the worldserver reads'),
(6930131,1345143,1,0,0,1,1,-1116.92,-5557.84,6.899,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged String of Ears | AtlasLoot Durotar | Z from the terrain the worldserver reads'),
(6930132,1345150,1,0,0,1,1,-2429.75,-418.28,-3.457,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged The "Kodo Egg" | AtlasLoot Mulgore | Z from the terrain the worldserver reads'),
(6930133,1345156,1,0,0,1,1,1274.25,-3558.52,96.171,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Venture Co. Boots | AtlasLoot The Barrens | Z from the terrain the worldserver reads'),
(6930134,1345161,1,0,0,1,1,328.55,-2241.36,237.986,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Vial of Dread Water | AtlasLoot The Barrens | Z from the terrain the worldserver reads'),
(6930135,1345183,1,0,0,1,1,6673.54,714.34,-14.011,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Zipcoil''s Zapper Cap | AtlasLoot Darkshore | Z from the terrain the worldserver reads'),
(6930136,90292,43,0,0,1,1,-204.08,242.42,-72.527,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Worn Axe | AtlasLoot Wailing Caverns | Z from the nearest occupant of that map'),
(6930137,254371,109,0,0,1,1,-496.64,96.66,-148.74,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Defiled Necklace | AtlasLoot The Temple of Atal''hakkar | Z from the realm''s occupants there'),
(6930138,254372,109,0,0,1,1,-496.64,96.66,-148.74,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Sunken Axe | AtlasLoot The Temple of Atal''hakkar | Z from the realm''s occupants there'),
(6930139,90598,349,0,0,1,1,375.02,-503.8,-64.308,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Broken Crate | AtlasLoot Maraudon | Z from the nearest occupant of that map'),
(6930140,96125,349,0,0,1,1,716.3,-127.06,-56.28,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Busted Buckler | AtlasLoot Maraudon | Z from the realm''s occupants there'),
(6930141,96142,349,0,0,1,1,303.92,-733.12,-124.867,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Tattered Fur Remains | AtlasLoot Maraudon | Z from the nearest occupant of that map'),
(6930142,96143,349,0,0,1,1,332.36,-733.12,-124.784,0,0,0,0,1,0,0,0,NULL,'AscensionWorldforged Half-Eaten Gnoll | AtlasLoot Maraudon | Z from the nearest occupant of that map');

-- c: a recorded loot position the restoration never rebuilt
DELETE FROM `gameobject` WHERE `guid` BETWEEN 6931001 AND 6931198;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
  `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`,
  `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(6931005,95509,0,0,0,1,1,-1361.4000,35.6000,-7.1840,0,0,0,0,1,0,0,0,'AscensionWorldforged Miner''s Pickaxe | | AtlasLoot Hillsbrad Foothills | Z from the floor its occupants share (within 200 yd)'),
(6931007,95694,0,0,0,1,1,-2044.6000,-4087.6000,2.1670,0,0,0,0,1,0,0,0,'AscensionWorldforged Jack''s Toothpicker | | AtlasLoot Arathi Highlands | Z from the floor its occupants share (within 200 yd)'),
(6931008,95736,0,0,0,1,1,-2370.9000,-1360.5000,-51.4420,0,0,0,0,1,0,0,0,'AscensionWorldforged Zul''Kunda Blood Ring | | AtlasLoot Wetlands | Z from the terrain the worldserver reads, where its neighbours agree'),
(6931009,254026,0,0,0,1,1,-7099.2000,-3406.3000,243.1670,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Flower | | AtlasLoot Badlands | Z from the floor its occupants share (within 80 yd)'),
(6931010,254326,0,0,0,1,1,-2278.1000,-1607.2000,-47.0130,0,0,0,0,1,0,0,0,'AscensionWorldforged Ogre Toothpick | | AtlasLoot Arathi Highlands | Z from the floor its occupants share (within 80 yd)'),
(6931014,67262,1,0,0,1,1,-7866.3000,-1363.8000,-269.9050,0,0,0,0,1,0,0,0,'AscensionWorldforged Leatherworking Book | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931015,90236,1,0,0,1,1,-6945.6000,-414.7000,-265.8200,0,0,0,0,1,0,0,0,'AscensionWorldforged Thunder Falls Enchanted Branches | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931016,90283,1,0,0,1,1,-7210.8000,-2296.7000,-267.6930,0,0,0,0,1,0,0,0,'AscensionWorldforged Alchemy Visceral Juice | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931017,90336,1,0,0,1,1,-7005.7000,-297.7000,-219.9320,0,0,0,0,1,0,0,0,'AscensionWorldforged Brambleblade Blade | | AtlasLoot Silithus | Z from the floor its occupants share (within 80 yd)'),
(6931021,90532,1,0,0,1,1,-6945.6000,-414.7000,-265.8200,0,0,0,0,1,0,0,0,'AscensionWorldforged Encrusted Spear | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931028,95637,1,0,0,1,1,1730.2000,-5800.9000,-90.3820,0,0,0,0,1,0,0,0,'AscensionWorldforged Floating Cargo | | AtlasLoot  | Z from the floor its occupants share (within 80 yd)'),
(6931029,95749,1,0,0,1,1,-5665.4000,-3667.4000,-58.6640,0,0,0,0,1,0,0,0,'AscensionWorldforged Splinter Guard | | AtlasLoot Thousand Needles | Z from the floor its occupants share (within 80 yd)'),
(6931030,95915,1,0,0,1,1,-7743.7000,-1030.6000,-269.5440,0,0,0,0,1,0,0,0,'AscensionWorldforged Strongly Scented Bottle | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931031,95916,1,0,0,1,1,-7041.9000,-1907.6000,-276.3590,0,0,0,0,1,0,0,0,'AscensionWorldforged Bone Scraper | | AtlasLoot Un''Goro Crater | Z from the terrain the worldserver reads, where its neighbours agree'),
(6931032,95917,1,0,0,1,1,-6795.7000,-1488.5000,-270.7410,0,0,0,0,1,0,0,0,'AscensionWorldforged Crystal Encased Staff | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931033,95919,1,0,0,1,1,-7046.3000,-1898.4000,-272.9250,0,0,0,0,1,0,0,0,'AscensionWorldforged Campsite Shrapnel | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931034,95920,1,0,0,1,1,-8145.9000,-1172.3000,-268.9120,0,0,0,0,1,0,0,0,'AscensionWorldforged Crystal Resonator Coffer | | AtlasLoot The Slithering Scar | Z from the floor its occupants share (within 80 yd)'),
(6931036,95922,1,0,0,1,1,-7950.9000,-1450.8000,-271.0530,0,0,0,0,1,0,0,0,'AscensionWorldforged Failed Delivery | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931037,95927,1,0,0,1,1,-6920.2000,-2378.1000,-204.3030,0,0,0,0,1,0,0,0,'AscensionWorldforged Fallen Axe | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931038,95927,1,0,0,1,1,-6910.6000,-2303.8000,-267.5420,0,0,0,0,1,0,0,0,'AscensionWorldforged Fallen Axe | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931039,95928,1,0,0,1,1,-7475.8000,-800.5000,-267.6930,0,0,0,0,1,0,0,0,'AscensionWorldforged Ballast Laden Pauldrons | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931040,95934,1,0,0,1,1,-7316.4000,-1278.8000,-246.8470,0,0,0,0,1,0,0,0,'AscensionWorldforged Precious Ring | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931041,95935,1,0,0,1,1,-7371.0000,-1379.4000,-270.2880,0,0,0,0,1,0,0,0,'AscensionWorldforged Ringo''s Throwing Star | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931042,96118,1,0,0,1,1,-7129.7000,-1359.4000,-184.3880,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Light of Elune | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931043,96118,1,0,0,1,1,-7118.3000,-1298.7000,-186.0750,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Light of Elune | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931044,96157,1,0,0,1,1,-6618.0000,-1076.4000,-271.2660,0,0,0,0,1,0,0,0,'AscensionWorldforged Freshly Brewed Potion | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931045,96157,1,0,0,1,1,-5159.3000,-2439.8000,-50.7360,0,0,0,0,1,0,0,0,'AscensionWorldforged Freshly Brewed Potion | | AtlasLoot Thousand Needles | Z from the floor its occupants share (within 80 yd)'),
(6931046,96169,1,0,0,1,1,-6741.1000,-810.1000,-271.5480,0,0,0,0,1,0,0,0,'AscensionWorldforged Dreamcatcher | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931047,96170,1,0,0,1,1,-6575.8000,-1845.1000,-273.5370,0,0,0,0,1,0,0,0,'AscensionWorldforged Silverback Cape | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931048,96173,1,0,0,1,1,-6684.9000,-1858.4000,-271.7740,0,0,0,0,1,0,0,0,'AscensionWorldforged Jane''s Hat | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931049,96175,1,0,0,1,1,-7871.0000,-1908.7000,-270.0410,0,0,0,0,1,0,0,0,'AscensionWorldforged Well Loved Bow | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931050,96179,1,0,0,1,1,-6813.2000,-1205.9000,-270.8240,0,0,0,0,1,0,0,0,'AscensionWorldforged Abandoned Crate | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931051,96180,1,0,0,1,1,-7262.9000,-472.8000,-272.1310,0,0,0,0,1,0,0,0,'AscensionWorldforged Spear of a Slain Hunter | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931052,96185,1,0,0,1,1,-7305.1000,-2285.6000,-267.2210,0,0,0,0,1,0,0,0,'AscensionWorldforged Shallow Grave | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931053,96188,1,0,0,1,1,-7378.9000,-2116.2000,-272.1340,0,0,0,0,1,0,0,0,'AscensionWorldforged Charging Box | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931054,96212,1,0,0,1,1,-7109.7000,-951.8000,-271.0460,0,0,0,0,1,0,0,0,'AscensionWorldforged Wooden Chest | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931055,96213,1,0,0,1,1,-7367.7000,-582.6000,-271.9560,0,0,0,0,1,0,0,0,'AscensionWorldforged Beach Bag | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931056,96215,1,0,0,1,1,-7721.0000,-1813.3000,-272.1230,0,0,0,0,1,0,0,0,'AscensionWorldforged Ravasaur Claw | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931057,96219,1,0,0,1,1,-7278.7000,-833.0000,-270.5950,0,0,0,0,1,0,0,0,'AscensionWorldforged Bert''s Box of Success | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931058,97135,1,0,0,1,1,-6130.4000,-4088.1000,-58.6250,0,0,0,0,1,0,0,0,'AscensionWorldforged Useless Racing Parts | | AtlasLoot Thousand Needles | Z from the floor its occupants share (within 80 yd)'),
(6931059,254381,1,0,0,1,1,-7620.1000,-1402.7000,-269.1960,0,0,0,0,1,0,0,0,'AscensionWorldforged Atal''ai Fisher''s Boots | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931060,254448,1,0,0,1,1,-7372.7000,-2001.9000,-271.1200,0,0,0,0,1,0,0,0,'AscensionWorldforged Giant''s Storm Dagger | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931061,254484,1,0,0,1,1,-8043.0000,-1331.7000,-273.9690,0,0,0,0,1,0,0,0,'AscensionWorldforged Hexed Staff | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931062,254504,1,0,0,1,1,-6578.8000,-745.4000,-270.0730,0,0,0,0,1,0,0,0,'AscensionWorldforged Plundered Shipment | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931063,254669,1,0,0,1,1,-7066.3000,-1219.2000,-242.3260,0,0,0,0,1,0,0,0,'AscensionWorldforged Old Ogre Relic | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931064,515525,1,0,0,1,1,-6910.6000,-2303.8000,-267.5420,0,0,0,0,1,0,0,0,'AscensionWorldforged Drowned Diver''s Helmet | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931065,515535,1,0,0,1,1,-6335.5000,-3747.1000,-58.7500,0,0,0,0,1,0,0,0,'AscensionWorldforged Rickety Invention | | AtlasLoot Thousand Needles | Z from the terrain the worldserver reads, where its neighbours agree'),
(6931066,515539,1,0,0,1,1,-6407.1000,-3378.8000,-57.6740,0,0,0,0,1,0,0,0,'AscensionWorldforged Rustmaul Artifact | | AtlasLoot Thousand Needles | Z from the floor its occupants share (within 80 yd)'),
(6931067,515540,1,0,0,1,1,-6345.2000,-3855.8000,-58.7500,0,0,0,0,1,0,0,0,'AscensionWorldforged Racing Boots | | AtlasLoot Thousand Needles | Z from the terrain the worldserver reads, where its neighbours agree'),
(6931068,515571,1,0,0,1,1,-8046.7000,-1346.8000,-271.4860,0,0,0,0,1,0,0,0,'AscensionWorldforged Harpy Feather | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931069,515791,1,0,0,1,1,-7422.8000,-1844.0000,-272.0970,0,0,0,0,1,0,0,0,'AscensionWorldforged Ancient Wagon Wheel | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931070,515800,1,0,0,1,1,-6920.2000,-2378.1000,-204.3030,0,0,0,0,1,0,0,0,'AscensionWorldforged Ancient Elven Chest | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931071,515918,1,0,0,1,1,-6452.0000,-1035.4000,-272.4030,0,0,0,0,1,0,0,0,'AscensionWorldforged Tiki Shield | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931072,515918,1,0,0,1,1,-6398.7000,-1764.1000,-267.5090,0,0,0,0,1,0,0,0,'AscensionWorldforged Tiki Shield | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931073,517272,1,0,0,1,1,-6830.7000,-1519.9000,-271.5030,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931074,517272,1,0,0,1,1,-6650.3000,-1435.6000,-271.9290,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931075,517272,1,0,0,1,1,-5159.3000,-2439.8000,-50.7360,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Thousand Needles | Z from the floor its occupants share (within 80 yd)'),
(6931076,686885,1,0,0,1,1,-6578.8000,-745.4000,-270.0730,0,0,0,0,1,0,0,0,'AscensionWorldforged Hardened Scarab Gauntlets | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931077,735902,1,0,0,1,1,-7593.7000,-887.0000,-267.3220,0,0,0,0,1,0,0,0,'AscensionWorldforged Primitive Offering Box | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931078,735924,1,0,0,1,1,-8006.9000,-1364.2000,-273.1700,0,0,0,0,1,0,0,0,'AscensionWorldforged Prancefin | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931079,1345000,1,0,0,1,1,-1861.4000,-4043.5000,-5.9430,0,0,0,0,1,0,0,0,'AscensionWorldforged Affray Cuirras | | AtlasLoot The Barrens | Z from the floor its occupants share (within 200 yd)'),
(6931080,1345079,1,0,0,1,1,-7994.9000,-1710.1000,-269.7080,0,0,0,0,1,0,0,0,'AscensionWorldforged Jungle String Bow | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931081,1345079,1,0,0,1,1,-7978.0000,-1807.3000,-267.2070,0,0,0,0,1,0,0,0,'AscensionWorldforged Jungle String Bow | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931082,1345080,1,0,0,1,1,-6871.1000,-1738.2000,-270.0540,0,0,0,0,1,0,0,0,'AscensionWorldforged Junglewood Recurve | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931083,1345121,1,0,0,1,1,-6412.0000,-1684.2000,-273.0730,0,0,0,0,1,0,0,0,'AscensionWorldforged Scholar''s Ring of Enlightenment | | AtlasLoot Un''Goro Crater | Z from the floor its occupants share (within 80 yd)'),
(6931084,1345132,1,0,0,1,1,-5954.7000,-4014.6000,-58.6250,0,0,0,0,1,0,0,0,'AscensionWorldforged Sizzling Potion | | AtlasLoot Thousand Needles | Z from the floor its occupants share (within 80 yd)'),
(6931085,1345132,1,0,0,1,1,-5887.2000,-4295.2000,-58.7500,0,0,0,0,1,0,0,0,'AscensionWorldforged Sizzling Potion | | AtlasLoot Thousand Needles | Z from the floor its occupants share (within 80 yd)'),
(6931086,1345152,1,0,0,1,1,-997.4000,-581.8000,-56.7850,0,0,0,0,1,0,0,0,'AscensionWorldforged Thunderwalk Breastplate | | AtlasLoot Mulgore | Z from the floor its occupants share (within 80 yd)'),
(6931087,1345159,1,0,0,1,1,-8071.4000,-1275.0000,-321.2790,0,0,0,0,1,0,0,0,'AscensionWorldforged Verdant Ember Loop | | AtlasLoot The Slithering Scar | Z from the floor its occupants share (within 80 yd)'),
(6931089,90323,43,0,0,1,1,-8.0000,258.9000,-88.8560,0,0,0,0,1,0,0,0,'AscensionWorldforged Sack of Pine Seeds | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931091,90373,43,0,0,1,1,-271.2000,-8.0000,-99.0120,0,0,0,0,1,0,0,0,'AscensionWorldforged Elven Militia Crown | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931092,95629,43,0,0,1,1,2.1000,-206.3000,-75.5470,0,0,0,0,1,0,0,0,'AscensionWorldforged Scalper''s Sack | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931093,95668,43,0,0,1,1,27.9000,530.6000,-59.7200,0,0,0,0,1,0,0,0,'AscensionWorldforged Spare Boots | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931094,95862,43,0,0,1,1,55.2000,206.7000,-88.0940,0,0,0,0,1,0,0,0,'AscensionWorldforged Hidden Stash | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931095,95874,43,0,0,1,1,-271.2000,-8.0000,-99.0120,0,0,0,0,1,0,0,0,'AscensionWorldforged Climbing Boots | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931096,517353,43,0,0,1,1,-107.9000,210.6000,-92.8440,0,0,0,0,1,0,0,0,'AscensionWorldforged Rusty Shotgun | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931097,517367,43,0,0,1,1,-107.9000,210.6000,-92.8440,0,0,0,0,1,0,0,0,'AscensionWorldforged Offering For the Dead | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931098,1345048,43,0,0,1,1,-19.0000,-211.5000,-74.8970,0,0,0,0,1,0,0,0,'AscensionWorldforged Empty Satchel | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931099,1345121,43,0,0,1,1,-151.2000,418.8000,-72.6630,0,0,0,0,1,0,0,0,'AscensionWorldforged Scholar''s Ring of Enlightenment | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931100,1345126,43,0,0,1,1,-284.3000,-310.1000,-64.5170,0,0,0,0,1,0,0,0,'AscensionWorldforged Shockzip''s Saw Blade | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931101,1345146,43,0,0,1,1,-339.6000,24.6000,-100.8320,0,0,0,0,1,0,0,0,'AscensionWorldforged Supply Runner''s Pants | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931102,1345171,43,0,0,1,1,-30.1000,-104.4000,-69.3710,0,0,0,0,1,0,0,0,'AscensionWorldforged Worldforged Scroll: Faerie Blink | | AtlasLoot Wailing Caverns | Z from the floor its occupants share (within 80 yd)'),
(6931103,90345,48,0,0,1,1,-598.7000,86.1000,-54.9610,0,0,0,0,1,0,0,0,'AscensionWorldforged Venture Co. Ring | | AtlasLoot Blackfathom Deeps | Z from the floor its occupants share (within 80 yd)'),
(6931104,340047,48,0,0,1,1,-453.0000,306.7000,-68.0790,0,0,0,0,1,0,0,0,'AscensionWorldforged Garmet Supplies | | AtlasLoot Blackfathom Deeps | Z from the floor its occupants share (within 80 yd)'),
(6931105,1345037,48,0,0,1,1,-437.6000,144.5000,-70.5800,0,0,0,0,1,0,0,0,'AscensionWorldforged Defias Turncoat''s Jerkin | | AtlasLoot Blackfathom Deeps | Z from the floor its occupants share (within 80 yd)'),
(6931106,1345048,48,0,0,1,1,-335.4000,-76.2000,-70.5850,0,0,0,0,1,0,0,0,'AscensionWorldforged Empty Satchel | | AtlasLoot Blackfathom Deeps | Z from the floor its occupants share (within 80 yd)'),
(6931107,90252,90,0,0,1,1,-870.5000,87.0000,-264.6480,0,0,0,0,1,0,0,0,'AscensionWorldforged Defias Mage Stash | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931108,90323,90,0,0,1,1,-589.6000,514.9000,-272.9780,0,0,0,0,1,0,0,0,'AscensionWorldforged Sack of Pine Seeds | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931109,95854,90,0,0,1,1,-613.3000,223.2000,-171.6660,0,0,0,0,1,0,0,0,'AscensionWorldforged Heat Tempered Sword | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931110,95862,90,0,0,1,1,-733.6000,345.2000,-272.5960,0,0,0,0,1,0,0,0,'AscensionWorldforged Hidden Stash | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931111,95862,90,0,0,1,1,-606.9000,737.0000,-326.9780,0,0,0,0,1,0,0,0,'AscensionWorldforged Hidden Stash | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931112,96157,90,0,0,1,1,-602.9000,452.3000,-230.6020,0,0,0,0,1,0,0,0,'AscensionWorldforged Freshly Brewed Potion | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931113,515525,90,0,0,1,1,-768.9000,508.7000,-294.6990,0,0,0,0,1,0,0,0,'AscensionWorldforged Drowned Diver''s Helmet | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931114,515525,90,0,0,1,1,-721.7000,456.7000,-272.9810,0,0,0,0,1,0,0,0,'AscensionWorldforged Drowned Diver''s Helmet | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931116,517272,90,0,0,1,1,-504.1000,251.5000,-207.8230,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931117,517272,90,0,0,1,1,-444.2000,355.3000,-230.5180,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 200 yd)'),
(6931118,517272,90,0,0,1,1,-381.4000,448.9000,-230.6010,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931119,1345089,90,0,0,1,1,-877.6000,426.0000,-312.2810,0,0,0,0,1,0,0,0,'AscensionWorldforged Melika''s Ring | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931120,1345089,90,0,0,1,1,-612.4000,22.2000,-195.4920,0,0,0,0,1,0,0,0,'AscensionWorldforged Melika''s Ring | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931121,1345121,90,0,0,1,1,-886.1000,413.8000,-272.5960,0,0,0,0,1,0,0,0,'AscensionWorldforged Scholar''s Ring of Enlightenment | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931122,1345126,90,0,0,1,1,-762.3000,501.4000,-295.5190,0,0,0,0,1,0,0,0,'AscensionWorldforged Shockzip''s Saw Blade | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931123,1345146,90,0,0,1,1,-510.6000,14.6000,-179.7340,0,0,0,0,1,0,0,0,'AscensionWorldforged Supply Runner''s Pants | | AtlasLoot Gnomeregan | Z from the floor its occupants share (within 80 yd)'),
(6931124,90323,109,0,0,1,1,-440.7000,9.3000,-91.0220,0,0,0,0,1,0,0,0,'AscensionWorldforged Sack of Pine Seeds | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931125,95515,109,0,0,1,1,-456.2000,111.3000,-148.7400,0,0,0,0,1,0,0,0,'AscensionWorldforged Ice Beard''s Furled Finger | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931126,95638,109,0,0,1,1,-456.2000,111.3000,-148.7400,0,0,0,0,1,0,0,0,'AscensionWorldforged Farmer''s Old Gear | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931127,96118,109,0,0,1,1,-393.7000,225.7000,-90.8300,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Light of Elune | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931128,254165,109,0,0,1,1,-435.8000,5.1000,-90.9850,0,0,0,0,1,0,0,0,'AscensionWorldforged Abandoned Bag | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931129,254374,109,0,0,1,1,-497.5000,96.4000,-148.7400,0,0,0,0,1,0,0,0,'AscensionWorldforged Shoulderguards of the Ancient Prophet | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931130,254375,109,0,0,1,1,-496.6000,96.7000,-148.7400,0,0,0,0,1,0,0,0,'AscensionWorldforged Kazkaz''s Ceremonial Mask | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931131,254376,109,0,0,1,1,-496.6000,96.7000,-148.7400,0,0,0,0,1,0,0,0,'AscensionWorldforged Atal''ai Alchemy Supplies | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931132,515525,109,0,0,1,1,-381.5000,220.6000,-90.8300,0,0,0,0,1,0,0,0,'AscensionWorldforged Drowned Diver''s Helmet | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931133,1345091,109,0,0,1,1,-451.1000,197.9000,-91.2340,0,0,0,0,1,0,0,0,'AscensionWorldforged Minervia''s Pendant of Atonement | | AtlasLoot The Temple of Atal''Hakkar | Z from the floor its occupants share (within 80 yd)'),
(6931134,254026,209,0,0,1,1,1877.5000,1042.8000,9.0140,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Flower | | AtlasLoot Zul''Farrak | Z from the floor its occupants share (within 80 yd)'),
(6931135,90260,230,0,0,1,1,1037.2000,-441.3000,-60.9190,0,0,0,0,1,0,0,0,'AscensionWorldforged Shadowhide Treasure | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931136,90323,230,0,0,1,1,583.3000,17.9000,-73.2430,0,0,0,0,1,0,0,0,'AscensionWorldforged Sack of Pine Seeds | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931137,90552,230,0,0,1,1,1146.3000,-304.3000,-105.1120,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Cane | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931138,95715,230,0,0,1,1,1135.1000,-349.5000,-104.3300,0,0,0,0,1,0,0,0,'AscensionWorldforged Baby Gorilla Bait | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931140,96215,230,0,0,1,1,909.0000,-315.0000,-50.1140,0,0,0,0,1,0,0,0,'AscensionWorldforged Ravasaur Claw | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931141,517272,230,0,0,1,1,1352.7000,-820.8000,-85.1650,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931142,518007,230,0,0,1,1,342.9000,-144.1000,-65.5320,0,0,0,0,1,0,0,0,'AscensionWorldforged Spark of Infernus | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931143,1345121,230,0,0,1,1,1380.1000,-797.6000,-85.1650,0,0,0,0,1,0,0,0,'AscensionWorldforged Scholar''s Ring of Enlightenment | | AtlasLoot Blackrock Depths | Z from the floor its occupants share (within 80 yd)'),
(6931144,95715,249,0,0,1,1,-297.5000,-208.7000,-93.6300,0,0,0,0,1,0,0,0,'AscensionWorldforged Baby Gorilla Bait | | AtlasLoot Onyxia''s Lair | Z from the floor its occupants share (within 200 yd)'),
(6931145,95872,249,0,0,1,1,-231.7000,-35.7000,-92.9140,0,0,0,0,1,0,0,0,'AscensionWorldforged Abandoned Supplies | | AtlasLoot Onyxia''s Lair | Z from the floor its occupants share (within 200 yd)'),
(6931146,96180,249,0,0,1,1,8.6000,-217.2000,-86.5700,0,0,0,0,1,0,0,0,'AscensionWorldforged Spear of a Slain Hunter | | AtlasLoot Onyxia''s Lair | Z from the floor its occupants share (within 80 yd)'),
(6931147,254381,249,0,0,1,1,-231.7000,-35.7000,-92.9140,0,0,0,0,1,0,0,0,'AscensionWorldforged Atal''ai Fisher''s Boots | | AtlasLoot Onyxia''s Lair | Z from the floor its occupants share (within 200 yd)'),
(6931148,90293,349,0,0,1,1,125.3000,-100.9000,-204.7840,0,0,0,0,1,0,0,0,'AscensionWorldforged Abandoned Peon''s Sack | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931149,90323,349,0,0,1,1,96.9000,-61.2000,-199.5540,0,0,0,0,1,0,0,0,'AscensionWorldforged Sack of Pine Seeds | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931150,90636,349,0,0,1,1,125.3000,-100.9000,-204.7840,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Sack | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931151,95830,349,0,0,1,1,353.7000,-171.0000,-59.8160,0,0,0,0,1,0,0,0,'AscensionWorldforged Drudger Smash | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931152,96115,349,0,0,1,1,248.5000,-479.9000,-140.0790,0,0,0,0,1,0,0,0,'AscensionWorldforged Bulging Sack | | AtlasLoot Maraudon | Z from the floor its occupants share (within 200 yd)'),
(6931153,96118,349,0,0,1,1,436.5000,-403.2000,-118.0520,0,0,0,0,1,0,0,0,'AscensionWorldforged Forgotten Light of Elune | | AtlasLoot Maraudon | Z from the floor its occupants share (within 200 yd)'),
(6931154,96120,349,0,0,1,1,554.2000,-506.9000,-51.9360,0,0,0,0,1,0,0,0,'AscensionWorldforged Ogre Laundry Pouch | | AtlasLoot Maraudon | Z from the floor its occupants share (within 200 yd)'),
(6931155,96122,349,0,0,1,1,480.0000,47.9000,-96.2300,0,0,0,0,1,0,0,0,'AscensionWorldforged Glint of Metal | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931156,96124,349,0,0,1,1,207.1000,10.7000,-131.0100,0,0,0,0,1,0,0,0,'AscensionWorldforged Hatestrike | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931157,96126,349,0,0,1,1,120.3000,-150.0000,-169.8670,0,0,0,0,1,0,0,0,'AscensionWorldforged Tanner''s Chest | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931158,96127,349,0,0,1,1,1069.0000,-249.9000,-72.6460,0,0,0,0,1,0,0,0,'AscensionWorldforged Pruning Knife | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931159,96128,349,0,0,1,1,1171.3000,-274.8000,-75.9700,0,0,0,0,1,0,0,0,'AscensionWorldforged Slightly Scorched Supplies | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931160,254307,349,0,0,1,1,574.1000,200.5000,-93.9660,0,0,0,0,1,0,0,0,'AscensionWorldforged Icon of Khan Maraudos | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931161,254309,349,0,0,1,1,392.9000,-151.1000,-118.0750,0,0,0,0,1,0,0,0,'AscensionWorldforged Greataxe of Kolk | | AtlasLoot Maraudon | Z from the floor its occupants share (within 200 yd)'),
(6931162,254335,349,0,0,1,1,484.9000,11.4000,-96.3130,0,0,0,0,1,0,0,0,'AscensionWorldforged Syndicate Slicer | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931163,340053,349,0,0,1,1,120.3000,-150.0000,-169.8670,0,0,0,0,1,0,0,0,'AscensionWorldforged Northridge Hatchet | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931164,515864,349,0,0,1,1,448.4000,-327.1000,-116.5910,0,0,0,0,1,0,0,0,'AscensionWorldforged Old Ship Wheel | | AtlasLoot Maraudon | Z from the floor its occupants share (within 200 yd)'),
(6931165,515866,349,0,0,1,1,850.8000,-261.2000,-54.1820,0,0,0,0,1,0,0,0,'AscensionWorldforged Gregan Tanning Rack | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931166,515877,349,0,0,1,1,726.4000,-181.6000,-56.3230,0,0,0,0,1,0,0,0,'AscensionWorldforged Giant Stalker Rifle | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931167,517272,349,0,0,1,1,100.1000,35.3000,-131.0730,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931168,517272,349,0,0,1,1,147.1000,-63.8000,-131.0730,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Maraudon | Z from the floor its occupants share (within 200 yd)'),
(6931169,517272,349,0,0,1,1,298.8000,-384.4000,-139.4720,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931170,517272,349,0,0,1,1,334.6000,-459.9000,-124.8670,0,0,0,0,1,0,0,0,'AscensionWorldforged Bubbling Cauldron | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931171,517276,349,0,0,1,1,819.8000,-193.9000,-60.7710,0,0,0,0,1,0,0,0,'AscensionWorldforged Embedded Claymore | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931172,518578,349,0,0,1,1,120.3000,-150.0000,-169.8670,0,0,0,0,1,0,0,0,'AscensionWorldforged Scalebane Corpse | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931173,1345045,349,0,0,1,1,588.3000,135.0000,-96.3130,0,0,0,0,1,0,0,0,'AscensionWorldforged Dwarven Crossbow | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931174,1345077,349,0,0,1,1,626.3000,-197.8000,-55.1060,0,0,0,0,1,0,0,0,'AscensionWorldforged Infernal Tender | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931175,1345124,349,0,0,1,1,280.5000,-270.2000,-131.0290,0,0,0,0,1,0,0,0,'AscensionWorldforged Sentinel Wrap | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931176,1345168,349,0,0,1,1,178.5000,-138.2000,-167.3360,0,0,0,0,1,0,0,0,'AscensionWorldforged Worldforged Scroll: Corrupted Shiv | | AtlasLoot Maraudon | Z from the floor its occupants share (within 80 yd)'),
(6931177,1345177,349,0,0,1,1,1031.3000,76.5000,-62.0540,0,0,0,0,1,0,0,0,'AscensionWorldforged Worldforged Scroll: Screams of the Past | | AtlasLoot Maraudon | Z from the floor its occupants share (within 200 yd)'),
(6931178,68428,409,0,0,1,1,1162.6000,-583.0000,-112.8020,0,0,0,0,1,0,0,0,'AscensionWorldforged Pile of Bones | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931179,90283,409,0,0,1,1,712.1000,-564.4000,-213.9440,0,0,0,0,1,0,0,0,'AscensionWorldforged Alchemy Visceral Juice | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931180,95715,409,0,0,1,1,1082.0000,-960.5000,-161.8350,0,0,0,0,1,0,0,0,'AscensionWorldforged Baby Gorilla Bait | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931181,95872,409,0,0,1,1,696.0000,-658.9000,-209.8230,0,0,0,0,1,0,0,0,'AscensionWorldforged Abandoned Supplies | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931182,96180,409,0,0,1,1,1162.6000,-583.0000,-112.8020,0,0,0,0,1,0,0,0,'AscensionWorldforged Spear of a Slain Hunter | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931183,515373,409,0,0,1,1,668.8000,-760.2000,-208.7230,0,0,0,0,1,0,0,0,'AscensionWorldforged Cracked Stone Golemn | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931184,520699,409,0,0,1,1,668.8000,-760.2000,-208.7230,0,0,0,0,1,0,0,0,'AscensionWorldforged Grimtotem Bow | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931185,1345147,409,0,0,1,1,1165.2000,-570.5000,-112.5520,0,0,0,0,1,0,0,0,'AscensionWorldforged Terrible Defias Mixture | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931186,1345148,409,0,0,1,1,979.3000,-891.8000,-159.8730,0,0,0,0,1,0,0,0,'AscensionWorldforged Terrible Defias Mixture | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931187,1345148,409,0,0,1,1,993.9000,-664.5000,-195.6950,0,0,0,0,1,0,0,0,'AscensionWorldforged Terrible Defias Mixture | | AtlasLoot Molten Core | Z from the floor its occupants share (within 80 yd)'),
(6931188,1345172,409,0,0,1,1,800.4000,-846.0000,-203.7500,0,0,0,0,1,0,0,0,'AscensionWorldforged Worldforged Scroll: Firefall | | AtlasLoot Molten Core | Z from the floor its occupants share (within 200 yd)'),
(6931189,95539,585,0,0,1,1,243.4000,82.3000,-2.9560,0,0,0,0,1,0,0,0,'AscensionWorldforged Bound Remains | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931190,95947,585,0,0,1,1,82.4000,33.1000,-19.9220,0,0,0,0,1,0,0,0,'AscensionWorldforged A "Fishy" Staff | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931191,254328,585,0,0,1,1,322.2000,-6.6000,-2.7370,0,0,0,0,1,0,0,0,'AscensionWorldforged Frostwatch Defender | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 200 yd)'),
(6931192,515039,585,0,0,1,1,92.8000,58.4000,-19.9220,0,0,0,0,1,0,0,0,'AscensionWorldforged Hunter''s Rifle | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931193,515367,585,0,0,1,1,154.4000,114.9000,-14.2980,0,0,0,0,1,0,0,0,'AscensionWorldforged Deathstalker Cape | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931194,515376,585,0,0,1,1,123.3000,75.4000,-19.9220,0,0,0,0,1,0,0,0,'AscensionWorldforged Dusty Trousers | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931195,515385,585,0,0,1,1,157.7000,-126.8000,-2.7770,0,0,0,0,1,0,0,0,'AscensionWorldforged Deadman''s Dagger | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931196,515403,585,0,0,1,1,128.5000,60.7000,-19.9220,0,0,0,0,1,0,0,0,'AscensionWorldforged Foreman''s Lightcap | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931197,517323,585,0,0,1,1,89.1000,-76.4000,-20.4940,0,0,0,0,1,0,0,0,'AscensionWorldforged Siren''s Wand | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)'),
(6931198,1345177,585,0,0,1,1,210.0000,0.9000,-2.9760,0,0,0,0,1,0,0,0,'AscensionWorldforged Worldforged Scroll: Screams of the Past | | AtlasLoot Magisters'' Terrace | Z from the floor its occupants share (within 80 yd)');

-- e: the facing another placement of the same object carries
UPDATE `gameobject` SET `orientation` = CASE `guid`
  WHEN 6901511 THEN 3.48194
  WHEN 6901513 THEN 3.14159
  WHEN 6901514 THEN 3.58666
  WHEN 6901515 THEN 3.58666
  WHEN 6901516 THEN 3.58666
  WHEN 6901517 THEN 3.58666
  WHEN 6901518 THEN 2.75761
  WHEN 6903001 THEN 0.72984
  WHEN 6910001 THEN 0.618034
  WHEN 6920004 THEN 0.724725
  WHEN 6920005 THEN 5.04808
  WHEN 6920007 THEN 4.32816
  WHEN 6920008 THEN 4.7405
  WHEN 6920009 THEN 2.47791
  WHEN 6920010 THEN 4.75247
  WHEN 6920012 THEN 5.02175
  WHEN 6920013 THEN 0.618034
  WHEN 6920018 THEN 5.15284
  WHEN 6920019 THEN 0.79259
  WHEN 6920020 THEN 0.69381
  WHEN 6920021 THEN 1.71758
  WHEN 6920022 THEN 0.98837
  WHEN 6920023 THEN 3.4613
  WHEN 6920024 THEN 6.25003
  WHEN 6920025 THEN 3.08028
  WHEN 6920026 THEN 1.10797
  WHEN 6920029 THEN 4.26801
  WHEN 6920030 THEN 0.20053
  WHEN 6920031 THEN 2.70501
  WHEN 6920032 THEN 3.74171
  WHEN 6920033 THEN 3.72952
  WHEN 6920034 THEN 1.94859
  WHEN 6920035 THEN 2.29905
  WHEN 6920036 THEN 4.47331
  WHEN 6920037 THEN 3.85914
  WHEN 6920038 THEN 3.02342
  WHEN 6920039 THEN 0.60418
  WHEN 6920040 THEN 4.88724
  WHEN 6920041 THEN 2.09653
  WHEN 6920042 THEN 2.91212
  WHEN 6920043 THEN 3.3535
  WHEN 6920044 THEN 1.09854
  WHEN 6920045 THEN 2.6139
  WHEN 6920046 THEN 2.9178
  WHEN 6920047 THEN 0.71766
  WHEN 6920048 THEN 5.17587
  WHEN 6920049 THEN 2.95216
  WHEN 6920050 THEN 4.46104
  WHEN 6920051 THEN 3.83438
  WHEN 6920052 THEN 4.53026
  WHEN 6920053 THEN 0.57894
  WHEN 6920054 THEN 3.75945
  WHEN 6920055 THEN 2.20014
  WHEN 6920056 THEN 4.01063
  WHEN 6920057 THEN 0.931378
  WHEN 6920058 THEN 1.27456
  WHEN 6920059 THEN 5.61838
  WHEN 6920060 THEN 6.19349
  WHEN 6920063 THEN 3.73795
  WHEN 6920064 THEN 1.74212
  WHEN 6920065 THEN 0.59162
  WHEN 6920066 THEN 6.16027
  WHEN 6920067 THEN 1.81143
  WHEN 6920068 THEN 1.66922
  WHEN 6920069 THEN 2.55751
  WHEN 6920070 THEN 0.4593
  WHEN 6920072 THEN 1.15279
  WHEN 6920073 THEN 1.32351
  WHEN 6920074 THEN 2.06665
  WHEN 6920076 THEN 0.35632
  WHEN 6930001 THEN 5.7039
  WHEN 6930002 THEN 5.40288
  WHEN 6930003 THEN 4.53178
  WHEN 6930004 THEN 4.1604
  WHEN 6930005 THEN 5.43481
  WHEN 6930006 THEN 4.26801
  WHEN 6930007 THEN 1.92351
  WHEN 6930008 THEN 2.57857
  WHEN 6930009 THEN 4.49314
  WHEN 6930010 THEN 0.27753
  WHEN 6930011 THEN 3.53213
  WHEN 6930012 THEN 5.61814
  WHEN 6930013 THEN 4.44036
  WHEN 6930014 THEN 4.98423
  WHEN 6930015 THEN 2.5884
  WHEN 6930016 THEN 6.20463
  WHEN 6930017 THEN 4.3998
  WHEN 6930018 THEN 2.28552
  WHEN 6930019 THEN 2.97956
  WHEN 6930020 THEN 0.25528
  WHEN 6930021 THEN 2.03843
  WHEN 6930022 THEN 0.32108
  WHEN 6930023 THEN 3.83593
  WHEN 6930024 THEN 2.00222
  WHEN 6930025 THEN 2.0385
  WHEN 6930026 THEN 0.09776
  WHEN 6930027 THEN 1.54165
  WHEN 6930028 THEN 2.8602
  WHEN 6930029 THEN 6.05221
  WHEN 6930030 THEN 0.8981
  WHEN 6930031 THEN 4.45048
  WHEN 6930032 THEN 0.03048
  WHEN 6930033 THEN 5.39539
  WHEN 6930034 THEN 1.32299
  WHEN 6930035 THEN 3.93924
  WHEN 6930036 THEN 5.89837
  WHEN 6930037 THEN 3.89324
  WHEN 6930038 THEN 2.9444
  WHEN 6930039 THEN 0.74328
  WHEN 6930040 THEN 1.37629
  WHEN 6930041 THEN 5.5168
  WHEN 6930042 THEN 1.75176
  WHEN 6930043 THEN 5.85464
  WHEN 6930044 THEN 3.4554
  WHEN 6930045 THEN 3.71489
  WHEN 6930046 THEN 3.56063
  WHEN 6930047 THEN 6.12009
  WHEN 6930048 THEN 0.51375
  WHEN 6930049 THEN 0.42637
  WHEN 6930050 THEN 5.43577
  WHEN 6930051 THEN 4.1953
  WHEN 6930052 THEN 3.59175
  WHEN 6930053 THEN 4.09409
  WHEN 6930054 THEN 3.14054
  WHEN 6930055 THEN 4.95517
  WHEN 6930056 THEN 5.40556
  WHEN 6930057 THEN 3.69054
  WHEN 6930058 THEN 0.99652
  WHEN 6930059 THEN 4.24921
  WHEN 6930060 THEN 2.84897
  WHEN 6930061 THEN 5.5252
  WHEN 6930062 THEN 5.87469
  WHEN 6930063 THEN 0.209537
  WHEN 6930064 THEN 1.44561
  WHEN 6930065 THEN 0.515189
  WHEN 6930066 THEN 0.413305
  WHEN 6930067 THEN 2.16552
  WHEN 6930068 THEN 0.004807
  WHEN 6930069 THEN 3.81393
  WHEN 6930070 THEN 1.03326
  WHEN 6930071 THEN 1.78399
  WHEN 6930072 THEN 0.4254
  WHEN 6930073 THEN 3.8572
  WHEN 6930074 THEN 2.34266
  WHEN 6930075 THEN 0.88168
  WHEN 6930076 THEN 6.19349
  WHEN 6930077 THEN 0.90021
  WHEN 6930078 THEN 3.89846
  WHEN 6930079 THEN 3.49776
  WHEN 6930080 THEN 4.05589
  WHEN 6930081 THEN 0.07037
  WHEN 6930082 THEN 2.15198
  WHEN 6930083 THEN 2.39611
  WHEN 6930084 THEN 3.18828
  WHEN 6930085 THEN 5.99432
  WHEN 6930086 THEN 0.69847
  WHEN 6930087 THEN 1.03522
  WHEN 6930088 THEN 2.96755
  WHEN 6930089 THEN 1.63765
  WHEN 6930090 THEN 4.84991
  WHEN 6930091 THEN 0.20329
  WHEN 6930092 THEN 3.48515
  WHEN 6930093 THEN 1.66758
  WHEN 6930094 THEN 3.76957
  WHEN 6930095 THEN 1.96195
  WHEN 6930096 THEN 0.01116
  WHEN 6930097 THEN 1.57837
  WHEN 6930098 THEN 3.71274
  WHEN 6930099 THEN 1.82375
  WHEN 6930100 THEN 1.28016
  WHEN 6930101 THEN 3.07132
  WHEN 6930102 THEN 4.50932
  WHEN 6930103 THEN 1.45106
  WHEN 6930104 THEN 0.01764
  WHEN 6930105 THEN 5.65093
  WHEN 6930106 THEN 2.48656
  WHEN 6930107 THEN 5.38258
  WHEN 6930108 THEN 5.16145
  WHEN 6930109 THEN 0.73175
  WHEN 6930110 THEN 5.4085
  WHEN 6930111 THEN 3.58787
  WHEN 6930112 THEN 3.51305
  WHEN 6930113 THEN 4.00623
  WHEN 6930114 THEN 1.35445
  WHEN 6930115 THEN 1.22059
  WHEN 6930116 THEN 5.34887
  WHEN 6930117 THEN 2.5683
  WHEN 6930118 THEN 6.13261
  WHEN 6930119 THEN 5.28358
  WHEN 6930120 THEN 3.3535
  WHEN 6930121 THEN 2.12104
  WHEN 6930122 THEN 3.06058
  WHEN 6930123 THEN 2.158
  WHEN 6930124 THEN 3.30152
  WHEN 6930125 THEN 5.77184
  WHEN 6930126 THEN 4.6367
  WHEN 6930127 THEN 2.5769
  WHEN 6930128 THEN 1.44657
  WHEN 6930129 THEN 3.30067
  WHEN 6930130 THEN 2.99213
  WHEN 6930131 THEN 2.27125
  WHEN 6930132 THEN 0.932339
  WHEN 6930133 THEN 3.40447
  WHEN 6930134 THEN 5.97753
  WHEN 6930135 THEN 2.16648
  WHEN 6930136 THEN 5.57946
  WHEN 6930137 THEN 2.21843
  WHEN 6930138 THEN 4.37139
  WHEN 6930139 THEN 3.80534
  WHEN 6930140 THEN 4.17001
  WHEN 6930141 THEN 1.58359
  WHEN 6930142 THEN 5.46919
  WHEN 6931001 THEN 2.28552
  WHEN 6931002 THEN 0.88168
  WHEN 6931003 THEN 2.83562
  WHEN 6931004 THEN 2.83562
  WHEN 6931005 THEN 2.81319
  WHEN 6931006 THEN 6.19349
  WHEN 6931007 THEN 5.97981
  WHEN 6931008 THEN 4.11176
  WHEN 6931009 THEN 3.8936
  WHEN 6931010 THEN 1.79993
  WHEN 6931011 THEN 0.65179
  WHEN 6931012 THEN 5.87119
  WHEN 6931013 THEN 5.87119
  WHEN 6931014 THEN 5.53632
  WHEN 6931015 THEN 3.40176
  WHEN 6931016 THEN 4.98423
  WHEN 6931017 THEN 2.19616
  WHEN 6931018 THEN 3.8572
  WHEN 6931019 THEN 3.8572
  WHEN 6931020 THEN 3.8572
  WHEN 6931021 THEN 3.75945
  WHEN 6931022 THEN 0.88168
  WHEN 6931023 THEN 0.88168
  WHEN 6931024 THEN 0.88168
  WHEN 6931025 THEN 0.88168
  WHEN 6931026 THEN 2.83562
  WHEN 6931027 THEN 2.83562
  WHEN 6931028 THEN 4.36127
  WHEN 6931029 THEN 1.61768
  WHEN 6931030 THEN 5.64351
  WHEN 6931031 THEN 4.05554
  WHEN 6931032 THEN 1.51931
  WHEN 6931033 THEN 1.55115
  WHEN 6931034 THEN 4.05589
  WHEN 6931035 THEN 4.05589
  WHEN 6931036 THEN 2.05694
  WHEN 6931037 THEN 2.15198
  WHEN 6931038 THEN 2.15198
  WHEN 6931039 THEN 0.19939
  WHEN 6931040 THEN 3.18828
  WHEN 6931041 THEN 0.46308
  WHEN 6931042 THEN 1.42201
  WHEN 6931043 THEN 1.42201
  WHEN 6931044 THEN 3.12075
  WHEN 6931045 THEN 3.12075
  WHEN 6931046 THEN 6.02695
  WHEN 6931047 THEN 0.22434
  WHEN 6931048 THEN 1.63765
  WHEN 6931049 THEN 2.96165
  WHEN 6931050 THEN 0.00508
  WHEN 6931051 THEN 0.20329
  WHEN 6931052 THEN 1.22471
  WHEN 6931053 THEN 2.15101
  WHEN 6931054 THEN 3.2959
  WHEN 6931055 THEN 5.33328
  WHEN 6931056 THEN 6.08334
  WHEN 6931057 THEN 1.88444
  WHEN 6931058 THEN 4.79191
  WHEN 6931059 THEN 1.40818
  WHEN 6931060 THEN 3.18633
  WHEN 6931061 THEN 1.45106
  WHEN 6931062 THEN 5.36612
  WHEN 6931063 THEN 5.40399
  WHEN 6931064 THEN 5.66434
  WHEN 6931065 THEN 6.24057
  WHEN 6931066 THEN 3.36957
  WHEN 6931067 THEN 2.05946
  WHEN 6931068 THEN 4.48775
  WHEN 6931069 THEN 1.25579
  WHEN 6931070 THEN 1.24513
  WHEN 6931071 THEN 2.29905
  WHEN 6931072 THEN 2.29905
  WHEN 6931073 THEN 5.10854
  WHEN 6931074 THEN 5.10854
  WHEN 6931075 THEN 5.10854
  WHEN 6931076 THEN 2.95003
  WHEN 6931077 THEN 0.71766
  WHEN 6931078 THEN 3.99515
  WHEN 6931079 THEN 3.40255
  WHEN 6931082 THEN 2.67975
  WHEN 6931083 THEN 1.44464
  WHEN 6931087 THEN 2.88736
  WHEN 6931088 THEN 5.87119
  WHEN 6931089 THEN 5.16831
  WHEN 6931090 THEN 5.16831
  WHEN 6931091 THEN 0.97459
  WHEN 6931092 THEN 1.38042
  WHEN 6931093 THEN 3.49776
  WHEN 6931094 THEN 2.50085
  WHEN 6931095 THEN 0.39846
  WHEN 6931096 THEN 0.96027
  WHEN 6931097 THEN 1.0686
  WHEN 6931098 THEN 5.04808
  WHEN 6931099 THEN 1.44464
  WHEN 6931100 THEN 0.10573
  WHEN 6931101 THEN 0.620918
  WHEN 6931103 THEN 4.81747
  WHEN 6931104 THEN 5.29011
  WHEN 6931105 THEN 0.206652
  WHEN 6931106 THEN 5.04808
  WHEN 6931107 THEN 3.90833
  WHEN 6931108 THEN 5.16831
  WHEN 6931109 THEN 1.06963
  WHEN 6931110 THEN 2.50085
  WHEN 6931111 THEN 2.50085
  WHEN 6931112 THEN 3.12075
  WHEN 6931113 THEN 5.66434
  WHEN 6931114 THEN 5.66434
  WHEN 6931115 THEN 5.66434
  WHEN 6931116 THEN 5.10854
  WHEN 6931117 THEN 5.10854
  WHEN 6931118 THEN 5.10854
  WHEN 6931119 THEN 3.19494
  WHEN 6931120 THEN 3.19494
  WHEN 6931121 THEN 1.44464
  WHEN 6931122 THEN 0.10573
  WHEN 6931123 THEN 0.620918
  WHEN 6931124 THEN 5.16831
  WHEN 6931125 THEN 1.64305
  WHEN 6931126 THEN 2.78108
  WHEN 6931127 THEN 1.42201
  WHEN 6931128 THEN 2.50769
  WHEN 6931129 THEN 2.66171
  WHEN 6931130 THEN 5.85464
  WHEN 6931131 THEN 3.4554
  WHEN 6931132 THEN 5.66434
  WHEN 6931133 THEN 4.32816
  WHEN 6931134 THEN 3.8936
  WHEN 6931135 THEN 2.57857
  WHEN 6931136 THEN 5.16831
  WHEN 6931137 THEN 3.96736
  WHEN 6931138 THEN 1.04844
  WHEN 6931139 THEN 1.04844
  WHEN 6931140 THEN 6.08334
  WHEN 6931141 THEN 5.10854
  WHEN 6931142 THEN 0.33605
  WHEN 6931143 THEN 1.44464
  WHEN 6931144 THEN 1.04844
  WHEN 6931145 THEN 6.05221
  WHEN 6931146 THEN 0.20329
  WHEN 6931147 THEN 1.40818
  WHEN 6931148 THEN 6.08949
  WHEN 6931149 THEN 5.16831
  WHEN 6931150 THEN 0.931378
  WHEN 6931151 THEN 4.46286
  WHEN 6931152 THEN 5.68604
  WHEN 6931153 THEN 1.42201
  WHEN 6931154 THEN 1.72135
  WHEN 6931155 THEN 4.79386
  WHEN 6931156 THEN 4.52611
  WHEN 6931157 THEN 0.39332
  WHEN 6931158 THEN 2.82791
  WHEN 6931159 THEN 0.40705
  WHEN 6931160 THEN 4.87219
  WHEN 6931161 THEN 0.79259
  WHEN 6931162 THEN 5.99404
  WHEN 6931163 THEN 5.21248
  WHEN 6931164 THEN 0.11141
  WHEN 6931165 THEN 3.51305
  WHEN 6931166 THEN 2.52625
  WHEN 6931167 THEN 5.10854
  WHEN 6931168 THEN 5.10854
  WHEN 6931169 THEN 5.10854
  WHEN 6931170 THEN 5.10854
  WHEN 6931171 THEN 5.17852
  WHEN 6931172 THEN 2.70543
  WHEN 6931173 THEN 4.94812
  WHEN 6931174 THEN 5.9785
  WHEN 6931175 THEN 0.004807
  WHEN 6931176 THEN 5.98138
  WHEN 6931177 THEN 5.05289
  WHEN 6931178 THEN 4.53178
  WHEN 6931179 THEN 4.98423
  WHEN 6931180 THEN 1.04844
  WHEN 6931181 THEN 6.05221
  WHEN 6931182 THEN 0.20329
  WHEN 6931183 THEN 5.84455
  WHEN 6931184 THEN 6.21111
  WHEN 6931185 THEN 0.518073
  WHEN 6931189 THEN 0.3247
  WHEN 6931190 THEN 1.17463
  WHEN 6931191 THEN 5.99752
  WHEN 6931192 THEN 4.66292
  WHEN 6931193 THEN 2.04744
  WHEN 6931194 THEN 2.78954
  WHEN 6931195 THEN 0.07712
  WHEN 6931196 THEN 5.40556
  WHEN 6931197 THEN 4.56247
  WHEN 6931198 THEN 5.05289
  ELSE `orientation` END
WHERE `guid` IN (6901511, 6901513, 6901514, 6901515, 6901516, 6901517, 6901518, 6903001, 6910001, 6920004, 6920005, 6920007, 6920008, 6920009, 6920010, 6920012, 6920013, 6920018, 6920019, 6920020, 6920021, 6920022, 6920023, 6920024, 6920025, 6920026, 6920029, 6920030, 6920031, 6920032, 6920033, 6920034, 6920035, 6920036, 6920037, 6920038, 6920039, 6920040, 6920041, 6920042, 6920043, 6920044, 6920045, 6920046, 6920047, 6920048, 6920049, 6920050, 6920051, 6920052, 6920053, 6920054, 6920055, 6920056, 6920057, 6920058, 6920059, 6920060, 6920063, 6920064, 6920065, 6920066, 6920067, 6920068, 6920069, 6920070, 6920072, 6920073, 6920074, 6920076, 6930001, 6930002, 6930003, 6930004, 6930005, 6930006, 6930007, 6930008, 6930009, 6930010, 6930011, 6930012, 6930013, 6930014, 6930015, 6930016, 6930017, 6930018, 6930019, 6930020, 6930021, 6930022, 6930023, 6930024, 6930025, 6930026, 6930027, 6930028, 6930029, 6930030, 6930031, 6930032, 6930033, 6930034, 6930035, 6930036, 6930037, 6930038, 6930039, 6930040, 6930041, 6930042, 6930043, 6930044, 6930045, 6930046, 6930047, 6930048, 6930049, 6930050, 6930051, 6930052, 6930053, 6930054, 6930055, 6930056, 6930057, 6930058, 6930059, 6930060, 6930061, 6930062, 6930063, 6930064, 6930065, 6930066, 6930067, 6930068, 6930069, 6930070, 6930071, 6930072, 6930073, 6930074, 6930075, 6930076, 6930077, 6930078, 6930079, 6930080, 6930081, 6930082, 6930083, 6930084, 6930085, 6930086, 6930087, 6930088, 6930089, 6930090, 6930091, 6930092, 6930093, 6930094, 6930095, 6930096, 6930097, 6930098, 6930099, 6930100, 6930101, 6930102, 6930103, 6930104, 6930105, 6930106, 6930107, 6930108, 6930109, 6930110, 6930111, 6930112, 6930113, 6930114, 6930115, 6930116, 6930117, 6930118, 6930119, 6930120, 6930121, 6930122, 6930123, 6930124, 6930125, 6930126, 6930127, 6930128, 6930129, 6930130, 6930131, 6930132, 6930133, 6930134, 6930135, 6930136, 6930137, 6930138, 6930139, 6930140, 6930141, 6930142, 6931001, 6931002, 6931003, 6931004, 6931005, 6931006, 6931007, 6931008, 6931009, 6931010, 6931011, 6931012, 6931013, 6931014, 6931015, 6931016, 6931017, 6931018, 6931019, 6931020, 6931021, 6931022, 6931023, 6931024, 6931025, 6931026, 6931027, 6931028, 6931029, 6931030, 6931031, 6931032, 6931033, 6931034, 6931035, 6931036, 6931037, 6931038, 6931039, 6931040, 6931041, 6931042, 6931043, 6931044, 6931045, 6931046, 6931047, 6931048, 6931049, 6931050, 6931051, 6931052, 6931053, 6931054, 6931055, 6931056, 6931057, 6931058, 6931059, 6931060, 6931061, 6931062, 6931063, 6931064, 6931065, 6931066, 6931067, 6931068, 6931069, 6931070, 6931071, 6931072, 6931073, 6931074, 6931075, 6931076, 6931077, 6931078, 6931079, 6931082, 6931083, 6931087, 6931088, 6931089, 6931090, 6931091, 6931092, 6931093, 6931094, 6931095, 6931096, 6931097, 6931098, 6931099, 6931100, 6931101, 6931103, 6931104, 6931105, 6931106, 6931107, 6931108, 6931109, 6931110, 6931111, 6931112, 6931113, 6931114, 6931115, 6931116, 6931117, 6931118, 6931119, 6931120, 6931121, 6931122, 6931123, 6931124, 6931125, 6931126, 6931127, 6931128, 6931129, 6931130, 6931131, 6931132, 6931133, 6931134, 6931135, 6931136, 6931137, 6931138, 6931139, 6931140, 6931141, 6931142, 6931143, 6931144, 6931145, 6931146, 6931147, 6931148, 6931149, 6931150, 6931151, 6931152, 6931153, 6931154, 6931155, 6931156, 6931157, 6931158, 6931159, 6931160, 6931161, 6931162, 6931163, 6931164, 6931165, 6931166, 6931167, 6931168, 6931169, 6931170, 6931171, 6931172, 6931173, 6931174, 6931175, 6931176, 6931177, 6931178, 6931179, 6931180, 6931181, 6931182, 6931183, 6931184, 6931185, 6931189, 6931190, 6931191, 6931192, 6931193, 6931194, 6931195, 6931196, 6931197, 6931198);

UPDATE `gameobject` SET `rotation0` = CASE `guid`
  WHEN 6901511 THEN 0
  WHEN 6901513 THEN 0
  WHEN 6901514 THEN 0
  WHEN 6901515 THEN 0
  WHEN 6901516 THEN 0
  WHEN 6901517 THEN 0
  WHEN 6901518 THEN 0
  WHEN 6903001 THEN 0
  WHEN 6910001 THEN 0
  WHEN 6920004 THEN 0
  WHEN 6920005 THEN 0
  WHEN 6920007 THEN 0
  WHEN 6920008 THEN 0
  WHEN 6920009 THEN 0
  WHEN 6920010 THEN 0
  WHEN 6920012 THEN 0
  WHEN 6920013 THEN 0
  WHEN 6920018 THEN 0
  WHEN 6920019 THEN 0
  WHEN 6920020 THEN 0
  WHEN 6920021 THEN 0
  WHEN 6920022 THEN 0
  WHEN 6920023 THEN 0
  WHEN 6920024 THEN 0
  WHEN 6920025 THEN 0
  WHEN 6920026 THEN 0
  WHEN 6920029 THEN 0
  WHEN 6920030 THEN 0
  WHEN 6920031 THEN 0
  WHEN 6920032 THEN 0
  WHEN 6920033 THEN 0
  WHEN 6920034 THEN 0
  WHEN 6920035 THEN 0
  WHEN 6920036 THEN 0
  WHEN 6920037 THEN 0
  WHEN 6920038 THEN 0
  WHEN 6920039 THEN 0
  WHEN 6920040 THEN 0
  WHEN 6920041 THEN 0
  WHEN 6920042 THEN 0
  WHEN 6920043 THEN 0
  WHEN 6920044 THEN 0
  WHEN 6920045 THEN 0
  WHEN 6920046 THEN 0
  WHEN 6920047 THEN 0
  WHEN 6920048 THEN 0
  WHEN 6920049 THEN 0
  WHEN 6920050 THEN 0
  WHEN 6920051 THEN 0
  WHEN 6920052 THEN 0
  WHEN 6920053 THEN 0
  WHEN 6920054 THEN 0
  WHEN 6920055 THEN 0
  WHEN 6920056 THEN 0
  WHEN 6920057 THEN 0
  WHEN 6920058 THEN 0
  WHEN 6920059 THEN 0
  WHEN 6920060 THEN 0
  WHEN 6920063 THEN 0
  WHEN 6920064 THEN 0
  WHEN 6920065 THEN 0
  WHEN 6920066 THEN 0
  WHEN 6920067 THEN 0
  WHEN 6920068 THEN 0
  WHEN 6920069 THEN 0
  WHEN 6920070 THEN 0
  WHEN 6920072 THEN 0
  WHEN 6920073 THEN 0
  WHEN 6920074 THEN 0
  WHEN 6920076 THEN 0
  WHEN 6930001 THEN 0
  WHEN 6930002 THEN 0
  WHEN 6930003 THEN 0
  WHEN 6930004 THEN 0
  WHEN 6930005 THEN 0
  WHEN 6930006 THEN 0
  WHEN 6930007 THEN 0
  WHEN 6930008 THEN 0
  WHEN 6930009 THEN 0
  WHEN 6930010 THEN 0
  WHEN 6930011 THEN 0
  WHEN 6930012 THEN 0
  WHEN 6930013 THEN 0
  WHEN 6930014 THEN 0
  WHEN 6930015 THEN 0
  WHEN 6930016 THEN 0
  WHEN 6930017 THEN 0
  WHEN 6930018 THEN 0
  WHEN 6930019 THEN 0
  WHEN 6930020 THEN 0
  WHEN 6930021 THEN 0
  WHEN 6930022 THEN 0
  WHEN 6930023 THEN 0
  WHEN 6930024 THEN 0
  WHEN 6930025 THEN 0
  WHEN 6930026 THEN 0
  WHEN 6930027 THEN 0
  WHEN 6930028 THEN 0
  WHEN 6930029 THEN 0
  WHEN 6930030 THEN 0
  WHEN 6930031 THEN 0
  WHEN 6930032 THEN 0
  WHEN 6930033 THEN 0
  WHEN 6930034 THEN 0
  WHEN 6930035 THEN 0
  WHEN 6930036 THEN 0
  WHEN 6930037 THEN 0
  WHEN 6930038 THEN 0
  WHEN 6930039 THEN 0
  WHEN 6930040 THEN 0
  WHEN 6930041 THEN 0
  WHEN 6930042 THEN 0
  WHEN 6930043 THEN 0
  WHEN 6930044 THEN 0
  WHEN 6930045 THEN 0
  WHEN 6930046 THEN 0
  WHEN 6930047 THEN 0
  WHEN 6930048 THEN 0
  WHEN 6930049 THEN 0
  WHEN 6930050 THEN 0
  WHEN 6930051 THEN 0
  WHEN 6930052 THEN 0
  WHEN 6930053 THEN 0
  WHEN 6930054 THEN 0
  WHEN 6930055 THEN 0
  WHEN 6930056 THEN 0
  WHEN 6930057 THEN 0
  WHEN 6930058 THEN 0
  WHEN 6930059 THEN 0
  WHEN 6930060 THEN 0
  WHEN 6930061 THEN 0
  WHEN 6930062 THEN 0
  WHEN 6930063 THEN 0
  WHEN 6930064 THEN 0
  WHEN 6930065 THEN 0
  WHEN 6930066 THEN 0
  WHEN 6930067 THEN 0
  WHEN 6930068 THEN 0
  WHEN 6930069 THEN 0
  WHEN 6930070 THEN 0
  WHEN 6930071 THEN 0
  WHEN 6930072 THEN 0
  WHEN 6930073 THEN 0
  WHEN 6930074 THEN 0
  WHEN 6930075 THEN 0
  WHEN 6930076 THEN 0
  WHEN 6930077 THEN 0
  WHEN 6930078 THEN 0
  WHEN 6930079 THEN 0
  WHEN 6930080 THEN 0
  WHEN 6930081 THEN 0
  WHEN 6930082 THEN 0
  WHEN 6930083 THEN 0
  WHEN 6930084 THEN 0
  WHEN 6930085 THEN 0
  WHEN 6930086 THEN 0
  WHEN 6930087 THEN 0
  WHEN 6930088 THEN 0
  WHEN 6930089 THEN 0
  WHEN 6930090 THEN 0
  WHEN 6930091 THEN 0
  WHEN 6930092 THEN 0
  WHEN 6930093 THEN 0
  WHEN 6930094 THEN 0
  WHEN 6930095 THEN 0
  WHEN 6930096 THEN 0
  WHEN 6930097 THEN 0
  WHEN 6930098 THEN 0
  WHEN 6930099 THEN 0
  WHEN 6930100 THEN 0
  WHEN 6930101 THEN 0
  WHEN 6930102 THEN 0
  WHEN 6930103 THEN 0
  WHEN 6930104 THEN 0
  WHEN 6930105 THEN 0
  WHEN 6930106 THEN 0
  WHEN 6930107 THEN 0
  WHEN 6930108 THEN 0
  WHEN 6930109 THEN 0
  WHEN 6930110 THEN 0
  WHEN 6930111 THEN 0
  WHEN 6930112 THEN 0
  WHEN 6930113 THEN 0
  WHEN 6930114 THEN 0
  WHEN 6930115 THEN 0
  WHEN 6930116 THEN 0
  WHEN 6930117 THEN 0
  WHEN 6930118 THEN 0
  WHEN 6930119 THEN 0
  WHEN 6930120 THEN 0
  WHEN 6930121 THEN 0
  WHEN 6930122 THEN 0
  WHEN 6930123 THEN 0
  WHEN 6930124 THEN 0
  WHEN 6930125 THEN 0
  WHEN 6930126 THEN 0
  WHEN 6930127 THEN 0
  WHEN 6930128 THEN 0
  WHEN 6930129 THEN 0
  WHEN 6930130 THEN 0
  WHEN 6930131 THEN 0
  WHEN 6930132 THEN 0
  WHEN 6930133 THEN 0
  WHEN 6930134 THEN 0
  WHEN 6930135 THEN 0
  WHEN 6930136 THEN 0
  WHEN 6930137 THEN 0
  WHEN 6930138 THEN 0
  WHEN 6930139 THEN 0
  WHEN 6930140 THEN 0
  WHEN 6930141 THEN 0
  WHEN 6930142 THEN 0
  WHEN 6931001 THEN 0
  WHEN 6931002 THEN 0
  WHEN 6931003 THEN 0
  WHEN 6931004 THEN 0
  WHEN 6931005 THEN 0
  WHEN 6931006 THEN 0
  WHEN 6931007 THEN 0
  WHEN 6931008 THEN 0
  WHEN 6931009 THEN 0
  WHEN 6931010 THEN 0
  WHEN 6931011 THEN 0
  WHEN 6931012 THEN 0
  WHEN 6931013 THEN 0
  WHEN 6931014 THEN 0
  WHEN 6931015 THEN 0
  WHEN 6931016 THEN 0
  WHEN 6931017 THEN 0
  WHEN 6931018 THEN 0
  WHEN 6931019 THEN 0
  WHEN 6931020 THEN 0
  WHEN 6931021 THEN 0
  WHEN 6931022 THEN 0
  WHEN 6931023 THEN 0
  WHEN 6931024 THEN 0
  WHEN 6931025 THEN 0
  WHEN 6931026 THEN 0
  WHEN 6931027 THEN 0
  WHEN 6931028 THEN 0
  WHEN 6931029 THEN 0
  WHEN 6931030 THEN 0
  WHEN 6931031 THEN 0
  WHEN 6931032 THEN 0
  WHEN 6931033 THEN 0
  WHEN 6931034 THEN 0
  WHEN 6931035 THEN 0
  WHEN 6931036 THEN 0
  WHEN 6931037 THEN 0
  WHEN 6931038 THEN 0
  WHEN 6931039 THEN 0
  WHEN 6931040 THEN 0
  WHEN 6931041 THEN 0
  WHEN 6931042 THEN 0
  WHEN 6931043 THEN 0
  WHEN 6931044 THEN 0
  WHEN 6931045 THEN 0
  WHEN 6931046 THEN 0
  WHEN 6931047 THEN 0
  WHEN 6931048 THEN 0
  WHEN 6931049 THEN 0
  WHEN 6931050 THEN 0
  WHEN 6931051 THEN 0
  WHEN 6931052 THEN 0
  WHEN 6931053 THEN 0
  WHEN 6931054 THEN 0
  WHEN 6931055 THEN 0
  WHEN 6931056 THEN 0
  WHEN 6931057 THEN 0
  WHEN 6931058 THEN 0
  WHEN 6931059 THEN 0
  WHEN 6931060 THEN 0
  WHEN 6931061 THEN 0
  WHEN 6931062 THEN 0
  WHEN 6931063 THEN 0
  WHEN 6931064 THEN 0
  WHEN 6931065 THEN 0
  WHEN 6931066 THEN 0
  WHEN 6931067 THEN 0
  WHEN 6931068 THEN 0
  WHEN 6931069 THEN 0
  WHEN 6931070 THEN 0
  WHEN 6931071 THEN 0
  WHEN 6931072 THEN 0
  WHEN 6931073 THEN 0
  WHEN 6931074 THEN 0
  WHEN 6931075 THEN 0
  WHEN 6931076 THEN 0
  WHEN 6931077 THEN 0
  WHEN 6931078 THEN 0
  WHEN 6931079 THEN 0
  WHEN 6931082 THEN 0
  WHEN 6931083 THEN 0
  WHEN 6931087 THEN 0
  WHEN 6931088 THEN 0
  WHEN 6931089 THEN 0
  WHEN 6931090 THEN 0
  WHEN 6931091 THEN 0
  WHEN 6931092 THEN 0
  WHEN 6931093 THEN 0
  WHEN 6931094 THEN 0
  WHEN 6931095 THEN 0
  WHEN 6931096 THEN 0
  WHEN 6931097 THEN 0
  WHEN 6931098 THEN 0
  WHEN 6931099 THEN 0
  WHEN 6931100 THEN 0
  WHEN 6931101 THEN 0
  WHEN 6931103 THEN 0
  WHEN 6931104 THEN 0
  WHEN 6931105 THEN 0
  WHEN 6931106 THEN 0
  WHEN 6931107 THEN 0
  WHEN 6931108 THEN 0
  WHEN 6931109 THEN 0
  WHEN 6931110 THEN 0
  WHEN 6931111 THEN 0
  WHEN 6931112 THEN 0
  WHEN 6931113 THEN 0
  WHEN 6931114 THEN 0
  WHEN 6931115 THEN 0
  WHEN 6931116 THEN 0
  WHEN 6931117 THEN 0
  WHEN 6931118 THEN 0
  WHEN 6931119 THEN 0
  WHEN 6931120 THEN 0
  WHEN 6931121 THEN 0
  WHEN 6931122 THEN 0
  WHEN 6931123 THEN 0
  WHEN 6931124 THEN 0
  WHEN 6931125 THEN 0
  WHEN 6931126 THEN 0
  WHEN 6931127 THEN 0
  WHEN 6931128 THEN 0
  WHEN 6931129 THEN 0
  WHEN 6931130 THEN 0
  WHEN 6931131 THEN 0
  WHEN 6931132 THEN 0
  WHEN 6931133 THEN 0
  WHEN 6931134 THEN 0
  WHEN 6931135 THEN 0
  WHEN 6931136 THEN 0
  WHEN 6931137 THEN 0
  WHEN 6931138 THEN 0
  WHEN 6931139 THEN 0
  WHEN 6931140 THEN 0
  WHEN 6931141 THEN 0
  WHEN 6931142 THEN 0
  WHEN 6931143 THEN 0
  WHEN 6931144 THEN 0
  WHEN 6931145 THEN 0
  WHEN 6931146 THEN 0
  WHEN 6931147 THEN 0
  WHEN 6931148 THEN 0
  WHEN 6931149 THEN 0
  WHEN 6931150 THEN 0
  WHEN 6931151 THEN 0
  WHEN 6931152 THEN 0
  WHEN 6931153 THEN 0
  WHEN 6931154 THEN 0
  WHEN 6931155 THEN 0
  WHEN 6931156 THEN 0
  WHEN 6931157 THEN 0
  WHEN 6931158 THEN 0
  WHEN 6931159 THEN 0
  WHEN 6931160 THEN 0
  WHEN 6931161 THEN 0
  WHEN 6931162 THEN 0
  WHEN 6931163 THEN 0
  WHEN 6931164 THEN 0
  WHEN 6931165 THEN 0
  WHEN 6931166 THEN 0
  WHEN 6931167 THEN 0
  WHEN 6931168 THEN 0
  WHEN 6931169 THEN 0
  WHEN 6931170 THEN 0
  WHEN 6931171 THEN 0
  WHEN 6931172 THEN 0
  WHEN 6931173 THEN 0
  WHEN 6931174 THEN 0
  WHEN 6931175 THEN 0
  WHEN 6931176 THEN 0
  WHEN 6931177 THEN 0
  WHEN 6931178 THEN 0
  WHEN 6931179 THEN 0
  WHEN 6931180 THEN 0
  WHEN 6931181 THEN 0
  WHEN 6931182 THEN 0
  WHEN 6931183 THEN 0
  WHEN 6931184 THEN 0
  WHEN 6931185 THEN 0
  WHEN 6931189 THEN 0
  WHEN 6931190 THEN 0
  WHEN 6931191 THEN 0
  WHEN 6931192 THEN 0
  WHEN 6931193 THEN 0
  WHEN 6931194 THEN 0
  WHEN 6931195 THEN 0
  WHEN 6931196 THEN 0
  WHEN 6931197 THEN 0
  WHEN 6931198 THEN 0
  ELSE `rotation0` END
WHERE `guid` IN (6901511, 6901513, 6901514, 6901515, 6901516, 6901517, 6901518, 6903001, 6910001, 6920004, 6920005, 6920007, 6920008, 6920009, 6920010, 6920012, 6920013, 6920018, 6920019, 6920020, 6920021, 6920022, 6920023, 6920024, 6920025, 6920026, 6920029, 6920030, 6920031, 6920032, 6920033, 6920034, 6920035, 6920036, 6920037, 6920038, 6920039, 6920040, 6920041, 6920042, 6920043, 6920044, 6920045, 6920046, 6920047, 6920048, 6920049, 6920050, 6920051, 6920052, 6920053, 6920054, 6920055, 6920056, 6920057, 6920058, 6920059, 6920060, 6920063, 6920064, 6920065, 6920066, 6920067, 6920068, 6920069, 6920070, 6920072, 6920073, 6920074, 6920076, 6930001, 6930002, 6930003, 6930004, 6930005, 6930006, 6930007, 6930008, 6930009, 6930010, 6930011, 6930012, 6930013, 6930014, 6930015, 6930016, 6930017, 6930018, 6930019, 6930020, 6930021, 6930022, 6930023, 6930024, 6930025, 6930026, 6930027, 6930028, 6930029, 6930030, 6930031, 6930032, 6930033, 6930034, 6930035, 6930036, 6930037, 6930038, 6930039, 6930040, 6930041, 6930042, 6930043, 6930044, 6930045, 6930046, 6930047, 6930048, 6930049, 6930050, 6930051, 6930052, 6930053, 6930054, 6930055, 6930056, 6930057, 6930058, 6930059, 6930060, 6930061, 6930062, 6930063, 6930064, 6930065, 6930066, 6930067, 6930068, 6930069, 6930070, 6930071, 6930072, 6930073, 6930074, 6930075, 6930076, 6930077, 6930078, 6930079, 6930080, 6930081, 6930082, 6930083, 6930084, 6930085, 6930086, 6930087, 6930088, 6930089, 6930090, 6930091, 6930092, 6930093, 6930094, 6930095, 6930096, 6930097, 6930098, 6930099, 6930100, 6930101, 6930102, 6930103, 6930104, 6930105, 6930106, 6930107, 6930108, 6930109, 6930110, 6930111, 6930112, 6930113, 6930114, 6930115, 6930116, 6930117, 6930118, 6930119, 6930120, 6930121, 6930122, 6930123, 6930124, 6930125, 6930126, 6930127, 6930128, 6930129, 6930130, 6930131, 6930132, 6930133, 6930134, 6930135, 6930136, 6930137, 6930138, 6930139, 6930140, 6930141, 6930142, 6931001, 6931002, 6931003, 6931004, 6931005, 6931006, 6931007, 6931008, 6931009, 6931010, 6931011, 6931012, 6931013, 6931014, 6931015, 6931016, 6931017, 6931018, 6931019, 6931020, 6931021, 6931022, 6931023, 6931024, 6931025, 6931026, 6931027, 6931028, 6931029, 6931030, 6931031, 6931032, 6931033, 6931034, 6931035, 6931036, 6931037, 6931038, 6931039, 6931040, 6931041, 6931042, 6931043, 6931044, 6931045, 6931046, 6931047, 6931048, 6931049, 6931050, 6931051, 6931052, 6931053, 6931054, 6931055, 6931056, 6931057, 6931058, 6931059, 6931060, 6931061, 6931062, 6931063, 6931064, 6931065, 6931066, 6931067, 6931068, 6931069, 6931070, 6931071, 6931072, 6931073, 6931074, 6931075, 6931076, 6931077, 6931078, 6931079, 6931082, 6931083, 6931087, 6931088, 6931089, 6931090, 6931091, 6931092, 6931093, 6931094, 6931095, 6931096, 6931097, 6931098, 6931099, 6931100, 6931101, 6931103, 6931104, 6931105, 6931106, 6931107, 6931108, 6931109, 6931110, 6931111, 6931112, 6931113, 6931114, 6931115, 6931116, 6931117, 6931118, 6931119, 6931120, 6931121, 6931122, 6931123, 6931124, 6931125, 6931126, 6931127, 6931128, 6931129, 6931130, 6931131, 6931132, 6931133, 6931134, 6931135, 6931136, 6931137, 6931138, 6931139, 6931140, 6931141, 6931142, 6931143, 6931144, 6931145, 6931146, 6931147, 6931148, 6931149, 6931150, 6931151, 6931152, 6931153, 6931154, 6931155, 6931156, 6931157, 6931158, 6931159, 6931160, 6931161, 6931162, 6931163, 6931164, 6931165, 6931166, 6931167, 6931168, 6931169, 6931170, 6931171, 6931172, 6931173, 6931174, 6931175, 6931176, 6931177, 6931178, 6931179, 6931180, 6931181, 6931182, 6931183, 6931184, 6931185, 6931189, 6931190, 6931191, 6931192, 6931193, 6931194, 6931195, 6931196, 6931197, 6931198);

UPDATE `gameobject` SET `rotation1` = CASE `guid`
  WHEN 6901511 THEN 0
  WHEN 6901513 THEN 0
  WHEN 6901514 THEN 0
  WHEN 6901515 THEN 0
  WHEN 6901516 THEN 0
  WHEN 6901517 THEN 0
  WHEN 6901518 THEN 0
  WHEN 6903001 THEN 0
  WHEN 6910001 THEN 0
  WHEN 6920004 THEN 0
  WHEN 6920005 THEN 0
  WHEN 6920007 THEN 0
  WHEN 6920008 THEN 0
  WHEN 6920009 THEN 0
  WHEN 6920010 THEN 0
  WHEN 6920012 THEN 0
  WHEN 6920013 THEN 0
  WHEN 6920018 THEN 0
  WHEN 6920019 THEN 0
  WHEN 6920020 THEN 0
  WHEN 6920021 THEN 0
  WHEN 6920022 THEN 0
  WHEN 6920023 THEN 0
  WHEN 6920024 THEN 0
  WHEN 6920025 THEN 0
  WHEN 6920026 THEN 0
  WHEN 6920029 THEN 0
  WHEN 6920030 THEN 0
  WHEN 6920031 THEN 0
  WHEN 6920032 THEN 0
  WHEN 6920033 THEN 0
  WHEN 6920034 THEN 0
  WHEN 6920035 THEN 0
  WHEN 6920036 THEN 0
  WHEN 6920037 THEN 0
  WHEN 6920038 THEN 0
  WHEN 6920039 THEN 0
  WHEN 6920040 THEN 0
  WHEN 6920041 THEN 0
  WHEN 6920042 THEN 0
  WHEN 6920043 THEN 0
  WHEN 6920044 THEN 0
  WHEN 6920045 THEN 0
  WHEN 6920046 THEN 0
  WHEN 6920047 THEN 0
  WHEN 6920048 THEN 0
  WHEN 6920049 THEN 0
  WHEN 6920050 THEN 0
  WHEN 6920051 THEN 0
  WHEN 6920052 THEN 0
  WHEN 6920053 THEN 0
  WHEN 6920054 THEN 0
  WHEN 6920055 THEN 0
  WHEN 6920056 THEN 0
  WHEN 6920057 THEN 0
  WHEN 6920058 THEN 0
  WHEN 6920059 THEN 0
  WHEN 6920060 THEN 0
  WHEN 6920063 THEN 0
  WHEN 6920064 THEN 0
  WHEN 6920065 THEN 0
  WHEN 6920066 THEN 0
  WHEN 6920067 THEN 0
  WHEN 6920068 THEN 0
  WHEN 6920069 THEN 0
  WHEN 6920070 THEN 0
  WHEN 6920072 THEN 0
  WHEN 6920073 THEN 0
  WHEN 6920074 THEN 0
  WHEN 6920076 THEN 0
  WHEN 6930001 THEN 0
  WHEN 6930002 THEN 0
  WHEN 6930003 THEN 0
  WHEN 6930004 THEN 0
  WHEN 6930005 THEN 0
  WHEN 6930006 THEN 0
  WHEN 6930007 THEN 0
  WHEN 6930008 THEN 0
  WHEN 6930009 THEN 0
  WHEN 6930010 THEN 0
  WHEN 6930011 THEN 0
  WHEN 6930012 THEN 0
  WHEN 6930013 THEN 0
  WHEN 6930014 THEN 0
  WHEN 6930015 THEN 0
  WHEN 6930016 THEN 0
  WHEN 6930017 THEN 0
  WHEN 6930018 THEN 0
  WHEN 6930019 THEN 0
  WHEN 6930020 THEN 0
  WHEN 6930021 THEN 0
  WHEN 6930022 THEN 0
  WHEN 6930023 THEN 0
  WHEN 6930024 THEN 0
  WHEN 6930025 THEN 0
  WHEN 6930026 THEN 0
  WHEN 6930027 THEN 0
  WHEN 6930028 THEN 0
  WHEN 6930029 THEN 0
  WHEN 6930030 THEN 0
  WHEN 6930031 THEN 0
  WHEN 6930032 THEN 0
  WHEN 6930033 THEN 0
  WHEN 6930034 THEN 0
  WHEN 6930035 THEN 0
  WHEN 6930036 THEN 0
  WHEN 6930037 THEN 0
  WHEN 6930038 THEN 0
  WHEN 6930039 THEN 0
  WHEN 6930040 THEN 0
  WHEN 6930041 THEN 0
  WHEN 6930042 THEN 0
  WHEN 6930043 THEN 0
  WHEN 6930044 THEN 0
  WHEN 6930045 THEN 0
  WHEN 6930046 THEN 0
  WHEN 6930047 THEN 0
  WHEN 6930048 THEN 0
  WHEN 6930049 THEN 0
  WHEN 6930050 THEN 0
  WHEN 6930051 THEN 0
  WHEN 6930052 THEN 0
  WHEN 6930053 THEN 0
  WHEN 6930054 THEN 0
  WHEN 6930055 THEN 0
  WHEN 6930056 THEN 0
  WHEN 6930057 THEN 0
  WHEN 6930058 THEN 0
  WHEN 6930059 THEN 0
  WHEN 6930060 THEN 0
  WHEN 6930061 THEN 0
  WHEN 6930062 THEN 0
  WHEN 6930063 THEN 0
  WHEN 6930064 THEN 0
  WHEN 6930065 THEN 0
  WHEN 6930066 THEN 0
  WHEN 6930067 THEN 0
  WHEN 6930068 THEN 0
  WHEN 6930069 THEN 0
  WHEN 6930070 THEN 0
  WHEN 6930071 THEN 0
  WHEN 6930072 THEN 0
  WHEN 6930073 THEN 0
  WHEN 6930074 THEN 0
  WHEN 6930075 THEN 0
  WHEN 6930076 THEN 0
  WHEN 6930077 THEN 0
  WHEN 6930078 THEN 0
  WHEN 6930079 THEN 0
  WHEN 6930080 THEN 0
  WHEN 6930081 THEN 0
  WHEN 6930082 THEN 0
  WHEN 6930083 THEN 0
  WHEN 6930084 THEN 0
  WHEN 6930085 THEN 0
  WHEN 6930086 THEN 0
  WHEN 6930087 THEN 0
  WHEN 6930088 THEN 0
  WHEN 6930089 THEN 0
  WHEN 6930090 THEN 0
  WHEN 6930091 THEN 0
  WHEN 6930092 THEN 0
  WHEN 6930093 THEN 0
  WHEN 6930094 THEN 0
  WHEN 6930095 THEN 0
  WHEN 6930096 THEN 0
  WHEN 6930097 THEN 0
  WHEN 6930098 THEN 0
  WHEN 6930099 THEN 0
  WHEN 6930100 THEN 0
  WHEN 6930101 THEN 0
  WHEN 6930102 THEN 0
  WHEN 6930103 THEN 0
  WHEN 6930104 THEN 0
  WHEN 6930105 THEN 0
  WHEN 6930106 THEN 0
  WHEN 6930107 THEN 0
  WHEN 6930108 THEN 0
  WHEN 6930109 THEN 0
  WHEN 6930110 THEN 0
  WHEN 6930111 THEN 0
  WHEN 6930112 THEN 0
  WHEN 6930113 THEN 0
  WHEN 6930114 THEN 0
  WHEN 6930115 THEN 0
  WHEN 6930116 THEN 0
  WHEN 6930117 THEN 0
  WHEN 6930118 THEN 0
  WHEN 6930119 THEN 0
  WHEN 6930120 THEN 0
  WHEN 6930121 THEN 0
  WHEN 6930122 THEN 0
  WHEN 6930123 THEN 0
  WHEN 6930124 THEN 0
  WHEN 6930125 THEN 0
  WHEN 6930126 THEN 0
  WHEN 6930127 THEN 0
  WHEN 6930128 THEN 0
  WHEN 6930129 THEN 0
  WHEN 6930130 THEN 0
  WHEN 6930131 THEN 0
  WHEN 6930132 THEN 0
  WHEN 6930133 THEN 0
  WHEN 6930134 THEN 0
  WHEN 6930135 THEN 0
  WHEN 6930136 THEN 0
  WHEN 6930137 THEN 0
  WHEN 6930138 THEN 0
  WHEN 6930139 THEN 0
  WHEN 6930140 THEN 0
  WHEN 6930141 THEN 0
  WHEN 6930142 THEN 0
  WHEN 6931001 THEN 0
  WHEN 6931002 THEN 0
  WHEN 6931003 THEN 0
  WHEN 6931004 THEN 0
  WHEN 6931005 THEN 0
  WHEN 6931006 THEN 0
  WHEN 6931007 THEN 0
  WHEN 6931008 THEN 0
  WHEN 6931009 THEN 0
  WHEN 6931010 THEN 0
  WHEN 6931011 THEN 0
  WHEN 6931012 THEN 0
  WHEN 6931013 THEN 0
  WHEN 6931014 THEN 0
  WHEN 6931015 THEN 0
  WHEN 6931016 THEN 0
  WHEN 6931017 THEN 0
  WHEN 6931018 THEN 0
  WHEN 6931019 THEN 0
  WHEN 6931020 THEN 0
  WHEN 6931021 THEN 0
  WHEN 6931022 THEN 0
  WHEN 6931023 THEN 0
  WHEN 6931024 THEN 0
  WHEN 6931025 THEN 0
  WHEN 6931026 THEN 0
  WHEN 6931027 THEN 0
  WHEN 6931028 THEN 0
  WHEN 6931029 THEN 0
  WHEN 6931030 THEN 0
  WHEN 6931031 THEN 0
  WHEN 6931032 THEN 0
  WHEN 6931033 THEN 0
  WHEN 6931034 THEN 0
  WHEN 6931035 THEN 0
  WHEN 6931036 THEN 0
  WHEN 6931037 THEN 0
  WHEN 6931038 THEN 0
  WHEN 6931039 THEN 0
  WHEN 6931040 THEN 0
  WHEN 6931041 THEN 0
  WHEN 6931042 THEN 0
  WHEN 6931043 THEN 0
  WHEN 6931044 THEN 0
  WHEN 6931045 THEN 0
  WHEN 6931046 THEN 0
  WHEN 6931047 THEN 0
  WHEN 6931048 THEN 0
  WHEN 6931049 THEN 0
  WHEN 6931050 THEN 0
  WHEN 6931051 THEN 0
  WHEN 6931052 THEN 0
  WHEN 6931053 THEN 0
  WHEN 6931054 THEN 0
  WHEN 6931055 THEN 0
  WHEN 6931056 THEN 0
  WHEN 6931057 THEN 0
  WHEN 6931058 THEN 0
  WHEN 6931059 THEN 0
  WHEN 6931060 THEN 0
  WHEN 6931061 THEN 0
  WHEN 6931062 THEN 0
  WHEN 6931063 THEN 0
  WHEN 6931064 THEN 0
  WHEN 6931065 THEN 0
  WHEN 6931066 THEN 0
  WHEN 6931067 THEN 0
  WHEN 6931068 THEN 0
  WHEN 6931069 THEN 0
  WHEN 6931070 THEN 0
  WHEN 6931071 THEN 0
  WHEN 6931072 THEN 0
  WHEN 6931073 THEN 0
  WHEN 6931074 THEN 0
  WHEN 6931075 THEN 0
  WHEN 6931076 THEN 0
  WHEN 6931077 THEN 0
  WHEN 6931078 THEN 0
  WHEN 6931079 THEN 0
  WHEN 6931082 THEN 0
  WHEN 6931083 THEN 0
  WHEN 6931087 THEN 0
  WHEN 6931088 THEN 0
  WHEN 6931089 THEN 0
  WHEN 6931090 THEN 0
  WHEN 6931091 THEN 0
  WHEN 6931092 THEN 0
  WHEN 6931093 THEN 0
  WHEN 6931094 THEN 0
  WHEN 6931095 THEN 0
  WHEN 6931096 THEN 0
  WHEN 6931097 THEN 0
  WHEN 6931098 THEN 0
  WHEN 6931099 THEN 0
  WHEN 6931100 THEN 0
  WHEN 6931101 THEN 0
  WHEN 6931103 THEN 0
  WHEN 6931104 THEN 0
  WHEN 6931105 THEN 0
  WHEN 6931106 THEN 0
  WHEN 6931107 THEN 0
  WHEN 6931108 THEN 0
  WHEN 6931109 THEN 0
  WHEN 6931110 THEN 0
  WHEN 6931111 THEN 0
  WHEN 6931112 THEN 0
  WHEN 6931113 THEN 0
  WHEN 6931114 THEN 0
  WHEN 6931115 THEN 0
  WHEN 6931116 THEN 0
  WHEN 6931117 THEN 0
  WHEN 6931118 THEN 0
  WHEN 6931119 THEN 0
  WHEN 6931120 THEN 0
  WHEN 6931121 THEN 0
  WHEN 6931122 THEN 0
  WHEN 6931123 THEN 0
  WHEN 6931124 THEN 0
  WHEN 6931125 THEN 0
  WHEN 6931126 THEN 0
  WHEN 6931127 THEN 0
  WHEN 6931128 THEN 0
  WHEN 6931129 THEN 0
  WHEN 6931130 THEN 0
  WHEN 6931131 THEN 0
  WHEN 6931132 THEN 0
  WHEN 6931133 THEN 0
  WHEN 6931134 THEN 0
  WHEN 6931135 THEN 0
  WHEN 6931136 THEN 0
  WHEN 6931137 THEN 0
  WHEN 6931138 THEN 0
  WHEN 6931139 THEN 0
  WHEN 6931140 THEN 0
  WHEN 6931141 THEN 0
  WHEN 6931142 THEN 0
  WHEN 6931143 THEN 0
  WHEN 6931144 THEN 0
  WHEN 6931145 THEN 0
  WHEN 6931146 THEN 0
  WHEN 6931147 THEN 0
  WHEN 6931148 THEN 0
  WHEN 6931149 THEN 0
  WHEN 6931150 THEN 0
  WHEN 6931151 THEN 0
  WHEN 6931152 THEN 0
  WHEN 6931153 THEN 0
  WHEN 6931154 THEN 0
  WHEN 6931155 THEN 0
  WHEN 6931156 THEN 0
  WHEN 6931157 THEN 0
  WHEN 6931158 THEN 0
  WHEN 6931159 THEN 0
  WHEN 6931160 THEN 0
  WHEN 6931161 THEN 0
  WHEN 6931162 THEN 0
  WHEN 6931163 THEN 0
  WHEN 6931164 THEN 0
  WHEN 6931165 THEN 0
  WHEN 6931166 THEN 0
  WHEN 6931167 THEN 0
  WHEN 6931168 THEN 0
  WHEN 6931169 THEN 0
  WHEN 6931170 THEN 0
  WHEN 6931171 THEN 0
  WHEN 6931172 THEN 0
  WHEN 6931173 THEN 0
  WHEN 6931174 THEN 0
  WHEN 6931175 THEN 0
  WHEN 6931176 THEN 0
  WHEN 6931177 THEN 0
  WHEN 6931178 THEN 0
  WHEN 6931179 THEN 0
  WHEN 6931180 THEN 0
  WHEN 6931181 THEN 0
  WHEN 6931182 THEN 0
  WHEN 6931183 THEN 0
  WHEN 6931184 THEN 0
  WHEN 6931185 THEN 0
  WHEN 6931189 THEN 0
  WHEN 6931190 THEN 0
  WHEN 6931191 THEN 0
  WHEN 6931192 THEN 0
  WHEN 6931193 THEN 0
  WHEN 6931194 THEN 0
  WHEN 6931195 THEN 0
  WHEN 6931196 THEN 0
  WHEN 6931197 THEN 0
  WHEN 6931198 THEN 0
  ELSE `rotation1` END
WHERE `guid` IN (6901511, 6901513, 6901514, 6901515, 6901516, 6901517, 6901518, 6903001, 6910001, 6920004, 6920005, 6920007, 6920008, 6920009, 6920010, 6920012, 6920013, 6920018, 6920019, 6920020, 6920021, 6920022, 6920023, 6920024, 6920025, 6920026, 6920029, 6920030, 6920031, 6920032, 6920033, 6920034, 6920035, 6920036, 6920037, 6920038, 6920039, 6920040, 6920041, 6920042, 6920043, 6920044, 6920045, 6920046, 6920047, 6920048, 6920049, 6920050, 6920051, 6920052, 6920053, 6920054, 6920055, 6920056, 6920057, 6920058, 6920059, 6920060, 6920063, 6920064, 6920065, 6920066, 6920067, 6920068, 6920069, 6920070, 6920072, 6920073, 6920074, 6920076, 6930001, 6930002, 6930003, 6930004, 6930005, 6930006, 6930007, 6930008, 6930009, 6930010, 6930011, 6930012, 6930013, 6930014, 6930015, 6930016, 6930017, 6930018, 6930019, 6930020, 6930021, 6930022, 6930023, 6930024, 6930025, 6930026, 6930027, 6930028, 6930029, 6930030, 6930031, 6930032, 6930033, 6930034, 6930035, 6930036, 6930037, 6930038, 6930039, 6930040, 6930041, 6930042, 6930043, 6930044, 6930045, 6930046, 6930047, 6930048, 6930049, 6930050, 6930051, 6930052, 6930053, 6930054, 6930055, 6930056, 6930057, 6930058, 6930059, 6930060, 6930061, 6930062, 6930063, 6930064, 6930065, 6930066, 6930067, 6930068, 6930069, 6930070, 6930071, 6930072, 6930073, 6930074, 6930075, 6930076, 6930077, 6930078, 6930079, 6930080, 6930081, 6930082, 6930083, 6930084, 6930085, 6930086, 6930087, 6930088, 6930089, 6930090, 6930091, 6930092, 6930093, 6930094, 6930095, 6930096, 6930097, 6930098, 6930099, 6930100, 6930101, 6930102, 6930103, 6930104, 6930105, 6930106, 6930107, 6930108, 6930109, 6930110, 6930111, 6930112, 6930113, 6930114, 6930115, 6930116, 6930117, 6930118, 6930119, 6930120, 6930121, 6930122, 6930123, 6930124, 6930125, 6930126, 6930127, 6930128, 6930129, 6930130, 6930131, 6930132, 6930133, 6930134, 6930135, 6930136, 6930137, 6930138, 6930139, 6930140, 6930141, 6930142, 6931001, 6931002, 6931003, 6931004, 6931005, 6931006, 6931007, 6931008, 6931009, 6931010, 6931011, 6931012, 6931013, 6931014, 6931015, 6931016, 6931017, 6931018, 6931019, 6931020, 6931021, 6931022, 6931023, 6931024, 6931025, 6931026, 6931027, 6931028, 6931029, 6931030, 6931031, 6931032, 6931033, 6931034, 6931035, 6931036, 6931037, 6931038, 6931039, 6931040, 6931041, 6931042, 6931043, 6931044, 6931045, 6931046, 6931047, 6931048, 6931049, 6931050, 6931051, 6931052, 6931053, 6931054, 6931055, 6931056, 6931057, 6931058, 6931059, 6931060, 6931061, 6931062, 6931063, 6931064, 6931065, 6931066, 6931067, 6931068, 6931069, 6931070, 6931071, 6931072, 6931073, 6931074, 6931075, 6931076, 6931077, 6931078, 6931079, 6931082, 6931083, 6931087, 6931088, 6931089, 6931090, 6931091, 6931092, 6931093, 6931094, 6931095, 6931096, 6931097, 6931098, 6931099, 6931100, 6931101, 6931103, 6931104, 6931105, 6931106, 6931107, 6931108, 6931109, 6931110, 6931111, 6931112, 6931113, 6931114, 6931115, 6931116, 6931117, 6931118, 6931119, 6931120, 6931121, 6931122, 6931123, 6931124, 6931125, 6931126, 6931127, 6931128, 6931129, 6931130, 6931131, 6931132, 6931133, 6931134, 6931135, 6931136, 6931137, 6931138, 6931139, 6931140, 6931141, 6931142, 6931143, 6931144, 6931145, 6931146, 6931147, 6931148, 6931149, 6931150, 6931151, 6931152, 6931153, 6931154, 6931155, 6931156, 6931157, 6931158, 6931159, 6931160, 6931161, 6931162, 6931163, 6931164, 6931165, 6931166, 6931167, 6931168, 6931169, 6931170, 6931171, 6931172, 6931173, 6931174, 6931175, 6931176, 6931177, 6931178, 6931179, 6931180, 6931181, 6931182, 6931183, 6931184, 6931185, 6931189, 6931190, 6931191, 6931192, 6931193, 6931194, 6931195, 6931196, 6931197, 6931198);

UPDATE `gameobject` SET `rotation2` = CASE `guid`
  WHEN 6901511 THEN -0.985556
  WHEN 6901513 THEN -1
  WHEN 6901514 THEN -0.975342
  WHEN 6901515 THEN -0.975342
  WHEN 6901516 THEN -0.975342
  WHEN 6901517 THEN -0.975342
  WHEN 6901518 THEN 0.981627
  WHEN 6903001 THEN 0.356873
  WHEN 6910001 THEN 0.304122
  WHEN 6920004 THEN 0.354484
  WHEN 6920005 THEN 0.579042
  WHEN 6920007 THEN 0.829109
  WHEN 6920008 THEN 0.697097
  WHEN 6920009 THEN 0.945443
  WHEN 6920010 THEN 0.692795
  WHEN 6920012 THEN 0.589726
  WHEN 6920013 THEN 0.304122
  WHEN 6920018 THEN 0.535563
  WHEN 6920019 THEN 0.386002
  WHEN 6920020 THEN 0.339991
  WHEN 6920021 THEN 0.757052
  WHEN 6920022 THEN 0.474313
  WHEN 6920023 THEN 0.98725
  WHEN 6920024 THEN 0.016576
  WHEN 6920025 THEN 0.99953
  WHEN 6920026 THEN 0.52608
  WHEN 6920029 THEN 0.845545
  WHEN 6920030 THEN 0.100097
  WHEN 6920031 THEN 0.976269
  WHEN 6920032 THEN 0.955318
  WHEN 6920033 THEN 0.957103
  WHEN 6920034 THEN 0.827306
  WHEN 6920035 THEN 0.91257
  WHEN 6920036 THEN 0.786386
  WHEN 6920037 THEN 0.936328
  WHEN 6920038 THEN 0.998255
  WHEN 6920039 THEN 0.297515
  WHEN 6920040 THEN 0.642667
  WHEN 6920041 THEN 0.866559
  WHEN 6920042 THEN 0.993425
  WHEN 6920043 THEN 0.994392
  WHEN 6920044 THEN 0.522067
  WHEN 6920045 THEN 0.965394
  WHEN 6920046 THEN 0.993746
  WHEN 6920047 THEN 0.35118
  WHEN 6920048 THEN 0.5258
  WHEN 6920049 THEN 0.995518
  WHEN 6920050 THEN 0.790162
  WHEN 6920051 THEN 0.940602
  WHEN 6920052 THEN 0.768481
  WHEN 6920053 THEN 0.285446
  WHEN 6920054 THEN 0.95266
  WHEN 6920055 THEN 0.89124
  WHEN 6920056 THEN 0.907073
  WHEN 6920057 THEN 0.449038
  WHEN 6920058 THEN 0.59501
  WHEN 6920059 THEN 0.326313
  WHEN 6920060 THEN 0.044831
  WHEN 6920063 THEN 0.955873
  WHEN 6920064 THEN 0.765012
  WHEN 6920065 THEN 0.291514
  WHEN 6920066 THEN 0.061418
  WHEN 6920067 THEN 0.786868
  WHEN 6920068 THEN 0.741035
  WHEN 6920069 THEN 0.957658
  WHEN 6920070 THEN 0.227638
  WHEN 6920072 THEN 0.545006
  WHEN 6920073 THEN 0.614503
  WHEN 6920074 THEN 0.859007
  WHEN 6920076 THEN 0.177219
  WHEN 6930001 THEN 0.285609
  WHEN 6930002 THEN 0.426078
  WHEN 6930003 THEN 0.767995
  WHEN 6930004 THEN 0.873035
  WHEN 6930005 THEN 0.41158
  WHEN 6930006 THEN 0.845546
  WHEN 6930007 THEN 0.820197
  WHEN 6930008 THEN 0.960637
  WHEN 6930009 THEN 0.780223
  WHEN 6930010 THEN 0.138318
  WHEN 6930011 THEN 0.980995
  WHEN 6930012 THEN 0.326426
  WHEN 6930013 THEN 0.796455
  WHEN 6930014 THEN 0.604769
  WHEN 6930015 THEN 0.96199
  WHEN 6930016 THEN 0.039267
  WHEN 6930017 THEN 0.808555
  WHEN 6930018 THEN 0.909783
  WHEN 6930019 THEN 0.99672
  WHEN 6930020 THEN 0.127295
  WHEN 6930021 THEN 0.851696
  WHEN 6930022 THEN 0.159853
  WHEN 6930023 THEN 0.940339
  WHEN 6930024 THEN 0.84207
  WHEN 6930025 THEN 0.851714
  WHEN 6930026 THEN 0.048858
  WHEN 6930027 THEN 0.696727
  WHEN 6930028 THEN 0.990119
  WHEN 6930029 THEN 0.115229
  WHEN 6930030 THEN 0.434108
  WHEN 6930031 THEN 0.793386
  WHEN 6930032 THEN 0.015238
  WHEN 6930033 THEN 0.429461
  WHEN 6930034 THEN 0.614298
  WHEN 6930035 THEN 0.921519
  WHEN 6930036 THEN 0.191221
  WHEN 6930037 THEN 0.930206
  WHEN 6930038 THEN 0.995143
  WHEN 6930039 THEN 0.363146
  WHEN 6930040 THEN 0.635106
  WHEN 6930041 THEN 0.373885
  WHEN 6930042 THEN 0.768109
  WHEN 6930043 THEN 0.212638
  WHEN 6930044 THEN 0.987716
  WHEN 6930045 THEN 0.959197
  WHEN 6930046 THEN 0.978131
  WHEN 6930047 THEN 0.081456
  WHEN 6930048 THEN 0.254057
  WHEN 6930049 THEN 0.211575
  WHEN 6930050 THEN 0.411144
  WHEN 6930051 THEN 0.864392
  WHEN 6930052 THEN 0.974777
  WHEN 6930053 THEN 0.88872
  WHEN 6930054 THEN 1
  WHEN 6930055 THEN 0.616277
  WHEN 6930056 THEN 0.424866
  WHEN 6930057 THEN 0.962567
  WHEN 6930058 THEN 0.477899
  WHEN 6930059 THEN 0.850528
  WHEN 6930060 THEN 0.989315
  WHEN 6930061 THEN 0.369985
  WHEN 6930062 THEN 0.202831
  WHEN 6930063 THEN 0.104577
  WHEN 6930064 THEN 0.661489
  WHEN 6930065 THEN 0.254755
  WHEN 6930066 THEN 0.205185
  WHEN 6930067 THEN 0.883256
  WHEN 6930068 THEN 0.002404
  WHEN 6930069 THEN 0.944025
  WHEN 6930070 THEN 0.493953
  WHEN 6930071 THEN 0.778325
  WHEN 6930072 THEN 0.211099
  WHEN 6930073 THEN 0.936668
  WHEN 6930074 THEN 0.921268
  WHEN 6930075 THEN 0.426698
  WHEN 6930076 THEN 0.044831
  WHEN 6930077 THEN 0.435059
  WHEN 6930078 THEN 0.929245
  WHEN 6930079 THEN 0.984185
  WHEN 6930080 THEN 0.897315
  WHEN 6930081 THEN 0.035177
  WHEN 6930082 THEN 0.880061
  WHEN 6930083 THEN 0.931332
  WHEN 6930084 THEN 0.999728
  WHEN 6930085 THEN 0.143933
  WHEN 6930086 THEN 0.342177
  WHEN 6930087 THEN 0.494804
  WHEN 6930088 THEN 0.996216
  WHEN 6930089 THEN 0.730344
  WHEN 6930090 THEN 0.656851
  WHEN 6930091 THEN 0.101471
  WHEN 6930092 THEN 0.985282
  WHEN 6930093 THEN 0.740484
  WHEN 6930094 THEN 0.951109
  WHEN 6930095 THEN 0.831039
  WHEN 6930096 THEN 0.005581
  WHEN 6930097 THEN 0.709779
  WHEN 6930098 THEN 0.9595
  WHEN 6930099 THEN 0.790652
  WHEN 6930100 THEN 0.597258
  WHEN 6930101 THEN 0.999383
  WHEN 6930102 THEN 0.775138
  WHEN 6930103 THEN 0.663532
  WHEN 6930104 THEN 0.008818
  WHEN 6930105 THEN 0.310891
  WHEN 6930106 THEN 0.946844
  WHEN 6930107 THEN 0.43524
  WHEN 6930108 THEN 0.531922
  WHEN 6930109 THEN 0.357766
  WHEN 6930110 THEN 0.423533
  WHEN 6930111 THEN 0.975207
  WHEN 6930112 THEN 0.982802
  WHEN 6930113 THEN 0.907996
  WHEN 6930114 THEN 0.626631
  WHEN 6930115 THEN 0.573108
  WHEN 6930116 THEN 0.450352
  WHEN 6930117 THEN 0.959198
  WHEN 6930118 THEN 0.075219
  WHEN 6930119 THEN 0.479254
  WHEN 6930120 THEN 0.994392
  WHEN 6930121 THEN 0.872609
  WHEN 6930122 THEN 0.99918
  WHEN 6930123 THEN 0.881487
  WHEN 6930124 THEN 0.996805
  WHEN 6930125 THEN 0.252895
  WHEN 6930126 THEN 0.733355
  WHEN 6930127 THEN 0.960405
  WHEN 6930128 THEN 0.661849
  WHEN 6930129 THEN 0.996839
  WHEN 6930130 THEN 0.997209
  WHEN 6930131 THEN 0.906798
  WHEN 6930132 THEN 0.449468
  WHEN 6930133 THEN 0.991374
  WHEN 6930134 THEN 0.152232
  WHEN 6930135 THEN 0.883481
  WHEN 6930136 THEN 0.344649
  WHEN 6930137 THEN 0.895349
  WHEN 6930138 THEN 0.816831
  WHEN 6930139 THEN 0.945434
  WHEN 6930140 THEN 0.870681
  WHEN 6930141 THEN 0.711616
  WHEN 6930142 THEN 0.395852
  WHEN 6931001 THEN 0.909783
  WHEN 6931002 THEN 0.426698
  WHEN 6931003 THEN 0.98832
  WHEN 6931004 THEN 0.98832
  WHEN 6931005 THEN 0.986549
  WHEN 6931006 THEN 0.044831
  WHEN 6931007 THEN 0.151107
  WHEN 6931008 THEN 0.884636
  WHEN 6931009 THEN 0.930139
  WHEN 6931010 THEN 0.783305
  WHEN 6931011 THEN 0.320158
  WHEN 6931012 THEN 0.204542
  WHEN 6931013 THEN 0.204542
  WHEN 6931014 THEN 0.364815
  WHEN 6931015 THEN 0.991551
  WHEN 6931016 THEN 0.604769
  WHEN 6931017 THEN 0.890335
  WHEN 6931018 THEN 0.936668
  WHEN 6931019 THEN 0.936668
  WHEN 6931020 THEN 0.936668
  WHEN 6931021 THEN 0.95266
  WHEN 6931022 THEN 0.426698
  WHEN 6931023 THEN 0.426698
  WHEN 6931024 THEN 0.426698
  WHEN 6931025 THEN 0.426698
  WHEN 6931026 THEN 0.98832
  WHEN 6931027 THEN 0.98832
  WHEN 6931028 THEN 0.81974
  WHEN 6931029 THEN 0.723486
  WHEN 6931030 THEN 0.314413
  WHEN 6931031 THEN 0.897392
  WHEN 6931032 THEN 0.68867
  WHEN 6931033 THEN 0.700125
  WHEN 6931034 THEN 0.897315
  WHEN 6931035 THEN 0.897315
  WHEN 6931036 THEN 0.856511
  WHEN 6931037 THEN 0.880061
  WHEN 6931038 THEN 0.880061
  WHEN 6931039 THEN 0.099531
  WHEN 6931040 THEN 0.999728
  WHEN 6931041 THEN 0.229475
  WHEN 6931042 THEN 0.652594
  WHEN 6931043 THEN 0.652594
  WHEN 6931044 THEN 0.999946
  WHEN 6931045 THEN 0.999946
  WHEN 6931046 THEN 0.12777
  WHEN 6931047 THEN 0.111934
  WHEN 6931048 THEN 0.730344
  WHEN 6931049 THEN 0.995956
  WHEN 6931050 THEN 0.00254
  WHEN 6931051 THEN 0.101471
  WHEN 6931052 THEN 0.574794
  WHEN 6931053 THEN 0.879831
  WHEN 6931054 THEN 0.997025
  WHEN 6931055 THEN 0.457296
  WHEN 6931056 THEN 0.099757
  WHEN 6931057 THEN 0.808866
  WHEN 6931058 THEN 0.67844
  WHEN 6931059 THEN 0.647342
  WHEN 6931060 THEN 0.99975
  WHEN 6931061 THEN 0.663532
  WHEN 6931062 THEN 0.442634
  WHEN 6931063 THEN 0.425575
  WHEN 6931064 THEN 0.304508
  WHEN 6931065 THEN 0.021304
  WHEN 6931066 THEN 0.99351
  WHEN 6931067 THEN 0.857159
  WHEN 6931068 THEN 0.781906
  WHEN 6931069 THEN 0.587444
  WHEN 6931070 THEN 0.583119
  WHEN 6931071 THEN 0.91257
  WHEN 6931072 THEN 0.91257
  WHEN 6931073 THEN 0.554135
  WHEN 6931074 THEN 0.554135
  WHEN 6931075 THEN 0.554135
  WHEN 6931076 THEN 0.995416
  WHEN 6931077 THEN 0.35118
  WHEN 6931078 THEN 0.910303
  WHEN 6931079 THEN 0.9915
  WHEN 6931082 THEN 0.973456
  WHEN 6931083 THEN 0.661128
  WHEN 6931087 THEN 0.991932
  WHEN 6931088 THEN 0.204542
  WHEN 6931089 THEN 0.529014
  WHEN 6931090 THEN 0.529014
  WHEN 6931091 THEN 0.468237
  WHEN 6931092 THEN 0.6367
  WHEN 6931093 THEN 0.984185
  WHEN 6931094 THEN 0.949118
  WHEN 6931095 THEN 0.197916
  WHEN 6931096 THEN 0.461899
  WHEN 6931097 THEN 0.509237
  WHEN 6931098 THEN 0.579042
  WHEN 6931099 THEN 0.661128
  WHEN 6931100 THEN 0.05284
  WHEN 6931101 THEN 0.305496
  WHEN 6931103 THEN 0.668998
  WHEN 6931104 THEN 0.476383
  WHEN 6931105 THEN 0.103142
  WHEN 6931106 THEN 0.579042
  WHEN 6931107 THEN 0.92741
  WHEN 6931108 THEN 0.529014
  WHEN 6931109 THEN 0.509681
  WHEN 6931110 THEN 0.949118
  WHEN 6931111 THEN 0.949118
  WHEN 6931112 THEN 0.999946
  WHEN 6931113 THEN 0.304508
  WHEN 6931114 THEN 0.304508
  WHEN 6931115 THEN 0.304508
  WHEN 6931116 THEN 0.554135
  WHEN 6931117 THEN 0.554135
  WHEN 6931118 THEN 0.554135
  WHEN 6931119 THEN 0.999644
  WHEN 6931120 THEN 0.999644
  WHEN 6931121 THEN 0.661128
  WHEN 6931122 THEN 0.05284
  WHEN 6931123 THEN 0.305496
  WHEN 6931124 THEN 0.529014
  WHEN 6931125 THEN 0.732184
  WHEN 6931126 THEN 0.983798
  WHEN 6931127 THEN 0.652594
  WHEN 6931128 THEN 0.950189
  WHEN 6931129 THEN 0.971352
  WHEN 6931130 THEN 0.212638
  WHEN 6931131 THEN 0.987716
  WHEN 6931132 THEN 0.304508
  WHEN 6931133 THEN 0.829109
  WHEN 6931134 THEN 0.930139
  WHEN 6931135 THEN 0.960637
  WHEN 6931136 THEN 0.529014
  WHEN 6931137 THEN 0.915969
  WHEN 6931138 THEN 0.500538
  WHEN 6931139 THEN 0.500538
  WHEN 6931140 THEN 0.099757
  WHEN 6931141 THEN 0.554135
  WHEN 6931142 THEN 0.167234
  WHEN 6931143 THEN 0.661128
  WHEN 6931144 THEN 0.500538
  WHEN 6931145 THEN 0.115229
  WHEN 6931146 THEN 0.101471
  WHEN 6931147 THEN 0.647342
  WHEN 6931148 THEN 0.096696
  WHEN 6931149 THEN 0.529014
  WHEN 6931150 THEN 0.449038
  WHEN 6931151 THEN 0.789605
  WHEN 6931152 THEN 0.294154
  WHEN 6931153 THEN 0.652594
  WHEN 6931154 THEN 0.758283
  WHEN 6931155 THEN 0.677725
  WHEN 6931156 THEN 0.769806
  WHEN 6931157 THEN 0.195393
  WHEN 6931158 THEN 0.987726
  WHEN 6931159 THEN 0.202123
  WHEN 6931160 THEN 0.648414
  WHEN 6931161 THEN 0.386002
  WHEN 6931162 THEN 0.144068
  WHEN 6931163 THEN 0.510144
  WHEN 6931164 THEN 0.055677
  WHEN 6931165 THEN 0.982802
  WHEN 6931166 THEN 0.953041
  WHEN 6931167 THEN 0.554135
  WHEN 6931168 THEN 0.554135
  WHEN 6931169 THEN 0.554135
  WHEN 6931170 THEN 0.554135
  WHEN 6931171 THEN 0.524675
  WHEN 6931172 THEN 0.976315
  WHEN 6931173 THEN 0.619051
  WHEN 6931174 THEN 0.151757
  WHEN 6931175 THEN 0.002404
  WHEN 6931176 THEN 0.150331
  WHEN 6931177 THEN 0.577081
  WHEN 6931178 THEN 0.767995
  WHEN 6931179 THEN 0.604769
  WHEN 6931180 THEN 0.500538
  WHEN 6931181 THEN 0.115229
  WHEN 6931182 THEN 0.101471
  WHEN 6931183 THEN 0.217562
  WHEN 6931184 THEN 0.036031
  WHEN 6931185 THEN 0.256149
  WHEN 6931189 THEN 0.161639
  WHEN 6931190 THEN 0.554127
  WHEN 6931191 THEN 0.142346
  WHEN 6931192 THEN 0.724379
  WHEN 6931193 THEN 0.854048
  WHEN 6931194 THEN 0.984547
  WHEN 6931195 THEN 0.038548
  WHEN 6931196 THEN 0.424866
  WHEN 6931197 THEN 0.758076
  WHEN 6931198 THEN 0.577081
  ELSE `rotation2` END
WHERE `guid` IN (6901511, 6901513, 6901514, 6901515, 6901516, 6901517, 6901518, 6903001, 6910001, 6920004, 6920005, 6920007, 6920008, 6920009, 6920010, 6920012, 6920013, 6920018, 6920019, 6920020, 6920021, 6920022, 6920023, 6920024, 6920025, 6920026, 6920029, 6920030, 6920031, 6920032, 6920033, 6920034, 6920035, 6920036, 6920037, 6920038, 6920039, 6920040, 6920041, 6920042, 6920043, 6920044, 6920045, 6920046, 6920047, 6920048, 6920049, 6920050, 6920051, 6920052, 6920053, 6920054, 6920055, 6920056, 6920057, 6920058, 6920059, 6920060, 6920063, 6920064, 6920065, 6920066, 6920067, 6920068, 6920069, 6920070, 6920072, 6920073, 6920074, 6920076, 6930001, 6930002, 6930003, 6930004, 6930005, 6930006, 6930007, 6930008, 6930009, 6930010, 6930011, 6930012, 6930013, 6930014, 6930015, 6930016, 6930017, 6930018, 6930019, 6930020, 6930021, 6930022, 6930023, 6930024, 6930025, 6930026, 6930027, 6930028, 6930029, 6930030, 6930031, 6930032, 6930033, 6930034, 6930035, 6930036, 6930037, 6930038, 6930039, 6930040, 6930041, 6930042, 6930043, 6930044, 6930045, 6930046, 6930047, 6930048, 6930049, 6930050, 6930051, 6930052, 6930053, 6930054, 6930055, 6930056, 6930057, 6930058, 6930059, 6930060, 6930061, 6930062, 6930063, 6930064, 6930065, 6930066, 6930067, 6930068, 6930069, 6930070, 6930071, 6930072, 6930073, 6930074, 6930075, 6930076, 6930077, 6930078, 6930079, 6930080, 6930081, 6930082, 6930083, 6930084, 6930085, 6930086, 6930087, 6930088, 6930089, 6930090, 6930091, 6930092, 6930093, 6930094, 6930095, 6930096, 6930097, 6930098, 6930099, 6930100, 6930101, 6930102, 6930103, 6930104, 6930105, 6930106, 6930107, 6930108, 6930109, 6930110, 6930111, 6930112, 6930113, 6930114, 6930115, 6930116, 6930117, 6930118, 6930119, 6930120, 6930121, 6930122, 6930123, 6930124, 6930125, 6930126, 6930127, 6930128, 6930129, 6930130, 6930131, 6930132, 6930133, 6930134, 6930135, 6930136, 6930137, 6930138, 6930139, 6930140, 6930141, 6930142, 6931001, 6931002, 6931003, 6931004, 6931005, 6931006, 6931007, 6931008, 6931009, 6931010, 6931011, 6931012, 6931013, 6931014, 6931015, 6931016, 6931017, 6931018, 6931019, 6931020, 6931021, 6931022, 6931023, 6931024, 6931025, 6931026, 6931027, 6931028, 6931029, 6931030, 6931031, 6931032, 6931033, 6931034, 6931035, 6931036, 6931037, 6931038, 6931039, 6931040, 6931041, 6931042, 6931043, 6931044, 6931045, 6931046, 6931047, 6931048, 6931049, 6931050, 6931051, 6931052, 6931053, 6931054, 6931055, 6931056, 6931057, 6931058, 6931059, 6931060, 6931061, 6931062, 6931063, 6931064, 6931065, 6931066, 6931067, 6931068, 6931069, 6931070, 6931071, 6931072, 6931073, 6931074, 6931075, 6931076, 6931077, 6931078, 6931079, 6931082, 6931083, 6931087, 6931088, 6931089, 6931090, 6931091, 6931092, 6931093, 6931094, 6931095, 6931096, 6931097, 6931098, 6931099, 6931100, 6931101, 6931103, 6931104, 6931105, 6931106, 6931107, 6931108, 6931109, 6931110, 6931111, 6931112, 6931113, 6931114, 6931115, 6931116, 6931117, 6931118, 6931119, 6931120, 6931121, 6931122, 6931123, 6931124, 6931125, 6931126, 6931127, 6931128, 6931129, 6931130, 6931131, 6931132, 6931133, 6931134, 6931135, 6931136, 6931137, 6931138, 6931139, 6931140, 6931141, 6931142, 6931143, 6931144, 6931145, 6931146, 6931147, 6931148, 6931149, 6931150, 6931151, 6931152, 6931153, 6931154, 6931155, 6931156, 6931157, 6931158, 6931159, 6931160, 6931161, 6931162, 6931163, 6931164, 6931165, 6931166, 6931167, 6931168, 6931169, 6931170, 6931171, 6931172, 6931173, 6931174, 6931175, 6931176, 6931177, 6931178, 6931179, 6931180, 6931181, 6931182, 6931183, 6931184, 6931185, 6931189, 6931190, 6931191, 6931192, 6931193, 6931194, 6931195, 6931196, 6931197, 6931198);

UPDATE `gameobject` SET `rotation3` = CASE `guid`
  WHEN 6901511 THEN 0.169352
  WHEN 6901513 THEN 0
  WHEN 6901514 THEN 0.2207
  WHEN 6901515 THEN 0.2207
  WHEN 6901516 THEN 0.2207
  WHEN 6901517 THEN 0.2207
  WHEN 6901518 THEN 0.190812
  WHEN 6903001 THEN 0.934153
  WHEN 6910001 THEN 0.952633
  WHEN 6920004 THEN 0.935062
  WHEN 6920005 THEN -0.815298
  WHEN 6920007 THEN -0.559087
  WHEN 6920008 THEN -0.716977
  WHEN 6920009 THEN 0.325787
  WHEN 6920010 THEN -0.721134
  WHEN 6920012 THEN -0.807603
  WHEN 6920013 THEN 0.952633
  WHEN 6920018 THEN -0.844495
  WHEN 6920019 THEN 0.922498
  WHEN 6920020 THEN 0.940429
  WHEN 6920021 THEN 0.653354
  WHEN 6920022 THEN 0.880356
  WHEN 6920023 THEN -0.159176
  WHEN 6920024 THEN -0.999863
  WHEN 6920025 THEN 0.030651
  WHEN 6920026 THEN 0.850435
  WHEN 6920029 THEN -0.533904
  WHEN 6920030 THEN 0.994978
  WHEN 6920031 THEN 0.216563
  WHEN 6920032 THEN -0.295578
  WHEN 6920033 THEN -0.289747
  WHEN 6920034 THEN 0.561751
  WHEN 6920035 THEN 0.408922
  WHEN 6920036 THEN -0.617736
  WHEN 6920037 THEN -0.351127
  WHEN 6920038 THEN 0.059054
  WHEN 6920039 THEN 0.954717
  WHEN 6920040 THEN -0.766146
  WHEN 6920041 THEN 0.499075
  WHEN 6920042 THEN 0.114483
  WHEN 6920043 THEN -0.105755
  WHEN 6920044 THEN 0.852905
  WHEN 6920045 THEN 0.260797
  WHEN 6920046 THEN 0.111662
  WHEN 6920047 THEN 0.936308
  WHEN 6920048 THEN -0.850608
  WHEN 6920049 THEN 0.094573
  WHEN 6920050 THEN -0.612897
  WHEN 6920051 THEN -0.33951
  WHEN 6920052 THEN -0.639873
  WHEN 6920053 THEN 0.958395
  WHEN 6920054 THEN -0.304037
  WHEN 6920055 THEN 0.453532
  WHEN 6920056 THEN -0.420973
  WHEN 6920057 THEN 0.893512
  WHEN 6920058 THEN 0.803718
  WHEN 6920059 THEN -0.945262
  WHEN 6920060 THEN -0.998995
  WHEN 6920063 THEN -0.29378
  WHEN 6920064 THEN 0.644016
  WHEN 6920065 THEN 0.956567
  WHEN 6920066 THEN -0.998112
  WHEN 6920067 THEN 0.617121
  WHEN 6920068 THEN 0.671466
  WHEN 6920069 THEN 0.287907
  WHEN 6920070 THEN 0.973746
  WHEN 6920072 THEN 0.838432
  WHEN 6920073 THEN 0.788915
  WHEN 6920074 THEN 0.511964
  WHEN 6920076 THEN 0.984171
  WHEN 6930001 THEN -0.958346
  WHEN 6930002 THEN -0.904686
  WHEN 6930003 THEN -0.640456
  WHEN 6930004 THEN -0.487658
  WHEN 6930005 THEN -0.911374
  WHEN 6930006 THEN -0.533903
  WHEN 6930007 THEN 0.572081
  WHEN 6930008 THEN 0.277806
  WHEN 6930009 THEN -0.625501
  WHEN 6930010 THEN 0.990388
  WHEN 6930011 THEN -0.194031
  WHEN 6930012 THEN -0.945223
  WHEN 6930013 THEN -0.604697
  WHEN 6930014 THEN -0.796401
  WHEN 6930015 THEN 0.273083
  WHEN 6930016 THEN -0.999229
  WHEN 6930017 THEN -0.58842
  WHEN 6930018 THEN 0.415084
  WHEN 6930019 THEN 0.080929
  WHEN 6930020 THEN 0.991865
  WHEN 6930021 THEN 0.524035
  WHEN 6930022 THEN 0.987141
  WHEN 6930023 THEN -0.340239
  WHEN 6930024 THEN 0.539368
  WHEN 6930025 THEN 0.524006
  WHEN 6930026 THEN 0.998806
  WHEN 6930027 THEN 0.717336
  WHEN 6930028 THEN 0.140231
  WHEN 6930029 THEN -0.993339
  WHEN 6930030 THEN 0.900861
  WHEN 6930031 THEN -0.608719
  WHEN 6930032 THEN 0.999884
  WHEN 6930033 THEN -0.903085
  WHEN 6930034 THEN 0.789074
  WHEN 6930035 THEN -0.388334
  WHEN 6930036 THEN -0.981547
  WHEN 6930037 THEN -0.367038
  WHEN 6930038 THEN 0.098436
  WHEN 6930039 THEN 0.931732
  WHEN 6930040 THEN 0.772425
  WHEN 6930041 THEN -0.927475
  WHEN 6930042 THEN 0.640319
  WHEN 6930043 THEN -0.977131
  WHEN 6930044 THEN -0.156263
  WHEN 6930045 THEN -0.28274
  WHEN 6930046 THEN -0.20799
  WHEN 6930047 THEN -0.996677
  WHEN 6930048 THEN 0.967189
  WHEN 6930049 THEN 0.977362
  WHEN 6930050 THEN -0.911571
  WHEN 6930051 THEN -0.502818
  WHEN 6930052 THEN -0.223182
  WHEN 6930053 THEN -0.45845
  WHEN 6930054 THEN 0.000526
  WHEN 6930055 THEN -0.78753
  WHEN 6930056 THEN -0.905256
  WHEN 6930057 THEN -0.271042
  WHEN 6930058 THEN 0.878415
  WHEN 6930059 THEN -0.52593
  WHEN 6930060 THEN 0.145791
  WHEN 6930061 THEN -0.929038
  WHEN 6930062 THEN -0.979214
  WHEN 6930063 THEN 0.994517
  WHEN 6930064 THEN 0.749955
  WHEN 6930065 THEN 0.967006
  WHEN 6930066 THEN 0.978723
  WHEN 6930067 THEN 0.468891
  WHEN 6930068 THEN 0.999997
  WHEN 6930069 THEN -0.329874
  WHEN 6930070 THEN 0.869488
  WHEN 6930071 THEN 0.627862
  WHEN 6930072 THEN 0.977465
  WHEN 6930073 THEN -0.350219
  WHEN 6930074 THEN 0.388928
  WHEN 6930075 THEN 0.904394
  WHEN 6930076 THEN -0.998995
  WHEN 6930077 THEN 0.900402
  WHEN 6930078 THEN -0.369463
  WHEN 6930079 THEN -0.177145
  WHEN 6930080 THEN -0.441391
  WHEN 6930081 THEN 0.999381
  WHEN 6930082 THEN 0.47486
  WHEN 6930083 THEN 0.364171
  WHEN 6930084 THEN -0.023339
  WHEN 6930085 THEN -0.989587
  WHEN 6930086 THEN 0.939635
  WHEN 6930087 THEN 0.869005
  WHEN 6930088 THEN 0.086914
  WHEN 6930089 THEN 0.683079
  WHEN 6930090 THEN -0.75402
  WHEN 6930091 THEN 0.994838
  WHEN 6930092 THEN -0.170937
  WHEN 6930093 THEN 0.672074
  WHEN 6930094 THEN -0.308854
  WHEN 6930095 THEN 0.556214
  WHEN 6930096 THEN 0.999984
  WHEN 6930097 THEN 0.704425
  WHEN 6930098 THEN -0.28171
  WHEN 6930099 THEN 0.612266
  WHEN 6930100 THEN 0.802049
  WHEN 6930101 THEN 0.035128
  WHEN 6930102 THEN -0.631792
  WHEN 6930103 THEN 0.748148
  WHEN 6930104 THEN 0.999961
  WHEN 6930105 THEN -0.950446
  WHEN 6930106 THEN 0.321693
  WHEN 6930107 THEN -0.900314
  WHEN 6930108 THEN -0.846793
  WHEN 6930109 THEN 0.933811
  WHEN 6930110 THEN -0.90588
  WHEN 6930111 THEN -0.221293
  WHEN 6930112 THEN -0.184661
  WHEN 6930113 THEN -0.418978
  WHEN 6930114 THEN 0.779316
  WHEN 6930115 THEN 0.81948
  WHEN 6930116 THEN -0.892851
  WHEN 6930117 THEN 0.282737
  WHEN 6930118 THEN -0.997167
  WHEN 6930119 THEN -0.877676
  WHEN 6930120 THEN -0.105755
  WHEN 6930121 THEN 0.48842
  WHEN 6930122 THEN 0.040493
  WHEN 6930123 THEN 0.472209
  WHEN 6930124 THEN -0.079879
  WHEN 6930125 THEN -0.967494
  WHEN 6930126 THEN -0.679846
  WHEN 6930127 THEN 0.278608
  WHEN 6930128 THEN 0.749637
  WHEN 6930129 THEN -0.079454
  WHEN 6930130 THEN 0.074661
  WHEN 6930131 THEN 0.421565
  WHEN 6930132 THEN 0.893297
  WHEN 6930133 THEN -0.131063
  WHEN 6930134 THEN -0.988345
  WHEN 6930135 THEN 0.468467
  WHEN 6930136 THEN -0.938732
  WHEN 6930137 THEN 0.445366
  WHEN 6930138 THEN -0.576877
  WHEN 6930139 THEN -0.325813
  WHEN 6930140 THEN -0.491848
  WHEN 6930141 THEN 0.702568
  WHEN 6930142 THEN -0.918314
  WHEN 6931001 THEN 0.415084
  WHEN 6931002 THEN 0.904394
  WHEN 6931003 THEN 0.152391
  WHEN 6931004 THEN 0.152391
  WHEN 6931005 THEN 0.163463
  WHEN 6931006 THEN -0.998995
  WHEN 6931007 THEN -0.988517
  WHEN 6931008 THEN -0.466282
  WHEN 6931009 THEN -0.367208
  WHEN 6931010 THEN 0.621638
  WHEN 6931011 THEN 0.947364
  WHEN 6931012 THEN -0.978858
  WHEN 6931013 THEN -0.978858
  WHEN 6931014 THEN -0.93108
  WHEN 6931015 THEN -0.129716
  WHEN 6931016 THEN -0.796401
  WHEN 6931017 THEN 0.455306
  WHEN 6931018 THEN -0.350219
  WHEN 6931019 THEN -0.350219
  WHEN 6931020 THEN -0.350219
  WHEN 6931021 THEN -0.304037
  WHEN 6931022 THEN 0.904394
  WHEN 6931023 THEN 0.904394
  WHEN 6931024 THEN 0.904394
  WHEN 6931025 THEN 0.904394
  WHEN 6931026 THEN 0.152391
  WHEN 6931027 THEN 0.152391
  WHEN 6931028 THEN -0.572735
  WHEN 6931029 THEN 0.690339
  WHEN 6931030 THEN -0.949286
  WHEN 6931031 THEN -0.441233
  WHEN 6931032 THEN 0.725075
  WHEN 6931033 THEN 0.71402
  WHEN 6931034 THEN -0.441391
  WHEN 6931035 THEN -0.441391
  WHEN 6931036 THEN 0.516129
  WHEN 6931037 THEN 0.47486
  WHEN 6931038 THEN 0.47486
  WHEN 6931039 THEN 0.995034
  WHEN 6931040 THEN -0.023339
  WHEN 6931041 THEN 0.973315
  WHEN 6931042 THEN 0.757707
  WHEN 6931043 THEN 0.757707
  WHEN 6931044 THEN 0.010422
  WHEN 6931045 THEN 0.010422
  WHEN 6931046 THEN -0.991804
  WHEN 6931047 THEN 0.993716
  WHEN 6931048 THEN 0.683079
  WHEN 6931049 THEN 0.089848
  WHEN 6931050 THEN 0.999997
  WHEN 6931051 THEN 0.994838
  WHEN 6931052 THEN 0.818298
  WHEN 6931053 THEN 0.475286
  WHEN 6931054 THEN -0.077078
  WHEN 6931055 THEN -0.889315
  WHEN 6931056 THEN -0.995012
  WHEN 6931057 THEN 0.587993
  WHEN 6931058 THEN -0.734656
  WHEN 6931059 THEN 0.762199
  WHEN 6931060 THEN -0.022365
  WHEN 6931061 THEN 0.748148
  WHEN 6931062 THEN -0.896702
  WHEN 6931063 THEN -0.904923
  WHEN 6931064 THEN -0.95251
  WHEN 6931065 THEN -0.999773
  WHEN 6931066 THEN -0.113743
  WHEN 6931067 THEN 0.515052
  WHEN 6931068 THEN -0.623397
  WHEN 6931069 THEN 0.809264
  WHEN 6931070 THEN 0.812387
  WHEN 6931071 THEN 0.408922
  WHEN 6931072 THEN 0.408922
  WHEN 6931073 THEN -0.832427
  WHEN 6931074 THEN -0.832427
  WHEN 6931075 THEN -0.832427
  WHEN 6931076 THEN 0.095636
  WHEN 6931077 THEN 0.936308
  WHEN 6931078 THEN -0.413942
  WHEN 6931079 THEN -0.13011
  WHEN 6931082 THEN 0.228875
  WHEN 6931083 THEN 0.750273
  WHEN 6931087 THEN 0.126773
  WHEN 6931088 THEN -0.978858
  WHEN 6931089 THEN -0.848613
  WHEN 6931090 THEN -0.848613
  WHEN 6931091 THEN 0.883603
  WHEN 6931092 THEN 0.771112
  WHEN 6931093 THEN -0.177145
  WHEN 6931094 THEN 0.314921
  WHEN 6931095 THEN 0.980219
  WHEN 6931096 THEN 0.886932
  WHEN 6931097 THEN 0.860626
  WHEN 6931098 THEN -0.815298
  WHEN 6931099 THEN 0.750273
  WHEN 6931100 THEN 0.998603
  WHEN 6931101 THEN 0.952193
  WHEN 6931103 THEN -0.743265
  WHEN 6931104 THEN -0.879238
  WHEN 6931105 THEN 0.994667
  WHEN 6931106 THEN -0.815298
  WHEN 6931107 THEN -0.374046
  WHEN 6931108 THEN -0.848613
  WHEN 6931109 THEN 0.860364
  WHEN 6931110 THEN 0.314921
  WHEN 6931111 THEN 0.314921
  WHEN 6931112 THEN 0.010422
  WHEN 6931113 THEN -0.95251
  WHEN 6931114 THEN -0.95251
  WHEN 6931115 THEN -0.95251
  WHEN 6931116 THEN -0.832427
  WHEN 6931117 THEN -0.832427
  WHEN 6931118 THEN -0.832427
  WHEN 6931119 THEN -0.02667
  WHEN 6931120 THEN -0.02667
  WHEN 6931121 THEN 0.750273
  WHEN 6931122 THEN 0.998603
  WHEN 6931123 THEN 0.952193
  WHEN 6931124 THEN -0.848613
  WHEN 6931125 THEN 0.681106
  WHEN 6931126 THEN 0.179282
  WHEN 6931127 THEN 0.757707
  WHEN 6931128 THEN 0.311673
  WHEN 6931129 THEN 0.237644
  WHEN 6931130 THEN -0.977131
  WHEN 6931131 THEN -0.156263
  WHEN 6931132 THEN -0.95251
  WHEN 6931133 THEN -0.559087
  WHEN 6931134 THEN -0.367208
  WHEN 6931135 THEN 0.277806
  WHEN 6931136 THEN -0.848613
  WHEN 6931137 THEN -0.40125
  WHEN 6931138 THEN 0.865715
  WHEN 6931139 THEN 0.865715
  WHEN 6931140 THEN -0.995012
  WHEN 6931141 THEN -0.832427
  WHEN 6931142 THEN 0.985917
  WHEN 6931143 THEN 0.750273
  WHEN 6931144 THEN 0.865715
  WHEN 6931145 THEN -0.993339
  WHEN 6931146 THEN 0.994838
  WHEN 6931147 THEN 0.762199
  WHEN 6931148 THEN -0.995314
  WHEN 6931149 THEN -0.848613
  WHEN 6931150 THEN 0.893512
  WHEN 6931151 THEN -0.613616
  WHEN 6931152 THEN -0.955758
  WHEN 6931153 THEN 0.757707
  WHEN 6931154 THEN 0.651925
  WHEN 6931155 THEN -0.735316
  WHEN 6931156 THEN -0.638278
  WHEN 6931157 THEN 0.980725
  WHEN 6931158 THEN 0.156199
  WHEN 6931159 THEN 0.97936
  WHEN 6931160 THEN -0.761288
  WHEN 6931161 THEN 0.922498
  WHEN 6931162 THEN -0.989568
  WHEN 6931163 THEN -0.860089
  WHEN 6931164 THEN 0.998449
  WHEN 6931165 THEN -0.184661
  WHEN 6931166 THEN 0.302841
  WHEN 6931167 THEN -0.832427
  WHEN 6931168 THEN -0.832427
  WHEN 6931169 THEN -0.832427
  WHEN 6931170 THEN -0.832427
  WHEN 6931171 THEN -0.851303
  WHEN 6931172 THEN 0.216355
  WHEN 6931173 THEN -0.785351
  WHEN 6931174 THEN -0.988418
  WHEN 6931175 THEN 0.999997
  WHEN 6931176 THEN -0.988636
  WHEN 6931177 THEN -0.816687
  WHEN 6931178 THEN -0.640456
  WHEN 6931179 THEN -0.796401
  WHEN 6931180 THEN 0.865715
  WHEN 6931181 THEN -0.993339
  WHEN 6931182 THEN 0.994838
  WHEN 6931183 THEN -0.976047
  WHEN 6931184 THEN -0.999351
  WHEN 6931185 THEN 0.966637
  WHEN 6931189 THEN 0.98685
  WHEN 6931190 THEN 0.832432
  WHEN 6931191 THEN -0.989817
  WHEN 6931192 THEN -0.689402
  WHEN 6931193 THEN 0.520194
  WHEN 6931194 THEN 0.175119
  WHEN 6931195 THEN 0.999257
  WHEN 6931196 THEN -0.905256
  WHEN 6931197 THEN -0.652166
  WHEN 6931198 THEN -0.816687
  ELSE `rotation3` END
WHERE `guid` IN (6901511, 6901513, 6901514, 6901515, 6901516, 6901517, 6901518, 6903001, 6910001, 6920004, 6920005, 6920007, 6920008, 6920009, 6920010, 6920012, 6920013, 6920018, 6920019, 6920020, 6920021, 6920022, 6920023, 6920024, 6920025, 6920026, 6920029, 6920030, 6920031, 6920032, 6920033, 6920034, 6920035, 6920036, 6920037, 6920038, 6920039, 6920040, 6920041, 6920042, 6920043, 6920044, 6920045, 6920046, 6920047, 6920048, 6920049, 6920050, 6920051, 6920052, 6920053, 6920054, 6920055, 6920056, 6920057, 6920058, 6920059, 6920060, 6920063, 6920064, 6920065, 6920066, 6920067, 6920068, 6920069, 6920070, 6920072, 6920073, 6920074, 6920076, 6930001, 6930002, 6930003, 6930004, 6930005, 6930006, 6930007, 6930008, 6930009, 6930010, 6930011, 6930012, 6930013, 6930014, 6930015, 6930016, 6930017, 6930018, 6930019, 6930020, 6930021, 6930022, 6930023, 6930024, 6930025, 6930026, 6930027, 6930028, 6930029, 6930030, 6930031, 6930032, 6930033, 6930034, 6930035, 6930036, 6930037, 6930038, 6930039, 6930040, 6930041, 6930042, 6930043, 6930044, 6930045, 6930046, 6930047, 6930048, 6930049, 6930050, 6930051, 6930052, 6930053, 6930054, 6930055, 6930056, 6930057, 6930058, 6930059, 6930060, 6930061, 6930062, 6930063, 6930064, 6930065, 6930066, 6930067, 6930068, 6930069, 6930070, 6930071, 6930072, 6930073, 6930074, 6930075, 6930076, 6930077, 6930078, 6930079, 6930080, 6930081, 6930082, 6930083, 6930084, 6930085, 6930086, 6930087, 6930088, 6930089, 6930090, 6930091, 6930092, 6930093, 6930094, 6930095, 6930096, 6930097, 6930098, 6930099, 6930100, 6930101, 6930102, 6930103, 6930104, 6930105, 6930106, 6930107, 6930108, 6930109, 6930110, 6930111, 6930112, 6930113, 6930114, 6930115, 6930116, 6930117, 6930118, 6930119, 6930120, 6930121, 6930122, 6930123, 6930124, 6930125, 6930126, 6930127, 6930128, 6930129, 6930130, 6930131, 6930132, 6930133, 6930134, 6930135, 6930136, 6930137, 6930138, 6930139, 6930140, 6930141, 6930142, 6931001, 6931002, 6931003, 6931004, 6931005, 6931006, 6931007, 6931008, 6931009, 6931010, 6931011, 6931012, 6931013, 6931014, 6931015, 6931016, 6931017, 6931018, 6931019, 6931020, 6931021, 6931022, 6931023, 6931024, 6931025, 6931026, 6931027, 6931028, 6931029, 6931030, 6931031, 6931032, 6931033, 6931034, 6931035, 6931036, 6931037, 6931038, 6931039, 6931040, 6931041, 6931042, 6931043, 6931044, 6931045, 6931046, 6931047, 6931048, 6931049, 6931050, 6931051, 6931052, 6931053, 6931054, 6931055, 6931056, 6931057, 6931058, 6931059, 6931060, 6931061, 6931062, 6931063, 6931064, 6931065, 6931066, 6931067, 6931068, 6931069, 6931070, 6931071, 6931072, 6931073, 6931074, 6931075, 6931076, 6931077, 6931078, 6931079, 6931082, 6931083, 6931087, 6931088, 6931089, 6931090, 6931091, 6931092, 6931093, 6931094, 6931095, 6931096, 6931097, 6931098, 6931099, 6931100, 6931101, 6931103, 6931104, 6931105, 6931106, 6931107, 6931108, 6931109, 6931110, 6931111, 6931112, 6931113, 6931114, 6931115, 6931116, 6931117, 6931118, 6931119, 6931120, 6931121, 6931122, 6931123, 6931124, 6931125, 6931126, 6931127, 6931128, 6931129, 6931130, 6931131, 6931132, 6931133, 6931134, 6931135, 6931136, 6931137, 6931138, 6931139, 6931140, 6931141, 6931142, 6931143, 6931144, 6931145, 6931146, 6931147, 6931148, 6931149, 6931150, 6931151, 6931152, 6931153, 6931154, 6931155, 6931156, 6931157, 6931158, 6931159, 6931160, 6931161, 6931162, 6931163, 6931164, 6931165, 6931166, 6931167, 6931168, 6931169, 6931170, 6931171, 6931172, 6931173, 6931174, 6931175, 6931176, 6931177, 6931178, 6931179, 6931180, 6931181, 6931182, 6931183, 6931184, 6931185, 6931189, 6931190, 6931191, 6931192, 6931193, 6931194, 6931195, 6931196, 6931197, 6931198);
