-- Givers named by the quests' own pickup text:
-- * "News from Cresthairn": "<The Three Sisters bless your name three times before taking their leave.>" - the Three
--   Sisters' cauldron offers it once Cardinal Sin is handed in.
-- * "A Temple in Ruins": "Follow me... <The Loa's eyes flash...>" - Anzuldin, the Leopard Loa.
DELETE FROM `gameobject_queststarter` WHERE `id` = 2300801 AND `quest` = 175205;
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES
(2300801, 175205);
UPDATE `creature_template` SET `npcflag` = `npcflag` | 2 WHERE `entry` = 164806;
DELETE FROM `creature_queststarter` WHERE `id` = 164806 AND `quest` = 175154;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164806, 175154);
