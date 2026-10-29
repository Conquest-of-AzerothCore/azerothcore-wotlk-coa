-- The LootCollector alignment pass inserted two Ancient Wagon Wheel pickups (template 9900027) 24 yd
-- apart in Tanaris, both in sight of the reporter's position ("double WF on my coordinates"). The
-- atlas-objects sighting of the original pickup corroborates guid 6970028; drop the extra copy 6970027
-- so only one wheel stands there (#9228).
DELETE FROM `gameobject` WHERE `guid` = 6970027 AND `id` = 9900027 AND `map` = 1
  AND `position_x` BETWEEN -8727.5 AND -8726.5 AND `position_y` BETWEEN -4289.5 AND -4288.5;
