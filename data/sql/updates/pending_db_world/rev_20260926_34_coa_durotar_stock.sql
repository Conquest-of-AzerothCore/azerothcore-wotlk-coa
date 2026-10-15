-- CoA Durotar: open-zone stock rows, holiday rows, graveyard links for the caves and CoA props.
-- Gameobject guids 7917320-7917379.

-- ---------------------------------------------------------------------------
-- 1. Quest NPCs and recorded moves
-- ---------------------------------------------------------------------------
-- Lar Prowltusk (4699): QuestSuperTrack 786 turn-in, on his Sen'jin walk between the rocks and the huts.
UPDATE `creature` SET `position_x` = -816.95, `position_y` = -4843.78, `position_z` = 21.332 WHERE `guid` = 4699 AND `id` = 3140;
-- His two pauses by the rocks move onto the turn-in point; the rest of the walk is stock.
UPDATE `waypoint_data` SET `position_x` = -816.95, `position_y` = -4843.78, `position_z` = 21.332 WHERE `id` = 46990 AND `point` IN (5, 21);
-- Master Gadrin (6462): QuestSuperTrack turn-in, beside his hut.
UPDATE `creature` SET `position_x` = -827.85, `position_y` = -4920.23, `position_z` = 19.592 WHERE `guid` = 6462 AND `id` = 3188;
-- Fizzle Darkstorm (6455): recorded CoA point (atlas) in the Thunder Ridge camp, facing the campfire.
UPDATE `creature` SET `position_x` = 872.43, `position_y` = -4186.39, `position_z` = -13.953, `orientation` = 3.13 WHERE `guid` = 6455 AND `id` = 3203;
-- Swine (10433): was on the log beside CoA's log machine; south-west corner of the pen between the fence and the
-- log.
UPDATE `creature` SET `position_x` = 740, `position_y` = -4275.5, `position_z` = 17.864 WHERE `guid` = 10433 AND `id` = 10685;
-- Swine (12119): was inside CoA's log machine; east side of the pen, clear of the machine and the fence.
UPDATE `creature` SET `position_x` = 750.5, `position_y` = -4271.5, `position_z` = 17.311 WHERE `guid` = 12119 AND `id` = 10685;

-- ---------------------------------------------------------------------------
-- 2. Holiday rows
-- ---------------------------------------------------------------------------
-- Pilgrim's Bounty hosts at the Orgrimmar gate.
-- Bountiful Feast Hostess (240526): QuestSuperTrack 14065 turn-in, facing the feast table 240525.
UPDATE `creature` SET `position_x` = 1292.92, `position_y` = -4406.65, `position_z` = 26.416, `orientation` = 5.06 WHERE `guid` = 240526 AND `id` = 34654;
-- Francis Eaton (240535): QuestSuperTrack 14040/14043/14047 turn-in, facing the feast table 240525.
UPDATE `creature` SET `position_x` = 1295.7, `position_y` = -4416.83, `position_z` = 26.651, `orientation` = 1.72 WHERE `guid` = 240535 AND `id` = 34679;
-- Ondani Greatmill (240534): QuestSuperTrack 14061/14062 turn-in, facing the feast table 240525.
UPDATE `creature` SET `position_x` = 1300.64, `position_y` = -4407.67, `position_z` = 26.539, `orientation` = 3.83 WHERE `guid` = 240534 AND `id` = 34713;

-- Hallow's End fires on the ridge north of Razor Hill; same x and y unless moved.
-- Headless Horseman - Fire (DND) (240017): sank 0.4.
UPDATE `creature` SET `position_z` = 28.076 WHERE `guid` = 240017 AND `id` = 23537;
-- Fire Effigy (43049): sank 0.5.
UPDATE `gameobject` SET `position_z` = 28.073 WHERE `guid` = 43049 AND `id` = 186720;
-- Headless Horseman - Fire (DND) (86588): sank 1.2.
UPDATE `creature` SET `position_z` = 30.174 WHERE `guid` = 86588 AND `id` = 23537;
-- Fire Effigy (66919): sank 1.3.
UPDATE `gameobject` SET `position_z` = 29.867 WHERE `guid` = 66919 AND `id` = 186720;
-- Headless Horseman - Fire (DND) (12738): floated 3.0.
UPDATE `creature` SET `position_z` = 33.781 WHERE `guid` = 12738 AND `id` = 23537;
-- Fire Effigy (313): floated 2.9.
UPDATE `gameobject` SET `position_z` = 33.772 WHERE `guid` = 313 AND `id` = 186720;
-- Headless Horseman - Fire (DND) (86587): buried 3.4 under CoA's raised ridge; CoA's recorded fire point (atlas)
-- on the ridge, 6 yd west.
UPDATE `creature` SET `position_x` = 284.37, `position_y` = -4571.27, `position_z` = 39.11 WHERE `guid` = 86587 AND `id` = 23537;
-- Fire Effigy (312): with its fire 86587.
UPDATE `gameobject` SET `position_x` = 284.37, `position_y` = -4571.27, `position_z` = 39.11 WHERE `guid` = 312 AND `id` = 186720;
-- Hay Bale 1 (420371): sunk inside the Azzar Faire wagon; open ground north of the wagon.
UPDATE `gameobject` SET `position_x` = 1333, `position_y` = -4348.5, `position_z` = 28.165 WHERE `guid` = 420371 AND `id` = 180700;
-- Hay Bale 1 (420372): against the Azzar Faire wagon's side; open ground north of the wagon, 4.7 yd from the
-- other bale.
UPDATE `gameobject` SET `position_x` = 1331.5, `position_y` = -4344, `position_z` = 28.495 WHERE `guid` = 420372 AND `id` = 180700;

-- ---------------------------------------------------------------------------
-- 3. Graveyard links
-- ---------------------------------------------------------------------------
-- The caves are parent-0 areas: 365 and 10205 use the valley graveyard, 371 and 10123 the Durotar list.
DELETE FROM `graveyard_zone` WHERE (`ID`, `GhostZone`) IN ((709, 365), (32, 371), (649, 371), (709, 371), (850, 371), (32, 10123), (649, 10123), (709, 10123), (850, 10123), (709, 10205));
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES
(709, 365, 0, 'Burning Blade Coven - Durotar, Valley of Trials GY'),
(32, 371, 0, 'Dustwind Cave - Durotar, Razor Hill GY'),
(649, 371, 67, 'Dustwind Cave - Durotar, Sen''jin Village GY'),
(709, 371, 67, 'Dustwind Cave - Durotar, Valley of Trials GY'),
(850, 371, 67, 'Dustwind Cave - Durotar, Northern Durotar GY'),
(32, 10123, 0, 'Skull Rock - Durotar, Razor Hill GY'),
(649, 10123, 67, 'Skull Rock - Durotar, Sen''jin Village GY'),
(709, 10123, 67, 'Skull Rock - Durotar, Valley of Trials GY'),
(850, 10123, 67, 'Skull Rock - Durotar, Northern Durotar GY'),
(709, 10205, 0, 'Sinister Lair - Durotar, Valley of Trials GY');

-- ---------------------------------------------------------------------------
-- 4. CoA props
-- ---------------------------------------------------------------------------
-- Kolkar tent 90601 held back: it would cover the worldforged Shabby Knife 6941806.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(90592, 5, 1014012, 'Blood pool RPG PROP', '', 'Inspecting', 0.15, 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(90595, 5, 7241, 'Wagon RPG PROP', '', 'Inspecting', 0.75, 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(90602, 5, 1053888, 'Seat RPG PROP', '', 'Inspecting', 0.5, 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(90603, 5, 192, 'Bonfire RPG PROP', '', 'Inspecting', 1, 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(90604, 5, 500023, 'Grunt Shoulder RPG PROP', '', 'Inspecting', 1.5, 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(90605, 5, 174789, 'Grunt Axe RPG PROP', '', 'Inspecting', 1.5, 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(95669, 5, 1015795, 'Skeleton RPG Prop', '', '', 1.35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(96376, 5, 6370, 'Torch RPG Prop', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(96500, 5, 328, 'Warlock Shrine RPG Prop', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(3288421, 5, 1026565, 'Hay Bale', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `gameobject` WHERE `guid` IN (7917321, 7917322, 7917323, 7917324, 7917325, 7917326, 7917327, 7917328, 7917329, 7917330, 7917331) OR `guid` BETWEEN 7917320 AND 7917379;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7917321, 90602, 1, 0, 0, 1, 1, -830.65, -4556.21, 49.76, 4.83, 0, 0, 0.664327, -0.747442, 180, 100, 1, '', 'CoA Durotar: Kolkar camp, stump seat facing the bonfire'),
(7917322, 90603, 1, 0, 0, 1, 1, -830.2, -4560.05, 49.68, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Durotar: Kolkar camp bonfire'),
(7917323, 90604, 1, 0, 0, 1, 1, -832.02, -4553.38, 50.39, 4.98, 0, 0, 0.606454, -0.795119, 180, 100, 1, '', 'CoA Durotar: Kolkar camp, dropped shoulder guard by the Shabby Knife'),
(7917324, 90605, 1, 0, 0, 1, 1, -830.25, -4554.87, 50.33, 4.72, 0, 0, 0.704411, -0.709793, 180, 100, 1, '', 'CoA Durotar: Kolkar camp, dropped axe beside the stump seat'),
(7917325, 90592, 1, 0, 0, 1, 1, -1366.65, -5141.34, 1.6, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Durotar: Echo Isles blood pool'),
(7917326, 90595, 1, 0, 0, 1, 1, -792.74, -4753.02, 25.21, 4.05, 0, 0, 0.898611, -0.438747, 180, 100, 1, '', 'CoA Durotar: wagon above the spilled Lost Goods, pointing at them'),
(7917327, 95669, 1, 0, 0, 1, 1, -296.9, -4334.41, 56.56, 0.93, 0, 0, 0.448423, 0.893822, 180, 100, 1, '', 'CoA Durotar: skeleton on the cactus slope, reaching for the Apprentice Staff'),
(7917328, 96376, 1, 0, 0, 1, 1, 51.79, -4791.55, 21.96, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Durotar: torch beside the warlock shrine'),
(7917329, 96500, 1, 0, 0, 1, 1, 51.78, -4788.83, 22.06, 4.71, 0, 0, 0.707951, -0.706262, 180, 100, 1, '', 'CoA Durotar: warlock shrine backed onto the rock ridge, facing the open ground'),
(7917330, 182255, 1, 0, 0, 1, 1, -617.66, -4617.43, 40.855, 5.63, 0, 0, 0.320818, -0.947141, 180, 100, 1, '', 'CoA Durotar: Wyvern Roost at node 343, facing the flight point'),
(7917331, 3288421, 1, 0, 0, 1, 1, -618.73, -4612.96, 41.34, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Durotar: hay bale beside the Wyvern Roost');
