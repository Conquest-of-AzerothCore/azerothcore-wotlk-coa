-- Pale Reach (Ascension Conquest of Azeroth) world content, generated from the repaired local world DB.
-- NOT TESTED in a fresh database: see the PR description.

DELETE FROM `game_graveyard` WHERE `ID` IN (6091,6092,6093,6094,6095,6096,6097,6098);
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6091, 0, -7563.83, 1160.78, 166.41, 'Pale Reach, Scadeald - Cresthairn'),
(6092, 0, -7739.44, 600.77, 136.72, 'Pale Reach, Scadeald - Dunshire'),
(6093, 0, -7591.89, -341.8, 379.36, 'Pale Reach, Scadeald - Andraste\'s Fortress'),
(6094, 0, -7285.25, 649.85, 335.3, 'Pale Reach, Scadeald - Scadeald Heights'),
(6095, 0, -7433.38, 147.31, 183.9, 'Pale Reach, Scadeald - Namarien'),
(6096, 0, -6926.82, 36.16, 433.74, 'Pale Reach, Scadeald - Ealdfrost Foothills'),
(6097, 0, -6359.04, -449.44, 650.08, 'Pale Reach, Scadeald - Snowveil'),
(6098, 0, -6878.31, 1750.68, 317.98, 'Pale Reach, Scadeald - Hallow Wind Hanging Abbey');

DELETE FROM `graveyard_zone` WHERE (`ID`,`GhostZone`) IN ((6074,10305),(6091,10302),(6092,10302),(6093,10302),(6094,10302),(6095,10302),(6096,10302),(6096,10306),(6097,10302),(6097,10306),(6098,10302));
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6074, 10305, 0, 'Shadewell - Elwynn Forest, Shadewell Spring'),
(6091, 10302, 0, 'Pale Reach - Scadeald - Cresthairn'),
(6092, 10302, 0, 'Pale Reach - Scadeald - Dunshire'),
(6093, 10302, 0, 'Pale Reach - Scadeald - Andraste\'s Fortress'),
(6094, 10302, 0, 'Pale Reach - Scadeald - Scadeald Heights'),
(6095, 10302, 0, 'Pale Reach - Scadeald - Namarien'),
(6096, 10302, 0, 'Pale Reach - Scadeald - Ealdfrost Foothills'),
(6096, 10306, 0, 'Dun Kazad - Scadeald - Ealdfrost Foothills'),
(6097, 10302, 0, 'Pale Reach - Scadeald - Snowveil'),
(6097, 10306, 0, 'Dun Kazad - Scadeald - Snowveil'),
(6098, 10302, 0, 'Pale Reach - Scadeald - Hallow Wind Hanging Abbey');

DELETE FROM `skill_fishing_base_level` WHERE `entry` IN (10302,10305);
INSERT INTO `skill_fishing_base_level` (`entry`, `skill`) VALUES
(10302, 55),
(10305, 55);
