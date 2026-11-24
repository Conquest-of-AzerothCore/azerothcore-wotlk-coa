-- #13340: Worldforged Tauren Crate (Muck Trudgers) had two spawns; the reporter confirmed the one inside the tent (6942290), the one by the tree goes.
DELETE FROM `gameobject` WHERE `guid` = 6941973 AND `id` = 515947 AND `map` = 1;
