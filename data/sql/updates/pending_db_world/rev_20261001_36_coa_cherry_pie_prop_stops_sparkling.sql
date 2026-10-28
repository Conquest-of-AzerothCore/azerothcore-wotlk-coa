-- Joshua's Cherry Pie: the table kept sparkling after the pie was looted. The Cherry Pie prop beside the pickup
-- (guid 6942562) carried the worldforged_pickup ScriptName, so the module made it sparkle for everyone, and a
-- prop can never be looted. The pickup 6942560 alone carries the marker.
UPDATE `gameobject` SET `ScriptName` = '' WHERE `guid` = 6942562 AND `id` = 90635;
