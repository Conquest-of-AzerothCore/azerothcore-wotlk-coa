-- Apex Bounty: The Stormfang -- playtest corrections #2
--
-- 102946 is a player Chain Lightning variant that is not casting from the
-- Stormfang/Conduits in play. Use native Chain Lightning 421, which is proven
-- on NPC casters.
-- 102934 Storm Bolt requires a thrown weapon; replace it with custom Lightning
-- Bolt 100621 so the boss actually fires a bolt.
-- Rake 100331 is kept, but its target is changed from "random not top" to a
-- normal random hostile target.
-- Storm Conduits are normal rank 0 creatures, not elite.
-- The Stormfang is fixed in place so the two conduits can spawn deterministically
-- at its left and right.
-- Stormcall conduits spawn at fixed offset points instead of stacking.

START TRANSACTION;

UPDATE `creature_template`
   SET `rank` = 0,
       `MovementType` = 0
 WHERE `entry` = 9916202;

UPDATE `creature_template`
   SET `MovementType` = 0
 WHERE `entry` = 9916201;

UPDATE `creature`
   SET `MovementType` = 0,
       `wander_distance` = 0
 WHERE `guid` = 9916503;

UPDATE `smart_scripts`
   SET `action_param1` = 421
 WHERE `entryorguid` IN (9916201, 9916202)
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 102946;

UPDATE `smart_scripts`
   SET `action_param1` = 100621
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 102934;

UPDATE `smart_scripts`
   SET `target_type` = 5,
       `target_param1` = 40,
       `target_param2` = 1
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 100331;

-- Left of the spawn.
UPDATE `smart_scripts`
   SET `target_type` = 8,
       `target_x` = -160.771,
       `target_y` = -2879.57,
       `target_z` = 117.037,
       `target_o` = 0
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `id` IN (22, 42, 57);

-- Right of the spawn.
UPDATE `smart_scripts`
   SET `target_type` = 8,
       `target_x` = -150.771,
       `target_y` = -2879.57,
       `target_z` = 117.037,
       `target_o` = 0
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `id` IN (23, 43, 58);

COMMIT;
