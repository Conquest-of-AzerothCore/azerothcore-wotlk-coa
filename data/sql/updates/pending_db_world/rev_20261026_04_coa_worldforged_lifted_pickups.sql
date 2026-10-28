-- Six more Worldforged pickups the LootCollector alignment lifted 60 yd or more into the air (#9079, #9071).
-- rev_20261014_95_worldforged_lootcollector_alignment moved each less than 30 yd across but changed its height by
-- 73 to 165 yd; #9079 reports Poison Unguent Extract floating in the air. As in
-- rev_20261026_00_coa_worldforged_cave_and_floor_pickups, each goes back to the position and rotation it held
-- before that pass.

-- Victim's Empty jar (Poison Unguent Extract)
UPDATE `gameobject` SET `map` = 0, `zoneId` = 0, `areaId` = 0, `position_x` = 1421.49, `position_y` = 1929.81, `position_z` = 9.11821, `orientation` = 4.59301, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.748029, `rotation3` = -0.663666 WHERE `guid` = 6940904 AND `id` = 90327;
-- Jane's Hat (Jane's Lucky Hat)
UPDATE `gameobject` SET `map` = 1, `zoneId` = 0, `areaId` = 0, `position_x` = -6262, `position_y` = -2000.8, `position_z` = -261.251, `orientation` = 1.63765, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.730344, `rotation3` = 0.68308 WHERE `guid` = 6941881 AND `id` = 96173;
-- Fallen Warrior's Axe (Honed Steel Axe)
UPDATE `gameobject` SET `map` = 0, `zoneId` = 0, `areaId` = 0, `position_x` = -11225.3, `position_y` = -179.775, `position_z` = 5.1963, `orientation` = 1.05044, `rotation0` = -0.374892, `rotation1` = 0.217255, `rotation2` = 0.451891, `rotation3` = 0.779776 WHERE `guid` = 6940459 AND `id` = 95942;
-- Witherbark Headsmasher (Witherbark Headsmasher)
UPDATE `gameobject` SET `map` = 0, `zoneId` = 0, `areaId` = 0, `position_x` = -2057.8, `position_y` = -3284.8, `position_z` = 67.41, `orientation` = 2.64262, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.969039, `rotation3` = 0.246906 WHERE `guid` = 6941347 AND `id` = 95850;
-- Malgin's Barback (Malgin's Barback)
UPDATE `gameobject` SET `map` = 1, `zoneId` = 0, `areaId` = 0, `position_x` = -4084, `position_y` = -2402.3, `position_z` = 126.197, `orientation` = 4.77466, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.684751, `rotation3` = -0.728777 WHERE `guid` = 6941944 AND `id` = 97117;
-- Harpy Feather (The Tickler)
UPDATE `gameobject` SET `map` = 1, `zoneId` = 0, `areaId` = 0, `position_x` = -5614.6, `position_y` = -1608.7, `position_z` = 13.326, `orientation` = 4.97216, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.609566, `rotation3` = -0.792736 WHERE `guid` = 6942304 AND `id` = 515571;
-- Shadowshard Shield pickup (254310), Maraudon purple caverns (#9071): the alignment set it 40 yd above the cavern floor.
UPDATE `gameobject` SET `map` = 1, `zoneId` = 0, `areaId` = 0, `position_x` = -1169.4, `position_y` = 2956.4, `position_z` = 64.5, `orientation` = 3.42067, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.99028, `rotation3` = -0.139086 WHERE `guid` = 6942158 AND `id` = 254310;
