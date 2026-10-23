-- Worldforged Shadewell Stabber (item 824384) at Shadewell Spring, Elwynn Forest: keep only the original Murloc Tool pickup
-- (520066, guid 6900733). The Northshire revamp added a second Murloc Tool on the same spot (guid 7500149) and the
-- LootCollector alignment added a third pickup of the same item, Brambleblade Blade (9900025, guid 6970024), 10 yd away.
DELETE FROM `gameobject` WHERE (`guid` = 7500149 AND `id` = 520066) OR (`guid` = 6970024 AND `id` = 9900025);
