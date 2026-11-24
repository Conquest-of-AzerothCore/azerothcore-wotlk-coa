-- Hallow Wind Eagle at the abbey entrance: its 15 yd wander reached the ground under the bridge, where the ground-only
-- eagle could not path back to players on the deck and reset. Within 5 yd every point keeps the deck, as for most
-- of its kin.
UPDATE `creature` SET `wander_distance` = 5 WHERE `guid` = 9962114 AND `id` = 164195;
