-- Frosty Crabs on the Frozen Shore are wildlife: level 22-23 like the troggs and trolls around them, neutral beasts that
-- can be attacked (faction 7, as the Scadeald fox and wolf); they were a level 1 placeholder friendly to everyone.
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23, `faction` = 7, `type` = 1 WHERE `entry` = 164394;

-- The Smart Tank beside Norhi stands where the user put it in game (2026-10-14).
UPDATE `creature` SET `position_x` = -6626.7866, `position_y` = -135.3987, `position_z` = 570.549, `orientation` = 3.4398 WHERE `guid` = 9962240 AND `id` = 165513;
