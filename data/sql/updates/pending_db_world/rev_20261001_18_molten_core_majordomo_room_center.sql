-- K6c: move the Ragnaros portal's static spawn (rev_20261001_08, guid 9000601) to the Majordomo
-- room's actual geometric middle - the centroid of Majordomo's own 8-add summon ring
-- (creature_summon_groups, entry 12018 group 1) - instead of Majordomo's own battle position.
-- Confirmed live on slot 3 (`.go xyz 753.3 -1174.4 -119.1 409`): the point holds at this exact z,
-- no fall-through, valid ground. Orientation/rotation/ScriptName/destination are unchanged.
-- Late-sorting on purpose: must sort after rev_20261001_08's own INSERT.
UPDATE `gameobject` SET `position_x` = 753.3, `position_y` = -1174.4, `position_z` = -119.1
WHERE `guid` = 9000601;
