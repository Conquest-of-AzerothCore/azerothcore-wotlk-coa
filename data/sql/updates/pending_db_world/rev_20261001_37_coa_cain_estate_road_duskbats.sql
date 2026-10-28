-- The road up the mountainside to the Cain estate had Duskbats on it (playtest). The five within 3 yd of the
-- road (TIRISFALLSTONEROAD01 weight >= 0.5 in the client ADT; they wander 10 yd) are removed; the nearest that
-- stay are 15.6 and 17.8 yd off it, and 15 Duskbats remain around it.
DELETE FROM `creature` WHERE `id` = 1512 AND `guid` IN (41897, 41900, 41902, 44731, 38317);
