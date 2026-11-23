-- #12858: the Worldforged Zazera's Wand spot (6970033) spawned the placeholder 9900031 (Rusty Shotgun); use the realm template 254577, which had no spawn.
UPDATE `gameobject` SET `id` = 254577 WHERE `guid` = 6970033 AND `id` = 9900031;
