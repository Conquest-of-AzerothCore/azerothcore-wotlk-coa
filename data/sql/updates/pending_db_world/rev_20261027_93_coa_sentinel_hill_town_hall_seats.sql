-- Sentinel Hill town hall: seated NPCs sat on the wall sill or inside the church pews, and the Normans stood in the
-- east wall pew. Seat them on the pews facing away from each backrest, with the root just above the floor as for the
-- stock Pew chairs (medium sit state; heights tuned in game), lay the sleeper just above the pew collision, and stand
-- the Normans in front.
-- The front pew is turned away from the podium, so Sally Vernal waits for the sermon on the second pew.

UPDATE `creature` SET `position_x` = -10694.41, `position_y` = 958.11, `position_z` = 38.67, `orientation` = 1.1504,
  `Comment` = 'Everard Handor (town hall, seated on the east wall pew)' WHERE `guid` = 9950149;
UPDATE `creature` SET `position_x` = -10693.21, `position_y` = 958.56, `position_z` = 38.47, `orientation` = 3.66,
  `Comment` = 'Melissa Norman (town hall, standing in front of Everard Handor)' WHERE `guid` = 9950150;
UPDATE `creature` SET `position_x` = -10692.52, `position_y` = 958.13, `position_z` = 38.47, `orientation` = 3.31,
  `Comment` = 'Ethan Norman (town hall, beside Melissa Norman)' WHERE `guid` = 9950151;
UPDATE `creature` SET `position_x` = -10689.10, `position_y` = 969.65, `position_z` = 38.62, `orientation` = 4.0995,
  `Comment` = 'Willow Brelor (town hall, seated on the west wall pew)' WHERE `guid` = 9950152;
UPDATE `creature` SET `position_x` = -10686.26, `position_y` = 968.62, `position_z` = 39.45, `orientation` = 2.68,
  `Comment` = 'Displaced Farmer (town hall, asleep on the west wall pew)' WHERE `guid` = 9950140;
UPDATE `creature` SET `position_x` = -10697.15, `position_y` = 969.12, `position_z` = 38.72, `orientation` = 2.69,
  `Comment` = 'Sally Vernal (town hall, seated at the right end of the second pew)' WHERE `guid` = 9950153;

DELETE FROM `creature_addon` WHERE `guid` = 9950153;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
  `auras`) VALUES
(9950153, 0, 0, 5, 1, 0, 0, NULL);
