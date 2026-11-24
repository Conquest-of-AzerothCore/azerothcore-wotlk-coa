-- #12860: the Worldforged Sandfury Ritual Mace spot (6970030) spawned the placeholder 9900029 (Shiny Hammer); use the realm template 515840, which had no spawn.
UPDATE `gameobject` SET `id` = 515840 WHERE `guid` = 6970030 AND `id` = 9900029;
