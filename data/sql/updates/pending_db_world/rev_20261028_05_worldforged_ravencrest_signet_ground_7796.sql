-- #7796: Worldforged Ravencrest Signet (guid 6942064, entry 254434, Ravencrest Monument, Azshara) is
-- 0.85 yd under the ground at its own spawn XY. Set it to the stock terrain height there.
UPDATE `gameobject` SET `position_z` = 110.33 WHERE `guid` = 6942064 AND `id` = 254434;
