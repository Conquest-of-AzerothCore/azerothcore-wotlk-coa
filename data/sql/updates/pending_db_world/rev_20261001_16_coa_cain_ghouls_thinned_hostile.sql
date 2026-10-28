-- Cain Family Estate Ghouls 161752: 17 -> 6 (playtest: too many, overlapping, three inside the manor), and hostile
-- (faction 14). The six kept are all Questie sighting points (rev_20260926_10), chosen farthest-first so they stand
-- at least 17.6 yd apart: great hall, south room, south lawn, east field, behind the manor, lakeside garden. The
-- eleven removed are the east hall's, the second south-room and south-lawn points and the eight fill spawns. The
-- Friends We Make Along the Way 1660029 needs 5 (180 s respawn); its ghoul map area (rev_20261001_08) is redrawn
-- around the six.
UPDATE `creature_template` SET `faction` = 14 WHERE `entry` = 161752;
DELETE FROM `creature` WHERE `id` = 161752 AND `guid` IN (9010051, 9010053, 9010055, 9010059, 9010060, 9010061, 9010062, 9010063,
    9010064, 9010065, 9010066);
DELETE FROM `quest_poi_points` WHERE `QuestID` = 1660029 AND `Idx1` = 2;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(1660029, 2, 0, 1904, 1980),
(1660029, 2, 1, 1926, 1917),
(1660029, 2, 2, 1963, 1932),
(1660029, 2, 3, 1924, 1990);
