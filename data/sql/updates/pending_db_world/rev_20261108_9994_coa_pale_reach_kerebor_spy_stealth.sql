-- Kerebor Spies (164269) in Shadewell walk around stealthed on the realm: RIEMlZSgbQw 4:01:56 ("Are these spies just
-- like invisible walking around? Oh, they are."), a translucent spy at 4:06:17 that turns solid once hit (4:06:20),
-- and two live captures that moved 7.7 yd in 6 s and 6.7 yd in 8 s. Sneak 365358 is the moving stealth in the
-- Kerebor rogue kit (365352-365358; Hide 365354 breaks on movement). As a template aura it breaks on damage or a
-- swing and comes back on respawn and evade. Random 6 yd wander, as stock stealthed infiltrators (4834) do.
DELETE FROM `creature_template_addon` WHERE `entry` = 164269;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
    `visibilityDistanceType`, `auras`) VALUES
(164269, 0, 0, 0, 1, 0, 0, '365358');

UPDATE `creature` SET `wander_distance` = 6, `MovementType` = 1 WHERE `id` = 164269
    AND `guid` IN (9961108, 9961139, 9961710, 9961716, 9961744, 9961748, 9961753, 9961758, 9961770);
