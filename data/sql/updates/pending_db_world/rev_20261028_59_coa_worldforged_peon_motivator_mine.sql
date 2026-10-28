-- Worldforged Peon Motivator (#9085): the realm-map terrain fallback placed the pickup (guid
-- 6942024) on the hill above the Horde mine room (Md_Hordemine1Room.wmo), 27 yd horizontally and
-- 36-38 yd above the room's floor. Restore the realm's own recorded sighting, inside the room near
-- the LootCollector pin.
UPDATE `gameobject` SET `position_x` = -526.307, `position_y` = -3166.890, `position_z` = 98.685
WHERE `guid` = 6942024 AND `id` = 95837 AND `map` = 1
  AND `position_x` BETWEEN -550.1 AND -549.1 AND `position_y` BETWEEN -3153.7 AND -3152.7;
