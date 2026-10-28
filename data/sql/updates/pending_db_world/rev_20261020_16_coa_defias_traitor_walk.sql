-- The Defias Brotherhood (#7595): the Defias Traitor ran down the Sentinel Hill tower instead
-- of walking, which reads as flying at the start of the escort.
--
-- Path 467 starts on the upper terrace (z 55.21) and descends to the road. The escort start
-- forced movement is RUN (2); switch it to WALK (1) so he walks down the terrace and the road
-- instead of running down the slope, which is what the report describes as flying.

UPDATE `smart_scripts` SET `action_param1` = 1
WHERE `entryorguid` = 467 AND `source_type` = 0 AND `id` = 3 AND `action_type` = 53;

UPDATE `waypoints` SET `position_z` = 50.13 WHERE `entry` = 467 AND `pointid` = 4;
