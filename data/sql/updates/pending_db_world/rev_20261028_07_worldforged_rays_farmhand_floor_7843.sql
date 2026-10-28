-- #7843: Worldforged Ray's Farmhand pickup (guid 6940938, entry 95946, Farmer Ray's house, Hillsbrad
-- Fields) floats 1.3-1.4 yd above the house floor. Set it to Farmer Ray's own floor height.
UPDATE `gameobject` SET `position_z` = 60.37 WHERE `guid` = 6940938 AND `id` = 95946;
