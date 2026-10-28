-- Worldforged Champion's Band (#9075): the realm-map terrain fallback placed the pickup (guid
-- 6941553) 14.7 yd below and away from its recorded spot on the Orcrefugetower2 balcony, where the
-- Durotar Warborn NPCs stand (rev_20260926_33). Restore the realm's own stored position on the
-- balcony.
UPDATE `gameobject` SET `position_x` = 168.986, `position_y` = -3966.811, `position_z` = 50.227
WHERE `guid` = 6941553 AND `id` = 517370 AND `map` = 1
  AND `position_x` BETWEEN 182.6 AND 183.6 AND `position_y` BETWEEN -3971.4 AND -3970.4;
