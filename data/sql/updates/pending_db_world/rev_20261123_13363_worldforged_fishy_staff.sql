-- #13363: Worldforged A "Fishy" Staff had an in-game placement in Eastern Plaguelands from 2026-09-24; its realm location is Hillsbrad Foothills (6940856), so the stray copy goes.
DELETE FROM `gameobject` WHERE `guid` = 6960026 AND `id` = 95947 AND `map` = 0;
