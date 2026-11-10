-- ----------------------------------------------------------------------------
-- Worldforged pickup: raise Anchorfoot Greaves (The Hinterlands) to the ground (#9596)
-- ----------------------------------------------------------------------------
-- Guid 6940042 (gameobject entry for the Anchorfoot Greaves pickup, item 515692/515885) sat
-- 2.18 yd below the stock terrain at its XY, read with the harness's spawn_ground_gap/
-- point_ground_gap tooling against the 3.3.5a Hinterlands map tile (#9596). The fix raises it
-- to the measured ground height; XY, orientation and entry are unchanged.
UPDATE `gameobject` SET `position_z` = 93.340 WHERE `guid` = 6940042;
