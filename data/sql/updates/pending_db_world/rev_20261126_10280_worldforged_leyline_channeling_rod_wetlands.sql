-- #10280: Worldforged Leyline Channeling Rod (item 521267, object 518321 Westfall Supply Cache) belongs solely in
-- Westfall (guid 6940698, matching realm dump 6900688 and CoA sidekick map).
-- Remove the stray Wetlands duplicate (guid 6940699) imported from multi-realm pins.
DELETE FROM `gameobject` WHERE `guid` = 6940699 AND `id` = 518321 AND `map` = 0;
