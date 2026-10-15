-- "No One to Bring Her Flowers": the quest text has Durak hand over the flowers and its log says "Return to Durak", so
-- Durakh in Dun Kazad gives and takes the quest (Martha Agros's gravestone is already in the Kheled-Zaram cemetery).
UPDATE `creature_template` SET `npcflag` = `npcflag` | 2 WHERE `entry` = 164414;
DELETE FROM `creature_queststarter` WHERE `id` = 164414 AND `quest` = 175340;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164414, 175340);
DELETE FROM `creature_questender` WHERE `id` = 164414 AND `quest` = 175340;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(164414, 175340);
