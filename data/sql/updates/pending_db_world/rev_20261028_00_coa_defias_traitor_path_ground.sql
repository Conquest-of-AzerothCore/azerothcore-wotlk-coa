-- The Defias Brotherhood: on the way down from Sentinel Hill the Defias Traitor (467) walked 1 to 6 yd above the
-- slope and dropped back to the road, as his escort points 2-9 sat above the ground (point 4 most, raised to 50.13 by
-- rev_20261020_16). Each point now sits on the ground.
UPDATE `waypoints` SET `position_z` = 52.9 WHERE `entry` = 467 AND `pointid` = 2;
UPDATE `waypoints` SET `position_z` = 47.25 WHERE `entry` = 467 AND `pointid` = 3;
UPDATE `waypoints` SET `position_z` = 44.25 WHERE `entry` = 467 AND `pointid` = 4;
UPDATE `waypoints` SET `position_z` = 41.56 WHERE `entry` = 467 AND `pointid` = 5;
UPDATE `waypoints` SET `position_z` = 37.87 WHERE `entry` = 467 AND `pointid` = 6;
UPDATE `waypoints` SET `position_z` = 36.2 WHERE `entry` = 467 AND `pointid` = 7;
UPDATE `waypoints` SET `position_z` = 35.8 WHERE `entry` = 467 AND `pointid` = 8;
UPDATE `waypoints` SET `position_z` = 35.4 WHERE `entry` = 467 AND `pointid` = 9;
