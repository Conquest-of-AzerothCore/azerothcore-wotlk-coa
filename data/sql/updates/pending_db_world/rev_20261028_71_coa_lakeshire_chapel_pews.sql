-- Lakeshire chapel (#9224): rev_20261015_20 seats the congregation Cateline, Vernell, Emelyne and Marinus
-- (9950411-9950414) in the front pews facing the altar, but the client chapel has no pews, so they sat on thin
-- air. Four Wooden Benches (151955, the Northshire Abbey pew) now stand under them, two rows on each side of the
-- nave, facing the altar like the congregation. Spots are estimated from the seated NPCs; heights are the chapel floor.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9001377 AND 9001380;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9001377, 151955, 0, 0, 0, 1, 1, -9425.5, -2082.5, 67.55, 1.5708, 0, 0, 0.707107, 0.707107, 300, 0, 1, '', NULL, 'Lakeshire chapel pew, east front row'),
(9001378, 151955, 0, 0, 0, 1, 1, -9425.5, -2086.5, 67.55, 1.5708, 0, 0, 0.707107, 0.707107, 300, 0, 1, '', NULL, 'Lakeshire chapel pew, east back row'),
(9001379, 151955, 0, 0, 0, 1, 1, -9432.0, -2082.5, 67.55, 1.5708, 0, 0, 0.707107, 0.707107, 300, 0, 1, '', NULL, 'Lakeshire chapel pew, west front row'),
(9001380, 151955, 0, 0, 0, 1, 1, -9432.0, -2086.5, 67.55, 1.5708, 0, 0, 0.707107, 0.707107, 300, 0, 1, '', NULL, 'Lakeshire chapel pew, west back row');
