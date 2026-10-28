-- #7794: Worldforged Shoulderguards of Zin-Malor (guid 6942173, entry 254459, a multi-storey structure
-- in Azshara) hovers 4.6 yd above the floor the reporter stands on. Lower it to that floor; XY is
-- already over the same floor polygon.
UPDATE `gameobject` SET `position_z` = 134.25 WHERE `guid` = 6942173 AND `id` = 254459;
