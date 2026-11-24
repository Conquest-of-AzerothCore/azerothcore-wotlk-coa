-- #11971: Worldforged Leyline Research (254502) had a second spawn in Mulgore (6941908) from the map pass; the
-- item's realm location is elsewhere, so the stray copy goes.
DELETE FROM `gameobject` WHERE `guid` = 6941908 AND `id` = 254502 AND `map` = 1;
