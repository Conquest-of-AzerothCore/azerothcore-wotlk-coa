-- Worldforged Fel Infused Band (pickup 6941728, Felfire Hill, Ashenvale) sat 1.24 yd under the ground at its
-- realm-map x/y (#11356): the realm-map pass moved x/y 8.4 yd east and kept the old z 108.343. The server measures
-- the ground there at 109.58, so lift only z.
UPDATE `gameobject` SET `position_z` = 109.58
WHERE `guid` = 6941728 AND `id` = 90394 AND `map` = 1
  AND `position_z` BETWEEN 108.33 AND 108.36;
