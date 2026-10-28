-- Red Cloud Mesa loses the Templar's Hidden Statue (9301301), its walk-in credit marker and the quest A Quiet Life
-- (200082): Jax Dawnsoar no longer gives or takes it. The templates stay, unused.
DELETE FROM `gameobject` WHERE `guid` = 7912501 AND `id` = 9301301;

DELETE FROM `smart_scripts` WHERE `entryorguid` = -9003916 AND `source_type` = 0;
DELETE FROM `creature` WHERE `guid` = 9003916 AND `id` = 685037;

DELETE FROM `creature_queststarter` WHERE `quest` = 200082;
DELETE FROM `creature_questender` WHERE `quest` = 200082;
