-- Patrols the user recorded in game with .wp add (2026-10-10/11) but never loaded onto their NPCs: each path starts where
-- its walker stands.
UPDATE `creature` SET `MovementType` = 2, `wander_distance` = 0 WHERE `guid` IN (9965020, 9965070, 9965088, 9965115, 9965128, 9965137);
DELETE FROM `creature_addon` WHERE `guid` IN (9965020, 9965070, 9965088, 9965115, 9965128, 9965137);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9965020, 9921102, 0, 0, 1, 0, 0, ''),
(9965070, 9921103, 0, 0, 1, 0, 0, ''),
(9965088, 9921104, 0, 0, 1, 0, 0, ''),
(9965115, 9921105, 0, 0, 1, 0, 0, ''),
(9965128, 9921106, 0, 0, 1, 0, 0, ''),
(9965137, 9921107, 0, 0, 1, 0, 0, '');

-- Frosty Crabs drop crab meat, claws and clams, and the same rare zone greens as the Scadeald foxes and wolves.
UPDATE `creature_template` SET `lootid` = 164394 WHERE `entry` = 164394;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164394;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164394, 2674, 0, 35, 0, 1, 0, 1, 2, 'Frosty Crab - Crawler Meat'),
(164394, 2675, 0, 20, 0, 1, 0, 1, 1, 'Frosty Crab - Crawler Claw'),
(164394, 5524, 0, 8, 0, 1, 0, 1, 1, 'Frosty Crab - Thick-shelled Clam'),
(164394, 9771, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14127, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14133, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14165, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14179, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14373, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14374, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14375, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14566, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14572, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14742, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 14748, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15117, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15122, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15124, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15329, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15330, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15500, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15511, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15512, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15513, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15517, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15526, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15894, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab'),
(164394, 15972, 0, 0.014, 0, 1, 0, 1, 1, 'Frosty Crab');
