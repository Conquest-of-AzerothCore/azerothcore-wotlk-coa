-- Dungeon Finder: Sunken Temple starts in the corridor before the Sanctum of the Fallen God, as on Ascension.
DELETE FROM `lfg_dungeon_template` WHERE `dungeonId` IN (28, 1718, 2718);
INSERT INTO `lfg_dungeon_template` (`dungeonId`, `name`, `position_x`, `position_y`, `position_z`, `orientation`, `VerifiedBuild`) VALUES
(28, 'Sunken Temple', -323.8665, 95.221275, -91.13821, 3.1585755, 0),
(1718, 'Sunken Temple', -323.8665, 95.221275, -91.13821, 3.1585755, 0),
(2718, 'Sunken Temple', -323.8665, 95.221275, -91.13821, 3.1585755, 0);
