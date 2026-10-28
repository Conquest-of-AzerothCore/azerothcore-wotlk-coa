-- The Wanted Poster at the Westbrook Garrison crossroads (156561, spawn 26846) also offers Wanted: "Hogger" on Ascension.
DELETE FROM `gameobject_queststarter` WHERE `id` = 156561 AND `quest` = 176;
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES (156561, 176);
