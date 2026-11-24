-- #12854: the Worldforged Ancient Wagon Wheel spot (6970028) spawned the placeholder 9900027 (Sturdy Coffin Lid); use the realm template 515791, which had no spawn.
UPDATE `gameobject` SET `id` = 515791 WHERE `guid` = 6970028 AND `id` = 9900027;
